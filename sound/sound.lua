Sound = {};

-- Play telephone ring (falls back to game sound if no custom audio)
local function playTelephone()
    -- Try playing custom sound file first (.ogg format for WoW 12.1)
    local soundFile = "Interface\\Addons\\PikaJohnes\\sound\\telephone.ogg";
    
    -- Check if we can use it (file exists check in 12.1)
    pcall(function()
        PlaySoundFile(soundFile, "Master");
    end);
end

function Sound.Play()
    pcall(playTelephone);
end
