local gfx = playdate.graphics

function newTitleScene(state)
    local scene = {}

    scene.state = state
    scene.musicPath = "png_and_wavs/title_screen/alienazzbeat"
    scene.warningImage = GameUtils.loadImage("png_and_wavs/title_screen/warning_v1")
    scene.introAnim = GameUtils.loadAnim("png_and_wavs/title_screen/brain for intro screen with buttons.gif", 8)

    scene.timer = 0
    scene.warningDuration = 5.0
    scene.fadeDuration = 0.8

    function scene:update(dt)
        self.timer = self.timer + dt

        if self.introAnim then
            self.introAnim:update(dt)
        end

        if self.timer >= self.warningDuration + self.fadeDuration then
            if playdate.buttonJustPressed(playdate.kButtonA) then
                Game:switchScene(function(nextState)
                    return newLobbyScene(nextState)
                end)
            end
        end
    end

    function scene:draw()
        gfx.clear(gfx.kColorBlack)

        if self.timer < self.warningDuration then
            if self.warningImage then
                self.warningImage:draw(0, 0)
            end
            return
        end

        local fadeT = GameUtils.clamp((self.timer - self.warningDuration) / self.fadeDuration, 0, 1)

        if fadeT < 1 then
            if self.warningImage then
                self.warningImage:drawFaded(0, 0, 1 - fadeT, gfx.image.kDitherTypeBayer8x8)
            end

            if self.introAnim then
                self.introAnim:drawFaded(0, 0, fadeT)
            end
        else
            if self.introAnim then
                self.introAnim:draw(0, 0)
            end
        end
    end

    return scene
end
