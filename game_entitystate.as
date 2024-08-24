/* game_entitystate
	by Outerbeast

	Save and load states of various brush entities between maps eg breakables broken, doors opened, wall entities, pushables moved or triggers used
	Entities that are meant to have their state saves will be marked with a special keyvalue.

	Installation:-
    - Place in scripts/maps
    - Add 
    map_script game_entitystate
    to your map cfg
    OR
    - Add
    #include "game_entitystate"
    to your main map script header
    OR
    - Create a trigger_script with these keys set in your map:
    "classname" "trigger_script"
    "m_iszScriptFile" "game_entitystate"

	Usage:- There are two seperate entities that are used
	game_entitystate_save: this entity will save the states of marked entities
	game_entitystate_load: this entity will load the states of marked entities, if states were saved previously
	Both entities will trigger "target" if their operation was successfull, and "message" if they failed

	Entities that are meant to have their states saved and loaded must be marked with a custom key "$s_transition_name" with value thats unique to it.
	The equivalent entity in the next map must also have the exact keyvalue as this one in order for the entities to be linked so that their state is kept.

	Entity states supported:
	Breakables - anything that can be broken, such as func_breakable, breakable doors or pushables, will remain broken
	Pushables - func_pushable will have their current position saved
	Doors - doors will save their open/closed state
	Walls - func_wall/illusionary will save their toggled texture. func_wall_toggles instead will save their on/invisible state
	Trams - func_(track)train entity will save their position and angles
	Triggers - trigger_once will be removed if previously triggered.

	Keys:-
	"map" "mapname" - (game_entitystate_save only) Name of the map that entitystates will be saved to.
	"targetname" "target_me" - If set, the entity will require manual triggering in order to perform its action. Otherwise, the entity should automatically operate when needed.
	"target" "entity_targetname" - Triggers this when states are successfully saved/loaded
	"message" "entity_targetname" - Triggers this when states have failed to save/load
*/
namespace GAME_ENTITYSTATE
{

enum EntType
{
	NONE,
	BREAKABLES,
	PUSHABLES,
	DOORS,
	WALLS,
	TRAMS,
	PLATS, // Not yet implemented
	TRIGGERS
};

string strSavePath = "scripts/maps/store/", strSavedEnts;
array<EHandle> H_BREAKABLES, H_PUSHABLES, H_DOORS, H_WALLS, H_TRIGGERS, H_TRAMS;

bool blEntityRegistered = RegisterEntity();

bool RegisterEntity()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "GAME_ENTITYSTATE::CGameEntityState", "game_entitystate_save" );
	g_CustomEntityFuncs.RegisterCustomEntity( "GAME_ENTITYSTATE::CGameEntityState", "game_entitystate_load" );

	return g_CustomEntityFuncs.IsCustomEntity( "game_entitystate_save" ) && g_CustomEntityFuncs.IsCustomEntity( "game_entitystate_load" );
}

string TransitionName(EHandle hEntity)
{
	if( !hEntity )
		return "";

	CustomKeyvalues@ kvEntity = hEntity.GetEntity().GetCustomKeyvalues();

	if( kvEntity is null || !kvEntity.HasKeyvalue( "$s_transition_name" ) )
		return "";

	return kvEntity.GetKeyvalue( "$s_transition_name" ).GetString();
}

