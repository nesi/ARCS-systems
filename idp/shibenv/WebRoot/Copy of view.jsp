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
		<div align="middle" >

			<table width="800">
				<tr>
					<td>
						<img src="images/arcs-general.png" width="143" height="59"
							alt="ARCS Logo" />
					</td>
					<td>
					</td>


				</tr>
			</table>
			<h1>
				ARCS IdP Conformance Test
			</h1>
			<h3>
				AAF Mandatory Attributes
			</h3>

			<table class="aafTable" border="1">
				<c:forEach var="x" items="${aafMap}">
					<tr>
						<td>
							<b>${x.key}</b>
						</td>
						<td>
							${x.value}
						</td>
					</tr>
				</c:forEach>
			</table>

			<h3>
				SLCS Required Attributes
			</h3>

			<table border="1" bordercolor="#FFFFFF"
				style="background-color:#CCFF99" width="800" cellpadding="3"
				cellspacing="0">
				<c:forEach var="x" items="${slcsMap}">
					<tr>
						<td>
							<b>${x.key}</b>
						</td>
						<td>
							${x.value}
						</td>
					</tr>
				</c:forEach>
			</table>

			<h3>
				RR Required Attributes
			</h3>

			<table border="1" bordercolor="#FFFFFF"
				style="background-color:#CCFFFF" width="800" cellpadding="3"
				cellspacing="0">
				<c:forEach var="x" items="${rrMap}">
					<tr>
						<td>
							<b>${x.key}</b>
						</td>
						<td>
							${x.value}
						</td>
					</tr>
				</c:forEach>
			</table>

			<h3>
				Other Attributes
			</h3>

			<table border="1" bordercolor="#FFFFFF"
				style="background-color:#FFFFFF" width="800" cellpadding="3"
				cellspacing="0">
				<c:forEach var="x" items="${otherMap}">
					<tr>
						<td>
							<b>${x.key}</b>
						</td>
						<td>
							${x.value}
						</td>
					</tr>
				</c:forEach>
			</table>
		</div>

	</body>
</html>
