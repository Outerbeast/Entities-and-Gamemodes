/*  M16 Full Auto firing mode
    Adds a fully automatic firing mode for the stock weapon_m16
    
    Installation:-
	- Place in scripts/maps
	- Add
	map_script m16_fullauto
	to your map cfg
	OR
	- Add
	#include "m16_fullauto"
	to your main map script header
	OR
	- Create a trigger_script with these keys set in your map:
	"classname" "trigger_script"
	"m_iszScriptFile" "m16_fullauto"

    Usage:
    Equip the M16 and use Primary fire button to shoot the m16 in a fully automatic firing mode. The firing mode can be switched back to the original stock burst mode and vice versa using Tertiary Fire button.
    The default firemodes can be changed to so change what the intitial fire mode is this CVar:
    "as_command m16_firemode"
    Choices:
    - 1: Select Fire Burst: The primary fire can be switched from burst to auto using tertiary fire button
    - 2: Select Fire Auto: The primary fire is full auto and can be switched back to stock burst using tertiary fire button. This is default if CVar is not set
    - 3: Primary fire button, replaces the stock burst fire for full auto entirely

    Issues:
    - Full auto damage is less than stock burst due to an API bug
    - Switching from full auto to burst may a side effect where the gun does not immediately start shooting if the button is pressed
- Outerbeast
*/
namespace M16_FULLAUTO
{

enum FireMode
{
    MODE_NONE,
    MODE_SELECT_FIRE_BURST,
    MODE_SELECT_FIRE_AUTO,
    MODE_PRIMARY_FIRE_ONLY// This overrides primary burst fire
};

array<FireMode> FM_PLAYER;

int 
    iDefaultFireMode, 
    iDmgCustom;

const int
    iShellMdl = Precache(),
    iDmgDefault = int( g_EngineFuncs.CVarGetFloat( "sk_556_bullet" ) );

float flShootDelay = 0.1f;

const float
    flDuration_Reload       = 3.4f,
    flDuration_GrenadeFire  = 1.0f,
    flDuration_GrenadeLoad  = 1.5f;

bool blInitialised;
CCVar cvarFireMode( "m16_firemode", float( MODE_SELECT_FIRE_AUTO ), "Select M16 firing mode", ConCommandFlag::AdminOnly );
CScheduledFunction@ fnSetup = g_Scheduler.SetTimeout( "Setup", 1.0f );

int Precache()
{
    g_SoundSystem.PrecacheSound( "weapons/m16_3single.wav" );
    return g_Game.PrecacheModel( "models/shell.mdl" );
}

void Setup()
{
    if( blInitialised )
        return;

    if( iDefaultFireMode <= MODE_NONE )
        iDefaultFireMode = cvarFireMode.GetInt();

    switch( iDefaultFireMode )
    {
        case MODE_PRIMARY_FIRE_ONLY:
            break;

        case MODE_SELECT_FIRE_BURST:
        case MODE_SELECT_FIRE_AUTO:
        {
            g_Hooks.RegisterHook( Hooks::Weapon::WeaponTertiaryAttack, M16TertiaryAttack );
            g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, ClearFireModeSelection );
            g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, ClearFireModeSelection );
            
            break;
        }

        default:
        {
            iDefaultFireMode = MODE_SELECT_FIRE_AUTO;
            g_Hooks.RegisterHook( Hooks::Weapon::WeaponTertiaryAttack, M16TertiaryAttack );
            g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, ClearFireModeSelection );
            g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, ClearFireModeSelection );
        }
    }

    FM_PLAYER = array<FireMode>( g_Engine.maxClients + 1, FireMode( iDefaultFireMode ) );
   
    blInitialised = g_Hooks.RegisterHook( Hooks::Player::PlayerUse, PlayerUseM16 ) && 
                    g_Hooks.RegisterHook( Hooks::Weapon::WeaponSecondaryAttack, M16SecondaryAttack );
}

CBasePlayerWeapon@ GetM16(EHandle hPlayer)
{
    if( !hPlayer )
        return null;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    if( pPlayer is null || !pPlayer.m_hActiveItem || pPlayer.m_hActiveItem.GetEntity().GetClassname() != "weapon_m16" )
        return null;

    return cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );
}

void SelectFireMode(EHandle hPlayer)
{
    if( !hPlayer || GetM16( hPlayer ) is null )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    if( pPlayer is null || float( pPlayer.GetUserData( "fire_select_timeout" ) ) > 0.0f )
        return;

    switch( FM_PLAYER[pPlayer.entindex()] )
    {
        case MODE_SELECT_FIRE_AUTO:
        {
            FM_PLAYER[pPlayer.entindex()] = MODE_SELECT_FIRE_BURST;
            g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Switched to fire mode: Burst" );

            break;
        }

        case MODE_SELECT_FIRE_BURST:
        {
            FM_PLAYER[pPlayer.entindex()] = MODE_SELECT_FIRE_AUTO;
            GetM16( hPlayer ).m_flNextPrimaryAttack = 2;
            g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Switched to fire mode: Auto" );

            break;
        }
    }

    pPlayer.GetUserData()["fire_select_timeout"] = 2.0f;
    g_Scheduler.SetTimeout( "FireSelectReset", float( pPlayer.GetUserData( "fire_select_timeout" ) ), EHandle( pPlayer ) );
}

