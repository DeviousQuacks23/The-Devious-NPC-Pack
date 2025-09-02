local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local playerManager = require("playerManager")

-- Code taken from MDA's Subspace Door

local corks = {}

corks.sharedSettings = {
	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	speed = 0,
	luahandlesspeed = true, 
	nowaterphysics = true,
	cliffturn = false,

	npcblock = true, 
	npcblocktop = false, 
	playerblock = true, 
	playerblocktop = true, 

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	notcointransformable = true, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	score = 0, 

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = true,
	nowalldeath = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = true,

        -- Custom Settings

        effect = 10,
}

function corks.register(npcID)
        npcManager.registerDefines(npcID, {NPC.UNHITTABLE})
	npcManager.registerEvent(npcID, corks, "onTickEndNPC")
	npcManager.registerEvent(npcID, corks, "onDrawNPC")
end

local characterGrabSpeeds = {
    [CHARACTER_MARIO] = 12,
    [CHARACTER_LUIGI] = 12,
    [CHARACTER_PEACH] = 16,
    [CHARACTER_TOAD]  = 8,
}

function corks.onTickEndNPC(v)
	if Defines.levelFreeze then return end

        local config = NPC.config[v.id]

        v.isProjectile = false
        v.speedX = 0
        v.speedY = 0

        for _,p in ipairs(Player.get()) do
                local grabSpeed = characterGrabSpeeds[playerManager.getBaseID(p.character)]
                if p.standingNPC == v and p:mem(0x26,FIELD_WORD) >= grabSpeed then
                        p.speedX = p:mem(0x28,FIELD_FLOAT)
                        p.speedY = p.standingNPC.speedY
                        if p.speedY == 0 then p.speedY = 0.01 end

                        p:mem(0x26,FIELD_WORD,0) -- grab timer
                        p:mem(0x28,FIELD_FLOAT,0) -- grab speed
                        p:mem(0x164,FIELD_WORD,0) -- tail swipe timer

                        local e = Effect.spawn(config.effect, v.x + v.width * 0.5,v.y + v.height * 0.5)
                        e.x = e.x - e.width * 0.5
                        e.y = e.y - e.height * 0.5

                        v:kill(9)
                end
        end
end

function corks.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	npcutils.drawNPC(v,{priority = -76})
	npcutils.hideNPC(v)
end

return corks