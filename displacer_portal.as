/* Displacer Portal
    by Outerbeast
    extension for weapon_displacer to create a portal to teleport other entities

    Installation:-
    - Place the script file into scripts/maps
    - Load the script with any of the methods below
    Add this cvar in your map cfg
    map_script displacer_portal
    OR
    Load this script via trigger_script entity in your map
    "classname" "trigger_script"
    "m_iszScriptFile" "displacer_portal"
    OR
    Add this in your map script header
    #include "displacer_portal"

    Using the trigger_script method will allow you to customise certain things from your map

    Usage:-
    Use the Displacer's tertiary attack to shoot a portal at the target entity you want to teleport. They will teleport to any entity named "displacer_global_target", the same as displacer 2ndary target
    Recommended using info_player_destination since that will allow you to trigger a target on arrival, with the teleported entity as the activator.
    By default it requires 60 ammo to shoot a portal, same as displacer 2ndary attack ammo requirement
    The portal will not do damage to enemies.*
    The certain npcs are blacklisted from teleporting, see STR_NPC_BLACKLIST below.

    -How to customise-
    The trigger_script has some keys for customisation. If you want to enable use of these, add these keyvalues to your trigger_script, then check flag 1:
    "m_iMode" "2"
    "m_iszScriptFunctionName" "DISPLACER_PORTAL::Think"
    "targetname" "displacer_portal_ts"
    Keys and flags should now be available for use.
    Keys:
    "message" "target_entity"       - Sets a custom destination entity name (default is "displacer_global_target"). You can choose this trigger_script as a destination. 
    "netname" "targetname_filter"   - Only entities named this will be teleported, rest is ignored. Warning: if the target entity is not included in one of the flags then its also ignored.
    "impulse" "i"                   - Custom displacer ammo amount to shoot the displacer portal
    "spawnflags" "f"                - See flags below
    FLags:
    "1": Start on
    "2": Teleport once      - Each target can only be teleported one time. After being teleported they will no longer be able to be teleported. You can changevalue the monster's "$i_displacer_tp_count" key to 0 to reset this.
    "4": Teleport Enemies   - Hostile npcs can be teleported (Monsters flag must be set first)
    "8": Players            - Players can be teleported
    "32": Monsters          - Monsters can be teleported

    Extra: setting the custom keyvalue "$i_displacer_tp_count" "-1" on any entity will prevent them being teleported no matter what

    Known Issues:-
    - *Entities still receive damage from the portal even if its 0, this can lead to strange behaviour like ally npcs becoming hostile, if mp_npckill is set 1. This is a game bug. Please set mp_npckill to 2.
    - The viewmodel animations are missing beam fx for the flaps, this can't be recreated with the API (these are client-side fx not exposed)
*/
namespace DISPLACER_PORTAL
{

enum displacerportalflags
{
    START_ON            = 1 << 0,
    DP_TELEPORT_ONCE    = 1 << 1,
    DP_TELEPORT_ENEMIES = 1 << 2
};

string 
    strDisplacerPortalDestName = "displacer_global_target", // Same as 2ndary fire default teleport destination
    strTeleportNameFilter;
    
int iDisplacerPortalAmmoCost = 60; // Same as displacer 2ndary fire cost
bool 
    blTpPlayers = true, 
    blTpMonsters = true,
    blTpEnemies = false, 
    blTeleportOnce = false;
// We shouldn't be teleporting these guys
const array<string> STR_NPC_BLACKLIST = 
{
    "monster_furniture",            // not a monster
    "monster_tentacle",
    "monster_gman",
    "monster_turret",               // treated as fixed to the world
    "monster_miniturret"            // treated as fixed to the world
    "monster_sitting_scientist",    // treated as part of scenery
    "monster_handgrenade",          // these aren't real monsters
    "monster_tripmine",             // these aren't real monsters
    "monster_apache",
    "monster_osprey",
    "monster_blkop_apache",
    "monster_blkop_osprey",
    "monstermaker",
    "squadmaker"
};

const bool blWeaponTertiaryAttack = g_Hooks.RegisterHook( Hooks::Weapon::WeaponTertiaryAttack, DisplacerTertiaryAttack );
CScheduledFunction@ fnThink = g_Scheduler.SetInterval( "Think", 0.0f, g_Scheduler.REPEAT_INFINITE_TIMES, cast<CBaseEntity@>( null ) );

bool FCantFire(EHandle hDisplacer, int iSetState = -1)
{
    if( !hDisplacer )
        return false;

    if( iSetState > -1 )
        hDisplacer.GetEntity().GetUserData( "cant_fire" ) = iSetState;

    return int( hDisplacer.GetEntity().GetUserData( "cant_fire" ) ) > 0;
}

int TeleportCount(EHandle hTarget, int iSetState = -1)
{
    if( !hTarget )
        return 0;

    if( iSetState > -1 )
        hTarget.GetEntity().GetUserData( "displacer_tp_count" ) = iSetState;
    
    return int( hTarget.GetEntity().GetUserData( "displacer_tp_count" ) );
}

void SetNextShoot(EHandle hDisplacer, float flDelay)
{
    if( !hDisplacer || !FCantFire( hDisplacer ) )
        return;
    
    if( flDelay > 0.0f )
        g_Scheduler.SetTimeout( "SetNextShoot", flDelay, hDisplacer, 0.0f );
    else
        FCantFire( hDisplacer, 0 );
}

void DryShoot(EHandle hPlayer, EHandle hDisplacer)
{
    if( !hPlayer || !hDisplacer )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( hDisplacer.GetEntity() );

    //g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_WEAPON, "buttons/button11.wav", Math.RandomFloat( 0.8f, 0.9f ), ATTN_NORM );
    pWeapon.PlayEmptySound();
    FCantFire( pWeapon, 1 );
    SetNextShoot( pWeapon, 0.5f );
}

void SpinUp(EHandle hPlayer, EHandle hDisplacer)
{
    if( !hPlayer || !hDisplacer )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( hDisplacer.GetEntity() );

    FCantFire( hDisplacer, 1 );
    pWeapon.SendWeaponAnim( 2 );// DISPLACER_SPINUP
    g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_WEAPON, "weapons/displacer_spin2.wav", Math.RandomFloat( 0.8f, 0.9f ), ATTN_NORM );
    pWeapon.m_flTimeWeaponIdle = g_Engine.time + 1.5f;

