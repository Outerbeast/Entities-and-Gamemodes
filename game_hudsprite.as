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
	"target" key allows the hud sprite draw on specific players whose targetname matches. "!activator" and "!caller" are supported. If not set, the sprite will display for all players.
	Killtargeting this entity will remove all currently displayed hud sprites

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
bool blGamehudSpriteRegistered = RegisterGamehudSpriteEntity();

bool RegisterGamehudSpriteEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "game_hudsprite", "game_hudsprite" );
	return g_CustomEntityFuncs.IsCustomEntity( "game_hudsprite" );
}

final class game_hudsprite : ScriptBaseEntity
{
	private HUDSpriteParams hudSpr, hudNull;
	private bool blToggled;
	private CScheduledFunction@ fnResetToggle;

	game_hudsprite()
	{
		hudSpr.effect = HUD_EFFECT_NONE;
		hudSpr.color1 = hudSpr.color2 = RGBA( 255, 255, 255, 255 );
		hudSpr.flags = HUD_ELEM_SCR_CENTER_X | HUD_ELEM_SCR_CENTER_Y;
	}

  	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if( szKey == "spritename" ) 
			hudSpr.spritename = szValue;
		else if( szKey == "x" ) 
			hudSpr.x = atof( szValue );
		else if( szKey == "y" ) 
			hudSpr.y = atof( szValue );
		else if( szKey == "left" ) 
			hudSpr.left = int8( Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "top" ) 
			hudSpr.top = int8( Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "width" ) 
			hudSpr.width = int16( Math.clamp( 0, 512, atoi( szValue ) ) );
		else if( szKey == "height" ) 
			hudSpr.height = int16( Math.clamp( 0, 512, atoi( szValue ) ) );
		else if( szKey == "numframes" ) 
			hudSpr.numframes = int8( Math.clamp( 0, 255, atoi( szValue ) ) );
		else if( szKey == "channel" ) 
			hudSpr.channel = hudNull.channel = Math.clamp( 0, 15, atoi( szValue ) );
		else if( szKey == "fadein" ) 
			hudSpr.fadeinTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "fadeout" ) 
			hudSpr.fadeoutTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "holdtime" ) 
			hudSpr.holdTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "fx" ) 
			hudSpr.effect = int8( Math.clamp( 0, 8, atoi( szValue ) ) );
		else if( szKey == "fxtime" ) 
			hudSpr.fxTime = Math.clamp( 0.0f, 360.0f, atof( szValue ) );
		else if( szKey == "color1" ) 
			g_Utility.StringToRGBA( hudSpr.color1, szValue );
		else if( szKey == "color2" ) 
			g_Utility.StringToRGBA( hudSpr.color2, szValue );
		else
			return BaseClass.KeyValue( szKey, szValue );

		return true;
  	}

	void Precache()
	{
		g_Game.PrecacheGeneric( "sprites/" + hudSpr.spritename );
		BaseClass.Precache();
	}

	void Spawn()
	{
		self.Precache();
		self.pev.movetype  = MOVETYPE_NONE;
		self.pev.solid     = SOLID_NOT;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		hudSpr.frame = int8( Math.clamp( 0, 255, atoi( self.pev.frame ) ) );
		hudSpr.framerate = Math.clamp( 0.0f, 360.0f, atof( self.pev.framerate ) );
		hudSpr.flags = self.pev.spawnflags;

		BaseClass.Spawn();
  	}

	bool ShouldTurnOff(USE_TYPE utTriggerstate)
	{
		switch( utTriggerstate )
		{
			case USE_TOGGLE: return blToggled;

			case USE_OFF:
			case USE_KILL: 
				return true;

			default: return false;
		}
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		if( self.pev.target != "" && self.pev.target != self.GetTargetname() )
		{
			CBasePlayer@ pTargetPlayer;

			if( self.pev.target == "!activator" && pActivator !is null && pActivator.IsPlayer() )
				@pTargetPlayer = cast<CBasePlayer@>( pActivator );
			else if( self.pev.target == "!caller" && pCaller !is null && pCaller.IsPlayer() )
				@pTargetPlayer = cast<CBasePlayer@>( pCaller );
			else
			{
				for( int iPlayer = 1; iPlayer <= g_Engine.maxClients + 1; iPlayer++ )
				{
					if( iPlayer > g_Engine.maxClients )
					{
						@pTargetPlayer = null;
						break;
					}

					@pTargetPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

					if( pTargetPlayer is null || !pTargetPlayer.IsConnected() || pTargetPlayer.GetTargetname() != self.pev.target )
						continue;

					g_PlayerFuncs.HudCustomSprite( pTargetPlayer, ShouldTurnOff( useType ) ? hudNull : hudSpr );
				}
			}

			if( pTargetPlayer !is null )
				g_PlayerFuncs.HudCustomSprite( pTargetPlayer, ShouldTurnOff( useType ) ? hudNull : hudSpr );
		}
		else
			g_PlayerFuncs.HudCustomSprite( null, ShouldTurnOff( useType ) ? hudNull : hudSpr );

		if( useType == USE_TOGGLE )
			blToggled = !blToggled;
		
		@fnResetToggle = g_Scheduler.SetTimeout( this, "ResetToggle", hudSpr.holdTime );	
	}

	void ResetToggle()
	{
		blToggled = false;
	}

	void UpdateOnRemove()
	{
		g_Scheduler.RemoveTimer( fnResetToggle );
		g_PlayerFuncs.HudCustomSprite( null, hudNull );

		BaseClass.UpdateOnRemove();
	}
};
/* My humble thanks to the folks in the Sven Co-op discord for helping create this script:
- H2
- Kerncore
- Neo 
- _RC 
- Admer456
their efforts will not go unappreciated :) */