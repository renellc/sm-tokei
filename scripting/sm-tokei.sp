#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

// General Plugin info
public Plugin myinfo =
{
    name = "sm-tokei",
    author = "chromatic",
    description = "Time how long it takes to get from one point to another in a map.",
    version = "1.0",
    url = "https://github.com/renellc/sm-tokei"
};

int playerStartTimes[MAXPLAYERS];

public void OnPluginStart()
{
    RegConsoleCmd("tokei_start", Command_TimeStart);
    RegConsoleCmd("tokei_end", Command_TimeEnd);
}

public Action Command_TimeStart(int client, int args)
{
    ReplyToCommand(client, "Tokei - Timer started!");
    playerStartTimes[client] = GetSysTickCount();
    return Plugin_Handled;
}

public Action Command_TimeEnd(int client, int args)
{
    int stopTick = GetSysTickCount();
    int diff = stopTick - playerStartTimes[client];
    float sec = float(diff) / 1000.0;
    ReplyToCommand(client, "Tokei - Timer ended!");
    ReplyToCommand(client, "Tokei - Time Taken: %.3f seconds", sec);
    return Plugin_Handled;
}

