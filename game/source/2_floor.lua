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
        fishTankBlock = { x = 0, y = 118, w = 58, h = 8 },
        fishTankZone = { x = 0, y = 84, w = 78, h = 42 },
        leftPlant = { x = 260, y = 92, w = 22, h = 27 },
        rightPlant = { x = 394, y = 92, w = 6, h = 27 },
        elevatorZone = { x = 286, y = 65, w = 64, h = 63 }
    },

    tv = {
        tvStand = { x = 294, y = 26, w = 79, h = 67 },
        tvZone = { x = 296, y = 8, w = 86, h = 84 },
        tvInteractZone = { x = 280, y = 88, w = 108, h = 22 }
    },

    elevator = {
        doorZone = { x = 150, y = 92, w = 100, h = 24 },
        operatorZone = { x = 220, y = 118, w = 32, h = 54 },
        operatorBlock = { x = 222, y = 150, w = 26, h = 24 }
    }
}

local floor2MusicPaths = {
    room = "png_and_wavs/lobby/the_color_of_smog",
    fishTank = "png_and_wavs/floor2/fishies",
    tvPlaceholder = "png_and_wavs/floor2/ohno_my_crops",
    profK = "png_and_wavs/floor2/esteemed-prof-k"
}

local function ensureFloor2State(state)
    if state.floor2 == nil then
        state.floor2 = {
            evvieGone = false,
            profKDone = false
        }
    end

    if state.floor2.evvieGone == nil then
        state.floor2.evvieGone = false
    end

    if state.floor2.profKDone == nil then
        state.floor2.profKDone = false
    end
end

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

local function loadSue32Images()
    return {
        sueIdle = GameUtils.loadImage("png_and_wavs/0_universal_sprites/sue_32x40"),
        sueWalkDown = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_32x40_down.gif", 10, true, 1.0),
        sueWalkLeft = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_32x40_left.gif", 10, true, 1.0),
        sueWalkRight = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_32x40_right.gif", 10, true, 1.0),
        sueWalkUp = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_32x40_up.gif", 10, true, 1.0)
    }
end

local function playFloor2Music(path)
    if Game and Game.playMusic then
        Game:playMusic(path)
    end
end

local function loadDemonPointerAnim()
    local anim = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/demon_pointy", 10, true, 1.0)
    if anim then
        return anim
    end

    return GameUtils.loadAnim("png_and_wavs/0_universal_sprites/demon pointy", 10, true, 1.0)
end


local function loadFishTankAnim()
    local candidates = {
        "png_and_wavs/floor2/fishies",
        "png_and_wavs/floor2/fishies.gif"
    }

    for i = 1, #candidates do
        local anim = GameUtils.loadAnim(candidates[i], 10, true, 1.0)
        if anim and anim.getFrame and anim:getFrame() then
            return anim
        end
    end

    return nil
end

local function loadFishFoodStrip()
    local candidates = {
        "png_and_wavs/floor2/fish_food",
        "png_and_wavs/floor2/fish_food.png"
    }

    for i = 1, #candidates do
        local image = GameUtils.loadImage(candidates[i])
        if image then
            return image
        end
    end

    return nil
end

local function loadSmallDemonImage()
    local candidates = {
        "png_and_wavs/0_universal_sprites/demon_32x32",
        "png_and_wavs/0_universal_sprites/demon_64x64",
        "png_and_wavs/0_universal_sprites/demon_pointy"
    }

    for i = 1, #candidates do
        local image = GameUtils.loadImage(candidates[i])
        if image then
            return image
        end

        local anim = GameUtils.loadAnim(candidates[i], 10, true, 1.0)
        if anim and anim.getFrame and anim:getFrame() then
            return anim:getFrame()
        end
    end

    return nil
end

local function drawFishFoodFrame(strip, frameIndex, x, y)
    if not strip then
        return
    end

    local w, h = strip:getSize()
    local frameW = math.floor(w / 3)

    if frameW <= 0 then
        frameW = w
    end

    local sourceX = (math.max(1, math.min(frameIndex, 3)) - 1) * frameW
    local frame = gfx.image.new(frameW, h)

    if frame then
        gfx.pushContext(frame)
        strip:draw(-sourceX, 0)
        gfx.popContext()
        frame:draw(x, y)
    end
end

local function getFootRect(x, y)
    return {
        x = math.floor(x - 6),
        y = math.floor(y - 3),
        w = 12,
        h = 3
    }
end

local function drawNpcImage(image, x, y)
    if image then
        image:draw(math.floor(x), math.floor(y))
    end
end

