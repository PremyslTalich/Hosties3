void Native_AskPluginLoad2()
{
	MarkNativeAsOptional("GetUserMessageType");

	CreateNative("Hosties3_IsClientAdmin", Admins_IsClientAdmin);
	CreateNative("Hosties3_GetAdminLevel", Admins_GetAdminLevel);

	CreateNative("Hosties3_StripClientAll", Client_StripClientAll);
	CreateNative("Hosties3_StripClient", Client_StripClient);
	CreateNative("Hosties3_IsClientValid", Client_IsValidClient);
	CreateNative("Hosties3_GetClientID", Client_GetClientID);
	CreateNative("Hosties3_SendOverlayToClient", Client_SendOverlayToClient);
	CreateNative("Hosties3_SendOverlayToAll", Client_SendOverlayToAll);
	CreateNative("Hosties3_GetRandomClient", Client_GetRandomClient);
	CreateNative("Hosties3_SwitchClient", Client_SwitchClient);
	CreateNative("Hosties3_SteamIDToCommunityID", Client_SteamIDToCommunityID);

	CreateNative("Hosties3_AddCvarInt", Cvar_AddCVarInt);
	CreateNative("Hosties3_AddCvarBool", Cvar_AddCVarBool);
	CreateNative("Hosties3_AddCvarFloat", Cvar_AddCVarFloat);
	CreateNative("Hosties3_AddCvarString", Cvar_AddCVarString);

	CreateNative("Hosties3_LogToFile", Misc_LogFile);
	CreateNative("Hosties3_GetLogLevel", Misc_GetLogLevel);
	CreateNative("Hosties3_CheckServerGame", Misc_CheckGame);
	CreateNative("Hosties3_GetServerGame", Misc_GetGame);
	CreateNative("Hosties3_GetColorTag", Misc_GetTag);
	CreateNative("Hosties3_GetCleanTag", Misc_GetCleanTag);
	CreateNative("Hosties3_GetAutoUpdate", Misc_GetAutoUpdate);
	CreateNative("Hosties3_IsSQLValid", Misc_IsSQLValid);
	CreateNative("Hosties3_StringToLower", Misc_StringToLower);
	CreateNative("Hosties3_RemoveSpaces", Misc_RemoveSpaces);
	CreateNative("Hosties3_LoadTranslations", Misc_LoadTranslations);
	CreateNative("Hosties3_AddToFeatureList", Misc_AddToFeatureList);

	// Forwards
	g_hOnConfigsLoaded = CreateGlobalForward("Hosties3_OnConfigsLoaded", ET_Ignore);
	g_hOnSQLConnected = CreateGlobalForward("Hosties3_OnSQLConnected", ET_Ignore, Param_Cell);
	g_hOnClientDisconnect = CreateGlobalForward("Hosties3_OnPlayerDisconnect", ET_Ignore, Param_Cell);
	g_hOnClientReady = CreateGlobalForward("Hosties3_OnPlayerReady", ET_Ignore, Param_Cell);
	g_hOnPlayerSpawn = CreateGlobalForward("Hosties3_OnPlayerSpawn", ET_Ignore, Param_Cell);
}
