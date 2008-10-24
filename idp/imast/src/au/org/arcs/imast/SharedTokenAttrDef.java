/**
 * 
 */
package au.org.arcs.imast;

import java.io.IOException;
import java.net.InetAddress;
import java.net.UnknownHostException;
import java.security.Principal;
import java.util.Properties;

import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.Attributes;

import org.w3c.dom.Element;

import org.apache.commons.codec.binary.Base64;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.log4j.Logger;

import edu.internet2.middleware.shibboleth.aa.attrresolv.AttributeResolverException;
import edu.internet2.middleware.shibboleth.aa.attrresolv.Dependencies;
import edu.internet2.middleware.shibboleth.aa.attrresolv.ResolutionPlugInException;
import edu.internet2.middleware.shibboleth.aa.attrresolv.ResolverAttribute;
import edu.internet2.middleware.shibboleth.aa.attrresolv.provider.SimpleAttributeDefinition;

/**
 * @author Damien Chen
 * 
 */
public class SharedTokenAttrDef extends SimpleAttributeDefinition {
	private static Logger log = Logger.getLogger(SharedTokenAttrDef.class
			.getName());

	private static String IMAST_PROPERTIES = "imast.properties";

	private Properties imastProperties = null;

	/**
	 * @param e
	 * @throws ResolutionPlugInException
	 */
	public SharedTokenAttrDef(Element e) throws ResolutionPlugInException {
		super(e);
		// TODO Auto-generated constructor stub
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see edu.internet2.middleware.shibboleth.aa.attrresolv.AttributeDefinitionPlugIn#resolve(edu.internet2.middleware.shibboleth.aa.attrresolv.ResolverAttribute,
	 *      java.security.Principal, java.lang.String, java.lang.String,
	 *      edu.internet2.middleware.shibboleth.aa.attrresolv.Dependencies)
	 */
	public void resolve(ResolverAttribute attribute, Principal principal,
			String requester, String responder, Dependencies depends)
			throws ResolutionPlugInException {

		String auEduPersonSharedToken;

		try {
			Attributes attributes = depends.getConnectorResolution("directory");
			Attribute directoryAuEduPersonSharedToken = attributes
					.get("auEduPersonSharedToken");

			if (directoryAuEduPersonSharedToken == null) {
				// no value in directory, so generate one
				log.info("generate aEPST");

				if (imastProperties == null) {
					imastProperties = new Properties();
					this.getIMASTProperties(imastProperties, responder);
				}

				String userIdentifier = this.getPrivateUniqueID(attributes,
						imastProperties);
				String idpIdentifier = responder;
				String privateSeed = imastProperties
						.getProperty("PRIVATE_SEED");

				log.debug("userIdentifier" + " : " + userIdentifier);
				log.debug("idpIdentifier" + " : " + idpIdentifier);
				log.debug("privateSeed" + " : " + privateSeed);
				log.debug("idp configuration file : " + imastProperties.getProperty("IDP_CONFIG_FILE"));

				if (userIdentifier == null || userIdentifier.trim().equals("")
						|| idpIdentifier == null
						|| idpIdentifier.trim().equals("")
						|| privateSeed == null || privateSeed.trim().equals("")) {
					auEduPersonSharedToken = null;
					log
							.warn("Either userIdentifier or idpIdentifier or privateSeed is missing, so can’t generate Shared Token");
				} else {
					auEduPersonSharedToken = this.generateShareToken(
							userIdentifier, idpIdentifier, privateSeed);
					this.writeAttribute(auEduPersonSharedToken, principal,
							imastProperties);
				}

			} else {
				// existing directory value
				log.info("aEPST is existing, get it from Ldap");

				auEduPersonSharedToken = (String) directoryAuEduPersonSharedToken
						.get(0);
			}
			attribute.addValue(auEduPersonSharedToken);

		} catch (NamingException e) {
			log.warn(e.getMessage()
					+ ". Couldn't generate aEPST and set aEPST to null");
			auEduPersonSharedToken = null;

		} catch (IMASTException e) {

			log.warn(e.getMessage()
					+ ". Couldn't generate aEPST and set aEPST to null");

		} catch (Exception e) {
			log.warn(e.getMessage()
					+ ". Couldn't generate aEPST and set aEPST to null");
			auEduPersonSharedToken = null;
		}
	}

