local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local magicBall = {}

magicBall.sharedSettings = {
	speed = 1,
	luahandlesspeed = true, 
	nowaterphysics = false,
	cliffturn = false,

	npcblock = false, 
	npcblocktop = false, 
	playerblock = false, 
	playerblocktop = false, 

	nohurt = true,
	nogravity = false,
	noblockcollision = false,
	notcointransformable = true, 

	nofireball = true,
	noiceball = true,
	noyoshi= true, 

	score = 0, 

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = true, 
	harmlessthrown = true, 
	ignorethrownnpcs = false,
	nowalldeath = true, 

	linkshieldable = false,
	noshieldfireeffect = false,

	grabside = false,
	grabtop = false,

        -- Custom Settings

        startBounceHeight = -8,
        bounceModifier = 0.25,
        bounceLimit = -3.5,

        jumpHeight = -14,

        isExplosive = false,
        explodeTime = 70,

        displayOutsideThing = false,

        rotate = true,
        squashAndStretch = true,
}

local deathEffectID = (76)

function magicBall.register(npcID)
	npcManager.registerEvent(npcID, magicBall, "onTickEndNPC")
	npcManager.registerEvent(npcID, magicBall, "onDrawNPC")
        npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_LAVA,
	},
	{
		[HARM_TYPE_NPC]             = deathEffectID,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
	}
        );
end

function magicBall.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
        local cfg = NPC.config[v.id]
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                v.noblockcollision = false
		data.height = cfg.startBounceHeight
                data.rotation = 0
                data.scaleX = 1
                data.scaleY = 1
                data.isExploding = false
                data.explodeTimer = 0
                data.explodeOpacity = 0
	end

        if cfg.rotate then data.rotation = data.rotation + 10 * v.direction end

        if data.scaleX > 1 then 
                data.scaleX = data.scaleX - 0.25
        elseif data.scaleX < 1 then 
                data.scaleX = data.scaleX + 0.25
        end

        if data.scaleY > 1 then 
                data.scaleY = data.scaleY - 0.25
        elseif data.scaleY < 1 then 
                data.scaleY = data.scaleY + 0.25
        end

	if v.heldIndex ~= 0  or v.forcedState > 0 then return end
        if v.isProjectile then v.isProjectile = false end

        v.speedX = 1.5 * v.direction

        if not v.underwater then
                v.speedY = v.speedY - 0.075
        end

        if data.isExploding then
                data.explodeTimer = data.explodeTimer + 1
                data.explodeOpacity = data.explodeOpacity + 0.25
                if data.explodeOpacity > 1 then data.explodeOpacity = 0 end
                if cfg.squashAndStretch then
                        if data.scaleX <= 1 then data.scaleX = 1.75 end
                        if data.scaleY <= 1 then data.scaleY = 1.75 end
                end
                if data.explodeTimer >= cfg.explodeTime then
	                Explosion.spawn(v.x + 0.5 * v.width, v.y + 0.5 * v.height, 3)
	                v:kill(9)
                end
        end

        if v.collidesBlockBottom then
                v.speedY = data.height
	        SFX.play("ball_bounce.ogg")
                if data.height <= cfg.bounceLimit then
	                data.height = data.height + cfg.bounceModifier
                end
                if cfg.squashAndStretch then
                        data.scaleX = 2
                        data.scaleY = 0.25
                end
        end

	if v.collidesBlockLeft or v.collidesBlockRight then
	        SFX.play("ball_jump.ogg")
		v.speedY = -6
                v.noblockcollision = true 
                if cfg.squashAndStretch then
                        data.scaleX = 0.5
                        data.scaleY = 1.5
                end
	end

	for _,p in ipairs(Player.getIntersecting(v.x,v.y,v.x + v.width,v.y + v.height)) do
		if p.forcedState == FORCEDSTATE_NONE and p.deathTimer == 0 then
			local distance = vector((p.x + p.width*0.5) - (v.x + v.width*0.5),(p.y + p.height*0.5) - (v.y + v.height*0.5))
			SFX.play("ball_jump.ogg")
                        if cfg.isExplosive then data.isExploding = true end
                        if cfg.squashAndStretch then
                                data.scaleX = 1.5
                                data.scaleY = 1.5
                        end

                        if #Player.getIntersecting(v.x + 4, v.y - 4, v.x + v.width - 4, v.y + (v.height * 0.1)) ~= 0 and (p.keys.jump or p.keys.altJump) then
			        p.speedY = cfg.jumpHeight
                        else
			        p.speedX = (distance.x / v.width ) * 8
			        p.speedY = (distance.y / v.height) * 4
                        end
		end
	end
end

local lowPriorityStates = table.map{1,3,4}

function magicBall.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

	local data = v.data
        local config = NPC.config[v.id]

	local img = Graphics.sprites.npc[v.id].img
        local priority = (lowPriorityStates[v:mem(0x138,FIELD_WORD)] and -75) or (v:mem(0x12C,FIELD_WORD) > 0 and -30) or (config.foreground and -15) or -45
	
	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth * data.scaleX,
		height = config.gfxheight * data.scaleY,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
                sourceWidth = config.gfxwidth,
		sceneCoords = true,
		centered = true,
                rotation = data.rotation,
		priority = priority,
	}

        if config.isExplosive then
                local explodingImg = Graphics.loadImageResolved("npc-"..v.id.."-explode.png")
	        Graphics.drawBox{
		        texture = explodingImg,
		        x = v.x+(v.width/2)+config.gfxoffsetx,
		        y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		        width = config.gfxwidth * data.scaleX,
		        height = config.gfxheight * data.scaleY,
		        sourceY = v.animationFrame * config.gfxheight,
		        sourceHeight = config.gfxheight,
                        sourceWidth = config.gfxwidth,
		        sceneCoords = true,
		        centered = true,
                        rotation = data.rotation,
                        color = Color.red .. data.explodeOpacity,
		        priority = (priority + 2),
	        }
        end

        if config.displayOutsideThing then
                local outsideImg = Graphics.loadImageResolved("npc-"..v.id.."-outline.png")
	        Graphics.drawBox{
		        texture = outsideImg,
		        x = v.x+(v.width/2)+config.gfxoffsetx,
		        y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		        width = config.gfxwidth * data.scaleX,
		        height = config.gfxheight * data.scaleY,
		        sceneCoords = true,
		        centered = true,
		        priority = (priority + 1),
	        }
        end

	npcutils.hideNPC(v)
end

return magicBall