import "CoreLibs/graphics"
import "CoreLibs/timer"
import "CoreLibs/crank"

import "1_sue_room"
import "1-1_breakfast"
import "2_floor"
import "3_floor"
import "3-1_trash_bin"
import "4_brain_mini_game"
import "5_ending"

import "0_title_screen"

local gfx = playdate.graphics
local snd = playdate.sound
local unpackFn = table.unpack or unpack

math.randomseed(playdate.getSecondsSinceEpoch())

GameUtils = {}

local pd <const> = playdate

storyFlags = storyFlags or {}
storyFlags.breakfastDone = storyFlags.breakfastDone or false
storyFlags.breakfastSkipped = storyFlags.breakfastSkipped or false
storyFlags.lobbyDoorUnlocked = storyFlags.lobbyDoorUnlocked or false

local afterBreakfastSkipHoldFrames = 0
local afterBreakfastSkipTriggered = false
local AFTER_BREAKFAST_SKIP_FRAMES <const> = 10

local function skipToAfterBreakfastComboHeld()
    return pd.buttonIsPressed(pd.kButtonA)
        and pd.buttonIsPressed(pd.kButtonB)
        and pd.buttonIsPressed(pd.kButtonLeft)
        and pd.buttonIsPressed(pd.kButtonDown)
end

local function applyAfterBreakfastStoryState()
    storyFlags.breakfastDone = true
    storyFlags.breakfastSkipped = true
    storyFlags.lobbyDoorUnlocked = true

    breakfastDone = true
    breakfastCompleted = true
    lobbyDoorUnlocked = true
    doorUnlocked = true

    lampInteractable = false
    windowInteractable = false
    bedInteractable = false

    canInteractLamp = false
    canInteractWindow = false
    canInteractBed = false

    showLampOffDither = false
    lampOffDitherVisible = false

    if playerState then
        playerState.breakfastDone = true
        playerState.lobbyDoorUnlocked = true
    end
end

local function stopSkipAudio()
    if currentMusic and currentMusic.stop then
        currentMusic:stop()
    end

    if music and music.stop then
        music:stop()
    end

    if bgm and bgm.stop then
        bgm:stop()
    end

    if breakfastMusic and breakfastMusic.stop then
        breakfastMusic:stop()
    end
end

local function goToAfterBreakfastScene()
    stopSkipAudio()

    if sceneManager and sceneManager.enter then
        if SueRoom then
            sceneManager:enter(SueRoom(), {
                fromSkip = true,
                afterBreakfast = true
            })
            return
        end

        if sue_room then
            sceneManager:enter(sue_room, {
                fromSkip = true,
                afterBreakfast = true
            })
            return
        end
    end

    if manager and manager.enter then
        if SueRoom then
            manager:enter(SueRoom(), {
                fromSkip = true,
                afterBreakfast = true
            })
            return
        end

        if sue_room then
            manager:enter(sue_room, {
                fromSkip = true,
                afterBreakfast = true
            })
            return
        end
    end

    if setScene then
        if SueRoom then
            setScene(SueRoom(), {
                fromSkip = true,
                afterBreakfast = true
            })
            return
        end

        if sue_room then
            setScene(sue_room, {
                fromSkip = true,
                afterBreakfast = true
            })
            return
        end
    end

    print("skip worked, but no known scene switch function was found")
end

function updateGlobalAfterBreakfastSkip()
    if storyFlags.breakfastDone then
        afterBreakfastSkipHoldFrames = 0
        afterBreakfastSkipTriggered = false
        return
    end

    if skipToAfterBreakfastComboHeld() then
        afterBreakfastSkipHoldFrames = afterBreakfastSkipHoldFrames + 1

        if afterBreakfastSkipHoldFrames >= AFTER_BREAKFAST_SKIP_FRAMES and not afterBreakfastSkipTriggered then
            afterBreakfastSkipTriggered = true
            applyAfterBreakfastStoryState()
            goToAfterBreakfastScene()
        end
    else
        afterBreakfastSkipHoldFrames = 0
        afterBreakfastSkipTriggered = false
    end
end

function GameUtils.isSkipComboDown()
    return false
end

function GameUtils.skipComboJustPressed()
    return false
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
    local frames = gfx.imagetable.new(path)

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
                if effectiveFps <= 0 then
                    effectiveFps = 1
                end

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
    local sideMargin = 8
    local maxWidth = 400 - sideMargin * 2
    local markerLeft = "< "
    local markerRight = " >"
    local reservedMarkerWidth = font:getTextWidth(markerLeft .. markerRight)
    local maxContentWidth = maxWidth - reservedMarkerWidth

    if maxContentWidth < 40 then
        maxContentWidth = 40
    end

    text = tostring(text or "")
    text = text:gsub("%s+", " ")
    text = text:gsub("^%s+", "")
    text = text:gsub("%s+$", "")

    local pages = GameUtils.wrapText(text, font, maxContentWidth)

    if #pages == 0 then
        pages = { "" }
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

function GameUtils.retreatDialogue(dialogue)
    if not dialogue then
        return false
    end

    if dialogue.index > 1 then
        dialogue.index = dialogue.index - 1
    end

    return false
end

