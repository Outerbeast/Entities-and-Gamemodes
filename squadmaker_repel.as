/* squadmaker_repel - squadmaker function script that spawns any monsters rappelling from a rope
    Installation:-
	- Place in scripts/maps
	- Add
	map_script squadmaker_repel
	to your map cfg
	OR
	- Add
	#include "squadmaker_repel"
	to your main map script header
	OR
	- Create a trigger_script with these keys set in your map:
	"classname" "trigger_script"
	"m_iszScriptFile" "squadmaker_repel"

    Usage:-
    - Place and configure your squadmaker entity as desired, ensuring that the position of your squadmaker
    is the same as where you would place your monster_*_repel entity
    - Add this keyvalue to your squadmaker:
    "function_name" "SQUADMAKER_REPEL::Repel"

    When triggered, the squadmaker will now spawn your monster rappelling down from a rope.
    If the monster spawned has its own standalone repel entity, the monster will rappel down the rope with
    the actual rappel animation.
- Outerbeast
*/
namespace SQUADMAKER_REPEL
{

const array<string> STR_RAPPEL_NPCS =
{
    "monster_male_assassin",
    "monster_human_grunt",
    "monster_hwgrunt",
    "monster_human_torch_ally",
    "monster_human_medic_ally",
    "monster_robogrunt"
};

array<EHandle> H_RAPPELERS;
CScheduledFunction@ fnLandThink = g_Scheduler.SetInterval( "RopeThink", 0.1f );

bool blPrecache = Precache();

bool Precache()
{
    g_Game.PrecacheModel( "sprites/rope.spr" );
    return true;
}
// Supports rappelling animations
bool IsRappellingType(EHandle hRappeller)
{
    return hRappeller ? STR_RAPPEL_NPCS.find( hRappeller.GetEntity().GetClassname() ) >= 0 : false;
}
// Code used from hgrunt.cpp "CHGruntRepel::RepelUse"
void Repel(CBaseMonster@ pSquadmaker, CBaseEntity@ pMonster)
{
    if( cast<CBaseMonster@>( pMonster ) is null )
        return;

    TraceResult trDown;
	g_Utility.TraceLine( pSquadmaker.pev.origin,  pSquadmaker.pev.origin + Vector( 0, 0, -4096.0 ), dont_ignore_monsters, pSquadmaker.edict(), trDown );

    CBaseMonster@ pRappeller = cast<CBaseMonster@>( pMonster );
    pRappeller.pev.movetype = MOVETYPE_FLY;
    pRappeller.pev.velocity = Vector( 0, 0, Math.RandomFloat( -196, -128 ) );

    if( IsRappellingType( pRappeller ) )
    {
        pRappeller.SetActivity( ACT_GLIDE );
        pRappeller.m_IdealActivity = ACT_GLIDE;
    }

    pRappeller.m_vecLastPosition = trDown.vecEndPos;

    CBeam@ pRope = g_EntityFuncs.CreateBeam( "sprites/rope.spr", 10 );
	pRope.PointEntInit( pSquadmaker.pev.origin + Vector( 0, 0, 112 ), pRappeller.entindex() );
	pRope.SetFlags( BEAM_FSOLID );
	pRope.SetColor( 255, 255, 255 );
    pRappeller.GetUserData( "h_rope" ) = EHandle( pRope );
    H_RAPPELERS.insertLast( pRappeller );
}

void RopeThink()
{
    if( H_RAPPELERS.length() < 0 )
        return;

    for( uint i = 0; i < H_RAPPELERS.length(); i++ )
    {
        if( !H_RAPPELERS[i] )
            continue;

        CBaseMonster@ pRappeller = cast<CBaseMonster@>( H_RAPPELERS[i].GetEntity() );
        // Monster landed.
        if( pRappeller.pev.FlagBitSet( FL_ONGROUND ) )
        {
            CBeam@ pRope = cast<CBeam@>( EHandle( pRappeller.GetUserData( "h_rope" ) ).GetEntity() );

            if( pRope is null )
                continue;

            pRope.SUB_Remove();

            if( IsRappellingType( pRappeller ) )
                pRappeller.m_IdealActivity = ACT_LAND;// otherwise the monster has to think about it for like 2 seconds before it wants to land.

            H_RAPPELERS[i] = EHandle();
        }// still zipping down
        else if( IsRappellingType( pRappeller ) && pRappeller.m_Activity != ACT_GLIDE && pRappeller.m_MonsterState <= MONSTERSTATE_COMBAT )
            pRappeller.m_IdealActivity = ACT_GLIDE;
    }
}

}
