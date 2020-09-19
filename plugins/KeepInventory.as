/* A simple plugin that will enable inventory saving between level changes.
- Outerbeast */

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "Outerbeast" );
	g_Module.ScriptInfo.SetContactInfo( "svencoopedia.fandom.com" );
}

void MapStart()
{
    CBaseEntity@ pEntity = null;
    while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_changelevel" ) ) !is null )
    { 
       g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "keep_inventory", "1" )
    }
}
