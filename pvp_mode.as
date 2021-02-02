/* Sven Co-op PVP Deathmatch Mode Script
- by Outerbeast

Script for enabling friendly fire between players for pvp deathmatch maps
Useful for Half-Life Deathmatch map ports to SC

Usage:-
- Put this script in scripts/maps folder
- In your map cfg file put this code in to enable
map_script pvp_mode
- Add your optional cvars

Map cfg settings:-
"map_script pvp_mode" - install the script to the map
"as_command pvp_spawnprotecttime" - set the time duration in seconds for how long spawn invulnerbility lasts, by default this is 5 if not set
"as_command pvp_viewmode" - set the force viewmode, 0 for first person or 1 for third person, by default this is first person if not set
"as_command pvp_afktimeout" - set the time after a player goes idle to put them into Spectator mode

Chat commands:-
!pvp_spectate - enter Spectator mode
!pvp_player - exit Spectator mode

Issues:-
- Only supports 17 player slots maximum because of limitations imposed by the game + API. 18th player and following will automatically
be moved to Spectator mode until a slot becomes free.
- Some players will have colored usernames in the scoreboard and in chat, this is due to the classification system assigning them to
TEAM classification which apply these colored.
*/

PvpMode@ g_pvpmode = @PvpMode();

CCVar cvarProtectDuration( "pvp_spawnprotecttime", 10.0f, "Duration of spawn invulnerability", ConCommandFlag::AdminOnly );
CCVar cvarViewModeSetting( "pvp_viewmode", 0.0f, "View Mode Setting", ConCommandFlag::AdminOnly );
CCVar cvarAFKTimeoutSetting( "pvp_afktimeout", 20.0f, "AFK timeout before moving to Spectator mode", ConCommandFlag::AdminOnly );

const bool blPlayerSpawnHookRegister = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PvpOnPlayerSpawn );
const bool blPlayerPreThink = g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PvpPlayerPreThink );
const bool blPlayerDisconnectRegister = g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @PvpOnPlayerLeave );
const bool blClientSayRegister = g_Hooks.RegisterHook( Hooks::Player::ClientSay, @PvpPlayerChatCommand );

HookReturnCode PvpOnPlayerSpawn(CBasePlayer@ pPlayer)
{
    return g_pvpmode.OnPlayerSpawn( pPlayer );
}

HookReturnCode PvpPlayerPreThink(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    return g_pvpmode.PlayerPreThink( pPlayer, uiFlags );
}

HookReturnCode PvpOnPlayerLeave(CBasePlayer@ pPlayer)
{
    return g_pvpmode.OnPlayerLeave( pPlayer );
}

HookReturnCode PvpPlayerChatCommand(SayParameters@ pParams)
{
    return g_pvpmode.PlayerChatCommand( pParams );
}

final class PvpMode
{
    array<uint> I_PLAYER_TEAM = { 1, 2, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 17, 18, 19, 99 };
    array<bool> BL_PLAYER_SLOT;
    array<EHandle> H_SPECTATOR;

    PvpMode()
    {
        I_PLAYER_TEAM.resize(33);
        BL_PLAYER_SLOT.resize(33);
        H_SPECTATOR.resize(33);

        g_EngineFuncs.CVarSetFloat( "mp_forcerespawn", 1 );
    }

    HookReturnCode OnPlayerSpawn(CBasePlayer@ pPlayer)
    {   
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
           return HOOK_CONTINUE;

        if( BL_PLAYER_SLOT.find( false ) >= 0 )
        {
            pPlayer.SetClassification( I_PLAYER_TEAM[BL_PLAYER_SLOT.find( false )] );
            BL_PLAYER_SLOT[I_PLAYER_TEAM.find( pPlayer.m_iClassSelection )] = true;
            //g_EngineFuncs.ServerPrint( "-- DEBUG -- Player: " + pPlayer.pev.netname + " in slot: " + I_PLAYER_TEAM.find( pPlayer.m_iClassSelection ) + " was assigned to team: " + pPlayer.m_iClassSelection + "\n" );
        }
        
        EnterSpectator( EHandle( pPlayer ), false );
        g_Scheduler.SetTimeout( this, "SpawnProtection", 0.01f, EHandle( pPlayer ) );

        return HOOK_CONTINUE;
    }

