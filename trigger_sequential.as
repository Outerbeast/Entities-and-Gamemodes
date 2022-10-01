/* trigger_sequential
by Outerbeast

Literally multi_manager except each target is not triggered automatically, rather only when the entity is triggered manually.
Each target is now triggered in the order that is set in the entity, not based on delay value. Delay values only determine when the target gets triggered after the trigger_sequential is used.
When the last target is triggered, the entity will reset back to the initial target and can be used again.
"health" key sets a wait-reset period before the trigger_sequential is allowed to be triggered again.
"frags" key keeps track of which number target the entity is expected to trigger next, the first target being "0" and the second "1", ...
This key can also be preset to override which target to start from, so from a list of 10 targets should you which to start from the 5th target, set the value to "4" (since 10 targets equates to 0th-9th)
This entity also has the trigger type "#3" which will use whatever the caller entity use type was.
*/
void RegisterTriggerSequential()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "trigger_sequential", "trigger_sequential" );
}

final class trigger_sequential : ScriptBaseEntity
{
    private dictionary dictKeyValues;
    private bool blShouldTrigger = true;

    private uint iTargetNumber
    {
        get { return uint( self.pev.frags ); }
        set { self.pev.frags = value; }
    }

    bool KeyValue(const string& in szKey, const string& in szValue)
    {
        dictKeyValues[szKey] = szValue;
        return true;
    }

    void Spawn()
    {
        self.pev.movetype   = MOVETYPE_NONE;
        self.pev.solid      = SOLID_NOT;
        self.pev.effects    |= EF_NODRAW;
        g_EntityFuncs.SetOrigin( self, self.pev.origin );

        BaseClass.Spawn();
    }

    USE_TYPE SetUseType(uint iTriggerType = 99)
    {
        switch( iTriggerType )
        {
            case 0: return USE_OFF;
            case 1: return USE_ON;
            case 2: return USE_KILL;
            case 3: return USE_SET;
            default: return USE_TOGGLE;
        }

        return USE_TOGGLE;
    }

    void KillTarget(string strTargetname, float flDelay)
    {
        if( strTargetname == "" )
            return;

        if( flDelay > 0.0f )
        {
            g_Scheduler.SetTimeout( this, "KillTarget", flDelay, strTargetname, 0.0f );
            return;
        }
        
        do( g_EntityFuncs.Remove( g_EntityFuncs.FindEntityByTargetname( null, strTargetname ) ) );
        while( g_EntityFuncs.FindEntityByTargetname( null, strTargetname ) !is null );
    }

    void Think()
    {
        if( !blShouldTrigger )
        {
            blShouldTrigger = true;
            self.pev.nextthink = 0.0f;
        }
    }

    void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
    {
        if( !blShouldTrigger || dictKeyValues.isEmpty() )
            return;

        const array<string> STR_KEYS = dictKeyValues.getKeys();

        if( iTargetNumber == STR_KEYS.length() )
            iTargetNumber = 0;

        string strCurrentTarget = STR_KEYS[iTargetNumber];
        strCurrentTarget.Trim( '#' );
        const string strValue = string( dictKeyValues[STR_KEYS[iTargetNumber]] );
        const float flDelay = atof( strValue );

        USE_TYPE utTriggerType = SetUseType();

        for( uint i = 0; i < strValue.Length(); i++ )
        {
            if( strValue[i] != '#' )
                continue;

            utTriggerType = SetUseType( atoui( strValue[i+1] ) );
            break;
        }

        if( utTriggerType != USE_KILL )
        {
            if( utTriggerType == USE_SET )
                g_EntityFuncs.FireTargets( strCurrentTarget, pActivator, pCaller, useType, 0.0f, flDelay );
            else
                g_EntityFuncs.FireTargets( strCurrentTarget, pActivator, pCaller, utTriggerType, 0.0f, flDelay );
        }
        else
            KillTarget( strCurrentTarget, flDelay );

        if( self.pev.health > 0.0f )
        {
            blShouldTrigger = false;
            self.pev.nextthink = g_Engine.time + self.pev.health;
        }

        iTargetNumber += 1;
    }
}
