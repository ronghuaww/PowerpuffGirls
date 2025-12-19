--!Type(Module)

local playerTracker = require("PlayerTracker")
local ordersManager = require("OrdersManager")

AddHeldItemRequest = Event.new("AddHeldItemRequest")
AddSelectedItemRequest = Event.new("AddSelectedItemRequest")
AddItemInventoryRequest = Event.new("AddItemInventoryRequest")
local AddHeldItemEvent = Event.new("AddHeldItemEvent")
local RemoveAllHeldItemsEvent = Event.new("RemoveAllHeldItemsEvent")
local RemoveHeldItemEvent = Event.new("RemoveHeldItemEvent")

--ClIENT-SIDE FUNCTION TO SPAWN HELD ITEM
function SpawnIngredient(ingredientBase: IngredientsBase, player: Player, itemIndex: number)
    local ingredientPrefab = ingredientBase.GetPrefab()
    if ingredientPrefab then
        local playerHeadPos = player.character.transform.position + Vector3.new(0,3,0) + (Vector3.new(0,1,0) * itemIndex)
        local ingredientInstance = GameObject.Instantiate(ingredientPrefab, playerHeadPos, Quaternion.identity)
        ingredientInstance.tag = "HeldItem"
        ingredientInstance.transform.parent = player.character.transform
    end
end

function self:ClientAwake()
    -- Client-side initialization if needed
    AddHeldItemEvent:Connect(function(player, itemName: string, itemIndex: number)
        print("Client received request to add held item: " .. itemName)
        local ingredientData = ordersManager.getIngredientByName(itemName)
        if ingredientData then
            SpawnIngredient(ingredientData, player, itemIndex)
        else
            print("Ingredient data not found for: " .. itemName)
        end
    end)

    RemoveAllHeldItemsEvent:Connect(function(player)
        -- Remove all held item game objects from the player's head
        local character = player.character
        if character then
            for i = character.transform.childCount - 1, 0, -1 do
                local child = character.transform:GetChild(i)
                if child.tag == "HeldItem" then
                    GameObject.Destroy(child.gameObject)
                end
            end
        end
    end)

    RemoveHeldItemEvent:Connect(function(player, itemName: string)
        -- Remove specific held item game object from the player's head
        local character = player.character
        if character then
            for i = character.transform.childCount - 1, 0, -1 do
                local child = character.transform:GetChild(i)
                if child.tag == "HeldItem" then
                    GameObject.Destroy(child.gameObject)
                    return
                end
            end
        end
    end)

end

function self:ServerAwake()
    -- Server-side initialization if needed
    AddHeldItemRequest:Connect(function(player: Player, itemName: string)
        local playerInventory = playerTracker.GetPlayerInventory(player)
        print("Player " .. player.name .. " inventory has " .. #playerInventory .. " items.")
        -- check to see if the player has the item in their inventory
        local hasItem = false
        for i, item in ipairs(playerInventory) do
            if item == itemName then
                hasItem = true
                break
            end
        end

        if hasItem then
            print("Player " .. player.name .. " used item: " .. itemName)
            playerTracker.AddHeldItem(player, itemName)
            local heldItems = playerTracker.GetPlayerHeldItems(player)
            AddHeldItemEvent:FireAllClients(player, itemName, #heldItems)


            local ifOrderCompleted = ordersManager.checkOrderCompleted(player)
            if ifOrderCompleted then
                print("Player " .. player.name .. " has completed their order!")
                Timer.After(0.5, function()
                    playerTracker.players[player].heldItems.value = {}


                    RemoveAllHeldItemsEvent:FireAllClients(player)
                    ordersManager.orderRemovedEvent:FireClient(player)
                    Timer.After(1.0, function()
                        ordersManager.AssignOrderToPlayer(player)
                    end)
                end)
                
                -- Further logic for order completion can be added here
            end
        end
    end)

    AddSelectedItemRequest:Connect(function(player: Player, itemName: string)
        playerTracker.SetSelectedItem(player, itemName)
    end)

    AddItemInventoryRequest:Connect(function(player: Player, updatePlayer: Player, itemName: string)
        local playerInventory = playerTracker.GetPlayerInventory(player)
        print("Player " .. player.name .. " inventory has " .. #playerInventory .. " items.")

        -- if player are sending each other items
        if player ~= updatePlayer then
            print("Player " .. player.name .. " is sending item: " .. itemName .. " to player " .. updatePlayer.name)
            -- check to see if the player has the item in their inventory
            local isInInventory = playerTracker.IsItemInInventory(player, itemName)
            if isInInventory then
                playerTracker.AddItemToInventory(updatePlayer, itemName)
                print("Added item " .. itemName .. " to player " .. updatePlayer.name .. "'s inventory.")
                -- remove the item from the original player's inventory
                playerTracker.RemoveFromInventory(player, itemName)
            end
        else
            print("Player " .. player.name .. " is adding item: " .. itemName .. " to their own inventory")
            -- see if the item is in their hands 
            if playerTracker.IsItemInHeldItems(player, itemName) then
                playerTracker.AddItemToInventory(player, itemName)
                print("Added item " .. itemName .. " to player " .. player.name .. "'s inventory from held items.")
                -- remove the item from held items
                playerTracker.RemoveHeldItem(player, itemName)
                RemoveHeldItemEvent:FireAllClients(player, itemName)
            end
        end

    end)
end