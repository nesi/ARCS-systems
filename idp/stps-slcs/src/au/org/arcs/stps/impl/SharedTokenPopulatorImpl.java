/**
 * 
 */
package au.org.arcs.stps.impl;

import java.security.SecureRandom;

import java.util.Properties;

import javax.naming.Context;
import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.BasicAttribute;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.ModificationItem;
import javax.naming.ldap.InitialLdapContext;
import javax.naming.ldap.LdapContext;
import javax.naming.ldap.StartTlsRequest;
import javax.naming.ldap.StartTlsResponse;
import javax.net.ssl.KeyManager;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import au.org.arcs.stps.service.SharedTokenPopulator;

/**
 * @author Damien Chen
 * 
 */
public class SharedTokenPopulatorImpl implements SharedTokenPopulator {

	/** Class logger. */
	private final Logger log = LoggerFactory
			.getLogger(SharedTokenPopulatorImpl.class);

	private String searchFilterSpec;

	private String useStartTLS;

	private String ldapUrl;

	private String baseDN;

	private String principal;

	private String credentials;

	public void init() {

		searchFilterSpec = "uid={0}";
		useStartTLS = "false";
		ldapUrl = "ldap://arcs-ca.ramp.org.au";
		baseDN = "ou=people,dc=arcs,dc=org,dc=au";
		principal = "uid=binduser,ou=people,dc=arcs,dc=org,dc=au";
		credentials = "test";
	}

	public void populate(String attributeName, String attributeValue,
			String principalName) throws Exception {

		log.info("storing sharedToken to Ldap ...");

		log.info("attributeName: " + attributeName);
		log.info("attributeValue: " + attributeValue);
		log.info("principalName " + principalName);

		try {

			InitialDirContext context = initConnection();

			String searchFilter = searchFilterSpec
					.replace("{0}", principalName);

			Attribute mod0 = new BasicAttribute(attributeName, attributeValue);
			ModificationItem[] mods = new ModificationItem[1];

			log.info("adding sharedToken to ldap entry");

			// mods[0] = new ModificationItem(DirContext.ADD_ATTRIBUTE, mod0);
			mods[0] = new ModificationItem(DirContext.REPLACE_ATTRIBUTE, mod0);
			try {
				context.modifyAttributes(searchFilter, mods);
				log.info("replace successfully");
			} catch (NamingException e) {
				e.printStackTrace();
				log.error(" failed to replace sharedToken to ldap entry");
				throw new Exception(e.getMessage());
				// mods[0] = new ModificationItem(DirContext.REPLACE_ATTRIBUTE,
				// mod0);
				// dirContext.modifyAttributes(populatedSearch, mods);
			}
		} catch (Exception e) {
			log.error(e.getMessage().concat(
					"\n failed to add sharedToken to ldap entry"));
			e.printStackTrace();
			throw new Exception(e.getMessage());

		}

	}

	private InitialDirContext initConnection() throws Exception {

		log.info("calling initConnection() ...");
		// this.init();
		Properties properties = new Properties();

		String providerUrl = ldapUrl + "/" + baseDN;

		boolean boolUseStartTLS = useStartTLS.trim().equals("true") ? true
				: false;
		properties.put(Context.INITIAL_CONTEXT_FACTORY,
				"com.sun.jndi.ldap.LdapCtxFactory");
		properties.put(Context.PROVIDER_URL, providerUrl);
		properties.put(Context.SECURITY_AUTHENTICATION, "SIMPLE");
		properties.put(Context.SECURITY_PRINCIPAL, principal);
		properties.put(Context.SECURITY_CREDENTIALS, credentials);
		// properties.put("useStartTLS", useStartTLS);

		InitialDirContext context = null;
		SSLSocketFactory sslsf;
		boolean useExternalAuth = false;

		try {

			if (boolUseStartTLS) {
				log.info("useStartTLS is true");
				if ("EXTERNAL".equals(properties
						.getProperty(Context.SECURITY_AUTHENTICATION))) {
					log.info("use EXTERNAL authentication");
					useExternalAuth = true;
					properties.remove(Context.SECURITY_AUTHENTICATION);
				}
				log
						.info("setting SECURITY_AUTHENTICATION to NONE before starting TLS");

				String backupAuthType = properties
						.getProperty(Context.SECURITY_AUTHENTICATION);
				properties.setProperty(Context.SECURITY_AUTHENTICATION, "NONE");

				log.info("initiating ldap context without bind: "
						+ properties.toString());
				context = new InitialLdapContext(properties, null);

				log.info("creating tls context ...");
				SSLContext sslc;
				sslc = SSLContext.getInstance("TLS");
				sslc.init(new KeyManager[] { null }, null, new SecureRandom());
				sslsf = sslc.getSocketFactory();

				StartTlsResponse tls = (StartTlsResponse) ((LdapContext) context)
						.extendedOperation(new StartTlsRequest());
				log.info("tls negotiating ...");
				tls.negotiate(sslsf);
				log.info("tls negotiating successful ...");

				if (useExternalAuth) {
					context.addToEnvironment(Context.SECURITY_AUTHENTICATION,
							"EXTERNAL");
				} else {
					log.debug("binding ...");
					properties.setProperty(Context.SECURITY_AUTHENTICATION,
							backupAuthType);
					log.debug("after starting " + properties.toString());
					context
							.addToEnvironment(
									Context.SECURITY_AUTHENTICATION,
									properties
											.getProperty(Context.SECURITY_AUTHENTICATION));

				}

			} else {
				log.debug(properties.toString());
				context = new InitialDirContext(properties);
			}
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			log.error("\n failed to initiate ldap context");
		}

		return context;
	}

	/**
	 * @return the credentials
	 */
	public String getCredentials() {
		return credentials;
	}

	/**
	 * @param credentials
	 *            the credentials to set
	 */
	public void setCredentials(String credentials) {
		this.credentials = credentials;
	}

	/**
	 * @return the principal
	 */
	public String getPrincipal() {
		return principal;
	}

	/**
	 * @param principal
	 *            the principal to set
	 */
	public void setPrincipal(String principal) {
		this.principal = principal;
	}

	/**
	 * @return the searchFilterSpec
	 */
	public String getSearchFilterSpec() {
		return searchFilterSpec;
	}

	/**
	 * @param searchFilterSpec
	 *            the searchFilterSpec to set
	 */
	public void setSearchFilterSpec(String searchFilterSpec) {
		this.searchFilterSpec = searchFilterSpec;
	}

	/**
	 * @return the useStartTLS
	 */
	public String getUseStartTLS() {
		return useStartTLS;
	}

	/**
	 * @param useStartTLS
	 *            the useStartTLS to set
	 */
	public void setUseStartTLS(String useStartTLS) {
		this.useStartTLS = useStartTLS;
	}

	/**
	 * @return the baseDN
	 */
	public String getBaseDN() {
		return baseDN;
	}

	/**
	 * @param baseDN
	 *            the baseDN to set
	 */
	public void setBaseDN(String baseDN) {
		this.baseDN = baseDN;
	}

	/**
	 * @return the ldapUrl
	 */
	public String getLdapUrl() {
		return ldapUrl;
	}

	/**
	 * @param ldapUrl
	 *            the ldapUrl to set
	 */
	public void setLdapUrl(String ldapUrl) {
		this.ldapUrl = ldapUrl;
	}

}
