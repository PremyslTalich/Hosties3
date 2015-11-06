#pragma semicolon 1

#include <sourcemod>
#include <hosties3>
#include <hosties3_vip>

#define FEATURE_NAME "Kill HP"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

int g_iMaxHP;
int g_iNormalKill;
int g_iHeadShotKill;
int g_iNeedPoints;

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

	g_iMaxHP = Hosties3_AddCvarInt(FEATURE_NAME, "Max HP", 150);
	g_iNormalKill = Hosties3_AddCvarInt(FEATURE_NAME, "Normal Kill", 2);
	g_iHeadShotKill = Hosties3_AddCvarInt(FEATURE_NAME, "Head Shot Kill", 3);
	g_iNeedPoints = Hosties3_AddCvarInt(FEATURE_NAME, "Need Points", 2000);

	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Max HP: %d", FEATURE_NAME, g_iMaxHP);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Normal Kill: %d", FEATURE_NAME, g_iNormalKill);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Head Shot Kill: %d", FEATURE_NAME, g_iHeadShotKill);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Need Points: %d", FEATURE_NAME, g_iNeedPoints);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, true, g_iNeedPoints, HOSTIES3_DESCRIPTION);

	LoadTranslations("hosties3_killhp.phrases");
}

public Hosties3_OnPlayerDeath(int victim, int attacker, int assister, const char[] weapon, bool headshot)
{
	if(GetClientTeam(victim) != GetClientTeam(attacker))
	{
		if(Hosties3_GetVIPPoints(attacker) >= g_iNeedPoints)
		{
			if(headshot)
			{
				AddHP(attacker, g_iNormalKill);
				Hosties3_PrintToChat(attacker, "%T", "NormalKill", attacker, g_sTag, g_iNormalKill, victim);
			}
			else
			{
				AddHP(attacker, g_iHeadShotKill);
				Hosties3_PrintToChat(attacker, "%T", "HeadshotKill", attacker, g_sTag, g_iHeadShotKill, victim);
			}
		}
	}
}

stock AddHP(int client, int hp)
{
	if(GetClientHealth(client) <= g_iMaxHP)
	{
		SetEntityHealth(client, (GetClientHealth(client) + hp));
	}
	else
	{
		SetEntityHealth(client, g_iMaxHP);
	}
}
