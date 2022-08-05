/*
respawndead_keepweapons
Adds a feature for trigger_respawn to let dead players respawn with the weapons they collected when they died, instead of losing them

Install:
put "map_script respawndead_keepweapons" to your map cfg
OR
Add this as a trigger_script
"classname" "trigger_script"
"m_iszScriptFile" "respawndead_keepweapons"
OR
Include it in your main map script header
#include "respawndead_keepweapons"

Usage:
- make your trigger_respawn, check the flag "Respawn dead" then 
- check flag box 4 (value 8)- this is the new flag to allow the trigger_respawn to let dead respawning players keep their weapons they had when they died
*/
namespace RESPAWNDEAD_KEEPWEAPONS
{

CScheduledFunction@ fnPatchTriggerRespawn = g_Scheduler.SetTimeout( "PatchTriggerRespawn", 0.0f );
bool blPlayerKilled = g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, PlayerKilled );
array<dictionary> DICT_PLAYER_LOADOUT( g_Engine.maxClients + 1 );

void PatchTriggerRespawn()
{
    CBaseEntity@ pEntity;

    while( ( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "trigger_respawn" ) ) !is null ) )
    {
        if( pEntity is null )
            continue;

        if( pEntity.pev.SpawnFlagBitSet( 2 ) && pEntity.pev.SpawnFlagBitSet( 8 ) )
        {
            pEntity.pev.spawnflags &= ~2;// disable respawn dead setting, trigger_script will do this now

            dictionary dictDeadRespawner =
            {
                { "m_iszScriptFile", "respawndead_keepweapons" },
                { "m_iszScriptFunctionName", "RESPAWNDEAD_KEEPWEAPONS::RespawnDead" },
                { "m_iMode", "1" },
                { "targetname", pEntity.GetTargetname() }
            };

            g_EntityFuncs.CreateEntity( "trigger_script", dictDeadRespawner );
        }
    }
}
// Replace trigger_respawn's dead respawner with our own
void RespawnDead(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    for( int iPlayer = 1; iPlayer <= g_PlayerFuncs.GetNumPlayers(); iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || pPlayer.IsAlive() )
            continue;

        g_PlayerFuncs.RespawnPlayer( pPlayer, false, true );
        ReEquipCollected( pPlayer );
    }
}
// Players get their old loadout when they died
void ReEquipCollected(EHandle hPlayer)
{
    if( !hPlayer )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );
    array<string> STR_LOADOUT_WEAPONS = DICT_PLAYER_LOADOUT[pPlayer.entindex()].getKeys();

    for( uint i = 0; i < STR_LOADOUT_WEAPONS.length(); i++ )
    {
        if( STR_LOADOUT_WEAPONS[i] == "" || pPlayer.HasNamedPlayerItem( STR_LOADOUT_WEAPONS[i] ) !is null )
            continue;

        pPlayer.GiveNamedItem( STR_LOADOUT_WEAPONS[i] ); // Would be nice if this returned the actual item ptr....
        CBasePlayerWeapon@ pEquippedWeapon = cast<CBasePlayerWeapon@>( pPlayer.HasNamedPlayerItem( STR_LOADOUT_WEAPONS[i] ) );

        if( pEquippedWeapon is null )
            continue;

        pPlayer.m_rgAmmo( pEquippedWeapon.m_iPrimaryAmmoType, int( DICT_PLAYER_LOADOUT[pPlayer.entindex()][STR_LOADOUT_WEAPONS[i]] ) );
    }

    DICT_PLAYER_LOADOUT[pPlayer.entindex()] = dictionary();
}
// Save player loadout upon death
HookReturnCode PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib)
{
    if( pPlayer is null )
        return HOOK_CONTINUE;

    DICT_PLAYER_LOADOUT[pPlayer.entindex()] = dictionary();

    for( uint i = 0; i < MAX_ITEM_TYPES; i++ )
    {
        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_rgpPlayerItems( i ) );

        while( pWeapon !is null )
        {
            DICT_PLAYER_LOADOUT[pPlayer.entindex()][pWeapon.GetClassname()] = pPlayer.m_rgAmmo( pWeapon.m_iPrimaryAmmoType );
            @pWeapon = cast<CBasePlayerWeapon@>( pWeapon.m_hNextItem.GetEntity() );
        }
    }

    return HOOK_CONTINUE;
}

}
