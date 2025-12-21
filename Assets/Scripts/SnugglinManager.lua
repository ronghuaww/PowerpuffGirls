--!Type(Module)

local audioManager = require("AudioManager")

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


--!SerializeField
local roomMeterHUD: RoomMeterHUD = nil

CompletedOrderRequest = Event.new("CompletedOrderRequest")
UpdateSnugglinCountEvent = Event.new("UpdateSnugglinCountEvent")




local EPIC_TRESHOLD = 200
local LENDARY_TRESHOLD = 400

local _roomScore: number = 0


local _roomRarity = "rare"



--------------------------------
------     LOCAL STATE    ------
--------------------------------

local _spawnedSnugglins: {GameObject} = {}

local _seenSnugglins = {}


--------------------------------
------  LOCAL FUNCTIONS   ------
--------------------------------

local function GetSnugglinBasedRarity(rarity: string) : {SnugglinBase}
    local _filteredSnugglins: {SnugglinBase} = {}
    for _, snugglin in ipairs(snugglinData) do
        if snugglin.GetRarity() == "Rare" then
            table.insert(_filteredSnugglins, snugglin)
        end
    end
    if rarity == "Rare" then return _filteredSnugglins end

    for _, snugglin in ipairs(snugglinData) do
        if snugglin.GetRarity() == "Epic" then
            table.insert(_filteredSnugglins, snugglin)
        end
    end
    if rarity == "Epic" then return _filteredSnugglins end 
    for _, snugglin in ipairs(snugglinData) do
        if snugglin.GetRarity() == "Leg" then
            table.insert(_filteredSnugglins, snugglin)
        end
    end
    return _filteredSnugglins
end

function UpdateSnugglinCount(count: number, rarity: string)
    local _filteredSnugglins = GetSnugglinBasedRarity(rarity)
    print("Updating snugglin count to: " .. count .. " of rarity: " .. rarity .. " (" .. #_filteredSnugglins .. " available)")
    
    if #_spawnedSnugglins > count then -- if we have more snugglins than desired, despawn extras
        local toDespawn = #_spawnedSnugglins - count
        for i = 1, toDespawn do
            WalkBackToSpawnAndDespawn(_spawnedSnugglins[#_spawnedSnugglins])
        end
    elseif #_spawnedSnugglins < count then -- if we have less snugglins than desired, spawn more
        local toSpawn = count - #_spawnedSnugglins
        for i = 1, toSpawn do
            local snugglinObject = SpawnAtPosition(rarity)
            WalkAndSitAtRandomAnchor(snugglinObject)
        end
    end

end


local function getCharacterFromGameObject(gameObject: GameObject): Character | nil
    if not gameObject then
        return nil
    end
    return gameObject:GetComponent(Character)
end

-- local function getRandomSnugglinData(): SnugglinBase
--     local _randomIndex = math.random(1, #snugglinData)
--     return snugglinData[_randomIndex]
-- end

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
function SpawnAtPosition(rarity: string): GameObject | nil
    local spawnPos = spawnPointOBJ.transform.position
    if not snugglinPrefab then
        print("ERROR: No snugglinPrefab assigned in SnugglinManager")
        return nil
    end

    local _spawnedNpc = Object.Instantiate(snugglinPrefab, spawnPos, Quaternion.identity)
    local _character = getCharacterFromGameObject(_spawnedNpc)
    if not _character then return nil end
    local _snugglins = GetSnugglinBasedRarity(rarity)
    local _randomIndex = math.random(1, #_snugglins)
    local _snugglinData = _snugglins[_randomIndex]
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
    if not snugglinObject then return false end

    local _character = getCharacterFromGameObject(snugglinObject)
    if not _character then return false end

    local _anchor = getRandomSittingAnchor()
    if not _anchor then return false end

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
    if not snugglinObject then return false end

    local _character = getCharacterFromGameObject(snugglinObject)
    if not _character then return false end

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
    if not snugglinObject then return false end

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
    print("Adding to seen snugglins: " .. snugglinName, _seenSnugglins[snugglinName] == nil)

    if not _seenSnugglins[snugglinName] then 
        print("Revealing snugglin picture frame: " .. snugglinName)
        -- grab all the objects with the picture frame tag
        local pictureFrames = GameObject.FindGameObjectsWithTag("PictureFrame")
        for _, frame in ipairs(pictureFrames) do
            print("Checking picture frame: " .. frame.name, frame.name == snugglinName)
            if frame.name == snugglinName then
                print("Found picture frame for snugglin: " .. snugglinName)
                -- turn on all children of the frame to make it visible
                for i = 0, frame.transform.childCount - 1 do
                    local child = frame.transform:GetChild(i)
                    child.gameObject:SetActive(true)
                end
                return
            end
        end
        _seenSnugglins[snugglinName] = true

    end 
end

function HasSeenSnugglin(snugglinName: string): boolean
    return _seenSnugglins[snugglinName] == true
end

function self:ServerAwake()
    CompletedOrderRequest:Connect(function(player)
        -- Increase room score
        _roomScore = _roomScore + 30
        UpdateSnugglinCountEvent:FireAllClients(_roomScore, true)
        -- Update snugglin count based on score
    end)
    Timer.Every(3, function()  
        -- decerment room score over time
        _roomScore = math.max(1, _roomScore - 3) 
        UpdateSnugglinCountEvent:FireAllClients(_roomScore, false)
    end)
end

function updateRoomRarity(newRarity: string)
    if newRarity == _roomRarity then
        return
    end

    _roomRarity = newRarity
    audioManager.PlayingMusic(newRarity, true)
end


function self:ClientStart()
    audioManager.PlayingMusic(_roomRarity, true)

    -- Client-side initialization if needed
    UpdateSnugglinCountEvent:Connect(function(roomScore: number, increased: boolean)
        print("Updating snugglin count based on room score: " .. roomScore)
        
        local snugglinCount = math.floor(roomScore / 20)
        local currentSnugglinCount = #GameObject.FindGameObjectsWithTag("Snugglins")

        if not increased then
            snugglinCount = math.ceil(_roomScore / 20)
            print("Room score decreased to: " .. snugglinCount, currentSnugglinCount)
        end

        if snugglinCount == currentSnugglinCount and snugglinCount ~= 0 then
            return
        end

        roomMeterHUD.SetValue(_roomScore)

        if snugglinCount <= 0 then 
            snugglinCount = 1 
            print("Ensuring at least one snugglin is present")
        end

        _roomScore = roomScore
        if _roomScore >= LENDARY_TRESHOLD then
            UpdateSnugglinCount(snugglinCount, "Leg")
            updateRoomRarity("legendary")
            
        elseif _roomScore >= EPIC_TRESHOLD then
            UpdateSnugglinCount(snugglinCount, "Epic")
            updateRoomRarity("epic")
            
        else
            UpdateSnugglinCount(snugglinCount, "Rare")
            updateRoomRarity("rare")
        end
    end)
end

