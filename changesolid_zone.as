/* trigger_script for changing player solidity inside a custom zone
Players leaving the zone will have their solidity reset back to default (SOLID_SLIDEBOX)
Players can still trigger brush entities that are touched ( trigger_once, trigger_multiple, etc. )
-Outerbeast

Template entity:-
"classname" "trigger_script"
"m_iszScriptFile" "changesolid_zone"
"m_iszScriptFunctionName" "changesolid_zone::ChangeSolid"
"m_iMode" "2"
// Don't change any of the above! //
"$s_brush" "*m" - use a brush model for bounds
"$f_radius" "r" - set radius for zone
"$v_mins" "x1 y1 z1" - absmin bound coord
"$v_maxs" "x2 y2 z2" - absmax bound coord
"solid" "0" - New solid value- this is 0 by default if not set
"netname" "player_targetname" - Filter for targetname: players with the same targetname as this netname only are effected (cant be inverted using flag 4)
"spawnflags" "f" - See "changsolidzone_flags" for options below
*/
namespace CHANGESOLID_ZONE
{

enum changsolidzone_flags
{
    START_ON                    = 1,
    DONT_FORCE_TRIGGER          = 2, // Disables nonsolid players interacting with trigger brush entities
    INVERT_TARGETNAME_FILTER    = 4 // Changes the netname to affect players NOT having the same targetname as this netname
}
// This simply patches nonsolid trigger touch accross the entire map ( "m_iszScriptFunctionName" "changesolid_zone::ChangeSolid" )
void TriggerTouchNonsolidFix(CBaseEntity@ pTriggerScript)
{
    for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;

        ForceTriggerTouch( EHandle( pPlayer ) );
    }
}

void ChangeSolid(CBaseEntity@ pTriggerScript)
{
    Vector vecAbsMin, vecAbsMax;

    CustomKeyvalues@ kvTriggerScript    = pTriggerScript.GetCustomKeyvalues();
    int iSolidSetting                   = Math.clamp( SOLID_NOT_EXPLICIT, SOLID_BSP, pTriggerScript.pev.solid );
    bool blBoundsChecked                = SetBounds( EHandle( pTriggerScript ), vecAbsMin, vecAbsMax );
    float flRadius                      = kvTriggerScript.HasKeyvalue( "$f_radius" ) ? kvTriggerScript.GetKeyvalue( "$f_radius" ).GetFloat() : 128.0f;

    for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;

        if( pTriggerScript.pev.netname != "" )
        {
            if( !pTriggerScript.pev.SpawnFlagBitSet( INVERT_TARGETNAME_FILTER ) && 
                pPlayer.GetTargetname() != pTriggerScript.pev.netname )
                continue;

            if( pTriggerScript.pev.SpawnFlagBitSet( INVERT_TARGETNAME_FILTER ) && 
                pPlayer.GetTargetname() == pTriggerScript.pev.netname )
                continue;
        }
        
        bool blInBounds;

        if( blBoundsChecked )
            blInBounds = CheckInBounds( EHandle( pPlayer ), vecAbsMin, vecAbsMax );
        else
            blInBounds = CheckInRadius( EHandle( pPlayer ), pTriggerScript.GetOrigin(), flRadius );

        if( blInBounds && pPlayer.pev.solid != iSolidSetting )
            pPlayer.pev.solid = iSolidSetting;
        else if( !blInBounds && pPlayer.pev.solid == iSolidSetting )
            pPlayer.pev.solid = SOLID_SLIDEBOX;

        if( pTriggerScript.pev.SpawnFlagBitSet( DONT_FORCE_TRIGGER ) || 
            !blBoundsChecked || 
            pPlayer.pev.solid != SOLID_NOT || 
            !CheckInBounds( EHandle( pPlayer ), vecAbsMin, vecAbsMax ) )
            continue;

        ForceTriggerTouch( pPlayer, vecAbsMin, vecAbsMax );
    }
}
// Brush entity "Touch()" doesn't call for non-solid entities. If any exist within the zone, force-trigger when player bbox intersects the brush entity
void ForceTriggerTouch(EHandle hPlayer, 
Vector vecAbsMin = Vector( -WORLD_BOUNDARY, -WORLD_BOUNDARY, -WORLD_BOUNDARY ), 
Vector vecAbsMax = Vector( WORLD_BOUNDARY, WORLD_BOUNDARY, WORLD_BOUNDARY ) )
{
    if( !hPlayer )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    if( pPlayer is null || pPlayer.pev.solid != SOLID_NOT )
        return;

    array<CBaseEntity@> P_BRUSHES( 256 );
    int iNumBrushes = g_EntityFuncs.BrushEntsInBox( @P_BRUSHES, vecAbsMin, vecAbsMax );

    for( uint i = 0; i < P_BRUSHES.length(); i++ )
    {
        if( P_BRUSHES[i] is null || P_BRUSHES[i].GetClassname().StartsWith( "func_" ) )
            continue;

        if( pPlayer.Intersects( P_BRUSHES[i] ) )
            P_BRUSHES[i].Touch( pPlayer );
    }
}

bool CheckInRadius(EHandle hPlayer, Vector vecOrigin, float flRadius)
{
    if( !hPlayer || flRadius <= 0 )
        return false;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    return( ( vecOrigin - pPlayer.pev.origin ).Length() <= flRadius );
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
