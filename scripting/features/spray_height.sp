#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <hosties3>

#define FEATURE_NAME "Spray Height"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;

int g_iUnit;

int g_iLogLevel;

char g_sTag[32];

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

	// 0 - Unit
	// 1 - mm
	// 2 - cm
	g_iUnit = Hosties3_AddCvarInt(FEATURE_NAME, "Unit", 0);

	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Unit: %d", FEATURE_NAME, g_iUnit);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	AddTempEntHook("Player Decal", Hook_PlayerDecal);

	LoadTranslations("hosties3_sprayheight.phrases");
}

public Action:Hook_PlayerDecal(const String:szTempEntityName[], const arrClients[], iClientCount, Float:flDelay)
{
	int client = TE_ReadNum("m_nPlayer");

	if(Hosties3_IsClientValid(client))
	{
		float fSpray[3];
		float fUp[3];
		float fDown[3];
		TE_ReadVector("m_vecOrigin", fSpray);

		TR_TraceRayFilter(fSpray, Float:{90.0, 0.0, 0.0}, MASK_PLAYERSOLID, RayType_Infinite, TraceRayFilter, client);
		TR_GetEndPosition(fDown);

		TR_TraceRayFilter(fSpray, Float:{-90.0, 0.0, 0.0}, MASK_PLAYERSOLID, RayType_Infinite, TraceRayFilter, client);
		TR_GetEndPosition(fUp);

		if(GetVectorDistance(fSpray, fUp) > 0.0 && GetVectorDistance(fSpray, fDown) > 0.0)
		{
			if(GetVectorDistance(fSpray, fUp) < 32.0 || GetVectorDistance(fSpray, fDown) < 32.0)
			{
				Hosties3_LoopClients(i)
				{
					if(Hosties3_IsClientValid(i))
					{
						Hosties3_PrintToChat(i, "%T", "SprayTouched", i, g_sTag, client);
					}
				}
			}
			else
			{
				Hosties3_LoopClients(i)
				{
					if(Hosties3_IsClientValid(i))
					{
						if(g_iUnit == 0)
						{
							char sBuffer[8];
							Format(sBuffer, sizeof(sBuffer), "%T", "Unit_units", i);

							Hosties3_PrintToChat(i, "%T", "Sprayed", i, g_sTag, client, ((GetVectorDistance(fSpray, fDown) - 32.0)), sBuffer);
						}
						else if(g_iUnit == 1)
						{
							char sBuffer[8];
							Format(sBuffer, sizeof(sBuffer), "%T", "Unit_mm", i);

							Hosties3_PrintToChat(i, "%T", "Sprayed", i, g_sTag, client, ((GetVectorDistance(fSpray, fDown) - 32.0) * 1000), sBuffer);
						}
						else if(g_iUnit == 2)
						{
							char sBuffer[8];
							Format(sBuffer, sizeof(sBuffer), "%T", "Unit_cm", i);

							Hosties3_PrintToChat(i, "%T", "Sprayed", i, g_sTag, client, ((GetVectorDistance(fSpray, fDown) - 32.0) * 100), sBuffer);
						}
					}
				}
			}
		}
	}
}

public bool TraceRayFilter(int entity, int mask, any data)
{
	if(entity != 0)
	{
		return false;
	}
	return true;
}
