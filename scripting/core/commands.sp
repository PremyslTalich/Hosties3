public Action Command_Featurelist(int client, int args)
{
  if(Hosties3_IsClientValid(client))
  {
    Show_Featurelist(client, 1);
  }
}

void Show_Featurelist(int client, int item)
{
  Menu menu = new Menu(Menu_Featurelist);

  // TODO: Translations
  menu.SetTitle("Hosties3 - Feature List");

  for (int i = 0; i < GetArraySize(g_hFlCache); i++)
  {
    int iFlCache[FlCache];
    char sBuffer[12];

    GetArrayArray(g_hFlCache, i, iFlCache[0]);
    IntToString(i, sBuffer, sizeof(sBuffer));
    
    char sName[HOSTIES3_MAX_FEATURE_NAME];
    
    if(iFlCache[bVIP])
    {
    	Format(sName, sizeof(sName), "[VIP] %s", iFlCache[flName]);
    }
    else
    {
    	Format(sName, sizeof(sName), "%s", iFlCache[flName]);
    }

    menu.AddItem(sBuffer, sName);
  }

  menu.ExitButton = true;
  menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

public int Menu_Featurelist(Menu menu, MenuAction action, int client, int param)
{
  if (action == MenuAction_Select)
  {
    g_iFlSite[client] = GetMenuSelectionPosition();

    char sArrayId[12];
    menu.GetItem(param, sArrayId, sizeof(sArrayId));

    int iFlCache[FlCache];
    GetArrayArray(g_hFlCache, StringToInt(sArrayId), iFlCache[0]);

    char sTitle[256], sCredits[256], sDesc[256], sVIP[256], sPoints[256], sBack[256], sFlCredits[HOSTIES3_MAX_CREDITS_LENGTH], sFlDesc[HOSTIES3_MAX_DESC_LENGTH];
    Format(sTitle, sizeof(sTitle), "%T", "FlTitle", client, iFlCache[flName]);
    
    Format(sCredits, sizeof(sCredits), "%T", "FlCredits", client);
    strcopy(sFlCredits, sizeof(sFlCredits), iFlCache[flCredits]);
    
    Format(sDesc, sizeof(sDesc), "%T", "FlDesc", client);
    strcopy(sFlDesc, sizeof(sFlDesc), iFlCache[flDescription]);
    
    if(iFlCache[bVIP])
    {
	    Format(sVIP, sizeof(sVIP), "%T", "FlVIP", client);
	    Format(sPoints, sizeof(sPoints), "%T", "FlPoints", client, iFlCache[iPoints]);
	}
    
    Format(sBack, sizeof(sBack), "%T", "FlBack", client);

    Panel panel = CreatePanel();
    panel.SetTitle(sTitle);
    panel.DrawText(" ");
    panel.DrawText(sCredits);
    panel.DrawText(sFlCredits);
    panel.DrawText(" ");
    panel.DrawText(sDesc);
    panel.DrawText(sFlDesc);
    
    if(iFlCache[bVIP])
    {
	    panel.DrawText(" ");
	    panel.DrawText(sVIP);
	    panel.DrawText(sPoints);
	}
	
    panel.DrawText(" ");
    panel.DrawItem(sBack);
    panel.Send(client, Menu_FeatureDetails, MENU_TIME_FOREVER);

    if(menu != null)
    {
      delete menu;
    }

    if(panel != null)
    {
      delete panel;
    }
  }
  else if (action == MenuAction_Cancel)
  {
    g_iFlSite[client] = 1;

    if(menu != null)
    {
      delete menu;
    }
  }
}

public int Menu_FeatureDetails(Menu menu2, MenuAction action, int client, int param)
{
  if (action == MenuAction_Select)
  {
    if(menu2 != null)
    {
      delete menu2;
    }
    Show_Featurelist(client, g_iFlSite[client]);
  }
  else if (action == MenuAction_Cancel)
  {
    if(menu2 != null)
    {
      delete menu2;
    }
    Show_Featurelist(client, g_iFlSite[client]);
  }
}
