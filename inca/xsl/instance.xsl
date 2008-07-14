<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- instance.xsl:  HTML table with report details.                       -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:sdf="java.text.SimpleDateFormat"
                xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes">

  <xsl:include href="header.xsl"/>
  <xsl:include href="footer.xsl"/>
  <xsl:include href="inca-common.xsl"/>
  <!-- <xsl:include href="instance-extra.xsl"/> -->

  <xsl:param name="url" />
  <xsl:param name="page" />

  <xsl:variable name="resourceName">
    <xsl:analyze-string select="$url" regex="(.*)esourceName=(.[^&amp;|?]+)(.*)">
      <xsl:matching-substring>
        <xsl:value-of select="regex-group(2)"/>
      </xsl:matching-substring>
      <xsl:non-matching-substring>
        <xsl:value-of select="''"/>
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
      <xsl:apply-templates select="combo/reportDetails/report" />
    </body>
    <!-- footer.xsl -->
    <xsl:call-template name="footer" />
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printReport - print table with report details info                   -->
  <!-- ==================================================================== -->
  <xsl:template name="printReport" match="report">
    <xsl:variable name="config" select="../seriesConfig"/>
    <xsl:variable
        name="cgi"
        select="concat(substring-before($config/series/uri, name),
        '../cgi-bin/reporters.cgi?reporter=', name, '&amp;action=help')"/>
    <xsl:variable name="comp" select="../comparisonResult"/>
    <xsl:variable name="used" select="../sysusage"/>
    <xsl:variable name="gmt" select="gmt" as="xs:dateTime" />
    <xsl:variable name="complete" select="exitStatus/completed"/>
    <xsl:variable name="errMsg" select="exitStatus/errorMessage" />
    <xsl:variable name="package" select="body/package"/>


    <xsl:variable name="resultText">
      <xsl:choose>
        <xsl:when test="count($comp)>0">
          <xsl:value-of select="$comp"/>
        </xsl:when>
        <xsl:when test="$complete='true'">
          <xsl:value-of select="'completed'"/>
        </xsl:when>
        <xsl:when test="$complete='false'">
          <xsl:value-of select="'did not complete'"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'unknown'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="nickName">
      <xsl:choose>
        <xsl:when test="$config/nickname!=''">
          <xsl:value-of select="$config/nickname"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="name"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- inca-common.xsl -->
    <xsl:call-template name="printBodyTitle">
      <xsl:with-param name="title" select="concat('Details for ',
      $nickName, ' series')" />
    </xsl:call-template>
    <table width="600" cellpadding="4">
      <tr><td colspan="2" class="header"><xsl:text>Result:</xsl:text></td></tr>
      <tr>
        <td><p><xsl:value-of select="$resultText"/></p></td>
        <td>
          <xsl:variable name="label"
                        select="concat($resourceName, ' (',$nickName,')')"/>
          <xsl:variable name="graphUrl"
                        select="concat('graph.jsp?start=1&amp;bgcolor=&amp;xmin=&amp;xmax=&amp;',
               'title=', $label,
               '&amp;testName=', $nickName,
               '&amp;resourceName=', $resourceName,
               '&amp;seriesLabel=', $label)"/>
          <table>
            <tr>
              <td>
                <a href="{$graphUrl}">
                  <img src="img/chart.gif" alt="graph history" border="0"/>
                </a>
              </td>
              <td>
                <a href="{$graphUrl}">view result history</a>
              </td>
            </tr>
          </table>
        </td>
      </tr>
      <tr><td colspan="2">
        <xsl:if test="$resultText=$comp">
          <p class="code"><xsl:value-of select="concat('Expecting: ',
            $config/acceptedOutput/comparison)"/></p>
        </xsl:if>
        <xsl:if test="string($package/version)!=''">
          <p class="code"><xsl:value-of select="concat('Found: ',
            $package/version)"/></p>
        </xsl:if>
        <xsl:if test="string($package/subpackage/version)!=''">
          <p class="code"><xsl:text>Found: </xsl:text>
            <xsl:for-each select="$package/subpackage">
              <xsl:value-of select="concat(ID, ': ', version)"/><br/>
            </xsl:for-each>
          </p>
        </xsl:if>
        <xsl:if test="$resultText='did not complete' or $resultText='unknown'
          or $resultText=$comp">
          <p class="code"><xsl:apply-templates select="$errMsg"/></p>
          <!-- <xsl:if test="$errMsg=''"> -->
            <p class="code"><xsl:apply-templates  select="../stderr"/></p>
          <!-- </xsl:if> -->
        </xsl:if>
      </td>
      </tr>
      <tr><td colspan="2" class="header">
        <xsl:text>Reporter details:</xsl:text>
      </td></tr>
      <tr>
        <td><xsl:text>reporter name</xsl:text></td>
        <td><a href="{$cgi}"><xsl:value-of select="name"/></a><br/>
          <xsl:text> (click name for more info)</xsl:text></td>
      </tr>
      <tr>
        <td><xsl:text>reporter version</xsl:text></td>
        <td><xsl:value-of select="$config/series/version"/></td>
      </tr>
      <tr>
        <td colspan="2" class="header">
          <xsl:text>Execution information:</xsl:text>
        </td>
      </tr>
      <tr>
        <td><xsl:text>ran at</xsl:text></td>
        <td>
          <xsl:call-template name="formatDate">
            <xsl:with-param name="date" select="$gmt"/>
          </xsl:call-template>
        </td>
      </tr>
      <tr>
        <td><xsl:text>age</xsl:text></td>
        <td>
          <xsl:call-template name="formatAge">
            <xsl:with-param name="age" select="$gmt"/>
          </xsl:call-template>
        </td>
      </tr>
      <tr>
        <td><xsl:text>cron</xsl:text></td>
        <td>
          <xsl:for-each select="$config/schedule/cron/*[not(self::suspended)
          and not(self::numOccurs)]">
            <xsl:value-of select="."/><xsl:text> </xsl:text>
          </xsl:for-each>
        </td>
      </tr>
      <tr>
        <td><xsl:text>ran on (hostname)</xsl:text></td>
        <td><xsl:value-of select="hostname"/></td>
      </tr>
      <tr>
        <td><xsl:text>memory usage (MB)</xsl:text></td>
        <td><xsl:value-of select="$used/memory"/></td>
      </tr>
      <tr>
        <td><xsl:text>cpu time (secs)</xsl:text></td>
        <td><xsl:value-of select="$used/cpuTime"/></td>
      </tr>
      <tr>
        <td><xsl:text>wall clock time (secs)</xsl:text></td>
        <td><xsl:value-of select="$used/wallClockTime"/></td>
      </tr>
      <tr><td colspan="2" class="header">
        <xsl:text>Input parameters:</xsl:text>
      </td></tr>
      <xsl:for-each select="$config/series/args/arg">
        <xsl:sort/>
        <tr><td><xsl:value-of select="name"/></td>
          <td><xsl:value-of select="value"/></td></tr>
      </xsl:for-each>
      <tr><td colspan="2" class="header">
        <xsl:text>Command used to execute the reporter:</xsl:text>
      </td></tr>
      <tr><td colspan="2"><p class="code">
        <xsl:value-of select="concat('% ',
        replace($config/series/context, $config/series/name, reporterPath))"/>
      </p></td></tr>
      <xsl:if test="count(log/system/message)>0">
        <tr><td colspan="2" class="header">
          <xsl:text>System commands executed by the reporter:</xsl:text>
        </td></tr>
        <tr><td colspan="2">
          <xsl:text>Note that the reporter may execute other actions in between
            system commands (e.g., change directories).</xsl:text>
          <xsl:apply-templates select="log/system"/>
        </td></tr>
      </xsl:if>
      <xsl:if test="count(log/info/message|log/debug/message)>0">
        <tr>
          <td colspan="2"><xsl:text>Debug or informational output:</xsl:text>
            <xsl:apply-templates select="log/info|log/debug"/>
          </td>
        </tr>
      </xsl:if>
      <!-- instance-extra.xsl for run-now and comment rows -->
      <!--<xsl:call-template name="instanceExtra">
        <xsl:with-param name="nickName" select="$nickName"/>
        <xsl:with-param name="config" select="$config"/>
      </xsl:call-template>-->
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printComment - print paragraph with comment                          -->
  <!-- ==================================================================== -->
  <xsl:template name="printComment" match="row">
    <p class="code">
      <xsl:value-of select="comment"/><br/>
      (<xsl:value-of select="author"/>, <xsl:value-of select="date"/>)
    </p>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printLog - print paragraph with log message                          -->
  <!-- ==================================================================== -->
  <xsl:template name="printLog" match="info|system">
    <p class="code">
      <xsl:if test="self::system">
        <xsl:text>% </xsl:text>
      </xsl:if>
      <xsl:value-of select="message"/>
    </p>
  </xsl:template>
  <xsl:template name="printDebug" match="debug">
    <pre><p class="code"><xsl:value-of select="message"/></p></pre>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- replaceBreak - replace symbol break with html break                  -->
  <!-- ==================================================================== -->
  <xsl:template name="replaceBreak" match="errorMessage|stderr">
    <xsl:param name="text" select="."/>
    <xsl:choose>
      <xsl:when test="contains($text, '&#xa;')">
        <xsl:value-of select="substring-before($text, '&#xa;')"/> <br/>
        <xsl:call-template name="replaceBreak">
          <xsl:with-param name="text" select="substring-after($text, '&#xa;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
