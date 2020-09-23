/* Script for enabling friendly fire between players for pvp deathmatch maps
Only supports 14 players maximum because of limitations imposed by the game + API.
Ensure the server has only 14 player slots available or extra players will be moved onto Observer Mode
Use as include in a map script or directly via map cfg.
Map cfg settings:
as_command pvp_spawnprotecttime - set the time duraion in seconds for how long spawn invulnerbility lasts
by default this is 5 if let undefined
-Outerbeast */

PvpMode@ g_pvpmode = @PvpMode();

CCVar g_ProtectDuration( "pvp_spawnprotecttime", 5.0f, "Duration of spawn invulnerability", ConCommandFlag::AdminOnly );

const bool _IS_ONPLAYERSPAWN_HOOK_REGISTERED = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PvpOnPlayerSpawn );

HookReturnCode PvpOnPlayerSpawn(CBasePlayer@ pPlayer)
{
    return g_pvpmode.OnPlayerSpawn( pPlayer );
}


final class PvpMode
{
    array<uint> PLAYER_TEAM = { 1, 2, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 99 };
    array<bool> _IS_ASSIGNED(33);

    PvpMode()
    {
        PLAYER_TEAM.resize(33);
    }

    HookReturnCode OnPlayerSpawn(CBasePlayer @pPlr)
    {   
        if( pPlr is null ){ return HOOK_CONTINUE; }

        AssignTeam();
        SpawnProtection( pPlr );
        EnterSpectator( pPlr );
        g_Scheduler.SetInterval( this, "ViewMode", 0.1f, -1, @pPlr ); //  Have to constantly keep updating the viewmode since it doesn't persist hence the scheduler
        return HOOK_CONTINUE;
    }

    void AssignTeam()
    {
        for( int playerID = 1; playerID <= g_Engine.maxClients; ++playerID )
        {
            CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
            CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );

            if( pPlayer !is null && pPlayer.IsAlive() && !_IS_ASSIGNED[playerID] )
            {
                pPlayer.SetClassification( PLAYER_TEAM[playerID-1] );
                _IS_ASSIGNED[playerID] = true;
                //pPlayer.pev.targetname = "dm_plyr_" + playerID;
                //g_EngineFuncs.ServerPrint( "-- DEBUG -- Player: " + pPlayer.pev.netname + " with targetname: " + pPlayer.GetTargetname() + " in slot: " + playerID + " was assigned to team: " + PLAYER_TEAM[playerID-1] + "\n" );
            }
            else
                continue;
        }
    }

    void SpawnProtection(CBasePlayer@ pPlayer)
    {
        if( pPlayer !is null && pPlayer.m_iClassSelection != 0 )
        {
            pPlayer.pev.flags       |= FL_FROZEN;
            pPlayer.pev.takedamage  = DAMAGE_NO;
        }

        EHandle ePlayer = pPlayer;
        g_Scheduler.SetTimeout( this, "ProtectionOff", g_ProtectDuration.GetFloat(), ePlayer );
        // For some retarded reason the render settings don't work instantly so had to delay it a tiny bit after PlayerSpawn
        g_Scheduler.SetTimeout( this, "RenderGhost", 0.01f, ePlayer );
    }
    
    void RenderGhost(EHandle ePlayer)
    {
        if( !ePlayer )
            return;
                
        CBaseEntity@ pEnt = ePlayer;
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEnt );

        pPlayer.pev.rendermode  = kRenderTransTexture;
        if( pPlayer.m_iClassSelection != 0){ pPlayer.pev.renderamt = 50.0f; }
        else
            pPlayer.pev.renderamt = 0.0f;
    }

    void ProtectionOff(EHandle ePlayer)
    {
        if( !ePlayer )
            return;
                
        CBaseEntity@ pEnt = ePlayer;
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEnt );

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
	    if( pPlayer is null )
		    return;
        if( !pPlayer.IsConnected() )
		    return;
		// Players not assigned to a team immediately get moved to observer mode
		if( !pPlayer.GetObserver().IsObserver() && pPlayer.m_iClassSelection == 0 )
		{
		    pPlayer.GetObserver().StartObserver( pPlayer.pev.origin, pPlayer.pev.angles, false );
            pPlayer.GetObserver().SetObserverModeControlEnabled( true );
            pPlayer.RemoveAllItems( true );
            g_PlayerFuncs.SayText( pPlayer, "SPECTATING: No player slots available. Please wait until the end of the round." );
            //g_EngineFuncs.ServerPrint( "-- DEBUG -- Player: " + pPlayer.pev.netname + " with targetname: " + pPlayer.GetTargetname() + " was moved into Spectator (no free player slots available\n" );
		}

        EHandle ePlayer = pPlayer;
        // Stupid hax needed to set the respawn delay, triggering directly in the block does not work
        g_Scheduler.SetTimeout( this, "NoRespawn", 0.1f, ePlayer );
	}
    // "Disables" respawning of players in Spectator Mode (just making the respawn delay stupid long)
    void NoRespawn(EHandle ePlayer)
    {
        if( !ePlayer )
            return;

        CBaseEntity@ pEnt = ePlayer;
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEnt );

        if( pPlayer.m_iClassSelection == 0 )
        { 
            pPlayer.m_flRespawnDelayTime = Math.FLOAT_MAX;
            pPlayer.RemoveAllItems( true );
        }
        // Just to make sure the respawn delay never counts down, keep updating the time in a loop
        g_Scheduler.SetTimeout( this, "NoRespawn", 1.0f, ePlayer );
    }

    void ViewMode(CBasePlayer@ pPlayer)
    {
        if( pPlayer !is null && pPlayer.IsConnected() )
        {
            pPlayer.SetViewMode( ViewMode_FirstPerson );
        }
    }
}

/* Special thanks to 
- AnggaraNothing, Zode, Neo and H2 for scripting help
AlexCorruptor for testing and building a test map*/