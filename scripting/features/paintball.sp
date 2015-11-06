#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hosties3>
#include <hosties3_vip>

#define FEATURE_NAME "Paintball"
#define FEATURE_FILE FEATURE_NAME ... ".cfg"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME
#define PLUGIN_CONFIG HOSTIES3_CONFIG ... FEATURE_FILE

bool g_bEnable;

int g_iNeedPoints;

int g_iLogLevel;

int g_iSpriteIndex[128];
int g_iSpriteIndexCount = 0;

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

public Hosties3_OnMapStart()
{
	Handle KvColors = CreateKeyValues("colors");
	char ConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigFile, sizeof(ConfigFile), "configs/hosties3/" ... FEATURE_FILE);
	if ( !FileToKeyValues(KvColors, ConfigFile) )
	{
		CloseHandle(KvColors);
		LogError("[ERROR] %s can not convert file to keyvalues: %s", FEATURE_NAME, ConfigFile);
		return;
	}

	KvRewind(KvColors);
	bool sectionExists;
	sectionExists = KvGotoFirstSubKey(KvColors);
	if ( !sectionExists )
	{
		CloseHandle(KvColors);
		LogError("[ERROR] %s can not find first keyvalues subkey in file: %s", FEATURE_NAME, ConfigFile);
		return;
	}

	char filename[PLATFORM_MAX_PATH];
	while ( sectionExists )
	{
		if ( KvGetNum(KvColors, "enabled") )
		{
			KvGetString(KvColors, "primary", filename, sizeof(filename));
			g_iSpriteIndex[g_iSpriteIndexCount++] = precachePaintballDecal(filename);
			KvGetString(KvColors, "secondary", filename, sizeof(filename));
			precachePaintballDecal(filename);
		}

		sectionExists = KvGotoNextKey(KvColors);
	}

	CloseHandle(KvColors);
}

precachePaintballDecal(const char[] filename)
{
	char tmpPath[PLATFORM_MAX_PATH];
	int result = 0;
	result = PrecacheDecal(filename, true);
	Format(tmpPath,sizeof(tmpPath),"materials/%s",filename);
	AddFileToDownloadsTable(tmpPath);
	return result;
}

public Hosties3_OnConfigsLoaded()
{
	if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	g_iNeedPoints = Hosties3_AddCvarInt(FEATURE_NAME, "Need Points", 2000);

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, true, g_iNeedPoints, HOSTIES3_DESCRIPTION);

	HookEvent("bullet_impact", Event_BulletImpact);
}

public Action Event_BulletImpact(Handle event, const char[] weapon, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	float fPos[3];
	fPos[0] = GetEventFloat(event, "x");
	fPos[1] = GetEventFloat(event, "y");
	fPos[2] = GetEventFloat(event, "z");

	if (g_iSpriteIndexCount && Hosties3_IsClientValid(client) && Hosties3_GetVIPPoints(client) >= g_iNeedPoints)
	{
		TE_SetupWorldDecal(fPos, g_iSpriteIndex[GetRandomInt(0, g_iSpriteIndexCount - 1)]);
		TE_SendToAll();
	}
}

TE_SetupWorldDecal(const Float:vecOrigin[3], int index)
{
	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("m_nIndex",index);
}
