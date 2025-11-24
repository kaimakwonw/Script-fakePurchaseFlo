--[[
    Kaisure UGC Tools - Versão Compacta com Minimizar/Fechar
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local UGC_IDS = {}
local DELAY = 0.1
local LOOP = false
local MINIMIZED = false

-----------------------------------------
-- HOOKS
-----------------------------------------

local function setupHooks()
    local idx
    idx = hookmetamethod(game, "__index", function(self, key)
        for _, id in ipairs(UGC_IDS) do
            if tostring(self):match("Ownership|Inventory|UGC") then
                return true
            end
        end
        return idx(self, key)
    end)

    local nc
    nc = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local m = getnamecallmethod()

        for _, id in ipairs(UGC_IDS) do
            if m == "PerformPurchase" and args[2] == id then
                return {
                    purchaseId = HttpService:GenerateGUID(false),
                    success = true,
                    assetId = id,
                    resale = true
                }
            end
            if m == "GetProductInfo" and args[1] == id then
                return {
                    AssetId = id,
                    PriceInRobux = 0,
                    IsForSale = true,
                    IsOwned = true
                }
            end
        end
        return nc(self, ...)
    end)
end

setupHooks()

-----------------------------------------
-- UI COMPACTA COM MINIMIZAR/FECHAR
-----------------------------------------

local gui = Instance.new("ScreenGui", LP.PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 280, 0, 200)
frame.Position = UDim2.new(.5, -140, .5, -100)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", frame)

local bar = Instance.new("TextLabel", frame)
bar.Size = UDim2.new(1,0,0,25)
bar.BackgroundColor3 = Color3.fromRGB(45,45,45)
bar.Text = "Kaisure UGC"
bar.TextColor3 = Color3.new(1,1,1)
bar.Font = Enum.Font.GothamBold
bar.TextSize = 14
Instance.new("UICorner", bar)

-- Botão Fechar
local closeBtn = Instance.new("TextButton", bar)
closeBtn.Size = UDim2.new(0, 20, 0, 20)
closeBtn.Position = UDim2.new(1, -25, 0.5, -10)
closeBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.new(1,1,1)
closeBtn.TextSize = 12
closeBtn.ZIndex = 2
Instance.new("UICorner", closeBtn)

-- Botão Minimizar
local minBtn = Instance.new("TextButton", bar)
minBtn.Size = UDim2.new(0, 20, 0, 20)
minBtn.Position = UDim2.new(1, -50, 0.5, -10)
minBtn.BackgroundColor3 = Color3.fromRGB(240, 180, 60)
minBtn.Text = "_"
minBtn.TextColor3 = Color3.new(1,1,1)
minBtn.TextSize = 12
minBtn.ZIndex = 2
Instance.new("UICorner", minBtn)

-- Conteúdo principal (será escondido quando minimizado)
local content = Instance.new("Frame", frame)
content.Size = UDim2.new(1, 0, 1, -25)
content.Position = UDim2.new(0, 0, 0, 25)
content.BackgroundTransparency = 1
content.Name = "Content"

local box = Instance.new("TextBox", content)
box.Size = UDim2.new(1,-20,0,25)
box.Position = UDim2.new(0,10,0,10)
box.BackgroundColor3 = Color3.fromRGB(50,50,50)
box.PlaceholderText = "IDs separados por vírgula"
box.TextColor3 = Color3.new(1,1,1)
box.TextSize = 12
Instance.new("UICorner", box)

local delayBtn = Instance.new("TextButton", content)
delayBtn.Size = UDim2.new(.45,0,0,25)
delayBtn.Position = UDim2.new(.05,0,0,45)
delayBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
delayBtn.Text = "Delay: 0.1"
delayBtn.TextSize = 12
Instance.new("UICorner", delayBtn)

local runBtn = Instance.new("TextButton", content)
runBtn.Size = UDim2.new(.45,0,0,25)
runBtn.Position = UDim2.new(.5,0,0,45)
runBtn.BackgroundColor3 = Color3.fromRGB(0,140,70)
runBtn.Text = "EXECUTAR"
runBtn.TextSize = 12
Instance.new("UICorner", runBtn)

local loopBtn = Instance.new("TextButton", content)
loopBtn.Size = UDim2.new(.9,0,0,25)
loopBtn.Position = UDim2.new(.05,0,0,80)
loopBtn.BackgroundColor3 = Color3.fromRGB(140,40,40)
loopBtn.Text = "INICIAR LOOP"
loopBtn.TextSize = 12
Instance.new("UICorner", loopBtn)

local status = Instance.new("TextLabel", content)
status.Size = UDim2.new(.9,0,0,50)
status.Position = UDim2.new(.05,0,0,115)
status.TextWrapped = true
status.TextColor3 = Color3.new(1,1,1)
status.BackgroundTransparency = 1
status.Text = "Aguardando IDs..."
status.TextSize = 11

-----------------------------------------
-- DRAG MOBILE/PC
-----------------------------------------

local dragging, dragStart, startPos

bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = frame.Position
        i.Changed:Connect(function()
            if i.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-----------------------------------------
-- FUNÇÕES MINIMIZAR/FECHAR
-----------------------------------------

local function toggleMinimize()
    MINIMIZED = not MINIMIZED
    if MINIMIZED then
        content.Visible = false
        frame.Size = UDim2.new(0, 280, 0, 25)
        minBtn.Text = "+"
    else
        content.Visible = true
        frame.Size = UDim2.new(0, 280, 0, 200)
        minBtn.Text = "_"
    end
end

local function closeGUI()
    gui:Destroy()
end

minBtn.MouseButton1Click:Connect(toggleMinimize)
closeBtn.MouseButton1Click:Connect(closeGUI)

-----------------------------------------
-- FUNÇÕES PRINCIPAIS
-----------------------------------------

local function fakePurchase()
    for _, id in ipairs(UGC_IDS) do
        pcall(function()
            MarketplaceService:SignalPromptPurchaseFinished(LP, id, true)
        end)
        task.wait(0.05)
    end
end

box.FocusLost:Connect(function()
    UGC_IDS = {}
    for id in box.Text:gmatch("%d+") do
        table.insert(UGC_IDS, tonumber(id))
    end
    status.Text = "IDs: " .. #UGC_IDS
end)

delayBtn.MouseButton1Click:Connect(function()
    DELAY += 0.1
    if DELAY > 1 then DELAY = 0.1 end
    delayBtn.Text = "Delay: " .. DELAY
end)

runBtn.MouseButton1Click:Connect(function()
    if #UGC_IDS == 0 then status.Text = "Adicione IDs!"; return end
    status.Text = "Executando..."
    fakePurchase()
    status.Text = "Concluído!"
end)

loopBtn.MouseButton1Click:Connect(function()
    if #UGC_IDS == 0 then status.Text = "Adicione IDs!"; return end
    LOOP = not LOOP
    loopBtn.Text = LOOP and "PARAR LOOP" or "INICIAR LOOP"
    loopBtn.BackgroundColor3 = LOOP and Color3.fromRGB(0,140,70) or Color3.fromRGB(140,40,40)
    status.Text = LOOP and "Loop ativo..." or "Loop parado."
    if LOOP then
        task.spawn(function()
            while LOOP do
                fakePurchase()
                task.wait(DELAY)
            end
        end)
    end
end)

print("Kaisure Tools Compacto carregado.")
