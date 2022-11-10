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
!pvp_stats/info - show your stats
!pvp_leave/spectate - enter Spectator mode
!pvp_join/play/afk - exit Spectator mode

Issues:-
- Only supports 17 player slots maximum because of limitations imposed by the game + API. 18th player and following will automatically
be moved to Spectator mode until a slot becomes free.
- Some players will have colored usernames in the scoreboard, this is due to the classification system assigning them to
TEAM classifications which apply these colors.
*/
namespace PVP_MODE
{

enum spectatortype
{
    SPECTYPE_NONE = 0,
    SPECTYPE_WAITING,
    SPECTYPE_VOLUNTARY
};

array<bool> BL_PLAYER_SLOT( g_Engine.maxClients + 1 );
array<uint8> I_PLAYER_TEAMS =
{ 
    CLASS_MACHINE,
    CLASS_PLAYER,
    CLASS_HUMAN_MILITARY,
    CLASS_ALIEN_MILITARY,
    CLASS_ALIEN_PASSIVE,
    CLASS_ALIEN_MONSTER,
    CLASS_ALIEN_PREY,
    CLASS_ALIEN_PREDATOR,
    CLASS_INSECT,
    CLASS_PLAYER_BIOWEAPON,
    CLASS_XRACE_PITDRONE,
    CLASS_XRACE_SHOCK,
    CLASS_TEAM1,
    CLASS_TEAM2,
    CLASS_TEAM3,
    CLASS_TEAM1,
    CLASS_BARNACLE
};

HUDTextParams txtWinner, txtLoser, txtStats;

int8 iTotalTeams = I_PLAYER_TEAMS.length();
int iForceRespawnDefault = int( g_EngineFuncs.CVarGetFloat( "mp_forcerespawn" ) );

CCVar cvarProtectDuration( "pvp_spawnprotecttime", 10.0f, "Duration of spawn invulnerability", ConCommandFlag::AdminOnly );
CCVar cvarViewModeSetting( "pvp_viewmode", 0.0f, "View mode setting", ConCommandFlag::AdminOnly );
CCVar cvarKillInfoSetting( "pvp_killinfo", 1.0f, "Kill hud info", ConCommandFlag::AdminOnly );

CScheduledFunction@ fnThink, fnInit = g_Scheduler.SetTimeout( "Initialise", 0.1f );

void Initialise()
{
    if( I_PLAYER_TEAMS.length() < uint( g_Engine.maxClients + 1 ) )
        I_PLAYER_TEAMS.resize( g_Engine.maxClients + 1 );

    if( iForceRespawnDefault < 1 )
        g_EngineFuncs.CVarSetFloat( "mp_forcerespawn", 1 );

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

    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, PlayerSpawn );
    g_Hooks.RegisterHook( Hooks::Player::PlayerUse, PlayerUse );
    g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, PlayerTakeDamage );
    g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, PlayerKilled );
    g_Hooks.RegisterHook( Hooks::Player::ClientSay, PlayerChatCommand );
    g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, PlayerLeave );

    @fnThink = g_Scheduler.SetInterval( "Think", 0.01f, g_Scheduler.REPEAT_INFINITE_TIMES );
}

int AssignTeam(EHandle hPlayer, const bool blSetTeam)
{
    if( !hPlayer )
        return CLASS_NONE;
    
    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    if( blSetTeam && BL_PLAYER_SLOT.find( false ) >= 0 )
    {
        pPlayer.SetClassification( I_PLAYER_TEAMS[BL_PLAYER_SLOT.find( false )] );
        BL_PLAYER_SLOT[I_PLAYER_TEAMS.find( pPlayer.m_iClassSelection )] = true;
    }
    else if( !blSetTeam ) // For when we want to remove classification from player
    {
        BL_PLAYER_SLOT[I_PLAYER_TEAMS.find( pPlayer.m_iClassSelection )] = false;
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
            pPlayer.pev.rendermode = kRenderTransTexture;
            pPlayer.pev.renderamt = 100.0f;
            g_Scheduler.SetTimeout( "SpawnProtection", cvarProtectDuration.GetFloat(), EHandle( pPlayer ), int( DAMAGE_YES ) );

            break;
        }

        case DAMAGE_YES:
        {
            pPlayer.SetMaxSpeedOverride( -1 );
            pPlayer.pev.rendermode = pPlayer.m_iOriginalRenderMode;
            pPlayer.pev.renderamt = pPlayer.m_flOriginalRenderAmount;

            break;
        }

        default: break;
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
        pPlayer.GetUserData( "i_spectating" ) = SPECTYPE_WAITING;
        pPlayer.SetMaxSpeedOverride( -1 );
        pPlayer.GetObserver().StartObserver( pPlayer.GetOrigin(), pPlayer.pev.angles, false );
        pPlayer.GetObserver().SetObserverModeControlEnabled( true );
        pPlayer.RemoveAllItems( true );

        g_PlayerFuncs.ShowMessage( pPlayer, "SPECTATING\nNo player slots available. Please wait..." );
    }   // !-BUG-! - Index out of bounds in 2 player slot server - why???? Hence this check.
    else if( blSpectatorOverride && g_Engine.maxClients > 2 )
    {
        pPlayer.GetUserData( "i_spectating" ) = SPECTYPE_VOLUNTARY;
        AssignTeam( EHandle( pPlayer ), false );

        pPlayer.SetMaxSpeedOverride( -1 );
        pPlayer.pev.frags = 0;
        pPlayer.GetObserver().StartObserver( pPlayer.GetOrigin(), pPlayer.pev.angles, false );
        pPlayer.GetObserver().SetObserverModeControlEnabled( true );
        pPlayer.RemoveAllItems( true );

        g_PlayerFuncs.ShowMessage( pPlayer, "You are in Spectator mode.\n\nType '!pvp_join' to exit." );
    }
}

