<%@ include file="/common/taglibs.jsp" %>
<html>
	<head>
		<title>IMS Demo</title>
	</head>

	<body>
		<s:actionerror />
		<s:fielderror />
		<s:actionmessage />

		<s:form action="imsdemo!upload.action" method="POST"
			enctype="multipart/form-data">

			<h1>
				IMS Demo
			</h1>
			<br>
			<s:file name="upload" label="File" />
			<br>
			<s:submit name="upload"/>
		</s:form>
		<a href="imsdemo!unzip.action">unzip</a>
		<br>
		<a href="imsdemo!show.action?destinationDir=<%=request.getSession().getAttribute("destinationDir") %>&urlPrefix=<%=request.getSession().getAttribute("urlPrefix") %>">play the IMS learning object</a>
		<br>
		<a href="imsdemo!delete.action">delete the old objects</a>
		<!-- 
		<br>
		<a href="imsdemo!wscall.action">web service call</a>
		-->
	</body>
</html>
