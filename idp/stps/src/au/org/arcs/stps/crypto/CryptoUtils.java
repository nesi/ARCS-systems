package au.org.arcs.stps.crypto;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileWriter;
import java.io.FileReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.security.GeneralSecurityException;
import java.security.NoSuchAlgorithmException;
import java.util.Properties;
import java.util.Scanner;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import au.org.arcs.stps.STPSConfiguration;

public class CryptoUtils {

	public static final String AES = "AES";

	/**
	 * encrypt a value and generate a keyfile if the keyfile is not found then a
	 * new one is created
	 * 
	 * @throws GeneralSecurityException
	 * @throws IOException
	 */
	public static String encrypt(String value, File keyFile)
			throws GeneralSecurityException, IOException {
		if (!keyFile.exists()) {
			KeyGenerator keyGen = KeyGenerator.getInstance(CryptoUtils.AES);
			keyGen.init(128);
			SecretKey sk = keyGen.generateKey();
			FileWriter fw = new FileWriter(keyFile);
			fw.write(byteArrayToHexString(sk.getEncoded()));
			fw.flush();
			fw.close();
		}

		SecretKeySpec sks = getSecretKeySpec(keyFile);
		Cipher cipher = Cipher.getInstance(CryptoUtils.AES);
		cipher.init(Cipher.ENCRYPT_MODE, sks, cipher.getParameters());
		byte[] encrypted = cipher.doFinal(value.getBytes());
		return byteArrayToHexString(encrypted);
	}

	/**
	 * decrypt a value
	 * 
	 * @throws GeneralSecurityException
	 * @throws IOException
	 */
	public static String decrypt(String message, File keyFile)
			throws GeneralSecurityException, IOException {
		SecretKeySpec sks = getSecretKeySpec(keyFile);
		Cipher cipher = Cipher.getInstance(CryptoUtils.AES);
		cipher.init(Cipher.DECRYPT_MODE, sks);
		byte[] decrypted = cipher.doFinal(hexStringToByteArray(message));
		return new String(decrypted);
	}

	private static SecretKeySpec getSecretKeySpec(File keyFile)
			throws NoSuchAlgorithmException, IOException {
		byte[] key = readKeyFile(keyFile);
		SecretKeySpec sks = new SecretKeySpec(key, CryptoUtils.AES);
		return sks;
	}

	private static byte[] readKeyFile(File keyFile)
			throws FileNotFoundException {
		Scanner scanner = new Scanner(keyFile).useDelimiter("\\Z");
		String keyValue = scanner.next();
		scanner.close();
		return hexStringToByteArray(keyValue);
	}

	private static String byteArrayToHexString(byte[] b) {
		StringBuffer sb = new StringBuffer(b.length * 2);
		for (int i = 0; i < b.length; i++) {
			int v = b[i] & 0xff;
			if (v < 16) {
				sb.append('0');
			}
			sb.append(Integer.toHexString(v));
		}
		return sb.toString().toUpperCase();
	}

	private static byte[] hexStringToByteArray(String s) {
		byte[] b = new byte[s.length() / 2];
		for (int i = 0; i < b.length; i++) {
			int index = i * 2;
			int v = Integer.parseInt(s.substring(index, index + 2), 16);
			b[i] = (byte) v;
		}
		return b;
	}

	public static void main(String[] args) throws Exception {

		String KEY_FILE = "../conf/crypto";

		String clearPwd = null;
		File keyFile = null;

		System.out.println("Please input a clear password:");

		// open up standard input
		BufferedReader br = new BufferedReader(new InputStreamReader(System.in));

		try {
			clearPwd = br.readLine();
		} catch (IOException ioe) {
			System.out.println("IO error trying to read the password!");
			System.exit(1);
		}

		keyFile = new File(KEY_FILE);
/*
		if (!keyFile.exists()) {
			System.out.println("Could find the key file: " + KEY_FILE
					+ "Please input the key file path: ");
			BufferedReader brKey = new BufferedReader(new InputStreamReader(
					System.in));
			try {
				KEY_FILE = br.readLine();

			} catch (IOException ioe) {
				System.out
						.println("IO error trying to read the key file path!");
				System.exit(1);
			}
			try {
				keyFile = new File(KEY_FILE);
			} catch (Exception ex) {
				System.out.println("Couldn't find the key file");
				System.exit(1);
			}

		}
*/
		String encryptedPwd = CryptoUtils.encrypt(clearPwd, keyFile);
		if (encryptedPwd != null) {
			System.out.println("Encrypted password:");
			System.out.println(encryptedPwd);
			System.out
					.println("Please copy above encrypted password to stps.properties");
		}
	}
}
