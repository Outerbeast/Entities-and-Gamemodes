/* info_player_speech - a way to have players speak based on their chosen character
    This entity is a work in progress, so no installation and usage information exists yet.
- Outerbeast */
namespace INFO_PLAYER_SPEECH
{

bool blInfoPlayerSpeechRegister = InfoPlayerSpeechRegister();
// TO-DO: add chat command to speak certain voice lines
enum voice_presets
{
    NONE,
    SCIENTIST,
    BARNEY,
    OTIS,
    HEV,
    FGRUNT,
    HGRUNT,
    ROBOGRUNT,
    ASLAVE,
    AGRUNT
};

const array<string> STR_SPEECH_GROUPS =
{
    "idle",
    "alert",
    "fight",
    "heal",
    "pain",
    "wounded",
    "help",
    "die",
    "kill",
    "jump",
    "message"
};

const array<dictionary> DICT_PRESETS =
{
    dictionary(),
    {//Scientist
        { "base", "scientist/" },
        { "idle", "!SC_IDLE;!SC_PIDLE;!SC_COUGH" },
        { "alert", "!SC_FEAR;!SC_SCREAM" },
        { "heal", "!SC_HEAL;!SC_REVIVE;!SC_M;!SC_CUREA;!SC_CUREB;!SC_CUREC" },
        { "fight", "SC_POK0" },
        { "help", "dontwantdie;canttakemore" },
        { "pain", "sci_pain1;sci_pain2;sci_pain3;sci_pain4;sci_pain5;sci_pain6;sci_pain7;sci_pain8;sci_pain9;sci_pain10" },
        { "wounded", "!SC_WOUND;!SC_MORTAL" },
        { "die", "sci_die1;sci_die2;sci_die3;sci_die4;scream21" }
    },
    {//Barney
        { "base", "barney/" },
        { "idle", "!BA_IDLE" },
        { "alert", "!BA_ATTACK" },
        { "heal", "checkwounds;youneedmedic;realbadwound;ba_cure0;ba_cure1" },
        { "fight", "!BA_MAD;ba_bring;ba_attacking1" },
        { "help", "!BA_HELPME" },
        { "pain", "ba_pain1;ba_pain2;ba_pain3" },
        { "wounded", "!BA_WOUND;!BA_CANAL_WOUND2" },
        { "die", "!BA_DIE1;ba_die2;ba_die3;!BA_CANAL_DEATH1" },
        { "kill", "!BA_KILL" }
    },
    {//Otis
        { "base", "" },
        { "idle", "!OT_IDLE" },
        { "alert", "!OT_ATTACK" },
        { "heal", "otis/scar;otis/insurance;otis/medic;otis/yourback" },
        { "fight", "!OT_MAD" },
        { "help", "otis/tooyoung;otis/virgin;otis/imdead" },
        { "pain", "barney/ba_pain1;barney/ba_pain2;barney/ba_pain3" },
        { "wounded", "!OT_WOUND;!OT_MORTAL" },
        { "die", "!BA_DIE1;barney/ba_die2;barney/ba_die3" },
        { "kill", "!OT_KILL" }
    },
    {//HEV
        { "base", "fvox/" },
        { "pain", "!HEV_DMG" },
        { "die", "!HEV_DEAD" }
    },
    {//AllyGrunt
        { "base", "fgrunt/" },
        { "idle", "!FG_IDLE" },
        { "alert", "!FG_ALERT;!FG_MONSTER" },
        { "fight", "!FG_ATTACK;!FG_TAUNT" },
        { "heal", "!MG_HEAL" },
        { "pain", "gr_pain1;gr_pain2;gr_pain3;gr_pain4;gr_pain5;gr_pain6;pain1;pain2;pain3;pain4;pain5;pain6" },
        { "die", "death1;death2;death3;death4;death5;death6" },
        { "kill", "!FG_KILL" }
    },
    {//HecuGrunt
        { "base", "hgrunt/" },
        { "idle", "!HG_IDLE" },
        { "alert", "!HG_ALERT" },
        { "fight", "!HG_TAUNT;!HG_CHARGE" },
        { "pain", "!HG_COVER;gr_pain1;gr_pain2;gr_pain3;gr_pain4;gr_pain5" },
        { "die", "gr_die1;gr_die2;gr_die3" },
        { "kill", "!HG_CLEAR" }
    },
    {//RoboGrunt
        { "idle", "!RB_IDLE" },
        { "alert", "!RB_ALERT;!RB_MONST" },
        { "fight", "!RB_CHARGE" },
        { "pain", "!RB_COVER" },
        { "kill", "!RB_CLEAR" }
    },
    {//AlienSlave
        { "base", "aslave/" },
        { "idle", "slv_word1;slv_word2;slv_word3;slv_word4;slv_word5;slv_word6;slv_word7;slv_word8" },
        { "alert", "slv_alert1;slv_alert3;slv_alert4" },
        { "pain", "slv_pain1;slv_pain2" },
        { "die", "slv_die1;slv_die2" }
    },
    {//AlienGrunt
        { "base", "agrunt/" },
        { "idle", "ag_idle1;ag_idle2;ag_idle3;ag_idle4;ag_idle5" },
        { "alert", "ag_alert1;ag_alert2;ag_alert3;ag_alert4;ag_alert5" },
        { "pain", "ag_pain1;ag_pain2;ag_pain3;ag_pain4;ag_pain5" },
        { "die", "ag_die1;ag_die2;ag_die3;ag_die4;ag_die5" }
    }
};

array<CCVar@> CVARS_PLAYER_SPEECH =
{
    CCVar( "player_speech_scientist", "", "", ConCommandFlag::None, CreatePreset ),
    CCVar( "player_speech_barney", "", "", ConCommandFlag::None, CreatePreset ),
    CCVar( "player_speech_otis", "", "", ConCommandFlag::None, CreatePreset ),
    CCVar( "player_speech_hev", "", "", ConCommandFlag::None, CreatePreset ),
    CCVar( "player_speech_fgrunt", "", "", ConCommandFlag::None, CreatePreset ),
    CCVar( "player_speech_hgrunt", "", "", ConCommandFlag::None, CreatePreset ),
    CCVar( "player_speech_robogrunt", "", "", ConCommandFlag::None, CreatePreset ),
    CCVar( "player_speech_aslave", "", "", ConCommandFlag::None, CreatePreset ),
    CCVar( "player_speech_agrunt", "", "", ConCommandFlag::None, CreatePreset )
};

array<info_player_speech> OBJ_PLAYER_SPEECHS;

void CreatePreset(CCVar@ cvar, const string& in szOldValue, float flOldValue)
{
    if( cvar is null || cvar.GetString() == "" )
        return;

    dictionary dictPlayerSpeech =
    {
        { "preset", "" + ( CVARS_PLAYER_SPEECH.find( cvar ) + 1 ) },
        { "pmodels", cvar.GetString() },
        { "spawnflags", "" + ( 1 << 8 ) }// Prevent precaching, because we already did it somewhere else.
    };

    g_EntityFuncs.CreateEntity( "info_player_speech", dictPlayerSpeech );
}
// Note to devs: this should be a standard CBasePlayer method.
string GetPlayerModel(EHandle hPlayer)
{
    if( !hPlayer )
        return "";

    CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

    if( pPlayer !is null && pPlayer.IsPlayer() ) // This only returns the filename of the playermodel, not the full path + extension.
        return string( g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() ).GetValue( "model" ) );
    else
        return "";
}

