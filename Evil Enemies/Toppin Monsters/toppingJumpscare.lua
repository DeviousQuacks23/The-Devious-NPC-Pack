--[[
				toppingJumpscare.lua by DeviousQuacks23
	A script that adds the Toppin Monsters from Pizza Tower into SMBX (Jumpscares included). Happy Halloween!
			
	CREDITS:
	MegaDood - Created the Inky Piranha Plant, which was used as a base for the jumpscares
        Emral - I used the code from spawnzones.lua to always load the monsters into the level
        FNC2002 - I used the Timer Blocks as a base for the Alarm Blocks (if it wasn't obvious enough)
        Jaf -  The indicator code was taken from the episode, 'Super Mario Miracle 2' 

        Note - this is NOT compatible with multiplayer.
]]--

local toppingJumpscare = {}

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local blockutils = require("blocks/blockutils")
local playerStun = require("playerstun")

local toppingMap = {}
local killerList = table.map{17, 18, 30, 50, 195, 617} -- list of NPCs that can kill the monsters

local activatedAlarmBlockID = 753
local deactivatedAlarmBlockID = 754

local image = nil
local colour = nil

local effectImage = Graphics.loadImageResolved("toppingJumpscare/effect.png")
local alertImage = Graphics.loadImageResolved("toppingJumpscare/indicator.png")
local dangerImage = Graphics.loadImageResolved("toppingJumpscare/danger.png")

local oktoberfestImg = Graphics.loadImageResolved("toppingJumpscare/oktoberfest.png")

local alertMusic = Misc.resolveFile("toppingJumpscare/hard_drive.ogg")
local scareSFX = Misc.resolveFile("toppingJumpscare/jumpscare.ogg")
local secretScareSFX = Misc.resolveFile("toppingJumpscare/yodel.ogg")

local loopShader = Shader()
loopShader:compileFromFile(nil, Misc.resolveFile("sh_loop.frag"))

local IDLE = 0
local AWAKEN = 1
local CHASE = 2

local active = false
local oktober = false

local jumpTimer = 0
local jumpSlider = 0
local jumped = false

local frame = 0
local frameTimer = 0
local canPlayEffect = false

local dangerX = 0
local dangerY = 0
local dangerIntensity = 0

local dir = 1
local limit = 200

local playing = false

local indi_frame = 0
local indicator = Sprite{
	image = alertImage,
	x = 0,
	y = 0,
	sourceX = 0,
	sourceY = 0,
	frames=2,
	pivot=vector(0.5, 0.5)
}

function toppingJumpscare.register(npcID)
	npcManager.registerEvent(npcID, toppingJumpscare, "onTickEndNPC")
	npcManager.registerEvent(npcID, toppingJumpscare, "onDrawNPC")
        toppingMap[npcID] = true
end

function toppingJumpscare.onInitAPI()
        registerEvent(toppingJumpscare,"onTick")
        registerEvent(toppingJumpscare,"onDraw")
        registerEvent(toppingJumpscare,"onNPCHarm")
        registerEvent(toppingJumpscare,"onLoadSection")
	Cheats.register("riseandshine",{
		isCheat = true,
		activateSFX = (scareSFX),
		aliases = {"harddrive","imadeasound","hauntedpizzatoppings"},
		onActivate = (function() 
                        toppingJumpscare.riseAndShine()
			return true
		end)
	})
end

local function canJumpscare(p)
    return (
        p.forcedState == 0
        and p.deathTimer == 0 -- not dead
        and not p.inLaunchBarrel
        and not p.inClearPipe
        and not p:mem(0x4A,FIELD_BOOL) -- statue
        and not p.isMega
        and not p.hasStarman
    )
end

local function displayIndicators()
        for _,n in NPC.iterate() do
                if toppingMap[n.id] then
                        if n.section == player.section and n.data.state ~= IDLE then
		                if not (n.x > camera.x - 32 and n.x < camera.x + camera.width + 32 and n.y > camera.y and n.y < camera.y + camera.height) then  -- if NOT within camera range
			                indicator:draw{
				                priority=1,
				                sceneCoords = false,
				                frame = math.floor(indi_frame + 1)
			                }		
			                if n.x < camera.x - 32 then  -- indicator to the left
				                indicator.x = 32
			                elseif n.x > camera.x + camera.width - 32 then
				                indicator.x = camera.width - 32
			                else
				                indicator.x = n.x + 16 - camera.x
			                end
			                if n.y < camera.y - 32 then
				                indicator.y = 32
			                elseif n.y > camera.y + camera.height - 32 then
				                indicator.y = camera.height - 32
			                else
				                indicator.y = n.y + 32 - camera.y
			                end
                                end
			end
		end		
	end
end

function toppingJumpscare.onTick()
	if jumpTimer > 0 then
                if not oktober then
                        Defines.earthquake = 2.5
                end
		jumpTimer = jumpTimer - 1
		jumped = true
		if jumpSlider > 0 then
			jumpSlider = jumpSlider - 15
		end
	else
		jumped = false
	end

	if jumpTimer == 1 then
                Defines.levelFreeze = false
		canPlayEffect = true
                frame = 0
                frameTimer = 0
                active = false
                playerStun.stunPlayer(player.idx, 150)
                oktober = false
	end

        if jumped then
	        if jumpTimer > 1 then
                        Defines.levelFreeze = true
                        player.forcedState = FORCEDSTATE_ONTONGUE
                end
        end

        if active then
	        if not playing then
			Audio.SeizeStream(-1)
			Audio.MusicOpen(alertMusic)
			Audio.MusicPlay()
                        playing = true
                end
		blockutils.setBlockFrame(activatedAlarmBlockID, 1)
		Block.config[activatedAlarmBlockID].passthrough = true
		blockutils.setBlockFrame(deactivatedAlarmBlockID, 1)
		Block.config[deactivatedAlarmBlockID].passthrough = false
        else
	        if playing then
                        Audio.ReleaseStream(-1)
		        playing = false
	        end
		blockutils.setBlockFrame(activatedAlarmBlockID, 0)
		Block.config[activatedAlarmBlockID].passthrough = false
		blockutils.setBlockFrame(deactivatedAlarmBlockID, 0)
		Block.config[deactivatedAlarmBlockID].passthrough = true
        end

	displayIndicators()
	indi_frame = (indi_frame + 0.25) % 2

        for _,n in NPC.iterate() do
                if toppingMap[n.id] then
                        if n.section == player.section then
                                if n:mem(0x124,FIELD_BOOL) then
                                        n:mem(0x12A, FIELD_WORD, 180)
                                elseif n:mem(0x12A, FIELD_WORD) == -1 then
                                        if n.x + n.width < camera.x or n.x > camera.x + camera.width or n.y > camera.y + camera.height or n.y + n.height < camera.y then
                                                n:mem(0x124,FIELD_BOOL, true)
                                                n:mem(0x12A, FIELD_WORD, 180)
                                        end
                                end
                        end
                end
        end
end

function toppingJumpscare.onDraw()
	if jumped then
		Graphics.drawBox{
                texture = image,
                x = 0,
                y = jumpSlider,
                priority = 7
                }

                Graphics.drawScreen{
                priority = 6,
                color = colour
                }
	end

	if canPlayEffect then
                if frameTimer ~= 36 then
                        frameTimer = frameTimer + 1
		        Graphics.drawBox{
                        texture = effectImage,
                        x = 0,
                        y = 0,
		        sourceY = frame * camera.height,
                        priority = 8
                        }

                        frame = math.min(8, math.floor(frameTimer / 4))
                else
                        canPlayEffect = false
                end
        end

        if active then
		Graphics.drawBox{
                texture = dangerImage,
                x = 0,
                y = 0,
                sourceX = dangerX,
                sourceY = dangerY,
                sourceWidth = dangerImage.width,
                sourceHeight = dangerImage.height,
                color = Color.white .. (dangerIntensity * 0.003),
		shader = loopShader,
                priority = -96
                }
                dangerIntensity = math.clamp(dangerIntensity + dir, 0, limit)
                if dangerIntensity == limit then
                        dir = -1
                elseif dangerIntensity == 0 then
                        dir = 1
                end
                dangerX = dangerX + 1
                dangerY = dangerY + 0.5
        else
                dangerIntensity = 0
                dangerX = 0
                dangerY = 0
        end
end

function toppingJumpscare.onLoadSection()
        active = false
        oktober = false
end

local function initialise(v,data)
	if not data.initialised  then
		data.initialised = true

	        data.state = IDLE
                data.timer = 0
                data.wokeUp = false
                data.vulnerable = false
                data.priority = -76
		data.attackCollider = data.attackCollider or Colliders.Box(v.x, v.y, v.width, v.height)
	end
end

function toppingJumpscare.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local cfg = NPC.config[v.id]
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialised = false
		return
	end

        initialise(v,data)

	if v.heldIndex ~= 0 
	or v.isProjectile  
	or v.forcedState > 0 
	then
		return
	end
	
	-- Put main AI below here

        data.timer = data.timer + 1

	data.attackCollider.x = v.x + 12 * v.direction
	data.attackCollider.y = v.y

	if data.state == CHASE then
                data.vulnerable = true
        end

        if v.y > (player.sectionObj.boundary.bottom + 128) then -- Manually kill the NPC if it falls below the player's section bounds
                v:kill(9)
        end

        if data.vulnerable then
        for _,p in ipairs(Player.getIntersecting(v.x, v.y, v.x + v.width, v.y + v.height)) do
                if canJumpscare(p) and not jumped then
                        toppingJumpscare.jumpscarePlayer()
                        if oktober then
                                image = oktoberfestImg
                                colour = Color.fromHexRGB(0x58C000)
                        else
                                image = cfg.image
                                colour = Color.fromHexRGB(0xF80000)
                        end
			if settings.shouldTP then
				p:teleport(settings.tele[1], settings.tele[2])
			end
                end
        end

        for _,n in ipairs(NPC.getIntersecting(v.x - 32, v.y - 32, v.x + v.width + 32, v.y + v.height + 32)) do
                if Colliders.collide(v, n) and Misc.canCollideWith(v, n) then
                        if n.idx ~= v.idx and not toppingMap[n.id] and (not n.isHidden) and (not n.friendly) and NPC.HITTABLE_MAP[n.id] then
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
end

function toppingJumpscare.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

	local data = v.data

	npcutils.drawNPC(v,{priority = data.priority})
	npcutils.hideNPC(v)

        if data.wokeUp then
                data.priority = -45
        end
end

function toppingJumpscare.onNPCHarm(eventObj,v,reason,culprit)
	if not toppingMap[v.id] then return end

	local data = v.data._basegame

        if reason ~= HARM_TYPE_LAVA then
		if type(culprit) == "NPC" and killerList[culprit.id] then
			v:harm(3)
		else
                        eventObj.cancelled = true
                        if data.vulnerable then
                                culprit:harm(3)
                        end
		end
        end
end

function toppingJumpscare.riseAndShine()
        for _,n in NPC.iterate() do
            local data = n.data
                if toppingMap[n.id] then
                        if n.section == player.section then
                                if not data.wokeUp then
                                        npcutils.faceNearestPlayer(n)
                                        data.state = AWAKEN
                                        data.timer = 0
                                        data.wokeUp = true
                                        active = true
                                        dangerIntensity = limit
                                        if RNG.randomInt(1, 250) == 1 then
                                                oktober = true
                                        end
                                end
                        end
                end
        end
end

function toppingJumpscare.jumpscarePlayer()
	jumpTimer = 125
        if oktober then
                SFX.play(secretScareSFX)
        else
	        jumpSlider = camera.height
                SFX.play(scareSFX)
        end
        for _,n in NPC.iterate() do
                if toppingMap[n.id] then
                        if n.section == player.section then
                                n.speedX = 0      
                                n.speedY = 0            
                                n.x = n.spawnX
                                n.y = n.spawnY
                                n.direction = n.spawnDirection
                                n.data.initialised = false
                        end
                end
        end
end

return toppingJumpscare