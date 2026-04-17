local gfx = playdate.graphics

local floor2Bounds = {
    hallwayTop = 97,
    hallwayBottom = 239,

    waitingTop = 97,
    waitingBottom = 172,

    tvTop = 97,
    tvBottom = 172
}

local floor2Objects = {
    hallway = {
        mouseHole = { x = 186, y = 86, w = 16, h = 11 }
    },

    waiting = {
        fishTankStand = { x = 0, y = 83, w = 88, h = 43 },
        leftPlant = { x = 260, y = 92, w = 22, h = 27 },
        rightPlant = { x = 394, y = 92, w = 6, h = 27 },
        doubleDoor = { x = 286, y = 65, w = 64, h = 63 }
    },

    tv = {
        tvStand = { x = 294, y = 26, w = 79, h = 67 }
    }
}

local function makeFloor2Player(footX, footY)
    return {
        footX = footX,
        footY = footY,
        speed = 4,
        facing = "down",
        isMoving = false
    }
end

local function loadSue64Images()
    return {
        sueIdle = GameUtils.loadImage("png_and_wavs/0_universal_sprites/sue_64x80"),
        sueWalkDown = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_64x80_down.gif", 10, true, 1.0),
        sueWalkLeft = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_64x80_left.gif", 10, true, 1.0),
        sueWalkRight = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_64x80_right.gif", 10, true, 1.0),
        sueWalkUp = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_64x80_up.gif", 10, true, 1.0),
        evvie = GameUtils.loadImage("png_and_wavs/0_universal_sprites/evvie_64x80")
    }
end

local function getFootRect(x, y)
    return {
        x = math.floor(x - 6),
        y = math.floor(y - 3),
        w = 12,
        h = 3
    }
end

local function pointInRect(px, py, rect)
    return px >= rect.x and px < rect.x + rect.w and py >= rect.y and py < rect.y + rect.h
end

local function drawSue64(scene)
    local imageToDraw = nil

    if scene.player.isMoving then
        if scene.player.facing == "down" and scene.images.sueWalkDown then
            imageToDraw = scene.images.sueWalkDown:getFrame()
        elseif scene.player.facing == "left" and scene.images.sueWalkLeft then
            imageToDraw = scene.images.sueWalkLeft:getFrame()
        elseif scene.player.facing == "right" and scene.images.sueWalkRight then
            imageToDraw = scene.images.sueWalkRight:getFrame()
        elseif scene.player.facing == "up" and scene.images.sueWalkUp then
            imageToDraw = scene.images.sueWalkUp:getFrame()
        end
    end

    if imageToDraw == nil then
        imageToDraw = scene.images.sueIdle
    end

    if imageToDraw == nil then
        return
    end

    local w, h = imageToDraw:getSize()
    imageToDraw:draw(math.floor(scene.player.footX - w / 2), math.floor(scene.player.footY - h))
end

local function updateSue64Movement(scene, dt)
    local dx = 0
    local dy = 0

    if playdate.buttonIsPressed(playdate.kButtonLeft) then
        dx = dx - 1
    end

    if playdate.buttonIsPressed(playdate.kButtonRight) then
        dx = dx + 1
    end

    if playdate.buttonIsPressed(playdate.kButtonUp) then
        dy = dy - 1
    end

    if playdate.buttonIsPressed(playdate.kButtonDown) then
        dy = dy + 1
    end

    scene.player.isMoving = (dx ~= 0 or dy ~= 0)

    if dx ~= 0 or dy ~= 0 then
        if math.abs(dx) > math.abs(dy) then
            if dx < 0 then
                scene.player.facing = "left"
            else
                scene.player.facing = "right"
            end
        else
            if dy < 0 then
                scene.player.facing = "up"
            else
                scene.player.facing = "down"
            end
        end
    end

    if dx ~= 0 and dy ~= 0 then
        dx = dx * 0.7071
        dy = dy * 0.7071
    end

    local nextX = scene.player.footX + dx * scene.player.speed
    if not scene:isBlocked(nextX, scene.player.footY) then
        scene.player.footX = nextX
    end

    local nextY = scene.player.footY + dy * scene.player.speed
    if not scene:isBlocked(scene.player.footX, nextY) then
        scene.player.footY = nextY
    end

    if scene.player.isMoving then
        if scene.player.facing == "down" and scene.images.sueWalkDown then
            scene.images.sueWalkDown:update(dt)
        elseif scene.player.facing == "left" and scene.images.sueWalkLeft then
            scene.images.sueWalkLeft:update(dt)
        elseif scene.player.facing == "right" and scene.images.sueWalkRight then
            scene.images.sueWalkRight:update(dt)
        elseif scene.player.facing == "up" and scene.images.sueWalkUp then
            scene.images.sueWalkUp:update(dt)
        end
    end
end

local function makeBaseScene(state, footX, footY)
    local scene = {}

    scene.state = state
    scene.player = makeFloor2Player(footX, footY)
    scene.dialogue = nil

    function scene:isInsideRoomBounds(footRect)
        return true
    end

    function scene:getFootRect(x, y)
        return getFootRect(x, y)
    end

    function scene:isBlockedByRects(footRect)
        for i = 1, #self.blockRects do
            if GameUtils.rectsOverlap(footRect, self.blockRects[i]) then
                return true
            end
        end

        return false
    end

    function scene:isBlocked(x, y)
        local footRect = self:getFootRect(x, y)

        if not self:isInsideRoomBounds(footRect) then
            return true
        end

        return self:isBlockedByRects(footRect)
    end

    function scene:update(dt)
        if self.dialogue then
            if playdate.buttonJustPressed(playdate.kButtonA) then
                if GameUtils.advanceDialogue(self.dialogue) then
                    self.dialogue = nil
                end
            end
            return
        end

        updateSue64Movement(self, dt)
        self:checkRoomTransitions()
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)
    end

    return scene
