local gfx = playdate.graphics

local breakfastMusicPath = "png_and_wavs/morning/tastes_of_stale_cardboard"

local breakfastPaths = {
    mateoIntro = "png_and_wavs/morning/mateo_morning.gif",
    mateoWait = "png_and_wavs/morning/mateo_morning_wait",
    instructions = "png_and_wavs/morning/morning_instruction",

    background = "png_and_wavs/morning/background",
    plate = "png_and_wavs/morning/plate",
    handCursor = "png_and_wavs/morning/hand_cursor",

    chewBar = "png_and_wavs/morning/chew_bar",
    biteBar = "png_and_wavs/morning/bite_bar",
    biteOrStashBar = "png_and_wavs/morning/bite_or_stash_bar",
    bitePointer = "png_and_wavs/morning/marker_bite"
}

local breakfastItems = {
    water = {
        platePath = "png_and_wavs/morning/water",
        bitePath = nil,
        chewPath = "png_and_wavs/morning/water_chew",
        zone = { x = 287, y = 22, w = 63, h = 84 },
        degreesPerFrame = 16,
        chewFrameCount = 6
    },

    sausageLeft = {
        platePath = "png_and_wavs/morning/sausage_left",
        bitePath = "png_and_wavs/morning/sausage_bite.gif",
        chewPath = "png_and_wavs/morning/sausage_chew",
        zone = { x = 203, y = 27, w = 48, h = 66 },
        biteRange = { 0.40, 0.62 },
        degreesPerFrame = 18,
        chewFrameCount = 6
    },

    sausageRight = {
        platePath = "png_and_wavs/morning/sausage_right",
        bitePath = "png_and_wavs/morning/sausage_bite.gif",
        chewPath = "png_and_wavs/morning/sausage_chew",
        zone = { x = 223, y = 40, w = 60, h = 62 },
        biteRange = { 0.40, 0.62 },
        degreesPerFrame = 18,
        chewFrameCount = 6,
        special = "sausageRight"
    },

    egg = {
        platePath = "png_and_wavs/morning/egg",
        bitePath = "png_and_wavs/morning/egg_bite.gif",
        chewPath = "png_and_wavs/morning/egg_chew",
        zone = { x = 178, y = 112, w = 96, h = 63 },
        biteRange = { 0.40, 0.62 },
        degreesPerFrame = 18,
        chewFrameCount = 6
    },

    bread = {
        platePath = "png_and_wavs/morning/bread",
        bitePath = "png_and_wavs/morning/bread_bite.gif",
        chewPath = "png_and_wavs/morning/bread_chew",
        zone = { x = 106, y = 26, w = 71, h = 73 },
        biteRange = { 0.40, 0.62 },
        degreesPerFrame = 18,
        chewFrameCount = 6
    },

    cheese = {
        platePath = "png_and_wavs/morning/cheese",
        bitePath = "png_and_wavs/morning/cheese_bite.gif",
        chewPath = "png_and_wavs/morning/cheese_chew",
        zone = { x = 120, y = 130, w = 63, h = 49 },
        biteRange = { 0.45, 0.56 },
        stashRange = { 0.84, 0.93 },
        degreesPerFrame = 16,
        chewFrameCount = 6,
        special = "cheese"
    }
}

local breakfastItemOrder = {
    "water",
    "sausageLeft",
    "sausageRight",
    "egg",
    "bread",
    "cheese"
}

local function ensureBreakfastState(state)
    if state.breakfast == nil then
        state.breakfast = {
            cheeseStashed = false,
            eaten = {
                water = false,
                sausageLeft = false,
                sausageRight = false,
                egg = false,
                bread = false,
                cheese = false
            }
        }
    end

    if state.breakfast.eaten == nil then
        state.breakfast.eaten = {}
    end

    if state.breakfast.cheeseStashed == nil then
        state.breakfast.cheeseStashed = false
    end

    for i = 1, #breakfastItemOrder do
        local key = breakfastItemOrder[i]
        if state.breakfast.eaten[key] == nil then
            state.breakfast.eaten[key] = false
        end
    end
end

