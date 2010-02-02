/**
 * 
 */
package au.org.arcs.stps.util;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.security.cert.X509Certificate;
import java.util.Date;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import au.org.arcs.stps.STPSException;
import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
import com.lowagie.text.DocumentException;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.Image;
import com.lowagie.text.Paragraph;
import com.lowagie.text.Phrase;
import com.lowagie.text.Rectangle;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfReader;
import com.lowagie.text.pdf.PdfSignatureAppearance;
import com.lowagie.text.pdf.PdfStamper;
import com.lowagie.text.pdf.PdfWriter;

/**
 * @author Damien Chen
 * 
 */

public class PDFUtil {

	private static Log log = LogFactory.getLog(PDFUtil.class);
	int defautFontSize = 12;
	int topPadding = 5;
	int bottomPadding = 5;
	static String title = "SharedToken Ownership Statement";
	static String text1 = "This document, generated by the ARCS SharedToken Portability Service and digitally signed by the Australian Research Collaboration Service, provides proof of the named user's ownership of an auEduPersonSharedToken value.";
	static String text2 = "The following information was received from the Australian Access Federation (AAF) Identity Provider:";
	static String text3 = "This document is to be used by the user to populate their auEduPersonSharedToken value when registering with a new AAF Identity Provider.";
	static String text4 = "The user should present this document to the new IdP Administrator when registering with a new institution.";
	static String text5 = "The IdP Administrator can verify the signature using a PDF Reader, thus confirming issuance by the Australian Research Collaboration Service, an AAF-member organisation, and then populate the users auEduPersonSharedToken attribute with this value in the IdP's institutional directory.";
	static String text6 = "If you have any questions regarding this statement, please contact customerservice@arcs.org.au.";

	/**
	 * Generate a PDF document.
	 * 
	 * @param sourceIdP
	 *            the IdP the user is from
	 * @param sharedToken
	 *            the SharedToken the user holds
	 * @param cn
	 *            the common name of the user
	 * @param mail
	 *            users email
	 * @param imageByteArray
	 *            the logo appeared on the document
	 * @param title
	 *            the title of the document
	 * @param note
	 *            the note on the document
	 * @param cert
	 *            the signing certificate path
	 * @param password
	 *            the password to protect the certificate
	 * @throws STPSException
	 *             if the document couldn't be generated
	 */

	public OutputStream genPDF(String sourceIdP, String sharedToken, String cn,
			String mail, byte[] imageByteArray, String cert, String password)
			throws STPSException, Exception {

		log.debug("Calling genPDF()...");

		ByteArrayOutputStream os = new ByteArrayOutputStream();

		try {

			Document document = new Document();

			PdfWriter.getInstance(document, os);

			document.open();
			
			try{

			if (imageByteArray != null) {
				Image image = Image.getInstance(imageByteArray);
				PdfPTable logoTable = new PdfPTable(2);
				logoTable.setTotalWidth(0);
				logoTable.getDefaultCell().setBorder(
						com.lowagie.text.Rectangle.NO_BORDER);
				logoTable.addCell(image);
				logoTable.addCell(" ");
				logoTable.addCell(" ");
				logoTable.addCell(" ");
				document.add(logoTable);
			} else {
				log.warn("Couldn't find the logo image, just ignore");
			}
			}catch(Exception e){
				log.warn("Couldn't find the logo image, just ignore");
			}

			Paragraph pTitle = new Paragraph();
			pTitle.setAlignment(1);
			pTitle.setExtraParagraphSpace(5);
			pTitle.add(new Chunk(title, new Font(Font.TIMES_ROMAN, 20)));

			// text1 table
			PdfPTable text1Table = new PdfPTable(1);
			text1Table.getDefaultCell().setBorder(
					com.lowagie.text.Rectangle.NO_BORDER);

			text1Table.addCell(new Phrase(defautFontSize, new Chunk(text1,
					FontFactory.getFont(FontFactory.TIMES_ROMAN))));
			// text1Table.addCell("");

			// Issuer Table

			String subjectDN = getSubjectDN(cert, password);

			PdfPTable issuerTable = new PdfPTable(2);
			// issuerTable.getDefaultCell().setBorder(
			// com.lowagie.text.Rectangle.NO_BORDER);

			issuerTable.getDefaultCell().setPaddingBottom(topPadding);
			issuerTable.getDefaultCell().setPaddingBottom(bottomPadding);

			issuerTable.addCell(new Phrase(defautFontSize, new Chunk(
					"Signed by", FontFactory.getFont(FontFactory.TIMES_ROMAN,
							defautFontSize, Font.BOLD))));
			issuerTable.addCell(new Phrase(defautFontSize, new Chunk(subjectDN,
					FontFactory.getFont(FontFactory.TIMES_ROMAN))));

			issuerTable.addCell(new Phrase(defautFontSize, new Chunk("Date",
					FontFactory.getFont(FontFactory.TIMES_ROMAN,
							defautFontSize, Font.BOLD))));
			issuerTable
					.addCell(new Phrase(defautFontSize, new Chunk(new Date()
							.toString(), FontFactory
							.getFont(FontFactory.TIMES_ROMAN))));

			// text2 table
			PdfPTable text2Table = new PdfPTable(1);
			text2Table.getDefaultCell().setBorder(
					com.lowagie.text.Rectangle.NO_BORDER);
			text2Table.addCell(new Phrase(defautFontSize, new Chunk(text2
					+ "  " + sourceIdP, FontFactory
					.getFont(FontFactory.TIMES_ROMAN))));

			PdfPTable attrTable = new PdfPTable(2);
			// attrTable.getDefaultCell().setBorder(
			// com.lowagie.text.Rectangle.NO_BORDER);
			attrTable.getDefaultCell().setPaddingBottom(topPadding);
			attrTable.getDefaultCell().setPaddingBottom(bottomPadding);
			attrTable
					.addCell(new Phrase(defautFontSize, new Chunk(
							"auEduPersonSharedToken", FontFactory.getFont(
									FontFactory.TIMES_ROMAN, defautFontSize,
									Font.BOLD))));
			attrTable.addCell(new Phrase(defautFontSize, new Chunk(sharedToken,
					FontFactory.getFont(FontFactory.TIMES_ROMAN))));

			attrTable.addCell(new Phrase(defautFontSize, new Chunk(
					"Common Name", FontFactory.getFont(FontFactory.TIMES_ROMAN,
							defautFontSize, Font.BOLD))));
			attrTable.addCell(new Phrase(defautFontSize, new Chunk(cn,
					FontFactory.getFont(FontFactory.TIMES_ROMAN))));

			attrTable.addCell(new Phrase(defautFontSize, new Chunk("Mail",
					FontFactory.getFont(FontFactory.TIMES_ROMAN,
							defautFontSize, Font.BOLD))));
			attrTable.addCell(new Phrase(defautFontSize, new Chunk(mail,
					FontFactory.getFont(FontFactory.TIMES_ROMAN))));

			PdfPTable text3456Table = new PdfPTable(1);
			text3456Table.getDefaultCell().setBorder(
					com.lowagie.text.Rectangle.NO_BORDER);

			text3456Table.addCell(new Phrase(defautFontSize, new Chunk(text3,
					FontFactory.getFont(FontFactory.TIMES_ROMAN))));
			text3456Table.addCell("");
			text3456Table.addCell(new Phrase(defautFontSize, new Chunk(text4,
					FontFactory.getFont(FontFactory.TIMES_ROMAN))));
			text3456Table.addCell("");
			text3456Table.addCell(new Phrase(defautFontSize, new Chunk(text5,
					FontFactory.getFont(FontFactory.TIMES_ROMAN))));
			text3456Table.addCell("");
			text3456Table.addCell(new Phrase(defautFontSize, new Chunk(text6,
					FontFactory.getFont(FontFactory.TIMES_ROMAN))));
			text3456Table.addCell("");

			Paragraph p = new Paragraph(" ");

			document.add(Chunk.NEWLINE);
			document.add(pTitle);
			document.add(Chunk.NEWLINE);
			document.add(text1Table);
			// document.add(Chunk.NEWLINE);
			// document.add(p);
			document.add(p);
			document.add(issuerTable);
			document.add(p);
			document.add(text2Table);
			document.add(p);
			document.add(attrTable);
			document.add(p);
			document.add(text3456Table);

			document.close();
		} catch (DocumentException e) {
			String msg = "Couldn't generate the PDF document. The reason is: "
					+ e.getMessage();
			log.warn(msg);
			throw new STPSException(msg);
		}

		return os;
	}

