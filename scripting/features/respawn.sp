#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <hosties3>

#define FEATURE_NAME "Respawn"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
int g_iMessageMode;
int g_iLogLevel;

char g_sTag[64];

int g_iRespawnCom;
char g_sRespawnComList[8][32];
char g_sRespawnCom[128];

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

	g_iMessageMode = Hosties3_AddCvarInt(FEATURE_NAME, "Message Mode", 1);
	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_AddCvarString(FEATURE_NAME, "Commands", "respawn;1up", g_sRespawnCom, sizeof(g_sRespawnCom));
	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Message Mode: %d", FEATURE_NAME, g_iMessageMode);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Commands: %s", FEATURE_NAME, g_sRespawnCom);
	}

	g_iRespawnCom = ExplodeString(g_sRespawnCom, ";", g_sRespawnComList, sizeof(g_sRespawnComList), sizeof(g_sRespawnComList[]));

	for(int i = 0; i < g_iRespawnCom; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sRespawnComList[i]);
		RegAdminCmd(sBuffer, Command_Respawn, ADMFLAG_GENERIC);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sRespawnComList[i], sBuffer);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	LoadTranslations("common.phrases");
	LoadTranslations("hosties3_respawn.phrases");
}

public Action Command_Respawn(int client, args)
{
	if (args != 1)
	{
		Hosties3_ReplyToCommand(client, "%T", "InvalidParameter", client, g_sTag);
		return Plugin_Handled;
	}

	char sArg[65];
	GetCmdArg(1, sArg, sizeof(sArg));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;

	if ((target_count = ProcessTargetString(sArg, client, target_list, MAXPLAYERS, COMMAND_FILTER_DEAD, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];

		if (!Hosties3_IsClientValid(target))
		{
			Hosties3_ReplyToCommand(client, "%T", "TargetInvalid", client, g_sTag);
			return Plugin_Handled;
		}

		if (GetClientTeam(target) != CS_TEAM_CT && GetClientTeam(target) != CS_TEAM_T)
		{
			Hosties3_ReplyToCommand(client, "TargetInvalidTeam", client, g_sTag);
			return Plugin_Handled;
		}

		CS_RespawnPlayer(target);
		Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, INFO, "\"%L\" was respawned by \"%L\"!", target, client);

		if (g_iMessageMode)
		{
			Hosties3_LoopClients(j)
			{
				if (Hosties3_IsClientValid(j))
				{
					Hosties3_PrintToChat(j, "%T", "PlayerRespawned", j, g_sTag, target, client);
				}
			}
		}
		else if (g_iMessageMode == 2)
		{
			Hosties3_LoopClients(j)
			{
				if (Hosties3_IsClientValid(j, _, _, true))
				{
					Hosties3_PrintToChat(j, "%T", "PlayerRespawned", j, g_sTag, target, client);
				}
			}
		}
	}
	return Plugin_Continue;
}
