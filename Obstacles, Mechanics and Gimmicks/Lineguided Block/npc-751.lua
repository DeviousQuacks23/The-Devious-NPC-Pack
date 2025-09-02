local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local blockutils = require("blocks/blockutils")
local lineguide = require("lineguide")

-- Code based on MDA's Block Wings

local lgBlock = {}
local npcID = NPC_ID

local lgBlockSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 1,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false, 

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = true,
	harmlessthrown = true,

	ignorethrownnpcs = true,
	notcointransformable = true,
	staticdirection = true,

	searchCentreOffsetX = 0,
	searchCentreOffsetY = 0,
}

npcManager.setNpcSettings(lgBlockSettings)
npcManager.registerDefines(npcID, {NPC.UNHITTABLE})
npcManager.registerHarmTypes(npcID, {}, {})

function lgBlock.onInitAPI()
	npcManager.registerEvent(npcID, lgBlock, "onTickNPC")
	npcManager.registerEvent(npcID, lgBlock, "onDrawNPC")
	registerEvent(lgBlock, "onDrawEnd")
	lineguide.registerNpcs(npcID)
end

-- Block attachment code

local function isValidBlock(v, b)
	return (b ~= nil and b.isValid and b.layerName == v.layerName and not b.isHidden)
end

local function isBetterPick(closestBlock, b)
	if closestBlock.contentID == 0 and b.contentID > 0 then
		return true
	end

	local configClosest = Block.config[closestBlock.id]
	local config = Block.config[b.id]

	if not configClosest.bumpable and config.bumpable then
		return true
	end

	return false
end

local function findBlock(v, data, config)
	if data.block ~= nil then
		if data.block.isValid then
			data.block.isHidden = false
		end

		return
	end

	local closestDistance = math.huge
	local closestBlock

	local centreX = v.x + v.width * 0.5 + config.searchCentreOffsetX
	local centreY = v.y + v.height + config.searchCentreOffsetY

	for _,b in Block.iterateIntersecting(centreX - 4, centreY - 4, centreX + 4, centreY + 4) do
		if isValidBlock(v, b) and b.data._theLineguidedNPC == nil then
			local difference = vector((b.x + b.width * 0.5) - centreX, (b.y + b.height * 0.5) - centreY)
			local distance = difference.length

			if distance < closestDistance or isBetterPick(closestBlock, b) then
				closestDistance = distance
				closestBlock = b
			end
		end
	end

	if closestBlock ~= nil then
		data.block = closestBlock
		data.blockWidth = closestBlock.width
		data.blockHeight = closestBlock.height

		v.width = data.blockWidth
		v.height = data.blockHeight

		closestBlock.data._theLineguidedNPC = v
	else
		data.block = nil
		data.blockWidth = 32
		data.blockHeight = 32

		v:kill(9)
	end
end

function lgBlock.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		if data.initialized then
			if isValidBlock(v, data.block) then
				data.block.isHidden = true
			end

			data.initialized = false
		end

		return
	end

	local config = NPC.config[v.id]

	if not data.initialized then
		findBlock(v, data, config)
		data.initialized = true
	end

	if not isValidBlock(v, data.block) then v:kill(9) return end

	-- Move block accordingly

	local newBlockX = v.x + v.width * 0.5 - data.blockWidth * 0.5
	local newBlockY = v.y + v.height * 0.5 - data.blockHeight * 0.5

	data.block.extraSpeedX = (newBlockX - data.block.x)
	data.block.extraSpeedY = (newBlockY - data.block.y)
	data.blockWidth = data.block.width
	data.blockHeight = data.block.height

	data.block:translate(data.block.extraSpeedX, data.block.extraSpeedY)

    	-- Some other behaviours

    	npcutils.applyLayerMovement(v)
    	local lineguideData = v.data._basegame.lineguide

    	if lineguideData ~= nil then
        	if lineguideData.state == lineguide.states.FALLING then
            		if v.underwater then
                		v.speedY = math.min(1.6, v.speedY + Defines.npc_grav * 0.2)
            		else
                		v.speedY = math.min(8, v.speedY + Defines.npc_grav)
            		end
        	end

        	if not data.lineSpeedInitialized then
            		data.lineSpeedInitialized = true
            		lineguideData.lineSpeed = v.ai2
        	end
    	end
end

-- All of this so that the block will render infront of the lineguides

local hiddenBlocks = {}

function lgBlock.onDrawNPC(v)
	if v.despawnTimer <= 0 or v.isHidden then return end
	if not v.data.initialized then return end

	local config = NPC.config[v.id]
	local data = v.data

	if isValidBlock(v, data.block) and not data.block.isHidden and not data.block:mem(0x5A,FIELD_BOOL) then
		local blockImage = Graphics.sprites.block[data.block.id].img
		local blockConfig = Block.config[data.block.id]
		local blockFrame = blockutils.getBlockFrame(data.block.id)
		local blockYOffset = data.block:mem(0x56,FIELD_WORD)

		Graphics.drawImageToSceneWP(blockImage, data.block.x, data.block.y + blockYOffset, 0, blockFrame * blockConfig.height, data.block.width, data.block.height, -62)

		table.insert(hiddenBlocks, data.block)
		data.block.isHidden = true
	end
end

function lgBlock.onDrawEnd()
	local i = 1

	while (true) do
		local b = hiddenBlocks[i]
		if b == nil then
			break
		end

		if b.isValid then
			b.isHidden = false
		end

		hiddenBlocks[i] = nil
		i = i + 1
	end
end

return lgBlock