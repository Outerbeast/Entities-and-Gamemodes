/* Player Sentry
    by Outerbeast
    extension for weapon_pipewrench that lets players create their own sentry gun

    Installation:-
    - Place the script file into scripts/maps
    - Load the script with any of the methods below
    Add this cvar in your map cfg
    map_script player_sentry
    OR
    Load this script via trigger_script entity in your map
    "classname" "trigger_script"
    "m_iszScriptFile" "player_sentry"
    OR
    Add this in your map script header
    #include "player_sentry"

    WARNING: if you add this to a map and it doesn't already contain a monster_sentry, the game will crash if you try to spawn a sentry.
    You must precache the sentry by calling "PLAYER_SENTRY::Precache()" in MapInit in your main map script. Alternatively, place a monster_sentry in your map - hide it somewhere or killtarget it if you don't intend it to be part of the level.

    Usage:-
    - Equip the pipewrench then use Tertiary attack key to place your sentry. Creating a sentry will cost you your remaining armor for its base health.
    - You need to have at least 10 armor to be able to create a sentry. Only one sentry can be deployed at a time. You cannot build a sentry in water or while you are in water (for safety reasons).
    - If it appears that the sentry didn't spawn, the set position is likely not valid. Find a better place to put your sentry and try again.
    - You can pick up and move the sentry to a new location: press USE while in front of your sentry then press it again to place it while the pipwrench is active. You can delete your sentry while carrying it by pressing Reload.
    If you die while carrying your sentry then the sentry will be destroyed.
    Mappers: if you want to restrict the sentries being placed in only allowed spots, you can create any brush entity with the name "player_sentry_allowed_zone" (recommend using an nulled func_illusionary).
    This will only permit sentries being built/placed inside that zone entity.

    Customisation (for advanced users):-
    You can change what weapon is used and what buttons can be used to deploy/move/delete your sentry
    - PLAYER_SENTRY::Setup(string strModel, string strDisplayNameIn = strDisplayName, int iAttackRange = iSentryAttackRange, float flHealthMultiplier = flSentryHealthMultiplier): function to configure your sentry. Call in MapInit.
    - PLAYER_SENTRY::strSentryMdl: sets a custom model for the sentry to use. Warning: when setting this, ensure you do this in MapInit then call Precache to avoid precache host errors. Better to use the function above.
    - PLAYER_SENTRY::strDisplayName: sets the sentry's hudinfo name, "Sentry" is default.
    - PLAYER_SENTRY::strSentryWeapon: name of the weapon used to spawn the sentry. It can be a custom weapon.
    - PLAYER_SENTRY::iSentryWeaponAttackType: select which weapon attack is used to spawn the sentry, either Primary (2), Secondary (1) or Tertiary attack (0, default)
    - PLAYER_SENTRY::iSentryMoveBtn/iSentryDeleteBtn: chose which button picks up/puts down and deletes the sentry. See In_Buttons enum for choices https://baso88.github.io/SC_AngelScript/docs/In_Buttons.htm
    - PLAYER_SENTRY::iSentryAttackRange: set a custom attack range for the sentry
    Any conflicting settings will cause the defaults to be used instead.

    Optional callbacks are also supported for certain events such as sentry building and everytime a player sentry thinks
    - PLAYER_SENTRY::SetSentryBuiltCallback(SentryBuiltCallback@ fn): registers a callback for when a player builds a sentry. Uses signature void FunctionName(CBaseMonster@, CBasePlayer@).
    - PLAYER_SENTRY::SetSentryThinkCallback(SentryThinkCallback@ fn): registers a callback for when a player built sentry thinks. Uses signature void FunctionName(CBaseMonster@).
    - PLAYER_SENTRY::SetSentryDestroyedCallback(SentryDestroyedCallback@ fn): registers a callback for when a sentry gets deleted. Uses signature void FunctionName(CBaseMonster@).
    Delegates for class methods are allowed.
    To remove a callback, its literally the same functions above but "Remove" instead of "Set" eg PLAYER_SENTRY::RemoveSentryBuiltCallback(SentryBuiltCallback@ fn).
*/
funcdef void SentryBuiltCallback(CBaseMonster@, CBasePlayer@);
funcdef void SentryThinkCallback(CBaseMonster@);
funcdef void SentryDestroyedCallback(CBaseMonster@);

