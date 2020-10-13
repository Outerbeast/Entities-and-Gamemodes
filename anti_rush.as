/* AntiRush custom entity by Outerbeast
A percent player trigger zone can be set using "zonecornermin/max" coords and percentage of players required to trigger
Percentage marker is red and will turn green with a bell sound when triggered, and will trigger its target.
Supports use of "killtarget", "delay" and locking entities with "master" key
Marker model/sprite and bell sound can be customised with the "icon" and "sound" keys

This script uses the custom entities "trigger_once_mp" and "func_wall_custom", programmed by CubeMath
Those scripts must already be installed for this one to work
*/

#include "cubemath/trigger_once_mp"
#include "cubemath/func_wall_custom"

class anti_rush : ScriptBaseEntity
{
    private string IconName         = "sprites/adamr/arrow_gohere.spr"; // Placeholder default icon, use your own custom one
    private string SoundName        = "buttons/bell1.wav";
    private string MasterName       = "";
    private string KillTarget       = "";
    private float fl_FadeTime       = 5.0f;
    private float fl_TargetDelay    = 0.0f;

    private float fl_PercentRequired = 0.0f;

    private Vector vZoneCornerMin = Vector(0, 0, 0);
    private Vector vZoneCornerMax = Vector(0, 0, 0);

    private CBaseEntity@ AntiRushIcon;

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if( szKey == "icon" ) 
		{
			IconName = szValue;
			return true;
		}
		else if( szKey == "sound" ) 
		{
			SoundName = szValue;
			return true;
		}
        else if( szKey == "master" ) 
		{
			MasterName = szValue;
			return true;
		}
        else if( szKey == "killtarget" ) 
		{
			KillTarget = szValue;
			return true;
		}
        else if( szKey == "zonecornermin" ) 
		{
			g_Utility.StringToVector( vZoneCornerMin, szValue );
			return true;
		}
         else if( szKey == "zonecornermax" ) 
		{
			g_Utility.StringToVector( vZoneCornerMax, szValue );
			return true;
		}
        else if( szKey == "percentage" ) 
		{
			fl_PercentRequired = atof( szValue )*0.01f;
			return true;
		}
        else if( szKey == "delay" )
		{
			fl_TargetDelay = atof( szValue );
			return true;
		}
		else if( szKey == "fadetime" ) 
		{
			fl_FadeTime = atof( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
    void Precache()
	{
		BaseClass.Precache();
        g_Game.PrecacheModel( "" + IconName );
		g_SoundSystem.PrecacheSound( "" + SoundName );
	}

	void Spawn()
	{
        Precache();
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( fl_PercentRequired > 0.01f )
        {   
            if( vZoneCornerMin != Vector (0, 0, 0) )
            {
                if( vZoneCornerMax != Vector (0, 0, 0) )
                {
                    CreatePercentPlayerTrigger();
                }
            }
        }

        if( self.pev.scale <= 0 )
        {
            self.pev.scale = 0.15;
        }
        CreateIcon();

        if( self.pev.target != "" || self.pev.target != self.GetTargetname() )
        {
            CreateLock();
        }
	}

    void CreatePercentPlayerTrigger()
    {
        dictionary trgr;
        trgr ["minhullsize"]        = ( "" + string(vZoneCornerMin.x) + " " + string(vZoneCornerMin.y) + " " + string(vZoneCornerMin.z) );
        trgr ["maxhullsize"]        = ( "" + string(vZoneCornerMax.x) + " " + string(vZoneCornerMax.y) + " " + string(vZoneCornerMax.z) );
        trgr ["m_flPercentage"]     = ( "" + fl_PercentRequired );
        trgr ["target"]             = ( "" + self.GetTargetname() );
        if( MasterName != "" || MasterName != "" + self.GetTargetname() )
        { 
            trgr ["master"] = ( "" + MasterName ); 
        }
	    CBaseEntity@ PercentPlayerTrigger = g_EntityFuncs.CreateEntity( "trigger_once_mp", trgr, true );
        //PercentPlayerTrigger.Think();
        g_EngineFuncs.ServerPrint( "-- DEBUG -- Created AntiRush trigger zone with target: " + PercentPlayerTrigger.pev.target + " with required percentage " + fl_PercentRequired + " with master: " + MasterName + " with bounds: " + "" + string(vZoneCornerMin.x) + " " + string(vZoneCornerMin.y) + " " + string(vZoneCornerMin.z) + " and " + string(vZoneCornerMax.x) + " " + string(vZoneCornerMax.y) + " " + string(vZoneCornerMax.z) + "\n" );
    }

    void CreateIcon()
    {
        dictionary spr;
        spr ["origin"]          = ( "" + string(self.pev.origin.x) + " " + string(self.pev.origin.y) + " " + string(self.pev.origin.z) );
        spr ["angles"]          = ( "" + string(self.pev.angles.x) + " " + string(self.pev.angles.y) + " " + string(self.pev.angles.z) );
        spr ["model"]           = ( "" + IconName );
        spr ["vp_type"]         = ( "0" );
        spr ["scale"]           = ( "" + self.pev.scale );
	    spr ["rendercolor"]     = ( "255 0 0" );
        spr ["renderamt"]       = ( "255 255 255" );
        spr ["rendermode"]      = ( "5" );
	    @AntiRushIcon = g_EntityFuncs.CreateEntity( "env_sprite", spr, true );
        AntiRushIcon.Think();
    }

    void CreateLock()
    {
        dictionary ms;
        ms ["targetname"] = ( "" + self.pev.target );
        CBaseEntity@ AntiRushLock = g_EntityFuncs.CreateEntity( "multisource", ms, true );   
        AntiRushLock.Think();
        g_EngineFuncs.ServerPrint( "-- DEBUG -- Created AntiRush multisource lock with targetname: " + AntiRushLock.GetTargetname() + "\n" );
    }

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
        g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "" + SoundName, 0.5f, ATTN_NORM );

        if( AntiRushIcon !is null )
        {
           	AntiRushIcon.pev.rendercolor = Vector(0, 255, 0);
            EHandle hIconHandle = AntiRushIcon;
            if( fl_FadeTime != 0 )
            {
                g_Scheduler.SetTimeout( this, "RemoveIcon", fl_FadeTime, hIconHandle );
            }
       	}
        g_Scheduler.SetTimeout( this, "TargetFuncs", fl_TargetDelay );
	}

    void TargetFuncs()
    {
        self.SUB_UseTargets( @self, USE_ON, 0 );

        CBaseEntity@ pKillTargetEnt = null;
        if( KillTarget != "" || KillTarget != self.GetTargetname() )
        {
            while( ( @pKillTargetEnt = g_EntityFuncs.FindEntityByTargetname( pKillTargetEnt, "" + KillTarget ) ) !is null )
            {
                g_EntityFuncs.Remove( pKillTargetEnt );
            }
        }
    }

    void RemoveIcon(EHandle hIconHandle)
    {
        if( !hIconHandle )
            return;

        g_EntityFuncs.Remove( hIconHandle.GetEntity() );
    }
}

void RegisterAntiRushEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "anti_rush", "anti_rush" );
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_once_mp", "trigger_once_mp" );
    g_CustomEntityFuncs.RegisterCustomEntity( "func_wall_custom", "func_wall_custom" );
}