    void SpawnProtection(EHandle hPlayer)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer !is null && pPlayer.m_iClassSelection > 0 )
        {
            pPlayer.SetMaxSpeedOverride( 0 );
            pPlayer.pev.takedamage  = DAMAGE_NO;
            pPlayer.pev.rendermode  = kRenderTransTexture;
            pPlayer.pev.renderamt   = 50.0f;
        }

        g_Scheduler.SetTimeout( this, "ProtectionOff", cvarProtectDuration.GetFloat(), EHandle( pPlayer ) );
    }

    void ProtectionOff(EHandle hPlayer)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer !is null && pPlayer.m_iClassSelection > 0 )
        {
            pPlayer.SetMaxSpeedOverride( -1 );
            pPlayer.pev.takedamage  = DAMAGE_YES;
            pPlayer.pev.rendermode  = kRenderNormal;
            pPlayer.pev.renderamt   = 255.0f;
        }
    }

    bool FlagSet(uint iTargetBits, uint iFlags)
    {
        if( ( iTargetBits & iFlags ) != 0 )
            return true;
        else
            return false;
    }

    HookReturnCode PlayerPreThink(CBasePlayer@ pPlayer, uint& out uiFlags)
    {
        if( pPlayer is null )
            return HOOK_CONTINUE;

        if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
        {
            if( cvarViewModeSetting.GetInt() <= 0 )
                pPlayer.SetViewMode( ViewMode_FirstPerson );
            else
                pPlayer.SetViewMode( ViewMode_ThirdPerson );
        }

        if( pPlayer !is null && pPlayer.GetMaxSpeedOverride() != -1 )
        {
            if( FlagSet( pPlayer.pev.button, IN_ATTACK | IN_ATTACK2 | IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT ) )
                ProtectionOff( EHandle( pPlayer ) );
        }

        if( pPlayer !is null && !pPlayer.IsMoving() )
            g_Scheduler.SetTimeout( this, "AFKTimeout", cvarAFKTimeoutSetting.GetFloat(), EHandle( pPlayer ), pPlayer.m_flLastMove );

        return HOOK_CONTINUE;
    }

    void AFKTimeout(EHandle hPlayer, const float flSpawnLastMove)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
        
        if( pPlayer !is null && flSpawnLastMove == pPlayer.m_flLastMove )
            EnterSpectator( EHandle( pPlayer ), true );
    }

    void EnterSpectator(EHandle hPlayer, const bool blSpectatorOverride)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null || !pPlayer.IsConnected() )
		    return;

        if( !pPlayer.GetObserver().IsObserver() )
        {
            if( !blSpectatorOverride && pPlayer.m_iClassSelection < 1 )
            {
                pPlayer.GetObserver().StartObserver( pPlayer.GetOrigin(), pPlayer.pev.angles, false );
                pPlayer.GetObserver().SetObserverModeControlEnabled( true );
                pPlayer.RemoveAllItems( true );
                g_PlayerFuncs.SayText( pPlayer, "SPECTATING: No player slots available. Please wait." );
            }
            else if( blSpectatorOverride )
            {
                H_SPECTATOR[I_PLAYER_TEAM.find( pPlayer.m_iClassSelection )] = pPlayer;
                BL_PLAYER_SLOT[I_PLAYER_TEAM.find( pPlayer.m_iClassSelection )] = false;

                pPlayer.GetObserver().StartObserver( pPlayer.GetOrigin(), pPlayer.pev.angles, false );
                pPlayer.GetObserver().SetObserverModeControlEnabled( true );
                pPlayer.RemoveAllItems( true );
                g_PlayerFuncs.SayText( pPlayer, "You are in Spectator mode. Type '!pvp_play' to exit." );
            }
        }

        g_Scheduler.SetTimeout( this, "NoRespawn", 0.1f, EHandle( pPlayer ) );
    }
    // "Disables" respawning of players in Spectator Mode (just making the respawn delay stupid long)
    void NoRespawn(EHandle hPlayer)
    {
        if( !hPlayer )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer !is null && pPlayer.GetObserver().IsObserver() )
        { 
            pPlayer.m_flRespawnDelayTime = Math.FLOAT_MAX;
            pPlayer.RemoveAllItems( true );
            // Just to make sure the respawn delay never counts down, keep updating the time in a loop
            g_Scheduler.SetTimeout( this, "NoRespawn", 1.0f, EHandle( pPlayer ) );
        }
    }

    HookReturnCode PlayerChatCommand(SayParameters@ pParams)
    {
        CBasePlayer@ pPlayer = pParams.GetPlayer();
        const CCommand@ cmdArgs = pParams.GetArguments();

        if( pPlayer is null || !pPlayer.IsConnected() )
            return HOOK_CONTINUE;

        if( cmdArgs.ArgC() < 1 || cmdArgs[0][0] != "!pvp_" )
            return HOOK_CONTINUE;

        pParams.set_ShouldHide( true );

        if( cmdArgs[0] == "!pvp_spectate" )
        {
            if( !pPlayer.GetObserver().IsObserver() )
            {
                pPlayer.pev.frags = 0;
                EnterSpectator( EHandle( pPlayer ), true );
                return HOOK_HANDLED;
            }
            else
            {
                g_PlayerFuncs.SayText( pPlayer, "You are already spectating. Type '!pvp_play' to start playing." );
                return HOOK_HANDLED;
            }
        }

        if( cmdArgs[0] == "!pvp_play" )
        {
            if( pPlayer.GetObserver().IsObserver() )
            {
                if( BL_PLAYER_SLOT.find( false ) >= 0 )
                    pPlayer.GetObserver().StopObserver( true );
                else
                    g_PlayerFuncs.SayText( pPlayer, "There are no free slots available yet. Please try again later." );

                return HOOK_HANDLED;
            }
            else
            {
                g_PlayerFuncs.SayText( pPlayer, "You are already playing. Type '!pvp_spectate' to enter Spectator mode." );
                return HOOK_HANDLED;
            }
        }
        return HOOK_CONTINUE;
    }

    HookReturnCode OnPlayerLeave(CBasePlayer@ pDisconnectedPlayer)
    {   
        if( pDisconnectedPlayer is null )
            return HOOK_CONTINUE;

        BL_PLAYER_SLOT[I_PLAYER_TEAM.find( pDisconnectedPlayer.m_iClassSelection )] = false;
        pDisconnectedPlayer.ClearClassification();
        pDisconnectedPlayer.pev.frags = 0;

        CBasePlayer@ pObserverPlayer;
        array<CBaseEntity@> P_SPECTATOR;

        for( uint i = 0; i < H_SPECTATOR.length(); i++ )
            @P_SPECTATOR[i] = H_SPECTATOR[i].GetEntity();

        for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
        {
            if( BL_PLAYER_SLOT.find( false ) < 0 )
               break;

            @pObserverPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

            if( pObserverPlayer is null || !pObserverPlayer.GetObserver().IsObserver() )
                continue;

            if( P_SPECTATOR.find( cast<CBaseEntity@>( pObserverPlayer ) ) > 0 )
                continue;

            pObserverPlayer.GetObserver().StopObserver( true );
        }  
        return HOOK_CONTINUE;
    }
}
/* Special thanks to 
- AnggaraNothing, Zode, Neo and H2 for scripting help
AlexCorruptor for testing and building a test map
Gauna, SV BOY, Jumpy for helping test */