local gfx = playdate.graphics
local snd = playdate.sound
local pd <const> = playdate

local function loadImageFirst(paths)
    for i = 1, #paths do
        local image = GameUtils.loadImage(paths[i])
        if image then
            return image
        end
    end

    return nil
end

local function loadAnimFirst(paths, fps, loop, speedScale)
    for i = 1, #paths do
        local anim = GameUtils.loadAnim(paths[i], fps, loop, speedScale)
        if anim and anim.getFrame and anim:getFrame() then
            return anim
        end
    end

    return nil
end

local function pickExistingAudioPath(paths)
    for i = 1, #paths do
        local player = snd.fileplayer.new(paths[i])
        if player then
            player:stop()
            return paths[i]
        end
    end

    return nil
end

local function drawCenteredImage(image)
    if not image then
        return
    end

    local w, h = image:getSize()
    local x = math.floor((400 - w) / 2)
    local y = math.floor((240 - h) / 2)
    image:draw(x, y)
end

local function drawCenteredImageFaded(image, alpha)
    if not image then
        return
    end

    local w, h = image:getSize()
    local x = math.floor((400 - w) / 2)
    local y = math.floor((240 - h) / 2)
    image:drawFaded(x, y, alpha, gfx.image.kDitherTypeBayer8x8)
end

local function drawMissingText(text)
    local font = Game.fonts.dialog or gfx.getSystemFont()
    local w = font:getTextWidth(text)
    GameUtils.drawTextWithUnderlay(text, math.floor((400 - w) / 2), 116, font)
end

function newEndingCreditsScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = pickExistingAudioPath({
        "png_and_wavs/outro/car_alarm",
        "png_and_wavs/outro/car_alarm.wav"
    })

    scene.credits = loadAnimFirst({
        "png_and_wavs/outro/ending_credits",
        "png_and_wavs/outro/ending_credits.gif"
    }, 0.7, true, 1.0)

    function scene:update(dt)
        if self.credits then
            self.credits:update(dt)
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.credits then
            self.credits:draw(0, 0)
        else
            drawMissingText("missing: ending_credits")
        end
    end

    return scene
end

function newSneakEndingScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = pickExistingAudioPath({
        "png_and_wavs/the_sneak_ending/success_questionmark",
        "png_and_wavs/the_sneak_ending/success_questionmark.wav",
        "png_and_wavs/outro/the_sneak_ending/success_questionmark",
        "png_and_wavs/outro/the_sneak_ending/success_questionmark.wav"
    })

    scene.anim = loadAnimFirst({
        "png_and_wavs/the_sneak_ending/lobotomy_success",
        "png_and_wavs/the_sneak_ending/lobotomy_success.gif",
        "png_and_wavs/outro/the_sneak_ending/lobotomy_success",
        "png_and_wavs/outro/the_sneak_ending/lobotomy_success.gif"
    }, 8, false, 1.0)

    function scene:update(dt)
        if self.anim then
            self.anim:update(dt)

            if self.anim.finished then
                Game:go("endingCredits")
                return
            end
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.anim then
            self.anim:draw(0, 0)
        else
            drawMissingText("missing: lobotomy_success")
        end
    end

    return scene
end

function newBadEndingScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = pickExistingAudioPath({
        "png_and_wavs/the_bad_ending/oh-wow-the-ceiling-fan-is-talking-to-me",
        "png_and_wavs/the_bad_ending/oh-wow-the-ceiling-fan-is-talking-to-me.wav",
        "png_and_wavs/the_bad_ending/oh-wow-the-ceiling-fan-is-talking-to",
        "png_and_wavs/the_bad_ending/oh-wow-the-ceiling-fan-is-talking-to.wav",
        "png_and_wavs/outro/the_bad_ending/oh-wow-the-ceiling-fan-is-talking-to-me",
        "png_and_wavs/outro/the_bad_ending/oh-wow-the-ceiling-fan-is-talking-to-me.wav",
        "png_and_wavs/outro/the_bad_ending/oh-wow-the-ceiling-fan-is-talking-to",
        "png_and_wavs/outro/the_bad_ending/oh-wow-the-ceiling-fan-is-talking-to.wav"
    })

    scene.images = {
        dizzy = loadImageFirst({
            "png_and_wavs/the_bad_ending/1_dizzy",
            "png_and_wavs/the_bad_ending/1_dizzy.png",
            "png_and_wavs/outro/the_bad_ending/1_dizzy",
            "png_and_wavs/outro/the_bad_ending/1_dizzy.png"
        }),
        room = loadImageFirst({
            "png_and_wavs/the_bad_ending/pixel_room_config",
            "png_and_wavs/the_bad_ending/pixel_room_config.png",
            "png_and_wavs/outro/the_bad_ending/pixel_room_config",
            "png_and_wavs/outro/the_bad_ending/pixel_room_config.png"
        }),
        sue = loadImageFirst({
            "png_and_wavs/the_bad_ending/sue_pixely",
            "png_and_wavs/the_bad_ending/sue_pixely.png",
            "png_and_wavs/outro/the_bad_ending/sue_pixely",
            "png_and_wavs/outro/the_bad_ending/sue_pixely.png"
        })
    }

    scene.timer = 0
    scene.holdTime = 10
    scene.fadeTime = 6
    scene.dizzyTime = 3

    function scene:drawRoomComposite(alpha)
        if self.images.room then
            drawCenteredImageFaded(self.images.room, alpha)
        end

        if self.images.room and self.images.sue then
            local rw, rh = self.images.room:getSize()
            local sw, sh = self.images.sue:getSize()

            local roomX = math.floor((400 - rw) / 2)
            local roomY = math.floor((240 - rh) / 2)

            local sueX = roomX + math.floor(rw * 0.47) - math.floor(sw / 2)
            local sueY = roomY + rh - sh - 18

            self.images.sue:drawFaded(sueX, sueY, alpha, gfx.image.kDitherTypeBayer8x8)
            return
        end

        if not self.images.room and self.images.sue then
            drawCenteredImageFaded(self.images.sue, alpha)
        end
    end

    function scene:update(dt)
        self.timer = self.timer + dt

        if self.timer >= self.holdTime + self.fadeTime then
            Game:go("endingCredits")
            return
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        local alpha = 1

        if self.timer > self.holdTime then
            alpha = 1 - ((self.timer - self.holdTime) / self.fadeTime)
            alpha = GameUtils.clamp(alpha, 0, 1)
        end

        if self.timer < self.dizzyTime and self.images.dizzy then
            drawCenteredImageFaded(self.images.dizzy, alpha)
            return
        end

        if self.images.room or self.images.sue then
            self:drawRoomComposite(alpha)
        else
            drawMissingText("missing: bad ending assets")
        end
    end

    return scene
