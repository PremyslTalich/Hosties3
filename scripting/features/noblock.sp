#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <hosties3>
#include <cstrike>

#define FEATURE_NAME "No Block"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

int g_iCollision = -1;

bool g_bEnable;

int g_bComMode;

bool g_bEnableWeapons;
bool g_bEnableGrenade;
bool g_bEnableHostage;

bool g_bEnableGlobal;
float g_fGlobalTime;

int g_iLogLevel;
int g_iSpawnMode;

float g_fTime;

int g_iCommands;

char g_sTag[64];
char g_sNoBlockComList[8][32];
char g_sNoBlockCom[128];

Handle g_hTimer[MAXPLAYERS + 1] = {null, ...};

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

	g_bEnableWeapons = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Weapons", true);
	g_bEnableGrenade = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Grenade", true);
	g_bEnableHostage = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Hostage", true);

	g_bEnableGlobal = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Global", true);
	g_fGlobalTime = Hosties3_AddCvarFloat(FEATURE_NAME, "Global Check Time", 3.0);

	g_bComMode = Hosties3_AddCvarInt(FEATURE_NAME, "Command Mode", 2);

	g_iSpawnMode = Hosties3_AddCvarInt(FEATURE_NAME, "No Block Mode", 0);

	g_fTime = Hosties3_AddCvarFloat(FEATURE_NAME, "Time No Block", 10.0);

	Hosties3_AddCvarString(FEATURE_NAME, "Commands", "b;block;ub;unblock;nb;noblock", g_sNoBlockCom, sizeof(g_sNoBlockCom));

	g_iLogLevel = Hosties3_GetLogLevel();
	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CommandMode: %d", FEATURE_NAME, g_bComMode);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] EnableWeapons: %d", FEATURE_NAME, g_bEnableWeapons);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] EnableGrenade: %d", FEATURE_NAME, g_bEnableGrenade);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] EnableHostage: %d", FEATURE_NAME, g_bEnableHostage);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] EnableGlobal: %d", FEATURE_NAME, g_bEnableGlobal);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Mode: %d", FEATURE_NAME, g_iSpawnMode);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] NoBlock Time: %.2f", FEATURE_NAME, g_fTime);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] NoBlock Commands: %s", FEATURE_NAME, g_sNoBlockCom);
	}

	g_iCommands = ExplodeString(g_sNoBlockCom, ";", g_sNoBlockComList, sizeof(g_sNoBlockComList), sizeof(g_sNoBlockComList[]));

	for(int i = 0; i < g_iCommands; i++)
	{
			char sBuffer[32];
			Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sNoBlockComList[i]);
			RegConsoleCmd(sBuffer, Command_Block);
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sNoBlockComList[i], sBuffer);
	}

	g_iCollision = FindSendPropOffs("CBaseEntity", "m_CollisionGroup");
	if (g_iCollision == -1)
	{
		SetFailState("Failed to get offset for CBaseEntity::m_CollisionGroup");
	}

	if (g_bEnableGlobal)
	{
		CreateTimer(g_fGlobalTime, Timer_CheckClients, _, TIMER_REPEAT);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
	LoadTranslations("common.phrases.txt");
	LoadTranslations("hosties3_noblock.phrases");
}

public Action Timer_CheckClients(Handle timer)
{
	Hosties3_LoopClients(client)
	{
		if(Hosties3_IsClientValid(client))
		{
			if (g_hTimer[client] == null && IsClientBlock(client))
			{
				SetBlock(client, false);
				RequestFrame(CheckClient, client);
			}
		}
	}
}

public Action Command_Block(int client, args)
{
	if (Hosties3_IsClientValid(client) && IsPlayerAlive(client))
	{
		if(g_bComMode == 2 && GetClientTeam(client) == CS_TEAM_CT)
		{
			ShowMenu(client);
		}
		else
		{
			Hosties3_PrintToChat(client, "%T", "WrongTeam", client);
			return;
		}
	}
}

public OnClientDisconnect(int client)
{
	if (g_hTimer[client] != null)
	{
		CloseHandle(g_hTimer[client]);
		g_hTimer[client] = null;
	}
}

public Hosties3_OnRoundStart()
{
	if (g_bEnableWeapons)
	{
		int iWeapons = -1;
		while((iWeapons = FindEntityByClassname(iWeapons, "weapon_*")) != -1)
		{
			if (GetEntPropEnt(iWeapons, Prop_Send, "m_hOwnerEntity") == -1)
			{
				SetBlock(iWeapons, false);
			}
		}
	}

	if(g_bEnableHostage)
	{
		for(new i = 1; i < GetMaxEntities(); i++)
		{
			if(IsValidEntity(i) || IsValidEdict(i))
			{
				char sClassname[128];
				GetEdictClassname(i, sClassname, sizeof(sClassname));
				if(StrEqual(sClassname, "hostage_entity", false))
				{
					SetBlock(i, false);
				}
			}
		}
	}
}

public Hosties3_OnPlayerSpawn(int client)
{
	if (Hosties3_IsClientValid(client))
	{
		RequestFrame(OnPlayerSpawn, client);
	}
}

public Action CS_OnCSWeaponDrop(int client, int weapon)
{
	if (g_bEnableWeapons)
	{
		SetBlock(weapon, false);
	}
}

