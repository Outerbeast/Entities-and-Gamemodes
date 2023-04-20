/* trigger script for playing sounds individually

    Standalone trigger_script entity can be used instead of patching existing ambient_generics with the "User Only" flag set, with optional "$i_channel" key.
    Obey's trigger usetypes - Toggle will toggle the sound on and off and Off will turn the sound off if already playing.

    Entity template:-
    "classname" "trigger_script"
    "m_iszScriptFile" "beast/playsound_individual"
    "m_iszScriptFunctionName" "PLAYSOUND_INDIVIDUAL::Trigger"
    "m_iMode" "1"
    // Do not change any of the above!
    "targetname" "target_me"
    "$s_sound" "sound.wav" // Sound file. This sound must be precached via custom_precache before using, otherwise the sound will not play.
    "$f_volume" "10" // Volume, default is 10 if set to 0 or left undefined.
    "i_channel" "2" // See SOUND_CHANNEL enum for choices for this key: https://baso88.github.io/SC_AngelScript/docs/SOUND_CHANNEL.htm. Default is CHAN_VOICE

    IMPORTANT: Use an entity that triggers the sound entity with "target"/"message"/"netname" key or the entity will not be triggered.
    If you can't create a trigger_relay and use that to trigger the entity.

- Outerbeast */
namespace PLAYSOUND_INDIVIDUAL
{

CScheduledFunction@ fnPatchAmbientGeneric = g_Scheduler.SetTimeout( "PatchAmbientGeneric", 0.0f );
// Patch all existing ambient_generics with "User Only" flag set
void PatchAmbientGeneric()
{
    CBaseEntity@ pSound;
    while( ( @pSound = g_EntityFuncs.FindEntityByClassname( pSound, "ambient_generic" ) ) !is null )
    {
        if( pSound is null || !pSound.pev.SpawnFlagBitSet( 1 << 7 ) )
            continue;

        dictionary dictPsi =
        {
            { "targetname", pSound.GetTargetname() },
            { "m_iszScriptFunctionName", "PLAYSOUND_INDIVIDUAL::Trigger" },
            { "m_iMode", "1" },
            { "$s_sound", "" + pSound.pev.message },
            { "$f_volume", "" + pSound.pev.health }
        };

        if( g_EntityFuncs.CreateEntity( "trigger_script", dictPsi, true ) !is null )
            g_EntityFuncs.Remove( pSound );
    }
}

EHandle TriggerScriptInstance(EHandle hCaller, const string strIdentifier)
{
    if( !hCaller || strIdentifier == "" )
        return EHandle();
    
    CBaseEntity@ pTemp, pTriggerScript;
    CustomKeyvalues@ kvTriggerScript;
    string strSelfTarget;

    array<string> STR_CALLTYPES = { "target", "message", "netname" };

    for( uint i = 0; i < STR_CALLTYPES.length(); i++ )
    {
        if( hCaller.GetEntity().pev.target != "" )
        {
            strSelfTarget = hCaller.GetEntity().pev.target;
            break;
        }
        else if( hCaller.GetEntity().pev.message != "" )
        {
            strSelfTarget = hCaller.GetEntity().pev.message;
            break;
        }
        else if( hCaller.GetEntity().pev.netname != "" )
        {
            strSelfTarget = hCaller.GetEntity().pev.netname;
            break;
        }
    }

    while( ( @pTemp = g_EntityFuncs.FindEntityByTargetname( pTemp, "" + strSelfTarget ) ) !is null )
    {
        if( pTemp is null || pTemp.GetClassname() != "trigger_script" )
            continue;
        
        @kvTriggerScript = pTemp.GetCustomKeyvalues();

        if( kvTriggerScript is null || !kvTriggerScript.HasKeyvalue( "" + strIdentifier ) )
        {
            @kvTriggerScript = null;
            continue;
        }
        
        @pTriggerScript = pTemp;
        break;
    }

    return pTriggerScript;
}
// Sound must already be precached before triggering
void Trigger(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( !TriggerScriptInstance( EHandle( pCaller ), "$s_sound" ) )
        return;

    CBaseEntity@ pTriggerScript = TriggerScriptInstance( pCaller, "$s_sound" ).GetEntity();
    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();

    if( pTriggerScript is null )
        return;
        
    if( !pTriggerScript.GetUserData().exists( "is_sound_playing" ) )
        pTriggerScript.GetUserData()["is_sound_playing"] = false;

    if( kvTriggerScript is null || !kvTriggerScript.HasKeyvalue( "$s_sound" ) )
        return;

    float volume = kvTriggerScript.HasKeyvalue( "$f_volume" ) ? kvTriggerScript.GetKeyvalue( "$f_volume" ).GetFloat() : 10.0f;
    const SOUND_CHANNEL channel = kvTriggerScript.HasKeyvalue( "$i_channel" ) ? SOUND_CHANNEL( kvTriggerScript.GetKeyvalue( "$i_channel" ).GetInteger() ) : CHAN_VOICE;
    // A sound that's inaudible isn't a sound.
    if( volume <= 0.0f )
        volume = 10.0f;
    // Activator is lost, do not play. Workaround: use game_zone_player to inject activator.
    if( pActivator is null || !pActivator.IsPlayer() )
        return;
    
    switch( useType )
    {
        case USE_OFF:
        {
            g_SoundSystem.StopSound( pActivator.edict(), channel, kvTriggerScript.GetKeyvalue( "$s_sound" ).GetString() );
            pTriggerScript.GetUserData( "is_sound_playing" ) = false;

            break;
        }

        case USE_TOGGLE:
        {
            if( !bool( pTriggerScript.GetUserData( "is_sound_playing" ) ) )
            {
                PlaySoundInvididual( pActivator, kvTriggerScript.GetKeyvalue( "$s_sound" ).GetString(), volume, channel );
                pTriggerScript.GetUserData( "is_sound_playing" ) = true;
            }
            else
            {
                g_SoundSystem.StopSound( pActivator.edict(), channel, kvTriggerScript.GetKeyvalue( "$s_sound" ).GetString() );
                pTriggerScript.GetUserData( "is_sound_playing" ) = false;
            }

            break;
        }

        default:
        {
            PlaySoundInvididual( pActivator, kvTriggerScript.GetKeyvalue( "$s_sound" ).GetString(), volume, channel );
            pTriggerScript.GetUserData( "is_sound_playing" ) = true;
        }
    }
    
}

void PlaySoundInvididual(EHandle hTarget, string strSound, float flVolume, SOUND_CHANNEL channel = CHAN_VOICE)
{
    if( !hTarget || !hTarget.GetEntity().IsPlayer() )
        return;

    g_SoundSystem.PlaySound( hTarget.GetEntity().edict(), channel, strSound, flVolume, 10.0f, 0, PITCH_NORM, hTarget.GetEntity().entindex(), true, hTarget.GetEntity().GetOrigin() );
}

}