void Think()
{
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null )
            continue;

        if( pPlayer.IsAlive() )
            pPlayer.SetViewMode( PlayerViewMode( cvarViewModeSetting.GetInt() ) );// Utterly retarded. Forced to cast to enum and not the actual value.
        else if( pPlayer.GetObserver().IsObserver() )
            pPlayer.pev.nextthink = g_Engine.time + 1.0f;

        if( pPlayer.pev.FlagBitSet( FL_GODMODE ) )
            pPlayer.pev.flags &= ~FL_GODMODE;
    }
}
// ========================= Hook Funcs - Runs the entire bloody thing ========================= //
HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
{   
    if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
        return HOOK_CONTINUE;

    pPlayer.GetUserData()["i_spectating"] = SPECTYPE_NONE;
    int iAssignedClassification = AssignTeam( EHandle( pPlayer ), true );

    if( iAssignedClassification < CLASS_MACHINE )
    {
        EnterSpectator( EHandle( pPlayer ), false );
        return HOOK_CONTINUE;
    }
    
    g_Scheduler.SetTimeout( "SpawnProtection", 0.01f, EHandle( pPlayer ), int( DAMAGE_NO ) ); // Why delay? Because rendering won't apply on spawn - but WHY.

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
    
    if( pAttackingPlayer !is pPlayer && cvarKillInfoSetting.GetInt() > 0 )
    {
        g_PlayerFuncs.HudMessage( pAttackingPlayer, txtWinner, "You killed\n\n" + string( pPlayer.pev.netname ).ToUppercase() + "\n" + strAttackerWeapon + "\n Damage done: " + iDamageDone + "\n" );
        g_PlayerFuncs.HudMessage( pPlayer, txtLoser, "" + string( pAttackingPlayer.pev.netname ).ToUppercase() + "\nkilled you" + strAttackerWeapon + "\n Damage taken: " + iDamageDone + "\n" );
    }
    else if( pAttackingPlayer is pPlayer ) // Case player suicided
    {   // True suicide, and not done via weapon self-damage
        if( pAttackingPlayer.pev.dmg_inflictor is pAttackingPlayer.edict() ) // !-BUG-!: Suicides via "kill" in console can sometimes cause a weapon be used as the dmg_inflictor and this check is false.
            g_Scheduler.SetTimeout( "EnterSpectator", 0.1f, EHandle( pPlayer ), true );
    }

    return HOOK_CONTINUE;
}

HookReturnCode PlayerLeave(CBasePlayer@ pDisconnectedPlayer)
{   
    if( pDisconnectedPlayer is null )
        return HOOK_CONTINUE;

    AssignTeam( EHandle( pDisconnectedPlayer ), false );
    pDisconnectedPlayer.ClearClassification();
    pDisconnectedPlayer.pev.frags = 0;

    for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); iPlayer++ )
    {
        if( BL_PLAYER_SLOT.find( false ) < 0 )
            break;

        CBasePlayer@ pObserverPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pObserverPlayer is null || !pObserverPlayer.GetObserver().IsObserver() )
            continue;
        // Skip players who are spectating voluntarily
        if( int( pObserverPlayer.GetUserData( "i_spectating" ) ) == SPECTYPE_VOLUNTARY )
            continue;

        pObserverPlayer.GetObserver().StopObserver( true );
        pObserverPlayer.GetUserData( "i_spectating" ) = SPECTYPE_NONE;
    }
    
    return HOOK_CONTINUE;
}

void Disable(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    g_EngineFuncs.CVarSetFloat( "mp_forcerespawn", iForceRespawnDefault );

    g_Hooks.RemoveHook( Hooks::Player::PlayerSpawn, PlayerSpawn );
    g_Hooks.RemoveHook( Hooks::Player::PlayerUse, PlayerUse );
    g_Hooks.RemoveHook( Hooks::Player::PlayerTakeDamage, PlayerTakeDamage );
    g_Hooks.RemoveHook( Hooks::Player::PlayerKilled, PlayerKilled );
    g_Hooks.RemoveHook( Hooks::Player::ClientSay, PlayerChatCommand );
    g_Hooks.RemoveHook( Hooks::Player::ClientDisconnect, PlayerLeave );

    if( fnThink !is null )
    {
        g_Scheduler.RemoveTimer( fnThink );
        @fnThink = null;
    }

    BL_PLAYER_SLOT = array<bool>( g_Engine.maxClients + 1, false );

    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        if( g_PlayerFuncs.FindPlayerByIndex( iPlayer ) !is null )
        {
            g_PlayerFuncs.FindPlayerByIndex( iPlayer ).pev.frags = 0.0f;
            g_PlayerFuncs.FindPlayerByIndex( iPlayer ).SetClassification( CLASS_PLAYER );
            g_PlayerFuncs.FindPlayerByIndex( iPlayer ).GetUserData( "i_spectating" ) = SPECTYPE_NONE;
        }
    }
}

}
/* Special thanks to 
- Zode, H2 and Neo for scripting help
AlexCorruptor for testing and building a test map
Gauna, SV BOY, Jumpy for helping test */