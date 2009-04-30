/**
 * 
 */
package au.org.arcs.stps;

import java.io.File;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.cert.X509Certificate;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.xml.security.signature.XMLSignature;
import org.apache.xml.security.utils.Constants;
import org.apache.xml.security.utils.IdResolver;
import org.apache.xml.security.utils.XMLUtils;
import org.jdom.Namespace;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 * @author Damien Chen
 * 
 */
public class SignerTest {

	static Log log = LogFactory.getLog(SignerTest.class.getName());

	static {
		org.apache.xml.security.Init.init();
	}

	public Document sign() throws Exception {

		File signatureFile = new File("./src/signatureTest.xml");
		KeyDiscovery keyDiscovery = new KeyDiscovery();
		DocumentUtils docManager = new DocumentUtils();

		PrivateKey signingKey = keyDiscovery.getSigningKey();
		PublicKey verifyingKey = keyDiscovery.getVerifyingKey();

		javax.xml.parsers.DocumentBuilderFactory dbf = javax.xml.parsers.DocumentBuilderFactory
				.newInstance();

		dbf.setNamespaceAware(true);

		javax.xml.parsers.DocumentBuilder db = dbf.newDocumentBuilder();
		org.w3c.dom.Document doc = db.newDocument();

		Element statement = doc.createElementNS(null, "Statement");

		statement.setAttributeNS(Constants.NamespaceSpecNS, "xmlns:ds",
				Constants.SignatureSpecNS);
		doc.appendChild(statement);

		Element bodyElem = doc.createElementNS(null, "Body");
		statement.appendChild(doc.createTextNode("\n"));
		statement.appendChild(bodyElem);
		statement.appendChild(doc.createTextNode("\n"));
		bodyElem
				.appendChild(doc
						.createTextNode("This is signed together with it's Body ancestor"));

		bodyElem.setAttributeNS(null, "id", "Body");

		
		IdResolver.registerElementById(bodyElem, "id");
		
		
		Element userInfo = doc.createElementNS(null, "UserInfo");
		bodyElem.appendChild(doc.createTextNode("\n"));
		bodyElem.appendChild(userInfo);
		bodyElem.appendChild(doc.createTextNode("\n"));

		
		Element sharedToken = doc.createElementNS(null, "SharedToken");
		userInfo.appendChild(doc.createTextNode("\n"));
		userInfo.appendChild(sharedToken);
		userInfo.appendChild(doc.createTextNode("\n"));
		sharedToken
				.appendChild(doc
						.createTextNode("xyzabcopq="));

	
		Element userDN = doc.createElementNS(null, "UserDN");
		userInfo.appendChild(doc.createTextNode("\n"));
		userInfo.appendChild(userDN);
		userInfo.appendChild(doc.createTextNode("\n"));
		userDN
				.appendChild(doc
						.createTextNode("damien.chen"));

		
		

		Element signatureElem = doc.createElementNS(null, "Signature");

		// statement.setAttributeNS(Constants.NamespaceSpecNS, "xmlns:SOAP-SEC",
		// SOAPSECNS);
		// statement.setAttributeNS(null, "actor", "some-uri");
		// statement.setAttributeNS(null, "mustUnderstand", "1");
		// statement.appendChild(doc.createTextNode("\n"));
		statement.appendChild(signatureElem);

		/*
		 * 
		 * End SOAP infrastructure code. This is to be made compatible with
		 * Axis.
		 */
		String BaseURI = signatureFile.toURL().toString();
		XMLSignature sig = new XMLSignature(doc, BaseURI,
				XMLSignature.ALGO_ID_SIGNATURE_RSA);

		signatureElem.appendChild(sig.getElement());

		{
			sig.addDocument("#Body");
			// sig.addDocument("");

			/*
			 * Transforms transforms = new Transforms(doc);
			 * transforms.addTransform(Transforms.TRANSFORM_ENVELOPED_SIGNATURE);
			 * sig.addDocument("", transforms);
			 */
		}

		{

			sig.addKeyInfo(keyDiscovery.getX509Certificate());
			sig.addKeyInfo(verifyingKey);
			sig.sign(signingKey);
		}

		FileOutputStream f = new FileOutputStream(signatureFile);

		XMLUtils.outputDOMc14nWithComments(doc, f);
		f.close();
		System.out.println("Wrote signature to " + BaseURI);

		for (int i = 0; i < sig.getSignedInfo().getSignedContentLength(); i++) {
			System.out.println("--- Signed Content follows ---");
			System.out.println(new String(sig.getSignedInfo()
					.getSignedContentItem(i)));
		}

		return null;
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub
		try {
			SignerTest signer = new SignerTest();
			signer.sign();
		} catch (Exception e) {
			e.printStackTrace();
		}

	}

}
