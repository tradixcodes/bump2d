function love.load()
	bump = require("library/bump/bump")

	sti = require("library/Simple-Tiled-Implementation/sti")

	world = bump.newWorld(32)

	player = {
		x = 100,
		y = 100,
		w = 32,
		h = 32,
		speed = 200,
	}

	platforms = {}

	loadMap("aw_level1")
end

function love.update(dt)
	local dx, dy = 0, 0

	if love.keyboard.isDown("d") then
		dx = player.speed * dt
	elseif love.keyboard.isDown("a") then
		dx = -player.speed * dt
	end

	if love.keyboard.isDown("s") then
		dy = player.speed * dt
	elseif love.keyboard.isDown("w") then
		dy = -player.speed * dt
	end

	local goalX = player.x + dx
	local goalY = player.y + dy

	local actualX, actualY, cols, len = world:move(player, goalX, goalY)

	player.x = actualX
	player.y = actualY
end

function love.draw()
	gameMap:drawLayer(gameMap.layers["background"])
	gameMap:drawLayer(gameMap.layers["walls"])

	love.graphics.rectangle("fill", player.x, player.y, player.w, player.h)

	for i, platform in ipairs(platforms) do
		love.graphics.rectangle("line", platform.x, platform.y, platform.width, platform.height)
	end
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
end
