/**
 * 
 */
package au.org.arcs.stps.service;

/**
 * @author Damien Chen
 *
 */
public interface Authenticator {
	
	public boolean authenticate(String principal, String credentials) throws Exception;

}
