/**
 * 
 */
package au.org.arcs.stps;

import java.io.File;
import java.io.FileInputStream;
import java.util.Properties;

import javax.servlet.ServletContext;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

/**
 * @author Damien Chen
 * 
 */
public class STPSConfiguration {

	/** Logger */
	public static Log log = LogFactory.getLog(STPSConfiguration.class);

	/**
	 * Parameter name in the context or in the web.xml file
	 */
	static private String CONFIGURATION_FILE_KEY = "STPSConfigurationFile";
	static private String SECRETKEY_FILE_KEY = "SecretKeyFile";

	/**
	 * Singelton pattern
	 */
	static private STPSConfiguration SINGLETON = null;

	private Properties properties = null;
	static private String keyFile = null;

	static public synchronized void initialize(ServletContext ctxt)
			throws STPSException {

		log.debug("Initializing STPSConfiguration ...");
		Log4JConfiguration.configure(ctxt);
		String filename = null;
		if (ctxt.getInitParameter(CONFIGURATION_FILE_KEY) != null) {
			filename = ctxt.getInitParameter(CONFIGURATION_FILE_KEY);
		} else {
			String msg = "Couldn't get STPSConfigurationFile path from the servlet initial parameter";
			log.error(msg);
			throw new STPSException(msg);
		}
		
		if (ctxt.getInitParameter(SECRETKEY_FILE_KEY) != null) {
			keyFile = ctxt.getInitParameter(SECRETKEY_FILE_KEY);
		} else {
			String msg = "Couldn't get STPSConfigurationFile path from the servlet initial parameter";
			log.error(msg);
			throw new STPSException(msg);
		}

		initialize(filename);
	}

	/**
	 * Initializes the singleton STPSConfiguration object loaded with the
	 * given XML filename.
	 * 
	 * @param filename
	 *            The XML filename.
	 * @throws STPSConfigurationException
	 *             If an error occurs.
	 */
	static public synchronized void initialize(String filename)
			throws STPSException {
		log.debug(CONFIGURATION_FILE_KEY + "=" + filename);
		if (SINGLETON == null) {
			log.debug("create new STPSConfiguration");
			SINGLETON = new STPSConfiguration(filename);
		} else {
			log.debug("STPSConfiguration already initialized");
		}
	}

	/**
	 * Returns the singleton instance of the STPSConfiguration.
	 * 
	 * @return The STPSConfiguration singleton.
	 */
	static public synchronized STPSConfiguration getInstance()
			throws STPSException {
		if (SINGLETON == null) {
			throw new STPSException(
					"Not initialized: call STPSConfiguration.initialize(...) first.");
		}
		return SINGLETON;
	}

	/**
	 * DO NOT USE directly the constructor. Factory pattern. Only use
	 * initialize() and getInstance().
	 * 
	 * @param filename
	 *            The Properties file based configuration file.
	 * @throws ConfigurationException
	 *             If a configuration error occurs while loading the
	 *             configuration file or checking the configuration.
	 * @see #initialize(ServletContext)
	 * @see #getInstance()
	 */
	protected STPSConfiguration(String filename) throws STPSException {

		loadProperties(filename);
	}

	private void loadProperties(String filename) throws STPSException {

		properties = new Properties();

		try {

			FileInputStream fis = new FileInputStream(new File(filename));
			properties.load(fis);
			fis.close();

		} catch (Exception e) {

			String msg = e.getMessage()
					+ "\n Couldn't load the properties file";
			log.error(msg);
			throw new STPSException(msg);
		}

	}

	public Properties getProperties() {
		return properties;
	}

	public void checkProperties() throws STPSException {

		String msgTmp = " is not specified in the properties file.";

		if (properties == null || properties.isEmpty()) {
			String msg = "Coldn't get the properties file or the file is empty";
			log.error(msg);
			throw new STPSException(msg);
		}

		String cert = properties.getProperty("CERTIFICATE");
		if (cert == null || cert.trim().equals("")) {
			String msg = "The signing certificate" + msgTmp;
			log.error(msg);
			throw new STPSException(msg);
		}

		String password = properties.getProperty("PASSWORD");

		if (password == null || password.trim().equals("")) {
			String msg = "The password of the signing key" + msgTmp;
			log.error(msg);
			throw new STPSException(msg);
		}

		String httpHeaderNameSharedToken = properties
				.getProperty("HTTP_HEADER_NAME_SHAREDTOKEN");

		if (httpHeaderNameSharedToken == null
				|| httpHeaderNameSharedToken.trim().equals("")) {
			String msg = "The http header's name for the SharedToken" + msgTmp;
			log.error(msg);
			throw new STPSException(msg);
		}

		String httpHeaderNameCn = properties.getProperty("HTTP_HEADER_NAME_CN");

		if (httpHeaderNameCn == null || httpHeaderNameCn.trim().equals("")) {
			String msg = "The http header's name for the cn" + msgTmp;
			log.error(msg);
			throw new STPSException(msg);
		}
		String httpHeaderNameMail = properties
				.getProperty("HTTP_HEADER_NAME_MAIL");

		if (httpHeaderNameMail == null || httpHeaderNameMail.trim().equals("")) {
			String msg = "The http header's name for the mail" + msgTmp;
			log.error(msg);
			throw new STPSException(msg);
		}
		String httpHeaderNameProviderID = properties
				.getProperty("HTTP_HEADER_NAME_PROVIDER_ID");
		if (httpHeaderNameProviderID == null
				|| httpHeaderNameProviderID.trim().equals("")) {
			String msg = "The http header's name for the Shibboleth ProviderID"
					+ msgTmp;
			log.error(msg);
			throw new STPSException(msg);
		}
	}
	public static String getKeyFile(){
		return keyFile;
	}
}
