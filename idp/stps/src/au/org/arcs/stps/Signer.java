/**
 * 
 */
package au.org.arcs.stps;

import java.io.File;
import java.security.PrivateKey;
import java.security.PublicKey;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.xml.security.signature.XMLSignature;
import org.apache.xml.security.utils.IdResolver;
import org.w3c.dom.Document;

/**
 * @author Damien Chen
 * 
 */
public class Signer {

	static Log log = LogFactory.getLog(Signer.class.getName());

	static {
		org.apache.xml.security.Init.init();
	}

	public Document sign(Document domDoc) throws Exception {

		File signedStatement = new File("./src/signedStatement.xml");
		KeyDiscovery keyDiscovery = new KeyDiscovery();

		PrivateKey signingKey = keyDiscovery.getSigningKey();
		PublicKey verifyingKey = keyDiscovery.getVerifyingKey();

		String BaseURI = signedStatement.toURL().toString();
		XMLSignature sig = new XMLSignature(domDoc, BaseURI,
				XMLSignature.ALGO_ID_SIGNATURE_RSA);

		domDoc.getElementsByTagName("Statement").item(0).appendChild(sig.getElement());
		
		org.w3c.dom.Element domElementBody = (org.w3c.dom.Element) domDoc
		.getElementsByTagName("Body").item(0);

		IdResolver.registerElementById(domElementBody, "id");
	
		sig.addDocument("#Body");

		sig.addKeyInfo(keyDiscovery.getX509Certificate());
		sig.addKeyInfo(verifyingKey);
		sig.sign(signingKey);
		
		
	      System.out.println("Wrote signature to " + BaseURI);

	      for (int i = 0; i < sig.getSignedInfo().getSignedContentLength(); i++) {
	         System.out.println("--- Signed Content follows ---");
	         System.out
	            .println(new String(sig.getSignedInfo().getSignedContentItem(i)));
	      }
	      
	      
		return domDoc;
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		try{
		Signer signer = new Signer();
		//signer.sign();
		}catch(Exception e){
			e.printStackTrace();
		}
		
	}

}
