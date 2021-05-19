/* Just a fun script that changes at what fall speed makes players die from falldamage- players also emit screaming sound
Usage:-
Put the code "DOOMFALL::Enable();" in MapInit
Replace or assign "flMortalVelocitySetting" to your falling speed
Replace or assign "blStartOnSetting" to true if you want it active on map start, or false if you want to have inactive
- Outerbeast */
namespace DOOMFALL
{

float flMortalVelocity;
bool blStartOn = true;

array<Vector2D> FALLING_PLAYER_DATA( g_Engine.maxClients + 1, Vector2D() );

void Enable(float flMortalVelocitySetting = 700.0f, bool blStartOnSetting = true)
{
    g_SoundSystem.PrecacheSound( "sc_persia/scream.wav" );

    if( flMortalVelocitySetting <= 0.0f )
        flMortalVelocity = 700.0f;
    else
        flMortalVelocity = flMortalVelocitySetting;
    
    if( blStartOnSetting )
    {
        blStartOn = true;
        StartThink(); 
    }
    else
        blStartOn = false;
}

void Trigger(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( !blStartOn )
    { 
        StartThink();
        blStartOn = true;
    }
    else if( blStartOn )
    { 
        StopThink(); 
        blStartOn = false;
    }
}

void StartThink()
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @OnGround );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @Fall );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @Splat );
}

HookReturnCode OnGround(CBasePlayer@ pPlayer)
{
    if( pPlayer is null )
        return HOOK_CONTINUE;

    FALLING_PLAYER_DATA[pPlayer.entindex()] = g_vecZero.Make2D();

    return HOOK_CONTINUE;
}

HookReturnCode Fall(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
        return HOOK_CONTINUE;
    
    if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) && !pPlayer.pev.FlagBitSet( FL_INWATER ) && !pPlayer.IsOnLadder() )
    {
        FALLING_PLAYER_DATA[pPlayer.entindex()].x = pPlayer.m_flFallVelocity;

        if( FALLING_PLAYER_DATA[pPlayer.entindex()].x >= flMortalVelocity && FALLING_PLAYER_DATA[pPlayer.entindex()].y < 1 )
        {
            g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "sc_persia/scream.wav", 1.0f, ATTN_NORM );
            FALLING_PLAYER_DATA[pPlayer.entindex()].y = 1;
            //g_PlayerFuncs.SayText( pPlayer, "You are falling to your doom." );
        }
    }
    else
        FALLING_PLAYER_DATA[pPlayer.entindex()] = g_vecZero.Make2D();
    
    return HOOK_CONTINUE;
}

HookReturnCode Splat(CBasePlayer@ pPlayer)
{
    if( pPlayer is null )
        return HOOK_CONTINUE;
    
    if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) && FALLING_PLAYER_DATA[pPlayer.entindex()].y > 0 )
    {
        pPlayer.TakeDamage( g_EntityFuncs.Instance( 0 ).pev, g_EntityFuncs.Instance( 0 ).pev, 10000.0f, DMG_FALL );
        FALLING_PLAYER_DATA[pPlayer.entindex()].y = 0.0f;
        //g_PlayerFuncs.SayText( pPlayer, "You went SPLAT." );
    }
    return HOOK_CONTINUE;
}

void StopThink()
{
    g_Hooks.RemoveHook( Hooks::Player::PlayerSpawn, @OnGround );
    g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, @Fall );
    g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, @Splat );
}

}
/* Special thanks to:-
-Zode for extensive support, testing and proofreading
and others I've asked help from for minor things:
-KernCore
-AnggaraNothing
-H2*/