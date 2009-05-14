/**
 * 
 */
package au.org.arcs.stps;

import java.security.PublicKey;
import javax.crypto.SecretKey;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.xml.security.encryption.EncryptedData;
import org.apache.xml.security.encryption.EncryptedKey;
import org.apache.xml.security.encryption.XMLCipher;
import org.apache.xml.security.keys.KeyInfo;

import org.w3c.dom.Document;

import au.org.arcs.stps.service.KeyDiscovery;
import au.org.arcs.stps.impl.KeyDiscoveryImpl;
/**
 * @author Damien Chen
 * 
 */
public class Encrypter {

	static Log log = LogFactory.getLog(Encrypter.class.getName());

	static {
		org.apache.xml.security.Init.init();
	}

	public Document encrypt(Document domDoc) throws Exception {
			
		KeyDiscovery keyDiscovery = new KeyDiscoveryImpl();
		PublicKey publicKey = keyDiscovery.getEncryptionKey();
		SecretKey symmetricKey = keyDiscovery.getSymmetricKey();

		String algorithmURI = XMLCipher.RSA_v1dot5;

		XMLCipher keyCipher = XMLCipher.getInstance(algorithmURI);
		keyCipher.init(XMLCipher.WRAP_MODE, publicKey);
		EncryptedKey encryptedKey = keyCipher.encryptKey(domDoc, symmetricKey);

		org.w3c.dom.Element rootElement = domDoc.getDocumentElement();
		org.w3c.dom.Element userInfoElement = (org.w3c.dom.Element) rootElement
				.getElementsByTagName("UserInfo").item(0);

		algorithmURI = XMLCipher.AES_128;

		XMLCipher xmlCipher = XMLCipher.getInstance(algorithmURI);
		xmlCipher.init(XMLCipher.ENCRYPT_MODE, symmetricKey);
		
		EncryptedData encryptedData = xmlCipher.getEncryptedData();
		KeyInfo keyInfo = new KeyInfo(domDoc);
		keyInfo.add(encryptedKey);
		encryptedData.setKeyInfo(keyInfo);

		xmlCipher.doFinal(domDoc, userInfoElement, true);
		
		return domDoc;
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		try {
			Encrypter encrypter = new Encrypter();
			//encrypter.encrypt();

		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}

}
