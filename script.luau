
local Players = game:GetService("Players")

local SHIRT_ID = 6237975654
local PANTS_ID = 6237974014
local HEAD_ID = 6202818787

-- Load assets using ID only
local function loadAsset(id, className)
    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. id)
    end)

    if not ok or not objects then
        warn("Failed to load asset:", id)
        return nil
    end

    local result

    for _, root in ipairs(objects) do
        local found

        if root:IsA(className) then
            found = root
        else
            found = root:FindFirstChildWhichIsA(
                className, true
            )
        end

        if found and not result then
            result = found:Clone()
        end

        root:Destroy()
    end

    return result
end

local shirt = loadAsset(SHIRT_ID, "Shirt")
local pants = loadAsset(PANTS_ID, "Pants")
local headAccessory = loadAsset(HEAD_ID, "Accessory")

-- Remove all original appearance
local function clearAppearance(character)
    for _, obj in ipairs(character:GetChildren()) do
        if obj:IsA("Accessory")
            or obj:IsA("Shirt")
            or obj:IsA("Pants")
            or obj:IsA("ShirtGraphic")
            or obj:IsA("CharacterMesh")
            or obj:IsA("BodyColors") then

            obj:Destroy()
        end
    end

    local head = character:FindFirstChild("Head")

    if head then
        -- Remove original face
        for _, obj in ipairs(head:GetDescendants()) do
            if obj:IsA("Decal")
                or obj:IsA("Texture") then
                obj:Destroy()
            end
        end

        -- Hide original head only if replacement loaded
        if headAccessory then
            head.Transparency = 1
        end
    end
end

-- Attach new head accessory
local function attachHead(character)
    if not headAccessory then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    local accessory = headAccessory:Clone()
    accessory.Name = "CustomHead"

    local handle = accessory:FindFirstChild("Handle")
    if not handle then
        accessory:Destroy()
        return
    end

    handle.Anchored = false
    handle.CanCollide = false
    handle.CanTouch = false
    handle.Massless = true

    local attachment =
        handle:FindFirstChildWhichIsA("Attachment")

    local target = nil

    if attachment then
        target = character:FindFirstChild(
            attachment.Name, true
        )

        if target and not target:IsA("Attachment") then
            target = nil
        end
    end

    local part0 = head
    local c0
    local c1

    if target and target.Parent:IsA("BasePart") then
        part0 = target.Parent
        c0 = target.CFrame
        c1 = attachment.CFrame
    else
        c0 = CFrame.new(0, head.Size.Y / 2, 0)
        c1 = accessory.AttachmentPoint
    end

    accessory.Parent = character

    handle.CFrame =
        part0.CFrame * c0 * c1:Inverse()

    local weld = Instance.new("Weld")
    weld.Name = "AccessoryWeld"
    weld.Part0 = part0
    weld.Part1 = handle
    weld.C0 = c0
    weld.C1 = c1
    weld.Parent = handle
end

-- Apply complete outfit
local function apply(character)
    if not character or not character.Parent then
        return
    end

    local humanoid =
        character:FindFirstChildOfClass("Humanoid")

    if not humanoid then return end

    -- Step 1: Remove old appearance
    clearAppearance(character)

    -- Step 2: Apply new shirt
    if shirt then
        shirt:Clone().Parent = character
    end

    -- Step 3: Apply new pants
    if pants then
        pants:Clone().Parent = character
    end

    -- Step 4: Apply new head accessory
    attachHead(character)
end

-- Existing players and NPCs
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Humanoid") then
        task.spawn(function()
            pcall(apply, obj.Parent)
        end)
    end
end

-- Newly spawned NPCs
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Humanoid") then
        task.delay(1, function()
            if obj.Parent then
                pcall(apply, obj.Parent)
            end
        end)
    end
end)

-- Players joining and respawning
local function setup(player)
    player.CharacterAdded:Connect(function(character)
        task.delay(2, function()
            if character.Parent then
                pcall(apply, character)
            end
        end)
    end)

    player.CharacterAppearanceLoaded:Connect(function(character)
        pcall(apply, character)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setup(player)
end

Players.PlayerAdded:Connect(setup)

print("Shirt:", shirt ~= nil)
print("Pants:", pants ~= nil)
print("Head:", headAccessory ~= nil)
print("Outfit replacement activated!")
