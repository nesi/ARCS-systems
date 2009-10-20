/**
 * 
 */
package au.org.arcs.shibenv;

import java.sql.Timestamp;
import java.util.Date;
import java.util.Iterator;
import java.util.Map;
import java.util.Properties;
import java.util.ArrayList;
import java.util.StringTokenizer;
import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import org.apache.log4j.Logger;

/**
 * @author Damien Chen
 * 
 */
public class MailUtil {

	private static Logger log = Logger.getLogger(MailUtil.class.getName());

	private String smtpHost;

	private String smtpUsername;

	private String smtpPassword;

	private String to;

	private String from;

	private String cc;

	private String subject;

	private String realSubject;

	private static String MISSING_VALUE = "<b>missing</b>";

	public void sendMail(String entityID, Timestamp timestamp) throws Exception {

		// String time = timestamp.getTime() + "L";
		log.debug("start send mail");

		realSubject = subject.replace("{0}", entityID);

		String msgContent = "This email is to notifiy you that an attributes report has been submitted for "
				+ entityID
				+ ". \n \n You are able to check it by click on https://slcs2.arcs.org.au/shibenv/check.action?entityID="
				+ entityID
				+ "&"
				+ "timestamp="
				+ timestamp.getTime()
				+ "\n\n Note:   This message was generated automatically by Pilot AAF Attribute Release Conformance Check website.";

		send(msgContent);

	}

	public void sendMail(String entityID, Map<String, String> aafMap,
			Map<String, String> slcsMap, Map<String, String> rrMap,
			Map<String, String> otherMap, String imastAlg, String uniqueAttr,
			String porting, Timestamp timestamp) throws Exception {

		log.debug("start send mail");

		realSubject = subject.replace("{0}", entityID);

		String msgContent = "";

		String aafHeading = "AAF Mandatory Attributes";
		String slcsHeading = "SLCS Required Attributes";
		String rrHeading = "RR Required Attributes";
		String otherHeading = "Other Attributes ";

		msgContent = addAttrList(aafHeading, aafMap, msgContent);
		msgContent = addAgreement(imastAlg, uniqueAttr, porting, msgContent);
		msgContent = addAttrList(slcsHeading, slcsMap, msgContent);
		msgContent = addAttrList(rrHeading, rrMap, msgContent);
		msgContent = addAttrList(otherHeading, otherMap, msgContent);

		send(msgContent);

	}

	private String addAgreement(String imastAlg, String uniqueAttr,
			String porting, String msgContent) {
		msgContent = msgContent.concat("<br>");
		msgContent = msgContent
				.concat("auEduPersonSharedToken is generated using the IMAST default algorithm: "
						+ "<b>" + imastAlg + "</b>" + "<br>");
		msgContent = msgContent
				.concat("The local unique, persistent attribute used to generate aEPST is: "
						+ "<b>" + uniqueAttr + "</b>" + "<br>");
		msgContent = msgContent
				.concat("I understand the requirement for enabling porting aEPST if user changes IdP: "
						+ "<b>" + porting + "</b>" + "<br>");

		return msgContent;
	}

	private String addAttrList(String heading, Map attrMap, String msgContent) {
		msgContent = msgContent.concat("<h2>" + heading + "</h2>");
		msgContent = msgContent.concat("<br>");
		Iterator it = attrMap.keySet().iterator();
		while (it.hasNext()) {
			String key = (String) it.next();
			String value = (String) attrMap.get(key);

			if (value.equals("missing")) {
				msgContent = msgContent.concat("<b>" + key + ":  </b> "
						+ "<i> missing </i>");
			} else {
				msgContent = msgContent
						.concat("<b>" + key + ":  </b> " + "fine");
			}
			msgContent = msgContent.concat("<br>");
		}
		return msgContent;

	}

