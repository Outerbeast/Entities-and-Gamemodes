/* player_weapon_config
    Custom entity to automatically modify an exisiting weapon in player's loadout.
    A selected weapon that is configured with this entity will replace the stock weapon in every player's loadout if they are holding the weapon.

    Installation:-
    - Place in scripts/maps
    - Add 
    map_script player_weapon_config
    to your map cfg
    OR
    - Add
    #include "player_weapon_config"
    to your main map script header
    OR
    - Create a trigger_script with these keys set in your map:
    "classname" "trigger_script"
    "m_iszScriptFile" "player_weapon_config"

    Keys:-
    "weapontype" "weapon_classname" - classname of the weapon you wish to preconfigure e.g. "weapontype" "weapon_m16"
    "targetname" "target_me" - When a targetname is set, automatic weapon configuration is disabled, requiring manual triggering. The activator of the entity will be equipped with the customised weapon.

    For configuration, this entity uses the same keys as a standalone weapon entity does, as well as the weapon_displacer specific keys. You should already be familiar with these.

    Flags:
    "spawnflags" "f"
    "1": Configure world weapons - Automatically configures weapons that spawn in the level, instead of only in the player's loadout
    "2": Force equip - When triggered, forces equipping of the configured weapon even the player already has it in their loadout. Only applicable when the entity has a targetname.

    The entity uses the standard weapon_displacer specific flags if the weapontype is weapon_displacer.

    Issues:-
    - "Configure world weapons" flag: Weapons spawned from breakables or other means only receive configuration when they are able to be picked up.
    If its set to use custom models, the weapon will appear to look like the stock version before switiching to the custom version for a brief moment.

    - Outerbeast
*/
enum playerweaponconfigflags
{
    SF_CONFIG_WORLD_WEAPONS = 1 << 0,
    SF_FORCE_EQUIP          = 1 << 1
};

enum displacerflags
{
    SF_RAND_DEST            = 1 << 6,
    SF_ROTATE_DEST_ANGLES   = 1 << 7,
    SF_KEEP_ANGLES          = 1 << 8,
    SF_KEEP_VELOCITY        = 1 << 9,
    SF_DISABLE_RESPAWN      = 1 << 10,
    SF_IGNORE_DELAY         = 1 << 12
};

bool blPlayerWeaponConfigRegistered = RegisterPlayerWeaponConfig();

bool RegisterPlayerWeaponConfig()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "player_weapon_config", "player_weapon_config" );
    return g_CustomEntityFuncs.IsCustomEntity( "player_weapon_config" );
}

bool WeaponConfig(dictionary dictKeys)
{
    if( !g_CustomEntityFuncs.IsCustomEntity( "player_weapon_config" ) )
        return false;

    return g_EntityFuncs.CreateEntity( "player_weapon_config", dictKeys ) !is null;
}

final class player_weapon_config : ScriptBaseEntity
{
    private EHandle hPreConfigWeapon;

    private CBasePlayerWeapon@ pPreConfigWeapon
    {
        get { return cast<CBasePlayerWeapon@>( hPreConfigWeapon.GetEntity() ); }
        set { hPreConfigWeapon = EHandle( @value ); }
    }

    private dictionary
        dictWeaponKeys =
        {
            { "wpn_v_model", "" },
            { "wpn_w_model", "" },
            { "wpn_p_model", "" },
            { "soundlist", "" },
            { "CustomSpriteDir", "" }
        },
        dictDisplacerKeys =
        {
            { "m_iszTeleportDestination", "" },
            { "m_TertiaryMode", "" },
            { "m_flPortalSpeed", "" },
            { "m_flPortalRadius", "" },
            { "m_flPrimaryAmmoNeeded", "" },
            { "m_flSecondaryAmmoNeeded", "" },
            { "m_flTertiaryAmmoNeeded", "" }
        };

    private string strWeaponType;
    private bool m_bExclusiveHold;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( dictWeaponKeys.exists( szKey ) )
            dictWeaponKeys[szKey] = szValue;
        else if( dictDisplacerKeys.exists( szKey ) )
           dictDisplacerKeys[szKey] = szValue;
        else if( szKey == "weapontype" )
            strWeaponType = szValue;
        else if( szKey == "exclusivehold" )
            m_bExclusiveHold = atoi( szValue ) > 0;
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Precache()
    {
        array<string> STR_KEYS = dictWeaponKeys.getKeys(), STR_DISPLACER_KEYS = dictDisplacerKeys.getKeys();

        for( uint i = 0; i < STR_KEYS.length(); i++ )
        {
            if( string( dictWeaponKeys[STR_KEYS[i]] ) == "" )
                continue;

            if( STR_KEYS[i] == "wpn_v_model" || 
                STR_KEYS[i] == "wpn_w_model" || 
                STR_KEYS[i] == "wpn_p_model" )
                g_Game.PrecacheModel( string( dictWeaponKeys[STR_KEYS[i]] ) );

            if( STR_KEYS[i] == "soundlist" )
                g_Game.PrecacheGeneric( string( dictWeaponKeys[STR_KEYS[i]] ) );
            // Does the game need to precache the actual spr file?
            if( STR_KEYS[i] == "CustomSpriteDir" )
                g_Game.PrecacheGeneric( "sprites/" + string( dictWeaponKeys[STR_KEYS[i]] ) + "/" + strWeaponType + ".txt" );
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

        if( strWeaponType == "" )
            return;

        @pPreConfigWeapon = cast<CBasePlayerWeapon@>( g_EntityFuncs.CreateEntity( strWeaponType, dictWeaponKeys, false ) );
        pPreConfigWeapon.pev.spawnflags |= 384;
        ConfigWeapon( pPreConfigWeapon );

        if( self.pev.SpawnFlagBitSet( SF_CONFIG_WORLD_WEAPONS ) )
            g_Hooks.RegisterHook( Hooks::PickupObject::Materialize, MaterializeHook( this.ItemSpawned ) );

        if( self.GetTargetname() == "" )
            g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, PlayerSpawnHook( this.PlayerSpawn ) );

        BaseClass.Spawn();
    }

