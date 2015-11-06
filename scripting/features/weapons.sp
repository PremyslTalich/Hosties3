#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>

#include <hosties3>

#define FEATURE_NAME "Weapons"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

bool g_bEnable;
bool g_bChatMessage;

int g_iLogLevel;

int g_iCTWeaponList;
char g_sCTWeapons[256];
char g_sCTWeaponsList[8][32];

int g_iTWeaponList;
char g_sTWeapons[256];
char g_sTWeaponsList[8][32];

char g_sTag[64];

Handle g_hAmmoList;

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

	g_bChatMessage = Hosties3_AddCvarBool(FEATURE_NAME, "Chat Message", true);
	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_AddCvarString(FEATURE_NAME, "CT", "ak47;deagle;knife", g_sCTWeapons, sizeof(g_sCTWeapons));
	Hosties3_AddCvarString(FEATURE_NAME, "T", "knife", g_sTWeapons, sizeof(g_sTWeapons));

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		if (StrEqual(g_sTWeapons, "", false))
		{
			Format(g_sTWeapons, sizeof(g_sTWeapons), "no weapons for ts");
		}

		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Chat Message: %d", FEATURE_NAME, g_bChatMessage);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] CT Weapons: %s", FEATURE_NAME, g_sCTWeapons);
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] T Weapons: %s", FEATURE_NAME, g_sTWeapons);
	}

	LoadTranslations("hosties3_weapons.phrases");
	
	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);

	g_hAmmoList = CreateTrie();

	SetTrieValue(g_hAmmoList, "weapon_ak47", 90);
	SetTrieValue(g_hAmmoList, "weapon_awp", 30);
	SetTrieValue(g_hAmmoList, "weapon_aug", 90);
	SetTrieValue(g_hAmmoList, "weapon_deagle", 35);
	SetTrieValue(g_hAmmoList, "weapon_elite", 120);
	SetTrieValue(g_hAmmoList, "weapon_famas", 90);
	SetTrieValue(g_hAmmoList, "weapon_fiveseven", 100);
	SetTrieValue(g_hAmmoList, "weapon_galil", 90);
	SetTrieValue(g_hAmmoList, "weapon_g3sg1", 90);
	SetTrieValue(g_hAmmoList, "weapon_glock", 120);
	SetTrieValue(g_hAmmoList, "weapon_m4a1", 90);
	SetTrieValue(g_hAmmoList, "weapon_m3", 32);
	SetTrieValue(g_hAmmoList, "weapon_mac10", 100);
	SetTrieValue(g_hAmmoList, "weapon_mp5navy", 120);
	SetTrieValue(g_hAmmoList, "weapon_m249", 200);
	SetTrieValue(g_hAmmoList, "weapon_p228", 52);
	SetTrieValue(g_hAmmoList, "weapon_p90", 100);
	SetTrieValue(g_hAmmoList, "weapon_scout", 90);
	SetTrieValue(g_hAmmoList, "weapon_sg552", 90);
	SetTrieValue(g_hAmmoList, "weapon_sg550", 90);
	SetTrieValue(g_hAmmoList, "weapon_tmp", 120);
	SetTrieValue(g_hAmmoList, "weapon_ump45", 100);
	SetTrieValue(g_hAmmoList, "weapon_usp", 100);
	SetTrieValue(g_hAmmoList, "weapon_xm1014",32);
	SetTrieValue(g_hAmmoList, "weapon_hkp2000", 52);
	SetTrieValue(g_hAmmoList, "weapon_p250", 52);
	SetTrieValue(g_hAmmoList, "weapon_tec9", 120);
	SetTrieValue(g_hAmmoList, "weapon_ssg08", 90);
	SetTrieValue(g_hAmmoList, "weapon_sg556", 90);
	SetTrieValue(g_hAmmoList, "weapon_sg553", 90);
	SetTrieValue(g_hAmmoList, "weapon_galilar", 90);
	SetTrieValue(g_hAmmoList, "weapon_scar20", 90);
	SetTrieValue(g_hAmmoList, "weapon_mp7", 120);
	SetTrieValue(g_hAmmoList, "weapon_nova", 32);
	SetTrieValue(g_hAmmoList, "weapon_mp9", 120);
	SetTrieValue(g_hAmmoList, "weapon_bizon", 120);
	SetTrieValue(g_hAmmoList, "weapon_sawedoff", 32);
	SetTrieValue(g_hAmmoList, "weapon_mag7", 32);
	SetTrieValue(g_hAmmoList, "weapon_negev", 200);
	SetTrieValue(g_hAmmoList, "weapon_m4a1_silencer", 40);
	SetTrieValue(g_hAmmoList, "weapon_usp_silencer", 24);
	SetTrieValue(g_hAmmoList, "weapon_cz75a", 12);
}

public Hosties3_OnPlayerSpawn(int client)
{
	Hosties3_StripClientAll(client, true);

	g_iCTWeaponList = ExplodeString(g_sCTWeapons, ";", g_sCTWeaponsList, sizeof(g_sCTWeaponsList), sizeof(g_sCTWeaponsList[]));
	g_iTWeaponList = ExplodeString(g_sTWeapons, ";", g_sTWeaponsList, sizeof(g_sTWeaponsList), sizeof(g_sTWeaponsList[]));

	int team = GetClientTeam(client);

	if (!IsFakeClient(client) && team == CS_TEAM_T)
	{
		for(int i = 0; i < g_iTWeaponList; i++)
		{
			char sBuffer[32];
			Format(sBuffer, sizeof(sBuffer), "weapon_%s", g_sTWeaponsList[i]);

			if (!StrEqual(sBuffer, "weapon_", false))
			{
				int iWeapon = GivePlayerItem(client, sBuffer);
				EquipPlayerWeapon(client, iWeapon);
				SetAmmo(client, iWeapon);

				if (g_bChatMessage)
				{
					Hosties3_PrintToChat(client, "%T", "GetWeapon", client, g_sTag, g_sTWeaponsList[i]);
				}

				if (g_iLogLevel <= 2)
				{
					Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Player: \"%L\" - Team: %d - Weapon: %s", FEATURE_NAME, client, team, g_sTWeaponsList[i]);
				}
			}
		}
	}

	if (!IsFakeClient(client) && team == CS_TEAM_CT)
	{
		for(int i = 0; i < g_iCTWeaponList; i++)
		{
			char sBuffer[32];
			Format(sBuffer, sizeof(sBuffer), "weapon_%s", g_sCTWeaponsList[i]);

			if (!StrEqual(sBuffer, "weapon_", false))
			{
				int iWeapon = GivePlayerItem(client, sBuffer);
				EquipPlayerWeapon(client, iWeapon);
				SetAmmo(client, iWeapon);

				if (g_bChatMessage)
				{
					Hosties3_PrintToChat(client, "%T", "GetWeapon", client, g_sTag, g_sCTWeaponsList[i]);
				}

				if (g_iLogLevel <= 2)
				{
					Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Player: \"%L\" - Team: %d - Weapon: %s", FEATURE_NAME, client, team, g_sCTWeaponsList[i]);
				}
			}
		}
	}
}

SetAmmo(client, weapon)
{
	int iOld, iNew;
	char sClass[64];

	iOld = Weapon_GetPrimaryClip(weapon);

	GetEntityClassname(weapon, sClass, sizeof(sClass));

	if (!GetTrieValue(g_hAmmoList, sClass, iNew))
	{
		iNew = iOld * 3;
	}

	Client_SetWeaponPlayerAmmoEx(client, weapon, iNew, -1);
}
