/**
 * 
 */
package au.org.arcs.stps.service;

import java.io.File;
import java.io.InputStream;
import java.security.Principal;
import java.security.cert.X509Certificate;

/**
 * @author Damien Chen
 * 
 */
public interface CertificateResolver {

	public X509Certificate getX509Certificate(byte[] certificate)
			throws Exception;

	// public Principal getDN(X509Certificate cert) throws Exception;
	public String getSharedToken(byte[] certificate) throws Exception;

	public String getSharedToken(X509Certificate cert) throws Exception;

	public void verifyCert(byte[] userCertByte, byte[] caCertByte)
			throws Exception;

	public void verifySignature(byte[] userCertByte, byte[] userSigByte)
			throws Exception;

	public byte[] inputStreamToByteArray(InputStream is) throws Exception;
}
