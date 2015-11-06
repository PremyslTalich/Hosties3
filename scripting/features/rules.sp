#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hosties3>
#include <hosties3_rules>

#define FEATURE_NAME "Rules"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME
#define PLUGIN_CONFIG HOSTIES3_CONFIG ... "rules.cfg"
#define RULES_CONFIG HOSTIES3_CONFIG ..."rules/rules.cfg"
#define CTRULES_CONFIG HOSTIES3_CONFIG ..."rules/ctrules.cfg"

int g_iEnable;
int g_iMessageMode;
int g_iOnConnect;
int g_iCTEnable;
int g_iCTBlockMovement;
int g_iCTPunishment;
int g_iNoobFilter;
int g_iLogLevel;

int g_iSite[MAXPLAYERS + 1];

bool g_bAccepted[MAXPLAYERS + 1] = {false, ...};

Handle g_hOnClientCTRules;

char g_sTag[64];

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
	CreateNative("Hosties3_GetClientCTRules", Rules_GetClientCTRules);
	CreateNative("Hosties3_SetClientCTRules", Rules_SetClientCTRules);

	g_hOnClientCTRules = CreateGlobalForward("Hosties3_OnClientCTRules", ET_Ignore, Param_Cell, Param_Cell);

	RegPluginLibrary("hosties3_rules");

	return APLRes_Success;
}

public Hosties3_OnPluginPreLoaded()
{
	Hosties3_IsLoaded();
	Hosties3_CheckServerGame();
}

public Hosties3_OnConfigsLoaded()
{
	Handle hConfig = CreateKeyValues("Hosties3");

	if (!FileExists(PLUGIN_CONFIG))
	{
		SetFailState("[Hosties3] 'addons/sourcemod/configs/hosties3/rules.cfg' not found!");
		return;
	}

	FileToKeyValues(hConfig, PLUGIN_CONFIG);
	if (KvJumpToKey(hConfig, "Settings"))
	{
		g_iEnable = KvGetNum(hConfig, "Enable", 1);
		g_iMessageMode = KvGetNum(hConfig, "MessageMode", 1);
		g_iOnConnect = KvGetNum(hConfig, "OnConnect", 1);
		g_iCTEnable = KvGetNum(hConfig, "CTEnable", 1);
		g_iCTBlockMovement = KvGetNum(hConfig, "CTBlockMovement", 1);
		g_iCTPunishment = KvGetNum(hConfig, "CTPunishment", 1);
		g_iNoobFilter = KvGetNum(hConfig, "NoobFilter", 1);
		g_iLogLevel = Hosties3_GetLogLevel();
		Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));
	}
	else
	{
		SetFailState("Config for 'Rules' not found!");
		return;
	}

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "[Rules] Enable: %d", g_iEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "[Rules] Message Mode: %d", g_iMessageMode);
		Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "[Rules] OnConnect: %d", g_iOnConnect);
		Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "[Rules] CTEnable: %d", g_iCTEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "[Rules] CTBlockMovement: %d", g_iCTBlockMovement);
		Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "[Rules] CTPunishment: %d", g_iCTPunishment);
		Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "[Rules] NoobFilter: %d", g_iNoobFilter);
	}

	if (g_iEnable != 1)
	{
		SetFailState("'Rules' is deactivated!");
		return;
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
	LoadTranslations("hosties3_rules.phrases");

	// Todo... add to configs
	RegConsoleCmd("sm_rules", Command_Rules);
	RegConsoleCmd("sm_ctrules", Command_CTRules);

	CloseHandle(hConfig);
}

public Rules_GetClientCTRules(Handle plugin, numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsClientValid(client))
	{
		return g_bAccepted[client];
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}

	return false;
}

public Rules_SetClientCTRules(Handle plugin, numParams)
{
	int client = GetNativeCell(1);
	bool status = GetNativeCell(2);

	if (Hosties3_IsClientValid(client))
	{
		if (g_bAccepted[client] == status)
		{
			bool message = GetNativeCell(3);

			SetCTRules(client, status, message);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Current of new status of Client %i are same", client);
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client %i is invalid", client);
	}
}

public Hosties3_OnPlayerReady(int client)
{
	if (g_iOnConnect)
	{
		ShowRules(client, 0);
	}
}

public Hosties3_OnPlayerSpawn(int client)
{
	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		if (g_iOnConnect && g_iCTEnable && !Hosties3_GetClientCTRules(client))
		{
			ShowCTRules(client);
		}
	}
}

public Action:Command_Rules(client, args)
{
	if(Hosties3_IsClientValid(client))
	{
		ShowRules(client, 0);
	}
}

