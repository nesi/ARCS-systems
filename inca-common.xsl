<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- inca-common.xsl:  Common templates for use in Inca stylesheets.      -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:sdf="java.text.SimpleDateFormat"
                xmlns:date="java.util.Date"
                xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes">


  <!-- ==================================================================== -->
  <!-- printErrors - print errors in xml                                    -->
  <!-- ==================================================================== -->
  <xsl:template name="printErrors" match="error">
    <h3>Error:  <xsl:value-of select="." /></h3>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printBodyTitle:  print the title of a page along with a timestamp    -->
  <!-- ==================================================================== -->
  <xsl:template name="printBodyTitle">
    <xsl:param name="title"/>
    <xsl:variable name="datenow" select="date:new()" />
    <table width="100%" border="0">
      <tr align="left">
        <td><h1 class="body"><xsl:value-of select="$title"/></h1></td>
        <td align="right">
          <p class="footer">Page loaded: 
            <xsl:call-template name="formatDate">
              <xsl:with-param name="date" select="$datenow"/>
            </xsl:call-template>
          </p>
        </td>
      </tr>
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- formatDate: format a date like "MM-dd-yyyy hh:mm a (z)"              -->
  <!-- ==================================================================== -->
  <xsl:template name="formatDate">
    <xsl:param name="date"/>
    <xsl:variable name="dateformat" select="sdf:new('MM-dd-yyyy hh:mm a (z)')"/>
    <xsl:value-of select="sdf:format($dateformat, $date)"/>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- formatAge: format a date like "X days X hours X mins" or "X secs"    -->
  <!-- ==================================================================== -->
  <xsl:template name="formatAge">
    <xsl:param name="age"/>
    <xsl:variable name="diff" select="current-dateTime()-$age"/>
    <xsl:variable name="format" select="replace(replace(replace(replace(
        $diff, 'P',''),'D',' days '),'T',''),'H',' hours ')"/>
    <xsl:choose>
      <xsl:when test="$format[not(matches(.,'^(\d|\.)+S$'))]">
        <xsl:value-of select="replace($format, 'M.*',' mins')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of 
          select="replace($format, '\.\d+S',' secs')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printCronDescription:  print description of Inca cron syntax         -->
  <!-- ==================================================================== -->
  <xsl:template name="printCronDescription">
    <p><a name="cron">(*)</a> Inca uses a modified version of Vixie cron syntax.
      The format is as follows:</p>
    <p><b>minute hour dayOfMonth month dayOfWeek</b></p>
    <table border="0">
      <tr>
        <td><b>minute</b></td>
        <td>The minute of the hour the reporter will be executed (range: 0-59)</td>
      </tr>
      <tr>
        <td><b>hour</b></td>
        <td>The hour of the day the reporter will be executed (range: 0-23)</td>
      </tr>
      <tr>
        <td><b>dayOfMonth</b></td>
        <td>The day of the month the reporter will be executed (range: 0-23)</td>
      </tr>
      <tr>
        <td><b>month</b></td>
        <td>The month the reporter will be executed (range: 1-12)</td>
      </tr>
      <tr>
        <td><b>dayOfWeek</b></td>
        <td>The day of the week the reporter will be executed (range: 0-6)</td>
      </tr>
    </table>
    <p>Ranges are allowed in any field.  For example, "0-4" in the minute field
      would mean to execute on the minutes 0, 1, 2, 3, and 4 only.  A step
      value can also be used with a range.  For example, "0-59/10" in the minute
      field would indicate to run every 10 minutes.  Finally, "?" in the field
      tells Inca to pick a random time within the specified range.  For example,
      "? * * * *" means to run every hour and let Inca choose which minute
      to run the reporter on.  Likewise, "?-59/10 * * * *" means to run every
      10 minutes and let Inca choose which minute to start on (e.g., if Inca
      chose "5", the reporter would execute at minutes 5, 15, 25, 35, 45, and 55.
    </p>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- markOld - print an ' *' if $gmt is older than $markAge hours         -->
  <!-- ==================================================================== -->
  <xsl:template name="markOld">
    <xsl:param name="gmtExpires" />
    <xsl:variable name="now" select="current-dateTime()" />
    <xsl:if test="$gmtExpires le $now">
      <xsl:value-of select="' *'" />
    </xsl:if>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSeriesNamesTable - prints a table with a list of series names   -->
  <!-- ==================================================================== -->
  <xsl:template name="printSeriesNamesTable">
    <xsl:param name="seriesNames"/>
    <table cellpadding="8">
      <tr valign="top">
        <td>
          <xsl:for-each select="$seriesNames">
            <xsl:sort/>
            <xsl:if test="position() mod 4 = 1">
              <td />
            </xsl:if>
            <li><a href="#{.}"><xsl:value-of select="." /></a></li>
          </xsl:for-each>
        </td>
      </tr>
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResourceNameCell - prints a table cell with resource name.      -->
  <!-- ==================================================================== -->
  <xsl:template name="printResourceNameCell" match="resource" mode="name">
    <td class="subheader"><xsl:value-of select="name" /></td>
  </xsl:template>

</xsl:stylesheet>
