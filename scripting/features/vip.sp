#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <hosties3>
#include <hosties3_vip>

#define FEATURE_NAME "VIP"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

int g_bEnable;
int g_iLogLevel;

int g_bEnableMinPlayers;
int g_iMinPlayers;

int g_bOnRoundStart;
int g_iPointsOnRoundStart;

int g_bGetPointsPerKill;
int g_iPointsPerKill;
int g_iExtraPointsPerHeadShotKill;

int g_bTimeEnable;
float g_fTimeInterval;
int g_iTimePoints;

int g_bEnableCommands;
int g_iShowPoints;

int g_iGPCommands;
char g_sGPCommandsList[8][32];
char g_sGPCommands[128];

int g_iAPCommands;
char g_sAPCommandsList[8][32];
char g_sAPCommands[128];

int g_iDPCommands;
char g_sDPCommandsList[8][32];
char g_sDPCommands[128];

int g_iSPCommands;
char g_sSPCommandsList[8][32];
char g_sSPCommands[128];

int g_iRPCommands;
char g_sRPCommandsList[8][32];
char g_sRPCommands[128];

int g_iPoints[MAXPLAYERS + 1];

char g_sTag[64];
char g_sClientID[MAXPLAYERS + 1][128];

Handle g_hDatabase;
Handle g_hOnClientGetPoints;
Handle g_hTimePointsTimer[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = HOSTIES3_AUTHOR,
	version = HOSTIES3_VERSION,
	description = HOSTIES3_DESCRIPTION,
	url = HOSTIES3_URL
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Hosties3_GetVIPPoints", VIP_GetVIPPoints);
	CreateNative("Hosties3_AddVIPPoints", VIP_AddVIPPoints);
	CreateNative("Hosties3_SetVIPPoints", VIP_SetVIPPoints);
	CreateNative("Hosties3_DelVIPPoints", VIP_DelVIPPoints);
	CreateNative("Hosties3_ResetVIPPoints", VIP_ResetVIPPoints);

	g_hOnClientGetPoints = CreateGlobalForward("Hosties3_OnClientGetVIPPoints", ET_Ignore, Param_Cell, Param_Cell);

	RegPluginLibrary("hosties3_vip");

	return APLRes_Success;
}

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

	g_bEnableMinPlayers = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Min Players", true);
	g_bOnRoundStart = Hosties3_AddCvarBool(FEATURE_NAME, "On Round Start", true);
	g_bGetPointsPerKill = Hosties3_AddCvarBool(FEATURE_NAME, "Get Points Per Kill", true);
	g_bEnableCommands = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Commands", true);
	g_bTimeEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Time Points", true);


	g_iMinPlayers = Hosties3_AddCvarInt(FEATURE_NAME, "Min Players", 4);
	g_iPointsOnRoundStart = Hosties3_AddCvarInt(FEATURE_NAME, "Points On Round Start", 1);
	g_iPointsPerKill = Hosties3_AddCvarInt(FEATURE_NAME, "Points Per Kill", 1);
	g_iExtraPointsPerHeadShotKill = Hosties3_AddCvarInt(FEATURE_NAME, "Extra Points Per Headshot Kill", 1);
	g_iShowPoints = Hosties3_AddCvarInt(FEATURE_NAME, "Show Points", 1);
	g_iTimePoints = Hosties3_AddCvarInt(FEATURE_NAME, "Time Points", 1);

	g_fTimeInterval = Hosties3_AddCvarFloat(FEATURE_NAME, "Time Interval", 3.0);

	g_iLogLevel = Hosties3_GetLogLevel();
	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	Hosties3_AddCvarString(FEATURE_NAME, "Get Points Command", "points", g_sGPCommands, sizeof(g_sGPCommands));
	Hosties3_AddCvarString(FEATURE_NAME, "Add Points Command", "addpoints", g_sAPCommands, sizeof(g_sAPCommands));
	Hosties3_AddCvarString(FEATURE_NAME, "Del Points Command", "delpoints", g_sDPCommands, sizeof(g_sDPCommands));
	Hosties3_AddCvarString(FEATURE_NAME, "Set Points Command", "setpoints", g_sSPCommands, sizeof(g_sSPCommands));
	Hosties3_AddCvarString(FEATURE_NAME, "Reset Points Command", "resetpoints", g_sRPCommands, sizeof(g_sRPCommands));

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] EnableMinPlayers: %d", FEATURE_NAME, g_bEnableMinPlayers);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] MinPlayers: %d", FEATURE_NAME, g_iMinPlayers);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] OnRoundStart: %d", FEATURE_NAME, g_bOnRoundStart);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PointsOnRoundStart: %d", FEATURE_NAME, g_iPointsOnRoundStart);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] GetPointsPerKill: %d", FEATURE_NAME, g_bGetPointsPerKill);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PointsPerKill: %d", FEATURE_NAME, g_iPointsPerKill);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] EnableTimePoints: %d", FEATURE_NAME, g_bTimeEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] TimeInterval: %.2f", FEATURE_NAME, g_fTimeInterval);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] TimePoints: %d", FEATURE_NAME, g_iTimePoints);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] ExtraPointsPerHeadShotKill: %d", FEATURE_NAME, g_iExtraPointsPerHeadShotKill);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable Commands: %d", FEATURE_NAME, g_bEnableCommands);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Show Points: %d", FEATURE_NAME, g_iShowPoints);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] GetPoints Commands: %s", FEATURE_NAME, g_sGPCommands);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] AddPoints Commands: %s", FEATURE_NAME, g_sAPCommands);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] DelPoints Commands: %s", FEATURE_NAME, g_sDPCommands);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] SetPoints Commands: %s", FEATURE_NAME, g_sSPCommands);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] ResetPoints Commands: %s", FEATURE_NAME, g_sRPCommands);
	}

	if (g_bEnableCommands)
	{
		g_iGPCommands = ExplodeString(g_sGPCommands, ";", g_sGPCommandsList, sizeof(g_sGPCommandsList), sizeof(g_sGPCommandsList[]));
		for(int i = 0; i < g_iGPCommands; i++)
		{
			char sBuffer[32];
			Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sGPCommandsList[i]);
			RegConsoleCmd(sBuffer, Command_GetPoints);
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Get Points Command: %s Full: %s", FEATURE_NAME, g_sGPCommandsList[i], sBuffer);
		}

		g_iAPCommands = ExplodeString(g_sAPCommands, ";", g_sAPCommandsList, sizeof(g_sAPCommandsList), sizeof(g_sAPCommandsList[]));
		for(int i = 0; i < g_iAPCommands; i++)
		{
			char sBuffer[32];
			Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sAPCommandsList[i]);
			RegAdminCmd(sBuffer, Command_AddPoints, ADMFLAG_ROOT);
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Add Points Command: %s Full: %s", FEATURE_NAME, g_sAPCommandsList[i], sBuffer);
		}

		g_iDPCommands = ExplodeString(g_sDPCommands, ";", g_sDPCommandsList, sizeof(g_sDPCommandsList), sizeof(g_sDPCommandsList[]));
		for(int i = 0; i < g_iDPCommands; i++)
		{
			char sBuffer[32];
			Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sDPCommandsList[i]);
			RegAdminCmd(sBuffer, Command_DelPoints, ADMFLAG_ROOT);
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Del Points Command: %s Full: %s", FEATURE_NAME, g_sDPCommandsList[i], sBuffer);
		}

		g_iSPCommands = ExplodeString(g_sSPCommands, ";", g_sSPCommandsList, sizeof(g_sSPCommandsList), sizeof(g_sSPCommandsList[]));
		for(int i = 0; i < g_iSPCommands; i++)
		{
			char sBuffer[32];
			Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sSPCommandsList[i]);
			RegAdminCmd(sBuffer, Command_SetPoints, ADMFLAG_ROOT);
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Set Points Command: %s Full: %s", FEATURE_NAME,  g_sSPCommandsList[i], sBuffer);
		}

		g_iRPCommands = ExplodeString(g_sRPCommands, ";", g_sRPCommandsList, sizeof(g_sRPCommandsList), sizeof(g_sRPCommandsList[]));
		for(int i = 0; i < g_iRPCommands; i++)
		{
			char sBuffer[32];
			Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sRPCommandsList[i]);
			RegAdminCmd(sBuffer, Command_ResetPoints, ADMFLAG_ROOT);
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Reset Points Command: %s Full: %s", FEATURE_NAME, g_sRPCommandsList[i], sBuffer);
		}
	}

	LoadTranslations("hosties3_vip.phrases");
}

