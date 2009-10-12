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
								src="images/arcs-logo.jpg" width="300" height="160"
								alt="ARCS Logo" style="border-style: none" /> </a>
					</td>
					<td>
					</td>
				</tr>
			</table>
			<br>
			<br>

			<h1>
				Pilot AAF Attribute Release Conformance Check
			</h1>



			<p>
				<b> Provider ID :</b>
				<s:property value="entityID" />

				<br>
				<br>
				<b> Timestamp : </b>
				<s:property value="strTimestamp" />

			</p>

			<br>
			<h2>
				AAF Mandatory Attributes
			</h2>
			<br>


			<table class="aafTable" border="1" cellpadding="5">
				<c:forEach var="x" items="${aafMap}">
					<tr>
						<td width="250">
							<b>${x.key}</b>
						</td>
						<td>
							<c:choose>
								<c:when test="${x.value!='missing'}">
										${x.value}
								</c:when>
								<c:otherwise>
									<span style='font-style:italic;color:CC0000'>missing</span>
								</c:otherwise>
							</c:choose>
						</td>
					</tr>
				</c:forEach>
			</table>

			<br>

			<br>

			auEduPersonSharedToken is generated using the IMAST default
			algorithm:
			<b><s:property value="imastAlg" /> </b>
			<br>
			<br>
			The local unique, persistent attribute used to generate aEPST is :
			<b><s:property value="uniqueAttr" /> </b>
			<br>
			<br>
			I understand the requirement for enabling porting aEPST if user
			changes IdP:
			<b><s:property value="porting" /> </b>
			<br>
			<br>


			<h2>
				Service Specific Attribute Requirements
			</h2>

			<h3>
				<a href="http://wiki.arcs.org.au/bin/view/Main/SLCS">SLCS
					Required Attributes</a>
			</h3>
			<br>

			<table class="aafTable" border="1" cellpadding="5">
				<c:forEach var="x" items="${slcsMap}">
					<tr>
						<td width="250">
							<b>${x.key}</b>
						</td>
						<td>
							<c:choose>
								<c:when test="${x.value!='missing'}">
										${x.value}
								</c:when>
								<c:otherwise>
									<span style='font-style:italic;color:CC0000'>missing</span>
								</c:otherwise>
							</c:choose>
						</td>
					</tr>
				</c:forEach>
			</table>
			<br>

			<h3>
				<a href="https://manager.test.aaf.edu.au/rr/">RR Required
					Attributes</a>
			</h3>
			<br>

			<table class="aafTable" border="1" cellpadding="5">
				<c:forEach var="x" items="${rrMap}">
					<tr>
						<td width="250">
							<b>${x.key}</b>
						</td>
						<td>
							<c:choose>
								<c:when test="${x.value!='missing'}">
										${x.value}
								</c:when>
								<c:otherwise>
									<span style='font-style:italic;color:CC0000'>missing</span>
								</c:otherwise>
							</c:choose>
						</td>
					</tr>
				</c:forEach>
			</table>

			<br>

			<h3>
				Other Attributes
			</h3>
			<br>

			<table class="aafTable" border="1" cellpadding="5">
				<c:forEach var="x" items="${otherMap}">
					<tr>
						<td width="250">
							<b>${x.key}</b>
						</td>
						<td>
							<c:choose>
								<c:when test="${x.value!='missing'}">
										${x.value}
								</c:when>
								<c:otherwise>
									<span style='font-style:italic;color:CC0000'>missing</span>
								</c:otherwise>
							</c:choose>
						</td>
					</tr>
				</c:forEach>
			</table>

			<br>
			<br>

			<br>

			<p>
				©2009 ARCS
			</p>
		</div>



	</body>
</html>
