#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hosties3>

#define FEATURE_NAME "Overlays"
#define FEATURE_FILE FEATURE_NAME ... ".cfg"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME
#define PLUGIN_CONFIG HOSTIES3_CONFIG ... FEATURE_FILE

bool g_bEnable;
bool g_bEnableOnDied;
int g_iLogLevel;

int g_iCTRoundEndCount;
int g_iTRoundEndCount;
char g_sCTRoundEndOverlay[PLATFORM_MAX_PATH + 1];
char g_sTRoundEndOverlay[PLATFORM_MAX_PATH + 1];

int g_iCTPlayerDeathCount;
int g_iTPlayerDeathCount;
char g_sCTPlayerDeathOverlay[PLATFORM_MAX_PATH + 1];
char g_sTPlayerDeathOverlay[PLATFORM_MAX_PATH + 1];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = HOSTIES3_AUTHOR,
	version = HOSTIES3_VERSION,
	description = HOSTIES3_DESCRIPTION,
	url = "www.overcore.eu"
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
		g_iCTRoundEndCount = KvGetNum(hConfig, "CTCountRoundEnd", 2);
		g_iTRoundEndCount = KvGetNum(hConfig, "TCountRoundEnd", 2);

		if (g_iLogLevel <= 2)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] RoundEnd - CT Count - %d",FEATURE_NAME,  g_iCTRoundEndCount);
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] RoundEnd - T Count - %d", FEATURE_NAME, g_iTRoundEndCount);
		}

		for(int i = 1; i <= g_iCTRoundEndCount; i++)
		{
			KvGetString(hConfig, "CTBaseRoundEnd", g_sCTRoundEndOverlay, sizeof(g_sCTRoundEndOverlay));

			char sBuffer[PLATFORM_MAX_PATH + 1];
			Format(sBuffer, sizeof(sBuffer), "%s%d", g_sCTRoundEndOverlay, i);

			char sMaterial[PLATFORM_MAX_PATH + 1];
			Format(sMaterial, sizeof(sMaterial), "%s.vmt", sBuffer);

			char sTexture[PLATFORM_MAX_PATH + 1];
			Format(sTexture, sizeof(sTexture), "%s.vtf", sBuffer);

			PrecacheGeneric(sMaterial, true);
			PrecacheGeneric(sMaterial, true);
			AddFileToDownloadsTable(sTexture);
			AddFileToDownloadsTable(sTexture);

			if (g_iLogLevel <= 2)
			{
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] RoundEnd - CT Overlay - %d - %s", FEATURE_NAME, i, sBuffer);
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] RoundEnd - CT Overlay Material - %d - %s", FEATURE_NAME, i, sMaterial);
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] RoundEnd - CT Overlay Texture - %d - %s", FEATURE_NAME, i, sTexture);
			}
		}

		for(int i = 1; i <= g_iTRoundEndCount; i++)
		{
			KvGetString(hConfig, "TBaseRoundEnd", g_sTRoundEndOverlay, sizeof(g_sTRoundEndOverlay));

			char sBuffer[PLATFORM_MAX_PATH + 1];
			Format(sBuffer, sizeof(sBuffer), "%s%d", g_sTRoundEndOverlay, i);

			char sMaterial[PLATFORM_MAX_PATH + 1];
			Format(sMaterial, sizeof(sMaterial), "%s.vmt", sBuffer);

			char sTexture[PLATFORM_MAX_PATH + 1];
			Format(sTexture, sizeof(sTexture), "%s.vtf", sBuffer);

			PrecacheGeneric(sMaterial, true);
			PrecacheGeneric(sMaterial, true);
			AddFileToDownloadsTable(sTexture);
			AddFileToDownloadsTable(sTexture);

			if (g_iLogLevel <= 2)
			{
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] RoundEnd - T Overlay - %d - %s", FEATURE_NAME, i, sBuffer);
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] RoundEnd - T Overlay Material - %d - %s", FEATURE_NAME, i, sMaterial);
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] RoundEnd - T Overlay Texture - %d - %s", FEATURE_NAME, i, sTexture);
			}
		}
		KvGoBack(hConfig);
	}
	else
	{
		SetFailState("Config for '%s' not found!", FEATURE_NAME);
		return;
	}

	if (KvJumpToKey(hConfig, "Overlay On Died"))
	{
		g_iCTPlayerDeathCount = KvGetNum(hConfig, "CTCountPlayerDeath", 2);
		g_iTPlayerDeathCount = KvGetNum(hConfig, "TCountPlayerDeath", 2);

		if (g_iLogLevel <= 2)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PlayerDeath - CT Count - %d", FEATURE_NAME, g_iCTPlayerDeathCount);
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PlayerDeath - T Count - %d", FEATURE_NAME, g_iTPlayerDeathCount);
		}
		
		for(int i = 1; i <= g_iCTPlayerDeathCount; i++)
		{
			KvGetString(hConfig, "CTBasePlayerDeath", g_sCTPlayerDeathOverlay, sizeof(g_sCTPlayerDeathOverlay));

			char sBuffer[PLATFORM_MAX_PATH + 1];
			Format(sBuffer, sizeof(sBuffer), "%s%d", g_sCTPlayerDeathOverlay, i);

			char sMaterial[PLATFORM_MAX_PATH + 1];
			Format(sMaterial, sizeof(sMaterial), "%s.vmt", sBuffer);

			char sTexture[PLATFORM_MAX_PATH + 1];
			Format(sTexture, sizeof(sTexture), "%s.vtf", sBuffer);

			PrecacheGeneric(sMaterial, true);
			PrecacheGeneric(sMaterial, true);
			AddFileToDownloadsTable(sTexture);
			AddFileToDownloadsTable(sTexture);

			if (g_iLogLevel <= 2)
			{
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PlayerDeath - CT Overlay - %d - %s", FEATURE_NAME, i, sBuffer);
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PlayerDeath - CT Overlay Material - %d - %s", FEATURE_NAME, i, sMaterial);
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PlayerDeath - CT Overlay Texture - %d - %s", FEATURE_NAME, i, sTexture);
			}
		}

		for(int i = 1; i <= g_iTPlayerDeathCount; i++)
		{
			KvGetString(hConfig, "TBasePlayerDeath", g_sTPlayerDeathOverlay, sizeof(g_sTPlayerDeathOverlay));

			char sBuffer[PLATFORM_MAX_PATH + 1];
			Format(sBuffer, sizeof(sBuffer), "%s%d", g_sTPlayerDeathOverlay, i);

			char sMaterial[PLATFORM_MAX_PATH + 1];
			Format(sMaterial, sizeof(sMaterial), "%s.vmt", sBuffer);


			char sTexture[PLATFORM_MAX_PATH + 1];
			Format(sTexture, sizeof(sTexture), "%s.vtf", sBuffer);


			PrecacheGeneric(sMaterial, true);
			PrecacheGeneric(sMaterial, true);
			AddFileToDownloadsTable(sTexture);
			AddFileToDownloadsTable(sTexture);

			if (g_iLogLevel <= 2)
			{
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PlayerDeath - T Overlay - %d - %s", FEATURE_NAME, i, sBuffer);
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PlayerDeath - T Overlay Material - %d - %s", FEATURE_NAME, i, sMaterial);
				Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PlayerDeath - T Overlay Texture - %d - %s", FEATURE_NAME, i, sTexture);
			}
		}
	}
	else
	{
		SetFailState("Config for '%s' not found!", FEATURE_NAME);
		return;
	}

	if (!g_bEnable)
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	CloseHandle(hConfig);
}

