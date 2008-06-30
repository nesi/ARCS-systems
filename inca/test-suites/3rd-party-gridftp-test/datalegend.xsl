<?xml version="1.0" encoding="UTF-8"?>

<!-- ==================================================================== -->
<!-- legend.xsl:  Key to cell colors and text.                            -->
<!-- ==================================================================== -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml">

  <xsl:template name="printLegend">
    <table cellpadding="10">
      <tr valign="top">
        <td>
          <table cellpadding="1" class="subheader">
            <tr valign="top">
              <td bgcolor="orange">
                <font color="black">t/o</font>
              </td>
              <td class="clear">
                <font color="black">time out</font>
              </td>
            </tr>
            <tr valign="top">
              <td class="clear"/>
              <td class="clear">
                <font color="black">missing (not yet executed or no need to be tested)</font>
              </td>
            </tr>
            <tr valign="top">
              <td bgcolor="yellow">
                <font color="black">&lt; 5MB/s</font>
              </td>
              <td class="clear">
                <font color="black">download speed</font>
              </td>
            </tr>
            <tr valign="top">
              <td bgcolor="#00FF00">
                <font color="black">5-15MB/s</font>
              </td>
              <td class="clear">
                <font color="black">download speed</font>
              </td>
            </tr>
            <tr valign="top">
              <td bgcolor="#4CC417">
                <font color="black">&gt; 15MB/s</font>
              </td>
              <td class="clear">
                <font color="black">download speed</font>
              </td>
            </tr>
            <tr valign="top">
              <td bgcolor="red">
                <font color="black">error</font>
              </td>
              <td class="clear">
                <font color="black">connection error</font>
              </td>
            </tr>
            <xsl:if test="$url[matches(., 'markOld')]">
              <tr valign="top">
                <td class="clear"><font color="black">*</font></td>
                <td class="clear"><font color="black">
                  older than <xsl:value-of select="$markHours"/> hour<xsl:if test="$markHours!='1'">s</xsl:if>
                </font></td>
              </tr>
            </xsl:if>
          </table>
        </td>
      </tr>
    </table>
    <br/>
  </xsl:template>

</xsl:stylesheet>
