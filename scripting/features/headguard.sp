#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hosties3>
#include <emitsoundany>
#include <smlib>

#define FEATURE_NAME "HeadGuard"
#define FEATURE_FILE FEATURE_NAME ... ".cfg"
#define PLUGIN_NAME HOSTIES3_NAME ... FEATURE_NAME
#define PLUGIN_CONFIG HOSTIES3_CONFIG ... FEATURE_FILE

/*// TODO ///

*/
int HeadGuard = -1;

int g_bEnable;
int g_iLogLevel;

char g_sTag[64];

bool g_bSetSoundPrecached;
bool g_bUnsetSoundPrecached;

char g_sSetSound[PLATFORM_MAX_PATH];
char g_sUnsetSound[PLATFORM_MAX_PATH];

Handle g_hHeadGuardColorTimer = null;

// Maker Sprites
int g_iBeamSprite = -1;
int g_iHaloSprite = -1;

// Maker Settings
float g_fMarkerRadiusMin = 100.0;
float g_fMarkerRadiusMax = 500.0;
float g_fMarkerRangeMax = 1500.0;

char g_MarkerNames[4][] =	
{	
	{"Red"},
	{"Green"},
	{"Blue"},
	{"Orange"}
};

int g_MarkerColors[4][4] =	
{	
	{255,25,25,255},
	{25,255,25,255},
	{25,25,255,255},
	{255,160,25,255}
};

// Maker Setup
bool g_bMarkerSetup;
float g_fMarkerSetupStartOrigin[3];
float g_fMarkerSetupEndOrigin[3];

// Makers
float g_MarkerOrigin[4][3];
float g_MarkerRadius[4];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = HOSTIES3_AUTHOR,
	version = HOSTIES3_VERSION,
	description = HOSTIES3_DESCRIPTION,
	url = "www.overcore.eu"
};

public Hosties3_OnPluginPreLoaded()
{
	Hosties3_IsLoaded();
	Hosties3_CheckServerGame();
}

public Hosties3_OnConfigsLoaded()
{
	g_bEnable = Hosties3_AddCvarBool(FEATURE_NAME, "Enable", true);
	
	g_iLogLevel = Hosties3_GetLogLevel();

	Hosties3_AddCvarString(FEATURE_NAME, "SetSound", "", g_sSetSound, sizeof(g_sSetSound));
	Hosties3_AddCvarString(FEATURE_NAME, "UnsetSound", "", g_sUnsetSound, sizeof(g_sUnsetSound));

	Hosties3_GetColorTag(g_sTag, sizeof(g_sTag));

	if (g_iLogLevel <= 2)
	{
		Hosties3_LogToFile(HOSTIES3_PATH, FEATURE_NAME, _, DEBUG, "[%s] Enable: %d", FEATURE_NAME, g_bEnable);
	}

	if(!g_bEnable)
	{
		SetFailState("'%s' is deactivated!", FEATURE_NAME);
		return;
	}

	LoadSounds();

	AddCommandListener(Event_HookPlayerChat, "say");
	
	RegAdminCmd("sm_rhg", Event_RemoveHeadGuard, ADMFLAG_BAN);
	RegAdminCmd("sm_removeheadguard", Event_RemoveHeadGuard, ADMFLAG_BAN);
	
	RegAdminCmd("sm_shg", Event_AdminSetHeadGuard, ADMFLAG_BAN);
	RegAdminCmd("sm_setheadguard", Event_AdminSetHeadGuard, ADMFLAG_BAN);
	
	RegConsoleCmd("sm_headguard", Event_SetHeadGuard);
	RegConsoleCmd("sm_hg", Event_SetHeadGuard);
	
	RegConsoleCmd("sm_unheadguard", Event_UnSetHeadGuard);
	RegConsoleCmd("sm_uhg", Event_UnSetHeadGuard);
	
	CreateTimer(1.0, Timer_DrawMakers, _, TIMER_REPEAT);
}

public Hosties3_OnMapStart()
{
	RemoveAllMarkers();
	if (GetEngineVersion() == Engine_CSS)
	{
		g_iBeamSprite = PrecacheModel("materials/sprites/laser.vmt");
		g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	}
	else if (GetEngineVersion() == Engine_CSGO)
	{
		g_iBeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
		g_iHaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	}
}

