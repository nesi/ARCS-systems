/**
 * 
 */
package au.org.arcs.imast;

import java.io.File;
import java.security.SecureRandom;
import java.util.HashMap;
import java.util.Properties;

import javax.naming.Context;
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
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

/**
 * @author Damien Chen
 * 
 */
public class LdapUtil {


	public void saveAttribute(String attributeName, String attributeValue,
			String dataConnectorID, String principalName) {

		try {
			String ldapConnectorConfFile = "/usr/local/idp/conf/attribute-resolver.xml";
			String searchFilterSpec = "uid={0}";
			
			Element ldapConf = getLdapConfig(dataConnectorID,
					ldapConnectorConfFile);
			HashMap<String, String> ldapRawProp = getLdapRawProperties(ldapConf);
			Properties properties = buildLdapProperties(ldapRawProp);
			InitialDirContext context = initConnection(properties);
			String searchFilter = searchFilterSpec
					.replace("{0}", principalName);

			Attribute mod0 = new BasicAttribute(attributeName, attributeValue);
			ModificationItem[] mods = new ModificationItem[1];

			try {
				mods[0] = new ModificationItem(DirContext.ADD_ATTRIBUTE, mod0);
				context.modifyAttributes(searchFilter, mods);
			} catch (Exception e) {
				throw new IMASTException(e.getMessage()
						+ ". Couldn't add aEPST to Ldap");
				// mods[0] = new ModificationItem(DirContext.REPLACE_ATTRIBUTE,
				// mod0);
				// dirContext.modifyAttributes(populatedSearch, mods);
			}

		} catch (Exception e) {
			// TODO Auto-generated catch block
			System.out.println("Couldn't add aEPST to Ldap");
			e.printStackTrace();
		}

	}

	private InitialDirContext initConnection(Properties properties)
			throws IMASTException {

		InitialDirContext context = null;
		SSLSocketFactory sslsf;
		boolean useExternalAuth = false;
		boolean useStartTLS = (Boolean) properties.get("useStartTLS");

		try {
			if (useStartTLS) {

				if ("EXTERNAL".equals(properties
						.getProperty(Context.SECURITY_AUTHENTICATION))) {
					useExternalAuth = true;
					properties.remove(Context.SECURITY_AUTHENTICATION);
				}

				SSLContext sslc = SSLContext.getInstance("TLS");
				sslc.init(new KeyManager[] { null }, null, new SecureRandom());
				sslsf = sslc.getSocketFactory();
				context = new InitialLdapContext(properties, null);

				StartTlsResponse tls = (StartTlsResponse) ((LdapContext) context)
						.extendedOperation(new StartTlsRequest());
				tls.negotiate(sslsf);

				if (useExternalAuth) {
					context.addToEnvironment(Context.SECURITY_AUTHENTICATION,
							"EXTERNAL");
				} else {
					context
							.addToEnvironment(
									Context.SECURITY_AUTHENTICATION,
									properties
											.getProperty(Context.SECURITY_AUTHENTICATION));
				}

			} else {
				context = new InitialDirContext(properties);
			}
		} catch (Exception e) {
			e.printStackTrace();
			throw new IMASTException(e.getMessage());
		}
		return context;
	}

	private Properties buildLdapProperties(HashMap<String, String> ldapRawProp)
			throws IMASTException {
		// Properties properties = new Properties(System.getProperties());
		Properties properties = new Properties();

		try {
			String providerUrl = ldapRawProp.get("ldapURL") + "/"
					+ ldapRawProp.get("baseDN");
			String secAuth = ldapRawProp.get("authenticationType") == "" ? "SIMPLE"
					: ldapRawProp.get("authenticationType");
			String secPrincipal = ldapRawProp.get("principal");
			String pricipalCre = ldapRawProp.get("principalCredential");
			boolean useStartTLS = ldapRawProp.get("useStartTLS") == "true" ? true
					: false;

			properties.put(Context.INITIAL_CONTEXT_FACTORY,
					"com.sun.jndi.ldap.LdapCtxFactory");
			properties.put(Context.PROVIDER_URL, providerUrl);
			properties.put(Context.SECURITY_AUTHENTICATION, secAuth);
			properties.put(Context.SECURITY_PRINCIPAL, secPrincipal);
			properties.put(Context.SECURITY_CREDENTIALS, pricipalCre);
			properties.put("useStartTLS", useStartTLS);
		} catch (Exception e) {
			e.printStackTrace();
			throw new IMASTException(e.getMessage());
		}
		return properties;

	}

	private HashMap<String, String> getLdapRawProperties(Element ldapConfig)
			throws IMASTException {

		HashMap<String, String> ldapProperties = new HashMap<String, String>();
		try {
			ldapProperties.put("ldapURL", ldapConfig.getAttribute("ldapURL"));
			ldapProperties.put("baseDN", ldapConfig.getAttribute("baseDN"));
			ldapProperties.put("authenticationType", ldapConfig
					.getAttribute("authenticationType"));
			ldapProperties.put("principal", ldapConfig
					.getAttribute("principal"));
			ldapProperties.put("principalCredential", ldapConfig
					.getAttribute("principalCredential"));
			ldapProperties.put("useStartTLS", ldapConfig
					.getAttribute("useStartTLS"));
			ldapProperties.put("filterTemplate", ldapConfig
					.getElementsByTagName("FilterTemplate").item(0)
					.getTextContent().trim());
		} catch (Exception e) {
			throw new IMASTException(e.getMessage());
		}
		return ldapProperties;

	}

	private Element getLdapConfig(String connectorID, String configFile)
			throws IMASTException {

		Element elem = null;

		try {
			DocumentBuilderFactory docBuilderFactory = DocumentBuilderFactory
					.newInstance();
			DocumentBuilder docBuilder = docBuilderFactory.newDocumentBuilder();
			Document doc = docBuilder.parse(new File(configFile));
			NodeList dataConnectors = doc
					.getElementsByTagName("resolver:DataConnector");
			for (int s = 0; s < dataConnectors.getLength(); s++) {
				elem = (Element) dataConnectors.item(s);
				String id = elem.getAttribute("id");
				if (id != null && id.equalsIgnoreCase(connectorID))
					break;
			}

			// String nodeName = ldapConfig.getNodeName();
		} catch (Exception e) {
			throw new IMASTException(e.getMessage());
		}
		return elem;

	}

}
