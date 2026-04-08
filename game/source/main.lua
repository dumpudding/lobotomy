function playdate.update()
end

import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "level_1"
import "trash_bin"
import "brain_mini_game"

local gfx = playdate.graphics
local snd = playdate.sound

math.randomseed(playdate.getSecondsSinceEpoch())

GameUtils = {}

function GameUtils.isSkipComboDown()
    return
        playdate.buttonIsPressed(playdate.kButtonA) and
        playdate.buttonIsPressed(playdate.kButtonB) and
        playdate.buttonIsPressed(playdate.kButtonUp) and
        playdate.buttonIsPressed(playdate.kButtonRight)
end
function GameUtils.skipComboJustPressed()
    local down = GameUtils.isSkipComboDown()
    local fired = down and not Game.debug.skipComboWasDown
    Game.debug.skipComboWasDown = down
    return fired
end

function GameUtils.clamp(v, lo, hi)
    if v < lo then
        return lo
    end

    if v > hi then
        return hi
    end

    return v
end

function GameUtils.rectsOverlap(a, b)
    return a.x < b.x + b.w and a.x + a.w > b.x and a.y < b.y + b.h and a.y + a.h > b.y
end

function GameUtils.pointRectDistance(px, py, r)
    local cx = math.max(r.x, math.min(px, r.x + r.w))
    local cy = math.max(r.y, math.min(py, r.y + r.h))
    local dx = px - cx
    local dy = py - cy
    return math.sqrt(dx * dx + dy * dy)
end

function GameUtils.loadImage(path)
    local image, err = gfx.image.new(path)
    if not image then
        print("image load failed: " .. path .. " :: " .. tostring(err))
    end
    return image
end

function GameUtils.loadAnim(path, fps, loop, speedScale)
    local shouldLoop = true
    if loop == false then
        shouldLoop = false
    end

    local animSpeed = speedScale or 0.5
    local frames, err = gfx.imagetable.new(path)

    if frames and #frames > 0 then
        return {
            frames = frames,
            frameCount = #frames,
            fps = fps or 8,
            frameIndex = 1,
            accumulator = 0,
            loop = shouldLoop,
            finished = false,
            speedScale = animSpeed,

            reset = function(self)
                self.frameIndex = 1
                self.accumulator = 0
                self.finished = false
            end,

            update = function(self, dt)
                if self.finished then
                    return
                end

                if self.frameCount <= 1 then
                    if not self.loop then
                        self.finished = true
                    end
                    return
                end

                self.accumulator = self.accumulator + dt
                local effectiveFps = self.fps * self.speedScale
                local step = 1 / effectiveFps

                while self.accumulator >= step do
                    self.accumulator = self.accumulator - step

                    if self.frameIndex < self.frameCount then
                        self.frameIndex = self.frameIndex + 1
                    else
                        if self.loop then
                            self.frameIndex = 1
                        else
                            self.frameIndex = self.frameCount
                            self.finished = true
                            break
                        end
                    end
                end
            end,

            getFrame = function(self)
                return self.frames:getImage(self.frameIndex)
            end,

            draw = function(self, x, y)
                self.frames:drawImage(self.frameIndex, x or 0, y or 0)
            end,

            drawFaded = function(self, x, y, alpha)
                local frame = self.frames:getImage(self.frameIndex)
                if frame then
                    frame:drawFaded(x or 0, y or 0, alpha, gfx.image.kDitherTypeBayer8x8)
                end
            end
        }
    end

    local fallbackImage = GameUtils.loadImage(path)

    return {
        image = fallbackImage,
        frameCount = fallbackImage and 1 or 0,
        fps = fps or 8,
        frameIndex = 1,
        accumulator = 0,
        loop = shouldLoop,
        finished = false,
        speedScale = animSpeed,

        reset = function(self)
            self.frameIndex = 1
            self.accumulator = 0
            self.finished = false
        end,

        update = function(self, dt)
            if not self.loop then
                self.finished = true
            end
        end,

        getFrame = function(self)
            return self.image
        end,

        draw = function(self, x, y)
            if self.image then
                self.image:draw(x or 0, y or 0)
            else
                gfx.drawText("missing: " .. path, 8, 8)
            end
        end,

        drawFaded = function(self, x, y, alpha)
            if self.image then
                self.image:drawFaded(x or 0, y or 0, alpha, gfx.image.kDitherTypeBayer8x8)
            else
                gfx.drawText("missing: " .. path, 8, 8)
            end
        end
    }
