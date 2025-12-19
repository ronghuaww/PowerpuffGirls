--!Type(Module)
local playerTracker = require("PlayerTracker")


--!SerializeField
local OrdersList: {OrdersBase} = {}

--!SerializeField
local GameHUD: GameHUD = nil

--------------------------------
------     NETWORKING     ------
--------------------------------
-- Event to notify clients when an order is assigned
local orderAssignedEvent = Event.new("OrderAssignedEvent")
-- Event to notify clients when inventory is updated
local inventoryUpdatedEvent = Event.new("InventoryUpdatedEvent")
orderRemovedEvent = Event.new("OrderRemovedEvent")

-- -- Expose events globally
-- OrderAssignedEvent = orderAssignedEvent
-- InventoryUpdatedEvent = inventoryUpdatedEvent

--------------------------------
------  LOCAL FUNCTIONS   ------
--------------------------------
local function getRandomOrder(): OrdersBase | nil
    if #OrdersList == 0 then
        print("ERROR: No orders in OrdersList!")
        return nil
    end
    local _index = math.random(1, #OrdersList)
    print("Selected random order index: " .. _index, OrdersList[_index].GetName())
    return OrdersList[_index]
end

local function getIngredientNames(order: OrdersBase): {string}
    print("Getting ingredient names for order: " .. order.GetName(), #order.GetIngredients())
    local _names = {}
    local _ingredients = order.GetIngredients()
    for _, ingredient in ipairs(_ingredients) do
        print("Found ingredient: " .. ingredient.GetName())
        table.insert(_names, ingredient.GetName())
    end
    return _names
end

local function getStartingIngredients(ingredientNames: {string}): {string}
    -- Give all ingredients except one random one
    if #ingredientNames <= 1 then
        return {}
    end

    local _startingIngredients = {}
    local _missingIndex = math.random(1, #ingredientNames)

    for i, name in ipairs(ingredientNames) do
        if i ~= _missingIndex then
            table.insert(_startingIngredients, name)
        end
    end

    return _startingIngredients
end

--------------------------------
------  PUBLIC FUNCTIONS  ------
--------------------------------
function AssignOrderToPlayer(player: Player)
    local _playerInfo = playerTracker.players[player]
    if not _playerInfo then
        print("ERROR: Player not found in tracker")
        return
    end

    -- Get a random order
    local _order = getRandomOrder()
    if not _order then return end

    -- Store order info in player's TableValue
    _playerInfo.order.value = _order.GetName()
    -- go through the items and add it to people's inventory

    local _currentInventory = _playerInfo.inventory.value or {}

    for i, ingredient in ipairs(_order.GetIngredients()) do
        print("Adding ingredient to player inventory: " .. ingredient.GetName())
        table.insert(_currentInventory, 1, ingredient.GetName())
    end
    _playerInfo.inventory.value = _currentInventory

    -- Notify client about the assigned order
    orderAssignedEvent:FireClient(player, _order.GetName(), getIngredientNames(_order))
    print("Assigned order '" .. _order.GetName() .. "' to " .. player.name)
end

function GetPlayerOrder(player: Player): (string, {string})
    local _playerInfo = playerTracker.players[player]
    if not _playerInfo or not _playerInfo.order.value then
        return "", {}
    end

    local _orderData = _playerInfo.order.value
    return _orderData.orderName, _orderData.requiredIngredients
end

function GetPlayerInventory(player: Player): {string}
    local _playerInfo = playerTracker.players[player]
    if not _playerInfo then
        return {}
    end
    return _playerInfo.inventory.value or {}
end

--------------------------------
------  LIFECYCLE HOOKS   ------
--------------------------------
function self:ServerAwake()
    -- Initialize random seed
    math.randomseed(os.time())

    -- Listen for when players are ready (character spawned)
    scene.PlayerJoined:Connect(function(scn, player)
        -- Wait a moment for PlayerTracker to register the player
        Timer.After(0.5, function()
            AssignOrderToPlayer(player)
        end)
    end)

end


function self:ClientAwake()
    -- Client-side logic can be added here if needed
    orderAssignedEvent:Connect(function(orderName, requiredIngredients)
        print("Received order assignment: " .. orderName)
        GameHUD.OrderAssigned(orderName, requiredIngredients)
    end)

    orderRemovedEvent:Connect(function()
        print("Received order removal")
        GameHUD.removeOrder()
        -- remove from player held items as well
    end)
end

function getIngredientByName(name: string): IngredientsBase | nil
    for _, order in ipairs(OrdersList) do
        for _, ingredient in ipairs(order.GetIngredients()) do
            if ingredient.GetName() == name then
                return ingredient
            end
        end
    end
    return nil
end

function getOrderByName(name: string): OrdersBase | nil
    for _, order in ipairs(OrdersList) do
        if order.GetName() == name then
            return order
        end
    end
    return nil
end

-- SERVER FUNCTION
function checkOrderCompleted(player): boolean
    local _playerInfo = playerTracker.players[player]
    if not _playerInfo then return false end

    local playerOrderName = _playerInfo.order.value
    local order = getOrderByName(playerOrderName)
    if not order then return false end

    local requiredIngredients = getIngredientNames(order)
    local playerHeldItems = _playerInfo.heldItems.value

    if #requiredIngredients ~= #playerHeldItems then
        return false
    end

    -- Count required ingredients
    for i, requiredIngredient in ipairs(requiredIngredients) do
        local found = false
        for j, heldItem in ipairs(playerHeldItems) do
            if heldItem == requiredIngredient then 
                found = true
                break
            end
        end
        if not found then
            return false
        end
    end
    return true
end