local function isItemCleared(state, key)
    ensureBreakfastState(state)

    if key == "cheese" then
        return state.breakfast.eaten.cheese or state.breakfast.cheeseStashed
    end

    return state.breakfast.eaten[key] == true
end

local function allBreakfastItemsCleared(state)
    ensureBreakfastState(state)

    for i = 1, #breakfastItemOrder do
        if not isItemCleared(state, breakfastItemOrder[i]) then
            return false
        end
    end

    return true
end

local function goToLobbyUnlocked()
    if Game.state.level1 == nil then
        Game.state.level1 = {}
    end

    Game.state.level1.lobbyDoorLocked = false
    Game.state.level1.breakfastDone = true
    Game.state.level1.lampOff = false

    if Game.go then
        Game:go("lobby")
        return
    end

    Game:switchScene(function(nextState)
        return newLevel1Scene(nextState)
    end)
end

local function returnToBreakfastOrFinish()
    if allBreakfastItemsCleared(Game.state) then
        goToLobbyUnlocked()
        return
    end

    Game:switchScene(function(nextState)
        return newBreakfastScene(nextState)
    end)
end

local function loadBiteVisual(path)
    if path == nil then
        return nil
    end

    if string.sub(path, -4) == ".gif" then
        return {
            kind = "anim",
            anim = GameUtils.loadAnim(path, 10, true, 1.0)
        }
    end

    return {
        kind = "image",
        image = GameUtils.loadImage(path)
    }
end

local function updateBiteVisual(biteVisual, dt)
    if biteVisual and biteVisual.kind == "anim" and biteVisual.anim then
        biteVisual.anim:update(dt)
    end
end

local function drawBiteVisual(biteVisual)
    if biteVisual == nil then
        return
    end

    if biteVisual.kind == "anim" and biteVisual.anim then
        biteVisual.anim:draw(0, 0)
        return
    end

    if biteVisual.kind == "image" and biteVisual.image then
        biteVisual.image:draw(0, 0)
    end
end

local function loadChewFrames(path, frameCount)
    local image = GameUtils.loadImage(path)
    if not image then
        return {
            kind = "missing",
            frameCount = 1
        }
    end

    local w, h = image:getSize()

    if w > 450 then
        local count = frameCount or 6
        local frameWidth = math.floor(w / count)

        return {
            kind = "strip",
            image = image,
            frameCount = count,
            frameWidth = frameWidth,
            height = h
        }
    end

    return {
        kind = "image",
        image = image,
        frameCount = 1
    }
end

local function drawChewFrame(frameSet, frameIndex)
    if frameSet == nil then
        return
    end

    if frameSet.kind == "strip" then
        local x = -((frameIndex - 1) * frameSet.frameWidth)
        frameSet.image:draw(x, 0)
        return
    end

    if frameSet.kind == "image" and frameSet.image then
        frameSet.image:draw(0, 0)
    end
end

local function drawBitePointer(x, y)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillCircleAtPoint(x, y, 3)
    gfx.setColor(gfx.kColorBlack)
end

local function pointerHitRange(pointerT, rangeData)
    if rangeData == nil then
        return false
    end

    return pointerT >= rangeData[1] and pointerT <= rangeData[2]
end

local function drawFillWhiteImageCentered(image)
    if not image then
        return
    end

    local w, h = image:getSize()
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    image:draw(math.floor((400 - w) / 2), math.floor((240 - h) / 2))
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

local function drawChewMeter(barImage, progress)
    local inner = {
        x = 39,
        y = 27,
        w = 36,
        h = 188
    }

    local clamped = GameUtils.clamp(progress, 0, 1)
    local fillHeight = math.floor(inner.h * clamped + 0.5)

    if fillHeight > 0 then
        local fillY = inner.y + inner.h - fillHeight

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRoundRect(inner.x, fillY, inner.w, fillHeight, 6)
        gfx.setColor(gfx.kColorBlack)
    end

    if barImage then
        barImage:draw(0, 0)
    end
end

function newBreakfastMateoScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = breakfastMusicPath

    ensureBreakfastState(scene.state)

    scene.introAnim = GameUtils.loadAnim(breakfastPaths.mateoIntro, 10, false, 0.5)
    scene.waitImage = GameUtils.loadImage(breakfastPaths.mateoWait)
    scene.phase = "intro"

    function scene:update(dt)
        if GameUtils.skipComboJustPressed() then
            if self.phase == "intro" then
                self.phase = "wait"
                return
            end

            if self.phase == "wait" then
                Game:switchScene(function(nextState)
                    return newMorningInstructionsScene(nextState)
                end)
                return
            end
        end

        if self.phase == "intro" then
            if self.introAnim then
                self.introAnim:update(dt)

                if self.introAnim.finished then
                    self.phase = "wait"
                end
            end
            return
        end

        if self.phase == "wait" then
            if playdate.buttonJustPressed(playdate.kButtonA) then
                Game:switchScene(function(nextState)
                    return newMorningInstructionsScene(nextState)
                end)
            end
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.phase == "intro" then
            if self.introAnim then
                self.introAnim:draw(0, 0)
            end
            return
        end

        if self.waitImage then
            self.waitImage:draw(0, 0)
        end
    end

    return scene
end

function newMorningInstructionsScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = breakfastMusicPath
    scene.image = GameUtils.loadImage(breakfastPaths.instructions)

    function scene:update(dt)
        if GameUtils.skipComboJustPressed() or playdate.buttonJustPressed(playdate.kButtonA) then
            Game:switchScene(function(nextState)
                return newBreakfastScene(nextState)
            end)
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.image then
            self.image:draw(0, 0)
        end
    end

    return scene
end

function newBreakfastScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = breakfastMusicPath

    ensureBreakfastState(scene.state)

    scene.images = {
        background = GameUtils.loadImage(breakfastPaths.background),
        plate = GameUtils.loadImage(breakfastPaths.plate),
        handCursor = GameUtils.loadImage(breakfastPaths.handCursor)
    }

    scene.itemImages = {}
    for i = 1, #breakfastItemOrder do
        local key = breakfastItemOrder[i]
        scene.itemImages[key] = GameUtils.loadImage(breakfastItems[key].platePath)
    end

    scene.cursor = {
        x = 200,
        y = 170,
        speed = 3
    }

    function scene:getHoveredItem()
        for i = 1, #breakfastItemOrder do
            local key = breakfastItemOrder[i]
            local item = breakfastItems[key]

            if not isItemCleared(self.state, key) then
                if self.cursor.x >= item.zone.x and self.cursor.x < item.zone.x + item.zone.w and
                   self.cursor.y >= item.zone.y and self.cursor.y < item.zone.y + item.zone.h then
                    return key
                end
            end
        end

        return nil
    end

    function scene:update(dt)
        if playdate.buttonIsPressed(playdate.kButtonLeft) then
            self.cursor.x = self.cursor.x - self.cursor.speed
        end

        if playdate.buttonIsPressed(playdate.kButtonRight) then
            self.cursor.x = self.cursor.x + self.cursor.speed
        end

        if playdate.buttonIsPressed(playdate.kButtonUp) then
            self.cursor.y = self.cursor.y - self.cursor.speed
        end

        if playdate.buttonIsPressed(playdate.kButtonDown) then
            self.cursor.y = self.cursor.y + self.cursor.speed
        end

        self.cursor.x = GameUtils.clamp(self.cursor.x, 0, 399)
        self.cursor.y = GameUtils.clamp(self.cursor.y, 0, 239)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            local hovered = self:getHoveredItem()
            if hovered ~= nil then
                local item = breakfastItems[hovered]

                if item.bitePath == nil then
                    Game:switchScene(function(nextState)
                        return newBreakfastChewScene(nextState, hovered)
                    end)
                    return
                end

                Game:switchScene(function(nextState)
                    return newBreakfastBiteScene(nextState, hovered)
                end)
            end
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.background then
            self.images.background:draw(0, 0)
        end

        if self.images.plate then
            self.images.plate:draw(0, 0)
        end

        if not isItemCleared(self.state, "water") and self.itemImages.water then
            self.itemImages.water:draw(0, 0)
        end

        if not isItemCleared(self.state, "sausageLeft") and self.itemImages.sausageLeft then
            self.itemImages.sausageLeft:draw(0, 0)
        end

        if not isItemCleared(self.state, "sausageRight") and self.itemImages.sausageRight then
            self.itemImages.sausageRight:draw(0, 0)
        end

        if not isItemCleared(self.state, "egg") and self.itemImages.egg then
            self.itemImages.egg:draw(0, 0)
        end

        if not isItemCleared(self.state, "bread") and self.itemImages.bread then
            self.itemImages.bread:draw(0, 0)
        end

        if not isItemCleared(self.state, "cheese") and self.itemImages.cheese then
            self.itemImages.cheese:draw(0, 0)
        end

        if self.images.handCursor then
            local cursorBBox = { x = 312, y = 111, w = 19, h = 20 }
            local targetX = math.floor(self.cursor.x - 6)
            local targetY = math.floor(self.cursor.y - 6)
            GameUtils.drawShiftedFullScreenImage(self.images.handCursor, cursorBBox, targetX, targetY)
        else
            gfx.setColor(gfx.kColorWhite)
            gfx.fillCircleAtPoint(self.cursor.x, self.cursor.y, 4)
            gfx.setColor(gfx.kColorBlack)
        end
    end

    return scene
