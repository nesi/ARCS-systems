<%@ page language="java" pageEncoding="ISO-8859-1"%>
<%@ taglib prefix="s" uri="/struts-tags"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
	<head>
		<link rel="stylesheet" type="text/css"
			href="<c:url value='/styles/view.css'/>" />
	</head>

	<body>
		<div class="aafDiv" align="middle" width="800">

			<table width="800">
				<tr>
					<td>
						<a href="http://www.arcs.org.au"><img
								src="images/arcs-general.png" width="300" height="160"
								alt="ARCS Logo" style="border-style: none" /> </a>
					</td>
					<td>
					</td>
				</tr>
			</table>

			<s:actionerror />
			<s:fielderror />
			<s:actionmessage />

			<p>
				©2009 ARCS
			</p>
		</div>


	</body>
</html>
