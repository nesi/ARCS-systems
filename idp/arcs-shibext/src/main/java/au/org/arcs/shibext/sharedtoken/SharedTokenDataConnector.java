/**
 * 
 */
package au.org.arcs.shibext.sharedtoken;

import java.util.Collection;
import java.util.Map;

import javax.sql.DataSource;

import org.apache.commons.codec.binary.Base64;
import org.apache.commons.codec.digest.DigestUtils;
import org.opensaml.xml.util.DatatypeHelper;
import org.opensaml.xml.util.LazyMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import edu.internet2.middleware.shibboleth.common.attribute.BaseAttribute;
import edu.internet2.middleware.shibboleth.common.attribute.provider.BasicAttribute;
import edu.internet2.middleware.shibboleth.common.attribute.resolver.AttributeResolutionException;
import edu.internet2.middleware.shibboleth.common.attribute.resolver.provider.ShibbolethResolutionContext;
import edu.internet2.middleware.shibboleth.common.attribute.resolver.provider.dataConnector.BaseDataConnector;
import edu.internet2.middleware.shibboleth.common.attribute.resolver.provider.dataConnector.StoredIDStore;

/**
 * @author Damien Chen
 * 
 */
public class SharedTokenDataConnector extends BaseDataConnector {

	/** Class logger. */
	private final Logger log = LoggerFactory
			.getLogger(SharedTokenDataConnector.class);

	private static String STORED_ATTRIBUTE_NAME = "auEduPersonSharedToken";

	private static String SEPARATOR = ",";

	/** ID of the attribute generated by this data connector. */
	private String generatedAttribute;

	/**
	 * IdP identifier used when computing the sharedToken.
	 */
	private String idpIdentifier;

	/**
	 * IdP home directory used when getting the IdP's configuration.
	 */
	private String idpHome;

	/**
	 * ID of the attribute whose first value is used when generating the
	 * computed ID.
	 */
	private String sourceAttribute;

	/** Salt used when computing the ID. */
	private byte[] salt;

	/** Whether to store the sharedToken to Ldap */
	private boolean storeLdap;

	/** Whether to search subtree when store the SharedToken */
	private boolean subtreeSearch;

	/** Whether to store the sharedToken to database */
	private boolean storeDatabase;

	/** SharedToken data store. */
	private SharedTokenStore stStore;

	/** Primary key in SharedToken database */
	private static String PRIMARY_KEY = "uid";

	/** Primary key in SharedToken database */
	private String primaryKeyName;

