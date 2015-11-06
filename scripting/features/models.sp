#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hosties3>

#define FEATURE_NAME "Models"
#define FEATURE_FILE FEATURE_NAME ... ".cfg"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME
#define PLUGIN_CONFIG HOSTIES3_CONFIG ... FEATURE_FILE

bool g_bEnable;
int g_iLogLevel;
int g_iCTCount;
int g_iTCount;

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

public OnMapStart()
{
	if (!FileExists(PLUGIN_CONFIG))
	{
		SetFailState("[Hosties3] '%s' not found!", PLUGIN_CONFIG);
		return;
	}
	
	Handle hConfig = CreateKeyValues("Hosties3");
	
	FileToKeyValues(hConfig, PLUGIN_CONFIG);
	if (KvJumpToKey(hConfig, FEATURE_NAME))
	{
		g_iCTCount = KvGetNum(hConfig, "CTModelCount", 1);
		g_iTCount = KvGetNum(hConfig, "TModelCount", 1);

		for(int i = 1; i <= g_iCTCount; i++)
		{
			char sName[64];
			char sBuffer[256];
			
			Format(sName, sizeof(sName), "CTModel%d", i);
			KvGetString(hConfig, sName, sBuffer, sizeof(sBuffer));
			
			if (DirExists(sBuffer))
			{
				new Handle:hModelDir = OpenDirectory(sBuffer);
				
				if (hModelDir != null)
				{
					decl String:sFileName[PLATFORM_MAX_PATH + 1];
					new FileType:ftType;
					
					while (ReadDirEntry(hModelDir, sFileName, sizeof(sFileName), ftType))
					{
						if (ftType == FileType_File)
						{
							Format(sFileName, sizeof(sFileName), "%s/%s", sBuffer, sFileName);
							
							if (StrContains(sFileName, ".mdl", false) != -1)
							{
								PrecacheModel(sFileName, true);
							}
							
							AddFileToDownloadsTable(sFileName);
							
							if (g_iLogLevel <= 2)
							{
								Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CT Model %s: %s", FEATURE_NAME, sName, sFileName);
							}
						}
					}
				}
				
				CloseHandle(hModelDir);
				
				ReplaceString(sBuffer, sizeof(sBuffer), "models/", "materials/models/");
				new Handle:hMaterialDir = OpenDirectory(sBuffer);
				if (hMaterialDir != null)
				{
					decl String:sFileName[PLATFORM_MAX_PATH + 1];
					new FileType:ftType;
					
					while (ReadDirEntry(hMaterialDir, sFileName, sizeof(sFileName), ftType))
					{
						if (ftType == FileType_File)
						{
							Format(sFileName, sizeof(sFileName), "%s/%s", sBuffer, sFileName);
							AddFileToDownloadsTable(sFileName);
							
							if (g_iLogLevel <= 2)
							{
								Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CT Model %s: %s", FEATURE_NAME, sName, sFileName);
							}
						}
					}
				}
				
				CloseHandle(hMaterialDir);
			}
		}
		
		for(int i = 1; i <= g_iTCount; i++)
		{
			char sName[64];
			char sBuffer[256];
			
			Format(sName, sizeof(sName), "TModel%d", i);
			KvGetString(hConfig, sName, sBuffer, sizeof(sBuffer));
			
			if (DirExists(sBuffer))
			{
				new Handle:hModelDir = OpenDirectory(sBuffer);
				
				if (hModelDir != null)
				{
					decl String:sFileName[PLATFORM_MAX_PATH + 1];
					new FileType:ftType;
					
					while (ReadDirEntry(hModelDir, sFileName, sizeof(sFileName), ftType))
					{
						if (ftType == FileType_File)
						{
							Format(sFileName, sizeof(sFileName), "%s/%s", sBuffer, sFileName);
							
							if (StrContains(sFileName, ".mdl", false) != -1)
							{
								PrecacheModel(sFileName, true);
							}
							
							AddFileToDownloadsTable(sFileName);
							
							if (g_iLogLevel <= 2)
							{
								Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] T Model %s: %s", FEATURE_NAME, sName, sFileName);
							}
						}
					}
				}
				
				CloseHandle(hModelDir);
				
				ReplaceString(sBuffer, sizeof(sBuffer), "models/", "materials/models/");
				new Handle:hMaterialDir = OpenDirectory(sBuffer);
				if (hMaterialDir != null)
				{
					decl String:sFileName[PLATFORM_MAX_PATH + 1];
					new FileType:ftType;
					
					while (ReadDirEntry(hMaterialDir, sFileName, sizeof(sFileName), ftType))
					{
						if (ftType == FileType_File)
						{
							Format(sFileName, sizeof(sFileName), "%s/%s", sBuffer, sFileName);
							AddFileToDownloadsTable(sFileName);
							
							if (g_iLogLevel <= 2)
							{
								Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] T Model %s: %s", FEATURE_NAME, sName, sFileName);
							}
						}
					}
				}
				
				CloseHandle(hMaterialDir);
			}
		}
	}
	else
	{
		SetFailState("Config for '%s' not found!", FEATURE_NAME);
		return;
	}
	CloseHandle(hConfig);
}

