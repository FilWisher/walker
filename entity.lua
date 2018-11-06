local Entity = {}

Entity.__index = Entity

Entity.__sub = function(lhs, rhs)
    local dx = math.abs(lhs.x - rhs.x)
    local dy = math.abs(lhs.y - rhs.y)
    return math.sqrt(dx^2, dy^2)
end

function Entity.new(r, x, y, color, speed)
    local o = {}
    o.r = r
    o.x = x
    o.y = y
    o.color = color
    o.dx = 0
    o.dy = 0
    o.speed = speed
    return setmetatable(o, Entity)
end

local Survivor = {}
setmetatable(Survivor, Entity)
Survivor.__sub = Entity.__sub
Survivor.__index = Survivor

function Survivor.new(x, y)
    local surv = Entity.new(5, x, y, {0, 0, 1}, 40, s)
    if math.random() < 0.4 then
        surv.gun = true
    end
    surv.health = 50 + (math.random() * 50)
    surv.maxhealth = surv.health
    return setmetatable(surv, Survivor)
end

local Zombie = {}
setmetatable(Zombie, Entity)
Zombie.__sub = Entity.__sub
Zombie.__index = Zombie

function Zombie.new(x, y)
    local zomb =  Entity.new(5, x, y, {0, 1, 0}, 10, z)
    zomb.health = 50 + (math.random() * 50)
    zomb.maxhealth = zomb.health
    return setmetatable(zomb, Zombie)
end

function Entity:draw()
    local alpha = 1
    if self.health then
        alpha = self.health/self.maxhealth
    end
    self.color[4] = alpha
    love.graphics.setColor(self.color)
    love.graphics.circle('fill', self.x, self.y, self.r)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle('line', self.x, self.y, self.r)
end

function Zombie:find_target(survivors, zombies)
    local distance = math.huge
    local target 

    for _, ent in ipairs(survivors) do
        if ent ~= self then
            if (self - ent) < distance then
                distance = (self - ent)
                target = ent
            end
        end
    end
    if not zombies then return target end

    for _, ent in ipairs(zombies) do
        if ent.target ~= self then
            if (self - ent) < distance then
                distance = (self - ent)
                target = ent
            end
        end
    end
    return target
end

function update_survivor_run(platform, self, dt, zombies)
    local thresh = 100
    local target = {x=0, y=0}
    for _, zomb in ipairs(zombies) do
        if self - zomb < thresh then
            target.x = target.x - (self.x - zomb.x)
            target.y = target.y - (self.y - zomb.y)
        end
    end

    local variance = 1
    local dx
    if target.x < self.x then
        dx = self.speed + variance
    elseif target.x > self.x then
        dx = -(self.speed + variance)
    end

    if target.y < self.y then
        dy = self.speed + variance
    elseif target.y > self.y then
        dy = -(self.speed + variance)
    end

    self.x = self.x + dx * dt
    self.y = self.y + dy * dt

    self.x = math.max(0, math.min(self.x, platform.width))
    self.y = math.max(0, math.min(self.y, platform.height))
end

function Survivor:find_target(zombies)
    local dist = math.huge
    local target
    for _, ent in ipairs(zombies) do
        if math.abs(self - ent) < dist then
            dist = math.abs(self - ent)
            target = ent
        end
    end
    return target
end

function update_survivor_gun(platform, self, dt, zombies, survivors)
    
    if not self.target then
        self.target = self:find_target(zombies)
    end
    -- Occasionally switch targets
    if self.target and math.random() < 0.1 then
        self.target = self:find_target(zombies)
    end
    -- If no target, don't worry!
    if not self.target then
        return
    end
    local target = self.target

    local danger_thresh = 20
    local gun_thresh = 30
    local dist = math.abs(self - target)

    if dist < danger_thresh then
        update_survivor_run(platform, self, dt, zombies)
        return
    end

    local variance = 1
    if dist > gun_thresh then
        if target.x < self.x then
            dx = -(self.speed + variance)
        elseif target.x > self.x then
            dx = self.speed + variance
        end

        if target.y < self.y then
            dy = -(self.speed + variance)
        elseif target.y > self.y then
            dy = self.speed + variance
        end

        self.x = self.x + dx * dt
        self.y = self.y + dy * dt

        self.x = math.max(0, math.min(self.x, platform.width))
        self.y = math.max(0, math.min(self.y, platform.height))
    end

    if dist < gun_thresh then
        local shoot_and_hit = math.random() < 0.04
        if shoot_and_hit then
            local damage = math.random() * 15
            target.health = math.max(0, target.health - damage)
            table.insert(platform.shoot, {self, target})
        end
    end
