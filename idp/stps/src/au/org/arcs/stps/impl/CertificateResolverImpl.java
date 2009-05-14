/**
 * 
 */
package au.org.arcs.stps.impl;

import java.io.BufferedInputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.InputStream;
import java.security.InvalidKeyException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.Principal;
import java.security.PublicKey;
import java.security.Signature;
import java.security.SignatureException;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import au.org.arcs.stps.service.CertificateResolver;

/**
 * @author Damien Chen
 * 
 */
public class CertificateResolverImpl implements CertificateResolver {

	private final Logger log = LoggerFactory
			.getLogger(CertificateResolverImpl.class);

	/*
	 * (non-Javadoc)
	 * 
	 * @see au.org.arcs.stps.service.CertificateResolver#getDN()
	 */
	public Principal getDN(X509Certificate cert) throws Exception {
		// TODO Auto-generated method stub
		Principal subjectDN = cert.getSubjectDN();
		return subjectDN;

	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see au.org.arcs.stps.service.CertificateResolver#getSharedToken()
	 */
	public String getSharedToken(byte[] certificate) throws Exception {
		// TODO Auto-generated method stub
		X509Certificate cert = getX509Certificate(certificate);
		Principal principal = cert.getSubjectDN();
		String dn = principal.getName();
		System.out.println("Subject DN : " + dn);
		String sharedToken = parseSharedToken(dn);
		return sharedToken;
	}

	public String getSharedToken(X509Certificate cert) throws Exception {
		// TODO Auto-generated method stub
		Principal principal = cert.getSubjectDN();
		String dn = principal.getName();
		System.out.println("Subject DN : " + dn);
		String sharedToken = parseSharedToken(dn);
		return sharedToken;
	}

	private String parseSharedToken(String dn) {
		// Subject DN : CN=Damien Chen m0CyWsvPpSLI__mcYxJkYBzSzps, O=ARCS IdP,
		// DC=slcs, DC=arcs, DC=org, DC=au
		// dn = "CN=Damien Chen m0CyWsvPpSLI__mcYxJkYBzSzps, O=ARCS IdP,
		// DC=slcs, DC=arcs, DC=org, DC=au";
		String cn = dn.substring(dn.indexOf("CN="), dn.indexOf(","));
		System.out.println("cn : " + cn);
		String st = cn.substring(cn.lastIndexOf(" "));
		System.out.println("st : " + st);
		return st;
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see au.org.arcs.stps.service.CertificateResolver#getX509Certificate()
	 */
	public X509Certificate getX509Certificate(byte[] certificate)
			throws Exception {
		// TODO Auto-generated method stub

		CertificateFactory cf = CertificateFactory.getInstance("X.509");

		X509Certificate cert = (X509Certificate) cf
				.generateCertificate(new ByteArrayInputStream(certificate));

		return cert;
	}

	public void verifyCert(byte[] userCertByte, byte[] caCertByte)
			throws Exception {

		X509Certificate userCert = getX509Certificate(userCertByte);
		X509Certificate caCert = getX509Certificate(caCertByte);
		userCert.verify(caCert.getPublicKey());
	}

	public byte[] inputStreamToByteArray(InputStream is) throws Exception {
		ByteArrayOutputStream byteOut = new ByteArrayOutputStream();
		byte[] buffer = new byte[4096]; // some large number - pick one
		for (int size; (size = is.read(buffer)) != -1;)
			byteOut.write(buffer, 0, size);
		return byteOut.toByteArray();
	}

	/*
	 * (non-Javadoc)
	 * 
	 * @see au.org.arcs.stps.service.CertificateResolver#verifySignature(java.security.cert.X509Certificate,
	 *      java.io.InputStream)
	 */

	public void verifySignature(byte[] userCertByte, byte[] userSigByte)
			throws Exception {
		// TODO Auto-generated method stub

		PublicKey publicKey = this.getX509Certificate(userCertByte)
				.getPublicKey();

		MessageDigest md = MessageDigest.getInstance("SHA-1");
		md.update(userCertByte);
		byte[] userCertDigest = md.digest();
		
	    StringBuffer hexDigest = new StringBuffer();
	    StringBuffer hexSig = new StringBuffer();
	    for (int i = 0; i < userCertDigest.length; ++i) {
	        hexDigest.append(Integer.toHexString(0x0100 + (userCertDigest[i] & 0x00FF)).substring(1));
	      }
	    for (int i = 0; i < userCertDigest.length; ++i) {
	        hexSig.append(Integer.toHexString(0x0100 + (userSigByte[i] & 0x00FF)).substring(1));
	      }
	    System.out.println("digest : " + hexDigest);
	    System.out.println("signature : " + hexSig);


		// String userCertString = userCertDigest.toString();

		Signature signer = Signature.getInstance("SHA1withRSA");
		signer.initVerify(publicKey);
		signer.update(userCertDigest);
		boolean result = signer.verify(userSigByte);
		if (result) {
			log.debug("verified : " + result);
		} else {
			//throw new Exception(
				//	"User's certificate is not verified by user's signature");
			log.debug("User's certificate is not verified by user's signature");
		}

	}

}
