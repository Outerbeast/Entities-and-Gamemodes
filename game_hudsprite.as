/* game_hudsprite- Custom entity for drawing hud sprites
By Outerbeast
Ideal for intro logos for maps

See below for "fx" and "spawnflags" settings
"fx" "e":-

HUD_EFFECT_NONE 		0 	No effect. (Default setting)
HUD_EFFECT_RAMP_UP 		1 	Linear ramp up from color1 to color2.
HUD_EFFECT_RAMP_DOWN 	2 	Linear ramp down from color2 to color1.
HUD_EFFECT_TRIANGLE 	3 	Linear ramp up and ramp down from color1 through color2 back to color1.
HUD_EFFECT_COSINE_UP 	4 	Cosine ramp up from color1 to color2.
HUD_EFFECT_COSINE_DOWN 	5 	Cosine ramp down from color2 to color1.
HUD_EFFECT_COSINE 		6 	Cosine ramp up and ramp down from color1 through color2 back to color1.
HUD_EFFECT_TOGGLE 		7 	Toggle between color1 and color2.
HUD_EFFECT_SINE_PULSE 	8 	Sine pulse from color1 through zero to color2.

"spawnflags" "f":-

HUD_ELEM_ABSOLUTE_X 		1 		X position in pixels.
HUD_ELEM_ABSOLUTE_Y 		2 		Y position in pixels.
HUD_ELEM_SCR_CENTER_X 		4 		X position relative to the center of the screen. (Set this flag if you are not using any other ones, always)
HUD_ELEM_SCR_CENTER_Y 		8 		Y position relative to the center of the screen.
HUD_ELEM_NO_BORDER 			16 		Ignore the client-side HUD border (hud_bordersize).
HUD_ELEM_HIDDEN 			32 		Create a hidden element.
HUD_ELEM_EFFECT_ONCE 		64 		Play the effect only once.
HUD_ELEM_DEFAULT_ALPHA 		128 	Use the default client-side HUD alpha (hud_defaultalpha).
HUD_ELEM_DYNAMIC_ALPHA 		256 	Use the default client-side HUD alpha and flash the element when updated.
HUD_SPR_OPAQUE 				65536 	Draw opaque sprite.
HUD_SPR_MASKED 				131072 	Draw masked sprite.
HUD_SPR_PLAY_ONCE 			262144 	Play the animation only once.
HUD_SPR_HIDE_WHEN_STOPPED 	524288 	Hide the sprite when the animation stops.
*/
void RegisterGameHudSpriteEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "game_hudsprite", "game_hudsprite" );
}

class game_hudsprite : ScriptBaseEntity
{
	private HUDSpriteParams m_hsp;

	game_hudsprite()
	{
		m_hsp.spritename;
		m_hsp.x;
		m_hsp.y;
		m_hsp.left;
		m_hsp.top;
		m_hsp.width;
		m_hsp.height;
		m_hsp.effect;
		m_hsp.frame;
		m_hsp.numframes;
		m_hsp.framerate;
		m_hsp.fadeinTime;
		m_hsp.fadeoutTime;
		m_hsp.holdTime;
		m_hsp.fxTime;
		m_hsp.color1 = RGBA( 255, 255, 255, 255 );
		m_hsp.color2 = RGBA( 255, 255, 255, 255 );
		m_hsp.channel;
		m_hsp.flags;
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
			m_hsp.top = int8(Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "width" ) 
			m_hsp.width = int16(Math.clamp( 0, 512, atoi( szValue ) ) );
		else if( szKey == "height" ) 
			m_hsp.height = int16(Math.clamp( 0, 512, atoi( szValue ) ) );
		else if( szKey == "frame" ) 
			m_hsp.frame = int8(Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "fps" ) 
			m_hsp.framerate = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "numframes" ) 
			m_hsp.numframes = int8(Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "channel" ) 
			m_hsp.channel = Math.clamp( 0, 15, atoi( szValue ) );
		else if( szKey == "fadein" ) 
			m_hsp.fadeinTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "fadeout" ) 
			m_hsp.fadeoutTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "holdtime" ) 
			m_hsp.holdTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "fx" ) 
			m_hsp.effect = int8(Math.clamp( 0, 8, atoi( szValue ) ) );
		else if( szKey == "fxtime" ) 
			m_hsp.fxTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
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
		g_Game.PrecacheGeneric( "sprites/" + m_hsp.spritename );
		BaseClass.Precache();
	}

	void Spawn()
	{
		self.Precache();
		self.pev.movetype  = MOVETYPE_NONE;
		self.pev.solid     = SOLID_NOT;

		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		m_hsp.flags = self.pev.spawnflags;
  	}
	// This needs to be a standard API method!!!
	RGBA StringToRGBA(string& in szColor)
	{
		array<string> arrValues = ( szColor + " 0 0 0 0" ).Split( " " );
		return RGBA( atoi( arrValues[0] ), atoi( arrValues[1] ), atoi( arrValues[2] ), atoi( arrValues[3] ) );
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		if( self.pev.target == "!activator" && pActivator !is null )
			g_PlayerFuncs.HudCustomSprite( cast<CBasePlayer@>( pActivator ), m_hsp );
		else if( self.pev.target == "!caller" && pCaller !is null )
			g_PlayerFuncs.HudCustomSprite( cast<CBasePlayer@>( pCaller ), m_hsp );
		else
			g_PlayerFuncs.HudCustomSprite( null, m_hsp );
	}
}
/* My humble thanks to the folks in the Sven Co-op discord for helping create this script:
-H2
-Kerncore
-Neo 
-_RC 
-Admer456
their efforts will not go unappreciated :) */