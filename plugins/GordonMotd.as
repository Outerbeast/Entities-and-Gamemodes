/* Gordon MOTD Welcome Animation
Plays dancing Gordon animation with welcome message in your selected maps
Edit GordonMotd_conf to customise the model and music played

Model by: ra4fhe
Original AMXX plugin by: KORD_12.7
*/

#include "GordonMotd_conf"

bool blMusicEnabled;
bool blWelcomeEnabledè;

EHandle hMusic;

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
                        blWelcomeEnabled = true;
		}
	}
	else
        {
		blMusicEnabled = false;
                blWelcomeEnabled = false;
	}
}

void MapStart()
{
	if( blMusicEnabled )
	{
		PlayMusic();
	}
}

HookReturnCode DrawGordonAnimation(CBasePlayer@ pPlayer)
{
    if( blWelcomeEnabled )
       pPlayer.pev.viewmodel = WelcomeModel;
	
    if( hMusic.GetEntity() !is null )
    {
	    FireTargets( hMusic.GetEntity().GetTargetname(), CBaseEntity@ pActivator, null, null, 0.0f, 0.0f );
            g_EntityFuncs.Remove( hMusic.GetEntity() );
    }
return HOOK_CONTINUE;
}

void PlayMusic()
{
	dictionary music;
	music ["targetname"]	= ( "welkum_muzak" );
	music ["message"]	= ( "" + WelcomeMusic );
	music ["volume"]	= ( "" + flMusicVolume );
	music ["spawnflags"]	= ( "3" );
	CBaseEntity@ pMusic = g_EntityFuncs.CreateEntity( "ambient_music", music, true );
	EHandle hMusic = pMusic;
}
