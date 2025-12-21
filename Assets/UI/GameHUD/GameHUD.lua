--!Type(UI)
local ordersManager = require("OrdersManager")

--------------------------------
------  USS CLASS NAMES   ------
--------------------------------
local OrderItemClass = "order-item"
local OrderLabelClass = "order-label"
local IngredientSlotClass = "ingredient-slot"
local IngredientSlotSelectedClass = "ingredient-slot-selected"
local IngredientLabelClass = "ingredient-label"
local PlayerItemClass = "player-item"
local PlayerNameClass = "player-name"
local IngredientIconsClass = "ingredient-icons"

--------------------------------
---- UXML ELEMENT BINDINGS -----
--------------------------------
--!Bind
local _ordersContainer: VisualElement = nil
--!Bind
local _orderLabel: Label = nil
--!Bind
local _orderIcon: VisualElement = nil

-- --!Bind
-- local _playerSelectPopup: VisualElement = nil
-- --!Bind
-- local _playerListContainer: VisualElement = nil
-- --!Bind
-- local _recipeReadyPopup: VisualElement = nil
-- --!Bind
-- local _recipeReadyLabel: Label = nil

--------------------------------
------     CONSTANTS      ------
--------------------------------
local INGREDIENT_EMOJIS = {
    flour = "F",
    sugar = "S",
    butter = "B",
    eggs = "E",
    milk = "M",
    chocolate = "C"
}

local INGREDIENT_COLORS = {
    flour = "ingredient-flour",
    sugar = "ingredient-sugar",
    butter = "ingredient-butter",
    eggs = "ingredient-eggs",
    milk = "ingredient-milk",
    chocolate = "ingredient-chocolate"
}

--------------------------------
------     LOCAL STATE    ------
--------------------------------
local myInventory: {string} = {}
local myOrderName: string = nil
local myRequiredIngredients: {string} = {}
local selectedIngredient: string = nil
local selectedIngredientElement: VisualElement = nil
local completedRecipe: string = nil
local isPopupVisible: boolean = false

--------------------------------
------  LOCAL FUNCTIONS   ------
--------------------------------



---MY CODE------------------------------------------------------------------------

