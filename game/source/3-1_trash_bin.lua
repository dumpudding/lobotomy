local gfx = playdate.graphics
local pd <const> = playdate

function newTrashScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/trash_can/trash_panda"

    if scene.state.trashItems == nil then
        scene.state.trashItems = {
            needle = "bin",
            gloves = "bin",
            vial = "bin",
            scissors = "bin",
            gauze = "bin"
        }
    end

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
            line = "would be useful if i was profusely bleeding… but then again, it's probably dirty"
        }
    }

    scene.cursor = {
        x = 320,
        y = 120,
        speed = 3
    }

    scene.dialogue = nil
    scene.fling = nil
    scene.flingAccumulator = 0
    scene.lastCrankDirection = 1

    function scene:getItemImage(name)
        return self.images[name]
    end

    function scene:getNearbyItemName()
        if self.state.heldItem ~= nil then
            return nil
        end

        local bestName = nil
        local bestDist = 999

        for name, location in pairs(self.state.trashItems) do
            if location == "bin" and self.itemData[name] ~= nil then
                local bbox = self.itemData[name].bbox
                local d = GameUtils.pointRectDistance(self.cursor.x, self.cursor.y, bbox)
                if d < bestDist then
                    bestDist = d
                    bestName = name
                end
            end
        end

        if bestName ~= nil and bestDist <= 6 then
            return bestName
        end

        return nil
    end

    function scene:startFling(direction)
        local held = self.state.heldItem
        if held == nil or self.itemData[held] == nil then
            return
        end

        local data = self.itemData[held]
        local startX = self.cursor.x - data.bbox.w - 4
        local startY = self.cursor.y - math.floor(data.bbox.h / 2)

        self.dialogue = nil
        self.fling = {
            item = held,
            x = startX,
            y = startY,
            vx = direction >= 0 and 620 or -620,
            vy = -110
        }
    end

    function scene:updateFling(dt)
        if self.fling == nil then
            return
        end

        self.fling.x = self.fling.x + self.fling.vx * dt
        self.fling.y = self.fling.y + self.fling.vy * dt

        if self.fling.x < -80 or self.fling.x > 480 or self.fling.y < -80 or self.fling.y > 320 then
            local item = self.fling.item
            self.state.trashItems[item] = "gone"
            self.state.heldItem = nil
            self.state.lobbyTrashPile = true
            self.fling = nil
            self.flingAccumulator = 0
        end
    end

    function scene:updateCursor()
        if pd.buttonIsPressed(pd.kButtonLeft) then
            self.cursor.x = self.cursor.x - self.cursor.speed
        end

        if pd.buttonIsPressed(pd.kButtonRight) then
            self.cursor.x = self.cursor.x + self.cursor.speed
        end

        if pd.buttonIsPressed(pd.kButtonUp) then
            self.cursor.y = self.cursor.y - self.cursor.speed
        end

        if pd.buttonIsPressed(pd.kButtonDown) then
            self.cursor.y = self.cursor.y + self.cursor.speed
        end

        self.cursor.x = GameUtils.clamp(self.cursor.x, 0, 399)
        self.cursor.y = GameUtils.clamp(self.cursor.y, 0, 239)
    end

    function scene:returnFromTrash()
        local returnScene = self.state.trashReturnScene
        self.state.trashReturnScene = nil

        if returnScene == "floor3Room" and newFloor3RoomScene ~= nil then
            Game:switchScene(function(nextState)
                return newFloor3RoomScene(nextState, "fromTrash")
            end)
            return
        end

        Game:switchScene(function(nextState)
            return newLobbyScene(nextState)
        end)
    end

    function scene:update(dt)
        self:updateCursor()
        self:updateFling(dt)

        if self.state.heldItem ~= nil and self.fling == nil then
            local change = pd.getCrankChange()

            if math.abs(change) > 0.1 then
                self.lastCrankDirection = change >= 0 and 1 or -1
                self.flingAccumulator = self.flingAccumulator + math.abs(change)
            end

            if self.flingAccumulator >= 1 then
                self:startFling(self.lastCrankDirection)
                self.flingAccumulator = 0
                return
            end
        end

        if self.dialogue ~= nil then
            if pd.buttonJustPressed(pd.kButtonA) then
                if GameUtils.advanceDialogue(self.dialogue) then
                    self.dialogue = nil
                end
            end
            return
        end

        local nearby = self:getNearbyItemName()
        if nearby ~= nil and pd.buttonJustPressed(pd.kButtonA) then
            self.state.heldItem = nearby
            self.state.trashItems[nearby] = "held"
            self.flingAccumulator = 0
            self.lastCrankDirection = 1
            self.dialogue = GameUtils.makeDialogue(self.itemData[nearby].line)
            return
        end

        if pd.buttonJustPressed(pd.kButtonB) then
            self:returnFromTrash()
        end
    end

    function scene:drawStaticItems()
        for name, location in pairs(self.state.trashItems) do
            if location == "bin" then
                local image = self:getItemImage(name)
                if image ~= nil then
                    image:draw(0, 0)
                end
            end
        end
    end

    function scene:drawHeldItem()
        local held = self.state.heldItem
        if held == nil or self.fling ~= nil or self.itemData[held] == nil then
            return
        end

        local image = self:getItemImage(held)
        local bbox = self.itemData[held].bbox
        if image == nil or bbox == nil then
            return
        end

        local drawX = self.cursor.x - bbox.w - 4
        local drawY = self.cursor.y - math.floor(bbox.h / 2)
        GameUtils.drawShiftedFullScreenImage(image, bbox, drawX, drawY)
    end

    function scene:drawFlingItem()
        if self.fling == nil then
            return
        end

        local image = self:getItemImage(self.fling.item)
        local bbox = self.itemData[self.fling.item].bbox
        if image ~= nil and bbox ~= nil then
            GameUtils.drawShiftedFullScreenImage(image, bbox, math.floor(self.fling.x), math.floor(self.fling.y))
        end
    end

    function scene:drawCursor()
        if self.images.hand == nil then
            return
        end

        local drawX = math.floor(self.cursor.x - math.floor(self.handBBox.w / 2))
        local drawY = math.floor(self.cursor.y - math.floor(self.handBBox.h / 2))
        GameUtils.drawShiftedFullScreenImage(self.images.hand, self.handBBox, drawX, drawY)
    end

    function scene:drawPrompt()
        local font = Game.fonts.prompt or gfx.getSystemFont()
        local nearby = self:getNearbyItemName()

        if nearby ~= nil then
            local data = self.itemData[nearby]
            local prompt = "A: pick up"
            local w = font:getTextWidth(prompt)
            local x = GameUtils.clamp(data.promptAnchor.x, 4, 396 - w)
            local y = GameUtils.clamp(data.promptAnchor.y, 4, 228)
            GameUtils.drawTextWithUnderlay(prompt, x, y, font)
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.images.base ~= nil then
            self.images.base:draw(0, 0)
        end

        self:drawStaticItems()
        self:drawHeldItem()
        self:drawFlingItem()
        self:drawCursor()
        self:drawPrompt()
        GameUtils.drawDialogue(self.dialogue)
    end

    return scene
end
