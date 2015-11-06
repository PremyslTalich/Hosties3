void ConnectToSQL()
{
	g_bStarted = true;

	if (!SQL_CheckConfig("hosties3"))
	{
		Hosties3_LogToFile(HOSTIES3_PATH, "sql", _, ERROR, "Database failure: Couldn't find Database entry \"hosties3\"");
		return;
	}
	SQL_TConnect(ConnectDatabase, "hosties3");
}

public void ConnectDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		if (error[0])
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, ERROR, "Connection to database has failed!: (ConnectDatabase) %s", error);
			return;
		}
	}

	g_hDatabase = CloneHandle(hndl);

	CreateTables();

	SQLQuery("SET NAMES \"UTF8\"");

	if (g_bSQLReady)
	{
		Call_StartForward(g_hOnSQLConnected);
		Call_PushCell(g_hDatabase);
		Call_Finish();
	}
}

void SQL_CheckPlayer(int client)
{
	char sSteamID64[128], sQuery[2048];
	GetClientAuthId(client, AuthId_SteamID64, sSteamID64, sizeof(sSteamID64));
	Format(sQuery, sizeof(sQuery), "SELECT id FROM hosties3_players WHERE id = '%s'", sSteamID64);
	SQL_TQuery(g_hDatabase, SQL_ClientConnect, sQuery, GetClientUserId(client));
}

