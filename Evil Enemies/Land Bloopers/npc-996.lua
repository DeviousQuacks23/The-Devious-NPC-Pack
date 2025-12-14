local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local inkShot = {}

local npcID = NPC_ID
local inkEffectID = (npcID + 3)

local inkShotSettings = {
	id = npcID,

	gfxheight = 16,
	gfxwidth = 16,

	height = 16,
	width = 16,

	frames = 1,

	ignorethrownnpcs = true,
	linkshieldable = true,
	nogravity = 1,

	jumphurt = 1,
	noblockcollision = 1,
    	noyoshi = 1,
	noiceball = 1,
}

npcManager.setNpcSettings(inkShotSettings)

function inkShot.onInitAPI()
	npcManager.registerEvent(npcID, inkShot, "onTickNPC")
end

function inkShot.onTickNPC(v)
	if Defines.levelFreeze then return end

	v.data.timer = (v.data.timer or 0) + 1
	if v.data.timer and v.data.timer % 7 == 0 then
		local e = Effect.spawn(inkEffectID, v.x + v.width * 0.5,v.y + v.height * 0.5)
		e.x = e.x - e.width * 0.5
		e.y = e.y - e.height * 0.5
		e.speedX = -(v.speedX * 0.5)
	end

	if v.heldIndex ~= 0 or v.forcedState > 0 then return end

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
	        for j = 1, RNG.randomInt(4, 10) do
                        local e = Effect.spawn(inkEffectID, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5
		        e.speedX = RNG.random(-5, 5)
		        e.speedY = RNG.random(-5, 5)
	        end  
		
		SFX.play(72, 0.75)
		v:kill(9)
	end
end

return inkShot