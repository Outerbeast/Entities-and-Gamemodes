/* trigger_sound brush entity from SoHL to be compatible with Sven Co-op
    Basically env_sound but relies on a trigger zone instead of a radius- yes this is completely
    needless and stupid idea and I am clueless as to why the mods implemented this when default env_sound is sufficient.
    Do not use this for maps you are building, this is purely for compatibility in map conversions.
    Use env_sound instead.
- Outerbeast
*/
bool blTriggerSoundRegistered = RegisterTriggerSoundEntity();

bool RegisterTriggerSoundEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_sound", "trigger_sound" );
    return g_CustomEntityFuncs.IsCustomEntity( "trigger_sound" )
}

final class trigger_sound : ScriptBaseEntity
{
    private EHandle hSound;
    private string strMaster, strKillTarget;
    private int iRadius = 2;
    private float flDelay;
    CScheduledFunction@ fnKillTarget;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey == "roomtype")
            self.pev.health = atof( szValue );
        else if( szKey == "master" )
            strMaster = szValue;
        else if( szKey == "killtarget" )
            strKillTarget = szValue;
        else if( szKey == "delay" )
            flDelay = atof( szValue );
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Spawn()
    {
        self.pev.solid      = SOLID_TRIGGER;
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.effects    |= EF_NODRAW;

        g_EntityFuncs.SetModel( self, self.pev.model );
        hSound = CreateSoundEntity();
        BaseClass.Spawn();
    }

    EHandle CreateSoundEntity()
    {
        dictionary dictEnvSound =
        {
            { "origin", self.Center().ToString().Replace( ",", "" ) },
            { "roomtype", string( int( self.pev.health ) ) },
            { "iRadius", string( iRadius ) },
            { "spawnflags", "1" }
        };

        return g_EntityFuncs.CreateEntity( "env_sound", dictEnvSound );
    }

    void ApplyRoomSoundEffect(CBasePlayer@ pPlayer)
    {
        if( pPlayer is null || !hSound ) 
            return;
        
        CBaseEntity@ pSound = hSound.GetEntity();
        const Vector vecNewOrigin = ( pPlayer.pev.origin + pPlayer.pev.view_ofs ) - pSound.pev.view_ofs;
        g_EntityFuncs.SetOrigin( pSound, vecNewOrigin );
        pSound.Think();
        pSound.pev.nextthink = 0.0f;
        g_EntityFuncs.SetOrigin( pSound, self.Center() );
    }

    void Touch(CBaseEntity@ pOther)
    {
        if( !g_EntityFuncs.IsMasterTriggered( strMaster, pOther ) || pOther is null || !pOther.IsPlayer() ) 
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );

        if( pPlayer is null )
            return;

        if( EHandle( pPlayer.GetUserData( "m_pentSndLast" ) ).GetEntity() !is self )
        {
            pPlayer.GetUserData()["m_pentSndLast"] = EHandle( self );
            ApplyRoomSoundEffect( pPlayer );
            self.SUB_UseTargets( pPlayer, USE_TOGGLE, 0 );
            KillTarget( strKillTarget, flDelay );
        }
    }

    void KillTarget(string strTargetname, float flDelay)
    {
        if( strTargetname == "" )
            return;

        if( flDelay > 0.0f )
        {
            @fnKillTarget = g_Scheduler.SetTimeout( this, "KillTarget", flDelay, strTargetname, 0.0f );
            return;
        }
        
        do( g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, strTargetname ) ) );
        while( g_EntityFuncs.FindEntityByTargetname( null, strTargetname ) !is null );
    }

    void UpdateOnRemove()
    {
        g_EntityFuncs.Remove( hSound.GetEntity() );
    }
};
// Special thanks to AnggaraNothing
