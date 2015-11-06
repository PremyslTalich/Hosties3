#pragma semicolon 1

#include <sourcemod>
#include <hosties3>
#include <hosties3_vip>
#include <dhooks>

#define FEATURE_NAME "All Spec"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
int g_iLogLevel;

Handle g_hIsValidTarget;
Handle g_hForceCamera;

bool g_bCheckNullPtr = false;

bool g_bAdmin;
bool g_bVIP;
int g_iVIPPoints;
bool g_bAll;

bool g_bVIPLoaded;

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
	MarkNativeAsOptional("DHookIsNullParam");

	return APLRes_Success;
}

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

	g_bAdmin = Hosties3_AddCvarBool(FEATURE_NAME, "Admin", true);

	if(g_bVIPLoaded)
	{
		g_bVIP = Hosties3_AddCvarBool(FEATURE_NAME, "VIP", false);
		g_iVIPPoints = Hosties3_AddCvarInt(FEATURE_NAME, "VIP Points", 6000);
	}

	g_bAll = Hosties3_AddCvarBool(FEATURE_NAME, "All", false);

	g_iLogLevel = Hosties3_GetLogLevel();


	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Admin: %d", FEATURE_NAME, g_bAdmin);

		if(g_bVIPLoaded)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] VIP: %d", FEATURE_NAME, g_bVIP);
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] VIP Points: %d", FEATURE_NAME, g_iVIPPoints);
		}

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] All: %d", FEATURE_NAME, g_bAll);

	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	g_hForceCamera = FindConVar("mp_forcecamera");

	if(!g_hForceCamera)
	{
		SetFailState("Failed to locate mp_forcecamera");
	}

	Handle hTmp = LoadGameConfigFile("allspec.hosties3");
	if (hTmp == null)
	{
		SetFailState("Gamedata (allspec.hosties3.txt) not founed!");
	}

	int offset = GameConfGetOffset(hTmp, "IsValidObserverTarget");
	g_hIsValidTarget = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, IsValidTarget);
	DHookAddParam(g_hIsValidTarget, HookParamType_CBaseEntity);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (Hosties3_IsClientValid(i) && !IsFakeClient(i))
		{
			Hosties3_OnPlayerReady(i);
		}
	}

	CloseHandle(hTmp);

	g_bCheckNullPtr = (GetFeatureStatus(FeatureType_Native, "DHookIsNullParam") == FeatureStatus_Available);
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
	if (!IsFakeClient(client))
	{
		if (g_bAll)
		{
			SendConVarValue(client, g_hForceCamera, "0");
			DHookEntity(g_hIsValidTarget, true, client);
		}
		else if (g_bVIPLoaded && (Hosties3_GetVIPPoints(client) >= g_iVIPPoints && g_bVIP))
		{
			SendConVarValue(client, g_hForceCamera, "0");
			DHookEntity(g_hIsValidTarget, true, client);
		}
		else if (Hosties3_IsClientAdmin(client) && g_bAdmin)
		{
			SendConVarValue(client, g_hForceCamera, "0");
			DHookEntity(g_hIsValidTarget, true, client);
		}

	}
}

public MRESReturn:IsValidTarget(int thisPointer, Handle hReturn, Handle hParams)
{
	if (g_bCheckNullPtr && DHookIsNullParam(hParams, 1))
	{
		return MRES_Ignored;
	}

	new target = DHookGetParam(hParams, 1);
	if (target <= 0 || target > MaxClients || !IsClientInGame(thisPointer) || !IsClientInGame(target) || !IsPlayerAlive(target) || IsPlayerAlive(thisPointer) || GetClientTeam(thisPointer) <= 1 || GetClientTeam(target) <= 1)
	{
		return MRES_Ignored;
	}
	else
	{
		DHookSetReturn(hReturn, true);
		return MRES_Override;
	}
}
