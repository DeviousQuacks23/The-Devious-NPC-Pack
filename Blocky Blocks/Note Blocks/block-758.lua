local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

-- Sprites by KoopshiKingGeoshi, SFX by MegaDood

local noteBlock = {}
local blockID = BLOCK_ID

local noteBlockSettings = {
	id = blockID,

	frames = 4,
	framespeed = 8,
	bumpable = true,

	sfxVolume = 0.5,
	noteEffect = 765,
}

blockManager.setBlockSettings(noteBlockSettings)

local AI = require("noteBlocks")
AI.register(blockID)

function noteBlock.onInitAPI()
	registerEvent(noteBlock, "onBlockHit")
end

-- List of music sounds
local musicNotes = {
	"musicNotes/C2.ogg",
	"musicNotes/C#.ogg",
	"musicNotes/D.ogg",
	"musicNotes/D#.ogg",
	"musicNotes/E.ogg",
	"musicNotes/F.ogg",
	"musicNotes/F#.ogg",
	"musicNotes/G.ogg",
	"musicNotes/G#.ogg",
	"musicNotes/A.ogg",
	"musicNotes/A#.ogg",
	"musicNotes/B.ogg",
	"musicNotes/C.ogg"
}

function noteBlock.onBlockHit(event, v, fromUpper, p)
    	if v.id ~= blockID then return end

	local blockCfg = Block.config[v.id]

	-- Spawn effects
	local speedTable = {-3, 3}
	for j = 1, 2 do
                local e = Effect.spawn(blockCfg.noteEffect, v.x + v.width * 0.5, v.y + v.height * 0.5)
                e.x = e.x - e.width * 0.5
                e.y = e.y - e.height * 0.5
		e.speedX = speedTable[j]
	end  

	-- SFX stuff
	local blockSectionBottom = Section(blockutils.getClosestPlayerSection(v)).boundary.bottom
	local sfxToPlay = musicNotes[1 + math.floor((blockSectionBottom - v.y - 1) / v.height) % #musicNotes]

	if blockutils.isOnScreen(v) then
		SFX.play(sfxToPlay)
	end
end

return noteBlock