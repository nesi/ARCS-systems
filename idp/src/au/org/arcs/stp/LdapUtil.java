/**
 * 
 */
package au.org.arcs.stp;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Hashtable;
import java.util.Map;
import java.util.Set;

import javax.naming.Context;
import javax.naming.NamingEnumeration;
import javax.naming.directory.Attributes;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.SearchControls;
import javax.naming.directory.SearchResult;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import au.org.arcs.stp.test.Test;

/**
 * @author Damien Chen
 * 
 */
public class LdapUtil {

	private static Log log = LogFactory.getLog(Test.class);

	private static String TRUST_STORE = "javax.net.ssl.trustStore";

	private String ldapURL;

	private String baseDN;

	private String principal;

	private String principalCredential;

	private String searchFilter;

	private String attributes;

	private String keyStore;

	private DirContext dirContext;
	

	/**
	 * @param protocol
	 * @param host
	 * @param port
	 * @param bindDN
	 * @param bindPassword
	 * @param userSearchBase
	 * @param userSearchFilter
	 * @param attributes
	 * @param keyStore
	 * @param dirContext
	 */
	public LdapUtil(String ldapURL, String principal, String principalCredential, String baseDN, String searchFilter, String attributes, String keyStore) {
		super();
		this.ldapURL = ldapURL;
		this.principal = principal;
		this.principalCredential = principalCredential;
		this.baseDN = baseDN;
		this.searchFilter = searchFilter;
		this.attributes = attributes;
		this.keyStore = keyStore;
	
		this.createDirContext();
	}

	private void createDirContext() {

		try {
			System.out.println("creating DirContext ...");
			// The search order of JSSE for locating the default trustStore file
			// is:
			// 1) The file specified by javax.net.ssl.trustStore
			// 2) <java-home>/lib/security/jssecacerts, then
			// 3) <java-home>/lib/security/cacerts.
			if (keyStore != null && !keyStore.equals(""))
				System.setProperty(TRUST_STORE, keyStore);
			String providerUrl = ldapURL + "/";
			Hashtable<String, String> env = new Hashtable<String, String>(11);
			env.put(Context.INITIAL_CONTEXT_FACTORY,
					"com.sun.jndi.ldap.LdapCtxFactory");
			env.put(Context.PROVIDER_URL, providerUrl);
			env.put(Context.SECURITY_AUTHENTICATION, "simple");
			env.put(Context.SECURITY_PRINCIPAL, principal);
			env.put(Context.SECURITY_CREDENTIALS, principalCredential);
			dirContext = new InitialDirContext(env);

		} catch (Exception e) {
			e.printStackTrace();
		}
	}

	public Map<String, Set> getUserAttributes(String userName) throws Exception {
		
		System.out.println("searching LDAP ...");

		Map<String, Set> attrMap = new HashMap<String, Set>();
		if (attributes == null || attributes.equals("")) {
			log.warn("no attributes need to retrieve");
			return attrMap;
		}
		if (baseDN == null || "".equals(baseDN))
			throw new Exception("can not find baseDN");

		if (searchFilter == null || "".equals(searchFilter))
			throw new Exception("can not find searchFilter");

		String[] attrs = attributes.split(",");
		searchFilter = searchFilter.replaceFirst("\\{0}", userName);
		return this.search(searchFilter, baseDN, attrs);
	}

	private Map<String, Set> search(String filter, String base, String[] attrs) {
		Map<String, Set> attrMap = new HashMap<String, Set>();
		try {
			SearchControls controls = new SearchControls();
			controls.setReturningAttributes(attrs);
			controls.setSearchScope(SearchControls.SUBTREE_SCOPE);
			NamingEnumeration results = dirContext.search(base, filter,
					controls);
			while (results.hasMore()) {
				SearchResult searchResult = (SearchResult) results.next();
				Attributes attributes = searchResult.getAttributes();
				NamingEnumeration<String> ne = attributes.getIDs();

				while (ne.hasMoreElements()) {
					String id = ne.next();
					NamingEnumeration ne2 = attributes.get(id).getAll();
					Set<String> values = new HashSet<String>();
					while (ne2.hasMoreElements()) {
						values.add((String) ne2.nextElement());
					}
					attrMap.put(id, values);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return attrMap;

	}

}