	private void send(String msgContent) throws Exception {
		try {
			boolean sessionDebug = false;

			ArrayList<String> arrayTo = new ArrayList<String>();
			StringTokenizer stTo = new StringTokenizer(to, ",");
			while (stTo.hasMoreTokens())
				arrayTo.add(stTo.nextToken());
			int sizeTo = arrayTo.size();
			InternetAddress[] addressTo = new InternetAddress[sizeTo];
			for (int i = 0; i < sizeTo; i++) {
				log.debug("to : " + arrayTo.get(i).toString());
				addressTo[i] = new InternetAddress(arrayTo.get(i).toString());
			}

			ArrayList<String> arrayCc = new ArrayList<String>();
			StringTokenizer stCc = new StringTokenizer(cc, ",");
			while (stCc.hasMoreTokens())
				arrayCc.add(stCc.nextToken());
			int sizeCc = arrayCc.size();
			InternetAddress[] addressCc = new InternetAddress[sizeCc];
			for (int i = 0; i < sizeCc; i++) {
				log.debug("cc : " + arrayCc.get(i).toString());
				addressCc[i] = new InternetAddress(arrayCc.get(i).toString());
			}

			Properties props = System.getProperties();
			props.put("mail.host", smtpHost);
			props.put("mail.transport.protocol", "smtp");
			props.put("mail.smtp.starttls.enable", "true");
			props.put("mail.smtp.auth", "true");

			Authenticator auth = new SMTPAuthenticator();
			Session session = Session.getDefaultInstance(props, auth);
			// Session session = Session.getDefaultInstance(props, null);
			session.setDebug(sessionDebug);
			try {
				// Instantiate a new MimeMessage and fill it with the
				// required information.
				Message msg = new MimeMessage(session);
				msg.setFrom(new InternetAddress(from));

				msg.setRecipients(Message.RecipientType.TO, addressTo);
				msg.setRecipients(Message.RecipientType.CC, addressCc);

				msg.setSubject(realSubject);
				msg.setSentDate(new Date());
				msg.setContent(msgContent, "text/html");
				// Hand the message to the default transport service
				// for delivery.
				Transport.send(msg);
				log.debug("notification email has been sent.");
			} catch (MessagingException mex) {
				throw new Exception(mex.getMessage());
			}
		} catch (Exception e) {
			throw new Exception(e.getMessage()
					+ " \n Failed to send notification email.");

		}

	}

	private class SMTPAuthenticator extends javax.mail.Authenticator {
		public PasswordAuthentication getPasswordAuthentication() {
			return new PasswordAuthentication(smtpUsername, smtpPassword);
		}
	}

	/**
	 * @return the cc
	 */
	public String getCc() {
		return cc;
	}

	/**
	 * @param cc
	 *            the cc to set
	 */
	public void setCc(String cc) {
		this.cc = cc;
	}

	/**
	 * @return the from
	 */
	public String getFrom() {
		return from;
	}

	/**
	 * @param from
	 *            the from to set
	 */
	public void setFrom(String from) {
		this.from = from;
	}

	/**
	 * @return the subject
	 */
	public String getSubject() {
		return subject;
	}

	/**
	 * @param subject
	 *            the subject to set
	 */
	public void setSubject(String subject) {
		this.subject = subject;
	}

	/**
	 * @return the to
	 */
	public String getTo() {
		return to;
	}

	/**
	 * @param to
	 *            the to to set
	 */
	public void setTo(String to) {
		this.to = to;
	}

	/**
	 * @return the smtpHost
	 */
	public String getSmtpHost() {
		return smtpHost;
	}

	/**
	 * @param smtpHost
	 *            the smtpHost to set
	 */
	public void setSmtpHost(String smtpHost) {
		this.smtpHost = smtpHost;
	}

	/**
	 * @return the smtpPassword
	 */
	public String getSmtpPassword() {
		return smtpPassword;
	}

	/**
	 * @param smtpPassword
	 *            the smtpPassword to set
	 */
	public void setSmtpPassword(String smtpPassword) {
		this.smtpPassword = smtpPassword;
	}

	/**
	 * @return the smtpUsername
	 */
	public String getSmtpUsername() {
		return smtpUsername;
	}

	/**
	 * @param smtpUsername
	 *            the smtpUsername to set
	 */
	public void setSmtpUsername(String smtpUsername) {
		this.smtpUsername = smtpUsername;
	}

}
