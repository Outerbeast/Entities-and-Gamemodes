/* percent_trigger_zone
by Outerbeast
Custom trigger zone with required percentage number of players to be in the zone to trigger
Trigger will fire its target once when the percentage condition is met then disable itself, requiring the trigger zone to be targeted to reenable it.
Can use a wait value to allow a trigger_multiple type use

Template entity:-
"classname" "trigger_script"
"m_iMode" "2"
"m_iszScriptFile" "beast/percent_trigger_zone"
"m_iszScriptFunctionName" "PERCENT_TRIGGER_ZONE::TriggerThink"
// Don't change any of the above! //
"targetname" "percent_trigger_zone"
"$s_brush" "*m"                 // Brush model to provide bounds.
"$v_mins" "x y z"               // Trigger zone box min origin
"$v_maxs" "x y z"               // Trigger zone box max origin
"$f_radius" "72"                // Trigger zone radius. Used if v_mins/maxs not set with the default value 512 units.
"$i_percentage" "66"            // Percentage of alive players required to trigger. Default is 66%. (Alernative key: "$f_percentage" followed by a fractional value can be used eg "0.66" to express the required percentage)
"message" "target_entity"       // Entity to trigger when the percentage condition is met
Optional keys:
"killtarget" "delete_entity"    // Entity to delete when the percentage condition is met
"$s_master" "multisource_name"  // Name of a multisource entity that can lock this trigger zone (I instead recommend enabling the trigger zone via direct targetname trigger)
"$f_delay"                      // Time in seconds before the trigger zone triggers "message" when percentage condition is met
"$f_wait" "t"                   // Time in seconds before the trigger zone can be used again after its triggered its "message".
"spawnflags" "1"                // Start On. If this flag is not set the entity needs to be triggered first to enable it.
*/
namespace PERCENT_TRIGGER_ZONE
{

void TriggerThink(CBaseEntity@ pTriggerScript)
{
    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();

    Vector vecAbsMin, vecAbsMax;
    const float flZoneRadius = kvTriggerScript.HasKeyvalue( "$f_radius" ) ? kvTriggerScript.GetKeyvalue( "$f_radius" ).GetFloat()  : 512.0f;
    const float flDelay      = kvTriggerScript.HasKeyvalue( "$f_delay" )  ? kvTriggerScript.GetKeyvalue( "$f_delay" ).GetFloat()   : 0.0f;
    const float flWait       = kvTriggerScript.HasKeyvalue( "$f_wait" )   ? kvTriggerScript.GetKeyvalue( "$f_wait" ).GetFloat()    : -1.0f;
    const string strMaster   = kvTriggerScript.HasKeyvalue( "$s_master" ) ? kvTriggerScript.GetKeyvalue( "$s_master" ).GetString() : "";
    
    float flPercentage = pTriggerScript.pev.frame = kvTriggerScript.HasKeyvalue( "$f_percentage" ) ? 
                            kvTriggerScript.GetKeyvalue( "$f_percentage" ).GetFloat() : 
                            ( kvTriggerScript.HasKeyvalue( "$i_percentage" ) ? float( kvTriggerScript.GetKeyvalue( "$i_percentage" ).GetInteger() ) / 100.0f : 0.66 );

    if( !g_EntityFuncs.IsMasterTriggered( strMaster, null ) )
        return;

    bool blBoundsSet = SetBounds( pTriggerScript, vecAbsMin, vecAbsMax ) && vecAbsMin != vecAbsMax;

    if( blBoundsSet )
    {
        pTriggerScript.pev.mins = vecAbsMin - pTriggerScript.GetOrigin();
        pTriggerScript.pev.maxs = vecAbsMax - pTriggerScript.GetOrigin();
        g_EntityFuncs.SetSize( pTriggerScript.pev, pTriggerScript.pev.mins, pTriggerScript.pev.maxs );
    }

    if( flPercentage <= 0.0f || flPercentage > 100.0f )
        flPercentage = 0.01f;

    uint iPlayersAlive = 0, iPlayersInZone = 0;

    for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
        
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;
        
        ++iPlayersAlive;

        if( blBoundsSet )
        {
            if( pPlayer.Intersects( pTriggerScript ) )
                ++iPlayersInZone;
        }
        else
        {
            if( EntityInRadius( pPlayer, pTriggerScript.GetOrigin(), flZoneRadius ) && pTriggerScript.FVisibleFromPos( pPlayer.pev.origin, pTriggerScript.pev.origin ) )
                ++iPlayersInZone;
        }
    }
    
    if( iPlayersAlive >= 1 )
    {
        const float flCurrentPercent = float( iPlayersInZone ) / float( iPlayersAlive ) + 0.00001f;

        if( flCurrentPercent >= flPercentage )
        {
            g_EntityFuncs.FireTargets( "" + pTriggerScript.pev.message, pTriggerScript, pTriggerScript, USE_TOGGLE, 0.0f, cast<CBaseDelay@>( pTriggerScript ).m_flDelay );
            KillTarget( cast<CBaseDelay@>( pTriggerScript ).m_iszKillTarget, cast<CBaseDelay@>( pTriggerScript ).m_flDelay );

            if( flWait > 0.0f )
                pTriggerScript.pev.nextthink = g_Engine.time + flWait;
            else
                pTriggerScript.Use( pTriggerScript, pTriggerScript, USE_OFF, 0.0f );
        }
    }
}

void KillTarget(string strTargetname, float flDelay)
{
    if( flDelay > 0.0f )
    {
        g_Scheduler.SetTimeout( "KillTarget", flDelay, strTargetname, 0.0f );
        return;
    }
    
    do( g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, strTargetname ) ) );
    while( g_EntityFuncs.FindEntityByTargetname( null, strTargetname ) !is null );
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
