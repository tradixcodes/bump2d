function love.load()
	bump = require("library/bump/bump")

	world = bump.newWorld(32)

	player = {
		x = 100,
		y = 100,
		w = 32,
		h = 32,
		speed = 200,
	}

	world:add(player, player.x, player.y, player.w, player.h)

	wall = {
		x = 300,
		y = 100,
		w = 64,
		h = 64,
	}

	world:add(wall, wall.x, wall.y, wall.w, wall.h)
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
	-- player
	love.graphics.rectangle("line", player.x, player.y, player.w, player.h)

	-- wall
	love.graphics.rectangle("line", wall.x, wall.y, wall.w, wall.h)
end
