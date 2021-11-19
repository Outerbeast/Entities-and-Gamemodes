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
"map_script pvp_mode"               - install the script to the map
"as_command pvp_spawnprotecttime"   - set the time duration in seconds for how long spawn invulnerbility lasts, by default this is 5 if not set
"as_command pvp_viewmode"           - set the force viewmode, 0 for first person or 1 for third person, by default this is first person if not set
"as_command pvp_killinfo"           - enable or disable hud kill info, enabled by default

Chat commands:-
!pvp_stats - show your stats
!pvp_leave/spectate - enter Spectator mode
!pvp_join/play - exit Spectator mode

Issues:-
- Only supports 17 player slots maximum because of limitations imposed by the game + API. 18th player and following will automatically
be moved to Spectator mode until a slot becomes free.
- Some players will have colored usernames in the scoreboard, this is due to the classification system assigning them to
TEAM classification which apply these colors.
*/
PvpMode g_pvpmode;

CCVar cvarProtectDuration( "pvp_spawnprotecttime", 10.0f, "Duration of spawn invulnerability", ConCommandFlag::AdminOnly );
CCVar cvarViewModeSetting( "pvp_viewmode", 0.0f, "View mode setting", ConCommandFlag::AdminOnly );
CCVar cvarKillInfoSetting( "pvp_killinfo", 1.0f, "Kill hud info", ConCommandFlag::AdminOnly );

const bool blPlayerSpawnHook    = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, PlayerSpawnHook( g_pvpmode.PlayerSpawn ) );
const bool blPlayerPreThink     = g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, PlayerPreThinkHook( g_pvpmode.PlayerPreThink ) );
const bool blPlayerUse          = g_Hooks.RegisterHook( Hooks::Player::PlayerUse, PlayerUseHook( g_pvpmode.PlayerUse ) );
const bool blPlayerTakeDamage   = g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, PlayerTakeDamageHook( g_pvpmode.PlayerTakeDamage ) );
const bool blPlayerKilled       = g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, PlayerKilledHook( g_pvpmode.PlayerKilled ) );
const bool blClientSay          = g_Hooks.RegisterHook( Hooks::Player::ClientSay, ClientSayHook( g_pvpmode.PlayerChatCommand ) );
const bool blClientDisconnect   = g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, ClientDisconnectHook( g_pvpmode.PlayerLeave ) );

final class PvpMode
{
    protected array<uint8> I_PLAYER_TEAM = { 1, 2, 4, 5, 6, 7, 8, 9, 10, 12, 14, 15, 16, 17, 18, 19, 99 };
    protected array<bool> BL_PLAYER_SLOT( g_Engine.maxClients + 1 );
    protected array<EHandle> H_SPECTATORS( g_Engine.maxClients + 1 );

    protected int8 iTotalTeams = I_PLAYER_TEAM.length();

    PvpMode()
    {
        if( I_PLAYER_TEAM.length() < uint( g_Engine.maxClients + 1 ) )
            I_PLAYER_TEAM.resize( g_Engine.maxClients + 1 );

        if( g_EngineFuncs.CVarGetFloat( "mp_forcerespawn" ) < 1 )
            g_EngineFuncs.CVarSetFloat( "mp_forcerespawn", 1 );
    }

    int AssignTeam(EHandle hPlayer, const bool blSetTeam)
    {
        if( !hPlayer )
            return CLASS_NONE;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( blSetTeam && BL_PLAYER_SLOT.find( false ) >= 0 )
        {
            pPlayer.SetClassification( I_PLAYER_TEAM[BL_PLAYER_SLOT.find( false )] );
            BL_PLAYER_SLOT[I_PLAYER_TEAM.find( pPlayer.m_iClassSelection )] = true;
        }
        else if( !blSetTeam ) // For when we want to remove classification from player
        {
            BL_PLAYER_SLOT[I_PLAYER_TEAM.find( pPlayer.m_iClassSelection )] = false;
            pPlayer.SetClassification( CLASS_FORCE_NONE );
        }

        return pPlayer.m_iClassSelection;
    }

