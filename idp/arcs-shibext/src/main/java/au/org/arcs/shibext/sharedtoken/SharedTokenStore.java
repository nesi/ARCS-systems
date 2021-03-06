/**
 * 
 */
package au.org.arcs.shibext.sharedtoken;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * @author Damien Chen
 * 
 */
public class SharedTokenStore {

	/** Class logger. */
	private final Logger log = LoggerFactory.getLogger(SharedTokenStore.class);

	private DataSource dataSource;

	public SharedTokenStore(DataSource dataSource) {

		this.dataSource = dataSource;

	}

	public String getSharedToken(String uid, String primaryKeyName)
			throws IMASTException {
		log.debug("calling getSharedToken ...");

		Connection conn = null;
		String sharedToken = null;
		PreparedStatement st = null;
		ResultSet rs = null;

		try {

			try {
				conn = dataSource.getConnection();
				if (!isValid(conn)) {
					conn.close();
					conn = dataSource.getConnection();
				}

				st = conn
						.prepareStatement("SELECT sharedToken from tb_st WHERE "
								+ primaryKeyName + "=?");
				st.setString(1, uid);
				log.debug("SELECT sharedToken from tb_st WHERE "
						+ primaryKeyName + "=" + uid);
				rs = st.executeQuery();

				while (rs.next()) {
					sharedToken = rs.getString("sharedToken");
				}
			} catch (SQLException e) {
				e.printStackTrace();
				log.error(e.getMessage());
				throw new IMASTException(e.getMessage());
			} finally {
				try {
					rs.close();
					conn.close();
				} catch (SQLException e) {
					throw new IMASTException(e.getMessage());
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
			throw new IMASTException(e.getMessage()
					+ "\n Failed to get SharedToken from database");

		}
		log.info("SharedToken : " + sharedToken);

		return sharedToken;
	}

	public void storeSharedToken(String uid, String sharedToken,
			String primaryKeyName) throws IMASTException {
		log.debug("calling storeSharedToken ...");
		Connection conn = null;
		// PreparedStatement st = null;
		Statement st = null;

		try {

			try {
				conn = dataSource.getConnection();
				st = conn.createStatement();
				st.execute("INSERT INTO tb_st VALUES ('" + uid + "','"
						+ sharedToken + "')");
				log.debug("INSERT INTO tb_st VALUES ('" + uid + "','"
						+ sharedToken + "')");
				log.debug("Successfully store the SharedToken in the database");
			} catch (SQLException e) {
				e.printStackTrace();
				throw new IMASTException(e.getMessage());
			} finally {
				try {
					conn.close();
				} catch (SQLException e) {
					throw new IMASTException(e.getMessage());
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
			throw new IMASTException(e.getMessage()
					+ "Failed to store SharedToken to database");

		}

	}

	private boolean isValid(Connection conn) throws SQLException {

		log.debug("testing if the connection is still valid");

		Statement stmt = null;
		ResultSet rs = null;
		try {
			stmt = conn.createStatement();
			rs = stmt.executeQuery("SELECT 1");
			if (rs.next()) {
				log.debug("the connection is still valid");
				return true;
			} else {
				log.debug("the connection is not valid, will reconnect");
				return false;
			}
		} catch (SQLException e) {
			log.debug("the connection is invalid, will reconnect");
			return false;
		} finally {
			if (stmt != null)
				stmt.close();
			if (rs != null)
				rs.close();
		}
	}
}
