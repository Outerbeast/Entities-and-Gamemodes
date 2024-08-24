/*  CTempFX extension for temporary effect entities (WIP)
    Includes entities:
    env_dlight
    env_elight
    env_quakefx
    env_shockwave
    env_smoke
    env_trail
    env_sprayer
    env_spritefield
    env_playersprite

    Installation:-
    -Import this script in your main map script 
    #include "envtempeffects"

- Outerbeast
*/
CTempFX g_TempEffectFuncs;

bool blFXEntitiesRegistered = RegisterFXEntities();

enum ShockWaveTypes
{
    WV_CYLINDER,
    WV_DISK,
    WV_TORUS
};

enum PlayerSpriteTypes
{
    PLAYERSPRITE_NONE,
    PLAYERSPRITE_ATTACH,
    PLAYERSPRITE_CLUSTER
};

enum QuakeFxTypes
{
    QFX_TAR_EXP         = 4,
    QFX_LAVA_SPLASH     = 10,
    QFX_TELE_SPLASH     = 11,
    QFX_EXP             = 12,
    QFX_PARTICLE_BURST  = 122
};

enum EnvLightFlags
{
	SF_LIGHT_ONLYONCE	= 1 << 0,
	SF_LIGHT_STARTON	= 1 << 1,
	SF_LIGHT_TOGGLE		= 1 << 2
};

enum EnvShockwaveFlags
{
    SF_WV_START_ON            = 1 << 0,
    SF_WV_TOGGLE              = 1 << 1,
    SF_WV_DONT_DMG_START_ENT  = 1 << 2,
    SF_WV_DMG_BREAKABLES      = 1 << 4
};

enum SpriteFieldFlags
{
    SF_SPRFL_DRIFTUP        = 1 << 0,
    SF_SPRFL_DRIFTUP_50     = 1 << 1,
    SF_SPRFL_LOOP           = 1 << 2,
    SF_SPRFL_TRANSPARENT    = 1 << 3,
    SF_SPRFL_FLAT           = 1 << 4
};

bool RegisterFXEntities()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvLight", "env_dlight" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvLight", "env_elight" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvQuakeFx", "env_quakefx" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvShockwave", "env_shockwave" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvTrail", "env_trail" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvTrail", "env_beamtrail" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvSprayer", "env_sprayer" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvSpriteField", "env_spritefield" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvSmoke", "env_smoke" );
    g_CustomEntityFuncs.RegisterCustomEntity( "CEnvPlayerSprite", "env_playersprite" );

    return true;
}

