#if defined _hosties3_included
  #endinput
#endif
#define _hosties3_included

#define HOSTIES3_NAME "Hosties3 - "
#define HOSTIES3_AUTHOR "Bara"
#define HOSTIES3_VERSION "3.0.0-alpha"
#define HOSTIES3_DESCRIPTION "Rewrite of SM_Hosties v2"
#define HOSTIES3_URL "www.hosties.info"

#define HOSTIES3_CONFIG "addons/sourcemod/configs/hosties3/"
#define HOSTIES3_PATH "hosties3"

#define HOSTIES3_MAX_FEATURE_NAME 64
#define HOSTIES3_MAX_CVAR_NAME 128
#define HOSTIES3_MAX_CVAR_VALUE 256
#define HOSTIES3_MAX_DESC_LENGTH 256
#define HOSTIES3_MAX_CREDITS_LENGTH 256

#define Hosties3_LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)

enum LogLevel:
{
	DEFAULT,
	TRACE,
	DEBUG,
	INFO,
	WARN,
	ERROR
};

enum CurrentGame:
{
	Game_CSS = 1,
	Game_CSGO,
	Game_Unsupported
};

forward void Hosties3_OnConfigsLoaded();
forward void Hosties3_OnSQLConnected(Handle database);
forward void Hosties3_OnPlayerReady(int client);
forward void Hosties3_OnPlayerSpawn(int client);
forward void Hosties3_OnPlayerDisconnect(int client);

native void Hosties3_LogToFile(const char[] path = "", const char[] file = "file", const char[] date = "", LogLevel level = INFO, const char[] format, any ...);
native int Hosties3_GetLogLevel();
native CurrentGame Hosties3_GetServerGame();
native void Hosties3_GetColorTag(const char[] tag, int maxlength);
native void Hosties3_GetCleanTag(const char[] tag, int maxlength);
native bool Hosties3_GetAutoUpdate();
native bool Hosties3_CheckServerGame();
native bool Hosties3_IsSQLValid(Handle database);
native void Hosties3_LoadTranslations(char[] file);
native void Hosties3_AddToFeatureList(const char[] feature, const char[] credits, bool vip, int points, const char[] description, any ...);

native int Hosties3_AddCvarInt(const char[] feature, const char[] cvar, int value);
native bool Hosties3_AddCvarBool(const char[] feature, const char[] cvar, bool value);
native float Hosties3_AddCvarFloat(const char[] feature, const char[] cvar, float value);
native void Hosties3_AddCvarString(const char[] feature, const char[] cvar, const char[] value, const char[] tag, int maxlength);

native bool Hosties3_IsClientAdmin(int client);
native int Hosties3_GetAdminLevel(int client);
native void Hosties3_StringToLower(char[] input, const char[] string, int maxlength);
native void Hosties3_RemoveSpaces(char[] input, const char[] string, int maxlength);
native int Hosties3_StripClientAll(int client, bool ammo = false);
native bool Hosties3_StripClient(int client, const char[] weapon, bool ammo = false);
native bool Hosties3_IsClientValid(int client, bool alive = false, bool bots = false, bool admin = false);
native bool Hosties3_GetClientID(int client, const char[] tag, int maxlength);
native bool Hosties3_SendOverlayToClient(int client, const char[] overlay);
native bool Hosties3_SendOverlayToAll(const char[] overlay);
native int Hosties3_GetRandomClient(int team);
native int Hosties3_SwitchClient(int client, int team);
native void Hosties3_SteamIDToCommunityID(const char[] steamid, const char[] communityid, int maxlength);

stock void Hosties3_SafeCloseHandle(Handle & rHandle)
{
	if (rHandle != INVALID_HANDLE)
	{
		CloseHandle(rHandle);
		rHandle = INVALID_HANDLE;
	}
}

stock bool Hosties3_CheckRequirements()
{
	if (!LibraryExists("hosties3"))
	{
		SetFailState("'Hosties3' not found!");
		
	}
	else
	{
		if(Hosties3_GetServerGame() != Game_CSGO && Hosties3_GetServerGame() != Game_CSS)
		{
			SetFailState("False game! Only CS:S/CS:GO supported!");
		}
	}
}

const HPlayer INVALID_ENTITY = view_as<HPlayer>(INVALID_ENT_REFERENCE);

methodmap HPlayer __nullable__
{
	public HPlayer(int client)
	{
		if(!Hosties3_IsClientValid(client))
			return INVALID_ENTITY;
		
		return view_as<HPlayer>(client);
	}
	
	property bool IsValid 
	{
		public get()
		{
			return Hosties3_IsClientValid(view_as<int>(this));
		}
	}
	
	property int ClientID
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
}

public SharedPlugin __pl_hosties3 =
{
	name = "hosties3",
	file = "hosties3.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public __pl_hosties3_SetNTVOptional()
{
	MarkNativeAsOptional("Hosties3_CheckServerGame");
	MarkNativeAsOptional("Hosties3_GetAutoUpdate");
	MarkNativeAsOptional("Hosties3_AddCvarInt");
	MarkNativeAsOptional("Hosties3_AddCvarBool");
	MarkNativeAsOptional("Hosties3_AddCvarFloat");
	MarkNativeAsOptional("Hosties3_AddCvarString");
	MarkNativeAsOptional("Hosties3_IsClientAdmin");
	MarkNativeAsOptional("Hosties3_GetAdminLevel");
	MarkNativeAsOptional("Hosties3_GetServerGame");
	MarkNativeAsOptional("Hosties3_GetRandomClient");
	MarkNativeAsOptional("Hosties3_GetColorTag");
	MarkNativeAsOptional("Hosties3_GetCleanTag");
	MarkNativeAsOptional("Hosties3_IsClientValid");
	MarkNativeAsOptional("Hosties3_GetClientID");
	MarkNativeAsOptional("Hosties3_IsSQLValid");
	MarkNativeAsOptional("Hosties3_LogToFile");
	MarkNativeAsOptional("Hosties3_GetLogLevel");
	MarkNativeAsOptional("Hosties3_SendOverlayToAll");
	MarkNativeAsOptional("Hosties3_SendOverlayToClient");
	MarkNativeAsOptional("Hosties3_StripClientAll");
	MarkNativeAsOptional("Hosties3_StripClient");
	MarkNativeAsOptional("Hosties3_StringToLower");
	MarkNativeAsOptional("Hosties3_RemoveSpaces");
	MarkNativeAsOptional("Hosties3_SwitchClient");
	MarkNativeAsOptional("Hosties3_SteamIDToCommunityID");
	MarkNativeAsOptional("Hosties3_AddToFeatureList");
}
#endif
