<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<cfscript>
	bool_allowDebug = false;
	
	bool_cgiURL = true;
	_CGI_SCRIPT_NAME = CGI.SCRIPT_NAME;
	if (UCASE(_CGI_SCRIPT_NAME) eq UCASE('/blog/404.cfm')) {
		_CGI_SCRIPT_NAME = CGI.QUERY_STRING;
		bool_cgiURL = false;
	}
</cfscript>

<html>
<head>
	<title>ColdFusion MX 7 Cluster Manager v1.0</title>
</head>

<body>

<cfset beginMs = GetTickCount( )>

<cftry>
	<cfset Request.modusOperandi = "READ">
	<cfinclude template="../../../../../Apache2/htdocs-StatsServer/includes/cfinclude_clusterDBFunctions.cfm">
	<cfinclude template="../../../../../Apache2/htdocs-StatsServer/includes/cfinclude_clusterDBRead.cfm">

	<cfif (Request.clusterDBError)>
		<cfscript>
			writeOutput(Request.clusterDBErrorMsg);
		</cfscript>
	</cfif>
	
	<cfcatch type="Any">
		<cfdump var="#cfcatch#" label="A. cfcatch" expand="No">
	</cfcatch>
</cftry>

<cftry>
	<cfset bool_debugMode = (Find("192.168.", CGI.REMOTE_ADDR) gt 0)>
	
	<cfif (bool_debugMode) AND (bool_allowDebug)>
		<cfscript>
			writeOutput('Request.dbError = [#Request.dbError#]<br>');
			writeOutput('Request.moreErrorMsg = [#Request.moreErrorMsg#]<br>');
		</cfscript>

		<cfif (IsDefined("qGetStats"))>
			<cfdump var="#qGetStats#" label="qGetStats" expand="No">
		</cfif>
	
		<cfif (IsDefined("Application"))>
			<cfdump var="#Application#" label="Application Scope" expand="No">
		</cfif>
		
		<cfif (IsDefined("Session"))>
			<cfdump var="#Session#" label="Session Scope" expand="No">
		</cfif>
		
		<cfif (IsDefined("Request"))>
			<cfdump var="#Request#" label="Request Scope" expand="No">
		</cfif>
		
		<cfif (IsDefined("CGI"))>
			<cfdump var="#CGI#" label="CGI Scope" expand="No">
		</cfif>
		
		<cfif (IsDefined("qGetStats"))>
			<cfdump var="#qGetStats#" label="qGetStats" expand="No">
		</cfif>

		<cfif (IsDefined("aStruct"))>
			<cfdump var="#aStruct#" label="aStruct" expand="No">
		</cfif>

		<UL>
			<LI>If Actual Server is offline...
				<UL>
					<LI>...then ignore the setting in Db.</LI>
					<LI>...then update the setting in the Db to Offline.</LI>
				</UL>
			</LI>
			<LI>If Actual Server is online...
				<UL>
					<LI>...then determine which server is to get the traffic and perform the redirection.</LI>
				</UL>
			</LI>
		</UL>

		<UL>
			<LI>Embed the ProductLicense within the ClusterDb Struct and use Blowfish to encrypt the data stream.
				<UL>
					<LI>This needs to be done and the ProductLicense needs to be encrypted.
					</LI>
					<LI>Database name will be tied to the specific Cluster Installation.
					</LI>
				</UL>
			</LI>
		</UL>

		<UL>
			<LI>Allow the configuration to be Editable at runtime.
				<UL>
					<LI>All newly added servers will be flagged offline upon creation until brought online manually.
					</LI>
					<LI>The initial configuration is a minimum of 2 servers in the cluster.
					</LI>
				</UL>
			</LI>
			<LI>Add support for gathering the unique server ID from the computer being used as the Cluster Manager using WinBatch.
			</LI>
		</UL>
	</cfif>
	
	<cfscript>
		latencyAR = ArrayNew(1);

		ar = ListToArray(CGI.SERVER_NAME, '.');
		ar1 = ArrayNew(1);
		ar2 = ArrayNew(1);
		ar1[1] = ar[1];
		ar1[2] = '1';
		ar2[1] = ar[1];
		ar2[2] = '2';
		for (i = 2; i lte ArrayLen(ar); i = i + 1) {
			ar1[i + 1] = ar[i];
			ar2[i + 1] = ar[i];
		}
		url1 = ArrayToList(ar1, '.');
		url2 = ArrayToList(ar2, '.');
	</cfscript>
	
	<cfset latencyAR[1] = StructNew()>
	<cfset latencyAR[1].beginMs = GetTickCount( )>
	<cfhttp url="http://#url1##_CGI_SCRIPT_NAME#" method="GET" port="#CGI.SERVER_PORT#" result="rHTTP1" resolveurl="yes"></cfhttp>
	<cfset latencyAR[1].endMs = GetTickCount( )>

	<cfscript>
		latencyAR[1].etMs = latencyAR[1].endMs - latencyAR[1].beginMs;
		if ((bool_debugMode) AND (bool_allowDebug)) writeOutput('latencyAR[1].etMs = [#latencyAR[1].etMs#]<br>');
	</cfscript>

	<cfset latencyAR[2] = StructNew()>
	<cfset latencyAR[2].beginMs = GetTickCount( )>
	<cfhttp url="http://#url2##_CGI_SCRIPT_NAME#" method="GET" port="#CGI.SERVER_PORT#" result="rHTTP2" resolveurl="yes"></cfhttp>
	<cfset latencyAR[2].endMs = GetTickCount( )>

	<cfscript>
		latencyAR[2].etMs = latencyAR[2].endMs - latencyAR[2].beginMs;
		if ((bool_debugMode) AND (bool_allowDebug)) writeOutput('latencyAR[2].etMs = [#latencyAR[2].etMs#]<br>');
	</cfscript>
	
	<cfif (bool_debugMode) AND (bool_allowDebug)>
		<cfif (IsDefined("rHTTP1"))>
			<cfdump var="#rHTTP1#" label="rHTTP1 [#url1##_CGI_SCRIPT_NAME#]" expand="No">
		</cfif>
		
		<cfif (IsDefined("rHTTP2"))>
			<cfdump var="#rHTTP2#" label="rHTTP2 [#url2##_CGI_SCRIPT_NAME#]" expand="No">
		</cfif>
	</cfif>
	
	<cfif (rHTTP1.Statuscode neq "200 OK")>
		<!--- Flag this server as being offline in the DB --->
		<cfscript>
			aStruct.Server1.ISONLINE = false;
		</cfscript>
	</cfif>
	
	<cfif (rHTTP2.Statuscode neq "200 OK")>
		<!--- Flag this server as being offline in the DB --->
		<cfscript>
			aStruct.Server2.ISONLINE = false;
		</cfscript>
	</cfif>
	
	<!--- Consider those servers that are flagged as being online - determine which one server has the least number of hits --->
	<cfscript>
		leastHits = 2^31;
		leastLatency = 2^31;
		sizeOfLatencyAR = ArrayLen(latencyAR);
		serverNumWithLeastHits = -1;
		numServersToConsider = 0;
		for (i = 1; i lte 99; i = i + 1) {
			try {
				if ( (IsStruct(aStruct['Server#i#'])) AND (aStruct['Server#i#'].ISONLINE) ) {
					numServersToConsider = numServersToConsider + 1;
					if ( (aStruct['Server#i#'].NUMHITS lt leastHits) OR ( (sizeOfLatencyAR gte i) AND (latencyAR[i].etMs lt leastLatency) ) ) {
						if (sizeOfLatencyAR gte i) {
							leastLatency = Min(latencyAR[i].etMs, leastLatency);
						}
						if (aStruct['Server#i#'].NUMHITS lt leastHits) {
							leastHits = aStruct['Server#i#'].NUMHITS;
						}
						serverNumWithLeastHits = i;
					}
				//	writeOutput('Considering Server#i#<br>');
				}
			} catch (Any e) {
			}
		}
		if ((bool_debugMode) AND (bool_allowDebug)) writeOutput('serverNumWithLeastHits = [#serverNumWithLeastHits#], leastHits = [#leastHits#]<br>');
		// Adjust the Db to reflect the hit the chosen server is about to get...
		// Create a suitable URL for the target server...
		// Redirect the hit to the target server...
	</cfscript>
	
	<cfscript>
		redirectToURL = '';
		
		torf = 'T';
		if (serverNumWithLeastHits eq 1) {
			torf = 'F';
			if (bool_cgiURL) {
				redirectToURL = 'http://#url1##_CGI_SCRIPT_NAME#?#CGI.QUERY_STRING#';
			} else {
				redirectToURL = 'http://#url1##_CGI_SCRIPT_NAME#';
			}
			aStruct.Server1.NUMHITS = aStruct.Server1.NUMHITS + 1;
		}
		safely_execSQL('qAddClusterStats1', DSN, "INSERT INTO ClusterStats (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (1,'#torf#',GetDate(),#latencyAR[1].endMs#,#aStruct.Server1.NUMHITS#); SELECT @@IDENTITY as 'id';");
		torf = 'T';
		if (serverNumWithLeastHits eq 2) {
			torf = 'F';
			if (bool_cgiURL) {
				redirectToURL = 'http://#url2##_CGI_SCRIPT_NAME#?#CGI.QUERY_STRING#';
			} else {
				redirectToURL = 'http://#url2##_CGI_SCRIPT_NAME#';
			}
			aStruct.Server2.NUMHITS = aStruct.Server2.NUMHITS + 1;
		}
		safely_execSQL('qAddClusterStats2', DSN, "INSERT INTO ClusterStats (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (2,'#torf#',GetDate(),#latencyAR[2].etMs#,#aStruct.Server2.NUMHITS#); SELECT @@IDENTITY as 'id';");
	</cfscript>

	<cfwddx action="CFML2WDDX" input="#aStruct#" output="_wddx" usetimezoneinfo="Yes">
	
	<cfif (bool_debugMode) AND (bool_allowDebug)>
		<cfoutput>
			<textarea cols="120" rows="10" readonly style="font-size: 10px;">#_wddx#</textarea>
		</cfoutput>
	</cfif>

	<cfcatch type="Any">
		<cfdump var="#cfcatch#" label="B. cfcatch" expand="No">
	</cfcatch>
</cftry>

<cfset endMs = GetTickCount( )>

<cfscript>
	etMs = endMs - beginMs;
	if ((bool_debugMode) AND (bool_allowDebug)) writeOutput('<br>etMs = [#etMs#]<br>');
</cfscript>

<cfscript>
	safely_execSQL('qAddClusterStatsF', DSN, "INSERT INTO ClusterStats (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (0,'F',GetDate(),#etMs#,#(aStruct.Server1.NUMHITS + aStruct.Server2.NUMHITS)#); SELECT @@IDENTITY as 'id';");
</cfscript>

<cfset Request.modusOperandi = "WRITE">
<cfinclude template="../../../../../Apache2/htdocs-StatsServer/includes/cfinclude_clusterDBRead.cfm">

<cfscript>
	if ((bool_debugMode) AND (bool_allowDebug)) writeOutput('redirectToURL = [#redirectToURL#]<br>');
</cfscript>

<cfif (Len(redirectToURL) gt 0)>
	<cflocation url="#redirectToURL#" addtoken="No">
<cfelseif (NOT IsDefined("Request.defaultContent"))>
	<h1>This Server is offline... PLS Standby.</h1>
<cfelse>
	<cfinclude template="#Request.defaultContent#">
</cfif>

</body>
</html>
