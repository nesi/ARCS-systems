package au.org.arcs.stps.test;

public class TestBeanImpl implements TestBean {
	
	private String message;

	/* (non-Javadoc)
	 * @see au.org.arcs.stps.test.TestBean#showMessage()
	 */
	public String showMessage() {
		// TODO Auto-generated method stub
		return message;
	}

	/**
	 * @return the message
	 */
	public String getMessage() {
		return message;
	}

	/**
	 * @param message the message to set
	 */
	public void setMessage(String message) {
		this.message = message;
	}

}