mixin class TempFx
{
    protected array<uint8> UINT8_QFX =
    {
        QFX_EXP,
        QFX_LAVA_SPLASH,
        QFX_PARTICLE_BURST,
        QFX_TAR_EXP,
        QFX_TELE_SPLASH
    };

    void te_dlight
    (
        Vector pos,
        uint8 radius = 32, 
        RGBA c = WHITE,
        uint8 life = 255, 
        uint8 decayRate = 255,
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage dlight(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
            dlight.WriteByte( TE_DLIGHT );

            dlight.WriteCoord( pos.x );
            dlight.WriteCoord( pos.y );
            dlight.WriteCoord( pos.z );

            dlight.WriteByte( radius );
            dlight.WriteByte( c.r );
            dlight.WriteByte( c.g );
            dlight.WriteByte( c.b );
            dlight.WriteByte( life );
            dlight.WriteByte( decayRate );
        dlight.End();
    }

    void te_elight
    (
        CBaseEntity@ target, 
        Vector pos, 
        float radius = 1024.0f, 
        RGBA c = WHITE, 
        uint8 life = 255, 
        float decayRate = 2000.0f, 
        uint8 iAttachment = 0,
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage elight(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
            elight.WriteByte( TE_ELIGHT );
            elight.WriteShort( target.entindex() + iAttachment );

            elight.WriteCoord( pos.x );
            elight.WriteCoord( pos.y );
            elight.WriteCoord( pos.z );
            elight.WriteCoord( radius );

            elight.WriteByte( c.r );
            elight.WriteByte( c.g );
            elight.WriteByte( c.b );
            elight.WriteByte( life );

            elight.WriteCoord( decayRate );
        elight.End();
    }
    // Quake Style FX
    void te_quakefx
    (
        uint8 iFxType, 
        Vector pos, 
        uint16 radius = 128, 
        uint8 color = 250, 
        uint8 life = 5, 
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest=null
    )
    {
        if( UINT8_QFX.find( iFxType ) < 0 )
            iFxType = QFX_EXP;

        NetworkMessage qfx(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
            qfx.WriteByte( iFxType );

            qfx.WriteCoord( pos.x );
            qfx.WriteCoord( pos.y );
            qfx.WriteCoord( pos.z );

            if( iFxType == TE_PARTICLEBURST )
            {
                qfx.WriteShort( radius );
                qfx.WriteByte( color );
                qfx.WriteByte( life ); // duration
            }
            else if( iFxType == TE_EXPLOSION2 )
            {
                qfx.WriteByte( 0 ); // "start color" - has no effect
                qfx.WriteByte( 127 ); // "number of colors" - has no effect
            }

        qfx.End();
    }

    void te_shockwave
    (
        uint8 iWaveType,
        Vector pos, 
        float radius, 
        string sprite = "sprites/shockwave.spr", 
        uint8 startFrame = 0, 
        uint8 frameRate = 16, 
        uint8 life = 8, 
        uint8 width = 8, 
        uint8 noise = 0, 
        RGBA c = WHITE, 
        uint8 scrollSpeed = 0, 
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage sw( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
            sw.WriteByte( iWaveType );

            sw.WriteCoord( pos.x );
            sw.WriteCoord( pos.y );
            sw.WriteCoord( pos.z );
            sw.WriteCoord( pos.x );
            sw.WriteCoord( pos.y );
            sw.WriteCoord( pos.z + radius );

            sw.WriteShort( g_EngineFuncs.ModelIndex( sprite ) );

            sw.WriteByte( startFrame );
            sw.WriteByte( frameRate );
            sw.WriteByte( life );
            sw.WriteByte( width );
            sw.WriteByte( noise );

            sw.WriteByte( uint8( c.r ) );
            sw.WriteByte( uint8( c.g ) );
            sw.WriteByte( uint8( c.b ) );
            sw.WriteByte( uint8( c.a ) );
            sw.WriteByte( scrollSpeed );
        sw.End();
    }

    void te_spray
    (
        uint8 iSprayType,
        Vector pos,
        Vector dir,
        string sprite = "sprites/bubble.spr", 
        uint8 count = 8,
        uint8 speed = 127,
        uint8 noise = 255,
        uint8 rendermode = 0,
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage spray( msgType, NetworkMessages::SVC_TEMPENTITY, dest );

        spray.WriteByte( iSprayType );

            spray.WriteCoord( pos.x );
            spray.WriteCoord( pos.y );
            spray.WriteCoord( pos.z );

            spray.WriteCoord( dir.x );
            spray.WriteCoord( dir.y );
            spray.WriteCoord( dir.z );

            spray.WriteShort( g_EngineFuncs.ModelIndex( sprite ) );

            spray.WriteByte( count );
            spray.WriteByte( speed );
            spray.WriteByte( noise );

            if( iSprayType == TE_SPRAY )
                spray.WriteByte( rendermode );

        spray.End();
    }

    void te_spritetrail
    (
        Vector start,
        Vector end, 
        string sprite = "sprites/hotglow.spr",
        uint8 count = 2,
        uint8 life = 0, 
        uint8 scale = 1,
        uint8 speed = 16,
        uint8 speedNoise = 8,
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage trail(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
            trail.WriteByte( TE_SPRITETRAIL );

            trail.WriteCoord( start.x );
            trail.WriteCoord( start.y );
            trail.WriteCoord( start.z );

            trail.WriteCoord( end.x );
            trail.WriteCoord( end.y );
            trail.WriteCoord( end.z );

            trail.WriteShort( g_EngineFuncs.ModelIndex( sprite ) );

            trail.WriteByte( count );
            trail.WriteByte( life );
            trail.WriteByte( scale );
            trail.WriteByte( speedNoise );
            trail.WriteByte( speed );
        trail.End();
    }

    void te_trail
    (
        CBaseEntity@ target,
        string sprite = "sprites/laserbeam.spr", 
        uint8 life = 100,
        uint8 width = 2,
        RGBA c = WHITE,
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage trail( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
            trail.WriteByte( TE_BEAMFOLLOW );

            trail.WriteShort( target.entindex() );
            trail.WriteShort( g_EngineFuncs.ModelIndex( sprite ) );

            trail.WriteByte( life );
            trail.WriteByte( width );

            trail.WriteByte( c.r );
            trail.WriteByte( c.g );
            trail.WriteByte( c.b );
            trail.WriteByte( c.a );
        trail.End();
    }
    // Not yet programmed enities for these fx
    void te_playersprites
    (
        CBasePlayer@ target, 
        string sprite = "sprites/bubble.spr", 
        uint8 count = 16,
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
            m.WriteByte( TE_PLAYERSPRITES );
            m.WriteShort( target.entindex() );
            m.WriteShort( g_EngineFuncs.ModelIndex(sprite) );
            m.WriteByte( count );
            m.WriteByte( 0 ); // "size variation" - has no effect
        m.End();
    }

    void te_playerattachment
    (
        CBasePlayer@ target,
        float vOffset = 51.0f, 
        string sprite = "sprites/bubble.spr",
        uint16 life = 16, 
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
            m.WriteByte( TE_PLAYERATTACHMENT );
            m.WriteByte( target.entindex() );
            m.WriteCoord( vOffset );
            m.WriteShort( g_EngineFuncs.ModelIndex(sprite) );
            m.WriteShort( life );
        m.End();
    }

    void te_killplayerattachments(CBasePlayer@ pPlayer, NetworkMessageDest msgType = MSG_BROADCAST, edict_t@ dest = null)
    {
        NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
            m.WriteByte( TE_KILLPLAYERATTACHMENTS );
            m.WriteByte( pPlayer.entindex() );
        m.End();
    }

    void te_smoke
    (
        Vector pos, 
        string sprite = "sprites/steam1.spr", 
        int scale = 10,
        int frameRate = 15,
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest=null
    )
    {
        NetworkMessage smoke( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
            smoke.WriteByte( TE_SMOKE );

            smoke.WriteCoord( pos.x );
            smoke.WriteCoord( pos.y );
            smoke.WriteCoord( pos.z );

            smoke.WriteShort( g_EngineFuncs.ModelIndex( sprite ) );

            smoke.WriteByte( scale );
            smoke.WriteByte( frameRate );
        smoke.End();
    }

    void te_firefield
    (
        Vector pos,
        uint16 radius = 128, 
        string sprite = "xfire.spr",
        uint8 count = 128, 
        uint8 flags = 30,
        uint8 life = 5,
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    ) 
    {
        NetworkMessage m( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
            m.WriteByte( TE_FIREFIELD );
            m.WriteCoord( pos.x );
            m.WriteCoord( pos.y );
            m.WriteCoord( pos.z );

            m.WriteShort( radius );

            m.WriteShort( g_EngineFuncs.ModelIndex(sprite) );
            m.WriteByte( count );
            m.WriteByte( flags );
            m.WriteByte( life );
        m.End();
    }

    void te_tracer
    (
        Vector start,
        Vector end, 
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage tracer(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
            tracer.WriteByte(TE_TRACER);

            tracer.WriteCoord(start.x);
            tracer.WriteCoord(start.y);
            tracer.WriteCoord(start.z);

            tracer.WriteCoord(end.x);
            tracer.WriteCoord(end.y);
            tracer.WriteCoord(end.z);
        tracer.End();
    }

    void te_usertracer
    (
        Vector pos,
        Vector dir,
        float speed = 6000.0f, 
        uint8 life = 32,
        uint color = 4,
        uint8 length = 12,
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        Vector velocity = dir * speed;
        NetworkMessage tracer( msgType, NetworkMessages::SVC_TEMPENTITY, dest );
            tracer.WriteByte( TE_USERTRACER );

            tracer.WriteCoord( pos.x );
            tracer.WriteCoord( pos.y );
            tracer.WriteCoord( pos.z );

            tracer.WriteCoord( velocity.x );
            tracer.WriteCoord( velocity.y );
            tracer.WriteCoord( velocity.z );

            tracer.WriteByte( life );
            tracer.WriteByte( color );
            tracer.WriteByte( length );
        tracer.End();
    }

    void te_streaksplash
    (
        Vector start,
        Vector dir,
        uint8 color = 4, 
        uint16 count = 256,
        uint16 speed = 2048,
        uint16 speedNoise = 128, 
        NetworkMessageDest msgType = MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
            m.WriteByte(TE_STREAK_SPLASH);

            m.WriteCoord(start.x);
            m.WriteCoord(start.y);
            m.WriteCoord(start.z);
            m.WriteCoord(dir.x);
            m.WriteCoord(dir.y);
            m.WriteCoord(dir.z);

            m.WriteByte(color);
            m.WriteShort(count);
            m.WriteShort(speed);
            m.WriteShort(speedNoise);
        m.End();
    }


    void te_implosion
    (
        Vector pos,
        uint8 radius = 255,
        uint8 count = 32,
        uint8 life = 5,
        NetworkMessageDest msgType=MSG_BROADCAST,
        edict_t@ dest = null
    )
    {
        NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
            m.WriteByte(TE_IMPLOSION);
            
            m.WriteCoord(pos.x);
            m.WriteCoord(pos.y);
            m.WriteCoord(pos.z);

            m.WriteByte(radius);
            m.WriteByte(count);
            m.WriteByte(life);
        m.End();
    }
};

final class CTempFX : TempFx { };

final class CEnvLight : ScriptBaseEntity, TempFx
{
	private bool blToggled;

    void Spawn()
    {
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		
		blToggled = self.pev.SpawnFlagBitSet( SF_LIGHT_STARTON ) || self.GetTargetname() == "";

        if( blToggled )
			g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, ClientPutInServerHook( this.ClientPutInServer ) );

		BaseClass.Spawn();
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
		if( blToggled )
		{
			switch( useType )
			{
				case USE_OFF:
					self.pev.nextthink = 0.0f;
					break;

				case USE_ON:
					self.pev.nextthink = g_Engine.time;
					break;
					
				case USE_TOGGLE:
					self.pev.nextthink = self.pev.nextthink > 0.0f ? 0.0f : g_Engine.time;
					break;
			}
		}
 		else
			self.pev.nextthink = g_Engine.time;

		if( blToggled && self.pev.SpawnFlagBitSet( SF_LIGHT_ONLYONCE ) )
			g_EntityFuncs.Remove( self );
    }

    void Think()
    {
		if( self.pev.health <= 0.0f )
			self.pev.health = 255.5f;

		if( self.GetClassname() == "env_dlight" )
			MakeDLight();
		else if( self.GetClassname() == "env_elight" )
		{
			CBaseEntity@ pTarget;

			if( self.pev.target != "" && self.pev.target != self.GetTargetname() )
				@pTarget = g_EntityFuncs.FindEntityByTargetname( pTarget, "" + self.pev.target );
			else
			{
				while( ( @pTarget = g_EntityFuncs.FindEntityInSphere( pTarget, self.pev.origin, self.pev.renderamt, "*", "classname" ) ) !is null )
					MakeELight( pTarget );
			}
		}

		if( blToggled )
			self.pev.nextthink = g_Engine.time + ( self.pev.health / 10 );// The effect only lasts for 25.5s maximum
    }

	void MakeDLight()
	{
        te_dlight
        (
            self.pev.origin,
            uint8( self.pev.renderamt ), 
            RGBA( self.pev.rendercolor, int( self.pev.renderamt ) ),
            uint8( self.pev.health <= 0.0f ? 255.5f : self.pev.health ),
            uint8( self.pev.frags )
        );
	}

	void MakeELight(EHandle hTarget)
	{
		CBaseEntity@ pTarget = hTarget.GetEntity(),
                    pFollower = g_EntityFuncs.FindEntityByTargetname( pFollower, "" + self.pev.netname );

		if( !hTarget || pTarget is null || !pTarget.IsPointEnt() )
			@pTarget = self;

        if( pFollower is null )
            @pFollower = self;

        te_elight
        (
            pTarget, 
            pFollower.pev.origin, 
            uint8( self.pev.renderamt ), 
            RGBA( self.pev.rendercolor, int( self.pev.renderamt ) ), 
            uint8( self.pev.health <= 0.0f ? 255.5f : self.pev.health ),
            uint8( self.pev.frags ), 
            0x1000 * self.pev.impulse
        );
	}
    // !-HACK-!: effect only happens when a valid player is connected to the server
    HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer)
    {
        self.pev.nextthink = g_Engine.time + Math.RandomFloat( 0.0f, 1.0f );
        g_Hooks.RemoveHook( Hooks::Player::ClientPutInServer, ClientPutInServerHook( this.ClientPutInServer ) );
        
        return HOOK_CONTINUE;
    }
};

final class CEnvShockwave : ScriptBaseEntity, TempFx
{
    private string strSprite = "sprites/shockwave.spr", strShockwaveStart;
    private float
        flRadius = 1000.0f,
        flStrikeTime = 1.0f;
    private uint8
        iShockwaveType,
        m_iHeight = 10,
        m_iScrollRate,
        m_iNoise;
    private bool blToggled;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "ShockwaveType" )
            iShockwaveType = atoui( szValue );
        else if( szKey == "m_iszPosition" )
            strShockwaveStart = szValue;
        else if( szKey == "m_iRadius" )
            flRadius = atof( szValue );
        else if( szKey == "StrikeTime" )
            flStrikeTime = atof( szValue );
        else if( szKey == "m_iHeight" )
            m_iHeight = Math.clamp( 0, 255, atoui( szValue ) );
        else if( szKey == "m_iNoise" )
            m_iNoise = Math.clamp( 0, 255, atoui( szValue ) );
        else if( szKey == "m_iScrollRate" )
            m_iScrollRate = Math.clamp( 0, 255, atoui( szValue ) );
        else if( szKey == "m_iFrameRate" )
            self.pev.framerate = atof( szValue );
        else if( szKey == "m_iStartFrame" )
            self.pev.frame = atof( szValue );
        else if( szKey == "m_iTime" )
            self.pev.health = atof( szValue );
        else
            return BaseClass.KeyValue( szKey, szValue );
            
        return true;
    }

    void Precache()
    {
        if( self.pev.netname != "" )
            strSprite = self.pev.netname;

        g_Game.PrecacheModel( strSprite );
        g_Game.PrecacheGeneric( strSprite );

        BaseClass.Precache();
    }

    void Spawn()
    {
        self.Precache();

        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.framerate <= 0.0f )
            self.pev.framerate = 16.0f;

        if( self.pev.rendercolor == g_vecZero )
            self.pev.rendercolor = Vector( 255, 255, 255 );

        if( self.pev.renderamt <= 0.0f )
            self.pev.renderamt = 255.0f;

        if( self.pev.health <= 0.0f )
            self.pev.health = 8.0f;

        blToggled = self.pev.SpawnFlagBitSet( SF_LIGHT_STARTON );

        if( blToggled )
            self.pev.nextthink = g_Engine.time + 1.0f;

        BaseClass.Spawn();
    }
    
    void Think()
    {
        if( blToggled && self.pev.SpawnFlagBitSet( SF_WV_TOGGLE ) )
            self.Use( self, self, USE_ON, 0.0f );

        self.pev.nextthink = g_Engine.time + flStrikeTime;
    }
    
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( useType == USE_OFF || ( useType == USE_TOGGLE && blToggled ) )
        {
            blToggled = false;
            return;
        }

        CBaseEntity@ pTarget;
        
        if( strShockwaveStart != "" )
        {
            if( strShockwaveStart == "!activator" && pActivator !is null )
                @pTarget = pActivator;
            else if( strShockwaveStart == "!caller" && pCaller !is null )
                @pTarget = pCaller;
            else
                @pTarget = g_EntityFuncs.FindEntityByTargetname( pTarget, strShockwaveStart );
        }
        else
            @pTarget = self;

        if( pTarget is null )
            @pTarget = self;

        switch( iShockwaveType )
        {
            case WV_CYLINDER:
                MakeShockwave( pTarget.pev.origin, flRadius, TE_BEAMCYLINDER );
                break;

            case WV_DISK: 
                MakeShockwave( pTarget.pev.origin, flRadius, TE_BEAMDISK );
                break;

            case WV_TORUS:
                MakeShockwave( pTarget.pev.origin, flRadius, TE_BEAMTORUS );
                break;

            default:
                MakeShockwave( pTarget.pev.origin, flRadius, TE_BEAMCYLINDER );
        }

        blToggled = useType == USE_ON || useType == USE_TOGGLE && !blToggled;

        if( flStrikeTime > 0.0f && self.pev.SpawnFlagBitSet( SF_WV_TOGGLE ) )
            self.pev.nextthink = g_Engine.time + flStrikeTime;
    }

    void MakeShockwave(Vector pos, float radius, uint8 iBeamTypeIn)
    {
        te_shockwave
        (
            iBeamTypeIn,
            pos, 
            radius, 
            strSprite,
            uint8( self.pev.frame ), 
            uint8( self.pev.framerate ),
            uint8( self.pev.health ),
            uint8( m_iHeight ),
            uint8( m_iNoise ),
            RGBA( self.pev.rendercolor, uint8( self.pev.renderamt ) ),
            uint8( m_iScrollRate ) 
        );
    }
};

final class CEnvSpriteField : ScriptBaseEntity, TempFx
{
    private string strSprite = "sprites/xfire.spr";
    uint16 iRadius = 128;
    uint8 iSpriteCount = 128;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "sprite" )
            strSprite = szValue;
        else if( szKey == "SpriteCount" )
            iSpriteCount = atoui( szValue );
        else if( szKey == "radius" )
            iRadius = atoui( szValue );
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Precache()
    {
        g_Game.PrecacheModel( strSprite );
        g_Game.PrecacheGeneric( strSprite );

        BaseClass.Precache();
    }

    void Spawn()
    {
        self.Precache();

        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        BaseClass.Spawn();
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        CBaseEntity@ pTarget;
        
        if( self.pev.target != "" )
        {
            if( self.pev.target == "!activator" && pActivator !is null )
                @pTarget = pActivator;
            else if( self.pev.target == "!caller" && pCaller !is null )
                @pTarget = pCaller;
            else
                @pTarget = g_EntityFuncs.FindEntityByTargetname( pTarget, "" + self.pev.target );
        }
        else
            @pTarget = self;

        if( pTarget is null )
            @pTarget = self;

        te_firefield
        (
            pTarget.pev.origin,
            uint16( iRadius ), 
            strSprite,
            iSpriteCount,
            uint8( self.pev.spawnflags ),
            uint8( self.pev.health )
        );
    }
};

final class CEnvQuakeFx : ScriptBaseEntity, TempFx
{
    void Spawn()
    {
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.frags < 0.0f )
            self.pev.frags = 70.0f;

        if( self.pev.armortype < 0.0f )
            self.pev.armortype = 300.0f;

        if( self.pev.health <= 0.0f )
            self.pev.health = 255.0f;
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        CBaseEntity@ pTarget;
        
        if( self.pev.message != "" )
        {
            if( self.pev.message == "!activator" && pActivator !is null )
                @pTarget = pActivator;
            else if( self.pev.message == "!caller" && pCaller !is null )
                @pTarget = pCaller;
            else
                @pTarget = g_EntityFuncs.FindEntityByTargetname( pTarget, self.pev.message );
        }

        if( pTarget is null )
            @pTarget = self;

        te_quakefx
        ( 
            uint8( self.pev.impulse ), 
            pTarget.pev.origin, 
            uint16( self.pev.armortype ), 
            uint8( self.pev.frags ), 
            uint8( self.pev.health )
        );

        if( !self.pev.SpawnFlagBitSet( 1 ) ) // Repeatable?
            g_EntityFuncs.Remove( self );
    }
};

final class CEnvSprayer : ScriptBaseEntity, TempFx
{
    private string strSprite = "sprites/hotglow.spr";
    private uint8 iSprayType, iSprayCount, iSprayNoise, iSpeed, iSpeedNoise;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "sprite" )
            strSprite = szValue;
        else if( szKey == "SprayType" )
            iSprayType = atoui( szValue );
        else if( szKey == "SprayCount" )
            iSprayCount = atoui( szValue );
        else if( szKey == "SprayNoise" )
            iSprayNoise = atoui( szValue );
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Precache()
    {
        g_Game.PrecacheModel( strSprite );
        g_Game.PrecacheGeneric( strSprite );

        BaseClass.Precache();
    }

    void Spawn()
    {
        self.Precache();

        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        BaseClass.Spawn();
    }
    
    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        CBaseEntity@ pStartEntity, pEndEntity;
        
        if( self.pev.netname != "" && self.pev.netname != self.GetTargetname() )
        {
            if( self.pev.netname == "!activator" && pActivator !is null )
                @pStartEntity = pActivator;
            else if( self.pev.target == "!caller" && pCaller !is null )
                @pStartEntity = pCaller;
            else
                @pStartEntity = g_EntityFuncs.FindEntityByTargetname( pStartEntity, self.pev.netname );
        }
        else
            @pStartEntity = self;
            
        if( self.pev.target != "" && self.pev.target != self.GetTargetname() )
        {
            if( self.pev.targetname == "!activator" && pActivator !is null )
                @pEndEntity = pActivator;
            else if( self.pev.target == "!caller" && pCaller !is null )
                @pEndEntity = pCaller;
            else
                @pEndEntity = g_EntityFuncs.FindEntityByTargetname( pStartEntity, self.pev.target );
        }

        const Vector
            start = pStartEntity.pev.origin,
            end = pEndEntity.pev.origin;
        
        if( iSprayType == TE_SPRITETRAIL )
        {
            te_spritetrail
            (
                start,
                end, 
                strSprite,
                uint8( iSprayCount ),
                uint8( self.pev.health ), 
                uint8( self.pev.scale ),
                uint8( iSpeed ),
                uint8( iSpeedNoise )
            );
        }
        else
        {
            te_spray
            (
                uint8( iSprayType ),
                start,
                self.pev.angles,
                strSprite, 
                uint8( iSprayCount ),
                uint8( iSpeed ),
                uint8( iSprayNoise ),
                uint8( self.pev.renderamt ) 
            );
        }
    }
};

