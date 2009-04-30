/**
 * 
 */
package au.org.arcs.stps;

import java.io.DataInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.security.interfaces.RSAPrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;

import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;

/**
 * @author Damien Chen
 * 
 */
public class KeyDiscovery {
	
	public X509Certificate getX509Certificate() throws Exception{
		String pubKeyFileName = "keys/test-idp-ramp-org-au-cert.pem";

		CertificateFactory cf = CertificateFactory.getInstance("X.509");

		X509Certificate cert = (X509Certificate) cf.generateCertificate(this
				.getClass().getClassLoader()
				.getResourceAsStream(pubKeyFileName));
		return cert;
	}

	public PublicKey getEncryptionKey() throws Exception {

		String pubKeyFileName = "keys/test-idp-ramp-org-au-cert.pem";

		CertificateFactory cf = CertificateFactory.getInstance("X.509");

		X509Certificate cert = (X509Certificate) cf.generateCertificate(this
				.getClass().getClassLoader()
				.getResourceAsStream(pubKeyFileName));
		PublicKey pk = cert.getPublicKey();
		return pk;
	}

	public PrivateKey getDecryptionKey() throws Exception {
		// read private key DER file

		String privKeyFileName = "./src/keys/test-idp-ramp-org-au-key.der";

		File privKeyFile = new File(privKeyFileName);
		DataInputStream dis = new DataInputStream(new FileInputStream(
				privKeyFile));
		byte[] privKeyBytes = new byte[(int) privKeyFile.length()];
		dis.read(privKeyBytes);
		dis.close();

		KeyFactory keyFactory = KeyFactory.getInstance("RSA");

		// decode private key
		PKCS8EncodedKeySpec privSpec = new PKCS8EncodedKeySpec(privKeyBytes);
		RSAPrivateKey privKey = (RSAPrivateKey) keyFactory
				.generatePrivate(privSpec);

		return privKey;
	}

	public PublicKey getVerifyingKey() throws Exception {
		String pubKeyFileName = "keys/test-idp-ramp-org-au-cert.pem";

		CertificateFactory cf = CertificateFactory.getInstance("X.509");

		X509Certificate cert = (X509Certificate) cf.generateCertificate(this
				.getClass().getClassLoader()
				.getResourceAsStream(pubKeyFileName));
		PublicKey pk = cert.getPublicKey();
		return pk;
	}

	public PrivateKey getSigningKey() throws Exception {
		// read private key DER file

		String privKeyFileName = "./src/keys/test-idp-ramp-org-au-key.der";

		File privKeyFile = new File(privKeyFileName);
		DataInputStream dis = new DataInputStream(new FileInputStream(
				privKeyFile));
		byte[] privKeyBytes = new byte[(int) privKeyFile.length()];
		dis.read(privKeyBytes);
		dis.close();

		KeyFactory keyFactory = KeyFactory.getInstance("RSA");

		// decode private key
		PKCS8EncodedKeySpec privSpec = new PKCS8EncodedKeySpec(privKeyBytes);
		RSAPrivateKey privKey = (RSAPrivateKey) keyFactory
				.generatePrivate(privSpec);

		return privKey;
	}
	
	public SecretKey getSymmetricKey() throws Exception {

		String jceAlgorithmName = "AES";
		KeyGenerator keyGenerator = KeyGenerator.getInstance(jceAlgorithmName);
		keyGenerator.init(128);
		SecretKey secretKey = keyGenerator.generateKey();
		return secretKey;
	}

	// openssl rsa -inform PEM -in rsapriv.pem -outform DER -pubout -out
	// rsapub.der
	// openssl pkcs8 -topk8 -inform PEM -in rsapriv.pem -outform DER -nocrypt
	// -out rsapriv.der

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		try {
			KeyDiscovery discovery = new KeyDiscovery();
			PublicKey enKey = discovery.getEncryptionKey();
			PrivateKey deKey = discovery.getDecryptionKey();
			PrivateKey sigingKey = discovery.getSigningKey();
			PublicKey verifyingKey = discovery.getVerifyingKey();
			System.out.println(verifyingKey);
			//System.out.println(deKey);
		} catch (Exception e) {
			e.printStackTrace();
		}

	}

}
