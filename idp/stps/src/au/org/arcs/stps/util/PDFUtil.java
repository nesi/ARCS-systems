/**
 * 
 */
package au.org.arcs.stps.util;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.util.Date;

import org.apache.log4j.Logger;

import au.org.arcs.stps.STPSException;
import au.org.arcs.stps.web.STPSAction;

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

	private static Logger log = Logger.getLogger(STPSAction.class.getName());

	/**
	 * Generate a PDF document.
	 * 
	 * @param sourceIdP the IdP the user is from
	 * @param issuer the organization that released the document
	 * @param sharedToken the SharedToken the user holds
	 * @param cn the common name of the user
	 * @param mail user's email
	 * @param imageByteArray the logo appeared on the document
	 * @param title the title of the document
	 * @param note the note on the document
	 * @throws STPSException if the document couldn't be generated 
	 */
	
	public OutputStream genPDF(String sourceIdP, String issuer,
			String sharedToken, String cn, String mail, byte[] imageByteArray,
			String title, String note) throws STPSException, Exception {

		log.debug("Calling genPDF()...");

		ByteArrayOutputStream os = new ByteArrayOutputStream();

		try {

			Document document = new Document();

			PdfWriter.getInstance(document, os);

			document.open();

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
				log.warn("Couldn't find the logo image");
			}

			document.add(Chunk.NEWLINE);

			Paragraph p = new Paragraph();
			p.setAlignment(1);
			p.setExtraParagraphSpace(5);

			if (title == null || title.trim().equals("")) {
				p.add(new Chunk("SharedToken Statement", new Font(
						Font.TIMES_ROMAN, 20)));
			} else {
				p.add(new Chunk(title, new Font(Font.TIMES_ROMAN, 20)));
			}

			document.add(p);

			document.add(Chunk.NEWLINE);

			PdfPTable attrTable = new PdfPTable(2);

			attrTable.addCell(new Phrase(18, new Chunk(
					"auEduPersonSharedToken", FontFactory.getFont(
							FontFactory.TIMES_ROMAN, 14, Font.BOLD, new Color(
									0, 0, 0)))));
			attrTable.addCell(sharedToken);

			attrTable.addCell(new Phrase(18, new Chunk("Common Name",
					FontFactory.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD,
							new Color(0, 0, 0)))));
			attrTable.addCell(cn);

			attrTable.addCell(new Phrase(18, new Chunk("Mail", FontFactory
					.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD, new Color(
							0, 0, 0)))));
			attrTable.addCell(mail);

			attrTable.addCell(new Phrase(18, new Chunk("Source IdP",
					FontFactory.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD,
							new Color(0, 0, 0)))));
			attrTable.addCell(sourceIdP);

			attrTable.addCell(new Phrase(18, new Chunk("Issuer", FontFactory
					.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD, new Color(
							0, 0, 0)))));
			attrTable.addCell(issuer);

			attrTable.addCell(new Phrase(18, new Chunk("Issue Date",
					FontFactory.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD,
							new Color(0, 0, 0)))));
			attrTable.addCell(new Date().toString());

			document.add(attrTable);

			if (note != null) {
				note = note.replace('\n', ' ');
				PdfPTable noteTable = new PdfPTable(1);
				noteTable.setTotalWidth(0);
				noteTable.getDefaultCell().setBorder(
						com.lowagie.text.Rectangle.NO_BORDER);

				document.add(Chunk.NEWLINE);

				noteTable.addCell(new Phrase(18, new Chunk("Note:", FontFactory
						.getFont(FontFactory.TIMES_ROMAN, 12))));
				noteTable.addCell("");
				noteTable.addCell(new Phrase(18, new Chunk(note, FontFactory
						.getFont(FontFactory.TIMES_ROMAN, 12))));

				document.add(noteTable);
			}
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
	 * @param cert the file path of the signing certificate
	 * @param password the passfrase to protect the certificate
	 * @param is the input stream of the document to be signed.
	 * @param cn the common name of the user
	 * @throws STPSException if the document couldn't be signed 
	 */

	public ByteArrayOutputStream signPDF(String cert, String password,
			InputStream is) throws STPSException {

		log.debug("Calling signPDF()...");
		ByteArrayOutputStream os = new ByteArrayOutputStream();

		try {
			KeyStore ks = KeyStore.getInstance("pkcs12");
			InputStream fis = null;
			try {
				fis = new FileInputStream(cert);
			} catch (FileNotFoundException e) {
				String msg = "Couldn't find the certificate: " + cert;
				log.error(msg);
				e.printStackTrace();
				throw new STPSException(msg);
			}

			ks.load(fis, password.toCharArray());

			String alias = (String) ks.aliases().nextElement();
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
			String msg = "Failed to sign the document. The error is: "
					+ e.getMessage();
			log.error(msg);
			e.printStackTrace();
			throw new STPSException(msg);
		}

		return os;
	}
}