local function formatFloor2SpokenLine(text)
    if text == nil or text == "" then
        return nil
    end

    local speaker, content = string.match(text, "^%s*([^:]+):%s*(.*)$")

    if speaker and content and content ~= "" then
        content = content:gsub('^"(.*)"$', "%1")
        return speaker .. ': "' .. content .. '"'
    end

    text = text:gsub('^"(.*)"$', "%1")
    return '"' .. text .. '"'
end

local function formatFloor2OptionLine(buttonLabel, text)
    if text == nil or text == "" then
        return nil
    end

    text = text:gsub('^"(.*)"$', "%1")
    return buttonLabel .. ': "' .. text .. '"'
end

local function drawFloor2TalkBox(ui)
    if not ui then
        return
    end

    local function drawOutlinedLeftArrow(xLeft, xRight, centerY)
        local function drawArrow(fillColor, expand)
            local bodyHalf = 4 + expand
            local headLen = 10 + expand
            local leftNeck = xLeft + headLen

            gfx.setColor(fillColor)
            gfx.fillPolygon(
                xLeft, centerY,
                leftNeck, centerY - bodyHalf,
                xRight, centerY - bodyHalf,
                xRight, centerY + bodyHalf,
                leftNeck, centerY + bodyHalf
            )
        end

        drawArrow(gfx.kColorBlack, 2)
        drawArrow(gfx.kColorWhite, 0)
        gfx.setColor(gfx.kColorBlack)
    end

    local function drawMeanOptionMarker(targetLine, targetY, demonAnim)
        if not targetLine or not demonAnim then
            return
        end

        demonAnim:update(1 / 30)

        local demonFrame = demonAnim:getFrame()
        if not demonFrame then
            return
        end

        local textEndX = 10 + font:getTextWidth(targetLine)
        local demonW, demonH = demonFrame:getSize()

        local demonX = 400 - demonW - 8
        local shakeOffset = math.floor(math.sin(playdate.getCurrentTimeMilliseconds() / 45) * 2)
        local demonY = targetY - 10 + shakeOffset

        local arrowRight = demonX - 6
        local arrowLeft = textEndX + 10

        if arrowLeft < arrowRight - 18 then
            drawOutlinedLeftArrow(arrowLeft, arrowRight, targetY + 6)
        end

        demonFrame:draw(demonX, demonY)

        GameUtils.drawTextWithUnderlay("hehehehehe", demonX - 30, targetY - 14, font)
    end

    local font = Game.fonts.dialog or gfx.getSystemFont()

    local spokenLine = formatFloor2SpokenLine(ui.text)
    if spokenLine then
        local lines = GameUtils.wrapText(spokenLine, font, 380)

        for i = 1, #lines do
            local y = 8 + (i - 1) * (font:getHeight() + 2)
            GameUtils.drawTextWithUnderlay(lines[i], 10, y, font)
        end
    end

    local aLine = formatFloor2OptionLine("A", ui.aText)
    local bLine = formatFloor2OptionLine("B", ui.bText)

    if aLine then
        GameUtils.drawTextWithUnderlay(aLine, 10, 196, font)
    end

    if bLine then
        GameUtils.drawTextWithUnderlay(bLine, 10, 214, font)
    end

    local meanTargets = {}

    if type(ui.demonTarget) == "table" then
        meanTargets = ui.demonTarget
    elseif ui.demonTarget == "A" or ui.demonTarget == "B" then
        meanTargets[ui.demonTarget] = true
    end

    if meanTargets.A then
        drawMeanOptionMarker(aLine, 196, ui.demonPointerAnim)
    end

    if meanTargets.B then
        drawMeanOptionMarker(bLine, 214, ui.demonPointerAnim)
    end
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

local function drawSue32At(imageSet, footX, footY)
    if not imageSet or not imageSet.sueIdle then
        return
    end

    local w, h = imageSet.sueIdle:getSize()
    imageSet.sueIdle:draw(math.floor(footX - w / 2), math.floor(footY - h))
end


local function drawSue32(scene)
    if not scene.images or not scene.images.sue then
        return
    end

    local imageSet = scene.images.sue
    local imageToDraw = nil

    if scene.player.isMoving then
        if scene.player.facing == "down" and imageSet.sueWalkDown then
            imageToDraw = imageSet.sueWalkDown:getFrame()
        elseif scene.player.facing == "left" and imageSet.sueWalkLeft then
            imageToDraw = imageSet.sueWalkLeft:getFrame()
        elseif scene.player.facing == "right" and imageSet.sueWalkRight then
            imageToDraw = imageSet.sueWalkRight:getFrame()
        elseif scene.player.facing == "up" and imageSet.sueWalkUp then
            imageToDraw = imageSet.sueWalkUp:getFrame()
        end
    end

    if imageToDraw == nil then
        imageToDraw = imageSet.sueIdle
    end

    if imageToDraw == nil then
        return
    end

    local w, h = imageToDraw:getSize()
    imageToDraw:draw(math.floor(scene.player.footX - w / 2), math.floor(scene.player.footY - h))
