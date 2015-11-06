#if defined _hosties3_capitulate_included
  #endinput
#endif
#define _hosties3_capitulate_included

native void Hosties3_OnClientCapitulate(int client, int capitulate, int maxcapitulate);
native void Hosties3_OnClientCapitulateEnd(int client, int capitulate, int maxcapitulate);

native bool Hosties3_IsClientInCapitulating(int client);
native int Hosties3_GetClientCapitulate(int client);
native int Hosties3_GetClientMaxCapitulate(int client);
native int Hosties3_SetClientCapitulate(int client, int count);
native int Hosties3_SetClientMaxCapitulate(int client, int count);

stock Hosties3_IsCapitulateLoaded()
{
	if (!LibraryExists("hosties3_capitulate"))
	{
		SetFailState("'Capitulate'-Feature not found!");
	}
}

public SharedPlugin __pl_hosties3_capitulate =
{
	file = "capitulate.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public __pl_hosties3_capitulate_SetNTVOptional()
{
	MarkNativeAsOptiomal("Hosties3_GetClientCapitulate");
	MarkNativeAsOptiomal("Hosties3_GetClientMaxCapitulate");
	MarkNativeAsOptiomal("Hosties3_SetClientCapitulate");
	MarkNativeAsOptiomal("Hosties3_SetClientMaxCapitulate");
  MarkNativeAsOptiomal("Hosties3_IsClientInCapitulating");
}
#endif
