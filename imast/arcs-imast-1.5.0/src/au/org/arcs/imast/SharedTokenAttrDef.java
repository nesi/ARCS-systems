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
import javax.sql.DataSource;

import org.w3c.dom.Element;

import org.apache.commons.codec.binary.Base64;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.commons.dbcp.BasicDataSource;
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

		String auEPST = null;

		try {
			Attributes attributes = depends.getConnectorResolution("directory");

			if (imastProperties == null) {
				imastProperties = new Properties();
				this.getIMASTProperties(imastProperties, responder);
			}

			String useDB = imastProperties.getProperty("USE_DB");

			if (useDB.equals("true")) {

				log
						.info("USE_DB=true, try to get the SharedToken from database");
				DataSource ds = getDataSource(imastProperties);

				SharedTokenStore stStore = new SharedTokenStore(ds);
				auEPST = stStore.getSharedToken(principal.getName());

				if (auEPST == null) {
					log
							.info("the SharedToken does not exist, try to generate it");
					auEPST = this.generateShareToken(imastProperties,
							attributes);
					if (auEPST != null) {
						log.info("Store the SharedToken in the database");
						stStore.storeSharedToken(principal.getName(), auEPST);
					} else {
						log.error("Couldn't resolve the SharedToken");
					}
				}
			} else {
				log.info("USE_DB=false, try to get the SharedToken from LDAP");

				Attribute directoryAuEduPersonSharedToken = attributes
						.get("auEduPersonSharedToken");

				if (directoryAuEduPersonSharedToken == null) {
					// no value in directory, so generate one
					log
							.info("the SharedToken does not exist, try to generate it");

					auEPST = this.generateShareToken(imastProperties,
							attributes);
					if (auEPST != null) {
						String workMode = imastProperties
								.getProperty("WORK_MODE");
						if (workMode != null && !workMode.trim().equals("")) {
							if (workMode.equals("ODP")) {
								log
										.info("On-Demand Provisioning - generate aEPST and write into Ldap");
								this.writeAttribute(auEPST, principal,
										imastProperties);

							} else if (workMode.equals("PNP")) {
								log
										.info("Partial or No Provisioning - generate aEPST and does not write into Ldap");
							} else {
								log.warn("Unkown WORK_MODE value");
							}
						} else {
							log
									.warn("No WORK_MODE set up. Partial or No Provisioning - generate aEPST and does not write into Ldap");
						}
					} else {
						log.error("Couldn't resolve the SharedToken");
					}

				} else {
					// existing directory value
					log.info("aEPST is existing, get it from Ldap");

					auEPST = (String) directoryAuEduPersonSharedToken.get(0);
				}
			}
			attribute.addValue(auEPST);

		} catch (NamingException e) {
			log.error(e.getMessage() + "\n Couldn't resove aEPST");

		} catch (IMASTException e) {
			log.error(e.getMessage() + "\n Couldn't resove aEPST");

		} catch (Exception e) {
			log.error(e.getMessage() + "\n Couldn't resove aEPST");
		}
	}

	private DataSource getDataSource(Properties imastProperties)
			throws IMASTException {

		log.info("getting data source");

		BasicDataSource dataSource = new BasicDataSource();
		String jdbcDriver = imastProperties.getProperty("JDBC_DRIVER");
		String jdbcURL = imastProperties.getProperty("JDBC_URL");
		String jdbcUsername = imastProperties.getProperty("JDBC_USERNAME");
		String jdbcPassword = imastProperties.getProperty("JDBC_PASSWORD");

		log.debug("JDBC_DRIVER : " + jdbcDriver);
		log.debug("JDBC_URL : " + jdbcURL);
		log.debug("JDBC_USERNAME : " + jdbcUsername);
		log.debug("JDBC_PASSWORD : " + "******");

		if (jdbcDriver == null || jdbcDriver.equals("")) {
			throw new IMASTException("missing property: JDBC_DRIVER is null ");
		}
		if (jdbcURL == null || jdbcURL.equals("")) {
			throw new IMASTException("missing property: JDBC_URL is null ");
		}
		if (jdbcUsername == null || jdbcUsername.equals("")) {
			throw new IMASTException("missing property: JDBC_USERNAME is null ");
		}
		if (jdbcPassword == null || jdbcPassword.equals("")) {
			throw new IMASTException("missing property: JDBC_PASSWORD is null ");
		}
		dataSource.setDriverClassName(jdbcDriver);
		dataSource.setUrl(jdbcURL);
		dataSource.setUsername(jdbcUsername);
		dataSource.setPassword(jdbcPassword);

		return dataSource;
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
					.debug("Couldn't find user identifier in imast.properties, defaults to "
							+ DefaultProperties.USER_IDENTIFIER);
		}

		String privateSeed = (String) imastProperties
				.getProperty("PRIVATE_SEED");

		String idpIdentifier = (String) imastProperties
				.getProperty("IDP_IDENTIFIER");
		if (idpIdentifier == null || idpIdentifier.trim().equals("")) {
			imastProperties.put("IDP_IDENTIFIER", responder);
			log
					.info("Couldn't find idp identifier in imast.properties, defaults to "
							+ responder);
		}

		if (privateSeed == null || privateSeed.trim().equals("")) {

			InetAddress thisIp = null;
			try {
				thisIp = InetAddress.getLocalHost();
			} catch (UnknownHostException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
				throw new IMASTException(e.getMessage()
						+ ". Couldn't get default private seed");
			}

			imastProperties.put("PRIVATE_SEED", thisIp.getHostAddress());
			log
					.debug("Couldn't find private seed in imast.properties, defaults to "
							+ thisIp.getHostAddress());

		}

		String idpConfFile = (String) imastProperties
				.getProperty("IDP_CONFIG_FILE");
		if (idpConfFile == null || idpConfFile.trim().equals("")) {
			imastProperties.put("IDP_CONFIG_FILE",
					DefaultProperties.IDP_CONFIG_FILE);
			log
					.debug("Couldn't find idp config file in imast.properties, defaults to "
							+ DefaultProperties.IDP_CONFIG_FILE);
		}

		String workMode = (String) imastProperties.getProperty("WORK_MODE");
		if (workMode == null || workMode.trim().equals("")) {
			imastProperties.put("WORK_MODE", DefaultProperties.WORK_MODE);
			log
					.debug("Couldn't find WORK_MODE in imast.properties, defaults to ODP");
		}
		String useDB = (String) imastProperties.getProperty("USE_DB");
		if (useDB == null || useDB.trim().equals("")) {
			imastProperties.put("USE_DB", "false");
			log
					.debug("Couldn't find USE_DB in imast.properties, defaults to false");
		}

	}

	private String generateShareToken(Properties imastProperties,
			Attributes attributes) throws NamingException {

		String auEPST = null;
		String userIdentifier = this.getPrivateUniqueID(attributes,
				imastProperties);
		String idpIdentifier = imastProperties.getProperty("IDP_IDENTIFIER");
		String privateSeed = imastProperties.getProperty("PRIVATE_SEED");

		log.debug("userIdentifier" + " : " + userIdentifier);
		log.debug("idpIdentifier" + " : " + idpIdentifier);
		log.debug("privateSeed" + " : " + privateSeed);
		log.debug("idp configuration file : "
				+ imastProperties.getProperty("IDP_CONFIG_FILE"));

		if (userIdentifier == null || userIdentifier.trim().equals("")
				|| idpIdentifier == null || idpIdentifier.trim().equals("")
				|| privateSeed == null || privateSeed.trim().equals("")) {
			auEPST = null;
			log
					.warn("Either userIdentifier or idpIdentifier or privateSeed is missing, so can’t generate Shared Token");
		} else {
			auEPST = this.generateShareToken(userIdentifier, idpIdentifier,
					privateSeed);
			log.info("auEduPersonSharedToken : " + auEPST);
		}
		return auEPST;
	}

	private String generateShareToken(String userIdentifier,
			String idpIdentifier, String privateSeed) {
		String globalUniqueID = userIdentifier + idpIdentifier + privateSeed;

		log.debug("globalUniqueID : " + globalUniqueID);
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