public Hosties3_OnRoundStart()
{
	if (g_bEnable)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i))
			{
				if (GetClientTeam(i) == CS_TEAM_CT)
				{
					//Todo... Add translations
					Hosties3_PrintToChat(i,"%s Use: !hg or !headguard to be HeadGuard", g_sTag);
				}
				if (GetClientTeam(i) == CS_TEAM_T)
				{
					//Todo...
				}
			}
		}
	}
}

public Hosties3_OnRoundEnd()
{
	if (g_bEnable)
	{
		Hosties3_LoopClients(i)
		{
			if (Hosties3_IsClientValid(i, true, true) && i == HeadGuard)
			{
				UnSetPlayerHeadGuard(i, false);
			}
		}
	}
}

public Action:Event_HookPlayerChat(int client, const char[] command, args)
{
	if (HeadGuard == client && client != 0)
	{
		char message[256];
		GetCmdArg(1, message, sizeof(message));
		
		if (message[0] == '/' || message[0] == '@' || message[0] == 0 || IsChatTrigger())
		{
			return Plugin_Handled;
		}
		
		//Todo... Add translations
		//Probably best to remove the g_sTag here or you'd have things like "[Hosties3] [Headguard] Meitis : Hi". I'd also suggest removing the space behind the playername myself
		Hosties3_PrintToChatAll("%s [HeadGuard] %N : %s", g_sTag, client, message);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Event_RemoveHeadGuard(int client, args)
{
	if (g_bEnable)
	{
		if (HeadGuard != -1)
		{
			UnSetPlayerHeadGuard(HeadGuard);
			//Todo... Add translations
			Hosties3_PrintToChatAll("%s Admin: %N removed HeadGuard. You can become the new HeadGuard !", g_sTag, client);
		}
		else
		{
			//Todo... Add translations
			Hosties3_PrintToChat(client, "%s There is no HeadGuard to remove", g_sTag);
		}
	}
	else
	{
		//Todo... Add translations
		Hosties3_PrintToChat(client, "%s HeadGuard is disabled on this server !", g_sTag);
	}
}

public Action:Event_UnSetHeadGuard(int client, args)
{
	if (g_bEnable)
	{
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			if (client == HeadGuard)
			{
				//Todo... Add translations
				Hosties3_PrintToChatAll("%s %N is not a HeadGuard anymore, You can become the new HeadGuard", g_sTag, client);
				UnSetPlayerHeadGuard(client);
			}
			else
			{
				//Todo... Add translations
				Hosties3_PrintToChat(client, "%s You are not a HeadGuard", g_sTag);
			}
		}
		else
		{
			//Todo... Add translations
			Hosties3_PrintToChat(client, "%s This command is allowed only for Counter-Terrorist", g_sTag);
		}
	}
	else
	{
		//Todo... Add translations
		Hosties3_PrintToChat(client, "%s HeadGuard is disabled on this server !", g_sTag);
	}
}

public Action:Event_AdminSetHeadGuard(int client, args)
{
	RemoveAllMarkers();
	
	if (g_bEnable)
	{
		if (args < 1)
		{
			Menu g_mAdminSetHG = new Menu(m_hAdminSetHG);
			g_mAdminSetHG.SetTitle("Choose player");
			Hosties3_LoopClients(i)
			{
				if((Hosties3_IsClientValid(i, true, true)) && (GetClientTeam(i) == CS_TEAM_CT) && (i != HeadGuard))
				{
					char clientname[MAX_NAME_LENGTH];
					GetClientName(i, clientname, sizeof(clientname));
					int userid = GetClientUserId(i);
					char clientid[3];
					IntToString(userid, clientid, sizeof(clientid));
					g_mAdminSetHG.AddItem(clientid, clientname);
				}
			}
			g_mAdminSetHG.ExitButton = true;
			g_mAdminSetHG.Display(client, MENU_TIME_FOREVER);
			return Plugin_Handled;
		}
		else
		{
			//Todo
		}
	}
	else
	{
		//Todo... Add translations
		Hosties3_PrintToChat(client, "%s HeadGuard is disabled on this server !", g_sTag);
	}
	return Plugin_Continue;
}

public m_hAdminSetHG(Handle g_mAdminSetHG, MenuAction:action, int client, Position)
{
	if (action == MenuAction_Select)
	{
		char Item[20];
		int NewHeadGuard = -1;
		GetMenuItem(g_mAdminSetHG, Position, Item, sizeof(Item));
		Hosties3_LoopClients(i)
		{
			if((Hosties3_IsClientValid(i, true, true)) && (GetClientTeam(i) == CS_TEAM_CT) && (i != HeadGuard))
			{
				int userid = GetClientUserId(i);
				char user[64];
				IntToString(userid, user, sizeof(user));
				if (StrEqual(Item, user))
				{
					NewHeadGuard = GetClientOfUserId(userid);
				}
			}
		}
		if (HeadGuard != -1)
		{
			//Todo... Add translations
			Hosties3_PrintToChatAll("%s Admin: %N set %N as a HeadGuard instead of %N !", g_sTag, client, NewHeadGuard, HeadGuard);
			UnSetPlayerHeadGuard(HeadGuard);
			SetPlayerHeadGuard(NewHeadGuard);
		}
		else
		{
			//Todo... Add translations
			Hosties3_PrintToChatAll("%s Admin: %N set < %N > as a new HeadGuard !", g_sTag, client, NewHeadGuard);
			SetPlayerHeadGuard(NewHeadGuard);
		}
	}
}

public Action:Event_SetHeadGuard(int client, args)
{
	if (g_bEnable)
	{
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			if (client == HeadGuard)
			{
				//Todo... Add translations
				Hosties3_PrintToChat(client, "%s You are already HeadGuard", g_sTag);
			}
			else if (HeadGuard == -1)
			{
				if (IsPlayerAlive(client))
				{
					//Todo... Add translations
					Hosties3_PrintToChatAll("%s New 'HeadGuard' is %N", g_sTag, client);
					SetPlayerHeadGuard(client);
				}
				else
				{
					//Todo... Add translations
					Hosties3_PrintToChat(client, "%s HeadGuard can be only living player", g_sTag);
				}
			}
			else
			{
				//Todo... Add translations
				Hosties3_PrintToChat(client, "%s There is already one HeadGuard < %N >", g_sTag, HeadGuard);
			}
		}
		else if (GetClientTeam(client) == CS_TEAM_T)
		{
			//Todo... Add translations
			Hosties3_PrintToChat(client, "%s HeadGuard can be only Counter-Terrorist", g_sTag);
		}
	}
	else
	{
		//Todo... Add translations
		Hosties3_PrintToChat(client, "%s HeadGuard is disabled on this server !", g_sTag);
	}
}

