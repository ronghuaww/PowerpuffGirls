--!Type(UI)

--------------------------------
---- UXML ELEMENT BINDINGS -----
--------------------------------
--!Bind
local _meterLabel: Label = nil
--!Bind
local _arrowIndicator: VisualElement = nil

--------------------------------
------     CONSTANTS      ------
--------------------------------
local BAR_HEIGHT = 100

--------------------------------
------     LOCAL STATE    ------
--------------------------------
local currentValue: number = 0
local maxValue: number = 100

--------------------------------
------  LOCAL FUNCTIONS   ------
--------------------------------
local function updateArrowPosition()
    if not _arrowIndicator then return end
    
    local _percentage = 0
    if maxValue > 0 then
        _percentage = currentValue / maxValue
    end
    _percentage = math.max(0, math.min(1, _percentage))
    
    -- Invert percentage since bar goes from top (100%) to bottom (0%)
    local _invertedPercentage = 1 - _percentage
    
    -- Calculate position (0% at bottom, 100% at top)
    local _position = _invertedPercentage * BAR_HEIGHT
    
    _arrowIndicator.style.top = StyleLength.new(Length.new(_position))
end

--------------------------------
------  PUBLIC FUNCTIONS  ------
--------------------------------
function SetValue(value: number)
    currentValue = math.max(0, value)
    updateArrowPosition()
end

function SetMaxValue(max: number)
    maxValue = math.max(1, max)
    updateArrowPosition()
end

function SetPercentage(percentage: number)
    percentage = math.max(0, math.min(100, percentage))
    currentValue = (percentage / 100) * maxValue
    updateArrowPosition()
end

function GetValue(): number
    return currentValue
end

function GetMaxValue(): number
    return maxValue
end

function GetPercentage(): number
    if maxValue <= 0 then return 0 end
    return (currentValue / maxValue) * 100
end

function SetLabel(text: string)
    if _meterLabel then
        _meterLabel.text = text
    end
end

function AddValue(amount: number)
    SetValue(currentValue + amount)
end

function SubtractValue(amount: number)
    SetValue(currentValue - amount)
end

--------------------------------
------  LIFECYCLE HOOKS   ------
--------------------------------
function self:Start()
    print("RoomMeterHUD: Initialized")
    
    -- Initialize at 50%
    SetPercentage(50)
end
