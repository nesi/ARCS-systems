/**
 * 
 */
package au.org.arcs.stps.cl;

import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import au.org.arcs.stps.util.PDFUtil;

/**
 * @author Damien Chen
 * 
 */
public class STP {

	static String attributes = "auEduPersonSharedToken,uid,cn,mail";

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		String uid = null;

		try {

			if (null == args || args.length < 1) {
				InputStreamReader inp = new InputStreamReader(System.in);
				BufferedReader br = new BufferedReader(inp);

				System.out.println("Enter uid: ");

				uid = br.readLine();

				System.out
						.println("will generate a signed SharedToken PDF document for "
								+ uid);

			} else if (args.length > 1) {
				System.out.println("too many arguments");
				System.exit(1);
			} else {
				uid = args[0];
			}

			System.out.println("loading properties file ...");

			Properties props = new Properties();
			
			
			InputStream is = new STP().getClass().getClassLoader().getResourceAsStream ("stps-cl.properties");

			props.load(is);
			//props.load(new FileInputStream("./stps-cl.properties"));

			String ldapURL = props.getProperty("LDAP_URL");
			String principal = props.getProperty("PRINCIPAL");
			String principalCredential = props
					.getProperty("PRINCIPAL_CREDENTIAL");
			String baseDN = props.getProperty("BASE_DN");
			String searchFilter = props.getProperty("SEARCH_FILTER");
			String keyStore = props.getProperty("KEY_STORE");

			String cert = props.getProperty("CERTIFICATE");
			String password = props.getProperty("PASSWORD");
			String location = props.getProperty("LOCATION");

			String entityID = props.getProperty("ENTITY_ID");

			String originalPDFDir = props.getProperty("ORIGINAL_PDF");
			String signedPDFDir = props.getProperty("SIGNED_PDF");

			LdapUtil ldapUtil = new LdapUtil(ldapURL, principal,
					principalCredential, baseDN, searchFilter, attributes,
					keyStore);

			Map<String, Set<String>> attrMap = ldapUtil.getUserAttributes(uid);
			
			String sharedToken = ldapUtil.setToString(attrMap.get("sharedToken"));
			String cn = ldapUtil.setToString(attrMap.get("cn"));
			String mail = ldapUtil.setToString(attrMap.get("mail"));

			PDFUtil pdfUtil = new PDFUtil();
			
			ByteArrayOutputStream unsignedOs = (ByteArrayOutputStream)pdfUtil.genPDF(entityID, sharedToken, cn, mail);
			ByteArrayOutputStream signedOs = pdfUtil.signPDF(cert, password, new ByteArrayInputStream(unsignedOs.toByteArray()));
			String filePath = originalPDFDir + "/" + uid + ".pdf";
			OutputStream fileOs = new FileOutputStream(new File(filePath));
			signedOs.writeTo(fileOs);
			fileOs.close();
			

		} catch (Exception e) {
			e.printStackTrace();
		}

	}
	
}
