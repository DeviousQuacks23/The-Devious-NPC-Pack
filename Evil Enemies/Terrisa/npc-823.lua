local terrisa = {}

-- Concept and sprites by Smuglutena, taken from Super Mario Construct

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local easing = require("ext/easing")

local npcID = NPC_ID

terrisa.config = npcManager.setNpcSettings({
	id = npcID,
	gfxheight = 32,
	gfxwidth = 40,
	width = 32,
	height = 32,
	frames = 6,
	framespeed = -1,
	framestyle = 1,
	nogravity = true,
	jumphurt = true,
	speed = 1,
	nowaterphysics = true,
	spinjumpsafe = false,
	nogravity = true,
	noblockcollision=true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	ignorethrownnpcs = true,

	maxspeedx = 3,
	maxspeedy = 3,
	accelx = 0.15,
	accely = 0.15,
	decelx = 0.15,
	decely = 0.15,

        jumpscareImg = Graphics.loadImageResolved("npc-"..npcID.."b.png"),
})

local CHASE = 0
local LAUGH = 1
local HIDEAWAY = 2
local JUMPSCARE = 3

function terrisa.onInitAPI()
	npcManager.registerEvent(npcID, terrisa, "onTickEndNPC")
	npcManager.registerEvent(npcID, terrisa, "onDrawNPC")
end

function terrisa.onTickEndNPC(v)
	if Defines.levelFreeze then return end

        local data = v.data
	local cfg = NPC.config[v.id]

	local p = npcutils.getNearestPlayer(v)

	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true

                data.state = LAUGH
                data.timer = 0
		data.animTimer = 0
                data.initialDir = 0

                data.rotation = 0
                data.opacity = 1
                data.scale = 1

                data.isRendering = true

                data.screenOpacity = 0
                data.scareX = 0
                data.scareY = 0
                data.scareScale = 1
		data.scareLerp = 0
                data.scareFrame = 0
                data.scareOpacity = 0
	end

        for k,j in ipairs(Player.getIntersecting(v.x - 2, v.y - 2, v.x + v.width + 2, v.y + v.height + 2)) do
                if j.deathTimer == 1 then
			-- taken from deathAnimations, by M.O.D.
		        local lastOneStanding = true
		        for c, pl in ipairs(Player.get()) do
			        if pl.deathTimer == 0 then
				        lastOneStanding = false
			        end
		        end
		        if lastOneStanding then
                                data.state = JUMPSCARE
                                data.opacity = 1
                                data.timer = 0
				data.scale = 1
		        end
                end
        end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
                v.animationFrame = 0
		return
	end

        v.despawnTimer = 180
        data.timer = data.timer + 1
	data.animTimer = data.animTimer + 1

        for k,l in ipairs(Player.get()) do
                if l.section == v.section and l.hasStarman then
                        if data.state ~= HIDEAWAY then
                                data.state = HIDEAWAY
                                data.initialDir = v.direction
                        end
                end
        end

        if data.state == CHASE then
                v.animationFrame = 0
                data.opacity = math.min(1,data.opacity + 0.01)
                data.scale = 1
                data.rotation = 0

                if p then
		        if v.x + v.width/2 < p.x + p.width/2 then
			        if v.speedX < cfg.maxspeedx then
				        v.speedX = v.speedX + cfg.accelx
			        end
		        else
			        if v.speedX > -cfg.maxspeedx then
				        v.speedX = v.speedX - cfg.accelx
			        end
		        end

		        if v.y + v.height/2 < p.y + p.height/2 then
			        if v.speedY < cfg.maxspeedy then
				        v.speedY = v.speedY + cfg.accely
			        end
		        elseif v.speedY > -cfg.maxspeedy then
			        v.speedY = v.speedY - cfg.accely
		        end
	        else
		        if v.speedX ~= 0 then
			        if v.speedX > 0 then
				        v.speedX = v.speedX - cfg.decelx
			        elseif v.speedX < 0 then
				        v.speedX = v.speedX + cfg.decelx
			        end
		        end
		        if math.abs(v.speedX) < cfg.decelx then
				v.speedX = 0
			end
		        if v.speedY ~= 0 then
			        if v.speedY > 0 then
				        v.speedY = v.speedY - cfg.decely
			        elseif v.speedY < 0 then
				        v.speedY = v.speedY + cfg.decely
			        end
		                if math.abs(v.speedY) < cfg.decely then
				        v.speedY = 0
			        end
		        end
	        end

                if data.timer >= 730 then
                        data.state = LAUGH
                        data.timer = 0
                	v.speedX = 0
                	v.speedY = 0
                end
        elseif data.state == LAUGH then
                if v.speedX > 0 then
                        v.speedX = math.max(0, v.speedX - cfg.decelx)
                elseif v.speedX < 0 then
                        v.speedX = math.min(0, v.speedX + cfg.decelx)
                else
                        v.speedX = 0
                end

                if v.speedY > 0 then
                        v.speedY = math.max(0, v.speedY - cfg.decely)
                elseif v.speedY < 0 then
                        v.speedY = math.min(0, v.speedY + cfg.decely)
                else
                        v.speedY = 0
                end

                v.animationFrame = math.floor(data.animTimer / 4) % 2 + 1
                data.rotation = math.sin((data.timer / 12) * math.pi) * 12
                data.opacity = math.min(1,data.opacity + 0.01)

                npcutils.faceNearestPlayer(v)

                data.scale = data.scale - 0.05
                if data.scale <= 1 then data.scale = 1.5 end

                if RNG.randomInt(1,15) == 1 then
                        local e = Effect.spawn(80, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))
                        e.speedX = RNG.random(-2, 2)
                        e.speedY = RNG.random(-2, 2)
                        e.x = e.x - e.width *0.5
                        e.y = e.y - e.height*0.5
                end

                if data.timer >= 90 then
                        data.state = CHASE
                        data.timer = 0
                end
        elseif data.state == HIDEAWAY then
                v.speedX = 0
                v.speedY = 0
                v.animationFrame = math.floor(data.animTimer / 128) % 2 + 3

                data.opacity = math.max(0.5,data.opacity - 0.005)
                data.scale = 1
                data.rotation = 0

                if v.animationFrame == 4 then
                        if (data.timer % 20) == 0 then v.direction = -v.direction end
                else
                        v.direction = data.initialDir
                end 

                for k,l in ipairs(Player.get()) do
                        if l.section == v.section and not l.hasStarman then
                                data.state = CHASE
                                data.timer = 0
                                data.initialDir = 0
                        end
                end
        elseif data.state == JUMPSCARE then
                data.scareX = v.x + (v.width * 0.5)
                data.scareY = v.y + (v.height * 0.5)
        	v.speedY = 0

                if data.timer >= 20 then
                        v.animationFrame = 5
                        data.rotation = 0
                else
                        v.animationFrame = math.floor(data.animTimer / 4) % 2 + 1
                        data.rotation = math.sin((data.timer / 12) * math.pi) * 12
                end

                if data.timer >= 30 and data.timer <= 52 and data.screenOpacity <= 1 then
                        data.screenOpacity = math.min(1, data.screenOpacity + 0.05)
                else
                        data.screenOpacity = math.max(0, data.screenOpacity - 0.05)
                end

                if data.screenOpacity == 1 then data.isRendering = false end
                if data.timer >= 90 then
                        if data.timer >= 100 then 
                                data.scareOpacity = math.min(0.5, data.scareOpacity + 0.005) 
                                data.opacity = math.max(0, data.opacity - 0.01)
                        end
			
			if data.timer == 90 then
				v.speedX = math.sign((camera.x + (camera.width / 2)) - (v.x + (v.width / 2))) * 24
                                SFX.play("terrisaJumpscare.ogg")
                                data.scareFrame = 1
                        end

			data.scareLerp = math.min(1, data.scareLerp + 0.05) 
                        data.scareScale = easing.outBack(data.scareLerp, 0, 7, 1, 3)

			if (v.x + v.width * 0.5) > (camera.x + camera.width * 0.5) then
				v.speedX = v.speedX - 1.5
			else
				v.speedX = v.speedX + 1.5
			end
			v.speedX = math.clamp(v.speedX, -24, 24)

			local distY = camera.y + (camera.height * 0.5) - v.y + (v.height * 0.5)
                        v.speedY = v.speedY + (distY * 0.25)
		else
                	v.speedX = 0
                end
        end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = cfg.frames
	});
