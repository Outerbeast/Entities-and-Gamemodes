/* checkpoint_spawner- Custom entity for spawning a new point_checkpoint with spawn fx
This entity only triggers when survival mode is active.
Entity supports all the keyvalues that point_checkpoint does
Additional keys:-
"sprite" "sprites/path/to/sprite.spr"	- customise the sprite for the spawn fx
"model" "models/path/to/model.mdl"		- customise the checkpoint model
"startsound" "path/to/sound.wav"		- customise spawning start sound fx
"endsound" "path/to/sound.wav"			- customise spawning end sound fx
- Outerbeast 
*/
#include "../point_checkpoint"

void RegisterCheckPointSpawnerEntity(const bool blPrecache = false)
{
	g_CustomEntityFuncs.RegisterCustomEntity( "point_checkpoint", "point_checkpoint" );
	g_CustomEntityFuncs.RegisterCustomEntity( "checkpoint_spawner", "checkpoint_spawner" );

	if( blPrecache )
	{
		g_Game.PrecacheOther( "point_checkpoint" );
		g_Game.PrecacheOther( "checkpoint_spawner" );
	}
}

final class checkpoint_spawner : ScriptBaseEntity
{
	CScheduledFunction@ fnSpawnSnd, fnCreateCheckoint;

	private string 
		strFunnelSprite = "sprites/glow01.spr",
		strStartSound 	= "ambience/particle_suck2.wav",
		strEndSound 	= "debris/beamstart7.wav";

	private dictionary dictCheckpointValues =
	{
		{ "model", "models/common/lambda.mdl" },
		{ "m_flDelayBeforeStart", "3" },
		{ "m_flDelayBetweenRevive", "1" },
		{ "m_flDelayBeforeReactivation", "60" },
		{ "m_fSpawnEffect", "0" }
	};

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if( szKey == "m_flDelayBeforeStart" ||
			szKey == "m_flDelayBetweenRevive" ||
			szKey == "m_flDelayBeforeReactivation" ||
			szKey == "minhullsize" ||
			szKey == "maxhullsize" )
			dictCheckpointValues[szKey] = szValue;
		else if( szKey == "m_fSpawnEffect" )
			dictCheckpointValues[szKey] = atoi( szValue ) != 0 ? "1" : "0";
		else if( szKey == "checkpoint_model" )
			dictCheckpointValues["model"] = szValue;
		else if( szKey == "sprite" )
			strFunnelSprite = szValue;
		else if( szKey == "startsound" )
			strStartSound = szValue;
		else if( szKey == "endsound" )
			strEndSound = szValue;
		else
			return BaseClass.KeyValue( szKey, szValue );

		return true;
	}

	void Precache()
	{
		g_Game.PrecacheOther( "point_checkpoint" );
		
		g_Game.PrecacheModel( string( dictCheckpointValues["model"] ) );
		g_Game.PrecacheGeneric( string( dictCheckpointValues["model"] ) );

		g_Game.PrecacheModel( strFunnelSprite );
		g_Game.PrecacheGeneric( strFunnelSprite );

		g_SoundSystem.PrecacheSound( strStartSound );
		g_SoundSystem.PrecacheSound( strEndSound );

		g_Game.PrecacheGeneric( "sound/" + strStartSound );
		g_Game.PrecacheGeneric( "sound/" + strEndSound );

		BaseClass.Precache();
	}

	void Spawn()
	{
		self.Precache();
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		BaseClass.Spawn();
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		if( !g_SurvivalMode.IsActive() )
			return;

		@fnSpawnSnd = g_Scheduler.SetTimeout( this, "SpawnSnd", 1.6f );

		NetworkMessage largefunnel( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
			largefunnel.WriteByte( TE_LARGEFUNNEL );

			largefunnel.WriteCoord( self.pev.origin.x );
			largefunnel.WriteCoord( self.pev.origin.y );
			largefunnel.WriteCoord( self.pev.origin.z );

			largefunnel.WriteShort( g_EngineFuncs.ModelIndex( "" + strFunnelSprite ) );
			largefunnel.WriteShort( 0 );
		largefunnel.End();

		@fnCreateCheckoint = g_Scheduler.SetTimeout( this, "CreateCheckpoint", 6.0f );
	}

	void SpawnSnd()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, strStartSound, 1.0f, ATTN_NORM );
	}

	void CreateCheckpoint()
	{
		dictCheckpointValues["origin"]		= self.GetOrigin().ToString();
		dictCheckpointValues["angles"]		= self.pev.angles.ToString();
		dictCheckpointValues["target"]		= string( self.pev.target );
		dictCheckpointValues["spawnflags"]	= "" + ( self.pev.spawnflags & SF_CHECKPOINT_REUSABLE );

		g_EntityFuncs.CreateEntity( "point_checkpoint", dictCheckpointValues, true );
		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, strEndSound, 1.0f, ATTN_NORM );

		if( !self.pev.SpawnFlagBitSet( 1 << 1 ) )
			g_EntityFuncs.Remove( self );
	}

	void UpdateOnRemove()
	{
		if( fnSpawnSnd !is null )
			g_Scheduler.RemoveTimer( fnSpawnSnd );

		if( fnCreateCheckoint !is null )
			g_Scheduler.RemoveTimer( fnCreateCheckoint );
	}
}
