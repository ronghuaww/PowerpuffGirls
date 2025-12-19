--!Type(Client)
local playerTracker = require("PlayerTracker")
local ingredientsManager = require("IngredientsManager")

function self:ClientStart()
    -- Remove this script from itself, ignore tapping ones self
    local TapHand = self.gameObject:GetComponent(TapHandler)

    -- Handle when a player tapped another 
    TapHand.Tapped:Connect(function()
        local localPlayer = client.localPlayer -- the person doing the tapping
        print("SubmitCounterTapped by player: " .. localPlayer.name)
        ingredientsManager.IsOrderCompletedRequest:FireServer(localPlayer) 
    end)
end
