<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- google.xsl:  Prints javascript to output a google map with markers   -->
<!--              representing resources and lines representing           -->
<!--              cross-site test status.                                 -->
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

  <!-- ==================================================================== -->
  <!-- Main template                                                        -->
  <!-- ==================================================================== -->
  <xsl:template match="/">
    <html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml">
    <head>
      <link href="css/inca.css" rel="stylesheet" type="text/css"/>
      <script> 
      var key = "<xsl:value-of select="/combo/google/key"/>";
      <xsl:text disable-output-escaping="yes"><![CDATA[
      var scriptTag = '<script ' + 
                      'src="http://maps.google.com/maps?file=api&amp;v=2&amp;' +
                      'key=' + key + 
                      '" type="text/javascript">/* DON"T REMOVE ME */' + '<' + 
                      '/script>';      
      var scriptCode = 'document.write( scriptTag );';      
      eval( scriptCode );
      ]]></xsl:text>
      </script>
      <script type="text/javascript">
        <xsl:call-template name="printGoogleJavascript"/>
      </script>
    </head>
    <body onload="load()" onunload="GUnload()" topMargin="0">
      <xsl:choose>
        <xsl:when test="count(error)>0">
          <!-- inca-common.xsl printErrors -->
          <xsl:apply-templates select="error" />
        </xsl:when>
        <xsl:otherwise>
          <!-- header.xsl -->
          <xsl:call-template name="header"/>
          <xsl:variable name="title">
            <xsl:value-of select="'Summary Status for '"/>
            <xsl:for-each select="/combo/suiteResults/suite/name">
              <xsl:sort/>
              <xsl:value-of select="."/>
              <xsl:if test="position() != last()">
                <xsl:value-of select="', '"/>
              </xsl:if>
            </xsl:for-each>
          </xsl:variable>
          <!-- inca-common.xsl -->
          <p><xsl:call-template name="printBodyTitle">
            <xsl:with-param name="title" select="$title"/>
          </xsl:call-template></p>
          <p>The map below uses the
             <a href="http://www.google.com/apis/maps">Google Maps API</a>
             to display a summary status for 
             <a href="http://inca.sdsc.edu">Inca</a> test suites.</p><p>
             Click on resource markers to view test errors for
             individual resources<br/> (any cross-resource tests will have
             toggle buttons to display them under the map image).</p>
          <!-- get height and width from xml file; need to use javascript
               because you can't include tags inside another tag; width
               and height are attributes to the div tag -->
          <script>
          var mapWidth = <xsl:value-of select="/combo/google/width"/>;
          var mapHeight = <xsl:value-of select="/combo/google/height"/>;
          <xsl:text disable-output-escaping="yes"><![CDATA[
            document.write( '<div id="map" style="width: ' +
                            mapWidth + 'px; height: ' + mapHeight + 'px">' +
                            '<br/></div>');
          ]]></xsl:text>
          </script>
          <br clear="all"/>
          <script>
          var testNames = new Array();
          <xsl:for-each select="distinct-values(//testSummary/name)">
            testNames.push( "<xsl:value-of select="."/>" );
          </xsl:for-each>
          <xsl:text disable-output-escaping="yes"><![CDATA[
          for( var i = 0; i < testNames.length; i++ ) {
            var url = '<input type="button" value="Toggle ' + testNames[i] + 
                      ' status" onClick="toggleAll2All(\'' + testNames[i] +
                      '\')"/>';
            document.writeln( url );
          }
          ]]></xsl:text>
          </script>
          <br/>
        </xsl:otherwise>
      </xsl:choose>
    <!-- footer.xsl -->
    <xsl:call-template name="footer" />
    </body>
    </html>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printGoogleJavascript                                                -->
  <!--                                                                      -->
  <!-- prints table with resources on left and % pass/fail on right         -->
  <!-- ==================================================================== -->
  <xsl:template name="printGoogleJavascript">
    <xsl:variable name="resources"
           select="/combo/suiteResults/resourceConfig/resources/resource"/>
    <xsl:variable name="google" select="/combo/google"/>

    // Global variables - map attributes
    var DEFAULT_MARKER_DIST = [ 0, 5,     2.25,  0.75, 0.75,  0.35, 
                                   0.2,   0.075, 0.05, 0.025, 0.01, 
                                   0.005, 0.0025 ];
    var DEGREES_PER_RADIAN = 180;
    var DEBUG =  <xsl:value-of select='$google/debug'/>;
    var MAGNIFICATION_LEVEL = 
      <xsl:value-of select='$google/magnificationLevel'/>;
    <xsl:text disable-output-escaping="yes"><![CDATA[
    if ( MAGNIFICATION_LEVEL > (DEFAULT_MARKER_DIST.length - 1) ) {
      MAGNIFICATION_LEVEL = DEFAULT_MARKER_DIST.length - 1;
    }
    ]]></xsl:text>
    var MAP_WIDTH = <xsl:value-of select='$google/width'/>;
    var MAP_HEIGHT  = <xsl:value-of select='$google/height'/>;
    var MAP_CENTER_COORDS = { 
      latitude: <xsl:value-of select='$google/center/latitude'/>, 
      longitude: <xsl:value-of select='$google/center/longitude'/> };
    var MARKER_DIST = DEFAULT_MARKER_DIST[MAGNIFICATION_LEVEL];
    <xsl:if test='$google/markerDist'>;
      MARKER_DIST = <xsl:value-of select='$google/markerDist'/>;
    </xsl:if>
    var MARKER_ICON_PREFIX = 
      "<xsl:value-of select='$google/marker/iconUrlPrefix'/>";
    var MARKER_ICON_SUFFIX = 
      "<xsl:value-of select='$google/marker/iconUrlSuffix'/>";
    var MARKER_COLOR = { 
      fail: "<xsl:value-of select='$google/marker/iconStatus/fail'/>",
      pass: "<xsl:value-of select='$google/marker/iconStatus/pass'/>",
      warn: "<xsl:value-of select='$google/marker/iconStatus/warn'/>" 
    };
    var MARKER_ICON = new GIcon();
    MARKER_ICON.iconSize = new GSize(
      <xsl:value-of select='$google/marker/iconWidth'/>, 
      <xsl:value-of select='$google/marker/iconHeight'/> );
    MARKER_ICON.iconAnchor = new GPoint
      ( <xsl:value-of select='$google/marker/iconAnchorCoord'/> );
    MARKER_ICON.shadow = 
      "<xsl:value-of select='$google/marker/shadowIconUrl'/>";
    MARKER_ICON.shadowSize = new GSize(
      <xsl:value-of select='$google/marker/shadowIconWidth'/>, 
      <xsl:value-of select='$google/marker/shadowIconHeight'/> );
    MARKER_ICON.infoWindowAnchor = new GPoint
      ( <xsl:value-of select='$google/marker/iconInfoWindowAnchorCoord'/> );
    var MAX_ERRORS = <xsl:value-of select='$google/maxErrors'/>;
    var LINE_COLORS = {  
      pass: "<xsl:value-of select='$google/line/pass'/>", 
      fail: "<xsl:value-of select='$google/line/fail'/>" 
    };
    var ALL2ALL = new Array();
    var ALL2ALL_BUTTONS = "";
    var LINES = new Array();
    var logos = new Array();
    var map;
    var resources = new Array(); 
    var sites = new Array();
    // setup default lat/long
    sites["DEFAULT"] = new Array();
    sites["DEFAULT"].latitude = MAP_CENTER_COORDS.latitude;
    sites["DEFAULT"].longitude = MAP_CENTER_COORDS.longitude;
    sites["DEFAULT"].resourceIdx = 0;


    /*
    * Searches for a given hostname in the set of resources by checking each
    * resources regex.
    *
    * Arguments:
    *
    *    hostname - the name of the host we are trying to match
    *
    * Returns:  The name of this hostname's resource or null if it's not found
    */
    function lookupResource( hostname ) {
      <xsl:text disable-output-escaping="yes"><![CDATA[
      for( var resourceName in resources ) {
        var regex = new RegExp( "^" + resources[resourceName].regex + "$" );
        if ( hostname.search(regex) >= 0 ) {
          return resourceName;
        }
      }
      return null;
      ]]></xsl:text>
    }

    /*
    * Pops up window to print debug messages.  From
    *
    * http://ajaxcookbook.org/javascript-debug-log/
    */
    function log(message) {
      if ( ! DEBUG ) { return };
      <xsl:text disable-output-escaping="yes"><![CDATA[
      if (!log.window_ || log.window_.closed) {
        var win = window.open("", null, "width=400,height=200," +
                              "scrollbars=yes,resizable=yes,status=no," +
                              "location=no,menubar=no,toolbar=no");
        if (!win) return;
        var doc = win.document;
        doc.write
          ( '<html><head><title>Debug Log</title></head><body></body></html> ');
        doc.close();
        log.window_ = win;
      }
      var logLine = log.window_.document.createElement("div");
      logLine.appendChild(log.window_.document.createTextNode(message));
      log.window_.document.body.appendChild(logLine);
      ]]></xsl:text>
    }

    /*
    * createMarker
    *
    * Creates a marker for a resource with an info window attached to it.
    * The info window will display the resource names, the availability,
    * and any failures.
    *
    * Arguments:
    *
    *   point: an GLatLng object describing where to place the marker
    *   resource:  a string containing the name of the resource which will
    *              appear as the title in the info window of the marker
    *   numPassed:  the number of tests this resource passed
    *   numTotal:  the number of total tests for this resource.
    *   errors:  an array of error objects (associative array) each containing 
    *            the configID, instanceID, and nickname attributes.
    */
    function createMarker(point, resource, numPassed, numTotal, errors ) {
      <xsl:text disable-output-escaping="yes"><![CDATA[
      var color;
      var perc;
      perc = numPassed / numTotal;
      switch(perc)
      {
        case 0: color = MARKER_COLOR["fail"]; break    
        case 1: color = MARKER_COLOR["pass"]; break
        default: color = MARKER_COLOR["warn"]; break
      }
      MARKER_ICON.image = MARKER_ICON_PREFIX + color + MARKER_ICON_SUFFIX;
      var marker = new GMarker(point, MARKER_ICON);
      var errorMsg = "";
      if ( errors.length > 0 ) {
        errorMsg += "<p>Failed tests: " + errors.length;
        if ( errors.length > MAX_ERRORS ) {
          errorMsg += " (" + MAX_ERRORS + " displayed)";
        }
        errorMsg += "<br/>";
        for( var i = 0; i < errors.length && i < MAX_ERRORS; i++ ) {
          errorMsg += "&nbsp;&nbsp;" +
                      "<a href=xslt.jsp?xsl=instance.xsl" + 
                              "&instanceID=" + errors[i].instanceID + 
                               "&configID=" + errors[i].configID +
                               "&resourceName=" + resource + ">" + 
                      errors[i].nickname + "</a><br/>";
        }
      }
      errorMsg += "</p>";
      GEvent.addListener(marker, "click", function() {
        marker.openInfoWindowHtml(
          "<b><p>Resource:  " + resource + "</p></b><hr/>" + 
          "<p>Availability: " + (Math.round(perc*1000)/10) + "%  (passed " + 
              numPassed + "/" + numTotal + " tests)</p>" +
           errorMsg
        );
      });

      return marker;
      ]]></xsl:text>
    }
   
    /*
    * toggleAll2All
    *
    * Remove or add lines from a specific all2all test
    *
    * Arguments:
    *
    *   testName:  The name of the all2all test
    */
    function toggleAll2All( testName ) {
      log( "toggling " + testName );
      <xsl:text disable-output-escaping="yes"><![CDATA[
        if ( ALL2ALL[testName].displayed == 0 ) {
          ALL2ALL[testName].displayed = 1;
          log( "Adding " + ALL2ALL[testName].lines.length + " lines" );
          for( var i = 0; i < ALL2ALL[testName].lines.length; i++ ) {
            map.addOverlay(ALL2ALL[testName].lines[i]);
          }
        } else {
          ALL2ALL[testName].displayed = 0;
          log( "Removing " + ALL2ALL[testName].lines.length + " lines" );
          for( var i = 0; i < ALL2ALL[testName].lines.length; i++ ) {
            map.removeOverlay(ALL2ALL[testName].lines[i]);
          }
        }
      ]]></xsl:text>
    }

    /*
    * load
    *
    * Called when page is loaded to generate google map
    */
    function load() {
      if (GBrowserIsCompatible()) {

        map = new GMap2(
          document.getElementById("map"), 
          { size: new GSize(MAP_WIDTH,MAP_HEIGHT) } 
        );
        map.addControl(new GSmallMapControl());
        map.setCenter(
          new GLatLng( MAP_CENTER_COORDS.latitude, MAP_CENTER_COORDS.longitude),
          MAGNIFICATION_LEVEL );

        // get site info
        <xsl:apply-templates select="$google/sites/site" />

        // add logos onto map
        <xsl:for-each select="$google/sites/site/logo">
          var logoAngle = <xsl:value-of select="angle"/>;
          logoAngle = (logoAngle / DEGREES_PER_RADIAN) * Math.PI; // to radians
          var logoLongDiff = Math.cos(logoAngle) * 2 * MARKER_DIST; 
          var logoLatDiff = Math.sin(logoAngle) * 2 * MARKER_DIST; 
          logos.push( 
            { url: "<xsl:value-of select="url"/>",
              width: <xsl:value-of select="width"/>,
              height: <xsl:value-of select="height"/>,
              anchorX: <xsl:value-of select="logoAnchorX"/>,
              anchorY: <xsl:value-of select="logoAnchorY"/>,
              latitude: <xsl:value-of select="../latitude"/> + logoLatDiff,
              longitude: <xsl:value-of select="../longitude"/> + logoLongDiff 
            } );
        </xsl:for-each>

        // add markers for each resource
        <xsl:variable name="reportSummaries" 
                select="/combo/suiteResults/suite/reportSummary"/>
        <xsl:variable name="all2alls" select="//testSummaries/.."/>
        var curResourceName; 
        <!-- We want to display each resource in the resourceConfig file. 
             Each resource has equivalent hosts (where a RM can be run) in the
             __regexp__ macro so we want to treat all hosts as equivalent.  In
             addition, for backwards compatibility each host can have a
             __regexpTmp macro which is essentially treated the same as
             __regexp__.  -->
        <xsl:for-each select="$resources">
          curResourceName = "<xsl:value-of select="name"/>";
          resources[curResourceName] = new Array();
          resources[curResourceName].regex =
            "<xsl:value-of select="macros/macro[name='__regexp__']/value"/>"
          <xsl:if test="count(macros/macro[name='__regexpTmp__']/value)>0">
            + "|" + 
            "<xsl:value-of select="macros/macro[name='__regexpTmp__']/value"/>"
          </xsl:if>;
          resources[curResourceName].regex = 
            resources[curResourceName].regex.replace( /\s+/g, "|" );
        </xsl:for-each>
        <!-- need to determine which all2all hosts are endpoints (i.e., not
             in resourceConfig.  These resources are tested to but not
             tested themselves. -->
        <xsl:variable name="allResources" 
                      select="distinct-values($resources/name)"/>
        <xsl:variable name="allRegexes" 
                      select="$resources/macros/macro
                                [ matches(name,'^__regexp.*__$') ]/value"/>
        <xsl:variable name="allRegexString" select='concat
          (replace( string-join($allRegexes, " "), " ", "|"), "|",
           string-join($allResources, "|"))'/>
        <xsl:variable name="endpoints"  
          select="$all2alls[not(matches(name, $allRegexString))]/name"/>
        <!-- Get resource info so we can then do the magic in javascript -->
        <xsl:variable name="distinctResources"  
          select="distinct-values($resources/name | $endpoints)"/>
        sites["DEFAULT"].numResources = 
          <xsl:value-of select='count($distinctResources)'/>
        <xsl:for-each select="$distinctResources">
          <xsl:sort/>
          <!-- pass in each resources tests -->
          <xsl:variable name="resourceName" select="."/>
          <xsl:variable name="regexes" 
                        select="$resources[name=$resourceName]/macros/macro
                                  [matches(name,'^__regexp.*__$')]/value"/>
          <xsl:variable name="regexString" >
            <xsl:choose><xsl:when test='count($regexes)>0'>
              <xsl:value-of select='concat
                (replace(string-join($regexes," ")," ","|"),"|",$resourceName)'/>
            </xsl:when><xsl:otherwise>
              <xsl:value-of select='$resourceName'/>
            </xsl:otherwise> </xsl:choose>
          </xsl:variable>
          <xsl:call-template name="getResourceInfo">
            <xsl:with-param name="resource" select="$resourceName"/>
            <xsl:with-param name="site" 
              select="$google/sites/site/resources[resource=$resourceName]/../name"/>
            <xsl:with-param 
              name="reportSummaries" 
              select="$reportSummaries[matches(hostname,$regexString)]"/>
            <xsl:with-param 
              name="all2alls" select="$all2alls[matches(name,$regexString)]"/>
            <xsl:with-param name="google" select="$google/sites/site"/>
          </xsl:call-template> 
        </xsl:for-each>
      <xsl:text disable-output-escaping="yes"><![CDATA[

      // add logos
      for ( var i = 0; i < logos.length; i++ ) {
        var icon = new GIcon();
        icon.image = logos[i].url;
        icon.iconSize = new GSize( logos[i].width, logos[i].height );
        icon.iconAnchor = new GPoint ( logos[i].anchorX, logos[i].anchorY );
        map.addOverlay
          (new GMarker(new GLatLng(logos[i].latitude,logos[i].longitude),icon));
      }

      // add resource markers
      for ( var resourceName in resources ) {
        map.addOverlay( 
          createMarker(
            new GLatLng(resources[resourceName].latitude, 
                        resources[resourceName].longitude), 
            resourceName,
            resources[resourceName].numPassedReports,
            resources[resourceName].totalReports,
            resources[resourceName].errors
        ));
      }
      
      // add lines
      for ( var sourceName in resources ) {
        for( var test in resources[sourceName].all2alls ) {
          if ( ALL2ALL[test] == null ) {
            ALL2ALL[test] = { displayed: 0, lines: new Array() };
            ALL2ALL_BUTTONS += "<p>" + test + "</p>";
          } 
          for( var dest in resources[sourceName].all2alls[test] ) {
            var destName;
            if ( (destName=lookupResource(dest)) == null ) {
              destName = dest;
            }
            var sourcePt = new GLatLng( resources[sourceName].latitude, 
                                      resources[sourceName].longitude);
            var destPt = new GLatLng( resources[destName].latitude, 
                                    resources[destName].longitude);
            var color;
            if ( resources[sourceName].all2alls[test][destName] == 1 ) {
              color = LINE_COLORS["pass"];
            } else {
              color = LINE_COLORS["fail"];
            }
            var polyline = new GPolyline([ sourcePt, destPt ], color, 3 );
            ALL2ALL[test].lines.push( polyline );
          }
        }
      }
      ]]></xsl:text>
      }
    }
  </xsl:template>

  <xsl:template name="getResourceInfo">
    <xsl:param name="resource"/>
    <xsl:param name="site"/>
    <xsl:param name="reportSummaries"/>
    <xsl:param name="all2alls"/>
    <xsl:param name="google"/>

    // ----- begin getResourceInfo( <xsl:value-of select="$resource"/> ) -----
    
    // add information about this resource
    curResourceName = "<xsl:value-of select="$resource"/>";
    if ( !resources[curResourceName] ) {
      resources[curResourceName] = new Array();
    }

    var siteName = "<xsl:value-of select="$site"/>";
    if ( siteName == "" ) {
      siteName = "DEFAULT";
    }

    // get marker info
    if ( sites[siteName].numResources == 1 ) {
      resources[curResourceName].latitude = sites[siteName].latitude;
      resources[curResourceName].longitude = sites[siteName].longitude;
    } else { 
      var theta = ((2 * Math.PI) / sites[siteName].numResources) * 
                  sites[siteName].resourceIdx;
      var longDiff = Math.cos(theta) * MARKER_DIST;
      var latDiff = Math.sin(theta) * MARKER_DIST;
      resources[curResourceName].latitude = sites[siteName].latitude + latDiff;
      resources[curResourceName].longitude = sites[siteName].longitude + longDiff;
      sites[siteName].resourceIdx++;
    }

    <!-- not including the all2alls -->
    <xsl:variable name="totalReports" 
      select='$reportSummaries[instanceId and not(matches(nickname, "^all2all.+$"))]'/>
    <xsl:variable name="passedReports" 
      select="$totalReports[body!='' and not(matches(comparisonResult, '^Failure:.+$'))]"/>
    <xsl:variable name="failedReports" 
      select="$totalReports[body='' or matches(comparisonResult, '^Failure:.+$')]"/>
    // get the errors
    resources[curResourceName].errors = new Array();
    <xsl:for-each select="$failedReports">
      resources[curResourceName].errors.push
        ( { configID: <xsl:value-of select="seriesConfigId"/>, 
            instanceID: <xsl:value-of select="instanceId"/>,
            nickname: '<xsl:value-of select="nickname"/>' } );
    </xsl:for-each>
    <xsl:for-each select="$all2alls/testSummaries/testSummary/failures/failure">
      resources[curResourceName].errors.push
        ( { configID: <xsl:value-of select="seriesConfigId"/>, 
            instanceID: <xsl:value-of select="instanceId"/>,
            nickname: '<xsl:value-of select="nickname"/>' } );
    </xsl:for-each>
    // get the number of passed reports and include the all2alls
    resources[curResourceName].numPassedReports = 
      <xsl:value-of select="count($passedReports)"/> +
      <xsl:for-each select="$all2alls/testSummaries/testSummary">
        <xsl:value-of select="numSuccesses"/> +
        <xsl:value-of select="numNotAtFaultFailures"/> +
      </xsl:for-each>0
    ;
    // get the number of total reports and include the all2alls
    resources[curResourceName].totalReports = 
      <xsl:value-of select="count($totalReports)"/> +
      <xsl:for-each select="$all2alls/testSummaries/testSummary">
        <xsl:value-of select="numSuccesses"/> + 
        <xsl:value-of select="numAtFaultFailures"/> + 
        <xsl:value-of select="numNotAtFaultFailures"/> +
      </xsl:for-each>0
    ;
    
    // get all2all tests
    resources[curResourceName].all2alls = new Array();
    <xsl:for-each select="$reportSummaries[matches(nickname, '^all2all.+$')]">
      var nickname = "<xsl:value-of select="nickname"/>";
      nickname = nickname.split( /:/ )[1];  // strip off 'all2all:'
      var testName = nickname.split( /_/ )[0];
      var destHost = nickname.split( /_/ )[2];
      var destName;
      if ( (destName=lookupResource(destHost)) == null ) {
        destName = destHost;
      }
      if ( resources[curResourceName].all2alls[testName] == null ) {
        resources[curResourceName].all2alls[testName] = new Array();
      }
      var tests = resources[curResourceName].all2alls[testName];
      <xsl:variable name="errorMessage" 
                    select='replace(errorMessage,"\n"," ")'/>      
      var errorMessage = 
        "<xsl:value-of select="replace($errorMessage,'&quot;','\\&quot;')"/>";
      if ( errorMessage == "" ) {
        tests[destName] = 1;
      } else {
        tests[destName] = 0;
      }
    </xsl:for-each>

    // ------ end getResourceInfo( <xsl:value-of select="$resource"/> ) -----
  </xsl:template>

  <xsl:template name="getSiteInfo" match="site">

    // ----- begin getSiteInfo( <xsl:value-of select="name"/> ) -----
    var name = "<xsl:value-of select="name"/>";
    if ( name != "" ) {
      sites[name] = new Array();
      sites[name].resourceIdx = 0;
      sites[name].numResources = 
        <xsl:value-of select='count(resources/resource)'/>;
      sites[name].latitude = <xsl:value-of select='latitude'/>;
      sites[name].longitude = <xsl:value-of select='longitude'/>;
    } 
    // ------ end getSiteInfo( <xsl:value-of select="name"/> ) -----

  </xsl:template>
    
</xsl:stylesheet>
