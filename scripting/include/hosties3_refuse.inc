#if defined _hosties3_refuse_included
  #endinput
#endif
#define _hosties3_refuse_included

native void Hosties3_OnClientRefuse(int client, int refuse, int maxrefuse);
native void Hosties3_OnClientRefuseEnd(int client, int refuse, int maxrefuse);

native bool Hosties3_IsClientInRefusing(int client);
native int Hosties3_GetClientRefuse(int client);
native int Hosties3_GetClientMaxRefuse(int client);
native int Hosties3_SetClientRefuse(int client, int count);
native int Hosties3_SetClientMaxRefuse(int client, int count);

stock Hosties3_IsRefuseLoaded()
{
	if (!LibraryExists("hosties3_refuse"))
	{
		SetFailState("'Refuse'-Feature not found!");
	}
}

public SharedPlugin __pl_hosties3_refuse =
{
	file = "refuse.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public __pl_hosties3_refuse_SetNTVOptional()
{
	MarkNativeAsOptiomal("Hosties3_GetClientRefuse");
	MarkNativeAsOptiomal("Hosties3_GetClientMaxRefuse");
	MarkNativeAsOptiomal("Hosties3_SetClientRefuse");
	MarkNativeAsOptiomal("Hosties3_SetClientMaxRefuse");
  MarkNativeAsOptiomal("Hosties3_IsClientInRefusing");
}
#endif
