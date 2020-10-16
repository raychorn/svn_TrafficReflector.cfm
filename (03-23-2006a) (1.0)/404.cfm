<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

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
	
	<cfif (bool_debugMode)>
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
		</UL>
	</cfif>
	
	<cfscript>
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
	
	<cfset beginMs1 = GetTickCount( )>
	<cfhttp url="http://#url1##CGI.SCRIPT_NAME#" method="GET" port="#CGI.SERVER_PORT#" result="rHTTP1" resolveurl="yes"></cfhttp>
	<cfset endMs1 = GetTickCount( )>
	<cfscript>
		etMs1 = endMs1 - beginMs1;
		writeOutput('etMs1 = [#etMs1#]<br>');
	</cfscript>

	<cfset beginMs2 = GetTickCount( )>
	<cfhttp url="http://#url2##CGI.SCRIPT_NAME#" method="GET" port="#CGI.SERVER_PORT#" result="rHTTP2" resolveurl="yes"></cfhttp>
	<cfset endMs2 = GetTickCount( )>
	<cfscript>
		etMs2 = endMs2 - beginMs2;
		writeOutput('etMs2 = [#etMs2#]<br>');
	</cfscript>
	
	<cfif (bool_debugMode)>
		<cfif (IsDefined("rHTTP1"))>
			<cfdump var="#rHTTP1#" label="rHTTP1 [#url1##CGI.SCRIPT_NAME#]" expand="No">
		</cfif>
		
		<cfif (IsDefined("rHTTP2"))>
			<cfdump var="#rHTTP2#" label="rHTTP2 [#url2##CGI.SCRIPT_NAME#]" expand="No">
		</cfif>
	</cfif>
	
	<cfif (rHTTP1.Statuscode neq "200 OK")>
		<!--- Flag this server as being offline in the DB --->
	</cfif>
	
	<cfif (rHTTP2.Statuscode neq "200 OK")>
		<!--- Flag this server as being offline in the DB --->
	</cfif>
	
	<!--- Consider those servers that are flagged as being online - determine which one server has the least number of hits --->
	<cfscript>
		leastHits = 2^31;
		serverNumWithLeastHits = -1;
		numServersToConsider = 0;
		for (i = 1; i lte 99; i = i + 1) {
			try {
				if ( (IsStruct(aStruct['Server#i#'])) AND (aStruct['Server#i#'].ISONLINE) ) {
					numServersToConsider = numServersToConsider + 1;
					if (aStruct['Server#i#'].NUMHITS lt leastHits) {
						leastHits = aStruct['Server#i#'].NUMHITS;
						serverNumWithLeastHits = i;
					}
					writeOutput('Considering Server#i#<br>');
				}
			} catch (Any e) {
			}
		}
		writeOutput('serverNumWithLeastHits = [#serverNumWithLeastHits#], leastHits = [#leastHits#]<br>');
		// Adjust the Db to reflect the hit the chosen server is about to get...
		// Create a suitable URL for the target server...
		// Redirect the hit to the target server...
	</cfscript>
	
	<cfscript>
		torf = 'T';
		if (serverNumWithLeastHits eq 1) {
			torf = 'F';
		}
		safely_execSQL('qAddClusterStats1', DSN, "INSERT INTO ClusterStats (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (1,'#torf#',GetDate(),#etMs1#,#aStruct.Server1.NUMHITS#); SELECT @@IDENTITY as 'id';");
		torf = 'T';
		if (serverNumWithLeastHits eq 2) {
			torf = 'F';
		}
		safely_execSQL('qAddClusterStats2', DSN, "INSERT INTO ClusterStats (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (2,'#torf#',GetDate(),#etMs2#,#aStruct.Server2.NUMHITS#); SELECT @@IDENTITY as 'id';");
	</cfscript>

	<cfwddx action="CFML2WDDX" input="#aStruct#" output="_wddx" usetimezoneinfo="Yes">
	
	<cfif (bool_debugMode)>
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
	writeOutput('<br>etMs = [#etMs#]<br>');
</cfscript>

<cfscript>
	safely_execSQL('qAddClusterStatsF', DSN, "INSERT INTO ClusterStats (serverNum, jobStep, beginDt, elapsedMs, numHits) VALUES (0,'F',GetDate(),#etMs#,#(aStruct.Server1.NUMHITS + aStruct.Server2.NUMHITS)#); SELECT @@IDENTITY as 'id';");
</cfscript>

</body>
</html>
