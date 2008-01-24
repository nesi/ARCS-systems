<?xml version="1.0"?>

<!--                                                                 -->
<!-- APAC National Grid                                              -->
<!--                                                                 -->
<!-- XSL to transform XML output from National Facility software map -->
<!-- into APACGlueSoftwareSubset schema                                -->
<!--                                                                 -->
<!-- iVEC October 2006                                               -->
<!--                                                                 -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:glue="http://forge.cnaf.infn.it/glueschema/Spec/V12/R2" xmlns:apac="http://grid.apac.edu.au/glueschema/Spec/V12/R1">

<!-- Use html output to create complete emtpy elements -->
<!-- <xsl:output method="xml" indent="yes" omit-xml-declaration="yes"/> -->
<xsl:output method="xml" version="1.0" indent="yes"/>

<xsl:template match="softwaremap_xml_service/site/host">
<xsl:element name="SoftwarePackages" namespace="http://www.ivec.org/softwareSubSchema/Spec/V12/R1">
<xsl:for-each select="software/package">
  <apac:SoftwarePackage>
    <xsl:choose>
      <xsl:when test="starts-with(version/@name,'-')">
        <xsl:attribute name="LocalID"><xsl:value-of select="@name"/></xsl:attribute>
      </xsl:when>
      <xsl:otherwise>
        <xsl:attribute name="LocalID">
          <xsl:value-of select="@name"/>/<xsl:value-of select="version/@name"/>
        </xsl:attribute>
      </xsl:otherwise>
    </xsl:choose>
    
    <apac:Name><xsl:value-of select="@name"/></apac:Name>
<!--
    <xsl:choose>
      <xsl:when test="starts-with(version/@name,'-')">
        <Version>NoVersion</Version>
      </xsl:when>
      <xsl:otherwise>
        <Version><xsl:value-of select="version/@name"/></Version>
      </xsl:otherwise>
    </xsl:choose>
-->
    <xsl:if test="not(starts-with(version/@name,'-'))">
      <apac:Version><xsl:value-of select="version/@name"/></apac:Version>
    </xsl:if>
<!-- Not needed anymore since path element is automatically being added by the python script anyway -->
<!--
    <xsl:element name="Path"></xsl:element>
-->
<!--
    <xsl:choose>
      <xsl:when test="version/shell/queue_resource='None'">
        <xsl:element name="QueueResource"></xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <QueueResource><xsl:value-of select="version/shell/queue_resource"/></QueueResource>
      </xsl:otherwise>
    </xsl:choose>
-->
    <xsl:if test="not(version/shell/queue_resource='None')">
      <apac:QueueResource><xsl:value-of select="version/shell/queue_resource"/></apac:QueueResource>
    </xsl:if>

    <xsl:choose>
      <!-- Test for non-empty module load statement in the batch_script element -->
      <xsl:when test="contains(version/shell/batch_script, 'module load')">
        <!-- If extraneous lines exist after the module name, remove them -->
        <xsl:if test="contains(version/shell/batch_script, '&#10;')">
          <apac:Module><xsl:value-of select="substring-before(substring(version/shell/batch_script, 13), '&#10;')"/></apac:Module>
        </xsl:if>
        <!-- Else, just grab the module name from the end of string -->
        <xsl:if test="not(contains(version/shell/batch_script, '&#10;'))">
          <apac:Module><xsl:value-of select="substring(version/shell/batch_script, 13)"/></apac:Module>
        </xsl:if>
      </xsl:when>
      <!-- No module specified, so output empty element -->
<!--  Don't output any element at all    
      <xsl:otherwise>
        <xsl:element name="Module"></xsl:element>
      </xsl:otherwise>
-->
    </xsl:choose>

    <!-- If serial available = 'Y' or serial available ='y' -->
    <xsl:if test="contains('Yy', version/shell/serial/available)">
      <apac:SerialAvail>true</apac:SerialAvail>
    </xsl:if>
    <!-- Use a second if statement as xsl does not have an if/else construct -->
    <xsl:if test="not(contains('Yy', version/shell/serial/available))">
      <apac:SerialAvail>false</apac:SerialAvail>
    </xsl:if>

    <!-- Similar test as for serial available above -->
    <xsl:if test="contains('Yy', version/shell/parallel/available)">
      <apac:ParallelAvail>true</apac:ParallelAvail>
    </xsl:if>
    <xsl:if test="not(contains('Yy', version/shell/parallel/available))">
      <apac:ParallelAvail>false</apac:ParallelAvail>
    </xsl:if>

    <apac:ParallelMaxCPUs><xsl:value-of select="version/shell/parallel/max_cpus"/></apac:ParallelMaxCPUs>
  </apac:SoftwarePackage>
</xsl:for-each>

</xsl:element>
</xsl:template>

</xsl:stylesheet>
