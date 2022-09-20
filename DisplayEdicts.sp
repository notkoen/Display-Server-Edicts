#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <csgocolors_fix>
#include <DynamicChannels> // https://github.com/Vauff/DynamicChannels

// Display status
bool g_bDisplayEdicts[MAXPLAYERS + 1] = {false, ...};

// Convars
ConVar g_cDisplayChannel;
ConVar g_cDisplayStyle;
ConVar g_cDisplayUpdateRate;
ConVar g_cDisplayPos;
ConVar g_cEdictThreshold, g_cEdictDeath;
ConVar g_cEnableTimer;

// Global variables
float g_flPosX, g_flPosY;
bool g_bTimer;

// Timer handle
Handle g_hDisplayUpdate;

public Plugin myinfo =
{
	name = "Display Edicts",
	author = "notkoen", // Thanks to tilgep for help with optimizations
	description = "Display live server edicts",
	version = "2.1",
	url = "https://github.com/notkoen"
};

public void OnPluginStart()
{
	// Load plugin translations
	LoadTranslations("displayedicts.phrases");
	
	// Convars
	g_cDisplayChannel = CreateConVar("sm_edict_channel", "5", "game_text display method channel", _, true, 0.0, true, 5.0);
	g_cDisplayStyle = CreateConVar("sm_edict_style", "1", "How should edicts be displayed? (1: game_text, 2: Center Text, 3: both)", _, true, 1.0, true, 3.0);
	g_cDisplayUpdateRate = CreateConVar("sm_edict_update", "1", "How often should edict display update (in seconds)", _, true, 0.5, true, 30.0);
	g_cDisplayPos = CreateConVar("sm_edict_pos", "0.35 1.00", "Position of game_text display");
	g_cEdictThreshold = CreateConVar("sm_edict_threshold", "1750", "Minimum amount of edicts before a warning is given", _, true, 0.0, true, 2048.0);
	g_cEdictDeath = CreateConVar("sm_edict_deathvalue", "1950", "Minimum amount of edicts before the death warning is given", _, true, 0.0, true, 2048.0);
	
	// Toggle timer cvar
	g_cEnableTimer = CreateConVar("sm_edict_enable_timer", "0", "Toggle update timer (Setting to 0 will disable live display & warnings)", _, true, 0.0, true, 1.0);
	g_bTimer = g_cEnableTimer.BoolValue;
	HookConVarChange(g_cEnableTimer, OnTimerToggle);
	
	// Autoexecute config
	AutoExecConfig(true, "DisplayEdicts");
	
	// Register console commands
	RegConsoleCmd("sm_edicts", Command_PrintEdicts, "Print current edicts in chat");
	RegConsoleCmd("sm_displayedicts", Command_ToggleDisplay, "Toggle edict display function");
}

// IsValidClient function
stock bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;
	return true;
}

// GetEdictCount function
stock int GetEdictCount()
{
	int EdictCount = 0;
	for (int entity = 0; entity <= 2048; entity++)
	{
		if (IsValidEdict(entity))
			EdictCount++;
	}
	return EdictCount;
}

// Hook g_cEnableTimer convar change
public void OnTimerToggle(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	// Use new value for functions
	int newCvar = StringToInt(newValue);
	g_bTimer = view_as<bool>(newCvar);
	
	// Delete the existing timer handle and then check if cvar is true for starting timer
	delete g_hDisplayUpdate;
	if (g_bTimer)
	{
		g_hDisplayUpdate = CreateTimer(g_cDisplayUpdateRate.FloatValue, UpdateEdictDisplay, _, TIMER_REPEAT);
	}
}

// Start display update timer when confg is executed
public void OnConfigsExecuted()
{
	g_hDisplayUpdate = CreateTimer(g_cDisplayUpdateRate.FloatValue, UpdateEdictDisplay, _, TIMER_REPEAT);
}

// Delete timer when map ends
public void OnMapEnd()
{
	delete g_hDisplayUpdate;
}

// Timer Event
public Action UpdateEdictDisplay(Handle timer)
{
	// Convert position cvar to 
	char buffer[32];
	char split[2][16];
	g_cDisplayPos.GetString(buffer, sizeof(buffer));
	int count = ExplodeString(buffer, " ", split, sizeof(split), sizeof(split[]), true);
	
	if (count != 2) LogError("[EDICTS] Invalid game_text position specified");
	else
	{
		g_flPosX = StringToFloat(split[0]);
		g_flPosY = StringToFloat(split[1]);
	}
	
	// Store edict count to a variable and then check if it is past the limits
	int eCount = GetEdictCount();
	if (eCount > g_cEdictDeath.IntValue)
		CPrintToChatAll("%t", "Server Is About to Die", eCount);
	else if (eCount > g_cEdictThreshold.IntValue)
		CPrintToChatAll("%t", "Edict Threshold Reached", eCount);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && g_bDisplayEdicts[client])
		{
			if (g_cDisplayStyle.IntValue == 1)
			{
				SetHudTextParams(g_flPosX, g_flPosY, g_cDisplayUpdateRate.FloatValue, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, GetDynamicChannel(g_cDisplayChannel.IntValue), "%t", "Display Game Text", GetEdictCount());
			}
			else if (g_cDisplayStyle.IntValue == 2)
			{
				PrintCenterText(client, "%t", "Display Center Text", GetEdictCount());
			}
			else
			{
				SetHudTextParams(g_flPosX, g_flPosY, g_cDisplayUpdateRate.FloatValue, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, GetDynamicChannel(g_cDisplayChannel.IntValue), "%t", "Display Game Text", GetEdictCount());
				PrintCenterText(client, "%t", "Display Center Text", GetEdictCount());
			}
		}
	}
	return Plugin_Continue;
}

// Print Edicts Command
public Action Command_PrintEdicts(int client, int args)
{
	CPrintToChat(client, "%t", "Print Edict", GetEdictCount());
	return Plugin_Handled;
}

// Toggle Edicts Display Command
public Action Command_ToggleDisplay(int client, int args)
{
	g_bDisplayEdicts[client] = !g_bDisplayEdicts[client];
	if (g_bDisplayEdicts[client])
	{
		CPrintToChat(client, "%t", "Enable Edict Display");
	}
	else
	{
		CPrintToChat(client, "%t", "Disable Edict Display");
	}
	return Plugin_Handled;
}