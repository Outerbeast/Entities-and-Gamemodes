/* airstrike.as - trigger an airstrike at a random point within the trigger's bounds
    Essentially a point entity version of func_mortar_field.
    Custom mortar field zone can be set using appropriate bounds.

    To use, create a trigger_script entity with the following keys set:
    "classname" "trigger_script"
    "spawnflags" "4"					
    "m_iMode" "1"
    "m_iszScriptFunctionName" "AIRSTRIKE::Strike"
    // Leave the above keys as is, do not change them
    "targetname" "airstrike_trigger"
    "vuser1" "<x y z>"					// minimum bounds of the strike area (Required)
    "vuser2" "<x y z>"					// maximum bounds of the strike area (Required)
    "weapons" "0"						// Targeting "m_fControl": strike control method (see StrikeControl enum, default STRIKE_RANDOM)
    "impulse" "1"						// Repeat Count "m_iCount": Amount of mortars to spawn each airstrike call (default 1)
    "scale" "256"						// Spread Radius "m_flSpread": Mortars spreading radius, bombs will spawn randomly within specified radius. (default 0.0, no spread)
    "message" "y_controller"			// X Controller "m_iszXController": The name of momentary_rot_button or func_rot_button to control X coordinates of mortar spawnpoint. (Used only if StrikeControl is STRIKE_TABLE)
    "netname" "x_controller"			// Y Controller "m_iszYController":  The name of momentary_rot_button or func_rot_button to control Y coordinates of mortar spawnpoint. (Used only if StrikeControl is STRIKE_TABLE)

- Outerbeast
*/
namespace AIRSTRIKE
{

enum StrikeControl
{
    STRIKE_RANDOM = 0,// Picks a random point within the trigger bounds
    STRIKE_TRIGGER_ACTIVATOR = 1,// Uses the activator's X/Y position
    STRIKE_TABLE = 2// Uses controller entities to determine X/Y position
};

void Strike(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
{	//!-NOTE-!: pCaller is the trigger_script entity instance executing THIS function.
    string
        strXController = pCaller.pev.netname,
        strYController = pCaller.pev.message;

    int 
        iControl = pCaller.pev.weapons,
        iCount = pCaller.pev.impulse < 1 ? 1 : pCaller.pev.impulse;

    float flSpread = pCaller.pev.scale <= 0.0f ? 0.0f : pCaller.pev.scale;
    // Directly from HL SDK: https://github.com/ValveSoftware/halflife/blob/master/dlls/mortar.cpp#L122-L189
    Vector
        vecFieldMin,
        vecFieldMax,
        vecStart;

    if( !SetBounds( EHandle( pCaller ), vecFieldMin, vecFieldMax ) )
    {
        g_Log.PrintF( "!---ERROR---! AIRSTRIKE: Invalid or missing bounds on trigger_script entity '" + pCaller.GetTargetname()+ "'.\n" );
        return;
    }
    else
    {	// Size needed for controller mode
        pCaller.pev.mins = vecFieldMin - pCaller.pev.origin;
        pCaller.pev.maxs = vecFieldMax - pCaller.pev.origin;
        g_EntityFuncs.SetSize( pCaller.pev, pCaller.pev.mins, pCaller.pev.maxs );
    }

    vecStart.x = Math.RandomFloat( vecFieldMin.x, vecFieldMax.x );
    vecStart.y = Math.RandomFloat( vecFieldMin.y, vecFieldMax.y );
    vecStart.z = pCaller.pev.maxs.z;


    switch( iControl )
    {
        case STRIKE_TRIGGER_ACTIVATOR:
        {
            if( pActivator !is null )
            {
                vecStart.x = pActivator.pev.origin.x;
                vecStart.y = pActivator.pev.origin.y;
            }

            break;
        }
         // table
        case STRIKE_TABLE:
        {
            CBaseEntity@ pController;

            if( strXController != "" )
            {
                @pController = g_EntityFuncs.FindEntityByTargetname( null, strXController);

                if( pController !is null )
                    vecStart.x = vecFieldMin.x + pController.pev.ideal_yaw * ( pCaller.pev.size.x );
            }

            if( strYController != "" )
            {
                @pController = g_EntityFuncs.FindEntityByTargetname( null, strYController );

                if( pController !is null )
                    vecStart.y = vecFieldMin.y + pController.pev.ideal_yaw * ( pCaller.pev.size.y );
            }

            break;
        }
        // Random - default behavior
        default: break;
    }

    g_SoundSystem.EmitSoundDyn( pCaller.edict(), CHAN_VOICE, "weapons/mortar.wav", 1.0, ATTN_NONE, 0, Math.RandomLong( 95, 124 ) );	

    float t = 2.5;
    for( int i = 0; i < iCount; i++ )
    {
        Vector vecSpot = vecStart;
        vecSpot.x += Math.RandomFloat( -flSpread, flSpread );
        vecSpot.y += Math.RandomFloat( -flSpread, flSpread );

        TraceResult tr;
        g_Utility.TraceLine( vecSpot, vecSpot + Vector( 0, 0, -1 ) * 4096, ignore_monsters, pCaller.edict(), tr );

        edict_t@ pentOwner;

        if( pActivator !is null )
            @pentOwner = pActivator.edict();

        CBaseEntity@ pMortar = g_EntityFuncs.Create( "monster_mortar", tr.vecEndPos, g_vecZero, false, pentOwner );
        pMortar.pev.nextthink = g_Engine.time + t;
        t += Math.RandomFloat( 0.2, 0.5 );

        if( i == 0 )
            GetSoundEntInstance().InsertSound( bits_SOUND_DANGER, tr.vecEndPos, 400, 0.3f, g_EntityFuncs.Instance( pentOwner ) );
    }
}

bool SetBounds(EHandle hTriggerScript, Vector& out vecFieldMin, Vector& out vecFieldMax)
{
    if( !hTriggerScript )
        return false;

    CustomKeyvalues@ kvTriggerScript = hTriggerScript.GetEntity().GetCustomKeyvalues();

    if( kvTriggerScript.HasKeyvalue( "$v_mins" ) && kvTriggerScript.HasKeyvalue( "$v_maxs" ) )
    {
        if( kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector() != kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector() )
        {
            vecFieldMin = kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector();
            vecFieldMax = kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector();

            return vecFieldMin != vecFieldMax;
        }
        else
            return false;
    }
    else
        return false;
}

}
