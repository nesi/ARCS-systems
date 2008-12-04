/*
 * Copyright [2005] [University Corporation for Advanced Internet Development, Inc.]
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package au.org.arcs.imast;

import java.io.IOException;
import java.net.Socket;
import java.security.GeneralSecurityException;
import java.security.Principal;
import java.security.PrivateKey;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import java.util.Properties;

import javax.naming.Context;
import javax.naming.NamingException;
import javax.naming.directory.Attribute;
import javax.naming.directory.BasicAttribute;
import javax.naming.directory.DirContext;
import javax.naming.directory.InitialDirContext;
import javax.naming.directory.ModificationItem;
import javax.naming.ldap.InitialLdapContext;
import javax.naming.ldap.LdapContext;
import javax.naming.ldap.StartTlsRequest;
import javax.naming.ldap.StartTlsResponse;
import javax.net.ssl.KeyManager;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.X509KeyManager;

import org.apache.log4j.Logger;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import edu.internet2.middleware.shibboleth.aa.attrresolv.ResolutionPlugInException;
import edu.internet2.middleware.shibboleth.common.Credential;
import edu.internet2.middleware.shibboleth.common.Credentials;

import edu.internet2.middleware.shibboleth.aa.attrresolv.provider.JNDIDirectoryDataConnector;

/**
 * <code>DataConnectorPlugIn</code> implementation that utilizes a
 * user-specified JNDI <code>DirContext</code> to retrieve attribute data.
 * 
 * @author Walter Hoehn (wassa@columbia.edu)
 */
public class IMASTDataConnector extends JNDIDirectoryDataConnector {

	private static Logger log = Logger
			.getLogger(IMASTDataConnector.class.getName());

	boolean useExternalAuth = false;

	private SSLSocketFactory sslsf;

	private Properties imastProperties = null;

	/**
	 * Constructs a DataConnector based on DOM configuration.
	 * 
	 * @param e
	 *            a &lt;JNDIDirectoryDataConnector /&gt; DOM Element as
	 *            specified by urn:mace:shibboleth:resolver:1.0
	 * @throws ResolutionPlugInException
	 *             if the PlugIn cannot be initialized
	 */
	public IMASTDataConnector(Element e) throws ResolutionPlugInException {

		super(e);

		if (startTls) {
			log.debug("start tls ");
			// UGLY!
			// We can't do SASL EXTERNAL auth until we have a TLS session
			// So, we need to take this out of the environment and then
			// stick it back in later
			if ("EXTERNAL".equals(properties
					.getProperty(Context.SECURITY_AUTHENTICATION))) {
				useExternalAuth = true;
				properties.remove(Context.SECURITY_AUTHENTICATION);
			}

			// If TLS credentials were supplied, load them and setup a
			// KeyManager
			KeyManager keyManager = null;
			NodeList credNodes = e.getElementsByTagNameNS(
					Credentials.credentialsNamespace, "Credential");
			if (credNodes.getLength() > 0) {
				log
						.debug("JNDI Directory Data Connector has a \"Credential\" specification.  "
								+ "Loading credential...");
				Credentials credentials = new Credentials((Element) credNodes
						.item(0));
				Credential clientCred = credentials.getCredential();
				if (clientCred == null) {
					log.error("No credentials were loaded.");
					throw new ResolutionPlugInException(
							"Error loading credential.");
				}
				keyManager = new KeyManagerImpl(clientCred.getPrivateKey(),
						clientCred.getX509CertificateChain());
			}

			try {
				// Setup a customized SSL socket factory that uses our
				// implementation of KeyManager
				// This factory will be used for all subsequent TLS
				// negotiation
				SSLContext sslc = SSLContext.getInstance("TLS");
				sslc.init(new KeyManager[] { keyManager }, null,
						new SecureRandom());
				sslsf = sslc.getSocketFactory();

				log
						.debug("Attempting to connect to JNDI directory source as a sanity check.");
			} catch (GeneralSecurityException gse) {
				log
						.error("Failed to startup directory context.  Error creating SSL socket: "
								+ gse);
				throw new ResolutionPlugInException(
						"Failed to startup directory context.");
			}

		}
	}