final class CEnvTrail : ScriptBaseEntity, TempFx
{
    private string strSprite = "sprites/laserbeam.spr";

    void Precache()
    {
        if( self.pev.netname != "" )
            strSprite = self.pev.netname;

        g_Game.PrecacheModel( strSprite );
        g_Game.PrecacheGeneric( strSprite );

        BaseClass.Precache();
    }

    void Spawn()
    {
        self.Precache();

        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        BaseClass.Spawn();

        if( !self.pev.SpawnFlagBitSet( 1 ) )
            self.Use( self, self, USE_ON, 0.0f );
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( useType == USE_OFF )
            return;

        CBaseEntity@ pTarget;

        if( self.pev.target != "" && self.pev.target != self.GetTargetname() )
        {
            if( self.pev.target == "!activator" && pActivator !is null )
                @pTarget = pActivator;
            else if( self.pev.target == "!caller" && pCaller !is null )
                @pTarget = pCaller;
            else
                @pTarget = g_EntityFuncs.FindEntityByTargetname( pTarget, self.pev.target );
        }
        else
            @pTarget = self;

        if( pTarget is null )
            @pTarget = self;

        te_trail
        (
            pTarget,
            strSprite, 
            uint8( self.pev.health * 10 ),
            uint8( self.pev.armorvalue ),
            RGBA( self.pev.rendercolor, int( self.pev.renderamt ) )
        );
    }
};

