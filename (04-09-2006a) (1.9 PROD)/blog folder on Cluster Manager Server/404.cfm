<cfif (FindNoCase("_index.html", CGI.QUERY_STRING) gt 0)>
	<cfinclude template="_index.html">
<cfelse>
	<cfset Request.defaultContent = "../../../../../Apache2/htdocs/blog/serverOffline.cfm">
	<cfinclude template="../../../JRun4/servers/rayhorn/cfusion.ear/cfusion.war/404.cfm">
</cfif>
