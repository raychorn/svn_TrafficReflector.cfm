<cfscript>
//	bool_debugMode = (Find("192.168.", CGI.REMOTE_ADDR) gt 0);
//	bool_debugMode = (Find("192.168.", CGI.REMOTE_ADDR) gt 0) OR (Find("127.0.0.1", CGI.REMOTE_ADDR) gt 0);
	bool_debugMode = false;

	bool_allowDebug = false;
	bool_simulatePhysicalServersOffline = false;
	
	const_ClusterStats_sumbol = 'ClusterStatsHits';
	
	bool_cgiURL = true;
	_CGI_SCRIPT_NAME = CGI.SCRIPT_NAME;
	if (FindNoCase('404.cfm', _CGI_SCRIPT_NAME) gt 0) {
		_CGI_SCRIPT_NAME = CGI.QUERY_STRING;
		bool_cgiURL = false;
	}
</cfscript>

<cfset beginMs = GetTickCount( )>

<cftry>
	<cfset Request.modusOperandi = "READ">
	<cfinclude template="../../../../../Apache2/htdocs-StatsServer/includes/cfinclude_clusterDBFunctions.cfm">
	<cfinclude template="../../../../../Apache2/htdocs-StatsServer/includes/cfinclude_clusterDBRead.cfm">

	<cfif (Request.clusterDBError)>
		<cflog file="Abstract_404_Handler" type="Information" text="Cluster DB Error: (READ) (#Request.clusterDBErrorMsg#)">
	</cfif>
	
	<cfcatch type="Any">
		<cflog file="Abstract_404_Handler" type="Information" text="Cluster DB Error: (READ) [#cfcatch.message#] [#cfcatch.detail#]">
	</cfcatch>
</cftry>

<cfscript>
	if ( (bool_debugMode) AND (bool_simulatePhysicalServersOffline) ) {
		_server1_isonline = aStruct.Server1.ISONLINE;
		_server2_isonline = aStruct.Server2.ISONLINE;
		aStruct.Server1.ISONLINE = false;
		aStruct.Server2.ISONLINE = false;
	}
</cfscript>

