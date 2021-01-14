/* env_healthbar
Custom entity to draw a health bar above a target entity
by Outerbeast

Note: Script is functional but prone to breaking.
Keys:
* "target"          - target entity to show a healthbar for. Can be a player, npc or breakable item ( with hud info enabled )
* "offset" "x y z"  - adds an offset from the health bar origin
* "scale" "0.0"     - resize the health bar, this is 0.3 by default
* "distance" "0.0"  - the distance you have to be to be able to see the health bar
* "spawnflags" "1"  - forces the healthbar to stay on for the entity

TO DO:
- Render the healthbars individually for each player
- Add triggering funcs
- Add support for custom sprites
*/

// For testing convenience, will be removed in the final version of course
void MapInit()
{
    HEALTHBAR::RegisterHealthBarEntity();
}

void MapStart()
{
    HEALTHBAR::StartHealthBarMode( (HEALTHBAR::PLAYERS | HEALTHBAR::MONSTERS | HEALTHBAR::BREAKABLES), Vector( 0, 0, 23 ), 0.6f, 0.0f, 0 );
}

namespace HEALTHBAR
{

array<string> STR_HEALTHBAR_FRAMES = { "h0", "h10", "h20", "h30", "h40", "h50", "h60", "h70", "h80", "h90", "h100" };

enum healthbarsettings
{
    PLAYERS     = 1,
    MONSTERS    = 2,
    BREAKABLES  = 4
};

string strSpriteDir = "sprites/misc/";

bool blHealthBarEntityRegistered = false;

void RegisterHealthBarEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "HEALTHBAR::env_healthbar", "env_healthbar" );
    blHealthBarEntityRegistered = true;
    
    for( uint p = 0; p < STR_HEALTHBAR_FRAMES.length(); ++p )
    {
        g_Game.PrecacheModel( strSpriteDir + STR_HEALTHBAR_FRAMES[p] + ".spr" );
        g_Game.PrecacheGeneric( strSpriteDir + STR_HEALTHBAR_FRAMES[p] + ".spr" );
    }
}

void StartHealthBarMode(const uint iHealthBarSettings, const Vector vOriginOffset, const float flScale, const float flDrawDistance, const uint iSpawnFlags)
{
    if( !blHealthBarEntityRegistered )
        return;

    if( FlagSet( iHealthBarSettings, MONSTERS ) )
        g_Hooks.RegisterHook( Hooks::Game::EntityCreated, @OnEntityCreated );
    if( FlagSet( iHealthBarSettings, PLAYERS ) )
        g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawned );

    CBaseEntity@ pExistingHealthBar;
    CBaseEntity@ pMonsterEntity;
    CBaseEntity@ pBreakableEntity;

    while( ( @pExistingHealthBar = g_EntityFuncs.FindEntityByClassname( pExistingHealthBar, "env_healthbar" ) ) !is null )
        g_EntityFuncs.Remove( pExistingHealthBar );

    if( FlagSet( iHealthBarSettings, MONSTERS ) )
    {
        while( ( @pMonsterEntity = g_EntityFuncs.FindEntityByClassname( pMonsterEntity, "monster_*" ) ) !is null )
        {   
            if( pMonsterEntity.GetClassname() == "monster_generic" || pMonsterEntity.GetClassname() == "monster_gman" || pMonsterEntity.GetClassname() == "monster_furniture" )
                continue;
    
            SpawnEnvHealthBar( @pMonsterEntity, vOriginOffset, flScale, flDrawDistance, iSpawnFlags );
        }
    }

    if( FlagSet( iHealthBarSettings, BREAKABLES ) )
    {   
        while( ( @pBreakableEntity = g_EntityFuncs.FindEntityByClassname( pBreakableEntity, "func_*" ) ) !is null )
        {
            if( !pBreakableEntity.IsBreakable() )
                continue;
            if( !pBreakableEntity.pev.SpawnFlagBitSet( 32 ) || pBreakableEntity.pev.SpawnFlagBitSet( 1 ) )
                continue;

            SpawnEnvHealthBar( @pBreakableEntity, vOriginOffset, flScale, flDrawDistance, iSpawnFlags );
        }
    }
} 

