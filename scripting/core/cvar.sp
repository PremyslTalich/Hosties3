public int Cvar_AddCVarInt(Handle plugin, int numParams)
{
	char feature[64], sFeature[64];
	GetNativeString(1, feature, sizeof(feature));
	Hosties3_StringToLower(feature, sFeature, sizeof(sFeature));
	Hosties3_RemoveSpaces(sFeature, sFeature, sizeof(sFeature));

	char cvar[128], sCvar[128];
	GetNativeString(2, cvar, sizeof(cvar));
	Hosties3_StringToLower(cvar, sCvar, sizeof(sCvar));
	Hosties3_RemoveSpaces(sCvar, sCvar, sizeof(sCvar));

	int value = GetNativeCell(3);

	bool bFound = false;

	for (int i = 0; i < GetArraySize(g_hCvarCache); i++)
	{
		int iCache[CvarCache];
		GetArrayArray(g_hCvarCache, i, iCache[0]);

		if (StrEqual(iCache[fFeature], sFeature, false) && StrEqual(iCache[fCvar], sCvar, false))
		{
			bFound = true;
			return StringToInt(iCache[fValue]);
		}
	}

	if(!bFound)
	{
		if (Hosties3_IsSQLValid(g_hDatabase))
		{
			char sQuery[2048];
			Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_settings` (`modul`, `name`, `value`, `type`) VALUES ('%s', '%s', '%d', '%s')", sFeature, sCvar, value, "int");
			SQLQuery(sQuery);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
		}

		return value;
	}
	return false;
}

public int Cvar_AddCVarBool(Handle plugin, int numParams)
{
	char feature[64], sFeature[64];
	GetNativeString(1, feature, sizeof(feature));
	Hosties3_StringToLower(feature, sFeature, sizeof(sFeature));
	Hosties3_RemoveSpaces(sFeature, sFeature, sizeof(sFeature));

	char cvar[128], sCvar[128];
	GetNativeString(2, cvar, sizeof(cvar));
	Hosties3_StringToLower(cvar, sCvar, sizeof(sCvar));
	Hosties3_RemoveSpaces(sCvar, sCvar, sizeof(sCvar));

	bool value = GetNativeCell(3);

	bool bFound = false;

	for (int i = 0; i < GetArraySize(g_hCvarCache); i++)
	{
		int iCache[CvarCache];
		GetArrayArray(g_hCvarCache, i, iCache[0]);

		if (StrEqual(iCache[fFeature], sFeature, false) && StrEqual(iCache[fCvar], sCvar, false))
		{
			bFound = true;
			return view_as<bool>(StringToInt(iCache[fValue]));
		}
	}

	if(!bFound)
	{
		if (Hosties3_IsSQLValid(g_hDatabase))
		{
			char sQuery[2048];
			Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_settings` (`modul`, `name`, `value`, `type`) VALUES ('%s', '%s', '%d', '%s')", sFeature, sCvar, value, "bool");
			SQLQuery(sQuery);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
		}

		return value;
	}
	return false;
}

public int Cvar_AddCVarFloat(Handle plugin, int numParams)
{
	char feature[64], sFeature[64];
	GetNativeString(1, feature, sizeof(feature));
	Hosties3_StringToLower(feature, sFeature, sizeof(sFeature));
	Hosties3_RemoveSpaces(sFeature, sFeature, sizeof(sFeature));

	char cvar[128], sCvar[128];
	GetNativeString(2, cvar, sizeof(cvar));
	Hosties3_StringToLower(cvar, sCvar, sizeof(sCvar));
	Hosties3_RemoveSpaces(sCvar, sCvar, sizeof(sCvar));

	float value = float(GetNativeCell(3));

	bool bFound = false;

	for (int i = 0; i < GetArraySize(g_hCvarCache); i++)
	{
		int iCache[CvarCache];
		GetArrayArray(g_hCvarCache, i, iCache[0]);

		if (StrEqual(iCache[fFeature], sFeature, false) && StrEqual(iCache[fCvar], sCvar, false))
		{
			bFound = true;
			return view_as<float>(StringToFloat(iCache[fValue])); // TODO: tag mismatch
		}
	}

	if(!bFound)
	{
		if (Hosties3_IsSQLValid(g_hDatabase))
		{
			char sQuery[2048];
			Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_settings` (`modul`, `name`, `value`, `type`) VALUES ('%s', '%s', '%f', '%s')", sFeature, sCvar, value, "float");
			SQLQuery(sQuery);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
		}

		return view_as<float>(value); // TODO: tag mismatch
	}
	return false;
}

public int Cvar_AddCVarString(Handle plugin, int numParams)
{
	char feature[64], sFeature[64];
	GetNativeString(1, feature, sizeof(feature));
	Hosties3_StringToLower(feature, sFeature, sizeof(sFeature));
	Hosties3_RemoveSpaces(sFeature, sFeature, sizeof(sFeature));

	char cvar[128], sCvar[128];
	GetNativeString(2, cvar, sizeof(cvar));
	Hosties3_StringToLower(cvar, sCvar, sizeof(sCvar));
	Hosties3_RemoveSpaces(sCvar, sCvar, sizeof(sCvar));

	char value[256];
	GetNativeString(3, value, sizeof(value));

	bool bFound = false;

	for (int i = 0; i < GetArraySize(g_hCvarCache); i++)
	{
		int iCache[CvarCache];
		GetArrayArray(g_hCvarCache, i, iCache[0]);

		if (StrEqual(iCache[fFeature], sFeature, false) && StrEqual(iCache[fCvar], sCvar, false))
		{
			bFound = true;
			SetNativeString(4, iCache[fValue], GetNativeCell(5), false);
			return true;
		}
	}

	if(!bFound)
	{
		if (Hosties3_IsSQLValid(g_hDatabase))
		{
			char sQuery[2048];
			Format(sQuery, sizeof(sQuery), "INSERT INTO `hosties3_settings` (`modul`, `name`, `value`, `type`) VALUES ('%s', '%s', '%s', '%s')", sFeature, sCvar, value, "str");
			SQLQuery(sQuery);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
		}

		SetNativeString(4, value, GetNativeCell(5), false);
		return true;
	}
	SetNativeString(4, "", GetNativeCell(5), false);
	return false;
}