bool PrecacheSentences(const dictionary@ dictSentences)
{
    if( dictSentences is null || dictSentences.isEmpty() )
        return false;

    array<string> STR_KEYS = dictSentences.getKeys(), STR_VALUES;

    for( uint i = 0; i < STR_KEYS.length(); i++ )
    {
        if( STR_SPEECH_GROUPS.find( STR_KEYS[i] ) < 0 )
            continue;

        STR_VALUES = string( dictSentences[STR_KEYS[i]] ).Split( ";" );

        for( uint j = 0; j < STR_VALUES.length(); j++ )
        {
            if( STR_VALUES[j].StartsWith( '!' ) )
                continue;

            g_Log.PrintF( "Precaching: " + string( dictSentences["base"] ) + STR_VALUES[j] + ".wav\n" );
            g_SoundSystem.PrecacheSound( string( dictSentences["base"] ) + STR_VALUES[j] + ".wav" );
        }
    }

    return true;
}

bool InfoPlayerSpeechRegister()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "INFO_PLAYER_SPEECH::info_player_speech", "info_player_speech" );
    g_EntityLoader.LoadFromFile( "store/info_player_speech.txt" );

    return g_CustomEntityFuncs.IsCustomEntity( "info_player_speech" );
}

final class info_player_speech : ScriptBaseEntity
{
    private dictionary dictSpeech;
    string strPlayerModels;
    private float flSpeechDelay = 0.6f;
    private uint iPreset;

