/* game_hudsprite- Custom entity for drawing hud sprites
By Outerbeast
Ideal for intro logos for maps
*/

class game_hudsprite : ScriptBaseEntity
{
	private HUDSpriteParams m_hsp;

	game_hudsprite()
	{
		m_hsp.spritename	= "";
		m_hsp.x 		= 0.0f;
		m_hsp.y			= 0.0f;
		m_hsp.left 		= 0;
		m_hsp.top		= 0;
		m_hsp.width		= 0;
		m_hsp.height		= 0;
		m_hsp.effect		= 0;
		m_hsp.frame 		= 0;
		m_hsp.numframes		= 0;
		m_hsp.framerate		= 0.0f;
		m_hsp.fadeinTime 	= 0.0f;
		m_hsp.fadeoutTime 	= 0.0f;
		m_hsp.holdTime		= 0.0f;
		m_hsp.fxTime 		= 0.0f;
		m_hsp.color1		= RGBA(255, 255, 255, 255);
		m_hsp.color2		= RGBA(255, 255, 255, 255);
		m_hsp.channel		= 0;
		m_hsp.flags		= 0;
	}
	
	RGBA StringToRGBA(string& in szColor)
	{
    	array<string> arrValues = (szColor + " 0 0 0 0").Split(" ");
    	return RGBA(atoi(arrValues[0]), atoi(arrValues[1]), atoi(arrValues[2]), atoi(arrValues[3]));
	}

  	bool KeyValue( const string& in szKey, const string& in szValue )
	{
    		if( szKey == "spritename" ) 
			m_hsp.spritename = szValue;
    		else if( szKey == "x" ) 
			m_hsp.x = atof( szValue );
    		else if( szKey == "y" ) 
			m_hsp.y = atof( szValue );
		else if( szKey == "left" ) 
			m_hsp.left = int8(Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "top" ) 
			m_hsp.top =  int8(Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "width" ) 
			m_hsp.width = int16(Math.clamp( 0, 512, atoi( szValue ) ) );
    		else if( szKey == "height" ) 
			m_hsp.height = int16(Math.clamp( 0, 512, atoi( szValue ) ) );
    		else if( szKey == "frame" ) 
			m_hsp.frame =  int8(Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "fps" ) 
			m_hsp.framerate =  Math.clamp(0.0f, 360.0f, atof( szValue ) );
    		else if( szKey == "numframes" ) 
			m_hsp.numframes =  int8(Math.clamp( 0, 255, atoi( szValue ) ) );
    		else if( szKey == "channel" ) 
			m_hsp.channel =  Math.clamp( 0, 15, atoi( szValue ) );
    		else if( szKey == "fadein" ) 
			m_hsp.fadeinTime = Math.clamp(0.0f, 360.0f, atof( szValue ) );
    		else if( szKey == "fadeout" ) 
			m_hsp.fadeoutTime = Math.clamp(0.0f, 360.0f, atof( szValue ) );
    		else if( szKey == "holdtime" ) 
			m_hsp.holdTime = Math.clamp(0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "fx" ) 
			m_hsp.effect = int8(Math.clamp( 0, 8, atoi( szValue ) ) );
    		else if( szKey == "fxtime" ) 
			m_hsp.fxTime = Math.clamp(0.0f, 360.0f, atof( szValue ) );
    		else if( szKey == "color1" ) 
			m_hsp.color1 = StringToRGBA( szValue );
    		else if( szKey == "color2" ) 
			m_hsp.color2 = StringToRGBA( szValue );
		else
      		return BaseClass.KeyValue( szKey, szValue );

		return true;
  	}

	void Precache()
	{
		g_Game.PrecacheModel( m_hsp.spritename );
	}

	void Spawn()
	{
		Precache();
    		self.pev.movetype  = MOVETYPE_NONE;
    		self.pev.solid     = SOLID_NOT;
    
    		g_EntityFuncs.SetOrigin( self, self.pev.origin );
  	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		m_hsp.flags = self.pev.spawnflags;
		g_PlayerFuncs.HudCustomSprite( null, m_hsp );
	}
}

void RegisterGameHudSpriteEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "game_hudsprite", "game_hudsprite" );
}

/* My humble thanks to the folks in the Sven Co-op discord for helping create this script:
-H2
-Kerncore
-Neo 
-_RC 
-Admer456
their efforts will not go unappreciated :) */
