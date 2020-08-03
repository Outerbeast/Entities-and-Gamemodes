/* game_hudsprite- Custom entity for drawing hud sprites
By Outerbeast
Ideal for intro logos for maps
*/

class game_hudsprite : ScriptBaseEntity
{
	string SpriteName 	= "";
  
	int16 Width		= 0;
	int16 Height		= 0;

	uint8 LeftOffset 	= 0;
	uint8 TopOffset 	= 0;
	uint8 Effect		= 0;
	uint8 Frame		= 0;
	uint8 NumFrames		= 0;
	uint8 Channel		= 0;

	float xPos		= 0.0f;
	float yPos		= 0.0f;
	float Fps		= 0.0f;
	float FadeinTime	= 0.0f;
	float FadeoutTime	= 0.0f;
	float HoldTime		= 0.0f;
	float EffectTime	= 0.0f;

	RGBA Color1(255, 255, 255, 255);
	RGBA Color2(255, 255, 255, 255);

	RGBA StringToRGBA(string& in szColor)
	{
    		array<string> arrValues = (szColor + " 0 0 0 0").Split(" ");
    		return RGBA(atoi(arrValues[0]), atoi(arrValues[1]), atoi(arrValues[2]), atoi(arrValues[3]));
	}

  	bool KeyValue( const string& in szKey, const string& in szValue )
	{
    	if( szKey == "spritename" ) 
    	{
			SpriteName = szValue;
			return true;
    	}
    	else if( szKey == "x" ) 
    	{
			xPos = atof( szValue );
			return true;
    	}
    	else if( szKey == "y" ) 
    	{
			yPos = atof( szValue );
			return true;
    	}
	else if( szKey == "left" ) 
    	{
			LeftOffset = atoi( szValue );
			return true;
    	}
	else if( szKey == "top" ) 
    	{
			TopOffset = atoi( szValue );
			return true;
    	}
	else if( szKey == "width" ) 
    	{
			Width = atoi( szValue );
			return true;
    	}
    	else if( szKey == "height" ) 
    	{
			Height = atoi( szValue );
			return true;
    	}
    	else if( szKey == "frames" ) 
    	{
			Frame = atoi( szValue );
			return true;
    	}
    	else if( szKey == "numframes" ) 
    	{
			NumFrames = atoi( szValue );
			return true;
    	}
    	else if( szKey == "channel" ) 
    	{
			Channel = atoi( szValue );
			return true;
    	}
    	else if( szKey == "fadein" ) 
    	{
			FadeinTime = atof( szValue );
			return true;
    	}
    	else if( szKey == "fadeout" ) 
    	{
			FadeoutTime = atof( szValue );
			return true;
    	}
    	else if( szKey == "holdtime" ) 
    	{
			HoldTime = atof( szValue );
			return true;
    	}
	else if( szKey == "fx" ) 
    	{
			Effect = atof( szValue );
			return true;
    	}
    	else if( szKey == "fxtime" ) 
    	{
			EffectTime = atof( szValue );
			return true;
    	}
    	else if( szKey == "color1" ) 
    	{
			Color1 = StringToRGBA( szValue );
			return true;
    	}
    	else if( szKey == "color2" ) 
    	{
			Color2 = StringToRGBA( szValue );
			return true;
    	}
   	else
      		return BaseClass.KeyValue( szKey, szValue );
  	}

	void Precache()
	{
		g_Game.PrecacheModel( SpriteName );
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
		HUDSpriteParams keys;
	
		keys.spritename		= "" + SpriteName;
		keys.x			= xPos;
		keys.y			= yPos;
		keys.left		= LeftOffset;
		keys.top		= TopOffset;
		keys.width		= Width;
		keys.height		= Height;
		keys.effect		= Effect;
		keys.frame		= Frame;
		keys.numframes		= NumFrames;
		keys.framerate		= Fps;
		keys.fadeinTime 	= FadeinTime;
		keys.holdTime		= HoldTime;
		keys.fadeoutTime	= FadeoutTime;
		keys.fxTime		= EffectTime;
		keys.color1		= Color1;
		keys.color2		= Color2;
		keys.channel		= Channel;
		keys.flags		= self.pev.spawnflags;

		g_PlayerFuncs.HudCustomSprite( null, keys );
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
