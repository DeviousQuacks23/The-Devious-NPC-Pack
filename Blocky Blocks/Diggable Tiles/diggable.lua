local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local playerManager = require("playerManager")

-- Code taken from MDA's Subspace Door
-- Diggable Sand sprites by Sednaiur
-- Diggable Cloud sprites by Murphmario

local diggable = {}

diggable.sharedSettings = {
	gfxheight = 32,
	gfxwidth = 32,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

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
	staticdirection = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = true,

        -- Custom Settings

        effect = 10,
	effectSpeed = nil,

	renderPriority = -76,

	slashable = true,
	explodable = true,
	poofSFX = 88,
}

diggable.idMap = {}

function diggable.register(npcID)
	diggable.idMap[npcID] = true

	npcManager.registerEvent(npcID, diggable, "onTickEndNPC")
	npcManager.registerEvent(npcID, diggable, "onDrawNPC")
	npcManager.registerEvent(npcID, diggable, "onPostExplosionNPC")
end

local characterGrabSpeeds = {
    	[CHARACTER_MARIO] = 12,
    	[CHARACTER_LUIGI] = 12,
    	[CHARACTER_PEACH] = 16,
    	[CHARACTER_TOAD]  = 8,
    	[CHARACTER_LINK]  = 1,
}

local function poof(v, config, playPoofSound)
	local e = Effect.spawn(config.effect, v)
	if config.effectSpeed then e.speedY = config.effectSpeed end

	if playPoofSound and config.poofSFX then
		SFX.play(config.poofSFX)
	end

	v:kill(9)
end

function diggable.onTickEndNPC(v)
        local config = NPC.config[v.id]

        if v.isProjectile then v.isProjectile = false end
        v.speedX = 0
        v.speedY = 0

	npcutils.applyLayerMovement(v)

        for _,p in ipairs(Player.get()) do
                local grabSpeed = characterGrabSpeeds[playerManager.getBaseID(p.character)]

                if p.standingNPC == v and p:mem(0x26, FIELD_WORD) >= grabSpeed then
                        p.speedX = p:mem(0x28, FIELD_FLOAT)
                        p.speedY = p.standingNPC.speedY
                        if p.speedY == 0 then p.speedY = 0.01 end

                        p:mem(0x26, FIELD_WORD, 0) -- grab timer
                        p:mem(0x28, FIELD_FLOAT, 0) -- grab speed
                        p:mem(0x164, FIELD_WORD, 0) -- tail swipe timer

			poof(v, config, false)
                end

		if config.slashable then
			if Colliders.slash(p, v) then
				poof(v, config, true)
			end

			if (playerManager.getBaseID(p.character) == 5) and Colliders.speedCollide(p, v) and (p.frame == 10) and (p.y >= v.y + v.height) then
				poof(v, config, true)
			end

			if Colliders.downSlash(p, v) then
				poof(v, config, true)

                        	p.speedY = Defines.jumpspeed
                        	p:mem(0x11C,FIELD_WORD, 10)
			end
		end
        end
end

function diggable.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        local config = NPC.config[v.id]

	if not config.renderPriority then return end

	npcutils.drawNPC(v,{priority = config.renderPriority})
	npcutils.hideNPC(v)
end

function diggable.onPostExplosionNPC(e, explosion, player)
	for _,v in ipairs(NPC.get()) do
        	local config = NPC.config[v.id]

		if diggable.idMap[v.id] then
			if config.explodable then
				if Colliders.collide(explosion.collider, v) and not v.isHidden then
					poof(v, config, true)
				end
			end
		end
	end
end

return diggable