// !!AN!! workaround...
final class Schedulers
{
    private void OnEntitySpawned(EHandle hMonster)
    {
        NpcSpawned( null, cast<CBaseEntity@>( hMonster ) );
    }
}

HookReturnCode OnEntityCreated(CBaseEntity@ pEntity)
{
    if( pEntity !is null && pEntity.IsMonster() )
    {
        CBaseMonster@ pMonster = cast<CBaseMonster@>( pEntity );
        g_Scheduler.SetTimeout( Schedulers(), "OnEntitySpawned", 0.05f, EHandle( @pMonster ) );
    }

    return HOOK_CONTINUE;
}

void NpcSpawned(CBaseMonster@ pSquadmaker, CBaseEntity@ pMonster) // Trigger this from a squadmaker via "function_name"
{
    if( blHealthBarEntityRegistered && pMonster !is null )
        SpawnEnvHealthBar( @pMonster, Vector( 0, 0, 0 ), 0.0f, 0.0f, 0 );
}

HookReturnCode PlayerSpawned(CBasePlayer@ pPlayer)
{
    if( pPlayer !is null )
        SpawnEnvHealthBar( @pPlayer, Vector( 0, 0, 0 ), 0.0f, 0.0f, 0 );

    return HOOK_CONTINUE;
}
// Credit to H2 for providing this function
bool FlagSet( uint iTargetBits, uint iFlags )
{
    if( ( iTargetBits & iFlags ) != 0 )
        return true;
    else
        return false;
}

void SpawnEnvHealthBar(CBaseEntity@ pTarget, const Vector vOriginOffset, const float flScale, const float flDrawDistance, const uint iSpawnFlags)
{
    if( pTarget is null ) 
       return;

    dictionary hlth;
    if( vOriginOffset != g_vecZero ) hlth ["offset"]        = vOriginOffset.ToString();
    if( flScale > 0 )                hlth ["scale"]         = string( flScale );
    if( flDrawDistance > 0 )         hlth ["distance"]      = string( flDrawDistance );
    if( iSpawnFlags > 0 )            hlth ["spawnflags"]    = string( iSpawnFlags );

    CBaseEntity@ pEnvHealthBar = g_EntityFuncs.CreateEntity( "env_healthbar", hlth, false );
    if( pEnvHealthBar is null )
       return;

    @pEnvHealthBar.pev.owner = pTarget.edict();
    //g_Game.AlertMessage( at_notice, "target: " + pTarget.entindex() + "\n" );
    g_EntityFuncs.DispatchSpawn( pEnvHealthBar.edict() );
}

class env_healthbar : ScriptBaseEntity
{
    PlayerPostThinkHook@ pPlayerPostThinkFunc = null;

    private CBaseEntity@ pTrackedEntity;
    private CSprite@ pHealthBar;

    private uint iHealthBar_LastFrame = STR_HEALTHBAR_FRAMES.length() - 1;

    private float flTrackedEntity_StartHealth;
    private float flDrawDistance = 12048;
    
    private Vector vOffset = Vector( 0, 0, 16 );

    bool KeyValue( const string& in szKey, const string& in szValue )
    {
        if( szKey == "offset" ) 
        {
            g_Utility.StringToVector( vOffset, szValue );
            return true;
        }
        else if( szKey == "distance" ) 
        {
            flDrawDistance = atof( szValue );
            return true;
        }
        else
            return BaseClass.KeyValue( szKey, szValue );
    }

    void Precache()
    {
        for( uint p = 0; p < STR_HEALTHBAR_FRAMES.length(); ++p )
        {
            g_Game.PrecacheModel( strSpriteDir + STR_HEALTHBAR_FRAMES[p] + ".spr" );
            g_Game.PrecacheGeneric( strSpriteDir + STR_HEALTHBAR_FRAMES[p] + ".spr" );
        }
    }

    void Spawn()
    {
        self.Precache();
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;

        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.scale <= 0.0f )
            self.pev.scale = 0.3f;

