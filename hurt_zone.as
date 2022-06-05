/* hurt_zone
by Outerbeast
trigger_script point entity analogue for trigger_hurt

Template entity:-
"classname" "trigger_script"
"m_iszScriptFile" "teleport_zone"
"m_iMode" "2"
// Don't change any of the above! //
"m_iszScriptFunctionName" "TELEPORT_ZONE::TeleportEntities"
"targetname" "target_me"
"$s_brush" "*m"             // Brush model to provide bounds.
"$v_mins" "x y z"           // Hurt zone box min origin
"$v_maxs" "x y z"           // Hurt zone box max origin
"m_flThinkDelta" "t"        // Time interval between each damage (same as trigger_hurt "delay" setting). Default is 0.1.
"dmg" "d"                   // Damage amount
"impulse"                   // Damage Type (refer to trigger_hurt "damagetype" settings)
Set flag 1 to make this active at start. Otherwise this trigger_script needs to be triggered manually to enable/disable it.
*/
namespace HURT_ZONE
{

void HurtZone(CBaseEntity@ pTriggerScript)
{
    if( pTriggerScript.pev.dmg == 0 )
        return;

    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();

    array<CBaseEntity@> P_ENTITIES( g_EngineFuncs.NumberOfEntities() );
    int iNumEntities, flagMask = pTriggerScript.pev.spawnflags & ~( 1 );
    Vector vecAbsMin, vecAbsMax;
    bool blBoundsSet = SetBounds( EHandle( pTriggerScript ), vecAbsMin, vecAbsMax );

    if( !blBoundsSet )
        return;

    if( flagMask == 0 )
        flagMask = FL_CLIENT;

    iNumEntities = g_EntityFuncs.EntitiesInBox( @P_ENTITIES, vecAbsMin, vecAbsMax, flagMask );

    if( iNumEntities < 1 )
        return;

    for( int i = 0; i < iNumEntities; i++ )
    {
        if( P_ENTITIES[i] is null ||
            !P_ENTITIES[i].IsAlive() ||
            P_ENTITIES[i].pev.FlagBitSet( FL_GODMODE ) || 
            P_ENTITIES[i].pev.takedamage == DAMAGE_NO )
            continue;

        P_ENTITIES[i].TakeDamage( pTriggerScript.pev, pTriggerScript.pev, pTriggerScript.pev.dmg, pTriggerScript.pev.impulse );
    }

    P_ENTITIES.resize( 0 );
}

bool SetBounds(EHandle hTriggerScript, Vector& out vecMin, Vector& out vecMax)
{
    if( !hTriggerScript )
        return false;

    CustomKeyvalues@ kvTriggerScript = hTriggerScript.GetEntity().GetCustomKeyvalues();

    if( kvTriggerScript.HasKeyvalue( "$s_brush" ) )
    {
        CBaseEntity@ pBBox = g_EntityFuncs.FindEntityByString( pBBox, "model", "" + kvTriggerScript.GetKeyvalue( "$s_brush" ).GetString() );

        if( pBBox !is null && pBBox.IsBSPModel() )
        {
            vecMin = pBBox.pev.absmin;
            vecMax = pBBox.pev.absmax;

            return true;
        }
        else
            return false;
    }
    else if( kvTriggerScript.HasKeyvalue( "$v_mins" ) && kvTriggerScript.HasKeyvalue( "$v_maxs" ) )
    {
        if( kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector() != kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector() )
        {
            vecMin = kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector();
            vecMax = kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector();

            return true;
        }
        else
            return false;
    }
    else
        return false;
}

}
