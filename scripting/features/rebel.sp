#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

#include <multicolors>
#include <hosties3>
#include <hosties3_rebel>

#undef REQUIRE_PLUGIN
#tryinclude <hosties3_vip>

#define FEATURE_NAME "Rebel"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
bool g_bShowMessage;
bool g_bMessageOnDead;
int g_iLogLevel;
bool g_bSetColor;
bool g_bOnShot;
bool g_bOnHurt;
bool g_bOnDeath;
int g_iRebelColorRed;
int g_iRebelColorGreen;
int g_iRebelColorBlue;
int g_iDefaultColorRed;
int g_iDefaultColorGreen;
int g_iDefaultColorBlue;
int g_iPointsOnRebelKill;

bool g_bRebel[MAXPLAYERS + 1];

Handle g_hOnClientRebel;
Handle g_hOnRebelDeath;

char g_sTag[64];

int g_iSRCommands;
char g_sSRCommandsList[8][32];
char g_sSRCommands[128];

bool g_bVIP = false;

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
	CreateNative("HRebel.IsRebel.get", Rebel_HRebel_IsRebel_Get);
	CreateNative("HRebel.SetRebel", Rebel_HRebel_SetRebel);

	g_hOnClientRebel = CreateGlobalForward("Hosties3_OnClientRebel", ET_Ignore, Param_Cell, Param_Cell);
	g_hOnRebelDeath = CreateGlobalForward("Hosties3_OnRebelDeath", ET_Ignore, Param_Cell, Param_Cell);

	RegPluginLibrary("hosties3_rebel");

	return APLRes_Success;
}

public void OnPluginStart()
{
	Hosties3_CheckRequirements();
}

public void Hosties3_OnConfigsLoaded()
{
	if (!(g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true)))
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	if(LibraryExists("hosties3_vip"))
	{
		g_bVIP = true;
	}

	g_bSetColor = Hosties3_AddCvarBool(FEATURE_NAME, "Set Color", true);
	g_bShowMessage = Hosties3_AddCvarBool(FEATURE_NAME, "Show Message", true);
	g_bMessageOnDead = Hosties3_AddCvarBool(FEATURE_NAME, "Message On Dead", true);
	g_bOnShot = Hosties3_AddCvarBool(FEATURE_NAME, "Rebel On Shot", true);
	g_bOnHurt = Hosties3_AddCvarBool(FEATURE_NAME, "Rebel On Hurt", true);
	g_bOnDeath = Hosties3_AddCvarBool(FEATURE_NAME, "Rebel On Death", true);

	if(g_bVIP)
	{
		g_iPointsOnRebelKill = Hosties3_AddCvarInt(FEATURE_NAME, "Points On Rebel Kill", 1);
	}

	g_iRebelColorRed = Hosties3_AddCvarInt(FEATURE_NAME, "Rebel Color Red", 255);
	g_iRebelColorGreen = Hosties3_AddCvarInt(FEATURE_NAME, "Rebel Color Green", 0);
	g_iRebelColorBlue = Hosties3_AddCvarInt(FEATURE_NAME, "Rebel Color Blue", 0);
	g_iDefaultColorRed = Hosties3_AddCvarInt(FEATURE_NAME, "Default Color Red", 255);
	g_iDefaultColorGreen = Hosties3_AddCvarInt(FEATURE_NAME, "Default Color Green", 255);
	g_iDefaultColorBlue = Hosties3_AddCvarInt(FEATURE_NAME, "Default Color Blue", 255);
	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));
	Hosties3_AddCvarString(FEATURE_NAME, "Set Rebel Commands", "setrebel;setr", g_sSRCommands, sizeof(g_sSRCommands));

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Set Color: %d", FEATURE_NAME, g_bSetColor);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] SetRebel Commands: %s", FEATURE_NAME, g_sSRCommands);

		if(g_bVIP)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Points On Rebel Kill: %s", FEATURE_NAME, g_iPointsOnRebelKill);
		}

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Show Message: %d", FEATURE_NAME, g_bShowMessage);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Message on Dead: %d", FEATURE_NAME, g_bMessageOnDead);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Rebel Color Red: %d", FEATURE_NAME, g_iRebelColorRed);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Rebel Color Green: %d", FEATURE_NAME, g_iRebelColorGreen);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Rebel Color Blue: %d", FEATURE_NAME, g_iRebelColorBlue);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Default Color Red: %d", FEATURE_NAME, g_iDefaultColorRed);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Default Color Green: %d", FEATURE_NAME, g_iDefaultColorGreen);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Default Color Blue: %d", FEATURE_NAME, g_iDefaultColorBlue);

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Rebel on Shot: %d", FEATURE_NAME, g_bOnShot);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Rebel on Hurt: %d", FEATURE_NAME, g_bOnHurt);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Rebel on Death: %d", FEATURE_NAME, g_bOnDeath);
	}

	g_iSRCommands = ExplodeString(g_sSRCommands, ";", g_sSRCommandsList, sizeof(g_sSRCommandsList), sizeof(g_sSRCommandsList[]));

	for(int i = 0; i < g_iSRCommands; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sSRCommandsList[i]);
		RegAdminCmd(sBuffer, Command_SetRebel, ADMFLAG_GENERIC);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sSRCommandsList[i], sBuffer);
	}

	LoadTranslations("hosties3_rebel.phrases");
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("bullet_impact", Event_BulletImpact);
	HookEvent("round_end", Event_RoundEnd);
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_vip"))
	{
		g_bVIP = true;
	}
}