namespace PLAYER_SENTRY
{

enum sentrydeployweaponattack
{
    WPN_TERTIARY_ATTACK = 0,
    WPN_SECONDARY_ATTACK,
    WPN_PRIMARY_ATTACK
};

array<SentryBuiltCallback@> FN_SENTRYBUILT_CBS;
array<SentryThinkCallback@> FN_SENTRYTHINK_CBS;
array<SentryDestroyedCallback@> FN_SENTRYDESTROYED_CBS;
array<uint> I_SENTRIES_DEPLOYED( g_Engine.maxClients + 1 );

string
    strSentryMdl,
    strDisplayName          = "Sentry",
    strSentryWeapon         = "weapon_pipewrench",
    strAllowedZoneEntity    = "player_sentry_allowed_zone";

int
    iSentryMoveBtn      = IN_USE,
    iSentryDeleteBtn    = IN_RELOAD,
    iSentryAttackRange  = 1200;// This is default, defined by game

uint32 iSentryWeaponAttackType = WPN_TERTIARY_ATTACK;
float flSentryHealthMultiplier = 1.0f;
Vector vecGroundOffset = Vector( 0, 0, 8 );
bool blUseArmourCost = true;

CScheduledFunction@ fnThink, fnInitialise = g_Scheduler.SetTimeout( "Initialise", 0.1f );

void Precache()
{
    g_Game.PrecacheMonster( "monster_sentry", true );

    if( strSentryMdl != "" )
        g_Game.PrecacheModel( strSentryMdl );
}

void Setup(string strModel, string strDisplayNameIn = strDisplayName, int iAttackRange = iSentryAttackRange, float flHealthMultiplier = flSentryHealthMultiplier)
{
    strSentryMdl = strModel;
    strDisplayName = strDisplayNameIn != "" ? strDisplayNameIn : "Sentry";
    iSentryAttackRange = iAttackRange >= 1 ? iAttackRange : 1200;
    flSentryHealthMultiplier = flHealthMultiplier >= 1.0f ? flHealthMultiplier : 1.0f;

    Precache();
}

void Initialise()
{
    switch( iSentryMoveBtn )
    {
        case IN_ATTACK:     break;
        case IN_ATTACK2:    break;
        case IN_RUN:        break;
        case IN_RELOAD:     break;
        case IN_ALT1:       break;

        default:
            iSentryMoveBtn = IN_USE;
            break;
    }

    switch( iSentryDeleteBtn )
    {
        case IN_ATTACK:     break;
        case IN_ATTACK2:    break;
        case IN_RUN:        break;
        case IN_RELOAD:     break;
        case IN_ALT1:       break;
        
        default:
            iSentryMoveBtn = IN_RELOAD;
            break;
    }
    // Crisis averted
    if( iSentryDeleteBtn == iSentryMoveBtn )
        iSentryDeleteBtn = IN_RELOAD;

    if( iSentryWeaponAttackType < 0 || iSentryWeaponAttackType > 2 )
        iSentryWeaponAttackType = WPN_TERTIARY_ATTACK;

    g_Hooks.RegisterHook( Hooks::Player::PlayerUse, PlayerUse );
    g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, PlayerLeave );
    g_Hooks.RegisterHook( iSentryWeaponAttackType, DeploySentryAttack );
    @fnThink = g_Scheduler.SetInterval( "Think", 0.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
}

CBaseMonster@ PlayerSentry(EHandle hPlayer)
{
    if( !hPlayer )
        return null;

    return g_EntityFuncs.Instance( I_SENTRIES_DEPLOYED[hPlayer.GetEntity().entindex()] ).MyMonsterPointer();
}

CBasePlayer@ SentryOwner(EHandle hSentry)
{
    if( !hSentry )
        return null;

    return g_PlayerFuncs.FindPlayerByIndex( I_SENTRIES_DEPLOYED.find( hSentry.GetEntity().entindex() ) );
}
// FX is laggy
void DeployFX(EHandle hPlayer, EHandle hSentry)
{
    if( !hPlayer || !hSentry )
        return;

    CBaseEntity@ pPlayer = hPlayer.GetEntity(), pSentry = hSentry.GetEntity();

    NetworkMessage box( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict() );
        box.WriteByte( TE_BOX );

        box.WriteCoord( pSentry.pev.absmin.x );
        box.WriteCoord( pSentry.pev.absmin.y );
        box.WriteCoord( pSentry.pev.absmin.z );

        box.WriteCoord( pSentry.pev.absmax.x );
        box.WriteCoord( pSentry.pev.absmax.y );
        box.WriteCoord( pSentry.pev.absmin.z );

        box.WriteShort( 8 );

        box.WriteByte( 0 );
        box.WriteByte( 255 );
        box.WriteByte( 0 );
    box.End();

    NetworkMessage line( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict() );
        line.WriteByte( TE_LINE );

        line.WriteCoord( pPlayer.pev.origin.x );
        line.WriteCoord( pPlayer.pev.origin.y );
        line.WriteCoord( pPlayer.pev.origin.z );

        line.WriteCoord( pSentry.pev.origin.x );
        line.WriteCoord( pSentry.pev.origin.y );
        line.WriteCoord( pSentry.pev.origin.z );

        line.WriteShort( 8 );

        line.WriteByte( 0 );
        line.WriteByte( 255 );
        line.WriteByte( 0 );
    line.End();
}

void MoveFX(EHandle hPlayer, EHandle hSentry)
{
    if( !hPlayer || !hSentry )
        return;

    CBaseEntity@ pPlayer = hPlayer.GetEntity(), pSentry = hSentry.GetEntity();

    NetworkMessage box( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict() );
        box.WriteByte( TE_BOX );

        box.WriteCoord( pSentry.pev.absmin.x );
        box.WriteCoord( pSentry.pev.absmin.y );
        box.WriteCoord( pSentry.pev.absmin.z );

        box.WriteCoord( pSentry.pev.absmax.x );
        box.WriteCoord( pSentry.pev.absmax.y );
        box.WriteCoord( pSentry.pev.absmin.z );

        box.WriteShort( 1 );

        box.WriteByte( 255 );
        box.WriteByte( 0 );
        box.WriteByte( 0 );
    box.End();

    NetworkMessage line( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict() );
        line.WriteByte( TE_LINE );

        line.WriteCoord( pPlayer.pev.origin.x );
        line.WriteCoord( pPlayer.pev.origin.y );
        line.WriteCoord( pPlayer.pev.origin.z );

        line.WriteCoord( pSentry.pev.origin.x );
        line.WriteCoord( pSentry.pev.origin.y );
        line.WriteCoord( pSentry.pev.origin.z );

        line.WriteShort( 1 );

        line.WriteByte( 255 );
        line.WriteByte( 0 );
        line.WriteByte( 0 );
    line.End();

    CSprite@ pFakeSentry = g_EntityFuncs.CreateSprite( string( pSentry.pev.model ), pSentry.pev.origin, false, 0.0f );
    pFakeSentry.pev.angles.y = hPlayer.GetEntity().pev.angles.y;
    pFakeSentry.SetTransparency( kRenderTransTexture, 255, 0, 0, 50, 0 );
    pFakeSentry.AnimateAndDie( 50.0f );
}

void RemoveSentry(EHandle hPlayer)
{
    if( !hPlayer )
        return;
        
    hPlayer.GetEntity().GetUserData( "is_carrying_sentry" ) = false;
    g_EntityFuncs.Remove( PlayerSentry( hPlayer ) );
    I_SENTRIES_DEPLOYED[hPlayer.GetEntity().entindex()] = 0;
}

void PickUpSentry(EHandle hPlayer, EHandle hSentry)
{
    if( !hPlayer || !hSentry )
        return;

    CBaseEntity@ pPlayer = hPlayer.GetEntity(), pSentry = hSentry.GetEntity();

    if( pPlayer is null || pSentry is null || !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) )
        return;

