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
local BAR_HEIGHT = 230

--------------------------------
------     LOCAL STATE    ------
--------------------------------
local currentValue: number = 0
local maxValue: number = 500

--------------------------------
------  LOCAL FUNCTIONS   ------
--------------------------------
local function updateArrowPosition(value: number)
    if not _arrowIndicator then return end
    
    local _percentage = 0
    if maxValue > 0 then
        _percentage = value / maxValue
    end
    _percentage = math.max(0, math.min(1, _percentage))

    print("Updating arrow position: " .. tostring(_percentage * 100) .. "%")
    
    -- Invert percentage since bar goes from top (100%) to bottom (0%)
    local _invertedPercentage = 1 - _percentage
    
    -- Calculate position (0% at bottom, 100% at top)
    local _position = (_invertedPercentage * BAR_HEIGHT) + 2
    
    _arrowIndicator.style.top = StyleLength.new(Length.new(_position))
end

--------------------------------
------  PUBLIC FUNCTIONS  ------
--------------------------------
function SetValue(value: number)
    updateArrowPosition(value)
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

