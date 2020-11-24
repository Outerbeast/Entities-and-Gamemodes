/* trigger_player- Freezing entity from Opposing Force 
by Outerbeast

Made this for backwards compatibility reasons- freezing players can already
be achieved using changevalue + entity_iterator but this is much more convenient.

Install:
place in scripts/maps/opfor
Add the lines to your main mapscript:-

#include "opfor/trigger_playerfreeze" <-- this goes at the top

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
	uint iRenderInvisible, iStartOn, iRemoveOnFire;
	float flWaitTime;

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

		if(StartOn == 1){ m_fTriggered = true; }
	}

	void TriggerThink()
	{
		if( blTriggered || blActivated )
		{
			for( int playerID = 0; playerID <= g_Engine.maxClients; playerID++ )
			{
				CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );

				if( pPlayer !is null )
				{
					if( TargetPlayer != "" && TargetPlayer == pPlayer.GetTargetname() )
					{
					    pPlayer.pev.flags |= FL_FROZEN;
						//g_EngineFuncs.ServerPrint( "-- DEBUG: Players with targetname " + TargetPlayer + " Frozen!\n");

						if( RenderInvisible == 1 && pPlayer.pev.rendermode != kRenderTransTexture )
						{
							pPlayer.pev.rendermode = kRenderTransTexture;
							//g_EngineFuncs.ServerPrint( "-- DEBUG: Players with targetname " + TargetPlayer + " Invisible!\n");
						}
					}					
					else
					{
                				pPlayer.pev.flags |= FL_FROZEN;
						//g_EngineFuncs.ServerPrint("-- DEBUG: All Players Frozen!\n");

						if( iRenderInvisible == 1 && pPlayer.pev.rendermode != kRenderTransTexture)
						{
							pPlayer.pev.rendermode = kRenderTransTexture;
							//g_EngineFuncs.ServerPrint( "-- DEBUG: All Players made Invisible!\n");
						}
					}
					blActivated = true;
				}
			}
		}
		if( blActivated ){ self.pev.nextthink = g_Engine.time + 0.1f; }
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		blActivated = true;
		if( flWaitTime != 0.0f )
		{
		g_EntityFuncs.FireTargets( "" + self.GetTargetname(), null, null, USECBasePflWaitTime )
		}

		//g_EngineFuncs.ServerPrint("-- DEBUG: trigger_playerfreeze status- triggered: " + m_fTriggered + " and activated: " + m_fActivated + "\n");
		
		if( blTriggered && blActivated )
		{
			for( int playerID = 0; playerID <= g_Engine.maxClients; playerID++ )
			{
				CBaseEntity@ ePlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer );

				if( pPlayer !is null )
				{
                	pPlayer.pev.flags &= ~FL_FROZEN;
					//g_EngineFuncs.ServerPrint("-- DEBUG: Player Unfrozen!\n");

					if( pPlayer.pev.rendermode != kRenderNormal )
					{
						pPlayer.pev.rendermode = kRenderNormal;
						//g_EngineFuncs.ServerPrint("-- DEBUG: Player now visible!\n");
					}

					m_fActivated = false;
					m_fTriggered = false;
				}
			}
			if( iRemoveOnFire == 1 ){ g_EntityFuncs.Remove( self ); }
		}
		else
			self.pev.nextthink = g_Engine.time + 0.1f;
	}
		
}

void RegisterTriggerPlayerFreezeEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_playerfreeze", "trigger_playerfreeze" );
}
