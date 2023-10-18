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

    Usage:- Use the key "netname" to add a semlicolon seperated list of entity names you wish to have their origins shuffled around.
    If there are more than one entity for a given name those entities will also be included.
    The angles of the old entity will be applied to the new entity during the shuffle, otherwise you can use flag 1 to disable this so that
    the entity's angles are kept as it was originally placed.

    If you wish to simply randomise the position of one or more entities in a set number of locations, you may use some dummy entity like info_target
    in the other locations and inlcude those entities in the list.

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
    void Spawn()
	{
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		self.pev.effects	|= EF_NODRAW;
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		if( self.GetTargetname() == "" )
			g_Scheduler.SetTimeout( this, "Shuffle", 1.0f, string( self.pev.netname ) );

		BaseClass.Spawn();
	}

    void Shuffle(string strEntityNames)
    {
        if( strEntityNames == "" )
            return;

        array<string> STR_ENTITY_NAMES = strEntityNames.Split( ";" );
        array<EHandle> H_ENTITIES;
        array<Vector> VEC_POSITIONS, VEC_ANGLES, VEC_OCCUPIED;

        for( uint i = 0; i < STR_ENTITY_NAMES.length(); i++ )
        {
            if( STR_ENTITY_NAMES[i] == "" )
                continue;

            CBaseEntity@ pEntity;

            while( ( @pEntity = g_EntityFuncs.FindEntityByTargetname( pEntity, STR_ENTITY_NAMES[i] ) ) !is null )
            {
                if( pEntity is null || H_ENTITIES.findByRef( EHandle( pEntity ) ) >= 0 )
                    continue;

                H_ENTITIES.insertLast( pEntity );
                VEC_POSITIONS.insertLast( pEntity.pev.origin );
                VEC_ANGLES.insertLast( pEntity.pev.angles );
            }
        }

        if( H_ENTITIES.length() < 1 || VEC_POSITIONS.length() < 1 )
            return;

        VEC_OCCUPIED.resize( VEC_POSITIONS.length() );

        for( uint i = 0; i < H_ENTITIES.length(); i++ )
        {
            if( !H_ENTITIES[i] )
                continue;

            CBaseEntity@ pEntity = H_ENTITIES[i].GetEntity();
            Vector 
                vecCurrentPos = pEntity.pev.origin,
                vecRandPos;
            
            do
            {
                vecRandPos = VEC_POSITIONS[Math.RandomLong( 0, VEC_POSITIONS.length() -1 )];
                g_EntityFuncs.SetOrigin( pEntity, vecRandPos );
            }
            while( pEntity.pev.origin == vecCurrentPos || VEC_OCCUPIED.find( pEntity.pev.origin ) >= 0 );

            VEC_OCCUPIED.insertLast( pEntity.pev.origin );

            if( !self.pev.SpawnFlagBitSet( SF_PRESERVE_ANGLES ) )
                pEntity.pev.angles = VEC_ANGLES[VEC_POSITIONS.find( pEntity.pev.origin )];
        }
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        Shuffle( string( self.pev.netname ) );
    }
};
