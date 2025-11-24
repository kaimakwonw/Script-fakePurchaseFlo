-- Script UI Roblox com Fake Purchase UGC - CORRIGIDO
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local UGC_IDS = {}
local DELAY = 0.1
local IS_LOOPING = false

-- HOOKS CORRETOS (igual ao script pequeno)
local function setupHooks()
    -- Hook __index para ownership
    local originalIndex
    originalIndex = hookmetamethod(game, "__index", function(self, key)
        for _, assetId in pairs(UGC_IDS) do
            if tostring(self):match("AssetOwnership|Inventory|PlayerData") and tostring(key):match("Owned|Items|UGC") then
                return true
            end
        end
        return originalIndex(self, key)
    end)

    -- Hook __namecall para PerformPurchase
    local originalNamecall
    originalNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        for _, assetId in pairs(UGC_IDS) do
            if method == "PerformPurchase" and args[2] == assetId then
                return {
                    purchaseId = HttpService:GenerateGUID(false),
                    success = true,
                    assetId = assetId,
                    resale = true
                }
            end
        end
        return originalNamecall(self, ...)
    end)

    -- Hook GetProductInfo
    local originalGetProductInfo
    originalGetProductInfo = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        for _, assetId in pairs(UGC_IDS) do
            if method == "GetProductInfo" and args[1] == assetId then
                return {
                    AssetId = assetId,
                    ProductId = assetId,
                    PriceInRobux = 0,
                    IsLimited = true,
                    IsForSale = true,
                    IsOwned = true
                }
            end
        end
        return originalGetProductInfo(self, ...)
    end)

    -- Hook ProcessReceipt
    local originalProcessReceipt
    originalProcessReceipt = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        for _, assetId in pairs(UGC_IDS) do
            if method == "ProcessReceipt" and args[1] and (args[1].ProductId == assetId or args[1].AssetId == assetId) then
                return Enum.ProductPurchaseDecision.PurchaseGranted
            end
        end
        return originalProcessReceipt(self, ...)
    end)

    -- Hook HttpGet para inventory
    local originalHttpGet
    originalHttpGet = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        for _, assetId in pairs(UGC_IDS) do
            if (method == "HttpGet" or method == "HttpGetAsync") and args[1]:match("inventory%.roblox%.com") and args[1]:match(tostring(assetId)) then
                return HttpService:JSONEncode({
                    success = true,
                    owned = true,
                    assetId = assetId,
                    userId = LocalPlayer.UserId
                })
            end
        end
        return originalHttpGet(self, ...)
    end)

    -- Hook para inventory do jogo
    local originalGameIndex
    originalGameIndex = hookmetamethod(game, "__index", function(self, key)
        for _, assetId in pairs(UGC_IDS) do
            if tostring(self):match("Inventory|PlayerData|UGCSystem") and tostring(key):match("Items|Inventory|UGC") then
                return {[tostring(assetId)] = {id = assetId, owned = true}}
            end
        end
        return originalGameIndex(self, key)
    end)
end

-- Funções do Fake Purchase (SIMPLIFICADAS)
local function log(message)
    print("[FakePurchase] " .. message)
end

local function simulateUIInteraction()
    pcall(function()
        for _, gui in pairs(LocalPlayer.PlayerGui:GetDescendants()) do
            if gui:IsA("TextButton") or gui:IsA("ImageButton") then
                if gui.Name:lower():match("trade|use|equip|claim") then
                    gui.Activated:Fire()
                end
            end
        end
    end)
end

local function fakePurchaseFlow()
    for _, assetId in pairs(UGC_IDS) do
        pcall(function()
            -- Simula a compra via hooks que já estão ativos
            MarketplaceService:SignalPromptPurchaseFinished(LocalPlayer, assetId, true)
            
            -- Dispara eventos de inventory
            local inventoryEvent = Instance.new("BindableEvent")
            inventoryEvent.Name = "InventoryUpdated"
            inventoryEvent:Fire(LocalPlayer, {AssetId = assetId, Owned = true, Resale = true})
            
            simulateUIInteraction()
            log("Fake purchase successful for ID: " .. assetId)
        end)
        task.wait(0.05)
    end
end

