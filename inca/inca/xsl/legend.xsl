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
              <td class="na">
                <font color="black">n/a</font>
              </td>
              <td class="clear">
                <font color="black">does not apply to resource</font>
              </td>
            </tr>
            <tr valign="top">
              <td class="clear"/>
              <td class="clear">
                <font color="black">missing (not yet executed)</font>
              </td>
            </tr>
            <tr valign="top">
              <td class="pass">
                <font color="black">pass</font>
              </td>
              <td class="clear">
                <font color="black">passed</font>
              </td>
            </tr>
            <tr valign="top">
              <td class="error">
                <font color="black">error</font>
              </td>
              <td class="clear">
                <font color="black">error</font>
              </td>
            </tr>
            <tr valign="top">
              <td class="clear"><font color="black">*</font></td>
              <td class="clear"><font color="black">result is stale</font></td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
    <br/>
  </xsl:template>

</xsl:stylesheet>
