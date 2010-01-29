/**
 * 
 */
package au.org.arcs.stps;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.naming.NoInitialContextException;

import org.apache.log4j.Logger;

import au.org.arcs.stps.web.STPSAction;

/**
 * @author Damien Chen
 * 
 */
public class AppConfig {
	private static Logger log = Logger.getLogger(STPSAction.class.getName());

	private static final Properties props;
	private static final String CONFIG_FILE = "/stps-web.properties";
	static {
		props = loadProperties();
	}

	private static Properties loadProperties() {
		String configFolder = null;
		Properties props = new Properties();
		try {
			try {
				Context c = new InitialContext();
				configFolder = (String) c.lookup("java:comp/env/configFolder");
				log.info("Using JNDI to get : " + configFolder);
			} catch (NoInitialContextException e) {
				log.info("JNDI not configured for STPS (NoInitialContextEx)");
			} catch (NamingException e) {
				log.info("No configFolder in JNDI");
			} catch (RuntimeException ex) {
				log.warn("Odd RuntimeException while testing for JNDI: "
						+ ex.getMessage());
			}

			
			try {
				if (configFolder != null) {
					FileInputStream fis = new FileInputStream(new File(
							configFolder + CONFIG_FILE));
					props.load(fis);
					fis.close();
				} else {
					props
							.load(AppConfig.class
									.getResourceAsStream(CONFIG_FILE));
				}
			} catch (IOException e) {
				throw new STPSException("Can't load app config file: "
						+ e.getMessage(), e);
			}

		} catch (Exception e) {
			String msg = e.getMessage()
					+ "\n Couldn't load the properties file";
			log.error(msg);
			//throw new STPSException();
		}
		return props;

	}
	public static Properties getProperties(){
		return props;
	} 

}
