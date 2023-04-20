/* info_itemswap - Custom entity that automatically swaps weapons and ammo in the player's loadout and placed in the world.
    by Outerbeast

    Installation:-
    - Place in scripts/maps
    - Add 
    map_script info_itemswap
    to your map cfg
    OR
    - Add
    #include "info_itemswap"
    to your main map script header
    OR
    - Create a trigger_script with these keys set in your map:
    "classname" "trigger_script"
    "m_iszScriptFile" "info_itemswap"

    Usage:-
    The keyvalues simply follow this format: "<old item classname>" for the key and "<new item classname>" for the value.
    Below is an example which swaps the mp5 to m16:
    "weapon_9mmAR" "weapon_m16"
    You can add as many weapons and ammo types as you want.
    Removing this entity, via killtarget, will disable swapping, but it will not undo swaps that have already been done.

    Template entity:
    !!EPAIRS
    "classname" "info_itemswap"
    "weapon_9mmAR" "weapon_m16"
    "ammo_9mmAR" "ammo_556clip"
    "weapon_crossbow" "weapon_sniperrifle"
    "ammo_crossbow" "ammo_762"

    If you don't want to use the entity and simply wish to make the item swapping for all maps, you can use the function "ItemSwap" in MapInit
    "bool ItemSwap(dictionary dictItems)"
    function recieves a dictionary object following the same format as the entity keyvalues.
*/
enum infoitemswapflags
{
    SF_INVERT_FILTER = 1 << 0
};

bool blInfoItemSwapRegistered = RegisterInfoItemSwap();

bool RegisterInfoItemSwap()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "info_itemswap", "info_itemswap" );
    return g_CustomEntityFuncs.IsCustomEntity( "info_itemswap" );
}
// Swap items globally, call in MapInit
bool ItemSwap(dictionary dictItems)
{
    if( !g_CustomEntityFuncs.IsCustomEntity( "info_itemswap" ) )
        return false;

    return g_EntityFuncs.CreateEntity( "info_itemswap", dictItems ) !is null;
}

final class info_itemswap : ScriptBaseEntity
{
    private array<ItemMapping@> IM_ITEMS;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( IM_ITEMS.findByRef( ItemMapping( szKey, szValue ) ) < 0 )
            IM_ITEMS.insertLast( ItemMapping( szKey, szValue ) );
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Precache()
    {   // Probably unecessary.
        for( uint w = 0; w < IM_ITEMS.length(); w++ )
        {
            if( IM_ITEMS[w].get_To() == "" )
                continue;

            g_Game.PrecacheOther( IM_ITEMS[w].get_To() );
        }

        BaseClass.Precache();
    }

    void Spawn()
    {
        self.Precache();

        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        g_ClassicMode.SetItemMappings( @IM_ITEMS );
        g_ClassicMode.ForceItemRemap( g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, MaterializeHook( this.SwapItem ) ) );

        BaseClass.Spawn();
    }

    bool CanReplace(string strTargetname)
    {
        if( self.pev.target == "" )
            return true;

        return !self.pev.SpawnFlagBitSet( SF_INVERT_FILTER ) ? self.pev.target == strTargetname : self.pev.target != strTargetname;
    }

    HookReturnCode SwapItem(CBaseEntity@ pOldItem)
    {
        if( pOldItem is null || !CanReplace( pOldItem.GetTargetname() ) ) 
            return HOOK_CONTINUE;

        for( uint w = 0; w < IM_ITEMS.length(); w++ )
        {
            if( pOldItem.GetClassname() != IM_ITEMS[w].get_From() || IM_ITEMS[w].get_To() == "" )
                continue;

            CBaseEntity@ pNewItem = g_EntityFuncs.Create( IM_ITEMS[w].get_To(), pOldItem.pev.origin, pOldItem.pev.angles, true );

            if( pNewItem is null ) 
                continue;

            pNewItem.pev.spawnflags = pOldItem.pev.spawnflags;
            pNewItem.pev.movetype = pOldItem.pev.movetype;
            pNewItem.pev.rendermode = pNewItem.m_iOriginalRenderMode = pOldItem.m_iOriginalRenderMode;
            pNewItem.pev.renderfx = pNewItem.m_iOriginalRenderFX = pOldItem.m_iOriginalRenderFX;
            pNewItem.pev.renderamt = pNewItem.m_flOriginalRenderAmount = pOldItem.m_flOriginalRenderAmount;
            pNewItem.pev.rendercolor = pNewItem.m_vecOriginalRenderColor = pOldItem.m_vecOriginalRenderColor;

            if( pOldItem.GetTargetname() != "" )
                pNewItem.pev.targetname = pOldItem.GetTargetname();

            if( pOldItem.pev.target != "" )
                pNewItem.pev.target = pOldItem.pev.target;

            if( pOldItem.pev.netname != "" )
                pNewItem.pev.netname = pOldItem.pev.netname;

            CBasePlayerWeapon@
                pOldWeapon = cast<CBasePlayerWeapon@>( pOldItem ), 
                pNewWeapon = cast<CBasePlayerWeapon@>( pNewItem );

            if( pOldWeapon !is null && pNewWeapon !is null )
            {
                pNewWeapon.m_flDelay = pOldWeapon.m_flDelay;
                pNewWeapon.m_bExclusiveHold = pOldWeapon.m_bExclusiveHold;

                if( pOldWeapon.m_iszKillTarget != "" )
                    pNewWeapon.m_iszKillTarget = pOldWeapon.m_iszKillTarget;
            }

            if( g_EntityFuncs.DispatchSpawn( pNewItem.edict() ) < 0 )
                continue;

            g_EntityFuncs.Remove( pOldItem );
        }
        
        return HOOK_CONTINUE;
    }

    void UpdateOnRemove()
    {
        g_Hooks.RemoveHook( Hooks::PickupObject::Materialize, MaterializeHook( this.SwapItem ) );
        g_ClassicMode.SetItemMappings( null );
    }
};
