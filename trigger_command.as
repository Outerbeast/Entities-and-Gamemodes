/* trigger_command - custom entity for executing player commands
    Based loosly on the SoHL entity.

    Installation:-
    - Place in scripts/maps
    - Add
    map_script trigger_command
    to your map cfg
    OR
    - Add
    #include "trigger_command"
    to your main map script header
    OR
    - Create a trigger_script with these keys set in your map:
    "classname" "trigger_script"
    "m_iszScriptFile" "trigger_command"

    Usage:-
    Use the "command" key folows by the command you wish to execute. The command is executed when the entity is triggered.
    If the entity has no targetname applied, the entity will trigger automatically.
    "netname" key sets a filter to target players with targetnames matching the netname value.
- Outerbeast
*/
const uint SF_SERVERCOMMAND = 1 << 0;
bool blTriggerCommandRegistered = RegisterTriggerCommand();

bool RegisterTriggerCommand()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_command", "trigger_command" );
    return g_CustomEntityFuncs.IsCustomEntity( "trigger_command" );
}
// Execute client command
void StuffClient(const string& in command, edict_t@ eTarget = null)
{
    if( command == "" )
        return;

    NetworkMessage stufftext( eTarget !is null ? MSG_ONE : MSG_BROADCAST, NetworkMessages::SVC_STUFFTEXT, eTarget );
    stufftext.WriteString( command );
    stufftext.End();
}

final class trigger_command : ScriptBaseEntity
{
    private string strCommand;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "command" )
            strCommand = szValue;
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Spawn()
    {
        self.Precache();

        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        BaseClass.Spawn();
    }

    void PostSpawn()
    {   // No targetname, just run automatically.
        if( self.GetTargetname() == "" )
            self.Use( self, self, USE_TOGGLE );
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( strCommand == "" )
            return;

        if( !self.pev.SpawnFlagBitSet( SF_SERVERCOMMAND ) )
        {
            if( self.pev.netname != "" )
            {
                CBasePlayer@ pTarget;

                if( self.pev.netname == "!activator" )
                    @pTarget = cast<CBasePlayer@>( pActivator );
                else if( self.pev.netname == "!caller" )
                    @pTarget = cast<CBasePlayer@>( pCaller );
                else
                {
                    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
                    {
                        @pTarget = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                        if( pTarget is null || !pTarget.IsConnected() || pTarget.GetTargetname() != self.pev.netname )
                            continue;

                        StuffClient( strCommand, pTarget.edict() );
                    }

                    return;
                }

                if( pTarget !is null && pTarget.IsConnected() )
                    StuffClient( strCommand, pTarget.edict() );
            }
            else
                StuffClient( strCommand );
        }// !-BLOCKED-!: these methods are only exposed to plugin scripts
/*         else
        {   
            g_EngineFuncs.ServerCommand( strCommand );
            g_EngineFuncs.ServerExecute();
        }*/

        if( self.pev.message != "" )
            g_EntityFuncs.FireTargets( self.pev.message, pActivator, pCaller, useType );
    }
};
