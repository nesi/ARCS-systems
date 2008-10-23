/**
 * 
 */
package au.org.arcs.imast;

import java.io.FileNotFoundException;
import java.io.IOException;
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
					this.getIMASTProperties(imastProperties);
				}

				String userIdentifier = this.getPrivateUniqueID(attributes,
						imastProperties);
				String idpIdentifier = responder;
				String privateSeed = this.getPrivateSeed(imastProperties);

				log.debug("userIdentifier" + " : " + userIdentifier);
				log.debug("idpIdentifier" + " : " + idpIdentifier);
				log.debug("privateSeed" + " : " + privateSeed);

				if (userIdentifier == null || userIdentifier.trim().equals("")
						|| idpIdentifier == null
						|| idpIdentifier.trim().equals("")
						|| privateSeed == null || privateSeed.trim().equals("")) {
					auEduPersonSharedToken = null;
					log
							.warn("no UniqueID value in directory, so can’t generate Shared Token");
				} else {
					auEduPersonSharedToken = this.generateShareToken(
							userIdentifier, idpIdentifier, privateSeed);
					try {
						this.writeAttribute(auEduPersonSharedToken, principal,
								imastProperties);
					} catch (IMASTException e) {
						// TODO Auto-generated catch block
						// e.printStackTrace();
						log
								.warn("couldn't write aEPST to Ldap, set aEPST to null");
						auEduPersonSharedToken = null;
					}
				}

			} else {
				// existing directory value
				log.info("aEPST is existing, get it from Ldap");

				auEduPersonSharedToken = (String) directoryAuEduPersonSharedToken
						.get(0);
			}
			attribute.addValue(auEduPersonSharedToken);

		} catch (NamingException e) {
			log.warn("couldn't generate aEPST, set aEPST to null");
			auEduPersonSharedToken = null;

		} catch (Exception e) {
			log.warn("couldn't generate aEPST, set aEPST to null");
			auEduPersonSharedToken = null;
		}
	}

	private void getIMASTProperties(Properties imastProperties) {
		try {
			imastProperties.load(this.getClass().getClassLoader()
					.getResourceAsStream(IMAST_PROPERTIES));
			String userIdentifierConf = (String) imastProperties
					.getProperty("USER_IDENTIFIER");
			if (userIdentifierConf == null
					|| userIdentifierConf.trim().equals("")) {
				imastProperties.put("USER_IDENTIFIER",
						DefaultProperties.USER_IDENTIFIER);
				log
						.info("can not find user identifier configuration, using default instead");
			}

			String privateSeed = (String) imastProperties
					.getProperty("PRIVATE_SEED");
			if (privateSeed == null || privateSeed.trim().equals("")) {
				imastProperties.put("PRIVATE_SEED",
						DefaultProperties.PRIVATE_SEED);
				log
						.info("can not find private seed in imast.properties, use default instead");

			}

			String idpConfFile = (String) imastProperties
					.getProperty("IDP_CONFIG_FILE");
			if (idpConfFile == null || idpConfFile.trim().equals("")) {
				imastProperties.put("IDP_CONFIG_FILE",
						DefaultProperties.IDP_CONFIG_FILE);
				log
						.info("can not find idp config file in imast.properties, using default instead");

			}

		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			log
					.warn("The IMAST properties file is not existing, use default properities instead");
			this.setDefaultProperties(imastProperties);

		} catch (IOException e) {
			// TODO Auto-generated catch block
			log
					.warn("Error to load imast.properties, use default properities instead");
			this.setDefaultProperties(imastProperties);
		} catch (Exception e) {
			log
					.warn("Error to get imast.properties, use default properities instead");
			this.setDefaultProperties(imastProperties);

		}
	}

	private void setDefaultProperties(Properties imastProperties) {

		imastProperties.put("USER_IDENTIFIER",
				DefaultProperties.USER_IDENTIFIER);
		imastProperties.put("PRIVATE_SEED", DefaultProperties.PRIVATE_SEED);
		imastProperties.put("IDP_CONFIG_FILE",
				DefaultProperties.IDP_CONFIG_FILE);
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

	private String getPrivateSeed(Properties imastProperties) {
		String seed = imastProperties.getProperty("PRIVATE_SEED");
		return seed;
	}

	private void writeAttribute(String aEPST, Principal principal,
			Properties imastProperties) throws IMASTException {
		IMASTDataConnector connector = null;
		try {
			IMASTUtil util = new IMASTUtil();
			connector = util.getDataConnector(imastProperties);
			connector.writeAttribute(aEPST, principal);

		} catch (AttributeResolverException e) {
			throw new IMASTException(e.getMessage(), e.getCause());
		} catch (Exception e) {
			throw new IMASTException(e.getMessage(), e.getCause());
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
