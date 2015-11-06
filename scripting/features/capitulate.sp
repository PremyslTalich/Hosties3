#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <hosties3>
#include <hosties3_capitulate>

#undef REQUIRE_PLUGIN
#tryinclude <hosties3_vip>

#define FEATURE_NAME "Capitulate"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

#define BEAM_CSS "materials/sprites/laser.vmt"
#define HALO_CSS "materials/sprites/halo01.vmt"
#define BEAM_CSGO "materials/sprites/laserbeam.vmt"
#define HALO_CSGO "materials/sprites/glow01.vmt"

bool g_bEnable;
int g_iLogLevel;

int g_iMultiplier;
int g_iMaxCapitulate;
int g_iMinTs;

int g_iRed[MAXPLAYERS + 1] = {255, ...};
int g_iGreen[MAXPLAYERS + 1] = {255, ...};
int g_iBlue[MAXPLAYERS + 1] = {255, ...};
int g_iAlpha[MAXPLAYERS + 1] = {255, ...};

float g_fReset;

int g_iCCount[MAXPLAYERS + 1] = {0, ...};
int g_iMaxCount[MAXPLAYERS + 1] = {1, ...};

int g_iBeamSprite;
int g_iHaloSprite;

int g_iCapitulateCom;
char g_sCapitulateComList[8][32];
char g_sCapitulateCom[128];

char g_sTag[128];

bool g_bVIPLoaded;

Handle g_hOnClientCapitulate;
Handle g_hOnClientCapitulateEnd;

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
	CreateNative("Hosties3_GetClientCapitulate", Capitulate_GetClientCapitulate);
	CreateNative("Hosties3_GetClientMaxCapitulate", Capitulate_GetClientMaxCapitulate);
	CreateNative("Hosties3_SetClientCapitulate", Capitulate_SetClientCapitulate);
	CreateNative("Hosties3_SetClientMaxCapitulate", Capitulate_SetClientMaxCapitulate);

	CreateNative("Hosties3_IsClientInCapitulating", Capitulate_IsClientInCapitulating);

	g_hOnClientCapitulate = CreateGlobalForward("Hosties3_OnClientCapitulate", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hOnClientCapitulateEnd = CreateGlobalForward("Hosties3_OnClientCapitulateEnd", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);

	RegPluginLibrary("hosties3_capitulate");

	return APLRes_Success;
}

public Action:OnWeaponCanUse(client, weapon)
{
	if(g_hResetTimer[client] != null)
	{
		Hosties3_PrintToChat(client, "%T", "NoWeaponsUse", client, g_sTag);
		return Plugin_Handled;
	}
	return Plugin_Continue;
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
	g_iMaxCapitulate = Hosties3_AddCvarInt(FEATURE_NAME, "Max Capitulate", 1);
	g_iMinTs = Hosties3_AddCvarInt(FEATURE_NAME, "Min Ts", 1);

	g_fReset = Hosties3_AddCvarFloat(FEATURE_NAME, "Reset Effect Time", 10.0);

	Hosties3_AddCvarString(FEATURE_NAME, "Commands", "e;capitulate;ergeben;c", g_sCapitulateCom, sizeof(g_sCapitulateCom));
	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, true, g_iMultiplier, HOSTIES3_DESCRIPTION);

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Multiplier: %d", FEATURE_NAME, g_iMultiplier);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] MaxCapitulate: %d", FEATURE_NAME, g_iMaxCapitulate);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] MinTs: %d", FEATURE_NAME, g_iMinTs);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Commands: %s", FEATURE_NAME, g_sCapitulateCom);
	}

	g_iCapitulateCom = ExplodeString(g_sCapitulateCom, ";", g_sCapitulateComList, sizeof(g_sCapitulateComList), sizeof(g_sCapitulateComList[]));

	for(int i = 0; i < g_iCapitulateCom; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sCapitulateComList[i]);
		RegConsoleCmd(sBuffer, Command_Capitulate);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sCapitulateComList[i], sBuffer);
	}

	LoadTranslations("hosties3_capitulate.phrases");
}

public OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_vip"))
	{
		g_bVIPLoaded = true;
	}
}

public Capitulate_GetClientCapitulate(Handle plugin, numParams)
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

public Capitulate_SetClientCapitulate(Handle plugin, numParams)
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

public Capitulate_GetClientMaxCapitulate(Handle plugin, numParams)
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

public Capitulate_SetClientMaxCapitulate(Handle plugin, numParams)
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

public Capitulate_IsClientInCapitulating(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		if(g_hResetTimer[client] == null)
		{
			return false;
		}
		else
		{
			return true;
		}
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

public Hosties3_OnPlayerReady(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Hosties3_OnPlayerDisconnect(int client)
{
	Reset(client);
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

	SetEntityRenderColor(client, g_iRed[client], g_iGreen[client], g_iBlue[client], g_iAlpha[client]);
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);

	g_hResetTimer[client] = null;
}

public Action Command_Capitulate(client, args)
{
	if (GetClientTeam(client) == CS_TEAM_T)
	{
		if (IsPlayerAlive(client))
		{
			if(g_hResetTimer[client] == null)
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

					if (g_iMaxCapitulate == 1 || iPoints < g_iMultiplier)
					{
						if (g_iCCount[client] == 0)
						{
							g_iCCount[client]++;
							g_iMaxCount[client] = 1;

							Capitulating(client, false);
						}
						else
						{
							Hosties3_PrintToChat(client, "%T", "NoMoreCapitulate", client, g_sTag);
						}
					}
					else
					{
						for (int i = 1; i <= g_iMaxCapitulate; i++)
						{
							if (iPoints >= (g_iMultiplier * i))
							{
								g_iMaxCount[client] = i;
							}
						}

						if (g_iCCount[client] < g_iMaxCapitulate)
						{
							g_iCCount[client]++;

							Capitulating(client, true);
						}
						else
						{
							Hosties3_PrintToChat(client, "%T", "NoMoreCapitulate", client, g_sTag);
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
				Hosties3_PrintToChat(client, "%T", "Already", client, g_sTag);
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

Capitulating(client, bool status)
{
	Hosties3_StripClientAll(client);

	if(!status)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Hosties3_PrintToChat(i, "%T", "SingleCapitulate", i, g_sTag, client);
			}
		}
	}
	else
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Hosties3_PrintToChat(i, "%T", "MultiCapitulate", i, g_sTag, client, g_iCCount[client], g_iMaxCount[client]);
			}
		}
	}

	SetColor(client);
	SetBeam(client);

	Call_StartForward(g_hOnClientCapitulate);
	Call_PushCell(client);
	Call_PushCell(g_iCCount[client]);
	Call_PushCell(g_iMaxCount[client]);
	Call_Finish();
}

stock SetColor(client)
{
	// save old rgba
	Hosties3_GetClientColors(client, g_iRed[client], g_iGreen[client], g_iBlue[client], g_iAlpha[client]);

	if (g_iCCount[client] == 1)
	{
		SetEntityRenderColor(client, 255, 204, 0, 255);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);

	}
	else
	{
		SetEntityRenderColor(client, 255, (50 * g_iCCount[client]), 0, 255);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
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
		g_hResetTimer[client] = null;

		Hosties3_PrintToChat(client, "%T", "WeaponsUseAgain", client, g_sTag);

		int iKnife = GivePlayerItem(client, "weapon_knife");
		EquipPlayerWeapon(client, iKnife);

		Call_CapitulateEnd(client);
	}
	return Plugin_Stop;
}

stock Call_CapitulateEnd(client)
{
	Call_StartForward(g_hOnClientCapitulateEnd);
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
	fColor[0] = 255;
	fColor[1] = 204;
	fColor[2] = 0;
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
		if (g_hResetTimer[client] != null)
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
