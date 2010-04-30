/**
 * 
 */
package au.org.arcs.stps.web;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import org.apache.struts2.ServletActionContext;

import au.org.arcs.stps.STPSConfiguration;
import au.org.arcs.stps.STPSException;
import au.org.arcs.stps.crypto.CryptoUtils;
import au.org.arcs.stps.util.PDFUtil;

import com.opensymphony.xwork2.ActionSupport;

/**
 * @author Damien Chen
 * 
 */
public class STPSAction extends ActionSupport {

	private static final long serialVersionUID = -2398665094703829495L;

	private static Log log = LogFactory.getLog(STPSAction.class);

	private String arcsLogoUrl = null;
	private String errorMessage = null;

	private static String arcsLogoDefaultPath = "/images/arcs-logo.png";

	@Override
	public String execute() throws Exception {

		ByteArrayOutputStream unsignedOs = null;
		ByteArrayOutputStream signedOs = null;
		Properties props = null;
		String cn = null;
		String sharedToken = null;
		String mail = null;
		String sourceIdP = null;

		try {

			STPSConfiguration.initialize(ServletActionContext
					.getServletContext());
			STPSConfiguration config = STPSConfiguration.getInstance();
			config.checkProperties();
			props = config.getProperties();
			
			//String keyFile = STPSConfiguration.getKeyFile();
			

			String cert = props.getProperty("CERTIFICATE");
			//String encrypedPass = props.getProperty("PASSWORD");
			String password = props.getProperty("PASSWORD");
			
			
			errorMessage = props.getProperty("ERROR_MESSAGE");
			
			arcsLogoUrl = props.getProperty("ARCSLOGO_URL");


			Map<String, String> attrMap = this.getShibAttributes(props);
			 //Map<String, String> attrMap = this.getAttributesMock();

			sharedToken = attrMap.get(props
					.getProperty("HTTP_HEADER_NAME_SHAREDTOKEN"));
			cn = attrMap.get(props.getProperty("HTTP_HEADER_NAME_CN"));
			mail = attrMap.get(props.getProperty("HTTP_HEADER_NAME_MAIL"));
			sourceIdP = attrMap.get(props
					.getProperty("HTTP_HEADER_NAME_PROVIDER_ID"));

			byte[] imageByteArray = this.getLogoImage();

			HttpServletResponse response = ServletActionContext.getResponse();
			response.setContentType("application/pdf");
			//response.addHeader("content-disposition","attachment; filename=sharedtoken_statement");
			response.addHeader("content-disposition","filename=sharedtoken_statement");

			PDFUtil pdfUtil = new PDFUtil();
			
			//String decrypedPass = CryptoUtils.decrypt(encrypedPass, new File(keyFile));

			unsignedOs = (ByteArrayOutputStream) pdfUtil.genPDF(sourceIdP,
					sharedToken, cn, mail, imageByteArray, cert, password);

			signedOs = pdfUtil.signPDF(cert, password,
					new ByteArrayInputStream(unsignedOs.toByteArray()));

			signedOs.writeTo(response.getOutputStream());

			unsignedOs.close();
			signedOs.close();

		} catch (STPSException e) {
			this.addActionError(errorMessage);
			log.error(e.getMessage());
			e.printStackTrace();
			log.info(cn + " is failed to obtain the SharedToken document from "
					+ sourceIdP + " at " + new Date().toString());
			return ERROR;
		} catch (Exception e) {
			this.addActionError(errorMessage);
			log.error(e.getMessage());
			e.printStackTrace();
			log.info(cn + " is failed to obtain the SharedToken document from "
					+ sourceIdP + " at " + new Date().toString());
			return ERROR;
		} finally {
			if (unsignedOs != null)
				unsignedOs.close();
			if (signedOs != null)
				signedOs.close();
		}

		String msg = cn + " is successfull to obtain the SharedToken document from "
				+ sourceIdP + " at " + new Date().toString();
		log.info(msg);

		return NONE;
	}

