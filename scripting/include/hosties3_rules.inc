#if defined _hosties3_rules_included
  #endinput
#endif
#define _hosties3_rules_included

forward void Hosties3_OnClientCTRules(int client, bool status);
native bool Hosties3_GetClientCTRules(int client);
native void Hosties3_SetClientCTRules(int client, bool status, bool message);

stock Hosties3_IsRulesLoaded()
{
	if (!LibraryExists("hosties3_rules"))
	{
		SetFailState("'Rules'-Feature not found!");
	}
}

public SharedPlugin __pl_hosties3_rules = 
{
	file = "rules.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN

public __pl_hosties3_rules_SetNTVOptional()
{
	MarkNativeAsOptional("Hosties3_GetClientCTRules");
	MarkNativeAsOptional("Hosties3_SetClientCTRules");
}
#endif
