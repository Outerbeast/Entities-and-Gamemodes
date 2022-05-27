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
You must precache the sentry by calling "PLAYER_SENTRY::Precache()" in MapInit in your main map script. Alernatively, place a monster_sentry in your map - hide it somewhere or killtarget it if you don't intend it to be part of the level.

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
- PLAYER_SENTRY::strSentryWeapon: name of the weapon used to spawn the sentry. It can be a custom weapon
- PLAYER_SENTRY::iSentryWeaponAttackType: select which weapon attack is used to spawn the sentry, either Primary (2), Secondary (1) or Tertiary attack (0, default)
- PLAYER_SENTRY::iSentryMoveBtn/iSentryDeleteBtn: chose which button picks up/puts down and deletes the sentry. See In_Buttons enum for choices https://baso88.github.io/SC_AngelScript/docs/In_Buttons.htm
- PLAYER_SENTRY::iSentryAttackRange: set a custom attack range for the sentry
Any conflicting settings will cause the defaults to be used instead.
*/
namespace PLAYER_SENTRY
{

array<uint> I_SENTRIES_DEPLOYED( g_Engine.maxClients + 1 );

enum sentrydeployweaponattack
{
    WPN_TERTIARY_ATTACK = 0,
    WPN_SECONDARY_ATTACK,
    WPN_PRIMARY_ATTACK
};

string strSentryWeapon          = "weapon_pipewrench";
string strAllowedZoneEntity     = "player_sentry_allowed_zone";
uint32 iSentryWeaponAttackType  = WPN_TERTIARY_ATTACK;
int iSentryMoveBtn              = IN_USE;
int iSentryDeleteBtn            = IN_RELOAD;
int iSentryAttackRange          = 1200;// This is default, defined by game
Vector vecGroundOffset          = Vector( 0, 0, 8 );

CScheduledFunction@ fnInitialise = g_Scheduler.SetTimeout( "Initialise", 0.0f );

void Precache()
{
    g_Game.PrecacheMonster( "monster_sentry", true );
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
    g_Scheduler.SetInterval( "Think", 0.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
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
    g_EntityFuncs.DispatchKeyValue( hPlayer.GetEntity().edict(), "$i_carryingsentry", "0" );
    g_EntityFuncs.Remove( PlayerSentry( hPlayer ) );
    I_SENTRIES_DEPLOYED[hPlayer.GetEntity().entindex()] = 0;
}

void PickUpSentry(CBasePlayer@ pPlayer, CBaseMonster@ pSentry)
{
    if( pPlayer is null || pSentry is null )
        return;

    if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) )
        return;

    g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_carryingsentry", "1" );
    g_EntityFuncs.DispatchKeyValue( pSentry.edict(), "attackrange", "1" );
    pSentry.pev.takedamage = DAMAGE_NO;
    pSentry.pev.effects |= EF_NODRAW;
    @pSentry.pev.owner = pPlayer.edict();
}

void PutDownSentry(CBasePlayer@ pPlayer, CBaseMonster@ pSentry)
{
    if( pPlayer is null || pSentry is null || pSentry.Intersects( pPlayer ) )
        return;

    if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) || !FInAllowedZone( pSentry ) )
        return;

    g_EntityFuncs.DispatchKeyValue( pPlayer.edict(), "$i_carryingsentry", "0" );
    g_EntityFuncs.DispatchKeyValue( pSentry.edict(), "attackrange", "" + iSentryAttackRange );
    pSentry.pev.angles.y = pPlayer.pev.angles.y;
    pSentry.pev.takedamage = DAMAGE_YES;
    pSentry.pev.effects &= ~EF_NODRAW;
    @pSentry.pev.owner = null;
    // Sentry is placed in a position thats daft
    if( g_EngineFuncs.DropToFloor( pSentry.edict() ) == -1 )
        RemoveSentry( pPlayer );
}

bool FPlayerCarryingSentry(EHandle hPlayer)
{
    if( !hPlayer )
        return false;

    CustomKeyvalues@ kvPlayer = hPlayer.GetEntity().GetCustomKeyvalues();

    if( kvPlayer is null || !kvPlayer.HasKeyvalue( "$i_carryingsentry" ) )
        return false;

    return kvPlayer.GetKeyvalue( "$i_carryingsentry" ).GetInteger() > 0;
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

    TraceResult trSentry, trReflect;

    Math.MakeVectors( hPlayer.GetEntity().pev.v_angle );
    const Vector vecStart = hPlayer.GetEntity().GetOrigin() + hPlayer.GetEntity().pev.view_ofs;
    const Vector vecEnd = vecStart + g_Engine.v_forward * 128;
    g_Utility.TraceLine( vecStart, vecEnd, ignore_monsters, dont_ignore_glass, hPlayer.GetEntity().edict(), trSentry );
    // If a player is carrying their sentry, ensure they don't clip it through a surface
    Vector vecFinalPos;
    if( PlayerSentry( hPlayer ) !is null )
    {
        g_Utility.TraceLine( trSentry.vecEndPos, hPlayer.GetEntity().pev.origin, dont_ignore_monsters, dont_ignore_glass, PlayerSentry( hPlayer ).edict(), trReflect );
        vecFinalPos = trReflect.vecEndPos + ( ( trSentry.vecEndPos - hPlayer.GetEntity().pev.origin ) * 0.5f );
    }
    else
        vecFinalPos = trSentry.vecEndPos;
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

    if( pPlayer is null || pPlayer.pev.armorvalue < 10.0f || !pPlayer.pev.FlagBitSet( FL_ONGROUND ) || pPlayer.pev.FlagBitSet( FL_INWATER ) )
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
    pSentry.pev.spawnflags |= 32; //Autostart

    if( iSentryAttackRange != 1200 )
        g_EntityFuncs.DispatchKeyValue( pSentry.edict(), "attackrange", "" + iSentryAttackRange );
    
    if( g_EntityFuncs.DispatchSpawn( pSentry.edict() ) == -1 )
        return 0;

    DeployFX( pPlayer, pSentry );
    
    if( g_EngineFuncs.DropToFloor( pSentry.edict() ) == -1 )
    {
        g_EntityFuncs.Remove( pSentry );
        return 0;
    }

    if( pSentry.Intersects( pPlayer ) || !FInAllowedZone( pSentry ) )
    {
        g_EntityFuncs.Remove( pSentry );
        return 0;
    }

    pSentry.pev.max_health = pSentry.pev.health = pPlayer.pev.armorvalue;
    pPlayer.pev.armorvalue = 0.0f;
    pSentry.m_FormattedName = "" + pPlayer.pev.netname + "'s Sentry";
    pSentry.pev.targetname = "player_sentry_PID" + pPlayer.entindex() + "_EID" + pSentry.entindex();
    g_EntityFuncs.FireTargets( pSentry.pev.targetname, pPlayer, pSentry, USE_ON, 0.0f, 1.0f );
    
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
    }
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

}
/*
Special thanks to:
-H2, for continued support with scripting
-AlexCorruptor, for testing
*/