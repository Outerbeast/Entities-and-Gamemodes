/*
* player_hurt_zone
* Point Entity
* Custom trigger_hurt zone with variable hullsize
*/

class player_hurt_zone : ScriptBaseEntity
{
	int DamageType = 0;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "minhullsize" )
		{
			g_Utility.StringToVector( self.pev.vuser1, szValue );
			return true;
		}
		else if( szKey == "maxhullsize" )
		{
			g_Utility.StringToVector( self.pev.vuser2, szValue );
			return true;
		}
		else if( szKey == "damagetype" ) 
		{
			DamageType = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		g_EntityFuncs.SetSize( self.pev, self.pev.vuser1, self.pev.vuser2 );
		SetThink( ThinkFunction( this.TriggerThink ) );
        self.pev.nextthink = g_Engine.time + 5.0f;

		if( self.pev.dmg == 0){ self.pev.dmg = 10; }
		if(	DamageType == 32){ DamageType = 0; }
	}
	
	void TriggerThink()
	{
		for(int playerID = 0; playerID <= g_Engine.maxClients; playerID++ )
		{
			CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );

			if( pPlayer !is null )
			{
				if( playerInBox( pPlayer, self.pev.absmin, self.pev.absmax ) )
				{	
					pPlayer.pev.flags &= ~( FL_GODMODE );
					pPlayer.TakeDamage( null, null, self.pev.dmg, DamageType );
				}
			}
		}
		self.pev.nextthink = g_Engine.time + 0.1f;
	}

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

void RegisterPlayerHurtZoneEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "player_hurt_zone", "player_hurt_zone" );
}
