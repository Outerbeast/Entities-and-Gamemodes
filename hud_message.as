namespace HUD_MESSAGE
{

CScheduledFunction@ fnInit = g_Scheduler.SetTimeout( "Init", 0.1f );

void Init()
{
    dictionary dictMessage = 
    { 
        { "m_iszScriptFunctionName", "HUD_MESSAGE::PrintMessage" },
        { "targetname", "ts_alt_message" },
        { "m_iMode", "1" } 
    };

    if( g_EntityFuncs.CreateEntity( "trigger_script", dictMessage ) is null )
        return;

    CBaseEntity@ pEntity;

    while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "env_message" ) ) !is null )
    {
        if( pEntity is null || pEntity.GetClassname() != "env_message" || pEntity.pev.message == "" )
            continue;

        pEntity.GetUserData( "alt_msg" ) = string( pEntity.pev.message );
        pEntity.pev.message = " ";
        pEntity.GetUserData( "targ" ) = string( pEntity.pev.target );
        pEntity.pev.target = "ts_alt_message";

        continue;
    }
}

void PrintMessage(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( pCaller is null || pCaller.GetClassname() != "env_message" )
        return;

    for( int iMsgDest = HUD_PRINTCENTER; iMsgDest >= HUD_PRINTNOTIFY; iMsgDest-- )
    {
        if( !pCaller.pev.SpawnFlagBitSet( 1 << ( iMsgDest + 1 ) ) )
            continue;

        g_EngineFuncs.ServerPrint( "!-----------------DEBUG---------! Current HUD_PRINT value is: " + iMsgDest  + "\n" );

        if( pCaller.pev.SpawnFlagBitSet( 1 << 1 ) )
            g_PlayerFuncs.ClientPrintAll( HUD( iMsgDest ), string( pCaller.GetUserData( "alt_msg" ) ) );
        else
            g_PlayerFuncs.ClientPrint( cast<CBasePlayer@>( pActivator ), HUD( iMsgDest ), string( pCaller.GetUserData( "alt_msg" ) ) ); // CRASH!!!!
    }

    g_EntityFuncs.FireTargets( string( pCaller.GetUserData( "targ" ) ), pActivator, pCaller, useType, 0.0f, 0.0f );
}

}