end

function GameUtils.drawShiftedFullScreenImage(image, bbox, drawX, drawY)
    if not image or not bbox then
        return
    end

    image:draw(drawX - bbox.x, drawY - bbox.y)
end

function GameUtils.wrapText(text, font, maxWidth)
    local lines = {}
    local current = ""

    for word in string.gmatch(text, "%S+") do
        local candidate = current == "" and word or (current .. " " .. word)
        if font:getTextWidth(candidate) <= maxWidth then
            current = candidate
        else
            if current ~= "" then
                lines[#lines + 1] = current
            end

            if font:getTextWidth(word) <= maxWidth then
                current = word
            else
                local chunk = ""
                for i = 1, #word do
                    local c = string.sub(word, i, i)
                    local candidateChunk = chunk .. c
                    if font:getTextWidth(candidateChunk) <= maxWidth then
                        chunk = candidateChunk
                    else
                        if chunk ~= "" then
                            lines[#lines + 1] = chunk
                        end
                        chunk = c
                    end
                end
                current = chunk
            end
        end
    end

    if current ~= "" then
        lines[#lines + 1] = current
    end

    return lines
end

function GameUtils.makeDialogue(text)
    local font = Game.fonts.dialog or gfx.getSystemFont()
    local maxWidth = 186
    local maxLines = 3
    local rawLines = GameUtils.wrapText(text, font, maxWidth)
    local pages = {}
    local index = 1

    while index <= #rawLines do
        local lines = {}
        for _ = 1, maxLines do
            if index <= #rawLines then
                lines[#lines + 1] = rawLines[index]
                index = index + 1
            end
        end

        pages[#pages + 1] = lines
    end

    for i = 1, #pages do
        if i < #pages then
            local last = pages[i][#pages[i]] or ""
            pages[i][#pages[i]] = last .. "[...]"
        end

        if i > 1 and pages[i][1] then
            pages[i][1] = "[...] " .. pages[i][1]
        end
    end

    for i = 1, #pages do
        pages[i] = table.concat(pages[i], "\n")
    end

    return {
        pages = pages,
        index = 1
    }
end

function GameUtils.advanceDialogue(dialogue)
    if not dialogue then
        return true
    end

    if dialogue.index < #dialogue.pages then
        dialogue.index = dialogue.index + 1
        return false
    end

    return true
end

function GameUtils.drawDialogue(dialogue)
    if not dialogue then
        return
    end

    gfx.setColor(gfx.kColorWhite)
    gfx.fillRoundRect(8, 176, 216, 56, 4)
    gfx.setColor(gfx.kColorBlack)
    gfx.drawRoundRect(8, 176, 216, 56, 4)

    local font = Game.fonts.dialog or gfx.getSystemFont()
    font:drawText(dialogue.pages[dialogue.index], 16, 186)
end

function GameUtils.makeHeartImage()
    local image = gfx.image.new(9, 8, gfx.kColorClear)
    gfx.pushContext(image)
        gfx.setColor(gfx.kColorBlack)
        gfx.fillRect(1, 1, 2, 2)
        gfx.fillRect(5, 1, 2, 2)
        gfx.fillRect(0, 2, 8, 2)
        gfx.fillRect(1, 4, 6, 1)
        gfx.fillRect(2, 5, 4, 1)
        gfx.fillRect(3, 6, 2, 1)
    gfx.popContext()
    return image
end

function GameUtils.drawHearts(count)
    local image = Game.assets.heart
    if not image then
        return
    end

    local w, h = image:getSize()
    local spacing = 4
    local total = count * w + math.max(0, count - 1) * spacing
    local startX = math.floor((400 - total) / 2)

    for i = 1, count do
        image:draw(startX + (i - 1) * (w + spacing), 8)
    end
end

function GameUtils.drawCrosshair(x, y)
    gfx.drawLine(x - 1, y, x + 1, y)
    gfx.drawLine(x, y - 1, x, y + 1)
end

function GameUtils.drawTextWithUnderlay(text, x, y, font)
    font = font or Game.fonts.prompt or gfx.getSystemFont()

    local padX = 2
    local padY = 1
    local w = font:getTextWidth(text)
    local h = font:getHeight()

    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(x - padX, y - padY, w + padX * 2, h + padY * 2)

    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    font:drawText(text, x, y)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)

    gfx.setColor(gfx.kColorBlack)
end

Game = {
    scene = nil,
    nextSceneFactory = nil,
    fadeAlpha = 1,
    fadeDir = -1,
    fadeSpeed = 0.08,
    lastTimeMs = playdate.getCurrentTimeMilliseconds(),

    music = {
        current = nil,
        currentPath = nil,
        next = nil,
        nextPath = nil,
        t = 1,
        speed = 0.07
    },

    fonts = {},
    assets = {},
        
    debug = {
        skipComboWasDown = false
    },

    state = {
        heldItem = nil,
        lobbyTrashPile = false,
        replaceSueWithDemon = false,
        level1 = {
            lampOff = false
        },
        trashItems = {
            needle = "bin",
            gloves = "bin",
            vial = "bin",
            scissors = "bin",
            gauze = "bin"
        }
    }
}

function Game:loadFonts()
    local promptFont = nil

    local customFontPath = "fonts/Bookxel_16"

    promptFont = gfx.font.new(customFontPath)

    if promptFont then
        promptFont:setLeading(0)
        self.fonts.prompt = promptFont
        self.fonts.dialog = promptFont
        print("loaded custom font: " .. customFontPath)
    end
end

function Game:loadSharedAssets()
    self.assets.heart = GameUtils.makeHeartImage()
end

function Game:playMusic(path)
    local music = self.music

    if path == nil then
        if music.current then
            music.current:stop()
        end

        if music.next then
            music.next:stop()
        end

        music.current = nil
        music.currentPath = nil
        music.next = nil
        music.nextPath = nil
        music.t = 1
        return
    end

    if music.currentPath == path and music.next == nil then
        return
    end

    local player = snd.fileplayer.new(path)
    if not player then
        print("music load failed: " .. tostring(path))
        return
    end

    if music.next then
        music.next:stop()
    end

    player:setVolume(0)
    local ok, err = player:play(0)
    if ok == false then
        print("music play failed: " .. tostring(path) .. " :: " .. tostring(err))
        return
    end

    music.next = player
    music.nextPath = path
    music.t = 0
end

function Game:updateMusic()
    local music = self.music
    if not music.next then
        return
    end

    music.t = GameUtils.clamp(music.t + music.speed, 0, 1)

    if music.current then
        music.current:setVolume(1 - music.t)
    end

    music.next:setVolume(music.t)

    if music.t >= 1 then
        if music.current then
            music.current:stop()
        end

        music.current = music.next
        music.currentPath = music.nextPath
        music.next = nil
        music.nextPath = nil
    end
end

function Game:setScene(factory)
    if self.scene and self.scene.leave then
        self.scene:leave(self.state)
    end

    self.scene = factory(self.state)

    if self.scene and self.scene.enter then
        self.scene:enter(self.state)
    end

    if self.scene and self.scene.musicPath then
        self:playMusic(self.scene.musicPath)
    else
        self:playMusic(nil)
    end
end

function Game:switchScene(factory)
    self:setScene(factory)
end

function Game:dropHeldItemFromLobby()
    local held = self.state.heldItem
    if held == nil then
        return
    end

    self.state.heldItem = nil

    if self.state.trashItems[held] then
        self.state.trashItems[held] = "gone"
    end
end

local lobbyObjectBBoxes = {
    bed = { x = 219, y = 58, w = 70, h = 48 },
    lamp = { x = 115, y = 39, w = 32, h = 45 },
    window = { x = 157, y = 32, w = 88, h = 21 },
    table = { x = 265, y = 106, w = 31, h = 24 },
    trash_bin = { x = 169, y = 180, w = 26, h = 26 },
    plant = { x = 261, y = 181, w = 25, h = 25 },
    door = { x = 120, y = 201, w = 44, h = 9 },
    trash_pile = { x = 198, y = 186, w = 22, h = 19 }
}

function newLobbyScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/lobby/the_color_of_smog"

    scene.images = {
        base = GameUtils.loadImage("png_and_wavs/lobby/lobby_empty"),
        borders = GameUtils.loadImage("png_and_wavs/lobby/room_wall_borders"),
        lamp = GameUtils.loadImage("png_and_wavs/lobby/lamp"),
        bed = GameUtils.loadImage("png_and_wavs/lobby/bed"),
        window = GameUtils.loadImage("png_and_wavs/lobby/window"),
        table = GameUtils.loadImage("png_and_wavs/lobby/table"),
        trashBin = GameUtils.loadImage("png_and_wavs/lobby/trash_bin"),
        plant = GameUtils.loadImage("png_and_wavs/lobby/plant"),
        door = GameUtils.loadImage("png_and_wavs/lobby/door"),
        trashPile = GameUtils.loadImage("png_and_wavs/lobby/trash_pile"),
        sue = GameUtils.loadImage("png_and_wavs/lobby/sue_32x40") or GameUtils.loadImage("png_and_wavs/0_universal_sprites/sue_32x40"),
        demon = GameUtils.loadImage("png_and_wavs/lobby/demon_64x64") or GameUtils.loadImage("png_and_wavs/0_universal_sprites/demon_64x64"),
        needle = GameUtils.loadImage("png_and_wavs/trash_can/needle")
    }

    scene.player = {
        footX = 200,
        footY = 84,
        speed = 2
    }

    scene.dialogue = nil

    scene.blockRects = {
        lobbyObjectBBoxes.bed,
        lobbyObjectBBoxes.lamp,
        lobbyObjectBBoxes.table,
        lobbyObjectBBoxes.trash_bin,
        lobbyObjectBBoxes.plant,
        lobbyObjectBBoxes.door
    }

    scene.interactives = {
        {
            name = "window",
            prompt = "A: Look Outside",
            zone = { x = 154, y = 50, w = 94, h = 24 },
            anchor = { x = 250, y = 52 },
            action = function(self)
                Game:switchScene(function(nextState)
                    return newWindowScene(nextState)
                end)
            end
        },
        {
            name = "trash_bin",
            prompt = "A: Inspect Bin",
            zone = { x = 163, y = 174, w = 38, h = 38 },
            anchor = { x = 197, y = 188 },
            action = function(self)
                Game:switchScene(function(nextState)
                    return newTrashScene(nextState)
                end)
            end
        },
        {
            name = "lamp",
            prompt = "A: Inspect Lamp",
            zone = { x = 109, y = 37, w = 42, h = 52 },
            anchor = { x = 150, y = 48 },
            action = function(self)
                self.dialogue = GameUtils.makeDialogue("not sharp enough…")
            end
        },
        {
            name = "bed",
            prompt = "A: Inspect Bed",
            zone = { x = 213, y = 94, w = 82, h = 18 },
            anchor = { x = 292, y = 96 },
            action = function(self)
                self.dialogue = GameUtils.makeDialogue("im not sleepy. not yet.")
            end
        },
        {
            name = "door",
            prompt = "A: Inspect Door",
            zone = { x = 114, y = 196, w = 56, h = 18 },
            anchor = { x = 82, y = 194 },
            action = function(self)
                self.dialogue = GameUtils.makeDialogue("the nurses would yell at me to lie down…")
            end
        }
    }

    function scene:getFootRect(x, y)
        return {
            x = math.floor(x - 5),
            y = math.floor(y - 2),
            w = 10,
            h = 2
        }
    end

    function scene:isOnFloor(footRect)
        if not self.images.base then
            return true
        end

        for sx = footRect.x, footRect.x + footRect.w - 1, 2 do
            for sy = footRect.y, footRect.y + footRect.h - 1 do
                if sx < 0 or sx >= 400 or sy < 0 or sy >= 240 then
                    return false
                end

                local sample = self.images.base:sample(sx, sy)
                if sample ~= gfx.kColorWhite then
                    return false
                end
            end
        end

        return true
    end

    function scene:isBlocked(x, y)
        local footRect = self:getFootRect(x, y)

        if not self:isOnFloor(footRect) then
            return true
        end

        for i = 1, #self.blockRects do
            if GameUtils.rectsOverlap(footRect, self.blockRects[i]) then
                return true
            end
        end

        if self.state.lobbyTrashPile and GameUtils.rectsOverlap(footRect, lobbyObjectBBoxes.trash_pile) then
            return true
        end

        return false
    end

    function scene:getNearbyInteractive()
        local best = nil
        local bestDist = 999

        for i = 1, #self.interactives do
            local item = self.interactives[i]
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

    function scene:updateMovement()
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

        if dx ~= 0 and dy ~= 0 then
            dx = dx * 0.7071
            dy = dy * 0.7071
        end

        local nextX = self.player.footX + dx * self.player.speed
        if not self:isBlocked(nextX, self.player.footY) then
            self.player.footX = nextX
        end

        local nextY = self.player.footY + dy * self.player.speed
        if not self:isBlocked(self.player.footX, nextY) then
            self.player.footY = nextY
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

        self:updateMovement()

        if self.state.heldItem and playdate.buttonJustPressed(playdate.kButtonB) then
            Game:dropHeldItemFromLobby()
            return
        end

        if playdate.buttonJustPressed(playdate.kButtonA) then
            local interactive = self:getNearbyInteractive()
            if interactive then
                interactive.action(self)
                return
            end

            if self.state.heldItem == "needle" then
                Game:switchScene(function(nextState)
                    return newBrainMiniGameScene(nextState)
                end)
                return
            end
        end
    end

    function scene:drawPrompt()
    local interactive = self:getNearbyInteractive()
    local font = Game.fonts.prompt or gfx.getSystemFont()

    local safeRect = {
        x = 112,
        y = 26,
        w = 176,
        h = 182
    }

    local function drawClampedPrompt(text, anchorX, anchorY)
        local padX = 2
        local padY = 1
        local w = font:getTextWidth(text)
        local h = font:getHeight()

        local x = GameUtils.clamp(anchorX, safeRect.x + padX, safeRect.x + safeRect.w - w - padX)
        local y = GameUtils.clamp(anchorY, safeRect.y + padY, safeRect.y + safeRect.h - h - padY)

        GameUtils.drawTextWithUnderlay(text, x, y, font)
    end

    if interactive then
        drawClampedPrompt(interactive.prompt, interactive.anchor.x, interactive.anchor.y)
    elseif self.state.heldItem == "needle" then
        drawClampedPrompt("A: use", 118, 30)
        drawClampedPrompt("B: drop", 118, 44)
    elseif self.state.heldItem then
        drawClampedPrompt("holding", 118, 30)
    end
    end

    function scene:drawPlayer()
        local image = self.state.replaceSueWithDemon and self.images.demon or self.images.sue
        if not image then
            return
        end

        local w, h = image:getSize()
        image:draw(math.floor(self.player.footX - w / 2), math.floor(self.player.footY - h))

        if self.state.heldItem == "needle" and self.images.needle then
            local bbox = { x = 221, y = 158, w = 31, h = 30 }
            local targetX = math.floor(self.player.footX - math.floor(bbox.w / 2))
            local targetY = math.floor(self.player.footY - h + 10)
            GameUtils.drawShiftedFullScreenImage(self.images.needle, bbox, targetX, targetY)
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.base then self.images.base:draw(0, 0) end
        if self.images.borders then self.images.borders:draw(0, 0) end
        if self.images.bed then self.images.bed:draw(0, 0) end
        if self.images.lamp then self.images.lamp:draw(0, 0) end
        if self.images.window then self.images.window:draw(0, 0) end
        if self.images.table then self.images.table:draw(0, 0) end
        if self.images.trashBin then self.images.trashBin:draw(0, 0) end
        if self.images.plant then self.images.plant:draw(0, 0) end
        if self.images.door then self.images.door:draw(0, 0) end

        if self.state.lobbyTrashPile and self.images.trashPile then
            self.images.trashPile:draw(0, 0)
        end

        self:drawPlayer()
        self:drawPrompt()
        GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end

function newWindowScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/window_view/a_gust_of_odd_wind"
    scene.windowAnim = GameUtils.loadAnim("png_and_wavs/window_view/window_animated.gif", 10, true)
    scene.dialogue = GameUtils.makeDialogue("...")

    function scene:update(dt)
        if self.windowAnim then
            self.windowAnim:update(dt)
        end

        if playdate.buttonJustPressed(playdate.kButtonA) and self.dialogue then
            if GameUtils.advanceDialogue(self.dialogue) then
                self.dialogue = nil
            end
        end

        if playdate.buttonJustPressed(playdate.kButtonB) then
            Game:switchScene(function(nextState)
                return newLobbyScene(nextState)
            end)
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.windowAnim then
            self.windowAnim:draw(0, 0)
        end

        GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end

Game:loadFonts()
Game:loadSharedAssets()
Game:setScene(function(state)
    return newTitleScene(state)
end)

function playdate.update()
    local now = playdate.getCurrentTimeMilliseconds()
    local dt = (now - Game.lastTimeMs) / 1000
    Game.lastTimeMs = now

    if Game.scene and Game.scene.update then
        Game.scene:update(dt)
    end

    playdate.timer.updateTimers()
    Game:updateMusic()

    if Game.scene and Game.scene.draw then
        Game.scene:draw()
    end
end