ShowRules(client, item)
{
	Menu menu = new Menu(Menu_Rules);

	char sTitle[64];
	Format(sTitle, sizeof(sTitle), "%T", "ServerRulesTitle", client);

	menu.SetTitle(sTitle);

	Handle hConfig = CreateKeyValues("Rules");

	if (!FileExists(RULES_CONFIG))
	{
		SetFailState("[Hosties3] 'addons/sourcemod/configs/hosties3/rules/rules.cfg' not found!");
		return;
	}

	FileToKeyValues(hConfig, RULES_CONFIG);

	if (!KvGotoFirstSubKey(hConfig))
	{
		SetFailState("Error!");
		return;
	}

	char hNumRules[64];
	char hTitleRules[256];

	do
	{
		KvGetSectionName(hConfig, hNumRules, sizeof(hNumRules));
		KvGetString(hConfig, "title", hTitleRules, sizeof(hTitleRules));
		menu.AddItem(hNumRules, hTitleRules);
	}
	while (KvGotoNextKey(hConfig));

	CloseHandle(hConfig);
	menu.ExitButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public Menu_Rules(Menu menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		Handle hConfig = CreateKeyValues("Rules");

		if (!FileExists(RULES_CONFIG))
		{
			SetFailState("[Hosties3] 'addons/sourcemod/configs/hosties3/rules/rules.cfg' not found!");
			return;
		}

		FileToKeyValues(hConfig, RULES_CONFIG);

		if (!KvGotoFirstSubKey(hConfig))
		{
			SetFailState("Error!");
			return;
		}

		char sBuffer[256];
		char sParam[256];
		menu.GetItem(param, sParam, sizeof(sParam));

		char sBack[64];
		Format(sBack, sizeof(sBack), "%T", "ServerRulesBack", client);

		do
		{
			KvGetSectionName(hConfig, sBuffer, sizeof(sBuffer));
			if (StrEqual(sBuffer, sParam))
			{
				char sTitle[256];
				char sRules[256];
				char sFile[256];

				KvGetString(hConfig, "title", sTitle, sizeof(sTitle));
				KvGetString(hConfig, "file", sFile, sizeof(sFile));

				g_iSite[client] = GetMenuSelectionPosition();

				Handle hPanel = CreatePanel();
				SetPanelTitle(hPanel, sTitle);
				DrawPanelText(hPanel, " ");

				if (!StrEqual(sFile, "", false))
				{
					char sPath[PLATFORM_MAX_PATH + 1];
					BuildPath(Path_SM, sPath, sizeof(sPath), "configs/hosties3/rules/%s", sFile);

					Handle hFile = OpenFile(sPath, "rt");

					if (!FileExists(sPath))
					{
						return;
					}

					while(!IsEndOfFile(hFile) && ReadFileLine(hFile, sRules, sizeof(sRules)))
					{
						DrawPanelText(hPanel, sRules);
					}
				}
				else
				{
					KvGetString(hConfig, "text", sRules, sizeof(sRules));
					DrawPanelText(hPanel, sRules);
				}
				DrawPanelText(hPanel, " ");
				DrawPanelItem(hPanel, sBack);
				// Todo... Add config (How long panel active)
				SendPanelToClient(hPanel, client, Panel_Rules, 15);
			}
		} while (KvGotoNextKey(hConfig));
		CloseHandle(hConfig);
	}
}

public Panel_Rules(Menu menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		if(Hosties3_IsClientValid(client))
		{
			ShowRules(client, g_iSite[client]);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Action:Command_CTRules(client, args)
{
	if(Hosties3_IsClientValid(client))
	{
		ShowCTRules(client);
	}
}

ShowCTRules(client)
{
	char sFile[256];
	char sRules[256];
	Handle hConfig = CreateKeyValues("CTRules");

	Menu menu = new Menu(Menu_CTRules);

	char sTitle[64], sAccept[64], sAcceptNot[64];
	Format(sTitle, sizeof(sTitle), "%T", "CTRulesTitle", client);
	Format(sAccept, sizeof(sAccept), "%T", "CTRulesAccept", client);
	Format(sAcceptNot, sizeof(sAcceptNot), "%T", "CTRulesAcceptNot", client);

	menu.SetTitle(sTitle);

	if (!FileExists(CTRULES_CONFIG))
	{
		SetFailState("[Hosties3] 'addons/sourcemod/configs/hosties3/rules/ctrules.cfg' not found!");
		return;
	}

	SetEntityMoveType(client, MOVETYPE_NONE);
	Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "\"%L\" can't now walk!", client);

	FileToKeyValues(hConfig, CTRULES_CONFIG);
	if (KvJumpToKey(hConfig, "Options"))
	{
		KvGetString(hConfig, "file", sFile, sizeof(sFile));

		if (!StrEqual(sFile, "", false))
		{
			char sPath[PLATFORM_MAX_PATH + 1];
			BuildPath(Path_SM, sPath, sizeof(sPath), "configs/hosties3/rules/%s", sFile);

			Handle hFile = OpenFile(sPath, "rt");

			if (!FileExists(sPath))
			{
				return;
			}

			while(!IsEndOfFile(hFile) && ReadFileLine(hFile, sRules, sizeof(sRules)))
			{
				menu.AddItem("", sRules, ITEMDRAW_DISABLED);
			}
		}
		else
		{
			KvGetString(hConfig, "text", sRules, sizeof(sRules));
			menu.AddItem("", sRules, ITEMDRAW_DISABLED);
		}

		if (StrEqual(sRules, "", false))
		{
			return;
		}
	}
	CloseHandle(hConfig);

	if (g_iNoobFilter)
	{
		menu.AddItem("no", sAcceptNot);
		menu.AddItem("yes", sAccept);
	}
	else
	{
		menu.AddItem("yes", sAccept);
		menu.AddItem("no", sAcceptNot);
	}

	menu.ExitButton = false;
	menu.Display(client, 30);
}

public Menu_CTRules(Menu menu, MenuAction:action, client, param)
{
	if (action == MenuAction_Select)
	{
		char sInfo[12];
		menu.GetItem(param, sInfo, sizeof(sInfo));
		if (StrEqual(sInfo, "yes", false))
		{
			SetCTRules(client, true, true);

			if (g_iCTBlockMovement)
			{
				SetEntityMoveType(client, MOVETYPE_WALK);
				Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "\"%L\" can walk again!", client);
			}
		}
		else
		{
			if (g_iCTPunishment > 0)
			{
				CTPunishment(client, g_iCTPunishment);
			}
		}
	}
	else if (action == MenuAction_End || action == MenuAction_Cancel)
	{
		if (g_iCTPunishment > 0)
		{
			CTPunishment(client, g_iCTPunishment);
		}
	}
}