    void SpawnProtection(EHandle hPlayer, const int iTakeDamageIn)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null || pPlayer.m_iClassSelection < CLASS_MACHINE )
            return;
        
        pPlayer.pev.takedamage = float( iTakeDamageIn );

        switch( int( pPlayer.pev.takedamage ) )
        {
            case DAMAGE_NO:
            {
                pPlayer.SetMaxSpeedOverride( 0 );
                pPlayer.pev.rendermode  = kRenderTransTexture;
                pPlayer.pev.renderamt   = 100.0f;
                g_Scheduler.SetTimeout( this, "SpawnProtection", cvarProtectDuration.GetFloat(), EHandle( pPlayer ), int( DAMAGE_YES ) );

                break;
            }

            case DAMAGE_YES:
            {
                pPlayer.SetMaxSpeedOverride( -1 );
                pPlayer.pev.rendermode  = pPlayer.m_iOriginalRenderMode;
                pPlayer.pev.renderamt   = pPlayer.m_flOriginalRenderAmount;

                break;
            }
        }
    }

    void EnterSpectator(EHandle hPlayer, const bool blSpectatorOverride)
    {
        if( !hPlayer )
            return;
        
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null || !pPlayer.IsConnected() || pPlayer.GetObserver().IsObserver() )
            return;

        if( !blSpectatorOverride )
        {
            pPlayer.SetMaxSpeedOverride( -1 );
            pPlayer.GetObserver().StartObserver( pPlayer.GetOrigin(), pPlayer.pev.angles, false );
            pPlayer.GetObserver().SetObserverModeControlEnabled( true );
            pPlayer.RemoveAllItems( true );

            g_PlayerFuncs.ShowMessage( pPlayer, "SPECTATING\nNo player slots available. Please wait..." );
        }   // !-BUG-! - Index out of bounds in 2 player slot server - why???? Hence this check.
        else if( blSpectatorOverride && g_Engine.maxClients > 2 )
        {
            H_SPECTATORS[I_PLAYER_TEAM.find( pPlayer.m_iClassSelection )] = pPlayer;
            AssignTeam( EHandle( pPlayer ), false );

            pPlayer.SetMaxSpeedOverride( -1 );
            pPlayer.pev.frags = 0;
            pPlayer.GetObserver().StartObserver( pPlayer.GetOrigin(), pPlayer.pev.angles, false );
            pPlayer.GetObserver().SetObserverModeControlEnabled( true );
            pPlayer.RemoveAllItems( true );

            g_PlayerFuncs.ShowMessage( pPlayer, "You are in Spectator mode.\n\nType '!pvp_play' to exit." );
        }
    }
    // ========================= Hook Funcs - Runs the entire bloody thing ========================= //
    HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
    {   
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
           return HOOK_CONTINUE;

        int iAssignedClassification = AssignTeam( EHandle( pPlayer ), true );

        if( iAssignedClassification < CLASS_MACHINE )
        {
            EnterSpectator( EHandle( pPlayer ), false );
            return HOOK_CONTINUE;
        }
        
        g_Scheduler.SetTimeout( this, "SpawnProtection", 0.01f, EHandle( pPlayer ), int( DAMAGE_NO ) ); // Why delay? Because rendering won't apply on spawn - but WHY.

        return HOOK_CONTINUE;
    }

    HookReturnCode PlayerPreThink(CBasePlayer@ pPlayer, uint& out uiFlags)
    {
        if( pPlayer is null || !pPlayer.IsConnected() )
            return HOOK_CONTINUE;

        if( pPlayer.IsAlive() )
            pPlayer.SetViewMode( PlayerViewMode( cvarViewModeSetting.GetInt() ) );// Utterly retarded. Forced to cast to enum and not the actual value.
        else if( pPlayer.GetObserver().IsObserver() )
            pPlayer.m_flRespawnDelayTime = Math.FLOAT_MAX;
        
        return HOOK_CONTINUE;
    }

    HookReturnCode PlayerUse(CBasePlayer@ pPlayer, uint& out uiFlags)
	{
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            return HOOK_CONTINUE;

        if( pPlayer.GetMaxSpeedOverride() == 0 && 
            pPlayer.m_afButtonPressed & (
            IN_DUCK | 
            IN_JUMP | 
            IN_USE | 
            IN_ATTACK | 
            IN_ATTACK2 | 
            IN_ALT1 | 
            IN_FORWARD | 
            IN_BACK | 
            IN_MOVELEFT | 
            IN_MOVERIGHT ) != 0 )
            SpawnProtection( EHandle( pPlayer ), int( DAMAGE_YES ) );

		return HOOK_CONTINUE;
	}

    HookReturnCode PlayerChatCommand(SayParameters@ pParams)
    {
        if( pParams is null )
            return HOOK_CONTINUE;

        CBasePlayer@ pPlayer = pParams.GetPlayer();
        const CCommand@ cmdArgs = pParams.GetArguments();

        if( pPlayer is null || !pPlayer.IsConnected() )
            return HOOK_CONTINUE;
        // Remove the coloration of player chat messages if they are in TEAM1-4
        if( pPlayer.m_iClassSelection >= CLASS_TEAM1 && pPlayer.m_iClassSelection <= CLASS_TEAM4 )
        {
            pParams.set_ShouldHide( true ); // "Remove" the original chat message
            g_PlayerFuncs.SayTextAll( pPlayer, "" + pPlayer.pev.netname + ": " + cmdArgs.GetCommandString() ); // Replace with decoy
        }

        if( cmdArgs.ArgC() < 1 || cmdArgs[0][0] != "!pvp_" )
            return HOOK_CONTINUE;

        pParams.set_ShouldHide( true );
        
        if( cmdArgs[0] == "!pvp_leave" || cmdArgs[0] == "!pvp_spectate" || cmdArgs[0] == "!pvp_afk" )
        {
            if( !pPlayer.GetObserver().IsObserver() )
            {
                EnterSpectator( EHandle( pPlayer ), true );
                return HOOK_HANDLED;
            }
            else
            {
                g_PlayerFuncs.SayText( pPlayer, "You are already spectating. Type '!pvp_join' to start playing." );
                return HOOK_HANDLED;
            }
        }

        if( cmdArgs[0] == "!pvp_join" || cmdArgs[0] == "!pvp_play" )
        {
            if( pPlayer.GetObserver().IsObserver() )
            {
                if( BL_PLAYER_SLOT.find( false ) <= iTotalTeams )
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

        if( ( cmdArgs[0] == "!pvp_stats" || cmdArgs[0] == "!pvp_info" ) && !pPlayer.GetObserver().IsObserver() )
        {
            string strMyWeapon = pPlayer.m_hActiveItem ? pPlayer.m_hActiveItem.GetEntity().GetClassname().Replace( "weapon_", "" ) : "No weapon selected";
            string strStats =  " -Team: " + pPlayer.m_iClassSelection + " - " + pPlayer.GetClassificationName() + "\n -Points: " + pPlayer.pev.frags + "\n -Deaths: " + pPlayer.m_iDeaths + "\n -Weapon: " + strMyWeapon + "\n";

            HUDTextParams txtStats;
                txtStats.x = 0.7;
                txtStats.y = 0.7;

                txtStats.a1 = 0;

                txtStats.r2 = 250;
                txtStats.g2 = 250;
                txtStats.b2 = 250;
                txtStats.a2 = 1;

                txtStats.fadeinTime = 0.0;
                txtStats.fadeoutTime = 0.0;
                txtStats.holdTime = 10.0;
                txtStats.fxTime = 0.0;
            g_PlayerFuncs.HudMessage( pPlayer, txtStats, "" + pPlayer.pev.netname + "'s Stats:-\n" + strStats );

            return HOOK_HANDLED;            
        }
        return HOOK_CONTINUE;
    }

    HookReturnCode PlayerTakeDamage(DamageInfo@ pDamageInfo)
    {
        if( pDamageInfo is null || pDamageInfo.pVictim is null || pDamageInfo.pAttacker is null || pDamageInfo.pInflictor is null )
            return HOOK_CONTINUE;
        // Prevents goomba-stomp killage
        if( pDamageInfo.bitsDamageType & DMG_CRUSH != 0 && ( pDamageInfo.pAttacker.IsPlayer() || pDamageInfo.pInflictor.IsPlayer() ) )
            pDamageInfo.flDamage = 0.0f;

        return HOOK_CONTINUE;
    }

    HookReturnCode PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib)
    {
        if( pPlayer is null || pAttacker is null )
            return HOOK_CONTINUE;

        AssignTeam( EHandle( pPlayer ), false );

        CBasePlayer@ pAttackingPlayer = cast<CBasePlayer@>( pAttacker );
        string strAttackerWeapon = pAttackingPlayer.m_hActiveItem ? " with: " + pAttackingPlayer.m_hActiveItem.GetEntity().GetClassname().Replace( "weapon_", "" ) : "";
        int iDamageDone = pPlayer.m_lastPlayerDamageAmount >= int( pPlayer.pev.dmg_take ) ? pPlayer.m_lastPlayerDamageAmount : int( pPlayer.pev.dmg_take );

        HUDTextParams txtWinner, txtLoser;
            txtWinner.y = txtLoser.y = 0.6;

            txtLoser.r1 = txtLoser.r2 = 128;
            txtWinner.r1 = 0;

            txtLoser.g1 = 0;
            txtWinner.g1 = txtWinner.g2 = 128;

            txtWinner.b1 = txtLoser.b1 = 0;

            txtWinner.effect = txtLoser.effect = 0;
            txtWinner.fadeinTime = txtLoser.fadeinTime = 0;
            txtWinner.fadeoutTime = txtLoser.fadeoutTime = 0;
            txtWinner.holdTime = txtLoser.holdTime = 3;

            txtWinner.channel = 5;
            txtLoser.channel = 7;
        
        if( pAttackingPlayer !is pPlayer && cvarKillInfoSetting.GetInt() > 0 )
        {
            g_PlayerFuncs.HudMessage( pAttackingPlayer, txtWinner, "You killed\n\n" + string( pPlayer.pev.netname ).ToUppercase() + "\n" + strAttackerWeapon + "\n Damage done: " + iDamageDone + "\n" );
            g_PlayerFuncs.HudMessage( pPlayer, txtLoser, "" + string( pAttackingPlayer.pev.netname ).ToUppercase() + "\nyou" + strAttackerWeapon + "\n Damage taken: " + iDamageDone + "\n" );
        }
        else if( pAttackingPlayer is pPlayer ) // Case player suicided
            g_Scheduler.SetTimeout( this, "EnterSpectator", 0.1f, EHandle( pPlayer ), true );

        return HOOK_CONTINUE;
    }

    HookReturnCode PlayerLeave(CBasePlayer@ pDisconnectedPlayer)
    {   
        if( pDisconnectedPlayer is null )
            return HOOK_CONTINUE;

        AssignTeam( EHandle( pDisconnectedPlayer ), false );
        pDisconnectedPlayer.ClearClassification();
        pDisconnectedPlayer.pev.frags = 0;

        CBasePlayer@ pObserverPlayer;
        array<CBaseEntity@> P_SPECTATORS( H_SPECTATORS.length() );
        // No opEquals/opCmp for EHandle <=> CBaseEntity types, hence the following cursed code
        for( uint i = 0; i < H_SPECTATORS.length(); i++ )
        {
            if( !H_SPECTATORS[i] )
                continue;

            @P_SPECTATORS[i] = H_SPECTATORS[i].GetEntity();
        }

        for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
        {
            if( BL_PLAYER_SLOT.find( false ) < 0 )
               break;

            @pObserverPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

            if( pObserverPlayer is null || !pObserverPlayer.GetObserver().IsObserver() )
                continue;
            // Skip players in the voluntary spectator mode list
            if( P_SPECTATORS.find( cast<CBaseEntity@>( pObserverPlayer ) ) > 0 )
                continue;

            pObserverPlayer.GetObserver().StopObserver( true );
        }  
        return HOOK_CONTINUE;
    }

    ~PvpMode() { }
}
/* Special thanks to 
- Zode, H2 and Neo for scripting help
AlexCorruptor for testing and building a test map
Gauna, SV BOY, Jumpy for helping test */