namespace BUTTON_LOS
{

CScheduledFunction@ fnPatchButtons = g_Scheduler.SetTimeout( "PatchButtons", 0.0f );

void PatchButtons()
{
    dictionary dictTs =
    {
        { "targetname", "ts_check_los" },
        { "m_iszScriptFunctionName", "BUTTON_LOS::CheckLOS" },
        { "m_iMode", "1" }
    };

    CBaseEntity@ pEntity;
    while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_button" ) ) !is null )
    {
        if( pEntity is null || !pEntity.pev.SpawnFlagBitSet( 1 << 1 ) )
            continue;

        pEntity.GetUserData()["targ"] = string( pEntity.pev.target );
        pEntity.pev.target = string( dictTs["targetname"] );
    }

    g_EntityFuncs.CreateEntity( "trigger_script", dictTs );
}

void CheckLOS(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( pActivator is null || pCaller is null )
        return;

    if( !pCaller.FVisibleFromPos( pActivator.pev.origin, pCaller.Center() ) )
        return;

    g_EntityFuncs.FireTargets( string( pCaller.GetUserData( "targ" ) ), pActivator, pCaller, useType, 0.0f, 0.0f );
}

}
