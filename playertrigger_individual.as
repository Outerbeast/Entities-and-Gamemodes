/* playertrigger_individual
Extension for trigger_once/multiple/func_button
Individual players interacting with triggers can only use them once, never again, allowing other players to use them.

Install:-
Put the script file into "scripts/maps/beast" then either
- put "map_script playertrigger_individual" to your map cfg
OR
-Add this as a trigger_script
"classname" "trigger_script"
"m_iszScriptFile" "playertrigger_individual"
OR
-Include it in your main map script header
#include "beast/playertrigger_individual"

Usage:-
Simply check the 8th flag box (value is 128) in your trigger_multiple/func_button to enable this feature for that entity.
You can also create a standalone trigger_script entity using "PLAYERTRIGGER_INDIVIDUAL::TriggerIndividual" as your "m_iszScriptFunctionName"
and have your entity trigger this - the main entity must have the key "$s_indiv_target" with the target entity for the value
*/
namespace PLAYERTRIGGER_INDIVIDUAL
{

string strEntitiesSupported = "trigger_multiple;func_button";

CScheduledFunction@ fnPatchTriggers = g_Scheduler.SetTimeout( "PatchTriggers", 0.1f );

void PatchTriggers()
{
    dictionary dictTrigger =
    {
        { "m_iszScriptFunctionName", "PLAYERTRIGGER_INDIVIDUAL::TriggerIndividual" },
        { "m_iMode", "1" },
        { "targetname", "ts_PLAYERTRIGGER_INDIVIDUAL" }
    };

    array<CBaseEntity@> P_TRIGGERS( g_EngineFuncs.NumberOfEntities() );
    const Vector vecAbsMin = Vector( -WORLD_BOUNDARY, -WORLD_BOUNDARY, -WORLD_BOUNDARY ), vecAbsMax = Vector( WORLD_BOUNDARY, WORLD_BOUNDARY, WORLD_BOUNDARY );

    if( g_EntityFuncs.BrushEntsInBox( @P_TRIGGERS, vecAbsMin, vecAbsMax ) <= 0 )
        return;

    for( uint i = 0; i < P_TRIGGERS.length(); i++ )
    {
        CBaseToggle@ pEntity = cast<CBaseToggle@>( P_TRIGGERS[i] );

        if( pEntity is null || strEntitiesSupported.Find( pEntity.GetClassname() ) == String::INVALID_INDEX )
            continue;

        if( !pEntity.pev.SpawnFlagBitSet( 1 << 7 ) )
            continue;

        pEntity.GetUserData()["player_ids"] = array<string>( 1 );
        pEntity.GetUserData()["target"] = "" + pEntity.pev.target;
        g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "$s_indiv_target", "" + pEntity.pev.target );
        pEntity.pev.target = string( dictTrigger["targetname"] );
    }

    g_EntityFuncs.CreateEntity( "trigger_script", dictTrigger );
}

void TriggerIndividual(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( pActivator is null || pCaller is null )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
    array<string> STR_PLAYER_IDS = cast<array<string>>( pCaller.GetUserData( "player_ids" ) );

    if( pPlayer is null || STR_PLAYER_IDS.find( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) ) >= 0 )
        return;

    string strTarget = string( pCaller.GetUserData( "target" ) );
    const float flDelay = cast<CBaseToggle@>( pCaller ) is null ? 0.0f : cast<CBaseToggle@>( pCaller ).m_flDelay;

    if( strTarget == "" )
    {
        CustomKeyvalues@ kvCaller = pCaller.GetCustomKeyvalues();

        if( kvCaller !is null && kvCaller.HasKeyvalue( "$s_indiv_target" ) )
            strTarget = kvCaller.GetKeyvalue( "$s_indiv_target" ).GetString();
    }

    g_EntityFuncs.FireTargets( strTarget, pActivator, pCaller, useType, flValue, flDelay );
    STR_PLAYER_IDS.insertLast( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) );
    pCaller.GetUserData( "player_ids" ) = STR_PLAYER_IDS;
}

}