	@SuppressWarnings("unchecked")
	private Map<String, String> getShibAttributes(Properties props)
			throws STPSException {

		HttpServletRequest request = ServletActionContext.getRequest();
		HashMap<String, String> attrMap = new HashMap<String, String>();

		for (Enumeration<String> e = request.getHeaderNames(); e
				.hasMoreElements();) {
			String key = e.nextElement();
			String value = request.getHeader(key);
			attrMap.put(key, value);
		}

		String httpHeaderNameSharedToken = props
				.getProperty("HTTP_HEADER_NAME_SHAREDTOKEN");
		String httpHeaderNameCn = props.getProperty("HTTP_HEADER_NAME_CN");
		String httpHeaderNameMail = props.getProperty("HTTP_HEADER_NAME_MAIL");
		String httpHeaderNameProviderID = props
				.getProperty("HTTP_HEADER_NAME_PROVIDER_ID");

		String sharedToken = attrMap.get(httpHeaderNameSharedToken);

		if (sharedToken == null || sharedToken.trim().equals("")) {
			String msg = "Couldn't get the attribute auEduPersonSharedToken from the IdP.";
			log.error(msg);
			throw new STPSException(msg);
		}
		String cn = attrMap.get(httpHeaderNameCn);
		if (cn == null || cn.trim().equals("")) {
			String msg = "Couldn't get the attribute cn from the IdP.";
			log.error(msg);
			throw new STPSException(msg);
		}
		String mail = attrMap.get(httpHeaderNameMail);
		if (mail == null || mail.trim().equals("")) {
			String msg = "Couldn't get the attribute mail from the IdP.";
			log.warn(msg);
			mail = "unknown";
		}
		String sourceIdP = attrMap.get(httpHeaderNameProviderID);
		if (sourceIdP == null || sourceIdP.trim().equals("")) {
			String msg = "Couldn't get the header Shib-Identity-Provider from the IdP.";
			log.warn(msg);
			mail = "unknown";
		}

		return attrMap;
	}

	private Map<String, String> getAttributesMock() {
		HashMap<String, String> attrMap = new HashMap<String, String>();

		attrMap.put("auEduPersonSharedToken", "j8PyWsvPpTIU__mcYxJkLKzSzxv");
		attrMap.put("cn", "Damien Chen");
		attrMap.put("mail", "damien.chen@arcs.org.au");
		attrMap.put("Shib-Identity-Provider",
				"https://arcs-a3.hpcu.uq.edu.au/idp/shibboleth");
		return attrMap;
	}

	private byte[] getLogoImage() {
		// get arcs logo image
		InputStream imageIs = null;
		boolean isAvailable = true;

		try {
			URL url = new URL(arcsLogoUrl);
			URLConnection uc = url.openConnection();
			imageIs = uc.getInputStream();
		} catch (Exception e) {
			isAvailable = false;
		}

		if (!isAvailable || imageIs == null) {
			log.warn("Couldn't get ARCS logo image from the URL : "
					+ arcsLogoUrl + ", get it locally instead.");
			HttpServletRequest request = ServletActionContext.getRequest();
			imageIs = request.getSession().getServletContext()
					.getResourceAsStream(arcsLogoDefaultPath);
		}

		byte[] imageByteArray = null;
		if (imageIs != null) {
			imageByteArray = this.inputStreamToBytes(imageIs);
		} else {
			log.warn("Couldn't load the logo image");
		}
		return imageByteArray;
	}

	private byte[] inputStreamToBytes(InputStream in) {

		ByteArrayOutputStream out = null;

		try {

			out = new ByteArrayOutputStream(1024);

			byte[] buffer = new byte[1024];
			int len;

			while ((len = in.read(buffer)) >= 0)
				out.write(buffer, 0, len);

			in.close();
			out.close();
		} catch (Exception e) {
			log
					.warn("Error when converting inputstream to byte array, ignore the log image");
		}

		if (out != null)
			return out.toByteArray();
		else
			return null;
	}

}
