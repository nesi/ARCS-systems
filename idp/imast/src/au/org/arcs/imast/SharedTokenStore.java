/**
 * 
 */
package au.org.arcs.imast;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import javax.sql.DataSource;

import org.apache.log4j.Logger;

/**
 * @author Damien Chen
 * 
 */
public class SharedTokenStore {

	/** Class logger. */
	private static Logger log = Logger.getLogger(SharedTokenAttrDef.class
			.getName());

	private DataSource dataSource;

	public SharedTokenStore(DataSource dataSource) {

		this.dataSource = dataSource;

	}

	public String getSharedToken(String uid) throws IMASTException {
		log.info("calling getSharedToken ...");

		Connection conn = null;
		String sharedToken = null;
		PreparedStatement st = null;
		ResultSet rs = null;

		try {

			try {
				conn = dataSource.getConnection();

				st = conn
						.prepareStatement("SELECT sharedToken from tb_st WHERE uid=?");
				st.setString(1, uid);
				log.debug("SELECT sharedToken from tb_st WHERE uid=" + uid);
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
		
		log.info("get the SharedToken from database : " + sharedToken);

		return sharedToken;
	}

	public void storeSharedToken(String uid, String sharedToken)
			throws IMASTException {
		log.info("calling storeSharedToken ...");
		Connection conn = null;
		PreparedStatement st = null;

		try {

			try {
				conn = dataSource.getConnection();
				st = conn
						.prepareStatement("REPLACE INTO tb_st SET sharedToken = ?, uid = ?");
				st.setString(1, sharedToken);
				st.setString(2, uid);
				log.debug("REPLACE INTO tb_st SET SharedToken = " + sharedToken
						+ ", uid = " + uid);
				int rows = st.executeUpdate();
				log.info("Successfully store the SharedToken in the database");
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
}
