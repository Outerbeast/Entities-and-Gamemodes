/* Custom entity for displaying an antirush marker in your map
Marker is red and will turn green with a bell sound when triggered, and will trigger its target.
Supports use of "killtarget" and "delay"
Marker model/sprite and bell sound can be customised with the "Icon" and "sound" spr
Can be used in conjunction with the custom antirush trigger "trigger_once_mp" by CubeMath
- Outerbeast */

class info_antirush : ScriptBaseEntity
{
    	private string IconName         = "sprites/adamr/arrow_gohere.spr"; // Placeholder default Icon, use your own custom one
    	private string Sound            = "buttons/bell1.wav";
    	private string KillTarget       = "";
        private string Slave            = "";
    	private float fl_FadeTime       = 5.0f;
    	private float fl_TargetDelay    = 0.0f;

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if( szKey == "Icon" ) 
		{
			IconName = szValue;
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
        else if( szKey == "slave" ) 
		{
			Slave = szValue;
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
        CreateLock();
        CreateIcon();
	}

    	void CreateIcon()
    	{
        	dictionary spr;
        	spr ["origin"]         = ( "" + string(self.pev.origin.x) + " " + string(self.pev.origin.y) + " " + string(self.pev.origin.z) );
        	spr ["angles"]         = ( "" + string(self.pev.angles.x) + " " + string(self.pev.angles.y) + " " + string(self.pev.angles.z) );
		    spr ["targetname"]     = ( "" + self.pev.targetname + "_spr" );
        	spr ["model"]          = ( "" + IconName );
        	spr ["vp_type"]        = ( "0" );
        	spr ["scale"]          = ( "" + self.pev.scale );
		    spr ["rendercolor"]    = ( "255 0 0" );
        	spr ["renderamt"]      = ( "255 255 255" );
        	spr ["rendermode"]     = ( "5" );
		    spr ["spawnflags"] 	   = ( "1" );
		    CBaseEntity@ AntirushPercentIcon = g_EntityFuncs.CreateEntity( "env_sprite", spr, true );
    		AntirushPercentIcon.Think();
    	}

        void CreateLock()
        {
           dictionary ms;
           ms ["targetname"] = ( "" + self.pev.target )
           CBaseEntity AntirushLock = g_EntityFuncs.CreateEntity( "multisource", ms, true );   
           AntirushLock.Think();
        }

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
        	g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "" + Sound, 0.5f, ATTN_NORM );
            // Don't know how to pass in a EHandle for the icon sprite into Use() so I'm having to retrieve the instance from scratch
        	CBaseEntity@ pIconInstance = g_EntityFuncs.FindEntityByTargetname( pIconInstance, "" + self.pev.targetname + "_spr" );
        	if( pIconInstance !is null )
        	{
           		pIconInstance.pev.rendercolor = Vector(0, 255, 0);
            		EHandle hIconHandle = pIconInstance;
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
        	while( ( @pKillTargetEnt = g_EntityFuncs.FindEntityByTargetname( pKillTargetEnt, "" + KillTarget ) ) !is null && KillTarget != "" )
        	{
            		g_EntityFuncs.Remove( pKillTargetEnt );
        	}
    	}

    	void RemoveIcon(EHandle hIconHandle)
    	{
        	g_EntityFuncs.Remove( hIconHandle.GetEntity() );
    	}
}

void RegisterInfoAntiRushEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "info_antirush", "info_antirush" );
}
