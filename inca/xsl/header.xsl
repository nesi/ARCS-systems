<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- header.xsl:  Prints HTML page header.                                -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:template name="header">
    <head>
      <link href="css/nav.css" rel="stylesheet" type="text/css"/>
      <link href="css/inca.css" rel="stylesheet" type="text/css"/>
    </head>

    <xsl:variable name="reportNumDays" select="7"/>
    <xsl:variable
        name="grid"
        select="'xslt.jsp?xsl=default.xsl'"/>
    <xsl:variable
        name="graph"
        select="'xslt.jsp?xsl=graph.xsl'"/>
    <xsl:variable
        name="map"
        select="'xslt.jsp?xsl=google.xsl&amp;xmlFile=google.xml'"/>
    <xsl:variable
        name="sample"
        select="'&amp;suiteName=sampleSuite&amp;resourceID=defaultGrid'"/>
    <div id="header">
      <div id="logo-floater">
        <h1><a href="http://www.arcs.org.au" title="ARCS"><img src="http://www.sapac.edu.au/webmds/xslfiles/ARCS_Logo_TRAC.png" alt="ARCS" id="logo" /></a></h1>
      </div>
    </div>
    <table width="100%" class="subheader">
      <tr>
        <td><b>ARCS INCA STATUS PAGES</b></td>
        <td>
          <div id="menu">

            <ul>
              <li><h2>Info</h2>
                <ul>
                  <li>
                    <a href="config.jsp?xsl=config.xsl">
                      list running reporters
                    </a>
                  </li>
                </ul>
              </li>
            </ul>
            <ul>
              <li><h2>Historical Data</h2>
                <ul>
                  <li>
                    <a href="xslt.jsp?xsl=graph.xsl&amp;suiteName=wsgram_tests&amp;resourceID=localResource">graph WSGRAM test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=graph.xsl&amp;suiteName=gridftp_from_submit_hosts&amp;resourceID=GridAustraliaHosts">graph GridFTP test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=graph.xsl&amp;suiteName=dataservice_3rdparty_tests&amp;resourceID=localResource">graph DataService 3rd party transfer test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=graph.xsl&amp;suiteName=infosystem_tests&amp;resourceID=localResource">graph Information Systems test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=graph.xsl&amp;suiteName=ildg_tests&amp;resourceID=localResource">graph ILDG test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=graph.xsl&amp;suiteName=application_tests&amp;resourceID=localResource">graph Commonly Used Apps test results</a>
                  </li>
                </ul>
              </li>
            </ul>
            <ul>
              <li><h2>Current Data</h2>
                <ul>
                  <li>
                    <a href="xslt.jsp?xsl=default.xsl&amp;suiteName=wsgram_tests&amp;resourceID=localResource">table of WSGRAM test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=default.xsl&amp;suiteName=gridftp_from_submit_hosts&amp;resourceID=GridAustraliaHosts">table of GridFTP test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=datatest.xsl&amp;suiteName=dataservice_3rdparty_tests&amp;resourceID=localResource">table of DataService 3rd party transfer test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=default.xsl&amp;suiteName=infosystem_tests&amp;resourceID=localResource">table of Information Systems test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=default.xsl&amp;suiteName=ildg_tests&amp;resourceID=localResource">table of ILDG test results</a>
                  </li>
                  <li>
                    <a href="xslt.jsp?xsl=default.xsl&amp;suiteName=application_tests&amp;resourceID=localResource">table of Commonly Used Apps test results</a>
                  </li>
                </ul>
              </li>
            </ul>
          </div>
        </td></tr></table>
  </xsl:template>

</xsl:stylesheet>
