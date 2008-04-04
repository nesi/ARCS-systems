<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- swStack.xsl:  Prints table of suite(s) results.  Uses XML file       -->
<!--               to format table rows by software categories and        -->
<!--               packages.                                              -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:sdf="java.text.SimpleDateFormat"
                xmlns:date="java.util.Date"
                xmlns:xdt="http://www.w3.org/2004/07/xpath-datatypes"
                xmlns:xs="http://www.w3.org/2001/XMLSchema">

  <xsl:include href="inca-common.xsl"/>
  <xsl:include href="header.xsl"/>
  <xsl:include href="legend.xsl"/>
  <xsl:include href="footer.xsl"/>
  <xsl:param name="url" />

  <xsl:variable name="matchProd"
                select="$url[matches(., 'reporterStatus=prod')]"/>

  <xsl:variable name="prodReportersOnly">
    <xsl:choose>
      <xsl:when test="$matchProd!=''">
        <xsl:value-of select="'true'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'false'" />
      </xsl:otherwise>
    </xsl:choose>
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
      <xsl:with-param name="title" select="''"/>
    </xsl:call-template>
    <!-- legend.xsl -->
    <xsl:call-template name="printLegend"/>
    <!-- printSuiteInfo -->
    <xsl:apply-templates select="suiteResults/suite" />
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSuiteInfo                                                       -->
  <!--                                                                      -->
  <!-- Either printAllPackages to print all package results                 -->
  <!-- or printPackage if a specific package is passed in the URL           -->
  <!-- ==================================================================== -->
  <xsl:template name="printSuiteInfo" match="suite">
    <xsl:choose>
      <xsl:when test="count(/combo/resourceConfig)=1">
        <xsl:call-template name="printAllPackages">
          <xsl:with-param
              name="resources"
              select="/combo/resourceConfig/resources/resource[name]"/>
          <xsl:with-param name="cats" select="../../stack/category" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="printAllPackages">
          <xsl:with-param name="resources"
                          select="../resourceConfig/resources/resource[name]"/>
          <xsl:with-param name="cats" select="../stack/category" />
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printAllPackages                                                     -->
  <!--                                                                      -->
  <!-- Print table with list of packages and table with all package results -->
  <!-- ==================================================================== -->
  <xsl:template name="printAllPackages">
    <xsl:param name="resources"/>
    <xsl:param name="cats"/>
    <xsl:variable name="suite" select="."/>
    <h1 class="body"><xsl:value-of select="$cats/../id"/></h1>
    <!-- inca-common.xsl -->
    <xsl:call-template name="printSeriesNamesTable">
      <xsl:with-param name="seriesNames" select="$cats/package/id"/>
    </xsl:call-template>
    <table class="subheader">
      <!-- resultsAllPackages -->
      <xsl:apply-templates select="$cats">
        <xsl:sort/>
        <xsl:with-param name="resources" select="$resources"/>
        <xsl:with-param name="suite" select="$suite" />
      </xsl:apply-templates>
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- resultsAllPackages                                                   -->
  <!--                                                                      -->
  <!-- Prints category header row and calls template to print its packages  -->
  <!-- ==================================================================== -->
  <xsl:template name="resultsAllPackages" match="category">
    <xsl:param name="resources"/>
    <xsl:param name="suite"/>
    <xsl:variable name="span" select="count($resources)+1" />
    <tr><td colspan="{$span}" class="header">
      <xsl:value-of select="upper-case(id)"/>
    </td></tr>
    <!-- printPackage -->
    <xsl:apply-templates select="package">
      <xsl:sort/>
      <xsl:with-param name="resources" select="$resources"/>
      <xsl:with-param name="suite" select="$suite" />
    </xsl:apply-templates>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printPackage                                                         -->
  <!--                                                                      -->
  <!-- Prints packages results for a set of resources                       -->
  <!-- ==================================================================== -->
  <xsl:template name="printPackage" match="package">
    <xsl:param name="resources"/>
    <xsl:param name="suite"/>
    <xsl:variable name="package" select="id"/>
    <!-- print subheader row for package with package name
    and each resource name -->
    <tr>
      <td class="subheader"><a name="{$package}">
        <xsl:value-of select="$package"/>
      </a></td>
      <!-- inca-common.xsl printResourceNameCell -->
      <xsl:apply-templates select="$resources" mode="name">
        <xsl:sort/>
      </xsl:apply-templates>
    </tr>
    <!-- printResultsRow -->
    <xsl:apply-templates select="tests/unitalias|tests/version">
      <xsl:with-param name="resources" select="$resources"/>
      <xsl:with-param name="suite" select="$suite" />
    </xsl:apply-templates>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResultsRow                                                      -->
  <!--                                                                      -->
  <!-- Prints results of test for resource set                              -->
  <!-- ==================================================================== -->
  <xsl:template name="printResultsRow" match="unitalias|version">
    <xsl:param name="resources"/>
    <xsl:param name="suite"/>
    <xsl:variable name="testname" select="id" />
    <xsl:variable name="package" select="../.." />
    <xsl:variable name="rowlabel">
      <xsl:choose>
        <xsl:when test="$package/tests/version[id=$testname]">
          <xsl:value-of select="concat('version: ' , $package/version)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$testname"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:if test="($prodReportersOnly='true' and count(status[.='dev'])=0)
    or $prodReportersOnly='false'">
      <tr>
        <td class="clear">
          <xsl:value-of select="replace($rowlabel, '^all2all:.*_to_', '')" />
        </td>
        <!-- printResourceResultCell -->
        <xsl:apply-templates select="$resources" mode="result">
          <xsl:sort/>
          <xsl:with-param name="test" select="."/>
          <xsl:with-param name="package" select="$package"/>
          <xsl:with-param name="suite" select="$suite"/>
        </xsl:apply-templates>
      </tr>
    </xsl:if>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResourceResultCell                                              -->
  <!--                                                                      -->
  <!-- Prints a table cell with resource result.                            -->
  <!-- ==================================================================== -->
  <xsl:template name="printResourceResultCell" match="resource" mode="result">
    <xsl:param name="test"/>
    <xsl:param name="package"/>
    <xsl:param name="suite"/>
    <xsl:variable name="testname" select="$test/id"/>
    <xsl:variable name="thisResource" select="concat('^', name, '$')"/>
    <xsl:variable name="regexHost" select="concat($thisResource, '|',
    replace(macros/macro[name='__regexp__']/value, ' ','|'))"/>
    <xsl:variable name="result"
                  select="$suite/reportSummary[matches(hostname, $regexHost)
                  and nickname=$testname]" />
    <xsl:variable name="instance" select="$result/instanceId" />
    <xsl:variable name="comparitor" select="$result/comparisonResult" />
    <xsl:variable name="foundVersion" select="$result/body/package" />
    <xsl:choose>
      <xsl:when test="count($result)>0">
        <!-- resource is not exempt -->
        <xsl:variable name="href"
                      select="concat('xslt.jsp?xsl=instance.xsl&amp;instanceID=',
                      $instance, '&amp;configID=', $result/seriesConfigId,
                      '&amp;resourceName=', name)"/>
        <xsl:variable name="tickets" select="$test/tgTickets"/>
        <xsl:variable name="exit">
          <xsl:choose>
            <xsl:when test="count($result/body)=0">
              <xsl:value-of select="''" />
            </xsl:when>
            <xsl:when test="$tickets/ticket[matches(resource, $thisResource)]">
              <xsl:value-of select="'tkt-'" />
              <xsl:value-of select="$tickets/ticket[matches(resource,
              $thisResource)]/number" />
            </xsl:when>
            <xsl:when test="$package/packagewait[matches(resource,
            $thisResource)]">
              <xsl:value-of select="'pkgWait'" />
            </xsl:when>
            <xsl:when test="$package/incawait[matches(resource,
            $thisResource)]">
              <xsl:value-of select="'incaWait'" />
            </xsl:when>
            <xsl:when test="$comparitor='Success' or
              (string($result/body)!=''
               and string($result/errorMessage)=''
               and string($comparitor)='' )"> 
              <xsl:value-of select="'pass'" />
            </xsl:when>
            <xsl:when test="$result[matches(errorMessage, 'Inca error')]">
              <xsl:value-of select="'incaErr'" />
            </xsl:when>
            <xsl:when test="$result[matches(errorMessage,
            'Reporter exceeded usage limits')]">
              <xsl:value-of select="'timeOut'" />
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="'error'" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$exit!=''">
            <xsl:variable name="class">
              <xsl:call-template name="getClass">
                <xsl:with-param name="status" select="$test/status" />
                <xsl:with-param name="result" select="$exit" />
              </xsl:call-template>
            </xsl:variable>
            <td class="{$class}">
              <a href="{$href}" title="{$result/errorMessage}">
                <xsl:choose>
                  <xsl:when test="string($foundVersion)=''">
                    <xsl:value-of select="$exit"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:choose><xsl:when test="string($foundVersion/subpackage/version)!=''">
                          <xsl:for-each select="$foundVersion/subpackage">
                            <xsl:value-of select="concat(ID, ': ', version)"/><br/>
                          </xsl:for-each>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of select="$foundVersion" />
                      </xsl:otherwise></xsl:choose>
                  </xsl:otherwise>
                </xsl:choose>
              </a>
              <!-- inca-common.xsl -->
              <xsl:call-template name="markOld">
                <xsl:with-param name="gmtExpires" select="$result/gmtExpires" as="xs:dateTime"/>
              </xsl:call-template>
            </td>
          </xsl:when>
          <!-- missing data -->
          <xsl:otherwise>
            <td class="clear"><xsl:value-of select="' '" /></td>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <!-- resource is exempt -->
        <td class="na">
          <xsl:text>n/a</xsl:text>
        </td>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- getClass                                                             -->
  <!--                                                                      -->
  <!-- Get CSS class for table cell                                         -->
  <!-- ==================================================================== -->
  <xsl:template name="getClass">
    <xsl:param name="status" />
    <xsl:param name="result" />
    <xsl:choose>
      <xsl:when test="$status!=''">
        <xsl:value-of select="$status" />
      </xsl:when>
      <xsl:when test="$result[matches(., 'tkt-')]">
        <xsl:value-of select="'tkt'" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$result" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