    pPlayer.GetUserData( "is_carrying_sentry" ) = true;
    g_EntityFuncs.DispatchKeyValue( pSentry.edict(), "attackrange", "1" );
    pSentry.pev.takedamage = DAMAGE_NO;
    pSentry.pev.effects |= EF_NODRAW;
    @pSentry.pev.owner = pPlayer.edict();
}

void PutDownSentry(EHandle hPlayer, EHandle hSentry)
{
    if( !hPlayer || !hSentry )
        return;

    CBaseEntity@ pPlayer = hPlayer.GetEntity(), pSentry = hSentry.GetEntity();

    if( pPlayer is null || pSentry is null || pSentry.Intersects( pPlayer ) )
        return;

    if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) || !FInAllowedZone( pSentry ) )
        return;

    pPlayer.GetUserData( "is_carrying_sentry" ) = false;
    g_EntityFuncs.DispatchKeyValue( pSentry.edict(), "attackrange", "" + iSentryAttackRange );
    pSentry.pev.angles.y = pPlayer.pev.angles.y;
    pSentry.pev.takedamage = DAMAGE_YES;
    pSentry.pev.effects &= ~EF_NODRAW;
    @pSentry.pev.owner = null;
    // Sentry is placed in a position thats daft
    if( g_EngineFuncs.DropToFloor( pSentry.edict() ) < 0 )
        RemoveSentry( pPlayer );
}

