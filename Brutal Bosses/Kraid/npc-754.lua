local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local clawProjectile = {}
local npcID = NPC_ID

local clawProjectileSettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 32,
	height = 32,
	width = 32,
	frames = 1,
	framestyle = 1,
	luahandlesspeed = true, 
	ignorethrownnpcs = false,
	linkshieldable = false,
	noshieldfireeffect = true,
	jumphurt = 1,
        spinjumpsafe = 1,
	noblockcollision = 0,
	nofireball = 0,
        noyoshi = 1,
	noiceball = 0,
	npcblocktop = false, 
	playerblocktop = false, 
	nogravity = true,
        paletteImage = Graphics.loadImageResolved("kraidPalettes.png"),
        colourCount = 15,
	score = 0
}

npcManager.setNpcSettings(clawProjectileSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]            = 10,
		[HARM_TYPE_FROMBELOW]       = 10,
		[HARM_TYPE_NPC]             = 10,
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_HELD]            = 10,
		[HARM_TYPE_TAIL]            = 10,
		[HARM_TYPE_SPINJUMP]        = 10,
	}
)

function clawProjectile.onInitAPI()
	npcManager.registerEvent(npcID, clawProjectile, "onTickEndNPC")
	npcManager.registerEvent(npcID, clawProjectile, "onDrawNPC")
end

function clawProjectile.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.verticalDir = RNG.irandomEntry({0, 1})
                data.finalPalette = v.ai1
                data.rotation = 0
                data.timer = 0
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
    
        data.timer = data.timer + 1

	if data.timer % 6 == 0 then
		data.rotation = data.rotation + (45 * v.direction)
	end

	v.speedX = 2 * v.direction
	v.speedY = (data.verticalDir == 0 and -2) or 2
	if v.collidesBlockUp and data.verticalDir == 0 then data.verticalDir = 1 end
	if v.collidesBlockBottom and data.verticalDir == 1 then data.verticalDir = 0 end

        data.palette = data.finalPalette
end

function clawProjectile.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
        if not v.data.initialized then return end

        local config = NPC.config[v.id]

        local paletteChangeShader

        if paletteChangeShader == nil then
            paletteChangeShader = Shader()
            paletteChangeShader:compileFromFile(nil,"kraidPaletteChange.frag",{COLOUR_COUNT = config.colourCount})
        end

	local img = Graphics.sprites.npc[v.id].img
	
	Graphics.drawBox{
		texture = img,
		x = v.x+(v.width/2)+config.gfxoffsetx,
		y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
		width = config.gfxwidth,
		height = config.gfxheight,
		sourceY = v.animationFrame * config.gfxheight,
		sourceHeight = config.gfxheight,
                sourceWidth = config.gfxwidth,
                rotation = v.data.rotation,
		sceneCoords = true,
		centered = true,
		priority = -76,
                shader = paletteChangeShader,
                uniforms = {
                    paletteImage = config.paletteImage,
                    colourSimilarityThreshold = 0.001,
                    currentPaletteY = v.data.palette,
                }
	}

	npcutils.hideNPC(v)
end

return clawProjectile