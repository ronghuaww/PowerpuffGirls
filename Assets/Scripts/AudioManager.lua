--!Type(Module)

--------------------------------
------  SERIALIZED FIELDS  ------
--------------------------------
--!SerializeField
local bgmRare: AudioShader = nil

--!SerializeField
local bgmEpic: AudioShader = nil

--!SerializeField
local bgmLegendary: AudioShader = nil

--!SerializeField
local sfxButtonClick: AudioShader = nil

--!SerializeField
local sfxSendIngredient: AudioShader = nil

--!SerializeField
local sfxSubmitOrder: AudioShader = nil

--!SerializeField
local musicVolume: number = 0.5

--!SerializeField
local sfxVolume: number = 1.0

--------------------------------
------     CONSTANTS      ------
--------------------------------
local BGM_RARE = "rare"
local BGM_EPIC = "epic"
local BGM_LEGENDARY = "legendary"

--------------------------------
------     LOCAL STATE    ------
--------------------------------
local currentBgm: string = ""
local currentMusicSource: AudioSource = nil

--------------------------------
------  LOCAL FUNCTIONS   ------
--------------------------------
local function getBgmShader(bgmType: string): AudioShader | nil
    if bgmType == BGM_RARE then
        return bgmRare
    elseif bgmType == BGM_EPIC then
        return bgmEpic
    elseif bgmType == BGM_LEGENDARY then
        return bgmLegendary
    end
    return nil
end

--------------------------------
------  PUBLIC FUNCTIONS  ------
--------------------------------
function PlayingMusic(bgmType: string, fadeIn: boolean?)
    if not bgmType then
        print("ERROR: No bgmType provided to PlayMusic")
        return
    end

    local _shader = getBgmShader(bgmType)
    if not _shader then
        print("ERROR: Invalid bgmType or AudioShader not assigned: " .. bgmType)
        return
    end

    -- Stop current music if playing different track
    if currentBgm ~= bgmType then
        Audio:StopMusic(true)
    end

    currentBgm = bgmType
    local _shouldFadeIn = fadeIn ~= false
    Audio:PlayMusic(_shader, musicVolume, _shouldFadeIn, true)
    print("Playing background music: " .. bgmType)
end

function StopMusic(fadeOut: boolean?)
    local _shouldFadeOut = fadeOut ~= false
    Audio:StopMusic(_shouldFadeOut)
    currentBgm = ""
    print("Stopped background music")
end

function SetMusicVolume(volume: number)
    if volume < 0 then volume = 0 end
    if volume > 1 then volume = 1 end
    musicVolume = volume
    Audio.musicVolume = volume
end

function PlayButtonClick()
    if not sfxButtonClick then
        Sounds.ButtonClick:Play()
        return
    end
    Audio:PlaySoundGlobal(sfxButtonClick, sfxVolume, 1.0, false)
end

function PlaySendIngredient()
    if not sfxSendIngredient then
        print("ERROR: sfxSendIngredient AudioShader not assigned")
        return
    end
    Audio:PlaySoundGlobal(sfxSendIngredient, sfxVolume, 1.0, false)
end

function PlaySubmitOrder()
    if not sfxSubmitOrder then
        print("ERROR: sfxSubmitOrder AudioShader not assigned")
        return
    end
    Audio:PlaySoundGlobal(sfxSubmitOrder, sfxVolume, 1.0, false)
end

function SetSfxVolume(volume: number)
    if volume < 0 then volume = 0 end
    if volume > 1 then volume = 1 end
    sfxVolume = volume
end

function GetCurrentBgm(): string
    return currentBgm
end

function IsMusicPlaying(): boolean
    return Audio.isPlaying
end

--------------------------------
------  LIFECYCLE HOOKS   ------
--------------------------------
function self:ClientAwake()
    Audio.musicVolume = musicVolume
end