	/**
	 * Constructor.
	 * 
	 * @param generatedAttributeId
	 *            ID of the attribute generated by this data connector
	 * @param sourceAttributeId
	 *            ID of the attribute whose first value is used when generating
	 *            the computed ID
	 * @param idSalt
	 *            salt used when computing the ID
	 * @param storeLdap
	 *            Whether to store the sharedToken to Ldap
	 */
	public SharedTokenDataConnector(String generatedAttributeId,
			String sourceAttributeId, byte[] idSalt, boolean storeLdap,
			boolean subtreeSearch, String idpIdentifier, String idpHome,
			boolean storeDatabase, DataSource source, String primaryKeyName) {

		try {
			log.info("construct SharedTokenDataConnector ...");
			if (DatatypeHelper.isEmpty(generatedAttributeId)) {
				throw new IllegalArgumentException(
						"Provided generated attribute ID must not be empty");
			}
			generatedAttribute = generatedAttributeId;

			if (DatatypeHelper.isEmpty(sourceAttributeId)) {
				throw new IllegalArgumentException(
						"Provided source attribute ID must not be empty");
			}
			sourceAttribute = sourceAttributeId;

			if (idSalt.length < 16) {
				log.warn("Provided salt less than 16 bytes in size.");
				// throw new IllegalArgumentException(
				// "Provided salt must be at least 16 bytes in size.");
			}
			salt = idSalt;

			this.idpIdentifier = idpIdentifier;

			this.idpHome = idpHome;

			this.storeLdap = storeLdap;

			this.subtreeSearch = subtreeSearch;

			this.primaryKeyName = primaryKeyName;

			this.storeDatabase = storeDatabase;

			if (storeDatabase) {
				if (source != null) {
					stStore = new SharedTokenStore(source);
				} else {
					log.error("DataSource should not be null");
					throw new IllegalArgumentException(
							"DataSource should not be null");
				}
			}

		} catch (Exception e) {
			// catch any exception so that the IdP will not screw up.
			e.printStackTrace();
			log.error(e.getMessage()
					+ "\n failed to construct SharedTokenDataConnector object");
		}

	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see
	 * edu.internet2.middleware.shibboleth.common.attribute.resolver.provider
	 * .ResolutionPlugIn
	 * #resolve(edu.internet2.middleware.shibboleth.common.attribute
	 * .resolver.provider.ShibbolethResolutionContext)
	 */
	/** {@inheritDoc} */
	public Map<String, BaseAttribute> resolve(
			ShibbolethResolutionContext resolutionContext)
			throws AttributeResolutionException {

		log.info("starting SharedTokenDataConnector.resolve( ) ...");

		Map<String, BaseAttribute> attributes = new LazyMap<String, BaseAttribute>();

		String sharedToken = null;
		try {
			if (storeDatabase) {
				log
						.info("storeDatabase = true. Try to get SharedToken from database");
				// Collection<Object> colUid =
				// super.getValuesFromAllDependencies(
				// resolutionContext, PRIMARY_KEY);

				// String uid = (String) colUid.iterator().next();

				String uid = resolutionContext.getAttributeRequestContext()
						.getPrincipalName();

				if (stStore != null) {
					sharedToken = stStore.getSharedToken(uid, primaryKeyName);
				} else {
					log.error("SharedTokenStore is null");
					throw new IMASTException("SharedTokenStore is null");
				}
				if (sharedToken == null) {
					log
							.info("sharedToken does not exist, will generate a new one and store in database.");

					sharedToken = getSharedToken(resolutionContext);
					stStore.storeSharedToken(uid, sharedToken, primaryKeyName);
				} else {
					log
							.info("sharedToken exists, will not generate a new one.");
				}
			} else {
				log
						.debug("storeDatabase = false. Try to get SharedToken from LDAP.");
				Collection<Object> col = super.getValuesFromAllDependencies(
						resolutionContext, STORED_ATTRIBUTE_NAME);
				//
				if (col.size() < 1) {
					log
							.info("sharedToken does not exist, will generate a new one.");
					sharedToken = getSharedToken(resolutionContext);
					if (getStoreLdap()) {
						log
								.debug("storeLdap=true, will store the SharedToken in LDAP.");
						storeSharedToken(resolutionContext, sharedToken);
					} else
						log
								.info("storeLdap=false, not to store sharedToken in Ldap");
				} else {
					log
							.info("sharedToken  exists, will not to generate a new one.");
					sharedToken = col.iterator().next().toString();
				}
			}
			BasicAttribute<String> attribute = new BasicAttribute<String>();
			attribute.setId(getGeneratedAttributeId());
			attribute.getValues().add(sharedToken);
			attributes.put(attribute.getId(), attribute);
		} catch (Exception e) {
			// catch any exception so that the IdP will not screw up.
			log.error(e.getMessage());
			log.error("Failed to resolve " + STORED_ATTRIBUTE_NAME);
			// e.printStackTrace();
		}
		return attributes;
	}

	/**
	 * Gets the sharedToken.
	 * 
	 * @param resolutionContext
	 *            current resolution context
	 * 
	 * @return sharedToken
	 * 
	 * @throws AttributeResolutionException
	 *             thrown if there is a problem retrieving or storing the
	 *             persistent ID
	 */
	private String getSharedToken(ShibbolethResolutionContext resolutionContext)
			throws AttributeResolutionException {

		String localId = getLocalId(resolutionContext);
		String persistentId = this.createSharedToken(resolutionContext,
				localId, salt);
		return persistentId;

	}

	/**
	 * Store the sharedToken.
	 * 
	 * @param resolutionContext
	 *            current resolution context
	 * @param sharedToken
	 * 
	 */

	private void storeSharedToken(
			ShibbolethResolutionContext resolutionContext, String sharedToken)
			throws IMASTException {

		log.info("calling storeSharedToken() ...");

		try {
			String principalName = resolutionContext
					.getAttributeRequestContext().getPrincipalName();

			(new LdapUtil()).saveAttribute(STORED_ATTRIBUTE_NAME, sharedToken,
					getDependencyIds().get(0), principalName, idpHome, subtreeSearch);
		} catch (Exception e) {
			// catch any exception, the program will go on.
			e.printStackTrace();
			log.error(e.getMessage().concat(
					"\n failed to store sharedToken to Ldap. "));
			throw new IMASTException(e.getMessage().concat(
					"\n failed to save attribute to ldap entry"), e.getCause());

		}
	}

