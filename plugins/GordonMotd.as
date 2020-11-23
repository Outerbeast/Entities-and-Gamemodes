/* Gordon MOTD Welcome Animation
Plays dancing Gordon animation with welcome message in your selected maps
Edit GordonMotd_conf to customise the model and music played

Model by: ra4fhe
Original AMXX plugin by: KORD_12.7
*/

#include "GordonMotd_conf"

bool blMusicEnabled;
bool blMusicTriggered;
bool blWelcomeEnabled;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Outerbeast" );
	g_Module.ScriptInfo.SetContactInfo( "svencoopedia.fandom.com" );

	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @DrawGordonAnimation );
}

void MapInit()
{
	if( LOBBY_MAPS.find( string(g_Engine.mapname) ) >= 0 )
	{
		if( strWelcomeMusic != "" )
		{
			g_SoundSystem.PrecacheSound( strWelcomeMusic );
			blMusicEnabled = true;
		}

		if( strWelcomeModel != "" )
		{
			g_Game.PrecacheModel( strWelcomeModel );
			blWelcomeEnabled = true;
		}
	}
	else
	{
		blMusicEnabled = false;
		blWelcomeEnabled = false;
	}
}

void MapActivate()
{
	dictionary music;
	music ["targetname"]	= ( "welkum_muzak" );
	music ["message"]		= ( "" + strWelcomeMusic );
	music ["volume"]		= ( "" + flMusicVolume );
	music ["spawnflags"]	= ( "3" );
	CBaseEntity@ pWelcomeMusic = g_EntityFuncs.CreateEntity( "ambient_music", music, true );
}

HookReturnCode DrawGordonAnimation(CBasePlayer@ pPlayer)
{
	if( pPlayer !is null )
	{
		if( blWelcomeEnabled )
			pPlayer.pev.viewmodel = strWelcomeModel;
		
		if( blMusicEnabled && !blMusicTriggered )
		{
			g_EntityFuncs.FireTargets( "welkum_muzak", null, null, USE_ON, 0.0f, 0.0f );
			blMusicTriggered = true;
		}
	}
	return HOOK_CONTINUE;
}
