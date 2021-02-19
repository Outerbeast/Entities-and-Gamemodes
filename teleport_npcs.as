/* trigger_scripts for teleporting npcs because trigger_teleport Monsters flag is broken
Teleports are "relative"
-Outerbeast

Template entities:-
{
"origin" "x1 y1 z1" // Starting position
"targetname" "store_transition_npcs"
"m_iszScriptFile" "teleport_npcs"
"m_iszScriptFunctionName" "StoreNpcs"
"m_iMode" "2"
"m_flThinkDelta" "1"
"$f_range" "72" // search radius
"classname" "trigger_script"
}
{
"origin" "x2 y2 z2" // Ending position
"targetname" "transition_stored_npcs"
"m_iszScriptFile" "teleport_npcs"
"m_iszScriptFunctionName" "TransportNpcs"
"m_iMode" "2"
"classname" "trigger_script"
"m_flThinkDelta" "1"
}
*/
array<EHandle> H_STORED_NPCS;
Vector g_vStartPos, g_vEndPos;

void StoreNpcs(CBaseEntity@ pTriggerScript)
{
    g_vStartPos = pTriggerScript.GetOrigin();
    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    float flSearchRange = kvTriggerScript.GetKeyvalue("$f_range").Exists() ? kvTriggerScript.GetKeyvalue("$f_range").GetFloat() : 128.0f;
    Vector vecTemp( flSearchRange/2.f, flSearchRange/2.f, flSearchRange/2.f );
    g_EngineFuncs.ServerPrint( "-- DEBUG: Triggered StoreNpcs script: " + pTriggerScript.GetTargetname() + " at origin " + g_vStartPos.ToString() + " with search range " + flSearchRange + "\n" );

    array<CBaseEntity@> P_ENTITIES_IN_BOX( 256 );
    const int iNumEntitiesInBox = g_EntityFuncs.EntitiesInBox( @P_ENTITIES_IN_BOX, g_vStartPos - vecTemp, g_vStartPos + vecTemp, FL_MONSTER );

    for( int i = 0; i < iNumEntitiesInBox; i++ )
    {
        CBaseEntity@ pCurrentEnt = @P_ENTITIES_IN_BOX[i];
        if( pCurrentEnt is null )
            continue;

        H_STORED_NPCS.insertLast( EHandle( pCurrentEnt) );
        g_EngineFuncs.ServerPrint( "-- DEBUG: StoreNpcs() Stored Npcs " + pCurrentEnt.GetClassname() + "\n" );
    }
    g_EntityFuncs.FireTargets( pTriggerScript.GetTargetname(), pTriggerScript, pTriggerScript, USE_OFF, 0.0f, 0.0f );
}

void TransportNpcs(CBaseEntity@ pTriggerScript)
{
    g_vEndPos = pTriggerScript.GetOrigin();
    g_EngineFuncs.ServerPrint( "-- DEBUG: Triggered TransportNpcs script: " + pTriggerScript.GetTargetname() + " in " + g_vEndPos.ToString()  + " with " + H_STORED_NPCS.length() + "\n" );

    for( uint i = 0; i < H_STORED_NPCS.length(); i++ )
    {
        if( !H_STORED_NPCS[i] )
            continue;

        H_STORED_NPCS[i].GetEntity().pev.origin = H_STORED_NPCS[i].GetEntity().GetOrigin() + ( g_vEndPos - g_vStartPos ) + Vector( 0, 0, 36 );
        g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs script teleported: " + H_STORED_NPCS[i].GetEntity().GetClassname() + " to end point: " + g_vEndPos.ToString() + " - New origin: " + H_STORED_NPCS[i].GetEntity().GetOrigin().ToString() + "\n" );
    }
    g_EntityFuncs.FireTargets( pTriggerScript.GetTargetname(), pTriggerScript, pTriggerScript, USE_OFF, 0.0f, 0.0f );
}