	/**
	 * Creates the sharedToken that is unique and persistent within a federation
	 * 
	 * @param resolutionContext
	 *            current resolution context
	 * @param localId
	 *            principal the the persistent ID represents, might be a
	 *            combination of attributes, e.g. uid+mail.
	 * @param salt
	 *            salt used when computing a persistent ID via SHA-1 hash
	 * 
	 * @return the created identifier
	 * 
	 * @throws AttributeResolutionException
	 *             thrown if there is a problem
	 */
	private String createSharedToken(
			ShibbolethResolutionContext resolutionContext, String localId,
			byte[] salt) throws AttributeResolutionException {
		String persistentId;
		log.info("creating a sharedToken ...");
		try {
			String localEntityId = null;
			if (this.idpIdentifier == null) {
				localEntityId = resolutionContext.getAttributeRequestContext()
						.getLocalEntityId();
			} else {
				localEntityId = idpIdentifier;
			}
			String globalUniqueID = localId + localEntityId + new String(salt);
			log.info("the globalUniqueID (user/idp/salt): " + localId + " / "
					+ localEntityId + " / " + new String(salt));
			byte[] hashValue = DigestUtils.sha(globalUniqueID);
			byte[] encodedValue = Base64.encodeBase64(hashValue);
			persistentId = new String(encodedValue);
			persistentId = this.replace(persistentId);
			log.info("the created sharedToken: " + persistentId);
		} catch (Exception e) {
			log.error("\n failed to create the sharedToken. ");
			throw new AttributeResolutionException(e.getMessage().concat(
					"\n failed to create the sharedToken."));
		}
		return persistentId;

	}

	private String replace(String persistentId) {
		// begin = convert non-alphanum chars in base64 to alphanum
		// (/+=)
		log.info("calling replace() ...");
		if (persistentId.contains("/") || persistentId.contains("+")
				|| persistentId.contains("=")) {
			String aepst;
			if (persistentId.contains("/")) {
				aepst = persistentId.replaceAll("/", "_");
				persistentId = aepst;
			}

			if (persistentId.contains("+")) {
				aepst = persistentId.replaceAll("\\+", "-");
				persistentId = aepst;
			}

			if (persistentId.contains("=")) {
				aepst = persistentId.replaceAll("=", "");
				persistentId = aepst;
			}
		}

		return persistentId;
	}

	/**
	 * Gets the local ID component of the persistent ID.
	 * 
	 * @param resolutionContext
	 *            current resolution context
	 * 
	 * @return local ID component of the persistent ID
	 * 
	 * @throws AttributeResolutionException
	 *             thrown if there is a problem resolving the local id
	 */
	private String getLocalId(ShibbolethResolutionContext resolutionContext)
			throws AttributeResolutionException {

		log.info("gets local ID ...");

		String[] ids = getSourceAttributeId().split(SEPARATOR);

		StringBuffer localIdValue = new StringBuffer();
		for (int i = 0; i < ids.length; i++) {

			Collection<Object> sourceIdValues = getValuesFromAllDependencies(
					resolutionContext, ids[i]);
			if (sourceIdValues == null || sourceIdValues.isEmpty()) {
				log
						.error(
								"Source attribute {} for connector {} provide no values",
								getSourceAttributeId(), getId());
				throw new AttributeResolutionException("Source attribute "
						+ getSourceAttributeId() + " for connector " + getId()
						+ " provided no values");
			}

			if (sourceIdValues.size() > 1) {
				log
						.warn(
								"Source attribute {} for connector {} has more than one value, only the first value is used",
								getSourceAttributeId(), getId());
			}
			localIdValue.append(sourceIdValues.iterator().next().toString());
		}
		log.info("local ID: " + localIdValue.toString());

		return localIdValue.toString();
	}

	/** {@inheritDoc} */
	public void validate() throws AttributeResolutionException {
		if (getDependencyIds() == null || getDependencyIds().size() != 1) {
			log.error("Computed ID " + getId()
					+ " data connectore requires exactly one dependency");
			throw new AttributeResolutionException("Computed ID " + getId()
					+ " data connectore requires exactly one dependency");
		}
	}

	/**
	 * Gets the salt used when computing the ID.
	 * 
	 * @return salt used when computing the ID
	 */
	public byte[] getSalt() {
		return salt;
	}

	/**
	 * Gets the ID of the attribute whose first value is used when generating
	 * the computed ID.
	 * 
	 * @return ID of the attribute whose first value is used when generating the
	 *         computed ID
	 */
	public String getSourceAttributeId() {
		return sourceAttribute;
	}

	/**
	 * Gets the ID of the attribute generated by this connector.
	 * 
	 * @return ID of the attribute generated by this connector
	 */
	public String getGeneratedAttributeId() {
		return generatedAttribute;
	}

	/**
	 * @return the storeLdap
	 */
	public boolean getStoreLdap() {
		return storeLdap;
	}

	/**
	 * @return the idpIdentifier
	 */
	public String getIdpIdentifier() {
		return idpIdentifier;
	}

	/**
	 * @param idpIdentifier
	 *            the idpIdentifier to set
	 */
	public void setIdpIdentifier(String idpIdentifier) {
		this.idpIdentifier = idpIdentifier;
	}

}
