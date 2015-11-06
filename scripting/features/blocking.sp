#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <hosties3>

#undef REQUIRE_PLUGIN
#tryinclude <hosties3_rebel>

#undef REQUIRE_EXTENSIONS
#tryinclude <sendproxy>

#define FEATURE_NAME "Blocking"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
int g_iLogLevel;
int g_iTHideRadar;
int g_iCTHideRadar;
bool g_bRemoveBuyzone;
bool g_bRemoveLocation;
bool g_bGrenadeSpam;
bool g_bRadioSpam;
bool g_bNameChangeSpam;
bool g_bAchievementSpam;
bool g_bTeamJoinMessage;
bool g_bConnectMessage;
bool g_bDisconnectMessage;
bool g_bBlockTextMsg;

char g_sRadioCommands[][] = {"coverme", "takepoint", "holdpos", "regroup", "followme", "takingfire", "go", "fallback", "sticktog", "getinpos", "stormfront", "report", "roger", "enemyspot", "needbackup", "sectorclear", "inposition", "reportingin", "getout", "negative","enemydown", "compliment", "thanks", "cheer"};

bool g_bSendProxy = false;

Handle g_hDatabase;

bool g_bRebel = false;

enum BlockTextMsgCache
{
	String:btmName[64]
};

Handle g_hBtmCache;
int g_iBtmCacheTmp[BlockTextMsgCache];

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

	if(LibraryExists("hosties3_rebel"))
	{
		g_bRebel = true;
	}

	g_bRemoveBuyzone = Hosties3_AddCvarBool(FEATURE_NAME, "Remove Buyzone", true);
	g_bRemoveLocation = Hosties3_AddCvarBool(FEATURE_NAME, "Remove Location", true);
	g_bGrenadeSpam = Hosties3_AddCvarBool(FEATURE_NAME, "Grenade Spam", true);
	g_bRadioSpam = Hosties3_AddCvarBool(FEATURE_NAME, "Radio Spam", true);
	g_bNameChangeSpam = Hosties3_AddCvarBool(FEATURE_NAME, "Name Change Spam", true);
	g_bAchievementSpam = Hosties3_AddCvarBool(FEATURE_NAME, "Achievement Spam", true);
	g_bTeamJoinMessage = Hosties3_AddCvarBool(FEATURE_NAME, "Team Join Message", true);
	g_bConnectMessage = Hosties3_AddCvarBool(FEATURE_NAME, "Connect Message", true);
	g_bDisconnectMessage = Hosties3_AddCvarBool(FEATURE_NAME, "Disconnect Message", true);
	g_bBlockTextMsg = Hosties3_AddCvarBool(FEATURE_NAME, "Block Text Msg", true);

	g_iTHideRadar = Hosties3_AddCvarInt(FEATURE_NAME, "T Hide Radar", 1);
	g_iCTHideRadar = Hosties3_AddCvarInt(FEATURE_NAME, "CT Hide Radar", 1);
	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] T Hide Radar: %d", FEATURE_NAME, g_iTHideRadar);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CT Hide Radar: %d", FEATURE_NAME, g_iCTHideRadar);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Remove Buyzone: %d", FEATURE_NAME, g_bRemoveBuyzone);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Remove Location: %d", FEATURE_NAME, g_bRemoveLocation);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Grenade Spam: %d", FEATURE_NAME, g_bGrenadeSpam);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Radio Spam: %d", FEATURE_NAME, g_bRadioSpam);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Name Change Spam: %d", FEATURE_NAME, g_bNameChangeSpam);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Achievement Spam: %d", FEATURE_NAME, g_bAchievementSpam);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Team Join Message: %d", FEATURE_NAME, g_bTeamJoinMessage);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Connect Message: %d", FEATURE_NAME, g_bConnectMessage);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Disconnect Message: %d", FEATURE_NAME, g_bDisconnectMessage);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Block Text Msg: %d", FEATURE_NAME, g_bBlockTextMsg);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	if(Hosties3_GetServerGame() == Game_CSS)
	{
		int iStatus = GetExtensionFileStatus("sendproxy.ext");

		if (iStatus != 1)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, ERROR, "[%s] 'SendProxy Manager' not found!", FEATURE_NAME);
		}
		else if (iStatus == 1)
		{
			g_bSendProxy = true;
		}
	}

	Hosties3_LoopClients(client)
	{
		if (Hosties3_IsClientValid(client))
		{
			SDKHook(client, SDKHook_PostThink, OnPostThink);
		}
	}

	if (g_bGrenadeSpam)
	{
		SetConVarInt(FindConVar("sv_ignoregrenaderadio"), 1);
	}

	if (g_bGrenadeSpam)
	{
		for(int i; i < sizeof(g_sRadioCommands); i++)
		{
			AddCommandListener(Command_BlockRadio, g_sRadioCommands[i]);
		}
	}

	if (g_bNameChangeSpam)
	{
		HookUserMessage(GetUserMessageId("SayText2"), UserMessage_SayText2, true);
	}

	if (g_bBlockTextMsg)
	{
		HookUserMessage(GetUserMessageId("TextMsg"), UserMessage_TextMsg, true);
	}

	if (g_bAchievementSpam)
	{
		HookEvent("achievement_earned", Event_AchievementEarned, EventHookMode_Pre);
	}

	if (g_bTeamJoinMessage)
	{
		HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	}

	if (g_bConnectMessage)
	{
		HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Pre);
	}

	if (g_bDisconnectMessage)
	{
		HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	}
}

public OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_rebel"))
	{
		g_bRebel = true;
	}
}

public Hosties3_OnSQLConnected(Handle database)
{
	if (Hosties3_IsSQLValid(database))
	{
		g_hDatabase = CloneHandle(database);

		CheckTables();
		ResetBtmCache();
		GetNames();
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThink, OnPostThink);
}

public OnPostThink(client)
{
	if (Hosties3_IsClientValid(client))
	{
		if (g_bRemoveBuyzone)
		{
			SetEntProp(client, Prop_Send, "m_bInBuyZone", 0);
		}

		if (g_bRemoveLocation)
		{
			SetEntPropString(client, Prop_Send, "m_szLastPlaceName", "");
		}

		if (GetClientTeam(client) == CS_TEAM_T)
		{
			if (g_iTHideRadar == 1 && g_bRebel)
			{
				if (!Hosties3_IsClientRebel(client))
				{
					if (Hosties3_GetServerGame() == Game_CSGO)
					{
						SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
					}
					else if (Hosties3_GetServerGame() == Game_CSS && g_bSendProxy)
					{
						new iPlayerManager = FindEntityByClassname(0, "cs_player_manager");

						for (new i = 1; i <= MaxClients; i++)
						{
							if (Hosties3_IsClientValid(i))
							{
								SendProxy_HookArrayProp(iPlayerManager, "m_bPlayerSpotted", i, Prop_Int, Hook_PlayerManager);
							}
						}
						SendProxy_Hook(iPlayerManager, "m_bBombSpotted", Prop_Int, Hook_PlayerManager);
					}
				}
			}
			else if (g_iTHideRadar == 2 && g_bRebel)
			{
				if (Hosties3_IsClientRebel(client))
				{
					if (Hosties3_GetServerGame() == Game_CSGO)
					{
						SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
					}
					else if (Hosties3_GetServerGame() == Game_CSS && g_bSendProxy)
					{
						new iPlayerManager = FindEntityByClassname(0, "cs_player_manager");

						for (new i = 1; i <= MaxClients; i++)
						{
							if (Hosties3_IsClientValid(i))
							{
								SendProxy_HookArrayProp(iPlayerManager, "m_bPlayerSpotted", i, Prop_Int, Hook_PlayerManager);
							}
						}
						SendProxy_Hook(iPlayerManager, "m_bBombSpotted", Prop_Int, Hook_PlayerManager);
					}
				}
			}
			else if (g_iTHideRadar == 3)
			{
				if (Hosties3_GetServerGame() == Game_CSGO)
				{
					SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
				}
				else if (Hosties3_GetServerGame() == Game_CSS && g_bSendProxy)
				{
					new iPlayerManager = FindEntityByClassname(0, "cs_player_manager");

					for (new i = 1; i <= MaxClients; i++)
					{
						if (Hosties3_IsClientValid(i))
						{
							SendProxy_HookArrayProp(iPlayerManager, "m_bPlayerSpotted", i, Prop_Int, Hook_PlayerManager);
						}
					}
					SendProxy_Hook(iPlayerManager, "m_bBombSpotted", Prop_Int, Hook_PlayerManager);
				}
			}
		}
		/* else if (GetClientTeam(client) == CS_TEAM_CT)
		{
			if (g_iCTHideRadar == 1)
			{
				if (!Hosties3_IsClientHeadGuard(client))
				{
					if (Hosties3_GetServerGame() == Game_CSGO)
					{
						SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
					}
					else if (Hosties3_GetServerGame() == Game_CSS && g_bSendProxy)
					{
						new iPlayerManager = FindEntityByClassname(0, "cs_player_manager");

						for (new i = 1; i <= MaxClients; i++)
						{
							if (Hosties3_IsClientValid(i))
							{
								SendProxy_HookArrayProp(iPlayerManager, "m_bPlayerSpotted", i, Prop_Int, Hook_PlayerManager);
							}
						}
						SendProxy_Hook(iPlayerManager, "m_bBombSpotted", Prop_Int, Hook_PlayerManager);
					}
				}
			}
			else if (g_iCTHideRadar == 2)
			{
				if (Hosties3_IsClientHeadGuard(client))
				{
					if (Hosties3_GetServerGame() == Game_CSGO)
					{
						SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
					}
					else if (Hosties3_GetServerGame() == Game_CSS && g_bSendProxy)
					{
						new iPlayerManager = FindEntityByClassname(0, "cs_player_manager");

						for (new i = 1; i <= MaxClients; i++)
						{
							if (Hosties3_IsClientValid(i))
							{
								SendProxy_HookArrayProp(iPlayerManager, "m_bPlayerSpotted", i, Prop_Int, Hook_PlayerManager);
							}
						}
						SendProxy_Hook(iPlayerManager, "m_bBombSpotted", Prop_Int, Hook_PlayerManager);
					}
				}
			}
			else if (g_iCTHideRadar == 3)
			{
				if (Hosties3_GetServerGame() == Game_CSGO)
				{
					SetEntPropEnt(client, Prop_Send, "m_bSpotted", 0);
				}
				else if (Hosties3_GetServerGame() == Game_CSS && g_bSendProxy)
				{
					new iPlayerManager = FindEntityByClassname(0, "cs_player_manager");

					for (new i = 1; i <= MaxClients; i++)
					{
						if (Hosties3_IsClientValid(i))
						{
							SendProxy_HookArrayProp(iPlayerManager, "m_bPlayerSpotted", i, Prop_Int, Hook_PlayerManager);
						}
					}
					SendProxy_Hook(iPlayerManager, "m_bBombSpotted", Prop_Int, Hook_PlayerManager);
				}
			}
		} */
	}
}

