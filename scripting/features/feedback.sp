#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hosties3>

#define FEATURE_NAME "Feedback"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

float g_fCooldown;
Handle g_hTimer[MAXPLAYERS + 1] = {null, ...};

int g_iLogLevel;

char g_sTag[128];

Handle g_hDatabase;

int g_iCom;
char g_sComList[8][32];
char g_sCom[128];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = HOSTIES3_AUTHOR,
	version = HOSTIES3_VERSION,
	description = HOSTIES3_DESCRIPTION,
	url = HOSTIES3_URL
};

public Hosties3_OnPluginPreLoaded()
{
	Hosties3_IsLoaded();
	Hosties3_CheckServerGame();
}

public Hosties3_OnConfigsLoaded()
{
	if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	g_fCooldown = Hosties3_AddCvarFloat(FEATURE_NAME, "Cooldown", 15.0);
	Hosties3_AddCvarString(FEATURE_NAME, "Commands", "feedback", g_sCom, sizeof(g_sCom));

	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Commands: %s", FEATURE_NAME, g_sCom);
	}

	g_iCom = ExplodeString(g_sCom, ";", g_sComList, sizeof(g_sComList), sizeof(g_sComList[]));

	for(int i = 0; i < g_iCom; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sComList[i]);
		RegAdminCmd(sBuffer, Command_Feedback, ADMFLAG_GENERIC);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sComList[i], sBuffer);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	LoadTranslations("common.phrases");
	LoadTranslations("hosties3_feedback.phrases");
}

public Action Command_Feedback(int client, int args)
{
	if (args < 1)
	{
		Hosties3_PrintToChat(client, "%T", "Usage", client, g_sTag);
		return Plugin_Handled;
	}

	if(g_hTimer[client] == null)
	{
		char sUserId[64], sMap[128], sIp[16], sPort[8], sGame[12], sMessage[256], sQuery[1024];

		Hosties3_GetClientID(client, sUserId, sizeof(sUserId));
		GetCurrentMap(sMap, sizeof(sMap));
		GetConVarString(FindConVar("ip"), sIp, sizeof(sIp));
		GetConVarString(FindConVar("hostport"), sPort, sizeof(sPort));
		GetCmdArgString(sMessage, sizeof(sMessage));

		if(Hosties3_GetServerGame() == Game_CSGO)
		{
			Format(sGame, sizeof(sGame), "csgo");
		}
		else if(Hosties3_GetServerGame() == Game_CSS)
		{
			Format(sGame, sizeof(sGame), "css");
		}

		Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_feedback` (`pid`, `date`, `smap`, `sip`, `sport`, `game`, `feedback`) VALUES ('%s', UNIX_TIMESTAMP(), '%s', '%s', '%s', '%s', '%s')", sUserId, sMap, sIp, sPort, sGame, sMessage);
		SQLQuery(sQuery);

		g_hTimer[client] = CreateTimer(g_fCooldown, Timer_Cooldown, GetClientUserId(client));

		Hosties3_PrintToChat(client, "%T", "Sended", client, g_sTag, sMessage);
	}
	else
	{
		Hosties3_PrintToChat(client, "%T", "NotSended", client, g_sTag, g_fCooldown);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Timer_Cooldown(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if(Hosties3_IsClientValid(client))
	{
		g_hTimer[client] = null;
		return Plugin_Stop;
	}
	return Plugin_Stop;
}

public Hosties3_OnSQLConnected(Handle database)
{
	if (Hosties3_IsSQLValid(database))
	{
		g_hDatabase = CloneHandle(database);

		CheckTables();
	}
}

CheckTables()
{
	char sQuery[] = "\
		CREATE TABLE IF NOT EXISTS `hosties3_feedback` ( \
		  `id` int(11) NOT NULL AUTO_INCREMENT, \
		  `date` int(10) NOT NULL, \
		  `pid` varchar(64) NOT NULL, \
		  `smap` varchar(32) NOT NULL, \
		  `sip` varchar(16) NOT NULL, \
		  `sport` varchar(6) NOT NULL, \
		  `game` varchar(32) NOT NULL, \
		  `feedback` varchar(255) NOT NULL, \
		  PRIMARY KEY (`id`) \
		) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;";

	SQLQuery(sQuery);
}

SQLQuery(char[] sQuery)
{
	Handle hPack = CreateDataPack();
	WritePackString(hPack, sQuery);
	SQL_TQuery(g_hDatabase, SQL_Callback, sQuery, hPack);
}

public SQL_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (error[0])
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, ERROR, "Query failed: %s", error);
		return;
	}
}
