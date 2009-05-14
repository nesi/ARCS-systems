/**
 * 
 */
package au.org.arcs.stps.action;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.security.cert.X509Certificate;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.opensymphony.xwork2.ActionContext;
import com.opensymphony.xwork2.ActionSupport;

import au.org.arcs.stps.Constants;
import au.org.arcs.stps.ConfigBean;
import au.org.arcs.stps.impl.CertificateResolverImpl;
import au.org.arcs.stps.service.CertificateResolver;
import au.org.arcs.stps.service.KeyDiscovery;
import au.org.arcs.stps.service.SharedTokenPopulator;

/**
 * @author Damien Chen
 * 
 */
public class SubmitAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = 8225536533490883992L;

	private final Logger log = LoggerFactory.getLogger(SubmitAction.class);

	private KeyDiscovery keyDiscovery;

	private CertificateResolver certResolver;

	private File[] upload;

	private SharedTokenPopulator stPopulator;

	private ConfigBean configBean;

	/*
	 * (non-Javadoc)
	 * 
	 * @see com.opensymphony.xwork2.ActionSupport#execute()
	 */
	@Override
	public String execute() throws Exception {
		// TODO Auto-generated method stub
		
		String sharedToken;
		String username;

		try {
			Map attributes = ActionContext.getContext().getSession();
			username = (String) attributes.get(Constants.SESSION_USER);

			FileInputStream userCertFis = new FileInputStream(upload[0]);
			byte[] userCertByte = certResolver
					.inputStreamToByteArray(userCertFis);
			FileInputStream userSignatureFis = new FileInputStream(upload[1]);
			byte[] userSigByte = certResolver
					.inputStreamToByteArray(userSignatureFis);
			FileInputStream caFis = new FileInputStream(configBean
					.getSlcsCAPath());
			byte[] caCertByte = certResolver
					.inputStreamToByteArray(caFis);

			certResolver.verifyCert(userCertByte, caCertByte);

			certResolver.verifySignature(userCertByte, userSigByte);

			sharedToken = certResolver.getSharedToken(userCertByte);

			String attrName = "auEduPersonSharedToken";

			stPopulator.populate(attrName, sharedToken, username);

			userCertFis.close();
			caFis.close();
			userSignatureFis.close();

		} catch (Exception e) {
			e.printStackTrace();
			this.addActionError(e.getMessage());
			return ERROR;
		}
		this.addActionMessage("Successfully added the sharedToken <b>" + sharedToken + "</b> for " + username );
		return SUCCESS;
	}

	/**
	 * @return the keyDiscovery
	 */
	public KeyDiscovery getKeyDiscovery() {
		return keyDiscovery;
	}

	/**
	 * @param keyDiscovery
	 *            the keyDiscovery to set
	 */
	public void setKeyDiscovery(KeyDiscovery keyDiscovery) {
		this.keyDiscovery = keyDiscovery;
	}

	/**
	 * @return the certificateResolver
	 */
	public CertificateResolver getCertResolver() {
		return certResolver;
	}

	/**
	 * @param certificateResolver
	 *            the certificateResolver to set
	 */
	public void setCertResolver(CertificateResolver certResolver) {
		this.certResolver = certResolver;
	}

	/**
	 * @return the stPopulator
	 */
	public SharedTokenPopulator getStPopulator() {
		return stPopulator;
	}

	/**
	 * @param stPopulator
	 *            the stPopulator to set
	 */
	public void setStPopulator(SharedTokenPopulator stPopulator) {
		this.stPopulator = stPopulator;
	}

	/**
	 * @return the configBean
	 */
	public ConfigBean getConfigBean() {
		return configBean;
	}

	/**
	 * @param configBean
	 *            the configBean to set
	 */
	public void setConfigBean(ConfigBean configBean) {
		this.configBean = configBean;
	}

	/**
	 * @return the uploads
	 */
	public File[] getUpload() {
		return upload;
	}

	/**
	 * @param uploads
	 *            the uploads to set
	 */
	public void setUpload(File[] upload) {
		this.upload = upload;
	}

}
