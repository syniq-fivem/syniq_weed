---@param title string Title of the progressbar
---@param duration number Duration of progressbar
---@param anim string Animation clip
---@param dict string Animation dict
---@param flag number Flag of animation

function ProgressBar(title, duration, anim, dict, flag)
    if lib.progressBar({
        duration = duration,
        label = title,
        useWhileDead = false,
        allowCuffed = false,
        allowFalling = false,
        allowSwimming = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true,
        },
        anim = {
            dict = dict or nil,
            clip = anim or nil,
            flag = flag,
        },
    }) then return true else return false end
end

---@param title string Title of the progressbar
---@param text string Notification text
---@param duration number Duration of progressbar
---@param type string Type of notifications

function Notification(title, text, duration, type)
    lib.notify({
        title = title,
        description = text,
        type = type,
        showDuration = true,
        duration = duration,
        position = 'top',
    })
end

RegisterNetEvent('syniq_weed:notify', Notification)

---@param text string TextUI text
function TextUI(text)
    lib.showTextUI(text, {
        position = "right-center",
    })
end

function HideTextUI()
    lib.hideTextUI()
end