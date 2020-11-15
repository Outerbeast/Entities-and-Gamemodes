/* Gordon MOTD Welcome Animation
Plays dancing Gordon animation with welcome message in your selected maps
Edit GordonMotd_conf to customise the model and music played

Model by: ra4fhe
Original AMXX plugin by: KORD_12.7
*/

#include "GordonMotd_conf"

bool blMusicEnabled = false;

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
		if( WelcomeMusic != "" )
		{
			g_SoundSystem.PrecacheSound( WelcomeMusic );
			blMusicEnabled = true;
		}

		if( WelcomeModel != "" )
		{
			g_Game.PrecacheModel( WelcomeModel );
		}
	}
	else
	{
		g_Hooks.RemoveHook( Hooks::Player::PlayerSpawn, @DrawGordonAnimation );
		blMusicEnabled = false;
	}
}

void MapStart()
{
	if( WelcomeMusic != "" && blMusicEnabled )
	{
		PlayMusic();
	}
}

HookReturnCode DrawGordonAnimation(CBasePlayer@ pPlayer)
{
    pPlayer.pev.viewmodel = WelcomeModel;
    return HOOK_CONTINUE;
}

void PlayMusic()
{
	dictionary rly;
	dictionary music;

	rly ["targetname"]		= ( "game_playerspawn" );
	rly ["target"]			= ( "welkum_muzak" );
	rly ["triggerstate"]	= ( "1" );
	rly ["spawnflags"]		= ( "1" );

	music ["targetname"]	= ( "welkum_muzak" );
	music ["message"]		= ( "" + WelcomeMusic );
	music ["volume"]		= ( "" + flMusicVolume );
	music ["spawnflags"]	= ( "3" );

	CBaseEntity@ pMusicStart = g_EntityFuncs.CreateEntity( "trigger_relay", rly, true );
	CBaseEntity@ pWelcomeMusic = g_EntityFuncs.CreateEntity( "ambient_music", music, true );
}
