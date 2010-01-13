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

import org.apache.struts2.ServletActionContext;

import au.org.arcs.stps.util.PDFUtil;

import com.opensymphony.xwork2.ActionSupport;

/**
 * @author Damien Chen
 * 
 */
public class STPSAction extends ActionSupport {

	@Override
	public String execute() throws Exception {

		try {

			Properties props = new Properties();

			InputStream is = this.getClass().getResourceAsStream(
					"/stps-web.properties");
			
			props.load(is);

			String cert = props.getProperty("CERTIFICATE");
			String password = props.getProperty("PASSWORD");
			String entityID = props.getProperty("ENTITY_ID");

			String httpHeaderNameSharedToken = props
					.getProperty("HTTP_HEADER_NAME_SHAREDTOKEN");
			String httpHeaderNameCn = props.getProperty("HTTP_HEADER_NAME_CN");
			String httpHeaderNameMail = props
					.getProperty("HTTP_HEADER_NAME_MAIL");

			// Map<String, String> attrMap = this.getAttributes();
			Map<String, String> attrMap = this.getAttributesTest();

			String sharedToken = attrMap.get(httpHeaderNameSharedToken);
			String cn = attrMap.get(httpHeaderNameCn);
			String mail = attrMap.get(httpHeaderNameMail);

			HttpServletResponse response = ServletActionContext.getResponse();
			response.setContentType("application/pdf");

			PDFUtil pdfUtil = new PDFUtil();
			ByteArrayOutputStream unsignedOs = (ByteArrayOutputStream) pdfUtil
					.genPDF(entityID, sharedToken, cn, mail);
			ByteArrayOutputStream signedOs = pdfUtil.signPDF(cert, password,
					new ByteArrayInputStream(unsignedOs.toByteArray()));

			signedOs.writeTo(response.getOutputStream());

		} catch (Exception e) {
			this.addActionError(e.getMessage());
			e.printStackTrace();
			return ERROR;
		}

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

	private Map<String, String> getAttributesTest() {
		HashMap<String, String> attrMap = new HashMap<String, String>();
		attrMap.put("uid", "damien.chen");
		attrMap.put("auEduPersonSharedToken", "j8PyWsvPpTIU__mcYxJkLKzSzxv");
		attrMap.put("cn", "Damien Chen");
		attrMap.put("mail", "damien.chen@arcs.org.au");
		return attrMap;
	}
}
