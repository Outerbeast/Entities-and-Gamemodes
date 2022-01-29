/* env_laser Trip Sensor - extention for env_laser
by Outerbeast

env_laser triggers its "target" when something blocks it when the laser is turned on.

Installation
This extension can be enabled in different ways, use whichever is most convenient:-
- Add 
map_script laser_trip_sensor 
to your map cfg
OR
- Add
#include "laser_trip_sensor"
to your main map script header
OR
- Create a trigger_script with these keys set in your map:
"classname" "trigger_script"
"targetname" "trip_sensor_activate"
"m_iMode" "2"
"m_iszScriptFile" "laser_trip_sensor"
"m_iszScriptFunctionName" "LASER_TRIP_SENSOR::TripSensor"
Trigger this to activate it, alternatively set "Start On" flag for this trigger_script

Usage:
Create and configure your env_laser in your map.
Then turn off "Smart Edit" mode and add these keys to the entity:-
"target" "entity"   - Entity to trigger when laser is blocked. Activator is the entity tripping the laser, caller is the env_laser instance itself. Trigger type is "Toggle"
"netname" "entity"  - Sets a specific entity targetname that is allowed to trip the sensor. Note that the filters set in "spawnflags" are still counted when set.
"impulse" "i"       - Sensor type- see "SensorTypes" below for choices
"health" "t"        - Sensor reset delay when using "Trip Once" option. If set to -1, the env_laser will trigger its target once then delete itself. Default is 0
"spawnflags" "f"    - These are a few filtering options:-
"2" : Monsters are able to trip the laser
"4" : func_pushables are able to trip the laser
"8" : Prevents players from being able to trip the laser

If you want to check if the laser was disturbed, check the env_laser's "fuser1" value against original value before it was disturbed, via trigger_condition/copyvalue.

Issues:
if the env_laser has multiple LaserTargets, it will pick a random one to draw the laser beam.
The trip sensors will likely not match up with the current drawn beam. For this reason its advisable to avoid using this when there are multiple laser targets.
*/
namespace LASER_TRIP_SENSOR
{

enum SensorTypes
{
    DEFAULT = 0,    // Laser triggers again when renentering or someone else enters
    TRIP_ONCE,      // Triggers once, then the laser turns off. Uses "wait" value for automatic reset delay, otherwise the env_laser needs to be manually turned on again
    TRIP_MULTIPLE   // Triggers constantly so long as laser is being blocked
}

enum LaserSpawnFlags
{
    MONSTERS            = 2,
    PUSHABLES           = 4
}

const array<string> STR_IGNORE_BRUSH_ENTS =
{
   "func_wall",
   "func_illusionary",
   "func_breakable"
};

CScheduledFunction@ fnTripSensorThink = g_Scheduler.SetInterval( "TripSensor", 0.0f, g_Scheduler.REPEAT_INFINITE_TIMES, cast<CBaseEntity@>( null ) );

void TripSensor(CBaseEntity@ pTriggerScript)
{
    if( pTriggerScript !is null && fnTripSensorThink !is null )
    {
        g_Scheduler.RemoveTimer( fnTripSensorThink );
        @fnTripSensorThink = null;
    }

    Vector vecEnd;
    TraceResult trSensor;
    CBaseEntity@ pLaser, pTrip;
    
    while( ( @pLaser = g_EntityFuncs.FindEntityByClassname( pLaser, "env_laser" ) ) !is null )
    {
        if( pLaser is null || 
            pLaser.pev.target == "" ||
            pLaser.pev.target == pLaser.GetTargetname() ||
            pLaser.pev.effects & EF_NODRAW != 0 ||
            g_EntityFuncs.RandomTargetname( "" + pLaser.pev.message ) is null )
            continue;
        
        vecEnd = g_EntityFuncs.RandomTargetname( "" + pLaser.pev.message ).GetOrigin();

        g_Utility.TraceLine( pLaser.pev.origin, vecEnd, dont_ignore_monsters, pLaser.edict(), trSensor );
        @pTrip = g_EntityFuncs.Instance( trSensor.pHit );
        pLaser.pev.fuser1 = trSensor.flfraction;

        if( pTrip is null || pTrip is g_EntityFuncs.Instance( 0 ) || STR_IGNORE_BRUSH_ENTS.find( pTrip.GetClassname() ) >= 0 )
        {
            @pLaser.pev.euser1 = null;
            continue;
        }
            
        if( pTrip.IsPlayer() && pLaser.pev.SpawnFlagBitSet( FL_CLIENT ) )
            continue;
        
        if( pTrip.pev.FlagBitSet( FL_MONSTER ) && !pLaser.pev.SpawnFlagBitSet( MONSTERS ) )
            continue;
            
        if( pTrip.GetClassname() == "func_pushable" && !pLaser.pev.SpawnFlagBitSet( PUSHABLES ) )
            continue;

        if( pLaser.pev.netname != "" && pTrip.GetTargetname() != pLaser.pev.netname )
            continue;
            
        if( pLaser.pev.impulse == TRIP_ONCE && pLaser.GetTargetname() == "" )
            pLaser.pev.health = -1.0f;

        switch( pLaser.pev.impulse )
        {
            case TRIP_ONCE:
            {
                g_EntityFuncs.FireTargets( pLaser.pev.target, pTrip, pLaser, USE_TOGGLE, 0.0f, 0.0f );
                pLaser.Use( pLaser, pLaser, USE_OFF, 0.0f );

                if( pLaser.pev.health > 0.0f )
                    g_Scheduler.SetTimeout( "ResetSensor", pLaser.pev.health, EHandle( pLaser ) );
                else if( pLaser.pev.health < 0.0f )
                    g_EntityFuncs.Remove( pLaser );

                break;
            }

            case TRIP_MULTIPLE:
                g_EntityFuncs.FireTargets( pLaser.pev.target, pTrip, pLaser, USE_TOGGLE, 0.0f, 0.0f );
                break;

            default:
            {
                if( pTrip !is g_EntityFuncs.Instance( @pLaser.pev.euser1 ) )
                    g_EntityFuncs.FireTargets( pLaser.pev.target, pTrip, pLaser, USE_TOGGLE, 0.0f, 0.0f );
            }
        }

        @pLaser.pev.euser1 = trSensor.pHit;
    }
}

void ResetSensor(EHandle hLaser)
{
    if( !hLaser )
        return;

    hLaser.GetEntity().Use( null, null, USE_ON, 0.0f );
}

}