end

local function drawPlaceholderElevatorNpc()
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRoundRect(220, 118, 28, 58, 8)
    gfx.fillCircleAtPoint(234, 114, 10)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(230, 112, 1)
    gfx.fillCircleAtPoint(238, 112, 1)
    gfx.setColor(gfx.kColorBlack)
end

local function updateSue32Movement(scene, dt)
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
        local imageSet = scene.images.sue

        if scene.player.facing == "down" and imageSet.sueWalkDown then
            imageSet.sueWalkDown:update(dt)
        elseif scene.player.facing == "left" and imageSet.sueWalkLeft then
            imageSet.sueWalkLeft:update(dt)
        elseif scene.player.facing == "right" and imageSet.sueWalkRight then
            imageSet.sueWalkRight:update(dt)
        elseif scene.player.facing == "up" and imageSet.sueWalkUp then
            imageSet.sueWalkUp:update(dt)
        end
    end
end

local function drawFloor2PromptNearZone(prompt, zone)
    local font = Game.fonts.prompt or gfx.getSystemFont()
    local w = font:getTextWidth(prompt)
    local h = font:getHeight()

    local x = GameUtils.clamp(zone.x + zone.w + 6, 4, 396 - w)
    local y = GameUtils.clamp(zone.y + math.floor((zone.h - h) / 2), 4, 228)

    GameUtils.drawTextWithUnderlay(prompt, x, y, font)
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
    scene.blockRects = {}

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

    scene.musicPath = floor2MusicPaths.room

    scene.images = loadSue64Images()
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor2/hallway_lvl2")
    scene.images.mouseHole = GameUtils.loadImage("png_and_wavs/floor2/no_cheese_mouse")
    scene.images.mouseSuccess = GameUtils.loadImage("png_and_wavs/floor2/mouse_success")
    scene.images.mouseFailure = GameUtils.loadImage("png_and_wavs/floor2/mouse_failure")
    scene.images.cheeseStretch = GameUtils.loadImage("png_and_wavs/floor2/cheese_stretch")
    scene.images.playThese = GameUtils.loadImage("png_and_wavs/floor2/play_these")
    scene.images.successIdiot = GameUtils.loadImage("png_and_wavs/floor2/success_idiot")
    scene.images.failureIdiot = GameUtils.loadImage("png_and_wavs/floor2/failure_idiot")

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
        if self.dialogue then
            return
        end

        local interactive = self:getNearbyInteractive()
        if not interactive then
            return
        end

        drawFloor2PromptNearZone(interactive.prompt, interactive.promptZone or interactive.zone)
    end

    function scene:checkRoomTransitions()
        if self.player.footX >= 388 then
            Game:switchScene(function(nextState)
                return newFloor2WaitingRoomScene(nextState, "fromHallway")
            end)
            return
        end
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

        if playdate.buttonJustPressed(playdate.kButtonA) then
            local interactive = self:getNearbyInteractive()
            if interactive then
                interactive.action(self)
                return
            end
        end

        self:checkRoomTransitions()
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.base then
            self.images.base:draw(0, 0)
        end

        drawSue64(self)
        self:drawPrompt()
        GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end