end

function newHealthyEndingScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = pickExistingAudioPath({
        "png_and_wavs/the_healthy_ending/enlightenment",
        "png_and_wavs/the_healthy_ending/enlightenment.wav",
        "png_and_wavs/outro/the_healthy_ending/enlightenment",
        "png_and_wavs/outro/the_healthy_ending/enlightenment.wav"
    })

    scene.anim1 = loadAnimFirst({
        "png_and_wavs/the_healthy_ending/mateo_1whatup",
        "png_and_wavs/the_healthy_ending/mateo_1whatup.gif",
        "png_and_wavs/outro/the_healthy_ending/mateo_1whatup",
        "png_and_wavs/outro/the_healthy_ending/mateo_1whatup.gif"
    }, 8, false, 1.0)

    scene.waitImage = loadImageFirst({
        "png_and_wavs/the_healthy_ending/mateo_1-1wait",
        "png_and_wavs/the_healthy_ending/mateo_1-1wait.png",
        "png_and_wavs/outro/the_healthy_ending/mateo_1-1wait",
        "png_and_wavs/outro/the_healthy_ending/mateo_1-1wait.png"
    })

    scene.anim2 = loadAnimFirst({
        "png_and_wavs/the_healthy_ending/mateo_2concernedohno",
        "png_and_wavs/the_healthy_ending/mateo_2concernedohno.gif",
        "png_and_wavs/outro/the_healthy_ending/mateo_2concernedohno",
        "png_and_wavs/outro/the_healthy_ending/mateo_2concernedohno.gif"
    }, 8, false, 1.0)

    scene.phase = "mateo1"
    scene.blackTimer = 0

    function scene:update(dt)
        if self.phase == "mateo1" then
            if self.anim1 then
                self.anim1:update(dt)

                if self.anim1.finished then
                    self.phase = "wait"
                end
            else
                self.phase = "wait"
            end
            return
        end

        if self.phase == "wait" then
            if pd.buttonJustPressed(pd.kButtonA) then
                Game:switchScene(function(nextState)
                    return newLobotomyDecisionScene(nextState)
                end)
                return
            end

            if pd.buttonJustPressed(pd.kButtonB) then
                if self.anim2 and self.anim2.reset then
                    self.anim2:reset()
                end
                self.phase = "mateo2"
                return
            end

            return
        end

        if self.phase == "mateo2" then
            if self.anim2 then
                self.anim2:update(dt)

                if self.anim2.finished then
                    self.phase = "black"
                    self.blackTimer = 0
                end
            else
                self.phase = "black"
                self.blackTimer = 0
            end
            return
        end

        if self.phase == "black" then
            self.blackTimer = self.blackTimer + dt

            if self.blackTimer >= 3 then
                Game:go("endingCredits")
                return
            end
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.phase == "mateo1" then
            if self.anim1 then
                self.anim1:draw(0, 0)
            else
                drawMissingText("missing: mateo_1whatup")
            end
            return
        end

        if self.phase == "wait" then
            if self.waitImage then
                drawCenteredImage(self.waitImage)
            else
                drawMissingText("missing: mateo_1-1wait")
            end
            return
        end

        if self.phase == "mateo2" then
            if self.anim2 then
                self.anim2:draw(0, 0)
            else
                drawMissingText("missing: mateo_2concernedohno")
            end
            return
        end
    end

    return scene
end
