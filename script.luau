
local Players = game:GetService("Players")

local SHIRT_ID = 6237975654
local PANTS_ID = 6237974014
local HEAD_ID = 6202818787

local function loadAsset(id, className)
    local ok, objects = pcall(function()
        return game:GetObjects("rbxassetid://" .. id)
    end)

    if not ok or not objects then
        warn("Asset load failed:", id, objects)
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

    if not result then
        warn("Wrong asset type:", id, className)
    end

    return result
end

-- ID로 에셋 불러오기
local shirtTemplate = loadAsset(SHIRT_ID, "Shirt")
local pantsTemplate = loadAsset(PANTS_ID, "Pants")
local headTemplate = loadAsset(HEAD_ID, "Accessory")

local function attachHead(character)
    if not headTemplate then return end

    local head = character:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return
    end

    local old = character:FindFirstChild("LocalHeadAccessory")
    if old then
        old:Destroy()
    end

    local accessory = headTemplate:Clone()
    accessory.Name = "LocalHeadAccessory"

    local handle = accessory:FindFirstChild("Handle")
    if not handle or not handle:IsA("BasePart") then
        accessory:Destroy()
        return
    end

    handle.Anchored = false
    handle.CanCollide = false
    handle.CanTouch = false
    handle.Massless = true

    local handleAttachment =
        handle:FindFirstChildWhichIsA("Attachment")

    local targetAttachment

    if handleAttachment then
        targetAttachment = character:FindFirstChild(
            handleAttachment.Name, true
        )

        if targetAttachment
            and not targetAttachment:IsA("Attachment") then
            targetAttachment = nil
        end
    end

    local targetPart = head
    local c0
    local c1

    if targetAttachment
        and targetAttachment.Parent:IsA("BasePart") then

        targetPart = targetAttachment.Parent
        c0 = targetAttachment.CFrame
        c1 = handleAttachment.CFrame
    else
        -- R6 구형 액세서리 호환
        c0 = CFrame.new(0, head.Size.Y / 2, 0)
        c1 = accessory.AttachmentPoint
    end

    accessory.Parent = character

    handle.CFrame =
        targetPart.CFrame * c0 * c1:Inverse()

    local weld = Instance.new("Weld")
    weld.Name = "AccessoryWeld"
    weld.Part0 = targetPart
    weld.Part1 = handle
    weld.C0 = c0
    weld.C1 = c1
    weld.Parent = handle
end

local function applyOutfit(character)
    if not character or not character.Parent then
        return
    end

    if not character:FindFirstChildOfClass("Humanoid") then
        return
    end

    -- 기존 신체 부위는 건드리지 않음

    if shirtTemplate then
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Shirt") then
                obj:Destroy()
            end
        end

        shirtTemplate:Clone().Parent = character
    end

    if pantsTemplate then
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("Pants") then
                obj:Destroy()
            end
        end

        pantsTemplate:Clone().Parent = character
    end

    attachHead(character)
end

-- 현재 캐릭터와 NPC
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj:IsA("Humanoid") then
        pcall(applyOutfit, obj.Parent)
    end
end

-- 새 NPC
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Humanoid") then
        task.delay(1, function()
            pcall(applyOutfit, obj.Parent)
        end)
    end
end)

-- 새 플레이어와 리스폰
local function setup(player)
    player.CharacterAdded:Connect(function(character)
        task.delay(2, function()
            pcall(applyOutfit, character)
        end)
    end)

    player.CharacterAppearanceLoaded:Connect(function(character)
        pcall(applyOutfit, character)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setup(player)
end

Players.PlayerAdded:Connect(setup)

print("Shirt loaded:", shirtTemplate ~= nil)
print("Pants loaded:", pantsTemplate ~= nil)
print("Head loaded:", headTemplate ~= nil)
print("Client outfit script started")
