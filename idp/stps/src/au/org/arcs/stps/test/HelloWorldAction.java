/**
 * 
 */
package au.org.arcs.stps.test;

import com.opensymphony.xwork2.ActionSupport;

/**
 * @author Damien Chen
 * 
 */

public class HelloWorldAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = -2279530830491029914L;

	public static final String MESSAGE = "Struts is up and running ...";

	private String message;

	private TestBean testBean;

	public String execute() throws Exception {
		//setMessage(MESSAGE);
		
		setMessage(testBean.showMessage());
		return SUCCESS;
	}

	public void setMessage(String message) {
		this.message = message;
	}

	public String getMessage() {
		return message;
	}

	/**
	 * @return the testBean
	 */
	public TestBean getTestBean() {
		return testBean;
	}

	/**
	 * @param testBean
	 *            the testBean to set
	 */
	public void setTestBean(TestBean testBean) {
		this.testBean = testBean;
	}

}