public Hosties3_OnPlayerDisconnect(int client)
{
	if (g_bEnable)
	{
		if (client == HeadGuard)
		{
			UnSetPlayerHeadGuard(client);
			//Todo... Add translations
			Hosties3_PrintToChatAll("%s HeadGuard is disconnected. You can become the new HeadGuard !", g_sTag);
		}
	}
}

public Hosties3_OnPlayerDeath(int victim)
{
	if (g_bEnable)
	{
		if (victim == HeadGuard)
		{
			UnSetPlayerHeadGuard(victim);
			//Todo... Add translations
			Hosties3_PrintToChatAll("%s HeadGuard is dead. You can become the new HeadGuard !", g_sTag);
		}
	}
}

public Action:Hosties3_HeadGuardColorAntiBug(Handle timer, any:client)
{
	if (g_bEnable)
	{
		//Todo... Add to config
		SetEntityRenderColor(client, 0,0,255,255);
	}
}

/* Makers */

public Action:Timer_DrawMakers(Handle:timer)
{
	Draw_Markers();
	return Plugin_Continue;
}

stock Draw_Markers()
{
	if (HeadGuard == -1)
		return;
	
	for(int i = 0; i<4; i++)
	{
		if (g_MarkerRadius[i] <= 0.0)
			continue;
		
		float fHeadGuardOrigin[3];
		Entity_GetAbsOrigin(HeadGuard, fHeadGuardOrigin);
		
		if (GetVectorDistance(fHeadGuardOrigin, g_MarkerOrigin[i]) > g_fMarkerRangeMax)
		{
			Hosties3_PrintToChat(HeadGuard, "%s %s marker removed! You were far away from it.", g_sTag, g_MarkerNames[i]);
			RemoveMarker(i);
			continue;
		}
		
		for(new client=1;client<=MaxClients;client++)
		{
			if(!IsClientInGame(client))
				continue;
			
			if (IsFakeClient(client))
				continue;
			
			if(!IsPlayerAlive(client))
				continue;
			
			TE_SetupBeamRingPoint(g_MarkerOrigin[i], g_MarkerRadius[i], g_MarkerRadius[i]+0.1, g_iBeamSprite, g_iHaloSprite, 0, 10, 1.0, 2.0, 0.0, g_MarkerColors[i], 10, 0);
			TE_SendToAll();
		}
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!client)
		return Plugin_Continue;
	
	if (client != HeadGuard)
		return Plugin_Continue;
	
	if(!IsPlayerAlive(client))
		return Plugin_Continue;
	
	if (buttons & IN_ATTACK2)
	{
		if(!g_bMarkerSetup)
			GetClientAimTargetPos(client, g_fMarkerSetupStartOrigin);
		
		GetClientAimTargetPos(client, g_fMarkerSetupEndOrigin);
		
		new Float:radius = 2*GetVectorDistance(g_fMarkerSetupEndOrigin, g_fMarkerSetupStartOrigin);
		
		if (radius > g_fMarkerRadiusMax)
			radius = g_fMarkerRadiusMax;
		else if (radius < g_fMarkerRadiusMin)
			radius = g_fMarkerRadiusMin;
		
		if (radius > 0)
		{
			TE_SetupBeamRingPoint(g_fMarkerSetupStartOrigin, radius, radius+0.1, g_iBeamSprite, g_iHaloSprite, 0, 10, 0.1, 2.0, 0.0, {255,255,255,255}, 10, 0);
			TE_SendToClient(client);
		}
		
		g_bMarkerSetup = true;
	}
	else if (g_bMarkerSetup)
	{
		MarkerMenu(client);
		g_bMarkerSetup = false;
	}
	
	return Plugin_Continue;
}