<cftry>
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
	<cfif (IsDefined("aStruct.Server1.ISONLINE")) AND (aStruct.Server1.ISONLINE)>
		<cfset latencyAR[1].beginMs = GetTickCount( )>
		<cftry>
			<cfhttp url="http://#url1##_CGI_SCRIPT_NAME#" method="GET" port="#CGI.SERVER_PORT#" result="rHTTP1" resolveurl="yes"></cfhttp>
	
			<cfcatch type="Any">
				<cflog file="Abstract_404_Handler" type="Information" text="Server 1 Latency Error: [#cfcatch.message#] [#cfcatch.detail#]">
			</cfcatch>
		</cftry>
		<cfset latencyAR[1].endMs = GetTickCount( )>
	
		<cfscript>
			latencyAR[1].etMs = latencyAR[1].endMs - latencyAR[1].beginMs;
			safely_execSQL('qAddClusterStats1a', DSN, "INSERT INTO #const_ClusterStats_sumbol# (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (1,'C',GetDate(),#latencyAR[1].etMs#,-1); SELECT @@IDENTITY as 'id';");
			if (Request.dbError) {
				cf_log('Abstract_404_Handler', 'qAddClusterStats1a :: ' & Request.moreErrorMsg);
			}
		</cfscript>
	<cfelse>
		<cfscript>
			latencyAR[1].etMs = 2^31;
		</cfscript>
	</cfif>

	<cfset latencyAR[2] = StructNew()>
	<cfif (IsDefined("aStruct.Server2.ISONLINE")) AND (aStruct.Server2.ISONLINE)>
		<cfset latencyAR[2].beginMs = GetTickCount( )>
		<cftry>
			<cfhttp url="http://#url2##_CGI_SCRIPT_NAME#" method="GET" port="#CGI.SERVER_PORT#" result="rHTTP2" resolveurl="yes"></cfhttp>
	
			<cfcatch type="Any">
				<cflog file="Abstract_404_Handler" type="Information" text="Server 2 Latency Error: [#cfcatch.message#] [#cfcatch.detail#]">
			</cfcatch>
		</cftry>
		<cfset latencyAR[2].endMs = GetTickCount( )>
	
		<cfscript>
			latencyAR[2].etMs = latencyAR[2].endMs - latencyAR[2].beginMs;
			safely_execSQL('qAddClusterStats2a', DSN, "INSERT INTO #const_ClusterStats_sumbol# (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (2,'C',GetDate(),#latencyAR[2].etMs#,-1); SELECT @@IDENTITY as 'id';");
			if (Request.dbError) {
				cf_log('Abstract_404_Handler', 'qAddClusterStats2a :: ' & Request.moreErrorMsg);
			}
		</cfscript>
	<cfelse>
		<cfscript>
			latencyAR[2].etMs = 2^31;
		</cfscript>
	</cfif>
	
	<cfset bool_wddxError = false>
	<cfif (IsDefined("rHTTP1"))>
		<cftry>
			<cfwddx action="CFML2WDDX" input="#rHTTP1#" output="_wddx" usetimezoneinfo="Yes">
	
			<cfcatch type="Any">
				<cfset bool_wddxError = true>
				<cflog file="Abstract_404_Handler" type="Information" text="CFML2WDDX Error: (rHTTP1) [#cfcatch.message#] [#cfcatch.detail#]">
			</cfcatch>
		</cftry>
	
		<cfscript>
			rHTTP1_Statuscode = Trim(rHTTP1.Statuscode);
			if ( (bool_wddxError) OR (rHTTP1_Statuscode IS '200 OK') OR (rHTTP1_Statuscode IS '404 Not Found') OR (rHTTP1_Statuscode IS '410 Gone') OR (rHTTP1_Statuscode IS '503 Server Error') ) {
				_wddx = ''; // no need to store this useless data if there was nothing worth looking at...
			}
			
			if (IsDefined("_wddx")) {
				safely_execSQL('qAddClusterStatus', DSN, "INSERT INTO ClusterStatus (serverNum, eventDt, Statuscode, cfhttp_wddx) VALUES (1,GetDate(),'#filterQuotesForSQL(rHTTP1_Statuscode)#','#filterQuotesForSQL(_wddx)#'); SELECT @@IDENTITY as 'id';");
				if (Request.dbError) {
					cf_log('Abstract_404_Handler', 'qAddClusterStatus :: ' & Request.moreErrorMsg);
				}
			}
		</cfscript>
	</cfif>
	
	<cfset bool_wddxError = false>
	<cfif (IsDefined("rHTTP2"))>
		<cftry>
			<cfwddx action="CFML2WDDX" input="#rHTTP2#" output="_wddx" usetimezoneinfo="Yes">
	
			<cfcatch type="Any">
				<cfset bool_wddxError = true>
				<cflog file="Abstract_404_Handler" type="Information" text="CFML2WDDX Error: (rHTTP2) [#cfcatch.message#] [#cfcatch.detail#]">
			</cfcatch>
		</cftry>
	
		<cfscript>
			rHTTP2_Statuscode = Trim(rHTTP2.Statuscode);
			if ( (bool_wddxError) OR (rHTTP2_Statuscode IS '200 OK') OR (rHTTP2_Statuscode IS '404 Not Found') OR (rHTTP2_Statuscode IS '410 Gone') OR (rHTTP2_Statuscode IS '503 Server Error') ) {
				_wddx = ''; // no need to store this useless data if there was nothing worth looking at...
			}
			
			if (IsDefined("_wddx")) {
				safely_execSQL('qAddClusterStatus', DSN, "INSERT INTO ClusterStatus (serverNum, eventDt, Statuscode, cfhttp_wddx) VALUES (2,GetDate(),'#filterQuotesForSQL(rHTTP2_Statuscode)#','#filterQuotesForSQL(_wddx)#'); SELECT @@IDENTITY as 'id';");
				if (Request.dbError) {
					cf_log('Abstract_404_Handler', 'qAddClusterStatus :: ' & Request.moreErrorMsg);
				}
			}
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
					if ( ( (aStruct.clusterMethod eq 1) AND (aStruct['Server#i#'].NUMHITS lt leastHits) ) OR ( (aStruct.clusterMethod eq 2) AND (sizeOfLatencyAR gte i) AND (latencyAR[i].etMs lt leastLatency) ) ) {
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

		if ( (bool_debugMode) AND (bool_simulatePhysicalServersOffline) ) cf_log('Abstract_404_Handler', '101. serverNumWithLeastHits = [#serverNumWithLeastHits#]');
		
		torf = 'T';
		reportedLatency = latencyAR[1].etMs;
		if (serverNumWithLeastHits eq 1) {
			torf = 'F';
			reportedLatency = leastLatency;
			if (bool_cgiURL) {
				redirectToURL = 'http://#url1##_CGI_SCRIPT_NAME#?#CGI.QUERY_STRING#';
			} else {
				redirectToURL = 'http://#url1##_CGI_SCRIPT_NAME#';
			}
			aStruct.Server1.NUMHITS = aStruct.Server1.NUMHITS + 1;
			safely_execSQL('qAddClusterStats1', DSN, "INSERT INTO #const_ClusterStats_sumbol# (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (1,'#torf#',GetDate(),#reportedLatency#,#aStruct.Server1.NUMHITS#); SELECT @@IDENTITY as 'id';");
			if (Request.dbError) {
				cf_log('Abstract_404_Handler', 'qAddClusterStats1 :: ' & Request.moreErrorMsg);
			}
		}

		torf = 'T';
		reportedLatency = latencyAR[2].etMs;
		if (serverNumWithLeastHits eq 2) {
			torf = 'F';
			reportedLatency = leastLatency;
			if (bool_cgiURL) {
				redirectToURL = 'http://#url2##_CGI_SCRIPT_NAME#?#CGI.QUERY_STRING#';
			} else {
				redirectToURL = 'http://#url2##_CGI_SCRIPT_NAME#';
			}
			aStruct.Server2.NUMHITS = aStruct.Server2.NUMHITS + 1;
			safely_execSQL('qAddClusterStats2', DSN, "INSERT INTO #const_ClusterStats_sumbol# (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (2,'#torf#',GetDate(),#reportedLatency#,#aStruct.Server2.NUMHITS#); SELECT @@IDENTITY as 'id';");
			if (Request.dbError) {
				cf_log('Abstract_404_Handler', 'qAddClusterStats2 :: ' & Request.moreErrorMsg);
			}
		}

		if (serverNumWithLeastHits eq -1) {
			_url = '/' & ListFirst(_CGI_SCRIPT_NAME, '/') & '/serverOffline.cfm';
			redirectToURL = 'http://#CGI.SERVER_NAME##_url#';
		}
	</cfscript>

	<cfwddx action="CFML2WDDX" input="#aStruct#" output="_wddx" usetimezoneinfo="Yes">
	
	<cfcatch type="Any">
		<cflog file="Abstract_404_Handler" type="Information" text="Primary Error: (101) [#cfcatch.message#] [#cfcatch.detail#]">
		<cfsavecontent variable="primaryErrorMsg">
			<cfdump var="#cfcatch#" label="cfcatch" expand="Yes">
		</cfsavecontent>
	</cfcatch>
</cftry>

<cfset endMs = GetTickCount( )>

<cfscript>
	etMs = endMs - beginMs;
	if ((bool_debugMode) AND (bool_allowDebug)) writeOutput('<br>etMs = [#etMs#]<br>');
</cfscript>

<cfscript>
	safely_execSQL('qAddClusterStatsF', DSN, "INSERT INTO #const_ClusterStats_sumbol# (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (0,'F',GetDate(),#etMs#,#(aStruct.Server1.NUMHITS + aStruct.Server2.NUMHITS)#); SELECT @@IDENTITY as 'id';");
	if (Request.dbError) {
		cf_log('Abstract_404_Handler', 'qAddClusterStatsF :: ' & Request.moreErrorMsg);
	}
</cfscript>

<cfscript>
	if ( (bool_debugMode) AND (bool_simulatePhysicalServersOffline) ) {
		aStruct.Server1.ISONLINE = _server1_isonline;
		aStruct.Server2.ISONLINE = _server2_isonline;
	}
</cfscript>

<cfset Request.modusOperandi = "WRITE">
<cfinclude template="../../../../../Apache2/htdocs-StatsServer/includes/cfinclude_clusterDBRead.cfm">

<cfscript>
	if ( (bool_debugMode) AND (bool_simulatePhysicalServersOffline) ) cf_log('Abstract_404_Handler', '201. redirectToURL = [#redirectToURL#], bool_debugMode = [#bool_debugMode#]');
</cfscript>

<cfif (NOT bool_debugMode)>
	<cfif (IsDefined("redirectToURL")) AND (Len(redirectToURL) gt 0)>
		<cfif (UCASE(CGI.REQUEST_METHOD) eq "GET")>
			<cflocation url="#redirectToURL#" addtoken="No">
		</cfif>
	<cfelseif (NOT IsDefined("Request.defaultContent"))>
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
		
		<html>
		<head>
			<title>ColdFusion MX 7 Cluster Manager v1.0 &copy;Hierarchical Applications Limited, All Rights Reserved.</title>
		</head>
		
		<body>
			<cfif (bool_debugMode) AND (IsDefined("primaryErrorMsg"))>
				<cfoutput>
					#primaryErrorMsg#
				</cfoutput>
			</cfif>
			<h3 style="color: blue;">This Server is offline... PLS Try Again Later.</h3>
		</body>
		</html>
	<cfelse>
		<cfinclude template="#Request.defaultContent#">
	</cfif>
<cfelse>
	<cfscript>
		if ( (bool_debugMode) AND (bool_simulatePhysicalServersOffline) ) cf_log('Abstract_404_Handler', '301. redirectToURL = [#redirectToURL#], bool_debugMode = [#bool_debugMode#]');
	</cfscript>
	<cfif (IsDefined("redirectToURL")) AND (Len(redirectToURL) gt 0)>
		<cfif (UCASE(CGI.REQUEST_METHOD) eq "GET")>
			<cflocation url="#redirectToURL#" addtoken="No">
		</cfif>
	<cfelseif (NOT IsDefined("Request.defaultContent"))>
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
		
		<html>
		<head>
			<title>ColdFusion MX 7 Cluster Manager v1.0 &copy;Hierarchical Applications Limited, All Rights Reserved.</title>
		</head>
		
		<body>
			<cfif (bool_debugMode) AND (IsDefined("primaryErrorMsg"))>
				<cfoutput>
					#primaryErrorMsg#
				</cfoutput>
			</cfif>
			<h3 style="color: blue;">This Server is offline... PLS Try Again Later.</h3>
		</body>
		</html>
	<cfelse>
		<cfinclude template="#Request.defaultContent#">
	</cfif>
</cfif>


