--!Type(Module)

--!SerializeField
local inventoryHUD: InventoryHUD = nil


players = {}
local playercount = 0

function GetPlayerHeldItems(player)
    return players[player].heldItems.value
end

function GetPlayerInventory(player)
    return players[player].inventory.value
end

function GetPlayerSelectedItem(player)
    return players[player].selectedItem.value
end
------------ Player Tracking ------------
function TrackPlayers(game, characterCallback)
    scene.PlayerJoined:Connect(function(scene, player)
        playercount = playercount + 1
        players[player] = {
            player = player,
            inventory = TableValue.new("Inventory" .. player.user.id, {}, player),
            heldItems = TableValue.new("HeldItems" .. player.user.id, {}, player),
            order = StringValue.new("CurrentOrder" .. player.user.id, "", player),
            selectedItem = StringValue.new("SelectedItem" .. player.user.id, "", player),
        }

        player.CharacterChanged:Connect(function(player, character) 
            local playerinfo = players[player]
            if (character == nil) then
                return
            end 

            if characterCallback then
                characterCallback(playerinfo)
            end
        end)
    end)

    game.PlayerDisconnected:Connect(function(player)
        playercount = playercount - 1
        players[player] = nil
    end)
end

------------- CLIENT -------------

function self:ClientAwake()
    function OnCharacterInstantiate(playerinfo)
        local player = playerinfo.player
        local character = playerinfo.player.character

        playerinfo.inventory.Changed:Connect(function(newInventory, oldInventory)

            inventoryHUD.UpdateInventoryDisplay(newInventory)

            -- Update UI or other client-side elements based on player score change
        end)

        playerinfo.heldItems.Changed:Connect(function(newHeldItems, oldHeldItems)
            -- Handle held items change if needed
            -- go through all the items on the player's head and see if they match the recipe
            

        end)
    end
    TrackPlayers(client, OnCharacterInstantiate)

    
end

------------- SERVER -------------

function self:ServerAwake()
    TrackPlayers(server, function(playerInfo)
        local player = playerInfo.player
    end)
end

function SetScore(player, score)
	players[player].playerScore.value = score
end

function SetSelectedItem(player, itemName)
    players[player].selectedItem.value = itemName
end

function AddHeldItem(player, itemName)
    -- add the item to held items
    local playerInfo = players[player]
    if playerInfo then
        local heldItems = playerInfo.heldItems.value
        table.insert(heldItems, itemName)
        playerInfo.heldItems.value = heldItems
    end

    -- remove the item from inventory
    RemoveFromInventory(player, itemName)

end

function RemoveFromInventory(player, itemName)
    local playerInfo = players[player]
    if playerInfo then
        local inventory = playerInfo.inventory.value
        for i, item in ipairs(inventory) do
            if item == itemName then
                table.remove(inventory, i)
                break
            end
        end
        playerInfo.inventory.value = inventory
    end
end

function AddItemToInventory(player, itemName)
    local playerInfo = players[player]
    if playerInfo then
        local inventory = playerInfo.inventory.value
        table.insert(inventory, itemName)
        playerInfo.inventory.value = inventory
    end
end

function IsItemInInventory(player, itemName): boolean
    local playerInfo = players[player]
    if playerInfo then
        local inventory = playerInfo.inventory.value
        for i, item in ipairs(inventory) do
            if item == itemName then
                return true
            end
        end
    end
    return false
end

function IsItemInHeldItems(player, itemName): boolean
    local playerInfo = players[player]
    if playerInfo then
        local heldItems = playerInfo.heldItems.value
        for i, item in ipairs(heldItems) do
            if item == itemName then
                return true
            end
        end
    end
    return false
end

function RemoveHeldItem(player, itemName)
    local playerInfo = players[player]
    if playerInfo then
        local heldItems = playerInfo.heldItems.value
        for i, item in ipairs(heldItems) do
            if item == itemName then
                table.remove(heldItems, i)
                break
            end
        end
        playerInfo.heldItems.value = heldItems
    end
end

