/* StaticCfg- Plugin for overriding standard map cvars
Based on The StaticCfg AMXX plugin
Only supports map cvars mp_, skl_ and sv_ types

Installation:
1) Put StaticCfg.as into svencoop_addon/scripts/plugins
2) Add this to default_plugins.txt:
	"plugin"
 	{
        "name" "StaticCfg"
        "script" "StaticCfg"
 	}
3) Inside the dir svencoop_addon/scripts/plugins/store create the file static.cfg
4) Add your CVars into this new config file 
- Outerbeast*/


dictionary d_Cvars;

void PluginInit()
{
    g_Module.ScriptInfo.SetAuthor( "Outerbeast" );
	g_Module.ScriptInfo.SetContactInfo( "svencoopedia.fandom.com" );

	ReadCfg();
}

void ReadCfg()
{
	File@ pFile = g_FileSystem.OpenFile( "scripts/plugins/store/static.cfg", OpenFile::READ );

	if( pFile !is null && pFile.IsOpen() )
	{
    	while( !pFile.EOFReached() )
		{
    		string sLine;
    		pFile.ReadLine( sLine );
    		if( sLine.SubString(0,1) == "#" || sLine.IsEmpty() )
    			continue;

    		array<string> parsed = sLine.Split( " " );
      		if( parsed.length() < 2 )
        		continue;

      		d_Cvars[parsed[0]] = parsed[1];
    	}

    	pFile.Close();
	}
}

void MapInit()
{	
	array<string> @d_CvarsKeys = d_Cvars.getKeys();
    d_CvarsKeys.sortAsc();
		
	string CvarValue;

	for( uint i = 0; i < d_CvarsKeys.length(); ++i )
	{
		d_Cvars.get(d_CvarsKeys[i], CvarValue);
		g_EngineFuncs.CVarSetFloat(d_CvarsKeys[i], atof(CvarValue) );
		g_EngineFuncs.ServerPrint( "StaticCfg: Set CVar " + d_CvarsKeys[i] + " " + CvarValue + "\n" );
	}
}

/* Special thanks to
- Neo for scripting supports
- Incognico for file parsing code */