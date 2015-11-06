#pragma semicolon 1

#include <sourcemod>
#include <SteamWorks>
#include <hosties3>

#define FEATURE_NAME "Fixes"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

bool g_bOfflineBugFix;
bool g_bBlockFamilySharing;

bool g_bLadderFix;
bool g_cLadder[MAXPLAYERS + 1] = {false, ...};
float g_fLadder[MAXPLAYERS + 1] = {1.0, ...};

int g_iLogLevel;

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

	g_bLadderFix = Hosties3_AddCvarBool(FEATURE_NAME, "Ladder Fix", true);
	g_bOfflineBugFix = Hosties3_AddCvarBool(FEATURE_NAME, "Offline Bug Fix", true);
	g_bBlockFamilySharing = Hosties3_AddCvarBool(FEATURE_NAME, "Block Family Sharing", true);

	g_iLogLevel = Hosties3_GetLogLevel();

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Ladder Fix: %d", FEATURE_NAME, g_bLadderFix);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Offline Bug Fix: %d", FEATURE_NAME, g_bOfflineBugFix);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Block Family Sharing: %d", FEATURE_NAME, g_bBlockFamilySharing);
	}

	Hosties3_AddToFeatureList("Ladder  Fix", HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
	Hosties3_AddToFeatureList("Offline Bug Fix", HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
	Hosties3_AddToFeatureList("Block Family Sharing", HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
}

public SW_OnValidateClient(OwnerID, ClientID)
{
	if(g_bOfflineBugFix || g_bBlockFamilySharing)
	{
	    if(OwnerID && OwnerID != ClientID)
	    {
	        int j;
	        for(int i = 1; i <= MaxClients; i++)
	        {
	            if(IsClientConnected(i))
	            {
	                j = GetSteamAccountID(i);
	                if(j && j == ClientID)
	                {
	                    KickClient(i, "Family Sharing/Offline Abuser detected! Family Sharing/Offline Abuser aren't allowed on this this!");
	                    if (g_iLogLevel <= 3)
	                    {
	                    	Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, INFO, "Family Sharing/Offline Abuser detected! Name: %L OwnerID: %d ClientID: %d", i, OwnerID, ClientID);
	                    }
	                    break;
	                }
	            }
	        }
	    }
    }
}

public OnClientPutInServer(client)
{
	if(g_bOfflineBugFix || g_bBlockFamilySharing)
	{
		if(GetSteamAccountID(client) < 1)
	    {
	        KickClient(client, "Family Sharing/Offline Abuser detected! Family Sharing/Offline Abuser aren't allowed on this this!");
	        if (g_iLogLevel <= 3)
	        {
	        	Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, INFO, "Family Sharing/Offline Abuser detected! Name: %L", client);
	        }
	    }
	}
}

public Action OnPlayerRunCmd(client, &buttons, &impulse, float vel[3], float angles[3], &weapon)
{
	if(!IsFakeClient(client))
	{
		if (g_bLadderFix)
		{
			if (GetEntityMoveType(client) == MOVETYPE_LADDER)
			{
				g_cLadder[client] = true;
			}
			else
			{
				if (g_cLadder[client])
				{
					SetEntityGravity(client, g_fLadder[client]);
					g_cLadder[client] = false;
				}
				else
				{
					g_fLadder[client] = GetEntityGravity(client);
				}
			}
		}
	}
}
