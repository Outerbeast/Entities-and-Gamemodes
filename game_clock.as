/* game_clock
trigger_script for getting the current time and date

Current time is stored in "vuser1" in 24H format "hh mm ss"
Current date is stored in "vuser2" in the format "dd mm yyyy"
Current weekday is stored "netname" in lowercase e.g. "monday"
Use entities "trigger_condition" and "trigger_copyvalue" to check and retrieve
these values and create trigger logic accordingly

Includes feature to display the time and date as an optional flag
Template:
"classname" "trigger_script"
"m_iszScriptFile" "game_clock"
"m_iszScriptFunctionName" "GAME_CLOCK::Clock"
"m_iMode" "2"
// Don't change any of the above!
"targetname" "clock_entity" - entity name
"spawnflags" "f" - See "game_clock_flags" for flag values

- Outerbeast
*/
namespace GAME_CLOCK
{

Vector2D HudClockPos    = Vector2D( 0.95, 0.1 );
RGBA HudClockColor1     = RGBA( 250, 250, 250, 0 );
RGBA HudClockColor2     = RGBA( 250, 250, 250, 0 );

enum game_clock_flags
{
    START_ON                = 1,
    SHOW_HUD_CLOCK          = 2,// Display time and date onscreen
    // The following flags only work when SHOW_HUD_CLOCK flag is set:
    SHOW_SECONDS            = 4,// Display seconds
    DD_MONTH_YYYY_FORMAT    = 8 // Changes the on screen date format to "DD, Month, YYYY"
}

EHandle CreateClock(bool blShowHUDClock = false)
{
    dictionary clock =
    {
        { "targetname", "clock_entity" },
        { "m_iszScriptFile", "game_clock" },
        { "m_iszScriptFunctionName", "GAME_CLOCK::Clock" },
        { "m_iMode", "2" },
        { "spawnflags", "" + blShowHUDClock }
    };

    return( g_EntityFuncs.CreateEntity( "trigger_script", clock ) );
}

void Clock(CBaseEntity@ pTriggerScript)
{
    DateTime obj_DateTime;
    string strTime, strDate, strDay;

    const Vector vecTime = pTriggerScript.pev.vuser1 = Vector( obj_DateTime.GetHour(), obj_DateTime.GetMinutes(), obj_DateTime.GetSeconds() );
    const Vector vecDate = pTriggerScript.pev.vuser2 = Vector( obj_DateTime.GetDayOfMonth(), obj_DateTime.GetMonth(), obj_DateTime.GetYear() );
    
    obj_DateTime.Format( strDay, "%A" );
    pTriggerScript.pev.netname = string( strDay ).ToLowercase();

    if( !pTriggerScript.pev.SpawnFlagBitSet( SHOW_HUD_CLOCK ) )
        return;
    
    const string strTimeColon = vecTime.z % 2 != 0 ? " " : ":";

    if( pTriggerScript.pev.SpawnFlagBitSet( SHOW_SECONDS ) )
        obj_DateTime.Format( strTime, "%H" + strTimeColon + "%M" + strTimeColon + "%S" );
    else
        obj_DateTime.Format( strTime, "%H" + strTimeColon + "%M" );

    if( pTriggerScript.pev.SpawnFlagBitSet( DD_MONTH_YYYY_FORMAT ) )
        obj_DateTime.Format( strDate, "%e %B, %Y" );
    else
        obj_DateTime.Format( strDate, "%d/%m/%Y" );

    HUDTextParams txtTimeDate;
        txtTimeDate.x = HudClockPos.x;
        txtTimeDate.y = HudClockPos.y;

        txtTimeDate.r1 = HudClockColor1.r;
        txtTimeDate.g1 = HudClockColor1.g;
        txtTimeDate.b1 = HudClockColor1.b;
        txtTimeDate.a1 = HudClockColor1.a;

        txtTimeDate.r2 = HudClockColor2.r;
        txtTimeDate.g2 = HudClockColor2.g;
        txtTimeDate.b2 = HudClockColor2.b;
        txtTimeDate.a2 = HudClockColor2.a;

        txtTimeDate.fadeinTime = 0.0;
        txtTimeDate.fadeoutTime = 0.0;
        txtTimeDate.holdTime = 10.0;
        txtTimeDate.fxTime = 0.0;
        txtTimeDate.channel = 5;
    g_PlayerFuncs.HudMessageAll( txtTimeDate, strTime + "\n" + strDay + " " + strDate );
}

}
