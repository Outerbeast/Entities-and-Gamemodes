/* trigger_script for counting players that are alive (or dead)
Template entity:
"classname" "trigger_script"
"m_iszScriptFunctionName" "GAME_PLAYERS_ALIVE::GamePlayersAlive"
"m_iMode" "2"
"spawnflags" "1"
"targetname" "game_players_alive"
// Do not change any of the above
Stats are stored in the following keys and can be accessible at any time:-
"max_health" - Total players connected
"health"     - Total players alive
"frags"      - Total players dead
"speed"      - Percent players alive
"dmg"        - Percent players dead
- Outerbeast */
namespace GAME_PLAYERS_ALIVE
{

EHandle Activate(string strTargetname = "game_players_alive")
{
    dictionary gpa =
    {
        { "m_iszScriptFunctionName", "GAME_PLAYERS_ALIVE::GamePlayersAlive" },
        { "m_iMode", "2" },
        { "targetname", "" + strTargetname },
        { "spawnflags", "1" }
    };
    return EHandle( g_EntityFuncs.CreateEntity( "trigger_script", gpa, true ) );
}

void GamePlayersAlive(CBaseEntity@ pTriggerScript)
{
    if( g_PlayerFuncs.GetNumPlayers() < 1 )
        return;
    
    uint iAlivePlayers = 0, iDeadPlayers = 0;
    float flPercentAlive, flPercentDead;
    // Yeah. No method CPlayerFuncs method "int GetNumPlayersAlive". WHY.
    for( int playerID = 1; playerID <= g_PlayerFuncs.GetNumPlayers(); playerID++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
                
        if( pPlayer is null || !pPlayer.IsConnected() )
            continue;
        
        if( pPlayer.IsAlive() )
            ++iAlivePlayers;
        else if( !pPlayer.IsAlive() )  
            iAlivePlayers = iAlivePlayers < 1 ? 0 : --iAlivePlayers;

        iDeadPlayers = g_PlayerFuncs.GetNumPlayers() - iAlivePlayers;
    }

    flPercentAlive  = float( iAlivePlayers ) / float( g_PlayerFuncs.GetNumPlayers() );
    flPercentDead   = float( iDeadPlayers ) / float( g_PlayerFuncs.GetNumPlayers() );

    pTriggerScript.pev.max_health = g_PlayerFuncs.GetNumPlayers();
    pTriggerScript.pev.health     = iAlivePlayers;
    pTriggerScript.pev.frags      = iDeadPlayers;
    pTriggerScript.pev.speed      = flPercentAlive;
    pTriggerScript.pev.dmg        = flPercentDead;
}

}