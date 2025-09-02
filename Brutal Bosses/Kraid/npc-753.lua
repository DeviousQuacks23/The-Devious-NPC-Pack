local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local spikeProjectile = {}
local npcID = NPC_ID

local spikeProjectileSettings = {
	id = npcID,
	gfxheight = 48,
	gfxwidth = 96,
	height = 48,
	width = 96,
	frames = 1,
	framestyle = 1,
	luahandlesspeed = true, 
	ignorethrownnpcs = true,
	linkshieldable = false,
	noshieldfireeffect = true,
	jumphurt = 0,
	noblockcollision = 1,
	nofireball = true,
        noyoshi = 1,
	noiceball = 1,
	npcblocktop = true, 
	playerblocktop = true, 
	nogravity = true,
        paletteImage = Graphics.loadImageResolved("kraidPalettes.png"),
        colourCount = 15,
	score = 0
}

npcManager.setNpcSettings(spikeProjectileSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_OFFSCREEN,
	},
	{
	}
);

function spikeProjectile.onInitAPI()
	npcManager.registerEvent(npcID, spikeProjectile, "onTickEndNPC")
	npcManager.registerEvent(npcID, spikeProjectile, "onDrawNPC")
end

function spikeProjectile.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
                data.finalPalette = v.ai1
                data.state = 0
                data.timer = 0
	end

	if v.heldIndex ~= 0 
	or v.isProjectile   
	or v.forcedState > 0
	then
		return
	end
    
        data.timer = data.timer + 1
	
        if data.state == 0 then
                if lunatime.tick() % 2 == 0 then 
                        data.palette = 8
                else
                        data.palette = data.finalPalette
                end
                if data.timer <= 30 then
                        v.speedX = 2 * v.direction
                else
                        v.speedX = 0
                end
                if data.timer >= 60 then
                        data.state = 1
                        SFX.play("bellySpike.wav")
                end
        else
                data.palette = data.finalPalette
                v.speedX = 4 * v.direction
        end
end

function spikeProjectile.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end

        local config = NPC.config[npcID]

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
		sceneCoords = true,
		centered = true,
		priority = -77,
                shader = paletteChangeShader,
                uniforms = {
                    paletteImage = config.paletteImage,
                    colourSimilarityThreshold = 0.001,
                    currentPaletteY = v.data.palette,
                }
	}

	npcutils.hideNPC(v)
end

return spikeProjectile