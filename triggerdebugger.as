/* Script for printing trigger information onscreen/console
Install: "map_script triggerdebugger" in your map cfg
Message format: <triggerer_classname> "<triggerer_targetname>" triggered "<targetentity_targetname>"
- Outerbeast
*/
namespace TRIGGERDEBUGGER
{

CScheduledFunction@ fnTriggerDebug = g_Scheduler.SetTimeout( "Init", 0.0f );

string strDebugMsg;
array<string> STR_TARGETNAMES;

dictionary dictTriggerDebug =
{
    { "m_iszScriptFile", "triggerdebugger" },
    { "m_iszScriptFunctionName", "TRIGGERDEBUGGER::TriggerListener" },
    { "m_iMode", "1" },
    { "target", "get_target_entityname" }
},
dictPrintDebugMsg =
{
    { "m_iszScriptFile", "triggerdebugger" },
    { "m_iszScriptFunctionName", "TRIGGERDEBUGGER::PrintDebugMsg" },
    { "m_iMode", "1" },
    { "targetname", "get_target_entityname" }
};

void Init()
{
    CBaseEntity@ pEntity, pTriggerDebugRly;

    while( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, "*" ) ) !is null )
    {
        if( pEntity is null || pEntity.IsMonster() )
            continue;

        if( STR_TARGETNAMES.find( pEntity.GetTargetname() ) >= 0 )
            continue;

        @pTriggerDebugRly = g_EntityFuncs.CreateEntity( "trigger_script", dictTriggerDebug, true );
        STR_TARGETNAMES.insertLast( pTriggerDebugRly.pev.targetname = pEntity.GetTargetname() );
    }

    g_EntityFuncs.CreateEntity( "trigger_script", dictPrintDebugMsg, true );
}

void TriggerListener(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    const string strTriggererClassname = pCaller.GetClassname();
    const string strTriggererTargetname = pCaller.GetTargetname() != "" ? "''" + pCaller.GetTargetname() + "''" : "";

    strDebugMsg = strTriggererClassname + " " + strTriggererTargetname + " triggered ";
}

void PrintDebugMsg(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    const string strTargetEntityTargetName = pCaller.GetTargetname() != "" ? "''" + pCaller.GetTargetname() + "''" : "";

    strDebugMsg = strDebugMsg + " " + strTargetEntityTargetName + "\n";
    g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, strDebugMsg );
    g_EngineFuncs.ServerPrint( strDebugMsg );
    strDebugMsg = "";
}

}