function newFishTankPlaceholderScene(state)
    ensureFloor2State(state)

    local scene = {}

    scene.state = state
    scene.musicPath = floor2MusicPaths.fishTank

    local function cropImage(sourceImage, x, y, w, h)
        if not sourceImage then
            return nil
        end

        local image = gfx.image.new(w, h, gfx.kColorClear)

        if not image then
            return nil
        end

        gfx.pushContext(image)
            sourceImage:draw(-x, -y)
        gfx.popContext()

        return image
    end

    local function loadFishFoodFrames()
        local strip = GameUtils.loadImage("png_and_wavs/floor2/fish_food")
        if not strip then
            strip = GameUtils.loadImage("fish_food")
        end

        if not strip then
            return nil
        end

        local stripW, stripH = strip:getSize()
        local frameW = math.floor(stripW / 3)

        return {
            cropImage(strip, 0, 0, frameW, stripH),
            cropImage(strip, frameW, 0, frameW, stripH),
            cropImage(strip, frameW * 2, 0, frameW, stripH)
        }
    end

    local function getCrankVerticalState(angle)
        angle = angle % 360

        -- much looser thresholds so smaller crank movement counts
        if angle >= 250 and angle <= 330 then
            return "up"
        end

        if angle >= 30 and angle <= 110 then
            return "down"
        end

        return "neutral"
    end

    local function exitFishTank()
        Game:switchScene(function(nextState)
            return newFloor2WaitingRoomScene(nextState, "fromFishTank")
        end)
    end

    scene.images = {
        bg = GameUtils.loadAnim("png_and_wavs/floor2/fishies.gif", 8, true, 1.0)
            or GameUtils.loadAnim("png_and_wavs/floor2/fishies", 8, true, 1.0),
        foodFrames = loadFishFoodFrames(),
        demon = GameUtils.loadImage("png_and_wavs/floor2/demon_32x32")
            or GameUtils.loadImage("png_and_wavs/brain_mini_game/demon_32x32")
            or GameUtils.loadImage("png_and_wavs/0_universal_sprites/demon_32x32")
    }

    scene.shakes = 0
    scene.foodFrameIndex = 1
    scene.pendingUp = false
    scene.gameOver = false
    scene.demonVibrateTimer = 0

    function scene:updateShakeLogic()
        local crankState = getCrankVerticalState(playdate.getCrankPosition())

        if crankState == "up" then
            self.foodFrameIndex = 2
            self.pendingUp = true
        elseif crankState == "down" then
            self.foodFrameIndex = 3

            if self.pendingUp and not self.gameOver then
                self.pendingUp = false

                if self.shakes < 10 then
                    self.shakes = self.shakes + 1
                end

                if self.shakes >= 10 then
                    self.gameOver = true
                    self.state.floor2.fishTankBadEnding = true
                end
            end
        else
            self.foodFrameIndex = 1
        end
    end

    function scene:drawShakeCounter(font)
        GameUtils.drawTextWithUnderlay("shakes: " .. tostring(self.shakes), 8, 214, font)
    end

    function scene:drawExitPrompt(font)
        local text = "B: exit"
        local x = 400 - font:getTextWidth(text) - 8
        GameUtils.drawTextWithUnderlay(text, x, 214, font)
    end

    function scene:drawDemon(font)
        if self.shakes < 5 or self.gameOver then
            return
        end

        local demonX = 400 - 32 - 8
        local demonY = 8

        if self.shakes > 5 then
            demonY = demonY + math.floor(math.sin(self.demonVibrateTimer * 14) * 3)
        end

        if self.images.demon then
            self.images.demon:draw(demonX, demonY)
        end

        local text = "cmon. just a few more shakes... cant hurt..?"
        if self.shakes > 5 then
            text = "hehehehehe"
        end

        local lines = GameUtils.wrapText(text, font, 120)
        local startY = demonY + 36

        for i = 1, #lines do
            local line = lines[i]
            local lineX = 400 - font:getTextWidth(line) - 8
            GameUtils.drawTextWithUnderlay(line, lineX, startY + (i - 1) * (font:getHeight() + 2), font)
        end
    end

    function scene:drawGameOver(font)
        gfx.clear(gfx.kColorBlack)

        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

        local lines = GameUtils.wrapText(
            "you listened to the voices?? how could you. the fish are gladly fine, but this is unacceptable.",
            font,
            260
        )

        local totalH = #lines * font:getHeight() + (#lines - 1) * 4
        local startY = math.floor((240 - totalH) / 2) - 10

        for i = 1, #lines do
            local line = lines[i]
            local x = math.floor((400 - font:getTextWidth(line)) / 2)
            local y = startY + (i - 1) * (font:getHeight() + 4)
            font:drawText(line, x, y)
        end

        local exitText = "B: exit"
        local exitX = math.floor((400 - font:getTextWidth(exitText)) / 2)
        font:drawText(exitText, exitX, 212)

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    function scene:update(dt)
        if self.images.bg then
            self.images.bg:update(dt)
        end

        if self.gameOver then
            if playdate.buttonJustPressed(playdate.kButtonB) then
                exitFishTank()
            end
            return
        end

        self:updateShakeLogic()

        if self.shakes >= 5 then
            self.demonVibrateTimer = self.demonVibrateTimer + dt

            if playdate.buttonJustPressed(playdate.kButtonB) then
                exitFishTank()
                return
            end
        end
    end

    function scene:draw()
        local font = Game.fonts.prompt or gfx.getSystemFont()

        if self.gameOver then
            self:drawGameOver(font)
            return
        end

        gfx.clear(gfx.kColorWhite)

        if self.images.bg then
            local frame = self.images.bg:getFrame()
            if frame then
                frame:draw(0, 0)
            end
        end

        if self.images.foodFrames and self.images.foodFrames[self.foodFrameIndex] then
            local foodImage = self.images.foodFrames[self.foodFrameIndex]
            local foodW, foodH = foodImage:getSize()
            local foodX = math.floor((400 - foodW) / 2)
            local foodY = 16 -- centered horizontally, lowered about 10 px from old top placement
            foodImage:draw(foodX, foodY)
        end

        self:drawShakeCounter(font)

        if self.shakes >= 5 then
            self:drawExitPrompt(font)
            self:drawDemon(font)
        end
    end

    return scene
