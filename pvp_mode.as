/* Script for enabling friendly fire between players for pvp deathmatch maps
Only supports 14 players maximum because of limitations.
Ensure the server has only 14 player slots available or your map has logic to account for extra players.

Use as include in a map script or directly via map cfg.
-Outerbeast */

array<string> player_classification = { "1", "2", "4", "5", "6", "7", "8", "9", "10", "12", "13", "14", "15", "99" };

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
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; ++iPlayer )
    {
        CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );

        if( pPlayer !is null && pPlayer.IsAlive() )
        { 
            pPlayer.pev.targetname = "dm_plyr_" + iPlayer;

            dictionary keys;
            keys ["targetname"]     = ( "game_playerspawn" );
            keys ["target"]         = ( "dm_plyr_" + iPlayer );
            keys ["m_iszValueName"] = ( "classify" );
            keys ["m_iszValueType"] = ( "0" );
            keys ["m_iszNewValue"]  = ( player_classification[iPlayer-1] );

            CBaseEntity@ ChangeClass = g_EntityFuncs.CreateEntity( "trigger_changevalue", keys, true );
            ChangeClass.pev.nextthink;
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
    g_Scheduler.SetTimeout( "ProtectionOff", 5.0f, ePlayer );
}

void ProtectionOff(EHandle ePlayer)
{
    if(!ePlayer)
        return;
            
    CBaseEntity@ pEnt = ePlayer;
    CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);

    pPlayer.pev.flags       &= ~FL_FROZEN;
    pPlayer.pev.takedamage  = DAMAGE_YES;
}

/* Special thanks to 
- Zode and H2 for scripting help
AlexCorruptor for testing*/