public Hosties3_OnSQLConnected(Handle database)
{
	if (Hosties3_IsSQLValid(database))
	{
		g_hDatabase = CloneHandle(database);

		CheckTables();
	}
}

public Hosties3_OnPlayerReady(int client)
{
	char sQuery[2048];
	Hosties3_GetClientID(client, g_sClientID[client], sizeof(g_sClientID[]));
	Format(sQuery, sizeof(sQuery), "SELECT points FROM hosties3_vip WHERE id = '%s'", g_sClientID[client]);
	SQL_TQuery(g_hDatabase, SQL_ClientConnect, sQuery, GetClientUserId(client));
}

public VIP_GetVIPPoints(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		return g_iPoints[client];
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
	return false;
}

public VIP_AddVIPPoints(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	int points = GetNativeCell(2);

	if (Hosties3_IsClientValid(client))
	{
		ChangePoints(client, Hosties3_GetVIPPoints(client) + points);
		Hosties3_PrintToChat(client, "%T", "PointsEarned", client, g_sTag, points);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
	return false;
}

public VIP_SetVIPPoints(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	int points = GetNativeCell(2);

	if (Hosties3_IsClientValid(client))
	{
		ChangePoints(client, points);
		Hosties3_PrintToChat(client, "%T", "PointsSet", client, g_sTag, points);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
	return false;
}

public VIP_DelVIPPoints(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	int points = GetNativeCell(2);

	if (Hosties3_IsClientValid(client))
	{
		ChangePoints(client, Hosties3_GetVIPPoints(client) - points);
		Hosties3_PrintToChat(client, "%T", "PointsTaken", client, g_sTag, points);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
	return false;
}

public VIP_ResetVIPPoints(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		ChangePoints(client, 0);
		Hosties3_PrintToChat(client, "%T", "PointsReset", client, g_sTag);
		return true;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
	return false;
}

public Hosties3_OnRoundStart()
{
	if (g_bOnRoundStart)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
			{
				int iPlayers;

				Hosties3_LoopClients(j)
				{
					if (Hosties3_IsClientValid(j) && GetClientTeam(j) > CS_TEAM_SPECTATOR)
					{
						iPlayers++;
					}
				}

				if (g_bEnableMinPlayers && iPlayers >= g_iMinPlayers || !g_bEnableMinPlayers)
				{
					Hosties3_AddVIPPoints(i, g_iPointsOnRoundStart);
				}
			}
		}
	}
}

public Hosties3_OnPlayerDeath(int victim, int attacker, int assister, const char[] weapon, bool headshot)
{
	if (GetClientTeam(victim) != GetClientTeam(attacker))
	{
		if (g_bGetPointsPerKill)
		{
			int iPoints;

			iPoints += g_iPointsPerKill;

			if (headshot)
			{
				iPoints += g_iExtraPointsPerHeadShotKill;
			}

			int iPlayers;

			Hosties3_LoopClients(i)
			{
				if (Hosties3_IsClientValid(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
				{
					iPlayers++;
				}
			}

			if (g_bEnableMinPlayers && iPlayers >= g_iMinPlayers || !g_bEnableMinPlayers)
			{
				Hosties3_AddVIPPoints(attacker, iPoints);
			}
		}
	}
}

public Action Command_GetPoints(int client, args)
{
	if (g_iShowPoints == 0)
	{
		Hosties3_PrintToChat(client, "%T", "OwnPoints", client, g_sTag, Hosties3_GetVIPPoints(client));
	}
	else if (g_iShowPoints == 1)
	{
		Hosties3_PrintToChat(client, "%T", "OwnPoints", client, g_sTag, Hosties3_GetVIPPoints(client));

		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i, _, _, true) && i != client)
			{
				Hosties3_PrintToChat(i, "%T", "OtherPoints", i, g_sTag, client, Hosties3_GetVIPPoints(client));
			}
		}
	}
	else if (g_iShowPoints == 2)
	{
		Hosties3_PrintToChat(client, "%T", "OwnPoints", client, g_sTag, Hosties3_GetVIPPoints(client));

		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i) && i != client)
			{
				Hosties3_PrintToChat(i, "%T", "OtherPoints", i, g_sTag, client, Hosties3_GetVIPPoints(client));
			}
		}
	}
}

