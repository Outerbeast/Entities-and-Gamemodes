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
"$f_radius" "72"             // Teleport Radius
"$s_brush" "*m"             // Brush model to provide bounds. Needs to be placed in the map as if it were the teleport itself
"$v_mins" "x y z"           // Teleport zone box min origin
"$v_maxs" "x y z"           // Teleport zone box max origin
"spawnflags" "f"            // See below

Flags:
f = 1 : Start Active and running constant, else it only teleports per trigger. Trigger with USE_OFF to disable.
f = 2 : Direct Teleport: entities teleport right at the destination origin, else its relative
f = 4 : Keep Velocity
f = 8 : Teleport Players
f = 16 : Teleport Miscellanous (items, ammo, weapons)
f = 32 : Teleport Monsters
f = 64 : Teleport Pushables

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

    CustomKeyvalues@ kvTriggerScript    = pTriggerScript.GetCustomKeyvalues();
    float flRange                       = kvTriggerScript.HasKeyvalue( "$f_radius" ) ? kvTriggerScript.GetKeyvalue( "$f_radius" ).GetFloat() : 128.0f;
    flagMask                            = pTriggerScript.pev.spawnflags & ~( FL_FLY | FL_SWIM | FL_CONVEYOR | FL_INWATER | FL_GODMODE );
    vStartPos                           = pTriggerScript.GetOrigin();
    bool blBoundsChecked                = TeleportBounds( EHandle( pTriggerScript ), vMins, vMaxs );
    
    if( flagMask == 0 )
        flagMask = FL_CLIENT | FL_MONSTER;

    if( kvTriggerScript.HasKeyvalue( "$v_destination" ) )
        vEndPos = kvTriggerScript.GetKeyvalue( "$v_destination" ).GetVector();
    else
        return;

    if( blBoundsChecked )
    {
        iNumEntities = g_EntityFuncs.EntitiesInBox( @P_ENTITIES, vMins, vMaxs, flagMask );

        if( pTriggerScript.pev.SpawnFlagBitSet( 16 ) )
            TeleportMisc( vStartPos, vEndPos, vMins, vMaxs, pTriggerScript.pev.spawnflags );
        
        if( pTriggerScript.pev.SpawnFlagBitSet( 64 ) )
            TeleportPushables( vStartPos, vEndPos, vMins, vMaxs );
    }
    else
        iNumEntities = g_EntityFuncs.MonstersInSphere( @P_ENTITIES, vStartPos, flRange );

    //g_EngineFuncs.ServerPrint( "-- DEBUG: TeleportEntities " + pTriggerScript.GetTargetname() + " FlagMask(s): " + flagMask + " is thinking...\n" );

    for( int i = 0; i < iNumEntities; i++ )
    {
        if( iNumEntities < 1 || P_ENTITIES.length() < 1 )
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

        //g_EngineFuncs.ServerPrint( "-- DEBUG: TeleportZone " + pTriggerScript.GetTargetname() + " teleported entity: " + P_ENTITIES[i].GetClassname() + " to end point: " + vEndPos.ToString() + " - New origin: " + P_ENTITIES[i].GetOrigin().ToString() + "\n" );
    }
    P_ENTITIES.resize( 0 );

    if( !pTriggerScript.pev.SpawnFlagBitSet( 1 ) || pTriggerScript.GetTargetname() != "" )
        pTriggerScript.Use( pTriggerScript, pTriggerScript, USE_OFF, 0.0f );
}
// Teleport miscellaneous stuff like items, ammo and weapons
void TeleportMisc(Vector vStartPos, Vector vEndPos, Vector vMins, Vector vMaxs, uint iSpawnflags)
{
    array<CBaseEntity@> P_MISC( 128 );
    int iNumEntities = g_EntityFuncs.EntitiesInBox( @P_MISC, vMins, vMaxs, 0 );

    if( iNumEntities < 1 || P_MISC.length() < 1 )
        return;

    for( int i = 0; i < iNumEntities; i++ )
    {
        if( P_MISC[i] is null || !P_MISC[i].IsPointEnt() || P_MISC[i].IsBSPModel() || P_MISC[i].IsPlayer() || P_MISC[i].IsMonster() )
            continue;
        // !-BUG-! : "ammo_" entities teleport, but they disappear
        if( cast<CItem@>( P_MISC[i] ) !is null || cast<CBasePlayerItem@>( P_MISC[i] ) !is null )
        {
            if( ( iSpawnflags & 2 ) == 0 )
                g_EntityFuncs.SetOrigin( P_MISC[i], P_MISC[i].GetOrigin() + vEndPos - vStartPos );
            else
                g_EntityFuncs.SetOrigin( P_MISC[i], vEndPos );
        }
        g_EngineFuncs.ServerPrint( "-- DEBUG: TeleportZone teleported misc item: " + P_MISC[i].GetClassname() + " to end point: " + vEndPos.ToString() + " - New origin: " + P_MISC[i].GetOrigin().ToString() + "\n" );
    }
    P_MISC.resize( 0 );
}
// Teleporting pushables is kind of buggy
void TeleportPushables(Vector vStartPos, Vector vEndPos, Vector vMins, Vector vMaxs)
{
    array<CBaseEntity@> P_BRUSHES( 128 );
    int iNumBrushes = g_EntityFuncs.BrushEntsInBox( @P_BRUSHES, vMins, vMaxs );

    if( iNumBrushes < 1 || P_BRUSHES.length() < 1 )
        return;

    for( int i = 0; i < iNumBrushes; i++ )
    {
        if( P_BRUSHES[i] is null || !P_BRUSHES[i].IsBSPModel() || P_BRUSHES[i].GetClassname() != "func_pushable" )
            continue;

        g_EntityFuncs.SetOrigin( P_BRUSHES[i], P_BRUSHES[i].GetOrigin() + vEndPos - vStartPos );

        //g_EngineFuncs.ServerPrint( "-- DEBUG: TeleportPushables teleported pushable: " + P_BRUSHES[i].GetClassname() + " to end point: " + vEndPos.ToString() + " - New origin: " + P_BRUSHES[i].GetOrigin().ToString() + "\n" );
    }
    P_BRUSHES.resize( 0 );
}

bool TeleportBounds(EHandle hTriggerScript, Vector& out vecMin, Vector& out vecMax)
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
