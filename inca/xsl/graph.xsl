<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- graph.xsl:  Prints form to select series to graph                    -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
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
    <xsl:text disable-output-escaping="yes"><![CDATA[
      <script type="text/javascript" src="js/graph.js"></script>
    ]]></xsl:text>
    <body topMargin="0">
      <xsl:choose>
        <xsl:when test="count(error)>0">
          <!-- inca-common.xsl printErrors -->
          <xsl:apply-templates select="error" />
        </xsl:when>
        <xsl:otherwise>
          <form method="get" action="graph.jsp" name="graph"
                onsubmit="return validate(graph);">
            <xsl:call-template name="printGraphForm"/>
            <!-- printSuiteBoxes -->
            <xsl:apply-templates select="combo/suiteResults/suite" />
          </form>
        </xsl:otherwise>
      </xsl:choose>
      <!-- footer.xsl -->
      <xsl:call-template name="footer"/>
    </body>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printGraphForm                                                       -->
  <!--                                                                      -->
  <!-- Prints form fields for graph.jsp                                     -->
  <!-- ==================================================================== -->
  <xsl:template name="printGraphForm">
    <p>
      <!-- inca-common.xsl -->
      <xsl:call-template name="printBodyTitle">
        <xsl:with-param name="title" select="'Graph Result History'"/>
      </xsl:call-template>
      Graph the result history of any Inca report series on a single graph.
      <br/>Use the input parameters below to customize the appearance of the graph,
      <br/>check the boxes for each Inca report series to be graphed,
      and click 'GRAPH'.</p>
      <p>Adjust the graph size or remove the legend if selecting many series
      <br/>as the legend is included as part of the graph. For example, if
      <br/>graphing 20 series increase graph height to 600.</p>
    <table class="subheader">
      <tr>
        <td>title: </td>
        <td><input name="title" type="text" value="Inca Chart"/></td>
      </tr>
      <tr>
        <td>show mouseovers/hyperlinks<br/> for datapoints:</td>
        <td><input name="map" type="radio" value="true"/> yes
          <input name="map" type="radio" value="false" checked=""/> no</td>
      </tr>
      <tr>
        <td>show legend:</td>
        <td><input name="legend" type="radio" value="true" checked=""/> yes
          <input name="legend" type="radio" value="false"/> no</td>
      </tr>
      <tr>
        <td>legend position:</td>
        <td>
          <input name="legendAnchor" type="radio"
                 value="south" checked=""/> south
          <input name="legendAnchor" type="radio" value="north"/> north
          <input name="legendAnchor" type="radio" value="east"/> east
          <input name="legendAnchor" type="radio" value="west"/> west
        </td>
      </tr>
      <tr>
        <td>width:</td>
        <td><input name="width" type="text" size="5" value="500"/></td>
      </tr>
      <tr>
        <td>height:</td>
        <td><input name="height" type="text" size="5" value="300"/></td>
      </tr>
      <tr>
        <td>background color:</td>
        <td><input name="bgcolor" type="text"/> (e.g. #ACB4BB)</td>
      </tr>
      <tr>
        <td>x-axis label:</td>
        <td><input name="xaxislabel" type="text"
                   value="reporter executed"/></td>
      </tr>
      <tr>
        <td>y-axis label:</td>
        <td><input name="yaxislabel" type="text"
                   value="result: pass = 1, fail = 0"/></td>
      </tr>
      <tr>
        <td>start date:</td>
        <td><input name="xmin"
                   type="text"/> (MMddyy format, e.g. "093007")</td>
      </tr>
      <tr>
        <td>end date:</td>
        <td><input name="xmax"
                   type="text"/> (MMddyy format, e.g. "103007")</td>
      </tr>
    </table>
    <br/><br/>
    <input type="hidden" name="start" value="1"/>
    <input type="hidden" name="series" value=""/>
    <input type="hidden" name="testName"/>
    <input type="hidden" name="resourceName"/>
    <input type="hidden" name="seriesLabel"/>
    <input type="submit" name="submit" value="GRAPH"/> <br/><br/>
    <input type="button" name="CheckAll" value="check all"
           onClick="checkAll(graph.series)"/>
    <input type="button" name="UnCheckAll" value="uncheck all"
           onClick="uncheckAll(graph.series)"/>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSuiteBoxes                                                      -->
  <!--                                                                      -->
  <!-- Calls printSeriesBoxTable                                            -->
  <!-- ==================================================================== -->
  <xsl:template name="printSuiteBoxes" match="suite">
    <p><xsl:value-of select="concat(name, ' suite')"/></p>
    <xsl:variable name="seriesNames"
                  select="distinct-values(reportSummary/nickname)"/>
    <xsl:choose>
      <xsl:when test="count(/combo/resourceConfig)=1">
        <xsl:call-template name="printSeriesBoxTable">
          <xsl:with-param name="seriesNames" select="$seriesNames"/>
          <xsl:with-param
              name="resources"
              select="/combo/resourceConfig/resources/resource[name]"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="printSeriesBoxTable">
          <xsl:with-param name="seriesNames" select="$seriesNames"/>
          <xsl:with-param name="resources"
                          select="../resourceConfig/resources/resource[name]"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printSeriesBoxTable                                                  -->
  <!--                                                                      -->
  <!-- Prints a table with series form boxes                                -->
  <!-- ==================================================================== -->
  <xsl:template name="printSeriesBoxTable">
    <xsl:param name="seriesNames"/>
    <xsl:param name="resources"/>
    <xsl:variable name="suite" select="."/>
    <table class="subheader">
      <xsl:for-each select="$seriesNames">
        <xsl:sort/>
        <xsl:variable name="testname" select="."/>
        <xsl:variable name="suiteName" select="$suite/name"/>
        <xsl:if test="position() mod 20 = 1">
          <tr>
            <td class="subheader"/>
            <td class="subheader"/>
            <!-- inca-common.xsl -->
            <xsl:apply-templates select="$resources" mode="name">
              <xsl:sort/>
            </xsl:apply-templates>
          </tr>
          <tr>
            <td class="subheader" colspan="2">select row or column:</td>
            <!-- printResourceNameBoxCell -->
            <xsl:apply-templates select="$resources" mode="box">
              <xsl:sort/>
              <xsl:with-param name="suiteName" select="$suiteName"/>
            </xsl:apply-templates>
          </tr>
        </xsl:if>
        <tr>
          <td class="clear">
              <xsl:value-of select="."/>
          </td>
          <td class="subheader">
              <input type="checkbox" name="fliprow" value="row" onClick="flip(graph,
              '{$suiteName}', '{$testname}', 'ROW', this.checked)"/>
          </td>
          <!-- printResourceBoxCell -->
          <xsl:apply-templates select="$resources" mode="result">
            <xsl:sort/>
            <xsl:with-param name="testname" select="$testname"/>
            <xsl:with-param name="suite" select="$suite"/>
            <xsl:with-param name="suiteName" select="$suiteName"/>
          </xsl:apply-templates>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResourceNameBoxCell                                             -->
  <!--                                                                      -->
  <!-- Prints a table cell with resource form box.                          -->
  <!-- ==================================================================== -->
  <xsl:template name="printResourceNameBoxCell" match="resource" mode="box">
    <xsl:param name="suiteName"/>
    <td class="subheader">
      <input type="checkbox" name="flipcol" value="col" onClick="flip(graph,
              '{$suiteName}', '{name}', 'COL', this.checked)"/>
    </td>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printResourceBoxCell                                                 -->
  <!--                                                                      -->
  <!-- Prints a table cell with resource form box.                          -->
  <!-- ==================================================================== -->
  <xsl:template name="printResourceBoxCell" match="resource" mode="result">
    <xsl:param name="testname"/>
    <xsl:param name="suite"/>
    <xsl:param name="suiteName"/>
    <xsl:variable name="regexHost" select="concat('^', name, '$|',
        replace(macros/macro[name='__regexp__']/value, ' ','|'))"/>
    <xsl:variable name="result"
                  select="$suite/reportSummary[matches(hostname, $regexHost)
                  and nickname=$testname]" />
    <xsl:choose>
      <xsl:when test="count($result)>0">
        <!-- resource is not exempt -->
        <td class="clear">
          <input type="checkbox" name="series" value="{concat($testname, ',',
            name, ',', name, ' (', $testname, ')')}"
            id="{concat('-SUITE-',$suiteName,'-COL-',name,'-ROW-',$testname)}"/>
        </td>
      </xsl:when>
      <xsl:otherwise>
        <!-- resource is exempt -->
        <td class="na">
          <xsl:text>n/a</xsl:text>
        </td>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
