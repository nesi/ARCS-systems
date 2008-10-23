/**
 * 
 */
package au.org.arcs.imast;

import java.security.Principal;
import java.util.Properties;

import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.BasicAttribute;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.ModificationItem;

import org.apache.log4j.Logger;
import org.w3c.dom.Element;

import edu.internet2.middleware.shibboleth.aa.attrresolv.ResolutionPlugInException;
import edu.internet2.middleware.shibboleth.aa.attrresolv.provider.JNDIDirectoryDataConnector;

/**
 * @author Damien Chen
 * 
 */
public class IMASTDataConnector extends JNDIDirectoryDataConnector {
	private static Logger log = Logger.getLogger(IMASTDataConnector.class
			.getName());

	private Properties imastProperties = null;

	/**
	 * @param e
	 * @throws ResolutionPlugInException
	 */
	public IMASTDataConnector(Element e) throws ResolutionPlugInException {
		super(e);
	}

	public void writeAttribute(String aEPST, Principal principal)
			throws IMASTException {
		try {
			Properties properties = super.properties;
			if (imastProperties != null) {
				String secPrincipal = imastProperties
						.getProperty("SECURITY_PRINCIPAL");
				String secCredential = imastProperties
						.getProperty("SECURITY_CREDENTIALS");
				if (secPrincipal != null && !secPrincipal.trim().equals("")
						&& secCredential != null
						&& !secCredential.trim().equals("")) {
					// overwrite default binduser
					properties.setProperty("java.naming.security.principal",
							imastProperties.getProperty("SECURITY_PRINCIPAL"));
					properties
							.setProperty(
									"java.naming.security.credentials",
									imastProperties
											.getProperty("SECURITY_CREDENTIALS"));
				}
			}

			String populatedSearch = searchFilter.replaceAll("%PRINCIPAL%",
					principal.getName());

			log.debug("auEduPersonSharedToken : " + aEPST);
			log.debug("searchFilter : " + super.searchFilter);
			log.debug("principal : " + principal.getName());
			log.debug("populatedSearch : " + populatedSearch);

			try {
				DirContext dirContext = new InitialDirContext(properties);
				Attribute mod0 = new BasicAttribute("auEduPersonSharedToken",
						aEPST);
				ModificationItem[] mods = new ModificationItem[1];

				try {
					mods[0] = new ModificationItem(DirContext.ADD_ATTRIBUTE,
							mod0);
					dirContext.modifyAttributes(populatedSearch, mods);
				} catch (Exception e) {
					// TODO should not replace, test only here
					log.warn("aEPST is existing");
					mods[0] = new ModificationItem(
							DirContext.REPLACE_ATTRIBUTE, mod0);
					//dirContext.modifyAttributes(populatedSearch, mods);
				}

			} catch (NamingException e) {
				throw new IMASTException(e.getMessage(), e.getCause());
			}
		} catch (Exception e) {
			throw new IMASTException(e.getMessage(), e.getCause());
		}

	}

	/**
	 * @param imastProperties
	 *            the imastProperties to set
	 */
	public void setImastProperties(Properties imastProperties) {
		this.imastProperties = imastProperties;
	}

}
