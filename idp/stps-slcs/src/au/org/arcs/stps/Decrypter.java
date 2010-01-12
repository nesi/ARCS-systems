/**
 * 
 */
package au.org.arcs.stps;

import java.security.PrivateKey;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.xml.security.encryption.XMLCipher;
import org.apache.xml.security.utils.EncryptionConstants;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

import au.org.arcs.stps.service.KeyDiscovery;
import au.org.arcs.stps.impl.KeyDiscoveryImpl;
/**
 * @author Damien Chen
 * 
 */
public class Decrypter {
	static Log log = LogFactory.getLog(Encrypter.class.getName());

	static {
		org.apache.xml.security.Init.init();
	}

	public Document decrypt(Document domDoc) throws Exception {

		KeyDiscovery keyDiscovery = new KeyDiscoveryImpl();
		PrivateKey privateKey = keyDiscovery.getDecryptionKey();

		Element encryptedDataElement = (Element) domDoc.getElementsByTagNameNS(
				EncryptionConstants.EncryptionSpecNS,
				EncryptionConstants._TAG_ENCRYPTEDDATA).item(0);

		XMLCipher xmlCipher = XMLCipher.getInstance();
		xmlCipher.init(XMLCipher.DECRYPT_MODE, null);
		xmlCipher.setKEK(privateKey);
		xmlCipher.doFinal(domDoc, encryptedDataElement);

	
		return domDoc;
	}
	
	

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		try {
			Decrypter decrypter = new Decrypter();
			//decrypter.decrypt();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

}
