<%@ page language="java" contentType="text/html; charset=ISO-8859-1"
	pageEncoding="ISO-8859-1"%>
<%@ taglib prefix="s" uri="/struts-tags"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=ISO-8859-1">
<title>SharedToken Portability Service</title>
</head>
<body>
<table align="center" width="70%" class="stats">
	<tr>
		<s:if test="hasActionErrors()">
			<s:iterator value="actionErrors">
				<tr>
					<td class="error"><img alt="error message"
						src="images/error.png" width="15" height="15" />&nbsp;<s:property
						escape="false" /></td>
				</tr>
			</s:iterator>
		</s:if>
	</tr>
</table>
</body>
</html>