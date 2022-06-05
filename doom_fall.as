/* doom_fall by Outerbeast
trigger_script that creates a zone at which a player falling at a certain velocity will be sure to take mortal fall damage.
They will go SPLAT.

Template entity:-
"classname" "trigger_script"
"m_iszScriptFile" "doom_fall"
"m_iszScriptFunctionName" "DOOMFALL::FallZone"
"m_iMode" "2"
// Don't change any of the above
"$s_brush" "*m"             - Brush model to provide bounds
"$v_mins" "x1 y1 z1"        - absmin bound coord for zone
"$v_maxs" "x2 y2 z2"        - absmax bound coord for zone
"speed" "s"                 - fall velocity threshold at which point a player will take mortal fall damage when they land at this speed. Default is 700.
"gravity" "g"               - gravity modifier for player falling. Applied when the player's fall velocity reaches "speed".
"message" "target_entity"   - entity to trigger when a falling player's fall velocity exceeds "speed". Activator is the player falling.
"netname" "target_entity"   - entity to trigger after a player lands on the ground. Activator is the player who fell.

If no or invalid min/max bounds for the death zone are set, the entire level is used
*/
namespace DOOMFALL
{

array<Vector> VEC_PLAYER_FALL_DATA( g_Engine.maxClients + 1 );

const bool blPlayerSpawnHook        = g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, OnGround );
const bool blPlayerPreThinkHook     = g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, Fall );
const bool blPlayerPostThinkHook    = g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, Splat );

EHandle Enable(float flMortalVelocity, float flGravityModifier)
{
    dictionary dictDoomfall =
    {
        { "m_iszScriptFile", "doom_fall" },
        { "m_iszScriptFunctionName", "DOOMFALL::FallZone" },
        { "m_iMode", "2" },
        { "speed", "" + flMortalVelocity },
        { "gravity", "" + flGravityModifier }
    };

    return( g_EntityFuncs.CreateEntity( "trigger_script", dictDoomfall ) );
}

void FallZone(CBaseEntity@ pTriggerScript)
{
    Vector vecAbsMin = Vector( -WORLD_BOUNDARY, -WORLD_BOUNDARY, -WORLD_BOUNDARY ), vecAbsMax = Vector( WORLD_BOUNDARY, WORLD_BOUNDARY, WORLD_BOUNDARY );
    bool blBoundsSet = SetBounds( EHandle( pTriggerScript ), vecAbsMin, vecAbsMax );

    pTriggerScript.pev.mins = vecAbsMin - pTriggerScript.GetOrigin();
    pTriggerScript.pev.maxs = vecAbsMax - pTriggerScript.GetOrigin();
    g_EntityFuncs.SetSize( pTriggerScript.pev, pTriggerScript.pev.mins, pTriggerScript.pev.maxs );

    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );
        
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
        {
            VEC_PLAYER_FALL_DATA[iPlayer] = g_vecZero;
            continue;
        }

        VEC_PLAYER_FALL_DATA[iPlayer].z = pPlayer.Intersects( pTriggerScript ) ? pTriggerScript.entindex() : 0;
    }
}

HookReturnCode OnGround(CBasePlayer@ pPlayer)
{
    if( pPlayer is null )
        return HOOK_CONTINUE;

    VEC_PLAYER_FALL_DATA[pPlayer.entindex()] = g_vecZero;

    return HOOK_CONTINUE;
}

HookReturnCode Fall(CBasePlayer@ pPlayer, uint& out uiFlags)
{
    if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() || VEC_PLAYER_FALL_DATA[pPlayer.entindex()].z < 1 )
        return HOOK_CONTINUE;

    CBaseEntity@ pFallZone = g_EntityFuncs.Instance( int( VEC_PLAYER_FALL_DATA[pPlayer.entindex()].z ) );

    if( pFallZone.pev.speed <= 0.0f )
        pFallZone.pev.speed = 700.0f;
    
    if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) && !pPlayer.pev.FlagBitSet( FL_INWATER ) && !pPlayer.IsOnLadder() )
    {
        VEC_PLAYER_FALL_DATA[pPlayer.entindex()].x = pPlayer.m_flFallVelocity;

        if( VEC_PLAYER_FALL_DATA[pPlayer.entindex()].x >= pFallZone.pev.speed && VEC_PLAYER_FALL_DATA[pPlayer.entindex()].y < 1 )
        {
            VEC_PLAYER_FALL_DATA[pPlayer.entindex()].y = 1;
            g_EntityFuncs.FireTargets( pFallZone.pev.message, pPlayer, pFallZone, USE_ON, 0.0f, 0.0f );

            if( pFallZone.pev.gravity > 1 )
                pPlayer.pev.gravity = pFallZone.pev.gravity;
        }
    }
    else
        VEC_PLAYER_FALL_DATA[pPlayer.entindex()] = g_vecZero;
    
    return HOOK_CONTINUE;
}

HookReturnCode Splat(CBasePlayer@ pPlayer)
{
    if( pPlayer is null || !pPlayer.IsConnected() || VEC_PLAYER_FALL_DATA[pPlayer.entindex()].z < 1 )
        return HOOK_CONTINUE;
    
    if( pPlayer.pev.FlagBitSet( FL_ONGROUND ) && VEC_PLAYER_FALL_DATA[pPlayer.entindex()].y > 0 )
    {
        CBaseEntity@ pFallZone = g_EntityFuncs.Instance( int( VEC_PLAYER_FALL_DATA[pPlayer.entindex()].z ) );

        if( pPlayer.pev.FlagBitSet( FL_GODMODE ) )
            pPlayer.pev.flags &= ~FL_GODMODE;

        g_EntityFuncs.Remove( pPlayer );

        if( !pPlayer.IsAlive() )
        {
            VEC_PLAYER_FALL_DATA[pPlayer.entindex()].y = 0;
            g_EntityFuncs.FireTargets( pFallZone.pev.netname, pPlayer, pFallZone, USE_ON, 0.0f, 0.0f );

            if( pPlayer.pev.gravity == pFallZone.pev.gravity )
                pPlayer.pev.gravity = 1;
        }
    }

    return HOOK_CONTINUE;
}

bool SetBounds(EHandle hTriggerScript, Vector& out vecMin, Vector& out vecMax)
{
    if( !hTriggerScript )
        return false;

    CustomKeyvalues@ kvTriggerScript = hTriggerScript.GetEntity().GetCustomKeyvalues();

    if( kvTriggerScript.HasKeyvalue( "$s_brush" ) )
    {
        CBaseEntity@ pBBox = g_EntityFuncs.FindEntityByString( pBBox, "model", "" + kvTriggerScript.GetKeyvalue( "$s_brush" ).GetString() );

        if( pBBox !is null && pBBox.IsBSPModel() )
        {
            vecMin = pBBox.pev.absmin;
            vecMax = pBBox.pev.absmax;

            return true;
        }
        else
            return false;
    }
    else if( kvTriggerScript.HasKeyvalue( "$v_mins" ) && kvTriggerScript.HasKeyvalue( "$v_maxs" ) )
    {
        if( kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector() != kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector() )
        {
            vecMin = kvTriggerScript.GetKeyvalue( "$v_mins" ).GetVector();
            vecMax = kvTriggerScript.GetKeyvalue( "$v_maxs" ).GetVector();

            return true;
        }
        else
            return false;
    }
    else
        return false;
}

}
/* Special thanks to:-
-Zode for extensive support, testing and proofreading
and others I've asked help from for minor things:
-KernCore
-H2 */