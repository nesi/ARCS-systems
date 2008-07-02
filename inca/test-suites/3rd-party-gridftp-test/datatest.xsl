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
  <xsl:include href="datalegend.xsl"/>
  <xsl:include href="footer.xsl"/>
  <xsl:param name="url" />

  <xsl:variable name="markHours">
    <xsl:analyze-string select="$url" regex="(.*)arkOld=([0-9]+)(.*)">
      <xsl:matching-substring>
        <xsl:value-of select="regex-group(2)"/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="'24'"/>
      </xsl:non-matching-substring>
    </xsl:analyze-string>
  </xsl:variable>

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
                  select="reportSummary/nickname"/>
    <!-- inca-common.xsl -->
<!--    <xsl:call-template name="printSeriesNamesTable">
      <xsl:with-param name="seriesNames" select="$seriesNames"/>
    </xsl:call-template>  -->
<!--    <xsl:choose>
      <xsl:when test="count(/combo/resourceConfig)=1">  -->
        <xsl:call-template name="printSeriesResultsTable">
          <xsl:with-param name="seriesNames" select="$seriesNames"/>
          <xsl:with-param
              name="resources"
              select="/combo/resourceConfig/resources/resource[name]"/>
        </xsl:call-template>
<!--      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="printSeriesResultsTable">
          <xsl:with-param name="seriesNames" select="$seriesNames"/>
          <xsl:with-param name="resources"
                          select="../resourceConfig/resources/resource[name]"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>  -->
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
    <xsl:variable name="sources" select="distinct-values(reportSummary/body/performance/benchmark/ID)"/>
    <xsl:variable name="dests" select="distinct-values(reportSummary/body/performance/benchmark/statistics/statistic/ID)"/>
    <xsl:variable name="sites">
        <xsl:for-each select="$dests">
	    <xsl:sort select="string-join(reverse(tokenize(current(),'\.')),',')"/>
            <xsl:variable name="destName" select="."/>
	    <xsl:choose>
		<xsl:when test="contains($destName,'edu')">
            	    <xsl:value-of select="string-join(subsequence(reverse(tokenize($destName,'\.')),3,1),'')"/><xsl:text>,</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="string-join(subsequence(reverse(tokenize($destName,'\.')),2,1),'')"/><xsl:text>,</xsl:text>
		</xsl:otherwise>
	    </xsl:choose>
        </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="siteCol" select="tokenize($sites,',')"/>
    <table class="subheader">
      <xsl:for-each select="$sources">
        <xsl:sort select="string-join(reverse(tokenize(current(),'\.')),',')"/>
	<xsl:variable name="sourceName" select="."/> 
        <xsl:if test="position() = 1">
          <tr>
            <td class="subheader" rowspan="2"><b>source\destination</b></td>
            <xsl:for-each select="distinct-values(subsequence($siteCol,1,count($siteCol)-1))">
                <xsl:text disable-output-escaping="yes">&lt;td class="subheader" align="center" colspan="</xsl:text>
		<xsl:number value="count(index-of($siteCol,current()))" format="1" />
		<xsl:text disable-output-escaping="yes">">&lt;b&gt;</xsl:text>
		<xsl:value-of select="." />
		<xsl:text disable-output-escaping="yes">&lt;/b&gt;&lt;/td&gt;</xsl:text>
            </xsl:for-each>
          </tr>