stock MarkerMenu(client)
{
	if(!(0 < client < MaxClients) || client != HeadGuard)
	{
		Hosties3_PrintToChat(client, "%s Only the HeadGuard can use this feature!", g_sTag);
		return;
	}
	
	int marker = IsMarkerInRange(g_fMarkerSetupStartOrigin);
	if (marker != -1)
	{
		RemoveMarker(marker);
		Hosties3_PrintToChat(client, "%s %s marker removed!", g_sTag, g_MarkerNames[marker]);
		return;
	}
	
	float radius = 2*GetVectorDistance(g_fMarkerSetupEndOrigin, g_fMarkerSetupStartOrigin);
	if (radius <= 0.0)
	{
		RemoveMarker(marker);
		Hosties3_PrintToChat(client, "%s Something went wrong, can not create marker!", g_sTag);
		return;
	}
	
	float pos[3];
	Entity_GetAbsOrigin(HeadGuard, pos);
	
	float range = GetVectorDistance(pos, g_fMarkerSetupStartOrigin);
	if (range > g_fMarkerRangeMax)
	{
		Hosties3_PrintToChat(client, "%sPosition out of range!", g_sTag);
		return;
	}
	
	if (0 < client < MaxClients)
	{
		Handle menu = CreateMenu(Handle_MarkerMenu);
		
		SetMenuTitle(menu, "Marker Type Selection");
		
		AddMenuItem(menu, "0", g_MarkerNames[0]);
		AddMenuItem(menu, "1", g_MarkerNames[1]);
		AddMenuItem(menu, "2", g_MarkerNames[2]);
		AddMenuItem(menu, "3", g_MarkerNames[3]);
		
		DisplayMenu(menu, client, 10);
	}
}

public Handle_MarkerMenu(Handle:menu, MenuAction:action, client, itemNum)
{
	if(!(0 < client < MaxClients))
	{
		return;
	}
	
	if(!IsPlayerAlive(client))
	{
		return;
	}
	
	if (client != HeadGuard)
	{
		Hosties3_PrintToChat(client, "%s Only the HeadGuard can use this feature!", g_sTag);
		return;
	}
	
	if ( action == MenuAction_Select )
	{
		char info[32]; char info2[32];
		bool found = GetMenuItem(menu, itemNum, info, sizeof(info), _, info2, sizeof(info2));
		int marker = StringToInt(info);
		
		if (found)
		{
			SetupMarker(client, marker);
			Hosties3_PrintToChat(client, "%s %s marker set!", g_sTag, g_MarkerNames[marker]);
		}
	}
}

