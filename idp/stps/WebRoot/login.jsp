<%@ include file="/common/taglibs.jsp"%>
<HEAD>
</HEAD>
<body>

	<h3>
		SharedToken Portability Service Demo
	</h3>

	<div id="page">
		<div id="head">
		</div>

		<div id="main">
			<div id="content">

				<p>
					<s:actionmessage />
					<s:actionerror />
				</p>

				<s:form action="login" theme="simple">
					<label for="username">
						Username
					</label>
					<s:textfield name="username" id="username" />
					<br />
					<label for="password">
						Password
					</label>
					<s:password name="password" id="password" />
					<br />
					<s:submit value="Submit"></s:submit>
				</s:form>
			</div>

		</div>
	</div>
	<p>
		<a href="https://test-idp.ramp.org.au/demo/stps.htm" target="_blank">STPS
			Flash Demo</a>
	</p>
</body>

