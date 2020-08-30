/* Custom brush entity for counting players within a zone. 
- Outerbeast*/

class player_count_zone : ScriptBaseEntity 
{
	uint ResetCount = 1;
	string FilterPlayer = "";

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "filterplayer" )
		{
			FilterPlayer = szValue;
			return true;
		}
		else if( szKey == "resetcount" )
		{
			ResetCount = atoi( szValue );
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
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetModel(self, self.pev.model);
		g_EntityFuncs.SetSize(self.pev, self.pev.mins, self.pev.maxs);
		self.pev.effects |= EF_NODRAW;
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if( ResetCount == 1 ){ self.pev.frags = 0 }

		for(int playerID = 0; playerID <= g_Engine.maxClients; playerID++ )
		{
			CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );

			if( pPlayer !is null )
			{
				if( playerInBox( pPlayer, self.pev.absmin, self.pev.absmax ) )
				{	
					if( FilterPlayer != "" && FilterPlayer == pPlayer.GetTargetname() && pPlayer.IsAlive() )
					{
						self.pev.frags++;
						g_EngineFuncs.ServerPrint( "-- DEBUG: Count of players of targetname " + FilterPlayer + " : " + self.pev.frags + " inside zone: " + self.pev.targetname + "\n");
					}
				}
			}
		}
		self.pev.nextthink = g_Engine.time + 0.1f;
	}

// Credit to CubeMath for the bounding box logic used here //
	bool playerInBox( CBasePlayer@ pPlayer, Vector vMin, Vector vMax )
	{
		if ( pPlayer.pev.origin.x >= vMin.x && pPlayer.pev.origin.x <= vMax.x )
		{
			if ( pPlayer.pev.origin.y >= vMin.y && pPlayer.pev.origin.y <= vMax.y )
			{
				if ( pPlayer.pev.origin.z >= vMin.z && pPlayer.pev.origin.z <= vMax.z )
				{
					return true;
				}
			}
		}
		return false;
	}
}

void RegisterPlayerCountZoneEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "player_count_zone", "player_count_zone" );
}
