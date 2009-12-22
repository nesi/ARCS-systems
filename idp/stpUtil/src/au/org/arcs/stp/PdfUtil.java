/**
 * 
 */
package au.org.arcs.stp;

import java.awt.Color;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
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
public class PdfUtil {

	public void genPDF(Map<String, Set<String>> attrMap, String originalPDFDir,
			String uid, String entityID) {

		try {
			System.out.println("generating PDF document ...");

			String sharedToken = setToString(attrMap
					.get("auEduPersonSharedToken"));
			String cn = setToString(attrMap.get("cn"));
			String filePath = originalPDFDir + "/" + uid + ".pdf";
			OutputStream file = new FileOutputStream(new File(filePath));
			Document document = new Document();
			PdfWriter.getInstance(document, file);
			document.open();
			
			Paragraph p = new Paragraph();
			p.setAlignment(1);
			p.setExtraParagraphSpace(5);
			p.add(new Chunk("SharedToken Statement", new Font(Font.TIMES_ROMAN, 20)));
			

			document.add(p);
			document.add(Chunk.NEWLINE);
		
			PdfPTable table = new PdfPTable(2);
			
			table.addCell(new Phrase(18, new Chunk("auEduPersonSharedToken", FontFactory.getFont(FontFactory.TIMES_ROMAN,
					 14, Font.BOLD, new Color(0, 0, 0)))));
			table.addCell(sharedToken);

			table.addCell(new Phrase(18, new Chunk("UID", FontFactory.getFont(FontFactory.TIMES_ROMAN,
					 14, Font.BOLD, new Color(0, 0, 0)))));
			table.addCell(uid);

			table.addCell(new Phrase(18, new Chunk("Common Name", FontFactory.getFont(FontFactory.TIMES_ROMAN,
					 14, Font.BOLD, new Color(0, 0, 0)))));
			table.addCell(cn);
			
			table.addCell(new Phrase(18, new Chunk("Issuer EntityID", FontFactory.getFont(FontFactory.TIMES_ROMAN,
					 14, Font.BOLD, new Color(0, 0, 0)))));
			table.addCell(entityID);

			table.addCell(new Phrase(18, new Chunk("Issue Date", FontFactory.getFont(FontFactory.TIMES_ROMAN,
					 14, Font.BOLD, new Color(0, 0, 0)))));
			table.addCell(new Date().toString());
			
			
			document.add(table);
			document.close();
			file.close();
			System.out.println("generated document: " + filePath);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	private String setToString(Set<String> set) {
		Iterator<String> it = set.iterator();
		String str = "";
		while (it.hasNext()) {
			str = str + it.next() + " ";
		}
		str.trim();
		System.out.println(str);
		return str;
	}

	public void sign(String cert, String password,
			String location, String uid, String originalPDFDir,
			String signedPDFDir) {
		try {
			System.out.println("signing PDF document ...");
			KeyStore ks = KeyStore.getInstance("pkcs12");
			ks.load(new FileInputStream(cert), password.toCharArray());

			String alias = (String) ks.aliases().nextElement();
			PrivateKey key = (PrivateKey) ks.getKey(alias, password
					.toCharArray());
			Certificate[] chain = ks.getCertificateChain(alias);

			PdfReader reader = new PdfReader(originalPDFDir + "/" + uid
					+ ".pdf");
			String filePath = signedPDFDir + "/" + uid + "-signed" + ".pdf";
			FileOutputStream fout = new FileOutputStream(filePath);
			PdfStamper stp = PdfStamper.createSignature(reader, fout, '\0');
			PdfSignatureAppearance sap = stp.getSignatureAppearance();
			sap.setCrypto(key, chain, null,
					PdfSignatureAppearance.WINCER_SIGNED);
			//sap.setReason(reason);
			sap.setLocation(location);
			// comment next line to have an invisible signature
			sap.setVisibleSignature(new Rectangle(100, 100, 200, 200), 1, null);
			stp.close();
			System.out.println("signed document: " + filePath);

		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
