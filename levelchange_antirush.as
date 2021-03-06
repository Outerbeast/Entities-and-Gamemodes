/* Adds a percentage of players required to change the level
Option to add level change sign sprites to indicate level change location
Comes in handy for massive map series
- Outerbeast */
namespace LEVELCHANGE_ANTIRUSH
{

string         strSprite;
uint           iPercentage;
float          flScale;
float          flChangeLevelTimeout = 300.0f;
bool           blTimeoutSet;
array<EHandle> H_TIMEOUT_CHANGELEVELS;

void SetLevelChangeSign(const string strSpriteIn = "sprites/level_change.spr", const float flScaleIn = 0.25f) // Trigger in MapInit()
{
     g_Game.PrecacheModel( strSpriteIn );
     // !-BUG-!: If the last required player is teleported to the changelevel, for some reason when the next level loads the server crashes
     // with a late preache error flagging this specific sprite. Quantum physics can't explain this one either.
     g_Game.PrecacheModel( "sprites/voiceicon.spr" );
     strSprite = strSpriteIn;
     flScale = flScaleIn;
}

void Enable(uint iPercentageSetting = 66, int iKeepInventory = -1) // Trigger in MapStart()
{
     CBaseEntity@ pChangeLevel;
     while( ( @pChangeLevel = g_EntityFuncs.FindEntityByClassname( pChangeLevel, "trigger_changelevel" ) ) !is null )
     {
          if( pChangeLevel is null )
               continue;

          if( iKeepInventory > -1 )
               g_EntityFuncs.DispatchKeyValue( pChangeLevel.edict(), "keep_inventory", "" + iKeepInventory );

          if( pChangeLevel.pev.SpawnFlagBitSet( 2 ) || pChangeLevel.pev.solid != SOLID_TRIGGER )
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

     if( flChangeLevelTimeout > 0.0f )
          H_TIMEOUT_CHANGELEVELS.insertLast( hChangeLevel ); // the level may have several changelevel triggers

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
          { "m_iszScriptFile", "LEVELCHANGE_ANTIRUSH" },
          { "m_iszScriptFunctionName", "LEVELCHANGE_ANTIRUSH::LevelChangeReached" },
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
          pPlayer.BlockWeapons( null );
          pPlayer.pev.rendermode   = kRenderTransTexture;
          pPlayer.pev.renderamt    = 100.0f;
          pPlayer.pev.solid        = SOLID_NOT; // I need this to allow players to make room
          pPlayer.pev.takedamage   = DAMAGE_NO;
          pPlayer.pev.flags       |= FL_NOTARGET;
         
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

          g_PlayerFuncs.ShowMessageAll( "" + pPlayer.pev.netname + " reached the end of the level.\nWaiting for " + iPercentage + "% of all players to transition to the next level...\n" );
     }

     if( flChangeLevelTimeout > 0.0f && !blTimeoutSet )
     {
          for( uint i = 0; i < H_TIMEOUT_CHANGELEVELS.length(); i++ )
          {
               if( !H_TIMEOUT_CHANGELEVELS[i] || !pActivator.Intersects( H_TIMEOUT_CHANGELEVELS[i].GetEntity() ) )
                    continue;

               blTimeoutSet = true;
               g_Scheduler.SetTimeout( "ForceLevelChange", flChangeLevelTimeout, H_TIMEOUT_CHANGELEVELS[i], EHandle( pActivator ) );
               LevelChangeCountdown( uint( flChangeLevelTimeout ) );
               break;
          }
     }
}
// Change the level anyways- prevents trolls from staying behind and stalling the level
void ForceLevelChange(EHandle hChangeLevel, EHandle hActivator)
{
     if( hChangeLevel.IsValid() && hActivator.IsValid() )
     {
          g_EntityFuncs.DispatchKeyValue( hChangeLevel.GetEntity().edict(), "percent_of_players", "0" );
          hChangeLevel.GetEntity().Touch( hActivator.GetEntity() );
     }
}

void LevelChangeCountdown(uint seconds)
{
     if( seconds > 0 )
     {
          g_PlayerFuncs.CenterPrintAll( "" + seconds + " seconds until level change." );
          g_Scheduler.SetTimeout( "LevelChangeCountdown", 1.0f, seconds-1 );
     }
}

}
