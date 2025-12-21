--!Type(UI)

--------------------------------
------  SERIALIZED FIELDS  ------
--------------------------------
--!SerializeField
local loadingImage: Texture2D = nil

--!SerializeField
local delayBeforeFade: number = 2.0

--!SerializeField
local fadeDuration: number = 1.5

--------------------------------
---- UXML ELEMENT BINDINGS -----
--------------------------------
--!Bind
local _loadingBackground: VisualElement = nil

--!Bind
local _loadingScreen: UILuaView = nil

--------------------------------
------  LIFECYCLE HOOKS   ------
--------------------------------
function self:Start()
    if not _loadingBackground then
        print("ERROR: LoadingScreen background element not found")
        return
    end

    -- Set the background image if provided
    if loadingImage then
        _loadingBackground.style.backgroundImage = loadingImage
    end

    -- Wait for delay, then fade out
    Timer.After(delayBeforeFade, function()
        _loadingScreen:TweenOpacity(1, 0)
            :Duration(fadeDuration)
            :EaseOutQuadratic()
            :OnStop(function()
                _loadingScreen:SetDisplay(false)
            end)
            :Play()
    end)
end