    g_Scheduler.SetTimeout( "ShootPortal", 0.9f, hPlayer, hDisplacer );
}

void ShootPortal(EHandle hPlayer, EHandle hDisplacer)
{
    if( !hPlayer || !hDisplacer )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( hDisplacer.GetEntity() );

    if( pPlayer is null || pWeapon is null )
        return;
    
    Vector
        vecStart = pPlayer.GetGunPosition(),
        vecAim = pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

    CBaseEntity@ pPortal = g_EntityFuncs.CreateDisplacerPortal( vecStart, vecAim * 500, pPlayer.edict(), 0.0f, 0.0f );
    pPortal.pev.netname = "" + pPortal.GetClassname() + "_" + pWeapon.entindex();

    g_SoundSystem.StopSound( pPlayer.edict(), CHAN_WEAPON, "weapons/displacer_spin2.wav" );
    g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_WEAPON, "weapons/displacer_fire.wav", Math.RandomFloat( 0.8f, 0.9f ), ATTN_NORM );
    // I don't know if this works, I'm not noticing anything
    pPlayer.pev.effects |= EF_MUZZLEFLASH;
    pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
    pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
    // DISPLACER_FIRE
    pWeapon.SendWeaponAnim( 4 );
    pWeapon.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
    // All this rubbish just to subtract ammo from the player wtf
    if( iDisplacerPortalAmmoCost > 0 )
        pPlayer.m_rgAmmo( pWeapon.m_iPrimaryAmmoType, pPlayer.m_rgAmmo( pWeapon.m_iPrimaryAmmoType ) - iDisplacerPortalAmmoCost );

    FCantFire( hDisplacer, 0 );
}

bool PortalExit(EHandle hTarget)
{
    if( !hTarget )
        return false;

    CBaseEntity@
        pPortalExit = g_EntityFuncs.RandomTargetname( strDisplacerPortalDestName != "" ? strDisplacerPortalDestName : "displacer_global_target" ), 
        pTarget = hTarget.GetEntity();

    if( pPortalExit is null || pTarget is null )
        return false;
    // Adjust for player/monster origin points
    Vector vecDest = pPortalExit.pev.origin + Vector( 0, 0, pTarget.IsPlayer() ? 36 : 0 );
    g_EntityFuncs.SetOrigin( pTarget, vecDest );
    pTarget.pev.angles = pPortalExit.pev.angles;
    pTarget.pev.velocity = g_vecZero;
    // Exit sprite
    CSprite@ pSprite = g_EntityFuncs.CreateSprite( "sprites/exit1.spr", !pTarget.IsPlayer() ? vecDest + Vector( 0, 0, 36 ) : vecDest, true, 0.0f );
    pSprite.SetScale( 0.75f );
    pSprite.SetTransparency( kRenderTransAdd, 0, 0, 0, 255, kRenderFxNoDissipation );
    pSprite.AnimateAndDie( 18 );
    g_SoundSystem.EmitSound( pSprite.edict(), CHAN_ITEM, "weapons/displacer_self.wav", 1.0f, ATTN_NORM );
    TeleportCount( hTarget, TeleportCount( hTarget ) + 1 );

    if( pPortalExit.GetClassname() == "info_teleport_destination" && pPortalExit.pev.SpawnFlagBitSet( 32 ) )
        pPortalExit.SUB_UseTargets( pTarget, USE_ON, 0.0f );

    return pTarget.pev.origin == pPortalExit.pev.origin;
}

