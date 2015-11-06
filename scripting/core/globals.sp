enum CvarCache
{
	fId,
	String:fFeature[HOSTIES3_MAX_FEATURE_NAME],
	String:fCvar[HOSTIES3_MAX_CVAR_NAME],
	String:fValue[HOSTIES3_MAX_CVAR_VALUE]
};

enum FlCache
{
	String:flName[HOSTIES3_MAX_FEATURE_NAME],
	String:flCredits[HOSTIES3_MAX_CREDITS_LENGTH],
	bool:bVIP,
	iPoints,
	String:flDescription[HOSTIES3_MAX_DESC_LENGTH]
};

char g_sLogLevel[6][32] =
{
	"default",
	"trace",
	"debug",
	"info",
	"warn",
	"error"
};

bool g_bEnable;
bool g_bAutoUpdate;
int g_iLogLevel;

Handle g_hCvarCache;
int g_iCvarCacheTmp[CvarCache];

Handle g_hFlCache;
int g_iFlCacheTmp[FlCache];

CurrentGame g_iGame;

bool g_bSQLReady = false;
bool g_bStarted = false;
bool g_bClientReady[MAXPLAYERS + 1] = {false,...};

int g_iAdmin[MAXPLAYERS + 1] = {0,...};

Handle g_hOnConfigsLoaded;
Handle g_hOnSQLConnected;
Handle g_hOnClientReady;
Handle g_hOnPlayerSpawn;
Handle g_hOnClientDisconnect;

Handle g_hDatabase;

char g_sTag[64];
char g_sCTag[64];
char g_sClientID[MAXPLAYERS + 1][128];

int g_iFlSite[MAXPLAYERS + 1];

int g_iFlCom;
char g_sFlComList[8][32];
char g_sFlCom[128];
