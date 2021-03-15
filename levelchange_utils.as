/* Modes for adding levelchange sprites
and percent player requirement for trigger_changelevels.
Comes in handy for massive map series

!-BUGS-! - Cannot specifically prevent drown damage (L91-L96) - have to just set DAMAGE_NO xc
- Outerbeast*/
namespace LEVELCHANGE_UTILS
{

string strSprite;
uint iScale;

void SetLevelChangeSign(const string strSpriteIn = "sprites/level_change.spr", const uint iScaleIn = 0.25) // Trigger in MapInit()
{
     g_Game.PrecacheModel( strSpriteIn );
     strSprite = strSpriteIn;
     iScale = iScaleIn;
}

void Enable(uint iPercentage = 0, int iKeepInventory = -1) // Trigger in MapStart()
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
               pLevelChangeSpr.SetScale( iScale );
               pLevelChangeSpr.pev.angles        = g_vecZero;
               pLevelChangeSpr.pev.nextthink     = 0.0f;
               pLevelChangeSpr.pev.rendermode    = 4;
               pLevelChangeSpr.pev.rendercolor   = g_vecZero;
               pLevelChangeSpr.pev.renderamt     = 255.0f;
          }

          if( iPercentage > 0 )
               SetPercentageRequired( EHandle( pChangeLevel ), Math.clamp( 0, 99, iPercentage ) );
     }
}

void SetPercentageRequired(EHandle hChangeLevel, uint iPercentage)
{
     if( !hChangeLevel )
          return;

     g_EntityFuncs.DispatchKeyValue( hChangeLevel.GetEntity().edict(), "percent_of_players", "" + iPercentage );
     g_EngineFuncs.ServerPrint( "-- LeveLChangeUtils: Added percentage " + iPercentage + "%\n" );

     dictionary trgr =
     {
          { "model", "" + hChangeLevel.GetEntity().pev.model },
          { "target", "fn_" + hChangeLevel.GetEntity().entindex() },
          { "delay", "0.1" }
     };
     dictionary fn =
     {
          { "targetname", "fn_" + hChangeLevel.GetEntity().entindex() },
          { "m_iszScriptFile", "levelchange_utils" },
          { "m_iszScriptFunctionName", "LEVELCHANGE_UTILS::LevelChangeReached" },
          { "m_iMode", "1" }
     };
     CBaseEntity@ pGoalTrgr = g_EntityFuncs.CreateEntity( "trigger_multiple", trgr, true );
     CBaseEntity@ pGoalFunc = g_EntityFuncs.CreateEntity( "trigger_script", fn, true );

     if( pGoalTrgr !is null )
          pGoalTrgr.pev.health = iPercentage;
}

void LevelChangeReached(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
     if( pActivator is null || !pActivator.IsPlayer() )
          return;

     CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
     
     if( pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() && pPlayer.GetMaxSpeedOverride() < 0 )
     {
          pPlayer.SetMaxSpeedOverride( 0 );
          pPlayer.pev.rendermode  = kRenderTransTexture;
          pPlayer.pev.renderamt   = 100.0f;
          g_PlayerFuncs.CenterPrintAll( "" + pCaller.pev.health + "percent of players are required to progress to the next level.\n" );

          if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
          {    // Can't prevent drown damage with any of these methods!!
               pPlayer.pev.flags |= FL_IMMUNE_WATER; // Doesn't work
               pPlayer.m_flEffectRespiration = 3600; // Doesn't work
               // Only one thing left to do...
               //pPlayer.pev.takedamage = DAMAGE_NO;

               pPlayer.pev.flags |= FL_FROZEN;
               g_EngineFuncs.ServerPrint( "-- LevelChangedReached: " + pPlayer.pev.netname + " is immune to water!\n" ); //...oh I wish.
          }
     }
}

}