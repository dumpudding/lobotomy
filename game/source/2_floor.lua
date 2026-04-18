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

local floor2MusicPaths = {
    room = "png_and_wavs/lobby/the_color_of_smog",
    fishTank = "png_and_wavs/floor2/fishies.wav",
    tvPlaceholder = "png_and_wavs/floor2/ohno_my_crops.wav",
    profK = "png_and_wavs/floor2/esteemed-prof-k.wav"
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
end

local function playFloor2Music(path)
    if Game and Game.playMusic then
        Game:playMusic(path)
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

local function drawNpcImage(image, x, y)
    if image then
        image:draw(math.floor(x), math.floor(y))
    end
end

local function drawFloor2TalkBox(ui)
    if not ui then
        return
    end

    local font = Game.fonts.dialog or gfx.getSystemFont()

    GameUtils.drawTextWithUnderlay(ui.text, 10, 182, font)

    if ui.aText then
        GameUtils.drawTextWithUnderlay("A: " .. ui.aText, 10, 200, font)
    end

    if ui.bText then
        GameUtils.drawTextWithUnderlay("B: " .. ui.bText, 10, 218, font)
    end
end

function newFloor2WaitingRoomScene(state, entry)
    ensureFloor2State(state)

    local spawnX = 96
    local spawnY = 170

    if entry == "fromTvRoom" then
        spawnX = 356
        spawnY = 170
    end

    local scene = makeBaseScene(state, spawnX, spawnY)

    scene.musicPath = floor2MusicPaths.room

    scene.images = loadSue64Images()
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor2/waiting_room_lvl2")

    scene.npcs = {
        evvie = {
            drawX = 24,
            drawY = 98,
            blockRect = { x = 24, y = 126, w = 56, h = 46 },
            talkZone = { x = 12, y = 98, w = 76, h = 80 }
        }
    }

    scene.blockRects = {
        { x = 0, y = 101, w = 86, h = 26 },
        { x = 262, y = 95, w = 18, h = 25 },
        { x = 386, y = 95, w = 14, h = 25 }
    }

    scene.ui = nil

    function scene:setChoiceDialogue(text, aText, bText, onA, onB)
        self.ui = {
            text = text,
            aText = aText,
            bText = bText,
            onA = onA,
            onB = onB
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
        if self.state.floor2.evvieGone then
            return nil
        end

        local item = {
            name = "evvie",
            prompt = "A: Talk",
            zone = self.npcs.evvie.talkZone,
            anchor = { x = 14, y = 182 },
            action = function(selfScene)
                selfScene:setChoiceDialogue(
                    'e: "hey, Sue, right? i\'m evvie."',
                    "hi evvie, nice to meet you!",
                    "no, its not. go away.",
                    function(s)
                        s:setChoiceDialogue(
                            'e: "what\'s up?"',
                            "nothing",
                            "could i feed the fish?",
                            function(s2)
                                s2.ui = nil
                            end,
                            function(s2)
                                s2:setChoiceDialogue(
                                    'e: "sure, just 5 shakes of the fish food, got it?"',
                                    "yep!",
                                    nil,
                                    function(s3)
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
                            'e: "oof.. okay?"',
                            function(s2)
                                s2.state.floor2.evvieGone = true
                            end
                        )
                    end
                )
            end
        }

        local d = GameUtils.pointRectDistance(self.player.footX, self.player.footY, item.zone)
        if d <= 10 then
            return item
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

function newFishTankPlaceholderScene(state)
    ensureFloor2State(state)

    local scene = {}

    scene.state = state
    scene.musicPath = floor2MusicPaths.fishTank

    function scene:update(dt)
        if playdate.buttonJustPressed(playdate.kButtonB) then
            self.state.floor2.evvieGone = true

            if Game.go then
                Game:go("lobby")
            else
                Game:switchScene(function(nextState)
                    return newLevel1Scene(nextState)
                end)
            end
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        local font = Game.fonts.prompt or gfx.getSystemFont()

        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        font:drawText("B: back to lobby", 122, 112)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    return scene
end

function newTvPlaceholderScene(state)
    ensureFloor2State(state)

    local scene = {}

    scene.state = state
    scene.musicPath = floor2MusicPaths.tvPlaceholder

    function scene:update(dt)
        if playdate.buttonJustPressed(playdate.kButtonB) then
            Game:switchScene(function(nextState)
                return newFloor2TvRoomScene(nextState)
            end)
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        local font = Game.fonts.prompt or gfx.getSystemFont()

        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        font:drawText("B: back", 164, 112)
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
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

    scene.npcs = {
        profK = {
            drawX = 18,
            drawY = 2,
            blockRect = { x = 18, y = 68, w = 52, h = 30 },
            talkZone = { x = 10, y = 2, w = 74, h = 98 }
        }
    }

    scene.tvInteractive = {
        zone = { x = 296, y = 8, w = 86, h = 84 },
        anchor = { x = 292, y = 182 }
    }

    scene.blockRects = {
        floor2Objects.tv.tvStand
    }

    scene.ui = nil

    function scene:setChoiceDialogue(text, aText, bText, onA, onB)
        self.ui = {
            text = text,
            aText = aText,
            bText = bText,
            onA = onA,
            onB = onB
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
                prompt = "A: Talk",
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
                                'pk: "no hi, how are you? well, it\'s hot in here and my feet would be sweaty."',
                                "my bad. how are you? who are you?",
                                nil,
                                function(s2)
                                    s2:setChoiceDialogue(
                                        'pk: "call me dr. Kaltman *smirk*"',
                                        "well it is nice to meet you.",
                                        "bye.",
                                        function(s3)
                                            s3:setMessageDialogue(
                                                'pk: "you too"',
                                                function(s4)
                                                    s4.state.floor2.profKDone = true
                                                    s4:restoreRoomMusic()
                                                end
                                            )
                                        end,
                                        function(s3)
                                            s3:setMessageDialogue(
                                                'pk: "...what a weirdo..."',
                                                function(s4)
                                                    s4.state.floor2.profKDone = true
                                                    s4:restoreRoomMusic()
                                                end
                                            )
                                        end
                                    )
                                end,
                                nil
                            )
                        end,
                        function(s)
                            s:setChoiceDialogue(
                                'pk: "call me dr. Kaltman *smirk*"',
                                "well it is nice to meet you.",
                                "bye.",
                                function(s2)
                                    s2:setMessageDialogue(
                                        'pk: "you too"',
                                        function(s3)
                                            s3.state.floor2.profKDone = true
                                            s3:restoreRoomMusic()
                                        end
                                    )
                                end,
                                function(s2)
                                    s2:setMessageDialogue(
                                        'pk: "...what a weirdo..."',
                                        function(s3)
                                            s3.state.floor2.profKDone = true
                                            s3:restoreRoomMusic()
                                        end
                                    )
                                end
                            )
                        end
                    )
                end
            }
        end

        candidates[#candidates + 1] = {
            name = "tv",
            prompt = "A: Interact",
            zone = self.tvInteractive.zone,
            anchor = self.tvInteractive.anchor,
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

        if best and bestDist <= 10 then
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
        if self.player.footX <= 4 then
            Game:switchScene(function(nextState)
                return newFloor2WaitingRoomScene(nextState, "fromTvRoom")
            end)
            return
        end
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

        drawNpcImage(self.images.profK, self.npcs.profK.drawX, self.npcs.profK.drawY)
        drawSue64(self)
        self:drawPrompt()
        drawFloor2TalkBox(self.ui)
    end

    return scene
end