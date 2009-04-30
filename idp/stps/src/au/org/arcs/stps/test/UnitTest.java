/**
 * 
 */
package au.org.arcs.stps.test;

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

	public void testSTPS() {
		try {
			Document domDoc = null;
			DocumentUtils du = new DocumentUtils();
			Encrypter encrypter = new Encrypter();
			Decrypter decrypter = new Decrypter();
			Signer signer = new Signer();
			Verifier verifier = new Verifier();

			domDoc = du.createRawDoc();
			du.jdomWriteToFile(domDoc, path + "statement.xml");
			domDoc = encrypter.encrypt(domDoc);
			du.jdomWriteToFile(domDoc, path + "encStatement.xml");
			domDoc = signer.sign(domDoc);
			du.jdomWriteToFile(domDoc, path + "signedStatement.xml");
			domDoc = verifier.verify(domDoc);
			domDoc = decrypter.decrypt(domDoc);
			du.jdomWriteToFile(domDoc, path + "decStatement.xml");


/*			
			domDoc = du.createRawDoc();
			du.writeToFile(domDoc, path + "statement.xml");
			domDoc = encrypter.encrypt(du.loadDocument(path + "statement.xml"));
			du.writeToFile(domDoc, path + "encStatement.xml");
			domDoc = signer.sign(du.loadDocument(path + "encStatement.xml"));
			du.writeToFile(domDoc, path + "signedStatement.xml");
			domDoc = verifier.verify(du.loadDocument(path + "signedStatement.xml"));
			domDoc = decrypter.decrypt(du.loadDocument(path + "signedStatement.xml"));
			du.writeToFile(domDoc, path + "decStatement.xml");
*/			
			

		} catch (Exception e) {
			e.printStackTrace();
		}

	}
	
	public void printDoc(Document domDoc, String subject) throws Exception{
		
		DocumentUtils docManager = new DocumentUtils();
		org.jdom.Document jdomDoc = docManager.dom2jdom(domDoc);
		XMLOutputter outputter = new XMLOutputter();
		outputter.setFormat(Format.getPrettyFormat());
		System.out.println("========== " + subject + " =========");
		outputter.output(jdomDoc, System.out);

		
	}

}
