/* PVP Deathmatch Mode Script
- by Outerbeast

Script for enabling friendly fire between players for pvp deathmatch maps
Only supports 18 players maximum because of limitations imposed by the game + API.
Ensure the server has only 18 player slots available or extra players will be moved onto Observer Mode
Use as include in a map script or directly via map cfg.

Map cfg settings:
"map_script pvp_mode" - install the script to the map
"as_command pvp_spawnprotecttime" - set the time duration in seconds for how long spawn invulnerbility lasts, by default this is 5 if let undefined
*/

PvpMode@ g_pvpmode = @PvpMode();

CCVar g_ProtectDuration( "pvp_spawnprotecttime", 5.0f, "Duration of spawn invulnerability", ConCommandFlag::AdminOnly );

const bool blPlayerSpawnHookRegister = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PvpOnPlayerSpawn );

HookReturnCode PvpOnPlayerSpawn(CBasePlayer@ pPlayer)
{
    return g_pvpmode.OnPlayerSpawn( pPlayer );
}


final class PvpMode
{
    array<uint> I_PLAYER_TEAM = { 0, 1, 2, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 19, 99 };

    PvpMode()
    {
        I_PLAYER_TEAM.resize(33);
    }

    HookReturnCode OnPlayerSpawn(CBasePlayer@ pSpawnedPlayer)
    {   
        if( pSpawnedPlayer is null )
           return HOOK_CONTINUE;

        AssignTeam( pSpawnedPlayer );
        SpawnProtection( pSpawnedPlayer );
        EnterSpectator( pSpawnedPlayer );
        g_Scheduler.SetInterval( this, "ViewMode", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES, @pSpawnedPlayer ); // Have to constantly keep updating the viewmode since it doesn't persist hence the scheduler
        
        return HOOK_CONTINUE;
    }

    void AssignTeam(CBasePlayer@ pPlayer)
    {
        if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
        {
            pPlayer.SetClassification( I_PLAYER_TEAM[pPlayer.entindex()] );
            //g_EngineFuncs.ServerPrint( "-- DEBUG -- Player: " + pPlayer.pev.netname + " with targetname: " + pPlayer.GetTargetname() + " in slot: " + pPlayer.entindex() + " was assigned to team: " + I_PLAYER_TEAM[pPlayer.entindex()] + "\n" );
        }
    }

    void SpawnProtection(CBasePlayer@ pPlayer)
    {
        if( pPlayer !is null && pPlayer.m_iClassSelection != 0 )
        {
            pPlayer.pev.flags       |= FL_FROZEN;
            pPlayer.pev.takedamage  = DAMAGE_NO;
        }

        g_Scheduler.SetTimeout( this, "ProtectionOff", g_ProtectDuration.GetFloat(), EHandle( pPlayer ) );
        // For some retarded reason the render settings don't work instantly so had to delay it a tiny bit after PlayerSpawn
        g_Scheduler.SetTimeout( this, "RenderGhost", 0.01f, EHandle( pPlayer ) );
    }
    
    void RenderGhost(EHandle hPlayer)
    {
        if( !hPlayer )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        pPlayer.pev.rendermode  = kRenderTransTexture;
        if( pPlayer.m_iClassSelection != 0){ pPlayer.pev.renderamt = 50.0f; }
        else
            pPlayer.pev.renderamt = 0.0f;
    }

    void ProtectionOff(EHandle hPlayer)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer.m_iClassSelection != 0 )
        {
            pPlayer.pev.flags       &= ~FL_FROZEN;
            pPlayer.pev.takedamage  = DAMAGE_YES;
            pPlayer.pev.rendermode  = kRenderNormal;
            pPlayer.pev.renderamt   = 255.0f;
        }
    }

    void EnterSpectator(CBasePlayer@ pPlayer)
    {
        if( pPlayer is null || !pPlayer.IsConnected() )
		    return;
		// Players not assigned to a team immediately get moved to observer mode
        if( !pPlayer.GetObserver().IsObserver() && pPlayer.m_iClassSelection == 0 )
        {
            pPlayer.GetObserver().StartObserver( pPlayer.GetOrigin(), pPlayer.pev.angles, false );
            pPlayer.GetObserver().SetObserverModeControlEnabled( true );
            pPlayer.RemoveAllItems( true );
            g_PlayerFuncs.SayText( pPlayer, "SPECTATING: No player slots available. Please wait until the end of the round." );
            //g_EngineFuncs.ServerPrint( "-- DEBUG -- Player: " + pPlayer.pev.netname + " with targetname: " + pPlayer.GetTargetname() + " in slot: " + pPlayer.entindex() + " was moved into Spectator (no free player slots available\n" );
        }

        EHandle hPlayer = pPlayer;
        // Stupid hax needed to set the respawn delay, triggering directly in the block does not work
        g_Scheduler.SetTimeout( this, "NoRespawn", 0.1f, hPlayer );
    }
    // "Disables" respawning of players in Spectator Mode (just making the respawn delay stupid long)
    void NoRespawn(EHandle hPlayer)
    {
        if( !hPlayer )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer.m_iClassSelection == 0 )
        { 
            pPlayer.m_flRespawnDelayTime = Math.FLOAT_MAX;
            pPlayer.RemoveAllItems( true );
        }
        // Just to make sure the respawn delay never counts down, keep updating the time in a loop
        g_Scheduler.SetTimeout( this, "NoRespawn", 1.0f, hPlayer );
    }

    void ViewMode(CBasePlayer@ pPlayer)
    {
        if( pPlayer !is null && pPlayer.IsConnected() )
            pPlayer.SetViewMode( ViewMode_FirstPerson );
    }
}
/* Special thanks to 
- AnggaraNothing, Zode, Neo and H2 for scripting help
AlexCorruptor for testing and building a test map*/