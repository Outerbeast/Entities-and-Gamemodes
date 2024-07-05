/* trigger_entity_volume
    Custom game_zone_player entity with resiazble bbox and extended functionality to monsters, pushables and platform entities

    Installation:-
    - Place in scripts/maps
    - Add
    map_script trigger_entity_volume
    to your map cfg
    OR
    - Add
    #include "trigger_entity_volume"
    to your main map script header
    OR
    - Create a trigger_script with these keys set in your map:
    "classname" "trigger_script"
    "m_iszScriptFile" "trigger_entity_volume"

    Keys:-
    "classname" "trigger_entity_volume"
    "incount" "i"                           - min number of entities required to be in the zone to trigger "intarget"
    "intarget" "target_entity"              - target to trigger for entities inside the zone
    "outcount" "o"                          - min number of entities required to be outside the zone to trigger "outcount"
    "outtarget" "target_entity"             - target to trigger for entities outside the zone
    "target_incount_fail" "target_entity"   - target to trigger when incount condition fails
    "target_outcount_fail" "target_entity"  - target to trigger when outcount condition fails
    "zoneradius" "256"                      - Radius to define the zone
    "zonecornermin" "x1 y1 z1               - Entity bbox min position
    "zonecornermax" "x2 y2 z2"              - Entity bbox max position
    "spawnflags" "f"                        - See Flags section below

    Flags:-
    "1" : Ignore Dead       - Dead players are not counted when triggered
    "2" : Start Inactive    - Entity has to be triggered first then it will become activated and perform its actions
    "4"	: Pushables         - Include func_pushable entities
    "8" : No players        - Players will be excluded from the entity
    "16": Platforms         - Include platform entities ( func_plat, func_train, etc)
    "32": Monsters          - Include monsters

    By default the entity will use its position and radius for its zone boundary, if a bounding box is not set via zonecornermin/max keys.
    "incount"/"outcount" keys are at default 0 and are optional.
    When triggered, the current number of entities inside the zone is stored in the entity's "health" key and "frags" for entities outside.

    - Outerbeast
*/
namespace TRIGGER_ENTITY_VOLUME
{

enum entity_zone_flags
{
    SF_IGNORE_DEAD 		= 1 << 0,
    SF_START_INACTIVE 	= 1 << 1,
    SF_PUSHABLES		= 1 << 2,
    SF_PLATFORMS		= 1 << 4,
    SF_DOORS			= 1 << 6
};

const array<string> STR_MOVEABLE_ENTS =
{
    "func_pushable",
    "func_door*",
    "func_plat",
    "func_platrot",
    "func_train",
    "func_tracktrain",
    "func_vehicle"// "future proofing" with some hopium
};

bool blRegisterTriggerEntityVolume = RegisterTriggerEntityVolume();

bool RegisterTriggerEntityVolume()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "TRIGGER_ENTITY_VOLUME::trigger_entity_volume", "trigger_entity_volume" );
    return g_CustomEntityFuncs.IsCustomEntity( "trigger_entity_volume" );
}

