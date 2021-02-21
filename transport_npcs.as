/* trigger_script for teleporting npcs because trigger_teleport Monsters flag is broken
Teleports are "relative"
-Outerbeast

Template entity:-

"classname" "trigger_script"
"m_iszScriptFile" "transport_npcs"
"m_iszScriptFunctionName" "TransportNpcs"
"m_iMode" "2"
"targetname" "transport_npcs"
"origin" "x1 y1 z1" // Starting position
"angles" "p y r" // custom angles
"$v_destination" "x2 y2 z2" // Ending position
"$f_range" "72" // search radius
"$v_mins" "x y z" // box min origin
"$v_maxs" "x y z" // box max origin

Flags:
"spawnflags" "s"
s = 1 : Start Active and running constant, else its only per trigger
s = 8 : Teleport Players
s = 32 : Teleport Monsters (default)

*/
void TransportNpcs(CBaseEntity@ pTriggerScript)
{
    array<CBaseEntity@> P_ENTITIES( 64 );
    int iNumEntities, flagMask;
    Vector vStartPos, vEndPos;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    float flTpRange = kvTriggerScript.GetKeyvalue( "$f_range" ).Exists() ? kvTriggerScript.GetKeyvalue( "$f_range" ).GetFloat() : 128.0f;
    flagMask = pTriggerScript.pev.spawnflags >= 1 ? pTriggerScript.pev.spawnflags & ~FL_FLY : FL_MONSTER;
    vStartPos = pTriggerScript.GetOrigin();

    if( kvTriggerScript.GetKeyvalue( "$v_destination" ).Exists() )
        vEndPos = kvTriggerScript.GetKeyvalue( "$v_destination" ).GetVector();
    else
        return;

    if( pTriggerScript.pev.SpawnFlagBitSet( 1 ) )
        g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs " + pTriggerScript.GetTargetname() + " is thinking...\n" );

    if( kvTriggerScript.GetKeyvalue( "$v_mins" ).Exists() && kvTriggerScript.GetKeyvalue( "$v_maxs" ).Exists() )
    {
        if( kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector() != kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector() )
            iNumEntities = g_EntityFuncs.EntitiesInBox( @P_ENTITIES, kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector(), kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector(), flagMask );
    }
    else
        iNumEntities = g_EntityFuncs.MonstersInSphere( @P_ENTITIES, vStartPos, flTpRange );

    g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs " + pTriggerScript.GetTargetname() + " FlagMask(s): " + flagMask + "\n" );

    for( int i = 0; i < iNumEntities; i++ )
    {
        if( iNumEntities < 1 || P_ENTITIES.length() < 1 )
            break;

        if( P_ENTITIES[i] is null )
            continue;
        
        if( P_ENTITIES[i].IsPlayer() && ( flagMask & FL_CLIENT ) == 0 )
        {
            g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs " + pTriggerScript.GetTargetname() + " Skipped player: " + P_ENTITIES[i].pev.netname + "\n" );
            continue;
        }

        if( P_ENTITIES[i].IsMonster() && ( flagMask & FL_MONSTER ) == 0 )
        {
            g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs " + pTriggerScript.GetTargetname() + " Skipped monster: " + P_ENTITIES[i].GetClassname() + "\n" );
            continue;
        }

        g_EntityFuncs.SetOrigin( P_ENTITIES[i], P_ENTITIES[i].GetOrigin() + ( vEndPos - vStartPos ) );
        P_ENTITIES[i].pev.angles = P_ENTITIES[i].pev.angles + pTriggerScript.pev.angles;

        g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs " + pTriggerScript.GetTargetname() + " teleported entity " + P_ENTITIES[i].GetClassname() + " to end point: " + vEndPos.ToString() + " - New origin: " + P_ENTITIES[i].GetOrigin().ToString() + "\n" );
    }
    P_ENTITIES.resize( 0 );

    if( !pTriggerScript.pev.SpawnFlagBitSet( 1 ) )
        pTriggerScript.Use( pTriggerScript, pTriggerScript, USE_OFF, 0.0f );
}