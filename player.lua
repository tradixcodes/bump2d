player = {}
player.x, player.y = 0, 0
player.w = 32
player.h = 32
player.tileSize = 32
player.moveDuration = 0.15
player.moveTimer = 0
player.startX, player.startY = 0, 0
player.targetX, player.targetY = 0, 0
player.isMoving = false
player.bufferedInput = nil

function playerUpdate(dt)
	if player.isMoving then
		player.moveTimer = math.min(player.moveTimer + dt, player.moveDuration)
		local t = player.moveTimer / player.moveDuration

		-- 1. Fixed interpolation logic
		player.x = player.startX + (player.targetX - player.startX) * t
		player.y = player.startY + (player.targetY - player.startY) * t

		if t >= 1 then
			player.x, player.y = player.targetX, player.targetY
			player.isMoving = false

			-- 2. Update bump position ONLY when move is finished
			world:update(player, player.x, player.y)

			-- 3. Check buffer
			if player.bufferedInput then
				local nextDir = player.bufferedInput
				player.bufferedInput = nil
				tryMove(nextDir)
			end
		end
	end
end

-- NEW: Use keypressed instead of polling in update to prevent double-moves
function love.keypressed(key)
	local dir = nil
	if key == "d" or key == "right" then
		dir = "right"
	elseif key == "a" or key == "left" then
		dir = "left"
	elseif key == "s" or key == "down" then
		dir = "down"
	elseif key == "w" or key == "up" then
		dir = "up"
	end

	if dir then
		if not player.isMoving then
			tryMove(dir)
		else
			player.bufferedInput = dir
		end
	end
end

function tryMove(dir)
	local dx, dy = 0, 0
	if dir == "right" then
		dx = player.tileSize
	elseif dir == "left" then
		dx = -player.tileSize
	elseif dir == "down" then
		dy = player.tileSize
	elseif dir == "up" then
		dy = -player.tileSize
	end

	local goalX = player.x + dx
	local goalY = player.y + dy

	-- 4. Use world:check to "look ahead" without moving yet
	local actualX, actualY, cols, len = world:check(player, goalX, goalY)

	if len == 0 then -- Only move if no collision
		player.startX, player.startY = player.x, player.y
		player.targetX, player.targetY = goalX, goalY
		player.moveTimer = 0
		player.isMoving = true
	else
		player.bufferedInput = nil -- Clear buffer if we hit a wall
	end
end