local function runAssetSequence()
    for _, assetId in ipairs(UGC_IDS) do
        if not IS_LOOPING then break end
        pcall(function()
            fakePurchaseFlow()
        end)
        task.wait(DELAY)
    end
end

-- SETUP HOOKS ANTES DA UI (ORDEM CORRETA)
setupHooks()

-- Criar UI Nativa do Roblox (VERSÃO MOBILE REDUZIDA)
local function CreateNativeUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KaisureUGCTools"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    -- FRAME PRINCIPAL (REDUZIDO)
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 280, 0, 360)
    MainFrame.Position = UDim2.new(0.5, -140, 0.5, -180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = MainFrame

    -- TÍTULO
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 40)
    TitleBar.BackgroundColor3 = Color3.fromRGB(45,45,45)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    TitleLabel.Position = UDim2.new(0, 10, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "Kaisure UGC Tools"
    TitleLabel.TextColor3 = Color3.fromRGB(255,255,255)
    TitleLabel.TextSize = 14
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TitleBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 32, 0, 32)
    CloseButton.Position = UDim2.new(1, -36, 0.5, -16)
    CloseButton.BackgroundColor3 = Color3.fromRGB(200,60,60)
    CloseButton.Text = "X"
    CloseButton.TextColor3 = Color3.fromRGB(255,255,255)
    CloseButton.TextSize = 16
    CloseButton.Font = Enum.Font.GothamBold
    CloseButton.Parent = TitleBar

    local MinimizeButton = Instance.new("TextButton")
    MinimizeButton.Size = UDim2.new(0, 32, 0, 32)
    MinimizeButton.Position = UDim2.new(1, -72, 0.5, -16)
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(80,80,80)
    MinimizeButton.Text = "_"
    MinimizeButton.TextColor3 = Color3.fromRGB(255,255,255)
    MinimizeButton.TextSize = 16
    MinimizeButton.Font = Enum.Font.GothamBold
    MinimizeButton.Parent = TitleBar

    -- ÁREA DE CONTEÚDO
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Size = UDim2.new(1, -16, 1, -56)
    ContentFrame.Position = UDim2.new(0, 8, 0, 48)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = MainFrame

    ------------------------------------------------------------------------------------
    -- UGC INPUT (ENXUTO)
    ------------------------------------------------------------------------------------
    local UGCSection = Instance.new("Frame")
    UGCSection.Size = UDim2.new(1, 0, 0, 85)
    UGCSection.BackgroundColor3 = Color3.fromRGB(40,40,40)
    UGCSection.Parent = ContentFrame

    local UC = Instance.new("UICorner")
    UC.Parent = UGCSection

    local UGCLabel = Instance.new("TextLabel")
    UGCLabel.Size = UDim2.new(1, -16, 0, 20)
    UGCLabel.Position = UDim2.new(0, 8, 0, 5)
    UGCLabel.BackgroundTransparency = 1
    UGCLabel.Text = "IDs UGC:"
    UGCLabel.TextColor3 = Color3.fromRGB(255,255,255)
    UGCLabel.TextSize = 13
    UGCLabel.Font = Enum.Font.Gotham
    UGCLabel.TextXAlignment = Enum.TextXAlignment.Left
    UGCLabel.Parent = UGCSection

    local UGCInput = Instance.new("TextBox")
    UGCInput.Size = UDim2.new(1, -16, 0, 30)
    UGCInput.Position = UDim2.new(0, 8, 0, 30)
    UGCInput.BackgroundColor3 = Color3.fromRGB(60,60,60)
    UGCInput.TextColor3 = Color3.fromRGB(255,255,255)
    UGCInput.PlaceholderText = "123, 456..."
    UGCInput.TextSize = 13
    UGCInput.Font = Enum.Font.Gotham
    UGCInput.Parent = UGCSection

    local UC2 = Instance.new("UICorner")
    UC2.Parent = UGCInput

    ------------------------------------------------------------------------------------
    -- DELAY (MENOR)
    ------------------------------------------------------------------------------------
    local DelaySection = Instance.new("Frame")
    DelaySection.Size = UDim2.new(1, 0, 0, 55)
    DelaySection.Position = UDim2.new(0, 0, 0, 90)
    DelaySection.BackgroundColor3 = Color3.fromRGB(40,40,40)
    DelaySection.Parent = ContentFrame

    local D1 = Instance.new("UICorner")
    D1.Parent = DelaySection

    local DelayLabel = Instance.new("TextLabel")
    DelayLabel.Size = UDim2.new(1, -16, 0, 18)
    DelayLabel.Position = UDim2.new(0, 8, 0, 5)
    DelayLabel.BackgroundTransparency = 1
    DelayLabel.Text = "Delay: " .. DELAY
    DelayLabel.TextColor3 = Color3.fromRGB(255,255,255)
    DelayLabel.TextSize = 12
    DelayLabel.Font = Enum.Font.Gotham
    DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
    DelayLabel.Parent = DelaySection

    local DelaySlider = Instance.new("TextButton")
    DelaySlider.Size = UDim2.new(1, -16, 0, 24)
    DelaySlider.Position = UDim2.new(0, 8, 0, 28)
    DelaySlider.BackgroundColor3 = Color3.fromRGB(80,80,80)
    DelaySlider.Text = "Ajustar"
    DelaySlider.TextColor3 = Color3.fromRGB(255,255,255)
    DelaySlider.TextSize = 12
    DelaySlider.Font = Enum.Font.Gotham
    DelaySlider.Parent = DelaySection

    local DS = Instance.new("UICorner")
    DS.Parent = DelaySlider

    ------------------------------------------------------------------------------------
    -- BOTÕES (REDUZIDOS)
    ------------------------------------------------------------------------------------
    local ControlSection = Instance.new("Frame")
    ControlSection.Size = UDim2.new(1, 0, 0, 70)
    ControlSection.Position = UDim2.new(0, 0, 0, 150)
    ControlSection.BackgroundColor3 = Color3.fromRGB(40,40,40)
    ControlSection.Parent = ContentFrame

    local CC = Instance.new("UICorner")
    CC.Parent = ControlSection

    local RunButton = Instance.new("TextButton")
    RunButton.Size = UDim2.new(0.48, 0, 0, 30)
    RunButton.Position = UDim2.new(0.01, 0, 0.5, -15)
    RunButton.BackgroundColor3 = Color3.fromRGB(60,140,60)
    RunButton.Text = "RUN"
    RunButton.TextColor3 = Color3.fromRGB(255,255,255)
    RunButton.TextSize = 13
    RunButton.Font = Enum.Font.GothamBold
    RunButton.Parent = ControlSection

    local LoopButton = Instance.new("TextButton")
    LoopButton.Size = UDim2.new(0.48, 0, 0, 30)
    LoopButton.Position = UDim2.new(0.51, 0, 0.5, -15)
    LoopButton.BackgroundColor3 = Color3.fromRGB(140,60,60)
    LoopButton.Text = "LOOP"
    LoopButton.TextColor3 = Color3.fromRGB(255,255,255)
    LoopButton.TextSize = 13
    LoopButton.Font = Enum.Font.GothamBold
    LoopButton.Parent = ControlSection

    ------------------------------------------------------------------------------------
    -- STATUS (REDUZIDO)
    ------------------------------------------------------------------------------------
    local StatusSection = Instance.new("Frame")
    StatusSection.Size = UDim2.new(1, 0, 0, 50)
    StatusSection.Position = UDim2.new(0, 0, 0, 225)
    StatusSection.BackgroundColor3 = Color3.fromRGB(40,40,40)
    StatusSection.Parent = ContentFrame

    local SS = Instance.new("UICorner")
    SS.Parent = StatusSection

    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -16, 1, -10)
    StatusLabel.Position = UDim2.new(0, 8, 0, 5)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "Status: pronto."
    StatusLabel.TextColor3 = Color3.fromRGB(200,200,200)
    StatusLabel.TextSize = 11
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextWrapped = true
    StatusLabel.Parent = StatusSection

    ------------------------------------------------------------------------------------
    -- CRÉDITOS (REDUZIDO)
    ------------------------------------------------------------------------------------
    local CreditSection = Instance.new("Frame")
    CreditSection.Size = UDim2.new(1, 0, 0, 40)
    CreditSection.Position = UDim2.new(0, 0, 0, 280)
    CreditSection.BackgroundColor3 = Color3.fromRGB(40,40,40)
    CreditSection.Parent = ContentFrame

    local CS = Instance.new("UICorner")
    CS.Parent = CreditSection

    local CreditButton = Instance.new("TextButton")
    CreditButton.Size = UDim2.new(1, -16, 1, -10)
    CreditButton.Position = UDim2.new(0, 8, 0, 5)
    CreditButton.BackgroundColor3 = Color3.fromRGB(80,80,180)
    CreditButton.Text = "CRÉDITOS"
    CreditButton.TextColor3 = Color3.fromRGB(255,255,255)
    CreditButton.TextSize = 12
    CreditButton.Font = Enum.Font.GothamBold
    CreditButton.Parent = CreditSection

    local CC2 = Instance.new("UICorner")
    CC2.Parent = CreditButton

    -- Função para arrastar a janela
    local dragging = false
    local dragInput, mousePos, framePos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = MainFrame.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            MainFrame.Position = UDim2.new(
                framePos.X.Scale, 
                framePos.X.Offset + delta.X,
                framePos.Y.Scale, 
                framePos.Y.Offset + delta.Y
            )
        end
    end)

    -- Funções dos botões
    CloseButton.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)

    local isMinimized = false
    MinimizeButton.MouseButton1Click:Connect(function()
        isMinimized = not isMinimized
        if isMinimized then
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 280, 0, 40)}):Play()
            ContentFrame.Visible = false
        else
            TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 280, 0, 360)}):Play()
            ContentFrame.Visible = true
        end
    end)

    UGCInput.FocusLost:Connect(function()
        UGC_IDS = {}
        local text = UGCInput.Text or ""
        for id in text:gmatch("%d+") do
            table.insert(UGC_IDS, tonumber(id))
        end
        StatusLabel.Text = "Status: " .. #UGC_IDS .. " IDs carregados\nPronto para executar!"
    end)

    DelaySlider.MouseButton1Click:Connect(function()
        DELAY = DELAY + 0.1
        if DELAY > 1 then DELAY = 0.1 end
        DelayLabel.Text = "Delay: " .. DELAY .. " segundos"
        StatusLabel.Text = "Status: Delay ajustado para " .. DELAY .. "s"
    end)

    RunButton.MouseButton1Click:Connect(function()
        if #UGC_IDS == 0 then
            StatusLabel.Text = "Status: ERRO - Adicione IDs UGC primeiro!"
            return
        end
        
        StatusLabel.Text = "Status: Executando fake purchase..."
        spawn(function()
            fakePurchaseFlow()
            StatusLabel.Text = "Status: Fake purchase completo!\n" .. #UGC_IDS .. " IDs processados"
        end)
    end)

    LoopButton.MouseButton1Click:Connect(function()
        if #UGC_IDS == 0 then
            StatusLabel.Text = "Status: ERRO - Adicione IDs UGC primeiro!"
            return
        end
        
        IS_LOOPING = not IS_LOOPING
        
        if IS_LOOPING then
            LoopButton.Text = "PARAR LOOP"
            LoopButton.BackgroundColor3 = Color3.fromRGB(60, 140, 60)
            StatusLabel.Text = "Status: LOOP ATIVADO\nDelay: " .. DELAY .. "s"
            
            spawn(function()
                while IS_LOOPING do
                    runAssetSequence()
                    task.wait(0.5)
                end
            end)
        else
            LoopButton.Text = "LOOP"
            LoopButton.BackgroundColor3 = Color3.fromRGB(140, 60, 60)
            StatusLabel.Text = "Status: Loop parado"
        end
    end)

    CreditButton.MouseButton1Click:Connect(function()
        setclipboard("https://youtube.com/@imkaisure?si=hOx6mHvKYSVmobXP")
        StatusLabel.Text = "Status: Link copiado!\nSaindo do Roblox..."
        
        wait(2)
        game:Shutdown()
    end)

    StatusLabel.Text = "Status: Sistema carregado! Hooks ativos."

    return ScreenGui
end

-- Criar a UI (AGORA OS HOOKS JÁ ESTÃO ATIVOS)
pcall(function()
    CreateNativeUI()
    print("Kaisure UGC Tools - Hooks ativos e UI carregada!")
end)

-- 🔒 DIGITAL SIGNATURE: kaimakwonw/Script-fakePurchaseFlo - DO NOT MODIFY
-- 📅 Created: 2024-11-24 - Tracked by Git
