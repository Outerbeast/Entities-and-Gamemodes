/*  game_popup
    by Outerbeast
    Entity that creates a custom MOTD popup with title and text
    MOTD code by Geigue

    When triggered, the activator (if it is a player) will receive the popup on their screen.
    Setting flag 1 will make the popup display for all players.

    Installation:-
    - Place in scripts/maps
    - Add
    map_script game_popup
    to your map cfg
    OR
    - Add
    #include "game_popup"
    to your main map script header
    OR
    - Create a trigger_script with these keys set in your map:
    "classname" "trigger_script"
    "m_iszScriptFile" "game_popup"

    Keys:-
    "classname" "game_popup"
    "netname" "Title goes here" - Title key
    "message" "Text goes here" - Main body text key. A specific file can be used using the "+" prefix followed by the path starting from "scripts/maps/store/"
    "spawnflags" "1" - All players receive the popup, not just the activator
*/
bool blRegisterGamePopEntity = RegisterGamePopupEntity();

bool RegisterGamePopupEntity()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "game_popup", "game_popup" );
    return g_CustomEntityFuncs.IsCustomEntity( "game_popup" );
}

class game_popup : ScriptBaseEntity
{
    void Spawn()
	{
		self.pev.movetype 	= MOVETYPE_NONE;
		self.pev.solid 		= SOLID_NOT;
		g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.netname == "" )
            self.pev.netname = "Title";

        if( string( self.pev.message ).StartsWith( '+' ) )
        {
            string temp = string( self.pev.message );
            temp.Trim( "+" );
            self.pev.message = ReadWholeFile( "scripts/maps/store/" + temp );
        }

        BaseClass.Spawn();
	}

    string ReadWholeFile(string strFileName)
    {
        string strText;
        File@ fileDat = g_FileSystem.OpenFile( strFileName, OpenFile::READ );

        if( fileDat is null || !fileDat.IsOpen() )
            return "";

        while( !fileDat.EOFReached() )
            fileDat.ReadLine( strText );

        fileDat.Close();

        return strText;
    }
    /* Shows a MOTD message to the player */ //Code by Geigue
    void ShowMOTD(EHandle hPlayer, const string& in szTitle, const string& in szMessage)
    {
        if( !hPlayer )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null )
            return;
        
        NetworkMessage title( MSG_ONE_UNRELIABLE, NetworkMessages::ServerName, pPlayer.edict() );
        title.WriteString( szTitle );
        title.End();
        
        uint iChars = 0;
        string szSplitMsg = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        
        for( uint uChars = 0; uChars < szMessage.Length(); uChars++ )
        {
            szSplitMsg.SetCharAt( iChars, char( szMessage[ uChars ] ) );
            iChars++;
            if( iChars == 32 )
            {
                NetworkMessage message( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, pPlayer.edict() );
                message.WriteByte( 0 );
                message.WriteString( szSplitMsg );
                message.End();
                
                iChars = 0;
            }
        }
        // If we reached the end, send the last letters of the message
        if( iChars > 0 )
        {
            szSplitMsg.Truncate( iChars );
            
            NetworkMessage fix( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, pPlayer.edict() );
            fix.WriteByte( 0 );
            fix.WriteString( szSplitMsg );
            fix.End();
        }
        
        NetworkMessage endMOTD( MSG_ONE_UNRELIABLE, NetworkMessages::MOTD, pPlayer.edict() );
        endMOTD.WriteByte( 1 );
        endMOTD.WriteString( "\n" );
        endMOTD.End();
        
        NetworkMessage restore( MSG_ONE_UNRELIABLE, NetworkMessages::ServerName, pPlayer.edict() );
        restore.WriteString( g_EngineFuncs.CVarGetString( "hostname" ) );
        restore.End();
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( pActivator !is null && pActivator.IsPlayer() && !self.pev.SpawnFlagBitSet( 1 ) )
            ShowMOTD( cast<CBasePlayer@>( pActivator ), string( self.pev.netname ), string( self.pev.message ) );
        else
        {
            for( int playerID = 1; playerID <= g_PlayerFuncs.GetNumPlayers(); playerID++ )
                ShowMOTD( g_PlayerFuncs.FindPlayerByIndex( playerID ), string( self.pev.netname ), string( self.pev.message ) );
        }

        self.SUB_UseTargets( pActivator, USE_TOGGLE, 0.0f );
    }
}
