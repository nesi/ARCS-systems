package au.org.arcs.df.outbox;

import edu.sdsc.grid.io.MetaDataCondition;
import edu.sdsc.grid.io.MetaDataRecordList;
import edu.sdsc.grid.io.MetaDataSelect;
import edu.sdsc.grid.io.MetaDataSet;
import edu.sdsc.grid.io.irods.*;
import org.apache.log4j.Logger;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Properties;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Created by IntelliJ IDEA.
 * User: pmak
 * Date: Jun 24, 2010
 * Time: 8:22:41 PM
 * To change this template use File | Settings | File Templates.
 */
public class OutboxServlet extends HttpServlet {
    private IRODSAccount acc = null;
    private ServletConfig config = null;
    static Logger logger = Logger.getLogger(OutboxServlet.class);
    private static Pattern PATTERN = Pattern.compile("[a-zA-Z0-9]*");
    private String URL_KEY;

    public void init(ServletConfig _config) throws ServletException
    {
        config = _config;
        Properties props = new Properties();
        try
        {
            logger.debug("config path: " + config.getServletContext().getRealPath("outbox.properties"));
            props.load(new FileInputStream(config.getServletContext().getRealPath("outbox.properties")));
            String username =props.getProperty("outbox-username", "OUTBOX_READER");
            String pass = props.getProperty("outbox-password");
            String host = props.getProperty("irods-host");
            int port = Integer.valueOf(props.getProperty("irods-port"));
            String zone = props.getProperty("irods-zone");
            URL_KEY = props.getProperty("url_key");
            acc = new IRODSAccount(host, port, username, pass,  "/" + zone + "/home", zone, "");
        }
        catch(IOException ioe)
        {
            logger.fatal("Cannot open outbox.properies.  Please make sure it's in your classpath! ");
            throw new ServletException("FATAL: Cannot start servlet - outbox.properties not found");
        }
    }

    public IRODSFileSystem getFilesystem() throws IOException
    {
        IRODSFileSystem sys = new IRODSFileSystem(acc);
        return sys;
    }

    protected void sendFile(String fullPath, HttpServletResponse response) throws IOException
    {
        IRODSFileSystem sys = null;
        try
        {
            sys = getFilesystem();
            IRODSFile file = new IRODSFile(sys, fullPath);
            String contentType = config.getServletContext().getMimeType(file.getName());
            response.setHeader("Content-Length", String.valueOf(file.length()));
            response.setContentType((contentType != null) ? contentType : "application/octet-stream");
            response.setHeader("Content-Disposition", "attachment; filename=\"" + file.getName() + "\"");
            response.setContentLength((int) file.length());

            int bufferSize = (int) (file.length() / 100);
            // minimum buf size of 50KiloBytes
            if (bufferSize < 51200)
                bufferSize = 51200;
            // maximum buf size of 5MegaByte
            else if (bufferSize > 5242880)
                bufferSize = 5242880;
            byte[] buf = new byte[bufferSize];
            int count = 0;
            ServletOutputStream output = response.getOutputStream();
            IRODSRandomAccessFile input = new IRODSRandomAccessFile((IRODSFile) file, "r");

            while ((count = input.read(buf)) > 0) {
                output.write(buf, 0, count);
            }
            output.flush();
            output.close();
        }
        finally
        {
            if(sys != null)
                sys.close();
        }
    }

    protected String findFile(String path) throws IOException
    {
        IRODSFileSystem sys = null;

        try
        {
            sys = this.getFilesystem();
            MetaDataSelect selectFile[] = MetaDataSet.newSelection(new String[] {
                IRODSMetaDataSet.FILE_NAME,
                IRODSMetaDataSet.DIRECTORY_NAME
            });

            MetaDataCondition[] condList = new MetaDataCondition[1];

            //Watch out for path - need to parse it properly... for security reasons...
            condList[0] = MetaDataSet.newCondition("OUTBOX_URL",
                                        MetaDataCondition.EQUAL, path);

            MetaDataRecordList[] recordList = sys.query(condList, selectFile);

            if((recordList != null) && (recordList.length == 1))
            {
                MetaDataRecordList record = recordList[0];
                String filename = (String)(record.getValue(record.getFieldIndex(IRODSMetaDataSet.FILE_NAME)));
                String dirname = (String)(record.getValue(record.getFieldIndex(IRODSMetaDataSet.DIRECTORY_NAME)));
                logger.debug("found file!: " + dirname + "/" + filename);
                return dirname + "/" + filename;
            }
            else
            {
                logger.debug("Cannot find file");
            }
        }
        catch(IOException e)
        {
            if(sys != null)
                sys.close();
        }

        //File doesn't exist!  Can't find anything that matches the request path
        //i.e. no match for OUTBOX_URL:
        return null;
    }

    protected void doGet(HttpServletRequest req, HttpServletResponse response) throws ServletException, IOException
    {
        String context = req.getContextPath() + "/";
        String cut = req.getRequestURI().substring(context.length());
        Matcher matcher = PATTERN.matcher(cut);
        if(matcher.matches())
        {
            logger.debug("Trying to match metadata for: " + cut);

            String filename = findFile(cut);
            if(filename != null)
            {
                logger.debug("found file, about to send content to client");

                //write to outputStream
                sendFile(filename, response);
            }  
        }
        else
        {
            logger.debug("Illegal characters encountered.  Invalid URL");
        }
        response.sendError(HttpServletResponse.SC_NOT_FOUND);
    }
}
