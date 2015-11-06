void FullCacheReset()
{
	ResetCvarCache();
	ResetFlCache();
}

void ResetCvarCache()
{
	if (g_hCvarCache != null)
	{
		ClearArray(g_hCvarCache);
	}
	else
	{
		g_hCvarCache = CreateArray(sizeof(g_iCvarCacheTmp));
	}
}

void ResetFlCache()
{
	if (g_hFlCache != null)
	{
		ClearArray(g_hFlCache);
	}
	else
	{
		g_hFlCache = CreateArray(sizeof(g_iFlCacheTmp));
	}
}
