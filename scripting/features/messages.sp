#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <geoip>
#include <hosties3>

#undef REQUIRE_PLUGIN
#tryinclude <hosties3_vip>

#define FEATURE_NAME "Messages"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

#define CONNECT 1
#define DISCONNECT 2
#define CTJOIN 3
#define TJOIN 4
#define SPECJOIN 5

#define VIP_CONNECT 6
#define VIP_DISCONNECT 7
#define VIP_CTJOIN 8
#define VIP_TJOIN 9
#define VIP_SPECJOIN 10

bool g_bEnable;
bool g_bVIPLoaded;

bool g_bConnect;
bool g_bVIPConnect;
int g_iVIPConnect;

bool g_bDisconnect;
bool g_bVIPDisconnect;
int g_iVIPDisconnect;

bool g_bCTJoin;
bool g_bVIPCTJoin;
int g_iVIPCTJoin;

bool g_bTJoin;
bool g_bVIPTJoin;
int g_iVIPTJoin;

bool g_bSpecJoin;
bool g_bVIPSpecJoin;
int g_iVIPSpecJoin;


int g_iLogLevel;

char g_sTag[64];

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

	if(LibraryExists("hosties3_vip"))
	{
		g_bVIPLoaded = true;
	}

	g_bConnect = Hosties3_AddCvarBool(FEATURE_NAME, "Connect", true);
	g_bVIPConnect = Hosties3_AddCvarBool(FEATURE_NAME, "VIP Connect", true);
	g_iVIPConnect = Hosties3_AddCvarInt(FEATURE_NAME, "VIP Connect", 2000);

	g_bDisconnect = Hosties3_AddCvarBool(FEATURE_NAME, "Disconnect", true);
	g_bVIPDisconnect = Hosties3_AddCvarBool(FEATURE_NAME, "VIP Disconnect", true);
	g_iVIPDisconnect = Hosties3_AddCvarInt(FEATURE_NAME, "VIP Disconnect", 2000);

	g_bCTJoin = Hosties3_AddCvarBool(FEATURE_NAME, "CT Join", true);
	g_bVIPCTJoin = Hosties3_AddCvarBool(FEATURE_NAME, "VIP CT Join", true);
	g_iVIPCTJoin = Hosties3_AddCvarInt(FEATURE_NAME, "VIP CT Join", 2000);

	g_bTJoin = Hosties3_AddCvarBool(FEATURE_NAME, "T Join", true);
	g_bVIPTJoin = Hosties3_AddCvarBool(FEATURE_NAME, "VIP T Join", true);
	g_iVIPTJoin = Hosties3_AddCvarInt(FEATURE_NAME, "VIP T Join", 2000);

	g_bSpecJoin = Hosties3_AddCvarBool(FEATURE_NAME, "Spec Join", true);
	g_bVIPSpecJoin = Hosties3_AddCvarBool(FEATURE_NAME, "VIP Spec Join", true);
	g_iVIPSpecJoin = Hosties3_AddCvarInt(FEATURE_NAME, "VIP Spec Join", 2000);


	g_iLogLevel = Hosties3_GetLogLevel();
	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Connect: %d", FEATURE_NAME, g_bConnect);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] VIP Connect: %d", FEATURE_NAME, g_bVIPConnect);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Connect Points: %d", FEATURE_NAME, g_iVIPConnect);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Disconnect: %d", FEATURE_NAME, g_bDisconnect);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] VIP Disconnect: %d", FEATURE_NAME, g_bVIPDisconnect);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Disconnect Points: %d", FEATURE_NAME, g_iVIPDisconnect);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CT Join: %d", FEATURE_NAME, g_bCTJoin);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] VIP CT Join: %d", FEATURE_NAME, g_bVIPCTJoin);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CT Join Points: %d", FEATURE_NAME, g_iVIPCTJoin);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] T Join: %d", FEATURE_NAME, g_bTJoin);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] VIP T Join: %d", FEATURE_NAME, g_bVIPTJoin);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] T Join Points: %d", FEATURE_NAME, g_iVIPTJoin);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Spec Join: %d", FEATURE_NAME, g_bSpecJoin);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] VIP Spec Join: %d", FEATURE_NAME, g_bVIPSpecJoin);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Spec Join Points: %d", FEATURE_NAME, g_iVIPSpecJoin);

	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	HookEvent("player_team", Event_PlayerTeam);

	LoadTranslations("hosties3_messages.phrases");
}

public OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_vip"))
	{
		g_bVIPLoaded = true;
	}
}

public Hosties3_OnPlayerReady(int client)
{
	if(g_bVIPLoaded && (g_bVIPConnect && Hosties3_GetVIPPoints(client) >= g_iVIPDisconnect))
	{
		GetTranslation(client, VIP_CONNECT);
	}
	else if (g_bConnect)
	{
		GetTranslation(client, CONNECT);
	}
}