        if( pTrackedEntity is null )
        {
            string strTarget = string( self.pev.target );
            strTarget.Trim();

            if( !strTarget.IsEmpty() && strTarget != self.GetTargetname() )
                @pTrackedEntity = g_EntityFuncs.FindEntityByTargetname( pTrackedEntity, strTarget );
            else
                @pTrackedEntity = g_EntityFuncs.Instance( self.pev.owner );
        }

        if( pTrackedEntity !is null )
        {
            //g_Game.AlertMessage( at_notice, "env_healthbar owner: " + pTrackedEntity.entindex() + "\n" );
            flTrackedEntity_StartHealth = pTrackedEntity.pev.max_health;

            if( flTrackedEntity_StartHealth <= 0 )
                flTrackedEntity_StartHealth = pTrackedEntity.pev.health;
        }

        SetThink( ThinkFunction( this.TrackEntity ) );
        self.pev.nextthink = g_Engine.time + 0.01f;

        if( !self.pev.SpawnFlagBitSet( 1 ) )
        {
            @pPlayerPostThinkFunc = PlayerPostThinkHook( this.AimingPlayer );
            g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @pPlayerPostThinkFunc );
        }
    }

    void UpdateOnRemove()
    {
        g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, @pPlayerPostThinkFunc );
        g_EntityFuncs.Remove( pHealthBar );
        BaseClass.UpdateOnRemove();
    }

    void TrackEntity()
    {
        if( pTrackedEntity !is null && ( pTrackedEntity.IsPlayer() || pTrackedEntity.IsMonster() || pTrackedEntity.IsBreakable() ) )
        {
            if( pHealthBar is null )
                CreateHealthBar();

            if( pHealthBar !is null )
            {
                uint iPercentHealth = uint( ( pTrackedEntity.pev.health / flTrackedEntity_StartHealth ) * iHealthBar_LastFrame );
                g_EntityFuncs.SetModel( pHealthBar, strSpriteDir + STR_HEALTHBAR_FRAMES[iPercentHealth] + ".spr");
                pHealthBar.SetScale( self.pev.scale );

                if( pTrackedEntity.IsBSPModel() )
                    pHealthBar.pev.origin = pTrackedEntity.pev.absmin + ( pTrackedEntity.pev.size * 0.5 ) + Vector( 0, 0, pTrackedEntity.pev.absmax.z );
                else
                    pHealthBar.pev.origin = pTrackedEntity.pev.origin + pTrackedEntity.pev.view_ofs + vOffset;
            }

            if( !pTrackedEntity.IsAlive() )
            {
                if( pTrackedEntity.IsRevivable() )
                    pHealthBar.pev.renderamt = 0.0f;
                else
                {
                    g_EntityFuncs.Remove( self );
                    return;
                }
            }
        }
        else
        {
            g_EntityFuncs.Remove( self );
            return;
        }

        self.pev.nextthink = g_Engine.time + 0.01f;
    }

    void CreateHealthBar()
    {
        @pHealthBar = g_EntityFuncs.CreateSprite( strSpriteDir + STR_HEALTHBAR_FRAMES[iHealthBar_LastFrame] + ".spr", pTrackedEntity.GetOrigin(), false, 0.0f );
        pHealthBar.SetScale( self.pev.scale );
        pHealthBar.pev.rendermode = kRenderTransAdd;

        if( self.pev.SpawnFlagBitSet( 1 ) )
            pHealthBar.pev.renderamt = 255.0f;
    }

    HookReturnCode AimingPlayer(CBasePlayer@ pPlayer)
    {
        if( pPlayer is null )
            return HOOK_CONTINUE;
        
        CBaseEntity@ pAimedEntity = g_Utility.FindEntityForward( pPlayer, flDrawDistance );

        if( pHealthBar !is null )
        {
            if( pAimedEntity is pTrackedEntity )
                pHealthBar.pev.renderamt = 255.0f;
            else if( pAimedEntity !is pTrackedEntity )
                pHealthBar.pev.renderamt = 0.0f;
        }

        return HOOK_CONTINUE;
    }
}

}
/* Special thanks to:
- Cadaver: sprites
- Snarkeh: original concept and implementation in Command&Conquer campaign
- AnggaraNothing and H2 for scripting support 
*/
