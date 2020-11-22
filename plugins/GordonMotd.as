/* Gordon MOTD Welcome Animation
Plays dancing Gordon animation with welcome message in your selected maps
Edit GordonMotd_conf to customise the model and music played

Model by: ra4fhe
Original AMXX plugin by: KORD_12.7
*/

#include "GordonMotd_conf"

bool blMusicEnabled;
bool blWelcomeEnabled;

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
		
HookReturnCode DrawGordonAnimation(CBasePlayer@ pPlayer)
{
    if( blWelcomeEnabled )
       pPlayer.pev.viewmodel = WelcomeModel;
	
    if( blMusicEnabled )
{
    NetworkMessage msg(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, edict);
        msg.WriteString("mp3 loop \""+WelcomeMusic+"\"");
    msg.End();
}

return HOOK_CONTINUE;
}
