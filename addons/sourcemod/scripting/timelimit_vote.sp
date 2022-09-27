#define MAX_ITEMS 6
#define MAX_ITEMS_STR "6"

#pragma semicolon 1

#include <colors>
#include <sourcemod>
#include <sdktools_gamerules>

#pragma newdecls required


int
    g_iDuration,
    g_iMinPlayers;

bool
    g_bCSGO,
    g_bHideVotes,
    g_bDisplayed;

char
    g_szItems[32];

float
    g_fDelay,
    g_fItems[MAX_ITEMS];


public Plugin myinfo =
{
    name    =   "Timelimit Vote",
    author  =   "Young <",
    version =   "1.2.1"
};

public void OnPluginStart()
{
    ConVar hCvar;

    hCvar = CreateConVar("sm_timelimit_vote_delay", "3.0", "Delay before the start of the first round.", _, true, 0.0);
    hCvar.AddChangeHook(OnCvarChanged);
    g_fDelay = hCvar.FloatValue;

    hCvar = CreateConVar("sm_timelimit_vote_items", "10 20 30 40 50 60", "Items (minutes) that can be chosen in the vote. (Each item must be greater than 0.0 and the total number must be no less than 2 and no more than "...MAX_ITEMS_STR...")");
    hCvar.AddChangeHook(OnCvarChanged);
    hCvar.GetString(g_szItems, sizeof g_szItems);

    hCvar = CreateConVar("sm_timelimit_vote_duration", "20", "Duration of the vote. (0 - permanent)", _, true, 0.0);
    hCvar.AddChangeHook(OnCvarChanged);
    g_iDuration = hCvar.IntValue;

    hCvar = CreateConVar("sm_timelimit_vote_hidevotes", "0", "Hide information about votes.", _, true, 0.0, true, 1.0);
    hCvar.AddChangeHook(OnCvarChanged);
    g_bHideVotes = hCvar.BoolValue;

    hCvar = CreateConVar("sm_timelimit_vote_minplayers", "2", "Minimum number of players required to start the vote.", _, true, 1.0, true, float(MaxClients));
    hCvar.AddChangeHook(OnCvarChanged);
    g_iMinPlayers = hCvar.IntValue;

    AutoExecConfig(true);

    LoadTranslations("timelimit.vote.phrases");
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);

    g_bCSGO = (GetEngineVersion() == Engine_CSGO);

    //RegConsoleCmd("tv_start", CmdStart);//For debugging
}

/*Action CmdStart(int iClient, int iArgs)
{
    OnDelayEnd(INVALID_HANDLE);
    return Plugin_Handled;
}*/

void OnCvarChanged(ConVar hCvar, const char[] szOldValue, const char[] szNewValue)
{
    char szName[32];
    hCvar.GetName(szName, sizeof szName);
    switch(szName[20])
    {
        case 'l': g_fDelay = StringToFloat(szNewValue);
        case 'r': g_iDuration = StringToInt(szNewValue);
        case 'd': g_bHideVotes = !!StringToInt(szNewValue);
        case 'n': g_iMinPlayers = StringToInt(szNewValue);
        case 'e': strcopy(g_szItems, sizeof g_szItems, szNewValue);
    }
}

public void OnMapStart()
{
    g_bDisplayed = false;
}

void Event_RoundStart(Event hEvent, const char[] szName, bool bDontBroadcast)
{
    if(g_bDisplayed || (g_bCSGO && GameRules_GetProp("m_bWarmupPeriod")))
    {
        return;
    }

    g_bDisplayed = true;
    CreateTimer(g_fDelay, OnDelayEnd, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action OnDelayEnd(Handle hTimer)
{
    if(IsVoteInProgress())
    {
        g_bDisplayed = false;
        return;
    }

    if(GetHumanPlayersCount() >= g_iMinPlayers)
    {
        Menu hMenu = new Menu(hMenu_Callback, MenuAction_End|MenuAction_Select|MenuAction_Display|MenuAction_DisplayItem);

        hMenu.SetTitle("Select map timelimit:\n ");
        hMenu.VoteResultCallback = hMenu_VoteCallback;

        char szItems[MAX_ITEMS][8];
        int iExpCount = ExplodeString(g_szItems, " ", szItems, sizeof szItems, sizeof szItems[]);
        if(iExpCount > MAX_ITEMS || iExpCount < 2)
        {
            LogError("Provided invalid items count: %i. Stopping the vote.", iExpCount);
            delete hMenu;
            return;
        }

        for(int i; i < iExpCount; i++)
        {
            if((g_fItems[i] = StringToFloat(szItems[i])) <= 0.0)
            {
                LogError("Provided invalid time: %s. Stopping the vote.", szItems[i]);
                delete hMenu;
                return;
            }

            hMenu.AddItem(szItems[i], szItems[i]);
        }

        hMenu.ExitButton = false;
        hMenu.DisplayVoteToAll(g_iDuration);
    }
}

int hMenu_Callback(Menu hMenu, MenuAction eAction, int iClient, int iItem)
{
    switch(eAction)
    {
        case MenuAction_End: delete hMenu;
        case MenuAction_Display: hMenu.SetTitle("%T", "menu_title", iClient);
        case MenuAction_DisplayItem:
        {
            char szTime[8], szDisplay[16];
            hMenu.GetItem(iItem, szTime, sizeof szTime);
            FormatEx(szDisplay, sizeof szDisplay, "%s %T", szTime, "minutes", iClient);

            return RedrawMenuItem(szDisplay);
        }
        case MenuAction_Select:
        {
            if(!g_bHideVotes)
            {
                char szName[32], szTime[8];
                hMenu.GetItem(iItem, szTime, sizeof szTime);
                GetClientName(iClient, szName, sizeof szName);
                CPrintTo(ALL, "player_x_chose_y_minutes", " %t %t", "prefix", "player_x_chose_y_minutes", szName, szTime);
            }
        }
    }

    return 0;
}

void hMenu_VoteCallback(Menu hMenu, int iNumVotes, int iNumClients, const int[][] iClientInfo, int iNumItems, const int[][] iItemInfo)
{
    float fResult, fTime;

    char szBuffer[8];
    for(int i; i < iNumClients; i++)
    {
        if(iClientInfo[i][VOTEINFO_CLIENT_ITEM] != -1)
        {
            hMenu.GetItem(iClientInfo[i][VOTEINFO_CLIENT_ITEM], szBuffer, sizeof szBuffer);
            fResult += StringToFloat(szBuffer);
        }
    }

    fResult = fResult / float(iNumVotes);

    for(int i; i < MAX_ITEMS; i++)
    {
        if(!i || FloatAbs(fResult - fTime) >= FloatAbs(g_fItems[i] - fResult))
        {
            fTime = g_fItems[i];
        }
    }

    FindConVar("mp_timelimit").FloatValue = fTime;
    CPrintTo(ALL, "timelimit_has_been_changed_to_x_minutes", " %t %t", "prefix", "timelimit_has_been_changed_to_x_minutes", fTime);
}

stock int GetHumanPlayersCount()
{
    int iCount;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i) && !IsFakeClient(i)) 
        {
            iCount++;
        }
    }
    return iCount;
}