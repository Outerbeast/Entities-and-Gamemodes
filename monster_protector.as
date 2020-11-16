/* "The GoldSRC Ministry of Defence has has raised conerns with the unethical practices of the SC Task Forces, namely "spawncamping" 
and thus have issued a statement on behalf of all npcs that those npcs spawning in must be allowed a few seconds of 
invulnerbility to gain a footing before being able to fight.
The SC Ethics Team have enforced measures to prevent this."
--------------------------------------------------------------
A script that allows a few seconds of spawn invulnerblity for npcs spawning
Usage:-
Call "MONSTERPROTECTOR::Activate( flProtectionTimeSetting );" where "flProtectionTimeSetting is any number between 0 and 3, fractions allowed 
- Outerbeast*/

namespace MONSTERPROTECTOR
{

float flProtectionTime;

void Activate(const float flProtectionTimeSetting)
{
    flProtectionTime = Math.clamp( 0.1, 3.0, flProtectionTimeSetting );

    CBaseEntity@ pNpcSpawner;
    while( ( @pNpcSpawner = g_EntityFuncs.FindEntityByClassname( pNpcSpawner, "squadmaker" ) ) !is null )
    {
        g_EntityFuncs.DispatchKeyValue( pNpcSpawner.edict(), "function_name", "MONSTERPROTECTOR::NpcSpawnProtect" );
    }
}

void NpcSpawnProtect(CBaseMonster@ pSquadmaker, CBaseEntity@ pMonster)
{
    if( pMonster !is null )
    {
        pMonster.pev.takedamage = DAMAGE_NO;

        EHandle hMonster = pMonster;
        g_Scheduler.SetTimeout( "NpcProtectionOff", flProtectionTime, hMonster );
    }
}

void NpcProtectionOff(EHandle hMonster)
{
    if( !hMonster )
        return;

    hMonster.GetEntity().pev.takedamage = DAMAGE_YES;
}

}
