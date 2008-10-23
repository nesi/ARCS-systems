/**
 * 
 */
package au.org.arcs.imast;

import java.io.IOException;
import java.util.Properties;

import org.apache.log4j.Logger;
import org.opensaml.SAMLException;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;
import org.xml.sax.SAXException;

import edu.internet2.middleware.shibboleth.aa.attrresolv.AttributeResolver;
import edu.internet2.middleware.shibboleth.aa.attrresolv.AttributeResolverException;
import edu.internet2.middleware.shibboleth.common.ShibResource;
import edu.internet2.middleware.shibboleth.common.ShibbolethConfigurationException;
import edu.internet2.middleware.shibboleth.common.ShibResource.ResourceNotAvailableException;
import edu.internet2.middleware.shibboleth.idp.IdPConfig;
import edu.internet2.middleware.shibboleth.idp.IdPConfigLoader;
import edu.internet2.middleware.shibboleth.xml.Parser;

/**
 * @author Damien Chen
 * 
 */
public class IMASTUtil {

	private static Logger log = Logger.getLogger(AttributeResolver.class
			.getName());

	private static IMASTDataConnector connector = null;

	// private String configFileLocation = "";

	/**
	 * @param configFileLocation
	 * @throws AttributeResolverException
	 */
	public IMASTUtil() throws AttributeResolverException {
		// TODO Auto-generated constructor stub
	}

	private void loadConfig(String configFile)
			throws AttributeResolverException {

		try {
			ShibResource config = new ShibResource(configFile, this.getClass());
			Parser.DOMParser parser = new Parser.DOMParser(true);
			parser.parse(new InputSource(config.getInputStream()));
			loadConfig(parser.getDocument());

		} catch (ResourceNotAvailableException e) {
			log
					.error("No Attribute Resolver configuration could be loaded from ("
							+ configFile + "): " + e);
			throw new AttributeResolverException(
					"No Attribute Resolver configuration found.");
		} catch (SAXException e) {
			log.error("Error parsing Attribute Resolver Configuration file: "
					+ e);
			throw new AttributeResolverException(
					"Error parsing Attribute Resolver Configuration file.");
		} catch (IOException e) {
			log.error("Error reading Attribute Resolver Configuration file: "
					+ e);
			throw new AttributeResolverException(
					"Error reading Attribute Resolver Configuration file.");
		} catch (SAMLException e) {
			log.error("Error parsing Attribute Resolver Configuration file: "
					+ e);
			throw new AttributeResolverException(
					"Error parsing Attribute Resolver Configuration file.");
		}
	}

	private void loadConfig(Document document)
			throws AttributeResolverException {

		log.info("Configuring Attribute Resolver.");
		if (!document.getDocumentElement().getTagName().equals(
				"AttributeResolver")) {
			log
					.error("Configuration must include <AttributeResolver> as the root node.");
			throw new AttributeResolverException(
					"Cannot load Attribute Resolver.");
		}

		NodeList plugInNodes = document.getElementsByTagNameNS(
				AttributeResolver.resolverNamespace, "AttributeResolver").item(
				0).getChildNodes();

		if (plugInNodes.getLength() <= 0) {
			log.error("Configuration inclues no PlugIn definitions.");
			throw new AttributeResolverException(
					"Cannot load Attribute Resolver.");
		}

		for (int i = 0; plugInNodes.getLength() > i; i++) {
			if (plugInNodes.item(i).getNodeType() == Node.ELEMENT_NODE) {
				if (((Element) plugInNodes.item(i)).getTagName().equals(
						"JNDIDirectoryDataConnector")) {
					try {
						log.info("Found a PlugIn. Loading...");
						connector = new IMASTDataConnector(
								(Element) plugInNodes.item(i));
					} catch (ClassCastException cce) {
						log.error("Problem realizing PlugIn configuration"
								+ cce.getMessage());
					} catch (AttributeResolverException are) {
						log.warn("Skipping PlugIn: "
								+ ((Element) plugInNodes.item(i))
										.getAttribute("id"));
					}
				}
			}
		}

		log.info("Configuration complete.");
	}

	public IMASTDataConnector getDataConnector(Properties imastProperties) throws IMASTException{
		if(connector != null){
			System.out.println("Connector is existing");
			log.info("Connector is existing");
			return connector;
		}
		String idpConfFile = imastProperties
				.getProperty("IDP_CONFIG_FILE");

		IdPConfig configuration = null;
		try {
			Document idpConfig = IdPConfigLoader.getIdPConfig(idpConfFile);
			configuration = new IdPConfig(idpConfig.getDocumentElement());
		} catch (ShibbolethConfigurationException e) {
			throw new IMASTException(e.getMessage(), e.getCause());
		}
		try {
			loadConfig(configuration.getResolverConfigLocation());
		} catch (AttributeResolverException e) {
			throw new IMASTException(e.getMessage(), e.getCause());
		}
		connector.setImastProperties(imastProperties);

		return connector;
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		// TODO Auto-generated method stub

	}

}