bool FPlayerCarryingSentry(EHandle hPlayer)
{
    return( hPlayer ? bool( hPlayer.GetEntity().GetUserData( "is_carrying_sentry" ) ) : false );
}

bool FInAllowedZone(EHandle hSentry)
{
    if( !hSentry )
        return false;

    CBaseEntity@ pZone;

    while( ( @pZone = g_EntityFuncs.FindEntityByTargetname( pZone, strAllowedZoneEntity ) ) !is null )
    {
        if( pZone is null || !pZone.IsBSPModel() )
            continue;

        if( !hSentry.GetEntity().Intersects( pZone ) )
            return false;
    }

    return true;
}

Vector SetPosition(EHandle hPlayer)
{
    if( !hPlayer )
        return g_vecZero;

    TraceResult trForward, trReflect;
    Math.MakeVectors( hPlayer.GetEntity().pev.v_angle );
    const Vector 
        vecStart = hPlayer.GetEntity().GetOrigin() + hPlayer.GetEntity().pev.view_ofs,
        vecEnd = vecStart + g_Engine.v_forward * 128;
    g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, dont_ignore_glass, hPlayer.GetEntity().edict(), trForward );
    // If a player is carrying their sentry, ensure they don't clip it through a surface
    Vector vecFinalPos;
    if( PlayerSentry( hPlayer ) !is null )
    {
        g_Utility.TraceLine( trForward.vecEndPos, hPlayer.GetEntity().pev.origin, dont_ignore_monsters, dont_ignore_glass, PlayerSentry( hPlayer ).edict(), trReflect );
        vecFinalPos = trReflect.vecEndPos + ( ( trForward.vecEndPos - hPlayer.GetEntity().pev.origin ) * 0.5f );
    }
    else
        vecFinalPos = trForward.vecEndPos;
    // Prevent sentry clipping the floor
    if( vecFinalPos.z < hPlayer.GetEntity().pev.origin.z )
        vecFinalPos = vecFinalPos + vecGroundOffset;

    return vecFinalPos;
}

uint BuildSentry(EHandle hPlayer)
{
    if( !hPlayer )
        return 0;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    if( pPlayer is null || !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) )
        return 0;

    if( blUseArmourCost && pPlayer.pev.armorvalue < 10.0f )
        return 0;

    const Vector vecSentryDeployPos = SetPosition( pPlayer ) != g_vecZero ? SetPosition( pPlayer ) + vecGroundOffset : g_vecZero;

    if( vecSentryDeployPos == g_vecZero )
        return 0;

    CBaseMonster@ pSentry = g_EntityFuncs.Create( "monster_sentry", vecSentryDeployPos, Vector( 0, pPlayer.pev.angles.y, 0 ), true ).MyMonsterPointer();

    if( pSentry is null )
        return 0;
    // !-BUG-!: For a split second after moving a sentry, hudinfo shows the sentry as enemy before correcting itself
    pSentry.SetClassification( CLASS_PLAYER_ALLY );
    pSentry.SetPlayerAllyDirect( true );
    pSentry.pev.spawnflags |= 1 << 5; //Autostart
    g_EntityFuncs.DispatchKeyValue( pSentry.edict(), "ondestroyfn", "PLAYER_SENTRY::SentryDestroyed" );

    if( iSentryAttackRange != 1200 )
        g_EntityFuncs.DispatchKeyValue( pSentry.edict(), "attackrange", "" + iSentryAttackRange );

    if( strSentryMdl != "" )
    {
        pSentry.pev.model = strSentryMdl;
        g_EntityFuncs.SetModel( pSentry, pSentry.pev.model );
    }
    
    if( g_EntityFuncs.DispatchSpawn( pSentry.edict() ) < 0 )
        return 0;

    DeployFX( pPlayer, pSentry );
    // Sentry has to exist in a sensible area
    if( g_EngineFuncs.DropToFloor( pSentry.edict() ) < 0 || pSentry.Intersects( pPlayer ) || !FInAllowedZone( pSentry ) )
    {
        g_EntityFuncs.Remove( pSentry );
        return 0;
    }

    if( blUseArmourCost )
    {
        pSentry.pev.max_health = pSentry.pev.health = pPlayer.pev.armorvalue * ( flSentryHealthMultiplier >= 1.0 ? flSentryHealthMultiplier : 1.0f );
        pPlayer.pev.armorvalue = 0.0f;
    }
    else
        pSentry.pev.max_health = pSentry.pev.health * ( flSentryHealthMultiplier >= 1.0 ? flSentryHealthMultiplier : 1.0f );

    pSentry.m_FormattedName = "" + pPlayer.pev.netname + "'s " + strDisplayName;
    pSentry.pev.targetname = "player_sentry_PID" + pPlayer.entindex() + "_EID" + pSentry.entindex();
    pPlayer.GetUserData()["is_carrying_sentry"] = false;

    g_SoundSystem.EmitSound( pSentry.edict(), CHAN_VOICE, "weapons/mine_deploy.wav", 1.0f, ATTN_NORM );
    g_EntityFuncs.FireTargets( pSentry.pev.targetname, pPlayer, pSentry, USE_ON, 0.0f, 1.0f );
    // SentryBuiltCallback handler
    for( uint i = 0; i < FN_SENTRYBUILT_CBS.length(); i++ )
    {
        if( FN_SENTRYBUILT_CBS[i] is null )
            continue;

        FN_SENTRYBUILT_CBS[i]( pSentry, pPlayer );
    }
    
    return pSentry.entindex();
}

