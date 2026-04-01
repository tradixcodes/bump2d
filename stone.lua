function pushStone(s, dir)
    local dx, dy = 0, 0
    if dir == "right" then dx = 32 elseif dir == "left" then dx = -32 end
    -- We only push stones horizontally in most grid games
    
    local goalX = s.x + dx
    local goalY = s.y -- Keep Y the same for the initial push
    
    local _, _, cols, len = world:check(s, goalX, goalY)
    
    if len == 0 then
        s.startX, s.startY = s.x, s.y
        s.targetX, s.targetY = goalX, goalY
        s.moveTimer = 0
        s.isMoving = true
        return true
    end
    return false
end

function updateStones(dt)
    for _, s in ipairs(stones) do
        if s.isMoving then
            s.anim:resume()
            s.anim:update(dt)

            s.moveTimer = math.min(s.moveTimer + dt, s.moveDuration)
            local t = s.moveTimer / s.moveDuration
            s.x = s.startX + (s.targetX - s.startX) * t
            s.y = s.startY + (s.targetY - s.startY) * t

            if t >= 1 then
                s.x, s.y = s.targetX, s.targetY
                s.isMoving = false
                s.anim:pause()
                world:update(s, s.x, s.y)
                
                -- Check if it needs to fall after finishing a move
                checkStoneFall(s)
            end
        else
            -- If it's not moving, check if it SHOULD be falling (e.g. tile broke)
            checkStoneFall(s)
        end
    end
end

function checkStoneFall(s)
    if s.isMoving then return end -- Don't start a new move if already moving
    
    local goalY = s.y + 32
    -- Peek below
    local actualX, actualY, cols, len = world:check(s, s.x, goalY)
    
    if len == 0 then
        s.startX, s.startY = s.x, s.y
        s.targetX, s.targetY = s.x, goalY
        s.moveTimer = 0
        s.isMoving = true
    end
end

function drawStones()
    for _, s in ipairs(stones) do
        -- Draw the stone animation at its current x, y
        s.anim:draw(sprites.stoneSprite, s.x, s.y)
    end
end