void FireSelectReset(EHandle hPlayer)
{
    if( !hPlayer )
        return;

    hPlayer.GetEntity().GetUserData( "fire_select_timeout" ) = 0.0f;
}

bool FCantFire(EHandle hM16, int iSetState = -1)
{
    if( !hM16 )
        return false;

    if( iSetState > -1 )
        hM16.GetEntity().GetUserData( "cant_fire" ) = iSetState;

    return int( hM16.GetEntity().GetUserData( "cant_fire" ) ) > 0;
}

void Shoot(EHandle hM16)
{
    if( !hM16 )
        return;

    CBasePlayerWeapon@ pM16 = cast<CBasePlayerWeapon@>( hM16.GetEntity() );
    CBasePlayer@ pPlayer = pM16 !is null ? cast<CBasePlayer@>( pM16.m_hPlayer.GetEntity() ) : null;

    if( pM16 is null || pPlayer is null || pM16.m_fInReload )
        return;

    if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD || pM16.m_iClip <= 0 )
    {
        pM16.PlayEmptySound();
        pPlayer.m_flNextAttack = flShootDelay;
        FCantFire( hM16, 1 );
        SetNextShoot( hM16, flShootDelay );

        return;
    }

    pM16.SendWeaponAnim( g_PlayerFuncs.SharedRandomLong( pPlayer.random_seed, 0, 1 ) < 1 ? 4 : 5, 0, 0 );
    pPlayer.SetAnimation( PLAYER_ATTACK1 );
    pPlayer.pev.punchangle.x = Math.RandomLong( -1, 1 );

    Vector
        vecSrc = pPlayer.GetGunPosition(),
        vecAiming = pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ),
        vecAccuracy = pM16.BulletAccuracy( VECTOR_CONE_6DEGREES, VECTOR_CONE_4DEGREES, VECTOR_CONE_3DEGREES ),
        vecDir, vecEnd;
    // !-BUG-!: "BULLET_PLAYER_SAW", which stock M16 fire uses, causes gibbing,
    // - FireBullets method does not obey npc damage modifiers
    pPlayer.FireBullets( 1, vecSrc, vecAiming, vecAccuracy, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, iDmgCustom > 0 ? iDmgCustom : iDmgDefault );
    g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_WEAPON, "weapons/m16_3single.wav", 0.75f, ATTN_NORM, 0, PITCH_HIGH + 20 );
    MuzzleFlash( pM16.m_hPlayer );
    EjectCasing( hM16 );

    if( --pM16.m_iClip <= 0 && pPlayer.m_rgAmmo( pM16.m_iPrimaryAmmoType ) <= 0 )
        pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
    // Bullet hole decals
    TraceResult trBullet;
    float spread_x, spread_y;
    g_Utility.GetCircularGaussianSpread( spread_x, spread_y );
    vecDir = vecAiming + spread_x * vecAccuracy.x * g_Engine.v_right + spread_y * vecAccuracy.y * g_Engine.v_up;
    vecEnd = vecSrc + vecDir * 4096;
    g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), trBullet );

    if( trBullet.flFraction < 1.0f )
    {
        CBaseEntity@ pHit = g_EntityFuncs.Instance( trBullet.pHit );
        
        if( pHit is null || pHit.IsBSPModel() )
            g_WeaponFuncs.DecalGunshot( trBullet, BULLET_PLAYER_SAW );
    }

    pPlayer.m_flNextAttack = flShootDelay;
}