public Hosties3_OnConfigsLoaded()
{
	g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "EnableRoundEnd", true);
	g_bEnableOnDied = Hosties3_AddCvarBool(FEATURE_NAME, "EnablePlayerDeath", true);
	
	g_iLogLevel = Hosties3_GetLogLevel();
	
	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] PlayerDeath - Enable - %d", FEATURE_NAME, g_bEnable);
	}

	if (!g_bEnable)
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}
	
	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
}

public Hosties3_OnPlayerDeath(int victim, int attacker)
{
	if (g_bEnableOnDied)
	{
		if (Hosties3_IsClientValid(victim && attacker))
		{
			if (GetClientTeam(victim) == CS_TEAM_CT && victim != attacker)
			{
				if (g_iCTPlayerDeathCount == 1)
				{
					char sBuffer[PLATFORM_MAX_PATH + 1];
					Format(sBuffer, sizeof(sBuffer), "%s1", g_sCTPlayerDeathOverlay);
					Hosties3_SendOverlayToAll(sBuffer);
				}
				else
				{
					int j = GetRandomInt(1, g_iCTPlayerDeathCount);
					char sBuffer[PLATFORM_MAX_PATH + 1];
					Format(sBuffer, sizeof(sBuffer), "%s%d", g_sCTPlayerDeathOverlay, j);
					Hosties3_SendOverlayToAll(sBuffer);
				}
				CreateTimer(5.0, Event_RemoveOverlayOnDied, victim);
			}
			else if (GetClientTeam(victim) == CS_TEAM_T && victim != attacker)
			{
				if (g_iTPlayerDeathCount == 1)
				{
					char sBuffer[PLATFORM_MAX_PATH + 1];
					Format(sBuffer, sizeof(sBuffer), "%s1", g_sTPlayerDeathOverlay);
					Hosties3_SendOverlayToAll(sBuffer);
				}
				else
				{
					int j = GetRandomInt(1, g_iTPlayerDeathCount);
					char sBuffer[PLATFORM_MAX_PATH + 1];
					Format(sBuffer, sizeof(sBuffer), "%s%d", g_sTPlayerDeathOverlay, j);
					Hosties3_SendOverlayToAll(sBuffer);
				}
				CreateTimer(5.0, Event_RemoveOverlayOnDied, victim);
			}
		}
	}
}

