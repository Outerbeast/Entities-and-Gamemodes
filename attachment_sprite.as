/* attachment_sprite - extension for env_sprite
Adds support for env_sprites to be attached to models

	Installation:-
	- Place in scripts/maps
	- Add
	map_script attachment_sprite
	to your map cfg
	OR
	- Add
	#include "attachment_sprite"
	to your main map script header
	OR
	- Create a trigger_script with these keys set in your map:
	"classname" "trigger_script"
	"m_iszScriptFile" "attachment_sprite"

    Usage:-
    - Create and configure your env_sprite
    - Check flag box 3
    - Select the target entity to attach to using "netname" key and specifying the entity targetname for the value
    - Select the attachment point using "impulse" key and setting the attachment point number for the value

    Changing "netname" and "impulse" at runtime via trigger_changevalue is allowed so you can change the attachment entity and the attachment point respectively.
    If you wish to un-attach the sprite momentarily, use trigger_changevalue to change the sprite's "iuser1" value to 1, this will
    free the sprite and become standalone. You can change it back to 0 to re-attach it to the attachment entity.
*/
namespace ATTACHMENT_SPRITE
{

enum AttachState
{
    NONE,
    ATTACHED,
    FREE
};

CScheduledFunction@ fnSpriteThink = g_Scheduler.SetInterval( "SpriteThink", 0.1f );

void AttachSprite(CSprite@ pSprite, CBaseAnimating@ pCarrier)
{
    if( pSprite is null || pCarrier is null )
        return;
    // No more than 4 attachment points are allowed, so I'm told
    pSprite.pev.impulse = Math.clamp( 0, 3, pSprite.pev.impulse );

    if( pSprite.pev.impulse >= pCarrier.GetAttachmentCount() )
        pSprite.pev.impulse = pCarrier.GetAttachmentCount() - 1;

    @pSprite.pev.owner = pCarrier.edict();
    pSprite.SetAttachment( pSprite.pev.owner, pSprite.pev.impulse );
    pSprite.GetUserData( "attach_state" ) = ATTACHED;
}

void FreeSprite(CSprite@ pSprite)
{
    if( pSprite is null || pSprite.pev.aiment is null )
        return;

    Vector vecCurrentPos;

    if( pSprite.pev.owner !is null )
    {
        CBaseAnimating@ pCarrier = cast<CBaseAnimating@>( g_EntityFuncs.Instance( pSprite.pev.owner ) );

        if( pCarrier !is null )
            pCarrier.GetAttachment( pSprite.pev.body, vecCurrentPos, void );
    }

    pSprite.pev.movetype = MOVETYPE_NONE;
    pSprite.pev.body = pSprite.pev.skin = 0;
    @pSprite.pev.aiment = null;

    if( vecCurrentPos != g_vecZero )
        g_EntityFuncs.SetOrigin( pSprite, vecCurrentPos );
    
    pSprite.GetUserData( "attach_state" ) = FREE;
}

void SpriteThink()
{
    CSprite@ pSprite;

    while( ( @pSprite = cast<CSprite@>( g_EntityFuncs.FindEntityByClassname( pSprite, "env_sprite" ) ) ) !is null )
    {
        if( pSprite is null || pSprite.pev.netname == "" || !pSprite.pev.SpawnFlagBitSet( 1 << 3 ) ) 
            continue;

        CBaseAnimating@ pCarrier = cast<CBaseAnimating@>( g_EntityFuncs.FindEntityByTargetname( pCarrier, pSprite.pev.netname ) );

        if( pSprite.pev.owner is null )
            AttachSprite( pSprite, pCarrier );
        else// This sprite is already attached
        {   
            if( AttachState( pSprite.GetUserData( "attach_state" ) ) == ATTACHED )
            {
                if( pSprite.pev.body != pSprite.pev.impulse )
                    pSprite.pev.body = Math.clamp( 0, 3, pSprite.pev.impulse );
                // Mapper wants to make this sprite free from carrier
                if( pSprite.pev.iuser1 == 1 )
                    FreeSprite( pSprite );
            }
            else if( AttachState( pSprite.GetUserData( "attach_state" ) ) == FREE && pSprite.pev.iuser1 == 0 )
            {// Sprite was previously freed, now reattach
                pSprite.SetAttachment( pSprite.pev.owner, Math.clamp( 0, 3, pSprite.pev.impulse ) );
                pSprite.GetUserData( "attach_state" ) = ATTACHED;
            }
            else if( string( pSprite.pev.netname ) != string( pSprite.pev.owner.vars.targetname ) )// sprite netname changed by mapper, find a new carrier
                AttachSprite( pSprite, pCarrier );
        }
    }
}

}

