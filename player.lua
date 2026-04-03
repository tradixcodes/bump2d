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
player.bufferedInput = {}
player.animation = nil
player.flipX = 1

function playerUpdate(dt)
	-- runs only when player animation is not nil
	if player.animation then 
		player.animation:update(dt)
	end
	-- if player.isMoving == true
	if player.isMoving then
		player.moveTimer = math.min(player.moveTimer + dt, player.moveDuration)
		local t = player.moveTimer / player.moveDuration

		player.x = player.startX + (player.targetX - player.startX) * t
		player.y = player.startY + (player.targetY - player.startY) * t

		if t >= 1 then
			player.x, player.y = player.targetX, player.targetY
			player.isMoving = false

			-- 2. Update bump position ONLY when move is finished
			world:update(player, player.x, player.y)
			player.animation = animations.idle

			-- 3. Check buffer 
			if #player.bufferedInput > 0 then
				local nextDir = table.remove(player.bufferedInput, 1)
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

-- runs only when a key is pressed not held
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

	-- if dir not nil or direction was passed
	if dir then
		-- if player.isMoving == false
		if not player.isMoving then
			tryMove(dir)
		-- if player.isMoving == true
		else
			-- adds continous keypresses to a table
			table.insert(player.bufferedInput, dir)
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
		-- flip sprite
		player.flipX = -1
	elseif dir == "down" then
		dy = player.tileSize
	elseif dir == "up" then
		-- convert direction into grid movement
		dy = -player.tileSize
	end

	-- new player location
	local goalX = player.x + dx
	local goalY = player.y + dy

	-- 4. Use world:check to "look ahead" without moving yet
	local actualX, actualY, cols, len = world:check(player, goalX, goalY)

	local canMove = true
	if len > 0 then
		for i, col in ipairs(cols) do 
			-- If we hit a stone, try to push it
			-- col type == stone and stone.isMoving == false
			if col.other.type == "stone" and not col.other.isMoving then 
				if pushStone(col.other, dir) then 
					-- if pushstone returns true, allow movement
					canMove = true
				else
					-- if pushstone returns false, block movement
					canMove = false
				end
			-- col.other.type is definitely not a stone
			else
				canMove = false
			end
		end
	end

	-- if canMove == true
	if canMove then
		player.startX, player.startY = player.x, player.y
		player.targetX, player.targetY = goalX, goalY
		player.moveTimer = 0
		player.isMoving = true

		player.animation = animations.walk
		--start walking animation from frame 1
		player.animation:gotoFrame(1)
	-- if canMove == false
	else
		player.animation = animations.idle
	end
end
