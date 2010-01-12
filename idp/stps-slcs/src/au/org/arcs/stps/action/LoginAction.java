/**
 * 
 */
package au.org.arcs.stps.action;

import javax.servlet.http.HttpSession;

import org.apache.struts2.ServletActionContext;

import au.org.arcs.stps.Constants;
import au.org.arcs.stps.service.Authenticator;

import com.opensymphony.xwork2.ActionSupport;

/**
 * @author Damien Chen
 * 
 */
public class LoginAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = -4320781018794957864L;

	private String username;

	private String password;

	private Authenticator authenticator;

	/*
	 * (non-Javadoc)
	 * 
	 * @see com.opensymphony.xwork2.ActionSupport#execute()
	 */
	@Override
	public String execute() throws Exception {

		if (username == null || username.trim().equals("")) {
			this.addActionError("Please input your username!");
			return INPUT;
		} else if (password == null || password.trim().equals("")) {
			this.addActionError("Please input your password!");
			return INPUT;
		}

		boolean validUser = authenticator.authenticate(username, password);
		if (validUser) {
			HttpSession session = ServletActionContext.getRequest().getSession();
			session.setAttribute(Constants.SESSION_USER, username);
			session.setAttribute(Constants.SESSION_PASSWORD, password);
			addActionMessage("Welcome " + username);
			return SUCCESS;
		} else {
			this.addActionError("Invalid credentials");
			return INPUT;
		}

		// call authentication method here
	}

	/**
	 * @return the password
	 */
	public String getPassword() {
		return password;
	}

	/**
	 * @param password
	 *            the password to set
	 */
	public void setPassword(String password) {
		this.password = password;
	}

	/**
	 * @param userName
	 *            the userName to set
	 */
	public void setUsername(String username) {
		this.username = username;
	}

	/**
	 * @return the userName
	 */
	public String getUsername() {
		return username;
	}

	/**
	 * @return the authenticator
	 */
	public Authenticator getAuthenticator() {
		return authenticator;
	}

	/**
	 * @param authenticator
	 *            the authenticator to set
	 */
	public void setAuthenticator(Authenticator authenticator) {
		this.authenticator = authenticator;
	}

}
