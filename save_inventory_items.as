/* Script for saving player inventory item across level transitions
-Outerbeast
*/
namespace SAVE_INVENTORY_ITEMS
{

string strNextMap;
const bool blInventoryItemsLoaded = g_EntityLoader.LoadFromFile( "store/" + g_Engine.mapname + ".inv" );
CScheduledFunction@ fnInit = g_Scheduler.SetTimeout( "Init", 0.0f );

string FormatEntityData(dictionary dictEntityData, string strEntityLabel = "Entity")
{
    if( dictEntityData.isEmpty() )
        return "";
    // Ugliness, because theres no string constructor implementing string formatting. Deal with it.
    string strEntLoaderKeyvalues;
    const string strLineStart = "\"" + strEntityLabel + "\" ";
    const string strEntStart = "{ ", strEntEnd = "}";
    const array<string> STR_KEYS = dictEntityData.getKeys();

    for( uint i = 0; i < STR_KEYS.length(); i++ )
    {
        if( STR_KEYS[i] == "" )
            continue;

        const string strKey = "\"" + STR_KEYS[i] + "\"";
        const string strValue = "\"" + string( dictEntityData[STR_KEYS[i]] ) + "\"";
        const string strKeyValue = strKey + " " + strValue + " ";
        strEntLoaderKeyvalues = strEntLoaderKeyvalues + strKeyValue;
    }

    return strLineStart + strEntStart + strEntLoaderKeyvalues + strEntEnd;
}

void Init()
{
    g_Hooks.RegisterHook( Hooks::Game::MapChange, MapChange );

    if( blInventoryItemsLoaded )
        g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, LoadInventory );
}

