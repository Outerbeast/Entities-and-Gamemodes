/* Wipe Restart Mode
    This mode automatically restarts the level when all players have died.
    This brings survival mode observer mode and level restarts when all players have died but still allowing players to respawn
    in the level until all players have died.

    Installation:-
    - Place in scripts/maps
    - Add
    map_script wipe_restart_mode
    to your map cfg
    OR
    - Add
    #include "wipe_restart_mode"
    to your main map script header
    OR
    - Create a trigger_script with these keys set in your map:
    "classname" "trigger_script"
    "m_iszScriptFile" "wipe_restart_mode"

    Usage:-
    To change the restart delay time, you can use the CVar
    "as_command wipe_restart_delay <seconds>"

- Outerbeast
*/
namespace WIPE_RESTART_MODE
{

CCVar cvarRestartDelay( "wipe_restart_delay", 10.0f, "Time until level restarts", ConCommandFlag::AdminOnly );
CScheduledFunction@ fnSearch, fnRestart;
bool blPlayerSpawnedHook = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, PlayerHasSpawned ), blHasWiped;

HookReturnCode PlayerHasSpawned(CBasePlayer@ pPlayer)
{   // Let survival mode handle its own restarts.
    if( pPlayer is null || !pPlayer.IsConnected() || g_SurvivalMode.IsEnabled() )
        return HOOK_CONTINUE;
    // If this is the first player to spawn, start the search timer.
    if( fnSearch is null )
    {
        @fnSearch = g_Scheduler.SetInterval( "CheckWipe", 1.0f );
        g_Hooks.RemoveHook( Hooks::Player::PlayerSpawn, PlayerHasSpawned );
        blPlayerSpawnedHook = false;
    }

    return HOOK_CONTINUE;
}

void CheckWipe()
{
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || pPlayer.pev.FlagBitSet( FL_FAKECLIENT ) )
            continue;

        if( pPlayer.IsAlive() )
            blHasWiped = false;
        else if( !pPlayer.GetObserver().IsObserver() )
        {
            pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );
            pPlayer.GetObserver().SetObserverModeControlEnabled( true );
            blHasWiped = true;
        }
    }

    if( blHasWiped )
    {
        if( fnRestart is null )
        {
            const float restartDelay = Math.clamp( 1.0f, 1337.0f, cvarRestartDelay.GetFloat() );
            g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "No survivors left. Restarting level after " + int( restartDelay ) + " seconds...\n" );
            @fnRestart = g_Scheduler.SetTimeout( @g_EngineFuncs, "ChangeLevel", restartDelay, string( g_Engine.mapname ) );
        }
    }
    else if( fnRestart !is null )
    {   // Someone has respawned, so we need to cancel the restart.
        g_Scheduler.RemoveTimer( fnRestart );
        @fnRestart = null; // Handle is not released automatically, so we need to set it to null? But RemoveTimer should do that.
    }
}

}