public Action Event_RemoveOverlayOnDied(Handle: timer, any: victim)
{
	if (g_bEnableOnDied)
	{
		if (Hosties3_IsClientValid(victim))
		{
			Hosties3_SendOverlayToClient(victim, "");
		}
	}
}

public Hosties3_OnRoundEnd(int winner)
{
	if (g_bEnable)
	{
		if (winner == CS_TEAM_CT)
		{
			if (g_iCTRoundEndCount == 1)
			{
				char sBuffer[PLATFORM_MAX_PATH + 1];
				Format(sBuffer, sizeof(sBuffer), "%s1", g_sCTRoundEndOverlay);
				Hosties3_SendOverlayToAll(sBuffer);
			}
			else
			{
				int j = GetRandomInt(1, g_iCTRoundEndCount);
				char sBuffer[PLATFORM_MAX_PATH + 1];
				Format(sBuffer, sizeof(sBuffer), "%s%d", g_sCTRoundEndOverlay, j);
				Hosties3_SendOverlayToAll(sBuffer);
			}
		}
		else if (winner == CS_TEAM_T)
		{
			if (g_iTRoundEndCount == 1)
			{
				char sBuffer[PLATFORM_MAX_PATH + 1];
				Format(sBuffer, sizeof(sBuffer), "%s1", g_sTRoundEndOverlay);
				Hosties3_SendOverlayToAll(sBuffer);
			}
			else
			{
				int j = GetRandomInt(1, g_iTRoundEndCount);
				char sBuffer[PLATFORM_MAX_PATH + 1];
				Format(sBuffer, sizeof(sBuffer), "%s%d", g_sTRoundEndOverlay, j);
				Hosties3_SendOverlayToAll(sBuffer);
			}
		}
	}
}

public Hosties3_OnRoundStart()
{
	if (g_bEnable || g_bEnableOnDied)
	{
		Hosties3_SendOverlayToAll("");
	}
}
