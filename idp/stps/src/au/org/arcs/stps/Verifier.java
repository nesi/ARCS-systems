/**
 * 
 */
package au.org.arcs.stps;

import java.io.File;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.xml.security.signature.XMLSignature;
import org.apache.xml.security.utils.Constants;
import org.apache.xpath.CachedXPathAPI;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 * @author Damien Chen
 *
 */
public class Verifier {

	static Log log = LogFactory.getLog(Verifier.class.getName());

	static {
		org.apache.xml.security.Init.init();
	}
	
	public Document verify(Document domDoc) throws Exception{
		
	      File signatureFile = new File("./src/signedStatement.xml");
	     
	      String BaseURI = signatureFile.toURL().toString();
	      CachedXPathAPI xpathAPI = new CachedXPathAPI();
	      Element nsctx = domDoc.createElementNS(null, "nsctx");

	      nsctx.setAttributeNS(Constants.NamespaceSpecNS, "xmlns:ds",
	                           Constants.SignatureSpecNS);

	      
	      Element signatureElem = (Element) xpathAPI.selectSingleNode(domDoc,
	                                 "//ds:Signature");

      
	      
	      XMLSignature sig = new XMLSignature(signatureElem, BaseURI);
	      boolean verify = sig.checkSignatureValue(sig.getKeyInfo().getPublicKey());

	      System.out.println("The signature is" + (verify
	                                               ? " "
	                                               : " not ") + "valid");

		
		return domDoc;
	}
	/**
	 * @param args
	 */
	public static void main(String[] args) {
		
		Verifier verifier = new Verifier();
		try {
			//verifier.verify(domDoc);
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

}
