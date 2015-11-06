#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

#include <hosties3>

#define FEATURE_NAME "Example"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
int g_iLogLevel;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = HOSTIES3_AUTHOR,
	version = HOSTIES3_VERSION,
	description = HOSTIES3_DESCRIPTION,
	url = HOSTIES3_URL
};

public void OnPluginStart()
{
	Hosties3_IsLoaded();
	Hosties3_CheckServerGame();
}

public void Hosties3_OnConfigsLoaded()
{
	Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "Try to load settings for %s", FEATURE_NAME);
	
	if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
}
