/* trigger_playerfreeze- Freezing entity from Opposing Force
	by Outerbeast

	Made this for backwards compatibility reasons- freezing players can already
	be achieved using trigger_camera "Freeze players" flag, or changevalue + entity_iterator but this is much more convenient.

	Installation:-
	- Place in scripts/maps
	- Add
	map_script trigger_playerfreeze
	to your map cfg
	OR
	- Add
	#include "trigger_playerfreeze"
	to your main map script header
	OR
	- Create a trigger_script with these keys set in your map:
	"classname" "trigger_script"
	"m_iszScriptFile" "trigger_playerfreeze"

	Usage:-
	Simply trigger the entity to start freezing players. The entity will continue to freeze players while its active.
	To unfreeze, trigger it again, or killtarget the entity.
	You can use "target" key followed by the targetname of your player to specifically freeze them and nobody else.
	After the entity triggers it will target entities matching its "message" value.

	Flags:
	1: "Start On" - the entity will be active when the level starts. This is automatically the case if the entity has no targetname
	2: "Invisible" - while the players are frozen, they will also be invisible.
	4: "Invert target" - instead of freezing the target, everyone else but the target will be frozen.
*/
enum freezespawnflags
{
	SF_STARTON			= 1 << 0,
	SF_RENDERINVIS		= 1 << 1,
	SF_INVERT_TARGET	= 1 << 2
};

bool blTriggerPlayerFreezeRegistered = RegisterTriggerPlayerFreezeEntity();

bool RegisterTriggerPlayerFreezeEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_playerfreeze", "trigger_playerfreeze" );
	return g_CustomEntityFuncs.IsCustomEntity( "trigger_playerfreeze" );
}

final class trigger_playerfreeze : ScriptBaseEntity
{
	private EHandle hActivator;
	private bool blShouldFreeze;
	private float flWaitTime;

	private CScheduledFunction@ fnWaitToggle;

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if( szKey == "wait" ) 
			flWaitTime = atof( szValue );
		else
			return BaseClass.KeyValue( szKey, szValue );

		return true;
	}
	
	void Spawn()
	{
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		self.pev.effects	|= EF_NODRAW;
		
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

		if( self.pev.SpawnFlagBitSet( SF_STARTON ) || self.GetTargetname() == "" )
			self.Use( self, self, USE_ON, 0.0f );
	}

	void ToggleEntity()
	{
  		self.Use( self, self, USE_TOGGLE, 0.0f );
	}

	bool FCanFreezeTarget(EHandle hFreezeTarget)
	{
		if( !hFreezeTarget )
			return false;

		if( self.pev.target == "" )
			return true;

		if( self.pev.target == "!activator" && hActivator )
		{
			return( self.pev.SpawnFlagBitSet( SF_INVERT_TARGET ) ? 
					hFreezeTarget.GetEntity() !is hFreezeTarget.GetEntity() : 
					hFreezeTarget.GetEntity() is hFreezeTarget.GetEntity() );
		}

		return( self.pev.SpawnFlagBitSet( SF_INVERT_TARGET ) ? 
				self.pev.target != hFreezeTarget.GetEntity().GetTargetname() : 
				self.pev.target == hFreezeTarget.GetEntity().GetTargetname() );
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value)
	{
		switch( useType )
		{
			case USE_ON:
			{
				blShouldFreeze = g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( this.Freezer ) );
				g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, ClientPutInServerHook( this.Freezer ) );
				g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( this.Defroster ) );
				hActivator = pActivator;

				break;
			}

			case USE_OFF:
			{
				blShouldFreeze = false;
				g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( this.Freezer ) );
				g_Hooks.RemoveHook( Hooks::Player::ClientPutInServer, ClientPutInServerHook( this.Freezer ) );
				g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( this.Defroster ) );
				hActivator = EHandle();

				break;
			}
			
			case USE_TOGGLE:
				self.Use( null, null, blShouldFreeze ? USE_OFF : USE_ON, 0 );
				break;
		}

		if( flWaitTime > 0 && blShouldFreeze ) 
			@fnWaitToggle = g_Scheduler.SetTimeout( @self, "Use", flWaitTime, cast<CBaseEntity@>( null ), cast<CBaseEntity@>( null ), USE_TYPE( USE_TOGGLE ), 0.0f );

		if( self.pev.message != "" && self.pev.message != self.GetTargetname() && blShouldFreeze )
			g_EntityFuncs.FireTargets( self.pev.message, hActivator.GetEntity(), self, USE_TOGGLE );
	}

	private HookReturnCode Freezer(CBasePlayer@ pPlayer)
	{
		if( pPlayer is null || !pPlayer.IsConnected() || !blShouldFreeze || !FCanFreezeTarget( pPlayer ) )
			return HOOK_CONTINUE;

		pPlayer.EnableControl( false );

		if( self.pev.SpawnFlagBitSet( SF_RENDERINVIS ) && pPlayer.pev.effects & EF_NODRAW == 0 )
			pPlayer.pev.effects |= EF_NODRAW;

		return HOOK_CONTINUE;
	}

	private HookReturnCode Defroster(CBasePlayer@ pPlayer)
	{
		if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.pev.FlagBitSet( FL_FROZEN ) || blShouldFreeze )
			return HOOK_CONTINUE;

		pPlayer.EnableControl( true );

		if( self.pev.SpawnFlagBitSet( SF_RENDERINVIS ) && pPlayer.pev.effects & EF_NODRAW != 0 )
			pPlayer.pev.effects &= ~EF_NODRAW;

		return HOOK_CONTINUE;
	}

	void UpdateOnRemove()
	{
		blShouldFreeze = false;

		g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( this.Freezer ) );
		g_Hooks.RemoveHook( Hooks::Player::ClientPutInServer, ClientPutInServerHook( this.Freezer ) );

		for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); iPlayer++ )
			Defroster( g_PlayerFuncs.FindPlayerByIndex( iPlayer ) );

		g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( this.Defroster ) );

		if( fnWaitToggle !is null )
			g_Scheduler.RemoveTimer( fnWaitToggle );

		BaseClass.UpdateOnRemove();
	}
}
