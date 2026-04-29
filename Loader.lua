Deadline ESP + Chams

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local CharFolder = Workspace:WaitForChild("characters")

local ESP_ENABLED = true
local DRAWINGS = {}
local CHAMS = {}
local CreationConnection = nil  -- used for permanent destroy

print("Deadline ESP + CHAMS | Loaded")

local function getRoot(model)
    return model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart", true)
end

local function createESP(model)
    if DRAWINGS[model] then return end
    local drawings = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Tracer = Drawing.new("Line")
    }
    
    drawings.Box.Thickness = 1
    drawings.Box.Filled = false
    drawings.Box.Transparency = 1
    drawings.Box.Color = Color3.fromRGB(0, 255, 255)   -- Cyan
    
    drawings.Name.Size = 13
    drawings.Name.Center = true
    drawings.Name.Outline = true
    drawings.Name.Font = 2
    drawings.Name.Color = Color3.fromRGB(255, 255, 100) -- Yellow
    
    drawings.Tracer.Thickness = 1
    drawings.Tracer.Transparency = 0.75
    drawings.Tracer.Color = Color3.fromRGB(255, 0, 0)   -- Red
    
    DRAWINGS[model] = drawings
end

local function createChams(model)
    if CHAMS[model] then return end
    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.fromRGB(255, 165, 0)      -- Orange
    highlight.OutlineColor = Color3.fromRGB(255, 200, 0)
    highlight.FillTransparency = 0.65
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Adornee = model
    highlight.Parent = model
    CHAMS[model] = highlight
end

local function updateESP()
    for model, drawings in pairs(DRAWINGS) do
        if not model.Parent or not getRoot(model) then
            for _, d in pairs(drawings) do d.Visible = false end
            continue
        end
        
        local root = getRoot(model)
        local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen or rootPos.Z < 0 then
            for _, d in pairs(drawings) do d.Visible = false end
            continue
        end
        
        if not ESP_ENABLED then
            for _, d in pairs(drawings) do d.Visible = false end
            continue
        end
        
        -- Box
        local topPos = Camera:WorldToViewportPoint(root.Position + Vector3.new(0, 2.5, 0))
        local bottomPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        local boxHeight = math.abs(topPos.Y - bottomPos.Y)
        local boxWidth = boxHeight * 0.6
        local boxPos = Vector2.new(rootPos.X - boxWidth/2, math.min(topPos.Y, bottomPos.Y))
        
        drawings.Box.Size = Vector2.new(boxWidth, boxHeight)
        drawings.Box.Position = boxPos
        drawings.Box.Visible = true
        
        -- Name
        local dist = math.floor((root.Position - (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position or root.Position)).Magnitude)
        drawings.Name.Text = model.Name .. " [" .. dist .. "m]"
        drawings.Name.Position = Vector2.new(rootPos.X, boxPos.Y - 20)
        drawings.Name.Visible = true
        
        -- Tracer
        drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
        drawings.Tracer.To = Vector2.new(rootPos.X, bottomPos.Y)
        drawings.Tracer.Visible = true
    end
end

-- Initial scan
for _, model in ipairs(CharFolder:GetChildren()) do
    if getRoot(model) then
        createESP(model)
        createChams(model)
    end
end

-- New models (stored so we can disconnect with END)
CreationConnection = CharFolder.ChildAdded:Connect(function(model)
    task.wait(0.3)
    if getRoot(model) then
        createESP(model)
        createChams(model)
    end
end)

RunService.RenderStepped:Connect(updateESP)

-- Hotkeys
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    
    if input.KeyCode == Enum.KeyCode.Insert then
        ESP_ENABLED = not ESP_ENABLED
        for _, h in pairs(CHAMS) do
            if h and h.Parent then h.Enabled = ESP_ENABLED end
        end
        print("ESP + Chams Toggled →", ESP_ENABLED)
        
    elseif input.KeyCode == Enum.KeyCode.End then
        print("END pressed - DESTROY")
        
        -- Destroy drawings
        for _, drawings in pairs(DRAWINGS) do
            for _, d in pairs(drawings) do pcall(function() d:Remove() end) end
        end
        
        -- Destroy chams
        for _, h in pairs(CHAMS) do
            pcall(function() h:Destroy() end)
        end
        
        -- Extra cleanup of any leftover highlights
        for _, model in ipairs(CharFolder:GetChildren()) do
            for _, obj in ipairs(model:GetDescendants()) do
                if obj:IsA("Highlight") then
                    pcall(function() obj:Destroy() end)
                end
            end
        end
        
        -- Kill the creator connection so nothing can recreate on respawn
        if CreationConnection then
            CreationConnection:Disconnect()
            CreationConnection = nil
        end
        
        DRAWINGS = {}
        CHAMS = {}
        ESP_ENABLED = false
        print("All ESP + Chams destroyed..")
    end
end)

print("Controls:")
print("   INS  → Toggle ESP + Chams")
print("   END  → Completely destroy everything")