void GetTransitionEntities()
{
	const Vector
		vecWorldMins = Vector( -WORLD_BOUNDARY, -WORLD_BOUNDARY, -WORLD_BOUNDARY ),
		vecWorldMaxs = Vector( WORLD_BOUNDARY, WORLD_BOUNDARY, WORLD_BOUNDARY );

	array<CBaseEntity@> P_ENTITIES( g_EngineFuncs.NumberOfEntities() );

	if( g_EntityFuncs.BrushEntsInBox( @P_ENTITIES, vecWorldMins, vecWorldMaxs ) < 1 )
		return;

	for( uint i = 0; i < P_ENTITIES.length(); i++ )
	{
		if( P_ENTITIES[i] is null || TransitionName( P_ENTITIES[i] ) == "" )
			continue;

		if( P_ENTITIES[i].GetClassname() == "func_breakable" && H_BREAKABLES.findByRef( EHandle( P_ENTITIES[i] ) ) < 0 )
			H_BREAKABLES.insertLast( P_ENTITIES[i] );
		// Pushable
		if( P_ENTITIES[i].IsBSPModel() && P_ENTITIES[i].pev.movetype == MOVETYPE_PUSHSTEP && H_PUSHABLES.findByRef( EHandle( P_ENTITIES[i] ) ) < 0 )
			H_PUSHABLES.insertLast( P_ENTITIES[i] );

		if( cast<CBaseDoor@>( P_ENTITIES[i] ) !is null && H_DOORS.findByRef( EHandle( P_ENTITIES[i] ) ) < 0 )
			H_DOORS.insertLast( P_ENTITIES[i] );

		if( ( P_ENTITIES[i].GetClassname().StartsWith( "func_wall" ) || P_ENTITIES[i].GetClassname() == "func_illusionary" ) && H_WALLS.findByRef( EHandle( P_ENTITIES[i] ) ) < 0 )
			H_WALLS.insertLast( P_ENTITIES[i] );

		if( P_ENTITIES[i].GetClassname().EndsWith( "train" ) && H_TRAMS.findByRef( EHandle( P_ENTITIES[i] ) ) < 0 )
			H_TRAMS.insertLast( P_ENTITIES[i] );

		if( P_ENTITIES[i].GetClassname() == "trigger_once" && H_TRIGGERS.findByRef( EHandle( P_ENTITIES[i] ) ) < 0 )
			H_TRIGGERS.insertLast( P_ENTITIES[i] );
	}
}
// !-TO-DO-!: save "health" for anything that is breakable
int FetchEntityStates(const EntType type)
{
	array<EHandle> H_ENTITIES;

	switch( type )
	{
		case BREAKABLES:
			H_ENTITIES = H_BREAKABLES;
			break;

		case PUSHABLES:
			H_ENTITIES = H_PUSHABLES;
			break;

		case DOORS:
			H_ENTITIES = H_DOORS;
			break;

		case WALLS:
			H_ENTITIES = H_WALLS;
			break;

		case TRIGGERS:
			H_ENTITIES = H_TRIGGERS;
			break;

		default: return 0;
	}

	if( H_ENTITIES.length() < 1 )
		return 0;

	int iEntitiesProcessed = 0;

	for( uint i = 0; i < H_ENTITIES.length(); i++ )
	{
		if( !H_ENTITIES[i] || TransitionName( H_ENTITIES[i] ) == "" )
			continue;

		CBaseEntity@ pEntity = H_ENTITIES[i].GetEntity();

		switch( type )
		{
			case PUSHABLES:
			case TRAMS: // Tram entities untested, but the logic is sound
			{
				strSavedEnts += ";" + TransitionName( pEntity ) + ";" + pEntity.pev.origin.ToString().Replace( ", ", ";" );

				if( type == TRAMS )
					strSavedEnts += ";" + TransitionName( pEntity ) + ";" + pEntity.pev.angles.ToString().Replace( ", ", ";" );

				iEntitiesProcessed++;

				break;
			}

			case DOORS:
			{
				strSavedEnts += ";" + TransitionName( pEntity );

				if( cast<CBaseDoor@>( pEntity ) !is null )
				{
					strSavedEnts += ";" + cast<CBaseDoor@>( pEntity ).GetToggleState();
					iEntitiesProcessed++;
				}

				break;
			}

			case WALLS:
			{
				if( pEntity.GetClassname() == "func_wall" || pEntity.GetClassname() == "func_illusionary" )
					strSavedEnts += ";" + TransitionName( pEntity ) + ";" + pEntity.pev.frame;
				else if( pEntity.GetClassname() == "func_wall_toggle" )
					strSavedEnts += ";" + TransitionName( pEntity ) + ";" + ( pEntity.pev.solid != SOLID_NOT );

				iEntitiesProcessed++;

				break;
			}

			default:
			{
				strSavedEnts += ";" + TransitionName( pEntity );
				iEntitiesProcessed++;
			}
		}
	}

	return strSavedEnts != "" ? iEntitiesProcessed : 0;
}

