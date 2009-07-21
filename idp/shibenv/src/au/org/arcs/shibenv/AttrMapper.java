/**
 * 
 */
package au.org.arcs.shibenv;

import java.io.Serializable;

/**
 * @author Damien Chen
 * 
 */
public class AttrMapper implements Serializable {

	private static final long serialVersionUID = 2669574660101300456L;

	private String providerID;

	private String authenticationMethod;

	private String o;

	private String eduPersonAssurance;

	private String auEduPersonSharedToken;

	private String eduPersonTargetedID;

	private String cn;

	private String displayName;

	private String mail;

	private String eduPersonAffiliation;

	private String eduPersonScopedAffiliation;

	private String eduPersonEntitlement;

	private String l;

	private String homeOrganization;

	private String homeOrganizationType;

	/**
	 * @return the auEduPersonSharedToken
	 */
	public String getAuEduPersonSharedToken() {
		return auEduPersonSharedToken;
	}

	/**
	 * @param auEduPersonSharedToken
	 *            the auEduPersonSharedToken to set
	 */
	public void setAuEduPersonSharedToken(String auEduPersonSharedToken) {
		this.auEduPersonSharedToken = auEduPersonSharedToken;
	}



	/**
	 * @return the authenticationMethod
	 */
	public String getAuthenticationMethod() {
		return authenticationMethod;
	}

	/**
	 * @param authenticationMethod the authenticationMethod to set
	 */
	public void setAuthenticationMethod(String authenticationMethod) {
		this.authenticationMethod = authenticationMethod;
	}

	/**
	 * @return the cn
	 */
	public String getCn() {
		return cn;
	}

	/**
	 * @param cn
	 *            the cn to set
	 */
	public void setCn(String cn) {
		this.cn = cn;
	}

	/**
	 * @return the displayName
	 */
	public String getDisplayName() {
		return displayName;
	}

	/**
	 * @param displayName
	 *            the displayName to set
	 */
	public void setDisplayName(String displayName) {
		this.displayName = displayName;
	}

	/**
	 * @return the eduPersonAffiliation
	 */
	public String getEduPersonAffiliation() {
		return eduPersonAffiliation;
	}

	/**
	 * @param eduPersonAffiliation
	 *            the eduPersonAffiliation to set
	 */
	public void setEduPersonAffiliation(String eduPersonAffiliation) {
		this.eduPersonAffiliation = eduPersonAffiliation;
	}

	/**
	 * @return the eduPersonAssurance
	 */
	public String getEduPersonAssurance() {
		return eduPersonAssurance;
	}

	/**
	 * @param eduPersonAssurance
	 *            the eduPersonAssurance to set
	 */
	public void setEduPersonAssurance(String eduPersonAssurance) {
		this.eduPersonAssurance = eduPersonAssurance;
	}

	/**
	 * @return the eduPersonEntitlement
	 */
	public String getEduPersonEntitlement() {
		return eduPersonEntitlement;
	}

	/**
	 * @param eduPersonEntitlement
	 *            the eduPersonEntitlement to set
	 */
	public void setEduPersonEntitlement(String eduPersonEntitlement) {
		this.eduPersonEntitlement = eduPersonEntitlement;
	}

	/**
	 * @return the eduPersonScopedAffiliation
	 */
	public String getEduPersonScopedAffiliation() {
		return eduPersonScopedAffiliation;
	}

	/**
	 * @param eduPersonScopedAffiliation
	 *            the eduPersonScopedAffiliation to set
	 */
	public void setEduPersonScopedAffiliation(String eduPersonScopedAffiliation) {
		this.eduPersonScopedAffiliation = eduPersonScopedAffiliation;
	}

	/**
	 * @return the eduPersonTargetedID
	 */
	public String getEduPersonTargetedID() {
		return eduPersonTargetedID;
	}

	/**
	 * @param eduPersonTargetedID
	 *            the eduPersonTargetedID to set
	 */
	public void setEduPersonTargetedID(String eduPersonTargetedID) {
		this.eduPersonTargetedID = eduPersonTargetedID;
	}

	/**
	 * @return the homeOrganization
	 */
	public String getHomeOrganization() {
		return homeOrganization;
	}

	/**
	 * @param homeOrganization
	 *            the homeOrganization to set
	 */
	public void setHomeOrganization(String homeOrganization) {
		this.homeOrganization = homeOrganization;
	}

	/**
	 * @return the homeOrganizationType
	 */
	public String getHomeOrganizationType() {
		return homeOrganizationType;
	}

	/**
	 * @param homeOrganizationType
	 *            the homeOrganizationType to set
	 */
	public void setHomeOrganizationType(String homeOrganizationType) {
		this.homeOrganizationType = homeOrganizationType;
	}

	/**
	 * @return the l
	 */
	public String getL() {
		return l;
	}

	/**
	 * @param l
	 *            the l to set
	 */
	public void setL(String l) {
		this.l = l;
	}

	/**
	 * @return the mail
	 */
	public String getMail() {
		return mail;
	}

	/**
	 * @param mail
	 *            the mail to set
	 */
	public void setMail(String mail) {
		this.mail = mail;
	}

	/**
	 * @return the o
	 */
	public String getO() {
		return o;
	}

	/**
	 * @param o
	 *            the o to set
	 */
	public void setO(String o) {
		this.o = o;
	}

	/**
	 * @return the providerID
	 */
	public String getProviderID() {
		return providerID;
	}

	/**
	 * @param providerID the providerID to set
	 */
	public void setProviderID(String providerID) {
		this.providerID = providerID;
	}

}
