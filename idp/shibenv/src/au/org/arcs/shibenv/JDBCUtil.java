/**
 * 
 */
package au.org.arcs.shibenv;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Date;
import java.util.Iterator;
import java.util.Map;

import org.apache.log4j.Logger;

/**
 * @author Damien Chen
 * 
 */
public class JDBCUtil {

	private static Logger log = Logger.getLogger(JDBCUtil.class.getName());

	private String username;

	private String password;

	private String url;

	public Connection getConnection() throws Exception {

		Connection conn = null;
		try {
			Class.forName("com.mysql.jdbc.Driver").newInstance();
			conn = DriverManager.getConnection(url, username, password);
			System.out.println("Database connection established");
		} catch (Exception e) {
			e.printStackTrace();
			log.error("Cannot connect to database server");
			throw new Exception(e.getMessage());
		}
		return conn;
	}

	public void storeDB(String entityID, Map<String, String> aafMap,
			Map<String, String> slcsMap, Map<String, String> rrMap,
			Map<String, String> otherMap, String imastAlg, String uniqueAttr,
			String porting, Timestamp timestamp) throws Exception {
		Connection conn = getConnection();

		try {
			updateAttr(entityID, "tb_aaf", aafMap, timestamp, conn);
			updateAttr(entityID, "tb_slcs", slcsMap, timestamp, conn);
			updateAttr(entityID, "tb_rr", rrMap, timestamp, conn);
			updateAttr(entityID, "tb_other", otherMap, timestamp, conn);
			updateAgreement(entityID, imastAlg, uniqueAttr, porting, timestamp,
					conn);
		} catch (Exception e) {
			//e.printStackTrace();
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
	}

	public Timestamp getCurrentJavaSqlTimestamp() {
		Date date = new Date();
		return new Timestamp(date.getTime());
	}

	public void updateAttr(String entityID, String tableName,
			Map<String, String> attrMap, Timestamp timestamp, Connection conn)
			throws Exception {

		PreparedStatement ins = null;
		Iterator it = attrMap.keySet().iterator();

		while (it.hasNext()) {
			String attrName = (String) it.next();
			String attrValue = attrMap.get(attrName);
			ins = conn
					.prepareStatement("INSERT INTO "
							+ tableName
							+ " (entityID, attrName, attrValue, timestamp) VALUES(?,?,?,?)");
			ins.setString(1, entityID);
			ins.setString(2, attrName);
			ins.setString(3, attrValue);
			ins.setTimestamp(4, timestamp);
			System.out.println("INSERT INTO " + tableName
					+ " (entityID, attrName, attrValue) VALUES(" + entityID
					+ ", " + attrName + "," + attrValue + ", " + timestamp
					+ ")");
			ins.executeUpdate();
			System.out.println("Successful");
		}

		ins.close();
	}

	public void updateAgreement(String entityID, String imastAlg,
			String uniqueAttr, String porting, Timestamp timestamp,
			Connection conn) throws Exception {

		PreparedStatement ins = null;

		ins = conn
				.prepareStatement("INSERT INTO "
						+ "tb_agreement"
						+ " (entityID, imastAlg, uniqueAttr, porting, timestamp) VALUES(?,?,?,?,?)");
		ins.setString(1, entityID);
		ins.setString(2, imastAlg);
		ins.setString(3, uniqueAttr);
		ins.setString(4, porting);
		ins.setTimestamp(5, timestamp);
		log
				.debug("INSERT INTO "
						+ "tb_agreement"
						+ " (entityID, imastAlg, uniqueAttr, porting, timestamp) VALUES("
						+ entityID + ", " + imastAlg + "," + uniqueAttr + ","
						+ porting + ", " + timestamp + ")");
		ins.executeUpdate();
		System.out.println("Successful");

		ins.close();

	}

	public void queryAttr(String entityID, Timestamp timestamp,
			String tableName, Map<String, String> attrMap, Connection conn)
			throws Exception {

		PreparedStatement st = null;

		st = conn.prepareStatement("SELECT attrName, attrValue from "
				+ tableName + " WHERE entityID=? AND timestamp=?");
		st.setString(1, entityID);
		st.setTimestamp(2, timestamp);
		log
				.debug("SELECT attrName, attrValue from " + tableName
						+ " WHERE entityID=" + entityID + " AND timestamp="
						+ timestamp);
		ResultSet rs = st.executeQuery();

		log.debug("attrName        attrValue");
		while (rs.next()) {
			log.debug(rs.getString("attrName") + "        "
					+ rs.getString("attrValue"));

			attrMap.put(rs.getString("attrName"), rs.getString("attrValue"));

		}
	}

	public void queryAgreement(String entityID, Timestamp timestamp,
			String tableName, Map<String, String> attrMap, Connection conn)
			throws Exception {

		PreparedStatement st = null;

		st = conn.prepareStatement("SELECT imastAlg, uniqueAttr, porting from "
				+ tableName + " WHERE entityID=? AND timestamp=?");
		st.setString(1, entityID);
		st.setTimestamp(2, timestamp);
		log
				.debug("SELECT imastAlg, uniqueAttr, porting from " + tableName
						+ " WHERE entityID=" + entityID + " AND timestamp="
						+ timestamp);
		ResultSet rs = st.executeQuery();

		while (rs.next()) {
			attrMap.put(Constants.IMAST_ALG, rs.getString("imastAlg"));
			attrMap.put(Constants.UNIQUE_ATTR, rs.getString("uniqueAttr"));
			attrMap.put(Constants.PORTING, rs.getString("porting"));
		}
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
	 * @return the url
	 */
	public String getUrl() {
		return url;
	}

	/**
	 * @param url
	 *            the url to set
	 */
	public void setUrl(String url) {
		this.url = url;
	}

	/**
	 * @return the userName
	 */
	public String getUsername() {
		return username;
	}

	/**
	 * @param userName
	 *            the userName to set
	 */
	public void setUsername(String username) {
		this.username = username;
	}

}
