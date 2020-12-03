/* Just a fun script that changes at what fall speed makes players die from falldamage- players also emit screaming sound
Usage:-
Put the code "DOOMFALL::Enable( flMortalVelocitySetting, blStartOnSetting );" in MapInit
Replace or assign "flMortalVelocitySetting" to your falling speed
Replace or assign "blStartOnSetting" to true if you want it active on map start, or false if you want to have inactive

- Outerbeast */

namespace DOOMFALL
{

float flMortalVelocity;
bool blStartOn = true;

class FallingPlayer
{
    float flPlayerFallSpeed;
    bool blHasPlayerFell;
}

array<FallingPlayer@> FALLING_PLAYER_DATA;

void Enable(const float flMortalVelocitySetting, const bool blStartOnSetting)
{
    g_SoundSystem.PrecacheSound( "sc_persia/scream.wav" );

    if( flMortalVelocitySetting <= 0.0f ){ flMortalVelocity = 700.0f; }
    else
        flMortalVelocity = flMortalVelocitySetting;
    
    if( blStartOnSetting )
    {
        blStartOn = true;
        StartThink(); 
    }
    else
        blStartOn = false;

    for( int i = 0; i < g_Engine.maxClients; i++ )
    {
        FallingPlayer plrdata;
        plrdata.flPlayerFallSpeed = 0.0f;
        plrdata.blHasPlayerFell = false;
        FALLING_PLAYER_DATA.insertLast(plrdata);
    }
}

void TriggerDoomFall(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
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

HookReturnCode OnGround(CBasePlayer@ pSpawnedPlyr)
{
    if( pSpawnedPlyr is null ){ return HOOK_CONTINUE; }

        FALLING_PLAYER_DATA[pSpawnedPlyr.entindex()-1].flPlayerFallSpeed = 0.0f;
        FALLING_PLAYER_DATA[pSpawnedPlyr.entindex()-1].blHasPlayerFell   = false;

    return HOOK_CONTINUE;
}

HookReturnCode Fall(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
    {
        if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            FALLING_PLAYER_DATA[pPlayer.entindex()-1].flPlayerFallSpeed = 0.0f;
            FALLING_PLAYER_DATA[pPlayer.entindex()-1].blHasPlayerFell   = false;
        }

        if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            FALLING_PLAYER_DATA[pPlayer.entindex()-1].flPlayerFallSpeed = pPlayer.m_flFallVelocity;

            if( FALLING_PLAYER_DATA[pPlayer.entindex()-1].flPlayerFallSpeed >= flMortalVelocity && !FALLING_PLAYER_DATA[pPlayer.entindex()-1].blHasPlayerFell )
            {
                g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "sc_persia/scream.wav", 1.0f, ATTN_NORM );
                FALLING_PLAYER_DATA[pPlayer.entindex()-1].blHasPlayerFell = true;
                g_PlayerFuncs.SayText( pPlayer, "You are falling to your doom." );
            }
        }
    }
    return HOOK_CONTINUE;
}

HookReturnCode Splat(CBasePlayer@ pPlayer)
{ 
    if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) && FALLING_PLAYER_DATA[pPlayer.entindex()-1].blHasPlayerFell )
    {
        entvars_t@ world = g_EntityFuncs.Instance(0).pev;
        pPlayer.TakeDamage(world, world, 10000.0f, DMG_FALL);
        FALLING_PLAYER_DATA[pPlayer.entindex()-1].blHasPlayerFell = false;
        g_PlayerFuncs.SayText( pPlayer, "You went SPLAT." );
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
