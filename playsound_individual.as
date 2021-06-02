/* trigger script for playing sounds for individual players only
(inaudible to anyone else) 
Fix for ambient_generic "User Only" flag which is broken
- Outerbeast */
namespace PLAYSOUND_INDIVIDUAL
{
// Patch all existing ambient_generics with "User Only" flag set - trigger in MapStart
void PatchAmbientGeneric()
{
    CBaseEntity@ pSound;
    while( ( @pSound = g_EntityFuncs.FindEntityByClassname( pSound, "ambient_generic" ) ) !is null )
    {
        if( pSound is null || !pSound.pev.SpawnFlagBitSet( 64 ) )
            continue;

        dictionary psi =
        {
            { "m_iszScriptFunctionName", "PLAYSOUND_INDIVIDUAL::Trigger" },
            { "m_iMode", "1" },
            { "targetname", "" + pSound.GetTargetname() },
            { "$s_sound", "" + pSound.pev.message },
            { "$f_volume", "" + pSound.pev.health }
        };

        CBaseEntity@ pSoundIndividual = g_EntityFuncs.CreateEntity( "trigger_script", psi, true );
        g_EntityFuncs.Remove( pSound );
    }
}

EHandle TriggerScriptInstance(EHandle hCaller, const string strIdentifier)
{
    if( !hCaller || strIdentifier == "" )
        return EHandle( null );
    
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
    return EHandle( pTriggerScript );
}
// Sound must already be precached before triggering
void Trigger(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	CBaseEntity@ pTriggerScript = TriggerScriptInstance( EHandle( pCaller ), "$s_sound" ).GetEntity();
    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();

    if( pTriggerScript is null || kvTriggerScript is null || !kvTriggerScript.HasKeyvalue( "$s_sound" ) )
        return;

    float volume = kvTriggerScript.HasKeyvalue( "$f_volume" ) ? kvTriggerScript.GetKeyvalue( "$f_volume" ).GetFloat() : 10.0f;
    
    if( pActivator !is null && pActivator.IsPlayer() )
        g_SoundSystem.PlaySound( pActivator.edict(), CHAN_VOICE, "" + kvTriggerScript.GetKeyvalue( "$s_sound" ).GetString(), volume, 10.0f, 0, PITCH_NORM, pActivator.entindex(), true, pActivator.GetOrigin() );
}

}
