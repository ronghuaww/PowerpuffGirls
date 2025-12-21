--!Type(Module)

local playerTracker = require("PlayerTracker")
local ordersManager = require("OrdersManager")

AddHeldItemRequest = Event.new("AddHeldItemRequest")
AddSelectedItemRequest = Event.new("AddSelectedItemRequest")
AddItemInventoryRequest = Event.new("AddItemInventoryRequest")
IsOrderCompletedRequest = Event.new("IsOrderCompletedRequest")

local AddHeldItemEvent = Event.new("AddHeldItemEvent")
local RemoveAllHeldItemsEvent = Event.new("RemoveAllHeldItemsEvent")
local RemoveHeldItemEvent = Event.new("RemoveHeldItemEvent")
local SendIngredientToPlayerEvent = Event.new("SendIngredientToPlayerEvent")

--ClIENT-SIDE FUNCTION TO SPAWN HELD ITEM
function SpawnIngredient(ingredientBase: IngredientsBase, player: Player, itemIndex: number)
    local ingredientPrefab = ingredientBase.GetPrefab()
    if ingredientPrefab then
        local playerHeadPos = player.character.transform.position + Vector3.new(0, 3, 0) + (Vector3.new(0, .9, 0) * itemIndex)
        local ingredientInstance = GameObject.Instantiate(ingredientPrefab, playerHeadPos, Quaternion.identity)
        ingredientInstance.tag = "HeldItem"
        ingredientInstance.transform.parent = player.character.transform
    end
end

function UpdateHeldItemPositions(player: Player)
    -- destroy all held game objects 
    if not player.character then return end
    for i = player.character.transform.childCount - 1, 0, -1 do
        local child = player.character.transform:GetChild(i)
        if child.tag == "HeldItem" then
            GameObject.Destroy(child.gameObject)
        end
    end
    -- re-add held items in correct positions
    local heldItems = playerTracker.GetPlayerHeldItems(player)
    for index, itemName in ipairs(heldItems) do
        local ingredientData = ordersManager.getIngredientByName(itemName)
        if ingredientData then
            SpawnIngredient(ingredientData, player, index)
        end
    end
end

--------------------------------
------  SEND INGREDIENT    ------
--------------------------------
function SendIngredientToPlayer(ingredientName: string, playerSent: Player, playerReceive: Player)
    -- Get ingredient data
    local _ingredientData = ordersManager.getIngredientByName(ingredientName)
    if not _ingredientData then
        print("ERROR: Ingredient not found: " .. ingredientName)
        return
    end

    -- Get prefab
    local _prefab = _ingredientData.GetPrefab()
    if not _prefab then
        print("ERROR: No prefab for ingredient: " .. ingredientName)
        return
    end

    -- Get start and end positions from player characters
    if not playerSent.character or not playerReceive.character then
        print("ERROR: Player character not found")
        return
    end

    local _startPos = playerSent.character.transform.position + Vector3.new(0, 2, 0)
    local _endPos = playerReceive.character.transform.position + Vector3.new(0, 2, 0)

    -- Spawn the ingredient object
    local _spawnedObject = Object.Instantiate(_prefab, _startPos, Quaternion.identity)

    -- Tween with arc using sin curve
    Tween.FromTo(0, 1, function(progress)
        if _spawnedObject and _spawnedObject.transform then
            local currentPos = Vector3.Lerp(_startPos, _endPos, progress)
            -- Add arc height using sin curve
            local arcHeight = 3.0 * math.sin(progress * math.pi)
            _spawnedObject.transform.position = currentPos + Vector3.new(0, arcHeight, 0)
        end
    end)
    :Duration(2.5)
    :EaseInOutQuadratic()
    :OnStop(function()
        if _spawnedObject then
            Object.Destroy(_spawnedObject)
        end
    end)
    :Play()

    print("Sending " .. ingredientName .. " from " .. playerSent.name .. " to " .. playerReceive.name)
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
                    local childIngredient = child:GetComponent(IngredientTapped)
                    print("Checking held item: " .. childIngredient.GetIngredientData().GetName(), " against " .. itemName)
                    if childIngredient.GetIngredientData().GetName() == itemName then
                        print("Removed held item: " .. itemName)
                        UpdateHeldItemPositions(player)
                        GameObject.Destroy(child.gameObject)
                        return
                    end
                end
            end
        end
    end)

    SendIngredientToPlayerEvent:Connect(function(ingredientName: string, playerSent: Player, playerReceive: Player)
        SendIngredientToPlayer(ingredientName, playerSent, playerReceive)
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
        end
    end)

    IsOrderCompletedRequest:Connect(function(player: Player)
        local ifOrderCompleted = ordersManager.checkOrderCompleted(player)
        if ifOrderCompleted then
            print("Player " .. player.name .. " has completed their order!")
            Timer.After(0.5, function()
                playerTracker.players[player].heldItems.value = {}


                RemoveAllHeldItemsEvent:FireAllClients(player)
                local playerOrder = playerTracker.players[player].order.value
                ordersManager.orderRemovedEvent:FireAllClients(player, playerOrder)
                Timer.After(1.0, function()
                    ordersManager.AssignOrderToPlayer(player)
                end)
            end)
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
                SendIngredientToPlayerEvent:FireAllClients(itemName, player, updatePlayer)
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