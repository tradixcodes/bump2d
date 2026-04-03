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
player.animation = nil
player.flipX = 1

function playerUpdate(dt)
	if player.animation then 
		player.animation:update(dt)
	end
	if player.isMoving then
		player.moveTimer = math.min(player.moveTimer + dt, player.moveDuration)
		local t = player.moveTimer / player.moveDuration

		-- Manually pick the frame based on progress (t)
    	-- If t is 0.5, it will show the middle frame
    	-- local frameIndex = math.floor(t * (#player.animation.frames - 1)) + 1
    	-- player.animation:gotoFrame(frameIndex)

		-- 1. Fixed interpolation logic
		player.x = player.startX + (player.targetX - player.startX) * t
		player.y = player.startY + (player.targetY - player.startY) * t

		if t >= 1 then
			player.x, player.y = player.targetX, player.targetY
			player.isMoving = false

			-- 2. Update bump position ONLY when move is finished
			world:update(player, player.x, player.y)
			player.animation = animations.idle

			-- 3. Check buffer
			if player.bufferedInput then
				local nextDir = player.bufferedInput
				player.bufferedInput = nil
				tryMove(nextDir)
			end
		end
	end
end

function playerDraw() 
	if player.animation then 
		player.animation:draw(sprites.playerSprite, player.x + 16, player.y + 16, 0, player.flipX, 1, 16, 16)
	end

	-- player hitbox
	-- love.graphics.rectangle("line", player.x, player.y, player.w, player.h)
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
		player.flipX = 1
	elseif dir == "left" then
		dx = -player.tileSize
		player.flipX = -1
	elseif dir == "down" then
		dy = player.tileSize
	elseif dir == "up" then
		dy = -player.tileSize
	end

	local goalX = player.x + dx
	local goalY = player.y + dy

	-- 4. Use world:check to "look ahead" without moving yet
	local actualX, actualY, cols, len = world:check(player, goalX, goalY)

	local canMove = true
	if len > 0 then
		for i, col in ipairs(cols) do 
			-- If we hit a stone, try to push it
			if col.other.type == "stone" and not col.other.isMoving then 
				if pushStone(col.other, dir) then 
					canMove = true
				else
					canMove = false
				end
			else
				canMove = false
			end
		end
	end

	if canMove then
		player.startX, player.startY = player.x, player.y
		player.targetX, player.targetY = goalX, goalY
		player.moveTimer = 0
		player.isMoving = true

		player.animation = animations.walk
		player.animation:gotoFrame(1)
	else
		player.bufferedInput = nil -- Clear buffer if we hit a wall
		player.animation = animations.idle
	end
end
