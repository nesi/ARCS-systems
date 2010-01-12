<%@ include file="/common/taglibs.jsp"%>
<html>
	<head>
		<title>STPS Demo</title>
	</head>

	<body>
			<h3>
				SharedToken Portability Service Demo
			</h3>
		<s:actionerror />
		<s:fielderror />
		<s:actionmessage />

		<s:form action="apply" method="POST" enctype="multipart/form-data" >
		
			<s:file name="upload" label="SLCS Certificate" />
			<s:file name="upload" label="Signature" />
			
			<s:submit name="upload" />
		</s:form>
		<!-- 
		<a href="imsdemo!unzip.action">unzip</a>
		-->
		<br>
		<!-- 
		<a
			href="imsdemo!show.action?destinationDir=<%=request.getSession().getAttribute("destinationDir")%>&urlPrefix=<%=request.getSession().getAttribute("urlPrefix")%>">play
			the IMS learning object</a>
		<br>
		<a href="imsdemo!delete.action">delete the old objects</a>
		-->
		<!-- 
		<br>
		<a href="imsdemo!wscall.action">web service call</a>
		-->
	</body>
</html>
