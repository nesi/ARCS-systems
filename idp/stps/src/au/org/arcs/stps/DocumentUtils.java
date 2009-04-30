/**
 * 
 */
package au.org.arcs.stps;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.FileWriter;

import org.apache.xml.security.utils.Constants;
import org.apache.xml.security.utils.IdResolver;
import org.apache.xml.security.utils.XMLUtils;
import org.jdom.input.DOMBuilder;
import org.jdom.input.SAXBuilder;
import org.jdom.output.DOMOutputter;
import org.jdom.output.Format;
import org.jdom.output.XMLOutputter;
import org.w3c.dom.Document;
import org.w3c.dom.Element;

/**
 * @author Damien Chen
 * 
 */
public class DocumentUtils {
	//static String path = "./src/";
	public Document createRawDoc() throws Exception {

		javax.xml.parsers.DocumentBuilderFactory dbf = javax.xml.parsers.DocumentBuilderFactory
				.newInstance();

		dbf.setNamespaceAware(true);

		javax.xml.parsers.DocumentBuilder db = dbf.newDocumentBuilder();
		org.w3c.dom.Document domDoc = db.newDocument();

		Element statement = domDoc.createElementNS(null, "Statement");

		statement.setAttributeNS(Constants.NamespaceSpecNS, "xmlns:ds",
				Constants.SignatureSpecNS);
		domDoc.appendChild(statement);

		Element bodyElem = domDoc.createElementNS(null, "Body");
		statement.appendChild(domDoc.createTextNode("\n"));
		statement.appendChild(bodyElem);
		statement.appendChild(domDoc.createTextNode("\n"));

		bodyElem.setAttributeNS(null, "id", "Body");

		IdResolver.registerElementById(bodyElem, "id");

		Element userInfo = domDoc.createElementNS(null, "UserInfo");
		bodyElem.appendChild(domDoc.createTextNode("\n"));
		bodyElem.appendChild(userInfo);
		bodyElem.appendChild(domDoc.createTextNode("\n"));

		Element sharedToken = domDoc.createElementNS(null, "SharedToken");
		userInfo.appendChild(domDoc.createTextNode("\n"));
		userInfo.appendChild(sharedToken);
		userInfo.appendChild(domDoc.createTextNode("\n"));
		sharedToken.appendChild(domDoc.createTextNode("uN4KqMe6u1_JDTZc9m_4ZG_xG_k"));

		Element userDN = domDoc.createElementNS(null, "UserDN");
		userInfo.appendChild(domDoc.createTextNode("\n"));
		userInfo.appendChild(userDN);
		userInfo.appendChild(domDoc.createTextNode("\n"));
		userDN.appendChild(domDoc.createTextNode("CN=Bruce Lee,OU=ARCS,O=APACGrid,C=AU"));
		
		return domDoc;
	}


	public static org.w3c.dom.Document jdom2dom(org.jdom.Document jdomDoc) throws Exception {
		DOMOutputter domOutputter = new DOMOutputter();

		org.w3c.dom.Document domDoc = domOutputter.output(jdomDoc);

		return domDoc;
	}

	public static org.jdom.Document dom2jdom(org.w3c.dom.Document domDoc) throws Exception {
		DOMBuilder in = new DOMBuilder();
		org.jdom.Document jdomDoc = in.build(domDoc);
		return jdomDoc;
	}

	
	public static void printDoc(Document domDoc, String subject) throws Exception {
		
		org.jdom.Document jdomDoc = DocumentUtils.dom2jdom(domDoc);
		XMLOutputter outputter = new XMLOutputter();
		outputter.setFormat(Format.getPrettyFormat());
		System.out.println("==========" + subject + "=========");
		outputter.output(jdomDoc, System.out);

	}
	
	public static void jdomWriteToFile(Document domDoc, String filePath) throws Exception{
		org.jdom.Document jdomDoc = DocumentUtils.dom2jdom(domDoc);
		XMLOutputter outputter = new XMLOutputter();
		outputter.setFormat(Format.getPrettyFormat());
		FileWriter writer = new FileWriter(filePath);
		outputter.output(jdomDoc, writer);
		writer.close();
	}
	public static void writeToFile(Document domDoc, String filePath) throws Exception{
		
		  File signedStatement = new File(filePath);
	      FileOutputStream f = new FileOutputStream(signedStatement);
	      XMLUtils.outputDOMc14nWithComments(domDoc, f);
	      f.close();

	}
	
	public static Document loadDocument(String filePath) throws Exception{
	      File signatureFile = new File(filePath);
	      javax.xml.parsers.DocumentBuilderFactory dbf =
	         javax.xml.parsers.DocumentBuilderFactory.newInstance();

	      dbf.setNamespaceAware(true);

	      javax.xml.parsers.DocumentBuilder db = dbf.newDocumentBuilder();
	      Document domDoc = db.parse(new FileInputStream(signatureFile));
	      return domDoc;

	}
	
	/**
	 * @param args
	 */
	public static void main(String[] args) {

		try {
			DocumentUtils dm = new DocumentUtils();
			Document doc = dm.createRawDoc();

		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

	}
}
