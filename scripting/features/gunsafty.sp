#pragma semicolon 1

#include <sourcemod>
#include <hosties3>

#define FEATURE_NAME "Gun Safty"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
bool g_bSlay;
bool g_bKick;
bool g_bBan;

int g_iLogLevel;

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

	g_bSlay = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Slay", true);
	g_bKick = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Kick", true);
	g_bBan = Hosties3_AddCvarBool(FEATURE_NAME, "Enable Ban", true);

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable Slay: %d", FEATURE_NAME, g_bSlay);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable Kick: %d", FEATURE_NAME, g_bKick);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable Ban: %d", FEATURE_NAME, g_bBan);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	AddCommandListener(Command_Check, "sm_slay");
	AddCommandListener(Command_Check, "sm_kick");
	AddCommandListener(Command_Check, "sm_ban");
}

public Action Command_Check(int client, const char[] command, int args)
{
	if (args < 1)
	{
		return Plugin_Continue;
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

		if (StrEqual(command, "sm_slay", false) && g_bSlay)
		{
			Hosties3_StripClientAll(target);
		}
		else if (StrEqual(command, "sm_kick", false) && g_bKick)
		{
			Hosties3_StripClientAll(target);
		}
		else if (StrEqual(command, "sm_ban", false) && g_bBan)
		{
			Hosties3_StripClientAll(target);
		}
	}

	return Plugin_Continue;
}
