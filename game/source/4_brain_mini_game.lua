local gfx = playdate.graphics

function newBrainMiniGameScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/brain_mini_game/anxiety_pro_max"

    scene.images = {
        brain = GameUtils.loadImage("png_and_wavs/brain_mini_game/brain"),
        demon = GameUtils.loadImage("png_and_wavs/brain_mini_game/demon_32x32") or GameUtils.loadImage("png_and_wavs/0_universal_sprites/demon_32x32"),
        crankBar = GameUtils.loadImage("png_and_wavs/brain_mini_game/crank_bar"),
        lrBar = GameUtils.loadImage("png_and_wavs/brain_mini_game/left_right_bar"),
        pointer = GameUtils.loadImage("png_and_wavs/brain_mini_game/left_right_pointer"),
        background = GameUtils.loadImage("png_and_wavs/brain_mini_game/background.png")
    }

    scene.brainRect = { x = 105, y = 15, w = 187, h = 209 }
    scene.pointerBBox = { x = 192, y = 192, w = 10, h = 20 }

    -- interiors of the visible white-outlined bars
    scene.barInterior = {
        crank = { x = 36, y = 23, w = 30, h = 161 },
        lr = { x = 110, y = 155, w = 173, h = 26 }
    }

    scene.anchorPoints = {
        { x = 138, y = 48 },
        { x = 178, y = 64 },
        { x = 224, y = 52 },
        { x = 134, y = 104 },
        { x = 185, y = 110 },
        { x = 233, y = 104 },
        { x = 144, y = 152 },
        { x = 198, y = 156 },
        { x = 236, y = 146 }
    }

    scene.previewTime = 10.0
    scene.hitShowTime = 5.0
    scene.endShowTime = 1.2

    scene.phase = "preview"
    scene.phaseTimer = 0
    scene.hearts = 3

    scene.pointerT = 0.5
    scene.pointerDir = 1
    scene.pointerSpeed = 1.2 -- - - LR bar speed (normalized units per second)

    scene.crankLevel = 0
    scene.crankGainScale = 1 / 120
    scene.crankDecayPerSecond = 0.42

    scene.crosshair = nil
    scene.flashTimer = 0
    scene.flashCount = 0
    scene.falling = nil
    scene.demons = {}

    local usedA = math.random(1, #scene.anchorPoints)
    local usedB = math.random(1, #scene.anchorPoints)
    while usedB == usedA do
        usedB = math.random(1, #scene.anchorPoints)
    end

    scene.demons[1] = {
        x = scene.anchorPoints[usedA].x,
        y = scene.anchorPoints[usedA].y,
        alive = true
    }

    scene.demons[2] = {
        x = scene.anchorPoints[usedB].x,
        y = scene.anchorPoints[usedB].y,
        alive = true
    }

    function scene:aliveCount()
        local count = 0
        for i = 1, #self.demons do
            if self.demons[i].alive then
                count = count + 1
            end
        end
        return count
    end

    function scene:moveOtherDemon(hitIndex)
        local otherIndex = nil

        for i = 1, #self.demons do
            if i ~= hitIndex and self.demons[i].alive then
                otherIndex = i
                break
            end
        end

        if not otherIndex then
            return
        end

        local tries = 0
        while tries < 32 do
            local pick = math.random(1, #self.anchorPoints)
            local candidate = self.anchorPoints[pick]

            local dx = candidate.x - self.demons[hitIndex].x
            local dy = candidate.y - self.demons[hitIndex].y

            if math.sqrt(dx * dx + dy * dy) > 30 then
                self.demons[otherIndex].x = candidate.x
                self.demons[otherIndex].y = candidate.y
                return
            end

            tries = tries + 1
        end
    end

    function scene:brainPointFromBars()
        local barX = self.barInterior.lr.x + self.pointerT * self.barInterior.lr.w
        local barY = self.barInterior.crank.y + (1 - self.crankLevel) * self.barInterior.crank.h

        local nx = (barX - self.barInterior.lr.x) / self.barInterior.lr.w
        local ny = (barY - self.barInterior.crank.y) / self.barInterior.crank.h

        local brainX = self.brainRect.x + nx * self.brainRect.w
        local brainY = self.brainRect.y + ny * self.brainRect.h

        return barX, barY, brainX, brainY
    end

    function scene:startFlash()
        self.flashTimer = 0.08
        self.flashCount = 4
    end

    function scene:resolveStrike()
        local barX, barY, brainX, brainY = self:brainPointFromBars()

        self.crosshair = {
            x = math.floor(barX + 0.5),
            y = math.floor(barY + 0.5),
            brainX = brainX,
            brainY = brainY,
            timer = 0.18
        }

        local hitIndex = nil

        for i = 1, #self.demons do
            local demon = self.demons[i]
            if demon.alive then
                local centerX = demon.x + 16
                local centerY = demon.y + 16
                local dx = brainX - centerX
                local dy = brainY - centerY

                if math.sqrt(dx * dx + dy * dy) <= 25 then
                    hitIndex = i
                    break
                end
            end
        end

        if hitIndex then
            local hitDemon = self.demons[hitIndex]
            hitDemon.alive = false

            self.falling = {
                x = hitDemon.x,
                y = hitDemon.y,
                vy = 70
            }

            self:moveOtherDemon(hitIndex)

            if self:aliveCount() == 0 then
                self.phase = "success_show"
                self.phaseTimer = 0
            else
                self.phase = "hit_show"
                self.phaseTimer = 0
            end
        else
            self.hearts = self.hearts - 1
            self:startFlash()

            if self.hearts <= 0 then
                self.state.heldItem = nil
                self.state.replaceSueWithDemon = true
                self.state.trashItems.needle = "gone"
                self.phase = "fail_return"
                self.phaseTimer = 0
            else
                self.phase = "miss_pause"
                self.phaseTimer = 0
            end
        end
    end

    function scene:updatePreview(dt)
        self.phaseTimer = self.phaseTimer + dt
        if self.phaseTimer >= self.previewTime then
            self.phase = "bars"
            self.phaseTimer = 0
        end
    end

    function scene:updateBars(dt)
        self.pointerT = self.pointerT + self.pointerDir * self.pointerSpeed * dt

        if self.pointerT >= 1 then
            self.pointerT = 1
            self.pointerDir = -1
        elseif self.pointerT <= 0 then
            self.pointerT = 0
            self.pointerDir = 1
        end

        local crankChange = math.abs(playdate.getCrankChange())

        self.crankLevel = self.crankLevel + crankChange * self.crankGainScale
        self.crankLevel = self.crankLevel - self.crankDecayPerSecond * dt
        self.crankLevel = GameUtils.clamp(self.crankLevel, 0, 1)

        if playdate.buttonJustPressed(playdate.kButtonA) then
            self:resolveStrike()
        end
    end

    function scene:updateCrosshairAndFlash(dt)
        if self.crosshair then
            self.crosshair.timer = self.crosshair.timer - dt
            if self.crosshair.timer <= 0 then
                self.crosshair = nil
            end
        end

        if self.flashCount > 0 then
            self.flashTimer = self.flashTimer - dt
            if self.flashTimer <= 0 then
                self.flashTimer = 0.08
                self.flashCount = self.flashCount - 1
            end
        end
    end

    function scene:updateFalling(dt)
        if self.falling then
            self.falling.y = self.falling.y + self.falling.vy * dt
            self.falling.vy = self.falling.vy + 240 * dt
        end
    end

    function scene:update(dt)
        self:updateCrosshairAndFlash(dt)

        if self.phase == "preview" then
            self:updatePreview(dt)
            return
        end

        if self.phase == "bars" then
            self:updateBars(dt)
            return
        end

        if self.phase == "miss_pause" then
            if not self.crosshair and self.flashCount <= 0 then
                self.phase = "bars"
                self.phaseTimer = 0
            end
            return
        end

        if self.phase == "hit_show" then
            self.phaseTimer = self.phaseTimer + dt
            self:updateFalling(dt)

            if self.phaseTimer >= self.hitShowTime then
                self.phase = "bars"
                self.phaseTimer = 0
                self.falling = nil
                self.crosshair = nil
                self.crankLevel = 0
            end
            return
        end

        if self.phase == "success_show" then
            self.phaseTimer = self.phaseTimer + dt
            self:updateFalling(dt)

            if self.phaseTimer >= self.endShowTime then
                self.state.replaceSueWithDemon = false
                self.state.heldItem = "needle"
                self.state.trashItems.needle = "held"
                Game:go("sneakEnding")
            end
            return
        end

        if self.phase == "fail_return" then
            if not self.crosshair and self.flashCount <= 0 then
                Game:go("badEnding")
            end
        end
    end

    function scene:drawDemons()
        if not self.images.demon then
            return
        end

        for i = 1, #self.demons do
            local demon = self.demons[i]
            if demon.alive then
                self.images.demon:draw(demon.x, demon.y)
            end
        end

        if self.falling then
            self.images.demon:draw(math.floor(self.falling.x), math.floor(self.falling.y))
        end
    end

    function scene:drawPreview()
    gfx.clear(gfx.kColorBlack)

    if self.images.brain then
        self.images.brain:draw(0, 0)
    end

    self:drawDemons()
    GameUtils.drawHearts(self.hearts)

    local font = Game.fonts.prompt or gfx.getSystemFont()
    local remaining = math.ceil(self.previewTime - self.phaseTimer)
    if remaining < 0 then
        remaining = 0
    end

    GameUtils.drawTextWithUnderlay(tostring(remaining), 8, 8, font)
    end

    function scene:drawCrankFill()
        local interior = self.barInterior.crank
        local fillHeight = math.floor(self.crankLevel * interior.h + 0.5)

        if fillHeight <= 0 then
            return
        end

        local fillY = interior.y + interior.h - fillHeight

        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(interior.x, fillY, interior.w, fillHeight)

        -- tiny cap line so the current level is easy to see
        gfx.setColor(gfx.kColorBlack)
        gfx.drawLine(interior.x, fillY, interior.x + interior.w - 1, fillY)
        gfx.setColor(gfx.kColorBlack)
    end

    function scene:drawBars()
    gfx.clear(gfx.kColorBlack)

    if self.images.crankBar then
        self.images.crankBar:draw(0, 0)
    end

    self:drawCrankFill()

    if self.images.lrBar then
        self.images.lrBar:draw(0, 0)
    end

    if self.images.pointer then
        local pointerX = math.floor(self.barInterior.lr.x + self.pointerT * self.barInterior.lr.w - math.floor(self.pointerBBox.w / 2))
        GameUtils.drawShiftedFullScreenImage(self.images.pointer, self.pointerBBox, pointerX, self.pointerBBox.y)
    end

    if self.crosshair then
        GameUtils.drawCrosshair(self.crosshair.x, self.crosshair.y)
    end

    GameUtils.drawHearts(self.hearts)

    local font = Game.fonts.prompt or gfx.getSystemFont()
    GameUtils.drawTextWithUnderlay("A: strike", 320, 188, font)
    end

    function scene:drawHitShow()
        gfx.clear(gfx.kColorBlack)

        if self.images.brain then
            self.images.brain:draw(0, 0)
        end

        self:drawDemons()

        if self.crosshair then
            GameUtils.drawCrosshair(math.floor(self.crosshair.brainX + 0.5), math.floor(self.crosshair.brainY + 0.5))
        end

        GameUtils.drawHearts(self.hearts)
    end

    function scene:draw()
        if self.phase == "preview" then
            self:drawPreview()
        elseif self.phase == "bars" or self.phase == "miss_pause" or self.phase == "fail_return" then
            self:drawBars()
        else
            self:drawHitShow()
        end

        if self.flashCount > 0 and self.flashCount % 2 == 0 then
            gfx.setColor(gfx.kColorWhite)
            gfx.fillRect(0, 0, 400, 240)
            gfx.setColor(gfx.kColorBlack)
        end
    end

    return scene
end