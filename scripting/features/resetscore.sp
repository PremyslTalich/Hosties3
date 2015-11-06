#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <hosties3>
#include <hosties3_vip>

#define FEATURE_NAME "Reset Score"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

int g_iNeedPoints;

int g_iLogLevel;

char g_sTag[64];

int g_iResetScoreCom;
char g_sResetScoreComList[8][32];
char g_sResetScoreCom[128];

bool g_bVIPLoaded;

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

  if(LibraryExists("hosties3_vip"))
  {
    g_bVIPLoaded = true;
  }

  if(g_bVIPLoaded)
  {
    g_iNeedPoints = Hosties3_AddCvarInt(FEATURE_NAME, "Need Points", 2000);
  }

  Hosties3_AddCvarString(FEATURE_NAME, "Commands", "rs;reset;resetscore", g_sResetScoreCom, sizeof(g_sResetScoreCom));

  g_iLogLevel = Hosties3_GetLogLevel();

  Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

  if (g_iLogLevel <= 2)
  {
    Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);

    if(g_bVIPLoaded)
    {
      Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Need Points: %d", FEATURE_NAME, g_iNeedPoints);
    }

    Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Commands: %s", FEATURE_NAME, g_sResetScoreCom);
  }

  Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, true, g_iNeedPoints, HOSTIES3_DESCRIPTION);

  g_iResetScoreCom = ExplodeString(g_sResetScoreCom, ";", g_sResetScoreComList, sizeof(g_sResetScoreComList), sizeof(g_sResetScoreComList[]));

  for(int i = 0; i < g_iResetScoreCom; i++)
  {
    char sBuffer[32];
    Format(sBuffer, sizeof(sBuffer), "sm_%s", g_sResetScoreComList[i]);
    RegConsoleCmd(sBuffer, Command_ResetScore);
    Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Register Command: %s Full: %s", FEATURE_NAME, g_sResetScoreComList[i], sBuffer);
  }

  LoadTranslations("hosties3_resetscore.phrases");
}

public OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "hosties3_vip"))
	{
		g_bVIPLoaded = true;
	}
}

public Action Command_ResetScore(int client, int args)
{
  if(g_bVIPLoaded && Hosties3_GetVIPPoints(client) < g_iNeedPoints)
  {
    return Plugin_Handled;
  }

  if(GetClientFrags(client) != 0)
  {
    SetClientFrags(client, 0);
  }

  if(GetClientDeaths(client) != 0)
  {
    SetClientDeaths(client, 0);
  }

  if(CS_GetMVPCount(client) != 0)
  {
    CS_SetMVPCount(client, 0);
  }

  if(GetEngineVersion() == Engine_CSGO)
  {
    if(CS_GetClientAssists(client) != 0)
    {
      CS_SetClientAssists(client, 0);
    }

    if(CS_GetClientContributionScore(client) != 0)
    {
      CS_SetClientContributionScore(client, 0);
    }
  }

  Hosties3_LoopClients(i)
  {
    if(Hosties3_IsClientValid(i))
    {
      Hosties3_PrintToChat(i, "%T", "ScoreReset", i, g_sTag, client);
    }
  }

  return Plugin_Continue;
}

SetClientFrags(int client, int points)
{
  SetEntProp(client, Prop_Data, "m_iFrags", points);
}
SetClientDeaths(int client, int points)
{
  SetEntProp(client, Prop_Data, "m_iDeaths", points);
}
