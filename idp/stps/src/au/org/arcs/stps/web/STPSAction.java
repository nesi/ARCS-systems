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
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.log4j.Logger;
import org.apache.struts2.ServletActionContext;

import au.org.arcs.stps.STPSException;
import au.org.arcs.stps.util.PDFUtil;

import com.opensymphony.xwork2.ActionSupport;

/**
 * @author Damien Chen
 * 
 */
public class STPSAction extends ActionSupport {

	private static final long serialVersionUID = -2398665094703829495L;

	private static Logger log = Logger.getLogger(STPSAction.class.getName());

	private String title;

	private String note;

	@Override
	public String execute() throws Exception {
		ByteArrayOutputStream unsignedOs = null;
		ByteArrayOutputStream signedOs = null;
		String cn = null;

		try {

			Properties props = new Properties();

			InputStream is = this.getClass().getResourceAsStream(
					"/stps-web.properties");

			if (is == null) {
				String msg = "Couldn't find the properties file: stps-web.properties.";
				log.error(msg);
				throw new STPSException(msg);
			}

			props.load(is);

			String cert = props.getProperty("CERTIFICATE");
			if (cert == null || cert.trim().equals("")) {
				String msg = "The signing certificate is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}

			String password = props.getProperty("PASSWORD");

			if (password == null || password.trim().equals("")) {
				String msg = "The password of the signing key is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}

			String issuer = props.getProperty("ISSUER");

			if (issuer == null || issuer.trim().equals("")) {
				String msg = "The issuer is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}

			String httpHeaderNameSharedToken = props
					.getProperty("HTTP_HEADER_NAME_SHAREDTOKEN");

			if (httpHeaderNameSharedToken == null
					|| httpHeaderNameSharedToken.trim().equals("")) {
				String msg = "The http header's name for the SharedToken is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}

			String httpHeaderNameCn = props.getProperty("HTTP_HEADER_NAME_CN");

			if (httpHeaderNameCn == null || httpHeaderNameCn.trim().equals("")) {
				String msg = "The http header's name for the cn is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}
			String httpHeaderNameMail = props
					.getProperty("HTTP_HEADER_NAME_MAIL");

			if (httpHeaderNameMail == null
					|| httpHeaderNameMail.trim().equals("")) {
				String msg = "The http header's name for the mail is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}
			String httpHeaderNameProviderID = props
					.getProperty("HTTP_HEADER_NAME_PROVIDER_ID");
			if (httpHeaderNameProviderID == null
					|| httpHeaderNameProviderID.trim().equals("")) {
				String msg = "The http header's name for the Shibboleth ProviderID is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}

			Map<String, String> attrMap = this.getAttributes();
			//Map<String, String> attrMap = this.getAttributesMock();

			String sharedToken = attrMap.get(httpHeaderNameSharedToken);
			if (sharedToken == null || sharedToken.trim().equals("")) {
				String msg = "Couldn't get the attribute auEduPersonSharedToken from the IdP.";
				log.error(msg);
				throw new STPSException(msg);
			}
			cn = attrMap.get(httpHeaderNameCn);
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

			HttpServletRequest request = ServletActionContext.getRequest();
			String imagePath = request.getSession().getServletContext()
					.getRealPath("/images/arcs-logo.jpg");

			File imageFile = null;
			byte[] imageByteArray = null;
			if (imagePath != null) {
				imageFile = new File(imagePath);
				if (imageFile != null) {
					imageByteArray = this.getBytesFromFile(imageFile);
				} else {
					log.warn("Couldn't load the logo image file");
				}
			} else {
				log.warn("Couldn't find the logo image file");
			}

			HttpServletResponse response = ServletActionContext.getResponse();
			response.setContentType("application/pdf");

			PDFUtil pdfUtil = new PDFUtil();

			unsignedOs = (ByteArrayOutputStream) pdfUtil.genPDF(sourceIdP,
					issuer, sharedToken, cn, mail, imageByteArray, title, note);

			signedOs = pdfUtil.signPDF(cert, password,
					new ByteArrayInputStream(unsignedOs.toByteArray()));

			signedOs.writeTo(response.getOutputStream());

			unsignedOs.close();
			signedOs.close();

		} catch (STPSException e) {
			this.addActionError(e.getMessage());
			e.printStackTrace();
			return ERROR;
		} catch (Exception e) {
			this.addActionError(e.getMessage());
			e.printStackTrace();
			return ERROR;
		} finally {
			if (unsignedOs != null)
				unsignedOs.close();
			if (signedOs != null)
				signedOs.close();
		}

		String msg = cn + " has obtained the SharedToken document.";
		log.info(msg);

		return NONE;
	}

	@SuppressWarnings("unchecked")
	private Map<String, String> getAttributes() {

		HttpServletRequest request = ServletActionContext.getRequest();
		HashMap<String, String> map = new HashMap<String, String>();

		for (Enumeration<String> e = request.getHeaderNames(); e
				.hasMoreElements();) {
			String key = e.nextElement();
			String value = request.getHeader(key);
			map.put(key, value);
		}
		String uid = request.getRemoteUser();
		map.put("uid", uid);
		return map;
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

	public byte[] getBytesFromFile(File file) throws STPSException {

		byte[] bytes = null;
		try {

			InputStream is = new FileInputStream(file);
			log.debug("FileInputStream is " + file);

			// Get the size of the file
			long length = file.length();
			System.out.println("DEBUG: Length of " + file + " is " + length
					+ "\n");

			if (length > Integer.MAX_VALUE) {
				System.out.println("File is too large to process");
				return null;
			}

			// Create the byte array to hold the data
			bytes = new byte[(int) length];

			// Read in the bytes
			int offset = 0;
			int numRead = 0;
			while ((offset < bytes.length)
					&& ((numRead = is
							.read(bytes, offset, bytes.length - offset)) >= 0)) {
				offset += numRead;
			}

			// Ensure all the bytes have been read in
			if (offset < bytes.length) {
				throw new IOException("Could not completely read file "
						+ file.getName());
			}

			is.close();
		} catch (IOException e) {
			throw new STPSException(e.getMessage()
					+ "/n couldn't read the logo image file.");
		}

		return bytes;
	}

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
	}

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

}