void Think(CBaseEntity@ pTriggerScript)
{
    if( pTriggerScript !is null )
    {
        if( fnThink !is null )
        {
            g_Scheduler.RemoveTimer( fnThink );
            @fnThink = null;
        }
        // Get values from the entity
        if( pTriggerScript.pev.message != "" && pTriggerScript.pev.message != "displacer_global_target" )
            strDisplacerPortalDestName = pTriggerScript.pev.message;

        if( pTriggerScript.pev.netname != "" )
            strTeleportNameFilter = pTriggerScript.pev.netname;

        if( pTriggerScript.pev.impulse > 0 && pTriggerScript.pev.impulse != 60 )
            iDisplacerPortalAmmoCost = pTriggerScript.pev.impulse;

        blTeleportOnce = pTriggerScript.pev.SpawnFlagBitSet( DP_TELEPORT_ONCE );
        blTpEnemies = pTriggerScript.pev.SpawnFlagBitSet( DP_TELEPORT_ENEMIES );
        blTpPlayers = pTriggerScript.pev.SpawnFlagBitSet( FL_CLIENT );
        blTpMonsters = pTriggerScript.pev.SpawnFlagBitSet( FL_MONSTER );
    }
    // Revert to defaults if no flags are set
    if( !blTpEnemies && !blTpPlayers && !blTpMonsters )
        blTpPlayers = blTpMonsters = true;

    CBaseEntity@ pPortal;
    array<CBaseEntity@> P_TARGET( 1 );
    
    while( ( @pPortal = g_EntityFuncs.FindEntityByString( pPortal, "netname", "displacer_portal_*" ) ) !is null )
    {
        if( pPortal is null || pPortal.GetClassname() != "displacer_portal" )// In case some cheeky mapper decides to be a wiseguy
            continue;
        // FindEntityInSphere doesn't work here - needs a pStartEntity that I don't have
        if( g_EntityFuncs.MonstersInSphere( @P_TARGET, pPortal.pev.origin, 32.0f ) < 1 )
            continue;

        if( P_TARGET[0] is null || pPortal.pev.owner is P_TARGET[0].edict() )
            continue;

        if( STR_NPC_BLACKLIST.find( P_TARGET[0].GetClassname() ) >= 0 )
            continue;

        if( P_TARGET[0].pev.FlagBitSet( FL_CLIENT ) && !blTpPlayers )
            continue;

        if( P_TARGET[0].pev.FlagBitSet( FL_MONSTER ) && !blTpMonsters )
            continue;

        if( P_TARGET[0].IRelationship( g_EntityFuncs.Instance( pPortal.pev.owner ) ) > R_NO && !blTpEnemies )
            continue;

        if( ( TeleportCount( P_TARGET[0] ) > 0 && blTeleportOnce ) || TeleportCount( P_TARGET[0] ) < 0 )
            continue;

        if( strTeleportNameFilter != "" && P_TARGET[0].GetTargetname() != strTeleportNameFilter )
            continue;

        PortalExit( P_TARGET[0] );
        // Can't delete it otherwise the beams remain - just move it outside the world and let it expire itself
        pPortal.pev.effects |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( pPortal, Vector( -WORLD_BOUNDARY, -WORLD_BOUNDARY, -WORLD_BOUNDARY ) );
    }
}

HookReturnCode DisplacerTertiaryAttack(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
{
    if( pWeapon is null || pPlayer is null || pWeapon.m_iID != WEAPON_DISPLACER )
        return HOOK_CONTINUE;

    if( !pWeapon.GetUserData().exists( "cant_fire" ) )
        pWeapon.GetUserData()["cant_fire"] = -1;

    if( !pWeapon.GetUserData().exists( "teleport_count" ) )
        pWeapon.GetUserData()["teleport_count"] = -1;

    CBaseEntity@ pPortal;
    
    while( ( @pPortal = g_EntityFuncs.FindEntityByClassname( pPortal, "displacer_portal" ) ) !is null )
    {
        if( pPortal is null )
            continue;
        // Player already shot the displacer
        if( pPortal.pev.owner is pPlayer.edict() )
            return HOOK_CONTINUE;
    }

    if( FCantFire( pWeapon ) )
        return HOOK_CONTINUE;

    if( iDisplacerPortalAmmoCost > 0 && pPlayer.m_rgAmmo( pWeapon.m_iPrimaryAmmoType ) < iDisplacerPortalAmmoCost )
        DryShoot( pPlayer, pWeapon );// Not enough ammo
    else
        SpinUp( pPlayer, pWeapon );

    return HOOK_CONTINUE;
}

}
/* Special thanks to:
- H2
- KernCore
*/