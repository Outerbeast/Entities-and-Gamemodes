/*  trigger_shuffle_position - Custom entity to randomly shuffle position of a given list of entities

    Installation:-
	- Place in scripts/maps
	- Add
	map_script trigger_shuffle_position
	to your map cfg
	OR
	- Add
	#include "trigger_shuffle_position"
	to your main map script header
	OR
	- Create a trigger_script with these keys set in your map:
	"classname" "trigger_script"
	"m_iszScriptFile" "trigger_shuffle_position"

    Usage:-
    Use the key "netname" to add a semlicolon seperated list of entity names you wish to have their origins shuffled around.
    If there are more than one entity for a given name (meaning there entities with duplicate names) those entities will also be included.
    The angles of the previous entity will be applied to the new entity during the shuffle, otherwise you can check flag 2 to disable this so that
    the entity's angles are kept as it was originally placed.
    You can instead use the key "target" to set target entities to shuffle, though you will need to mark those entities with the custom keyvalue "$s_shuffle"
    If the entity has no targetname set, it will automatically trigger and shuffle the set entities.
    If the entity is triggered with "Off" use type, the entities will revert back to their original positions before being shuffled the first time.

    Keys:-
    "classname" "trigger_shuffle_position"
    "targetname" "target_me" - if targetname is not set, the entity will automatically trigger itself after map is loaded
    "netname" "entityA;entityB;entityC;...;entityZ" - list of entity targetnames to shuffle
    "target" "shuffletarget" - this will target entities with the custom key "$s_shuffle" with the value matching the "target" value

    Flags:-
    1: Start On (no targetname also does this)
    2: Preserve angles - keeps the original orientiation of the entity as it was before it was shuffled

    Extra notes:-
    If you wish to simply randomise the position of one or more entities in a set number of locations, you may use some dummy entity like info_target
    in the other locations and include those dummy entities in the list. This will make it appear as if the entity is placed in a random location.

- Outerbeast
*/
enum shuffleflags
{
    SF_STARTON          = 1 << 0,
    SF_PRESERVE_ANGLES  = 1 << 1,
};

bool blRegisterShufflePositon = RegisterShufflePosition();

bool RegisterShufflePosition()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_shuffle_position", "trigger_shuffle_position" );
    return g_CustomEntityFuncs.IsCustomEntity( "trigger_shuffle_position" );
}

final class trigger_shuffle_position : ScriptBaseEntity
{
    private bool blShuffledOnce;

    void Spawn()
    {
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        self.pev.effects |= EF_NODRAW;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.GetTargetname() == "" || self.pev.SpawnFlagBitSet( SF_STARTON ) )
            g_Scheduler.SetTimeout( this, "Shuffle", 1.0f, string( self.pev.netname ), string( self.pev.target ), false, self.pev.SpawnFlagBitSet( SF_PRESERVE_ANGLES ) );

        BaseClass.Spawn();
    }

    void Shuffle(const string& in strEntityList, const string& in strTarget, bool blResetPositions, bool blPreserveAngles)
    {
        CBaseEntity@ pEntity;
        array<CBaseEntity@> P_ENTITIES;
        array<Vector> VEC_POSITIONS, VEC_ANGLES;
        array<uint> I_OCCUPIED;
        // Could condense this code further, but this will do for now
        if( strEntityList != "" )
        {
            array<string> STR_ENTITY_NAMES = strEntityList.Split( ";" );

            for( uint i = 0; i < STR_ENTITY_NAMES.length(); i++ )
            {
                if( STR_ENTITY_NAMES[i] == "" )
                    continue;

                while( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, STR_ENTITY_NAMES[i] ) ) !is null )
                {
                    if( pEntity is null || P_ENTITIES.findByRef( pEntity ) >= 0 )
                        continue;

                    P_ENTITIES.insertLast( pEntity );
                    VEC_POSITIONS.insertLast( pEntity.pev.origin );
                    VEC_ANGLES.insertLast( pEntity.pev.angles );
                    
                    if( !blShuffledOnce )
                        pEntity.pev.oldorigin = pEntity.pev.origin;
                }
            }
        }
        else if( strTarget != "" )
        {
            for( int i = g_Engine.maxClients + 1; i <= g_EngineFuncs.NumberOfEntities(); i++ )
            {
                @pEntity = g_EntityFuncs.Instance( i );

                if( pEntity is null || !pEntity.IsInWorld() || P_ENTITIES.findByRef( pEntity ) >= 0  )
                    continue;

                CustomKeyvalues@ kvEntity = pEntity.GetCustomKeyvalues();

                if( kvEntity is null || !kvEntity.HasKeyvalue( "$s_shuffle" ) || kvEntity.GetKeyvalue( "$s_shuffle" ).GetString() != strTarget )
                    continue;

                P_ENTITIES.insertLast( pEntity );
                VEC_POSITIONS.insertLast( pEntity.pev.origin );
                VEC_ANGLES.insertLast( pEntity.pev.angles );

                if( !blShuffledOnce )
                    pEntity.pev.oldorigin = pEntity.pev.origin;
            }
        }
        // Unless you show me how to shuffle a set containing one item.
        if( P_ENTITIES.length() < 2 || VEC_POSITIONS.length() < 2 )
            return;
  
        for( uint i = 0; i < P_ENTITIES.length(); i++ )
        {
            @pEntity = P_ENTITIES[i];

            if( pEntity is null )
                continue;

            if( blResetPositions )
            {
                if( pEntity.pev.oldorigin == g_vecZero )
                    continue;

                if( pEntity.pev.oldorigin != pEntity.pev.origin )
                    g_EntityFuncs.SetOrigin( pEntity, pEntity.pev.oldorigin );
            }
            else
            {//Select a position of an entity at random
                uint iRandomIdx = 0;

                do
                    iRandomIdx = Math.RandomLong( 0, VEC_POSITIONS.length() - 1 );
                while( I_OCCUPIED.find( iRandomIdx ) >= 0 );
                
                g_EntityFuncs.SetOrigin( pEntity, VEC_POSITIONS[iRandomIdx] );
                I_OCCUPIED.insertLast( iRandomIdx );

                if( blPreserveAngles )
                    pEntity.pev.angles = VEC_ANGLES[VEC_POSITIONS.find( pEntity.pev.origin )];
            }
        }

        blShuffledOnce = true;
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( self.pev.target != "" )
            Shuffle( "", self.pev.target, useType == USE_OFF || useType == USE_KILL, self.pev.SpawnFlagBitSet( SF_PRESERVE_ANGLES ) );
        else
            Shuffle( self.pev.netname, "", useType == USE_OFF || useType == USE_KILL, self.pev.SpawnFlagBitSet( SF_PRESERVE_ANGLES ) );
    }
};
