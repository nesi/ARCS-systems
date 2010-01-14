/**
 * 
 */
package au.org.arcs.stps.web;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
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

	/**
	 * 
	 */
	private static final long serialVersionUID = -2398665094703829495L;

	private static Logger log = Logger.getLogger(STPSAction.class.getName());

	@Override
	public String execute() throws Exception {
		ByteArrayOutputStream unsignedOs = null;
		ByteArrayOutputStream signedOs = null;

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
			if(cert == null || cert.trim().equals("")){
				String msg = "The signing certificate is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}
			
			String password = props.getProperty("PASSWORD");
			
			if(password == null || password.trim().equals("")){
				String msg = "The password of the signing key is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}
			
			String issuer = props.getProperty("ISSUER");
			
			if(issuer == null || issuer.trim().equals("")){
				String msg = "The issuer is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}

			String httpHeaderNameSharedToken = props
					.getProperty("HTTP_HEADER_NAME_SHAREDTOKEN");

			if(httpHeaderNameSharedToken == null || httpHeaderNameSharedToken.trim().equals("")){
				String msg = "The http header's name for the SharedToken is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}
			
			String httpHeaderNameCn = props.getProperty("HTTP_HEADER_NAME_CN");
			
			if(httpHeaderNameCn == null || httpHeaderNameCn.trim().equals("")){
				String msg = "The http header's name for the cn is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}
			String httpHeaderNameMail = props
					.getProperty("HTTP_HEADER_NAME_MAIL");
			
			if(httpHeaderNameMail == null || httpHeaderNameMail.trim().equals("")){
				String msg = "The http header's name for the mail is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}
			String httpHeaderNameProviderID = props
					.getProperty("HTTP_HEADER_NAME_PROVIDER_ID");
			if(httpHeaderNameProviderID == null || httpHeaderNameProviderID.trim().equals("")){
				String msg = "The http header's name for the Shibboleth ProviderID is not specified in the properties file.";
				log.error(msg);
				throw new STPSException(msg);
			}
			
			Map<String, String> attrMap = this.getAttributes();
			//Map<String, String> attrMap = this.getAttributesMock();

			String sharedToken = attrMap.get(httpHeaderNameSharedToken);
			if(sharedToken == null || sharedToken.trim().equals("")){
				String msg = "Couldn't get the attribute auEduPersonSharedToken from the IdP.";
				log.error(msg);
				throw new STPSException(msg);
			}
			String cn = attrMap.get(httpHeaderNameCn);
			if(cn == null || cn.trim().equals("")){
				String msg = "Couldn't get the attribute cn from the IdP.";
				log.error(msg);
				throw new STPSException(msg);
			}
			String mail = attrMap.get(httpHeaderNameMail);
			if(mail == null || mail.trim().equals("")){
				String msg = "Couldn't get the attribute mail from the IdP.";
				log.warn(msg);
				mail = "unknown";
			}			
			String sourceIdP = attrMap.get(httpHeaderNameProviderID);
			if(sourceIdP == null || sourceIdP.trim().equals("")){
				String msg = "Couldn't get the header Shib-Identity-Provider from the IdP.";
				log.warn(msg);
				mail = "unknown";
			}			

			HttpServletResponse response = ServletActionContext.getResponse();
			response.setContentType("application/pdf");

			PDFUtil pdfUtil = new PDFUtil();

			unsignedOs = (ByteArrayOutputStream) pdfUtil
					.genPDF(sourceIdP, issuer, sharedToken, cn, mail);
			
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
		} finally{
			if(unsignedOs != null)
				unsignedOs.close();
			if(signedOs != null)
				signedOs.close();
		}
		
		HttpServletRequest request = ServletActionContext.getRequest();
		String remoteUser = request.getRemoteUser();
		String msg = remoteUser + "has obtained the SharedToken document."; 
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
}