/* trigger_script for teleporting npcs because trigger_teleport Monsters flag is broken
Teleports are "relative"
-Outerbeast

Template entity:-
"classname" "trigger_script"
"m_iszScriptFile" "teleport_zone"
"m_iMode" "2"
// Don't change any of the above! //
"m_iszScriptFunctionName" "TELEPORT_ZONE::TeleportEntities/TeleportPushables" // Pick which one you want
"targetname" "target_me"
"origin" "x1 y1 z1"         // Starting position
"angles" "p y r"            // Custom angles
"$v_destination" "x2 y2 z2" // Ending position
"$f_range" "72"             // Teleport Radius
"$s_brush" "*m"              // Brush model to provide bounds. Needs to be placed in the map as if it were the teleport itself
"$v_mins" "x y z"           // Teleport zone box min origin
"$v_maxs" "x y z"           // Teleport zone box max origin
"spawnflags" "f"            // See below

Flags:
f = 1 : Start Active and running constant, else it only teleports per trigger. Trigger with USE_OFF to disable.
f = 2 : Direct Teleport: entities teleport right at the destination origin, else its relative
f = 4 : Keep Velocity
f = 8 : Teleport Players
f = 32 : Teleport Monsters

Defaults:
No flags set = Both Players + monsters are affected
No brush or mins/maxs = Teleport uses radius 128 as zone from entity self origin
No destination value = Entity won't work
No angles set = entity original angles is preserved
*/
namespace TELEPORT_ZONE
{

void TeleportEntities(CBaseEntity@ pTriggerScript)
{
    array<CBaseEntity@> P_ENTITIES( 128 );
    int iNumEntities, flagMask;
    Vector vStartPos, vEndPos, vMins, vMaxs;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    float flTpRange = kvTriggerScript.GetKeyvalue( "$f_range" ).Exists() ? kvTriggerScript.GetKeyvalue( "$f_range" ).GetFloat() : 128.0f;
    flagMask = pTriggerScript.pev.spawnflags & ~( FL_FLY | FL_SWIM | FL_CONVEYOR );
    vStartPos = pTriggerScript.GetOrigin();
    
    if( flagMask == 0 )
        flagMask = FL_CLIENT | FL_MONSTER;

    if( kvTriggerScript.GetKeyvalue( "$v_destination" ).Exists() )
        vEndPos = kvTriggerScript.GetKeyvalue( "$v_destination" ).GetVector();
    else
        return;

    bool blBoundsChecked = TeleportBounds( EHandle( pTriggerScript ), vMins, vMaxs );

    if( blBoundsChecked )
        iNumEntities = g_EntityFuncs.EntitiesInBox( @P_ENTITIES, vMins, vMaxs, flagMask );
    else
        iNumEntities = g_EntityFuncs.MonstersInSphere( @P_ENTITIES, vStartPos, flTpRange );

    g_EngineFuncs.ServerPrint( "-- DEBUG: TeleportEntities " + pTriggerScript.GetTargetname() + " FlagMask(s): " + flagMask + "is thinking...\n" );

    if( iNumEntities > 0 && P_ENTITIES.length() > 0 )
    {
        for( int i = 0; i < iNumEntities; i++ )
        {
            if( iNumEntities < 1 && P_ENTITIES.length() < 1 )
                break;

            if( P_ENTITIES[i] is null || !P_ENTITIES[i].pev.FlagBitSet( FL_CLIENT | FL_MONSTER ) || P_ENTITIES[i].IsBSPModel() )
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

            if( !pTriggerScript.pev.SpawnFlagBitSet( 4 ) )
                P_ENTITIES[i].pev.velocity = g_vecZero;

            g_EngineFuncs.ServerPrint( "-- DEBUG: TeleportZone " + pTriggerScript.GetTargetname() + " teleported entity " + P_ENTITIES[i].GetClassname() + " to end point: " + vEndPos.ToString() + " - New origin: " + P_ENTITIES[i].GetOrigin().ToString() + "\n" );
        }
    }
    P_ENTITIES.resize( 0 );

    if( !pTriggerScript.pev.SpawnFlagBitSet( 1 ) || pTriggerScript.GetTargetname() != "" )
        pTriggerScript.Use( pTriggerScript, pTriggerScript, USE_OFF, 0.0f );
}

void TeleportPushables(CBaseEntity@ pTriggerScript)
{
    array<CBaseEntity@> P_BRUSHES( 128 );
    int iNumBrushes;
    Vector vStartPos, vEndPos, vMins, vMaxs;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();
    float flTpRange = kvTriggerScript.GetKeyvalue( "$f_range" ).Exists() ? kvTriggerScript.GetKeyvalue( "$f_range" ).GetFloat() : 128.0f;
    vStartPos = pTriggerScript.GetOrigin();

    if( kvTriggerScript.GetKeyvalue( "$v_destination" ).Exists() )
        vEndPos = kvTriggerScript.GetKeyvalue( "$v_destination" ).GetVector();
    else
        return;

    if( pTriggerScript.pev.SpawnFlagBitSet( 1 ) )
        g_EngineFuncs.ServerPrint( "-- DEBUG: TeleportPushables " + pTriggerScript.GetTargetname() + " is thinking...\n" );

    bool blBoundsChecked = TeleportBounds( EHandle( pTriggerScript ), vMins, vMaxs );

    if( blBoundsChecked )
        iNumBrushes = g_EntityFuncs.BrushEntsInBox( @P_BRUSHES, vMins, vMaxs );
    else
        return;

    if( iNumBrushes > 0 && P_BRUSHES.length() > 0 )
    {
        for( int i = 0; i < iNumBrushes; i++ )
        {
            if( iNumBrushes < 1 && P_BRUSHES.length() < 1 )
                break;

            if( P_BRUSHES[i] is null || !P_BRUSHES[i].IsBSPModel() || P_BRUSHES[i].GetClassname() != "func_pushable" )
                continue;

            g_EntityFuncs.SetOrigin( P_BRUSHES[i], P_BRUSHES[i].GetOrigin() + vEndPos - vStartPos );
            P_BRUSHES[i].pev.angles = P_BRUSHES[i].pev.angles + pTriggerScript.pev.angles;

            g_EngineFuncs.ServerPrint( "-- DEBUG: TeleportPushables " + pTriggerScript.GetTargetname() + " teleported entity " + P_BRUSHES[i].GetClassname() + " to end point: " + vEndPos.ToString() + " - New origin: " + P_BRUSHES[i].GetOrigin().ToString() + "\n" );
        }
    }
    P_BRUSHES.resize( 0 );

    if( !pTriggerScript.pev.SpawnFlagBitSet( 1 ) || pTriggerScript.GetTargetname() != "" )
        pTriggerScript.Use( pTriggerScript, pTriggerScript, USE_OFF, 0.0f );
}

bool TeleportBounds(EHandle hTriggerScript, Vector& out vecMin, Vector& out vecMax)
{
    if( !hTriggerScript )
        return false;

    CustomKeyvalues@ kvTriggerScript = hTriggerScript.GetEntity().GetCustomKeyvalues();

    if( kvTriggerScript.GetKeyvalue( "$s_brush" ).Exists() )
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
    else if( kvTriggerScript.GetKeyvalue( "$v_mins" ).Exists() && kvTriggerScript.GetKeyvalue( "$v_maxs" ).Exists() )
    {
        if( kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector() != kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector() )
        {
            vecMin = kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector();
            vecMin = kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector();

            return true;
        }
        else
            return false;
    }
    else
        return false;
}

}