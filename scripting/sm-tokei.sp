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

enum struct PlayerInfo
{
    bool timerStarted;
    int startTime;
    float lastPos[3];
    float distTravelled;
}

PlayerInfo tokeiPlayers[MAXPLAYERS];
char replyStart[] = "[Tokei] -";

public void OnPluginStart()
{
    RegConsoleCmd("tokei_start", Command_TimeStart);
    RegConsoleCmd("tokei_stop", Command_TimeStop);
}

public void OnGameFrame()
{
    // MAXPLAYERS should never be substantially large enough for the following loop to cause any significant slowdown
    // on the server.
    for (int currPlayer = 0; currPlayer < MAXPLAYERS; currPlayer++)
    {
        if (tokeiPlayers[currPlayer].timerStarted)
        {
            float currPos[3];
            GetClientAbsOrigin(currPlayer, currPos);
            float dist = GetVectorDistance(tokeiPlayers[currPlayer].lastPos, currPos);
            tokeiPlayers[currPlayer].lastPos = currPos;
            tokeiPlayers[currPlayer].distTravelled += dist;
        }
    }
}

public Action Command_TimeStart(int client, int args)
{
    if (tokeiPlayers[client].timerStarted)
    {
        ReplyToCommand(
            client,
            "%s \x01 \x07Timer already running! Stop the current timer first before starting a new timer.",
            replyStart
        );
        return Plugin_Handled;
    }

    tokeiPlayers[client].timerStarted = true;
    tokeiPlayers[client].startTime = GetSysTickCount();
    tokeiPlayers[client].distTravelled = 0.0;

    ReplyToCommand(client, "%s Timer started!", replyStart);
    return Plugin_Handled;
}

public Action Command_TimeStop(int client, int args)
{
    if (!tokeiPlayers[client].timerStarted)
    {
        ReplyToCommand(client, "%s \x01 \x07Cannot stop timer as no timer is started", replyStart);
        return Plugin_Handled;
    }

    tokeiPlayers[client].timerStarted = false;
    int stopTick = GetSysTickCount();

    int diff = stopTick - tokeiPlayers[client].startTime;
    float sec = float(diff) / 1000.0;
    
    // 52.49 units = 1 meter
    // See https://developer.valvesoftware.com/wiki/Dimensions#Map_Grid_Units:_quick_reference
    float distMeters = tokeiPlayers[client].distTravelled / 52.49;

    ReplyToCommand(client, "%s Timer ended!", replyStart);
    ReplyToCommand(
        client,
        "%s\x01 \x05\%.3f seconds \x01to travel \x01 \x05%.3f meters",
        replyStart, sec, distMeters
    );
    return Plugin_Handled;
}

