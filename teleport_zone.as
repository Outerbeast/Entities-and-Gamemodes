/* trigger_script for teleporting npcs because trigger_teleport Monsters flag is broken
Teleports are "relative"
-Outerbeast

Template entity:-
"classname" "trigger_script"
"m_iszScriptFile" "teleport_zone"
"m_iszScriptFunctionName" "TeleportZone"
"m_iMode" "2"
// Don't change any of the above! //
"targetname" "target_me"
"origin" "x1 y1 z1"         // Starting position
"angles" "p y r"            // Custom angles
"$v_destination" "x2 y2 z2" // Ending position
"$f_range" "72"             // search radius
"$v_mins" "x y z"           // box min origin
"$v_maxs" "x y z"           // box max origin
"spawnflags" "f"            // See below

Flags:
f = 1 : Start Active and running constant, else it only teleports per trigger. Trigger with USE_OFF to disable.
f = 2 : Direct Teleport: entities teleport right at the destination origin, else its relative
f = 4 : Teleport Pushables (Must use bounding box mins/maxs for this)
f = 8 : Teleport Players
f = 32 : Teleport Monsters

Defaults:
No targetname = Active and thinking at start
No flags set = Players + monsters are affected, no pushables
No mins/maxs = Teleport uses radius 128 as zone from entity self origin
No destination value = Entity is disabled
No angles set = entity original angles is preserved
*/
void TeleportZone(CBaseEntity@ pTriggerScript)
{
    array<CBaseEntity@> P_ENTITIES( 64 ), P_BRUSHES( 64 );
    int iNumEntities, iNumBrushes, flagMask;
    Vector vStartPos, vEndPos;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    float flTpRange = kvTriggerScript.GetKeyvalue( "$f_range" ).Exists() ? kvTriggerScript.GetKeyvalue( "$f_range" ).GetFloat() : 128.0f;
    flagMask = pTriggerScript.pev.spawnflags > 0 ? pTriggerScript.pev.spawnflags & ~( FL_FLY | FL_SWIM | FL_CONVEYOR ) : FL_CLIENT | FL_MONSTER;
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
        {
            iNumEntities = g_EntityFuncs.EntitiesInBox( @P_ENTITIES, kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector(), kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector(), flagMask );

            if( pTriggerScript.pev.SpawnFlagBitSet( 4 ) )
                iNumBrushes = g_EntityFuncs.BrushEntsInBox( @P_BRUSHES, kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector(), kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector() );
        }
    }
    else
        iNumEntities = g_EntityFuncs.MonstersInSphere( @P_ENTITIES, vStartPos, flTpRange );

    g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs " + pTriggerScript.GetTargetname() + " FlagMask(s): " + flagMask + "\n" );

    if( iNumEntities > 0 && P_ENTITIES.length() > 0 )
    {
        for( int i = 0; i < iNumEntities; i++ )
        {
            if( P_ENTITIES[i] is null )
                continue;

            if( P_ENTITIES[i].IsPlayer() && ( flagMask & FL_CLIENT ) == 0 )
                continue;

            if( P_ENTITIES[i].IsMonster() && ( flagMask & FL_MONSTER ) == 0 )
                continue;

            if( !pTriggerScript.pev.SpawnFlagBitSet( 2 ) )
                g_EntityFuncs.SetOrigin( P_ENTITIES[i], P_ENTITIES[i].GetOrigin() + vEndPos - vStartPos );
            else
                g_EntityFuncs.SetOrigin( P_ENTITIES[i], vEndPos );

            P_ENTITIES[i].pev.angles = P_ENTITIES[i].pev.angles + pTriggerScript.pev.angles;

            g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs " + pTriggerScript.GetTargetname() + " teleported entity " + P_ENTITIES[i].GetClassname() + " to end point: " + vEndPos.ToString() + " - New origin: " + P_ENTITIES[i].GetOrigin().ToString() + "\n" );
        }
    }
    P_ENTITIES.resize( 0 );

    if( iNumBrushes > 0 && P_BRUSHES.length() > 0 )
    {
        for( int i = 0; i < iNumBrushes; i++ )
        {
            if( P_BRUSHES[i] is null || P_BRUSHES[i].GetClassname() != "func_pushable" )
                continue;

            g_EntityFuncs.SetOrigin( P_BRUSHES[i], P_BRUSHES[i].GetOrigin() + vEndPos - vStartPos );
            P_BRUSHES[i].pev.angles = P_BRUSHES[i].pev.angles + pTriggerScript.pev.angles;

            g_EngineFuncs.ServerPrint( "-- DEBUG: TransportNpcs " + pTriggerScript.GetTargetname() + " teleported entity " + P_BRUSHES[i].GetClassname() + " to end point: " + vEndPos.ToString() + " - New origin: " + P_BRUSHES[i].GetOrigin().ToString() + "\n" );
        }
    }
    P_BRUSHES.resize( 0 );

    if( !pTriggerScript.pev.SpawnFlagBitSet( 1 ) || pTriggerScript.GetTargetname() != "" )
        pTriggerScript.Use( pTriggerScript, pTriggerScript, USE_OFF, 0.0f );
}
