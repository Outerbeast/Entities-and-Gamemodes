array<float> PLAYER_FALL_VELOCITY(33);
float flMortalVelocity;

void DoomFallStartThink(float flMortalVelocitySetting)
{
    if( flMortalVelocitySetting <= 0.0f )
    {
       flMortalVelocity = 700.0f;
    }
    else
        flMortalVelocity = flMortalVelocitySetting;

    g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @DoomFall );
}

HookReturnCode DoomFall( CBasePlayer@ pPlayer )
{
    if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
    {
        if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
            return HOOK_CONTINUE;

        if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
        {
            if( pPlayer.m_flFallVelocity >= flMortalVelocity )
            {
                g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "sc_persia/scream.wav", 1.0f, ATTN_NORM );
                g_PlayerFuncs.SayText( pPlayer, "You are falling to your doom." );
                entvars_t@ world = g_EntityFuncs.Instance(0).pev;
                pPlayer.TakeDamage(world, world, 10000.0f, DMG_FALL);
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

void DoomFallStopThink()
{
    g_Hooks.UnRegisterHook( Hooks::Player::PlayerPreThink, @DoomFall );
}
