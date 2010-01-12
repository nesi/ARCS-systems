/**
 * 
 */
package au.org.arcs.stps;

/**
 * @author Damien Chen
 *
 */
public class StatementBean {
	
	private String sharedToken;
	private String subject;
	private String issuer;
	private String recipient;
	private String issuedOn;
	private String expiresOn;
	private String statementID;
	private String referenceNo;
	/**
	 * @return the expiresOn
	 */
	public String getExpiresOn() {
		return expiresOn;
	}
	/**
	 * @param expiresOn the expiresOn to set
	 */
	public void setExpiresOn(String expiresOn) {
		this.expiresOn = expiresOn;
	}
	/**
	 * @return the issuedOn
	 */
	public String getIssuedOn() {
		return issuedOn;
	}
	/**
	 * @param issuedOn the issuedOn to set
	 */
	public void setIssuedOn(String issuedOn) {
		this.issuedOn = issuedOn;
	}
	/**
	 * @return the issuer
	 */
	public String getIssuer() {
		return issuer;
	}
	/**
	 * @param issuer the issuer to set
	 */
	public void setIssuer(String issuer) {
		this.issuer = issuer;
	}
	/**
	 * @return the recipient
	 */
	public String getRecipient() {
		return recipient;
	}
	/**
	 * @param recipient the recipient to set
	 */
	public void setRecipient(String recipient) {
		this.recipient = recipient;
	}
	/**
	 * @return the referenceNo
	 */
	public String getReferenceNo() {
		return referenceNo;
	}
	/**
	 * @param referenceNo the referenceNo to set
	 */
	public void setReferenceNo(String referenceNo) {
		this.referenceNo = referenceNo;
	}
	/**
	 * @return the sharedToken
	 */
	public String getSharedToken() {
		return sharedToken;
	}
	/**
	 * @param sharedToken the sharedToken to set
	 */
	public void setSharedToken(String sharedToken) {
		this.sharedToken = sharedToken;
	}
	/**
	 * @return the statementID
	 */
	public String getStatementID() {
		return statementID;
	}
	/**
	 * @param statementID the statementID to set
	 */
	public void setStatementID(String statementID) {
		this.statementID = statementID;
	}
	/**
	 * @return the subject
	 */
	public String getSubject() {
		return subject;
	}
	/**
	 * @param subject the subject to set
	 */
	public void setSubject(String subject) {
		this.subject = subject;
	}

}
