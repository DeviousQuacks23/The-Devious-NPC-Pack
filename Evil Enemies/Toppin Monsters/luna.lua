-- Widescreen is recommended for the jumpscares, so this code enables widescreen mode.
-- Don't worry, everything still works without widescreen, there's anti-widescreen versions of the jumpscare images in the toppingJumpscare folder.

local CAMERA_WIDTH = 960
local CAMERA_HEIGHT = 540

function onStart()
    camera.width = CAMERA_WIDTH
    camera.height = CAMERA_HEIGHT
    Graphics.setMainFramebufferSize(CAMERA_WIDTH, CAMERA_HEIGHT)
end

function onCameraUpdate()
    camera.width, camera.height = Graphics.getMainFramebufferSize()
end