/**
 * 
 */
package au.org.arcs.shibenv.action;

import java.util.Enumeration;
import java.util.LinkedHashMap;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.apache.struts2.ServletActionContext;

import com.opensymphony.xwork2.ActionSupport;

import au.org.arcs.shibenv.AttrMapper;
import au.org.arcs.shibenv.Constants;

/**
 * @author Damien Chen
 * 
 */
public class ViewAction extends ActionSupport {

	private static Logger log = Logger.getLogger(ViewAction.class.getName());

	private static final long serialVersionUID = -7917429343871547586L;

	private LinkedHashMap<String, String> aafMap;

	private LinkedHashMap<String, String> aafMap1;

	private LinkedHashMap<String, String> aafMap2;

	private LinkedHashMap<String, String> slcsMap;

	private LinkedHashMap<String, String> rrMap;

	private LinkedHashMap<String, String> otherMap;

	private static String MISSING_VALUE = "missing";

	private AttrMapper mapper;

	/*
	 * (non-Javadoc)
	 * 
	 * @see com.opensymphony.xwork2.ActionSupport#execute()
	 */
	@Override
	public String execute() throws Exception {
		// TODO Auto-generated method stub

		HttpServletRequest request = ServletActionContext.getRequest();
		HttpSession session = request.getSession();

		aafMap = new LinkedHashMap<String, String>();
		aafMap1 = new LinkedHashMap<String, String>();
		aafMap2 = new LinkedHashMap<String, String>();
		slcsMap = new LinkedHashMap<String, String>();
		rrMap = new LinkedHashMap<String, String>();
		otherMap = new LinkedHashMap<String, String>();

		try {

			String entityID = request.getHeader(mapper.getProviderID());

			if (entityID != null && !entityID.equals("")) {
				aafMap.put("Shib-Identity-Provider", entityID);
				aafMap1.put("Shib-Identity-Provider", entityID);
			} else {
				aafMap.put("Shib-Identity-Provider", MISSING_VALUE);
				aafMap1.put("Shib-Identity-Provider", MISSING_VALUE);
			}

			String authenticationMethod = request.getHeader(mapper
					.getAuthenticationMethod());
			if (authenticationMethod != null
					&& !authenticationMethod.equals("")) {
				aafMap.put("AuthenticationMethod", authenticationMethod);
				aafMap1.put("AuthenticationMethod", authenticationMethod);
			} else {
				aafMap.put("AuthenticationMethod", MISSING_VALUE);
				aafMap1.put("AuthenticationMethod", MISSING_VALUE);
			}

			String o = request.getHeader(mapper.getO());
			if (o != null && !o.equals("")) {
				aafMap.put("o", o);
				aafMap1.put("o", o);
				slcsMap.put("o", o);
			} else {
				aafMap.put("o", MISSING_VALUE);
				aafMap1.put("o", MISSING_VALUE);
				slcsMap.put("o", MISSING_VALUE);
			}

			String eduPersonAssurance = request.getHeader(mapper
					.getEduPersonAssurance());
			if (eduPersonAssurance != null && !eduPersonAssurance.equals("")) {
				aafMap.put("eduPersonAssurance", eduPersonAssurance);
				aafMap2.put("eduPersonAssurance", eduPersonAssurance);
				slcsMap.put("eduPersonAssurance", eduPersonAssurance);
			} else {
				aafMap.put("eduPersonAssurance", MISSING_VALUE);
				aafMap2.put("eduPersonAssurance", MISSING_VALUE);
				slcsMap.put("eduPersonAssurance", MISSING_VALUE);
			}

			String auEduPersonSharedToken = request.getHeader(mapper
					.getAuEduPersonSharedToken());
			if (auEduPersonSharedToken != null
					&& !auEduPersonSharedToken.equals("")) {
				aafMap.put("auEduPersonSharedToken", auEduPersonSharedToken);
				aafMap2.put("auEduPersonSharedToken", auEduPersonSharedToken);
				slcsMap.put("auEduPersonSharedToken", auEduPersonSharedToken);
			} else {
				aafMap.put("auEduPersonSharedToken", MISSING_VALUE);
				aafMap2.put("auEduPersonSharedToken", MISSING_VALUE);
				slcsMap.put("auEduPersonSharedToken", auEduPersonSharedToken);
			}

			String eduPersonTargetedID = request.getHeader(mapper
					.getEduPersonTargetedID());
			if (eduPersonTargetedID != null && !eduPersonTargetedID.equals("")) {
				aafMap.put("eduPersonTargetedID", eduPersonTargetedID);
				aafMap2.put("eduPersonTargetedID", eduPersonTargetedID);
				rrMap.put("eduPersonTargetedID", eduPersonTargetedID);
			} else {
				aafMap.put("eduPersonTargetedID", MISSING_VALUE);
				aafMap2.put("eduPersonTargetedID", MISSING_VALUE);
				rrMap.put("eduPersonTargetedID", MISSING_VALUE);
			}

			String cn = request.getHeader(mapper.getCn());
			if (cn != null && !cn.equals("")) {
				aafMap.put("cn", cn);
				aafMap2.put("cn", cn);
				slcsMap.put("cn", cn);
			} else {
				aafMap.put("cn", MISSING_VALUE);
				aafMap2.put("cn", MISSING_VALUE);
				slcsMap.put("cn", MISSING_VALUE);
			}

			String displayName = request.getHeader(mapper.getDisplayName());
			if (displayName != null && !displayName.equals("")) {
				aafMap.put("displayName", displayName);
				aafMap2.put("displayName", displayName);
			} else {
				aafMap.put("displayName", MISSING_VALUE);
				aafMap2.put("displayName", MISSING_VALUE);
			}

			String mail = request.getHeader(mapper.getMail());
			if (mail != null && !mail.equals("")) {
				aafMap.put("mail", mail);
				aafMap2.put("mail", mail);
				slcsMap.put("mail", mail);
				rrMap.put("mail", mail);
			} else {
				aafMap.put("mail", MISSING_VALUE);
				aafMap2.put("mail", MISSING_VALUE);
				slcsMap.put("mail", MISSING_VALUE);
				rrMap.put("mail", mail);
			}

			String eduPersonAffiliation = request.getHeader(mapper
					.getEduPersonAffiliation());
			if (eduPersonAffiliation != null
					&& !eduPersonAffiliation.equals("")) {
				aafMap.put("eduPersonAffiliation", eduPersonAffiliation);
				aafMap2.put("eduPersonAffiliation", eduPersonAffiliation);
			} else {
				aafMap.put("eduPersonAffiliation", MISSING_VALUE);
				aafMap2.put("eduPersonAffiliation", MISSING_VALUE);
			}

			String eduPersonScopedAffiliation = request.getHeader(mapper
					.getEduPersonScopedAffiliation());
			if (eduPersonScopedAffiliation != null
					&& !eduPersonScopedAffiliation.equals("")) {
				aafMap.put("eduPersonScopedAffiliation",
						eduPersonScopedAffiliation);
				aafMap2.put("eduPersonScopedAffiliation",
						eduPersonScopedAffiliation);
			} else {
				aafMap.put("eduPersonScopedAffiliation", MISSING_VALUE);
				aafMap2.put("eduPersonScopedAffiliation", MISSING_VALUE);
			}

			String eduPersonEntitlement = request.getHeader(mapper
					.getEduPersonEntitlement());
			if (eduPersonEntitlement != null
					&& !eduPersonEntitlement.equals("")) {
				aafMap.put("eduPersonEntitlement", eduPersonEntitlement);
				aafMap2.put("eduPersonEntitlement", eduPersonEntitlement);
			} else {
				aafMap.put("eduPersonEntitlement", MISSING_VALUE);
				aafMap2.put("eduPersonEntitlement", MISSING_VALUE);
			}

			String l = request.getHeader(mapper.getL());
			if (l != null && !l.equals("")) {
				slcsMap.put("l", l);
			} else {
				slcsMap.put("l", MISSING_VALUE);
			}

			String homeOrganization = request.getHeader(mapper
					.getHomeOrganization());
			if (homeOrganization != null && !homeOrganization.equals("")) {
				rrMap.put("homeOrganization", homeOrganization);
			} else {
				rrMap.put("homeOrganization", MISSING_VALUE);
			}

			String homeOrganizationType = request.getHeader(mapper
					.getHomeOrganizationType());
			if (homeOrganizationType != null
					&& !homeOrganizationType.equals("")) {
				rrMap.put("homeOrganizationType", homeOrganizationType);
			} else {
				rrMap.put("homeOrganizationType", MISSING_VALUE);
			}

			for (Enumeration e = request.getHeaderNames(); e.hasMoreElements();) {
				String key = (String) e.nextElement();
				String value = request.getHeader(key);

				if (!key.equals(mapper.getAuEduPersonSharedToken())
						&& !key.equals(mapper.getProviderID())
						&& !key.equals(mapper.getDisplayName())
						&& !key.equals(mapper.getEduPersonAffiliation())
						&& !key.equals(mapper.getEduPersonEntitlement())
						&& !key.equals(mapper.getEduPersonScopedAffiliation())
						&& !key.equals(mapper.getEduPersonTargetedID())
						&& !key.equals(mapper.getAuthenticationMethod())
						&& !key.equals(mapper.getCn()) && !key.equals(mapper.getO())
						&& !key.equals(mapper.getMail())
						&& !key.equals(mapper.getEduPersonAssurance())
						&& !key.equals(mapper.getL()) && !key.equals(mapper.getHomeOrganization())
						&& !key.equals(mapper.getHomeOrganizationType())
						&& !key.equals("cookie") && !value.equals("")) {
					otherMap.put(key, value);
				}

				// System.out.println(key);
				// System.out.println(value);
				// System.out.println("====================================");
			}

			session.setAttribute(Constants.ATTR_AAF, aafMap);
			session.setAttribute(Constants.ATTR_SLCS, slcsMap);
			session.setAttribute(Constants.ATTR_RR, rrMap);
			session.setAttribute(Constants.ATTR_OTHER, otherMap);
			session.setAttribute(Constants.ENTITY_ID, entityID);

		} catch (Exception e) {
			log.debug(e.getMessage());
		}

		return SUCCESS;
	}

