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
enum game_clock_flags
{
    SHOW_HUD_CLOCK          = 1,// Display time and date onscreen
    // The following flags only work when SHOW_HUD_CLOCK flag is set:
    SHOW_SECONDS            = 2,// Display seconds
    DD_MONTH_YYYY_FORMAT    = 4 // Changes the on screen date format to "DD, Month, YYYY"
}

bool blGameClockRegistered = RegisterGameClock();

bool RegisterGameClock()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "game_clock", "game_clock" );
    return g_CustomEntityFuncs.IsCustomEntity( "game_clock" );
}

final class game_clock : ScriptBaseEntity
{
    private RGBA
        HudClockColor1 = RGBA( 250, 250, 250, 0 ),
        HudClockColor2 = RGBA( 250, 250, 250, 0 );

    private HUDTextParams txtTimeDate;

    game_clock()
    {
        txtTimeDate.x = 0.95f;
        txtTimeDate.y = 0.1f;
        txtTimeDate.fadeinTime = txtTimeDate.fadeoutTime = txtTimeDate.fxTime = 0.0;
        txtTimeDate.holdTime = 10.0;
        txtTimeDate.channel = 5;
    }

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "x" )
            txtTimeDate.x = atof( szValue );
        else if( szKey == "y" )
            txtTimeDate.y = atof( szValue );
        else if( szKey == "color1" )
            g_Utility.StringToRGBA( HudClockColor1, szValue );
        else if( szKey == "color2" )
            g_Utility.StringToRGBA( HudClockColor2, szValue );
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Spawn()
    {
        txtTimeDate.r1 = HudClockColor1.r;
        txtTimeDate.g1 = HudClockColor1.g;
        txtTimeDate.b1 = HudClockColor1.b;
        txtTimeDate.a1 = HudClockColor1.a;

        txtTimeDate.r2 = HudClockColor2.r;
        txtTimeDate.g2 = HudClockColor2.g;
        txtTimeDate.b2 = HudClockColor2.b;
        txtTimeDate.a2 = HudClockColor2.a;

        self.pev.nextthink = g_Engine.time + 0.1f;

        BaseClass.Spawn();
    }

    void Think()
    {
        DateTime obj_DateTime;
        string strTime, strDate, strDay;

        self.pev.vuser1 = Vector( obj_DateTime.GetHour(), obj_DateTime.GetMinutes(), obj_DateTime.GetSeconds() );// Time, in 24H format: "hh mm ss"
        self.pev.vuser2 = Vector( obj_DateTime.GetDayOfMonth(), obj_DateTime.GetMonth(), obj_DateTime.GetYear() );// Date, in the format: "dd mm yyyy"
        
        obj_DateTime.Format( strDay, "%A" );
        self.pev.netname = string( strDay ).ToLowercase();

        if( !self.pev.SpawnFlagBitSet( SHOW_HUD_CLOCK ) )
            return;
        
        const string 
            strTimeColon = vuser1.z % 2 != 0 ? " " : ":",
            strDateFormat = self.pev.SpawnFlagBitSet( DD_MONTH_YYYY_FORMAT ) ? "%e %B, %Y" : "%d/%m/%Y";

        obj_DateTime.Format( strTime, "%H" + strTimeColon + "%M" + ( self.pev.SpawnFlagBitSet( SHOW_SECONDS ) ? strTimeColon + "%S" : "" ) );
        obj_DateTime.Format( strDate, strDateFormat );
        g_PlayerFuncs.HudMessageAll( txtTimeDate, strTime + "\n" + strDay + " " + strDate );

        self.pev.nextthink = g_Engine.time + 0.001f;
    }
};