end

function newElevatorScene(state)
    ensureFloor2State(state)

    local scene = {}

    scene.state = state
    scene.musicPath = floor2MusicPaths.room

    scene.images = {
        base = GameUtils.loadImage("png_and_wavs/elevator/elevator"),
        sue = loadSue32Images()
    }

    scene.player = makeFloor2Player(198, 178)
    scene.ui = nil

    function scene:setChoiceDialogue(text, aText, bText, onA, onB, demonTarget)
        self.ui = {
            text = text,
            aText = aText,
            bText = bText,
            onA = onA,
            onB = onB,
            demonTarget = demonTarget,
            demonPointerAnim = self.images.demonPointer
        }
    end

    function scene:setMessageDialogue(text, onClose)
        self.ui = {
            text = text,
            onClose = onClose
        }
    end

    function scene:handleUiInput()
        if not self.ui then
            return false
        end

        if self.ui.aText or self.ui.bText then
            if playdate.buttonJustPressed(playdate.kButtonA) and self.ui.onA then
                self.ui.onA(self)
            elseif playdate.buttonJustPressed(playdate.kButtonB) and self.ui.onB then
                self.ui.onB(self)
            end
            return true
        end

        if playdate.buttonJustPressed(playdate.kButtonA) or playdate.buttonJustPressed(playdate.kButtonB) then
            local onClose = self.ui.onClose
            self.ui = nil
            if onClose then
                onClose(self)
            end
            return true
        end

        return true
    end

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 150 or footRect.x + footRect.w > 254 then
            return false
        end

        if footRect.y < 118 or footRect.y + footRect.h > 186 then
            return false
        end

        return true
    end

    function scene:isBlocked(x, y)
        local footRect = getFootRect(x, y)

        if not self:isInsideRoomBounds(footRect) then
            return true
        end

        if GameUtils.rectsOverlap(footRect, floor2Objects.elevator.operatorBlock) then
            return true
        end

        return false
    end

    function scene:getNearbyInteractive()
        local candidates = {
            {
                name = "door",
                prompt = "A: Exit Elevator",
                zone = floor2Objects.elevator.doorZone,
                action = function(selfScene)
                    Game:switchScene(function(nextState)
                        return newFloor2WaitingRoomScene(nextState, "fromElevator")
                    end)
                end
            },
            {
                name = "operator",
                prompt = "A: talk",
                zone = floor2Objects.elevator.operatorZone,
                action = function(selfScene)
                    selfScene:setChoiceDialogue(
                        "hey kid, which floor?",
                        "2nd",
                        "3rd",
                        function(s)
                            s:setMessageDialogue("you're already on the second floor, silly child.")
                        end,
                        function(s)
                            s.ui = nil
                            Game:go("floor3Waiting", "fromElevator")
                        end
                    )
                end
            }
        }

        local best = nil
        local bestDist = 999

        for i = 1, #candidates do
            local item = candidates[i]
            local d = GameUtils.pointRectDistance(self.player.footX, self.player.footY, item.zone)
            if d < bestDist then
                best = item
                bestDist = d
            end
        end

        if best and bestDist <= 14 then
            return best
        end

        return nil
    end

    function scene:drawPrompt()
        if self.ui then
            return
        end

        local interactive = self:getNearbyInteractive()
        if not interactive then
            return
        end

        drawFloor2PromptNearZone(interactive.prompt, interactive.promptZone or interactive.zone)
    end

    function scene:update(dt)
        if self:handleUiInput() then
            return
        end

        updateSue32Movement(self, dt)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            local interactive = self:getNearbyInteractive()
            if interactive then
                interactive.action(self)
                return
            end
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorWhite)

        if self.images.base then
            self.images.base:draw(0, 0)
        end

        drawPlaceholderElevatorNpc()
        drawSue32(self)
        self:drawPrompt()
        drawFloor2TalkBox(self.ui)
    end

    return scene
end

