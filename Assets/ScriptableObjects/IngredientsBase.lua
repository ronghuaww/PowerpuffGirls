--!Type(ScriptableObject)

--!SerializeField
local name: string = ""

--!SerializeField
local icon: Sprite = nil

--!SerializeField
local prefab: GameObject = nil

function GetName(): string
    return name
end

function GetIcon(): Sprite
    return icon
end

function GetPrefab(): GameObject
    return prefab
end