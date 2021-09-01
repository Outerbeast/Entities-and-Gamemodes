/* trigger_script for changing player solidity inside a custom zone
Players leaving the zone will have their solidity reset back to default (SOLID_SLIDEBOX)
-Outerbeast

Template entity:-
"classname" "trigger_script"
"m_iszScriptFile" "changesolid_zone"
"m_iszScriptFunctionName" "changesolid_zone::ChangeSolid"
"m_iMode" "2"
// Don't change any of the above! //
"$v_mins" "x1 y1 z1" - absmin bound coord
"$v_maxs" "x2 y2 z2" - absmax bound coord
"solid" "0" - New solid value- this is 0 by default if not set
*/
namespace CHANGESOLID_ZONE
{

void ChangeSolid(CBaseEntity@ pTriggerScript)
{
    Vector vecAbsMin, vecAbsMax;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    int iSolidSetting = Math.clamp( SOLID_NOT_EXPLICIT, SOLID_BSP, pTriggerScript.pev.solid );

    if( kvTriggerScript.HasKeyvalue( "$v_mins" ) && kvTriggerScript.HasKeyvalue( "$v_maxs" ) )
    {
        vecAbsMin = kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector();
        vecAbsMax = kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector();
    }
    else
        return;

    if( vecAbsMin == vecAbsMax )
        return;

    for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;
        
        bool blInBounds = CheckInBounds( EHandle( pPlayer ), vecAbsMin, vecAbsMax );

        if( blInBounds && pPlayer.pev.solid != iSolidSetting )
            pPlayer.pev.solid = iSolidSetting;
        else if( !blInBounds && pPlayer.pev.solid == iSolidSetting )
            pPlayer.pev.solid = SOLID_SLIDEBOX;
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