function newTvPlaceholderScene(state)
    ensureFloor2State(state)

    local scene = {}

    scene.state = state
    scene.musicPath = floor2MusicPaths.tvPlaceholder
    scene.images = {
        screen = GameUtils.loadAnim("png_and_wavs/floor2/tv_screen.gif", 10, true, 1.0)
    }

    function scene:update(dt)
        if self.images.screen then
            self.images.screen:update(dt)
        end

        if playdate.buttonJustPressed(playdate.kButtonB) then
            Game:switchScene(function(nextState)
                return newFloor2TvRoomScene(nextState)
            end)
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorWhite)

        local frame = nil
        if self.images.screen then
            frame = self.images.screen:getFrame()
        end

        if frame then
            frame:draw(0, 0)
        end

        local font = Game.fonts.prompt or gfx.getSystemFont()
    end

    return scene
end

function newFloor2WaitingRoomScene(state, entry)
    ensureFloor2State(state)

    local spawnX = 96
    local spawnY = 170

    if entry == "fromTvRoom" then
        spawnX = 356
        spawnY = 170
    elseif entry == "fromFishTank" then
        spawnX = 96
        spawnY = 170
    elseif entry == "fromElevator" then
        spawnX = 320
        spawnY = 170
    end

    local scene = makeBaseScene(state, spawnX, spawnY)

    scene.musicPath = floor2MusicPaths.room

    scene.images = loadSue64Images()
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor2/waiting_room_lvl2")
    scene.images.demonPointer = loadDemonPointerAnim()

    scene.npcs = {
        evvie = {
            drawX = 165,
            drawY = 70,
            blockRect = { x = 165, y = 70, w = 65, h = 80 },
            talkZone = { x = 165, y = 70, w = 76, h = 80 }
        }
    }

    scene.ui = nil
    scene.blockRects = {
        floor2Objects.waiting.fishTankBlock,
        { x = 262, y = 112, w = 18, h = 18 },
        { x = 386, y = 112, w = 14, h = 18 }
    }

    function scene:setChoiceDialogue(text, aText, bText, onA, onB, demonTarget)
        self.ui = {
            text = text,
            aText = aText,
            bText = bText,
            onA = onA,
            onB = onB,
            demonTarget = demonTarget,
            demonPointerAnim = self.images.demonPointer
        }
    end

    function scene:setMessageDialogue(text, onClose)
        self.ui = {
            text = text,
            onClose = onClose
        }
    end

    function scene:handleUiInput()
        if not self.ui then
            return false
        end

        if self.ui.aText or self.ui.bText then
            if playdate.buttonJustPressed(playdate.kButtonA) and self.ui.onA then
                self.ui.onA(self)
            elseif playdate.buttonJustPressed(playdate.kButtonB) and self.ui.onB then
                self.ui.onB(self)
            end
            return true
        end

        if playdate.buttonJustPressed(playdate.kButtonA) or playdate.buttonJustPressed(playdate.kButtonB) then
            local onClose = self.ui.onClose
            self.ui = nil
            if onClose then
                onClose(self)
            end
            return true
        end

        return true
    end

    function scene:getNearbyInteractive()
        local candidates = {}

        if not self.state.floor2.evvieGone then
            candidates[#candidates + 1] = {
                name = "evvie",
                prompt = "A: Talk",
                zone = self.npcs.evvie.talkZone,
                anchor = { x = 14, y = 182 },
                action = function(selfScene)
                    selfScene:setChoiceDialogue(
                        "evvie: hey, sue, right? i'm evvie.",
                        "hi evvie, nice to meet you!",
                        "no, its not. go away.",
                        function(s)
                            s:setChoiceDialogue(
                                "evvie: what's up?",
                                "nothing...",
                                "could i feed the fish?",
                                function(s2)
                                    s2:setMessageDialogue(
                                        "evvie: okay, see you around.",
                                        function(s3)
                                            s3.state.floor2.evvieGone = true
                                        end
                                    )
                                end,
                                function(s2)
                                    s2:setChoiceDialogue(
                                        "evvie: sure, just 5 shakes of the fish food, got it?",
                                        "okay",
                                        nil,
                                        function(s3)
                                            s3.state.floor2.evvieGone = true
                                            Game:switchScene(function(nextState)
                                                return newFishTankPlaceholderScene(nextState)
                                            end)
                                        end,
                                        nil
                                    )
                                end
                            )
                        end,
                        function(s)
                            s:setMessageDialogue(
                                "evvie: oof.. okay?",
                                function(s2)
                                    s2.state.floor2.evvieGone = true
                                end
                            )
                        end,
                        "B"
                    )
                end
            }
        end

        candidates[#candidates + 1] = {
            name = "elevator",
            prompt = "A: Enter Elevator",
            zone = floor2Objects.waiting.elevatorZone,
            action = function(selfScene)
                Game:switchScene(function(nextState)
                    return newElevatorScene(nextState)
                end)
            end
        }

        local best = nil
        local bestDist = 999

        for i = 1, #candidates do
            local item = candidates[i]
            local d = GameUtils.pointRectDistance(self.player.footX, self.player.footY, item.zone)
            if d < bestDist then
                best = item
                bestDist = d
            end
        end

        if best and bestDist <= 10 then
            return best
        end

        return nil
    end

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 0 or footRect.x + footRect.w > 400 then
            return false
        end

        if footRect.y < floor2Bounds.waitingTop or footRect.y + footRect.h > floor2Bounds.waitingBottom then
            return false
        end

        return true
    end

    function scene:isBlocked(x, y)
        local footRect = self:getFootRect(x, y)

        if not self:isInsideRoomBounds(footRect) then
            return true
        end

        for i = 1, #self.blockRects do
            if GameUtils.rectsOverlap(footRect, self.blockRects[i]) then
                return true
            end
        end

        if not self.state.floor2.evvieGone and GameUtils.rectsOverlap(footRect, self.npcs.evvie.blockRect) then
            return true
        end

        return false
    end

    function scene:checkRoomTransitions()
        if self.player.footX <= 4 then
            Game:switchScene(function(nextState)
                return newFloor2HallwayScene(nextState)
            end)
            return
        end

        if self.player.footX >= 388 then
            Game:switchScene(function(nextState)
                return newFloor2TvRoomScene(nextState)
            end)
            return
        end
    end

    function scene:drawPrompt()
        if self.ui then
            return
        end

        local interactive = self:getNearbyInteractive()
        if not interactive then
            return
        end

        drawFloor2PromptNearZone(interactive.prompt, interactive.promptZone or interactive.zone)
    end

    function scene:update(dt)
        if self:handleUiInput() then
            return
        end

        updateSue64Movement(self, dt)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            local interactive = self:getNearbyInteractive()
            if interactive then
                interactive.action(self)
                return
            end
        end

        self:checkRoomTransitions()
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.base then
            self.images.base:draw(0, 0)
        end

        if not self.state.floor2.evvieGone then
            drawNpcImage(self.images.evvie, self.npcs.evvie.drawX, self.npcs.evvie.drawY)
        end

        drawSue64(self)
        self:drawPrompt()
        drawFloor2TalkBox(self.ui)
    end

    return scene