bool SaveInventoryItem(CItemInventory@ pInventoryItem)
{
    if( pInventoryItem is null || !pInventoryItem.m_hHolder )
        return false;

    dictionary dictInventoryItem =
    {
        { "classname", "item_inventory" },
        { "targetname", pInventoryItem.GetTargetname() },
        { "netname", g_EngineFuncs.GetPlayerAuthId( pInventoryItem.m_hHolder.GetEntity().edict() ) },
        { "model", string( pInventoryItem.pev.model ) },
        { "skin", string( pInventoryItem.pev.skin ) },
        { "body", string( pInventoryItem.pev.body ) },
        { "scale", string( pInventoryItem.pev.scale ) },
        { "rendercolor", pInventoryItem.pev.rendercolor.ToString() },
        { "rendermode", string( pInventoryItem.pev.rendermode ) },
        { "renderfx", string( pInventoryItem.pev.renderfx ) },
        { "spawnflags", StringToRGBA( pInventoryItem.pev.spawnflags ) }
    };

    dictInventoryItem["holder_keep_on_death"] = string( pInventoryItem.m_fKeepOnDeath ? "1" : "0" );// Holder still has the item after dying (i.e. so they can keep it while being revived)
    dictInventoryItem["holder_keep_on_respawn"] = string( pInventoryItem.m_fKeepOnRespawn ? "1" : "0" );// Delayed respawn on return (like with weapons/ammo/pickups)
    dictInventoryItem["holder_can_drop"] = string( pInventoryItem.m_fCanBeDropped ? "1" : "0" );// Holder is allowed to drop this item by choice
    dictInventoryItem["carried_hidden"] = string( pInventoryItem.m_fHiddenWhenCarried ? "1" : "0" );// Model is hidden while it is being carried.
    dictInventoryItem["holder_can_drop"] = string( pInventoryItem.m_fCanBeDropped ? "1" : "0" );// Holder is allowed to drop this item by choice
    dictInventoryItem["return_delay_respawn"] = string( pInventoryItem.m_fDelayedRespawn ? "1" : "0" );// Delayed respawn on return (like with weapons/ammo/pickups)
    
    dictInventoryItem["effect_block_weapons"] = string( pInventoryItem.m_fEffectBlockWeapons ? "1" : "0" );// Holder can't use weapons
    dictInventoryItem["effect_invulnerable"] = string( pInventoryItem.m_fEffectInvulnerable ? "1" : "0" );// Holder is invulnerable (god mode)
    dictInventoryItem["effect_invisible"] = string( pInventoryItem.m_fEffectInvisible ? "1" : "0" );// Holder is invisible (render + non-targetable)
    dictInventoryItem["effect_nonsolid"] = string( pInventoryItem.m_fEffectNonSolid ? "1" : "0" );// Holder is non-solid
    dictInventoryItem["effects_permanent"] = string( pInventoryItem.m_fEffectsPermanent ? "1" : "0" );// Holder keeps effects after dropping the item

    //dictInventoryItem["activate_limit"] = string( pInventoryItem. );// NOT EXPOSED
    dictInventoryItem["collect_limit"] = string( pInventoryItem.m_iCollectLimit );// How many times the item can be picked up, destroyed when limit is reached (0 = infinite).
    dictInventoryItem["carried_skin"] = string( pInventoryItem.m_iCarriedSkin );// Model skin while CARRIED.
    dictInventoryItem["carried_body"] = string( pInventoryItem.m_iCarriedBody );// Model body while CARRIED.
    dictInventoryItem["carried_sequence"] = string( pInventoryItem.m_iCarriedSequence );// Model sequence number while CARRIED.

    dictInventoryItem["item_group_required_num"] = string( pInventoryItem.m_iRequiresItemGroupNum );// Number of item(s) from the required group(s) required (0 = all)
    dictInventoryItem["item_group_canthave_num"] = string( pInventoryItem.m_iCantHaveItemGroupNum );// Number of item(s) from the can't have group(s) (0 = all)
    dictInventoryItem["filter_npc_classifications"] = string( pInventoryItem.m_iAllowedNpcClassify );// NPC classification filter "filter_npc_classifications"

    dictInventoryItem["weight"] = string( pInventoryItem.m_flWeight );// How heavy the item is (0-100), holders can hold multiple items up to a total weight 100, think of this as KG if you like (though what person can carry 100KG!?).
    dictInventoryItem["return_timelimit"] = string( pInventoryItem.m_flReturnTime );// How long this item returns to its' original location when dropped (-1 = never, 0 = instant)
    dictInventoryItem["holder_timelimit"] = string( pInventoryItem.m_flMaximumHoldTime );// Limit to how long this item can be held for, forcibly dropped after (0 = no limit)
    dictInventoryItem["holder_time_wearout"] = string( pInventoryItem.m_flWearOutTime );// Perform a trigger prior to this item being forcibly dropped (0 = none)
    dictInventoryItem["effect_respiration"] = string( pInventoryItem.m_flEffectRespiration );// Extra/less breathing time underwater in seconds
    dictInventoryItem["effect_gravity"] = string( pInventoryItem.m_flEffectGravity );// Gravity modifier (%)
    dictInventoryItem["effect_friction"] = string( pInventoryItem.m_flEffectFriction );// Movement friction modifier (%)
    dictInventoryItem["effect_speed"] = string( pInventoryItem.m_flEffectSpeed );// Movement speed modifier (%)
    dictInventoryItem["effect_damage"] = string( pInventoryItem.m_flEffectDamage );// Damage modifier (%)

    dictInventoryItem["item_name"] = string( pInventoryItem.m_szItemName );
    dictInventoryItem["description"] = string( pInventoryItem.m_szDescription );
    dictInventoryItem["display_name"] = string( pInventoryItem.m_szDisplayName );
    dictInventoryItem["carried_sequencename"] = string( pInventoryItem.m_szCarriedSequenceName );// Model sequence name while CARRIED.
    dictInventoryItem["filter_targetnames"] = string( pInventoryItem.m_szAllowedTargetNames );// CBaseEntity target name filters
    dictInventoryItem["filter_classnames"] = string( pInventoryItem.m_szAllowedClassNames );// CBaseEntity class name filters
    dictInventoryItem["filter_teams"] = string( pInventoryItem.m_szAllowedTeams );// Team filters
    dictInventoryItem["item_name_required"] = string( pInventoryItem.m_szRequiresItemName );// Require these item(s)
    dictInventoryItem["item_group"] = string( pInventoryItem.m_szItemGroup );// Group name referred to by triggers.
    dictInventoryItem["item_group_required"] = string( pInventoryItem.m_szRequiresItemGroup );// Require an item from these group(s)
    dictInventoryItem["item_name_moved"] = string( pInventoryItem.m_szItemNameMoved );// These item(s) must have moved
    dictInventoryItem["item_name_canthave"] = string( pInventoryItem.m_szCantHaveItemName );// Must not have these item(s)
    dictInventoryItem["item_group_canthave"] = string( pInventoryItem.m_szCantHaveItemGroup );// Must not have an item in these group(s)
    dictInventoryItem["item_name_not_moved"] = string( pInventoryItem.m_szItemNameNotMoved );// These item(s) must NOT have moved
    dictInventoryItem["target_on_collect"] = string( pInventoryItem.m_szTriggerOnCollectSelf );// On successful collection (for collector)
    dictInventoryItem["target_on_collect_team"] = string( pInventoryItem.m_szTriggerOnCollectTeam );// On successful collection (for collector's team)
    dictInventoryItem["target_on_collect_other"] = string( pInventoryItem.m_szTriggerOnCollectOther );// On successful collection (for everyone else)
    dictInventoryItem["target_cant_collect"] = string( pInventoryItem.m_szTriggerOnCantCollectSelf );// On failed collection (for collector)
    dictInventoryItem["target_cant_collect_team"] = string( pInventoryItem.m_szTriggerOnCantCollectTeam );// On failed collection (for collector's team)
    dictInventoryItem["target_cant_collect_other"] = string( pInventoryItem.m_szTriggerOnCantCollectOther );// On failed collection (for everyone else)
    dictInventoryItem["target_on_drop"] = string( pInventoryItem.m_szTriggerOnDropSelf );// On successful drop (for collector)
    dictInventoryItem["target_on_drop_team"] = string( pInventoryItem.m_szTriggerOnDropTeam );// On successful drop (for collector's team)
    dictInventoryItem["target_on_drop_other"] = string( pInventoryItem.m_szTriggerOnDropOther );// On successful drop (for everyone else)
    dictInventoryItem["target_cant_drop"] = string( pInventoryItem.m_szTriggerOnCantDropSelf );// On failed drop (for collector)
    dictInventoryItem["target_cant_drop_team"] = string( pInventoryItem.m_szTriggerOnCantDropTeam );// On failed drop (for collector's team)
    dictInventoryItem["target_cant_drop_other"] = string( pInventoryItem.m_szTriggerOnCantDropOther );// On failed drop (for everyone else)
    dictInventoryItem["target_on_activate"] = string( pInventoryItem.m_szTriggerOnUseSelf );// On use by trigger (for collector)
    dictInventoryItem["target_on_activate_team"] = string( pInventoryItem.m_szTriggerOnUseTeam );// On use by trigger (for collector's team)
    dictInventoryItem["target_on_activate_other"] = string( pInventoryItem.m_szTriggerOnUseOther );// On use by trigger (for everyone else)
    dictInventoryItem["target_on_wearing_out"] = string( pInventoryItem.m_szTriggerOnWearingOutSelf );// On wearing out (for collector)
    dictInventoryItem["target_on_wearing_out_team"] = string( pInventoryItem.m_szTriggerOnWearingOutTeam );// On wearing out (for collector's team)
    dictInventoryItem["target_on_wearing_out_other"] = string( pInventoryItem.m_szTriggerOnWearingOutOther );// On wearing out (for everyone else)
    dictInventoryItem["target_on_return"] = string( pInventoryItem.m_szTriggerOnReturnSelf );// On return (for collector)
    dictInventoryItem["target_on_return_team"] = string( pInventoryItem.m_szTriggerOnReturnTeam );// On return (for collector's team)
    dictInventoryItem["target_on_return_other"] = string( pInventoryItem.m_szTriggerOnReturnOther );// On return (for everyone else)
    dictInventoryItem["target_on_materialise"] = string( pInventoryItem.m_szTriggerOnMaterialise );// On materialise after return
    dictInventoryItem["target_on_destroy"] = string( pInventoryItem.m_szTriggerOnDestroy );// On destroy

    if( pInventoryItem.m_vecEffectGlowColor != g_vecZero )
        dictInventoryItem["effect_glow"] = pInventoryItem.m_vecEffectGlowColor.ToString();

    array<string> STR_KEYS = dictInventoryItem.getKeys();

    for( uint i = 0; i < STR_KEYS.length(); i++ )
    {
        if( atof( string( dictInventoryItem[STR_KEYS[i]] ) ) == 0.0f )
            dictInventoryItem.delete( STR_KEYS[i] );
    }

    if( dictInventoryItem.isEmpty() )
        return false;

    const string strFileName = "scripts/maps/store/" + strNextMap + ".inv";
    File@ fileItemInventory = g_FileSystem.OpenFile( strFileName, OpenFile::APPEND );

    if( fileItemInventory is null || !fileItemInventory.IsOpen() )
        return false;

    fileItemInventory.Write( FormatEntityData( dictInventoryItem, pInventoryItem.m_hHolder.GetEntity().pev.netname ) + "\n" );
    fileItemInventory.Close();

    return true;
}