public Action Command_AddPoints(int client, args)
{
	if (args < 2 || args > 2)
	{
		ReplyToCommand(client, "sm_addpoints <#UserID|Name> <points>");
		return Plugin_Handled;
	}

	char sArg1[65];
	char sArg2[65];
	GetCmdArg(1, sArg1, sizeof(sArg1));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(sArg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (Hosties3_IsClientValid(target))
		{
			Hosties3_AddVIPPoints(target, StringToInt(sArg2));
			Hosties3_PrintToChat(client, "%T", "Admin_AddPoints", client, g_sTag, target, StringToInt(sArg2));
		}
		else
		{
			Hosties3_ReplyToCommand(client, "%T", "InvalidTarget", client, g_sTag, target);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Command_DelPoints(int client, args)
{
	if (args < 2 || args > 2)
	{
		ReplyToCommand(client, "sm_delpoints <#UserID|Name> <points>");
		return Plugin_Handled;
	}

	char sArg1[65];
	char sArg2[65];
	GetCmdArg(1, sArg1, sizeof(sArg1));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(sArg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (Hosties3_IsClientValid(target))
		{
			Hosties3_DelVIPPoints(target, StringToInt(sArg2));
			Hosties3_PrintToChat(client, "%T", "Admin_DelPoints", client, g_sTag, StringToInt(sArg2), target);
		}
		else
		{
			Hosties3_ReplyToCommand(client, "%T", "InvalidTarget", client, g_sTag, target);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Command_SetPoints(int client, args)
{
	if (args < 2 || args > 2)
	{
		ReplyToCommand(client, "sm_setpoints <#UserID|Name> <points>");
		return Plugin_Handled;
	}

	char sArg1[65];
	char sArg2[65];
	GetCmdArg(1, sArg1, sizeof(sArg1));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(sArg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (Hosties3_IsClientValid(target))
		{
			Hosties3_SetVIPPoints(target, StringToInt(sArg2));
			Hosties3_PrintToChat(client, "%T", "Admin_SetPoints", client, g_sTag, target, StringToInt(sArg2));
		}
		else
		{
			Hosties3_ReplyToCommand(client, "%T", "InvalidTarget", client, g_sTag, target);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Command_ResetPoints(int client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "sm_resetpoints <#UserID|Name>");
		return Plugin_Handled;
	}

	char sArg1[65];
	GetCmdArg(1, sArg1, sizeof(sArg1));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(sArg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (Hosties3_IsClientValid(target))
		{
			Hosties3_ResetVIPPoints(target);
			Hosties3_PrintToChat(client, "%T", "Admin_ResPoints", client, g_sTag, target);
		}
		else
		{
			Hosties3_ReplyToCommand(client, "%T", "InvalidTarget", client, g_sTag, target);
			return Plugin_Handled;
		}


	}

	return Plugin_Continue;
}

public SQL_ClientConnect(Handle owner, Handle hndl, const char[] error, any userid)
{
	if (hndl != null)
	{
		int client = GetClientOfUserId(userid);

		if (Hosties3_IsClientValid(client) && !IsFakeClient(client))
		{
			if (!SQL_FetchRow(hndl))
			{
				char sQuery[2048];
				g_iPoints[client] = 0;
				Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_vip` (`id`, `points`) VALUES ('%s', 0)", g_sClientID[client]);
				SQLQuery(sQuery);
			}
			else
			{
				g_iPoints[client] = SQL_FetchInt(hndl, 0);
			}

			if (g_bTimeEnable)
			{
				float fTime = (g_fTimeInterval * 60);
				g_hTimePointsTimer[client] = CreateTimer(fTime, VIP_TimePoints, GetClientUserId(client), TIMER_REPEAT);
			}
		}
	}
	else
	{
		if (error[0])
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, ERROR, "Connection to database has failed!: %s", error);
			return;
		}
	}
}

public Action VIP_TimePoints(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (Hosties3_IsClientValid(client) && GetClientTeam(client) > CS_TEAM_SPECTATOR)
	{
		int iPlayers;

		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i) && GetClientTeam(i) > CS_TEAM_SPECTATOR)
			{
				iPlayers++;
			}
		}

		if (g_bEnableMinPlayers && iPlayers >= g_iMinPlayers || !g_bEnableMinPlayers)
		{
			Hosties3_AddVIPPoints(client, g_iTimePoints);
		}
	}
}

CheckTables()
{
	char sQuery[] = "\
		CREATE TABLE IF NOT EXISTS `hosties3_vip` ( \
			`id` varchar(128) NOT NULL, \
			`points` INT NOT NULL DEFAULT 0, \
			PRIMARY KEY (`id`), \
			UNIQUE KEY (`id`) \
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;";

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

ChangePoints(int client, int points)
{
	char sQuery[1024];
	g_iPoints[client] = points;

	Format(sQuery, sizeof(sQuery), "UPDATE `hosties3_vip` SET `points`='%d' WHERE `id`='%s'", g_iPoints[client], g_sClientID[client]);
	SQLQuery(sQuery);

	Call_StartForward(g_hOnClientGetPoints);
	Call_PushCell(g_iPoints[client]);
	Call_Finish();
}