	private void getIMASTProperties(Properties imastProperties, String responder)
			throws IMASTException {

		try {
			imastProperties.load(this.getClass().getClassLoader()
					.getResourceAsStream(IMAST_PROPERTIES));
		} catch (IOException e) {
			log
					.warn(e.getMessage()
							+ ". couldn't find imast.properties file. try to use default properties");
			if (imastProperties == null)
				imastProperties = new Properties();
		}

		String userIdentifierConf = (String) imastProperties
				.getProperty("USER_IDENTIFIER");

		if (userIdentifierConf == null || userIdentifierConf.trim().equals("")) {
			imastProperties.put("USER_IDENTIFIER",
					DefaultProperties.USER_IDENTIFIER);
			log
					.info("Can not find user identifier in imast.properties, use default value instead");
		}

		String privateSeed = (String) imastProperties
				.getProperty("PRIVATE_SEED");

		String idpIdentifier = (String) imastProperties
				.getProperty("IDP_IDENTIFIER");
		if (idpIdentifier == null || idpIdentifier.trim().equals("")) {
			imastProperties.put("IDP_IDENTIFIER", responder);
			log
					.info("Can not find idp identifier in imast.properties, use default value instead");
		}

		if (privateSeed == null || privateSeed.trim().equals("")) {

			log
					.info("Can not find private seed in imast.properties, use default value instead");
			InetAddress thisIp = null;
			try {
				thisIp = InetAddress.getLocalHost();
			} catch (UnknownHostException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
				throw new IMASTException(e.getMessage()
						+ ". Can not get default private seed");
			}

			imastProperties.put("PRIVATE_SEED", thisIp.getHostAddress());

		}

		String idpConfFile = (String) imastProperties
				.getProperty("IDP_CONFIG_FILE");
		if (idpConfFile == null || idpConfFile.trim().equals("")) {
			imastProperties.put("IDP_CONFIG_FILE",
					DefaultProperties.IDP_CONFIG_FILE);
			log
					.info("Can not find idp config file in imast.properties, use default value instead");
		}
	}

	private String generateShareToken(String userIdentifier,
			String idpIdentifier, String privateSeed) {
		String globalUniqueID = userIdentifier + idpIdentifier + privateSeed;

		System.out.println("globalUniqueID : " + globalUniqueID);
		byte[] hashValue = DigestUtils.sha(globalUniqueID);
		byte[] encodedValue = Base64.encodeBase64(hashValue);
		String auEduPersonSharedToken = new String(encodedValue);
		auEduPersonSharedToken = this.replace(auEduPersonSharedToken);

		return auEduPersonSharedToken;
	}

	private String getPrivateUniqueID(Attributes attributes,
			Properties imastProperties) throws NamingException {

		String userIdentifierConf = imastProperties
				.getProperty("USER_IDENTIFIER");

		String somePrivateUniqueID = "";
		String[] userIdentifierdArray = userIdentifierConf.split(",");
		for (int i = 0; i < userIdentifierdArray.length; i++) {
			if (attributes.get(userIdentifierdArray[i]) != null) {
				somePrivateUniqueID = somePrivateUniqueID
						.concat((String) attributes
								.get(userIdentifierdArray[i]).get(0));
			} else {
				log.warn(userIdentifierdArray[i] + " is not existing");
				somePrivateUniqueID = null;
				break;
			}
		}
		return somePrivateUniqueID;

	}

	private void writeAttribute(String aEPST, Principal principal,
			Properties imastProperties) throws IMASTException {
		IMASTDataConnector connector = null;
		try {
			IMASTUtil util = new IMASTUtil();
			connector = util.getDataConnector(imastProperties);
			connector.writeAttribute(aEPST, principal);

		} catch (AttributeResolverException e) {
			throw new IMASTException(e.getMessage());
		} catch (Exception e) {
			throw new IMASTException(e.getMessage());
		}

	}

	private String replace(String auEduPersonSharedToken) {
		// begin = convert non-alphanum chars in base64 to alphanum
		// (/+=)
		if (auEduPersonSharedToken.contains("/")
				|| auEduPersonSharedToken.contains("+")
				|| auEduPersonSharedToken.contains("=")) {
			String aepst;
			if (auEduPersonSharedToken.contains("/")) {
				aepst = auEduPersonSharedToken.replaceAll("/", "_");
				auEduPersonSharedToken = aepst;
			}

			if (auEduPersonSharedToken.contains("+")) {
				aepst = auEduPersonSharedToken.replaceAll("\\+", "-");
				auEduPersonSharedToken = aepst;
			}

			if (auEduPersonSharedToken.contains("=")) {
				aepst = auEduPersonSharedToken.replaceAll("=", "");
				auEduPersonSharedToken = aepst;
			}
		}

		return auEduPersonSharedToken;
	}

}