end

local lowPriorityStates = table.map{1,3,4}

function terrisa.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[npcID]

	local img = Graphics.sprites.npc[v.id].img
	local jumpImg = config.jumpscareImg
	local height = (jumpImg.height / 2)
        local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45

	if data.isRendering then
	        Graphics.drawBox{
		        texture = img,
		        x = v.x+(v.width/2)+config.gfxoffsetx,
		        y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		        width = config.gfxwidth * data.scale,
		        height = config.gfxheight * data.scale,
		        sourceY = v.animationFrame * config.gfxheight,
		        sourceHeight = config.gfxheight,
                        sourceWidth = config.gfxwidth,
		        sceneCoords = true,
		        centered = true,
                        rotation = data.rotation,
                        color = Color.white .. data.opacity,
		        priority = priority,
	        }
        else
	        Graphics.drawBox{
		        texture = jumpImg,
		        x = data.scareX,
		        y = data.scareY,
		        width = jumpImg.width * data.scareScale,
		        height = height * data.scareScale,
		        sourceY = data.scareFrame * height,
		        sourceHeight = height,
		        sceneCoords = true,
		        centered = true,
                        color = Color.white .. data.opacity,
		        priority = priority,
	        }

                -- Silhoutte

	        Graphics.drawBox{
		        texture = jumpImg,
		        x = data.scareX,
		        y = data.scareY,
		        width = jumpImg.width * data.scareScale,
		        height = height * data.scareScale,
		        sourceY = data.scareFrame * height,
		        sourceHeight = height,
		        sceneCoords = true,
		        centered = true,
                        color = Color.black .. data.scareOpacity,
		        priority = (priority + 1),
	        }
        end

        Graphics.drawScreen{
                priority = 6,
                color = Color.white .. data.screenOpacity
        }

	npcutils.hideNPC(v)
end

return terrisa