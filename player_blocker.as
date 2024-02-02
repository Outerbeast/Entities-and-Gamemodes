/* trigger_script for blocking players from exiting or entering a custom zone
- Outerbeast

Template entity:-
"classname" "trigger_script"
"m_iszScriptFile" "player_blocker"
"m_iszScriptFunctionName" "PLAYER_BLOCKER::PlayerBlocker"
"m_iMode" "2"
// Don't change any of the above
"$s_brush" "*m"                 - Brush model to provide bounds
"$v_mins" "x1 y1 z1"            - absmin bound coord
"$v_maxs" "x2 y2 z2"            - absmax bound coord
"netname" "player_targetname"   - Optional key to exclude named players from being blocked
"spawnflags" "f" - see  "Flags" below

Flags:-
1: Start On
2: Block entry - Prevents players from entering a set zone
*/
namespace PLAYER_BLOCKER
{

EHandle Enable(Vector vecAbsMinIn, Vector vecAbsMaxIn)
{
    if( vecAbsMinIn == vecAbsMaxIn )
        return EHandle();

    dictionary blocker =
    {
        { "m_iszScriptFunctionName", "PLAYER_BLOCKER::PlayerBlocker" },
        { "m_iMode", "2" },
        { "spawnflags", "1" },
        { "$v_mins", "" + vecAbsMinIn.ToString() },
        { "$v_maxs", "" + vecAbsMaxIn.ToString() }
    };

    return g_EntityFuncs.CreateEntity( "trigger_script", blocker, true );
}

void PlayerBlocker(CBaseEntity@ pTriggerScript)
{
    Vector vecAbsMin, vecAbsMax;
    EHandle hBrushModel;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    bool 
        blBoundsSet = SetBounds( pTriggerScript, vecAbsMin, vecAbsMax ),
        blBrushSet = SetBrushModel( pTriggerScript, hBrushModel );

    if( blBoundsSet )
    {
        pTriggerScript.pev.mins = vecAbsMin - pTriggerScript.GetOrigin();
        pTriggerScript.pev.maxs = vecAbsMax - pTriggerScript.GetOrigin();
        g_EntityFuncs.SetSize( pTriggerScript.pev, pTriggerScript.pev.mins, pTriggerScript.pev.maxs );
    }
    else if( !blBrushSet )
        return;
    
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        if( !pTriggerScript.GetUserData().exists( string( iPlayer ) ) )
            pTriggerScript.GetUserData()[string( iPlayer )] = g_vecZero;

        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
        {
            pTriggerScript.GetUserData( string( iPlayer ) ) = g_vecZero;
            continue;
        }

        if( pTriggerScript.pev.netname != "" && pPlayer.GetTargetname() == pTriggerScript.pev.netname )
            continue;

        const bool 
            blInZone = hBrushModel ? g_Utility.IsPlayerInVolume( pPlayer, hBrushModel.GetEntity() ) : pPlayer.Intersects( pTriggerScript ),
            blIsFree = pTriggerScript.pev.SpawnFlagBitSet( 1 << 1 ) ? !blInZone : blInZone;

        if( blIsFree )
            pTriggerScript.GetUserData( string( iPlayer ) ) = pPlayer.pev.origin;
        else
        {
            g_EntityFuncs.SetOrigin( pPlayer, Vector( pTriggerScript.GetUserData( string( iPlayer ) ) ) );
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

    if( kvTriggerScript.HasKeyvalue( "$v_mins" ) && kvTriggerScript.HasKeyvalue( "$v_maxs" ) )
    {
        if( kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector() != kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector() )
        {
            vecMin = kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector();
            vecMax = kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector();

            return vecMin != vecMax;
        }
        else
            return false;
    }
    else
        return false;
}

bool SetBrushModel(EHandle hTriggerScript, EHandle& out hBrushModel)
{
    if( !hTriggerScript )
        return false;

    CustomKeyvalues@ kvTriggerScript = hTriggerScript.GetEntity().GetCustomKeyvalues();

    if( kvTriggerScript.HasKeyvalue( "$s_brush" ) )
    {
        if( kvTriggerScript.GetKeyvalue( "$s_brush" ).GetString() == "" )
            return false;

        CBaseEntity@ pBBox = 
            kvTriggerScript.GetKeyvalue( "$s_brush" ).GetString()[0] == "*" ?
            g_EntityFuncs.FindEntityByString( pBBox, "model", kvTriggerScript.GetKeyvalue( "$s_brush" ).GetString() ) :
            g_EntityFuncs.FindEntityByTargetname( pBBox, kvTriggerScript.GetKeyvalue( "$s_brush" ).GetString() );

        if( pBBox !is null && pBBox.IsBSPModel() )
        {
            hBrushModel = pBBox;
            return hBrushModel.IsValid();
        }
        else
            return false;
    }
    else
        return false; 
}

}
