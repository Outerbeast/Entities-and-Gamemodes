/* Custom entity for displaying an antirush marker in your map
Marker is red and will turn green with a bell sound when triggered, and will trigger its target.
Supports use of "killtarget" and "delay"
Marker model/sprite and bell sound can be customised with the "logo" and "sound" keys
Can be used in conjunction with the custom antirush trigger "trigger_once_mp" by CubeMath
- Outerbeast */

class info_antirush : ScriptBaseEntity
{
    string LogoName         = "sprites/adamr/arrow_gohere.spr"; // Placeholder default logo, use your own custom one
    string Sound            = "buttons/bell1.wav";
    string KillTarget       = "";
    float fl_FadeTime      = 5.0f;
    float fl_TargetDelay    = 0.0f;

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if( szKey == "logo" ) 
		{
			LogoName = szValue;
			return true;
		}
		else if( szKey == "sound" ) 
		{
			Sound = szValue;
			return true;
		}
        else if( szKey == "killtarget" ) 
		{
			KillTarget = szValue;
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
        g_Game.PrecacheModel( "" + LogoName );
		g_SoundSystem.PrecacheSound( "" + Sound );
	}

	void Spawn()
	{
        Precache();
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.scale == 0)
        {
            self.pev.scale = 0.15;
        }

        CreateLogo();
	}

    void CreateLogo()
    {
        dictionary keys;
        keys ["origin"]         = ( "" + string(self.pev.origin.x) + " " + string(self.pev.origin.y) + " " + string(self.pev.origin.z) );
        keys ["angles"]         = ( "" + string(self.pev.angles.x) + " " + string(self.pev.angles.y) + " " + string(self.pev.angles.z) );
		keys ["targetname"]     = ( "" + self.pev.targetname + "_spr" );
        keys ["model"]          = ( "" + LogoName );
        keys ["vp_type"]        = ( "0" );
        keys ["scale"]          = ( "" + self.pev.scale );
		keys ["rendercolor"]    = ( "255 0 0" );
        keys ["renderamt"]      = ( "255 255 255" );
        keys ["rendermode"]     = ( "5" );
		keys ["spawnflags"] 	= ( "1" );
		CBaseEntity@ AntirushPercentLogo = g_EntityFuncs.CreateEntity( "env_sprite", keys, true );
    	AntirushPercentLogo.Think();

		g_EngineFuncs.ServerPrint( "-- DEBUG: Created AntirushPercentLogo:  " + AntirushPercentLogo.pev.targetname + " \n");
    }

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
        g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "" + Sound, 0.5f, ATTN_NORM );

        CBaseEntity@ pLogoInstance = g_EntityFuncs.FindEntityByTargetname( pLogoInstance, "" + self.pev.targetname + "_spr" );
        if( pLogoInstance !is null )
        {
            pLogoInstance.pev.rendercolor = Vector(0, 255, 0);
            EHandle hLogoHandle = pLogoInstance;
            if( fl_FadeTime != 0 )
            {
                g_Scheduler.SetTimeout( this, "RemoveLogo", fl_FadeTime, hLogoHandle );
            }
        }
        g_Scheduler.SetTimeout( this, "TargetFuncs", fl_TargetDelay );
	}

    void TargetFuncs()
    {
        self.SUB_UseTargets( @self, USE_ON, 0 );

        CBaseEntity@ pKillTargetEnt = null;
        while( ( @pKillTargetEnt = g_EntityFuncs.FindEntityByTargetname( pKillTargetEnt, "" + KillTarget ) ) !is null && KillTarget != "" )
        {
            g_EntityFuncs.Remove( pKillTargetEnt );
        }
    }

    void RemoveLogo(EHandle hLogoHandle)
    {
        g_EntityFuncs.Remove( hLogoHandle.GetEntity() );
    }
}

void RegisterInfoAntiRushEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "info_antirush", "info_antirush" );
}