<!--          <tr>
            <xsl:for-each select="$dests">
                <xsl:sort select="string-join(reverse(tokenize(current(),'\.')),',')"/>
		<xsl:variable name="destName" select="."/>
		<xsl:if test="ends-with($destName,'au')">
		    <xsl:variable name="siteName" select="string-join(subsequence(reverse(tokenize($destName,'\.')),3,1),'')"/>
                    <td class="subheader" align="center"><b><xsl:value-of select="$siteName" /></b></td>
		</xsl:if>
                <xsl:if test="ends-with($destName,'org')">
		    <xsl:variable name="siteName" select="string-join(subsequence(reverse(tokenize($destName,'\.')),2,1),'')"/>
                    <td class="subheader" align="center"><b><xsl:value-of select="$siteName" /></b></td>
                </xsl:if>
            </xsl:for-each>
          </tr>  -->
          <tr>
	    <xsl:for-each select="$dests">
		<xsl:sort select="string-join(reverse(tokenize(current(),'\.')),',')"/>
		<td class="subheader"><b><xsl:value-of select="." /></b></td>
	    </xsl:for-each>
          </tr>
        </xsl:if> 
        <tr>
          <td class="subheader">
            <a name="{.}"><b><xsl:value-of select="."/></b></a>
          </td>

	  <xsl:for-each select="$dests">
	    <xsl:sort select="string-join(reverse(tokenize(current(),'\.')),',')"/>
	    <xsl:variable name="destName" select="."/>
	    <xsl:variable name="thisTest" select="$suite/reportSummary/body/performance/benchmark[ID=$sourceName and statistics/statistic/ID=$destName]"/>
	    <xsl:choose>
	    <xsl:when test="exists($thisTest)">
	      <xsl:variable name="rate" select='$thisTest/statistics/statistic[1]/value'/>
	      <xsl:variable name="instanceId" select="$thisTest/../../../instanceId" />
              <xsl:variable name="configId" select="$thisTest/../../../seriesConfigId" />
              <xsl:variable name="href" select="concat('xslt.jsp?xsl=datainstance.xsl&amp;instanceID=', $instanceId, '&amp;configID=', $configId)"/>
	      <xsl:variable name="downloadSpeedUnits" select="$thisTest/statistics/statistic[1]/units" />
	      <xsl:variable name="displayValue" select="concat(format-number($rate,'###.##'),$downloadSpeedUnits)"/>

              <!--<xsl:value-of select="concat($sourceName,'-&gt;',$destName)"/>
	        <xsl:value-of select="$rate"/>-->
              <xsl:if test="$rate = -5">
                <td bgcolor="red"><a href="{$href}" title="{$thisTest/../../../nickname}">mds error</a></td>
              </xsl:if>
              <xsl:if test="$rate = -4">
                <td bgcolor="orange"><a href="{$href}" title="{$thisTest/../../../nickname}">source timeout</a></td>
              </xsl:if>
              <xsl:if test="$rate = -3">
                <td bgcolor="red"><a href="{$href}" title="{$thisTest/../../../nickname}">source error</a></td>
              </xsl:if>
	      <xsl:if test="$rate = -2">
	        <td bgcolor="#AFDCEC" align="center">/</td>
	      </xsl:if>
	      <xsl:if test="$rate = -1">
	        <td bgcolor="orange"><a href="{$href}" title="{$thisTest/../../../nickname}">timeout</a></td>
	      </xsl:if>
              <xsl:if test="$rate = 0">
                <td bgcolor="red"><a href="{$href}" title="{$thisTest/../../../nickname}">error</a></td>
              </xsl:if>
              <xsl:if test="$rate > 0 and $rate &lt; 5120">
                <td bgcolor="yellow"><a href="{$href}" title="{$thisTest/../../../nickname}"><xsl:value-of select="$displayValue"/></a></td>
              </xsl:if>
              <xsl:if test="$rate >= 5120 and $rate &lt; 15360">
                <td bgcolor="#00FF00"><a href="{$href}" title="{$thisTest/../../../nickname}"><xsl:value-of select="$displayValue"/></a></td>
              </xsl:if>
              <xsl:if test="$rate >= 15360">
                <td bgcolor="#4CC417"><a href="{$href}" title="{$thisTest/../../../nickname}"><xsl:value-of select="$displayValue"/></a></td>
              </xsl:if>
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

<!--  <xsl:template name="printResourceNameCell" match="sources" mode="name">
    <td class="subheader"><xsl:value-of select="name" /></td>
  </xsl:template> 

  <xsl:template name="printResourceResultCell" match="body" mode="result">
    <xsl:variable name="downloadSpeed" select="performance/benchmark/statistics/statistic[1]/value" />
    <xsl:variable name="downloadSpeedUnits" select="performance/benchmark/statistics/statistic[1]/units" />
    <td><xsl:value-of select="performance/benchmark/statistics/statistic[1]/value"/></td>
  </xsl:template>
            <xsl:apply-templates select="$suite/reportSummary/body[performance/benchmark/ID='$sourceName' and performance/benchmark/statistics/statistic/ID='$destName']" mode="result">
              <xsl:with-param name="testname" select="."/>
              <xsl:with-param name="sources" select="$sources"/> 
            </xsl:apply-templates>

-->

</xsl:stylesheet>
