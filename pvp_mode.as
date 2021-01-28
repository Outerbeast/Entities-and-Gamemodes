/* PVP Deathmatch Mode Script
- by Outerbeast

Script for enabling friendly fire between players for pvp deathmatch maps
Only supports 18 players maximum because of limitations imposed by the game + API.
Ensure the server has only 17 player slots available or extra players will be moved onto Observer Mode
Use as include in a map script or directly via map cfg.

Map cfg settings:
"map_script pvp_mode" - install the script to the map
"as_command pvp_spawnprotecttime" - set the time duration in seconds for how long spawn invulnerbility lasts, by default this is 5 if let undefined
*/

PvpMode@ g_pvpmode = @PvpMode();

CCVar cvarProtectDuration( "pvp_spawnprotecttime", 5.0f, "Duration of spawn invulnerability", ConCommandFlag::AdminOnly );
CCVar cvarViewModeSetting( "pvp_viewmode", 0.0f, "View Mode Setting", ConCommandFlag::AdminOnly );

const bool blPlayerSpawnHookRegister = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PvpOnPlayerSpawn );
const bool blPlayerDisconnectRegister = g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @PvpOnPlayerLeave );

HookReturnCode PvpOnPlayerSpawn(CBasePlayer@ pPlayer)
{
    return g_pvpmode.OnPlayerSpawn( pPlayer );
}

HookReturnCode PvpOnPlayerLeave(CBasePlayer@ pPlayer)
{
    return g_pvpmode.OnPlayerLeave( pPlayer );
}

final class PvpMode
{
    array<uint> I_PLAYER_TEAM = { 1, 2, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 17, 18, 19, 99 };
    array<bool> BL_PLAYER_SLOT;

    PvpMode()
    {
        I_PLAYER_TEAM.resize(33);
        BL_PLAYER_SLOT.resize(33);
    }

    HookReturnCode OnPlayerSpawn(CBasePlayer@ pPlayer)
    {   
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
           return HOOK_CONTINUE;

        if( BL_PLAYER_SLOT.find( false ) >= 0 )
        {
            pPlayer.SetClassification( I_PLAYER_TEAM[BL_PLAYER_SLOT.find( false )] );
            BL_PLAYER_SLOT[I_PLAYER_TEAM.find( pPlayer.m_iClassSelection )] = true;
            g_EngineFuncs.ServerPrint( "-- DEBUG -- Player: " + pPlayer.pev.netname + " in slot: " + I_PLAYER_TEAM.find( pPlayer.m_iClassSelection ) + " was assigned to team: " + pPlayer.m_iClassSelection + "\n" );
        }
        
        EnterSpectator( EHandle( pPlayer ) );

        g_Scheduler.SetTimeout( this, "SpawnProtection", 0.01f, EHandle( pPlayer ) );
        g_Scheduler.SetInterval( this, "ForceViewMode", 0.05f, g_Scheduler.REPEAT_INFINITE_TIMES, EHandle( pPlayer ) ); // Have to constantly keep updating the viewmode since it doesn't persist hence the scheduler
        
        return HOOK_CONTINUE;
    }

    void SpawnProtection(EHandle hPlayer)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer !is null && pPlayer.m_iClassSelection > 0 )
        {
            pPlayer.pev.flags       |= FL_FROZEN;
            pPlayer.pev.takedamage  = DAMAGE_NO;
            pPlayer.pev.rendermode  = kRenderTransTexture;
            pPlayer.pev.renderamt   = 50.0f;
        }

        g_Scheduler.SetTimeout( this, "ProtectionOff", cvarProtectDuration.GetFloat(), EHandle( pPlayer ) );
    }

    void ProtectionOff(EHandle hPlayer)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer !is null && pPlayer.m_iClassSelection > 0 )
        {
            pPlayer.pev.flags       &= ~FL_FROZEN;
            pPlayer.pev.takedamage  = DAMAGE_YES;
            pPlayer.pev.rendermode  = kRenderNormal;
            pPlayer.pev.renderamt   = 255.0f;
        }
    }

    void EnterSpectator(EHandle hPlayer)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null || !pPlayer.IsConnected() )
		    return;
		// Players not assigned to a team immediately get moved to observer mode
        if( !pPlayer.GetObserver().IsObserver() && pPlayer.m_iClassSelection < 1 )
        {
            pPlayer.GetObserver().StartObserver( pPlayer.GetOrigin(), pPlayer.pev.angles, false );
            pPlayer.GetObserver().SetObserverModeControlEnabled( true );
            pPlayer.RemoveAllItems( true );
            g_PlayerFuncs.SayText( pPlayer, "SPECTATING: No player slots available. Please wait until the end of the round." );
            //g_EngineFuncs.ServerPrint( "-- DEBUG -- Player: " + pPlayer.pev.netname + " was moved into Spectator (no free player slots available ) \n" );
        }

        g_Scheduler.SetTimeout( this, "NoRespawn", 0.1f, EHandle( pPlayer ) );
    }
    // "Disables" respawning of players in Spectator Mode (just making the respawn delay stupid long)
    void NoRespawn(EHandle hPlayer)
    {
        if( !hPlayer )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer.GetObserver().IsObserver() )
        { 
            pPlayer.m_flRespawnDelayTime = Math.FLOAT_MAX;
            pPlayer.RemoveAllItems( true );
        }
        // Just to make sure the respawn delay never counts down, keep updating the time in a loop
        g_Scheduler.SetTimeout( this, "NoRespawn", 1.0f, EHandle( pPlayer ) );
    }

    void ForceViewMode(EHandle hPlayer)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
        {
            if( cvarViewModeSetting.GetInt() <= 0 )
                pPlayer.SetViewMode( ViewMode_FirstPerson );
            else
                pPlayer.SetViewMode( ViewMode_ThirdPerson );
        }
    }

    HookReturnCode OnPlayerLeave(CBasePlayer@ pDisconnectedPlayer)
    {   
        if( pDisconnectedPlayer is null )
            return HOOK_CONTINUE;

        BL_PLAYER_SLOT[I_PLAYER_TEAM.find( pDisconnectedPlayer.m_iClassSelection )] = false;

        for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
        {
            if( BL_PLAYER_SLOT.find( false ) < 0 )
               break;

            CBasePlayer@ pObserverPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

            if( pObserverPlayer !is null && pObserverPlayer.GetObserver().IsObserver() )
                pObserverPlayer.GetObserver().StopObserver( true );
        }  
        return HOOK_CONTINUE;
    }
}
/* Special thanks to 
- AnggaraNothing, Zode, Neo and H2 for scripting help
AlexCorruptor for testing and building a test map
Gauna, SV BOY, Jumpy for helping test */