final class CSparkShower : ScriptBaseEntity, TempFx
{
    
};
// Just a wrapper for native entity env_smoker
final class CEnvSmoke : ScriptBaseEntity, TempFx
{
    EHandle hSmoker;

    void Spawn()
    {
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        BaseClass.Spawn();

        if( !self.pev.SpawnFlagBitSet( 1 ) )
            self.Use( self, self, USE_ON );
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        switch( useType )
        {
            case USE_ON:
            {
                if( !hSmoker )
                {
                    hSmoker = g_EntityFuncs.Create( "env_smoker", self.pev.origin, self.pev.angles, true, self.edict() );
                    hSmoker.GetEntity().pev.health = self.pev.health <= 0.0f ? 9999999.9f : self.pev.health;
                    hSmoker.GetEntity().pev.scale = self.pev.health <= 0.0f ? 1.0f : self.pev.scale;
                    hSmoker.GetEntity().pev.dmg = self.pev.dmg;
                    g_EntityFuncs.DispatchSpawn( hSmoker.GetEntity().edict() );
                }

                break;
            }

            case USE_TOGGLE:
                self.Use( null, null, hSmoker ? USE_OFF : USE_ON );
                break;


            case USE_OFF:
                g_EntityFuncs.Remove( hSmoker.GetEntity() );
                break;
        }
    }

