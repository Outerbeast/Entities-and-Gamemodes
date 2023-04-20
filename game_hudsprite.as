/* game_hudsprite- Custom entity for drawing hud sprites
	By Outerbeast
	Ideal for intro logos for maps

	Installation:-
	- Place in scripts/maps
	- Add
	map_script game_hudsprite
	to your map cfg
	OR
	- Add
	#include "game_hudsprite"
	to your main map script header
	OR
	- Create a trigger_script with these keys set in your map:
	"classname" "trigger_script"
	"m_iszScriptFile" "game_hudsprite"

	Usage:-
	Follow the guide for game_text to check for positioning, colouration and timing, since this entity uses the same values: https://wiki.svencoop.com/Game_text
	"spritename" key is used for the path and filename of the sprite to display, the path already begins in svencoop/sprites, so your value can be "mysubfolder/mysprite.spr"

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

	Flags:-
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
bool blGameHudSpriteRegistered = RegisterGameHudSpriteEntity();

bool RegisterGameHudSpriteEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "game_hudsprite", "game_hudsprite" );
	return g_CustomEntityFuncs.IsCustomEntity( "game_hudsprite" );
}

final class game_hudsprite : ScriptBaseEntity
{
	private HUDSpriteParams hudspr;

	game_hudsprite()
	{
		hudspr.spritename;
		hudspr.x;
		hudspr.y;
		hudspr.left;
		hudspr.top;
		hudspr.width;
		hudspr.height;
		hudspr.effect = HUD_EFFECT_NONE;
		hudspr.frame;
		hudspr.numframes;
		hudspr.framerate;
		hudspr.fadeinTime;
		hudspr.fadeoutTime;
		hudspr.holdTime;
		hudspr.fxTime;
		hudspr.color1 = RGBA( 255, 255, 255, 255 );
		hudspr.color2 = RGBA( 255, 255, 255, 255 );
		hudspr.channel;
		hudspr.flags = HUD_ELEM_SCR_CENTER_X;
	}

  	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "spritename" ) 
			hudspr.spritename = szValue;
		else if( szKey == "x" ) 
			hudspr.x = atof( szValue );
		else if( szKey == "y" ) 
			hudspr.y = atof( szValue );
		else if( szKey == "left" ) 
			hudspr.left = int8(Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "top" ) 
			hudspr.top = int8(Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "width" ) 
			hudspr.width = int16(Math.clamp( 0, 512, atoi( szValue ) ) );
		else if( szKey == "height" ) 
			hudspr.height = int16(Math.clamp( 0, 512, atoi( szValue ) ) );
		else if( szKey == "numframes" ) 
			hudspr.numframes = int8(Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "channel" ) 
			hudspr.channel = Math.clamp( 0, 15, atoi( szValue ) );
		else if( szKey == "fadein" ) 
			hudspr.fadeinTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "fadeout" ) 
			hudspr.fadeoutTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "holdtime" ) 
			hudspr.holdTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "fx" ) 
			hudspr.effect = int8(Math.clamp( 0, 8, atoi( szValue ) ) );
		else if( szKey == "fxtime" ) 
			hudspr.fxTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "color1" ) 
			hudspr.color1 = StringToRGBA( szValue );
		else if( szKey == "color2" ) 
			hudspr.color2 = StringToRGBA( szValue );
		else
			return BaseClass.KeyValue( szKey, szValue );

		return true;
  	}

	void Precache()
	{
		g_Game.PrecacheGeneric( "sprites/" + hudspr.spritename );
		BaseClass.Precache();
	}

	void Spawn()
	{
		self.Precache();
		self.pev.movetype  = MOVETYPE_NONE;
		self.pev.solid     = SOLID_NOT;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		hudspr.frame = int8( Math.clamp( 0, 255, atoi( self.pev.frame ) ) );
		hudspr.framerate = Math.clamp( 0.0f, 360.0f, atof( self.pev.framerate ) );
		hudspr.flags = self.pev.spawnflags;

		BaseClass.Spawn();
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
			g_PlayerFuncs.HudCustomSprite( cast<CBasePlayer@>( pActivator ), hudspr );
		else if( self.pev.target == "!caller" && pCaller !is null )
			g_PlayerFuncs.HudCustomSprite( cast<CBasePlayer@>( pCaller ), hudspr );
		else
			g_PlayerFuncs.HudCustomSprite( null, hudspr );
	}
}
/* My humble thanks to the folks in the Sven Co-op discord for helping create this script:
- H2
- Kerncore
- Neo 
- _RC 
- Admer456
their efforts will not go unappreciated :) */