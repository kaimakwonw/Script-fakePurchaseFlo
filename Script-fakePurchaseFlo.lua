--[[
    Kaisure UGC Tools - Versão Curta / Mobile-Friendly
    Arrastável no celular + Hooks + Fake Purchase + UI simples
]]

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local UGC_IDS = {}
local DELAY = 0.1
local LOOP = false

-----------------------------------------
-- HOOKS
-----------------------------------------

local function setupHooks()
    local function fakeReturn(cond, val, orig, self, keyOrMethod, ...)
        if cond then return val end
        return orig(self, keyOrMethod, ...)
    end

    local idx
    idx = hookmetamethod(game, "__index", function(self, key)
        for _, id in ipairs(UGC_IDS) do
            if tostring(self):match("Ownership|Inventory|UGC") then
                return fakeReturn(true, true, idx, self, key)
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
            if m == "ProcessReceipt" and args[1] and (args[1].ProductId == id) then
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
            if (m == "HttpGet" or m == "HttpGetAsync")
                and tostring(args[1]):match("inventory") then
                return HttpService:JSONEncode({
                    owned = true,
                    assetId = id,
                    userId = LP.UserId
                })
            end
        end

        return nc(self, ...)
    end)
end

setupHooks()

-----------------------------------------
-- Fake purchase simples
-----------------------------------------

local function fakePurchase()
    for _, id in ipairs(UGC_IDS) do
        pcall(function()
            MarketplaceService:SignalPromptPurchaseFinished(LP, id, true)
        end)
        task.wait(0.05)
    end
end

-----------------------------------------
-- UI SHORT VERSION + MOBILE DRAG
-----------------------------------------

local gui = Instance.new("ScreenGui", LP.PlayerGui)
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 330, 0, 350)
frame.Position = UDim2.new(.5, -165, .5, -175)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

Instance.new("UICorner", frame)

local bar = Instance.new("TextLabel", frame)
bar.Size = UDim2.new(1,0,0,35)
bar.BackgroundColor3 = Color3.fromRGB(45,45,45)
bar.Text = "Kaisure UGC Tools"
bar.TextColor3 = Color3.new(1,1,1)
bar.Font = Enum.Font.GothamBold
bar.TextSize = 16

Instance.new("UICorner", bar)

-- INPUT UGC
local box = Instance.new("TextBox", frame)
box.Size = UDim2.new(1,-20,0,30)
box.Position = UDim2.new(0,10,0,50)
box.BackgroundColor3 = Color3.fromRGB(50,50,50)
box.PlaceholderText = "IDs separados por vírgula"
box.TextColor3 = Color3.new(1,1,1)

Instance.new("UICorner", box)

-- DELAY BUTTON
local delayBtn = Instance.new("TextButton", frame)
delayBtn.Size = UDim2.new(.45,0,0,35)
delayBtn.Position = UDim2.new(.05,0,0,100)
delayBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
delayBtn.Text = "Delay: 0.1"

Instance.new("UICorner", delayBtn)

-- RUN BUTTON
local runBtn = Instance.new("TextButton", frame)
runBtn.Size = UDim2.new(.45,0,0,35)
runBtn.Position = UDim2.new(.5,0,0,100)
runBtn.BackgroundColor3 = Color3.fromRGB(0,140,70)
runBtn.Text = "EXECUTAR"

Instance.new("UICorner", runBtn)

-- LOOP BUTTON
local loopBtn = Instance.new("TextButton", frame)
loopBtn.Size = UDim2.new(.9,0,0,35)
loopBtn.Position = UDim2.new(.05,0,0,145)
loopBtn.BackgroundColor3 = Color3.fromRGB(140,40,40)
loopBtn.Text = "INICIAR LOOP"

Instance.new("UICorner", loopBtn)

-- STATUS
local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(.9,0,0,80)
status.Position = UDim2.new(.05,0,0,195)
status.TextWrapped = true
status.TextColor3 = Color3.new(1,1,1)
status.BackgroundTransparency = 1
status.Text = "Aguardando IDs..."

-----------------------------------------
-- MOBILE + PC DRAG
-----------------------------------------

local dragging = false
local dragStart
local startPos

local function drag(input)
    local delta = input.Position - dragStart
    frame.Position = UDim2.new(
        startPos.X.Scale, startPos.X.Offset + delta.X,
        startPos.Y.Scale, startPos.Y.Offset + delta.Y
    )
end

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
        drag(i)
    end
end)

-----------------------------------------
-- HANDLERS
-----------------------------------------

box.FocusLost:Connect(function()
    UGC_IDS = {}
    for id in box.Text:gmatch("%d+") do
        table.insert(UGC_IDS, tonumber(id))
    end
    status.Text = "IDs carregados: " .. #UGC_IDS
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

print("Kaisure Tools carregado.")