final class trigger_entity_volume : ScriptBaseEntity
{
    private string strInTarget, strOutTarget, strFailInTarget, strFailOutTarget, strClassnameFilter, strTargetnameFilter;
    private uint iInCount, iOutCount, 
        iMaxCount = 128, 
        iFlagMask = FL_CLIENT;
    private Vector vecZoneCornerMin, vecZoneCornerMax;
    private float flZoneRadius = 256.0f;
    private bool blActivated = true;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "intarget" )
            strInTarget = szValue;
        else if( szKey == "outtarget" )
            strOutTarget = szValue;
        else if( szKey == "target_incount_fail" )
            strFailInTarget = szValue;
        else if( szKey == "target_outcount_fail" )
            strFailOutTarget = szValue;
        else if( szKey == "incount" )
            iInCount = atoui( szValue );
        else if( szKey ==  "outcount" )
            iOutCount = atoui( szValue );
        else if( szKey ==  "maxcount" )
            iMaxCount = atoui( szValue );
        else if( szKey == "zoneradius" )
            flZoneRadius = Math.clamp( 16.0f, 2048.0f, atof( szValue ) );
        else if( szKey == "zonecornermin" )
            g_Utility.StringToVector( vecZoneCornerMin, szValue );
        else if( szKey == "zonecornermax" )
            g_Utility.StringToVector( vecZoneCornerMax, szValue );
        else if( szKey == "classname_filter" )
            strClassnameFilter = szValue;
        else if( szKey == "targetname_filter" )
            strTargetnameFilter = szValue;
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Spawn()
    {
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( vecZoneCornerMin != g_vecZero && vecZoneCornerMax != g_vecZero && vecZoneCornerMin != vecZoneCornerMax )
        {
            self.pev.mins = vecZoneCornerMin - self.pev.origin;
            self.pev.maxs = vecZoneCornerMax - self.pev.origin;
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }

        if( flZoneRadius < 16.0f )
            flZoneRadius = 256.0f;

        blActivated = !self.pev.SpawnFlagBitSet( SF_START_INACTIVE );

        BaseClass.Spawn();
    }

    bool FIsInZone(EHandle hEntity)
    {
        if( !hEntity )
            return false;

        if( self.pev.absmin != g_vecZero && self.pev.absmax != g_vecZero && self.pev.absmin != self.pev.absmax )
            return hEntity.GetEntity().Intersects( self );
        else
        {
            Vector vecCenter = hEntity.GetEntity().IsBSPModel() ? hEntity.GetEntity().Center() : hEntity.GetEntity().pev.origin;
            return ( self.pev.origin - vecCenter ).Length() <= flZoneRadius;
        }
    }

    bool FMatchClassnameFilter(const string strClassname)
    {
        if( strClassnameFilter == "" )
            return true;

        if( strClassnameFilter.EndsWith( "*" ) )
        {
            string s = strClassnameFilter;
            s.Trim( '*' );

            return strClassname.StartsWith( s );
        }
        else
            return strClassname == strClassnameFilter;
    }

    bool FMatchTargetnameFilter(const string strTargetname)
    {
        if( strTargetnameFilter == "" )
            return true;

        if( strTargetnameFilter.EndsWith( "*" ) )
        {
            string s = strTargetnameFilter;
            s.Trim( '*' );

            return strTargetname.StartsWith( s );
        }
        else
            return strTargetname == strTargetnameFilter;
    }

    uint ZoneEntities(array<EHandle>@ H_ENTITIES_INZONE, array<EHandle>@ H_ENTITIES_OUTZONE) 
    {
        if( self.pev.SpawnFlagBitSet( FL_MONSTER ) )
            iFlagMask |= FL_MONSTER;

        if( self.pev.SpawnFlagBitSet( FL_CLIENT ) )
            iFlagMask &= ~FL_CLIENT;

        array<CBaseEntity@> P_ENTITIES( iMaxCount );

        if( iFlagMask > 0 && g_EntityFuncs.Instance( 0 ).FindMonstersInWorld( @P_ENTITIES, iFlagMask ) > 0 )
        {
            for( uint i = 0; i < P_ENTITIES.length(); i++ )
            {
                if( P_ENTITIES[i] is null || ( self.pev.SpawnFlagBitSet( SF_IGNORE_DEAD ) && !P_ENTITIES[i].IsAlive() ) )
                    continue;

                if( !FMatchClassnameFilter( P_ENTITIES[i].GetClassname() ) || !FMatchTargetnameFilter( P_ENTITIES[i].GetTargetname() ) )
                    continue;

                if( FIsInZone( P_ENTITIES[i] ) )
                    H_ENTITIES_INZONE.insertLast( EHandle( P_ENTITIES[i] ) );
                else
                    H_ENTITIES_OUTZONE.insertLast( EHandle( P_ENTITIES[i] ) );
            }
        }

        if( self.pev.SpawnFlagBitSet( SF_PUSHABLES ) || self.pev.SpawnFlagBitSet( SF_PLATFORMS ) )
        {
            uint
                i = 0,
                j = self.pev.SpawnFlagBitSet( SF_PLATFORMS ) ? STR_MOVEABLE_ENTS.length() : 1;

            for( ; i < j; i++ )
            {
                if( STR_MOVEABLE_ENTS[i] == "func_pushable" && !self.pev.SpawnFlagBitSet( SF_PUSHABLES ) )
                    continue;

                CBaseEntity@ pEntity;

                while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, STR_MOVEABLE_ENTS[i] ) ) !is null )
                {
                    if( pEntity is null || !FMatchClassnameFilter( pEntity.GetClassname() ) || !FMatchTargetnameFilter( pEntity.GetTargetname() ) )
                        continue;

                    if( FIsInZone( pEntity ) )
                        H_ENTITIES_INZONE.insertLast( pEntity );
                    else
                        H_ENTITIES_OUTZONE.insertLast( pEntity );
                }
            }
        }

        self.pev.health = H_ENTITIES_INZONE.length();
        self.pev.frags = H_ENTITIES_OUTZONE.length();

        return H_ENTITIES_INZONE.length() + H_ENTITIES_OUTZONE.length();
    }

    uint TargetIterate(string strTarget, const array<EHandle>@ H_TARGETS, EHandle hOther = EHandle(), USE_TYPE useType = USE_TOGGLE)
    {
        if( strTarget == "" || H_TARGETS.length() < 1 )
            return 0;

        uint iTargetsTriggered = 0;

        for( uint i = 0; i < H_TARGETS.length(); i++ )
        {
            if( !H_TARGETS[i] )
                continue;

            if( !hOther )
                hOther = H_TARGETS[i];

            g_EntityFuncs.FireTargets( strTarget, H_TARGETS[i].GetEntity(), hOther.GetEntity(), useType );
            iTargetsTriggered++;
        }

        return iTargetsTriggered;
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( !blActivated )
        {
            blActivated = true;
            return;
        }

        array<EHandle> H_ENTITIES_INZONE, H_ENTITIES_OUTZONE;

        if( ZoneEntities( H_ENTITIES_INZONE, H_ENTITIES_OUTZONE ) < 1 )
            return;

        uint iTotalTargetsTriggered = 0;

        EHandle hOther = pActivator !is null ? pActivator : ( pCaller !is null ? pCaller : self );

        if( strInTarget != "" && strInTarget != self.GetTargetname() && uint( self.pev.health ) >= iInCount )
            iTotalTargetsTriggered += TargetIterate( strInTarget, @H_ENTITIES_INZONE, hOther, useType );
        else
            g_EntityFuncs.FireTargets( strFailInTarget, pActivator, pCaller, useType );

        if( strOutTarget != "" && strOutTarget != self.GetTargetname() && uint( self.pev.frags ) >= iOutCount )
            iTotalTargetsTriggered += TargetIterate( strOutTarget, @H_ENTITIES_OUTZONE, hOther, useType );
        else
            g_EntityFuncs.FireTargets( strFailOutTarget, pActivator, pCaller, useType );

        if( iTotalTargetsTriggered > 0 && self.pev.target != "" && self.pev.target != self.GetTargetname() )
            self.SUB_UseTargets( pActivator, useType, 0.0f );
    }

};

}
