<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- default.xsl:  Prints table of suite(s) results.                      -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:include href="inca-common.xsl"/>
  <xsl:include href="header.xsl"/>
  <xsl:include href="legend.xsl"/>
  <xsl:include href="footer.xsl"/>
  <xsl:param name="url" />

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
  <!-- Prints an html header with a page title and a legend.                -->
  <!-- Calls printSuiteInfo.                                                -->
  <!-- ==================================================================== -->
  <xsl:template name="generateHTML" match="combo">
    <!-- inca-common.xsl -->
    <xsl:call-template name="printBodyTitle">
      <xsl:with-param name="title" select="''" />
    </xsl:call-template>
    <!-- legend.xsl -->
    <xsl:call-template name="printLegend"/>
    <!-- printSuiteInfo -->
    <xsl:apply-templates select="suiteResults/suite" />
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSuiteInfo                                                       -->
  <!--                                                                      -->
  <!-- Calls printSeriesNamesTable and printSeriesResultsTable              -->
  <!-- ==================================================================== -->
  <xsl:template name="printSuiteInfo" match="suite">
    <h1 class="body"><xsl:value-of select="name"/></h1>
    <xsl:variable name="seriesNames"
                  select="distinct-values(reportSummary/nickname)"/>
    <!-- inca-common.xsl -->
<!--    <xsl:call-template name="printSeriesNamesTable">
      <xsl:with-param name="seriesNames" select="$seriesNames"/>
    </xsl:call-template>
-->
    <xsl:choose>
      <xsl:when test="count(/combo/resourceConfig)=1">
        <xsl:call-template name="printSeriesResultsTable">
          <xsl:with-param name="seriesNames" select="$seriesNames"/>
          <xsl:with-param
              name="resources"
              select="/combo/resourceConfig/resources/resource[name]"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="printSeriesResultsTable">
          <xsl:with-param name="seriesNames" select="$seriesNames"/>
          <xsl:with-param name="resources"
                          select="../resourceConfig/resources/resource[name]"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSeriesResultsTable                                              -->
  <!--                                                                      -->
  <!-- Prints a table with series results.                                  -->
  <!-- ==================================================================== -->
  <xsl:template name="printSeriesResultsTable">
    <xsl:param name="seriesNames"/>
    <xsl:param name="resources"/>
    <xsl:variable name="suite" select="."/>
    <xsl:variable name="sites" select="distinct-values(reportSummary/body/srb_site)"/>
    <xsl:variable name="tests" select="distinct-values(reportSummary/body/srb_test)"/>
    <table class="subheader">
      <xsl:for-each select="$tests">
        <xsl:sort />
        <xsl:variable name="testName" select="."/>
        <xsl:if test="position() = 1">
          <tr>
            <td class="subheader"><b>test\site</b></td>
            <xsl:for-each select="$sites">
                <xsl:sort />
                <td class="subheader"><b><xsl:value-of select="." /></b></td>
            </xsl:for-each>
          </tr>
        </xsl:if>
        <tr>
          <td class="subheader">
            <a name="{.}"><b><xsl:value-of select="."/></b></a>
          </td>
          <xsl:for-each select="$sites">
            <xsl:sort />
            <xsl:variable name="siteName" select="."/>
            <xsl:variable name="thisTest" select="$suite/reportSummary[body/srb_site=$siteName and body/srb_test=$testName]"/>
            <xsl:choose>
              <xsl:when test="exists($thisTest)">
                <xsl:variable name="instanceId" select="$thisTest/instanceId" />
                <xsl:variable name="configId" select="$thisTest/seriesConfigId" />
                <xsl:variable name="href" select="concat('xslt.jsp?xsl=instance.xsl&amp;instanceID=', $instanceId, '&amp;configID=', $configId)"/>

                <xsl:choose>
                  <xsl:when test="string($thisTest/errorMessage) = ''">
                    <td class="pass"><a href="{$href}" title="{$thisTest/nickname}">pass</a></td>
                  </xsl:when>
                  <xsl:otherwise>
                    <td class="error"><a href="{$href}" title="{$thisTest/nickname}">error</a></td>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:when>
              <xsl:otherwise>
                <td class="clear"></td>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>

</xsl:stylesheet>
