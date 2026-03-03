import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/object"
import "CoreLibs/timer"

local pd <const> = playdate
local gfx <const> = playdate.graphics

local SCREEN_W <const> = 400
local SCREEN_H <const> = 240

local function loadImage(path)
    local img = gfx.image.new(path)
    assert(img, "Missing image: " .. path)
    return img
end

local function buildCompositeBackground()
    local bg = gfx.image.new(SCREEN_W, SCREEN_H, gfx.kColorWhite)

    local layers = {
        "images/bed_element",
        "images/cake_element",
        "images/desk_element",
        "images/door_element",
        "images/skewer_element",
        "images/kebab_element",

        "images/label_bed",
        "images/label_cake",
        "images/label_door",
        "images/label_skewer",
    }

    gfx.pushContext(bg)
        for _, path in ipairs(layers) do
            loadImage(path):draw(0, 0)
        end
    gfx.popContext()

    local bgSprite = gfx.sprite.new(bg)
    bgSprite:setCenter(0, 0)
    bgSprite:moveTo(0, 0)
    bgSprite:setZIndex(0)
    bgSprite:add()
end

class("Player").extends(gfx.sprite)

function Player:init(path)
    local img = loadImage(path)
    Player.super.init(self, img)

    self:setZIndex(10)
    self:setCenter(0.5, 0.5)
    self:moveTo(SCREEN_W / 2, SCREEN_H / 2)

    self.speed = 2.5
    self:add()
end

-- keep Player class, but REMOVE Player:update() entirely

function pd.update()
    local dx, dy = 0, 0
    local speed = player.speed

    if pd.buttonIsPressed(pd.kButtonLeft)  then dx -= speed end
    if pd.buttonIsPressed(pd.kButtonRight) then dx += speed end
    if pd.buttonIsPressed(pd.kButtonUp)    then dy -= speed end
    if pd.buttonIsPressed(pd.kButtonDown)  then dy += speed end

    if dx ~= 0 or dy ~= 0 then
        player:moveTo(player.x + dx, player.y + dy)

        -- clamp to screen bounds
        local w, h = player:getSize()
        local halfW, halfH = w * 0.5, h * 0.5
        local x = math.max(halfW, math.min(SCREEN_W - halfW, player.x))
        local y = math.max(halfH, math.min(SCREEN_H - halfH, player.y))
        player:moveTo(x, y)
    end

    gfx.sprite.update()
    pd.timer.updateTimers()
end

buildCompositeBackground()
local player = Player("images/player_element")

function pd.update()
    gfx.sprite.update()
    pd.timer.updateTimers()
    function playdate.update()
    local dx, dy = 0, 0
    local speed = 3

    if playdate.buttonIsPressed(playdate.kButtonLeft)  then dx -= speed end
    if playdate.buttonIsPressed(playdate.kButtonRight) then dx += speed end
    if playdate.buttonIsPressed(playdate.kButtonUp)    then dy -= speed end
    if playdate.buttonIsPressed(playdate.kButtonDown)  then dy += speed end

    if dx ~= 0 or dy ~= 0 then
        player:moveTo(player.x + dx, player.y + dy)
    end

    -- fixed-radius clamp (won't lock you to center even if image is 400x240)
    local r = 8
    player:moveTo(
        math.max(r, math.min(400 - r, player.x)),
        math.max(r, math.min(240 - r, player.y))
    )

    playdate.graphics.sprite.update()
    playdate.timer.updateTimers()
end
end