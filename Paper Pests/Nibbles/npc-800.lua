local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local nibbles = {}
local npcID = NPC_ID

-- Sprites by SuperAlex

local nibblesSettings = {
	id = npcID,

	gfxwidth = 78,
	gfxheight = 74,
	width = 48,
	height = 48,
	gfxoffsetx = 8,
	gfxoffsety = 8,

	frames = 2,
	framestyle = 1,
	framespeed = 8, 

	luahandlesspeed = true, 
	nowaterphysics = true,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = false,
	nogravity = true,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	score = 6, 

	jumphurt = true, 
	spinjumpsafe = true, 
	harmlessgrab = false, 
	harmlessthrown = false, 
	ignorethrownnpcs = false,
	nowalldeath = false, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside=false,
	grabtop=false,

	weight = 2,
	staticdirection = true, 

	-- Custom Properties

        health = 5,
}

npcManager.setNpcSettings(nibblesSettings)

local deathEffectID = (788)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

function nibbles.onInitAPI()
	npcManager.registerEvent(npcID, nibbles, "onTickEndNPC")
	registerEvent(nibbles, "onNPCHarm") 
end

function nibbles.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.canLeap = false
		data.hasLeaped = false
		data.health = config.health
		data.immunity = 0
		data.attackCollider = data.attackCollider or Colliders.Box(v.x, v.y, v.width, v.height)
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
	
	-- Main AI

	data.immunity = data.immunity - 1

	data.attackCollider.x = v.x + 12 * v.direction
	data.attackCollider.y = v.y

        if v.underwater then 
		data.hasLeaped = false
                data.canLeap = true
                npcutils.faceNearestPlayer(v)
	        data.pos = vector((Player.getNearest(v.x + v.width/2, v.y + v.height).x + Player.getNearest(v.x + v.width/2, v.y + v.height).width * 0.5) - (v.x + v.width * 0.5), (Player.getNearest(v.x + v.width/2, v.y + v.height).y + Player.getNearest(v.x + v.width/2, v.y + v.height).height * 0.5) - (v.y + v.height * 0.5)):normalize()
	        v.speedX = data.pos.x * 2
	        v.speedY = data.pos.y * 2
        else
                v.speedX = 2 * v.direction
                v.speedY = v.speedY + Defines.npc_grav 
                if data.canLeap and not data.hasLeaped then 
			v.speedY = -6
			npcutils.faceNearestPlayer(v)
			data.hasLeaped = true
		end
                if v.collidesBlockBottom then
			v.speedY = -4
			npcutils.faceNearestPlayer(v)
			SFX.play("nibblesLand.ogg")
		        for j = 1, RNG.randomInt(4, 16) do
		                local e = Effect.spawn(74,0,0)
				e.x = (v.x+v.width*0.5)-(e.width*0.5)
		                e.y = v.y+v.height-e.height * 0.5
                                e.speedX = RNG.random(-5, 5)
                                e.speedY = RNG.random(0, 5)
                        end
                end
        end

	if data.immunity > 0 then
		if lunatime.tick() % 2 == 0 then v.animationFrame = -50 end
	end

        for k,n in ipairs(NPC.getIntersecting(v.x - 32, v.y - 32, v.x + v.width + 32, v.y + v.height + 32)) do
                if Colliders.collide(v,n) and Misc.canCollideWith(v, n) then
                        if n.idx ~= v.idx and (not n.isProjectile) and (not n.isHidden) and (not n.friendly) and NPC.HITTABLE_MAP[n.id] then
                                n:harm(3)
                        end
                end
        end

	local list = Colliders.getColliding{
	a = data.attackCollider,
	btype = Colliders.BLOCK,
	filter = function(other)
		if other.isHidden and other:mem(0x5A, FIELD_BOOL) then
			return false
		end
		return true
	end
	}
	for _,b in ipairs(list) do
		if Block.MEGA_SMASH_MAP[b.id] or Block.MEGA_HIT_MAP[b.id] or (Block.config[b.id].smashable ~= nil and Block.config[b.id].smashable == 3) then
			b:remove(true)
		end
	end
end

function nibbles.onNPCHarm(e, v, r, c)
	if v.id ~= npcID then return end
	if r == HARM_TYPE_LAVA or r == HARM_TYPE_OFFSCREEN then return end
	local data = v.data
        if c ~= nil then Effect.spawn(75, c.x, c.y) end
	if type(c) == "NPC" then c:harm(HARM_TYPE_NPC) end
	if 0 >= data.immunity then
		if data.health > 1 then
			e.cancelled = true
			data.health = data.health - 1
			data.immunity = 20
			SFX.play(39)
		end
	else
		e.cancelled = true
		SFX.play(3)
	end
end

return nibbles