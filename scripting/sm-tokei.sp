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

public void OnPluginStart()
{
    RegConsoleCmd("tokei_start", Command_TimeStart);
    RegConsoleCmd("tokei_stop", Command_TimeStop);
    RegConsoleCmd("tokei_config", Menu_TimerConfig);
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

public Action Menu_TimerConfig(int client, int args)
{
    Menu menu = new Menu(Menu_TimerConfigHandler);
    menu.SetTitle("Tokei Configuration");
    menu.AddItem("units", "Distance Units");
    menu.ExitButton = true;
    menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_TimerConfigHandler(Menu menu, MenuAction action, int param1, int param2)
{
    switch (action)
    {
        case MenuAction_Display:
        {
            Panel panel = view_as<Panel>(param2);
            panel.SetTitle("Tokei Config"); 
        }
        case MenuAction_Select:
        {
            char opt[32];
            menu.GetItem(param2, opt, sizeof(opt));
            PrintToServer("Client %d selected option %s", param1, opt);
        }
        case MenuAction_End:
        {
            delete menu;
        }
    }
}

public Action Command_TimeStart(int client, int args)
{
    if (tokeiPlayers[client].timerStarted)
    {
        ReplyToCommand(client, "[Tokei] - Timer already running! Stop the current timer first before starting a new timer.");
        return Plugin_Handled;
    }

    tokeiPlayers[client].timerStarted = true;
    tokeiPlayers[client].startTime = GetSysTickCount();
    tokeiPlayers[client].distTravelled = 0.0;

    ReplyToCommand(client, "[Tokei] - Timer started!");
    return Plugin_Handled;
}

public Action Command_TimeStop(int client, int args)
{
    if (!tokeiPlayers[client].timerStarted)
    {
        ReplyToCommand(client, "[Tokei] - Cannot stop timer as no timer is started");
        return Plugin_Handled;
    }

    tokeiPlayers[client].timerStarted = false;
    int stopTick = GetSysTickCount();

    int diff = stopTick - tokeiPlayers[client].startTime;
    float sec = float(diff) / 1000.0;
    
    // 52.49 units = 1 meter
    // See https://developer.valvesoftware.com/wiki/Dimensions#Map_Grid_Units:_quick_reference
    float distMeters = tokeiPlayers[client].distTravelled / 52.49;

    ReplyToCommand(client, "[Tokei] - Timer ended!");
    ReplyToCommand(
        client,
        "[Tokei] - %.3f seconds to travel %.3f meters",
        sec, distMeters
    );
    return Plugin_Handled;
}

