/* AntiRush custom entity 
by Outerbeast
A percent player trigger zone can be set using "zonecornermin/max" coords and percentage of players required to trigger
Percentage marker is red and will turn green with a bell sound when triggered, and will trigger its target.
Supports use of "killtarget", "delay" and locking entities with "master" key
Marker model/sprite and bell sound can be customised with the "icon" and "sound" keys

This script uses the custom entities "trigger_once/multiple_mp" and "func_wall_custom", programmed by CubeMath
Those scripts must already be installed for this one to work
*/

#include "cubemath/trigger_once_mp"
#include "cubemath/trigger_multiple_mp"
#include "cubemath/func_wall_custom"

class anti_rush : ScriptBaseEntity
{
    private string IconName             = "sprites/adamr/arrow_gohere.spr"; // Placeholder default icon, use your own custom one
    private string SoundName            = "buttons/bell1.wav";
    private string PercentTriggerType   = "trigger_once_mp";
    private string MasterName, KillTarget;

    private uint VpType                 = 0;

    private float flPercentRequired, flTargetDelay, flTriggerWait = 0.0f;
    private float flFadeTime           = 5.0f;

    private Vector vZoneCornerMin, vZoneCornerMax, vBlockerCornerMin, vBlockerCornerMax = Vector( 0, 0, 0 );

    private CBaseEntity@ pAntiRushBarrier, pAntiRushIcon;

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
        else if( szKey == "icon_drawtype" ) 
		{
			VpType = atoi( szValue );
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
        else if( szKey == "blockercornermin" ) 
		{
			g_Utility.StringToVector( vBlockerCornerMin, szValue );
			return true;
		}
         else if( szKey == "blockercornermax" ) 
		{
			g_Utility.StringToVector( vBlockerCornerMax, szValue );
			return true;
		}
        else if( szKey == "percentage" ) 
		{
			flPercentRequired = atof( szValue )*0.01f;
			return true;
		}
        else if( szKey == "wait" )
		{
			flTriggerWait = atof( szValue );
			return true;
		}
        else if( szKey == "delay" )
		{
			flTargetDelay = atof( szValue );
			return true;
		}
		else if( szKey == "fadetime" ) 
		{
			flFadeTime = atof( szValue );
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
        // Configuring the settings for each antirush component
        if( flTriggerWait > 0.0f ){ PercentTriggerType = "trigger_multiple_mp"; }
        else
            PercentTriggerType = "trigger_once_mp";

        if( self.GetTargetname() != "" && flPercentRequired > 0.01f )
        {   
            if( vZoneCornerMin != Vector( 0, 0, 0 ) )
            {
                if( vZoneCornerMax != Vector( 0, 0, 0 ) )
                {
                    if( vZoneCornerMin != vZoneCornerMax )
                    {
                        CreatePercentPlayerTrigger();
                    }
                }
            }
        }
   
        if( vBlockerCornerMin != Vector( 0, 0, 0 ) )
        {
            if( vBlockerCornerMax != Vector( 0, 0, 0 ) )
            {
                if( vBlockerCornerMin != vBlockerCornerMax )
                {
                    CreateBlocker();
                }
            }
        }

        if( self.pev.rendercolor == Vector( 0, 0, 0 ) ){ self.pev.rendercolor = Vector( 255, 0, 0 ); }
        if( self.pev.scale <= 0 ){ self.pev.scale = 0.15; }
        CreateIcon();

        if( self.pev.target != "" || self.pev.target != self.GetTargetname() ){ CreateLock(); }
	}
    // Creating auxilliary entities required for antirush logic
    void CreatePercentPlayerTrigger()
    {
        dictionary trgr;
        trgr ["minhullsize"]        = ( "" + string(vZoneCornerMin.x) + " " + string(vZoneCornerMin.y) + " " + string(vZoneCornerMin.z) );
        trgr ["maxhullsize"]        = ( "" + string(vZoneCornerMax.x) + " " + string(vZoneCornerMax.y) + " " + string(vZoneCornerMax.z) );
        trgr ["m_flPercentage"]     = ( "" + flPercentRequired );
        trgr ["target"]             = ( "" + self.GetTargetname() );
        if( MasterName != "" || MasterName != "" + self.GetTargetname() ){ trgr ["master"] = ( "" + MasterName ); }
        if( PercentTriggerType == "trigger_multiple_mp" ){ trgr ["m_flDelay"] = ( "" + flTriggerWait ); }
	    CBaseEntity@ pPercentPlayerTrigger = g_EntityFuncs.CreateEntity( "" + PercentTriggerType, trgr, true );
    }

    void CreateBlocker()
    {
        dictionary wall;
        wall ["minhullsize"]        = ( "" + string(vBlockerCornerMin.x) + " " + string(vBlockerCornerMin.y) + " " + string(vBlockerCornerMin.z) );
        wall ["maxhullsize"]        = ( "" + string(vBlockerCornerMax.x) + " " + string(vBlockerCornerMax.y) + " " + string(vBlockerCornerMax.z) );
        @pAntiRushBarrier = g_EntityFuncs.CreateEntity( "func_wall_custom", wall, true );
    }

    void CreateIcon()
    {
        dictionary spr;
        spr ["origin"]          = ( "" + string(self.pev.origin.x) + " " + string(self.pev.origin.y) + " " + string(self.pev.origin.z) );
        spr ["angles"]          = ( "" + string(self.pev.angles.x) + " " + string(self.pev.angles.y) + " " + string(self.pev.angles.z) );
        spr ["model"]           = ( "" + IconName );
        spr ["vp_type"]         = ( "" + VpType );
        spr ["scale"]           = ( "" + self.pev.scale );
	    spr ["rendercolor"]     = ( "" + string(self.pev.rendercolor.x) + " " + string(self.pev.rendercolor.y) + " " + string(self.pev.rendercolor.z) );
        spr ["renderamt"]       = ( "255" );
        spr ["rendermode"]      = ( "5" );
	    @pAntiRushIcon = g_EntityFuncs.CreateEntity( "env_sprite", spr, true );
        pAntiRushIcon.Think();
    }

    void CreateLock()
    {
        dictionary ms;
        ms ["targetname"] = ( "" + self.pev.target );
        CBaseEntity@ pAntiRushLock = g_EntityFuncs.CreateEntity( "multisource", ms, true );   
        pAntiRushLock.Think();
    }
    // Main triggering business
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
        if( pAntiRushIcon !is null )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "" + SoundName, 0.5f, ATTN_NORM );
           	pAntiRushIcon.pev.rendercolor = Vector( 0, 255, 0 );
            EHandle hIconHandle = pAntiRushIcon;
            if( flFadeTime > 0 )
            {
                g_Scheduler.SetTimeout( this, "RemoveIcon", flFadeTime, hIconHandle );
            }
       	}

        if( pAntiRushBarrier !is null )
        {
            g_EntityFuncs.Remove( pAntiRushBarrier );
        }

        g_Scheduler.SetTimeout( this, "TargetFuncs", flTargetDelay );
	}

    void TargetFuncs()
    {
        self.SUB_UseTargets( @self, USE_TOGGLE, 0 );

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
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_multiple_mp", "trigger_multiple_mp" );
    g_CustomEntityFuncs.RegisterCustomEntity( "func_wall_custom", "func_wall_custom" );
}

/* Special Thanks to:
- CubeMath for creating the custom entities required for building anti-rush setups 
- Admer456 for coding support
*/