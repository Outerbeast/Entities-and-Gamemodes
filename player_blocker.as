/* trigger_script for blocking players from exiting or entering a custom zone
- Outerbeast

Template entity:-
"classname" "trigger_script"
"m_iszScriptFile" "player_blocker"
"m_iszScriptFunctionName" "PLAYER_BLOCKER::PlayerBlocker"
"m_iMode" "2"
// Don't change any of the above
"$s_brush" "*m"      - Brush model to provide bounds
"$v_mins" "x1 y1 z1" - absmin bound coord
"$v_maxs" "x2 y2 z2" - absmax bound coord
"spawnflags" "f" - see  "Flags" below

Flags:-
1: Start On
2: Block entry - Prevents players from entering a set zone
*/
namespace PLAYER_BLOCKER
{

dictionary dictPlayerLastPosData;

EHandle Enable(Vector vecAbsMinIn, Vector vecAbsMaxIn)
{
    if( vecAbsMinIn == vecAbsMaxIn )
        return EHandle( null );

    dictionary blocker =
    {
        { "m_iszScriptFunctionName", "PLAYER_BLOCKER::PlayerBlocker" },
        { "m_iMode", "2" },
        { "spawnflags", "1" },
        { "$v_mins", "" + vecAbsMinIn.ToString() },
        { "$v_maxs", "" + vecAbsMaxIn.ToString() }
    };

    return EHandle( g_EntityFuncs.CreateEntity( "trigger_script", blocker, true ) );
}

void PlayerBlocker(CBaseEntity@ pTriggerScript)
{
    Vector vecAbsMin, vecAbsMax;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    bool blBoundsChecked  = SetBounds( EHandle( pTriggerScript ), vecAbsMin, vecAbsMax );

    if( !blBoundsChecked || vecAbsMin == vecAbsMax )
        return;

    if( !dictPlayerLastPosData.exists( pTriggerScript.entindex() ) )
        dictPlayerLastPosData.set( pTriggerScript.entindex(), array<Vector>( g_Engine.maxClients + 1, g_vecZero ) );

    array<Vector>@ VEC_PLAYER_LAST_POS = cast<array<Vector>>( dictPlayerLastPosData[pTriggerScript.entindex()] );
    
    for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;

        bool blInBounds = CheckInBounds( EHandle( pPlayer ), vecAbsMin, vecAbsMax );
        bool blIsFree = pTriggerScript.pev.SpawnFlagBitSet( 2 ) ? !blInBounds : blInBounds;

        if( blIsFree )
            VEC_PLAYER_LAST_POS[playerID] = pPlayer.GetOrigin();
        else
        {
            g_EntityFuncs.SetOrigin( pPlayer, VEC_PLAYER_LAST_POS[playerID] );
            pPlayer.pev.velocity.x = -1 * g_Engine.v_forward.x;
            pPlayer.pev.velocity.y = -1 * g_Engine.v_forward.y;
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

bool SetBounds(EHandle hTriggerScript, Vector& out vecMin, Vector& out vecMax)
{
    if( !hTriggerScript )
        return false;

    CustomKeyvalues@ kvTriggerScript = hTriggerScript.GetEntity().GetCustomKeyvalues();

    if( kvTriggerScript.HasKeyvalue( "$s_brush" ) )
    {
        CBaseEntity@ pBBox = g_EntityFuncs.FindEntityByString( pBBox, "model", "" + kvTriggerScript.GetKeyvalue( "$s_brush" ).GetString() );

        if( pBBox !is null && pBBox.IsBSPModel() )
        {
            vecMin = pBBox.pev.absmin;
            vecMax = pBBox.pev.absmax;

            return true;
        }
        else
            return false;
    }
    else if( kvTriggerScript.HasKeyvalue( "$v_mins" ) && kvTriggerScript.HasKeyvalue( "$v_maxs" ) )
    {
        if( kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector() != kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector() )
        {
            vecMin = kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector();
            vecMax = kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector();

            return true;
        }
        else
            return false;
    }
    else
        return false;
}

}