	/**
	 * @return the aafMap
	 */
	public LinkedHashMap<String, String> getAafMap() {
		return aafMap;
	}

	/**
	 * @param aafMap
	 *            the aafMap to set
	 */
	public void setAafMap(LinkedHashMap<String, String> aafMap) {
		this.aafMap = aafMap;
	}

	/**
	 * @return the rrMap
	 */
	public LinkedHashMap<String, String> getRrMap() {
		return rrMap;
	}

	/**
	 * @param rrMap
	 *            the rrMap to set
	 */
	public void setRrMap(LinkedHashMap<String, String> rrMap) {
		this.rrMap = rrMap;
	}

	/**
	 * @return the slcsMap
	 */
	public LinkedHashMap<String, String> getSlcsMap() {
		return slcsMap;
	}

	/**
	 * @param slcsMap
	 *            the slcsMap to set
	 */
	public void setSlcsMap(LinkedHashMap<String, String> slcsMap) {
		this.slcsMap = slcsMap;
	}

	/**
	 * @return the otherMap
	 */
	public LinkedHashMap<String, String> getOtherMap() {
		return otherMap;
	}

	/**
	 * @param otherMap
	 *            the otherMap to set
	 */
	public void setOtherMap(LinkedHashMap<String, String> otherMap) {
		this.otherMap = otherMap;
	}

	/**
	 * @return the aafMap1
	 */
	public LinkedHashMap<String, String> getAafMap1() {
		return aafMap1;
	}

	/**
	 * @param aafMap1
	 *            the aafMap1 to set
	 */
	public void setAafMap1(LinkedHashMap<String, String> aafMap1) {
		this.aafMap1 = aafMap1;
	}

	/**
	 * @return the aafMap2
	 */
	public LinkedHashMap<String, String> getAafMap2() {
		return aafMap2;
	}

	/**
	 * @param aafMap2
	 *            the aafMap2 to set
	 */
	public void setAafMap2(LinkedHashMap<String, String> aafMap2) {
		this.aafMap2 = aafMap2;
	}

	/**
	 * @return the mapper
	 */
	public AttrMapper getMapper() {
		return mapper;
	}

	/**
	 * @param mapper
	 *            the mapper to set
	 */
	public void setMapper(AttrMapper mapper) {
		this.mapper = mapper;
	}

}
