/* trigger_script for teleporting npcs because trigger_teleport Monsters flag is broken
Teleports are "relative"
-Outerbeast

Template entity:-

"classname" "trigger_script"
"m_iszScriptFile" "transport_npcs"
"m_iszScriptFunctionName" "TransportNpcs"
"m_iMode" "2"
"m_flThinkDelta" "1"
"targetname" "transport_npcs"
"origin" "x1 y1 z1" // Starting position
"angles" "p y r" // custom angles
"$v_destination" "x2 y2 z2"
"$f_range" "72" // search radius
"$v_mins" "x y z" // box min origin
"$v_maxs" "x y z" // box max origin

*/
void TransportNpcs(CBaseEntity@ pTriggerScript)
{
    array<CBaseEntity@> P_ENTITIES( 64 );
    int iNumEntities;
    Vector vStartPos, vEndPos;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    float flSearchRange = kvTriggerScript.GetKeyvalue( "$f_range" ).Exists() ? kvTriggerScript.GetKeyvalue("$f_range").GetFloat() : 128.0f;
    vStartPos = pTriggerScript.GetOrigin();

    CBaseEntity@ pDestination = g_EntityFuncs.FindEntityByTargetname( pDestination, "" + pTriggerScript.pev.target );
    if( kvTriggerScript.GetKeyvalue( "$v_destination" ).Exists() )
        vEndPos = kvTriggerScript.GetKeyvalue( "$v_destination" ).GetVector();
    else if( pDestination !is null && pDestination !is pTriggerScript )
        vEndPos = pDestination.GetOrigin();
    else
        return;

    g_EngineFuncs.ServerPrint( "-- DEBUG: Triggered TransportNpcs script: " + pTriggerScript.GetTargetname() + " at start position " + vStartPos.ToString() + " and destination position " + vEndPos.ToString() + "\n" );
    

    if( kvTriggerScript.GetKeyvalue( "$v_mins" ).Exists() && kvTriggerScript.GetKeyvalue( "$v_maxs" ).Exists() )
    {
        if( kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector() != kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector() )
        {
            iNumEntities = g_EntityFuncs.EntitiesInBox( @P_ENTITIES, kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector(), kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector(), FL_MONSTER );
            g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs script: " + pTriggerScript.GetTargetname() + " is transporting entities in box with bounds: Min- " + kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector().ToString() + " - Max- " + kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector().ToString() + "\n" );
        }
    }
    else
        iNumEntities = g_EntityFuncs.MonstersInSphere( @P_ENTITIES, vStartPos, flSearchRange );

    for( int i = 0; i < iNumEntities; i++ )
    {
        if( P_ENTITIES[i] is null || P_ENTITIES[i].IsPlayer() )
            continue;

        P_ENTITIES[i].pev.origin = P_ENTITIES[i].GetOrigin() + ( vEndPos - vStartPos ) + Vector( 0, 0, 36 );
        P_ENTITIES[i].pev.angles = P_ENTITIES[i].pev.angles + pTriggerScript.pev.angles;

        g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs Script teleported entity " + P_ENTITIES[i].GetClassname() + " to end point: " + vEndPos.ToString() + " - New origin: " + P_ENTITIES[i].GetOrigin().ToString() + "\n" );
    }
    P_ENTITIES.resize( 0 );
    pTriggerScript.Use( pTriggerScript, pTriggerScript, USE_OFF, 0.0f );
}
