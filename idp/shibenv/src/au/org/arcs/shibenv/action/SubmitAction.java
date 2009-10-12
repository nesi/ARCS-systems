/**
 * 
 */
package au.org.arcs.shibenv.action;

import java.sql.Connection;
import java.sql.Timestamp;
import java.util.LinkedHashMap;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.apache.struts2.ServletActionContext;

import au.org.arcs.shibenv.Constants;
import au.org.arcs.shibenv.DBBean;
import au.org.arcs.shibenv.JDBCUtil;
import au.org.arcs.shibenv.MailUtil;

import com.opensymphony.xwork2.ActionSupport;

/**
 * @author Damien Chen
 * 
 */
public class SubmitAction extends ActionSupport {

	/**
	 * 
	 */
	private static Logger log = Logger.getLogger(SubmitAction.class.getName());

	private static final long serialVersionUID = 3870243019881088974L;

	private String entityID;

	private String imastAlg;

	private String uniqueAttr;

	private String porting;

	private JDBCUtil jdbcUtil;

	private MailUtil mailUtil;

	private DBBean dbBean;

	/*
	 * (non-Javadoc)
	 * 
	 * @see com.opensymphony.xwork2.ActionSupport#execute()
	 */
	@SuppressWarnings("unchecked")
	@Override
	public String execute() throws Exception {
		// TODO Auto-generated method stub

		try {
			HttpServletRequest request = ServletActionContext.getRequest();
			HttpSession session = request.getSession();

			LinkedHashMap<String, String> aafMap = (LinkedHashMap<String, String>) session
					.getAttribute(Constants.ATTR_AAF);

			LinkedHashMap<String, String> slcsMap = (LinkedHashMap<String, String>) session
					.getAttribute(Constants.ATTR_SLCS);

			LinkedHashMap<String, String> rrMap = (LinkedHashMap<String, String>) session
					.getAttribute(Constants.ATTR_RR);

			LinkedHashMap<String, String> otherMap = (LinkedHashMap<String, String>) session
					.getAttribute(Constants.ATTR_OTHER);

			entityID = (String) session.getAttribute(Constants.ENTITY_ID);

			if (imastAlg == null)
				imastAlg = "No";
			if (porting == null)
				porting = "No";
			if (uniqueAttr.equals("") || uniqueAttr.trim().equals(""))
				uniqueAttr = "Unknown";

			Timestamp timestamp = jdbcUtil.getCurrentJavaSqlTimestamp();

			if (dbBean.getDbEnforce().equals("true")) {

				jdbcUtil.storeDB(entityID, aafMap, slcsMap, rrMap, otherMap,
						imastAlg, uniqueAttr, porting, timestamp);

				mailUtil.sendMail(entityID, timestamp);
			} else {
				mailUtil.sendMail(entityID, aafMap, slcsMap, rrMap, otherMap,
						imastAlg, uniqueAttr, porting, timestamp);
			}

		} catch (Exception e) {
			this.addActionError("Sorry, you are failed to submit the form");
			log.debug(e.getMessage());
			return ERROR;

		}
		this.addActionMessage("You have successfully submitted the form");
		return SUCCESS;
	}

	/**
	 * @return the entityID
	 */
	public String getEntityID() {
		return entityID;
	}

	/**
	 * @param entityID
	 *            the entityID to set
	 */
	public void setEntityID(String entityID) {
		this.entityID = entityID;
	}

	/**
	 * @return the imastAlg
	 */
	public String getImastAlg() {
		return imastAlg;
	}

	/**
	 * @param imastAlg
	 *            the imastAlg to set
	 */
	public void setImastAlg(String imastAlg) {
		this.imastAlg = imastAlg;
	}

	/**
	 * @return the porting
	 */
	public String getPorting() {
		return porting;
	}

	/**
	 * @param porting
	 *            the porting to set
	 */
	public void setPorting(String porting) {
		this.porting = porting;
	}

	/**
	 * @return the uniqueAttr
	 */
	public String getUniqueAttr() {
		return uniqueAttr;
	}

	/**
	 * @param uniqueAttr
	 *            the uniqueAttr to set
	 */
	public void setUniqueAttr(String uniqueAttr) {
		this.uniqueAttr = uniqueAttr;
	}

	/**
	 * @return the mailUtil
	 */
	public MailUtil getMailUtil() {
		return mailUtil;
	}

	/**
	 * @param mailUtil
	 *            the mailUtil to set
	 */
	public void setMailUtil(MailUtil mailUtil) {
		this.mailUtil = mailUtil;
	}

	/**
	 * @return the jdbcUtil
	 */
	public JDBCUtil getJdbcUtil() {
		return jdbcUtil;
	}

	/**
	 * @param jdbcUtil
	 *            the jdbcUtil to set
	 */
	public void setJdbcUtil(JDBCUtil jdbcUtil) {
		this.jdbcUtil = jdbcUtil;
	}

	/**
	 * @return the dbBean
	 */
	public DBBean getDbBean() {
		return dbBean;
	}

	/**
	 * @param dbBean
	 *            the dbBean to set
	 */
	public void setDbBean(DBBean dbBean) {
		this.dbBean = dbBean;
	}

}
