/* Script for enabling friendly fire between players for pvp deathmatch maps
Only supports 14 players maximum because of limitations imposed by the game + API.
Ensure the server has only 14 player slots available or some players will spawn outside the map and unable to play.

Use as include in a map script or directly via map cfg.
-Outerbeast */

PvpMode@ g_pvpmode = @PvpMode();

const bool _IS_ONPLAYERSPAWN_HOOK_REGISTERED = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PvpOnPlayerSpawn );

HookReturnCode PvpOnPlayerSpawn(CBasePlayer@ pPlayer)
{
	return g_pvpmode.OnPlayerSpawn( pPlayer );
}

final class PvpMode
{
    CCVar@ g_ProtectDuration;
    
    array<uint> PLAYER_TEAM = { 1, 2, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 99 };

    PvpMode()
    {
        PLAYER_TEAM.resize(32);
        @g_ProtectDuration = CCVar("protectduration", 5.0f, "Duration of spawn invulnerability", ConCommandFlag::AdminOnly);
    }

    HookReturnCode OnPlayerSpawn(CBasePlayer @pPlr)
    {   
        if( pPlr is null ){ return HOOK_CONTINUE; }

        AssignTeam();
        SpawnProtection( pPlr );
        return HOOK_CONTINUE;
    }

    void AssignTeam()
    {
        for( int playerID = 1; playerID <= g_Engine.maxClients; ++playerID )
        {
            CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
            CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );

            if( pPlayer !is null && pPlayer.IsAlive() )
            {
                pPlayer.pev.targetname = "dm_plyr_" + playerID;
                pPlayer.SetClassification( PLAYER_TEAM[playerID-1] );
                g_EngineFuncs.ServerPrint( "-- Player: " + pPlayer.pev.netname + " with targetname: " + pPlayer.GetTargetname() + " in slot: " + ( playerID ) + " was assigned to team: " + PLAYER_TEAM[playerID-1] + "\n" );

                if( pPlayer.m_iClassSelection == 0 )
                {
                    pPlayer.pev.origin.z    = 1000.0f;
                    pPlayer.pev.angles.x    = 90.0f;
                    pPlayer.RemoveAllItems( true );
                    g_PlayerFuncs.ShowMessage( pPlayer, "SPECTATING" + "\n\n" + "No player slots available. Please wait until the end of the round." );
                    g_EngineFuncs.ServerPrint( "-- Player: " + pPlayer.pev.netname + " with targetname: " + pPlayer.GetTargetname() + " in slot: " + ( playerID ) + " is Spectating (no free player slots available!)\n" );
                }
            }
        }
    }

    void SpawnProtection(CBasePlayer@ pPlayer)
    {
        if( pPlayer !is null )
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
        CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);

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
        CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);

        if( pPlayer.m_iClassSelection != 0 )
        {
            pPlayer.pev.flags       &= ~FL_FROZEN;
            pPlayer.pev.takedamage  = DAMAGE_YES;
            pPlayer.pev.rendermode  = kRenderNormal;
            pPlayer.pev.renderamt   = 255.0f;
        }
    }

}

/* Special thanks to 
- AnggaraNothing, Zode and H2 for scripting help
AlexCorruptor for testing and building a test map*/
