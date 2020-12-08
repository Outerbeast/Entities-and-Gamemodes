/* AntiRush custom entity 
by Outerbeast
A percent player trigger zone can be set using "zonecornermin/max" coords and percentage of players required to trigger
Percentage marker is red and will turn green with a bell sound when triggered, and will trigger its target.
Supports use of "strKillTarget", "delay" and locking entities with "master" key
Marker model/sprite and bell sound can be customised with the "icon" and "sound" keys

This script uses the custom entities "trigger_once/multiple_mp" and "func_wall_custom", programmed by CubeMath
Those scripts must already be installed for this one to work
*/

#include "cubemath/trigger_once_mp"
#include "cubemath/trigger_multiple_mp"
#include "cubemath/func_wall_custom"

class anti_rush : ScriptBaseEntity
{
    private CBaseEntity@ pAntiRushBarrier, pAntiRushIcon;

    private string strIconName             = "sprites/adamr/arrow_gohere.spr"; // Placeholder default icon, use your own custom one
    private string strSoundName            = "buttons/bell1.wav";
    private string strPercentTriggerType   = "trigger_once_mp";
    private string strMasterName, strKillTarget;

    private Vector vZoneCornerMin, vZoneCornerMax, vBlockerCornerMin, vBlockerCornerMax;

    private float flPercentRequired, flTargetDelay, flTriggerWait;
    private float flFadeTime = 5.0f;

    private uint iVpType = 0;

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if( szKey == "icon" ) 
		{
			strIconName = szValue;
			return true;
		}
		else if( szKey == "sound" ) 
		{
			strSoundName = szValue;
			return true;
		}
        else if( szKey == "icon_drawtype" ) 
		{
			iVpType = atoi( szValue );
			return true;
		}
        else if( szKey == "master" ) 
		{
			strMasterName = szValue;
			return true;
		}
        else if( szKey == "killtarget" ) 
		{
			strKillTarget = szValue;
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
        g_Game.PrecacheGeneric( "" + strIconName );
        g_SoundSystem.PrecacheSound( "" + strSoundName );
	}

	void Spawn()
	{
        self.Precache();
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
        // Configuring the settings for each antirush component
        if( flTriggerWait > 0.0f ){ strPercentTriggerType = "trigger_multiple_mp"; }
        else
            strPercentTriggerType = "trigger_once_mp";

        if( self.GetTargetname() != "" && flPercentRequired > 0.01f )
        {   
            if( vZoneCornerMin != g_vecZero && vZoneCornerMax != g_vecZero )
            {
                if(vZoneCornerMin != vZoneCornerMax )
                    CreatePercentPlayerTrigger();
            }
        }
   
        if( vBlockerCornerMin != g_vecZero && vBlockerCornerMax != g_vecZero ) 
        {
            if( vBlockerCornerMin != vBlockerCornerMax )
                CreateBarrier();
        }

        if( self.pev.rendercolor == g_vecZero ){ self.pev.rendercolor = Vector( 255, 0, 0 ); }
        if( self.pev.scale <= 0 ){ self.pev.scale = 0.15; }
        CreateIcon();

        if( self.pev.target != "" || self.pev.target != self.GetTargetname() ){ CreateLock(); }
	}
    // Creating auxilliary entities required for antirush logic
    void CreatePercentPlayerTrigger()
    {
        dictionary trgr;
        trgr ["minhullsize"]        = ( "" + vZoneCornerMin.ToString() );
        trgr ["maxhullsize"]        = ( "" + vZoneCornerMax.ToString() );
        trgr ["m_flPercentage"]     = ( "" + flPercentRequired );
        trgr ["target"]             = ( "" + self.GetTargetname() );
        if( strMasterName != "" || strMasterName != "" + self.GetTargetname() ){ trgr ["master"] = ( "" + strMasterName ); }
        if( strPercentTriggerType == "trigger_multiple_mp" ){ trgr ["m_flDelay"] = ( "" + flTriggerWait ); }
	    CBaseEntity@ pPercentPlayerTrigger = g_EntityFuncs.CreateEntity( "" + strPercentTriggerType, trgr, true );
    }

    void CreateBarrier()
    {
        dictionary wall =
        {
            { "minhullsize", "" + vBlockerCornerMin.ToString() },
            { "maxhullsize", "" + vBlockerCornerMax.ToString() }
        };
        @pAntiRushBarrier = g_EntityFuncs.CreateEntity( "func_wall_custom", wall, true );
    }

    void CreateIcon()
    {
        dictionary spr;
        spr ["origin"]          = ( "" + self.GetOrigin().ToString() );
        spr ["angles"]          = ( "" + self.pev.angles.ToString() );
        spr ["model"]           = ( "" + strIconName );
        spr ["vp_type"]         = ( "" + iVpType );
        spr ["scale"]           = ( "" + self.pev.scale );
	    spr ["rendercolor"]     = ( "" + self.pev.rendercolor.ToString() );
        spr ["renderamt"]       = ( "255" );
        spr ["rendermode"]      = ( "5" );
	    @pAntiRushIcon = g_EntityFuncs.CreateEntity( "env_sprite", spr, true );
        pAntiRushIcon.Think();
    }

    void CreateLock()
    {
        dictionary ms = { { "targetname", "" + self.pev.target } };
        CBaseEntity@ pAntiRushLock = g_EntityFuncs.CreateEntity( "multisource", ms, true );   
        pAntiRushLock.Think();
    }
    // Main triggering business
	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
        if( pAntiRushIcon !is null )
        {
            g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "" + strSoundName, 0.5f, ATTN_NORM );
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

        CBaseEntity@ pKillTargetEnt;
        if( strKillTarget != "" || strKillTarget != self.GetTargetname() )
        {
            while( ( @pKillTargetEnt = g_EntityFuncs.FindEntityByTargetname( pKillTargetEnt, "" + strKillTarget ) ) !is null )
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