    void UpdateOnRemove()
    {
        if( hSmoker )
            g_EntityFuncs.Remove( hSmoker.GetEntity() );
    }

};
// WIP
final class CEnvPlayerSprite : ScriptBaseEntity, TempFx
{
    private float flOffset = 51.0f;
    private string strSprite = "sprites/bubble.spr";
    private int
        iSpriteCount = 1,
        iSpriteType = 2;

    private array<bool> BL_PLAYERSPRITE_ACTIVE( g_Engine.maxClients + 1 );

    void Precache()
    {
        if( self.pev.netname != "" )
            strSprite = self.pev.netname;

        g_Game.PrecacheModel( strSprite );
        g_Game.PrecacheGeneric( strSprite );

        BaseClass.Precache();
    }

    void Spawn()
    {
        self.Precache();

        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        BaseClass.Spawn();
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( pActivator is null || !pActivator.IsPlayer() )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );

        switch( useType )
        {
            case USE_OFF:
            case USE_KILL
            {
                for( uint iPlayer = 1; iPlayer < BL_PLAYERSPRITE_ACTIVE.length(); iPlayer++ )
                {
                    if( g_PlayerFuncs.FindPlayerByIndex( iPlayer ) is null || !g_PlayerFuncs.FindPlayerByIndex( iPlayer ).IsConnected() )
                        continue;

                    te_killplayerattachments( g_PlayerFuncs.FindPlayerByIndex( iPlayer ) );
                }

                return;
            }
        }

        switch( iSpriteType )
        {
            case PLAYERSPRITE_NONE:
                te_killplayerattachments( pPlayer );
                break;

            case PLAYERSPRITE_ATTACH:
            {
                te_playerattachment( pPlayer, flOffset, strSprite, int( self.pev.health ) );
                BL_PLAYERSPRITE_ACTIVE[pPlayer.entindex()] = true;
                break;
            }

            case PLAYERSPRITE_CLUSTER:
            {
                te_playersprites( pPlayer, strSprite, iSpriteCount );
                BL_PLAYERSPRITE_ACTIVE[pPlayer.entindex()] = true;
                break;
            }
        }
    }

    void UpdateOnRemove()
    {
        for( int iPlayer = 1; iPlayer < g_Engine.maxClients; iPlayer++ )
        {
            if( g_PlayerFuncs.FindPlayerByIndex( iPlayer ) is null || !g_PlayerFuncs.FindPlayerByIndex( iPlayer ).IsConnected() )
                continue;

            te_killplayerattachments( g_PlayerFuncs.FindPlayerByIndex( iPlayer ) );
        }
    }
};