public void SQL_ClientConnect(Handle owner, Handle hndl, const char[] error, any userid)
{
	if (hndl != null)
	{
		int client = GetClientOfUserId(userid);

		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			if (!SQL_FetchRow(hndl))
			{
				char sSteamID64[128], sQuery[2048], sName[MAX_NAME_LENGTH], sEName[MAX_NAME_LENGTH];

				GetClientAuthId(client, AuthId_SteamID64, sSteamID64, sizeof(sSteamID64));
				Format(g_sClientID[client], sizeof(g_sClientID[]), sSteamID64);

				GetClientName(client, sName, sizeof(sName));
				SQL_EscapeString(g_hDatabase, sName, sEName, sizeof(sEName));

				Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_players` (`id`, `name`, `firstconnect`, `lastconnect`) VALUES ('%s', '%s', UNIX_TIMESTAMP(), UNIX_TIMESTAMP())", sSteamID64, sEName);
				SQLQuery(sQuery);
			}
			else
			{
				char sQuery[2048], sName[MAX_NAME_LENGTH], sEName[MAX_NAME_LENGTH];

				SQL_FetchString(hndl, 0, g_sClientID[client], sizeof(g_sClientID[]));

				GetClientName(client, sName, sizeof(sName));
				SQL_EscapeString(g_hDatabase, sName, sEName, sizeof(sEName));

				Format(sQuery, sizeof(sQuery), "UPDATE `hosties3_players` SET `name`='%s', `lastconnect`=UNIX_TIMESTAMP() WHERE `id`='%s'", sEName, g_sClientID[client]);
				SQLQuery(sQuery);
			}

			SQL_GetAdminLevel(client);
		}
	}
	else
	{
		if (error[0])
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, ERROR, "Connection to database has failed!: (SQL_ClientConnect) %s", error);
			return;
		}
	}
}

void SQL_GetAdminLevel(int client)
{
	char sQuery[2048];
	Format(sQuery, sizeof(sQuery), "SELECT level FROM hosties3_admins WHERE id = '%s'", g_sClientID[client]);
	SQL_TQuery(g_hDatabase, SQL_AdminLevel, sQuery, GetClientUserId(client));
}

public void SQL_AdminLevel(Handle owner, Handle hndl, const char[] error, any userid)
{
	if (hndl != null)
	{
		int client = GetClientOfUserId(userid);

		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			if (SQL_FetchRow(hndl))
			{
				g_iAdmin[client] = SQL_FetchInt(hndl, 0);
			}

			g_bClientReady[client] = true;
			
			Call_StartForward(g_hOnClientReady);
			Call_PushCell(client);
			Call_Finish();
		}
	}
	else
	{
		if (error[0])
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, ERROR, "Connection to database has failed!: (SQL_AdminLevel) %s", error);
			return;
		}
	}
}

void UpdatePlayerName(int client)
{
	char sQuery[2048], sName[MAX_NAME_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	Format(sQuery, sizeof(sQuery), "UPDATE `hosties3_players` SET `name`='%s' WHERE `id`='%s'", sName, g_sClientID[client]);
	SQLQuery(sQuery);
}

void SQLQuery(char[] sQuery)
{
	Handle hPack = CreateDataPack();
	WritePackString(hPack, sQuery);
	SQL_TQuery(g_hDatabase, SQL_Callback, sQuery, hPack);
}

public void SQL_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (error[0])
	{
		Hosties3_LogToFile(HOSTIES3_PATH, "sql", _, ERROR, "Query failed: (SQL_Callback) %s", error);
		return;
	}
}

void CreateTables()
{
	char sQuery1[] = "\
		CREATE TABLE IF NOT EXISTS `hosties3_players` ( \
			`id` varchar(128) NOT NULL, \
			`name` varchar(65) NOT NULL, \
			`firstconnect` int(10) NOT NULL, \
			`lastconnect` int(10) NOT NULL, \
			PRIMARY KEY (`id`), \
			UNIQUE KEY (`id`) \
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;";
	SQLQuery(sQuery1);

	char sQuery2[] = "\
		CREATE TABLE IF NOT EXISTS `hosties3_settings` ( \
		 	`id` int(10) NOT NULL AUTO_INCREMENT, \
			`modul` varchar(100) NOT NULL, \
			`name` varchar(100) NOT NULL, \
			`value` varchar(100) NOT NULL, \
			`type` varchar(10) NOT NULL, \
			PRIMARY KEY (`id`), \
			UNIQUE KEY (`id`) \
		) ENGINE=InnoDB DEFAULT CHARSET=utf8;";
	SQLQuery(sQuery2);

	char sQuery3[] = "\
	CREATE TABLE IF NOT EXISTS `hosties3_admins` ( \
		`id` varchar(128) NOT NULL, \
		`level` int(10) NOT NULL, \
		PRIMARY KEY (`id`), \
		UNIQUE KEY (`id`) \
	) ENGINE=InnoDB DEFAULT CHARSET=utf8;";
	SQLQuery(sQuery3);

	ResetCvarCache();
	CacheSettings();
}

void CacheSettings()
{
	char sQuery[2048];
	Format(sQuery, sizeof(sQuery), "SELECT id, modul, name, value FROM hosties3_settings");
	SQL_TQuery(g_hDatabase, SQL_CacheSettings, sQuery);

	g_bSQLReady = true;
}

public void SQL_CacheSettings(Handle owner, Handle hndl, const char[] error, any userid)
{
	if (hndl != null)
	{
		while(SQL_FetchRow(hndl))
		{
			int iNewCache[CvarCache];

			iNewCache[fId] = SQL_FetchInt(hndl, 0);
			SQL_FetchString(hndl, 1, iNewCache[fFeature], HOSTIES3_MAX_FEATURE_NAME);
			SQL_FetchString(hndl, 2, iNewCache[fCvar], HOSTIES3_MAX_CVAR_NAME);
			SQL_FetchString(hndl, 3, iNewCache[fValue], HOSTIES3_MAX_CVAR_VALUE);

			Hosties3_LogToFile(HOSTIES3_PATH, "Cache", _, DEBUG, "[Cache] ID: %d - Feature: %s - Cvar: %s - Value: %s", iNewCache[fId], iNewCache[fFeature], iNewCache[fCvar], iNewCache[fValue]);

			PushArrayArray(g_hCvarCache, iNewCache[0]);
		}

		LoadConfig();
	}
}