void StoreInventory()
{
    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || pPlayer.get_m_pInventory() is null )
            continue;

        InventoryList@ pInventory = pPlayer.get_m_pInventory();

        do
        {
            CItemInventory@ pInventoryItem = cast<CItemInventory@>( pInventory.hItem.GetEntity() );

            if( pInventoryItem !is null && pInventoryItem.pev.netname == "save_for_next_level" )
                SaveInventoryItem( pInventoryItem );

            @pInventory = pInventory.pNext;
        }
        while( pInventory !is null );
    }
}

void ClearFile()
{
    const string strFileName = "scripts/maps/store/" + strNextMap + ".inv";
    File@ fileItemInventory = g_FileSystem.OpenFile( strFileName, OpenFile::APPEND );

    if( fileItemInventory is null || !fileItemInventory.IsOpen() )
        return;

    fileItemInventory.Remove();
}

HookReturnCode LoadInventory(CBasePlayer@ pPlayer)
{
    if( pPlayer is null || !pPlayer.IsConnected() || !blInventoryItemsLoaded )
        return HOOK_CONTINUE;

    CBaseEntity@ pEntity;

    while( ( @pEntity = g_EntityFuncs.FindEntityByString( pEntity, "netname", g_EngineFuncs.GetPlayerAuthId( pPlayer.edict() ) ) ) !is null )
    {
        if( pEntity is null || pEntity.GetClassname() != "item_inventory" )
            continue;

        pEntity.Touch( pPlayer );
        //g_EntityFuncs.SetOrigin( pEntity, pPlayer.pev.origin );
        pEntity.pev.netname == "";// Don't automatically equip anymore.
    }

    return HOOK_CONTINUE;
}

HookReturnCode MapChange(const string& in strLevel)
{
    if( strLevel == "" || strLevel == g_Engine.mapname )
        return HOOK_CONTINUE;

    strNextMap = strLevel;
    ClearFile();
    StoreInventory();

    return HOOK_CONTINUE; 
}

}
