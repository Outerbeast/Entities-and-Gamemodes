/* Script for enabling friendly fire between players for pvp deathmatch
Only supports 14 players maximum- more than 14 players connected to the server may cause unwanted effects!

-Outerbeast */

array<string> player_classification = { "1", "2", "4", "5", "6", "7", "8", "9", "10", "12", "13", "14", "15", "99" };

void MapInit()
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @OnPlayerSpawn );
}

HookReturnCode OnPlayerSpawn( CBasePlayer @pPlr )
{
    PvpMode();
    return HOOK_CONTINUE;
}

void PvpMode()
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