function GameUtils.handleDialogueInput(dialogue)
    if not dialogue then
        return false
    end

    if playdate.buttonJustPressed(playdate.kButtonB) then
        GameUtils.retreatDialogue(dialogue)
        return false
    end

    if playdate.buttonJustPressed(playdate.kButtonA) then
        return GameUtils.advanceDialogue(dialogue)
    end

    return false
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

function GameUtils.drawDialogue(dialogue)
    if not dialogue then
        return
    end

    local font = Game.fonts.dialog or gfx.getSystemFont()
    local text = dialogue.pages[dialogue.index] or ""

    if dialogue.index > 1 then
        text = "< " .. text
    end

    if dialogue.index < #dialogue.pages then
        text = text .. " >"
    end

    local w = font:getTextWidth(text)
    local x = math.floor((400 - w) / 2)
    local y = 240 - font:getHeight() - 2

    GameUtils.drawTextWithUnderlay(text, x, y, font)
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

Game = {
    scene = nil,
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
        skipComboWasDown = false,
        floor3WarpWasDown = false,
        lobotomyChoiceWarpWasDown = false,
        brainWinWarpWasDown = false
    },

    state = {
        heldItem = nil,
        lobbyTrashPile = false,
        replaceSueWithDemon = false,
        level1 = {
            lampOff = false,
            lobbyDoorLocked = true
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
    local systemFont = gfx.getSystemFont()
    local customFontPath = "fonts/Bookxel_16"
    local customFont = gfx.font.new(customFontPath)

    if customFont then
        customFont:setLeading(0)
        self.fonts.prompt = customFont
        self.fonts.dialog = customFont
        print("loaded custom font: " .. customFontPath)
        return
    end

    self.fonts.prompt = systemFont
    self.fonts.dialog = systemFont
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

-- compatibility aliases so old scene files still work
newLobbyScene = newLevel1Scene
newWindowScene = newLevel1WindowScene

Game.routes = {
    title = function(state)
        return newTitleScene(state)
    end,

    lobby = function(state)
        return newLevel1Scene(state)
    end,

    lobbyWindow = function(state)
        return newLevel1WindowScene(state)
    end,

    nightIntro = function(state)
        return newNightIntroScene(state)
    end,

    nightInstructions = function(state)
        return newNightInstructionsScene(state)
    end,

    nightMinigame = function(state)
        return newNightMiniGameScene(state)
    end,

    catchingZs = function(state)
        return newCatchingZsScene(state)
    end,

    sunriseWindow = function(state)
        return newWindowSunriseScene(state)
    end,

    floor2Hallway = function(state)
        return newFloor2HallwayScene(state)
    end,

    floor2Waiting = function(state, entry)
        return newFloor2WaitingRoomScene(state, entry)
    end,

    floor2Tv = function(state)
        return newFloor2TvRoomScene(state)
    end,

    floor3Waiting = function(state, entry)
        return newFloor3WaitingRoomScene(state, entry)
    end,

    floor3Hallway = function(state, entry)
        return newFloor3HallwayScene(state, entry)
    end,

    floor3Room = function(state)
        return newFloor3RoomScene(state)
    end,

    floor3BroomCloset = function(state)
        return newFloor3BroomClosetScene(state)
    end,

    lobotomyDecision = function(state)
        return newLobotomyDecisionScene(state)
    end,

    trashBin = function(state)
        return newTrashScene(state)
    end,

    brainMinigame = function(state)
        return newBrainMiniGameScene(state)
    end,

    sneakEnding = function(state)
        return newSneakEndingScene(state)
    end,

    badEnding = function(state)
        return newBadEndingScene(state)
    end,

    healthyEnding = function(state)
        return newHealthyEndingScene(state)
    end,

    endingCredits = function(state)
        return newEndingCreditsScene(state)
    end
}

function Game:go(routeName, ...)
    local route = self.routes[routeName]

    if not route then
        print("unknown route: " .. tostring(routeName))
        return
    end

    self.currentRoute = routeName

    local args = { ... }

    self:setScene(function(state)
        return route(state, unpackFn(args))
    end)
end


local function floor3WarpComboDown()
    return playdate.buttonIsPressed(playdate.kButtonA)
        and playdate.buttonIsPressed(playdate.kButtonB)
        and playdate.buttonIsPressed(playdate.kButtonLeft)
        and playdate.buttonIsPressed(playdate.kButtonDown)
end

function Game:updateDebugCombos()
    local floor3Down = floor3WarpComboDown()
    local floor3Pressed = floor3Down and not self.debug.floor3WarpWasDown

    self.debug.floor3WarpWasDown = floor3Down

    if floor3Pressed then
        self:go("floor3Hallway")
        return true
    end

    return false
end

Game:loadFonts()
Game:loadSharedAssets()
Game:go("title")

function playdate.update()
    local now = playdate.getCurrentTimeMilliseconds()
    local dt = (now - Game.lastTimeMs) / 1000
    Game.lastTimeMs = now

    local warped = Game:updateDebugCombos()

    if not warped and Game.scene and Game.scene.update then
        Game.scene:update(dt)
    end

    playdate.timer.updateTimers()
    Game:updateMusic()

    if Game.scene and Game.scene.draw then
        Game.scene:draw()
    end
end