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

	/**
	 * Default configuration filename
	 */
	static private String DEFAULT_CONFIGURATION_FILE = "/stps.properties";

	/**
	 * Singelton pattern
	 */
	static private STPSConfiguration SINGLETON = null;

	private Properties properties = null;

	static public synchronized void initialize(ServletContext ctxt)
			throws STPSException {
		// first configure Log4J with the external log4j config file
		Log4JConfiguration.configure(ctxt);
		// and the SLCS server
		log.debug("initialize STPSConfiguration(ServletContext)...");
		String filename = DEFAULT_CONFIGURATION_FILE;
		if (ctxt.getInitParameter(CONFIGURATION_FILE_KEY) != null) {
			filename = ctxt.getInitParameter(CONFIGURATION_FILE_KEY);
		} else {
			log.warn("Parameter " + CONFIGURATION_FILE_KEY
					+ " not found in the Servlet context, using default file: "
					+ filename);
		}
		initialize(filename);
	}

	/**
	 * Initializes the singleton SLCSServerConfiguration object loaded with the
	 * given XML filename.
	 * 
	 * @param filename
	 *            The XML filename.
	 * @throws SLCSConfigurationException
	 *             If an error occurs.
	 */
	static public synchronized void initialize(String filename)
			throws STPSException {
		log.info(CONFIGURATION_FILE_KEY + "=" + filename);
		if (SINGLETON == null) {
			log.info("create new SLCSServerConfiguration");
			SINGLETON = new STPSConfiguration(filename);
		} else {
			log.info("SLCSServerConfiguration already initialized");
		}
	}

	/**
	 * Returns the singleton instance of the SLCSServerConfiguration.
	 * 
	 * @return The SLCSServerConfiguration singleton.
	 */
	static public synchronized STPSConfiguration getInstance() {
		if (SINGLETON == null) {
			throw new IllegalStateException(
					"Not initialized: call SLCSServerConfiguration.initialize(...) first.");
		}
		return SINGLETON;
	}

	/**
	 * DO NOT USE directly the constructor. Factory pattern. Only use
	 * initialize() and getInstance().
	 * 
	 * @param filename
	 *            The Properties file based configuration file.
	 * @throws SLCSConfigurationException
	 *             If a configuration error occurs while loading the
	 *             configuration file or checking the configuration.
	 * @see #initialize(ServletContext)
	 * @see #getInstance()
	 */
	protected STPSConfiguration(String filename) throws STPSException {

		log.info("Properties file =" + filename);

		// load the attribute definitions
		loadProperties(filename);
	}

	private void loadProperties(String filename) throws STPSException {
		log.info("load property file");

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

	public Properties getProperties(){
		return properties;
	}
}
