local entity = require "entity"
local Entity = entity.Entity
local Survivor = entity.Survivor
local Zombie = entity.Zombie
local Player = entity.Player

-- TODO:
-- o Infinite scrolling(?)
-- o Obstacles and walls
-- o Eat other zombies to get health
-- o Convert other zombies to follow you
-- o Update zombie movement to flock with
--      a small sample picking targets
-- o Corpses to bring back to life

local platform = {}

math.randomseed(os.time())

local z = 'z'
local s = 's'

local tinymap = {
    { z , 0 },
    { 0 , s },
}
local bigmap = {
    { z , z , z , 0 , 0 , 0 , 0 , 0 , z , z , 0 , 0 , z  },
    { z , z , z , 0 , 0 , 0 , 0 , 0 , z , z , 0 , 0 , z  },
    { z , z , z , 0 , z , 0 , z , 0 , z , z , z , 0 , z  },
    { 0 , z , z , z , z , 0 , z , 0 , z , z , z , 0 , z  },
    { 0 , 0 , z , z , 0 , 0 , 0 , 0 , z , z , 0 , 0 , z  },
    { 0 , 0 , z , z , 0 , 0 , 0 , 0 , z , z , 0 , 0 , z  },
    { 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  },
    { 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  },
    { 0 , 0 , 0 , 0 , s , 0 , s , 0 , 0 , 0 , s , 0 , 0  },
    { 0 , s , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0  },
    { 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , s , 0 , 0 , s  },
    { s , 0 , 0 , 0 , 0 , 0 , 0 , 0 , s , s , 0 , 0 , s  },
    { s , 0 , 0 , 0 , 0 , 0 , 0 , 0 , s , s , 0 , 0 , s  },
}

local outnumberedmap = {
    { z, z, z, z, z, z, z, z, z }, 
    { z, z, z, z, z, z, z, z, z }, 
    { z, z, z, z, z, z, z, z, z }, 
    { z, z, z, z, z, z, z, z, z }, 
    { z, z, z, z, z, z, z, z, z }, 
    { 0, 0, 0, 0, 0, 0, 0, 0, 0 }, 
    { s, s, s, s, s, s, s, s, s }, 
}

local testmap = outnumberedmap

function loadmap(platform, map, factor)
    platform.zombies = platform.zombies or {}
    platform.survivors = platform.survivors or {}
    for y, row in ipairs(map) do
        for x, c in ipairs(row) do
            local randx = (math.random() * factor * 2) - factor
            local randy = (math.random() * factor * 2) - factor
            if c == 'z' then
                local zombie = Zombie.new(
                    (x * factor)+randx, 
                    (y*factor)+randy
                )
                table.insert(platform.zombies, zombie)
            elseif c == 's' then
                local survivor = Survivor.new(
                    (x * factor)+randx, 
                    (y*factor)+randy
                )
                table.insert(platform.survivors, survivor)
            end
        end
    end
    platform.zombie_count = #platform.zombies
end

function load_sound()
    platform.assets = platform.assets or {}
    platform.assets.sound = platform.assets.sound or {}

    local zombies = love.audio.newSource("assets/hell.wav", "static")
    zombies:setLooping(true)
    love.audio.play(zombies)
    
    local gun = love.audio.newSource("assets/gunshot.wav", "static")
    gun:setVolume(0.2)

    local guns = {
        gun,
        gun:clone(),
        gun:clone(),
    }
    guns[0] = #guns

    platform.assets.sound.guns = guns
    platform.assets.sound.zombies = zombies

end

function load_images()
    platform.assets = platform.assets or {}
    platform.assets.images = platform.assets.images or {}

    local tile = love.graphics.newImage("assets/tile.png")
    tile:setWrap('repeat', 'repeat')
    platform.assets.images.tile = tile
end

function love.load()
    platform.width = love.graphics.getWidth()
    platform.height = love.graphics.getHeight()

    platform.assets = {}

    load_images()
    load_sound()

    platform.player = Player.new(platform.height/2, platform.width/2)

    platform.survivors = {}
    platform.zombies = {platform.player}


    loadmap(platform, testmap, platform.width/#testmap)
end

function love.update(dt)
    
    -- Gun shots
    platform.shoot = {}

    for i, ent in ipairs(platform.survivors) do
        ent:update(platform, dt, platform.zombies, platform.survivors)
        if ent.health <= 0 then
            table.remove(platform.survivors, i)
            if #platform.survivors == 0 then
                print("YOU WIN")
                love.window.close()
            end
        end
    end

    for i, ent in ipairs(platform.zombies) do
        ent:update(platform, dt, platform.zombies, platform.survivors)
        if ent.health <= 0 then
            table.remove(platform.zombies, i)
            local volume = #platform.zombies/platform.zombie_count
            platform.assets.sound.zombies:setVolume(volume)
        end
    end
end

function love.draw()

    love.graphics.setColor(0.6, 0.6, 0.6)
    local tile = platform.assets.images.tile
    local scale = 0.18
    local width = tile:getWidth() * scale
    local height = tile:getHeight() * scale
    for i = 0, platform.width / width do
        for j = 0, platform.height / height do
            love.graphics.draw(tile, i*width, j*height, 0, scale, scale)
        end
    end

    platform.player:draw()
    for _, entity in ipairs(platform.zombies) do
        entity:draw()
    end
    for _, entity in ipairs(platform.survivors) do
        entity:draw()
    end
    for _, shot in ipairs(platform.shoot) do
        local from, to = shot[1], shot[2]
        local guns = platform.assets.sound.guns
        local gun = guns[guns[0]]
        guns[0] = ((guns[0] + 1) % #guns) + 1

        gun:seek(0)
        love.graphics.setColor(1, 1, 0, 0.8)
        love.graphics.line(from.x, from.y, to.x, to.y)
        love.audio.play(gun)
    end
end
