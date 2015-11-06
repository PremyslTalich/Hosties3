#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hosties3>

#undef REQUIRE_PLUGIN
#tryinclude <hosties3_rebel>

#define FEATURE_NAME "Check Players"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
int g_iLogLevel;

char g_sTag[64];

bool g_bRebel;

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

	if(LibraryExists("hosties3_rebel"))
	{
		g_bRebel = true;
	}

	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	LoadTranslations("hosties3_checkplayers.phrases");

	AddCommandListener(Event_BlockKillCommand, "kill");

	// Todo... Add to configs
	RegConsoleCmd("sm_kill", Event_KillCommand);

	if(g_bRebel)
	{
		RegConsoleCmd("sm_rebels", Command_Rebels);
	}
}

public OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_rebel"))
	{
		g_bRebel = true;
	}
}

public Action Command_Rebels(client, args)
{
	char sTitle[64], sNoRebels[64], sClose[64];
	int iCount = 0;

	Format(sTitle, sizeof(sTitle), "%T", "RebelsTitle", client);
	Format(sNoRebels, sizeof(sNoRebels), "%T", "NoRebels", client);
	Format(sClose, sizeof(sClose), "%T", "Close", client);

	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, sTitle);
	DrawPanelText(panel, " ");
	Hosties3_LoopClients(i)
	{
		if (Hosties3_IsClientValid(i) && GetClientTeam(i) == CS_TEAM_T && Hosties3_IsClientRebel(i))
		{
			char sBuffer[64];
			Format(sBuffer, sizeof(sBuffer), "%N (#%d)", i, i);
			DrawPanelText(panel, sBuffer);
			iCount++;
		}
	}

	if (iCount == 0)
	{
		DrawPanelText(panel, sNoRebels);
	}
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, sClose);
	SendPanelToClient(panel, client, PanelHandler, 30);
	CloseHandle(panel);
}

public PanelHandler(Handle menu, MenuAction action, client, param2)
{

}

public Action Event_KillCommand(int client, args)
{
	ForcePlayerSuicide(client);

	Hosties3_LoopClients(i)
	{
		if (Hosties3_IsClientValid(i))
		{
			Hosties3_PrintToChat(i, "%T", "Suicide", i, g_sTag, client);
		}
	}
}

public Action Event_BlockKillCommand(int client, const char[] command, args)
{
	return Plugin_Handled;
}
