function pushStone(s, dir)
    -- if s.isMoving == true
    if s.isMoving then return false end
    
    local dx = 0
    if dir == "right" then 
        dx = 32 
    elseif dir == "left" then 
        dx = -32 
    end

    -- when dir == up or dir == down, the stone can't be pushed up
    if dx == 0 then return false end 

    local goalX, goalY = s.x + dx, s.y
    
    local _, _, _, len = world:check(s, goalX, goalY)
    
    -- if there is no collision in the goalX and Y coordinate, move the stone there
    if len == 0 then
        startStoneMove(s, goalX, goalY)
        -- return that the push was successful so that the player can move too
        return true
    end
    -- there is an object/collider therefore movement of the stone is not successful
    return false
end

function checkStoneFall(s)
    if s.isMoving or s.state == "teetering" then return end
    
    local downY = s.y + 32
    local _, _, cols, len = world:check(s, s.x, downY)
    
    -- If air is below, just fall (Natural gravity)
    if len == 0 then
        s.moveDuration = 0.2
        startStoneMove(s, s.x, downY)
        return
    end

    -- Slide Logic
    local restingOnStone = false
    for _, col in ipairs(cols) do
        if col.other.type == "stone" then
            restingOnStone = true
            break
        end
    end

    if restingOnStone then
        local sides = {32, -32}
        for _, dx in ipairs(sides) do
            local sideX = s.x + dx
            local _, _, _, sideLen = world:check(s, sideX, s.y)
            
            if sideLen == 0 then
                -- INSTEAD OF MOVING: Start Teetering
                s.state = "teetering"
                s.teeterTimer = s.teeterDuration
                s.targetSlideX = sideX -- Save where we want to go
                return 
            end
        end
    end
end

function startStoneMove(s, tx, ty)
    s.startX, s.startY = s.x, s.y
    s.targetX, s.targetY = tx, ty
    s.moveTimer = 0
    s.isMoving = true

    -- IMPORTANT: Move the hitbox to the target IMMEDIATELY 
    -- This prevents other objects from entering the same tile
    world:update(s, tx, ty)
end

function updateStones(dt)
    for _, s in ipairs(stones) do
        -- 1. TEETERING STATE (The "Jitter" before falling)
        if s.state == "teetering" then
            s.teeterTimer = s.teeterTimer - dt
            
            -- Rapidly offset the drawing position for a shaking effect
            s.shakeX = math.random(-1, 1)
            
            if s.teeterTimer <= 0 then
                s.state = "idle" -- Reset state
                s.shakeX = 0
                s.moveDuration = 0.4 -- Make the slide feel heavy/slow
                startStoneMove(s, s.targetSlideX, s.y)
            end

        -- 2. MOVING STATE (Sliding or Falling)
        elseif s.isMoving then
            s.anim:resume()
            s.anim:update(dt)

            s.moveTimer = math.min(s.moveTimer + dt, s.moveDuration)
            local t = s.moveTimer / s.moveDuration
            
            -- Calculate actual grid position
            local nextX = s.startX + (s.targetX - s.startX) * t
            local nextY = s.startY + (s.targetY - s.startY) * t

            -- ARC MOTION (The "Circular" feel)
            -- If it's a horizontal move (startY == targetY), add a small hop
            if s.startY == s.targetY then
                local hopHeight = 1 -- Pixels to lift
                -- Sine wave creates a smooth arc that starts and ends at 0
                s.visualY = nextY - math.sin(t * math.pi) * hopHeight
            else
                -- If falling vertically, no arc is needed
                s.visualY = nextY
            end

            s.x = nextX
            s.y = nextY

            -- Move completion
            if t >= 1 then
                s.x, s.y = s.targetX, s.targetY
                s.visualY = s.y -- Reset visual offset
                s.isMoving = false
                s.anim:pause()
                world:update(s, s.x, s.y)
                
                -- Check immediately if we need to fall/teeter again
                checkStoneFall(s)
            end
            
        -- 3. IDLE STATE
        else
            checkStoneFall(s)
        end
    end
end


function drawStones()
    for _, s in ipairs(stones) do
        local drawX = s.x + (s.shakeX or 0)
        local drawY = s.visualY or s.y
        s.anim:draw(sprites.stoneSprite, drawX, drawY)
    end

    for _, s in ipairs(stones) do
        love.graphics.rectangle("line", s.x, s.y, s.w, s.h)
    end
end