end

function newBreakfastBiteScene(state, itemKey)
    local scene = {}

    scene.state = state
    scene.musicPath = breakfastMusicPath
    scene.itemKey = itemKey
    scene.item = breakfastItems[itemKey]

    scene.images = {
        bite = loadBiteVisual(scene.item.bitePath),
        bar = GameUtils.loadImage(scene.item.special == "cheese" and breakfastPaths.biteOrStashBar or breakfastPaths.biteBar)
    }

    scene.pointerT = 0.5
    scene.pointerDir = 1
    scene.pointerSpeed = 1.15

    scene.barInterior = {
        x = 78,
        y = 201,
        w = 243,
        h = 14
    }

    scene.pointerY = 208

    function scene:update(dt)
        updateBiteVisual(self.images.bite, dt)

        self.pointerT = self.pointerT + self.pointerDir * self.pointerSpeed * dt

        if self.pointerT >= 1 then
            self.pointerT = 1
            self.pointerDir = -1
        elseif self.pointerT <= 0 then
            self.pointerT = 0
            self.pointerDir = 1
        end

        if GameUtils.skipComboJustPressed() then
            if self.item.special == "cheese" then
                self.state.breakfast.cheeseStashed = true
                returnToBreakfastOrFinish()
            else
                Game:switchScene(function(nextState)
                    return newBreakfastChewScene(nextState, self.itemKey)
                end)
            end
            return
        end

        if playdate.buttonJustPressed(playdate.kButtonB) then
            Game:switchScene(function(nextState)
                return newBreakfastScene(nextState)
            end)
            return
        end

        if playdate.buttonJustPressed(playdate.kButtonA) then
            if self.item.special == "cheese" and pointerHitRange(self.pointerT, self.item.stashRange) then
                self.state.breakfast.cheeseStashed = true
                returnToBreakfastOrFinish()
                return
            end

            if pointerHitRange(self.pointerT, self.item.biteRange) then
                Game:switchScene(function(nextState)
                    return newBreakfastChewScene(nextState, self.itemKey)
                end)
            end
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        drawBiteVisual(self.images.bite)

        if self.images.bar then
            self.images.bar:draw(0, 0)
        end

        local pointerX = math.floor(self.barInterior.x + self.pointerT * self.barInterior.w)
        drawBitePointer(pointerX, self.pointerY)
    end

    return scene
end