public Action Event_AchievementEarned(Handle event, const char[] name, bool dontBroadcast)
{
	return (Plugin_Handled);
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	return (Plugin_Handled);
}

public Action Event_PlayerConnect(Handle event, const char[] name, bool dontBroadcast)
{
	return (Plugin_Handled);
}

public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	return (Plugin_Handled);
}

public Action Command_BlockRadio(int client, const char[] command, args)
{
	return Plugin_Handled;
}

public Action UserMessage_SayText2(UserMsg msg_hd, Handle hMessage, const players[], playersNum, bool reliable, bool init)
{
	if (Hosties3_GetServerGame() == Game_CSS)
	{
		char sMessage[96];
		BfReadString(hMessage, sMessage, sizeof(sMessage));
		BfReadString(hMessage, sMessage, sizeof(sMessage));

		if (StrContains(sMessage, "Name_Change") != -1)
		{
			BfReadString(hMessage, sMessage, sizeof(sMessage));
			return Plugin_Handled;
		}
	}
	else if (Hosties3_GetServerGame() == Game_CSGO)
	{
		char sBuffer[64];
		new iRepeat = PbGetRepeatedFieldCount(hMessage, "params");
		for(new i = 0; i < iRepeat; i++)
		{
			PbReadString(hMessage, "params", sBuffer, sizeof(sBuffer), i);
			if (StrEqual(sBuffer, ""))
			{
				continue;
			}

			if (StrContains(sBuffer, "Name_Change") != -1)
			{
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action UserMessage_TextMsg(UserMsg msg_hd, Handle hText, const players[], playersNum, bool reliable, bool init)
{
	for (int i = 0; i < GetArraySize(g_hBtmCache); i++)
	{
		new iCache[BlockTextMsgCache];
		GetArrayArray(g_hBtmCache, i, iCache[0]);

		if (Hosties3_GetServerGame() == Game_CSS)
		{
			char sText[96];
			BfReadString(hText, sText, sizeof(sText));
			BfReadString(hText, sText, sizeof(sText));

			if (StrContains(sText, iCache[btmName]) != -1)
			{
				BfReadString(hText, sText, sizeof(sText));
				return Plugin_Handled;
			}
		}
		else if (Hosties3_GetServerGame() == Game_CSGO)
		{
			if(reliable)
			{
				decl String:sText[32];
				PbReadString(hText, "params", sText, sizeof(sText),0);
				if (StrContains(sText, iCache[btmName], false) != -1)
				{
					return Plugin_Handled;
				}
			}
		}
	}

	return Plugin_Continue;
}

public Action Hook_PlayerManager(int entity, const char[] propname, &iValue, int element)
{
	iValue = 0;
	return Plugin_Changed;
}

CheckTables()
{
	char sQuery[] = "\
		CREATE TABLE IF NOT EXISTS `hosties3_block_textmsg` ( \
			`name` varchar(64) NOT NULL \
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
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, ERROR, "(SQL_Callback) Query failed: %s", error);
		return false;
	}
	return true;
}

GetNames()
{
	char sQuery[2048];
	Format(sQuery, sizeof(sQuery), "SELECT name FROM hosties3_block_textmsg");
	SQL_TQuery(g_hDatabase, SQL_GetNames, sQuery);
}

public SQL_GetNames(Handle owner, Handle hndl, const char[] error, any userid)
{
	if (hndl != null)
	{
		if (SQL_FetchRow(hndl))
		{
			int iCache[BlockTextMsgCache];

			SQL_FetchString(hndl, 0, iCache[btmName], 64);

			PushArrayArray(g_hBtmCache, iCache[0]);
		}
	}
}

ResetBtmCache()
{
	if (g_hBtmCache != null)
	{
		ClearArray(g_hBtmCache);
	}
	else
	{
		g_hBtmCache = CreateArray(sizeof(g_iBtmCacheTmp));
	}
}
