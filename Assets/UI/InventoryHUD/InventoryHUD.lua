--!Type(UI)
local ordersManager = require("OrdersManager")
local ingredientsManager = require("IngredientsManager")
local audioManager = require("AudioManager")


--------------------------------
------  USS CLASS NAMES   ------
--------------------------------
local IngredientSlotClass = "ingredient-slot"
local IngredientSlotSelectedClass = "ingredient-slot-selected"
local IngredientSlotEmptyClass = "ingredient-slot-empty"
local IngredientLabelClass = "ingredient-label"
local IngredientIconClass = "ingredient-icon"

--------------------------------
---- UXML ELEMENT BINDINGS -----
--------------------------------
--!Bind
local _inventoryScroll: UIScrollView = nil
--!Bind
local _inventoryContainer: VisualElement = nil

--------------------------------
------     LOCAL STATE    ------
--------------------------------
local myInventory: {string} = {}
local inventorySlots: {VisualElement} = {}
local selectedIngredient: string = nil
local selectedSlotIndex: number = nil

--------------------------------
------  LOCAL FUNCTIONS   ------
--------------------------------
local function clearInventory()
    if _inventoryContainer then
        _inventoryContainer:Clear()
    end
    inventorySlots = {}
end

local function selectSlot(slotIndex: number, ingredient: string)
    -- Deselect previous
    if selectedSlotIndex and inventorySlots[selectedSlotIndex] then
        inventorySlots[selectedSlotIndex]:RemoveFromClassList(IngredientSlotSelectedClass)
    end

    -- Select new
    selectedIngredient = ingredient
    selectedSlotIndex = slotIndex

    if inventorySlots[slotIndex] then
        inventorySlots[slotIndex]:AddToClassList(IngredientSlotSelectedClass)
    end

   -- print("Selected ingredient: " .. (ingredient or "none"))
end

local function createIngredientSlot(ingredientData: IngredientsBase, index: number) : VisualElement
    local _slot = VisualElement.new()
    _slot:AddToClassList(IngredientSlotClass)

    -- -- Add color class based on ingredient
    -- local _colorClass = INGREDIENT_COLORS[ingredient]
    -- if _colorClass then
    --     _slot:AddToClassList(_colorClass)
    -- end


    local _icon = Image.new()
    _icon.image = ingredientData.GetIcon().texture
    _icon:AddToClassList(IngredientIconClass)

    _slot:Add(_icon)

    _slot:RegisterPressCallback(function()
        --ingredientsManager.AddHeldItemRequest:FireServer(ingredientData.GetName())
        -- listen if the player taps themselves or someone else
        audioManager.PlayButtonClick()
        ingredientsManager.AddSelectedItemRequest:FireServer(ingredientData.GetName())

        -- spawn the game asset on the players head 
    end)

    return _slot

end

function UpdateInventoryDisplay(inventory: {string})
    clearInventory()

    if not _inventoryContainer then return end

    for i, item in ipairs(inventory) do
        local ingredientData = ordersManager.getIngredientByName(item)
        if not ingredientData then return end

        local _slot = createIngredientSlot(ingredientData, i)
        _inventoryContainer:Add(_slot)
        table.insert(inventorySlots, _slot)
    end

    print("Inventory display updated with " .. #inventory .. " items")
end

--------------------------------
------  PUBLIC FUNCTIONS  ------
--------------------------------
function GetSelectedIngredient(): string
    return selectedIngredient
end

function GetInventory(): {string}
    return myInventory
end

function SetInventory(inventory: {string})
    myInventory = inventory or {}
    --updateInventoryDisplay()
end

function AddIngredient(ingredient: string)
    table.insert(myInventory, ingredient)
    --updateInventoryDisplay()
end

function RemoveIngredient(ingredient: string): boolean
    for i, inv in ipairs(myInventory) do
        if inv == ingredient then
            table.remove(myInventory, i)
            --updateInventoryDisplay()
            return true
        end
    end
    return false
end

--------------------------------
------  LIFECYCLE HOOKS   ------
--------------------------------
function self:Start()

end
