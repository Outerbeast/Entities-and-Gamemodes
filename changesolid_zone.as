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
};
// This simply patches nonsolid trigger touch accross the entire map ( "m_iszScriptFunctionName" "changesolid_zone::ChangeSolid" )
void TriggerTouchNonsolidFix(CBaseEntity@ pTriggerScript)
{
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

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
    bool blBoundsSet                    = SetBounds( EHandle( pTriggerScript ), vecAbsMin, vecAbsMax );
    float flRadius                      = kvTriggerScript.HasKeyvalue( "$f_radius" ) ? kvTriggerScript.GetKeyvalue( "$f_radius" ).GetFloat() : 128.0f;

    if( blBoundsSet )
    {
        pTriggerScript.pev.mins = vecAbsMin - pTriggerScript.GetOrigin();
        pTriggerScript.pev.maxs = vecAbsMax - pTriggerScript.GetOrigin();
        g_EntityFuncs.SetSize( pTriggerScript.pev, pTriggerScript.pev.mins, pTriggerScript.pev.maxs );
    }

    for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

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
        
        bool blInZone = blBoundsSet ? pPlayer.Intersects( pTriggerScript ) : EntityInRadius( EHandle( pPlayer ), pTriggerScript.GetOrigin(), flRadius );

        if( blInZone && pPlayer.pev.solid != iSolidSetting )
            pPlayer.pev.solid = iSolidSetting;
        else if( !blInZone && pPlayer.pev.solid == iSolidSetting )
            pPlayer.pev.solid = SOLID_SLIDEBOX;

        if( pTriggerScript.pev.SpawnFlagBitSet( DONT_FORCE_TRIGGER ) || 
            !blBoundsSet || 
            pPlayer.pev.solid != SOLID_NOT || 
            !pPlayer.Intersects( pTriggerScript ) )
            continue;

        ForceTriggerTouch( pPlayer, vecAbsMin, vecAbsMax );
    }
}
// Brush entity "Touch()" doesn't call for non-solid entities. If any exist within the zone, force-trigger when player bbox intersects the brush entity's bounding box
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
        if( P_BRUSHES[i] is null || P_BRUSHES[i].pev.solid != SOLID_TRIGGER )
            continue;

        if( pPlayer.Intersects( P_BRUSHES[i] ) )
            P_BRUSHES[i].Touch( pPlayer );
    }
}

	// Note to devs: add this as a CUtility method please!!!
bool EntityInRadius(EHandle hEntity, Vector vecOrigin, float flRadius)
{
	if( !hEntity || flRadius <= 0 )
		return false;

	return( ( vecOrigin - hEntity.GetEntity().pev.origin ).Length() <= flRadius );
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
