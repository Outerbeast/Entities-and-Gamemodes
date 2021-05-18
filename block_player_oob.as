/* trigger_script for blocking players from exiting or entering a custom zone
- Outerbeast

Template entity:-

"classname" "trigger_script"
"m_iszScriptFile" "block_player_oob"
"m_iszScriptFunctionName" "BLOCK_PLAYER_OOB::Trigger"
"m_iMode" "2"
// Don't change any of the above
"$v_mins" "x1 y1 z1
"$v_maxs" "x2 y2 z2"
"spawnflags" "f"

Flags:-

1: Start On
2: Block entry - Prevents players from entering a set zone
*/
namespace BLOCK_PLAYER_OOB
{

dictionary dictVecTriggerPlrOldOrigin;

EHandle Enable(Vector vMinIn, Vector vMaxIn, uint iBlockType)
{
    if( vMinIn == vMaxIn )
        return EHandle( null );

    dictionary oob =
    {
        { "m_iszScriptFunctionName", "BLOCK_PLAYER_OOB::Trigger" },
        { "m_iMode", "2" },
        { "spawnflags", "1" },
        { "$v_mins", "" + vMinIn.ToString() },
        { "$v_maxs", "" + vMaxIn.ToString() }
    };
    CBaseEntity@ pOoBInstance = g_EntityFuncs.CreateEntity( "trigger_script", oob, true );

    if( pOoBInstance !is null )
        return EHandle( pOoBInstance );
    else
        return EHandle( null );
}

void Trigger(CBaseEntity@ pTriggerScript)
{
    Vector vecAbsMin, vecAbsMax;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    if( kvTriggerScript.HasKeyvalue( "$v_mins" ) && kvTriggerScript.HasKeyvalue( "$v_maxs" ) )
    {
        vecAbsMin = kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector();
        vecAbsMax = kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector();
    }
    else
        return;

    if( vecAbsMin == vecAbsMax )
        return;

    uint entID = pTriggerScript.entindex();
    if( !dictVecTriggerPlrOldOrigin.exists( entID ) )
        dictVecTriggerPlrOldOrigin.set( entID, array<Vector>( g_Engine.maxClients + 1, g_vecZero ) );

    array<Vector>@ VEC_PLR_OLD_POS = cast<array<Vector>>( dictVecTriggerPlrOldOrigin[ entID ] );
    for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;

        bool isInBound = CheckInBounds( EHandle( pPlayer ), vecAbsMin, vecAbsMax );
        bool isFree = pTriggerScript.pev.SpawnFlagBitSet( 2 ) ? !isInBound : isInBound;

        if( isFree )
            VEC_PLR_OLD_POS[ playerID ] = pPlayer.GetOrigin();
        else
        {
            g_EntityFuncs.SetOrigin( pPlayer, VEC_PLR_OLD_POS[ playerID ] );
            pPlayer.pev.velocity = Vector( 0, 0, pPlayer.pev.velocity.z );
            //g_PlayerFuncs.SayText( pPlayer, "lol no skip 4 u xd" );
        }
    }
}

bool CheckInBounds(EHandle hPlayer, Vector vecAbsMin, Vector vecAbsMax)
{
    if( !hPlayer )
        return false;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    return ( pPlayer.GetOrigin().x >= vecAbsMin.x && pPlayer.GetOrigin().x <= vecAbsMax.x )
        && ( pPlayer.GetOrigin().y >= vecAbsMin.y && pPlayer.GetOrigin().y <= vecAbsMax.y )
        && ( pPlayer.GetOrigin().z >= vecAbsMin.z && pPlayer.GetOrigin().z <= vecAbsMax.z );
}

}
/* Special Thanks to AnggaraNothing for script fixes and improvements */