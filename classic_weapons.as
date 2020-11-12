/* Script for swapping default weapons with classic ones without Classic Mode.
Usage: map_script classic_mode or if you are already using your own map script do the following:-
1) Comment out or remove the block
void MapInit()
{
    g_ClassicWeapons.MapInit();
} 
then in your main map script add
#include "classic_weapons"

and inside your MapInit block add
g_ClassicWeapons.MapInit();

-Outerbeast */

#include "hl_weapons/weapon_hl357"
#include "hl_weapons/weapon_hlcrowbar"
#include "hl_weapons/weapon_hlmp5"
#include "hl_weapons/weapon_hlshotgun"

ClassicWeapons@ g_ClassicWeapons = @ClassicWeapons();

const bool _IS_ITEMSPAWNED_HOOK_REGISTERED = g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, @ClassicWeaponsItemSpawned );

void MapInit()
{
    g_ClassicWeapons.MapInit();
} 

HookReturnCode ClassicWeaponsItemSpawned(CBaseEntity@ pItem)
{
    return g_ClassicWeapons.ItemSpawned( pItem );
}


final class ClassicWeapons
{
    ClassicWeapons(){ }

    private array<ItemMapping@> CLASSIC_WEAPONS_LIST = 
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

    void MapInit()
    {
        RegisterHLPYTHON();
        RegisterHLCrowbar();
        RegisterHLMP5();
        RegisterHLShotgun();

        g_ClassicMode.SetItemMappings( @CLASSIC_WEAPONS_LIST );
        g_ClassicMode.ForceItemRemap( true );
    }    
    // World weapon swapper routine (credit to KernCore)
    HookReturnCode ItemSpawned( CBaseEntity@ pOldItem ) 
    {
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
        return HOOK_HANDLED;
    }
}