int ApplyEntityStates(const EntType type)
{
	if( strSavedEnts == "" )
		return 0;

	const array<string> STR_SAVED_ENTS = strSavedEnts.Split( ";" );

	if( STR_SAVED_ENTS.length() < 1 )
		return 0;

	array<EHandle> H_ENTITIES;

	switch( type )
	{
		case BREAKABLES:
			H_ENTITIES = H_BREAKABLES;
			break;

		case PUSHABLES:
			H_ENTITIES = H_PUSHABLES;
			break;

		case DOORS:
			H_ENTITIES = H_DOORS;
			break;

		case WALLS:
			H_ENTITIES = H_WALLS;
			break;

		case TRIGGERS:
			H_ENTITIES = H_TRIGGERS;
			break;

		default: return 0;
	}

	if( H_ENTITIES.length() < 1 )
		return 0;

	int iEntitiesProcessed = 0;

	for( uint i = 0; i < H_ENTITIES.length(); i++ )
	{
		if( !H_ENTITIES[i] || TransitionName( H_ENTITIES[i] ) == "" )
			continue;

		CBaseEntity@ pEntity = H_ENTITIES[i].GetEntity();

		if( STR_SAVED_ENTS.find( TransitionName( pEntity ) ) < 0 )
		{
			g_EntityFuncs.Remove( pEntity );
			continue;
		}

		switch( type )
		{
			case PUSHABLES:
			case TRAMS:
			{
				Vector vecSavedPos;
				vecSavedPos.x = atof( STR_SAVED_ENTS[STR_SAVED_ENTS.find( TransitionName( pEntity ) ) + 1] );
				vecSavedPos.y = atof( STR_SAVED_ENTS[STR_SAVED_ENTS.find( TransitionName( pEntity ) ) + 2] );
				vecSavedPos.z = atof( STR_SAVED_ENTS[STR_SAVED_ENTS.find( TransitionName( pEntity ) ) + 3] );
				g_EntityFuncs.SetOrigin( pEntity, vecSavedPos );

				if( type == TRAMS )
				{
					Vector vecSavedAngles;
					vecSavedAngles.x = atof( STR_SAVED_ENTS[STR_SAVED_ENTS.find( TransitionName( pEntity ) ) + 4] );
					vecSavedAngles.y = atof( STR_SAVED_ENTS[STR_SAVED_ENTS.find( TransitionName( pEntity ) ) + 5] );
					vecSavedAngles.z = atof( STR_SAVED_ENTS[STR_SAVED_ENTS.find( TransitionName( pEntity ) ) + 6] );
				}

				iEntitiesProcessed++;

				break;
			}

			case DOORS:
			{
				CBaseDoor@ pDoor = cast<CBaseDoor@>( pEntity );

				if( pDoor is null )
					break;

				const string state = STR_SAVED_ENTS[STR_SAVED_ENTS.find( TransitionName( pDoor ) ) + 1];
				pDoor.SetToggleState( TOGGLE_STATE( atoi( state ) ) );
				iEntitiesProcessed++;

				break;
			}

			case WALLS:
			{
				const string state = STR_SAVED_ENTS[STR_SAVED_ENTS.find( TransitionName( pEntity ) ) + 1];

				if( pEntity.GetClassname() == "func_wall" || pEntity.GetClassname() == "func_illusionary" )
					pEntity.pev.frame = atof( state );
				else if( pEntity.GetClassname() == "func_wall_toggle" )
					pEntity.Use( pEntity, pEntity, USE_TYPE( atoi( state ) ), 0.0f );

				iEntitiesProcessed++;

				break;
			}

			default:
				iEntitiesProcessed++;
		}
	}

	return iEntitiesProcessed;
}

bool Save(string strMap)
{
	g_FileSystem.RemoveFile( strSavePath + strMap + ".dat" );

	if( strMap == "" || !g_EngineFuncs.IsMapValid( strMap ) )
	{
		//g_EngineFuncs.ServerPrint( "!-----------------NEXTMAP INVALID!------------------!\n" );
		return false;
	}

	GetTransitionEntities();
	int iStatesSaved = 0;

	for( int i = BREAKABLES; i <= TRIGGERS; i++ )
		iStatesSaved += FetchEntityStates( i );

	if( iStatesSaved < 1 )
	{
		//g_EngineFuncs.ServerPrint( "!-----------------ENTITY STATES FETCH FAILED!------------------!\n" );
		return false;
	}

	File@ fileSave = g_FileSystem.OpenFile( strSavePath + strMap + ".dat", OpenFile::WRITE );

	if( fileSave is null || !fileSave.IsOpen() )
	{
		//g_EngineFuncs.ServerPrint( "!-----------------WRITE FAILED!------------------!\n" );
		return false;
	}

	fileSave.Write( strSavedEnts );
	fileSave.Close();	
	//g_EngineFuncs.ServerPrint( "!-----------------SAVING ENTITY STATES: " + strSavedEnts + " ------------------!\n" );

	return strSavedEnts != "";
}

