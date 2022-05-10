#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <csgocolors_fix>
#include <DynamicChannels> //https://github.com/Vauff/DynamicChannels

// Display status
bool g_bDisplayEdicts[MAXPLAYERS + 1] = {false, ...};

// Convars
ConVar g_cDisplayChannel;
ConVar g_cDisplayStyle;
ConVar g_cDisplayUpdateRate;
ConVar g_cDisplayPosX, g_cDisplayPosY;
ConVar g_cEnableDisplay;

// Timer handle
Handle g_hDisplayUpdate;

// Boolean value for display enabled
bool g_bEnableDisplay;

public Plugin myinfo =
{
	name = "Display Edicts",
	author = "koen#4977",
	description = "Display live server edicts",
	version = "1.1",
	url = "https://steamcommunity.com/id/fungame1224/"
};

public void OnPluginStart()
{
	// Load plugin translations
	LoadTranslations("displayedicts.phrases");
	
	// Convars
	g_cDisplayChannel = CreateConVar("sm_edict_channel", "5", "What channel should edict display use?", _, true, 0.0, true, 5.0);
	g_cDisplayStyle = CreateConVar("sm_edict_style", "3", "How should edicts be displayed? (1: game_text, 2: Center Text, 3: both)", _, true, 1.0, true, 3.0);
	g_cDisplayUpdateRate = CreateConVar("sm_edict_update", "1", "How often should edict display update (in seconds)", _, true, 0.5, true, 30.0);
	g_cDisplayPosX = CreateConVar("sm_edict_posx", "0.35", "X coordinate of game_text edict display", _, true, 0.0, true, 1.0);
	g_cDisplayPosY = CreateConVar("sm_edict_posy", "1.00", "Y coordinate of game_text edict display", _, true, 0.0, true, 1.0);
	g_cEnableDisplay = CreateConVar("sm_edict_display_enable", "0", "Enable edict display? (Does not affect sm_edicts)", _, true, 0.0, true, 1.0);
	
	// Hook display cvar changes
	g_cEnableDisplay.AddChangeHook(OnDisplayChange);
	g_bEnableDisplay = g_cEnableDisplay.BoolValue;
	
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

// Hook g_cEnableDisplay convar change
public void OnDisplayChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	// Use new value for functions
	int newCvar = StringToInt(newValue);
	g_bEnableDisplay = view_as<bool>(newCvar);
	
	// Delete the existing timer handle and then check if cvar is true for starting timer
	delete g_hDisplayUpdate;
	if (g_bEnableDisplay)
	{
		g_hDisplayUpdate = CreateTimer(GetConVarFloat(g_cDisplayUpdateRate), UpdateEdictDisplay, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

// Start display update timer when confg is executed
public void OnConfigsExecuted()
{
	if (g_cEnableDisplay.BoolValue)
		g_hDisplayUpdate = CreateTimer(GetConVarFloat(g_cDisplayUpdateRate), UpdateEdictDisplay, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

// Timer Event
public Action UpdateEdictDisplay(Handle timer)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client) && g_bDisplayEdicts[client])
		{
			if (g_cDisplayStyle.IntValue == 1)
			{
				SetHudTextParams(GetConVarFloat(g_cDisplayPosX), GetConVarFloat(g_cDisplayPosY), GetConVarFloat(g_cDisplayUpdateRate), 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, GetDynamicChannel(g_cDisplayChannel.IntValue), "%t", "Display Game Text", GetEdictCount());
			}
			else if (g_cDisplayStyle.IntValue == 2)
			{
				PrintCenterText(client, "%t", "Display Center Text", GetEdictCount());
			}
			else
			{
				SetHudTextParams(GetConVarFloat(g_cDisplayPosX), GetConVarFloat(g_cDisplayPosY), GetConVarFloat(g_cDisplayUpdateRate), 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
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
	if (!g_cEnableDisplay.BoolValue)
		CPrintToChat(client, "%t", "Display Command Disabled");
	else
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
	return Plugin_Handled;
}