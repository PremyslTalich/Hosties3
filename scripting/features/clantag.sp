#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <hosties3>
#include <hosties3_vip>

#define FEATURE_NAME "Clan Tag"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

int g_iVIPTagPoints;
int g_iTagPoints;

char g_sTag[16];

int g_iLogLevel;

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

	g_iVIPTagPoints = Hosties3_AddCvarInt(FEATURE_NAME, "Need VIPTag Points", 2000);
	g_iTagPoints = Hosties3_AddCvarInt(FEATURE_NAME, "Need Tag Points", 1000);
	Hosties3_AddCvarString(FEATURE_NAME, "VIP Clan Tag", "[*VIP*]", g_sTag, sizeof(g_sTag));

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] VIPTag: %d", FEATURE_NAME, g_iVIPTagPoints);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Tag: %d", FEATURE_NAME, g_iTagPoints);
	}

	Hosties3_AddToFeatureList("VIP Tag", HOSTIES3_AUTHOR, true, g_iVIPTagPoints, HOSTIES3_DESCRIPTION);
	Hosties3_AddToFeatureList("Clan Tag", HOSTIES3_AUTHOR, true, g_iTagPoints, HOSTIES3_DESCRIPTION);

	CreateTimer(5.0, Timer_CheckClients);
}

public Hosties3_OnPlayerReady(int client)
{
	CheckClientClanTag(client);
}

public Hosties3_OnPlayerSpawn(int client)
{
	CheckClientClanTag(client);
}

public Hosties3_OnClientGetVIPPoints(int client, int points)
{
	CheckClientClanTag(client);
}

public Action Timer_CheckClients(Handle timer)
{
	Hosties3_LoopClients(i)
	{
		if(Hosties3_IsClientValid(i))
		{
			CheckClientClanTag(i);
		}
	}
}

stock CheckClientClanTag(int client)
{
	if(Hosties3_IsClientValid(client))
	{
		if(Hosties3_GetVIPPoints(client) >= g_iVIPTagPoints)
		{
			CS_SetClientClanTag(client, g_sTag);
		}
		else
		{
			char sBuffer[16];
			CS_GetClientClanTag(client, sBuffer, sizeof(sBuffer));

			if(Hosties3_GetVIPPoints(client) < g_iTagPoints || StrContains(sBuffer, g_sTag, false) != 0)
			{
				CS_SetClientClanTag(client, " ");
			}
		}
	}
}