function newBreakfastChewScene(state, itemKey)
    local scene = {}

    scene.state = state
    scene.musicPath = breakfastMusicPath
    scene.itemKey = itemKey
    scene.item = breakfastItems[itemKey]

    scene.images = {
        demonOverlay = GameUtils.loadImage("png_and_wavs/0_universal_sprites/demon_64x64"),
        markerOverlay = GameUtils.loadImage(breakfastPaths.bitePointer),
        chewBar = GameUtils.loadImage(breakfastPaths.chewBar)
    }

    scene.chewFrames = loadChewFrames(scene.item.chewPath, scene.item.chewFrameCount or 6)
    scene.frameIndex = 1
    scene.crankAccumulator = 0
    scene.degreesPerFrame = scene.item.degreesPerFrame or 20

    scene.demonTimer = 0
    scene.markerMode = false
    scene.shockTimer = 0
    scene.specialTriggered = false

    function scene:leaveUneaten()
        Game:switchScene(function(nextState)
            return newBreakfastScene(nextState)
        end)
    end

    function scene:finishItem()
        self.state.breakfast.eaten[self.itemKey] = true
        returnToBreakfastOrFinish()
    end

    function scene:getChewProgress()
        if self.chewFrames.frameCount <= 1 then
            return 1
        end

        return (self.frameIndex - 1) / (self.chewFrames.frameCount - 1)
    end

    function scene:advanceChewByCrank()
        local crankChange = math.abs(playdate.getCrankChange())
        self.crankAccumulator = self.crankAccumulator + crankChange

        while self.crankAccumulator >= self.degreesPerFrame do
            self.crankAccumulator = self.crankAccumulator - self.degreesPerFrame

            if self.frameIndex < self.chewFrames.frameCount then
                self.frameIndex = self.frameIndex + 1
            else
                return true
            end
        end

        return false
    end

    function scene:updateNormalChew(dt)
        if GameUtils.skipComboJustPressed() then
            self:finishItem()
            return
        end

        if playdate.buttonJustPressed(playdate.kButtonB) then
            self:leaveUneaten()
            return
        end

        if self:advanceChewByCrank() then
            self:finishItem()
        end
    end

    function scene:updateSausageRight(dt)
        if GameUtils.skipComboJustPressed() then
            self:finishItem()
            return
        end

        if self.shockTimer > 0 then
            self.shockTimer = self.shockTimer - dt

            if self.shockTimer <= 0 then
                self:finishItem()
            end

            return
        end

        if self.demonTimer > 0 then
            self.demonTimer = self.demonTimer - dt

            if self.demonTimer <= 0 then
                self.demonTimer = 0
                self.markerMode = true
            end

            return
        end

        local crankChange = math.abs(playdate.getCrankChange())

        if not self.specialTriggered then
            if playdate.buttonJustPressed(playdate.kButtonB) then
                self:leaveUneaten()
                return
            end

            self.crankAccumulator = self.crankAccumulator + crankChange

            while self.crankAccumulator >= self.degreesPerFrame do
                self.crankAccumulator = self.crankAccumulator - self.degreesPerFrame

                if self.frameIndex < self.chewFrames.frameCount then
                    self.frameIndex = self.frameIndex + 1
                end

                self.specialTriggered = true
                self.demonTimer = 0.5
                return
            end

            return
        end

        if self.markerMode then
            if crankChange > 0 then
                self.shockTimer = 1.0
                return
            end

            if playdate.buttonJustPressed(playdate.kButtonB) then
                self:leaveUneaten()
                return
            end
        end
    end

    function scene:update(dt)
        if self.item.special == "sausageRight" then
            self:updateSausageRight(dt)
            return
        end

        self:updateNormalChew(dt)
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.shockTimer > 0 then
            local font = Game.fonts.dialog or gfx.getSystemFont()
            local text = "!!!"
            local w = font:getTextWidth(text)
            local x = math.floor((400 - w) / 2)
            local y = math.floor((240 - font:getHeight()) / 2)

            gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
            font:drawText(text, x, y)
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
            return
        end

        drawChewFrame(self.chewFrames, self.frameIndex)

        if self.itemKey == "water" then
            drawChewMeter(nil, self:getChewProgress())
        else
            drawChewMeter(self.images.chewBar, self:getChewProgress())
        end

        if self.item.special == "sausageRight" then
            if self.demonTimer > 0 then
                drawFillWhiteImageCentered(self.images.demonOverlay)
            elseif self.markerMode then
                drawFillWhiteImageCentered(self.images.markerOverlay)
            end
        end
    end

    return scene
end