stock SetupMarker(client, marker)
{
	g_MarkerOrigin[marker][0] = g_fMarkerSetupStartOrigin[0];
	g_MarkerOrigin[marker][1] = g_fMarkerSetupStartOrigin[1];
	g_MarkerOrigin[marker][2] = g_fMarkerSetupStartOrigin[2];
	
	float radius = 2*GetVectorDistance(g_fMarkerSetupEndOrigin, g_fMarkerSetupStartOrigin);
	if (radius > g_fMarkerRadiusMax)
		radius = g_fMarkerRadiusMax;
	else if (radius < g_fMarkerRadiusMin)
		radius = g_fMarkerRadiusMin;
	g_MarkerRadius[marker] = radius;
}

stock GetClientAimTargetPos(client, Float:pos[3]) 
{
	if (client < 1) 
	{
		return -1;
	}
	
	float vAngles[3]; float vOrigin[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);
	
	TR_GetEndPosition(pos, trace);
	pos[2] += 5.0;
	
	int entity = TR_GetEntityIndex(trace);
	
	CloseHandle(trace);
	
	return entity;
}

stock RemoveMarker(marker)
{
	g_MarkerRadius[marker] = 0.0;
}

stock RemoveAllMarkers()
{
	for(int i = 0; i < 4;i++)
		RemoveMarker(i);
}

stock IsMarkerInRange(Float:pos[3])
{
	for(int i = 0; i < 4;i++)
	{
		if (g_MarkerRadius[i] <= 0.0)
			continue;
		
		if (GetVectorDistance(g_MarkerOrigin[i], pos) < g_MarkerRadius[i])
			return i;
	}
	return -1;
}

public bool:TraceFilterAllEntities(entity, contentsMask, any:client)
{
	if (entity == client)
		return false;
	if (entity > MaxClients)
		return false;
	if(!IsClientInGame(entity))
		return false;
	if(!IsPlayerAlive(entity))
		return false;
	
	return true;
}

stock UnSetPlayerHeadGuard(const int client, bool playsound = true)
{
	//why the client variable here if it's not getting used? just wondering
	CloseHandle(g_hHeadGuardColorTimer);
	//Todo... Add to config
	SetEntityRenderColor(client, 255,255,255,255);
	HeadGuard = -1;
	if (playsound && g_bUnsetSoundPrecached)
		EmitSoundToAllAny(g_sUnsetSound);
	
	//Remove all makers
	RemoveAllMarkers();
}

stock SetPlayerHeadGuard(const int client, bool playsound = true)
{
	HeadGuard = client;
	g_hHeadGuardColorTimer = CreateTimer(5.0, Hosties3_HeadGuardColorAntiBug, client, TIMER_REPEAT);
	//Todo... Add to config
	SetEntityRenderColor(HeadGuard, 0,0,255,255);
	if (playsound && g_bSetSoundPrecached)
		EmitSoundToAllAny(g_sSetSound);
	
	//Remove all makers
	RemoveAllMarkers();
}

stock LoadSounds()
{
	char sFileName[PLATFORM_MAX_PATH];
	Format(sFileName, sizeof(sFileName), "sound/%s", g_sSetSound);
	if (FileExists(g_sSetSound))
	{
		AddFileToDownloadsTable(sFileName);
		PrecacheSoundAny(g_sSetSound);
		g_bSetSoundPrecached = true;
	}
	else
	{
		g_bSetSoundPrecached = false;
	}
	
	Format(sFileName, sizeof(sFileName), "sound/%s", g_sUnsetSound);
	if (FileExists(g_sUnsetSound))
	{
		AddFileToDownloadsTable(sFileName);
		PrecacheSoundAny(g_sUnsetSound);
		g_bUnsetSoundPrecached = true;
	}
	else
	{
		g_bUnsetSoundPrecached = false;
	}
}