public Hosties3_OnConfigsLoaded()
{
	g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true);
	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
	}

	if (!g_bEnable)
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}
	
	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
}

public Hosties3_OnPlayerSpawn(int client)
{
	CreateTimer(1.0, Timer_SetModel, client);
}

public Action Timer_SetModel(Handle timer, any client)
{
	if (Hosties3_IsClientValid(client) && IsPlayerAlive(client))
	{
		SetModel(client);
	}
}

SetModel(client)
{
	Handle hConfig = CreateKeyValues("Hosties3");

	if (!FileExists(PLUGIN_CONFIG))
	{
		SetFailState("[Hosties3] '%s' not found!", PLUGIN_CONFIG);
		return;
	}

	FileToKeyValues(hConfig, PLUGIN_CONFIG);

	if (GetClientTeam(client) == CS_TEAM_CT)
	{
		char sName[64];
		char sBuffer[256];
		int model = GetRandomInt(1, g_iCTCount);
		
		Format(sName, sizeof(sName), "CTModel%d", model);
		if (KvJumpToKey(hConfig, FEATURE_NAME))
		{
			KvGetString(hConfig, sName, sBuffer, sizeof(sBuffer));
		}
		
		if (DirExists(sBuffer))
		{
			new Handle:hDir = OpenDirectory(sBuffer);
			
			if (hDir != null)
			{
				decl String:sFileName[PLATFORM_MAX_PATH + 1];
				new FileType:ftType;
				
				while (ReadDirEntry(hDir, sFileName, sizeof(sFileName), ftType))
				{
					if (ftType == FileType_File)
					{
						Format(sFileName, sizeof(sFileName), "%s/%s", sBuffer, sFileName);
						
						if (StrContains(sFileName, ".mdl", false) != -1)
						{
							if (g_iLogLevel <= 2)
							{
								Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Set Model of %N to %s", FEATURE_NAME, client, sFileName);
							}
							
							SetEntityModel(client, sFileName);
						}
					}
				}
			}
			
			CloseHandle(hDir);
		}
	}
	
	if (GetClientTeam(client) == CS_TEAM_T)
	{
		char sName[64];
		char sBuffer[256];
		int model = GetRandomInt(1, g_iTCount);
		
		Format(sName, sizeof(sName), "TModel%d", model);
		if (KvJumpToKey(hConfig, FEATURE_NAME))
		{
			KvGetString(hConfig, sName, sBuffer, sizeof(sBuffer));
		}
		
		if (DirExists(sBuffer))
		{
			new Handle:hDir = OpenDirectory(sBuffer);
			
			if (hDir != null)
			{
				decl String:sFileName[PLATFORM_MAX_PATH + 1];
				new FileType:ftType;
				
				while (ReadDirEntry(hDir, sFileName, sizeof(sFileName), ftType))
				{
					if (ftType == FileType_File)
					{
						Format(sFileName, sizeof(sFileName), "%s/%s", sBuffer, sFileName);
						
						if (StrContains(sFileName, ".mdl", false) != -1)
						{
							if (g_iLogLevel <= 2)
							{
								Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Set Model of %N to %s", FEATURE_NAME, client, sFileName);
							}
							
							SetEntityModel(client, sFileName);
						}
					}
				}
			}
			
			CloseHandle(hDir);
		}
	}
	
	CloseHandle(hConfig);
}
