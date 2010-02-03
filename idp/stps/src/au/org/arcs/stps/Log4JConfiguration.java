/**
 * 
 */
package au.org.arcs.stps;

import javax.servlet.ServletContext;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.apache.log4j.PropertyConfigurator;
import org.apache.log4j.xml.DOMConfigurator;

/**
 * @author Damien Chen
 * 
 */

public class Log4JConfiguration {

	/**
	 * Logger
	 */
	public static Log log = LogFactory.getLog(Log4JConfiguration.class);

	/**
	 * Parameter name in the context or in the web.xml file
	 */
	static private String LOG4J_CONFIGURATION_FILE_KEY = "Log4JConfigurationFile";

	/**
	 * Watchdog to prevent multiple load
	 */
	static private boolean LOG4J_CONFIGURED = false;

	/**
	 * Configures the Log4J engine with an external <code>log4j.xml</code> file.
	 * The Servlet context must define a <code>Log4JConfigurationFile</code>
	 * parameter with the absolute path of the Log4J config file.
	 * 
	 * @param ctxt
	 *            The {@link ServletContext} object.
	 */
	public static synchronized void configure(ServletContext ctxt) {
		if (!LOG4J_CONFIGURED) {
			// try to configure log4j
			if (ctxt.getInitParameter(LOG4J_CONFIGURATION_FILE_KEY) != null) {
				String log4jConfig = ctxt
						.getInitParameter(LOG4J_CONFIGURATION_FILE_KEY);
				log.debug("load " + log4jConfig);
				if (log4jConfig.endsWith(".xml")) {
					DOMConfigurator.configure(log4jConfig);
				} else {
					PropertyConfigurator.configure(log4jConfig);
				}
			} else {
				log.warn(LOG4J_CONFIGURATION_FILE_KEY + " not found.");

			}
			LOG4J_CONFIGURED = true;
		}
	}
}