void Think()
{
    for( uint i = 0; i < I_SENTRIES_DEPLOYED.length(); i++ )
    {
        if( I_SENTRIES_DEPLOYED[i] <= 0 )
            continue;

        CBaseMonster@ pSentry = PlayerSentry( g_PlayerFuncs.FindPlayerByIndex( i ) );
        CBasePlayer@ pSentryOwner = pSentry !is null ? SentryOwner( pSentry ) : null;

        if( pSentry is null )
            continue;
        // Get rid of orphaned player sentrys
        if( !pSentry.IsAlive() )
        {
            I_SENTRIES_DEPLOYED[i] = 0;
            continue;
        }
        // !-BUG-!: IsConnected() doesn't work? Have to resort to ClientDisconnected hook
        if( pSentryOwner is null || 
            !pSentryOwner.IsConnected() || 
            pSentry.pev.FlagBitSet( FL_INWATER ) || 
            pSentry.GetOrigin() == g_vecZero )
        {
            RemoveSentry( pSentryOwner );
            continue;
        }

        if( FPlayerCarryingSentry( pSentryOwner ) )
        {
            g_EntityFuncs.SetOrigin( pSentry, SetPosition( pSentryOwner ) );
            MoveFX( pSentryOwner, pSentry );

            if( !pSentryOwner.m_hActiveItem || pSentryOwner.m_hActiveItem.GetEntity().GetClassname() != strSentryWeapon )
            {
                PutDownSentry( pSentryOwner, pSentry );
                continue;
            }

            if( !pSentryOwner.IsAlive() || pSentryOwner.m_afButtonPressed & iSentryDeleteBtn != 0 )
                RemoveSentry( pSentryOwner );
        }
        // SentryThinkCallback handler
        for( uint j = 0; j < FN_SENTRYTHINK_CBS.length(); j++ )
        {
            if( FN_SENTRYTHINK_CBS[j] is null )
                continue;

            FN_SENTRYTHINK_CBS[j]( pSentry );
        }
    }
}

void SentryDestroyed(CBaseEntity@ pEntity)
{
    if( pEntity is null || !pEntity.IsMonster() )
        return;

    CBaseMonster@ pSentry = pEntity.MyMonsterPointer();

    if( pSentry is null )
        return;
    // SentryDestroyedCallback handler
    for( uint i = 0; i < FN_SENTRYDESTROYED_CBS.length(); i++ )
    {
        if( FN_SENTRYDESTROYED_CBS[i] is null )
            continue;

        FN_SENTRYDESTROYED_CBS[i]( pSentry );
    }

    if( I_SENTRIES_DEPLOYED.find( pSentry.entindex() ) >= 0 )
        I_SENTRIES_DEPLOYED[I_SENTRIES_DEPLOYED.find( pSentry.entindex() )] = 0;
}

HookReturnCode DeploySentryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
{
    if( pPlayer is null || pWeapon is null || pWeapon.GetClassname() != strSentryWeapon || PlayerSentry( pPlayer ) !is null )
        return HOOK_CONTINUE;

    if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) )
        return HOOK_CONTINUE;

    I_SENTRIES_DEPLOYED[pPlayer.entindex()] = BuildSentry( pPlayer );

    return HOOK_CONTINUE;
}

