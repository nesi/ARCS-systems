/**
 * 
 */
package au.org.arcs.stps.service;

import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.cert.X509Certificate;

import javax.crypto.SecretKey;

/**
 * @author Damien Chen
 * 
 */
public interface KeyDiscovery {

	public X509Certificate getX509Certificate() throws Exception;

	public PublicKey getEncryptionKey() throws Exception;

	public PrivateKey getDecryptionKey() throws Exception;

	public PublicKey getVerifyingKey() throws Exception;

	public PrivateKey getSigningKey() throws Exception;

	public SecretKey getSymmetricKey() throws Exception;

}