end

function newFloor2TvRoomScene(state)
    ensureFloor2State(state)

    local scene = makeBaseScene(state, 28, 172)

    scene.musicPath = floor2MusicPaths.room

    scene.images = loadSue64Images()
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor2/tv_waiting_room")
    scene.images.profK = GameUtils.loadImage("png_and_wavs/floor2/prof_k_64x96")
    scene.images.boots = GameUtils.loadImage("png_and_wavs/floor2/tv_room_boots")
    scene.images.demonPointer = loadDemonPointerAnim()

    scene.npcs = {
        profK = {
            drawX = 18,
            drawY = 8,
            blockRect = { x = 18, y = 12, w = 52, h = 30 },
            talkZone = { x = 18, y = 12, w = 74, h = 98 }
        }
    }

    scene.ui = nil
    scene.blockRects = {
        floor2Objects.tv.tvStand
    }

    function scene:setChoiceDialogue(text, aText, bText, onA, onB, demonTarget)
        self.ui = {
            text = text,
            aText = aText,
            bText = bText,
            onA = onA,
            onB = onB,
            demonTarget = demonTarget,
            demonPointerAnim = self.images.demonPointer
        }
    end

    function scene:setMessageDialogue(text, onClose)
        self.ui = {
            text = text,
            onClose = onClose
        }
    end

    function scene:handleUiInput()
        if not self.ui then
            return false
        end

        if self.ui.aText or self.ui.bText then
            if playdate.buttonJustPressed(playdate.kButtonA) and self.ui.onA then
                self.ui.onA(self)
            elseif playdate.buttonJustPressed(playdate.kButtonB) and self.ui.onB then
                self.ui.onB(self)
            end
            return true
        end

        if playdate.buttonJustPressed(playdate.kButtonA) or playdate.buttonJustPressed(playdate.kButtonB) then
            local onClose = self.ui.onClose
            self.ui = nil
            if onClose then
                onClose(self)
            end
            return true
        end

        return true
    end

    function scene:restoreRoomMusic()
        playFloor2Music(self.musicPath)
    end

    function scene:getNearbyInteractive()
        local candidates = {}

        if not self.state.floor2.profKDone then
            candidates[#candidates + 1] = {
                name = "profK",
                prompt = "A: talk",
                zone = self.npcs.profK.talkZone,
                anchor = { x = 14, y = 182 },
                action = function(selfScene)
                    playFloor2Music(floor2MusicPaths.profK)

                    selfScene:setChoiceDialogue(
                        nil,
                        "hey, why aren't you wearing any shoes?",
                        "who are you?",
                        function(s)
                            s:setChoiceDialogue(
                                "professor k: no hi, how are you? well, it's hot in here and my feet would be sweaty.",
                                "my bad. how are you? who are you?",
                                nil,
                                function(s2)
                                    s2:setChoiceDialogue(
                                        "professor k: call me professor k.",
                                        "nice to meet you, professor k! *is this professor kaltman..?*",
                                        "well, idc, bye.",
                                        function(s3)
                                            s3:setMessageDialogue(
                                                "professor k: you too",
                                                function(s4)
                                                    s4.state.floor2.profKDone = true
                                                    s4:restoreRoomMusic()
                                                end
                                            )
                                        end,
                                        function(s3)
                                            s3:setMessageDialogue(
                                                "professor k: ...uh??",
                                                function(s4)
                                                    s4.state.floor2.profKDone = true
                                                    s4:restoreRoomMusic()
                                                end
                                            )
                                        end,
                                        "B"
                                    )
                                end,
                                nil
                            )
                        end,
                        function(s)
                            s:setChoiceDialogue(
                                "professor k: call me professor k.",
                                    "nice to meet you, professor k! *is this professor kaltman..?*",
                                    "bye.",
                                function(s2)
                                    s2:setMessageDialogue(
                                        "professor k: you too",
                                        function(s3)
                                            s3.state.floor2.profKDone = true
                                            s3:restoreRoomMusic()
                                        end
                                    )
                                end,
                                function(s2)
                                    s2:setMessageDialogue(
                                        "professor k: ...???",
                                        function(s3)
                                            s3.state.floor2.profKDone = true
                                            s3:restoreRoomMusic()
                                        end
                                    )
                                end,
                                "B"
                            )
                        end
                    )
                end
            }
        end

        candidates[#candidates + 1] = {
            name = "tv",
            prompt = "A: Interact",
            zone = floor2Objects.tv.tvInteractZone,
            promptZone = floor2Objects.tv.tvZone,
            action = function(selfScene)
                Game:switchScene(function(nextState)
                    return newTvPlaceholderScene(nextState)
                end)
            end
        }

        local best = nil
        local bestDist = 999

        for i = 1, #candidates do
            local item = candidates[i]
            local d = GameUtils.pointRectDistance(self.player.footX, self.player.footY, item.zone)
            if d < bestDist then
                best = item
                bestDist = d
            end
        end

        if best and bestDist <= 30 then
            return best
        end

        return nil
    end

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 0 or footRect.x + footRect.w > 400 then
            return false
        end

        if footRect.y < floor2Bounds.tvTop or footRect.y + footRect.h > floor2Bounds.tvBottom then
            return false
        end

        return true
    end

    function scene:isBlocked(x, y)
        local footRect = self:getFootRect(x, y)

        if not self:isInsideRoomBounds(footRect) then
            return true
        end

        for i = 1, #self.blockRects do
            if GameUtils.rectsOverlap(footRect, self.blockRects[i]) then
                return true
            end
        end

        if GameUtils.rectsOverlap(footRect, self.npcs.profK.blockRect) then
            return true
        end

        return false
    end

    function scene:checkRoomTransitions()
        if self.player.footX <= 12 then
            Game:switchScene(function(nextState)
                return newFloor2WaitingRoomScene(nextState, "fromTvRoom")
            end)
            return
        end
    end

    function scene:drawPrompt()
        if self.ui then
            return
        end

        local interactive = self:getNearbyInteractive()
        if not interactive then
            return
        end

        drawFloor2PromptNearZone(interactive.prompt, interactive.promptZone or interactive.zone)
    end

    function scene:update(dt)
        if self:handleUiInput() then
            return
        end

        updateSue64Movement(self, dt)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            local interactive = self:getNearbyInteractive()
            if interactive then
                interactive.action(self)
                return
            end
        end

        self:checkRoomTransitions()
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.base then
            self.images.base:draw(0, 0)
        end

        if self.images.boots then
            self.images.boots:draw(0, 0)
        end

        drawNpcImage(self.images.profK, self.npcs.profK.drawX, self.npcs.profK.drawY)
        drawSue64(self)
        self:drawPrompt()
        drawFloor2TalkBox(self.ui)
    end

    return scene
end