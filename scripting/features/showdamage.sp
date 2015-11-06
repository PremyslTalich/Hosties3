#pragma semicolon 1

#include <sourcemod>
#include <hosties3>
#include <hosties3_vip>

#define FEATURE_NAME "Show Damage"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

int g_iNeedPoints;

int g_iLogLevel;

bool g_bVIPLoaded;

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

	if(g_bVIPLoaded)
	{
		g_iNeedPoints = Hosties3_AddCvarInt(FEATURE_NAME, "Need Points", 2000);
	}

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		if(g_bVIPLoaded)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Need Points: %d", FEATURE_NAME, g_iNeedPoints);
		}
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, true, g_iNeedPoints, HOSTIES3_DESCRIPTION);

	LoadTranslations("hosties3_showdamage.phrases");
}

public OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_vip"))
	{
		g_bVIPLoaded = true;
	}
}

public Hosties3_OnPlayerHurt(int victim, int attacker, int damage, const char[] weapon)
{
	if(g_bVIPLoaded && Hosties3_GetVIPPoints(attacker) >= g_iNeedPoints)
	{
		PrintCenterText(attacker, "%T", "CenterOutput", attacker, damage);
		PrintToConsole(attacker, "%T", "ConsoleOutput", attacker, damage, victim);
	}
}
