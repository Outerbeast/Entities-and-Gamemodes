/* trigger_player- Freezing entity from Opposing Force 
by Outerbeast

Made this for backwards compatibility reasons- freezing players can already
be achieved using changevalue + entity_iterator but this is much more convenient.

Install:
place in scripts/maps/opfor
Add the lines to your main mapscript:-

#include "trigger_playerfreeze" <-- this goes at the top

RegisterTriggerPlayerFreezeEntity(); <-- this goes inside "void MapInit()"

TO DO:-
- implement flags
- add support for !activator/!caller
*/

enum freezestate
{
	DEFROST  = -1,
	NONE	 = 0,
	FREEZING = 1
};

enum playerfreezespawnflags
{
	STARTON			= 1,
	RENDERINVIS		= 2,
	REMOVEONFIRE	        = 4,
	ACTIVATOR		= 8
};

class trigger_playerfreeze : ScriptBaseEntity
{
	private int iFreezeState = NONE;
	private float flWaitTime;

	private array<EHandle> H_FREEZE_ENTS;

	bool KeyValue( const string& in szKey, const string& in szValue )
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

		SetThink( ThinkFunction( this.FreezeThink ) );

		if( self.pev.SpawnFlagBitSet( STARTON ) || self.GetTargetname() == "" )
			ToggleEntity();
		else
			self.pev.nextthink = 0.0f;
	}

	void FreezeThink()
	{
		GetFreezeEnts( null );

		if( H_FREEZE_ENTS.length() < 1 )
			return;
		
		for( uint i = 0; i < H_FREEZE_ENTS.length(); i++ )
		{
			if( !H_FREEZE_ENTS[i] )
				continue;

			switch( iFreezeState )
			{
				case FREEZING:
					Freezer( H_FREEZE_ENTS[i] );
					self.pev.nextthink = g_Engine.time + 0.1f;
					//g_EngineFuncs.ServerPrint( "-- DEBUG: Freezing On\n");
					break;
				case DEFROST:
					Defroster( H_FREEZE_ENTS[i] );
					self.pev.nextthink = g_Engine.time + 0.1f;
					//g_EngineFuncs.ServerPrint( "-- DEBUG: Defrosting On\n");
					break;
				default:
					self.pev.nextthink = 0.0f;
					break;
			}
		}
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
		GetFreezeEnts( pActivator );

		if( H_FREEZE_ENTS.length() < 1 )
			return;

		if( iFreezeState == NONE )
		{
			iFreezeState = FREEZING;
			self.pev.nextthink = g_Engine.time + 0.1f;
		}
		else
			iFreezeState *= -1;

		if( flWaitTime > 0 && iFreezeState == FREEZING ) 
			g_Scheduler.SetTimeout( this, "ToggleEntity", flWaitTime );
	}

	void ToggleEntity()
	{
  		self.Use( self, self, USE_TOGGLE, 0.0f );
	}

	void GetFreezeEnts(CBaseEntity@ pActivator)
	{
		CBaseEntity@ pFreezeEntity;
                array<CBaseEntity@> P_FREEZE_ENTS;

		if( self.pev.SpawnFlagBitSet( ACTIVATOR ) )
		{
			if( pActivator !is null )
				@pFreezeEntity = pActivator;
			
			H_FREEZE_ENTS[pFreezeEntity.entindex()] = pFreezeEntity;
		}
		else if( self.pev.target != "" && self.pev.target != self.GetTargetname() )
		{
			while( ( @pFreezeEntity = g_EntityFuncs.FindEntityByTargetname( pFreezeEntity, "" + self.pev.target ) ) !is null )
			{
			        for( uint i = 0; i < H_FREEZE_ENTS.length(); i++ )
					P_FREEZE_ENTS.insertLast( H_FREEZE_ENTS[i].GetEntity() );

			        if( P_FREEZE_ENTS.find( pFreezeEntity ) >= 0 )
					continue;

				H_FREEZE_ENTS.insertLast( pFreezeEntity );
			}
		}
		else
		{
			for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
			{
				@pFreezeEntity = g_EntityFuncs.Instance( playerID );

				if( pFreezeEntity is null || !pFreezeEntity.IsPlayer() )
					continue;

				for( uint i = 0; i < H_FREEZE_ENTS.length(); i++ )
					P_FREEZE_ENTS.insertLast( H_FREEZE_ENTS[i].GetEntity() );

				if( P_FREEZE_ENTS.find( pFreezeEntity ) >= 0 )
					continue;

				H_FREEZE_ENTS.insertLast( pFreezeEntity );
			}
		}
	}

	void Freezer(EHandle hEntity)
	{
		if( !hEntity )
			return;

		CBaseEntity@ pEntity = hEntity.GetEntity();

		if( pEntity !is null && !pEntity.pev.FlagBitSet( FL_FROZEN ))
			pEntity.pev.flags |= FL_FROZEN;

		if( self.pev.SpawnFlagBitSet( RENDERINVIS ) )
		{
			pEntity.pev.rendermode = kRenderTransTexture;
			pEntity.pev.renderamt = 0.0f;
		}

		iFreezeState = FREEZING;
	}

	void Defroster(EHandle hEntity)
	{
		if( !hEntity )
			return;

		CBaseEntity@ pEntity = hEntity.GetEntity();

		if( pEntity !is null )
			pEntity.pev.flags &= ~FL_FROZEN;

		if( self.pev.SpawnFlagBitSet( RENDERINVIS ) && pEntity.pev.rendermode == kRenderTransTexture )
		{
			pEntity.pev.rendermode = kRenderNormal;
			pEntity.pev.renderamt = 255.0f;
		}

		iFreezeState = DEFROST;
	}
}

void RegisterTriggerPlayerFreezeEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_playerfreeze", "trigger_playerfreeze" );
}
