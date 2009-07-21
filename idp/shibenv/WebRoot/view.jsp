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

			<form action="submit">


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
				<table width="800">
					<tr>
						<td>
							<li>
								This page is provided by ARCS to confirm that an Identity
								Provider is releasing the Pilot AAF Mandatory attributes and
								also those required by ARCS for generating a SLCS Certificate
								for Grid and Data Services Access. It does not verify
								comprehensive technical conformance.
							</li>
							<br>
							<li>
								IdPs using this page are requested to configure their attribute
								release policy to release all releasable attributes to this
								service. Information received will not be released by ARCS or
								used for any other purpose.
							</li>
							<br>
							<li>
								The AAF relies on participants abiding by the CAUDIT standard
								definitions of attributes
								<a
									href="https://wiki.caudit.edu.au/confluence/download/attachments/784/auEduPerson_attribute_vocabulary_v02.0.2.pdf?version=1">auEduPerson
									Definition and Attribute Vocabulary</a>

							</li>
						</td>
					</tr>
				</table>

				<br>




				<h1>
					Pilot AAF Attribute Release Conformance Check
				</h1>
				<p>
					The Pilot AAF
					<a
						href="http://www.caudit.edu.au/download.php?doc_id=916&site_id=43">Rules
						for Participants</a> requires that the following mandatory attributes
					are supported by IdPs.

				</p>
				<br>
				<h2>
					AAF Mandatory Attributes
				</h2>
				<br>

				<table class="aafTable" border="1" cellpadding="5">
					<c:forEach var="x" items="${aafMap1}">
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

				<table class="aafTable" border="1" cellpadding="5">
					<c:forEach var="x" items="${aafMap2}">
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

				<p>
					Note: The Pilot AAF Rules for Participants requires that
					auEduPersonSharedToken is generated and managed according
					<br>
					to the prescribed process. Refer to the guidelines for Institution
					Managed auEduPersonSharedToken generation
					<a
						href="http://www.aaf.edu.au/docs/Institution_managed_auEduPersonSharedToken_v01.2.doc">IMAST</a>.
				</p>
				<br>

				<input type="checkbox" name="imastAlg" value="Yes">
				auEduPersonSharedToken is generated using the IMAST default
				algorithm
				<br>
				<br>
				The local unique, persistent attribute used to generate aEPST is 
				<input type="text" size="8" name="uniqueAttr" value="">
				<br>
				<br>
				<input type="checkbox" name="porting" value="Yes">
				I understand the requirement for enabling porting aEPST if user
				changes IdP
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


				<input type="submit" value="Send To Site Admin" />
			</form>
			<br>

			<p>
				©2009 ARCS
			</p>
		</div>



	</body>
</html>
