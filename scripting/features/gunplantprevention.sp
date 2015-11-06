#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <smlib>
#include <hosties3>

#define FEATURE_NAME "Gun Plant Prevention"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME

enum GunplantPrevention:
{
	DISABLED = 0,
	ENABLED_FULL,
	ENABLED_ALLOWEMPTY,
};

enum GunplantPunishment:
{
	DEATH = 0,
	REMOVEWEAPON,
	DEATH_REMOVEWEAPON,
};

int g_iEnable;
int g_iLogLevel;
int g_iPunishment;

float g_fGunplantPreventionTime;

char g_sTag[64];

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

	g_iEnable = Hosties3_AddCvarInt(FEATURE_NAME, "Enable", 1);
	
	if (g_iEnable < 1 || g_iEnable > 2)
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	g_iPunishment = Hosties3_AddCvarInt(FEATURE_NAME, "Punishment", 1);
	g_fGunplantPreventionTime = Hosties3_AddCvarFloat(FEATURE_NAME, "Prevention Time", 1.337);
	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_iEnable);
	}

	Hosties3_AddToFeatureList(FEATURE_NAME, HOSTIES3_AUTHOR, false, 0, HOSTIES3_DESCRIPTION);
}

public Action CS_OnCSWeaponDrop(int client, int iWeapon)
{
	//TODO: make sure it doesn't trigger during the player's last request
	if (g_iEnable && Hosties3_IsClientValid(client, true) && GetClientTeam(client) == CS_TEAM_CT)
	{
		if (GunplantPrevention:g_iEnable == ENABLED_ALLOWEMPTY)
		{
			int iPrimaryAmmo;
			char sWeaponName[32];
			GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));
			Client_GetWeaponPlayerAmmo(client, sWeaponName, iPrimaryAmmo);
			int iSecondaryAmmo = Weapon_GetPrimaryClip(iWeapon);

			if (iPrimaryAmmo == 0 && iSecondaryAmmo == 0)
			{
				return Plugin_Continue;
			}
		}

		Handle hData = CreateDataPack();
		WritePackCell(hData, client);
		WritePackCell(hData, iWeapon);

		CreateTimer(g_fGunplantPreventionTime, Timer_GunPlantPrevention, hData, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action Timer_GunPlantPrevention(Handle hTimer, Handle hData)
{
	ResetPack(hData);
	int iOriginalOwner = ReadPackCell(hData);
	int iWeapon = ReadPackCell(hData);

	if (!IsValidEdict(iWeapon) || !Hosties3_IsClientValid(iOriginalOwner, true))
	{
		return Plugin_Stop;
	}

	char sWeaponName[32];
	GetEntityClassname(iWeapon, sWeaponName, sizeof(sWeaponName));

	if (!strncmp(sWeaponName, "weapon_", 7))
	{
		return Plugin_Stop;
	}

	int iNewOwner = GetEntPropEnt(iWeapon, Prop_Data, "m_hOwnerEntity");
	if (iNewOwner == -1)
	{
		return Plugin_Stop;
	}

	if (Hosties3_IsClientValid(iNewOwner, true) && GetClientTeam(iNewOwner) != GetClientTeam(iOriginalOwner))
	{
		switch(g_iPunishment)
		{
			case DEATH:
			{
				ForcePlayerSuicide(iOriginalOwner);
			}
			case REMOVEWEAPON:
			{
				if (Client_GetActiveWeapon(iNewOwner) == iWeapon)
				{
					FakeClientCommand(iNewOwner, "use weapon_knife");
				}
				AcceptEntityInput(iWeapon, "kill");
			}
			case DEATH_REMOVEWEAPON:
			{
				if (Client_GetActiveWeapon(iNewOwner) == iWeapon)
				{
					FakeClientCommand(iNewOwner, "use weapon_knife");
				}
				AcceptEntityInput(iWeapon, "kill");
				ForcePlayerSuicide(iOriginalOwner);
			}
		}

		if (g_iLogLevel <= 2)
		{
			Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[Gunplant Prevention] \"%L\" tried to gunplant \"%L\"!", iOriginalOwner, iNewOwner);
		}
	}

	return Plugin_Stop;
}
