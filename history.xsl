<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- history.xsl:  Prints line of text for each series instance.          -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:sdf="java.text.SimpleDateFormat"
                xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes"
		xmlns:ser="http://inca.sdsc.edu/queryResult/series_2.0">

  <xsl:param name="type"/>
  <xsl:param name="xsl"/>
  <xsl:variable name="jsp">
    <xsl:value-of select="'xslt.jsp?xsl=instance.xsl'"/>
    <xsl:value-of select="'&amp;instanceID='"/>
  </xsl:variable>
  <xsl:variable name="div" select="','"/>

  <xsl:template match="/">
    <head>
      <link href="css/inca.css" rel="stylesheet" type="text/css"/>
    </head>
    <body topMargin="0">
      <h1 class="body">
        <xsl:value-of select="ser:series/reportDetails/seriesConfig/series/name"/>
      </h1>
      <table class="clear" border="1" cellpadding="4">
        <tr><td>HOST</td><td>RAN</td><td>CONFIG ID</td><td>INSTANCE ID</td></tr>
        <xsl:for-each select="ser:series/reportDetails">
          <xsl:sort select="report/gmt" data-type="text" order="descending"/>
          <xsl:variable name="details" select="."/>
          <xsl:variable name="uri" select="$details/seriesConfig/series/uri"/>
          <xsl:variable name="instance" select="$details/instanceId"/>
          <xsl:variable name="conf" select="$details/seriesConfigId"/>
          <xsl:variable name="ran" select="$details/report/gmt"/>
          <xsl:variable name="completed" select="$details/report/body"/>
          <xsl:variable name="host"
                        select="$details/seriesConfig/resourceHostname"/>
          <xsl:variable name="href">
            <xsl:value-of select="$jsp"/>
            <xsl:value-of select="$instance"/>
            <xsl:value-of select="'&amp;configID='"/>
            <xsl:value-of select="$conf"/>
            <xsl:value-of select="'&amp;resourceName='"/>
            <xsl:value-of select="$host"/>
          </xsl:variable>
          <tr>
            <td><xsl:value-of select="$host"/></td>
            <td><xsl:value-of select="$ran"/></td>
            <td><xsl:value-of select="$conf"/></td>
            <td><a href="{$href}"><xsl:value-of select="$instance"/></a></td>
          </tr>
        </xsl:for-each>
      </table>
    </body>
  </xsl:template>

</xsl:stylesheet>
