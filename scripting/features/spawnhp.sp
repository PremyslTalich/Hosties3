#pragma semicolon 1

#include <sourcemod>
#include <hosties3>
#include <hosties3_vip>

#define FEATURE_NAME "Spawn HP"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

int g_iMaxHP;
int g_iSpawnHP;
int g_iMultiplier;
int g_iMultiplierMax;

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

	g_iMaxHP = Hosties3_AddCvarInt(FEATURE_NAME, "Max HP", 150);
	g_iSpawnHP = Hosties3_AddCvarInt(FEATURE_NAME, "Spawn HP", 10);
	g_iMultiplier = Hosties3_AddCvarInt(FEATURE_NAME, "Multiplier", 2000);
	g_iMultiplierMax = Hosties3_AddCvarInt(FEATURE_NAME, "Multiplier Max", 3);

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Max HP: %d", FEATURE_NAME, g_iMaxHP);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Spawn HP: %d", FEATURE_NAME, g_iSpawnHP);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Multiplier: %d", FEATURE_NAME, g_iMultiplier);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Multiplier Max: %d", FEATURE_NAME, g_iMultiplierMax);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, true, g_iMultiplier, HOSTIES3_DESCRIPTION);
}

public Hosties3_OnPlayerSpawn(int client)
{
	int points = Hosties3_GetVIPPoints(client);

	for (int i = 1; i <= g_iMultiplierMax; i++)
	{
		if(points >= g_iMultiplier * i)
		{
			SetEntProp(client, Prop_Data, "m_iMaxHealth", g_iMaxHP);

			if((GetClientHealth(client) + g_iSpawnHP) <= g_iMaxHP)
			{
				SetEntityHealth(client, (GetClientHealth(client) + g_iSpawnHP));
			}
			else if((GetClientHealth(client) + g_iSpawnHP) > g_iMaxHP)
			{
				SetEntityHealth(client, g_iMaxHP);
			}
		}
	}
}
