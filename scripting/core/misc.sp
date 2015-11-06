public int Misc_LogFile(Handle plugin, int numParams)
{
	char sPath[PLATFORM_MAX_PATH + 1];
	char sPath2[PLATFORM_MAX_PATH + 1];
	char sLevelPath[PLATFORM_MAX_PATH + 1];
	char sFile[PLATFORM_MAX_PATH + 1];
	char sFile2[PLATFORM_MAX_PATH + 1];
	char sDate[PLATFORM_MAX_PATH + 1];
	char sBuffer[1024];

	GetNativeString(1, sPath, sizeof(sPath));
	GetNativeString(2, sFile, sizeof(sFile));
	GetNativeString(3, sDate, sizeof(sDate));

	LogLevel iLevel = GetNativeCell(4);

	if (StrEqual(sPath, "", false))
	{
		BuildPath(Path_SM, sPath2, sizeof(sPath2), "logs");
	}
	else
	{
		BuildPath(Path_SM, sPath2, sizeof(sPath2), "logs/%s", sPath);

		if (!DirExists(sPath2))
		{
			CreateDirectory(sPath2, 755);
		}
	}

	if (iLevel < TRACE || iLevel > ERROR)
	{
		Format(sLevelPath, sizeof(sLevelPath), "%s", sPath2);
	}
	else
	{
		Format(sLevelPath, sizeof(sLevelPath), "%s/%s", sPath2, g_sLogLevel[iLevel]);
	}


	if (!DirExists(sLevelPath))
	{
		CreateDirectory(sLevelPath, 755);
	}

	if (StrEqual(sDate, "", false))
	{
		Format(sFile2, sizeof(sFile2), "%s/%s.log", sLevelPath, sFile);
	}
	else
	{
		Format(sFile2, sizeof(sFile2), "%s/%s_%s.log", sLevelPath, sFile, sDate);
	}

	FormatNativeString(0, 5, 6, sizeof(sBuffer), _, sBuffer);

	LogToFileEx(sFile2, sBuffer);
}

public int Misc_GetLogLevel(Handle plugin, int numParams)
{
	return g_iLogLevel;
}

public int Misc_GetGame(Handle plugin, int numParams)
{
	return view_as<int>(g_iGame);
}

public int Misc_GetTag(Handle plugin, int numParams)
{
	SetNativeString(1, g_sTag, GetNativeCell(2), false);
}

public int Misc_GetCleanTag(Handle plugin, int numParams)
{
	SetNativeString(1, g_sCTag, GetNativeCell(2), false);
}

public int Misc_GetAutoUpdate(Handle plugin, int numParams)
{
	return g_bAutoUpdate;
}

public int Misc_CheckGame(Handle plugin, int numParams)
{
	if (Hosties3_GetServerGame() == Game_Unsupported)
	{
		SetFailState("Only Counter-Strike: Source and Global Offensive are supported!");
	}
}

public int Misc_IsSQLValid(Handle plugin, int numParams)
{
	Handle hDatabase = GetNativeCell(1);

	if (hDatabase != null)
	{
		return true;
	}
	return false;
}

public int Misc_StringToLower(Handle plugin, int numParams)
{
	char sBuffer[512];
	GetNativeString(1, sBuffer, sizeof(sBuffer));
	StringToLower(sBuffer, sBuffer, sizeof(sBuffer));
	SetNativeString(2, sBuffer, GetNativeCell(3), false);
}

stock void StringToLower(const char[] input, char[] output, int size)
{
	size--;

	int x = 0;
	while (input[x] != '\0' || x < size)
	{
		if (IsCharUpper(input[x]))
		{
			output[x] = CharToLower(input[x]);
		}
		else
		{
			output[x] = input[x];
		}

		x++;
	}
	output[x] = '\0';
}

public int Misc_RemoveSpaces(Handle plugin, int numParams)
{
	char sBuffer[512];
	GetNativeString(1, sBuffer, sizeof(sBuffer));
	ReplaceString(sBuffer, sizeof(sBuffer), " ", "", false);
	SetNativeString(2, sBuffer, GetNativeCell(3), false);
}

public int Misc_LoadTranslations(Handle plugin, int numParams)
{
	char sBuffer[512];
	char sName[512];
	char sFile[512];

	GetNativeString(1, sBuffer, sizeof(sBuffer));
	Hosties3_StringToLower(sBuffer, sName, sizeof(sName));
	Format(sFile, sizeof(sFile), "hosties3_%s.phrases", sName);

	LoadTranslations("common.phrases");
	LoadTranslations(sFile);
}

public int Misc_AddToFeatureList(Handle plugin, int numParams)
{
	char sName[HOSTIES3_MAX_FEATURE_NAME];
	char sCredits[HOSTIES3_MAX_CREDITS_LENGTH];
	char sDesc[HOSTIES3_MAX_DESC_LENGTH];

	GetNativeString(1, sName, sizeof(sName));
	GetNativeString(2, sCredits, sizeof(sCredits));
	FormatNativeString(0, 5, 6, sizeof(sDesc), _, sDesc);

	int iCache[FlCache];

	strcopy(iCache[flDescription], HOSTIES3_MAX_FEATURE_NAME, sDesc);
	strcopy(iCache[flCredits], HOSTIES3_MAX_CREDITS_LENGTH, sCredits);
	iCache[bVIP] = GetNativeCell(3);
	iCache[iPoints] = GetNativeCell(4);
	strcopy(iCache[flName], HOSTIES3_MAX_DESC_LENGTH, sName);
	

	Hosties3_LogToFile(HOSTIES3_PATH, "FeatureList", _, DEBUG, "[FeatureList] Feature: %s - Credits: %s - VIP: %d - Points: %d - Description: %s", iCache[flName], iCache[flCredits], iCache[bVIP], iCache[iPoints], iCache[flDescription]);

	PushArrayArray(g_hFlCache, iCache[0]);
}
