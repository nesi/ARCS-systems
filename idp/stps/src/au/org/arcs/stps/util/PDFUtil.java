/**
 * 
 */
package au.org.arcs.stps.util;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.util.Date;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import com.lowagie.text.Chunk;
import com.lowagie.text.Document;
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

	public OutputStream genPDF(String entityID, String sharedToken,
			String cn, String mail) {
		ByteArrayOutputStream os = new ByteArrayOutputStream();
		try {
			System.out.println("calling genPDF()...");

			Document document = new Document();

			PdfWriter.getInstance(document, os);

			document.open();

			Paragraph p = new Paragraph();
			p.setAlignment(1);
			p.setExtraParagraphSpace(5);
			p.add(new Chunk("SharedToken Statement", new Font(Font.TIMES_ROMAN,
					20)));

			document.add(p);
			document.add(Chunk.NEWLINE);

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

			table.addCell(new Phrase(18, new Chunk("Issuer EntityID",
					FontFactory.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD,
							new Color(0, 0, 0)))));
			table.addCell(entityID);

			table.addCell(new Phrase(18, new Chunk("Issue Date", FontFactory
					.getFont(FontFactory.TIMES_ROMAN, 14, Font.BOLD, new Color(
							0, 0, 0)))));
			table.addCell(new Date().toString());

			document.add(table);

			document.close();

		} catch (Exception e) {
			e.printStackTrace();
		}

		return os;
	}

	public ByteArrayOutputStream signPDF(String cert, String password, InputStream is) {
		System.out.println("signing PDF document ...");
		ByteArrayOutputStream os = new ByteArrayOutputStream();
		try {
			KeyStore ks = KeyStore.getInstance("pkcs12");
			ks.load(new FileInputStream(cert), password.toCharArray());

			String alias = (String) ks.aliases().nextElement();
			PrivateKey key = (PrivateKey) ks.getKey(alias, password
					.toCharArray());
			Certificate[] chain = ks.getCertificateChain(alias);

			PdfReader reader = new PdfReader(is);

			PdfStamper stp = PdfStamper.createSignature(reader, os, '\0');
			PdfSignatureAppearance sap = stp.getSignatureAppearance();
			sap.setCrypto(key, chain, null,
					PdfSignatureAppearance.WINCER_SIGNED);
			// sap.setReason(reason);
			// comment next line to have an invisible signature
			sap.setVisibleSignature(new Rectangle(100, 100, 200, 200), 1, null);
			stp.close();

		} catch (Exception e) {
			e.printStackTrace();
		}
		return os;
	}
}