public void Hosties3_OnPlayerSpawn(int client)
{
	HRebel player = new HRebel(client);
	
	if(player.IsRebel)
	{
		player.SetRebel(false, false);
	}
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Hosties3_LoopClients(i)
	{
		HPlayer player = new HPlayer(i);
		
		if(player.IsValid)
		{
			HRebel rebel = new HRebel(i);
			
			if(rebel.IsRebel)
				rebel.SetRebel(false, false);
		}
	}
}

public void Event_BulletImpact(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bOnShot)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		HPlayer player = new HPlayer(client);

		if (player.IsValid && GetClientTeam(client) == CS_TEAM_T)
		{
			HRebel rebel = new HRebel(client);
			
			if (!rebel.IsRebel)
			{
				if (g_iLogLevel <= 2)
				{
					Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] \"%L\" has shot and is now a rebel!", FEATURE_NAME, client);
				}

				rebel.SetRebel(true, true);
			}
		}
	}
}

public Action Command_SetRebel(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "sm_setrebel <#UserID|Name>");
		return Plugin_Handled;
	}

	char sArg[65];
	GetCmdArg(1, sArg, sizeof(sArg));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(sArg, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		HPlayer player = new HPlayer(target);

		if (!player.IsValid)
		{
			//Todo... add translations
			CReplyToCommand(client, "Invalid target (invalid #2)");
			return Plugin_Handled;
		}

		if(GetClientTeam(target) == CS_TEAM_T)
		{
			HRebel rebel = new HRebel(target);
			
			if (rebel.IsRebel)
				rebel.SetRebel(false, true);
			else
				rebel.SetRebel(true, true);
		}
	}

	return Plugin_Continue;
}

public Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bOnHurt)
	{
		int victim = GetClientOfUserId(event.GetInt("userid"));
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		
		HPlayer player_vic = new HPlayer(victim);
		HPlayer player_att = new HPlayer(attacker);
		
		if(player_vic.IsValid && player_att.IsValid)
		{
			if (victim != attacker)
			{
				if (GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT)
				{
					HRebel rebel = new HRebel(attacker);
					
					if (!rebel.IsRebel)
					{
						if (g_iLogLevel <= 2)
						{
							Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] \"%L\" has hurt a ct and is now a rebel!", FEATURE_NAME, attacker);
						}
	
						rebel.SetRebel(true, true);
					}
				}
			}
		}
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	HPlayer player_vic = new HPlayer(victim);
	HPlayer player_att = new HPlayer(attacker);
	HRebel rebel_vic = new HRebel(victim);
	HRebel rebel_att = new HRebel(attacker);
	
	if(player_vic.IsValid && player_att.IsValid)
	{
		if (g_bOnDeath)
		{
			if (victim != attacker)
			{
				if (GetClientTeam(attacker) == CS_TEAM_T && GetClientTeam(victim) == CS_TEAM_CT)
				{
					if (!rebel_att.IsRebel)
					{
						if (g_iLogLevel <= 2)
						{
							Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] \"%L\" has killed \"%L\" and is now a rebel!", FEATURE_NAME, attacker, victim);
						}
	
						rebel_att.SetRebel(true, true);
					}
				}
			}
		}
	
		if (rebel_vic.IsRebel)
		{
			rebel_vic.SetRebel(false, false);
	
			Call_StartForward(g_hOnRebelDeath);
			Call_PushCell(victim);
			Call_PushCell(attacker);
			Call_Finish();
	
			if(g_bVIP)
			{
				if (g_iPointsOnRebelKill > 0)
				{
					Hosties3_AddVIPPoints(attacker, g_iPointsOnRebelKill);
				}
			}
	
			if (g_bMessageOnDead)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i))
					{
						CPrintToChat(i, "%T", "RebelDead", i, g_sTag, victim);
					}
				}
			}
		}
	}
}

public int Rebel_HRebel_IsRebel_Get(Handle plugin, int numParams)
{
	HPlayer player = new HPlayer(GetNativeCell(1));

	if (Hosties3_IsClientValid(view_as<int>(player)))
	{
		return g_bRebel[view_as<int>(player)];
	}
	
	ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", view_as<int>(player));
	return false;
}

public int Rebel_HRebel_SetRebel(Handle plugin, int numParams)
{
	HPlayer client = new HPlayer(GetNativeCell(1));
	
	bool status = GetNativeCell(2);
	bool message = GetNativeCell(3);
	
	if (Hosties3_IsClientValid(view_as<int>(client)))
	{
		if (GetClientTeam(view_as<int>(client)) == CS_TEAM_T && IsPlayerAlive(view_as<int>(client)))
		{
			if(g_bRebel[view_as<int>(client)] != status)
			{
				SetClientRebel(view_as<int>(client), status, message);
			}
		}
	}
}

void SetClientRebel(int client, bool status, bool bMessage)
{
	if (!status)
	{
		g_bRebel[client] = false;

		if (g_bShowMessage && bMessage)
		{
			Hosties3_LoopClients(i)
			{
				if (Hosties3_IsClientValid(i))
				{
					CPrintToChat(i, "%T", "NoRebel", i, g_sTag, client);
				}
			}
		}

		if (g_bSetColor)
		{
			SetEntityRenderColor(client, g_iDefaultColorRed, g_iDefaultColorGreen, g_iDefaultColorBlue, 255);
		}

		if (g_iLogLevel <= 3)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, INFO, "[%s] \"%L\" is no longer a rebel!", FEATURE_NAME, client);
		}
	}
	else
	{
		g_bRebel[client] = true;

		if (g_bShowMessage && bMessage)
		{
			Hosties3_LoopClients(i)
			{
				if (Hosties3_IsClientValid(i))
				{
					CPrintToChat(i, "%T", FEATURE_NAME, i, g_sTag, client);
				}
			}
		}

		if (g_bSetColor)
		{
			SetEntityRenderColor(client, g_iRebelColorRed, g_iRebelColorGreen, g_iRebelColorBlue, 255);
		}

		if (g_iLogLevel <= 3)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, INFO, "[%s] \"%L\" is now a rebel!", FEATURE_NAME, client);
		}
	}

	Call_StartForward(g_hOnClientRebel);
	Call_PushCell(client);
	Call_PushCell(status);
	Call_Finish();
}
