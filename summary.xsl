<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- summary.xsl:  Table with a list of resources in the left column and  -->
<!--               a list of the suite tests each resource is failing     -->
<!--               in the right column.  Failing tests are listed by name -->
<!--               and by overall percentage passing in suite.            -->
<!--               Uses XML file (e.g. swStack.xml) to get test groups.   -->
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
          <xsl:apply-templates select="combo" />
        </xsl:otherwise>
      </xsl:choose>
    </body>
    <!-- footer.xsl -->
    <xsl:call-template name="footer" />
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResults                                                         -->
  <!--                                                                      -->
  <!-- prints page title and calls templates to print results tables        -->
  <!-- ==================================================================== -->
  <xsl:template name="printResults" match="combo">
    <!-- inca-common.xsl -->
    <xsl:call-template name="printBodyTitle">
      <xsl:with-param name="title" select="concat(stack/id, ' (summary)')"/>
    </xsl:call-template>
    <xsl:variable name="resources"
                  select="suiteResults/resourceConfig/resources/resource"/>
    <xsl:variable name="stack" select="stack"/>
    <!-- inca-common.xsl -->
    <xsl:call-template name="printSeriesNamesTable">
      <xsl:with-param name="seriesNames" select="$resources/name"/>
    </xsl:call-template>
    <xsl:call-template name="printSummaryTable">
      <xsl:with-param name="resources" select="$resources"/>
      <xsl:with-param name="stack" select="$stack"/>
    </xsl:call-template>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSummaryTable                                                    -->
  <!--                                                                      -->
  <!-- prints table with resources on left and % pass/fail on right         -->
  <!-- ==================================================================== -->
  <xsl:template name="printSummaryTable">
    <xsl:param name="resources"/>
    <xsl:param name="stack"/>
    <xsl:variable name="alltests" select="$stack//package//tests" />
    <xsl:variable name="crosstests"
                  select="$alltests/unitalias[matches(id, '^all2all:.*$')]/id"/>
    <xsl:variable
        name="unittests"
        select="$alltests/unitalias[not(matches(id, '^all2all:.*$'))]/id"/>
    <xsl:variable name="vertests" select="$alltests/version/id"/>
    <hr/>
    <p>
      <xsl:value-of
          select="count($crosstests) + count($unittests) + count($vertests)" />
      <xsl:value-of select="' possible tests ('" />
      <xsl:value-of select="count($unittests)" />
      <xsl:value-of select="' unit, '" />
      <xsl:value-of select="count($vertests)" />
      <xsl:value-of select="' version, '" />
      <xsl:value-of select="count($crosstests)" />
      <xsl:value-of select="' cross-site)'" />
    </p>
    <table cellpadding="8" class="subheader">
      <xsl:for-each select="$resources">
        <xsl:sort/>
        <xsl:variable name="resourceName" select="name"/>
        <xsl:variable name="regexHost" select="concat('^', name, '$|',
            replace(macros/macro[name='__regexp__']/value, ' ','|'))"/>
        <!-- get unit test stats -->
        <xsl:variable
            name="unitMatch"
            select="//reportSummary[matches(hostname,
            $regexHost)]//nickname[.=$unittests]" />
        <xsl:variable name="numUnitMatches" select="count($unitMatch)" />
        <xsl:variable name="unitCompleted" select="$unitMatch/../body" />
        <xsl:variable name="unitFail" select="count($unitCompleted[.=''])" />
        <xsl:variable
            name="numUnitFail"
            select="if(number($unitFail)=number($unitFail))
            then $unitFail else 0"/>
        <xsl:variable name="unitPass" select="count($unitCompleted[.!=''])" />
        <xsl:variable
            name="numUnitPass"
            select="if(number($unitPass)=number($unitPass))
            then $unitPass else 0" />
        <xsl:variable name="numUnitMiss"
                      select="$numUnitMatches - $numUnitFail - $numUnitPass" />
        <xsl:variable name="unitMissing"
                      select="$unitMatch[not(.=$unitCompleted/../nickname)]" />
        <!-- get version test stats -->
        <xsl:variable name="verMatch"
                      select="//reportSummary[matches(hostname,
            $regexHost)]//nickname[. = $vertests]" />
        <xsl:variable name="numVerMatches" select="count($verMatch)" />
        <xsl:variable name="verCompleted"
                      select="$verMatch/../comparisonResult" />
        <xsl:variable name="verFail"
                      select="count($verCompleted[.!='Success'])" />
        <xsl:variable name="numVerFail"
                      select="if (number($verFail)=number($verFail))
                      then $verFail else 0" />
        <xsl:variable name="verPass"
                      select="count($verCompleted[.='Success'])"/>
        <xsl:variable name="numVerPass"
                      select="if (number($verPass)=number($verPass))
                      then $verPass else 0" />
        <xsl:variable name="numVerMiss"
                      select="$numVerMatches - $numVerFail - $numVerPass" />
        <xsl:variable name="verMissing"
                      select="$verMatch[not(.=$verCompleted/../nickname)]" />
        <!-- get cross-site test stats -->
        <xsl:variable name="crossMatch"
                      select="//reportSummary[matches(hostname,
                      $regexHost)]//nickname[.=$crosstests]" />
        <xsl:variable name="numCrossMatches" select="count($crossMatch)" />
        <xsl:variable name="crossCompleted" select="$crossMatch/../body" />
        <xsl:variable name="crossMissing"
                      select="$crossMatch[not(.=$crossCompleted/../nickname)]"/>
        <xsl:variable name="numCrossMiss" select="count($crossMissing)" />
        <xsl:variable
            name="crossFail"
            select="//resource[matches(name,
            $regexHost)]/testSummaries//testSummary/failures//failure" />
        <!-- get total stats -->
        <xsl:variable name="numUnitVersionFail"
                      select="$numUnitFail + $numVerFail" />
        <xsl:variable name="numCrossFail" select="count($crossFail)" />
        <xsl:variable
            name="unitVersionFail"
            select="$unitCompleted[.='']/../nickname |
            $verCompleted[.!='Success']/../nickname" />
        <xsl:variable name="allMissing"
                      select="$verMissing | $unitMissing | $crossMissing" />
        <xsl:variable name="numAllMatches"
                      select="$numVerMatches+$numUnitMatches+$numCrossMatches"/>
        <xsl:variable name="numAllMiss"
                      select="$numUnitMiss + $numVerMiss + $numCrossMiss" />
        <xsl:variable name="numAllMiss"
                      select="$numUnitMiss + $numVerMiss + $numCrossMiss" />
        <xsl:variable name="numAllFail"
                      select="$numUnitVersionFail + $numCrossFail" />
        <xsl:variable name="percPass">
          <xsl:choose>
            <xsl:when test="$numAllFail=0">
              <xsl:value-of select="100"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of
                  select="100 - round($numAllFail div $numAllMatches * 100)" />
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <tr>
          <td class="clear" valign="top"><a name="{name}">
            <xsl:value-of select="name"/></a> </td>
          <td class="clear" valign="top">
            <xsl:value-of select="concat($percPass,'% passed')"/> <br/><br/>
            <u><b><xsl:value-of select="'Tests:'" /></b></u>
            <xsl:value-of select="concat(' ',$numAllMatches)"/><br/>
            <xsl:value-of
                select="concat(' (',$numUnitMatches,' unit, ',$numVerMatches,
                ' version, ',$numCrossMatches,' cross-site)')"/>
            <br/><br/>
            <xsl:if test="$numAllFail>0">
              <u><b><xsl:value-of select="'Errors:'" /></b></u>
              <xsl:value-of select="concat(' ',$numAllFail)"/><br/>
            </xsl:if>
            <xsl:if test="$numUnitVersionFail>0">
              <xsl:value-of select="concat(' (',$numUnitVersionFail,' unit/version)')"/>
              <ol><xsl:for-each select="$unitVersionFail">
                <xsl:sort select="."/>
                <xsl:variable name="thisTest" select="." />
                <xsl:variable
                    name="result"
                    select="//reportSummary[matches(hostname, $regexHost)
                    and nickname=$thisTest]" />
                <xsl:apply-templates select="$result">
                  <xsl:with-param name="resourceName" select="$resourceName"/>
                </xsl:apply-templates>
              </xsl:for-each></ol>
            </xsl:if>
            <xsl:if test="$numCrossFail>0">
              <xsl:value-of select="concat(' (',$numCrossFail,' cross-site)')"/>
              <ol><xsl:apply-templates select="$crossFail">
                <xsl:with-param name="resourceName" select="$resourceName"/>
                <xsl:sort select="."/>
              </xsl:apply-templates></ol>
            </xsl:if>
          </td>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printTestLink                                                        -->
  <!--                                                                      -->
  <!-- prints hyperlink to test details page                                -->
  <!-- ==================================================================== -->
  <xsl:template name="printTestLink" match="failure|reportSummary">
    <xsl:param name="resourceName"/>
    <xsl:variable name="href"
                  select="concat('xslt.jsp?xsl=instance.xsl&amp;instanceID=',
                  instanceId,'&amp;configID=',seriesConfigId,
                  '&amp;resourceName=',$resourceName)" />
    <li><a href="{$href}">
      <xsl:value-of select="replace(nickname, '^all2all:', '')" /></a></li>
  </xsl:template>

</xsl:stylesheet>
