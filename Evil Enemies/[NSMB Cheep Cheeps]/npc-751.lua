local npcManager = require("npcManager")

local mechaCheep = {}
local npcID = NPC_ID

local mechaCheepSettings = {
	id = npcID,

	gfxwidth = 48,
	gfxheight = 34,
	width = 32,
	height = 32,
	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 8,
	framestyle = 1,
	framespeed = 6, 

	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,

	nohurt = false,
	nogravity = true,
	noblockcollision = false,
	notcointransformable = false, 

	nofireball = true,
	noiceball = false,
	noyoshi= true, 

	score = 2, 

	jumphurt = true, 
	spinjumpsafe = true, 

	weight = 2,

	-- Custom settings

	sfxLoop = Misc.resolveFile("mechaCheepLoop.ogg"),
	volume = 0.35,
	radius = 256,
}

npcManager.setNpcSettings(mechaCheepSettings)

local deathEffectID = (npcID)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	},
	{
		[HARM_TYPE_FROMBELOW]       = deathEffectID,
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_PROJECTILE_USED] = deathEffectID,
		[HARM_TYPE_HELD]            = deathEffectID,
		[HARM_TYPE_TAIL]            = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
);

function mechaCheep.onInitAPI()
	npcManager.registerEvent(npcID, mechaCheep, "onTickEndNPC")
	registerEvent(mechaCheep, "onPostNPCKill") 
end

function mechaCheep.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false

		if data.sound then
			data.sound:stop()
		end

		return
	end

	if not data.initialized then
		data.initialized = true
                data.timer = 0
                data.hasBeenUnderwater = false

		if config.sfxLoop then
			data.sound = SFX.create{
				x = v.x + v.width*0.5,
				y = v.y + v.height*0.5,
				sound = config.sfxLoop,
				parent = v,
				type = typ,
				volume = config.volume,
				falloffRadius = config.radius,
				falloffType = SFX.FALLOFF_LINEAR,
				sourceRadius = 32,
				sourceWidth = v.width,
				sourceHeight = v.height,
				sourceVector = vector.v2(64, 0)
			}
		end
	end

	-- Play SFX

	if data.sound ~= nil then
		local cx = v.x + v.width*0.5
		local cy = v.y + v.height*0.5
		local r = data.sound.falloffRadius
		for _,c in ipairs(Camera.get()) do
			if cx + r > c.x and cx - r < c.x + c.width and 
			   cy + r > c.y and cy - r < c.y + c.height then
				if not v:mem(0x124, FIELD_BOOL) then
					v:mem(0x124, FIELD_BOOL, true)
				end
				v:mem(0x12A, FIELD_WORD, 180)
			end
		end
		
		if v.isHidden and data.sound.playing then
			data.sound:stop()
		elseif not v.isHidden and not data.sound.playing  then
			data.sound:play()
		end
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
	
	-- Main AI

        data.timer = data.timer + 1

        if v.underwater then -- If the NPC is underwater...
                data.hasBeenUnderwater = true
                v.noblockcollision = false

                v.speedX = 3.5 * v.direction
                v.speedY = 0.5 * math.sin(data.timer * 0.1)

                if (data.timer % 12) == 0 then
                        local e = Effect.spawn(10, v.x + v.width * 0.5, v.y + v.height * 0.5) -- Spawn an effect every 12 ticks
                        e.x = e.x - ((e.width * 0.5) + (v.width * 0.5) * v.direction)
                        e.y = e.y - e.height * 0.5
                end
        else
                v.noblockcollision = true
                v.speedY = v.speedY + Defines.npc_grav -- Emulate gravity, since nogravity is enabled.
                if data.hasBeenUnderwater then
                        v.speedX = 1 * v.direction
                else
                        v.speedX = 0
                end
        end
end

function mechaCheep.onPostNPCKill(v, r)
	if v.id == npcID then
		local data = v.data

		if data.sound then
			data.sound:destroy()
		end

		if r ~= HARM_TYPE_LAVA and r ~= HARM_TYPE_OFFSCREEN and r ~= HARM_TYPE_SWORD then
                	local e = Effect.spawn(75, v.x + v.width * 0.5,v.y + v.height * 0.5)
                	e.x = e.x - e.width * 0.5
                	e.y = e.y - e.height * 0.5
			SFX.play(57, 0.5)
		end
	end
end

return mechaCheep