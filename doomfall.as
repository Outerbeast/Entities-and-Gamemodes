/* Just a fun script that changes at what fall speed makes players die from falldamage
- Outerbeast */

int playerID = 1;
float flMortalVelocity;

array<float> FL_OLD_PLAYER_VELOCITY(33);
array<bool> F_PLAYER_HAS_FELL(33);

void DoomFallStartThink(float flMortalVelocitySetting)
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @TrackPlayer );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @DoomFall );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @Splat );
    g_SoundSystem.PrecacheSound( "sc_persia/scream.wav" );

    if( flMortalVelocitySetting <= 0.0f ){ flMortalVelocity = 700.0f; }
    else
        flMortalVelocity = flMortalVelocitySetting;
}

HookReturnCode TrackPlayer(CBasePlayer @pSpawnedPlyr)
{
    if( @pSpawnedPlyr is null ){ return HOOK_CONTINUE; }

    for( playerID; playerID <= g_Engine.maxClients; ++playerID )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
        FL_OLD_PLAYER_VELOCITY[playerID]    = 0.0f;
        F_PLAYER_HAS_FELL[playerID]       = false;
    }
    return HOOK_HANDLED;
}

HookReturnCode DoomFall(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
    {
        if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            FL_OLD_PLAYER_VELOCITY[playerID] = 0.0f;
            F_PLAYER_HAS_FELL[playerID] = false;
        }

        if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            FL_OLD_PLAYER_VELOCITY[playerID] = pPlayer.m_flFallVelocity;

            if( FL_OLD_PLAYER_VELOCITY[playerID] >= flMortalVelocity && !F_PLAYER_HAS_FELL[playerID] )
            {
                g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "sc_persia/scream.wav", 1.0f, ATTN_NORM );
                g_PlayerFuncs.SayText( pPlayer, "You are falling to your doom." );
                F_PLAYER_HAS_FELL[playerID] = true;

                return HOOK_HANDLED;
            }
            else
                return HOOK_CONTINUE; 
        }
        else
            return HOOK_CONTINUE; 
    }
    else
        return HOOK_CONTINUE; 
}

HookReturnCode Splat( CBasePlayer@ pPlayer )
{
    if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) && F_PLAYER_HAS_FELL[playerID] )
    {
        entvars_t@ world = g_EntityFuncs.Instance(0).pev;
        pPlayer.TakeDamage(world, world, 10000.0f, DMG_FALL);
        F_PLAYER_HAS_FELL[playerID] = false;
        g_PlayerFuncs.SayText( pPlayer, "You went SPLAT." );
        return HOOK_HANDLED;
    }
    else
        return HOOK_CONTINUE; 
}

void DoomFallStopThink()
{
    g_Hooks.RemoveHook( Hooks::Player::PlayerSpawn, @TrackPlayer );
    g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, @DoomFall );
    g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, @Splat );
}

/* Special thanks to the usual scripting gang:-
-KernCore
-AnggaraNothing
-H2
-Zode */