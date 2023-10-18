/* trigger_entity_volume
	Custom game_zone_player entity with resiazble bbox and extended functionality to monsters

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
	"incount" "i" 								- min number of entities required to be in the zone to trigger "intarget"
	"intarget" "target_entity"					- target to trigger for entities inside the zone
	"outcount" "o"								- min number of entities reqyired to be outside the zone to trigger "outcount"
	"outtarget" "target_entity" 				- target to trigger for entities outside the zone
	"target_incount_fail" "target_entity"		- target to trigger when incount condition fails
	"target_outcount_fail" "target_entity"		- target to trigger when outcount condition fails
	"zoneradius" "256"							- Radius to define the zone
	"zonecornermin" "x1 y1 z1   				- Entity bbox min position
	"zonecornermax" "x2 y2 z2"					- Entity bbox max position
	"spawnflags" "f"							- See Flags section below

	By default the entity will use its position and radius for its zone boundary, if a bounding box is not set via zonecornermin/max keys.
	"incount"/"outcount" keys are at default 0 and are optional.
	When triggered, the current number of entities inside the zone stored in the entity's "health" key and "frags" for entities outside.
	For more information on how to set up the targets and counters, visit the game_zone_player page in the SC Wiki:
	https://wiki.svencoop.com/Game_zone_player

	Flags:-
	"1" : Ignore Dead 		- Dead players are not counted when triggered
	"2" : Start Inactive 	- Entity has to be triggered first then it will become activated and perform its actions
	"8" : No players 		- Players will be excluded from the entity
	"32": Monsters 			- Include monsters

	- Outerbeast
*/
enum entity_zone_flags
{
	SF_IGNORE_DEAD 		= 1 << 0,
	SF_START_INACTIVE 	= 1 << 1
};

bool blRegisterTriggerEntityVolume = RegisterTriggerEntityVolume();

bool RegisterTriggerEntityVolume()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_entity_volume", "trigger_entity_volume" );
	return g_CustomEntityFuncs.IsCustomEntity( "trigger_entity_volume" );
}

final class trigger_entity_volume : ScriptBaseEntity
{
	private string strInTarget, strOutTarget, strFailInTarget, strFailOutTarget;
	private uint iInCount, iOutCount, iMaxCount = 128, iFlagMask = FL_CLIENT;
	private Vector vecZoneCornerMin, vecZoneCornerMax;
	private float flZoneRadius = 256;
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
			self.pev.mins = vecZoneCornerMin - self.GetOrigin();
			self.pev.maxs = vecZoneCornerMax - self.GetOrigin();
			g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
		}

		blActivated = !self.pev.SpawnFlagBitSet( SF_START_INACTIVE );

		BaseClass.Spawn();
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		if( !blActivated )
		{
			blActivated = true;
			return;
		}

		if( self.pev.SpawnFlagBitSet( FL_MONSTER ) )
			iFlagMask |= FL_MONSTER;

		if( self.pev.SpawnFlagBitSet( FL_CLIENT ) )
			iFlagMask &= ~FL_CLIENT;

		array<CBaseEntity@> P_ENTITIES( iMaxCount );
		uint iTotalTargetsTriggered = 0;

		if( g_EntityFuncs.Instance( 0 ).FindMonstersInWorld( @P_ENTITIES, iFlagMask ) < 1 )
			return;

		array<EHandle> H_ENTITIES_INZONE, H_ENTITIES_OUTZONE;

		for( uint i = 0; i < P_ENTITIES.length(); i++ )
		{
			if( P_ENTITIES[i] is null || ( self.pev.SpawnFlagBitSet( SF_IGNORE_DEAD ) && !P_ENTITIES[i].IsAlive() ) )
				continue;

			if( FIsInZone( P_ENTITIES[i] ) )
				H_ENTITIES_INZONE.insertLast( EHandle( P_ENTITIES[i] ) );
			else
				H_ENTITIES_OUTZONE.insertLast( EHandle( P_ENTITIES[i] ) );
		}

		self.pev.health = H_ENTITIES_INZONE.length();
		self.pev.frags = H_ENTITIES_OUTZONE.length();

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
		
	uint TargetIterate(string strTarget, array<EHandle>@ H_ENTITIES, EHandle hOther = EHandle( null ), USE_TYPE useType = USE_TOGGLE)
	{
		uint iTargetsTriggered = 0;

		for( uint i = 0; i < H_ENTITIES.length(); i++ )
		{
			if( !H_ENTITIES[i] )
				continue;

			if( !hOther )
				hOther = H_ENTITIES[i];

			g_EntityFuncs.FireTargets( strTarget, H_ENTITIES[i].GetEntity(), hOther.GetEntity(), useType );
			iTargetsTriggered++;
		}

		return iTargetsTriggered;
	}

 	bool FIsInZone(EHandle hEntity)
	{
		if( !hEntity )
			return false;

		if( self.pev.absmin != g_vecZero && self.pev.absmax != g_vecZero && self.pev.absmin != self.pev.absmax )
			return hEntity.GetEntity().Intersects( self );
		else
			return EntityInRadius( hEntity, self.GetOrigin(), flZoneRadius );
	}
	// Note to devs: add this as a CUtility method please!!!
	bool EntityInRadius(EHandle hEntity, Vector vecOrigin, float flRadius)
	{
		if( !hEntity || flRadius <= 0 )
			return false;

		return( ( vecOrigin - hEntity.GetEntity().pev.origin ).Length() <= flRadius );
	}
};
