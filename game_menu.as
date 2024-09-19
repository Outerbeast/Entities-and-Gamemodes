/* game_menu - Custom entity for making a customisable text menu
    Installation:-
    - Place in scripts/maps
    - Add 
    map_script game_menu
    to your map cfg
    OR
    - Add
    #include "game_menu"
    to your main map script header
    OR
    - Create a trigger_script with these keys set in your map:
    "classname" "trigger_script"
    "m_iszScriptFile" "game_menu"

    Usage:-
    Triggering the game_menu entity will open the menu up to the player who activated this menu.
    Keys follow this format:
    "n:<option name>" "<targetname to trigger>"
    n is the option number. All of the options in a menu page will be ordered based on their number.
    A maximum of 7 options can fit in one page before the rest are put on the next page, so if you had an 8th option it would begin on page 2.

    Example:
    "1:Option A" "target_something"
    "2:Plan B" "target_something_else"
    "3:Test C" "target_another_thing"
    ...

    "delay" - time delay before the menu closes automatically. By default this is 15 seconds, but, you can set 0 to make the menu not close.
    "health" - You can set this value to have the menu start from a specific page rather than the first page.

    Flags:-
    Checking flag 1 will make the menu open for everyone.
- Outerbeast */
bool blGameMenuEntityRegistered = RegisterGameMenuEntity();

bool RegisterGameMenuEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "game_menu", "game_menu" );
    return g_CustomEntityFuncs.IsCustomEntity( "game_menu" );
}

final class game_menu : ScriptBaseEntity
{
    private CTextMenu@ menu;
    private array<array<string>> ARR_STR_OPTIONS;
    private int iDelay = 15.0f;
    private bool blMenuOpen;
    private CScheduledFunction@ fnCloseMenu;

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( szKey != "" && szValue != "" && ARR_STR_OPTIONS.find( { szKey, szValue } ) < 0 )
            ARR_STR_OPTIONS.insertLast( { szKey, szValue } );
        else if( szKey == "delay" )
            iDelay = atoi( szValue );
        else
            return BaseClass.KeyValue( szKey, szValue );

        return true;
    }

    void Spawn()
    {
        ARR_STR_OPTIONS.sort( function(a,b) { return atoi( a[0].Split( ":" )[0] ) < atoi( b[0].Split( ":" )[0] ); } );
        SetupMenu();
    }

    bool SetupMenu()
    {
        @menu = CTextMenu( TextMenuPlayerSlotCallback( this.OptionSelected ) );
        menu.SetTitle( "" + self.pev.message );

        for( uint i = 0; i < ARR_STR_OPTIONS.length(); i++ )
        {
            if( ARR_STR_OPTIONS[i][0] == "" )
                continue;

            menu.AddItem( ARR_STR_OPTIONS[i][0].Split( ":" )[1], any( ARR_STR_OPTIONS[i][1] ) );
        } 

        return menu.Register();
    }

    void OptionSelected(CTextMenu@ menu, CBasePlayer@ pPlayer, int iSlot, const CTextMenuItem@ pItem)
    {
        if( pPlayer is null || pItem is null || pItem.m_pUserData is null )
            return;

        string target;
        pItem.m_pUserData.retrieve( target );
        g_EntityFuncs.FireTargets( target, pPlayer, null, USE_TOGGLE );
        self.pev.frags = iSlot;
        self.SUB_UseTargets( pPlayer, USE_SET, float( iSlot ) );
        blMenuOpen = false;
    }
    // This just updates the state, but can force a open menu to close
    void CloseMenu(bool blForceClose)
    {
        blMenuOpen = false;
        g_Scheduler.RemoveTimer( fnCloseMenu );
        // Hardly open = close
        if( blForceClose && blMenuOpen )
            menu.Open( 1, 0 );
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        switch( useType )
        {
            case USE_KILL:
            {
                g_EntityFuncs.Remove( self );
                return;
            }

            case USE_OFF:
                iDelay = 1;
                break;

            case USE_TOGGLE:
                iDelay = blMenuOpen ? 1 : iDelay;
                break;
        }

        if( self.pev.SpawnFlagBitSet( 1 << 0 ) )// All players
            menu.Open( iDelay, uint( self.pev.health ) );
        else if( pActivator.IsPlayer() )
        {
            CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
            menu.Open( iDelay, uint( self.pev.health ), pPlayer );
        }

        blMenuOpen = true;
        @fnCloseMenu = g_Scheduler.SetTimeout( "CloseMenu", float( iDelay ), false );
    }

    void UpdateOnRemove()
    {
        g_Scheduler.RemoveTimer( fnCloseMenu );
        CloseMenu( true );
    }
};
