local gfx = playdate.graphics

function newTrashScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/trash_can/trash_panda"

    scene.images = {
        base = GameUtils.loadImage("png_and_wavs/trash_can/empty_bin"),
        hand = GameUtils.loadImage("png_and_wavs/trash_can/hand_cursor"),
        needle = GameUtils.loadImage("png_and_wavs/trash_can/needle"),
        gloves = GameUtils.loadImage("png_and_wavs/trash_can/gloves"),
        vial = GameUtils.loadImage("png_and_wavs/trash_can/vial"),
        scissors = GameUtils.loadImage("png_and_wavs/trash_can/scissors"),
        gauze = GameUtils.loadImage("png_and_wavs/trash_can/gauze")
    }

    scene.handBBox = { x = 311, y = 110, w = 21, h = 22 }
    scene.itemData = {
        needle = {
            bbox = { x = 221, y = 158, w = 31, h = 30 },
            promptAnchor = { x = 250, y = 164 },
            line = "that would work!"
        },
        gloves = {
            bbox = { x = 242, y = 120, w = 22, h = 27 },
            promptAnchor = { x = 266, y = 126 },
            line = "dont know what i would need that for…"
        },
        vial = {
            bbox = { x = 218, y = 66, w = 24, h = 26 },
            promptAnchor = { x = 246, y = 72 },
            line = "mmm… goopy."
        },
        scissors = {
            bbox = { x = 196, y = 114, w = 20, h = 29 },
            promptAnchor = { x = 218, y = 120 },
            line = "not sharp enough…"
        },
        gauze = {
            bbox = { x = 153, y = 79, w = 25, h = 26 },
            promptAnchor = { x = 118, y = 84 },
            line = "would be useful if i was profusely bleeding… but then again, it’s probably dirty"
        }
    }

    scene.cursor = {
        x = 320,
        y = 120,
        speed = 3
    }

    scene.dialogue = nil
    scene.fling = nil

    function scene:getItemImage(name)
        return self.images[name]
    end

    function scene:getHeldItem()
        return self.state.heldItem
    end

    function scene:getNearbyItemName()
        if self.state.heldItem ~= nil then
            return nil
        end

        local bestName = nil
        local bestDist = 999

        for name, location in pairs(self.state.trashItems) do
            if location == "bin" then
                local bbox = self.itemData[name].bbox
                local d = GameUtils.pointRectDistance(self.cursor.x, self.cursor.y, bbox)
                if d < bestDist then
                    bestDist = d
                    bestName = name
                end
            end
        end

        if bestName and bestDist <= 5 then
            return bestName
        end

        return nil
    end

    function scene:startFling(change)
        local held = self.state.heldItem
        if not held then
            return
        end

        local data = self.itemData[held]
        local startX = self.cursor.x - data.bbox.w - 4
        local startY = self.cursor.y - math.floor(data.bbox.h / 2)

        self.fling = {
            item = held,
            x = startX,
            y = startY,
            vx = change >= 0 and 520 or -520,
            vy = -80
        }
    end

    function scene:updateFling(dt)
        if not self.fling then
            return
        end

        self.fling.x = self.fling.x + self.fling.vx * dt
        self.fling.y = self.fling.y + self.fling.vy * dt

        if self.fling.x < -60 or self.fling.x > 460 or self.fling.y < -60 or self.fling.y > 300 then
            local item = self.fling.item
            self.state.trashItems[item] = "gone"
            self.state.heldItem = nil
            self.state.lobbyTrashPile = true
            self.fling = nil
        end
    end

    function scene:updateCursor()
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
    end

    function scene:update(dt)
        self:updateCursor()
        self:updateFling(dt)

        if self.dialogue then
            if playdate.buttonJustPressed(playdate.kButtonA) then
                if GameUtils.advanceDialogue(self.dialogue) then
                    self.dialogue = nil
                end
            end
        else
            local nearby = self:getNearbyItemName()
            if nearby and playdate.buttonJustPressed(playdate.kButtonA) then
                self.state.heldItem = nearby
                self.state.trashItems[nearby] = "held"
                self.dialogue = GameUtils.makeDialogue(self.itemData[nearby].line)
            end
        end

        if self.state.heldItem and not self.fling then
            local change = playdate.getCrankChange()
            if math.abs(change) >= 8 then
                self:startFling(change)
            end
        end

        if playdate.buttonJustPressed(playdate.kButtonB) then
            Game:switchScene(function(nextState)
                return newLobbyScene(nextState)
            end)
        end
    end

    function scene:drawStaticItems()
        for name, location in pairs(self.state.trashItems) do
            if location == "bin" then
                local image = self:getItemImage(name)
                if image then
                    image:draw(0, 0)
                end
            end
        end
    end

    function scene:drawHeldItem()
        local held = self.state.heldItem
        if not held or self.fling then
            return
        end

        local image = self:getItemImage(held)
        local bbox = self.itemData[held].bbox
        if not image or not bbox then
            return
        end

        local drawX = self.cursor.x - bbox.w - 4
        local drawY = self.cursor.y - math.floor(bbox.h / 2)
        GameUtils.drawShiftedFullScreenImage(image, bbox, drawX, drawY)
    end

    function scene:drawFlingItem()
        if not self.fling then
            return
        end

        local image = self:getItemImage(self.fling.item)
        local bbox = self.itemData[self.fling.item].bbox
        if image and bbox then
            GameUtils.drawShiftedFullScreenImage(image, bbox, math.floor(self.fling.x), math.floor(self.fling.y))
        end
    end

    function scene:drawCursor()
        if not self.images.hand then
            return
        end

        local drawX = math.floor(self.cursor.x - math.floor(self.handBBox.w / 2))
        local drawY = math.floor(self.cursor.y - math.floor(self.handBBox.h / 2))
        GameUtils.drawShiftedFullScreenImage(self.images.hand, self.handBBox, drawX, drawY)
    end

    function scene:drawPrompt()
        local font = Game.fonts.prompt or gfx.getSystemFont()
        local nearby = self:getNearbyItemName()

        font:drawText("B: exit trash", 8, 8)

        if nearby then
            local data = self.itemData[nearby]
            local prompt = "A: pick up"
            local w = font:getTextWidth(prompt)
            local x = GameUtils.clamp(data.promptAnchor.x, 4, 396 - w)
            local y = GameUtils.clamp(data.promptAnchor.y, 4, 228)
            font:drawText(prompt, x, y)
        end

        if self.state.heldItem then
            font:drawText("crank to fling aside", 274, 210)
        end
    end

    function scene:draw()
    gfx.clear(gfx.kColorBlack)

    if self.images.bin then
        self.images.bin:draw(0, 0)
    end

    for _, item in ipairs(self.items) do
        if item.state == "bin" and item.image then
            item.image:draw(0, 0)
        end
    end

    if self.heldItem and self.heldItem.image then
        local drawX = self.cursorX - 10
        local drawY = self.cursorY - 8
        self.heldItem.image:draw(drawX, drawY)
    end

    if self.handImage then
        self.handImage:draw(self.cursorX, self.cursorY)
    end

    local font = Game.fonts.prompt or gfx.getSystemFont()
    GameUtils.drawTextWithUnderlay("B: exit trash", 10, 8, font)

    local hovered = self:getHoveredItem()
    if hovered and self.heldItem == nil then
        GameUtils.drawTextWithUnderlay("A: pick up", 10, 26, font)
    end

    if self.heldItem then
        GameUtils.drawTextWithUnderlay("crank to fling aside", 252, 210, font)
    end

    GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end
