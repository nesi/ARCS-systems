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
    <table width="100%" class="subheader">
      <tr>
        <td><b>INCA STATUS PAGES</b></td>
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
                    <a href="{concat($graph, $sample)}">
                      graph sampleSuite
                    </a>
                  </li>
                  <li>
                  <xsl:variable name="startDate" 
                    select="current-date() - xdt:dayTimeDuration(
                              concat('P',$reportNumDays,'D'))" />
                  <xsl:variable name="date" select='concat
                    (format-date($startDate, "[M,2][D,2]"),
                    substring(format-date($startDate, "[Y]"),3,2))'/>
                  <xsl:variable name="href" 
                    select="concat('report.jsp?startDate=', $date)"/> 
                  <a href="{$href}">summary report of sampleSuite</a>
                  </li>
                </ul>
              </li>
            </ul>
            <ul>
              <li><h2>Current Data</h2>
                <ul>
                  <li>
                    <a href="{concat($grid, $sample)}">
                      table of sampleSuite results
                    </a>
                  </li>
                  <li>
                    <a href="{concat($map, $sample)}">
                      map of sampleSuite results
                    </a>
                  </li>
                </ul>
              </li>
            </ul>
          </div>
        </td></tr></table>
  </xsl:template>

</xsl:stylesheet>