    private array<EHandle> H_PLAYER_ENEMIES( g_Engine.maxClients + 1 );
    private array<float> 
        FL_LAST_SPOKE( g_Engine.maxClients + 1 ),
        FL_LAST_DAMAGE_TIME( g_Engine.maxClients + 1 );
    private array<string> STR_LAST_SPOKE( g_Engine.maxClients + 1 );

    private CScheduledFunction@ fnResetBaddiesSeen;

    private string strBase
    {
        get { return string( dictSpeech["base"] ); }
        set { dictSpeech["base"] = value + "/"; }
    }

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        if( STR_SPEECH_GROUPS.find( szKey ) >= 0 && !dictSpeech.exists( szKey ) )
            dictSpeech[szKey] = szValue;
        else if( szKey == "pmodels" )
            strPlayerModels = szValue;
        else if( szKey == "preset" )
            iPreset = atoui( szValue );
        else if( szKey == "base" )
            strBase = szValue;
        else if( szKey == "delay" )
            flSpeechDelay = atof( szValue ) <= 0.0f ? 0.5f : atof( szValue );
        else
            return BaseClass.KeyValue( szKey, szValue );
            
        return true;
    }

    void Precache()
    {
        for( uint i = 0; i < DICT_PRESETS.length(); i++ )
            PrecacheSentences( DICT_PRESETS[i] );

        PrecacheSentences( dictSpeech );
        BaseClass.Precache();
    }

    void PreSpawn()
    {
        if( iPreset > 0 )
            dictSpeech = DICT_PRESETS[iPreset];
    }

    void Spawn()
    {
        if( !self.pev.SpawnFlagBitSet( 1 << 8 ) )
            self.Precache();

        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        if( self.pev.message != "" )
            dictSpeech["message"] = string( self.pev.message );

        StartThink();
        BaseClass.Spawn();

        OBJ_PLAYER_SPEECHS.insertLast( ( cast<info_player_speech@>( CastToScriptClass( self ) ) ) );
    }
    
    void StartThink()
    {
        if( string( dictSpeech["idle"] ) != "" || string( dictSpeech["fight"] ) != "" )
            self.pev.nextthink = g_Engine.time + 1.5f;

        if( string( dictSpeech["alert"] ) != "" )
            g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( this.EnemySpotted ) );

        if( string( dictSpeech["heal"] ) != "" )
        {
            g_Hooks.RegisterHook( Hooks::Weapon::WeaponPrimaryAttack, WeaponPrimaryAttackHook( this.MedkitUse ) );
            g_Hooks.RegisterHook( Hooks::Weapon::WeaponSecondaryAttack, WeaponSecondaryAttackHook( this.MedkitUse ) );
        }

        if( string( dictSpeech["kill"] ) != "" )
            g_Hooks.RegisterHook( Hooks::Monster::MonsterKilled, MonsterKilledHook( this.EnemyKilled ) );

        if( string( dictSpeech["pain"] ) != "" )
            g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, PlayerTakeDamageHook( this.PlayerTakeDamage ) );
        
        if( string( dictSpeech["die"] ) != "" )
            g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, PlayerKilledHook( this.PlayerKilled ) );
    }

    void Speak(EHandle hPlayer, string strSpeechGroup, int pitch = PITCH_NORM)
    {
        if
        (
            !hPlayer ||
            hPlayer.GetEntity().pev.waterlevel > WATERLEVEL_WAIST ||
            hPlayer.GetEntity().pev.effects & EF_NODRAW != 0 ||
            strSpeechGroup == "" || 
            !dictSpeech.exists( strSpeechGroup ) ||
            string( dictSpeech[strSpeechGroup] ) == "" ||
            string( dictSpeech[strSpeechGroup] ) == "null"
        )
            return;

        if( strPlayerModels != "" && strPlayerModels.Find( GetPlayerModel( hPlayer ) ) == String::INVALID_INDEX )
            return;

        const array<string> PHRASES = string( dictSpeech[strSpeechGroup] ).Split( ";" );
        string strSelectedSnd;

        do( strSelectedSnd = PHRASES[Math.RandomLong( 0, PHRASES.length() - 1 )] );
        while( PHRASES.length() > 1 && strSelectedSnd == STR_LAST_SPOKE[hPlayer.GetEntity().entindex()] );

        if( strSelectedSnd.StartsWith( '!' ) )
        {
            strSelectedSnd.Trim( '!' );
            g_SoundSystem.PlaySentenceGroup( hPlayer.GetEntity().edict(), strSelectedSnd, VOL_NORM, ATTN_NORM, 0, pitch );
        }
        else
            g_SoundSystem.EmitSoundDyn( hPlayer.GetEntity().edict(), CHAN_VOICE, strBase + strSelectedSnd + ".wav", VOL_NORM, ATTN_NORM, 0, pitch );

        FL_LAST_SPOKE[hPlayer.GetEntity().entindex()] = g_Engine.time;
        STR_LAST_SPOKE[hPlayer.GetEntity().entindex()] = strSelectedSnd;
        g_Log.PrintF( "! %1 !: %2 spoke %3: %4\n", self.GetClassname(), hPlayer.GetEntity().pev.netname, strSpeechGroup, strSelectedSnd );
    }

    EHandle PlayerEnemy(EHandle hPlayer, EHandle hNewEnemy = EHandle(), bool blResetEnemy = false)
    {
        if( !hPlayer )
            return EHandle();

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null )
            return EHandle();

        if( hNewEnemy )
            H_PLAYER_ENEMIES[pPlayer.entindex()] = hNewEnemy;

        if( blResetEnemy )
            H_PLAYER_ENEMIES[pPlayer.entindex()] = EHandle();

        return H_PLAYER_ENEMIES[pPlayer.entindex()];
    }

    void ResetBaddieSeen(EHandle hPlayer)
    {
        PlayerEnemy( hPlayer, EHandle(), true );
    }

    void Think()
    {
        for( int iPlayer = 1; iPlayer <= g_Engine.maxClients; iPlayer++ )
        {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( iPlayer );

            if( pPlayer is null || !pPlayer.IsConnected() )
            {
                H_PLAYER_ENEMIES[iPlayer] = EHandle();
                continue;
            }

            if( g_Engine.time < FL_LAST_SPOKE[pPlayer.entindex()] + flSpeechDelay )
                continue;

            if( g_Engine.time < FL_LAST_DAMAGE_TIME[pPlayer.entindex()] + flSpeechDelay )
                continue;
            // !-BUG-!: Sometimes idle chatter plays while taking damage
            if( pPlayer.IsAlive() )
            {
                if( string( dictSpeech["idle"] ) != "" && !PlayerEnemy( pPlayer ) )
                    Idle( pPlayer );

                if( string( dictSpeech["wounded"] ) != "" )
                    Wounded( pPlayer );

                if( string( dictSpeech["fight"] ) != "" )
                    Fight( pPlayer );
            }
            else if( g_PlayerFuncs.SharedRandomLong( pPlayer.random_seed, 0, 100 ) <= 10 )
                Speak( pPlayer, "help" );
        }

        self.pev.nextthink = g_Engine.time + Math.RandomFloat( 0.7f, 1.5f );
    }
    // Random chatter
    void Idle(EHandle hPlayer)
    {
        if( !hPlayer )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null || pPlayer.pev.button & ( IN_ATTACK | IN_ATTACK2 ) != 0 )
            return;

        if( g_PlayerFuncs.SharedRandomLong( pPlayer.random_seed, 0, 100 ) <= 10 )
            Speak( hPlayer, "idle" );
    }

    void Wounded(EHandle hPlayer)
    {
        if( !hPlayer )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null || hPlayer.GetEntity().pev.health > 25  )
            return;

        if( g_PlayerFuncs.SharedRandomLong( pPlayer.random_seed, 0, 100 ) <= 10 )
            Speak( hPlayer, "wounded" );
    }
    
    void Fight(EHandle hPlayer)
    {
        if( !hPlayer )
            return;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( hPlayer.GetEntity() );

        if( pPlayer is null || !pPlayer.m_hActiveItem || !PlayerEnemy( pPlayer ) )
            return;

        if( g_PlayerFuncs.SharedRandomLong( pPlayer.random_seed, 0, 100 ) <= 10 )
            Speak( hPlayer, "fight" );	
    }
    //!-TODO-!: add features for saying speak alert looking at an enemy or speak follow if looking at a player
    HookReturnCode PlayerUse(CBasePlayer@ pPlayer, uint& out uiFlags)
	{
		if( pPlayer is null )
			return HOOK_CONTINUE;

        if( ( pPlayer.m_afButtonReleased & IN_JUMP ) != 0 && pPlayer.pev.velocity.z > 0.0f )
            Speak( pPlayer, "jump" );

		return HOOK_CONTINUE;
	}

    HookReturnCode PlayerTakeDamage(DamageInfo@ pDamageInfo)
    {
        if( pDamageInfo is null || pDamageInfo.pVictim is null )
            return HOOK_CONTINUE;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );

        if( pDamageInfo.flDamage <= 0.0f || pDamageInfo.pAttacker is null || !pPlayer.IsAlive() )
            return HOOK_CONTINUE;

        int iWoundValue = int( pPlayer.pev.max_health - pPlayer.pev.health );

        if( Math.RandomLong( 1, int( pPlayer.pev.max_health ) ) > iWoundValue )
            return HOOK_CONTINUE;

        if( g_Engine.time > FL_LAST_SPOKE[pPlayer.entindex()] + flSpeechDelay )
            Speak( pPlayer, "pain" );

        FL_LAST_DAMAGE_TIME[pPlayer.entindex()] = g_Engine.time;
        self.pev.nextthink = g_Engine.time + flSpeechDelay;

        return HOOK_CONTINUE;
    }

    HookReturnCode PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib)
    {
        if( pPlayer is null || iGib == GIB_ALWAYS )
            return HOOK_CONTINUE;

        Speak( pPlayer, "die" );

        return HOOK_CONTINUE;
    }

    HookReturnCode MedkitUse(CBasePlayer@ pPlayer, CBasePlayerWeapon@ pWeapon)
    {
        if( pPlayer is null || pWeapon is null || pWeapon.m_iId != WEAPON_MEDKIT )
            return HOOK_CONTINUE;

        if( g_Engine.time > FL_LAST_SPOKE[pPlayer.entindex()] + flSpeechDelay + 4.0f )
            Speak( pPlayer, "heal" );

        return HOOK_CONTINUE;
    }

    HookReturnCode EnemySpotted(CBasePlayer@ pPlayer)
    {
        if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive() )
            return HOOK_CONTINUE;

        CBaseEntity@ pAimedEntity = g_Utility.FindEntityForward( pPlayer, 500.0f );

        if
        ( 
            pAimedEntity is null || 
            !pAimedEntity.pev.FlagBitSet( FL_MONSTER ) || 
            pPlayer.IRelationship( pAimedEntity, false ) <= R_NO || 
            pAimedEntity.pev.deadflag == DEAD_DEAD
        )
            return HOOK_CONTINUE;

        if( H_PLAYER_ENEMIES[pPlayer.entindex()].IsValid() && H_PLAYER_ENEMIES[pPlayer.entindex()].GetEntity() is pAimedEntity )
            return HOOK_CONTINUE;

        if( g_PlayerFuncs.SharedRandomLong( pPlayer.random_seed, 0, 1 ) == 1 )
            Speak( pPlayer, "alert" );

        PlayerEnemy( pPlayer, pAimedEntity );
        @fnResetBaddiesSeen = g_Scheduler.SetTimeout( this, "ResetBaddieSeen", 10.0f, EHandle( pPlayer ) );

        return HOOK_CONTINUE;
    }
    // !-TODO-!: Implement for 5.26
    HookReturnCode EnemyKilled(CBaseMonster@ pMonster, CBaseEntity@ pAttacker, int bitsDamageType)
    {
        if( pMonster is null || pMonster.IsPlayer() || pAttacker is null || !pAttacker.IsPlayer() )
            return HOOK_CONTINUE;

        CBasePlayer@ pPlayer = cast<CBasePlayer@>( pAttacker );
        //TO-DO: have a check for visible in range
        if( Math.RandomLong( 0, 10 ) >= 6 )
            Speak( pPlayer, "kill" );
        // Remove the player's enemy
        PlayerEnemy( pPlayer, EHandle(), true );

        return HOOK_CONTINUE;
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( pActivator is null || !pActivator.IsPlayer() || !pActivator.IsAlive() )
            return;

        Speak( cast<CBasePlayer@>( pActivator ), "message" );
    }

    void UpdateOnRemove()
    {
        g_Hooks.RemoveHook( Hooks::Player::PlayerPostThink, PlayerPostThinkHook( this.EnemySpotted ) );
        g_Hooks.RemoveHook( Hooks::Monster::MonsterKilled, MonsterKilledHook( this.EnemyKilled ) );
        g_Hooks.RemoveHook( Hooks::Player::PlayerTakeDamage, PlayerTakeDamageHook( this.PlayerTakeDamage ) );
        g_Hooks.RemoveHook( Hooks::Player::PlayerKilled, PlayerKilledHook( this.PlayerKilled ) );

        g_Scheduler.RemoveTimer( fnResetBaddiesSeen );
    }
};

}
