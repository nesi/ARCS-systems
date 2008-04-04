<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- config.xsl:  Prints description of deployed suites and series.       -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml" >

  <xsl:include href="inca-common.xsl"/>
  <xsl:include href="header.xsl"/>
  <xsl:include href="footer.xsl"/>

  <!-- ==================================================================== -->
  <!-- Main template                                                        -->
  <!-- ==================================================================== -->
  <xsl:template match="/">
    <!-- header.xsl -->
    <xsl:call-template name="header"/>
    <body topMargin="0">
      <xsl:choose>
        <xsl:when test="count(error)>0">
          <!-- inca-common.xsl printErrors -->
          <xsl:apply-templates select="error" />
        </xsl:when>
        <xsl:otherwise>
          <!-- generateHTML -->
          <xsl:apply-templates select="combo" />
        </xsl:otherwise>
      </xsl:choose>
    </body>
    <!-- footer.xsl -->
    <xsl:call-template name="footer"/>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- generateHTML                                                         -->
  <!--                                                                      -->
  <!-- Prints out header page description and bottom cron table description -->
  <!-- Also prints out the table start and end tags and calls printSuite    -->
  <!-- to generate suite header and rows.                                   -->
  <!-- ==================================================================== -->
  <xsl:template name="generateHTML" match="combo">
    <p>
    <!-- inca-common.xsl -->
    <xsl:call-template name="printBodyTitle">
      <xsl:with-param name="title" select="'Running Reporters'"/>
    </xsl:call-template>

      This page lists the currently running <i>suites</i> for this
      Inca deployment.  Each suite is comprised of a number of <i>reporter
      series</i>.  A <i>reporter</i> is an executable program that tests or
      measures some aspect of the system or installed software.  A
      <i>reporter series</i> identifies a particular configuration (arguments
      and environment) of a reporter when executed on a resource.  Each
      section of the following table lists the reporter series <b>Name</b>,
      execution <b>Frequency</b> (expressed in modified <a
        href="#cron">cron</a> syntax), whether email <b>Notification</b> is
      configured, the <b>Reporter script used</b>, and the <b>Reporter
      script's description</b>.
    </p>

    <table cellpadding="6" class="subheader" border="0">
      <xsl:apply-templates select="suites//suite">
        <xsl:sort select="name" />
      </xsl:apply-templates>
    </table>

    <xsl:call-template name="printCronDescription" />

  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSuite                                                           -->
  <!--                                                                      -->
  <!-- Prints out the suite header which is the suite name and description  -->
  <!-- followed by the description of the columns.  Then calls printSeries  -->
  <!-- to print out the rows.                                               -->
  <!-- ==================================================================== -->
  <xsl:template name="printSuite" match="suite">

    <!-- Print Header -->
    <tr valign="top">
      <td class="header" colspan="5">
        <xsl:value-of select="name"/>
        <xsl:if test="string(description)">
          - <xsl:value-of select="description"/>
        </xsl:if>
      </td>
    </tr>
    <tr valign="top" class="subheader">
      <td>
        Name (<xsl:value-of select="count(seriesConfigs//seriesConfig)"/>)
      </td>
      <td>Frequency <a href="#cron">(*)</a></td>
      <td>Notification</td>
      <td>Reporter script used</td>
      <td>Reporter script description</td>
    </tr>

    <!-- print values -->
    <xsl:apply-templates select="seriesConfigs//seriesConfig">
      <xsl:sort select="nickname" />
    </xsl:apply-templates>

  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSeries                                                          -->
  <!--                                                                      -->
  <!-- Prints out a row specifying the configuration of a series            -->
  <!-- ==================================================================== -->
  <xsl:template name="printSeries" match="seriesConfig">

    <tr valign="top">
      <!-- Column 1 = series nickname -->
      <td class="clear">
        <xsl:value-of select="nickname" />
      </td>

      <!-- Column 2 = cron frequency -->
      <td class="clear" nowrap="yes" align="center">
        <xsl:for-each select="schedule/cron">
          <xsl:value-of select="."/>
        </xsl:for-each>
      </td>

      <!-- Column 3 - notification -->
      <td class="clear" align="center">
        <xsl:choose>
          <xsl:when
              test="count(acceptedOutput/notifications/notification)&gt;0">
            yes
          </xsl:when>
          <xsl:otherwise>no</xsl:otherwise>
        </xsl:choose>
      </td>

      <!-- Column 4 - reporter script -->
      <td class="clear">
        <a href="{substring-before(series/uri,
        series/name)}../cgi-bin/reporters.cgi?reporter={series/name}&amp;action=view">
          <xsl:value-of select="series/name"/>
        </a>
      </td>

      <!-- Column 5 - reporter description -->
      <xsl:variable name="repname" select="series/name"/>
      <td class="clear">
        <!-- get the reporter description from the catalog which is a list
 of reporter entries each containing a property list; this
 says get the reporter entry whose name matches the reporter
 name and then get the description  -->
        <xsl:value-of
            select="/combo/catalogs/catalog/reporter/property[matches(name,'name')
            and matches(value, $repname)]/../property[name='description']/value"/>
      </td>
    </tr>
  </xsl:template>

</xsl:stylesheet>