void MuzzleFlash(EHandle hPlayer)
{
    if( !hPlayer )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
    pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
    pPlayer.pev.effects |= EF_MUZZLEFLASH;//!-BUG-!: using EF_MUZZLEFLASH doesn't work, forced replicate it via temporary fx
    // This will have to do
    Vector vecFlashPos = pPlayer.GetGunPosition() + g_Engine.v_forward * 59;// extra bit to align it perfectly with gun muzzle
    vecFlashPos.z = pPlayer.pev.origin.z - ( pPlayer.pev.FlagBitSet( FL_DUCKING ) ? 18 : 36 );

    NetworkMessage flash( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecFlashPos );
        flash.WriteByte( TE_DLIGHT );

        flash.WriteCoord( vecFlashPos.x );
        flash.WriteCoord( vecFlashPos.y );
        flash.WriteCoord( vecFlashPos.z );

        flash.WriteByte( 8 );
        flash.WriteByte( 255 );
        flash.WriteByte( 200 );
        flash.WriteByte( 180 );
        flash.WriteByte( 1 );
        flash.WriteByte( 0 );
    flash.End();
}
// Code from https://github.com/KernCore91/-SC-Insurgency-Weapons-Project/blob/master/scripts/maps/ins2/base.as#L462C2-L477 - thanks KernCore :>
void EjectCasing(EHandle hM16)
{
    if( !hM16 )
        return;

    CBasePlayerWeapon@ pM16 = cast<CBasePlayerWeapon@>( hM16.GetEntity() );
    CBasePlayer@ pPlayer = pM16 !is null ? cast<CBasePlayer@>( pM16.m_hPlayer.GetEntity() ) : null;

    if( pM16 is null || pPlayer is null )
        return;

    Vector vecForward, vecRight, vecUp, vecShellVelocity, vecShellStart;
    g_EngineFuncs.AngleVectors( pPlayer.pev.v_angle, vecForward, vecRight, vecUp );
    // Values tweaked to approximate default M16 case ejection pattern
    const float
        fF = Math.RandomFloat( 50, 150 ),
        fR = Math.RandomFloat( 60, 120 ),
        fU = Math.RandomFloat( 90, 150 ),
        forwardScale = 26.0f,
        rightScale = 16.0f,
        upScale = -15.0f;

    for( int i = 0; i < 3; i++ )
    {
        vecShellVelocity[i] = pPlayer.pev.velocity[i] + vecRight[i] * fR + vecUp[i] * fU + vecForward[i] * fF;
        vecShellStart[i] = pPlayer.pev.origin[i] + pPlayer.pev.view_ofs[i] + vecUp[i] * upScale + vecForward[i] * forwardScale + vecRight[i] * rightScale;
    }

    vecShellVelocity.y *= 1.0f;
    vecShellVelocity.z *= 1.4f;
    g_EntityFuncs.EjectBrass( vecShellStart, vecShellVelocity, pM16.pev.angles.y, iShellMdl, TE_BOUNCE_SHELL );
}

bool AutoReload(EHandle hM16)
{
    if( !hM16 )
        return false;

    CBasePlayerWeapon@ pM16 = cast<CBasePlayerWeapon@>( hM16.GetEntity() );
    CBasePlayer@ pPlayer = pM16 !is null ? cast<CBasePlayer@>( pM16.m_hPlayer.GetEntity() ) : null;
    pM16.DefaultReload( pM16.iMaxClip(), 6/* RELOAD*/, flDuration_Reload, 0 );

    if( pPlayer !is null )
        pPlayer.SetAnimation( PLAYER_RELOAD );

    return pM16.m_iClip == pM16.iMaxClip();
}

void SetNextShoot(EHandle hM16, float flDelay)
{
    if( !hM16 )
        return;
    
    if( flDelay > 0.0f )
    {
        FCantFire( hM16, 1 );
        g_Scheduler.SetTimeout( "SetNextShoot", flDelay, hM16, 0.0f );
    }
    else
        FCantFire( hM16, 0 );
}

HookReturnCode PlayerUseM16(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer is null || GetM16( pPlayer ) is null || FM_PLAYER[pPlayer.entindex()] == MODE_SELECT_FIRE_BURST )
        return HOOK_CONTINUE;

    CBasePlayerWeapon@ pM16 = GetM16( pPlayer );
    pM16.m_flNextPrimaryAttack = 2.0f;

    if( FCantFire( pM16 ) || pM16.m_fInReload )
        return HOOK_CONTINUE;

    if( pPlayer.pev.button & IN_ATTACK != 0 )
    {
        if( pM16.m_iClip > 0 )
        {
            FCantFire( pM16, 1 );
            Shoot( pM16 );
            SetNextShoot( pM16, flShootDelay );
        }
        else// reloads immediately, not when the moment the fire button is released while held down
            AutoReload( pM16 );
    }

    return HOOK_CONTINUE;
}

HookReturnCode M16SecondaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pM16)
{
    if( pPlayer is null || pM16 is null || pM16.m_iId != WEAPON_M16 )
        return HOOK_CONTINUE;

    if( FM_PLAYER[pPlayer.entindex()] <= MODE_SELECT_FIRE_BURST || FCantFire( pM16 ) )
        return HOOK_CONTINUE;
    // !-BUG-!: as soon as the the grenade clip is 1 the weapon it shootable, ie before the grenade load animation completes!
    FCantFire( pM16, 1 );
    SetNextShoot( pM16, pM16.m_iClip2 > 0 ? flDuration_GrenadeFire : flDuration_GrenadeLoad );

    return HOOK_CONTINUE;
}

HookReturnCode M16TertiaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pM16)
{
    if( pPlayer is null || pM16 is null || pM16.m_iId != WEAPON_M16 )
        return HOOK_CONTINUE;

    if( iDefaultFireMode >= MODE_SELECT_FIRE_BURST )
        SelectFireMode( pPlayer );

    return HOOK_CONTINUE;
}

HookReturnCode ClearFireModeSelection(CBasePlayer@ pPlayer)
{
    if( pPlayer is null || FM_PLAYER.length() < 1 )
        return HOOK_CONTINUE;

    FM_PLAYER[pPlayer.entindex()] = FireMode( iDefaultFireMode );

    return HOOK_CONTINUE;
}

}
/* Special thanks to:-
- KernCore, for scripting support
- SV BOY for testing
*/