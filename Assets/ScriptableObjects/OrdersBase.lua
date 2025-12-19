--!Type(ScriptableObject)

--!SerializeField
local name: string = ""

--!SerializeField
local ingredients: {IngredientsBase} = {}

--!SerializeField
local prefab: GameObject = nil


function GetName(): string
    return name
end

function GetIngredients(): {IngredientsBase}
    return ingredients
end

function GetPrefab(): GameObject
    return prefab
end