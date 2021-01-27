/* trigger_playerfreeze- Freezing entity from Opposing Force 
by Outerbeast

Made this for backwards compatibility reasons- freezing players can already
be achieved using changevalue + entity_iterator but this is much more convenient.

Install:
place in scripts/maps/opfor
Add the lines to your main mapscript:-

#include "trigger_playerfreeze" <-- this goes at the top

RegisterTriggerPlayerFreezeEntity(); <-- this goes inside "void MapInit()"

TO-DO:-
- Fix "Start On" flag not working
*/

enum fridgesetting
{
	DEFROST  = -1,
	NONE	 = 0,
	FREEZING = 1
};

enum freezespawnflags
{
	STARTON			= 1,
	RENDERINVIS		= 2
};

class trigger_playerfreeze : ScriptBaseEntity
{
	private int iFridgeSetting;
	private float flWaitTime;

	private array<EHandle> H_FRIDGE;

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if( szKey == "wait" ) 
		{
			flWaitTime = atof( szValue );
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

		SetThink( ThinkFunction( this.Refrigerator ) );
		
		if( self.pev.SpawnFlagBitSet( STARTON ) || self.GetTargetname() == "" )
		{
			iFridgeSetting = FREEZING;
			self.pev.nextthink = g_Engine.time + 0.1f;
			g_EngineFuncs.ServerPrint( "-- DEBUG: playefreeze is START ON\n");
		}
		else
		{
			self.pev.nextthink = 0.0f;
			g_EngineFuncs.ServerPrint( "-- DEBUG: playefreeze is START OFF\n");
		}
		g_EngineFuncs.ServerPrint( "-- DEBUG: playefreeze spawnflags is " + self.pev.spawnflags + "\n");
	}

	void Refrigerator()
	{
		g_EngineFuncs.ServerPrint( "-- DEBUG: playerfreeze is thinking...\n");
		PutEntsInFridge();

		if( H_FRIDGE.length() < 1 )
			return;
		
		for( uint i = 0; i < H_FRIDGE.length(); i++ )
		{
			if( !H_FRIDGE[i] )
				continue;

			switch( iFridgeSetting )
			{
				case FREEZING:
					Freezer( H_FRIDGE[i] );
					self.pev.nextthink = g_Engine.time + 0.1f;
					g_EngineFuncs.ServerPrint( "-- DEBUG: Freezing On\n");
					break;
				case DEFROST:
					Defroster( H_FRIDGE[i] );
					self.pev.nextthink = g_Engine.time + 0.1f;
					g_EngineFuncs.ServerPrint( "-- DEBUG: Defrosting On\n");
					break;
				default:
					self.pev.nextthink = g_Engine.time + 0.5f;
					break;
			}
		}
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
		PutEntsInFridge();

		if( H_FRIDGE.length() < 1 )
			return;

		if( iFridgeSetting == NONE )
		{
			iFridgeSetting = FREEZING;
			self.pev.nextthink = g_Engine.time + 0.1f;
		}
		else
			iFridgeSetting *= -1;

		if( flWaitTime > 0 && iFridgeSetting == FREEZING ) 
			g_Scheduler.SetTimeout( this, "ToggleEntity", flWaitTime );
	}

	void ToggleEntity()
	{
  		self.Use( self, self, USE_TOGGLE, 0.0f );
		g_EngineFuncs.ServerPrint( "-- DEBUG: playerfreeze " + self.GetTargetname() + " has been triggered and fridge setting is " + iFridgeSetting + "\n");
	}

	void PutEntsInFridge()
	{
		CBaseEntity@ pFreezeEntity;
        array<CBaseEntity@> P_OPENED_FRIDGE;

		if( self.pev.target != "" && self.pev.target != self.GetTargetname() )
		{
			while( ( @pFreezeEntity = g_EntityFuncs.FindEntityByTargetname( pFreezeEntity, "" + self.pev.target ) ) !is null )
			{
			    for( uint i = 0; i < H_FRIDGE.length(); i++ )
			        P_OPENED_FRIDGE.insertLast( H_FRIDGE[i].GetEntity() );

			    if( P_OPENED_FRIDGE.find( pFreezeEntity ) >= 0 )
					continue;

				H_FRIDGE.insertLast( pFreezeEntity );
			}
		}
		else // Default behaviour if "target" is undefined, cycle through players
		{
			for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
			{
				@pFreezeEntity = g_EntityFuncs.Instance( playerID );

				if( pFreezeEntity is null || !pFreezeEntity.IsPlayer() )
					continue;

				for( uint i = 0; i < H_FRIDGE.length(); i++ )
					P_OPENED_FRIDGE.insertLast( H_FRIDGE[i].GetEntity() );

				if( P_OPENED_FRIDGE.find( pFreezeEntity ) >= 0 )
					continue;

				H_FRIDGE.insertLast( pFreezeEntity );
			}
		}
	}

	void Freezer(EHandle hEntity)
	{
		if( !hEntity )
			return;

		CBaseEntity@ pEntity = hEntity.GetEntity();

		if( pEntity !is null && !pEntity.pev.FlagBitSet( FL_FROZEN ) )
			pEntity.pev.flags |= FL_FROZEN;

		if( self.pev.SpawnFlagBitSet( RENDERINVIS ) )
		{
			pEntity.pev.rendermode = kRenderTransTexture;
			pEntity.pev.renderamt = 0.0f;
		}
		iFridgeSetting = FREEZING;
	}

	void Defroster(EHandle hEntity)
	{
		if( !hEntity )
			return;

		CBaseEntity@ pEntity = hEntity.GetEntity();

		if( pEntity !is null && pEntity.pev.FlagBitSet( FL_FROZEN ) )
			pEntity.pev.flags &= ~FL_FROZEN;

		if( self.pev.SpawnFlagBitSet( RENDERINVIS ) && pEntity.pev.rendermode == kRenderTransTexture )
		{
			pEntity.pev.rendermode = kRenderNormal;
			pEntity.pev.renderamt = 255.0f;
		}
		iFridgeSetting = DEFROST;
	}
}

void RegisterTriggerPlayerFreezeEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_playerfreeze", "trigger_playerfreeze" );
}
