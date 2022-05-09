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

public Plugin myinfo =
{
	name = "Display Edicts",
	author = "koen#4977",
	description = "Display live server edicts",
	version = "1.0",
	url = "https://steamcommunity.com/id/fungame1224/"
};

public void OnPluginStart()
{
	// Load plugin translations
	LoadTranslations("displayedicts.phrases");
	
	// Convars
	g_cDisplayChannel = CreateConVar("sm_edict_channel", "5", "What channel should edict display use?", _, true, 0.0, true, 5.0);
	g_cDisplayStyle = CreateConVar("sm_edict_style", "1", "How should edicts be displayed? (1: game_text, 2: Center Text, 3: both)", _, true, 1.0, true, 3.0);
	g_cDisplayUpdateRate = CreateConVar("sm_edict_update", "1", "How often should edict display update (in seconds)", _, true, 0.5, true, 30.0);
	g_cDisplayPosX = CreateConVar("sm_edict_posx", "0.35", "X coordinate of game_text edict display", _, true, 0.0, true, 1.0);
	g_cDisplayPosY = CreateConVar("sm_edict_posy", "1.00", "Y coordinate of game_text edict display", _, true, 0.0, true, 1.0);
	
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

// Start display update timer when confg is executed
public void OnConfigsExecuted()
{
	CreateTimer(GetConVarFloat(g_cDisplayUpdateRate), UpdateEdictDisplay, _, TIMER_REPEAT);
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
				ShowHudText(client, GetDynamicChannel(g_cDisplayChannel.IntValue), "%t", "Display Game Text", GetEntityCount());
				return Plugin_Continue;
			}
			else if (g_cDisplayStyle.IntValue == 2)
			{
				PrintCenterText(client, "%t", "Display Center Text", GetEntityCount());
				return Plugin_Continue;
			}
			else
			{
				SetHudTextParams(GetConVarFloat(g_cDisplayPosX), GetConVarFloat(g_cDisplayPosY), GetConVarFloat(g_cDisplayUpdateRate), 255, 255, 255, 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, GetDynamicChannel(g_cDisplayChannel.IntValue), "%t", "Display Game Text", GetEntityCount());
				PrintCenterText(client, "%t", "Display Center Text", GetEntityCount());
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

// Print Edicts Command
public Action Command_PrintEdicts(int client, int args)
{
	CPrintToChat(client, "%t", "Print Edict", GetEntityCount());
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