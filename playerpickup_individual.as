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

bool blEntityCreated = g_Hooks.RegisterHook( Hooks::Game::EntityCreated, MarkPickup );
bool blPickupSpawned = g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, MarkPickup );
bool blCanCollect = g_Hooks.RegisterHook( Hooks::PickupObject::CanCollect, CanCollect );
bool blCollected = g_Hooks.RegisterHook( Hooks::PickupObject::Collected, Collected );

CScheduledFunction@ fnPatchPickups = g_Scheduler.SetTimeout( "PatchPickups", 0.1f );

void PatchPickups()
{
    CBaseEntity@ pItem, pAmmo, pWeaponBox;

    while( ( @pItem = g_EntityFuncs.FindEntityByClassname( pItem, "item_*" ) ) !is null )
        MarkPickup( pItem );

    while( ( @pAmmo = g_EntityFuncs.FindEntityByClassname( pAmmo, "ammo_*" ) ) !is null )
        MarkPickup( pAmmo );

    while( ( @pWeaponBox = g_EntityFuncs.FindEntityByClassname( pWeaponBox, "weaponbox" ) ) !is null )
        MarkPickup( pWeaponBox );
}

HookReturnCode MarkPickup(CBaseEntity@ pPickup)
{
    if( pPickup is null || pPickup.GetClassname() == "item_generic" || 
        pPickup.GetClassname() == "item_inventory" || 
        pPickup.GetUserData().exists( "player_ids" ) )
        return HOOK_CONTINUE;

    if( pPickup.GetClassname().Find( "item_" ) != String::INVALID_INDEX || 
        pPickup.GetClassname().Find( "ammo_" ) != String::INVALID_INDEX ||
        pPickup.GetClassname() == "weaponbox" )
    {
        if( !pPickup.pev.SpawnFlagBitSet( 1 << 0 ) )
            return HOOK_CONTINUE;

        pPickup.GetUserData()["player_ids"] = array<string>( 1 );
    }
    
    return HOOK_CONTINUE;
}

HookReturnCode CanCollect(CBaseEntity@ pPickup, CBaseEntity@ pOther, bool& out bResult)
{
    if( pPickup is null || pOther is null || !pOther.IsPlayer() || !pPickup.GetUserData().exists( "player_ids" ) )
        return HOOK_CONTINUE;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );
    array<string> STR_PLAYER_IDS = cast<array<string>>( pPickup.GetUserData( "player_ids" ) );

    if( pPlayer is null || STR_PLAYER_IDS.find( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) ) >= 0 )
    {
        bResult = false;
        return HOOK_CONTINUE;
    }

    return HOOK_CONTINUE;
}

HookReturnCode Collected(CBaseEntity@ pPickup, CBaseEntity@ pOther)
{
    if( pPickup is null || pOther is null || !pPickup.GetUserData().exists( "player_ids" ) )
        return HOOK_CONTINUE;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( pOther );
    array<string> STR_PLAYER_IDS = cast<array<string>>( pPickup.GetUserData( "player_ids" ) );

    if( STR_PLAYER_IDS.find( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) ) >= 0 )
        return HOOK_CONTINUE;

    STR_PLAYER_IDS.insertLast( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) );
    pPickup.GetUserData( "player_ids" ) = STR_PLAYER_IDS;

    return HOOK_CONTINUE;
}

}
