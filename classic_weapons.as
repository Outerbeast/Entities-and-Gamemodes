/* !-OBSOLETE-!: use info_itemswap entity, and customise that to suit a classic mode setup
    Script for swapping default weapons with classic ones without Classic Mode.
    Usage: Add #include "classic_weapons" in the script header
    then add CLASSICWEAPONS::Enable() in MapInit in your main map script
-Outerbeast */

#include "hl_weapons/weapon_hlcrowbar"
#include "hl_weapons/weapon_hlmp5"
#include "hl_weapons/weapon_hlshotgun"

namespace CLASSICWEAPONS
{

array<ItemMapping@> CLASSIC_WEAPONS_LIST = 
{
    ItemMapping( "weapon_m16", "weapon_hlmp5" ),
    ItemMapping( "weapon_9mmAR", "weapon_hlmp5" ),
    ItemMapping( "weapon_uzi", "weapon_hlmp5" ),
    ItemMapping( "weapon_uziakimbo", "weapon_hlmp5" ),
    ItemMapping( "weapon_crowbar", "weapon_hlcrowbar" ),
    ItemMapping( "weapon_shotgun", "weapon_hlshotgun" ),
    ItemMapping( "ammo_556clip", "ammo_9mmAR" ),
    ItemMapping( "ammo_9mmuziclip", "ammo_9mmAR" )
};

void Enable()
{
    RegisterHLCrowbar();
    RegisterHLMP5();
    RegisterHLShotgun();

    g_ClassicMode.SetItemMappings( @CLASSIC_WEAPONS_LIST );
    g_ClassicMode.ForceItemRemap( g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, ItemSpawned ) );
}    
// World weapon swapper routine (credit to KernCore)
HookReturnCode ItemSpawned(CBaseEntity@ pOldItem) 
{
    if( pOldItem is null ) 
        return HOOK_CONTINUE;

    for( uint w = 0; w < CLASSIC_WEAPONS_LIST.length(); ++w )
    {
        if( pOldItem.GetClassname() != CLASSIC_WEAPONS_LIST[w].get_From() )
            continue;

        CBaseEntity@ pNewItem = g_EntityFuncs.Create( CLASSIC_WEAPONS_LIST[w].get_To(), pOldItem.GetOrigin(), pOldItem.pev.angles, false );

        if( pNewItem is null ) 
            continue;

        pNewItem.pev.movetype = pOldItem.pev.movetype;

        if( pOldItem.pev.netname != "" )
            pNewItem.pev.netname = pOldItem.pev.netname;

        g_EntityFuncs.Remove( pOldItem );
    }
    
    return HOOK_CONTINUE;
}

}