	/**
	 * Generate a PDF document.
	 * 
	 * @param cert
	 *            the file path of the signing certificate
	 * @param password
	 *            the passfrase to protect the certificate
	 * @param is
	 *            the input stream of the document to be signed.
	 * @param cn
	 *            the common name of the user
	 * @throws STPSException
	 *             if the document couldn't be signed
	 */
	public ByteArrayOutputStream signPDF(String cert, String password,
			InputStream is) throws STPSException {

		log.debug("Calling signPDF()...");
		ByteArrayOutputStream os = new ByteArrayOutputStream();

		try {
			KeyStore ks = KeyStore.getInstance("pkcs12");

			InputStream fis = this.getCertIs(cert);

			ks.load(fis, password.toCharArray());

			String alias = ks.aliases().nextElement();
			PrivateKey key = (PrivateKey) ks.getKey(alias, password
					.toCharArray());
			Certificate[] chain = ks.getCertificateChain(alias);

			PdfReader reader = new PdfReader(is);

			PdfStamper stp = PdfStamper.createSignature(reader, os, '\0');
			PdfSignatureAppearance sap = stp.getSignatureAppearance();
			sap.setCrypto(key, chain, null,
					PdfSignatureAppearance.WINCER_SIGNED);
			// comment next line to have an invisible signature
			sap.setVisibleSignature(new Rectangle(100, 100, 200, 200), 1, null);
			stp.close();
		} catch (Exception e) {
			String msg = e.getMessage()
					+ "\n Failed to sign the document. The error is: "
					+ e.getMessage();
			log.error(msg);
			e.printStackTrace();
			throw new STPSException(msg);
		}

		return os;
	}

	private InputStream getCertIs(String cert) throws STPSException {
		InputStream certIs = null;
		try {
			certIs = new FileInputStream(cert);
		} catch (FileNotFoundException e) {
			String msg = e.getMessage() + " \n Couldn't find the certificate: "
					+ cert;
			log.error(msg);
			// e.printStackTrace();
			throw new STPSException(msg);
		}
		return certIs;

	}

	private String getSubjectDN(String cert, String password)
			throws STPSException {

		String subjectDN = null;
		try {
			InputStream certIs = getCertIs(cert);
			KeyStore ks = KeyStore.getInstance("pkcs12");
			ks.load(certIs, password.toCharArray());
			String alias = ks.aliases().nextElement();
			X509Certificate xcert = (X509Certificate) ks.getCertificate(alias);
			subjectDN = xcert.getSubjectDN().getName();
			subjectDN = subjectDN.substring(subjectDN.indexOf("=") + 1);

		} catch (Exception e) {
			String msg = e.getMessage() + "\n couldn't get subject DN";
			throw new STPSException(msg);
		}
		return subjectDN;
	}

}
