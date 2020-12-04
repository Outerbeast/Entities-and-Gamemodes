/* Script for swapping default weapons with classic ones without Classic Mode.
Usage: Add CLASSICMODE::Enable() in MapInit in your main amp script

-Outerbeast */

#include "hl_weapons/weapon_hl357"
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
    ItemMapping( "weapon_357", "weapon_hl357" ),
    ItemMapping( "ammo_556clip", "ammo_9mmAR" ),
    ItemMapping( "ammo_9mmuziclip", "ammo_9mmAR" )
};

void Enable()
{
    RegisterHLPYTHON();
    RegisterHLCrowbar();
    RegisterHLMP5();
    RegisterHLShotgun();

    g_ClassicMode.SetItemMappings( @CLASSIC_WEAPONS_LIST );
    g_ClassicMode.ForceItemRemap( true );
    
    g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, @ItemSpawned );
}    
// World weapon swapper routine (credit to KernCore)
HookReturnCode ItemSpawned( CBaseEntity@ pOldItem ) 
{
    if( pOldItem is null ) 
        return HOOK_CONTINUE;

    for( uint w = 0; w < CLASSIC_WEAPONS_LIST.length(); ++w )
    {
        if( pOldItem.GetClassname() == CLASSIC_WEAPONS_LIST[w].get_From() )
        {
            CBaseEntity@ pNewItem = g_EntityFuncs.Create( CLASSIC_WEAPONS_LIST[w].get_To(), pOldItem.GetOrigin(), pOldItem.pev.angles, false );
            if( pNewItem is null ) 
                return HOOK_CONTINUE;

            pNewItem.pev.movetype = pOldItem.pev.movetype;

            if( pOldItem.GetTargetname() != "" )
                g_EntityFuncs.DispatchKeyValue( pNewItem.edict(), "targetname", pOldItem.GetTargetname() );

            if( pOldItem.pev.target != "" )
                g_EntityFuncs.DispatchKeyValue( pNewItem.edict(), "target", pOldItem.pev.target );

            if( pOldItem.pev.netname != "" )
                g_EntityFuncs.DispatchKeyValue( pNewItem.edict(), "netname", pOldItem.pev.netname );

            g_EntityFuncs.Remove( pOldItem );
        }
    }
    return HOOK_CONTINUE;
}

}