end

function newFloor2HallwayScene(state)
    local scene = makeBaseScene(state, 30, 101)

    scene.musicPath = "png_and_wavs/lobby/the_color_of_smog"

    scene.images = loadSue64Images()
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor2/hallway_lvl2")
    scene.images.mouseHole = GameUtils.loadImage("png_and_wavs/floor2/no_cheese_mouse")
    scene.images.mouseSuccess = GameUtils.loadImage("png_and_wavs/floor2/mouse_success")
    scene.images.mouseFailure = GameUtils.loadImage("png_and_wavs/floor2/mouse_failure")
    scene.images.cheeseStretch = GameUtils.loadImage("png_and_wavs/floor2/cheese_stretch")
    scene.images.playThese = GameUtils.loadImage("png_and_wavs/floor2/play_these")
    scene.images.successIdiot = GameUtils.loadImage("png_and_wavs/floor2/success_idiot")
    scene.images.failureIdiot = GameUtils.loadImage("png_and_wavs/floor2/failure_idiot")

    scene.blockRects = {
    }

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 0 or footRect.x + footRect.w > 400 then
            return false
        end

        if footRect.y < floor2Bounds.hallwayTop or footRect.y + footRect.h > floor2Bounds.hallwayBottom then
            return false
        end

        return true
    end

    function scene:getNearbyInteractive()
        local interactives = {
            {
                name = "lobbyDoor",
                prompt = "A: Go Back",
                zone = { x = 10, y = 97, w = 50, h = 18 },
                anchor = { x = 10, y = 112 },
                action = function(selfScene)
                    Game:switchScene(function(nextState)
                        return newLevel1Scene(nextState)
                    end)
                end
            }
        }

        local best = nil
        local bestDist = 999

        for i = 1, #interactives do
            local item = interactives[i]
            local d = GameUtils.pointRectDistance(self.player.footX, self.player.footY, item.zone)
            if d < bestDist then
                best = item
                bestDist = d
            end
        end

        if best and bestDist <= 5 then
            return best
        end

        return nil
    end

    function scene:drawPrompt()
        local interactive = self:getNearbyInteractive()
        if not interactive then
            return
        end

        local font = Game.fonts.prompt or gfx.getSystemFont()
        local w = font:getTextWidth(interactive.prompt)
        local x = GameUtils.clamp(interactive.anchor.x, 4, 396 - w)
        local y = GameUtils.clamp(interactive.anchor.y, 4, 228)
        GameUtils.drawTextWithUnderlay(interactive.prompt, x, y, font)
    end

    function scene:checkRoomTransitions()
        if self.player.footX >= 388 then
            Game:switchScene(function(nextState)
                return newFloor2WaitingRoomScene(nextState, "fromHallway")
            end)
            return
        end

        -- mouse hole later
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.base then
            self.images.base:draw(0, 0)
        end

        drawSue64(self)
        GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end

function newFloor2WaitingRoomScene(state, entry)
    local spawnX = 18
    local spawnY = 172

    if entry == "fromTvRoom" then
        spawnX = 360
        spawnY = 172
    end

    local scene = makeBaseScene(state, spawnX, spawnY)

    scene.musicPath = "png_and_wavs/lobby/the_color_of_smog"

    scene.images = loadSue64Images()
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor2/waiting_room_lvl2")

    scene.npcs = {
        evvie = {
            footX = 45,
            footY = 126
        }
    }

    scene.blockRects = {
        floor2Objects.waiting.fishTankStand,
        floor2Objects.waiting.leftPlant,
        floor2Objects.waiting.rightPlant,
        floor2Objects.waiting.doubleDoor
    }

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 0 or footRect.x + footRect.w > 400 then
            return false
        end

        if self.player.footY < floor2Bounds.hallwayTop or self.player.footY > floor2Bounds.hallwayBottom then
            return false
        end

        return true
    end

    function scene:checkRoomTransitions()
        if self.player.footX <= 4 then
            Game:switchScene(function(nextState)
                return newFloor2HallwayScene(nextState)
            end)
            return
        end

        if self.player.footX >= 396 then
            Game:switchScene(function(nextState)
                return newFloor2TvRoomScene(nextState)
            end)
            return
        end
    end

    function scene:drawNpcEvvie()
        if not self.images.evvie then
            return
        end

        local w, h = self.images.evvie:getSize()
        self.images.evvie:draw(
            math.floor(self.npcs.evvie.footX - w / 2),
            math.floor(self.npcs.evvie.footY - h)
        )
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.base then
            self.images.base:draw(0, 0)
        end

        self:drawNpcEvvie()
        drawSue64(self)
        GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end

function newFloor2TvRoomScene(state)
    local scene = makeBaseScene(state, 28, 172)

    scene.musicPath = "png_and_wavs/lobby/the_color_of_smog"

    scene.images = loadSue64Images()
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor2/tv_waiting_room")

    scene.blockRects = {
        floor2Objects.tv.tvStand
    }

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 0 or footRect.x + footRect.w > 400 then
            return false
        end

        if footRect.y < floor2Bounds.tvTop or footRect.y + footRect.h > floor2Bounds.tvBottom then
            return false
        end

        return true
    end

    function scene:checkRoomTransitions()
        if self.player.footX <= 4 then
            Game:switchScene(function(nextState)
                return newFloor2WaitingRoomScene(nextState, "fromTvRoom")
            end)
            return
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.base then
            self.images.base:draw(0, 0)
        end

        drawSue64(self)
        GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end