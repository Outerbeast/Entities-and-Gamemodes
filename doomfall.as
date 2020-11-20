/* Just a fun script that changes at what fall speed makes players die from falldamage- players also emit screaming sound
Usage:-
Put the code "DOOMFALL::Enable( flMortalVelocitySetting, blStartOnSetting );" in MapInit
Replace or assign "flMortalVelocitySetting" to your falling speed
Replace or assign "blStartOnSetting" to true if you want it active on map start, or false if you want to have inactive

- Outerbeast */

namespace DOOMFALL
{

uint playerID = 1;
float flMortalVelocity;
bool blStartOn = true;
    
//array<float> PLAYER_FALL_SPEED(33);
//array<bool> HAS_PLAYER_FELL(33);

class FallingPlayer
{
    float flPlayerFallSpeed;
    bool blHasPlayerFell;
}

array<FallingPlayer@> FALLING_PLAYER_DATA( 33, FallingPlayer() );

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
}

void TriggerDoomFall(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( !blStartOn ){ StartThink(); }
}

void StartThink()
{
    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @TrackPlayer );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @Fall );
    g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @Splat );
}

HookReturnCode TrackPlayer(CBasePlayer@ pSpawnedPlyr)
{
    if( pSpawnedPlyr is null ){ return HOOK_CONTINUE; }

    for( uint playerID = 1; playerID <= FALLING_PLAYER_DATA.length(); ++playerID )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

        FallingPlayer playerdata;
        playerdata.flPlayerFallSpeed = 0.0f;
        playerdata.blHasPlayerFell   = false;
        FALLING_PLAYER_DATA[playerID-1] = playerdata;
    }
    return HOOK_HANDLED;
}

HookReturnCode Fall(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
    {
        if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            FALLING_PLAYER_DATA[playerID-1].flPlayerFallSpeed = 0.0f;
            FALLING_PLAYER_DATA[playerID-1].blHasPlayerFell   = false;
        }

        if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            FALLING_PLAYER_DATA[playerID-1].flPlayerFallSpeed = pPlayer.m_flFallVelocity;

            if( FALLING_PLAYER_DATA[playerID-1].flPlayerFallSpeed >= flMortalVelocity && !FALLING_PLAYER_DATA[playerID-1].blHasPlayerFell )
            {
                g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "sc_persia/scream.wav", 1.0f, ATTN_NORM );
                //g_PlayerFuncs.SayText( pPlayer, "You are falling to your doom." );
                FALLING_PLAYER_DATA[playerID-1].blHasPlayerFell = true;

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

HookReturnCode Splat(CBasePlayer@ pPlayer)
{ 
    if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) && !FALLING_PLAYER_DATA[playerID-1].blHasPlayerFell )
    {
        entvars_t@ world = g_EntityFuncs.Instance(0).pev;
        pPlayer.TakeDamage(world, world, 10000.0f, DMG_FALL);
        FALLING_PLAYER_DATA[playerID-1].blHasPlayerFell = false;
        //g_PlayerFuncs.SayText( pPlayer, "You went SPLAT." );

        return HOOK_HANDLED;
    }
    else
        return HOOK_CONTINUE;
}

void StopThink(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    g_Hooks.RemoveHook( Hooks::Player::PlayerSpawn, @TrackPlayer );
    g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, @Fall );
    g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, @Splat );
}

}
/* Special thanks to the usual scripting gang:-
-KernCore
-AnggaraNothing
-H2
-Zode */