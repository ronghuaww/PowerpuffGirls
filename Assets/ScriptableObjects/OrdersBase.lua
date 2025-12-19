--!Type(ScriptableObject)

--!SerializeField
local name: string = ""

--!SerializeField
local ingredients: {IngredientsBase} = {}


function GetName(): string
    return name
end

function GetIngredients(): {IngredientsBase}
    return ingredients
end