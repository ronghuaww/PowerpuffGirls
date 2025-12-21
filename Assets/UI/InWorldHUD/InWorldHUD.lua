--!Type(UI)

--!Bind
local _image: VisualElement = nil

--!SerializeField
local spriteIcon: Texture2D = nil

function self:Start()
    if _image then
        _image.style.backgroundImage = spriteIcon
    end
end