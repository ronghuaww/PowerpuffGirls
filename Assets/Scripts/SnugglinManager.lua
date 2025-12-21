--!Type(Module)

--------------------------------
------  SERIALIZED FIELDS ------
--------------------------------

--!SerializeField
local snugglinPrefab: GameObject = nil

--!SerializeField
local spawnPointOBJ: GameObject = nil

--!SerializeField
local sittingAnchors: {Anchor} = nil

--!SerializeField
local snugglinData: {SnugglinBase} = nil


--------------------------------
------     LOCAL STATE    ------
--------------------------------

local _spawnedSnugglins: {GameObject} = {}

local _seenSnugglins = {}

--------------------------------
------  LOCAL FUNCTIONS   ------
--------------------------------

local function getCharacterFromGameObject(gameObject: GameObject): Character
    if not gameObject then
        return nil
    end
    return gameObject:GetComponent(Character)
end

local function getRandomSnugglinData(): SnugglinBase
    local _randomIndex = math.random(1, #snugglinData)
    return snugglinData[_randomIndex]
end

local function getRandomSittingAnchor(): Anchor?
    if not sittingAnchors or #sittingAnchors == 0 then
        return nil
    end
    -- Find an unoccupied anchor
    local _availableAnchors: {Anchor} = {}
    for _, anchor in ipairs(sittingAnchors) do
        if not anchor.isOccupied then
            table.insert(_availableAnchors, anchor)
        end
    end
    if #_availableAnchors == 0 then
        return nil
    end
    local _randomIndex = math.random(1, #_availableAnchors)
    return _availableAnchors[_randomIndex]
end

local function applyOutfitToCharacter(character: Character, outfit: CharacterOutfit)
    if not character or not outfit then
        return
    end
    character:SetOutfit(outfit)
end

--------------------------------
------  PUBLIC FUNCTIONS  ------
--------------------------------


-- Spawns a Snugglin NPC at the specified position
-- Returns the spawned GameObject
function SpawnAtPosition(): GameObject | nil
    local spawnPos = spawnPointOBJ.transform.position
    if not snugglinPrefab then
        print("ERROR: No snugglinPrefab assigned in SnugglinManager")
        return nil
    end

    local _spawnedNpc = Object.Instantiate(snugglinPrefab, spawnPos, Quaternion.identity)
    local _character = getCharacterFromGameObject(_spawnedNpc)
    if not _character then return nil end
    local _snugglinData = getRandomSnugglinData()
    if _snugglinData then
        applyOutfitToCharacter(_character, _snugglinData.GetOutfit())
        AddToSeenSnugglins(_snugglinData.GetName())
    end

    if _spawnedNpc then
        table.insert(_spawnedSnugglins, _spawnedNpc)
    end

    return _spawnedNpc
end

-- Makes the Snugglin NPC walk to a random available anchor and sit
-- Returns true if movement was initiated successfully
function WalkAndSitAtRandomAnchor(snugglinObject: GameObject, callback: ((...any) -> (...any))?): boolean
    if not snugglinObject then
        print("ERROR: No snugglinObject provided to WalkAndSitAtRandomAnchor")
        return false
    end

    local _character = getCharacterFromGameObject(snugglinObject)
    if not _character then
        print("ERROR: Snugglin does not have a Character component")
        return false
    end

    local _anchor = getRandomSittingAnchor()
    if not _anchor then
        print("ERROR: No available sitting anchors")
        return false
    end

    -- Walk near the anchor's enter position, then jump and sit
    local _enterPos = _anchor.enterFromPosition
    local _anchorPos = _anchor.transform.position

    _character:MoveWithinRangeOf(_enterPos, 0, -1, function()
        -- Once close enough, jump to the anchor position
        _character:JumpTo(_anchorPos, function()
            -- After landing, attach to anchor and play sitting animation
            _character:TeleportToAnchor(_anchor)
            _character.transform.rotation = _anchor.transform.rotation
            _character:PlayEmote("idle-lookAround")

            Timer.After(5, function()
                _character:PlayEmote("idle-blink", true)
            end)

            if callback then
                callback()
            end
        end)
    end)

    return true
end



-- Makes the Snugglin jump off anchor, walk back to spawn, and destroy
function WalkBackToSpawnAndDespawn(snugglinObject: GameObject, callback: ((...any) -> (...any))?): boolean
    if not snugglinObject then
        print("ERROR: No snugglinObject provided to WalkBackToSpawnAndDespawn")
        return false
    end

    local _character = getCharacterFromGameObject(snugglinObject)
    if not _character then
        print("ERROR: Snugglin does not have a Character component")
        return false
    end

    local _spawnPos = spawnPointOBJ.transform.position

    -- First, detach from anchor by jumping to nearby NavMesh position
    local _currentPos = _character.transform.position
    local _jumpOffPos = _currentPos + Vector3.new(-1, 0, 0) -- Jump slightly forward/off the stool

    _character:JumpTo(_jumpOffPos, function()
        -- Now walk back to spawn position
        _character:MoveTo(_spawnPos, -1, function()
            -- Arrived at spawn, destroy the instance
            DespawnSnugglin(snugglinObject)

            if callback then
                callback()
            end
        end)
    end)

    return true
end

-- Destroys a spawned Snugglin NPC
function DespawnSnugglin(snugglinObject: GameObject): boolean
    if not snugglinObject then
        print("ERROR: No snugglinObject provided to DespawnSnugglin")
        return false
    end

    for i, snugglin in ipairs(_spawnedSnugglins) do
        if snugglin == snugglinObject then
            table.remove(_spawnedSnugglins, i)
            break
        end
    end

    Object.Destroy(snugglinObject)
    return true
end

-- Returns all currently spawned Snugglins
function GetAllSpawnedSnugglins(): {GameObject}
    return _spawnedSnugglins
end

function AddToSeenSnugglins(snugglinName: string)
    _seenSnugglins[snugglinName] = true
end

function HasSeenSnugglin(snugglinName: string): boolean
    return _seenSnugglins[snugglinName] == true
end


function self:ClientStart()
    local snugglinObject = SpawnAtPosition()
    Timer.After(2, function()
        WalkAndSitAtRandomAnchor(snugglinObject, function()
            print("Snugglin arrived and is now sitting!")
        end)
    end)

    Timer.After(20, function()
        WalkBackToSpawnAndDespawn(snugglinObject, function()
            print("Snugglin has despawned.")
        end)
    end)
end