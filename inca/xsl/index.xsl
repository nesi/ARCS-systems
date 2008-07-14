<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- index.xsl:  Lists all configured suite and resource names in an      -->
<!--             HTML form whose action is to display results for the     -->
<!--             selected suite and resource.                             -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:include href="inca-common.xsl"/>
  <xsl:include href="header.xsl"/>
  <xsl:include href="footer.xsl"/>
  <xsl:param name="url" />

  <xsl:template match="/">
    <!-- header.xsl -->
    <xsl:call-template name="header"/>
    <xsl:call-template name="printJavascript"/>
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
    <xsl:call-template name="footer" />
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- generateHTML                                                         -->
  <!--                                                                      -->
  <!-- Prints out header page description and bottom cron table description -->
  <!-- Also prints out the table start and end tags and calls printSuite    -->
  <!-- to generate suite header and rows.                                   -->
  <!-- ==================================================================== -->
  <xsl:template name="generateHTML" match="combo">
    <xsl:variable name="suites" select="suites/suite"/>
    <xsl:variable name="numSuites" select="count($suites)"/>
    <xsl:variable name="resources" select="resourceConfig/resources/resource"/>
    <xsl:variable name="numResources" select="count($resources)"/>
    <form method="get" action="xslt.jsp" name="form" onsubmit="setParam(form);">
      <table border="0" align="center" cellpadding="10" width="400">
        <tr><td colspan="2">
          <h3 align="center">Welcome to the ARCS Inca web interface</h3>
          <p>To display the status page for a suite, please select a suite-resource
            pair and press the 'Submit' button.</p>
          <p>To view the series results, you'll need to select
            the suite-resource pair corresponding to the series result you want
            to view</p>
          <ol>
            <li><a href="/inca/xslt.jsp?suiteName=wsgram_tests&amp;resourceID=localResource&amp;xsl=default.xsl&amp;xmlFile=swStack.xml&amp;Submit=Submit">WSGRAM Series</a> - wsgram_tests and localResource</li>
            <li><a href="/inca/xslt.jsp?suiteName=gridftp_from_submit_hosts&amp;resourceID=GridAustraliaHosts&amp;xsl=default.xsl&amp;xmlFile=swStack.xml&amp;Submit=Submit">GridFTP Series</a> - gridftp_from_submit_hosts and GridAustraliaHosts</li>
            <li><a href="/inca/xslt.jsp?suiteName=dataservice_3rdparty_tests&amp;resourceID=localResource&amp;xsl=datatest.xsl&amp;xmlFile=swStack.xml&amp;Submit=Submit">DataService 3rd Party Transfer Series</a> - dataservice_3rdparty_tests and localResource</li>
            <li><a href="/inca/xslt.jsp?suiteName=infosystem_tests&amp;resourceID=localResource&amp;xsl=default.xsl&amp;xmlFile=swStack.xml&amp;Submit=Submit">Information Systems Series</a> - infosystem_tests and localResource</li>
            <li><a href="/inca/xslt.jsp?suiteName=ildg_tests&amp;resourceID=localResource&amp;xsl=default.xsl&amp;xmlFile=swStack.xml&amp;Submit=Submit">ILDG Series</a> - ildg_tests and localResource</li>
            <li><a href="/inca/xslt.jsp?suiteName=application_tests&amp;resourceID=localResource&amp;xsl=default.xsl&amp;xmlFile=swStack.xml&amp;Submit=Submit">Commonly Used Applications on GridAustralia Series</a> - application_tests and localResource</li>
          </ol>
        </td></tr>
        <tr align="center">
          <td>
            <xsl:if test="$numSuites=0">
              <p><i>No suites found</i></p>
            </xsl:if>
            <xsl:if test="$numSuites>0">
              <p>SUITE:</p>
              <p>
                <select name="suiteName" size="10">
                  <xsl:for-each select="$suites">
                    <xsl:sort select="." />
		    <xsl:choose>
		      <xsl:when test="position()=1">
                        <option value="{.}" selected=""><xsl:value-of select="."/></option>
		      </xsl:when>
		      <xsl:otherwise>
                        <option value="{.}"><xsl:value-of select="."/></option>
		      </xsl:otherwise>
		    </xsl:choose>
                  </xsl:for-each>
                </select>
              </p>
            </xsl:if>
          </td>
          <td>
            <xsl:if test="$numResources=0">
              <p><i>No resources found</i></p>
            </xsl:if>
            <xsl:if test="$numResources>0">
              <p>RESOURCE:</p>
              <p>
                <select name="resourceID" size="10">
                  <xsl:for-each select="$resources/name">
                    <xsl:sort select="."/>
		    <xsl:choose>
		      <xsl:when test="position()=1">
                        <option value="{.}" selected=""><xsl:value-of select="."/></option>
		      </xsl:when>
		      <xsl:otherwise>
                        <option value="{.}"><xsl:value-of select="."/></option>
		      </xsl:otherwise>
		    </xsl:choose>
                  </xsl:for-each>
                </select>
              </p>
            </xsl:if>
          </td>
        </tr>
        <tr align="center">
          <td colspan="2">
            <input type="hidden" name="xsl" />
            <input type="hidden" name="xmlFile" />
            <input type="submit" name="Submit" value="Submit"/>
          </td>
        </tr>
        <tr align="center">
          <td colspan="2">
            <p>(To view suite configuration details,
              <a href="config.jsp?xsl=config.xsl">click here</a>.)</p>
          </td>
        </tr>
      </table>
    </form>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printJavascript                                                      -->
  <!--                                                                      -->
  <!-- Prints out javascript                                                -->
  <!-- ==================================================================== -->
  <xsl:template name="printJavascript">
    <script language="javascript" type="text/javascript">
      <xsl:text disable-output-escaping="yes"><![CDATA[
function setParam(form) {
	var suite = form.suiteName.value;
	var xsl = new Object();

	// define xsl param for particular suite
	// (use line below as example for your suite)
	xsl['usage'] = 'job.xsl';

	var xslparam = xsl[suite];
	if (xslparam == undefined){
		xslparam = 'default.xsl';
	}
	form.xsl.value = xslparam;

	var xml = new Object();

	// define xmlFile param for particular suite
	// (use lines below as example for your suite)
	xml['usage'] = 'jobs.xml';
	xml['security'] = 'security.xml';
	xml['ctss-v3'] = 'ctssv3.xml';

	var xmlparam = xml[suite];
	if (xmlparam == undefined){
		xmlparam = 'swStack.xml';
	}
	form.xmlFile.value = xmlparam;
}
]]></xsl:text>
    </script>
  </xsl:template>

</xsl:stylesheet>
