/* playerpickup_individual
by Outerbeast
Extension for item_/ammo_/weaponbox entities
Individual players interacting with pickups can only pick them up once, never again, allowing other players to pick them.

Install:-
Put the script file into "scripts/maps/beast" then either
- put "map_script playerpickup_individual" to your map cfg
OR
-Add this as a trigger_script
"classname" "trigger_script"
"m_iszScriptFile" "playerpickup_individual"
OR
-Include it in your main map script header
#include "beast/playerpickup_individual"

Usage:-
Simply check the 1st flag box (value is 1) in your item_/ammo_/weaponbox entity to enable this feature for that entity.
*/
namespace PLAYERPICKUP_INDIVIDUAL
{

array<EHandle> H_PICKUPS;

bool blEntityCreated = g_Hooks.RegisterHook( Hooks::Game::EntityCreated, DisablePickup );
CScheduledFunction@ fnPatchPickups = g_Scheduler.SetTimeout( "PatchPickups", 0.1f ), 
                    fnPickupThink = g_Scheduler.SetInterval( "PickupThink", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );

void PatchPickups()
{
    CBaseEntity@ pItem, pAmmo, pWeaponBox;

    while( ( @pItem = g_EntityFuncs.FindEntityByClassname( pItem, "item_*" ) ) !is null )
        DisablePickup( pItem );

    while( ( @pAmmo = g_EntityFuncs.FindEntityByClassname( pAmmo, "ammo_*" ) ) !is null )
        DisablePickup( pAmmo );

    while( ( @pWeaponBox = g_EntityFuncs.FindEntityByClassname( pWeaponBox, "weaponbox" ) ) !is null )
        DisablePickup( pWeaponBox );
}

HookReturnCode DisablePickup(CBaseEntity@ pPickup)
{
    if( pPickup is null || pPickup.GetClassname() == "item_generic" || pPickup.GetClassname() == "item_inventory" )
        return HOOK_CONTINUE;

    if( H_PICKUPS.length() > 0 && H_PICKUPS.findByRef( EHandle( pPickup ) ) >= 0 )
        return HOOK_CONTINUE;

    if( pPickup.GetClassname().Find( "item_" ) != String::INVALID_INDEX || 
        pPickup.GetClassname().Find( "ammo_" ) != String::INVALID_INDEX ||
        pPickup.GetClassname() == "weaponbox" )
    {
        if( !pPickup.pev.SpawnFlagBitSet( 1 << 0 ) )
            return HOOK_CONTINUE;

        pPickup.pev.spawnflags |= ( 1 << 7 | 1 << 8 );
        pPickup.GetUserData()["player_ids"] = array<string>( 1 );
        H_PICKUPS.insertLast( pPickup );
    }
    
    return HOOK_CONTINUE;
}

void PickupThink()
{
    if( H_PICKUPS.length() < 1 )
        return;

    for( uint i = 0; i < H_PICKUPS.length(); i++ )
    {
        if( !H_PICKUPS[i] )
            continue;

        CBaseEntity@ pPickup = H_PICKUPS[i].GetEntity();
        array<CBaseEntity@> P_COLLECTOR( 1 );

        if( pPickup is null || pPickup.pev.effects & EF_NODRAW != 0 )
            continue;

        if( g_EntityFuncs.EntitiesInBox( @P_COLLECTOR, pPickup.pev.absmin, pPickup.pev.absmax, FL_CLIENT ) < 1 )
            continue;
           
        CBasePlayer@ pPlayer = cast<CBasePlayer@>( P_COLLECTOR[0] );
        array<string> STR_PLAYER_IDS = cast<array<string>>( pPickup.GetUserData( "player_ids" ) );

        if( pPlayer is null || !pPlayer.Intersects( pPickup ) )
            continue;

        if( STR_PLAYER_IDS.find( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) ) >= 0 )
            continue;

        STR_PLAYER_IDS.insertLast( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) );
        pPickup.GetUserData( "player_ids" ) = STR_PLAYER_IDS;
        pPickup.Use( pPlayer, pPlayer, USE_TOGGLE, 0.0f );
    }
}

}