bool Load(string strPrevMap)
{
	if( strPrevMap == "" )
		return false;

	File@ fileLoad = g_FileSystem.OpenFile( strSavePath + strPrevMap + ".dat", OpenFile::READ );
	
	if( fileLoad is null || !fileLoad.IsOpen() )
	{
		//g_EngineFuncs.ServerPrint( "!-----------------READ FAILED!------------------!\n" );
		return false;
	}

	fileLoad.ReadLine( strSavedEnts );
	fileLoad.Close();
	GetTransitionEntities();
	//g_EngineFuncs.ServerPrint( "!-----------------LOADING ENTITY STATES: " + strSavedEnts + " ------------------!\n" );
	int iStatesLoaded = 0;

	for( int i = BREAKABLES; i <= TRIGGERS; i++ )
		iStatesLoaded += ApplyEntityStates( i );

	return iStatesLoaded > 0;	
}

void Delete(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	const string strPrevMap = pCaller.pev.netname;

	if( strPrevMap == "" || !g_EngineFuncs.IsMapValid( strPrevMap ) )
		return;

	g_FileSystem.RemoveFile( strSavePath + strPrevMap + ".dat" );
}
// !-TEMPORARY-!: Cleanup routine for savestates - remove save files when these maps are NOT running
void Cleanup(const string strSaveMapList)
{
	if( strSaveMapList == "" )
		return;

	array<string> STR_SAVE_MAPS = strSaveMapList.Split( ";" );

	if( STR_SAVE_MAPS.find( g_Engine.mapname ) >= 0 )
		return;

	for( uint i = 0; i < STR_SAVE_MAPS.length(); i++ )
		g_FileSystem.RemoveFile( strSavePath + STR_SAVE_MAPS[i] + ".dat" );
}
// !-TO-DO-!: logic for automatically deleting current level's loaded state when level is changing
final class CGameEntityState : ScriptBaseEntity
{
	private string strMap
	{
		get { return string( pev.netname ); }
		set { pev.netname = string( value ); }
	};

	bool KeyValue(const string& in szKey, const string& in szValue)
	{
		if( szKey == "map" )
			strMap = szValue;
		else
			return BaseClass.KeyValue( szKey, szValue );

		return true;
	}

	void Spawn()
	{
		self.pev.solid      = SOLID_NOT;
		self.pev.movetype   = MOVETYPE_NONE;
		self.pev.effects   |= EF_NODRAW;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		// Delayed a millisecond later because of Sod's Law.
		g_Scheduler.SetTimeout( this, "Init", 0.01f );

		BaseClass.Spawn();
	}

	void Init()
	{
		if( self.GetTargetname() == "" )
		{
			if( self.GetClassname().EndsWith( "_save" ) )
				g_Hooks.RegisterHook( Hooks::Game::MapChange, MapChangeHook( this.MapChange ) );
			else if( self.GetClassname().EndsWith( "_load" ) )
				self.Use( self, self, USE_TOGGLE, 0.1f );
		}
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
	{
		if( ( self.GetClassname().EndsWith( "_save" ) && Save( strMap ) ) || 
			( self.GetClassname().EndsWith( "_load" ) && Load( g_Engine.mapname ) ) )
			self.SUB_UseTargets( pActivator, USE_TOGGLE, 0.0f );
		else
			g_EntityFuncs.FireTargets( self.pev.message, pActivator, self, USE_TOGGLE, 0.0f, 0.0f );
	}

	HookReturnCode MapChange(const string& in szNextMap)
	{
		if( g_Engine.mapname == szNextMap )
			return;

		if( strMap == "" )
			strMap = szNextMap;

		self.Use( self, self, USE_ON );
		return HOOK_CONTINUE;
	}
};

}
/* Special thanks to:-
- _RC, for original concept and design
*/