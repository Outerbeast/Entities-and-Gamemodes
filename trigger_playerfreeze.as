/* trigger_player- Freezing entity from Opposing Force 
by Outerbeast

Made this for backwards compatibility reasons- freezing players can already
be achieved using changevalue + entity_iterator but this is much more convenient.

Install:
place in scripts/maps/opfor
Add the lines to your main mapscript:-

#include "trigger_playerfreeze" <-- this goes at the top

RegisterTriggerPlayerFreezeEntity(); <-- this goes inside "void MapInit()"

Usage:
Simply trigger it to freeze and trigger again to unfreeze already frozen players.
"targetplayer" lets players of a targetname only be frozen- all players will be frozen if not set.
"wait" makes the freezing automatically reset after the set time
"renderinvisible" key causes players to be invisible if set to 1.
"starton" allows the entity to be active on map start if set to 1.
Entity can be set to delete itself using the "removeonfire" key if set to 1.
*/

class trigger_playerfreeze : ScriptBaseEntity
{
	private bool blTriggered, blActivated;
	private string strTargetPlayer;
	private uint iRenderInvisible, iStartOn, iRemoveOnFire;
	private float flWaitTime;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "targetplayer" ) 
		{
			strTargetPlayer = szValue;
			return true;
		}
		else if( szKey == "wait" ) 
		{
			flWaitTime = atof( szValue );
			return true;
		}
		else if( szKey == "renderinvisible" ) 
		{
			iRenderInvisible = atoi( szValue );
			return true;
		}
		else if( szKey == "starton" )
		{
			iStartOn = atoi( szValue );
			return true;
		}
		else if( szKey == "removeonfire" ) 
		{
			iRemoveOnFire = atoi( szValue );
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

		SetThink( ThinkFunction( this.TriggerThink ) );
        self.pev.nextthink = g_Engine.time + 5.0f;

		if( iStartOn == 1 ){ blTriggered = true; }
	}

	void TriggerThink()
	{
		g_EngineFuncs.ServerPrint("-- DEBUG: trigger_playerfreeze: " + self.GetTargetname() + " is thinking...\n");
		if( blTriggered || blActivated ){ Freezer(); }
		if( blActivated ){ self.pev.nextthink = g_Engine.time + 0.1f; }
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		blTriggered = true;
		if( blTriggered && blActivated ){ Thawer(); }
		else
			self.pev.nextthink = g_Engine.time + 0.1f;

		if( flWaitTime != 0.0f )
		{
		    g_Scheduler.SetTimeout( this, "Use", flWaitTime, null, null, USE_TOGGLE, 0.0f );
			g_EngineFuncs.ServerPrint("-- DEBUG: trigger_playerfreeze: " + self.GetTargetname() + " timeout in " + flWaitTime + "seconds.\n");
		}

		if( iRemoveOnFire == 1 ){ g_EntityFuncs.Remove( self ); }
		g_EngineFuncs.ServerPrint("-- DEBUG: trigger_playerfreeze status- triggered: " + blTriggered + " and activated: " + blActivated + "\n");
	}

    void Freezer()
    {
		for( int playerID = 0; playerID <= g_Engine.maxClients; playerID++ )
		{
			CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );

			if( pPlayer !is null && !pPlayer.pev.FlagBitSet( FL_FROZEN ) )
			{
				if( strTargetPlayer != "" && strTargetPlayer == pPlayer.GetTargetname() )
				{
					pPlayer.pev.flags |= FL_FROZEN;
					g_EngineFuncs.ServerPrint( "-- DEBUG: Players with targetname " + strTargetPlayer + " Frozen!\n");

					if( iRenderInvisible == 1 && pPlayer.pev.rendermode != kRenderTransTexture )
					{
						pPlayer.pev.rendermode = kRenderTransTexture;
						g_EngineFuncs.ServerPrint( "-- DEBUG: Players with targetname " + strTargetPlayer + " Invisible!\n");
					}
				}					
				else
				{
					pPlayer.pev.flags |= FL_FROZEN;
					g_EngineFuncs.ServerPrint("-- DEBUG: All Players Frozen!\n");

					if( iRenderInvisible == 1 && pPlayer.pev.rendermode != kRenderTransTexture )
					{
						pPlayer.pev.rendermode = kRenderTransTexture;
						g_EngineFuncs.ServerPrint( "-- DEBUG: All Players made Invisible!\n");
					}
				}

				blActivated = true;
			}
		}
    }

	void Thawer()
	{
		for( int playerID = 0; playerID <= g_Engine.maxClients; playerID++ )
		{
			CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );

			if( pPlayer !is null && pPlayer.pev.FlagBitSet( FL_FROZEN ) )
			{
				pPlayer.pev.flags &= ~FL_FROZEN;
				g_EngineFuncs.ServerPrint("-- DEBUG: Player Unfrozen!\n");

				if( pPlayer.pev.rendermode != kRenderNormal )
				{
					pPlayer.pev.rendermode = kRenderNormal;
					g_EngineFuncs.ServerPrint("-- DEBUG: Player now visible!\n");
				}

				blActivated = false;
				blTriggered = false;
			}
		}
	}

}

void RegisterTriggerPlayerFreezeEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_playerfreeze", "trigger_playerfreeze" );
}
