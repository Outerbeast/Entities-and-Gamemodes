/* checkpoint_spawner- Custom entity for spawning a new point_checkpoint with spawn fx
 - Outerbeast 
*/
#include "../point_checkpoint"

class checkpoint_spawner : ScriptBaseEntity
{
	private float m_flDelayBeforeStart = 3;
	private float m_flDelayBetweenRevive = 1;
	private float m_flDelayBeforeReactivation = 60; 					
	private bool m_fSpawnEffect = false; 

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "m_flDelayBeforeStart" )
		{
			m_flDelayBeforeStart = atof( szValue );
			return true;
		}
		else if( szKey == "m_flDelayBetweenRevive" )
		{
			m_flDelayBetweenRevive = atof( szValue );
			return true;
		}
		else if( szKey == "m_flDelayBeforeReactivation" )
		{
			m_flDelayBeforeReactivation = atof( szValue );
			return true;
		}
		else if( szKey == "minhullsize" )
		{
			g_Utility.StringToVector( self.pev.vuser1, szValue );
			return true;
		}
		else if( szKey == "maxhullsize" )
		{
			g_Utility.StringToVector( self.pev.vuser2, szValue );
			return true;
		}
		else if( szKey == "m_fSpawnEffect" )
		{
			m_fSpawnEffect = atoi( szValue ) != 0;
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/common/lambda.mdl" );
		g_Game.PrecacheModel( "sprites/glow01.spr" );

		g_Game.PrecacheGeneric( "sprites/glow01.spr" );

		g_SoundSystem.PrecacheSound( "ambience/particle_suck2.wav" );
		g_SoundSystem.PrecacheSound( "debris/beamstart7.wav" );
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
		if( g_SurvivalMode.IsActive() )
		{
			g_Scheduler.SetTimeout( this, "SpawnSnd", 1.6f );

			NetworkMessage m( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
				m.WriteByte( TE_LARGEFUNNEL );

				m.WriteCoord( self.pev.origin.x );
				m.WriteCoord( self.pev.origin.y );
				m.WriteCoord( self.pev.origin.z );

				m.WriteShort( g_EngineFuncs.ModelIndex( "sprites/glow01.spr" ) );
				m.WriteShort( 0 );
			m.End();

			g_Scheduler.SetTimeout( this, "SpawnCheckpoint", 6.0f );
		}
	}

	void SpawnSnd()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "ambience/particle_suck2.wav", 1.0f, ATTN_NORM );
	}

	void SpawnCheckpoint()
	{
		dictionary cp;
		cp ["origin"]                         = "" + self.GetOrigin().ToString();
		cp ["angles"]                         = "" + self.pev.angles.ToString();
		cp ["target"]                         = "" + self.pev.target;
		cp ["m_fSpawnEffect"]                 = "" + m_fSpawnEffect;
		cp ["m_flDelayBeforeReactivation"]    = "" + m_flDelayBeforeReactivation;
		cp ["m_flDelayBetweenRevive"]         = "" + m_flDelayBetweenRevive;
		cp ["m_flDelayBeforeStart"]           = "" + m_flDelayBeforeStart;
		CBaseEntity@ CheckPoint = g_EntityFuncs.CreateEntity( "point_checkpoint", cp, true );

		g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "debris/beamstart7.wav", 1.0f, ATTN_NORM );
		g_EntityFuncs.Remove( self ); 
	}
}

void RegisterCheckPointSpawnerEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "checkpoint_spawner", "checkpoint_spawner" );
	g_CustomEntityFuncs.RegisterCustomEntity( "point_checkpoint", "point_checkpoint" );
}