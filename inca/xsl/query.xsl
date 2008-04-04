<?xml version="1.0" encoding="utf-8"?>

<!-- ==================================================================== -->
<!-- query.xsl:  Creates form to create and store hql queries             -->
<!-- ==================================================================== -->
<xsl:stylesheet version="2.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.w3.org/1999/xhtml"
                xmlns:quer="http://inca.sdsc.edu/dataModel/queryStore_2.0">

  <xsl:include href="inca-common.xsl"/>
  <xsl:include href="header.xsl"/>
  <xsl:include href="footer.xsl"/>
  <xsl:param name="qname" />
  <xsl:param name="hql" />
  <xsl:param name="period" />

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
          <h1>Query Management</h1><br/>
          <xsl:call-template name="printJavascript" />
          <xsl:apply-templates select="queryInfo/quer:queryStore" />
        </xsl:otherwise>
      </xsl:choose>
    </body>
    <!-- footer.xsl -->
    <xsl:call-template name="footer"/>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printJavascript                                                      -->
  <!--                                                                      -->
  <!-- Output some Javascript functions and global variables.               -->
  <!-- ==================================================================== -->
  <xsl:template name="printJavascript">
    <script language="javascript" type="text/javascript">

      /*
      * Store query information
      */
      var queries = new Array();
      <xsl:for-each select="/queryInfo/quer:queryStore/query">
        var queryName = "<xsl:value-of select="name"/>";
        queries[queryName] =
        { hql: "<xsl:value-of select="replace(hql, '\n|\r', '\\n\\&#xa;')"/>" };
        var period = 0;
        <xsl:if test="cache">
          period = <xsl:value-of select="cache/reloadPeriod"/>;
        </xsl:if>
        queries[queryName].period = period;
      </xsl:for-each>

      /*
      * Change the values of the query name, hql, and period based on the
      * selected query name.
      *
      * Arguments:
      *
      *   queryName - A string containing the name of a query.
      */
      function changeFormValues( queryName ) {
        document.queryForm.qname.value = queryName;
        document.queryForm.hql.value=queries[queryName].hql;
        document.queryForm.period.value=queries[queryName].period;
      }

      /*
      * Store template information
      */
      var templates = new Array();
      <xsl:for-each select="/queryInfo/quer:queryStore/template">
        var templateName = "<xsl:value-of select="name"/>";
        templates[templateName]  =
        { hql: "<xsl:value-of select="replace(hql, '\n|\r', '\\n\\&#xa;')"/>" };
        templates[templateName].param = new Array(1);
        <xsl:for-each select="param">
          var position = "<xsl:value-of select="position()"/>";
          templates[templateName].param[position]= "<xsl:value-of select="."/>";
          </xsl:for-each>
      </xsl:for-each>

      /*
      * Change HQL and template params
      * depending on which template selected
      */
      function changeTemplateValues( template, tbl ) {
        var tbl = document.getElementById(tbl);
        var rows = tbl.getElementsByTagName('tr').length;
        <xsl:text disable-output-escaping="yes"><![CDATA[
        /*document.queryForm.hql.value=templates[template].hql;
        for (i=1; i<=rows; i++){
          tbl.deleteRow(i);
        }*/
        for (i=0; i<=templates[template].param.length; i++){
          var newRow = tbl.insertRow(i);
          newRow.insertCell(0).innerHTML  = templates[template].param[i];
          newRow.insertCell(1).innerHTML = '<input type="text" name="param"/>' +
          templates[template].param.length;
        }
        ]]></xsl:text>
      }

      /*
      * Clear the value of a given form element.
      *
      * Arguments:
      *
      *   formElement - An input element in a form.
      */
      function clearValue( formElement ) {
        formElement.value = "";
      }

      /*
      * Clear if element is "Enter Name"
      */
      function clearEnter( formElement ) {
      if (formElement.value == "Enter Name")
        formElement.value = "";
      }

      /*
      * Confirm that user wants to change value
      */
      function confirmChange( value ) {
        if (qSelected(value)){
          var agree=confirm("Do you want to change " + value + "?");
        if (agree)
          return true;
        else
          return false;
        }
      }

      /*
      * Confirm that user wants to delete value
      */
      function confirmDelete( value ) {
        if (qSelected(value)){
          var agree=confirm("Do you want to delete " + value + "?");
        if (agree)
          return true;
        else
          return false;
        }
      }

      /*
      * Check whether stored query is selected
      * to perform exe/change/delete
      */
      function qSelected( query ) {
        if (query)
          return true;
        else
          alert("Please select a stored HQL query.");
        return false;
      }

    </script>
  </xsl:template>

  <!-- ==================================================================== -->
  <!-- printQueryForm                                                       -->
  <!--                                                                      -->
  <!-- Prints a HTML form that allows an user to add a stored query         -->
  <!-- ==================================================================== -->
  <xsl:template name="printQueryForm" match="quer:queryStore">
    <form method="get" action="query.jsp" name="queryForm">
      <table class="subheader" cellpadding="20" border="1" cellspacing="0"
             bordercolor="gray">
        <tr valign="top">
          <td width="50%">
            <p><b>Stored HQL Queries:</b></p>
            <xsl:choose>
              <xsl:when test="count(query)>0">
                <select name ="selectQname" size="10"
                        onClick="changeFormValues(selectQname.value);">
                  <xsl:for-each select="query">
                    <xsl:sort select="." />
                    <option value="{name}">
                      <xsl:value-of select="name"/>
                    </option>
                  </xsl:for-each>
                </select>
                <br/>
                <input name ="action" type="submit" value="Execute"
                       onClick="return qSelected(selectQname.value)"/>
                <input name ="action" type="submit" value="Delete"
                       onClick="return confirmDelete(selectQname.value)"/>
              </xsl:when>
              <xsl:otherwise>
                <p><em>(no stored queries)</em></p>
              </xsl:otherwise>
            </xsl:choose>
            <p>query name:<br/>
              <input type="text" name="qname" value="Enter Name"
                     onClick="clearEnter(qname)"/>
            </p>
            <p>fetch every:<br/>
              <input type="text" name="period" size="4" value="0"/>
              seconds
            </p>
            <input name="action" type="submit" value="Add" />
            <input name="action" type="submit" value="Change"
                   onClick="return confirmChange(selectQname.value)"/>
          </td>
          <td width="50%">
            <p><b>HQL Templates:</b></p>
            <xsl:choose>
              <xsl:when test="count(template)>0">
                <table>
                  <tr valign="top">
                    <td>
                      <select name ="selectTname" size="10"
                              onClick="changeTemplateValues(selectTname.value,
                              'paramtbl');">
                        <xsl:for-each select="template">
                          <xsl:sort select="." />
                          <option value="{name}">
                            <xsl:value-of select="name"/>
                          </option>
                        </xsl:for-each>
                      </select>
                    </td>
                    <td>
                      <table border="1" class="clear" id="paramtbl">
                        <tr><td><b>param name</b></td>
                          <td><b>enter param</b></td></tr>
                      </table>
                    </td>
                  </tr>
                </table>
              </xsl:when>
              <xsl:otherwise>
                <p><em>(no templates)</em></p>
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <tr valign="top">
          <td colspan="2">
            <p><b>HQL Query:</b></p>
            <center>
              <textarea name="hql" rows="10" cols="40" wrap="hard">
                <xsl:text> </xsl:text>
                <xsl:value-of
                    select="replace($hql, '(&#xd;|&#xa;)+', '\\n\\&#xa;')"/>
              </textarea>
              <br/>
              <input name ="action" type="submit" value="Execute hql" />
            </center>
          </td>
        </tr>
      </table>
      <br/>
      <input type="submit" value="Refresh" />
    </form>
  </xsl:template>

</xsl:stylesheet>
