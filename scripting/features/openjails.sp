#pragma semicolon 1

#include <sourcemod>
#include <smlib/entities>
#include <sdktools>
#include <hosties3>

#define FEATURE_NAME "Open Jails"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
bool g_bMessage;
bool g_bDebug;
bool g_bAdmin;
bool g_bCT;
bool g_bDeadCT;
int g_iLogLevel;

char g_sTag[128];

int g_iOpenJailsCom;
char g_sOpenJailsComList[8][32];
char g_sOpenJailsCom[128];

char g_sDoorList[64][32];
int g_iDoors;

Handle g_hDatabase;

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

	g_bMessage = Hosties3_AddCvarBool(FEATURE_NAME, "Show Message", true);
	g_bDebug = Hosties3_AddCvarBool(FEATURE_NAME, "Debug", true);
	g_bAdmin = Hosties3_AddCvarBool(FEATURE_NAME, "Admin", true);
	g_bCT = Hosties3_AddCvarBool(FEATURE_NAME, "CT", true);
	g_bDeadCT = Hosties3_AddCvarBool(FEATURE_NAME, "Dead CT", true);
	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_AddCvarString(FEATURE_NAME, "Commands", "openjail;openjails;oj;open", g_sOpenJailsCom, sizeof(g_sOpenJailsCom));
	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Message: %d", FEATURE_NAME, g_bMessage);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Debug: %d", FEATURE_NAME, g_bDebug);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Admin: %d", FEATURE_NAME, g_bAdmin);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CT: %d", FEATURE_NAME, g_bCT);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] DeadCT: %d", FEATURE_NAME, g_bDeadCT);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Commands: %s", FEATURE_NAME, g_sOpenJailsCom);
	}

	g_iOpenJailsCom = ExplodeString(g_sOpenJailsCom, ";", g_sOpenJailsComList, sizeof(g_sOpenJailsComList), sizeof(g_sOpenJailsComList[]));

	for(int i = 0; i < g_iOpenJailsCom; i++)
	{
		char sBuffer[32];
		Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sOpenJailsComList[i]);
		RegConsoleCmd(sBuffer, Command_OpenJails);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sOpenJailsComList[i], sBuffer);
	}

	LoadDoors();
	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
	LoadTranslations("hosties3_openjails.phrases");
}

public Hosties3_OnSQLConnected(Handle database)
{
	if (Hosties3_IsSQLValid(database))
	{
		g_hDatabase = CloneHandle(database);

		CheckTables();
	}
}

CheckTables()
{
	char sQuery[] = "\
		CREATE TABLE IF NOT EXISTS `hosties3_openjails` ( \
		  `map` varchar(128) NOT NULL, \
		  `doors` varchar(512) NOT NULL, \
		  PRIMARY KEY (`map`) \
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;";

	SQLQuery(sQuery);
}

SQLQuery(char[] sQuery)
{
	Handle hPack = CreateDataPack();
	WritePackString(hPack, sQuery);
	SQL_TQuery(g_hDatabase, SQL_Callback, sQuery, hPack);
}

public SQL_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (error[0])
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, ERROR, "Query failed: %s", error);
		return;
	}
}

public Action Command_OpenJails(client, args)
{
	if (g_bDebug)
	{
		if (Hosties3_IsClientValid(client))
		{
			int iTarget = GetClientAimTarget(client, false);

			if (IsValidEntity(iTarget))
			{
				if (g_iLogLevel <= 2)
				{
					char sName[32], sClass[32];
					Entity_GetName(iTarget, sName, sizeof(sName));
					Entity_GetClassName(iTarget, sClass, sizeof(sClass));
					PrintToChat(client, "[%s] ID: %d, Class: %s, Name: %s", FEATURE_NAME, iTarget, sClass, sName);
				}
			}
		}
	}

	if (g_iDoors == 0)
	{
		Hosties3_ReplyToCommand(client, "[%s] We don't know the what the cell door is for this map.", FEATURE_NAME);
		return Plugin_Handled;
	}

	int iMaxEntities = GetMaxEntities();
	for(int iEnt = MaxClients + 1; iEnt < iMaxEntities; iEnt++)
	{
		if (IsValidEntity(iEnt))
		{
			char sName[64];
			Entity_GetName(iEnt, sName, sizeof(sName));
			for(int i = 0; i < g_iDoors; i++)
			{
				if (StrEqual(sName, g_sDoorList[i]))
				{
					char sClass[32];
					Entity_GetClassName(iEnt, sClass, sizeof(sClass));

					if (StrEqual(sClass, "func_breakable"))
					{
						AcceptEntityInput(iEnt, "Break");
					}
					else
					{
						AcceptEntityInput(iEnt, "Open");
					}

					if (g_iLogLevel <= 2)
					{
						Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Door %d opened", FEATURE_NAME, iEnt);
					}
				}
			}
		}
	}
	EmitSoundToAll("ambient/misc/brass_bell_d.wav");

	if (g_bMessage)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				Hosties3_PrintToChat(i, "%T", "UseOpenJails", i, g_sTag, client);
			}
		}
	}

	if (g_iLogLevel <= 3)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, INFO, "[%s] %N used openjails", FEATURE_NAME, client);
	}
	return Plugin_Handled;
}

LoadDoors()
{
	char sQuery[512];
	char sMap[128];

	GetCurrentMap(sMap, sizeof(sMap));

	Format(sQuery, sizeof(sQuery), "SELECT `doors`, `map` FROM `hosties3_openjails` WHERE `map`='%s'", sMap);
	SQL_TQuery(g_hDatabase, SQL_LoadDoors, sQuery, _, DBPrio_Low);
}

public SQL_LoadDoors(Handle owner, Handle hndl, const char[] error, any userid)
{
	if (hndl == null)
	{
		SetFailState("(SQL_LoadDoors) Error: %s", error);
		return;
	}

	if(!SQL_FetchRow(hndl))
	{
		char sMap[128];
		GetCurrentMap(sMap, sizeof(sMap));

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, WARN, "[%s] No doors for %s found!", FEATURE_NAME, sMap);
		return;
	}

	char sDoors[512];
	char sMap[128];

	SQL_FetchString(hndl, 0, sDoors, sizeof(sDoors));
	SQL_FetchString(hndl, 1, sMap, sizeof(sMap));

	g_iDoors = ExplodeString(sDoors, ";", g_sDoorList, sizeof(g_sDoorList), sizeof(g_sDoorList[]));

	if (g_iDoors == 0)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Error with g_iDoors", FEATURE_NAME);
	}
	else
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Doors (%s): %s", FEATURE_NAME, sMap, sDoors);
	}
}
