#if defined _hosties3_vip_included
  #endinput
#endif
#define _hosties3_vip_included

forward void Hosties3_OnClientGetVIPPoints(int client, int points);

native int Hosties3_GetVIPPoints(int client);

native bool Hosties3_AddVIPPoints(int client, int points);
native bool Hosties3_SetVIPPoints(int client, int points);
native bool Hosties3_DelVIPPoints(int client, int points);
native bool Hosties3_ResetVIPPoints(int client);

stock bool Hosties3_IsVIPLoaded()
{
	if (!LibraryExists("hosties3_vip"))
	{
		SetFailState("'VIP' Feature not found!");
		return false;
	}
	
	return true;
}

public SharedPlugin __pl_hosties3_vip = 
{
	name = "hosties3_vip",
	file = "hosties3_vip.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public void __pl_hosties3_vip_SetNTVOptional()
{
	MarkNativeAsOptional("Hosties3_GetVIPPoints");
	MarkNativeAsOptional("Hosties3_AddVIPPoints");
	MarkNativeAsOptional("Hosties3_SetVIPPoints");
	MarkNativeAsOptional("Hosties3_DelVIPPoints");
	MarkNativeAsOptional("Hosties3_ResetVIPPoints");
}
#endif
