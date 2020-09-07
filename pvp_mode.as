/* Script for enabling friendly fire between players for pvp deathmatch maps
Only supports 14 players maximum because of limitations.
Ensure the server has only 14 player slots available or your map as logic to account for extra players.

Use as include in a map script or directly via map cfg.
-Outerbeast */

array<uint> PLAYER_TEAM = { 1, 2, 4, 5, 6, 7, 8, 9, 10, 12, 13, 14, 15, 99 };

void MapInit()
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @OnPlayerSpawn );

    g_EngineFuncs.CVarSetFloat( "mp_disable_autoclimb", 1 );
    g_EngineFuncs.CVarSetFloat( "mp_monsterpoints", 1 );
    g_EngineFuncs.CVarSetFloat( "mp_respawndelay", 0 );
    g_EngineFuncs.CVarSetFloat( "mp_multiplespawn", 1 );
    g_EngineFuncs.CVarSetFloat( "mp_allowmonsterinfo", 1 );
}

HookReturnCode OnPlayerSpawn( CBasePlayer @pPlr )
{
    AssignTeam();
    SpawnProtection(pPlr);
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
            g_EngineFuncs.ServerPrint( "-- Player: " + pPlayer.pev.netname + " in slot: " + ( playerID ) +" was assigned to team: " + PLAYER_TEAM[playerID-1] + "\n");
        }
    }
}

void SpawnProtection(CBasePlayer@ pPlayer)
{
    if( pPlayer !is null )
    {
        pPlayer.pev.flags       |= FL_FROZEN;
        pPlayer.pev.takedamage  = DAMAGE_NO;
        // For some retarded reason the render settings don't work
        pPlayer.pev.rendermode  = kRenderTransTexture;
        pPlayer.pev.renderamt   = 50.0f;
    }

    EHandle ePlayer = pPlayer;
    g_Scheduler.SetTimeout( "ProtectionOff", 5.0f, ePlayer );
}

void ProtectionOff(EHandle ePlayer)
{
    if( !ePlayer )
        return;
            
    CBaseEntity@ pEnt = ePlayer;
    CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);

    pPlayer.pev.flags       &= ~FL_FROZEN;
    pPlayer.pev.takedamage  = DAMAGE_YES;
    // For some retarded reason the render settings don't work
    pPlayer.pev.rendermode  = kRenderNormal;
    pPlayer.pev.renderamt   = 255.0f;
}

/* Special thanks to 
- Zode and H2 for scripting help
AlexCorruptor for testing*/