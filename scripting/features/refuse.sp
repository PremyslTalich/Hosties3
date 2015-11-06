#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hosties3>
#include <hosties3_refuse>

#undef REQUIRE_PLUGIN
#tryinclude <hosties3_vip>

#define FEATURE_NAME "Refuse"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

#define BEAM_CSS "materials/sprites/laser.vmt"
#define HALO_CSS "materials/sprites/halo01.vmt"
#define BEAM_CSGO "materials/sprites/laserbeam.vmt"
#define HALO_CSGO "materials/sprites/glow01.vmt"

bool  g_bEnable;
int g_iLogLevel;

int g_iMultiplier;
int g_iMaxRefuse;
int g_iMinTs;

int g_iRed[MAXPLAYERS + 1] = {255, ...};
int g_iGreen[MAXPLAYERS + 1] = {255, ...};
int g_iBlue[MAXPLAYERS + 1] = {255, ...};
int g_iAlpha[MAXPLAYERS + 1] = {255, ...};

float g_fReset;
bool g_bRun[MAXPLAYERS + 1] =  {false, ...};

int g_iCCount[MAXPLAYERS + 1] = {0, ...};
int g_iMaxCount[MAXPLAYERS + 1] = {1, ...};

int g_iBeamSprite;
int g_iHaloSprite;

int g_iRefuseCom;
char g_sRefuseComList[8][32];
char g_sRefuseCom[128];

char g_sTag[128];

bool g_bVIPLoaded;

Handle g_hOnClientRefuse;
Handle g_hOnClientRefuseEnd;

Handle g_hResetTimer[MAXPLAYERS + 1] = {null, ...};

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
	CreateNative("Hosties3_GetClientRefuse", Refuse_GetClientRefuse);
	CreateNative("Hosties3_GetClientMaxRefuse", Refuse_GetClientMaxRefuse);
	CreateNative("Hosties3_SetClientRefuse", Refuse_SetClientRefuse);
	CreateNative("Hosties3_SetClientMaxRefuse", Refuse_SetClientMaxRefuse);

	CreateNative("Hosties3_IsClientInRefusing", Refuse_IsClientInRefusing);

	g_hOnClientRefuse = CreateGlobalForward("Hosties3_OnClientRefuse", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hOnClientRefuseEnd = CreateGlobalForward("Hosties3_OnClientRefuseEnd", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	RegPluginLibrary("hosties3_refuse");

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

	g_iLogLevel = Hosties3_GetLogLevel();

	g_iMultiplier = Hosties3_AddCvarInt(FEATURE_NAME, "Multiplier", 2000);
	g_iMaxRefuse = Hosties3_AddCvarInt(FEATURE_NAME, "Max Refuse", 1);
	g_iMinTs = Hosties3_AddCvarInt(FEATURE_NAME, "Min Ts", 1);

	g_fReset = Hosties3_AddCvarFloat(FEATURE_NAME, "Reset Effect Time", 10.0);

	Hosties3_AddCvarString(FEATURE_NAME, "Commands", "v;refuse;verweigern", g_sRefuseCom, sizeof(g_sRefuseCom));
	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, true, g_iMultiplier, HOSTIES3_DESCRIPTION);

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Multiplier: %d", FEATURE_NAME, g_iMultiplier);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] MaxRefuse: %d", FEATURE_NAME, g_iMaxRefuse);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] MinTs: %d", FEATURE_NAME, g_iMinTs);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Commands: %s", FEATURE_NAME, g_sRefuseCom);
	}

	g_iRefuseCom = ExplodeString(g_sRefuseCom, ";", g_sRefuseComList, sizeof(g_sRefuseComList), sizeof(g_sRefuseComList[]));

	for(int i = 0; i < g_iRefuseCom; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sRefuseComList[i]);
		RegConsoleCmd(sBuffer, Command_Refuse);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sRefuseComList[i], sBuffer);
	}

	LoadTranslations("hosties3_refuse.phrases");
}

public OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_vip"))
	{
		g_bVIPLoaded = true;
	}
}

public Refuse_GetClientRefuse(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		return g_iCCount[client];
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}

	return false;
}

public Refuse_SetClientRefuse(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	int count = GetNativeCell(2);

	if (Hosties3_IsClientValid(client))
	{
		g_iCCount[client] = count;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}

	return false;
}

public Refuse_GetClientMaxRefuse(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		return g_iMaxCount[client];
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}

	return false;
}

public Refuse_SetClientMaxRefuse(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	int count = GetNativeCell(2);

	if (Hosties3_IsClientValid(client))
	{
		g_iMaxCount[client] = count;
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}

	return false;
}

public Refuse_IsClientInRefusing(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		return g_bRun[client];
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}

	return false;
}

public Hosties3_OnMapStart()
{
	if (Hosties3_GetServerGame() == Game_CSS)
	{
		g_iBeamSprite = PrecacheModel(BEAM_CSS);
		g_iHaloSprite = PrecacheModel(HALO_CSS);
	}
	else if (Hosties3_GetServerGame() == Game_CSGO)
	{
		g_iBeamSprite = PrecacheModel(BEAM_CSGO);
		g_iHaloSprite = PrecacheModel(HALO_CSGO);
	}
}