local function addOrderDisplay(recipeName: string, ingredients: {string})
    if not _ordersContainer then
        return
    end

    -- local _orderItem = VisualElement.new()
    -- _orderItem:AddToClassList(OrderItemClass)

    -- Order name
    _orderLabel.text = recipeName
    print("Adding order display for: " .. #ingredients .. " ingredients")

    -- order icon
    local orderData = ordersManager.getOrderByName(recipeName)
    if orderData == nil then return end

    _orderIcon.style.backgroundImage = orderData.GetIcon().texture


    -- Ingredients list
    if ingredients and #ingredients > 0 then
        
        -- Show which ingredients player has vs needs
        local _ingredientDisplay = {}
        for i, ingredient in ipairs(ingredients) do
            local _ingredientsLabel = Label.new()

            local ingredientData = ordersManager.getIngredientByName(ingredient)

            if ingredientData == nil then return end 

            local _ingredientIcon = UIImage.new()
            _ingredientIcon.image = ingredientData.GetIcon().texture
            _ingredientIcon:AddToClassList(IngredientIconsClass)
            _ordersContainer:Add(_ingredientIcon)

            -- _ingredientsLabel:AddToClassList("order-ingredients")
            -- _ingredientsLabel.text = ingredient
            -- _orderItem:Add(_ingredientsLabel)
        end

    end
    --_ordersContainer:Add(_orderItem)
end
------------------------------------------------------------------------


-- local function selectIngredientSlot(slot: VisualElement, ingredient: string)
--     -- Deselect previous
--     if selectedIngredientElement then
--         selectedIngredientElement:RemoveFromClassList(IngredientSlotSelectedClass)
--     end

--     -- Select new
--     selectedIngredient = ingredient
--     selectedIngredientElement = slot
--     slot:AddToClassList(IngredientSlotSelectedClass)

--     print("Selected: " .. ingredient)
-- end


-- local function showPlayerSelectPopup()
--     if not _playerSelectPopup or not _playerListContainer then
--         return
--     end

--     _playerListContainer:Clear()

--     -- Add other players to list
--     for _, player in ipairs(scene.players) do
--         if player ~= client.localPlayer then
--             local _playerItem = VisualElement.new()
--             _playerItem:AddToClassList(PlayerItemClass)

--             local _nameLabel = Label.new()
--             _nameLabel:AddToClassList(PlayerNameClass)
--             _nameLabel.text = player.name

--             _playerItem:Add(_nameLabel)

--             -- Handle tap to select player and throw
--             local _targetPlayer = player
--             -- _playerItem:RegisterCallback(ClickEvent, function(evt)
--             --     if selectedIngredient then
--             --         -- Throw ingredient to this player
--             --         ThrowIngredientEvent:FireServer(_targetPlayer.id, selectedIngredient)
--             --         print("Throwing " .. selectedIngredient .. " to " .. _targetPlayer.name)
--             --     end
--             --     hidePlayerSelectPopup()
--             -- end)

--             _playerListContainer:Add(_playerItem)
--         end
--     end

--     _playerSelectPopup.style.display = DisplayStyle.Flex
--     isPopupVisible = true
-- end

-- local function hidePlayerSelectPopup()
--     if _playerSelectPopup then
--         _playerSelectPopup.style.display = DisplayStyle.None
--         isPopupVisible = false
--     end
-- end

-- local function showRecipeReady(recipeName: string)
--     if _recipeReadyPopup and _recipeReadyLabel then
--         _recipeReadyLabel.text = recipeName .. " Ready!"
--         _recipeReadyPopup.style.display = DisplayStyle.Flex
--         completedRecipe = recipeName

--         -- Hide after delay
--         Timer.After(3, function()
--             if _recipeReadyPopup then
--                 _recipeReadyPopup.style.display = DisplayStyle.None
--             end
--         end)
--     end
-- end

-- local function hideRecipeReady()
--     if _recipeReadyPopup then
--         _recipeReadyPopup.style.display = DisplayStyle.None
--         completedRecipe = nil
--     end
-- end

-- local function showStatusMessage(message: string, duration: number)
--     if _statusMessage then
--         _statusMessage.text = message
--         _statusMessage.style.display = DisplayStyle.Flex

--         if duration and duration > 0 then
--             Timer.After(duration, function()
--                 if _statusMessage then
--                     _statusMessage.text = ""
--                 end
--             end)
--         end
--     end
-- end

function OrderAssigned(orderName: string, requiredIngredients: {string})
    myOrderName = orderName
    myRequiredIngredients = requiredIngredients
    addOrderDisplay(orderName, requiredIngredients)
    --showStatusMessage("New Order: " .. orderName, 3)
    print("Order assigned: " .. orderName)
end

function removeOrder()
    if _ordersContainer then
        _ordersContainer:Clear()
    end
    if _orderLabel then
        _orderLabel:Clear()
    end
    if _orderIcon then
        _orderIcon:Clear()
    end
end

--------------------------------
------  LIFECYCLE HOOKS   ------
--------------------------------
function self:Start()
    print("GameHUD: Initialized")

    -- -- Listen for game events
    -- GameTimeValue.Changed:Connect(function(newValue, oldValue)
    --     updateTimerDisplay(newValue)
    -- end)

    -- TeamScoreValue.Changed:Connect(function(newValue, oldValue)
    --     updateScoreDisplay(newValue)
    -- end)

    -- GameStartEvent:Connect(function()
    --     showStatusMessage("GO!", 2)
    -- end)

    -- GameEndEvent:Connect(function(finalScore)
    --     showStatusMessage("Game Over! Score: " .. finalScore, 5)
    -- end)

    -- Listen for order assignment from OrdersManager
    -- OrderAssignedEvent:Connect(function(orderName, requiredIngredients)
    --     myOrderName = orderName
    --     myRequiredIngredients = requiredIngredients
    --     updateMyOrderDisplay()
    --     showStatusMessage("New Order: " .. orderName, 3)
    --     print("Order assigned: " .. orderName)
    -- end)

    -- -- Listen for inventory updates from OrdersManager
    -- InventoryUpdatedEvent:Connect(function(inventory)
    --     myInventory = inventory
    --     updateInventoryDisplay(inventory)
    --     updateMyOrderDisplay() -- Refresh order display to show what we have/need
    --     print("Inventory updated: " .. table.concat(inventory, ", "))
    -- end)

    -- -- Listen for inventory updates (legacy event)
    -- InventoryUpdateEvent:Connect(function(playerId, inventory)
    --     if client.localPlayer and client.localPlayer.id == playerId then
    --         updateInventoryDisplay(inventory)
    --     end
    -- end)

    -- -- Listen for recipe completion
    -- RecipeCompletedEvent:Connect(function(playerId, recipeName)
    --     if client.localPlayer and client.localPlayer.id == playerId then
    --         showRecipeReady(recipeName)
    --     end
    -- end)

    -- -- Listen for serve events
    -- ServeRecipeEvent:Connect(function(playerId, recipeName, points)
    --     if client.localPlayer and client.localPlayer.id == playerId then
    --         showStatusMessage("+" .. points .. " points!", 2)
    --     end
    -- end)

end
