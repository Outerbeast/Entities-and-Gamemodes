/* Modes for adding levelchange sprites
and percent player requirement for trigger_changelevels.
Comes in handy for massive map series
- Outerbeast*/
namespace LEVELCHANGE_UTILS
{

string strSprite;
uint iPercentage;
float flScale;

void SetLevelChangeSign(const string strSpriteIn = "sprites/level_change.spr", const float flScaleIn = 0.25f) // Trigger in MapInit()
{
     g_Game.PrecacheModel( strSpriteIn );
     // !-BUG-!: If the last required player is teleported to the changelevel, for some reason when the next level loads the server crashes
     // with a late preache error flagging this specific sprite. Quantum physics can't explain this one either.
     g_Game.PrecacheModel( "sprites/voiceicon.spr" );
     strSprite = strSpriteIn;
     flScale = flScaleIn;
}

void Enable(uint iPercentageSetting = 0, int iKeepInventory = -1) // Trigger in MapStart()
{
     CBaseEntity@ pChangeLevel;
     while( ( @pChangeLevel = g_EntityFuncs.FindEntityByClassname( pChangeLevel, "trigger_changelevel" ) ) !is null )
     {
          if( iKeepInventory > -1 )
               g_EntityFuncs.DispatchKeyValue( pChangeLevel.edict(), "keep_inventory", "" + iKeepInventory );

          if( pChangeLevel.pev.SpawnFlagBitSet( 2 ) || pChangeLevel.GetTargetname() != "" || pChangeLevel.pev.solid != SOLID_TRIGGER )
               continue;

          if( strSprite != "" )
          {
               CSprite@ pLevelChangeSpr = g_EntityFuncs.CreateSprite( strSprite, pChangeLevel.pev.absmin + ( ( pChangeLevel.pev.absmax - pChangeLevel.pev.absmin ) / 2 ), false, 0.0f );
               g_EntityFuncs.DispatchKeyValue( pLevelChangeSpr.edict(), "vp_type", 0 );
               pLevelChangeSpr.SetScale( flScale );
               pLevelChangeSpr.pev.angles        = g_vecZero;
               pLevelChangeSpr.pev.nextthink     = 0.0f;
               pLevelChangeSpr.pev.rendermode    = 4;
               pLevelChangeSpr.pev.rendercolor   = g_vecZero;
               pLevelChangeSpr.pev.renderamt     = 255.0f;
          }

          if( iPercentageSetting > 0 )
          {
               iPercentage = Math.clamp( 0, 99, iPercentageSetting );
               SetPercentageRequired( EHandle( pChangeLevel ) );
          }
     }
}

void SetPercentageRequired(EHandle hChangeLevel)
{
     if( !hChangeLevel )
          return;

     g_EntityFuncs.DispatchKeyValue( hChangeLevel.GetEntity().edict(), "percent_of_players", "0." + iPercentage );
     string strMaster = string( cast<CBaseToggle@>( hChangeLevel.GetEntity() ).m_sMaster ); // When will we ever get m_sMaster in CBaseEntity?

     dictionary trgr =
     {
          { "model", "" + hChangeLevel.GetEntity().pev.model },
          { "origin", "" + hChangeLevel.GetEntity().GetOrigin().ToString() },
          { "target", "fn_" + hChangeLevel.GetEntity().entindex() },
          { "delay", "0.1" }
     };
     if( strMaster != "" )
          trgr ["master"] = "" + strMaster;
     
     dictionary fn =
     {
          { "targetname", "fn_" + hChangeLevel.GetEntity().entindex() },
          { "m_iszScriptFile", "levelchange_utils" },
          { "m_iszScriptFunctionName", "LEVELCHANGE_UTILS::LevelChangeReached" },
          { "m_iMode", "1" }
     };
     CBaseEntity@ pGoalTrgr = g_EntityFuncs.CreateEntity( "trigger_multiple", trgr, true );
     CBaseEntity@ pGoalFunc = g_EntityFuncs.CreateEntity( "trigger_script", fn, true );
}

void LevelChangeReached(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
     if( pActivator is null || !pActivator.IsPlayer() )
          return;

     CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
     // Player triggered the changelevel, great - now just keep the bastard there and wait for stragglers
     if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() && pPlayer.GetMaxSpeedOverride() < 0 )
     {
          pPlayer.pev.velocity = g_vecZero;
          pPlayer.SetMaxSpeedOverride( 0 );
          pPlayer.pev.rendermode   = kRenderTransTexture;
          pPlayer.pev.renderamt    = 100.0f;
          pPlayer.pev.solid        = SOLID_NOT; // I need this to allow players to make room
          g_PlayerFuncs.ShowMessageAll( "" + pPlayer.pev.netname + " reached the end of the level.\nWaiting for " + iPercentage + "% of all players to transition to the next level...\n" );

          if( !pPlayer.pev.FlagBitSet( FL_ONGROUND ) )
               pPlayer.pev.flags |= FL_FROZEN;
          // If a trigger_changelevel exists underwater, we don't want the players to drown...
          if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
          {
               //pPlayer.pev.flags |= FL_IMMUNE_WATER; // Doesn't work - remnant of Quake property. It exists in the API docs as if it were usable.
               //pPlayer.m_flEffectRespiration = 1000000; // Only comes into effect (or so I'm told) after calling ApplyEffects()
               //pPlayer.ApplyEffects(); // ....and it doesn't work - in fact this resets rendering for the player that was set prior!!!
               pPlayer.pev.air_finished += 1000000; // This is the only way to stop DMG_DROWN
          }
     }
}

}
