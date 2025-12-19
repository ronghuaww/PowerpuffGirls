--!Type(Client)
local playerTracker = require("PlayerTracker")
local ingredientsManager = require("IngredientsManager")

function self:ClientStart()
    -- Remove this script from itself, ignore tapping ones self
    local TapHand = self.gameObject:GetComponent(TapHandler)

    -- Handle when a player tapped another 
    TapHand.Tapped:Connect(function()
        local localPlayer = client.localPlayer

        local tappedPlayer = self:GetComponent(Character).player -- the person who got tapped

        -- if the player tapped themselves and if they have an item selected
        if localPlayer == tappedPlayer then
            local selectedItem = playerTracker.GetPlayerSelectedItem(localPlayer)
            if selectedItem and selectedItem ~= "" then
                print("Player tapped themselves with selected item: " .. selectedItem)
                ingredientsManager.AddHeldItemRequest:FireServer(selectedItem)
            end
            return
        end

        -- If the player tapped someone else, we give them the selected item in their inventory
        if localPlayer ~= tappedPlayer then
            local selectedItem = playerTracker.GetPlayerSelectedItem(localPlayer)
            if selectedItem and selectedItem ~= "" then
                print("Player tapped another player: " .. tappedPlayer.name .. " with selected item: " .. selectedItem)
               ingredientsManager.AddItemInventoryRequest:FireServer(tappedPlayer, selectedItem)
            end
        end
    end)
end


