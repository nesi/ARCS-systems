/**
 * 
 */
package au.org.arcs.imast;

import java.beans.PropertyVetoException;
import java.util.Hashtable;
import java.util.List;
import java.util.Map;

import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.sql.DataSource;
import javax.xml.namespace.QName;

import org.opensaml.xml.util.DatatypeHelper;
import org.opensaml.xml.util.XMLHelper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.BeanCreationException;
import org.springframework.beans.factory.support.BeanDefinitionBuilder;
import org.springframework.beans.factory.xml.ParserContext;
import org.w3c.dom.Element;

import com.mchange.v2.c3p0.ComboPooledDataSource;

import edu.internet2.middleware.shibboleth.common.config.attribute.resolver.dataConnector.BaseDataConnectorBeanDefinitionParser;
import edu.internet2.middleware.shibboleth.common.config.attribute.resolver.dataConnector.DataConnectorNamespaceHandler;


/**
 * @author Damien Chen
 *
 */
public class SharedTokenDataConnectorBeanDefinitionParser extends
		BaseDataConnectorBeanDefinitionParser {

    /** Schema type name. */
    public static final QName TYPE_NAME = new QName(SharedTokenDataConnectorNamespaceHandler.NAMESPACE, "SharedToken");

    /** Class logger. */
    private final Logger log = LoggerFactory.getLogger(SharedTokenDataConnectorBeanDefinitionParser.class);

    /** {@inheritDoc} */
    protected Class getBeanClass(Element element) {
        return SharedTokenDataConnectorBeanFactory.class;
    }

    /** {@inheritDoc} */
    protected void doParse(String pluginId, Element pluginConfig, Map<QName, List<Element>> pluginConfigChildren,
            BeanDefinitionBuilder pluginBuilder, ParserContext parserContext) {
        super.doParse(pluginId, pluginConfig, pluginConfigChildren, pluginBuilder, parserContext);

        if (pluginConfig.hasAttributeNS(null, "generatedAttributeID")) {
            pluginBuilder.addPropertyValue("generatedAttribute", pluginConfig.getAttributeNS(null,
                    "generatedAttributeID"));
        } else {
            pluginBuilder.addPropertyValue("generatedAttribute", "auEduPersonSharedToken");
        }
        
        pluginBuilder.addPropertyValue("sourceAttribute", pluginConfig.getAttributeNS(null, "sourceAttributeID"));
        pluginBuilder.addPropertyValue("salt", pluginConfig.getAttributeNS(null, "salt").getBytes());

    }

    /**
     * Processes the connection management configuration.
     * 
     * @param pluginId ID of this data connector
     * @param pluginConfigChildren configuration elements for this connector
     * @param pluginBuilder bean definition builder
     * 
     * @return data source built from configuration
     */
    protected DataSource processConnectionManagement(String pluginId, Map<QName, List<Element>> pluginConfigChildren,
            BeanDefinitionBuilder pluginBuilder) {
        List<Element> cmc = pluginConfigChildren.get(new QName(
                DataConnectorNamespaceHandler.NAMESPACE, "ContainerManagedConnection"));
        if (cmc != null && cmc.get(0) != null) {
            return buildContainerManagedConnection(pluginId, cmc.get(0));
        } else {
            return buildApplicationManagedConnection(pluginId, pluginConfigChildren.get(
                    new QName(
                            DataConnectorNamespaceHandler.NAMESPACE, "ApplicationManagedConnection")).get(0));
        }
    }

    /**
     * Builds a JDBC {@link DataSource} from a ContainerManagedConnection configuration element.
     * 
     * @param pluginId ID of this data connector
     * @param cmc the container managed configuration element
     * 
     * @return the built data source
     */
    protected DataSource buildContainerManagedConnection(String pluginId, Element cmc) {
        String jndiResource = cmc.getAttributeNS(null, "resourceName");
        jndiResource = DatatypeHelper.safeTrim(jndiResource);

        Hashtable<String, String> initCtxProps = buildProperties(XMLHelper.getChildElementsByTagNameNS(cmc,
                DataConnectorNamespaceHandler.NAMESPACE, "JNDIConnectionProperty"));
        try {
            InitialContext initCtx = new InitialContext(initCtxProps);
            DataSource dataSource = (DataSource) initCtx.lookup(jndiResource);
            if(dataSource == null){
                log.error("DataSource " + jndiResource + " did not exist in JNDI directory");
                throw new BeanCreationException("DataSource " + jndiResource + " did not exist in JNDI directory");
            }
            if (log.isDebugEnabled()) {
                log.debug("Retrieved data source for data connector {} from JNDI location {} using properties ",
                        pluginId, initCtxProps);
            }
            return dataSource;
        } catch (NamingException e) {
            log.error("Unable to retrieve data source for data connector " + pluginId + " from JNDI location "
                    + jndiResource + " using properties " + initCtxProps, e);
            return null;
        }
    }

    /**
     * Builds a JDBC {@link DataSource} from an ApplicationManagedConnection configuration element.
     * 
     * @param pluginId ID of this data connector
     * @param amc the application managed configuration element
     * 
     * @return the built data source
     */
    protected DataSource buildApplicationManagedConnection(String pluginId, Element amc) {
        ComboPooledDataSource datasource = new ComboPooledDataSource();

        String driverClass = DatatypeHelper.safeTrim(amc.getAttributeNS(null, "jdbcDriver"));
        ClassLoader classLoader = this.getClass().getClassLoader();
        try{
            classLoader.loadClass(driverClass);
        }catch(ClassNotFoundException e){
            log.error("Unable to create relational database connector, JDBC driver can not be found on the classpath");
            throw new BeanCreationException("Unable to create relational database connector, JDBC driver can not be found on the classpath");
        }
        
        try {
            datasource.setDriverClass(driverClass);
            datasource.setJdbcUrl(DatatypeHelper.safeTrim(amc.getAttributeNS(null, "jdbcURL")));
            datasource.setUser(DatatypeHelper.safeTrim(amc.getAttributeNS(null, "jdbcUserName")));
            datasource.setPassword(DatatypeHelper.safeTrim(amc.getAttributeNS(null, "jdbcPassword")));

            if (amc.hasAttributeNS(null, "poolAcquireIncrement")) {
                datasource.setAcquireIncrement(Integer.parseInt(DatatypeHelper.safeTrim(amc.getAttributeNS(null,
                        "poolAcquireIncrement"))));
            } else {
                datasource.setAcquireIncrement(3);
            }

            if (amc.hasAttributeNS(null, "poolAcquireRetryAttempts")) {
                datasource.setAcquireRetryAttempts(Integer.parseInt(DatatypeHelper.safeTrim(amc.getAttributeNS(null,
                        "poolAcquireRetryAttempts"))));
            } else {
                datasource.setAcquireRetryAttempts(36);
            }

            if (amc.hasAttributeNS(null, "poolAcquireRetryDelay")) {
                datasource.setAcquireRetryDelay(Integer.parseInt(DatatypeHelper.safeTrim(amc.getAttributeNS(null,
                        "poolAcquireRetryDelay"))));
            } else {
                datasource.setAcquireRetryDelay(5000);
            }

            if (amc.hasAttributeNS(null, "poolBreakAfterAcquireFailure")) {
                datasource.setBreakAfterAcquireFailure(XMLHelper.getAttributeValueAsBoolean(amc.getAttributeNodeNS(
                        null, "poolBreakAfterAcquireFailure")));
            } else {
                datasource.setBreakAfterAcquireFailure(true);
            }

            if (amc.hasAttributeNS(null, "poolMinSize")) {
                datasource.setMinPoolSize(Integer.parseInt(DatatypeHelper.safeTrim(amc.getAttributeNS(null,
                        "poolMinSize"))));
            } else {
                datasource.setMinPoolSize(2);
            }

            if (amc.hasAttributeNS(null, "poolMaxSize")) {
                datasource.setMaxPoolSize(Integer.parseInt(DatatypeHelper.safeTrim(amc.getAttributeNS(null,
                        "poolMaxSize"))));
            } else {
                datasource.setMaxPoolSize(50);
            }

            if (amc.hasAttributeNS(null, "poolMaxIdleTime")) {
                datasource.setMaxIdleTime(Integer.parseInt(DatatypeHelper.safeTrim(amc.getAttributeNS(null,
                        "poolMaxIdleTime"))));
            } else {
                datasource.setMaxIdleTime(600);
            }

            if (amc.hasAttributeNS(null, "poolIdleTestPeriod")) {
                datasource.setIdleConnectionTestPeriod(Integer.parseInt(DatatypeHelper.safeTrim(amc.getAttributeNS(
                        null, "poolIdleTestPeriod"))));
            } else {
                datasource.setIdleConnectionTestPeriod(180);
            }

            log.debug("Created application managed data source for data connector {}", pluginId);
            return datasource;
        } catch (PropertyVetoException e) {
            log.error("Unable to create data source for data connector {} with JDBC driver class {}", pluginId,
                    driverClass);
            return null;
        }
    }

    /**
     * Builds a hash from PropertyType elements.
     * 
     * @param propertyElements properties elements
     * 
     * @return properties extracted from elements, key is the property name.
     */
    protected Hashtable<String, String> buildProperties(List<Element> propertyElements) {
        if (propertyElements == null || propertyElements.size() < 1) {
            return null;
        }

        Hashtable<String, String> properties = new Hashtable<String, String>();

        String propName;
        String propValue;
        for (Element propertyElement : propertyElements) {
            propName = DatatypeHelper.safeTrim(propertyElement.getAttributeNS(null, "name"));
            propValue = DatatypeHelper.safeTrim(propertyElement.getAttributeNS(null, "value"));
            properties.put(propName, propValue);
        }

        return properties;
    }

}
