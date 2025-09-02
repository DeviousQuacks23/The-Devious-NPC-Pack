local npcManager = require("npcManager")

local fire = {}
local deathEffectID = (756)

local npcID = NPC_ID

npcManager.setNpcSettings({
	id=npcID,
	
	width=40,
	
	height=40,
	gfxheight=64,
	
	gfxwidth=64,
	
	frames=3,
        framestyle = 1,
	framespeed=4,
	gfxoffsety=8,

	npcblock=false,

	linkshieldable = false,
	noblockcollision=true,
	spinjumpsafe = false,
	
	jumphurt=true,
	
	playerblocktop = false,
	npcblocktop = false,
	
	nogravity = true,

	lightradius=128,
	lightcolor=Color.orange,
	lightbrightness=1,

	ishot = true,
	durability = 6,
	
	nofireball=true,
	noiceball = true,
	noyoshi = true,

	ignorethrownnpcs = true, --If you enable any of the harm types you should disable this.
})

--[[
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD,
	}, 
	{
		[HARM_TYPE_NPC]=deathEffectID,
		[HARM_TYPE_HELD]=deathEffectID,
		[HARM_TYPE_TAIL]=deathEffectID,
		[HARM_TYPE_PROJECTILE_USED]=deathEffectID,
	}
);
]]

function fire.onInitAPI()
	npcManager.registerEvent(npcID, fire, "onTickEndNPC")
end	

function fire.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data

	if not data.initialized then
		data.initialized = true
	end

	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

        v.speedX = 4 * v.direction

	-- Collide with walls

        local hit = false

	local function solidNPCFilter(v) -- Filter for Colliders.getColliding to only return NPCs that are solid to NPCs
    		return (not v.isGenerator and not v.isHidden and not v.friendly and (NPC.config[v.id] and NPC.config[v.id].npcblock))
	end

        -- Account for blocks
        for _,w in ipairs(Colliders.getColliding{a = v, b = Block.SOLID.. Block.PLAYER, btype = Colliders.BLOCK}) do
		if not w.isHidden and not w:mem(0x5A, FIELD_BOOL) then
            		hit = true
		end
        end
        
        -- Account for NPCs
        hit = hit or (#Colliders.getColliding{a = v, btype = Colliders.NPC, filter = solidNPCFilter} > 0)

        if hit then
        	v:kill(HARM_TYPE_OFFSCREEN)
                local e = Effect.spawn(deathEffectID, v.x + v.width * 0.5,v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
        end
end

return fire