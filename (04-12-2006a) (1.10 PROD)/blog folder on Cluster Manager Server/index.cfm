<cfscript>
	bool_debugMode = (Find("192.168.", CGI.REMOTE_ADDR) gt 0) OR (Find("127.0.0.1", CGI.REMOTE_ADDR) gt 0);
</cfscript>

<cfif (bool_debugMode)>
	<cfinclude template="_index.html">
<cfelse>
	<cfset Request.defaultContent = "../../../../../Apache2/htdocs/blog/serverOffline.cfm">
	<cfinclude template="../../../JRun4/servers/rayhorn/cfusion.ear/cfusion.war/404.cfm">
</cfif>
