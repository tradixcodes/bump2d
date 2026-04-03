function pushStone(s, dir)
    local dx, dy = 0, 0
    if dir == "right" then dx = 32 
    elseif dir == "left" then dx = -32
    elseif dir == "down" then dy = 32
    elseif dir == "up" then dy = -32
    end
    -- We only push stones horizontally in most grid games
    
    local goalX = s.x + dx
    local goalY = s.y + dy 
    
    local actualX, actualY, cols, len = world:check(s, goalX, goalY)
    
    if len == 0 then
        if dx ~= 0 then 
            s.startX, s.startY = s.x, s.y
            s.targetX, s.targetY = goalX, goalY
            s.moveTimer = 0
            s.isMoving = true
        end
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
    if s.isMoving then return end
    
    local downY = s.y + 32
    local _, _, cols, len = world:check(s, s.x, downY)
    
    -- CASE 1: Total Air. If nothing is below, just fall straight down.
    if len == 0 then
        startStoneMove(s, s.x, downY)
        return
    end

    -- CASE 2: Check if we are resting on another stone
    local isOnStone = false
    for _, col in ipairs(cols) do
        if col.other.type == "stone" then 
            isOnStone = true 
            break 
        end
    end

    -- If we are on a stone, check if we should slide off the sides
    if isOnStone then
        -- We try to slide Right first, then Left
        local directions = {32, -32} 
        
        for _, dx in ipairs(directions) do
            local sideX = s.x + dx
            -- Is the side clear AND the diagonal (side + down) clear?
            local _, _, _, sideLen = world:check(s, sideX, s.y)
            local _, _, _, diagLen = world:check(s, sideX, downY)
            
            if sideLen == 0 and diagLen == 0 then
                startStoneMove(s, sideX, downY)
                return -- Slide triggered, exit function
            end
        end
    end
    -- If it's on a platform (not a stone) or the sides are blocked, it stays still.
end

-- Helper to keep code DRY
function startStoneMove(s, tx, ty)
    s.startX, s.startY = s.x, s.y
    s.targetX, s.targetY = tx, ty
    s.moveTimer = 0
    s.isMoving = true

    world:update(s, tx, ty)
end

function drawStones()
    for _, s in ipairs(stones) do
        -- Draw the stone animation at its current x, y
        s.anim:draw(sprites.stoneSprite, s.x, s.y)
    end
    -- stone hitbox
    for i, s in ipairs(stones) do
	    love.graphics.rectangle("line", s.x, s.y, s.w, s.h)
    end
end