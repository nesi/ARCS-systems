/**
 * 
 */
package au.org.arcs.imast;

/**
 * @author Damien Chen
 * 
 */
public interface DefaultProperties {

	/**
	 * 
	 */
	public final static String USER_IDENTIFIER = "uid,mail";

	// public final static String PRIVATE_SEED = "ihHkOYigjIYBNmygbLSUn";

	public final static String IDP_CONFIG_FILE = "file:/usr/local/shibboleth-idp/etc/idp.xml";

	//PNP: Partial or No Provisioning - This resolver will compute aEPST values in cases where the
	//value is not present in the directory. This option requires no commitment to provisioning
	//the directory.

	//ODP: On-Demand Provisioning - This resolver will compute aEPST values in cases where the
	//value is not present in the directory and then write the value to the directory for future use.
	//This option provides the benefits of full provisioning, but requires write access to the
	//aEPST attribute in directory entries.
	
	public final static String WORK_MODE = "ODP";

}
