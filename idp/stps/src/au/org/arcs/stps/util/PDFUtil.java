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

	public OutputStream genPDF(String sourceIdP, String issuer,
			String sharedToken, String cn, String mail) throws STPSException,
			Exception {

		log.debug("Calling genPDF()...");

		ByteArrayOutputStream os = new ByteArrayOutputStream();

		try {

			Document document = new Document();

			PdfWriter.getInstance(document, os);

			document.open();

			Paragraph p = new Paragraph();
			p.setAlignment(1);
			p.setExtraParagraphSpace(5);
			p.add(new Chunk("SharedToken Statement", new Font(Font.TIMES_ROMAN,
					20)));

			try {
				document.add(p);
			} catch (DocumentException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			try {
				document.add(Chunk.NEWLINE);
			} catch (DocumentException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}

			PdfPTable table = new PdfPTable(2);

			table.addCell(new Phrase(18, new Chunk("auEduPersonSharedToken",
					FontFactory.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD,
							new Color(0, 0, 0)))));
			table.addCell(sharedToken);

			table.addCell(new Phrase(18, new Chunk("Common Name", FontFactory
					.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD, new Color(
							0, 0, 0)))));
			table.addCell(cn);

			table.addCell(new Phrase(18,
					new Chunk("Mail", FontFactory.getFont(
							FontFactory.TIMES_ROMAN, 14, Font.BOLD, new Color(
									0, 0, 0)))));
			table.addCell(mail);

			table.addCell(new Phrase(18, new Chunk("Source IdP", FontFactory
					.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD, new Color(
							0, 0, 0)))));
			table.addCell(sourceIdP);

			table.addCell(new Phrase(18, new Chunk("Issuer", FontFactory
					.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD, new Color(
							0, 0, 0)))));
			table.addCell(issuer);

			table.addCell(new Phrase(18, new Chunk("Issue Date", FontFactory
					.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD, new Color(
							0, 0, 0)))));
			table.addCell(new Date().toString());

			document.add(table);

			document.close();
		} catch (DocumentException e) {
			String msg = "Couldn't generate the PDF document. The reason is: "
					+ e.getMessage();
			log.warn(msg);
			throw new STPSException(msg);
		}

		return os;
	}

	public ByteArrayOutputStream signPDF(String cert, String password,
			InputStream is) throws STPSException{
		
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
				PrivateKey key = (PrivateKey) ks.getKey(alias, password.toCharArray());
				Certificate[] chain = ks.getCertificateChain(alias);

				PdfReader reader = new PdfReader(is);

				PdfStamper stp = PdfStamper.createSignature(reader, os, '\0');
				PdfSignatureAppearance sap = stp.getSignatureAppearance();
				sap.setCrypto(key, chain, null, PdfSignatureAppearance.WINCER_SIGNED);
				// comment next line to have an invisible signature
				sap.setVisibleSignature(new Rectangle(100, 100, 200, 200), 1, null);
				stp.close();
			} catch (Exception e) {
				String msg = "Failed to sign the document. The error is: " + e.getMessage();
				log.error(msg);
				e.printStackTrace();
				throw new STPSException(msg);
			} 

		return os;
	}
}
