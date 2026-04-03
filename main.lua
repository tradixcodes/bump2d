function love.load()
	-- collision system (AABB collision detection)
	bump = require("library/bump/bump")
	-- load maps from tiled
	sti = require("library/Simple-Tiled-Implementation/sti")
	-- lets you move/zoom the view
	cameraFile = require("library/hump/camera")
	-- handles sprites animations
	anim8 = require("library/anim8/anim8")

	--creates a camera object
	cam = cameraFile()
	-- zooms x2
	cam:zoom(2)

	-- sprites table and loading sprites
	sprites = {}
	sprites.playerSprite = love.graphics.newImage("sprites/walking_animation.png")
	sprites.grassSprite = love.graphics.newImage("sprites/grass_animation_tileset.png")
	sprites.stoneSprite = love.graphics.newImage("sprites/aw_stones_tileset.png")

	-- slicing sprite sheets into small boxes
	local playerGrid = anim8.newGrid(32, 33, sprites.playerSprite:getWidth(), sprites.playerSprite:getHeight())
	local grassGrid = anim8.newGrid(44, 35, sprites.grassSprite:getWidth(), sprites.grassSprite:getHeight())
	local stoneGrid = anim8.newGrid(32, 32, sprites.stoneSprite:getWidth(), sprites.stoneSprite:getHeight())

	-- animation definition from grids
	animations = {}
	animations.idle = anim8.newAnimation(playerGrid("1-3", 2), 1)
	animations.walk = anim8.newAnimation(playerGrid("1-3", 1), 0.05)
	animations.grassFall = anim8.newAnimation(grassGrid("1-8", 1), 0.15)
	animations.stoneRoll = anim8.newAnimation(stoneGrid('1-3', 1, '1-3', 2, '1-2', 3), 0.1)

	-- new world wih cell size 32
	world = bump.newWorld(32)

	-- load player logic
	require("player")
	player.animation = animations.idle

	-- map collisions
	platforms = {}

	-- moving objects (stones)
	stones = {}
	-- load stone behaviour
	require("stone")

	loadMap("aw_level1")
end

function love.update(dt)
	playerUpdate(dt)
	updateStones(dt)

	-- camera logic
	local zoomLevel = 2
	local halfW = (love.graphics.getWidth() / 2) / zoomLevel
	local halfH = (love.graphics.getHeight() / 2) / zoomLevel

	local camX = math.max(halfW, math.min(player.x, mapWidth - halfW))
	local camY = math.max(halfH, math.min(player.y, mapHeight - halfH))

	cam:lookAt(camX, camY)
end

function love.draw()
	-- objects don't move with the camera view
	cam:attach()
	-- draw background
	gameMap:drawLayer(gameMap.layers["background"])
	-- draw walls
	gameMap:drawLayer(gameMap.layers["walls"])
	-- draw stones
	drawStones()
	-- draw player
	playerDraw()

	-- draws collision boxes for the map colliders
	-- bump.lua lacks a world:draw() unlike windfield
	for i, platform in ipairs(platforms) do
		love.graphics.rectangle("line", platform.x, platform.y, platform.width, platform.height)
	end
	
	cam:detach()

	-- objects that move with the camera view
	love.graphics.printf(
		"Player Hitbox: " .. math.floor(player.x) .. ", " .. math.floor(player.y),
		10,
		10,
		love.graphics.getWidth(),
		"left"
	)
	local fps = love.timer.getFPS()
	love.graphics.print("FPS: " .. fps, 10, 25)
end

-- used to make platform object from tiled map
function spawnPlatform(x, y, width, height)
	if width > 0 and height > 0 then
		local platform = {
			x = x,
			y = y,
			width = width,
			height = height,
		}
		-- registers an object into the collision world so that Bump can track and detect collision for it
		world:add(platform, x, y, width, height)
		table.insert(platforms, platform)
	end
end

-- loads maps assets
function loadMap(mapName)
	gameMap = sti("maps/" .. mapName .. ".lua")

	mapWidth = gameMap.width * gameMap.tilewidth
	mapHeight = gameMap.height * gameMap.tileheight

	-- initiates player dimensions and position  
	for i, obj in pairs(gameMap.layers["start"].objects) do
		player.x = obj.x
		player.y = obj.y
		player.w = obj.width
		player.h = obj.height
	end

	-- registers the player object for collision detection
	world:add(player, player.x, player.y, player.w, player.h)

	for i, obj in pairs(gameMap.layers["Platforms"].objects) do
		spawnPlatform(obj.x, obj.y, obj.width, obj.height)
	end

	for i, obj in pairs(gameMap.layers["stones_object"].objects) do 
		local stone = {
			x = obj.x, y = obj.y,
			w = obj.width, h = obj.height,
			isMoving = false,
			moveTimer = 0,
			moveDuration = 0.25,
			startX = obj.x, startY = obj.y,
			targetX = obj.x, targetY = obj.y,
			-- each stone get its own animation instance
			--:clone() prevents all the stones from sharing one animation
			anim = animations.stoneRoll:clone(),
			type = "stone",
			state = "idle", -- "idle", "teetering", "sliding", "falling"
			teeterTimer = 0,
			teeterDuration = 0.4,
			targetSlideX = 0
		}
		-- stops animation from playing (can be triggered when the stone is moving)
		stone.anim:pause()
		table.insert(stones, stone)
		-- adds stone as an objects for collision detection
		world:add(stone, stone.x, stone.y, stone.w, stone.h)
	end

end