end

-- Initially, just find the closest survivor and walk towards them.
-- TODO: find closest thing. If survivor, walk towards them. If zombie, do
--       flocking behaviour with aspects of Boids.
function Zombie:update(platform, dt, zombies, survivors)

    local eat_threshold = 2

    if not self.target then
        self.target = self:find_target(self, survivors, zombies)
    elseif getmetatable(self.target.type) == Zombie and math.random() < 0.2 then
        self.target = self:find_target(self, survivors)
    end
    if not self.target then
        return
    end

    local follow = self.follows or self.target
    local target = self.target
    local dx, dy

    local variance = 1

    if follow.x < self.x then
        dx = -(self.speed + variance)
    elseif follow.x > self.x then
        dx = self.speed + variance
    end

    if follow.y < self.y then
        dy = -(self.speed + variance)
    elseif follow.y > self.y then
        dy = self.speed + variance
    end

    if dx and dy then
        if math.random() < 0.5 then
            dx = 0
        else
            dy = 0
        end
    end

    dx = dx or 0
    dy = dy or 0
    self.x = self.x + (dx * dt)
    self.y = self.y + (dy * dt)
    
    if self - target < eat_threshold then
        local bite = math.random() < 0.5
        if bite then
            local damage = math.random() * 30
            target.health = math.max(0, target.health - damage)
        end
    end
end

function Survivor:update(platform, dt, zombies, survivors)
    if self.gun then
        update_survivor_gun(platform, self, dt, zombies, survivors)
    else
        update_survivor_run(platform, self, dt, zombies, survivors)
    end
end

local Player = {}
setmetatable(Player, Entity)
Player.__index = Player
Player.__sub = Entity.__sub

function Player.new(x, y)
    local player = Entity.new(5, x, y, {1, 0, 0}, 30)
    player.health = 100
    player.maxhealth = 150
    return setmetatable(player, Player)
end

function Player:update(platform, dt)
    local dx, dy
    if love.keyboard.isDown('h') then
        dx = -self.speed
    elseif love.keyboard.isDown('l') then
        dx = self.speed
    else
        dx = 0
    end

    if love.keyboard.isDown('k') then
        dy = -self.speed
    elseif love.keyboard.isDown('j') then
        dy = self.speed
    else
        dy = 0
    end

    local follow_thresh = 2
    if love.keyboard.isDown('c') then
        for _, zomb in ipairs(platform.zombies) do
            if zomb ~= self then
                if self - zomb < follow_thresh then
                    zomb.follows = self
                end
            end
        end
    end

    local bite_thresh = 3
    if love.keyboard.isDown('space') then
        for _, surv in ipairs(platform.survivors) do
            if self - surv < bite_thresh then
                local damage = 50
                surv.health = math.max(0, surv.health - damage)
            end
        end

        for _, zomb in ipairs(platform.zombies) do
            if zomb ~= self then
                if self - zomb < bite_thresh then
                    local damage = 50
                    zomb.health = math.max(0, zomb.health - damage)
                    self.health = math.min(self.maxhealth, self.health + 20)
                end
            end
        end
    end

    self.x = self.x + (dx * dt)
    self.y = self.y + (dy * dt)

    if self.health <= 0 then
        love.window.close()
    end
end

return {
    Entity=Entity,
    Survivor=Survivor,
    Zombie=Zombie,
    Player=Player,
}
