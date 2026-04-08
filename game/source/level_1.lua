local gfx = playdate.graphics

local level1ObjectBBoxes = {
    bed = { x = 219, y = 58, w = 70, h = 48 },
    lamp = { x = 115, y = 39, w = 32, h = 45 },
    window = { x = 157, y = 32, w = 88, h = 21 },
    table = { x = 265, y = 106, w = 31, h = 24 },
    trash_bin = { x = 169, y = 180, w = 26, h = 26 },
    plant = { x = 261, y = 181, w = 25, h = 25 },
    door = { x = 120, y = 201, w = 44, h = 9 }
}

function newTitleScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/title_screen/alienazzbeat"

    scene.warningImage = GameUtils.loadImage("png_and_wavs/title_screen/warning_v1.png")
    scene.introAnim = GameUtils.loadAnim("png_and_wavs/title_screen/brain for intro screen with buttons.gif", 10, true)

    scene.phase = "warning"
    scene.timer = 0
    scene.warningDuration = 5.0
    scene.crossfadeDuration = 0.75

    function scene:update(dt)
    if GameUtils.skipComboJustPressed() then
        if self.phase == "warning" or self.phase == "crossfade" then
            self.phase = "intro"
            self.timer = 0
            return
        end

        if self.phase == "intro" then
            Game:switchScene(function(nextState)
                return newNightIntroScene(nextState)
            end)
            return
        end
    end

    if self.phase == "warning" then
        self.timer = self.timer + dt
        if self.timer >= self.warningDuration then
            self.phase = "crossfade"
            self.timer = 0
        end
        return
    end

    if self.phase == "crossfade" then
        self.timer = self.timer + dt
        self.introAnim:update(dt)
        if self.timer >= self.crossfadeDuration then
            self.phase = "intro"
            self.timer = 0
        end
        return
    end

    if self.phase == "intro" then
        self.introAnim:update(dt)
        if playdate.buttonJustPressed(playdate.kButtonA) then
            Game:switchScene(function(nextState)
                return newNightIntroScene(nextState)
            end)
        end
    end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.phase == "warning" then
            if self.warningImage then
                self.warningImage:draw(0, 0)
            end
            return
        end

        if self.phase == "crossfade" then
            local alpha = GameUtils.clamp(self.timer / self.crossfadeDuration, 0, 1)

            if self.warningImage then
                self.warningImage:drawFaded(0, 0, 1 - alpha, gfx.image.kDitherTypeBayer8x8)
            end

            if self.introAnim then
                self.introAnim:drawFaded(0, 0, alpha)
            end

            return
        end

        if self.introAnim then
            self.introAnim:draw(0, 0)
        end
    end

    return scene
end

function newNightIntroScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/night/mateos_jiv"

    scene.anim1 = GameUtils.loadAnim("png_and_wavs/night/1_mateo_intro.gif", 10, false, 0.5)
    scene.waitImage = GameUtils.loadImage("png_and_wavs/night/2_mateo_wait.png")
    scene.animA = GameUtils.loadAnim("png_and_wavs/night/3.1_mateo_gn.gif", 10, false, 0.5)
    scene.animB = GameUtils.loadAnim("png_and_wavs/night/3.2_mateo_awkward.gif", 10, false, 0.5)
    scene.anim4 = GameUtils.loadAnim("png_and_wavs/night/4_walk_away.gif", 10, false, 0.5)

    scene.phase = "mateo1"

    function scene:update(dt)
    if GameUtils.skipComboJustPressed() then
        if self.phase == "mateo1" then
            self.phase = "wait"
            return
        end

        if self.phase == "wait" then
            self.animA:reset()
            self.phase = "choiceA"
            return
        end

        if self.phase == "choiceA" or self.phase == "choiceB" then
            self.anim4:reset()
            self.phase = "walkAway"
            return
        end

        if self.phase == "walkAway" then
            Game:switchScene(function(nextState)
                return newLevel1Scene(nextState)
            end)
            return
        end
    end

    if self.phase == "mateo1" then
        self.anim1:update(dt)
        if self.anim1.finished then
            self.phase = "wait"
        end
        return
    end

    if self.phase == "wait" then
        if playdate.buttonJustPressed(playdate.kButtonA) then
            self.animA:reset()
            self.phase = "choiceA"
        elseif playdate.buttonJustPressed(playdate.kButtonB) then
            self.animB:reset()
            self.phase = "choiceB"
        end
        return
    end

    if self.phase == "choiceA" then
        self.animA:update(dt)
        if self.animA.finished then
            self.anim4:reset()
            self.phase = "walkAway"
        end
        return
    end

    if self.phase == "choiceB" then
        self.animB:update(dt)
        if self.animB.finished then
            self.anim4:reset()
            self.phase = "walkAway"
        end
        return
    end

    if self.phase == "walkAway" then
        self.anim4:update(dt)
        if self.anim4.finished then
            Game:switchScene(function(nextState)
                return newLevel1Scene(nextState)
            end)
        end
    end
    end
    
    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.phase == "mateo1" then
            self.anim1:draw(0, 0)
            return
        end

        if self.phase == "wait" then
            if self.waitImage then
                self.waitImage:draw(0, 0)
            end
            return
        end

        if self.phase == "choiceA" then
            self.animA:draw(0, 0)
            return
        end

        if self.phase == "choiceB" then
            self.animB:draw(0, 0)
            return
        end

        if self.phase == "walkAway" then
            self.anim4:draw(0, 0)
        end
    end

    return scene
end

