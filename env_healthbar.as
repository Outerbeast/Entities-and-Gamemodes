/* env_healthbar
Custom entity to draw a health bar above a target entity
supports "scale" key to resize the health bar

Script is functional but prone to breaking.
TO DO:
- Fix division by 0 error
- "offset_pos" "x y z" key to change the position of the health bar slightly
- draw healthbars for newly spawned entities (how?)
- "healthbar_persist" flag that will always keep the healthbar on if set (by default health bar disappears when not aiming)
- shove this bastard into a plugin of sorts (I hope) and apply the healthbars to all entities automatically
*/

class env_healthbar : ScriptBaseEntity
{
    PlayerPostThinkHook@ pPlayerPostThinkFunc = null;

    private CBaseEntity@ pTrackedEntity;
    private CSprite@ pHealthBar;

    array<string> STR_HEALTHBAR_FRAMES = { "h0", "h10", "h20", "h30", "h40", "h50", "h60", "h70", "h80", "h90", "h100" };

    void Precache()
    {
        for( uint p = 0; p < STR_HEALTHBAR_FRAMES.length(); ++p )
        {
            g_Game.PrecacheModel( "sprites/misc/" + STR_HEALTHBAR_FRAMES[p] + ".spr" );
            g_Game.PrecacheGeneric( "sprites/misc/" + STR_HEALTHBAR_FRAMES[p] + ".spr" );
        }
    }

    void Spawn()
	{
        self.Precache();
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.scale == 0.0f )
            self.pev.scale = 0.3f;

        if( pTrackedEntity is null )
        {
            if( self.pev.target != "" && self.pev.target != self.GetTargetname() )
                @pTrackedEntity = g_EntityFuncs.FindEntityByTargetname( pTrackedEntity, "" + self.pev.target );
        }

		SetThink( ThinkFunction( this.TrackEntity ) );
        self.pev.nextthink = g_Engine.time + 0.01f;

        @pPlayerPostThinkFunc = PlayerPostThinkHook( this.AimingPlayer );
        g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @pPlayerPostThinkFunc );
	}

    void TrackEntity()
    {
        if( pTrackedEntity !is null && pTrackedEntity.pev.health != 0 && ( pTrackedEntity.IsPlayer() || pTrackedEntity.IsMonster() || ( pTrackedEntity.IsBreakable() && pTrackedEntity.pev.SpawnFlagBitSet( 32 ) ) ) )
        {
            if( pHealthBar is null )
                CreateHealthBar();

            if( pHealthBar !is null )
            {
                uint iPercentHealth = uint( ( pTrackedEntity.pev.health / pTrackedEntity.pev.max_health ) * 10 ); // BUG: this monster keeps dividing by 0 because retarded API, causing crashing
                g_EntityFuncs.SetModel( pHealthBar, "sprites/misc/" + STR_HEALTHBAR_FRAMES[iPercentHealth] + ".spr");

                if( pTrackedEntity.IsBSPModel() )
                    pHealthBar.pev.origin = pTrackedEntity.pev.absmin + ( pTrackedEntity.pev.size * 0.5 ) + Vector( 0, 0, pTrackedEntity.pev.absmax.z );
                else
                    pHealthBar.pev.origin = pTrackedEntity.pev.origin + pTrackedEntity.pev.view_ofs + Vector( 0, 0, 12 );

                pHealthBar.pev.scale = self.pev.scale;
            }

            if( !pTrackedEntity.IsAlive() )
                g_EntityFuncs.Remove( pHealthBar );
        }
        self.pev.nextthink = g_Engine.time + 0.01f;
    }

    void CreateHealthBar()
    {
        @pHealthBar = g_EntityFuncs.CreateSprite( "sprites/misc/" + STR_HEALTHBAR_FRAMES[10] + ".spr", pTrackedEntity.GetOrigin(), false, 0.0f );
        pHealthBar.pev.scale = self.pev.scale;
    }

    HookReturnCode AimingPlayer(CBasePlayer@ pPlayer)
    {
        if( pPlayer is null )
            return HOOK_CONTINUE;
        
        CBaseEntity@ pAimedEntity = g_Utility.FindEntityForward( pPlayer );

        if( pHealthBar !is null && pAimedEntity !is pTrackedEntity )
        {
            pHealthBar.pev.rendermode   = kRenderTransAdd;
            pHealthBar.pev.renderamt    = 0.0f;
        }
        if( pHealthBar !is null && pAimedEntity is pTrackedEntity )
        {
            pHealthBar.pev.rendermode   = kRenderNormal;
            pHealthBar.pev.renderamt    = 255.0f;
        }
        return HOOK_CONTINUE;
    }
}

void MapInit()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "env_healthbar", "env_healthbar" );
}
/* Special thanks to:
- Cadaver: sprites
- Snarkeh: original concept and implementation in Command&Conquer campaign
- AnggaraNothing and H2 for scripting support 
*/