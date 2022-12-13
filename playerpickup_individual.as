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
Optional settings (set in MapInit):
- PLAYERPICKUP_INDIVIDUAL::blHideAfterCollect = true; - this will hide the pickup after respawning from the player who collected the pickup
- PLAYERPICKUP_INDIVIDUAL::blApplyGlobal = true; - Sets all pickups to individual collection
*/
namespace PLAYERPICKUP_INDIVIDUAL
{

bool
    blHideAfterCollect = false,
    blApplyGlobal = false;

CScheduledFunction@ fnPatchPickups = g_Scheduler.SetTimeout( "PatchPickups", 0.01f );

void PatchPickups()
{
    CBaseEntity@ pItem, pAmmo, pWeaponBox;

    while( ( @pItem = g_EntityFuncs.FindEntityByClassname( pItem, "item_*" ) ) !is null )
        MarkPickup( pItem );

    while( ( @pAmmo = g_EntityFuncs.FindEntityByClassname( pAmmo, "ammo_*" ) ) !is null )
        MarkPickup( pAmmo );

    while( ( @pWeaponBox = g_EntityFuncs.FindEntityByClassname( pWeaponBox, "weaponbox" ) ) !is null )
        MarkPickup( pWeaponBox );

    g_Hooks.RegisterHook( Hooks::Game::EntityCreated, MarkPickup );
    g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, MarkPickup );
    g_Hooks.RegisterHook( Hooks::PickupObject::CanCollect, CanCollect );
    g_Hooks.RegisterHook( Hooks::PickupObject::Collected, Collected );
}
// Code from: https://github.com/Outerbeast/Utility-Scripts/blob/main/render_settings.as
void HidePickup(EHandle hPickup, EHandle hPlayer)
{
    if( !hPickup || !hPlayer )
        return;
    
    dictionary dictRenderIndividual =
    {
        { "rendermode", "2" },
        { "renderamt", "0" },
        { "spawnflags", "" + ( 1 | 8 | 64 ) }
    };

    dictRenderIndividual["target"] = hPickup.GetEntity().GetTargetname() == "" ? 
                            string( hPickup.GetEntity().pev.targetname = string_t( "render_individual_entity_" + hPickup.GetEntity().entindex() ) ) :
                            hPickup.GetEntity().GetTargetname();

    CBaseEntity@ pRenderIndividual = g_EntityFuncs.CreateEntity( "env_render_individual", dictRenderIndividual );

    if( pRenderIndividual is null )
        return;

    pRenderIndividual.Use( hPlayer.GetEntity(), pRenderIndividual, USE_ON, 0.0f );

    if( hPickup.GetEntity().GetTargetname().StartsWith( "render_individual_" ) )
        hPickup.GetEntity().pev.targetname = "";
}

HookReturnCode MarkPickup(CBaseEntity@ pPickup)
{
    if( pPickup is null || 
        pPickup.GetClassname() == "item_generic" || 
        pPickup.GetClassname() == "item_inventory" )
        return HOOK_CONTINUE;

    if( pPickup.GetUserData().exists( "player_ids" ) )
    {
        if( blHideAfterCollect )
        {
            array<string> STR_PLAYER_IDS = cast<array<string>>( pPickup.GetUserData( "player_ids" ) );

            for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
            {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

                if( pPlayer is null || !pPlayer.IsConnected() )
                    continue;

                if( STR_PLAYER_IDS.find( g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) ) < 0 )
                    continue;

                if( pPickup.pev.rendermode == kRenderNormal )
                    HidePickup( pPickup, pPlayer );
            }
        }

        return HOOK_CONTINUE;
    }

    if( pPickup.GetClassname().Find( "item_" ) != String::INVALID_INDEX || 
        pPickup.GetClassname().Find( "ammo_" ) != String::INVALID_INDEX ||
        pPickup.GetClassname() == "weaponbox" )
    {
        if( blApplyGlobal )
            pPickup.GetUserData()["player_ids"] = array<string>( 1 );
        else if( pPickup.pev.SpawnFlagBitSet( 1 << 0 ) )
            pPickup.GetUserData()["player_ids"] = array<string>( 1 );
    }
    
    return HOOK_CONTINUE;
}

HookReturnCode CanCollect(CBaseEntity@ pPickup, CBaseEntity@ pOther, bool& out bResult)
{
    if( pPickup is null || 
        pOther is null ||
        !pOther.IsPlayer() ||
        !pPickup.GetUserData().exists( "player_ids" ) )
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
