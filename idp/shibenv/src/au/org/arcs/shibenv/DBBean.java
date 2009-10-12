/**
 * 
 */
package au.org.arcs.shibenv;

import java.io.Serializable;

/**
 * @author Damien Chen
 *
 */
public class DBBean implements Serializable {
	
	/**
	 * 
	 */
	private static final long serialVersionUID = -7290449515498688134L;
	private String dbEnforce;

	/**
	 * @return the dbEnforce
	 */
	public String getDbEnforce() {
		return dbEnforce;
	}

	/**
	 * @param dbEnforce the dbEnforce to set
	 */
	public void setDbEnforce(String dbEnforce) {
		this.dbEnforce = dbEnforce;
	}

}
