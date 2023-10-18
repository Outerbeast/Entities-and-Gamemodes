/* trigger_entity_alias - Custom entity to trigger entities through an alias system

    Installation:-
	- Place in scripts/maps
	- Add
	map_script trigger_entity_alias
	to your map cfg
	OR
	- Add
	#include "trigger_entity_alias"
	to your main map script header
	OR
	- Create a trigger_script with these keys set in your map:
	"classname" "trigger_script"
	"m_iszScriptFile" "trigger_entity_alias"

    Usage:-
    This entity allows you to target an entity with an alternative name (an alias) rather than via targetname directly.
    This is useful if you wish to trigger an entity that already has a targetname which is shared with other entities, but only trigger that entity and nothing else.
    The entity(s) that you wish to target target must have an alias key, which is a custom key of the form "$s_alias" "alias_name".

    Keys:-
    "alias" "alias_name"            - Entities whose "$s_alias" keyvalue matches this will become targetted. Wildcards are supported.
    "name_filter" "targetname"      - Only target aliased entities that have this targetname (optional but recommended). Can be used in conjunction with "classname_filter"
    "classname_filter" "classname"  - Only target aliased entities that have this classname (optional but recommended). Can be used in conjunction with "name_filter"
    "target" "iterated_entity"      - (Optional) Name of a given entity that will perform its action upon the aliased entities (Must have !activator). Otherwise, the aliased entities are triggered directly.
    "triggerstate" "s"              - The use type that the aliased (or target) entity is triggered with. Default value is 2(Toggle). If you want to remove (killtarget) use the value 4.

- Outerbeast
*/
bool blRegisterEntityAlias = RegisterEntityAlias();

bool RegisterEntityAlias()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_entity_alias", "trigger_entity_alias" );
    return g_CustomEntityFuncs.IsCustomEntity( "trigger_entity_alias" );
}

final class trigger_entity_alias : ScriptBaseEntity
{
    private string 
        strAlias,
        strNameFilter,
        strClassnameFilter;

    private USE_TYPE utTriggerState = USE_TOGGLE;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "alias" )
            strAlias = szValue;
        else if( szKey == "name_filter" )
            strNameFilter =  szValue;
        else if( szKey == "classname_filter" )
            strClassnameFilter = szValue;
        else if( szKey == "triggerstate" )
            utTriggerState = USE_TYPE( atoui( szValue ) < 0 ? 0 : atoui( szValue ) );
        else
            return BaseClass.KeyValue( szKey, szValue );
            
        return true;
    }

    void Spawn()
	{
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		self.pev.effects	|= EF_NODRAW;
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		BaseClass.Spawn();
	}

    bool FMatchAlias(EHandle hEntity)
    {
        if( !hEntity )
            return false;

        CustomKeyvalues@ kvEntity = hEntity.GetEntity().GetCustomKeyvalues();

        if( kvEntity is null || !kvEntity.HasKeyvalue( "$s_alias" ) )
            return false;

        if( strAlias.EndsWith( "*" ) )
        {
            string s = strAlias;
            s.Trim( '*' );

            return kvEntity.GetKeyvalue( "$s_alias" ).GetString().StartsWith( s );
        }
        else
            return kvEntity.GetKeyvalue( "$s_alias" ).GetString() == strAlias;
    }

    array<EHandle>@ GetAliasedEntities()
    {
        CBaseEntity@ pEntity;
        array<EHandle> H_ALIASES;

        if( strNameFilter == "" && strClassnameFilter == "" )
        {
            for( int i = g_Engine.maxClients + 1; i <= g_EngineFuncs.NumberOfEntities(); i++ )
            {
                @pEntity = g_EntityFuncs.Instance( i );

                if( pEntity is null || pEntity is self || !FMatchAlias( pEntity ) )
                    continue;

                H_ALIASES.insertLast( pEntity );
            }
        }
        else
        {
            if( strNameFilter != "" )
            {
                while( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, strNameFilter ) ) !is null )
                {
                    if( pEntity is null || pEntity is self || !FMatchAlias( pEntity ) )
                        continue;

                    H_ALIASES.insertLast( pEntity );
                }
            }

            if( strClassnameFilter != "" )
            {
                while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, strClassnameFilter ) ) !is null )
                {
                    if( pEntity is null || pEntity is self || !FMatchAlias( pEntity ) )
                        continue;

                    H_ALIASES.insertLast( pEntity );
                }
            }
        }

        if( strNameFilter != "" && strClassnameFilter != "" )
        {
            for( uint i = 0; i < H_ALIASES.length(); i++ )
            {
                if( !H_ALIASES[i] )
                    continue;

                @pEntity = H_ALIASES[i].GetEntity();

                if( pEntity.GetClassname() == strClassnameFilter && pEntity.GetTargetname() != strNameFilter )
                    H_ALIASES[i] = EHandle();

                if( pEntity.GetClassname() != strClassnameFilter && pEntity.GetTargetname() == strNameFilter )
                    H_ALIASES[i] = EHandle();
            }
        }

        return H_ALIASES;
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( self.pev.target == self.GetTargetname() || strAlias == "" )
            return;

        if( utTriggerState < USE_OFF || utTriggerState > USE_KILL )
            utTriggerState = useType;// Same as source

        const array<EHandle> H_ALIASES = GetAliasedEntities();

        if( H_ALIASES.length() < 1 )
            return;

        for( uint i = 0; i < H_ALIASES.length(); i++ )
        {
            if( !H_ALIASES[i] )
                continue;

            if( self.pev.target == ""  || self.pev.target == self.GetTargetname() )
            {
                if( utTriggerState != USE_KILL )
                    H_ALIASES[i].GetEntity().Use( pActivator, pCaller, utTriggerState, 0.0f );// Direct trigger
                else
                    g_EntityFuncs.Remove( H_ALIASES[i].GetEntity() );// killtarget
            }
            else// Use the target entity and iterate its operation to all aliased entities
            {
                CBaseEntity@ pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, string( self.pev.target ) );

                if( pEntity !is null )
                    pEntity.Use( H_ALIASES[i].GetEntity(), pCaller, utTriggerState, 0.0f );
            }
        }
    }
};
