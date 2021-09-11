/* env_dlight/elight custom entities 
Attempted port of the SoHL implementation for compatibility in Sven Co-op
- Outerbeast */
enum light_spawnflags
{
	SF_LIGHT_TOGGLE = 1 << 0,
	SF_LIGHT_STARTON = 1 << 1
};

void RegisterEnvLightEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "env_dlight", "env_dlight" );
	g_CustomEntityFuncs.RegisterCustomEntity( "env_elight", "env_elight" );
}

class env_dlight : ScriptBaseEntity
{
    void Spawn()
    {
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;

		if( self.pev.health == 0.0f )
    		self.pev.health = 255.0f;
		// Spread out the thinking to make flickering easier on the eyes.
        if( ( self.pev.spawnflags & SF_LIGHT_STARTON ) > 0 )
			self.pev.nextthink = g_Engine.time + Math.RandomFloat( 0.0f, 1.0f );
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
		if( ( self.pev.spawnflags & SF_LIGHT_TOGGLE ) > 0 )
		{
			// We're toggled so determine what to do based on the use type.
			switch( useType )
			{
				case USE_OFF:
					self.pev.nextthink = 0.0f;
					break;

				case USE_ON:
					self.pev.nextthink = g_Engine.time;
					break;
					
				case USE_TOGGLE:
					if( self.pev.nextthink > 0.0f )
						self.pev.nextthink = 0.0f;
					else
						self.pev.nextthink = g_Engine.time;
			}
		}
		else
			self.pev.nextthink = g_Engine.time; // If we don't toggle, just kickstart the thinking to run it once.
    }

    void Think()
    {
		NetworkMessage dlight( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
			dlight.WriteByte( TE_DLIGHT );

			dlight.WriteCoord( self.pev.origin.x );
			dlight.WriteCoord( self.pev.origin.y );
			dlight.WriteCoord( self.pev.origin.z );

			dlight.WriteByte( uint8( self.pev.renderamt ) );

			dlight.WriteByte( uint8( self.pev.rendercolor.x ) );
			dlight.WriteByte( uint8( self.pev.rendercolor.y ) );
			dlight.WriteByte( uint8( self.pev.rendercolor.z ) );

			dlight.WriteByte( uint8( self.pev.health ) );
			dlight.WriteByte( uint8( self.pev.frags ) );
        dlight.End();
		// When toggled, think with a 0.1 second delay.
		// Experiment with different timings and life/decay rate for better results.
		if( ( self.pev.spawnflags & SF_LIGHT_TOGGLE ) > 0 )
			self.pev.nextthink = g_Engine.time + ( self.pev.health / 10 );
    }
}

class env_elight : ScriptBaseEntity
{
	private EHandle hTarget;

    void Spawn()
    {
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;

		if( self.pev.health == 0.0f )
    		self.pev.health = 255.0f;
		// Spread out the thinking to make flickering easier on the eyes.
        if( ( self.pev.spawnflags & SF_LIGHT_STARTON ) > 0 )
			self.pev.nextthink = g_Engine.time + Math.RandomFloat( 0.0f, 1.0f );

		if( self.pev.target != "" || self.pev.target != self.GetTargetname() )
			hTarget = EHandle( g_EntityFuncs.FindEntityByTargetname( null, "" + self.pev.target ) );
		else
			hTarget = EHandle( g_EntityFuncs.FindEntityInSphere( self, self.GetOrigin(), self.pev.renderamt, "", "" ) );
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
		if( ( self.pev.spawnflags & SF_LIGHT_TOGGLE ) > 0 )
		{
			// We're toggled so determine what to do based on the use type.
			switch( useType )
			{
				case USE_OFF:
					self.pev.nextthink = 0.0f;
					break;

				case USE_ON:
					self.pev.nextthink = g_Engine.time;
					break;

				case USE_TOGGLE:
					if( self.pev.nextthink > 0.0f )
						self.pev.nextthink = 0.0f;
					else
						self.pev.nextthink = g_Engine.time;
			}
		}
		else
			self.pev.nextthink = g_Engine.time; // If we don't toggle, just kickstart the thinking to run it once.
    }

    void Think()
    {
		if( !hTarget )
			return;

		CBaseEntity@ pTarget = hTarget.GetEntity();

		NetworkMessage elight( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
			elight.WriteByte( TE_ELIGHT );

			elight.WriteShort( pTarget.entindex() );

			elight.WriteCoord( pTarget.pev.origin.x );
			elight.WriteCoord( pTarget.pev.origin.y );
			elight.WriteCoord( pTarget.pev.origin.z );

			elight.WriteByte( uint8( self.pev.renderamt ) );

			elight.WriteByte( uint8( self.pev.rendercolor.x ) );
			elight.WriteByte( uint8( self.pev.rendercolor.y ) );
			elight.WriteByte( uint8( self.pev.rendercolor.z ) );

			elight.WriteByte( uint8( self.pev.health ) );
			elight.WriteByte( uint8( self.pev.frags ) );
        elight.End();
		// When toggled, think with a 0.1 second delay.
		// Experiment with different timings and life/decay rate for better results.
		if( ( self.pev.spawnflags & SF_LIGHT_TOGGLE ) > 0 )
			self.pev.nextthink = g_Engine.time + ( self.pev.health / 10 );
    }
}
/* Special thanks to H2 for scripting help and fixes */