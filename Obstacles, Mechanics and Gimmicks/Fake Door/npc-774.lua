local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

-- Code taken from MDA's Subspace Door

local fakeDoor = {}
local npcID = NPC_ID

local fakeDoorSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 64,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 0,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
	ignorethrownnpcs = true,
	isstationary = true,

	doorRotation = true,
}

npcManager.setNpcSettings(fakeDoorSettings)

function fakeDoor.onInitAPI()
	npcManager.registerEvent(npcID, fakeDoor, "onTickNPC")
	npcManager.registerEvent(npcID, fakeDoor, "onDrawNPC")
end

local function canEnterDoor(p)
	return (
		p.forcedState == FORCEDSTATE_NONE
		and p.deathTimer == 0
		and not p:mem(0x13C,FIELD_BOOL)

		and not p.isMega
		and not p.climbing
		and p.mount ~= MOUNT_CLOWNCAR

		and not p:mem(0x0C,FIELD_BOOL) -- fairy
		and not p:mem(0x44,FIELD_BOOL) -- rainbow shell
		and not p:mem(0x5C,FIELD_BOOL) -- yoshi ground pound
		and p:mem(0x15C,FIELD_WORD) == 0 -- warp cooldown
	)
end

function fakeDoor.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.rotation = 0
		data.rotTimer = 0
		data.timer = 0
	end

	if v.heldIndex ~= 0  or v.forcedState > 0 then return end
        if v.isProjectile then v.isProjectile = false end

	-- cool door rotation (from super mario run)

	data.timer = data.timer - 1

	if data.timer <= 0 then
		if NPC.config[v.id].doorRotation then
			if lunatime.tick() % RNG.randomInt(300, 800) == 0 then
				data.timer = RNG.randomInt(50, 150)
			end
		end
		data.rotTimer = 0
                if data.rotation > 0 then
                        data.rotation = math.max(0,data.rotation - 2)
                elseif data.rotation < 0 then
                        data.rotation = math.min(0,data.rotation + 2)
                else
                        data.rotation = 0
                end
	elseif data.timer > 0 then
		data.rotTimer = data.rotTimer + 1
		data.rotation = math.sin((data.rotTimer / 12) * math.pi) * 16
	end

	-- the actual door logic
	
	local x1 = v.x + v.width*0.5 - 0.5
	local x2 = v.x + v.width*0.5 + 0.5
	local y1 = v.y + v.height - 1
	local y2 = v.y + v.height

	for _,p in ipairs(Player.getIntersecting(x1,y1,x2,y2)) do
		if p.keys.up and canEnterDoor(p) then
			local e1 = Effect.spawn(131, v.x, v.y - 16)
			e1.speedX = -2
		        e1.speedY = -3
			local e2 = Effect.spawn(131, v.x, v.y - 16)
		        e2.speedX = 2
		        e2.speedY = 3
			local e3 = Effect.spawn(131, v.x, v.y - 16)
		        e3.speedX = -2
		        e3.speedY = 3
			local e4 = Effect.spawn(131, v.x, v.y - 16)
		        e4.speedX = 2
		        e4.speedY = -3
	                SFX.play("pranked.ogg")
		        Effect.spawn(11,v.x + 16,v.y + 32)
		        Misc.coins(1,false)
	                v:kill(HARM_TYPE_OFFSCREEN)
		end
	end 	
end

function fakeDoor.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img

	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,
		height = config.gfxheight,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
		sceneCoords = true,
		centered = true,
                rotation = data.rotation,
		priority = -85,
	}

	npcutils.hideNPC(v)
end

return fakeDoor