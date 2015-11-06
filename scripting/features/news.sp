#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hosties3>

#define FEATURE_NAME "News"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

int g_iLogLevel;

char g_sTag[128];

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
	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
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
		CREATE TABLE IF NOT EXISTS `hosties3_news` ( \
			`id` int(10) NOT NULL AUTO_INCREMENT, \
			`date` int(10) NOT NULL, \
			`title` varchar(255) NOT NULL, \
			`message` text, \
			`author` varchar(128) NOT NULL, \
			PRIMARY KEY (`id`), \
			UNIQUE KEY (`id`) \
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
