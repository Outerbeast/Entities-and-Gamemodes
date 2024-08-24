/*  player_collision - Custom entity that removes player-player collision when touching the entity

    Installation:-
	- Place in scripts/maps
	- Add
	map_script player_collision
	to your map cfg
	OR
	- Add
	#include "player_collision"
	to your main map script header
	OR
	- Create a trigger_script with these keys set in your map:
	"classname" "trigger_script"
	"m_iszScriptFile" "player_collision"

    Usage:-
    These entities allow you to to enclose an area where player-player collision needs to be disabled.
    You can use the brush entity func_player_collision, or the point entity env_player_collision (this requires custom set bounds)
    Keys (env_player_collision only):
    "zonecornermin" "x1 y1 z1" - Position of zone bounding box minimum
    "zonecornermax" "x2 y2 z2" - Position of zone bounding box maximum
    "zoneradius" "r" - if you don't use the zonecorner keys, you can make a radius zone

    This script also automatically disables player-player collisions whenever players are in crawl spaces.
    If you don't want this behaviour, execute "g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, CrawlSpaceCollision )" in MapInit or later.
- Outerbeast
*/
enum playercollisionflags
{
    SF_STARTOFF         = 1 << 0,
    SF_CHANGE_SOLIDITY  = 1 << 1
};

array<CPlayerCollision> PLRC_INSTANCES;

bool 
    blPlayerCollisionRegister = PlayerCollisionRegister(),
    blCrawlSpaceCollision = g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, CrawlSpaceCollision );

bool PlayerCollisionRegister()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "CPlayerCollision", "func_player_collision" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CPlayerCollision", "env_player_collision" );

    return g_CustomEntityFuncs.IsCustomEntity( "func_player_collision" ) && g_CustomEntityFuncs.IsCustomEntity( "env_player_collision" );
}
// Automatic collision removal in tight spaces like vents
HookReturnCode CrawlSpaceCollision(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer is null || !pPlayer.IsAlive() || !blCrawlSpaceCollision )
        return HOOK_CONTINUE;

    if( pPlayer.pev.FlagBitSet( FL_DUCKING ) )
    {   // Check if the player is in a vent or something and can't uncrouch
        TraceResult trUp;
        g_Utility.TraceLine( pPlayer.pev.origin, pPlayer.pev.origin + Vector( 0, 0, 37 ), ignore_monsters, pPlayer.edict(), trUp );

        if( ( trUp.vecEndPos.z - pPlayer.pev.origin.z ) < 37 && pPlayer.pev.iuser4 == 0 )
            pPlayer.pev.iuser4 = 1;// disable player collision in the "vent" or whereever
    }
    else if( pPlayer.pev.iuser4 == 1 )
    {   // Let the entity(s) take over
        for( uint i = 0; i < PLRC_INSTANCES.length(); i++ )
        {   
            if( PLRC_INSTANCES[i].PlayerInEntity( pPlayer ) )
                continue;

            pPlayer.pev.iuser4 = 0;
        }
    }

    return HOOK_CONTINUE;
}

final class CPlayerCollision : ScriptBaseEntity
{    
    private Vector vecZoneCornerMin, vecZoneCornerMax;
    private float flZoneRadius = 128.0f;
    private bool blRemoveCollision, blUseRadius;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "zonecornermin" )
            g_Utility.StringToVector( vecZoneCornerMin, szValue );
        else if( szKey == "zonecornermax" )
            g_Utility.StringToVector( vecZoneCornerMax, szValue );
        else if( szKey == "zoneradius" )
            flZoneRadius = atof( szValue );
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Spawn()
    {
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.GetClassname() == "func_player_collision" && self.IsBSPModel() )
        {
            g_EntityFuncs.SetModel( self, self.pev.model );
            self.pev.solid = SOLID_TRIGGER;
        }
        else
        {
            self.pev.mins = vecZoneCornerMin - self.pev.origin;
            self.pev.maxs = vecZoneCornerMax - self.pev.origin;
        }

        if( self.pev.mins != g_vecZero && 
            self.pev.maxs != g_vecZero && 
            self.pev.mins != self.pev.maxs )
        {
            g_EntityFuncs.SetSize( self.pev, self.pev.mins, self.pev.maxs );
        }
        else
        {
            blUseRadius = true;

            if( flZoneRadius <= 0.0f )
                flZoneRadius = 128.0f;
        }

        if( self.pev.SpawnFlagBitSet( SF_STARTOFF ) && self.GetTargetname() != "" ) { }
        else
            self.Use( self, self, USE_ON, 0.0f );

        PLRC_INSTANCES.insertLast( cast<CPlayerCollision@>( CastToScriptClass( self ) ) );

        BaseClass.Spawn();
    }

    bool PlayerInEntity(EHandle hPlayer)
    {
        if( !hPlayer )
            return false;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( blUseRadius )
            return( ( self.pev.origin - pPlayer.pev.origin ).Length() <= flZoneRadius );
        else
            return self.GetClassname() == "func_player_collision" ? g_Utility.IsPlayerInVolume( pPlayer, self ) : pPlayer.Intersects( self );
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        switch( useType )
        {
            case USE_ON:
            {
                blRemoveCollision = g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, PlayerPreThinkHook( this.ModifyCollision ) );
                break;
            }

            case USE_OFF:
            {
                g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, PlayerPreThinkHook( this.ModifyCollision ) );
                blRemoveCollision = false;
                break;
            }

            case USE_TOGGLE:
            {
                self.Use( null, null, blRemoveCollision ? USE_OFF : USE_ON, 0 );
                break;
            }
        }
    }

    HookReturnCode ModifyCollision(CBasePlayer@ pPlayer, uint& out uiFlags)
    {
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            return HOOK_CONTINUE;

        if( self.pev.netname != "" && pPlayer.GetTargetname() == self.pev.netname )
            return HOOK_CONTINUE;

        if( ( blRemoveCollision && pPlayer.pev.iuser4 > 0 ) || ( !blRemoveCollision && pPlayer.pev.iuser4 < 1 ) )
            return HOOK_CONTINUE;

        pPlayer.pev.iuser4 = PlayerInEntity( pPlayer ) ? 1 : 0;

        return HOOK_CONTINUE;
    }

    void UpdateOnRemove()
    {
        blRemoveCollision = false;
        g_Hooks.RemoveHook( Hooks::Player::PlayerPreThink, PlayerPreThinkHook( this.ModifyCollision ) );
        PLRC_INSTANCES.removeAt( PLRC_INSTANCES.findByRef( this ) );

        for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
        {
            if( g_PlayerFuncs.FindPlayerByIndex( iPlayer ) !is null )
                g_PlayerFuncs.FindPlayerByIndex( iPlayer ).pev.iuser4 = 0;
        }

        BaseClass.UpdateOnRemove();
    }
};
