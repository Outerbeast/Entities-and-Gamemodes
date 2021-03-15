/* Modes for adding levelchange sprites
and percent player requirement for trigger_changelevels.
Comes in handy for massive map series
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

void Enable(uint iPercentage = 0) // Trigger in MapStart()
{
     CBaseEntity@ pChangeLvl;
     while( ( @pChangeLvl = g_EntityFuncs.FindEntityByClassname( pChangeLvl, "trigger_changelevel" ) ) !is null )
     {
          if( pChangeLvl.pev.SpawnFlagBitSet( 2 ) || pChangeLvl.GetTargetname() != "" || pChangeLvl.pev.solid != SOLID_TRIGGER || pChangeLvl.pev.movetype == MOVETYPE_PUSH )
               continue;

          if( strSprite != "" )
          {
               CSprite@ pLevelChangeSpr = g_EntityFuncs.CreateSprite( strSprite, pChangeLvl.pev.absmin + ( ( pChangeLvl.pev.absmax - pChangeLvl.pev.absmin ) / 2 ), false, 0.0f );
               g_EntityFuncs.DispatchKeyValue( pLevelChangeSpr.edict(), "vp_type", 0 );
               pLevelChangeSpr.SetScale( iScale );
               pLevelChangeSpr.pev.angles        = g_vecZero;
               pLevelChangeSpr.pev.nextthink     = 0.0f;
               pLevelChangeSpr.pev.rendermode    = 4;
               pLevelChangeSpr.pev.rendercolor   = g_vecZero;
               pLevelChangeSpr.pev.renderamt     = 255.0f;
          }

          if( iPercentage > 0 )
               SetPercentageRequired( EHandle( pChangeLvl ), Math.clamp( 0, 99, iPercentage ) );
     }
}

void SetPercentageRequired(EHandle hChangeLevel, uint iPercentage)
{
     if( !hChangeLevel )
          return;

     g_EntityFuncs.DispatchKeyValue( hChangeLevel.GetEntity().edict(), "percent_of_players", "" + iPercentage );

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
          g_PlayerFuncs.CenterPrintAll( "" + pCaller.pev.health + "% of players are required to progress to the next level.\n" );
     }
}

}