HookReturnCode PlayerUse(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer is null || I_SENTRIES_DEPLOYED[pPlayer.entindex()] <= 0 )
        return HOOK_CONTINUE;

    if( !pPlayer.m_hActiveItem || pPlayer.m_hActiveItem.GetEntity().GetClassname() != strSentryWeapon )
        return HOOK_CONTINUE;

    if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) )
        return HOOK_CONTINUE;

    CBaseMonster@ pDeployedSentry = PlayerSentry( pPlayer );

    if( pDeployedSentry is null )
        return HOOK_CONTINUE;

    if( pPlayer.m_afButtonPressed & iSentryMoveBtn != 0 )
    {
        if( !FPlayerCarryingSentry( pPlayer ) )
        {
            if( g_Utility.FindEntityForward( pPlayer, 64.0f ) is pDeployedSentry && SentryOwner( pDeployedSentry ) is pPlayer )
            {
                PickUpSentry( pPlayer, pDeployedSentry );
                return HOOK_CONTINUE;
            }
        }
        else
            PutDownSentry( pPlayer, pDeployedSentry ); 
    }

    return HOOK_CONTINUE;
}

HookReturnCode PlayerLeave(CBasePlayer@ pPlayer)
{
    if( pPlayer is null )
        return HOOK_CONTINUE;

    RemoveSentry( pPlayer );

    return HOOK_CONTINUE;
}

void Disable(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    for( uint i = 0; i < I_SENTRIES_DEPLOYED.length(); i++ )
        RemoveSentry( g_PlayerFuncs.FindPlayerByIndex( i ) );

    I_SENTRIES_DEPLOYED = array<uint>( g_Engine.maxClients + 1, 0 );

    g_Hooks.RemoveHook( Hooks::Player::PlayerUse, PlayerUse );
    g_Hooks.RemoveHook( Hooks::Player::ClientDisconnect, PlayerLeave );
    g_Hooks.RemoveHook( iSentryWeaponAttackType, DeploySentryAttack );

    if( fnThink !is null )
        g_Scheduler.RemoveTimer( fnThink );
}
// Funcs for configuring optional callbacks
bool SetSentryBuiltCallback(SentryBuiltCallback@ fn)
{
    if( fn is null )
        return false;

    if( FN_SENTRYBUILT_CBS.findByRef( fn ) >= 0 )
        return true;

    FN_SENTRYBUILT_CBS.insertLast( fn );

    return( FN_SENTRYBUILT_CBS.findByRef( fn ) >= 0 );
}

bool SetSentryThinkCallback(SentryThinkCallback@ fn)
{
    if( fn is null )
        return false;

    if( FN_SENTRYTHINK_CBS.findByRef( fn ) >= 0 )
        return true;

    FN_SENTRYTHINK_CBS.insertLast( fn );

    return( FN_SENTRYTHINK_CBS.findByRef( fn ) >= 0 );
}

bool SetSentryDestroyedCallback(SentryDestroyedCallback@ fn)
{
    if( fn is null )
        return false;

    if( FN_SENTRYDESTROYED_CBS.findByRef( fn ) >= 0 )
        return true;

    FN_SENTRYDESTROYED_CBS.insertLast( fn );

    return( FN_SENTRYDESTROYED_CBS.findByRef( fn ) >= 0 );
}

void RemoveSentryBuiltCallback(SentryBuiltCallback@ fn)
{
    if( fn !is null && FN_SENTRYBUILT_CBS.findByRef( fn ) >= 0 )
        FN_SENTRYBUILT_CBS.removeAt( FN_SENTRYBUILT_CBS.findByRef( fn ) );
}

void RemoveSentryThinkCallback(SentryThinkCallback@ fn)
{
    if( fn !is null && FN_SENTRYTHINK_CBS.findByRef( fn ) >= 0 )
        FN_SENTRYTHINK_CBS.removeAt( FN_SENTRYTHINK_CBS.findByRef( fn ) );
}

void RemoveSentryDestroyedCallback(SentryDestroyedCallback@ fn)
{
    if( fn !is null && FN_SENTRYDESTROYED_CBS.findByRef( fn ) >= 0 )
        FN_SENTRYDESTROYED_CBS.removeAt( FN_SENTRYDESTROYED_CBS.findByRef( fn ) );
}

}
/*
Special thanks to:
-H2, for continued support with scripting
-AlexCorruptor, for testing
*/