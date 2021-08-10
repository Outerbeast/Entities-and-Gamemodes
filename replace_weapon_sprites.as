/* Script to override hud sprites for weapons with your custom ones
Usage:-
Call this code in MapInit block in your map script:

" REPLACE_WEAPON_SPRITES::SetReplacements( "path/to/sprites", "hudsprite01;hudsprite02", "weapon_balls;weapon_pants;weapon_..." ); "
-First parameter: sets the path of the sprites - you can put "" if you're not using it
-Second paramater: semicolon seperated list of the sprites containing the hud elements
-Final parameter: semicolon seperated list of the weapons you want to have replaced hud sprites

If for some reason you want to disable sprites being replaced for certain maps, put this cvar followed by a semicolon seperated
list of weapons you want ignored in your desired map cfg file:

"as_command rws_ignore_weapons weapon_balls;weapon_pants;weapon_..."

- Outerbeast
*/
CCVar cvarIgnoreWeaponSprReplacement( "rws_ignore_weapons", "", "Prevent this weapon from getting custom sprites in this map", ConCommandFlag::AdminOnly );

namespace REPLACE_WEAPON_SPRITES
{

string strDirPath;
array<string> STR_WEAPONS;

void SetReplacements(string strRootIn = "", string strHudSprs = "", string strWeapons = "")
{
    if( strHudSprs == "" || strWeapons == "" )
        return;

    strDirPath = strRootIn == "" ? "" : strRootIn + "/";
    STR_WEAPONS = strWeapons.Split( ";" );
    const array<string> STR_HUD_SPRS = strHudSprs.Split( ";" );

    if( STR_HUD_SPRS.length() < 1 || STR_WEAPONS.length() < 1 )
        return;

    for( uint i = 0; i < STR_HUD_SPRS.length(); i++ )
    {
        g_Game.PrecacheModel( "sprites/" + strDirPath + STR_HUD_SPRS[i] + ".spr" );
        g_Game.PrecacheGeneric( "sprites/" + strDirPath + STR_HUD_SPRS[i] + ".spr" );
    }

    for( uint j = 0; j < STR_WEAPONS.length(); j++ )
        g_Game.PrecacheGeneric( "sprites/" + strDirPath + STR_WEAPONS[j] + ".txt" );

    g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, PlayerJoined );
    g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, PlayerJoined );
    g_Hooks.RegisterHook( Hooks::PickupObject::Collected, ItemCollected );
}

void ChangeWpnHudSpr(EHandle hPlayer, EHandle hWeapon)
{
    if( !hPlayer || !hWeapon )
        return;

    CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( hWeapon.GetEntity() );

    if( pWeapon is null )
        return;

    if( STR_WEAPONS.find( pWeapon.GetClassname() ) >= 0 )
    {
        if( cvarIgnoreWeaponSprReplacement.GetString() != "" && 
            cvarIgnoreWeaponSprReplacement.GetString().Split( ";" ).find( pWeapon.GetClassname() ) >= 0 )
                return;

        pWeapon.LoadSprites( cast<CBasePlayer@>( hPlayer.GetEntity() ), strDirPath + pWeapon.GetClassname() );
    }
}

HookReturnCode PlayerJoined(CBasePlayer@ pPlayer)
{
    if( pPlayer is null )
        return HOOK_CONTINUE;
    // !-BUG-!: HasNamedPlayerItem handle is not valid when the player spawns (assuming), must get it a millisecond later
    for( uint i = 0; i < STR_WEAPONS.length(); i++ )
        g_Scheduler.SetTimeout( "ChangeWpnHudSpr", 0.01f, EHandle( pPlayer ), EHandle( pPlayer.HasNamedPlayerItem( STR_WEAPONS[i] ) ) );

    return HOOK_CONTINUE;
}

HookReturnCode ItemCollected(CBaseEntity@ pPickup, CBaseEntity@ pOther)
{
    if( pPickup is null || pOther is null || !pOther.IsPlayer() || cast<CBasePlayerWeapon@>( pPickup ) is null )
        return HOOK_CONTINUE;

    ChangeWpnHudSpr( pOther, pPickup );

    return HOOK_CONTINUE;
}

}
/* Special thanks to:
KernCore for scripting support */