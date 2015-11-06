#pragma semicolon 1

#include <sourcemod>
#include <SteamWorks>
#include <hosties3>

#define FEATURE_NAME "Description"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
int g_iLogLevel;

char g_sDescription[64];

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

	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_AddCvarString(FEATURE_NAME, "Description", "Jail by Hosties3", g_sDescription, sizeof(g_sDescription));

	if (g_iLogLevel <= 2)
	{
		if (StrEqual(g_sDescription, "", false))
		{
			SetFailState("[Hosties3] No '%s' found!", FEATURE_NAME);
			return;
		}

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Description: %s", FEATURE_NAME, g_sDescription);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	SetDescription();
}

SetDescription()
{
	SteamWorks_SetGameDescription(g_sDescription);

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] %s set to %s", FEATURE_NAME, FEATURE_NAME, g_sDescription);
	}
}
