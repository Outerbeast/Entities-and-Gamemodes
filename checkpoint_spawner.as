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

class checkpoint_spawner : ScriptBaseEntity
{
	private string strFunnelSprite 	= "sprites/glow01.spr";
	private string strStartSound 	= "ambience/particle_suck2.wav";
	private string strEndSound 		= "debris/beamstart7.wav";
	private string strModel 		= "models/common/lambda.mdl";

	private float m_flDelayBeforeStart = 3, m_flDelayBetweenRevive = 1, m_flDelayBeforeReactivation = 60; 					
	private bool m_fSpawnEffect = false; 

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "m_flDelayBeforeStart" )
			m_flDelayBeforeStart = atof( szValue );
		else if( szKey == "m_flDelayBetweenRevive" )
			m_flDelayBetweenRevive = atof( szValue );
		else if( szKey == "m_flDelayBeforeReactivation" )
			m_flDelayBeforeReactivation = atof( szValue );
		else if( szKey == "minhullsize" )
			g_Utility.StringToVector( self.pev.vuser1, szValue );
		else if( szKey == "maxhullsize" )
			g_Utility.StringToVector( self.pev.vuser2, szValue );
		else if( szKey == "m_fSpawnEffect" )
			m_fSpawnEffect = atoi( szValue ) != 0;
		else if( szKey == "checkpoint_model" )
			strModel = szValue;
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
		g_Game.PrecacheModel( strModel );
		g_Game.PrecacheGeneric( strModel );

		g_Game.PrecacheModel( strFunnelSprite );
		g_Game.PrecacheGeneric( strFunnelSprite );

		g_SoundSystem.PrecacheSound( strStartSound );
		g_SoundSystem.PrecacheSound( strEndSound );

		g_Game.PrecacheGeneric( strStartSound );
		g_Game.PrecacheGeneric( strEndSound );

		BaseClass.Precache();
	}

	void Spawn()
	{
		self.Precache();
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		if( !g_SurvivalMode.IsActive() )
			return;

		g_Scheduler.SetTimeout( this, "SpawnSnd", 1.6f );

		NetworkMessage largefunnel( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
			largefunnel.WriteByte( TE_LARGEFUNNEL );

			largefunnel.WriteCoord( self.pev.origin.x );
			largefunnel.WriteCoord( self.pev.origin.y );
			largefunnel.WriteCoord( self.pev.origin.z );

			largefunnel.WriteShort( g_EngineFuncs.ModelIndex( "" + strFunnelSprite ) );
			largefunnel.WriteShort( 0 );
		largefunnel.End();

		g_Scheduler.SetTimeout( this, "CreateCheckpoint", 6.0f );
	}

	void SpawnSnd()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, strStartSound, 1.0f, ATTN_NORM );
	}

	void CreateCheckpoint()
	{
		dictionary cp;
		cp ["origin"]						= self.GetOrigin().ToString();
		cp ["angles"]						= self.pev.angles.ToString();
		cp ["target"]						= string( self.pev.target );
		cp ["minhullsize"]					= self.pev.vuser1.ToString();
		cp ["maxhullsize"]					= self.pev.vuser2.ToString();
		cp ["model"]						= strModel;
		cp ["m_fSpawnEffect"]				= "" + m_fSpawnEffect;
		cp ["m_flDelayBeforeReactivation"]	= "" + m_flDelayBeforeReactivation;
		cp ["m_flDelayBetweenRevive"]		= "" + m_flDelayBetweenRevive;
		cp ["m_flDelayBeforeStart"]			= "" + m_flDelayBeforeStart;
		cp ["spawnflags"]					= "" + ( self.pev.spawnflags & SF_CHECKPOINT_REUSABLE );

		g_EntityFuncs.CreateEntity( "point_checkpoint", cp, true );
		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, strEndSound, 1.0f, ATTN_NORM );

		if( !self.pev.SpawnFlagBitSet( 2 ) )
			g_EntityFuncs.Remove( self );
	}
}
