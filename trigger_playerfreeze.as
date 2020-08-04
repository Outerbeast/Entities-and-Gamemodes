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
	private bool m_fTriggered	= false;
	private bool m_fActivated	= false;
	private string TargetPlayer	= "";

	uint RenderInvisible		= 0;
	uint StartOn			= 0;
	uint szRemoveOnFire		= 0;
	float waitTime 			= 0.0f;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "targetplayer" ) 
		{
			TargetPlayer = szValue;
			return true;
		}
		else if( szKey == "wait" ) 
		{
			waitTime = atof( szValue );
			return true;
		}
		else if( szKey == "renderinvisible" ) 
		{
			RenderInvisible = atoi( szValue );
			return true;
		}
		else if( szKey == "starton" )
		{
			StartOn = atoi( szValue );
			return true;
		}
		else if( szKey == "removeonfire" ) 
		{
			szRemoveOnFire = atoi( szValue );
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
		if( m_fTriggered || m_fActivated )
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

						if( RenderInvisible == 1 && pPlayer.pev.rendermode != kRenderTransTexture)
						{
							pPlayer.pev.rendermode = kRenderTransTexture;
							//g_EngineFuncs.ServerPrint( "-- DEBUG: All Players made Invisible!\n");
						}
					}
					m_fActivated = true;
				}
			}
		}
		if( m_fActivated ){ self.pev.nextthink = g_Engine.time + 0.1f; }
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		m_fTriggered = true;
		if( waitTime != 0.0f )
		{
			Wait();
		}

		//g_EngineFuncs.ServerPrint("-- DEBUG: trigger_playerfreeze status- triggered: " + m_fTriggered + " and activated: " + m_fActivated + "\n");
		
		if( m_fTriggered && m_fActivated )
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
			if( szRemoveOnFire == 1 ){ g_EntityFuncs.Remove( self ); }
		}
		else
			self.pev.nextthink = g_Engine.time + 0.1f;
	}

 	void Wait()
	{
		dictionary keys;
        	keys ["target"]			= ( "" + self.pev.targetname );
		keys ["targetname"] 	= ( "" + self.pev.targetname + "_playerfreeze_wait_rly" );
		keys ["delay"] 			= ( "" + waitTime );
		keys ["triggerstate"] 	= ( "2" );
		keys ["spawnflags"] 	= ( "65" );

		CBaseEntity@ WaitRelay = g_EntityFuncs.CreateEntity( "trigger_relay", keys, true );
    		WaitRelay.Think();
		//g_EngineFuncs.ServerPrint( "-- DEBUG: Created WaitRelay " + self.pev.targetname + "_playerfreeze_wait_rly with wait time " + waitTime + "\n");
		g_EntityFuncs.FireTargets( "" + self.pev.targetname + "_playerfreeze_wait_rly", WaitRelay, WaitRelay, USE_ON, 0.0f );
		//g_EngineFuncs.ServerPrint( "-- DEBUG: WaitRelay " + self.pev.targetname + "_playerfreeze_wait with wait time " + waitTime + "triggered. \n");
		waitTime = 0.0f;
	}
}

void RegisterTriggerPlayerFreezeEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_playerfreeze", "trigger_playerfreeze" );
}
