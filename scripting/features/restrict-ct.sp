#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <hosties3>
#include <hosties3_vip>

#define FEATURE_NAME "Restrict CT"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
int g_iLogLevel;
int g_iNeededPoints;
int g_iStartPlayers;
int g_iHowManyPlayers;

float g_fStartPluginTime;

bool g_bReady;

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

	g_iNeededPoints = Hosties3_AddCvarInt(FEATURE_NAME, "Points To Join CT", 50);
	g_iStartPlayers = Hosties3_AddCvarInt(FEATURE_NAME, "Start Players", 12);
	g_iHowManyPlayers = Hosties3_AddCvarInt(FEATURE_NAME, "How Many Players", 4);

	g_fStartPluginTime = Hosties3_AddCvarFloat(FEATURE_NAME, "Start Plugin Time", 20.0);

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PointsToJoinCT: %d", FEATURE_NAME, g_iNeededPoints);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] StartPlayers: %d", FEATURE_NAME, g_iStartPlayers);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] HowManyPlayers: %d", FEATURE_NAME, g_iHowManyPlayers);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] StartPluginTime: %.1f", FEATURE_NAME, g_fStartPluginTime);
	}

	AddCommandListener(Command_JoinTeam, "jointeam");

	if (g_fStartPluginTime > 0.0)
	{
		CreateTimer(g_fStartPluginTime, RestrictCT_StartPlugin);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
	LoadTranslations("hosties3_restrict-ct.phrases");
}

public Hosties3_OnPlayerSpawn(int client)
{
	if (!g_bReady)
	{
		return;
	}

	if (CheckPlayers())
	{
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			if (Hosties3_GetVIPPoints(client) < g_iNeededPoints)
			{
				Hosties3_PrintToChat(client, "%T", "NotEnoughPoints", client);
				Hosties3_SwitchClient(client, CS_TEAM_T);
				return;
			}
		}
	}
	return;
}

public Action Command_JoinTeam(int client, const char[] command, args)
{
	if (!g_bReady || !Hosties3_IsClientValid(client))
	{
		return Plugin_Continue;
	}

	char sTeam[3];
	GetCmdArg(1, sTeam, sizeof(sTeam));
	int iTeam = StringToInt(sTeam);

	if (CheckPlayers())
	{
		if (iTeam == CS_TEAM_CT)
		{
			if (Hosties3_GetVIPPoints(client) < g_iNeededPoints)
			{
				Hosties3_PrintToChat(client, "%T", "NotEnoughPoints", client);
				Hosties3_SwitchClient(client, CS_TEAM_T);
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

public Action RestrictCT_StartPlugin(Handle timer)
{
	g_bReady = true;
	CreateTimer(5.0, Timer_CheckClients, _, TIMER_REPEAT);
}

public Action Timer_CheckClients(Handle timer)
{
	Hosties3_LoopClients(client)
	{
		if (g_bReady && CheckPlayers() && Hosties3_IsClientValid(client))
		{
			if (GetClientTeam(client) == CS_TEAM_CT)
			{
				if (Hosties3_GetVIPPoints(client) < g_iNeededPoints)
				{
					Hosties3_PrintToChat(client, "%T", "NotEnoughPoints", client);
					Hosties3_SwitchClient(client, CS_TEAM_T);
					return Plugin_Stop;
				}
			}
		}
	}

	return Plugin_Continue;
}

CheckPlayers()
{
	if (!g_bReady)
	{
		return false;
	}

	int iPlayers;
	int iVIPPlayers;

	Hosties3_LoopClients(i)
	{
		if (Hosties3_IsClientValid(i))
		{
			iPlayers++;

			if(Hosties3_GetVIPPoints(i) >= g_iNeededPoints)
			{
				iVIPPlayers++;
			}
		}
	}

	if (iPlayers >= g_iStartPlayers && iVIPPlayers >= g_iHowManyPlayers)
	{
		return true;
	}
	return false;
}
