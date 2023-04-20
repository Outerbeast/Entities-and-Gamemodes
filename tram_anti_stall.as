/* tram_anti_stall - trigger_script to prevent players from blocking trams or escaping them
    wWen a player blocks the tram from moving or has ended up outside somehow, that player will automatically be respawned.
    Ensure a moving spawn point has been made inside the tram.
    - Outerbeast
    Template entity:-
    "classname" "trigger_script"
    "m_iMode" "2"
    "m_iszScriptFunctionName" "TRAM_ANTI_STALL::TramThink"
    // Don't change any of the above!
    "targetname" "tram_anti_stall" - Trigger this to start
    "netname" "tram" - Targetname of tram to prevent stalling
    "vuser1" "x y z" - offset for the tram spawn point

    Flags: see "tram_anti_stall_flags" below for flags
*/
namespace TRAM_ANTI_STALL
{

enum tramantistall_flags
{
    START_ACTIVE         = 1, // Starts on
    DONT_CHECK_BLOCKING  = 8, // Skips checking players blocking
    DONT_CHECK_OUTSIDE   = 16,// Skips checking  players escaped
    TRAM_SPAWN           = 32 // Uses the tram as a spawn point
};

void TramThink(CBaseEntity@ pTriggerScript)
{
    const string strTramName = pTriggerScript !is null ? string( pTriggerScript.pev.netname ) : "";
    const bool
        blCheckPlayerBlocking = !pTriggerScript.pev.SpawnFlagBitSet( DONT_CHECK_BLOCKING ),
        blCheckPlayerOutside = !pTriggerScript.pev.SpawnFlagBitSet( DONT_CHECK_OUTSIDE );

    if( strTramName == "" )
        return;

    CBaseEntity@ pTram = g_EntityFuncs.FindEntityByTargetname( pTram, strTramName );

    if( pTram is null )
        return;

    if( blCheckPlayerBlocking && pTram.pev.dmg <= 0.0f )
        pTram.pev.dmg = 1.0f;

    Vector vecOffset = Vector( 0, 0, 36 );
    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();

    if( kvTriggerScript !is null && kvTriggerScript.HasKeyvalue( "$v_offset" ) )
        vecOffset = kvTriggerScript.GetKeyvalue( "$v_offset" ).GetVector();

    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
    
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;

        if( !( ( blCheckPlayerOutside && !pPlayer.Intersects( pTram ) ) || 
            ( blCheckPlayerBlocking && pPlayer.pev.dmg_inflictor is pTram.edict() ) ) )
            continue;

        @pPlayer.pev.dmg_inflictor = null;
        g_PlayerFuncs.RespawnPlayer( pPlayer );

        if( pTriggerScript.pev.SpawnFlagBitSet( TRAM_SPAWN ) )
        {
            g_EntityFuncs.SetOrigin( pPlayer, pTram.Center() + vecOffset );
            pPlayer.pev.angles.y = -pTram.pev.angles.y;
        }
    }
}

}
