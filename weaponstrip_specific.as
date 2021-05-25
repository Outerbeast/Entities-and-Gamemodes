/* weaponstrip_specific
trigger_script for stripping specified weapons, or keeping specified weapons and stripping everything else

Template keys:-
"classname" "trigger_script"
"m_iszScriptFile" "weaponstrip_specific"
"m_iszScriptFunctionName" "WEAPONSTRIP_SPECIFIC::Trigger"
"m_iMode" "1"
// Don't change any of the above
"targetname" "target_me"
"$s_strip" "weapon_9mmhandgun;weapon_egon;weapon_hornetgun;weapon_eagle" - semicolon seperated list of weapons to strip (or keep)
"$s_targetname_filter"  - Filters only for players with the set targetname
"spawnflags" "f"        - see "weaponstrip_flags" enum for settings

- Outerbeast
*/
namespace WEAPONSTRIP_SPECIFIC
{

enum weaponstrip_flags
{
    START_ON            = 1,    // Entity starts active on map start
    ACTIVATOR_ONLY      = 2,    // Only the activating player gets stripped
    KEEP_WEAPONS        = 4     // Inverts selection - strips everything else but the specified weapons
};

EHandle TriggerScriptInstance(EHandle hCaller, const string strIdentifier)
{
    if( !hCaller || strIdentifier == "" )
        return EHandle( null );
    
    CBaseEntity@ pTemp, pTriggerScript;
    CustomKeyvalues@ kvTriggerScript;

    while( ( @pTemp = g_EntityFuncs.FindEntityByTargetname( pTemp, "" + hCaller.GetEntity().pev.target ) ) !is null )
    {
        if( pTemp is null || pTemp.GetClassname() != "trigger_script" )
            continue;
        
        @kvTriggerScript = pTemp.GetCustomKeyvalues();

        if( kvTriggerScript is null || !kvTriggerScript.HasKeyvalue( "" + strIdentifier ) )
        {
            @kvTriggerScript = null;
            continue;
        }
        
        @pTriggerScript = pTemp;
        break;
    }
    return EHandle( pTriggerScript );
}

void Trigger(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
    if( pActivator is null || pCaller is null || useType == USE_OFF )
        return;

    CBaseEntity@ pTriggerScript = TriggerScriptInstance( EHandle( pCaller ), "$s_strip" ).GetEntity();
    CustomKeyvalues@ kvTriggerScript = pTriggerScript.GetCustomKeyvalues();

    if( pTriggerScript is null || kvTriggerScript is null )
        return;

    array<string> STR_STRIPWEAPONS = kvTriggerScript.GetKeyvalue( "$s_strip" ).GetString().Split( ";" );
    string strTargetnameFilter = kvTriggerScript.HasKeyvalue( "$s_targetname_filter" ) ? kvTriggerScript.GetKeyvalue( "$s_targetname_filter" ).GetString() : "";

    if( pActivator.IsPlayer() && pTriggerScript.pev.SpawnFlagBitSet( ACTIVATOR_ONLY ) )
        Strippery( EHandle( pActivator ), @STR_STRIPWEAPONS, pTriggerScript.pev.SpawnFlagBitSet( KEEP_WEAPONS ) );
    else
    {
        for( int playerID = 1; playerID <= g_Engine.maxClients; playerID++ )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( playerID );

            if( pPlayer is null || !pPlayer.IsConnected() )
                continue;
            
            if( strTargetnameFilter != "" && pPlayer.GetTargetname() != strTargetnameFilter )
                continue;

            Strippery( EHandle( pPlayer ), @STR_STRIPWEAPONS, pTriggerScript.pev.SpawnFlagBitSet( KEEP_WEAPONS ) );
        }
    }
}

void Strippery(EHandle hPlayer, array<string>@ STR_STRIPWEAPONS, const bool blInvertSelection)
{
    if( !hPlayer || STR_STRIPWEAPONS.length() < 1 )
        return;
    
    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    if( !blInvertSelection )
    {
        for( uint i = 0; i < STR_STRIPWEAPONS.length(); i++ )
        {
            if( pPlayer.HasNamedPlayerItem( STR_STRIPWEAPONS[i] ) is null ||
                STR_STRIPWEAPONS[i] == "" ||
                STR_STRIPWEAPONS[i].Find( " ", 0, String::CaseInsensitive ) != String::INVALID_INDEX )
                continue;

            pPlayer.RemovePlayerItem( pPlayer.HasNamedPlayerItem( STR_STRIPWEAPONS[i] ) );
        }
    }
    else
    {
        CBasePlayerItem@ pItem;
        CBasePlayerWeapon@ pWeapon;

        for( uint j = 0; j < MAX_ITEM_TYPES; j++ )
        {
            @pItem = pPlayer.m_rgpPlayerItems( j );

            while( pItem !is null )
            {
                @pWeapon = pItem.GetWeaponPtr();
                
                if( STR_STRIPWEAPONS.find( pWeapon.GetClassname() ) < 0 )
                    pPlayer.RemovePlayerItem( pItem );

                @pItem = cast<CBasePlayerItem@>( pItem.m_hNextItem.GetEntity() );
            }
        }
    }
}

}