public Hosties3_OnPlayerDisconnect(int client)
{
	if(g_bVIPLoaded && (g_bVIPDisconnect && Hosties3_GetVIPPoints(client) >= g_iVIPConnect))
	{
		GetTranslation(client, VIP_DISCONNECT);
	}
	else if (g_bDisconnect)
	{
		GetTranslation(client, DISCONNECT);
	}
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");

	if(Hosties3_IsClientValid(client))
	{
		if (team == CS_TEAM_SPECTATOR)
		{
			if(g_bVIPLoaded && (g_bVIPSpecJoin && Hosties3_GetVIPPoints(client) >= g_iVIPSpecJoin))
			{
				GetTranslation(client, VIP_SPECJOIN);
			}
			else if(g_bSpecJoin)
			{
				GetTranslation(client, SPECJOIN);
			}
		}
		else if (team == CS_TEAM_CT)
		{
			if(g_bVIPLoaded && (g_bVIPCTJoin && Hosties3_GetVIPPoints(client) >= g_iVIPCTJoin))
			{
				GetTranslation(client, VIP_CTJOIN);
			}
			else if(g_bCTJoin)
			{
				GetTranslation(client, CTJOIN);
			}
		}
		else if (team == CS_TEAM_T)
		{
			if(g_bVIPLoaded && (g_bVIPTJoin && Hosties3_GetVIPPoints(client) >= g_iVIPTJoin))
			{
				GetTranslation(client, VIP_TJOIN);
			}
			else if(g_bTJoin)
			{
				GetTranslation(client, TJOIN);
			}
		}
	}
}

GetTranslation(int client, int type)
{
	char message[512];

	if (type == CONNECT)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%T", "Connect", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
	else if (type == DISCONNECT)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%T", "Disconnect", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
	else if (type == SPECJOIN)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%T", "Spectator", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
	else if (type == CTJOIN)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%T", "CounterTerrorist", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
	else if (type == TJOIN)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%T", "Terrorist", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
	else if (type == VIP_CONNECT)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%TVIP_", "Connect", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
	else if (type == VIP_DISCONNECT)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%T", "VIP_Disconnect", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
	else if (type == VIP_SPECJOIN)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%T", "VIP_Spectator", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
	else if (type == VIP_CTJOIN)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%T", "VIP_CounterTerrorist", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
	else if (type == VIP_TJOIN)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Format(message, sizeof(message), "%T", "VIP_Terrorist", i, g_sTag);
				PrintMessage(client, i, message);
			}
		}
	}
}

PrintMessage(int client, int target, const char[] sMessage)
{
	char message[512];
	strcopy(message, sizeof(message), sMessage);

	if (StrContains(message, "{NAME}", true) != -1)
	{
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		ReplaceString(message, sizeof(message), "{NAME}", name);
	}

	if (StrContains(message, "{STEAMID2}", true) != -1)
	{
		char steamid[MAX_NAME_LENGTH];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		ReplaceString(message, sizeof(message), "{STEAMID2}", steamid);
	}

	if (StrContains(message, "{STEAMID3}", true) != -1)
	{
		char steamid[MAX_NAME_LENGTH];
		GetClientAuthId(client, AuthId_Steam3, steamid, sizeof(steamid));
		ReplaceString(message, sizeof(message), "{STEAMID3}", steamid);
	}

	if (StrContains(message, "{STEAMID64}", true) != -1)
	{
		char steamid[MAX_NAME_LENGTH];
		GetClientAuthId(client, AuthId_SteamID64, steamid, sizeof(steamid));
		ReplaceString(message, sizeof(message), "{STEAMID64}", steamid);
	}

	if (StrContains(message, "{IP}", true) != -1)
	{
		char ip[MAX_NAME_LENGTH];
		GetClientIP(client, ip, sizeof(ip));
		ReplaceString(message, sizeof(message), "{IP}", ip);
	}

	if (StrContains(message, "{COUNTRYCODE2}", true) != -1)
	{
		char cc2[3];
		char ip[MAX_NAME_LENGTH];
		GetClientIP(client, ip, sizeof(ip));
		GeoipCode2(ip, cc2);
		ReplaceString(message, sizeof(message), "{COUNTRYCODE2}", cc2);
	}

	if (StrContains(message, "{COUNTRYCODE3}", true) != -1)
	{
		char cc3[4];
		char ip[MAX_NAME_LENGTH];
		GetClientIP(client, ip, sizeof(ip));
		GeoipCode3(ip, cc3);
		ReplaceString(message, sizeof(message), "{COUNTRYCODE3}", cc3);
	}

	if (StrContains(message, "{COUNTRY}", true) != -1)
	{
		char country[MAX_NAME_LENGTH];
		char ip[MAX_NAME_LENGTH];
		GetClientIP(client, ip, sizeof(ip));
		GeoipCountry(ip, country, sizeof(country));
		ReplaceString(message, sizeof(message), "{COUNTRY}", country);
	}

	Hosties3_PrintToChat(target, message);
}
