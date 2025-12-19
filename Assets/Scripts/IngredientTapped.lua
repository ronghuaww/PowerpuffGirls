--!Type(Client)
local ingredientsManager = require("IngredientsManager")
local playerTracker = require("PlayerTracker")

--!SerializeField
local IngredientData: IngredientsBase = nil


function self:ClientStart()
    -- Remove this script from itself, ignore tapping ones self
    local TapHand = self.gameObject:GetComponent(TapHandler)

    -- Handle when a player tapped another 
    TapHand.Tapped:Connect(function()
        local localPlayer = client.localPlayer -- the person doing the tapping

        -- check if the object is a held item of the player
        print("Tapped object name: " .. IngredientData.GetName())

        if playerTracker.IsItemInHeldItems(localPlayer, IngredientData.GetName()) then
            ingredientsManager.AddItemInventoryRequest:FireServer(localPlayer, IngredientData.GetName())
            Object.Destroy(self.gameObject)
        end

    end)
end


