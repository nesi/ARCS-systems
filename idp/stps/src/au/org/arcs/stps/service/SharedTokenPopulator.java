/**
 * 
 */
package au.org.arcs.stps.service;

/**
 * @author Damien Chen
 * 
 */
public interface SharedTokenPopulator {

	public void populate(String attributeName, String attributeValue,
			 String principalName) throws Exception;

}
