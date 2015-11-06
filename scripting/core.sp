#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <regex>
#include <smlib>
#include <multicolors>
#include <hosties3>

#define FEATURE_NAME "Core"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

#pragma newdecls required

#include "core/globals.sp"
#include "core/native.sp"
#include "core/client.sp"
#include "core/misc.sp"
#include "core/sql.sp"
#include "core/cvar.sp"
#include "core/admins.sp"
#include "core/cache.sp"
#include "core/commands.sp"


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
	Native_AskPluginLoad2();
	
	RegPluginLibrary("hosties3");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	GetGame();
	Hosties3_CheckServerGame();
	
	g_bSQLReady = false;
	
	if (!g_bStarted)
	{
		FullCacheReset();
		Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
		ConnectToSQL();
	}
	
	LoadTranslations("hosties3_core.phrases");
}

public void OnMapStart()
{
	if (!g_bStarted)
	{
		FullCacheReset();
		Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
		ConnectToSQL();
	}
}

/* public OnMapEnd()
{
	if(g_bStarted)
	{
		g_bStarted = false;
	}
} */

public void OnClientPutInServer(int client)
{
	g_bClientReady[client] = false;
	SQL_CheckPlayer(client);
}

public void OnClientDisconnect(int client)
{
	if (Hosties3_IsClientValid(client))
	{
		UpdatePlayerName(client);
		
		Call_StartForward(g_hOnClientDisconnect);
		Call_PushCell(client);
		Call_Finish();
	}
}

public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	RequestFrame(OnPlayerSpawn, client);
}

public void OnPlayerSpawn(any client)
{
	if (Hosties3_IsClientValid(client))
	{
		Call_StartForward(g_hOnPlayerSpawn);
		Call_PushCell(client);
		Call_Finish();
	}
}

void GetGame()
{
	if (GetEngineVersion() == Engine_CSS)
	{
		g_iGame = Game_CSS;
	}
	else if (GetEngineVersion() == Engine_CSGO)
	{
		g_iGame = Game_CSGO;
	}
	else
	{
		g_iGame = Game_Unsupported;
	}
}

void LoadConfig()
{
	if (Hosties3_IsSQLValid(g_hDatabase))
	{
		if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
		{
			SetFailState("'%s' is deactivated!", FEATURE_NAME);
			return ;
		}
		
		g_bAutoUpdate = Hosties3_AddCvarBool(FEATURE_NAME, "Auto Update", true);
		g_iLogLevel = Hosties3_AddCvarInt(FEATURE_NAME, "Log Level", 2);
		Hosties3_AddCvarString(FEATURE_NAME, "Color Tag", "{green}[Hosties3]{lightgreen}", g_sTag, sizeof(g_sTag));
		Hosties3_AddCvarString(FEATURE_NAME, "Clean Tag", "[Hosties3]", g_sCTag, sizeof(g_sCTag));
		Hosties3_AddCvarString(FEATURE_NAME, "Fl Commands", "features", g_sFlCom, sizeof(g_sFlCom));
	}
	
	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Auto Update: %d", FEATURE_NAME, g_bAutoUpdate);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Log Level: %d", FEATURE_NAME, g_iLogLevel);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Tag: %s", FEATURE_NAME, g_sTag);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Clean Tag: %s", FEATURE_NAME, g_sCTag);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Fl Commands: %s", FEATURE_NAME, g_sFlCom);
	}
	
	g_iFlCom = ExplodeString(g_sFlCom, ";", g_sFlComList, sizeof(g_sFlComList), sizeof(g_sFlComList[]));
	
	for (int i = 0; i < g_iFlCom; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sFlComList[i]);
		RegConsoleCmd(sBuffer, Command_Featurelist);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sFlComList[i], sBuffer);
	}
	
	HookEvent("player_spawn", Event_OnPlayerSpawn);

	Call_StartForward(g_hOnConfigsLoaded);
	Call_Finish();
}
