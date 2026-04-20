local gfx = playdate.graphics
local pd <const> = playdate

local floor3MusicPath = "png_and_wavs/lobby/the_color_of_smog"

local function ensureFloor3State(state)
    if state.floor2 == nil then
        state.floor2 = {}
    end

    if state.floor2.evvieGone == nil then
        state.floor2.evvieGone = false
    end

    if state.floor3 == nil then
        state.floor3 = {}
    end

    if state.floor3.evvieDone == nil then
        state.floor3.evvieDone = false
    end

    if state.floor3.broomClosetOpen == nil then
        state.floor3.broomClosetOpen = false
    end

    if state.floor3.broomClosetLampOn == nil then
        state.floor3.broomClosetLampOn = false
    end

    if state.floor3.broomClosetDoorLocked == nil then
        state.floor3.broomClosetDoorLocked = false
    end

    if state.floor3.lobotomyMonologueSeen == nil then
        state.floor3.lobotomyMonologueSeen = false
    end

    if state.floor3.noChoiceBranchTaken == nil then
        state.floor3.noChoiceBranchTaken = false
    end

    if state.floor3.needleRecovered == nil then
        state.floor3.needleRecovered = false
    end

    if state.floor3.elevatorFloor == nil then
        state.floor3.elevatorFloor = 3
    end

    if state.trashItems == nil then
        state.trashItems = {
            needle = "bin",
            gloves = "bin",
            vial = "bin",
            scissors = "bin",
            gauze = "bin"
        }
    end
end

