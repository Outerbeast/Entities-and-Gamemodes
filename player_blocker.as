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
    bool blBoundsSet = SetBounds( EHandle( pTriggerScript ), vecAbsMin, vecAbsMax );

    if( !blBoundsSet || vecAbsMin == vecAbsMax )
        return;

    if( blBoundsSet )
    {
        pTriggerScript.pev.mins = vecAbsMin - pTriggerScript.GetOrigin();
        pTriggerScript.pev.maxs = vecAbsMax - pTriggerScript.GetOrigin();
        g_EntityFuncs.SetSize( pTriggerScript.pev, pTriggerScript.pev.mins, pTriggerScript.pev.maxs );
    }

    if( !dictPlayerLastPosData.exists( pTriggerScript.entindex() ) )
        dictPlayerLastPosData.set( pTriggerScript.entindex(), array<Vector>( g_Engine.maxClients + 1, g_vecZero ) );

    array<Vector>@ VEC_PLAYER_LAST_POS = cast<array<Vector>>( dictPlayerLastPosData[pTriggerScript.entindex()] );
    
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;

        bool blIsFree = pTriggerScript.pev.SpawnFlagBitSet( 2 ) ? !pPlayer.Intersects( pTriggerScript ) : pPlayer.Intersects( pTriggerScript );

        if( blIsFree )
            VEC_PLAYER_LAST_POS[iPlayer] = pPlayer.GetOrigin();
        else
        {
            g_EntityFuncs.SetOrigin( pPlayer, VEC_PLAYER_LAST_POS[iPlayer] );
            pPlayer.pev.velocity.x = -1 * g_Engine.v_forward.x;
            pPlayer.pev.velocity.y = -1 * g_Engine.v_forward.y;
        }
    }
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