    void ConfigWeapon(EHandle hWeapon)
    {
        if( !hWeapon )
            return;

        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( hWeapon.GetEntity() );

        if( pWeapon is null || bool( pWeapon.GetUserData( "b_configured" ) ) )
            return;

        pWeapon.pev.dmg = self.pev.dmg;
        pWeapon.m_bExclusiveHold = m_bExclusiveHold;

        array<string> STR_KEYS = dictWeaponKeys.getKeys(), STR_DISPLACER_KEYS;

        for( uint i = 0; i < STR_KEYS.length(); i++ )
        {
            if( string( dictWeaponKeys[STR_KEYS[i]] ) == "" )
                continue;

            g_EntityFuncs.DispatchKeyValue( pWeapon.edict(), STR_KEYS[i], string( dictWeaponKeys[STR_KEYS[i]] ) );
        }

        if( pWeapon.GetClassname() == "weapon_displacer" )
        {
            STR_DISPLACER_KEYS = dictDisplacerKeys.getKeys();

            for( uint i = 0; i < STR_DISPLACER_KEYS.length(); i++ )
            {
                if( string( dictWeaponKeys[STR_DISPLACER_KEYS[i]] ) == "" )
                    continue;

                g_EntityFuncs.DispatchKeyValue( pWeapon.edict(), STR_DISPLACER_KEYS[i], string( dictDisplacerKeys[STR_DISPLACER_KEYS[i]] ) );
            }
            // Flags only really matter for displacer
            pWeapon.pev.spawnflags = self.pev.spawnflags;
        }

        g_EntityFuncs.DispatchSpawn( pWeapon.edict() );// Fixes bullshit with custom world model not applying. Thanks KernCore :]
        pWeapon.GetUserData()["b_configured"] = true;
    }

    void EquipCustomisedWeapon(EHandle hPlayer)
    {
        if( hPlayer )
            pPreConfigWeapon.Use( hPlayer.GetEntity(), hPlayer.GetEntity(), USE_TOGGLE, 0.0f );
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( pActivator is null || !pActivator.IsPlayer() || pPreConfigWeapon is null || strWeaponType == "" )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );

        if( pPlayer.HasPlayerItem( pPreConfigWeapon ) && !self.pev.SpawnFlagBitSet( SF_FORCE_EQUIP ) )
            return;

        if( pPlayer.HasNamedPlayerItem( strWeaponType ) !is null )
        {
            if( !pPlayer.RemovePlayerItem( pPlayer.HasNamedPlayerItem( strWeaponType ) ) )
                return;
        }

        EquipCustomisedWeapon( pActivator );
    }

    HookReturnCode ItemSpawned(CBaseEntity@ pItem)
    {
        if( pItem is null )
            return HOOK_CONTINUE;

        CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pItem );

        if( pWeapon is null || pWeapon.GetClassname() != strWeaponType || bool( pWeapon.GetUserData( "b_configured" ) ) )
            return HOOK_CONTINUE;

        ConfigWeapon( pWeapon );

        return HOOK_CONTINUE;
    }

    HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
    {
        if( pPlayer is null || pPreConfigWeapon is null || strWeaponType == "" )
            return HOOK_CONTINUE;

        if( pPlayer.HasNamedPlayerItem( strWeaponType ) !is null )
        {
            if( pPlayer.RemovePlayerItem( pPlayer.HasNamedPlayerItem( strWeaponType ) ) )
                g_Scheduler.SetTimeout( this, "EquipCustomisedWeapon", 0.01f, EHandle( pPlayer ) );
        }

        return HOOK_CONTINUE;
    }

    void UpdateOnRemove()
    {
        g_Hooks.RemoveHook( Hooks::PickupObject::Materialize, MaterializeHook( this.ItemSpawned ) );
        g_Hooks.RemoveHook( Hooks::Player::PlayerSpawn, PlayerSpawnHook( this.PlayerSpawn ) );
    }
}