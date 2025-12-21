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


local function addOrderDisplay(recipeName: string, ingredients: {string})
    if not _ordersContainer then
        return
    end

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
        end
    end
end


function OrderAssigned(orderName: string, requiredIngredients: {string})
    myOrderName = orderName
    myRequiredIngredients = requiredIngredients
    addOrderDisplay(orderName, requiredIngredients)
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