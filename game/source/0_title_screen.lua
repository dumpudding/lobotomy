local gfx = playdate.graphics

function newTitleScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/title_screen/alienazzbeat"

    scene.warningImage = GameUtils.loadImage("png_and_wavs/title_screen/warning_v1")
    scene.introAnim = GameUtils.loadAnim("png_and_wavs/title_screen/brain for intro screen with buttons.gif", 8, true, 1.0)

    scene.phase = "warning"
    scene.timer = 0
    scene.warningDuration = 5.0
    scene.fadeDuration = 0.8

    function scene:goToNextScene()
        Game:switchScene(function(nextState)
            return newNightIntroScene(nextState)
        end)
    end

    function scene:update(dt)
        if GameUtils.skipComboJustPressed() then
            if self.phase == "warning" or self.phase == "fade" then
                self.phase = "intro"
                self.timer = 0

                if self.introAnim then
                    self.introAnim:reset()
                end

                return
            end

            if self.phase == "intro" then
                self:goToNextScene()
                return
            end
        end

        if self.phase == "warning" then
            self.timer = self.timer + dt

            if self.timer >= self.warningDuration then
                self.phase = "fade"
                self.timer = 0
            end

            return
        end

        if self.phase == "fade" then
            self.timer = self.timer + dt

            if self.introAnim then
                self.introAnim:update(dt)
            end

            if self.timer >= self.fadeDuration then
                self.phase = "intro"
                self.timer = 0
            end

            return
        end

        if self.phase == "intro" then
            if self.introAnim then
                self.introAnim:update(dt)
            end

            if playdate.buttonJustPressed(playdate.kButtonA) then
                self:goToNextScene()
                return
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

        if self.phase == "fade" then
            local fadeT = GameUtils.clamp(self.timer / self.fadeDuration, 0, 1)

            if self.warningImage then
                self.warningImage:drawFaded(0, 0, 1 - fadeT, gfx.image.kDitherTypeBayer8x8)
            end

            if self.introAnim then
                self.introAnim:drawFaded(0, 0, fadeT)
            end

            return
        end

        if self.introAnim then
            self.introAnim:draw(0, 0)
        end
    end

    return scene
end