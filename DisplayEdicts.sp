#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <DynamicChannels> // https://github.com/Vauff/DynamicChannels

// Display status
bool g_bDisplayEdicts[MAXPLAYERS + 1] = {false, ...};

// Display position
#define POS_X 0.15
#define POS_Y 0.0

// Convars
ConVar g_cvChannel;
ConVar g_cvStyle;
ConVar g_cvRate;
ConVar g_cvLimit;
ConVar g_cvEnable;

// Global variables
bool g_bTimer;

// Timer handle
Handle g_hDisplayUpdate;

public Plugin myinfo =
{
	name = "Display Edicts",
	author = "notkoen", // Thanks to tilgep for help with optimizations
	description = "Display live server edicts",
	version = "2.3",
	url = "https://github.com/notkoen"
};

public void OnPluginStart()
{
	// Convars
	g_cvChannel = CreateConVar("sm_edict_channel", "5", "game_text display method channel", _, true, 0.0, true, 5.0);
	g_cvStyle = CreateConVar("sm_edict_style", "1", "How should edicts be displayed? (1: game_text, 2: Center Text)", _, true, 1.0, true, 2.0);
	g_cvRate = CreateConVar("sm_edict_update", "1", "How often should edict display update (in seconds)", _, true, 0.5, true, 30.0);
	g_cvLimit = CreateConVar("sm_edict_deathvalue", "1950", "Minimum amount of edicts before the death warning is given", _, true, 0.0, true, 2048.0);
	
	// Toggle timer cvar
	g_cvEnable = CreateConVar("sm_edict_enable_timer", "0", "Toggle update timer (Setting to 0 will disable live display & warnings)", _, true, 0.0, true, 1.0);
	g_bTimer = g_cvEnable.BoolValue;
	HookConVarChange(g_cvEnable, OnTimerToggle);
	
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

// Hook g_cvEnable convar change
public void OnTimerToggle(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	// Use new value for functions
	int newCvar = StringToInt(newValue);
	g_bTimer = view_as<bool>(newCvar);
	
	// Delete the existing timer handle and then check if cvar is true for starting timer
	delete g_hDisplayUpdate;
	if (g_bTimer)
	{
		g_hDisplayUpdate = CreateTimer(g_cvRate.FloatValue, UpdateEdictDisplay, _, TIMER_REPEAT);
	}
}

// Start display update timer when confg is executed
public void OnConfigsExecuted()
{
	g_hDisplayUpdate = CreateTimer(g_cvRate.FloatValue, UpdateEdictDisplay, _, TIMER_REPEAT);
}

// Delete timer when map ends
public void OnMapEnd()
{
	delete g_hDisplayUpdate;
}

// Timer Event
public Action UpdateEdictDisplay(Handle timer)
{
	// Store edict count to a variable and then check if it is past the limits
	int eCount = GetEdictCount();
	if (eCount > g_cvLimit.IntValue)
		PrintToChatAll(" \x04[Edicts] \x02Warning! \x01Number of edicts has reached a dangerous level! (\x04%d\x01/2048)", eCount);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && g_bDisplayEdicts[client])
		{
			switch (g_cvStyle.IntValue)
			{
				case 1:
				{
					SetHudTextParams(POS_X, POS_Y, g_cvRate.FloatValue, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(client, GetDynamicChannel(g_cvChannel.IntValue), "Edicts: %d/2048", eCount);
				}
				case 2:
				{
					PrintCenterText(client, "<font color='#FF0000'>Edicts</font>: <font color='#00FF00'>{1}</font>/2048", eCount);
				}
			}
		}
	}
	return Plugin_Continue;
}

// Print Edicts Command
public Action Command_PrintEdicts(int client, int args)
{
	PrintToChat(client, " \x04[Edicts] \x01Current number of edicts: \x04%d\x01/2048", GetEdictCount());
	return Plugin_Handled;
}

// Toggle Edicts Display Command
public Action Command_ToggleDisplay(int client, int args)
{
	g_bDisplayEdicts[client] = !g_bDisplayEdicts[client];
	PrintToChat(client, " \x04[Edicts] \x01Edict counter display is now %s\x01.", g_bDisplayEdicts[client] ? "\x04enabled" : "\x02disabled");
	return Plugin_Handled;
}

// Reset client index preference on disconnect
public void OnClientDisconnect(int client)
{
	g_bDisplayEdicts[client] = false;
}