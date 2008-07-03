<?xml version="1.0" encoding="iso-8859-1"?>
<!-- xsltproc all-srbs.xsl all-srbs.xsl -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                version="1.0">


<xsl:output indent="yes"/>

<xsl:variable name="classes" select="document('http://projects.arcs.org.au/trac/systems/browser/trunk/data-services/sapac.xml?format=raw')/data-services |
                                     document('http://projects.arcs.org.au/trac/systems/browser/trunk/data-services/ivec.xml?format=raw')/data-services"/>


<!--this solution pairs id and name at all times-->

<xsl:template match="/">
<data-fabric>
	<xsl:for-each select="$classes">
		<xsl:copy-of select="srb-servers"/>
	</xsl:for-each>
</data-fabric>
</xsl:template>

</xsl:stylesheet>