public Hosties3_OnPlayerDisconnect(int client)
{
	if (Hosties3_IsClientValid(client))
	{
		Reset(client);
	}
}

public Hosties3_OnPlayerSpawn(int client)
{
	Reset(client);
}

public Hosties3_OnPlayerDeath(int victim, int attacker, int assister, const char[] weapon, bool headshot)
{
	Reset(victim);
}

Reset(client)
{
	g_iCCount[client] = 0;
}

public Action Command_Refuse(client, args)
{
	if (GetClientTeam(client) == CS_TEAM_T)
	{
		if (IsPlayerAlive(client))
		{
			if (CheckTeam() >= g_iMinTs)
			{
				int iPoints;

				if(g_bVIPLoaded)
				{
					iPoints = Hosties3_GetVIPPoints(client);
				}
				else
				{
					iPoints = 0;
				}

				if (g_iMaxRefuse == 1 || iPoints < g_iMultiplier)
				{
					if (g_iCCount[client] == 0)
					{
						g_iCCount[client]++;
						g_iMaxCount[client] = 1;

						Refusing(client, false);
					}
					else
					{
						Hosties3_PrintToChat(client, "%T", "NoMoreRefuse", client, g_sTag);
					}
				}
				else
				{
					for (int i = 1; i <= g_iMaxRefuse; i++)
					{
						if (iPoints >= (g_iMultiplier * i))
						{
							g_iMaxCount[client] = i;
						}
					}

					if (g_iCCount[client] < g_iMaxRefuse)
					{
						g_iCCount[client]++;

						Refusing(client, true);
					}
					else
					{
						Hosties3_PrintToChat(client, "%T", "NoMoreRefuse", client, g_sTag);
					}
				}
			}
			else
			{
				Hosties3_PrintToChat(client, "%T", "NotEnoughAlive", client, g_sTag);
			}
		}
		else
		{
			Hosties3_PrintToChat(client, "%T", "NotAlive", client, g_sTag);
		}
	}
	else
	{
		Hosties3_PrintToChat(client, "%T", "WrongTeam", client, g_sTag);
	}

	return Plugin_Handled;
}

Refusing(client, bool status)
{
	g_bRun[client] = true;

	if(!status)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Hosties3_PrintToChat(i, "%T", "SingleRefuse", i, g_sTag, client);
			}
		}
	}
	else
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Hosties3_PrintToChat(i, "%T", "MultiRefuse", i, g_sTag, client, g_iCCount[client], g_iMaxCount[client]);
			}
		}
	}

	SetColor(client);

	if (g_bRun[client])
	{
		SetBeam(client);
	}

	Call_StartForward(g_hOnClientRefuse);
	Call_PushCell(client);
	Call_PushCell(g_iCCount[client]);
	Call_PushCell(g_iMaxCount[client]);
	Call_Finish();
}

stock SetColor(client)
{
	// save old rgba
	if (g_hResetTimer[client] == null)
	{
		Hosties3_GetClientColors(client, g_iRed[client], g_iGreen[client], g_iBlue[client], g_iAlpha[client]);
	}

	if (g_iCCount[client] == 1)
	{
		SetEntityRenderColor(client, 0, 0, 255, 255);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);

	}
	else
	{
		SetEntityRenderColor(client, 0, (50 * g_iCCount[client]), 255, 255);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	}

	if (g_hResetTimer[client] != null)
	{
		CloseHandle(g_hResetTimer[client]);
		g_bRun[client] = false;
		g_hResetTimer[client] = null;

		Call_RefuseEnd(client);
	}

	g_hResetTimer[client] = CreateTimer(g_fReset, Timer_ResetColor, GetClientUserId(client));
}

public Action Timer_ResetColor(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);

	if (Hosties3_IsClientValid(client) && IsPlayerAlive(client))
	{
		SetEntityRenderColor(client, g_iRed[client], g_iGreen[client], g_iBlue[client], g_iAlpha[client]);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		g_bRun[client] = false;
		g_hResetTimer[client] = null;

		Call_RefuseEnd(client);
	}
	return Plugin_Stop;
}

stock Call_RefuseEnd(client)
{
	Call_StartForward(g_hOnClientRefuseEnd);
	Call_PushCell(client);
	Call_PushCell(g_iCCount[client]);
	Call_PushCell(g_iMaxCount[client]);
	Call_Finish();
}

stock SetBeam(client)
{
	float fVec[3];

	GetClientAbsOrigin(client, fVec);
	fVec[2] += (5 * g_iCCount[client]);

	new fColor[4];
	fColor[0] = 0;
	fColor[1] = 0;
	fColor[2] = 255;
	fColor[3] = 255;

	TE_SetupBeamRingPoint(fVec, 50.0, 51.0, g_iBeamSprite, g_iHaloSprite, 0, 15, 0.1, 10.0, 0.0, fColor, 100, 0);
	TE_SendToAll();

	RequestFrame(Request_Beam, GetClientUserId(client));
}

public Request_Beam(any userid)
{
	int client = GetClientOfUserId(userid);

	if (Hosties3_IsClientValid(client))
	{
		if (g_bRun[client])
		{
			SetBeam(client);
		}
	}
}

stock CheckTeam()
{
	int TCount;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (Hosties3_IsClientValid(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			TCount++;
		}
	}

	return TCount;
}