SetCTRules(int client, bool status, bool message)
{
	g_bAccepted[client] = status;

	Call_StartForward(g_hOnClientCTRules);
	Call_PushCell(client);
	Call_PushCell(status);
	Call_Finish();

	if (message)
	{
		if (Hosties3_GetClientCTRules(client))
		{
			if (g_iMessageMode)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i))
					{
						Hosties3_PrintToChat(i, "%T", "CTRulesAccepted", i, g_sTag, client);
					}
				}
			}
			else if (g_iMessageMode == 2)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i, _, _, true))
					{
						Hosties3_PrintToChat(i, "%T", "CTRulesAccepted", i, g_sTag, client);
					}
				}
			}

			Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "\"%L\" has accept the rules!", client);
		}
		else if (!Hosties3_GetClientCTRules(client))
		{
			if (g_iMessageMode)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i))
					{
						Hosties3_PrintToChat(i, "%T", "CTRulesAcceptedNot", i, g_sTag, client);
					}
				}
			}
			else if (g_iMessageMode == 2)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i, _, _, true))
					{
						Hosties3_PrintToChat(i, "%T", "CTRulesAcceptedNot", i, g_sTag, client);
					}
				}
			}

			Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, DEBUG, "\"%L\" hasn't accepted the rules!", client);
		}
	}
}

CTPunishment(int client, int method)
{
	if (Hosties3_IsClientValid(client))
	{
		if (method == 1)
		{
			ChangeClientTeam(client, CS_TEAM_T);

			if (g_iMessageMode)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i))
					{
						Hosties3_PrintToChat(i, "%T", "PlayerMoved", i, g_sTag, client);
					}
				}
			}
			else if (g_iMessageMode == 2)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i, _, _, true))
					{
						Hosties3_PrintToChat(i, "%T", "PlayerMoved", i, g_sTag, client);
					}
				}
			}

			Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, INFO, "\"%L\" hasn't accepted the rules and was moved to t team!", client);
		}
		else if (method == 2)
		{
			ForcePlayerSuicide(client);

			if (g_iMessageMode)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i))
					{
						Hosties3_PrintToChat(i, "%T", "PlayerSlayed", i, g_sTag, client);
					}
				}
			}
			else if (g_iMessageMode == 2)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i, _, _, true))
					{
						Hosties3_PrintToChat(i, "%T", "PlayerSlayed", i, g_sTag, client);
					}
				}
			}

			Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, INFO, "\"%L\" hasn't accepted the rules and was slayed!", client);
		}
		else if (method == 3)
		{
			char sReason[256];
			Format(sReason, sizeof(sReason), "%T", "PlayerKickReason", client);

			KickClient(client, sReason);

			if (g_iMessageMode)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i))
					{
						Hosties3_PrintToChat(i, "%T", "PlayerKicked", i, g_sTag, client);
					}
				}
			}
			else if (g_iMessageMode == 2)
			{
				Hosties3_LoopClients(i)
				{
					if (Hosties3_IsClientValid(i, _, _, true))
					{
						Hosties3_PrintToChat(i, "%T", "PlayerKicked", i, g_sTag, client);
					}
				}
			}

			Hosties3_LogToFile(HOSTIES3_PATH, "rules", _, INFO, "\"%L\" hasn't accepted the rules and was kicked!", client);
		}
	}
}

public Action OnPlayerRunCmd(client, &buttons)
{
	if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
	{
		if (GetClientTeam(client) == CS_TEAM_CT && !g_bAccepted[client])
		{
			buttons &= ~IN_ATTACK;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}