local function loadSue64Images()
    return {
        sueIdle = GameUtils.loadImage("png_and_wavs/0_universal_sprites/sue_64x80"),
        sueWalkDown = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_64x80_down.gif", 10, true, 1.0),
        sueWalkLeft = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_64x80_left.gif", 10, true, 1.0),
        sueWalkRight = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_64x80_right.gif", 10, true, 1.0),
        sueWalkUp = GameUtils.loadAnim("png_and_wavs/0_universal_sprites/sue_64x80_up.gif", 10, true, 1.0)
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

local function loadEvvie32Image()
    local image = GameUtils.loadImage("png_and_wavs/floor3/evvie_32x40")
    if image then
        return image
    end

    return GameUtils.loadImage("png_and_wavs/0_universal_sprites/evvie_32x40")
end

local function makePlayer(footX, footY, speed)
    return {
        footX = footX,
        footY = footY,
        speed = speed or 4,
        facing = "down",
        isMoving = false
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

local function rectsIntersect(a, b)
    return not (
        a.x + a.w <= b.x or
        b.x + b.w <= a.x or
        a.y + a.h <= b.y or
        b.y + b.h <= a.y
    )
end

local function updateWalkAnim(player, images, dt)
    if not player.isMoving then
        return
    end

    if player.facing == "down" and images.sueWalkDown then
        images.sueWalkDown:update(dt)
    elseif player.facing == "left" and images.sueWalkLeft then
        images.sueWalkLeft:update(dt)
    elseif player.facing == "right" and images.sueWalkRight then
        images.sueWalkRight:update(dt)
    elseif player.facing == "up" and images.sueWalkUp then
        images.sueWalkUp:update(dt)
    end
end

local function updateMovement(scene, dt)
    local dx = 0
    local dy = 0

    if pd.buttonIsPressed(pd.kButtonLeft) then
        dx = dx - 1
    end

    if pd.buttonIsPressed(pd.kButtonRight) then
        dx = dx + 1
    end

    if pd.buttonIsPressed(pd.kButtonUp) then
        dy = dy - 1
    end

    if pd.buttonIsPressed(pd.kButtonDown) then
        dy = dy + 1
    end

    scene.player.isMoving = (dx ~= 0 or dy ~= 0)

    if dx ~= 0 or dy ~= 0 then
        if math.abs(dx) > math.abs(dy) then
            scene.player.facing = dx < 0 and "left" or "right"
        else
            scene.player.facing = dy < 0 and "up" or "down"
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

    updateWalkAnim(scene.player, scene.images, dt)
end

local function drawSue(scene)
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

local function stripOuterQuotes(text)
    if text == nil then
        return ""
    end

    text = tostring(text)
    return text:gsub('^"(.*)"$', "%1")
end

local function formatFloor3SpokenLine(text)
    if text == nil or text == "" then
        return nil
    end

    local speaker, content = string.match(text, "^%s*([^:]+):%s*(.*)$")

    if speaker and content and content ~= "" then
        content = stripOuterQuotes(content)
        return speaker .. ': "' .. content .. '"'
    end

    text = stripOuterQuotes(text)
    return '"' .. text .. '"'
end

local function formatFloor3OptionLine(buttonLabel, text)
    if text == nil or text == "" then
        return nil
    end

    text = stripOuterQuotes(text)
    return buttonLabel .. ': "' .. text .. '"'
end

local function makeSueBottomDialogue(text)
    local content = text or ""
    local _, rest = string.match(content, "^%s*([^:]+):%s*(.*)$")
    if rest and rest ~= "" then
        content = rest
    end

    content = stripOuterQuotes(content)
    return GameUtils.makeDialogue('sue: "' .. content .. '"')
end

local function drawFloor3TalkBox(ui)
    if not ui then
        return
    end

    if ui.bottomDialogue then
        GameUtils.drawDialogue(ui.bottomDialogue)
        return
    end

    local font = Game.fonts.dialog or gfx.getSystemFont()
    local spokenLine = formatFloor3SpokenLine(ui.text)

    if spokenLine then
        local lines = GameUtils.wrapText(spokenLine, font, 380)
        for i = 1, #lines do
            local y = 8 + (i - 1) * (font:getHeight() + 2)
            GameUtils.drawTextWithUnderlay(lines[i], 10, y, font)
        end
    end

    local aLine = formatFloor3OptionLine("A", ui.aText)
    local bLine = formatFloor3OptionLine("B", ui.bText)

    if aLine then
        GameUtils.drawTextWithUnderlay(aLine, 10, 196, font)
    end

    if bLine then
        GameUtils.drawTextWithUnderlay(bLine, 10, 214, font)
    end
end

local function drawFloor3Prompt(text, anchor)
    if not text or not anchor then
        return
    end

    local font = Game.fonts.prompt or gfx.getSystemFont()
    local w = font:getTextWidth(text)
    local x = GameUtils.clamp(anchor.x, 4, 396 - w)
    local y = GameUtils.clamp(anchor.y, 4, 228)
    GameUtils.drawTextWithUnderlay(text, x, y, font)
end

local function evvieIsFriendly(state)
    if state.floor2 and state.floor2.evvieFriendly ~= nil then
        return state.floor2.evvieFriendly
    end

    if state.floor2 and state.floor2.evvieGone then
        return false
    end

    return true
end

local function floor3HasNeedleAccess(state)
    if state.heldItem == "needle" then
        return true
    end

    if state.trashItems and state.trashItems.needle == "held" then
        return true
    end

    if state.floor3 and state.floor3.needleRecovered then
        return true
    end

    return false
end

local function roomHasNeedleInPile(state)
    return state.trashItems ~= nil and state.trashItems.needle == "gone"
end

local function makeBaseScene(state, footX, footY, useBigSue)
    local scene = {}
    scene.state = state
    scene.player = makePlayer(footX, footY, 4)
    scene.images = useBigSue and loadSue64Images() or loadSue32Images()
    scene.musicPath = floor3MusicPath
    scene.ui = nil
    scene.blockers = {}

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
        if type(text) == "string" and string.match(text, "^%s*s:%s*") then
            self.ui = {
                text = text,
                onClose = onClose,
                bottomDialogue = makeSueBottomDialogue(text)
            }
            return
        end

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
            if pd.buttonJustPressed(pd.kButtonA) and self.ui.onA then
                self.ui.onA(self)
            elseif pd.buttonJustPressed(pd.kButtonB) and self.ui.onB then
                self.ui.onB(self)
            end
            return true
        end

        if self.ui.bottomDialogue then
            if pd.buttonJustPressed(pd.kButtonA) then
                local onClose = self.ui.onClose
                if GameUtils.advanceDialogue(self.ui.bottomDialogue) then
                    self.ui = nil
                    if onClose then
                        onClose(self)
                    end
                end
            end
            return true
        end

        if pd.buttonJustPressed(pd.kButtonA) or pd.buttonJustPressed(pd.kButtonB) then
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
        return true
    end

    function scene:getBlockers()
        return self.blockers or {}
    end

    function scene:isBlocked(x, y)
        local footRect = getFootRect(x, y)
        if not self:isInsideRoomBounds(footRect) then
            return true
        end

        local blockers = self:getBlockers()
        for i = 1, #blockers do
            if rectsIntersect(footRect, blockers[i]) then
                return true
            end
        end

        return false
    end

    function scene:drawPrompt()
        if self.ui then
            return
        end

        local interactive = self:getNearbyInteractive()
        if interactive then
            drawFloor3Prompt(interactive.prompt, interactive.anchor)
        end
    end

    return scene
end

function newFloor3ElevatorScene(state)
    ensureFloor3State(state)
    state.floor3.elevatorFloor = 3

    local scene = makeBaseScene(state, 196, 170, false)
    scene.images.base = GameUtils.loadImage("png_and_wavs/elevator/elevator")
    scene.player.speed = 3

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 152 or footRect.x + footRect.w > 248 then
            return false
        end

        if footRect.y < 96 or footRect.y + footRect.h > 232 then
            return false
        end

        return true
    end

    function scene:getNearbyInteractive()
        local items = {
            {
                prompt = "A: Exit Elevator",
                zone = { x = 166, y = 78, w = 68, h = 20 },
                anchor = { x = 240, y = 80 },
                action = function(selfScene)
                    Game:go("floor3Waiting", "fromElevator")
                end
            },
            {
                prompt = "A: talk to odd guy",
                zone = { x = 220, y = 124, w = 28, h = 42 },
                anchor = { x = 254, y = 136 },
                action = function(selfScene)
                    selfScene:setChoiceDialogue(
                        "hey kid. which floor?",
                        "2nd floor",
                        "3rd floor",
                        function(s)
                            s.ui = nil
                            Game:go("floor2Waiting", "fromElevator")
                        end,
                        function(s)
                            s:setMessageDialogue("you're already on the third floor, silly child.")
                        end
                    )
                end
            }
        }

        local best = nil
        local bestDist = 999
        for i = 1, #items do
            local d = GameUtils.pointRectDistance(self.player.footX, self.player.footY, items[i].zone)
            if d < bestDist then
                best = items[i]
                bestDist = d
            end
        end

        if best and bestDist <= 12 then
            return best
        end

        return nil
    end

    function scene:update(dt)
        if self:handleUiInput() then
            return
        end

        updateMovement(self, dt)

        if pd.buttonJustPressed(pd.kButtonA) then
            local interactive = self:getNearbyInteractive()
            if interactive then
                interactive.action(self)
            end
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorWhite)

        if self.images.base then
            self.images.base:draw(0, 0)
        end

        gfx.setColor(gfx.kColorBlack)
        gfx.fillCircleAtPoint(236, 150, 6)
        gfx.drawLine(236, 156, 236, 167)
        gfx.drawLine(236, 160, 230, 164)
        gfx.drawLine(236, 160, 242, 164)

        drawSue(scene)
        self:drawPrompt()
        drawFloor3TalkBox(self.ui)
    end

    return scene
end

function newFloor3WaitingRoomScene(state, entry)
    ensureFloor3State(state)
    state.floor3.elevatorFloor = 3

    local spawnX = 318
    local spawnY = 172

    if entry == "fromHallway" then
        spawnX = 20
        spawnY = 172
    end

    local scene = makeBaseScene(state, spawnX, spawnY, true)
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor3/waiting_room_lvl3")

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 0 or footRect.x + footRect.w > 400 then
            return false
        end

        if footRect.y < 97 or footRect.y + footRect.h > 236 then
            return false
        end

        return true
    end

    function scene:getNearbyInteractive()
        local elevator = {
            prompt = "A: enter elevator",
            zone = { x = 286, y = 24, w = 72, h = 102 },
            anchor = { x = 362, y = 66 },
            action = function(selfScene)
                Game:switchScene(function(nextState)
                    return newFloor3ElevatorScene(nextState)
                end)
            end
        }

        if GameUtils.pointRectDistance(self.player.footX, self.player.footY, elevator.zone) <= 12 then
            return elevator
        end

        return nil
    end

    function scene:checkRoomTransitions()
        if self.player.footX <= 8 then
            Game:switchScene(function(nextState)
                return newFloor3HallwayScene(nextState, "fromWaiting")
            end)
        end
    end

    function scene:update(dt)
        if self:handleUiInput() then
            return
        end

        updateMovement(self, dt)

        if pd.buttonJustPressed(pd.kButtonA) then
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

        drawSue(scene)
        self:drawPrompt()
        drawFloor3TalkBox(self.ui)
    end

    return scene
end

function newFloor3HallwayScene(state, entry)
    ensureFloor3State(state)

    local spawnX = 372
    local spawnY = 172

    if entry == "fromRoom" then
        spawnX = 36
        spawnY = 172
    elseif entry == "fromCloset" then
        spawnX = 214
        spawnY = 172
    end

    local scene = makeBaseScene(state, spawnX, spawnY, true)
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor3/hallway_lvl3")

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 0 or footRect.x + footRect.w > 400 then
            return false
        end

        if footRect.y < 97 or footRect.y + footRect.h > 236 then
            return false
        end

        return true
    end

    function scene:getNearbyInteractive()
        local items = {
            {
                prompt = "A: enter room",
                zone = { x = 0, y = 8, w = 48, h = 92 },
                anchor = { x = 52, y = 56 },
                action = function(selfScene)
                    Game:switchScene(function(nextState)
                        return newFloor3RoomScene(nextState, "fromHallway")
                    end)
                end
            },
            {
                prompt = (self.state.floor3.broomClosetOpen and floor3HasNeedleAccess(self.state)) and "A: enter" or "A: Inspect",
                zone = { x = 188, y = 8, w = 66, h = 92 },
                anchor = { x = 258, y = 56 },
                action = function(selfScene)
                    if not selfScene.state.floor3.broomClosetOpen then
                        selfScene:setMessageDialogue("it's locked... i wonder if i can get inside somehow?")
                        return
                    end

                    if not floor3HasNeedleAccess(selfScene.state) then
                        selfScene:setMessageDialogue("the broom closet is open now... now i am just missing a tool...")
                        return
                    end

                    Game:switchScene(function(nextState)
                        return newFloor3BroomClosetScene(nextState)
                    end)
                end
            },
            {
                prompt = "A: listen at door",
                zone = { x = 320, y = 8, w = 72, h = 92 },
                anchor = { x = 300, y = 56 },
                action = function(selfScene)
                    selfScene:setMessageDialogue("hmm. sounds like someone's snoring...")
                end
            }
        }

        local best = nil
        local bestDist = 999
        for i = 1, #items do
            local d = GameUtils.pointRectDistance(self.player.footX, self.player.footY, items[i].zone)
            if d < bestDist then
                best = items[i]
                bestDist = d
            end
        end

        if best and bestDist <= 5 then
            return best
        end

        return nil
    end

    function scene:checkRoomTransitions()
        if self.player.footX >= 388 then
            Game:switchScene(function(nextState)
                return newFloor3WaitingRoomScene(nextState, "fromHallway")
            end)
        end
    end

    function scene:update(dt)
        if self:handleUiInput() then
            return
        end

        updateMovement(self, dt)

        if pd.buttonJustPressed(pd.kButtonA) then
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

        drawSue(scene)
        self:drawPrompt()
        drawFloor3TalkBox(self.ui)
    end

    return scene
end

function newFloor3RoomScene(state, entry)
    ensureFloor3State(state)

    local spawnX = 146
    local spawnY = 198

    if entry == "fromTrash" then
        spawnX = 176
        spawnY = 198
    end

    local scene = makeBaseScene(state, spawnX, spawnY, false)
    scene.images.base = GameUtils.loadImage("png_and_wavs/floor3/3_floor_room")
    scene.images.overlay = GameUtils.loadImage("png_and_wavs/floor3/3_floor_room_overlay_assets")
    scene.images.evvie = loadEvvie32Image()
    scene.images.pileNoNeedle = GameUtils.loadImage("png_and_wavs/floor3/trash_pile_no_needle")
    scene.images.pileWithNeedle = GameUtils.loadImage("png_and_wavs/floor3/trash_pile_w_needle")

    scene.blockers = {
        { x = 166, y = 196, w = 18, h = 8 },
        { x = 262, y = 196, w = 14, h = 8 }
    }

    scene.evvie = {
        footX = 131,
        footY = 130,
        zone = { x = 114, y = 120, w = 34, h = 46 },
        anchor = { x = 160, y = 110 }
    }

    scene.trashCan = {
        zone = { x = 166, y = 176, w = 30, h = 28 },
        anchor = { x = 198, y = 184 }
    }

    scene.pile = {
        zone = { x = 197, y = 176, w = 34, h = 28 },
        anchor = { x = 232, y = 184 }
    }

    scene.exitDoor = {
        zone = { x = 116, y = 190, w = 34, h = 18 },
        anchor = { x = 152, y = 182 }
    }

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 113 or footRect.x + footRect.w > 287 then
            return false
        end

        if footRect.y < 107 or footRect.y + footRect.h > 206 then
            return false
        end

        return true
    end

    function scene:beginEvvieConversation()
        local friendly = evvieIsFriendly(self.state)
        local firstLine = friendly and "evvie: hey Sue, do you need something?" or "evvie: ...hey."

        self:setMessageDialogue(
            firstLine,
            function(s)
                s:setMessageDialogue(
                    "A: \"there's a spill on the first floor. mateo told me to tell you.\"",
                    function(s2)
                        s2:setMessageDialogue(
                            "evvie: oh, thanks for letting me know! i better go get a mop from the broom closet and head down",
                            function(s3)
                                s3.state.floor3.evvieDone = true
                                s3.state.floor3.broomClosetOpen = true
                            end
                        )
                    end
                )
            end
        )
    end

    function scene:getNearbyInteractive()
        local items = {
            {
                prompt = "A: exit",
                zone = self.exitDoor.zone,
                anchor = self.exitDoor.anchor,
                action = function(selfScene)
                    Game:switchScene(function(nextState)
                        return newFloor3HallwayScene(nextState, "fromRoom")
                    end)
                end
            },
            {
                prompt = "A: Interact",
                zone = self.trashCan.zone,
                anchor = self.trashCan.anchor,
                action = function(selfScene)
                    selfScene.state.trashReturnScene = "floor3Room"
                    Game:go("trashBin")
                end
            }
        }

        if not self.state.floor3.evvieDone then
            items[#items + 1] = {
                prompt = "A: Talk",
                zone = self.evvie.zone,
                anchor = self.evvie.anchor,
                action = function(selfScene)
                    selfScene:beginEvvieConversation()
                end
            }
        end

        if roomHasNeedleInPile(self.state) and self.state.heldItem == nil then
            items[#items + 1] = {
                prompt = "A: pick up flung needle",
                zone = self.pile.zone,
                anchor = self.pile.anchor,
                action = function(selfScene)
                    selfScene.state.heldItem = "needle"
                    selfScene.state.trashItems.needle = "held"
                    selfScene.state.floor3.needleRecovered = true
                end
            }
        end

        local best = nil
        local bestDist = 999
        for i = 1, #items do
            local d = GameUtils.pointRectDistance(self.player.footX, self.player.footY, items[i].zone)
            if d < bestDist then
                best = items[i]
                bestDist = d
            end
        end

        if best and bestDist <= 5 then
            return best
        end

        return nil
    end

    function scene:checkRoomTransitions()
    end

    function scene:update(dt)
        if self:handleUiInput() then
            return
        end

        updateMovement(self, dt)

        if pd.buttonJustPressed(pd.kButtonA) then
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

        if roomHasNeedleInPile(self.state) then
            if self.images.pileWithNeedle then
                self.images.pileWithNeedle:draw(0, 0)
            end
        else
            if self.images.pileNoNeedle then
                self.images.pileNoNeedle:draw(0, 0)
            end
        end

        if not self.state.floor3.evvieDone and self.images.evvie then
            local w, h = self.images.evvie:getSize()
            self.images.evvie:draw(math.floor(self.evvie.footX - w / 2), math.floor(self.evvie.footY - h))
        end

        drawSue(scene)

        if self.images.overlay then
            self.images.overlay:draw(0, 0)
        end

        self:drawPrompt()
        drawFloor3TalkBox(self.ui)
    end

    return scene
end


function newFloor3BroomClosetScene(state)
    ensureFloor3State(state)

    local scene = makeBaseScene(state, 200, 190, false)
    scene.images.base = GameUtils.loadImage("png_and_wavs/broom_closet/broom_closet_config_demo")
    scene.images.overlay = GameUtils.loadImage("png_and_wavs/broom_closet/broom_closet_stuff")
    scene.images.dither = GameUtils.loadImage("png_and_wavs/broom_closet/lamp_off_dither")
    scene.player.speed = 3

    scene.blockers = {
        { x = 146, y = 56, w = 28, h = 60 },
        { x = 183, y = 60, w = 24, h = 58 },
        { x = 208, y = 32, w = 49, h = 90 },
        { x = 218, y = 80, w = 28, h = 24 }
    }

    function scene:maybeStartMonologue()
        if self.state.floor3.broomClosetLampOn and self.state.floor3.broomClosetDoorLocked and not self.state.floor3.lobotomyMonologueSeen then
            self.state.floor3.lobotomyMonologueSeen = true
            Game:switchScene(function(nextState)
                return newLobotomyDecisionScene(nextState)
            end)
            return true
        end

        return false
    end

    function scene:isInsideRoomBounds(footRect)
        if footRect.x < 146 or footRect.x + footRect.w > 256 then
            return false
        end

        if footRect.y < 32 or footRect.y + footRect.h > 206 then
            return false
        end

        return true
    end

    function scene:getNearbyInteractive()
        local items = {
            {
                kind = "door",
                prompt = "A: leave room B: lock door from inside",
                zone = { x = 186, y = 196, w = 30, h = 16 },
                anchor = { x = 218, y = 180 }
            }
        }

        if not self.state.floor3.broomClosetLampOn then
            items[#items + 1] = {
                kind = "lamp",
                prompt = "A: turn on lamp",
                zone = { x = 146, y = 54, w = 26, h = 58 },
                anchor = { x = 176, y = 86 }
            }
        end

        local best = nil
        local bestDist = 999
        for i = 1, #items do
            local d = GameUtils.pointRectDistance(self.player.footX, self.player.footY, items[i].zone)
            if d < bestDist then
                best = items[i]
                bestDist = d
            end
        end

        if best and bestDist <= 12 then
            return best
        end

        return nil
    end

    function scene:update(dt)
        if self:handleUiInput() then
            return
        end

        updateMovement(self, dt)

        local interactive = self:getNearbyInteractive()
        if not interactive then
            return
        end

        if interactive.kind == "door" then
            if pd.buttonJustPressed(pd.kButtonA) then
                Game:switchScene(function(nextState)
                    return newFloor3HallwayScene(nextState, "fromCloset")
                end)
                return
            end

            if pd.buttonJustPressed(pd.kButtonB) then
                self.state.floor3.broomClosetDoorLocked = true
                self:maybeStartMonologue()
                return
            end

            return
        end

        if interactive.kind == "lamp" and pd.buttonJustPressed(pd.kButtonA) then
            self.state.floor3.broomClosetLampOn = true
            self:maybeStartMonologue()
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.base then
            self.images.base:draw(0, 0)
        end

        if self.images.overlay then
            self.images.overlay:draw(0, 0)
        end

        if not self.state.floor3.broomClosetLampOn and self.images.dither then
            self.images.dither:draw(0, 0)
        end

        drawSue(scene)
        self:drawPrompt()
        drawFloor3TalkBox(self.ui)
    end

    return scene
end

function newLobotomyDecisionScene(state)
    ensureFloor3State(state)

    local scene = {}
    scene.state = state
    scene.phase = "text"

    function scene:update(dt)
        if self.phase == "text" then
            if pd.buttonJustPressed(pd.kButtonA) then
                self.phase = "choice"
            end
            return
        end

        if pd.buttonJustPressed(pd.kButtonA) then
            Game:go("brainMinigame")
            return
        end

        if pd.buttonJustPressed(pd.kButtonB) then
            self.state.floor3.noChoiceBranchTaken = true
            Game:switchScene(function(nextState)
                return newFloor3NoChoicePlaceholderScene(nextState)
            end)
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)
        local font = Game.fonts.dialog or gfx.getSystemFont()
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)

        if self.phase == "text" then
            local text = "I CAN'T STAND THIS... IT FEELS LIKE MY BRAIN HAS BEEN POSESSED... i need to do something about it..."
            local lines = GameUtils.wrapText(text, font, 360)
            for i = 1, #lines do
                font:drawText(lines[i], 20, 44 + (i - 1) * (font:getHeight() + 4))
            end
        else
            local aLine = "A: a lobotomy isn't hard right? i'm doing myself a favor.. let's do this."
            local bLine = "B: no no no.. no... this isn't right! i should just tell mateo..."
            local linesA = GameUtils.wrapText(aLine, font, 360)
            local linesB = GameUtils.wrapText(bLine, font, 360)

            for i = 1, #linesA do
                font:drawText(linesA[i], 20, 72 + (i - 1) * (font:getHeight() + 4))
            end

            for i = 1, #linesB do
                font:drawText(linesB[i], 20, 138 + (i - 1) * (font:getHeight() + 4))
            end
        end

        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    return scene
end

function newFloor3NoChoicePlaceholderScene(state)
    ensureFloor3State(state)

    local scene = {}
    scene.state = state

    function scene:update(dt)
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)
        local font = Game.fonts.dialog or gfx.getSystemFont()
        gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
        local lines = GameUtils.wrapText("placeholder: this branch is not implemented yet.", font, 360)
        for i = 1, #lines do
            font:drawText(lines[i], 20, 100 + (i - 1) * (font:getHeight() + 4))
        end
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
    end

    return scene
end
