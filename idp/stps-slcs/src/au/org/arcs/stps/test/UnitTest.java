/**
 * 
 */
package au.org.arcs.stps.test;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.math.BigInteger;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.jdom.output.Format;
import org.jdom.output.XMLOutputter;
import org.w3c.dom.Document;

import junit.framework.TestCase;
import au.org.arcs.stps.*;

/**
 * @author Damien Chen
 * 
 */
public class UnitTest extends TestCase {

	String path = "./src/";

	/**
	 * 
	 */
	public UnitTest() {
		// TODO Auto-generated constructor stub
	}

	/**
	 * @param arg0
	 */
	public UnitTest(String arg0) {
		super(arg0);
		// TODO Auto-generated constructor stub
	}

	public void testDigest() {
		try {
		FileInputStream fis = new FileInputStream("c:/.globus-slcs/usercert.pem");
		byte[] input = inputStreamToByteArray(fis);

		//String input = "hello";
		String dstr = null;
	    StringBuffer hexString = new StringBuffer();
		byte[] digest = null;
	
			MessageDigest md = MessageDigest.getInstance("SHA-1");
			md.update(input);
			digest = md.digest();
			
		    for (int i = 0; i < digest.length; ++i) {
		        hexString.append(Integer.toHexString(0x0100 + (digest[i] & 0x00FF)).substring(1));
		      }
			//dstr = new BigInteger(1, digest).toString(16);
			/* this is important, toString leaves out initial 0 */
			//if (dstr.length() % 2 > 0)
				//dstr = "0" + dstr;
			System.out.println(hexString);
		} catch (Exception ex) {
			ex.printStackTrace();
		}
	}
	public byte[] inputStreamToByteArray(InputStream is) throws Exception {
		ByteArrayOutputStream byteOut = new ByteArrayOutputStream();
		byte[] buffer = new byte[4096]; // some large number - pick one
		for (int size; (size = is.read(buffer)) != -1;)
			byteOut.write(buffer, 0, size);
		return byteOut.toByteArray();
	}
	private static String bytes2String(byte[] bytes) {
		StringBuilder string = new StringBuilder();
		for (byte b : bytes) {
			String hexString = Integer.toHexString(0x00FF & b);
			string
					.append(hexString.length() == 1 ? "0" + hexString
							: hexString);
		}
		return string.toString();
	}
	/*
	 * public void testDN(){ String dn = "CN=Damien Chen
	 * m0CyWsvPpSLI__mcYxJkYBzSzps, O=ARCS IdP, DC=slcs, DC=arcs, DC=org,
	 * DC=au"; String cn = dn.substring(dn.indexOf("CN="), dn.indexOf(","));
	 * System.out.println("cn : " + cn); String st =
	 * cn.substring(cn.lastIndexOf(" ")); System.out.println("st : " + st); }
	 */
	/*
	 * public void testSTPS() { try { StatementBean sb = new StatementBean();
	 * sb.setExpiresOn("2009-07-05T09:27:05Z");
	 * sb.setIssuedOn("2009-04-05T09:22:05Z");
	 * sb.setIssuer("https://idp.ramp.org.au/idp/shibboleth");
	 * sb.setRecipient("https://idp.arcs.org.au/idp/shibboleth");
	 * sb.setStatementID("abcdefg"); sb.setReferenceNo("1234567");
	 * sb.setSubject("CN=Bruce Lee,OU=ARCS,O=APACGrid,C=AU");
	 * sb.setSharedToken("uN4KqMe6u1_JDTZc9m_4ZG_xG_k");
	 * 
	 * Document domDoc = null; DocumentUtils du = new DocumentUtils(); Encrypter
	 * encrypter = new Encrypter(); Decrypter decrypter = new Decrypter();
	 * Signer signer = new Signer(); Verifier verifier = new Verifier();
	 * 
	 * domDoc = du.createRawDoc(sb);
	 * 
	 * du.jdomWriteToFile(domDoc, path + "statement.xml");
	 * 
	 * 
	 * domDoc = encrypter.encrypt(domDoc); du.jdomWriteToFile(domDoc, path +
	 * "encStatement.xml"); domDoc = signer.sign(domDoc);
	 * du.jdomWriteToFile(domDoc, path + "signedStatement.xml"); domDoc =
	 * verifier.verify(domDoc); domDoc = decrypter.decrypt(domDoc);
	 * du.jdomWriteToFile(domDoc, path + "decStatement.xml");
	 * 
	 * 
	 * 
	 * 
	 * domDoc = du.createRawDoc(); du.writeToFile(domDoc, path +
	 * "statement.xml"); domDoc = encrypter.encrypt(du.loadDocument(path +
	 * "statement.xml")); du.writeToFile(domDoc, path + "encStatement.xml");
	 * domDoc = signer.sign(du.loadDocument(path + "encStatement.xml"));
	 * du.writeToFile(domDoc, path + "signedStatement.xml"); domDoc =
	 * verifier.verify(du.loadDocument(path + "signedStatement.xml")); domDoc =
	 * decrypter.decrypt(du.loadDocument(path + "signedStatement.xml"));
	 * du.writeToFile(domDoc, path + "decStatement.xml");
	 * 
	 * 
	 *  } catch (Exception e) { e.printStackTrace(); }
	 *  }
	 */
	/*
	 * public void printDoc(Document domDoc, String subject) throws Exception{
	 * 
	 * DocumentUtils docManager = new DocumentUtils(); org.jdom.Document jdomDoc =
	 * docManager.dom2jdom(domDoc); XMLOutputter outputter = new XMLOutputter();
	 * outputter.setFormat(Format.getPrettyFormat());
	 * System.out.println("========== " + subject + " =========");
	 * outputter.output(jdomDoc, System.out);
	 * 
	 *  }
	 */

}
