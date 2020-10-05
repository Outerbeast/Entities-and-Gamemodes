/* trigger_sound brush entity from SoHL to be compatible with Sven Co-op
Basically env_sound but relies on a trigger zone instead of a radius- yes this is completely
needless and stupid idea and I am clueless as to why the mods implemented this when default env_sound is sufficient.

Do not use this for maps you are building, this is purely for compatibility in map conversions.
Use env_sound instead.
- Outerbeast */

class trigger_sound : ScriptBaseEntity 
{
	uint iRadius = 128;
	string EnvSoundTName = "";
	Vector vOrigin;
	array<bool> _HAS_TRIGGERED(33);

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "roomtype" )
		{
    		self.pev.health = atoi( szValue ); // Assigning it to health kv so its compatible with Azure Sheep maps that use "health" key directly instead of "roomtype"
    		return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
	
	void Spawn() 
    {
		self.pev.movetype 		= MOVETYPE_NONE;
		self.pev.solid 			= SOLID_NOT;
		self.pev.framerate 		= 1.0f;
		self.pev.effects 		|= EF_NODRAW;
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetModel(self, self.pev.model);
		g_EntityFuncs.SetSize(self.pev, self.pev.mins, self.pev.maxs);

		vOrigin = ( self.pev.absmin + self.pev.absmax )*0.5f;
		iRadius = uint( ( vOrigin - self.pev.absmin ).Length() );
		if( self.GetTargetname() == "" ){ EnvSoundTName = "trigger_sound_nu" + string( self.pev.model ).Replace( "*","m" ); }
		else
			EnvSoundTName = self.pev.targetname;

		CreateEnvSound();

		SetThink( ThinkFunction( this.TriggerThink ) );
        self.pev.nextthink = g_Engine.time + 5.0f;
	}

	void CreateEnvSound()
	{
		dictionary keys;
		keys ["origin"]		= ( "" + string(vOrigin.x) + " " + string(vOrigin.y) + " " + string(vOrigin.z) );
		keys ["targetname"]	= ( "" + EnvSoundTName );
        keys ["roomtype"]	= ( "" + self.pev.health );
		keys ["radius"]		= ( "" + iRadius );
		keys ["spawnflags"]	= ( "1" );

		CBaseEntity@ EnvSound = g_EntityFuncs.CreateEntity( "env_sound", keys, true );
    	EnvSound.Think();

		//g_EngineFuncs.ServerPrint( "-- DEBUG: Spawned env_sound from trigger_sound brush number: " + self.pev.model + " with targetname " + EnvSoundTName + " and origin: " + string(vOrigin.x) + " " + string(vOrigin.y) + " " + string(vOrigin.z) + " with roomtype: " + self.pev.health + " of radius: " + iRadius + "\n" );
	}

	void TriggerThink()
	{
		for( int playerID = 0; playerID <= g_Engine.maxClients; playerID++ )
		{
			CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );  
		
			if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
			{
				while( !playerInBox( pPlayer, self.pev.absmin, self.pev.absmax ) && _HAS_TRIGGERED[playerID] ){ _HAS_TRIGGERED[playerID] = false; }

				if( playerInBox( pPlayer, self.pev.absmin, self.pev.absmax ) )
				{
					if( !_HAS_TRIGGERED[playerID] )
					{
						g_EntityFuncs.FireTargets( "" + EnvSoundTName, self, self, USE_ON, 0.0f, 0.1f );
						_HAS_TRIGGERED[playerID] = true;
						//g_EngineFuncs.ServerPrint( "-- DEBUG: Activated trigger_sound: " + EnvSoundTName + " at origin: " + string(vOrigin.x) + " " + string(vOrigin.y) + " " + string(vOrigin.z) + " with roomtype: " + self.pev.health + " of radius: " + iRadius + " triggered by: " + pPlayer.pev.netname + "\n" );
					}
					//else
					//	g_EngineFuncs.ServerPrint( "-- DEBUG: Player: " + pPlayer.pev.netname + " cannot activate trigger_sound: " + EnvSoundTName + " again!\n" );
				}
			}
		}
		self.pev.nextthink = g_Engine.time + 1.0f;
	}

	bool playerInBox( CBasePlayer@ pPlayer, Vector vMin, Vector vMax )
	{
		if( pPlayer.pev.origin.x >= vMin.x && pPlayer.pev.origin.x <= vMax.x )
		{
			if( pPlayer.pev.origin.y >= vMin.y && pPlayer.pev.origin.y <= vMax.y )
			{
				if( pPlayer.pev.origin.z >= vMin.z && pPlayer.pev.origin.z <= vMax.z )
				{
					return true;
				}
			}
		}
		return false;
	}
}

void RegisterTriggerSoundEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_sound", "trigger_sound" );
}