function newLevel1WindowScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/window_view/a_gust_of_odd_wind"
    scene.windowAnim = GameUtils.loadAnim("png_and_wavs/window_view/window_animated.gif", 10, true)
    scene.dialogue = GameUtils.makeDialogue("...")

    function scene:update(dt)
        self.windowAnim:update(dt)

        if playdate.buttonJustPressed(playdate.kButtonA) and self.dialogue then
            if GameUtils.advanceDialogue(self.dialogue) then
                self.dialogue = nil
            end
        end

        if playdate.buttonJustPressed(playdate.kButtonB) then
            Game:switchScene(function(nextState)
                return newLevel1Scene(nextState)
            end)
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)
        self.windowAnim:draw(0, 0)
        GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end

function newNightMiniGameScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/night/mateos_jiv"

    scene.bg = GameUtils.loadImage("png_and_wavs/night/night_minigame_config.png")
    scene.overlay = GameUtils.loadImage("png_and_wavs/night/night_minigame_fov.png")

    scene.overlayX = 0
    scene.overlayY = 0
    scene.speed = 2

    scene.minOverlayX = -80
    scene.maxOverlayX = 80
    scene.minOverlayY = -48
    scene.maxOverlayY = 48

    function scene:update(dt)
        if playdate.buttonIsPressed(playdate.kButtonLeft) then
            self.overlayX = self.overlayX - self.speed
        end

        if playdate.buttonIsPressed(playdate.kButtonRight) then
            self.overlayX = self.overlayX + self.speed
        end

        if playdate.buttonIsPressed(playdate.kButtonUp) then
            self.overlayY = self.overlayY - self.speed
        end

        if playdate.buttonIsPressed(playdate.kButtonDown) then
            self.overlayY = self.overlayY + self.speed
        end

        self.overlayX = GameUtils.clamp(self.overlayX, self.minOverlayX, self.maxOverlayX)
        self.overlayY = GameUtils.clamp(self.overlayY, self.minOverlayY, self.maxOverlayY)
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.bg then
            self.bg:draw(0, 0)
        end

        if self.overlay then
            self.overlay:draw(self.overlayX, self.overlayY)

            gfx.setColor(gfx.kColorBlack)

            if self.overlayX > 0 then
                gfx.fillRect(0, 0, self.overlayX, 240)
            elseif self.overlayX < 0 then
                gfx.fillRect(400 + self.overlayX, 0, -self.overlayX, 240)
            end

            if self.overlayY > 0 then
                gfx.fillRect(0, 0, 400, self.overlayY)
            elseif self.overlayY < 0 then
                gfx.fillRect(0, 240 + self.overlayY, 400, -self.overlayY)
            end
        end
    end

    return scene
end

function newLevel1Scene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/night/mateos_jiv"

    if scene.state.level1 == nil then
        scene.state.level1 = { lampOff = false }
    end

    scene.images = {
        base = GameUtils.loadImage("png_and_wavs/lobby/lobby_empty"),
        lamp = GameUtils.loadImage("png_and_wavs/lobby/lamp"),
        bed = GameUtils.loadImage("png_and_wavs/lobby/bed"),
        window = GameUtils.loadImage("png_and_wavs/lobby/window"),
        borders = GameUtils.loadImage("png_and_wavs/lobby/room_wall_borders"),
        table = GameUtils.loadImage("png_and_wavs/lobby/table"),
        trashBin = GameUtils.loadImage("png_and_wavs/lobby/trash_bin"),
        plant = GameUtils.loadImage("png_and_wavs/lobby/plant"),
        door = GameUtils.loadImage("png_and_wavs/lobby/door"),
        lampOffOverlay = GameUtils.loadImage("png_and_wavs/lobby/lamp_off_dither.png"),
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
        level1ObjectBBoxes.bed,
        level1ObjectBBoxes.lamp,
        level1ObjectBBoxes.table,
        level1ObjectBBoxes.trash_bin,
        level1ObjectBBoxes.plant,
        level1ObjectBBoxes.door
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

        return false
    end

    function scene:getNearbyInteractive()
        local interactives = {
            {
                name = "window",
                prompt = "A: Look Outside",
                zone = { x = 154, y = 50, w = 94, h = 24 },
                anchor = { x = 250, y = 52 },
                action = function(selfScene)
                    Game:switchScene(function(nextState)
                        return newLevel1WindowScene(nextState)
                    end)
                end
            },
            {
                name = "lamp",
                prompt = self.state.level1.lampOff and "A: Turn On" or "A: Turn Off",
                zone = { x = 109, y = 37, w = 42, h = 52 },
                anchor = { x = 150, y = 48 },
                action = function(selfScene)
                    selfScene.state.level1.lampOff = not selfScene.state.level1.lampOff
                end
            }
        }

        if self.state.level1.lampOff then
            interactives[#interactives + 1] = {
                name = "bed",
                prompt = "A: Go to Sleep",
                zone = { x = 200, y = 90, w = 82, h = 18 },
                anchor = { x = 250, y = 90 },
                action = function(selfScene)
                    Game:switchScene(function(nextState)
                        return newNightMiniGameScene(nextState)
                    end)
                end
            }
        end

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

        if playdate.buttonJustPressed(playdate.kButtonA) then
            local interactive = self:getNearbyInteractive()
            if interactive then
                interactive.action(self)
            end
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

        self:drawPlayer()

        if self.state.level1.lampOff and self.images.lampOffOverlay then
            self.images.lampOffOverlay:draw(0, 0)
        end

        self:drawPrompt()
        GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end