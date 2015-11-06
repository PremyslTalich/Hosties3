#pragma semicolon 1

#include <sourcemod>
#include <hosties3>

#undef REQUIRE_PLUGIN
#tryinclude <hosties3_vip>

#define FEATURE_NAME "All Chat"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

bool g_bAdmin;
bool g_bVIP;
int g_iVIPPoints;
bool g_bAll;

int g_iMode;
int g_iTeam;

int g_iLogLevel;

int g_iAuthor;
bool g_bIsChat;
char g_sType[64];
char g_sName[64];
char g_sText[512];
bool g_bIsTeammate;
bool g_bTarget[MAXPLAYERS + 1];

Handle g_hAlltalk;

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
	MarkNativeAsOptional("GetUserMessageType");
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

	g_iTeam = Hosties3_AddCvarInt(FEATURE_NAME, "Team Read", 0);
	g_iMode = Hosties3_AddCvarInt(FEATURE_NAME, "Relay Mode", 2);

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
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] TeamRead: %d", FEATURE_NAME, g_iTeam);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] RelayMode: %d", FEATURE_NAME, g_iMode);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
	UserMsg SayText2 = GetUserMessageId("SayText2");

	if (SayText2 == INVALID_MESSAGE_ID)
	{
		SetFailState("This game doesn't support SayText2!");
	}
	else
	{
		HookUserMessage(SayText2, Hook_UserMessage);

		HookEvent("player_say", Event_PlayerSay);

		AddCommandListener(Command_Say, "say");
		AddCommandListener(Command_Say, "say_team");

		g_hAlltalk = FindConVar("sv_alltalk");
	}
}

public OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_vip"))
	{
		g_bVIPLoaded = true;
	}
}

public Action Hook_UserMessage(UserMsg msg_id, Handle bf, const players[], int playersNum, bool reliable, bool init)
{
	if (GetUserMessageType() == UM_Protobuf)
	{
		g_iAuthor = PbReadInt(bf, "ent_idx");
		g_bIsChat = bool:PbReadBool(bf, "chat");
		PbReadString(bf, "msg_name", g_sName, sizeof(g_sName));
		PbReadString(bf, "params", g_sText, sizeof(g_sText), 0);
		PbReadString(bf, "params", g_sType, sizeof(g_sType), 1);
	}
	else
	{
		g_iAuthor = BfReadByte(bf);
		g_bIsChat = bool:BfReadByte(bf);
		BfReadString(bf, g_sType, sizeof(g_sType), false);
		BfReadString(bf, g_sName, sizeof(g_sName), false);
		BfReadString(bf, g_sText, sizeof(g_sText), false);
	}

	for (int i = 0; i < playersNum; i++)
	{
		g_bTarget[players[i]] = false;
	}
}

public Action Event_PlayerSay(Handle event, const char[] name, bool dontBroadcast)
{
	if (g_iMode < 1)
	{
		return;
	}

	if (g_iMode > 1 && g_hAlltalk != INVALID_HANDLE && !GetConVarBool(g_hAlltalk))
	{
		return;
	}

	if (GetClientOfUserId(GetEventInt(event, "userid")) != g_iAuthor)
	{
		return;
	}

	if (g_bIsTeammate && g_iTeam < 1)
	{
		return;
	}

	decl players[MaxClients];
	int playersNum = 0;

	if (g_bIsTeammate && g_iTeam == 1 && g_iAuthor > 0)
	{
		int team = GetClientTeam(g_iAuthor);

		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && g_bTarget[client] && GetClientTeam(client) == team)
			{
				players[playersNum++] = client;
			}

			g_bTarget[client] = false;
		}
	}
	else
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && g_bTarget[client])
			{
				players[playersNum++] = client;
			}

			g_bTarget[client] = false;
		}
	}

	if (playersNum == 0)
	{
		return;
	}

	Handle SayText2 = StartMessage("SayText2", players, playersNum, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);

	if(GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(SayText2, "ent_idx", g_iAuthor);
		PbSetBool(SayText2, "chat", g_bIsChat);
		PbSetString(SayText2, "msg_name", g_sName);
		PbAddString(SayText2, "params", g_sText);
		PbAddString(SayText2, "params", g_sType);
		PbAddString(SayText2, "params", "");
		PbAddString(SayText2, "params", "");
	}
	else
	{
		BfWriteByte(SayText2, g_iAuthor);
		BfWriteByte(SayText2, g_bIsChat);
		BfWriteString(SayText2, g_sType);
		BfWriteString(SayText2, g_sName);
		BfWriteString(SayText2, g_sText);
	}
	EndMessage();
}

public Action Command_Say(int client, const char[] command, int args)
{
		for (int target = 1; target <= MaxClients; target++)
		{
				g_bTarget[target] = true;
		}

		if (StrEqual(command, "say_team", false))
		{
				g_bIsTeammate = true;
		}
		else
		{
				g_bIsTeammate = false;
		}

		return Plugin_Continue;
}
