/**
 * 
 */
package au.org.arcs.shibext.sharedtoken;

import javax.sql.DataSource;

import edu.internet2.middleware.shibboleth.common.config.attribute.resolver.dataConnector.BaseDataConnectorFactoryBean;

/**
 * @author Damien Chen
 * 
 */
public class SharedTokenDataConnectorBeanFactory extends
		BaseDataConnectorFactoryBean {

	/** ID of the attribute generated by the connector. */
	private String generatedAttribute;

	/**
	 * Comma separated IDs of attributes whose first value is used when
	 * generating the sharedToken.
	 */
	private String sourceAttribute;

	/**
	 * Salt used when computing the sharedToken.
	 */
	private byte[] salt;

	/**
	 * IdP identifier used when computing the sharedToken.
	 */
	private String idpIdentifier;

	/**
	 * IdP home directory.
	 */
	private String idpHome;

	/** Whether to store the sharedToken to Ldap */
	private boolean storeLdap;

	/** Whether to search subtree when store the SharedToken */
	private boolean subtreeSearch;

	/** Whether to store the sharedToken to database */
	private boolean storeDatabase;

	/**
	 * The primary key name in the database table to index the SharedToken
	 */
	private String primaryKeyName;

	/** Datasource used to communicate with database. */
	private DataSource dataSource;

	/** {@inheritDoc} */
	@Override
	public Class getObjectType() {
		return SharedTokenDataConnector.class;
	}

	/**
	 * Gets the datasource used to communicate with database.
	 * 
	 * @return datasource used to communicate with database
	 */
	public DataSource getDataSource() {
		return dataSource;
	}

	/**
	 * Sets the datasource used to communicate with database.
	 * 
	 * @param source
	 *            datasource used to communicate with database
	 */
	public void setDataSource(DataSource source) {
		dataSource = source;
	}

	/**
	 * Gets the ID of the attribute generated by the connector.
	 * 
	 * @return ID of the attribute generated by the connector
	 */
	public String getGeneratedAttribute() {
		return generatedAttribute;
	}

	/**
	 * Sets the ID of the attribute generated by the connector.
	 * 
	 * @param id
	 *            ID of the attribute generated by the connector
	 */
	public void setGeneratedAttribute(String id) {
		generatedAttribute = id;
	}

	/**
	 * Gets the ID of the attribute whose first value is used when generating
	 * the computed ID.
	 * 
	 * @return ID of the attribute whose first value is used when generating the
	 *         computed ID
	 */
	public String getSourceAttribute() {
		return sourceAttribute;
	}

	/**
	 * Sets the ID of the attribute whose first value is used when generating
	 * the computed ID.
	 * 
	 * @param id
	 *            ID of the attribute whose first value is used when generating
	 *            the computed ID
	 */
	public void setSourceAttribute(String id) {
		this.sourceAttribute = id;
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
	 * Sets the salt used when computing the ID.
	 * 
	 * @param salt
	 *            salt used when computing the ID
	 */
	public void setSalt(byte[] salt) {
		this.salt = salt;
	}

	/** {@inheritDoc} */
	@Override
	protected Object createInstance() throws Exception {
		SharedTokenDataConnector connector = new SharedTokenDataConnector(
				getGeneratedAttribute(), getSourceAttribute(), getSalt(),
				getStoreLdap(), getSubtreeSearch(), getIdpIdentifier(),
				getIdpHome(), getStoreDatabase(), getDataSource(), this
						.getPrimaryKeyName());
		populateDataConnector(connector);
		return connector;
	}

	/**
	 * @return the storeLdap
	 */
	public boolean getStoreLdap() {
		return storeLdap;
	}

	/**
	 * @param storeLdap
	 *            the storeLdap to set
	 */
	public void setStoreLdap(boolean storeLdap) {
		this.storeLdap = storeLdap;
	}

	/**
	 * @return the subtreeSearch
	 */

	public boolean getSubtreeSearch() {
		return subtreeSearch;
	}

	/**
	 * @param subtreeSearch
	 *            the subtreeSearch to set
	 */

	public void setSubtreeSearch(boolean subtreeSearch) {
		this.subtreeSearch = subtreeSearch;
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

	/**
	 * @return the storeDatabase
	 */
	public boolean getStoreDatabase() {
		return storeDatabase;
	}

	/**
	 * @param storeDatabase
	 *            the storeDatabase to set
	 */
	public void setStoreDatabase(boolean storeDatabase) {
		this.storeDatabase = storeDatabase;
	}

	/**
	 * @return the idpHome
	 */
	public String getIdpHome() {
		return idpHome;
	}

	/**
	 * @param idpHome
	 *            the idpHome to set
	 */
	public void setIdpHome(String idpHome) {
		this.idpHome = idpHome;
	}

	/**
	 * @return the primaryKeyName
	 */
	public String getPrimaryKeyName() {
		return primaryKeyName;
	}

	/**
	 * @param primaryKeyName
	 *            the primaryKeyName to set
	 */
	public void setPrimaryKeyName(String primaryKeyName) {
		this.primaryKeyName = primaryKeyName;
	}

}
