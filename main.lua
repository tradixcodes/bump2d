function love.load()
	bump = require("library/bump/bump")
	sti = require("library/Simple-Tiled-Implementation/sti")
	cameraFile = require("library/hump/camera")

	cam = cameraFile()
	cam:zoom(2)

	world = bump.newWorld(32)

	require("player")

	platforms = {}

	loadMap("aw_level1")
end

function love.update(dt)
	playerUpdate(dt)

	local zoomLevel = 2
	local halfW = (love.graphics.getWidth() / 2) / zoomLevel
	local halfH = (love.graphics.getHeight() / 2) / zoomLevel

	local camX = math.max(halfW, math.min(player.x, mapWidth - halfW))
	local camY = math.max(halfH, math.min(player.y, mapHeight - halfH))

	cam:lookAt(camX, camY)
end

function love.draw()
	cam:attach()
	gameMap:drawLayer(gameMap.layers["background"])
	gameMap:drawLayer(gameMap.layers["walls"])
	gameMap:drawLayer(gameMap.layers["stones"])

	love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

	for i, platform in ipairs(platforms) do
		love.graphics.rectangle("line", platform.x, platform.y, platform.width, platform.height)
	end
	cam:detach()
	love.graphics.printf(
		"Player Hitbox: " .. math.floor(player.x) .. ", " .. math.floor(player.y),
		10,
		10,
		love.graphics.getWidth(),
		"left"
	)
	local fps = love.timer.getFPS()
	love.graphics.print("FPS: " .. fps, 10, 20)
end

-- (Keep your loadMap and spawnPlatform functions as they were)
function spawnPlatform(x, y, width, height)
	if width > 0 and height > 0 then
		local platform = {
			x = x,
			y = y,
			width = width,
			height = height,
		}

		world:add(platform, x, y, width, height)
		table.insert(platforms, platform)
	end
end

function loadMap(mapName)
	gameMap = sti("maps/" .. mapName .. ".lua")

	mapWidth = gameMap.width * gameMap.tilewidth
	mapHeight = gameMap.height * gameMap.tileheight

	for i, obj in pairs(gameMap.layers["start"].objects) do
		player.x = obj.x
		player.y = obj.y
		player.w = obj.width
		player.h = obj.height
	end

	world:add(player, player.x, player.y, player.w, player.h)

	for i, obj in pairs(gameMap.layers["Platforms"].objects) do
		spawnPlatform(obj.x, obj.y, obj.width, obj.height)
	end

	for i, obj in pairs(gameMap.layers["stones_object"].objects) do 
		spawnPlatform(obj.x, obj.y, obj.width, obj.height)
	end
end