	private InitialDirContext initConnection() throws NamingException,
			IOException, ResolutionPlugInException {

		InitialDirContext context;
		log.debug("startTls : " + startTls);
		log.debug("useExternalAuth : " + useExternalAuth);
		if (!startTls) {
			context = new InitialDirContext(properties);

		} else {
			context = new InitialLdapContext(properties, null);
			if (!(context instanceof LdapContext)) {
				log
						.error("Directory context does not appear to be an implementation of LdapContext.  "
								+ "This is required for startTls.");
				throw new ResolutionPlugInException(
						"Start TLS is only supported for implementations of LdapContext.");
			}
			StartTlsResponse tls = (StartTlsResponse) ((LdapContext) context)
					.extendedOperation(new StartTlsRequest());
			tls.negotiate(sslsf);
			if (useExternalAuth) {
				context.addToEnvironment(Context.SECURITY_AUTHENTICATION,
						"EXTERNAL");
			}
		}
		return context;
	}

	public void writeAttribute(String aEPST, Principal principal)
			throws IMASTException {
		// Properties properties = super.properties;
		DirContext dirContext;
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
				properties.setProperty("java.naming.security.credentials",
						imastProperties.getProperty("SECURITY_CREDENTIALS"));
			}
		}
		try {
			dirContext = this.initConnection();
		} catch (ResolutionPlugInException e1) {
			throw new IMASTException(e1.getMessage());
		} catch (NamingException e1) {
			throw new IMASTException(e1.getMessage());
		} catch (IOException e1) {
			throw new IMASTException(e1.getMessage());
		}

		String populatedSearch = searchFilter.replaceAll("%PRINCIPAL%",
				principal.getName());

		//log.debug("auEduPersonSharedToken : " + aEPST);
		log.debug("java.naming.provider.url : " + properties.getProperty("java.naming.provider.url") );
		log.debug("java.naming.security.principal : "
				+ properties.getProperty("java.naming.security.principal"));
		log.debug("searchFilter : " + super.searchFilter);
		log.debug("populatedSearch : " + populatedSearch);

		Attribute mod0 = new BasicAttribute("auEduPersonSharedToken", aEPST);
		ModificationItem[] mods = new ModificationItem[1];

		try {
			mods[0] = new ModificationItem(DirContext.ADD_ATTRIBUTE, mod0);
			dirContext.modifyAttributes(populatedSearch, mods);
			log.info("Successfully write aEPTS to Ldap");
		} catch (Exception e) {
			// TODO should not replace, test only here
			log.warn("aEPST is existing");
			throw new IMASTException(e.getMessage()
					+ ". Couldn't add aEPST to Ldap");
			// mods[0] = new ModificationItem(DirContext.REPLACE_ATTRIBUTE,
			// mod0);
			// dirContext.modifyAttributes(populatedSearch, mods);
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

/**
 * Implementation of <code>X509KeyManager</code> that always uses a hard-coded
 * client certificate.
 */

class KeyManagerImpl implements X509KeyManager {

	private PrivateKey key;

	private X509Certificate[] chain;

	KeyManagerImpl(PrivateKey key, X509Certificate[] chain) {

		this.key = key;
		this.chain = chain;
	}

	public String[] getClientAliases(String arg0, Principal[] arg1) {

		return new String[] { "default" };
	}

	public String chooseClientAlias(String[] arg0, Principal[] arg1, Socket arg2) {

		return "default";
	}

	public String[] getServerAliases(String arg0, Principal[] arg1) {

		return null;
	}

	public String chooseServerAlias(String arg0, Principal[] arg1, Socket arg2) {

		return null;
	}

	public X509Certificate[] getCertificateChain(String arg0) {

		return chain;
	}

	public PrivateKey getPrivateKey(String arg0) {

		return key;
	}

}