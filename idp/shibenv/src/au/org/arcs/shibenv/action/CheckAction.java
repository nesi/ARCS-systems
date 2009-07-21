/**
 * 
 */
package au.org.arcs.shibenv.action;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.apache.log4j.Logger;
import org.apache.struts2.ServletActionContext;

import au.org.arcs.shibenv.JDBCUtil;

import au.org.arcs.shibenv.Constants;

import java.sql.Connection;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.LinkedHashMap;

import com.opensymphony.xwork2.ActionSupport;

/**
 * @author Damien Chen
 * 
 */
public class CheckAction extends ActionSupport {

	/**
	 * 
	 */
	private static final long serialVersionUID = 4519608664074092954L;

	private static Logger log = Logger.getLogger(CheckAction.class.getName());

	private LinkedHashMap<String, String> aafMap;

	private LinkedHashMap<String, String> slcsMap;

	private LinkedHashMap<String, String> rrMap;

	private LinkedHashMap<String, String> otherMap;

	private String entityID;

	private String strTimestamp;

	private String imastAlg;

	private String uniqueAttr;

	private String porting;

	private JDBCUtil jdbcUtil;



	/*
	 * (non-Javadoc)
	 * 
	 * @see com.opensymphony.xwork2.ActionSupport#execute()
	 */
	@Override
	public String execute() {
		// TODO Auto-generated method stub

		try {

			HttpServletRequest request = ServletActionContext.getRequest();
			HttpSession session = request.getSession();

			aafMap = new LinkedHashMap<String, String>();
			slcsMap = new LinkedHashMap<String, String>();
			rrMap = new LinkedHashMap<String, String>();
			otherMap = new LinkedHashMap<String, String>();
			HashMap<String, String> agreementMap = new HashMap<String, String>();

			entityID = request.getParameter(Constants.ENTITY_ID);
			String strTime = request.getParameter("timestamp");

			log.debug("entityID : " + entityID);
			log.debug("strTime : " + strTime);
			long longTime = Long.valueOf(strTime);
			Timestamp timestamp = new Timestamp(longTime);
			strTimestamp = timestamp.toString();

			Connection conn = jdbcUtil.getConnection();

			try {
				jdbcUtil.queryAttr(entityID, timestamp, Constants.TB_AAF,
						aafMap, conn);
				jdbcUtil.queryAttr(entityID, timestamp, Constants.TB_SLCS,
						slcsMap, conn);
				jdbcUtil.queryAttr(entityID, timestamp, Constants.TB_RR, rrMap,
						conn);
				jdbcUtil.queryAttr(entityID, timestamp, Constants.TB_OTHER,
						otherMap, conn);
				jdbcUtil.queryAgreement(entityID, timestamp,
						Constants.TB_AGREEMENT, agreementMap, conn);

			} catch (Exception e) {
				e.printStackTrace();
				throw new Exception(e.getMessage());
			} finally {
				if (conn != null) {
					try {
						conn.close();
						log.debug("Database connection terminated");
					} catch (Exception e) { /* ignore close errors */
						e.printStackTrace();
						throw new Exception(e.getMessage());
					}
				}
			}

			imastAlg = agreementMap.get(Constants.IMAST_ALG);
			uniqueAttr = agreementMap.get(Constants.UNIQUE_ATTR);
			porting = agreementMap.get(Constants.PORTING);

		} catch (Exception e) {
			this.addActionError("Sorry, you are failed to query the database");
			log.debug(e.getMessage());
			return ERROR;

		}
		// this.addActionMessage("");
		return SUCCESS;

	}

	/*
	 * private void query() throws Exception {
	 * 
	 * Connection conn = JDBCUtil.getConnection(); Statement aaf =
	 * conn.createStatement();
	 * 
	 * 
	 * 
	 * s.executeQuery("SELECT id, name, category FROM animal"); ResultSet rs =
	 * s.getResultSet(); int count = 0; while (rs.next()) { int idVal =
	 * rs.getInt("id"); String nameVal = rs.getString("name"); String catVal =
	 * rs.getString("category"); System.out.println("id = " + idVal + ", name = " +
	 * nameVal + ", category = " + catVal); ++count; } rs.close(); s.close();
	 * 
	 * log.debug(count + " rows were retrieved"); }
	 */

	/**
	 * @return the aafMap
	 */
	public LinkedHashMap<String, String> getAafMap() {
		return aafMap;
	}

	/**
	 * @param aafMap
	 *            the aafMap to set
	 */
	public void setAafMap(LinkedHashMap<String, String> aafMap) {
		this.aafMap = aafMap;
	}

	/**
	 * @return the otherMap
	 */
	public LinkedHashMap<String, String> getOtherMap() {
		return otherMap;
	}

	/**
	 * @param otherMap
	 *            the otherMap to set
	 */
	public void setOtherMap(LinkedHashMap<String, String> otherMap) {
		this.otherMap = otherMap;
	}

	/**
	 * @return the rrMap
	 */
	public LinkedHashMap<String, String> getRrMap() {
		return rrMap;
	}

	/**
	 * @param rrMap
	 *            the rrMap to set
	 */
	public void setRrMap(LinkedHashMap<String, String> rrMap) {
		this.rrMap = rrMap;
	}

	/**
	 * @return the slcsMap
	 */
	public LinkedHashMap<String, String> getSlcsMap() {
		return slcsMap;
	}

	/**
	 * @param slcsMap
	 *            the slcsMap to set
	 */
	public void setSlcsMap(LinkedHashMap<String, String> slcsMap) {
		this.slcsMap = slcsMap;
	}

	/**
	 * @return the entityID
	 */
	public String getEntityID() {
		return entityID;
	}

	/**
	 * @param entityID the entityID to set
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
	 * @param imastAlg the imastAlg to set
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
	 * @param porting the porting to set
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
	 * @param uniqueAttr the uniqueAttr to set
	 */
	public void setUniqueAttr(String uniqueAttr) {
		this.uniqueAttr = uniqueAttr;
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
	 * @return the strTimestamp
	 */
	public String getStrTimestamp() {
		return strTimestamp;
	}

	/**
	 * @param strTimestamp the strTimestamp to set
	 */
	public void setStrTimestamp(String strTimestamp) {
		this.strTimestamp = strTimestamp;
	}
}
