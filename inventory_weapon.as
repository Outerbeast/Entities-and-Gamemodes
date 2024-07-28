/* trigger_script for making weapons as inventory items
    Activating the item in your inventory will equip you the weapon

    Installation:-
    - Place in scripts/maps
    - Add this trigger_script entity to your map, set targetname of your choice
    "classname" "trigger_script"
    "targetname" "unlock_weapon"
    "m_iszScriptFile" "inventory_weapon"
    "m_iszScriptFunctionName" "InventoryWeapon"
    "m_iMode" "1"

    Usage:-
    - Configure your item_inventory that will serve as a weapon pickup that will be added to your inventory.
    - Set the item_inventory "target_on_activate" to trigger the trigger_script you configured previously.
    - Set the "item_name" keyvalue to the weapon classname that will equip that weapon when activating it e.g. "weapon_m16".
- Outerbeast, concept by RaptorSKA
*/
void InventoryWeapon(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( pActivator is null || !pActivator.IsPlayer() )
        return;

    CItemInventory@ pItemInventory = cast<CItemInventory@>( pCaller );

    if( pItemInventory is null || !pItemInventory.m_hHolder )
        return;

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( pItemInventory.m_hHolder.GetEntity() );

    if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
        return;

    const string strWeaponName = pItemInventory.m_szItemName;

    if( pPlayer.HasNamedPlayerItem( strWeaponName ) !is null )
        return;

    pPlayer.GiveNamedItem( strWeaponName );
    //g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "" + pPlayer.pev.netname + " equipped " + strWeaponName + "\n" );
    pItemInventory.SUB_Remove();
}