public Hosties3_OnPlayerDeath(int victim, int attacker, int assister, const char[] weapon, bool headshot)
{
	if (g_hTimer[victim] != null)
	{
		CloseHandle(g_hTimer[victim]);
		g_hTimer[victim] = null;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (g_bEnableGrenade)
	{
		if (StrEqual("weapon_hegrenade", classname, false) ||
				StrEqual("weapon_flashbang", classname, false) ||
				StrEqual("weapon_smokegrenade", classname, false) ||
				StrEqual("weapon_incgrenade", classname, false) ||
				StrEqual("weapon_molotov", classname, false) ||
				StrEqual("weapon_decoy", classname, false))
		{
			SetBlock(entity, false);
		}
	}
}

CheckMenu(int client)
{
	if(Hosties3_IsClientValid(client))
	{
		if(g_bComMode == 2 && GetClientTeam(client) == CS_TEAM_CT)
		{
			ShowMenu(client);
		}
		else
		{
			Hosties3_PrintToChat(client, "%T", "WrongTeam", client);
			return;
		}
	}
}

ShowMenu(int client)
{
	char sTitle[128], sTime[128], sActivate[64], sDeactivate[64];

	Format(sTitle, sizeof(sTitle), "%T", "NoBlock Menu Title", client);
	Format(sActivate, sizeof(sActivate), "%T", "NoBlock Menu Activate", client);
	Format(sDeactivate, sizeof(sDeactivate), "%T", "NoBlock Menu Deactivate", client);
	Format(sTime, sizeof(sTime), "%T", "NoBlock Menu Time", client, g_fTime);

	Menu menu = CreateMenu(Menu_Block);
	menu.SetTitle(sTitle);

	if (g_hTimer[client] == null)
	{
		if (IsClientBlock(client))
		{
			menu.AddItem("", sActivate, ITEMDRAW_DISABLED);
			menu.AddItem("", sTime, ITEMDRAW_DISABLED);
			menu.AddItem("off", sDeactivate);
		}
		else
		{
			menu.AddItem("on", sActivate);
			menu.AddItem("time", sTime);
			menu.AddItem("", sDeactivate, ITEMDRAW_DISABLED);
		}
	}
	else
	{
		menu.AddItem("", "Es läuft bereits ein Timer", ITEMDRAW_DISABLED);
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public Menu_Block(Menu menu, MenuAction action, int client, int param)
{
	if (action == MenuAction_Select)
	{
		char sParam[256];
		menu.GetItem(param, sParam, sizeof(sParam));

		if (StrEqual(sParam, "on"))
		{
			SetBlock(client, false);
			Hosties3_PrintToChat(client, "%T", "NoBlock On", client);
			CheckMenu(client);
		}
		else if (StrEqual(sParam, "time"))
		{
			if (!IsClientStuck(client))
			{
				SetBlock(client, false);
				Hosties3_PrintToChat(client, "%T", "NoBlock On", client);
				g_hTimer[client] = CreateTimer(g_fTime, Timer_Block, client);
				CheckMenu(client);
			}
			else
			{
				RequestFrame(CheckClientTime, client);
			}
		}
		else if (StrEqual(sParam, "off"))
		{
			if (!IsClientStuck(client))
			{
				SetBlock(client, true);
				Hosties3_PrintToChat(client, "%T", "NoBlock Off", client);
				CheckMenu(client);
			}
			else
			{
				RequestFrame(CheckClient, client);
			}
		}
	}
}

public CheckClient(any client)
{
	if (Hosties3_IsClientValid(client) && IsPlayerAlive(client))
	{

		if (!IsClientStuck(client))
		{
			SetBlock(client, true);
			Hosties3_PrintToChat(client, "%T", "NoBlock Off", client);
			CheckMenu(client);
		}
		else
		{
			RequestFrame(CheckClient, client);
		}
	}
}

public CheckClientTime(any client)
{
	if (Hosties3_IsClientValid(client) && IsPlayerAlive(client))
	{
		if (!IsClientStuck(client))
		{
			SetBlock(client, false);
			Hosties3_PrintToChat(client, "%T", "NoBlock On", client);
			g_hTimer[client] = CreateTimer(g_fTime, Timer_Block, client);
			CheckMenu(client);
		}
		else
		{
			RequestFrame(CheckClientTime, client);
		}
	}
}

public OnPlayerSpawn(any client)
{
	if (g_iSpawnMode && !IsClientBlock(client))
	{
		SetBlock(client, false);
	}
}

public Action Timer_Block(Handle timer, any client)
{
	SetBlock(client, true);
	Hosties3_PrintToChat(client, "%T", "NoBlock Off", client);
	g_hTimer[client] = null;
	CheckMenu(client);
	return Plugin_Stop;
}

bool IsClientBlock(int client)
{
	if (GetEntData(client, g_iCollision, 4) == 5)
	{
		return false;
	}
	return true;
}

bool IsClientStuck(int client)
{
	float vOrigin[3];
	float vMins[3];
	float vMaxs[3];

	GetClientAbsOrigin(client, vOrigin);

	GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);

	TR_TraceHullFilter(vOrigin, vOrigin, vMins, vMaxs, MASK_ALL, FilterOnlyPlayers, client);

	return TR_DidHit();
}


public bool FilterOnlyPlayers(int client, contentsMask, any data)
{
	if (client != data && client > 0 && client <= MaxClients)
	{
    	return true;
	}
	return false;
}

SetBlock(int client, bool status)
{
	// 2 - NoBlock
	// 5 - Block
	if (status)
	{
		SetEntData(client, g_iCollision, 5, 4, true);
	}
	else
	{
		SetEntData(client, g_iCollision, 2, 4, true);
	}
}
