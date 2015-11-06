public int Admins_IsClientAdmin(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsSQLValid(g_hDatabase))
	{
		if (Hosties3_IsClientValid(client))
		{
			if (g_iAdmin[client] > 0)
			{
				return true;
			}
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Client is invalid!");
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
	}
	return false;
}

public int Admins_GetAdminLevel(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);

	if (Hosties3_IsSQLValid(g_hDatabase))
	{
		if (Hosties3_IsClientValid(client))
		{
			if (Hosties3_IsClientAdmin(client))
			{
				return g_iAdmin[client];
			}
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, "Client is invalid!");
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Error: Database handle is invalid!");
	}
	return false;
}