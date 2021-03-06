/**
 * 
 */
package au.org.arcs.shibext.targetedid;

import java.util.Collection;
import java.util.Map;
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

/**
 * @author Damien Chen
 * 
 */
public class TargetedIDDataConnector extends BaseDataConnector {

	/** Class logger. */
	private final Logger log = LoggerFactory
			.getLogger(TargetedIDDataConnector.class);

	/** ID of the attribute generated by this data connector. */
	private String generatedAttribute;

	/**
	 * ID of the attribute whose first value is used when generating the
	 * computed ID.
	 */
	private String sourceAttribute;

	/** Salt used when computing the ID. */
	private byte[] salt;

	private static String SEPARATOR = ",";

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
	 */
	public TargetedIDDataConnector(String generatedAttributeId,
			String sourceAttributeId, byte[] idSalt) {

		try {
			log.info("construct TargetedIDDataConnector ...");
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
				throw new IllegalArgumentException(
						"Provided salt must be at least 16 bytes in size.");
			}
			salt = idSalt;
		} catch (Exception e) {
			// catch any exception to let IdP go on
			log.error(e.getMessage().concat(
					"\n failed to construct TargetedIDDataConnector "));
		}
	}

	/** {@inheritDoc} */
	public Map<String, BaseAttribute> resolve(
			ShibbolethResolutionContext resolutionContext)
			throws AttributeResolutionException {
		
		log.info("starting TargetedIDDataConnector.resolve( ) ...");

		Map<String, BaseAttribute> attributes = new LazyMap<String, BaseAttribute>();

		try {
			String targetedID = getTargetedID(resolutionContext);
			BasicAttribute<String> attribute = new BasicAttribute<String>();
			attribute.setId(getGeneratedAttributeId());
			attribute.getValues().add(targetedID);
			attributes.put(attribute.getId(), attribute);
			log.info("successfully generated " + generatedAttribute + " : " + targetedID);
		} catch (Exception e) {
			// catch any exception to let IdP go on
			log.error(e.getMessage().concat("\n failed to resolve ").concat(
					generatedAttribute));
		}
		return attributes;
	}

	/**
	 * Gets the persistent ID stored in the database. If one does not exist it
	 * is created.
	 * 
	 * @param resolutionContext
	 *            current resolution context
	 * 
	 * @return persistent ID
	 * 
	 * @throws AttributeResolutionException
	 *             thrown if there is a problem retrieving or storing the
	 *             persistent ID
	 */
	private String getTargetedID(ShibbolethResolutionContext resolutionContext)
			throws AttributeResolutionException {

		String localId = getLocalId(resolutionContext);
		String targetedID = createTargetedID(resolutionContext, localId, salt);
		return targetedID;
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

		StringBuffer localIdValue = new StringBuffer();

		String[] ids = getSourceAttributeId().split(SEPARATOR);

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

	/**
	 * Creates the targetedID that is unique for a given local/peer/localId
	 * tuple.
	 * 
	 * @param resolutionContext
	 *            current resolution context
	 * @param localId
	 *            principal the the persistent ID represents
	 * @param salt
	 *            salt used when computing a persistent ID via SHA-1 hash
	 * 
	 * @return the created identifier
	 */
	private String createTargetedID(
			ShibbolethResolutionContext resolutionContext, String localId,
			byte[] salt) throws AttributeResolutionException {

		log.info("creating targetedID");
		String targetedID = null;

		try {
			String localEntityID = resolutionContext
					.getAttributeRequestContext().getLocalEntityId();
			String peerEntityID = resolutionContext
					.getAttributeRequestContext().getInboundMessageIssuer();
			String globalUniqueID = localId + localEntityID + peerEntityID
					+ new String(salt);
			log.info("the uniqueID (user/IdP/SP/salt) : " + localId + " / "
					+ localEntityID + " / " + peerEntityID + " / " + new String(salt));
			byte[] hashValue = DigestUtils.sha(globalUniqueID);
			byte[] encodedValue = Base64.encodeBase64(hashValue);
			targetedID = new String(encodedValue);
			targetedID = this.replace(targetedID);

		} catch (Exception e) {
			log.error("failed to create the targetedID");
			throw new AttributeResolutionException(e.getMessage());
		}
		return targetedID;
	}

	private String replace(String persistentId) {
		// begin = convert non-alphanum chars in base64 to alphanum
		// (/+=)
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

	/** {@inheritDoc} */
	public void validate() throws AttributeResolutionException {
		if (getDependencyIds() == null || getDependencyIds().size() != 1) {
			log.error("targetedID " + getId()
					+ " data connectore requires exactly one dependency");
			throw new AttributeResolutionException("Computed ID " + getId()
					+ " data connectore requires exactly one dependency");
		}
	}
}
