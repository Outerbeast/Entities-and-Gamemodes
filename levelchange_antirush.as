/* Adds a percentage of players required to change the level
    Option to add level change sign sprites to indicate level change location
    Comes in handy for massive map series
- Outerbeast
*/
namespace LEVELCHANGE_ANTIRUSH
{

string         strSprite;
uint           iPercentage;
float          flScale, flChangeLevelTimeout = 300.0f;
Vector         vecSpriteOffset;
array<EHandle> H_CHANGELEVELS;

CScheduledFunction@ fnThink;

CCVar cvarLevelChangeAntirushPercentage( "lvlchange_antirush_percent", 66, "Set level change percentage (0 disables percentage antirush)", ConCommandFlag::AdminOnly );

void Config(string strSpriteIn = "sprites/level_change.spr", float flScaleIn = 0.25f, Vector vecSpriteOffsetIn = g_vecZero)// Execute in MapInit()
{
    g_Game.PrecacheModel( strSpriteIn );
    g_SoundSystem.PrecacheSound( "buttons/bell1.wav" );
    strSprite = strSpriteIn;
    flScale = flScaleIn;
    vecSpriteOffset = vecSpriteOffsetIn;

    g_Scheduler.SetTimeout( "Setup", 0.1f, uint( cvarLevelChangeAntirushPercentage.GetInt() ) );
}

void Setup(uint iPercentageSetting)
{
    if( iPercentageSetting < 2 )
        return;

    CBaseEntity@ pChangeLevel;

    while( ( @pChangeLevel = g_EntityFuncs.FindEntityByClassname( pChangeLevel, "trigger_changelevel" ) ) !is null )
    {
        if
        (
            pChangeLevel is null || 
            pChangeLevel.pev.SpawnFlagBitSet( 2 ) || 
            pChangeLevel.pev.solid != SOLID_TRIGGER
        )
            continue;

        if( strSprite != "" )
        {
            CSprite@ pLevelChangeSpr = g_EntityFuncs.CreateSprite( strSprite, pChangeLevel.Center() + vecSpriteOffset, false, 0.0f );
            g_EntityFuncs.DispatchKeyValue( pLevelChangeSpr.edict(), "vp_type", 0 );
            pLevelChangeSpr.SetTransparency( int( kRenderTransTexture ), 255, 0, 0, 255, int( kRenderFxNone ) );
            pLevelChangeSpr.SetScale( flScale );
            pLevelChangeSpr.pev.angles = g_vecZero;
            pLevelChangeSpr.pev.nextthink = 0.0f;
            @pLevelChangeSpr.pev.owner = pChangeLevel.edict();
            @pChangeLevel.pev.euser1 = pLevelChangeSpr.edict();
        }

        if( iPercentageSetting > 0 )
        {
            iPercentage = Math.clamp( 0, 99, iPercentageSetting );
            LockChangeLevel( pChangeLevel );
        }
    }

    @fnThink = g_Scheduler.SetInterval( "PercentThink", 0.5f, g_Scheduler.REPEAT_INFINITE_TIMES );
}
//Just make the trigger_changelevel a solid wall.
void LockChangeLevel(CBaseEntity@ pChangeLevel)
{
    pChangeLevel.pev.solid = SOLID_BSP;
    pChangeLevel.pev.movetype = MOVETYPE_PUSH;
    g_EntityFuncs.SetOrigin( pChangeLevel, pChangeLevel.pev.origin );
    H_CHANGELEVELS.insertLast( pChangeLevel );
}

void UnlockChangeLevel(CBaseEntity@ pChangeLevel)
{
    pChangeLevel.pev.solid = SOLID_TRIGGER;
    pChangeLevel.pev.movetype = MOVETYPE_NONE;
    g_EntityFuncs.SetOrigin( pChangeLevel, pChangeLevel.pev.origin );
    pChangeLevel.pev.euser1.vars.rendercolor = Vector( 0, 255, 0 );
    g_SoundSystem.EmitSound( pChangeLevel.pev.euser1, CHAN_ITEM, "buttons/bell1.wav", 0.5f, ATTN_NORM );
}

void PercentThink()
{
    if( H_CHANGELEVELS.length() < 1 )
        return;

    uint 
        iPlayersAlive = 0,
        iPlayersInZone = 0;

    EHandle hCorrectChangeLevel;
    array<bool> BL_PLAYER_REACHED_GOAL( g_Engine.maxClients + 1 );

    for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
    {
        CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            continue;

        iPlayersAlive++;

        for( uint i = 0; i < H_CHANGELEVELS.length(); i++ )
        {
            if( !H_CHANGELEVELS[i] )
                continue;

            const float 
                flZoneRadius = H_CHANGELEVELS[i].GetEntity().pev.size.Length(),
                flChangeLevelDist = ( H_CHANGELEVELS[i].GetEntity().Center() - pPlayer.pev.origin ).Length();

            if( flChangeLevelDist <= flZoneRadius + 72.0f && H_CHANGELEVELS[i].GetEntity().FVisibleFromPos( pPlayer.pev.origin, H_CHANGELEVELS[i].GetEntity().Center() ) )
            {
                hCorrectChangeLevel = H_CHANGELEVELS[i];
                iPlayersInZone++;
            }
        }
    }

    if( iPlayersAlive < 1 )
        return;

    const float flCurrentPercent = float( iPlayersInZone ) / float( iPlayersAlive ) + 0.0001f;

    if( flCurrentPercent >= ( iPercentage ) * 0.01f && hCorrectChangeLevel )
    {
        UnlockChangeLevel( hCorrectChangeLevel.GetEntity() );
        g_Scheduler.RemoveTimer( fnThink );
    }
}

}
