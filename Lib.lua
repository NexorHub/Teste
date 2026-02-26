local HttpService = game:GetService("HttpService")

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SISTEMA DE ARQUIVOS SEGURO                                 ║
-- ╚══════════════════════════════════════════════════════════════╝

local _canWrite  = type(writefile) == "function"
local _canRead   = type(readfile)  == "function"
local _canIsfile = type(isfile)    == "function"
local _canMkdir  = type(makefolder) == "function"

-- Criar pastas apenas se o executor permitir
if _canMkdir then
    pcall(function()
        if not _canIsfile or not isfile("Bastard X Hub") then
            makefolder("Bastard X Hub")
        end
    end)
    pcall(function()
        if not _canIsfile or not isfile("Bastard X Hub/Config") then
            makefolder("Bastard X Hub/Config")
        end
    end)
end

-- Obter nome do jogo de forma segura
local _ok, _info = pcall(function()
    return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
end)
local gameName = _ok and tostring(_info) or "UnknownGame"
gameName         = gameName:gsub("[^%w_ ]", "")
gameName         = gameName:gsub("%s+", "_")
if gameName == "" then gameName = "UnknownGame" end

local ConfigFile = "Bastard X Hub/Config/Bastard_" .. gameName .. ".json"
local THEME_FILE = "Bastard X Hub/Config/Theme_" .. gameName .. ".txt"

ConfigData       = {}
Elements         = {}
CURRENT_VERSION  = nil

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  TEMAS PADRÃO                                                ║
-- ╚══════════════════════════════════════════════════════════════╝

local PALETTES = {
    ["Dark"] = {
        ["Primary"] = Color3.fromRGB(255, 255, 255),
        ["Secondary"] = Color3.fromRGB(200, 200, 200),
        ["Surface"] = Color3.fromRGB(30, 30, 30),
        ["Tertiary"] = Color3.fromRGB(50, 50, 50),
        ["Text"] = Color3.fromRGB(255, 255, 255),
        ["Warn"] = Color3.fromRGB(255, 170, 0),
        ["Danger"] = Color3.fromRGB(255, 85, 85),
        ["Success"] = Color3.fromRGB(85, 255, 127),
        ["Background"] = Color3.fromRGB(18, 18, 18),
    },
    ["Cyan"] = {
        ["Primary"] = Color3.fromRGB(0, 200, 255),
        ["Secondary"] = Color3.fromRGB(100, 220, 255),
        ["Surface"] = Color3.fromRGB(15, 30, 40),
        ["Tertiary"] = Color3.fromRGB(25, 50, 65),
        ["Text"] = Color3.fromRGB(200, 255, 255),
        ["Warn"] = Color3.fromRGB(255, 170, 0),
        ["Danger"] = Color3.fromRGB(255, 85, 85),
        ["Success"] = Color3.fromRGB(85, 255, 127),
        ["Background"] = Color3.fromRGB(10, 20, 25),
    },
    ["Blue"] = {
        ["Primary"] = Color3.fromRGB(0, 100, 255),
        ["Secondary"] = Color3.fromRGB(100, 150, 255),
        ["Surface"] = Color3.fromRGB(15, 25, 50),
        ["Tertiary"] = Color3.fromRGB(25, 45, 80),
        ["Text"] = Color3.fromRGB(150, 200, 255),
        ["Warn"] = Color3.fromRGB(255, 170, 0),
        ["Danger"] = Color3.fromRGB(255, 85, 85),
        ["Success"] = Color3.fromRGB(85, 255, 127),
        ["Background"] = Color3.fromRGB(10, 15, 30),
    },
    ["Purple"] = {
        ["Primary"] = Color3.fromRGB(155, 89, 182),
        ["Secondary"] = Color3.fromRGB(188, 110, 220),
        ["Surface"] = Color3.fromRGB(25, 15, 40),
        ["Tertiary"] = Color3.fromRGB(40, 25, 65),
        ["Text"] = Color3.fromRGB(200, 150, 255),
        ["Warn"] = Color3.fromRGB(255, 170, 0),
        ["Danger"] = Color3.fromRGB(255, 85, 85),
        ["Success"] = Color3.fromRGB(85, 255, 127),
        ["Background"] = Color3.fromRGB(15, 10, 25),
    },
    ["Red"] = {
        ["Primary"] = Color3.fromRGB(231, 76, 60),
        ["Secondary"] = Color3.fromRGB(255, 120, 100),
        ["Surface"] = Color3.fromRGB(40, 15, 15),
        ["Tertiary"] = Color3.fromRGB(65, 25, 25),
        ["Text"] = Color3.fromRGB(255, 150, 150),
        ["Warn"] = Color3.fromRGB(255, 170, 0),
        ["Danger"] = Color3.fromRGB(255, 85, 85),
        ["Success"] = Color3.fromRGB(85, 255, 127),
        ["Background"] = Color3.fromRGB(25, 10, 10),
    },
    ["Green"] = {
        ["Primary"] = Color3.fromRGB(46, 204, 113),
        ["Secondary"] = Color3.fromRGB(85, 239, 196),
        ["Surface"] = Color3.fromRGB(15, 40, 20),
        ["Tertiary"] = Color3.fromRGB(25, 65, 35),
        ["Text"] = Color3.fromRGB(150, 255, 200),
        ["Warn"] = Color3.fromRGB(255, 170, 0),
        ["Danger"] = Color3.fromRGB(255, 85, 85),
        ["Success"] = Color3.fromRGB(85, 255, 127),
        ["Background"] = Color3.fromRGB(10, 25, 15),
    },
    ["Orange"] = {
        ["Primary"] = Color3.fromRGB(255, 140, 0),
        ["Secondary"] = Color3.fromRGB(255, 165, 100),
        ["Surface"] = Color3.fromRGB(40, 25, 10),
        ["Tertiary"] = Color3.fromRGB(65, 40, 20),
        ["Text"] = Color3.fromRGB(255, 180, 100),
        ["Warn"] = Color3.fromRGB(255, 170, 0),
        ["Danger"] = Color3.fromRGB(255, 85, 85),
        ["Success"] = Color3.fromRGB(85, 255, 127),
        ["Background"] = Color3.fromRGB(30, 18, 8),
    },
}

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  SISTEMA DE PERSISTÊNCIA DE TEMA                             ║
-- ╚══════════════════════════════════════════════════════════════╝

local function SaveTheme(name)
    if not _canWrite then return end
    pcall(function()
        writefile(THEME_FILE, name)
    end)
end

local function LoadTheme()
    if not _canRead then return "Dark" end
    local ok, data = pcall(function()
        return readfile(THEME_FILE)
    end)
    if ok and type(data) == "string" then
        data = data:match("^%s*(.-)%s*$")
        if PALETTES[data] then return data end
    end
    return "Dark"
end

function SaveConfig()
    if not _canWrite then return end
    pcall(function()
        ConfigData._version = CURRENT_VERSION
        writefile(ConfigFile, HttpService:JSONEncode(ConfigData))
    end)
end

function LoadConfigFromFile()
    if not CURRENT_VERSION or not _canRead then return end
    if _canIsfile then
        local ok = pcall(function()
            if isfile(ConfigFile) then
                local result = HttpService:JSONDecode(readfile(ConfigFile))
                if result._version == CURRENT_VERSION then
                    ConfigData = result
                else
                    ConfigData = { _version = CURRENT_VERSION }
                end
            else
                ConfigData = { _version = CURRENT_VERSION }
            end
        end)
        if not ok then
            ConfigData = { _version = CURRENT_VERSION }
        end
    else
        ConfigData = { _version = CURRENT_VERSION }
    end
end

function LoadConfigElements()
    for key, element in pairs(Elements) do
        if ConfigData[key] ~= nil and element.Set then
            element:Set(ConfigData[key], true)
        end
    end
end

local Icons = loadstring(game:HttpGet("https://raw.githubusercontent.com/NexorHub/Teste/refs/heads/main/Icons.lua"))()

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local CoreGui = game:GetService("CoreGui")
local viewport = workspace.CurrentCamera.ViewportSize

local function isMobileDevice()
    return UserInputService.TouchEnabled
        and not UserInputService.KeyboardEnabled
        and not UserInputService.MouseEnabled
end

local isMobile = isMobileDevice()

local function safeSize(pxWidth, pxHeight)
    local scaleX = pxWidth / viewport.X
    local scaleY = pxHeight / viewport.Y

    if isMobile then
        if scaleX > 0.5 then scaleX = 0.5 end
        if scaleY > 0.3 then scaleY = 0.3 end
    end

    return UDim2.new(scaleX, 0, scaleY, 0)
end

local function MakeDraggable(topbarobject, object)
    local function CustomPos(topbarobject, object)
        local Dragging, DragInput, DragStart, StartPosition

        local function UpdatePos(input)
            local Delta = input.Position - DragStart
            local pos = UDim2.new(
                StartPosition.X.Scale,
                StartPosition.X.Offset + Delta.X,
                StartPosition.Y.Scale,
                StartPosition.Y.Offset + Delta.Y
            )
            local Tween = TweenService:Create(object, TweenInfo.new(0.2), { Position = pos })
            Tween:Play()
        end

        topbarobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = input.Position
                StartPosition = object.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)

        topbarobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                DragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == DragInput and Dragging then
                UpdatePos(input)
            end
        end)
    end

    local function CustomSize(object)
        local Dragging, DragInput, DragStart, StartSize

        local minSizeX, minSizeY
        local defSizeX, defSizeY

        if isMobile then
            minSizeX, minSizeY = 100, 100
            defSizeX, defSizeY = 470, 270
        else
            minSizeX, minSizeY = 100, 100
            defSizeX, defSizeY = 640, 400
        end

        object.Size = UDim2.new(0, defSizeX, 0, defSizeY)

        local changesizeobject = Instance.new("Frame")
        changesizeobject.AnchorPoint = Vector2.new(1, 1)
        changesizeobject.BackgroundTransparency = 1
        changesizeobject.Size = UDim2.new(0, 40, 0, 40)
        changesizeobject.Position = UDim2.new(1, 20, 1, 20)
        changesizeobject.Name = "changesizeobject"
        changesizeobject.Parent = object

        local function UpdateSize(input)
            local Delta = input.Position - DragStart
            local newWidth = StartSize.X.Offset + Delta.X
            local newHeight = StartSize.Y.Offset + Delta.Y

            newWidth = math.max(newWidth, minSizeX)
            newHeight = math.max(newHeight, minSizeY)

            local Tween = TweenService:Create(object, TweenInfo.new(0.2), { Size = UDim2.new(0, newWidth, 0, newHeight) })
            Tween:Play()
        end

        changesizeobject.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                Dragging = true
                DragStart = input.Position
                StartSize = object.Size
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        Dragging = false
                    end
                end)
            end
        end)

        changesizeobject.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                DragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == DragInput and Dragging then
                UpdateSize(input)
            end
        end)
    end

    CustomSize(object)
    CustomPos(topbarobject, object)
end

function CircleClick(Button, X, Y)
    spawn(function()
        Button.ClipsDescendants = true
        local Circle = Instance.new("ImageLabel")
        Circle.Image = "rbxassetid://266543268"
        Circle.ImageColor3 = Color3.fromRGB(255, 105, 180)
        Circle.ImageTransparency = 0.8999999761581421
        Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Circle.BackgroundTransparency = 1
        Circle.ZIndex = 10
        Circle.Name = "Circle"
        Circle.Parent = Button

        local NewX = X - Circle.AbsolutePosition.X
        local NewY = Y - Circle.AbsolutePosition.Y
        Circle.Position = UDim2.new(0, NewX, 0, NewY)
        local Size = 0
        if Button.AbsoluteSize.X > Button.AbsoluteSize.Y then
            Size = Button.AbsoluteSize.X * 1.5
        elseif Button.AbsoluteSize.X < Button.AbsoluteSize.Y then
            Size = Button.AbsoluteSize.Y * 1.5
        else
            Size = Button.AbsoluteSize.X * 1.5
        end

        for i = 1, 10 do
            Circle.Size = UDim2.new(0, Size / 10 * i, 0, Size / 10 * i)
            Circle.ImageTransparency = 0.8999999761581421 + (0.1 / 10 * i)
            game:GetService("RunService").Heartbeat:Wait()
        end
        Circle:Destroy()
    end)
end

local BastardXHub = {}
BastardXHub.CurrentTheme = LoadTheme()
BastardXHub.Themes = PALETTES

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  CRIAR BIBLIOTECA                                            ║
-- ╚══════════════════════════════════════════════════════════════╝

function BastardXHub:CreateLib(WindowName, configIgnore)
    configIgnore = configIgnore or ""
    CURRENT_VERSION = WindowName

    local Tabs = {}
    local TabPages = {}
    local HotKeys = {
        Toggle = Enum.KeyCode.X,
        Close = Enum.KeyCode.F4,
    }

    local DropShadowHolder = Instance.new("Frame")
    DropShadowHolder.Name = "DropShadowHolder"
    DropShadowHolder.BackgroundTransparency = 1
    DropShadowHolder.BorderSizePixel = 0
    DropShadowHolder.Size = UDim2.new(0, 600, 0, 400)
    DropShadowHolder.Position = UDim2.new(0.5, -300, 0.5, -200)
    DropShadowHolder.ZIndex = 100
    DropShadowHolder.Parent = CoreGui
    DropShadowHolder.Visible = false

    -- ╔═══════════════════════════════════════════════════════════════╗
    -- ║  ANIMAÇÕES DE ENTRADA E SAÍDA                                ║
    -- ╚═══════════════════════════════════════════════════════════════╝

    local function AnimateIn()
        DropShadowHolder.Visible = true
        local windowFrame = DropShadowHolder:FindFirstChild("WindowFrame")
        if windowFrame then
            windowFrame.Size = UDim2.new(0, 600, 0, 0)
            windowFrame.Position = UDim2.new(0.5, -300, 0.5, 0)
            
            local tween = TweenService:Create(
                windowFrame,
                TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                {
                    Size = UDim2.new(0, 600, 0, 400),
                    Position = UDim2.new(0.5, -300, 0.5, -200)
                }
            )
            tween:Play()
        end
    end

    local function AnimateOut()
        local windowFrame = DropShadowHolder:FindFirstChild("WindowFrame")
        if windowFrame then
            local tween = TweenService:Create(
                windowFrame,
                TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                {
                    Size = UDim2.new(0, 600, 0, 0),
                    Position = UDim2.new(0.5, -300, 0.5, 0)
                }
            )
            tween:Play()
            tween.Completed:Connect(function()
                DropShadowHolder.Visible = false
            end)
        end
    end

    local WindowVisible = false

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end

        if input.KeyCode == HotKeys.Toggle then
            WindowVisible = not WindowVisible
            if WindowVisible then
                AnimateIn()
            else
                AnimateOut()
            end
        elseif input.KeyCode == HotKeys.Close then
            WindowVisible = false
            AnimateOut()
        end
    end)

    local DropShadow = Instance.new("Frame")
    DropShadow.Name = "DropShadow"
    DropShadow.AnchorPoint = Vector2.new(0.5, 0.5)
    DropShadow.BackgroundColor3 = Color3.new(0, 0, 0)
    DropShadow.BackgroundTransparency = 0.5
    DropShadow.BorderSizePixel = 0
    DropShadow.Size = UDim2.new(1, 20, 1, 20)
    DropShadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    DropShadow.CornerRadius = UDim.new(0, 12)
    DropShadow.Parent = DropShadowHolder

    local DropShadowCorner = Instance.new("UICorner")
    DropShadowCorner.CornerRadius = UDim.new(0, 12)
    DropShadowCorner.Parent = DropShadow

    local WindowFrame = Instance.new("Frame")
    WindowFrame.Name = "WindowFrame"
    WindowFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    WindowFrame.BackgroundColor3 = PALETTES[self.CurrentTheme]["Surface"]
    WindowFrame.BorderSizePixel = 0
    WindowFrame.Size = UDim2.new(0, 600, 0, 400)
    WindowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    WindowFrame.ZIndex = 101
    WindowFrame.Parent = DropShadowHolder

    local WindowCorner = Instance.new("UICorner")
    WindowCorner.CornerRadius = UDim.new(0, 12)
    WindowCorner.Parent = WindowFrame

    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.BackgroundColor3 = PALETTES[self.CurrentTheme]["Tertiary"]
    TitleBar.BorderSizePixel = 0
    TitleBar.Size = UDim2.new(1, 0, 0, 45)
    TitleBar.Parent = WindowFrame

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar

    local TitleText = Instance.new("TextLabel")
    TitleText.Name = "TitleText"
    TitleText.BackgroundTransparency = 1
    TitleText.Size = UDim2.new(1, -60, 1, 0)
    TitleText.Position = UDim2.new(0, 15, 0, 0)
    TitleText.TextColor3 = PALETTES[self.CurrentTheme]["Text"]
    TitleText.TextSize = 16
    TitleText.Font = Enum.Font.GothamBold
    TitleText.TextXAlignment = Enum.TextXAlignment.Left
    TitleText.Text = WindowName
    TitleText.Parent = TitleBar

    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.BorderSizePixel = 0
    ContentFrame.Size = UDim2.new(1, 0, 1, -45)
    ContentFrame.Position = UDim2.new(0, 0, 0, 45)
    ContentFrame.Parent = WindowFrame

    local TabsContainer = Instance.new("ScrollingFrame")
    TabsContainer.Name = "TabsContainer"
    TabsContainer.BackgroundColor3 = PALETTES[self.CurrentTheme]["Tertiary"]
    TabsContainer.BorderSizePixel = 0
    TabsContainer.Size = UDim2.new(0, 150, 1, 0)
    TabsContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabsContainer.ScrollingDirection = Enum.ScrollingDirection.Y
    TabsContainer.ScrollBarThickness = 4
    TabsContainer.ScrollBarImageColor3 = PALETTES[self.CurrentTheme]["Primary"]
    TabsContainer.Parent = ContentFrame

    local TabsLayout = Instance.new("UIListLayout")
    TabsLayout.Padding = UDim.new(0, 0)
    TabsLayout.FillDirection = Enum.FillDirection.Vertical
    TabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabsLayout.Parent = TabsContainer

    local PagesContainer = Instance.new("Frame")
    PagesContainer.Name = "PagesContainer"
    PagesContainer.BackgroundTransparency = 1
    PagesContainer.BorderSizePixel = 0
    PagesContainer.Size = UDim2.new(1, -150, 1, 0)
    PagesContainer.Position = UDim2.new(0, 150, 0, 0)
    PagesContainer.Parent = ContentFrame

    MakeDraggable(TitleBar, DropShadowHolder)

    -- ╔═══════════════════════════════════════════════════════════════╗
    -- ║  SISTEMA DE TEMAS                                            ║
    -- ╚═══════════════════════════════════════════════════════════════╝

    function Tabs:SetTheme(themeName)
        if not PALETTES[themeName] then return end
        self.CurrentTheme = themeName
        SaveTheme(themeName)

        local palette = PALETTES[themeName]
        
        WindowFrame.BackgroundColor3 = palette["Surface"]
        TitleBar.BackgroundColor3 = palette["Tertiary"]
        TitleText.TextColor3 = palette["Text"]
        TabsContainer.BackgroundColor3 = palette["Tertiary"]
        TabsContainer.ScrollBarImageColor3 = palette["Primary"]

        for _, tabButton in pairs(TabsContainer:GetChildren()) do
            if tabButton:IsA("TextButton") then
                tabButton.BackgroundColor3 = palette["Tertiary"]
                tabButton.TextColor3 = palette["Text"]
            end
        end

        for _, page in pairs(PagesContainer:GetChildren()) do
            if page:IsA("ScrollingFrame") then
                page.BackgroundColor3 = palette["Surface"]
                for _, element in pairs(page:GetDescendants()) do
                    if element:IsA("Frame") or element:IsA("TextButton") then
                        element.BackgroundColor3 = palette["Tertiary"]
                    elseif element:IsA("TextLabel") then
                        element.TextColor3 = palette["Text"]
                    end
                end
            end
        end
    end

    function Tabs:SetAccentColor(color)
        TabsContainer.ScrollBarImageColor3 = color
    end

    function Tabs:SetTransparency(transparency)
        WindowFrame.BackgroundTransparency = transparency
        TitleBar.BackgroundTransparency = transparency
        TabsContainer.BackgroundTransparency = transparency
    end

    -- ╔═══════════════════════════════════════════════════════════════╗
    -- ║  CRIAR ABAS                                                  ║
    -- ╚═══════════════════════════════════════════════════════════════╝

    function Tabs:AddTab(tabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = tabName
        TabButton.BackgroundColor3 = PALETTES[self.CurrentTheme]["Tertiary"]
        TabButton.BorderSizePixel = 0
        TabButton.Size = UDim2.new(1, 0, 0, 40)
        TabButton.TextColor3 = PALETTES[self.CurrentTheme]["Text"]
        TabButton.TextSize = 14
        TabButton.Font = Enum.Font.Gotham
        TabButton.Text = tabName
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabsContainer

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 8)
        TabCorner.Parent = TabButton

        local PageFrame = Instance.new("ScrollingFrame")
        PageFrame.Name = tabName
        PageFrame.BackgroundColor3 = PALETTES[self.CurrentTheme]["Surface"]
        PageFrame.BorderSizePixel = 0
        PageFrame.Size = UDim2.new(1, 0, 1, 0)
        PageFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
        PageFrame.ScrollingDirection = Enum.ScrollingDirection.Y
        PageFrame.ScrollBarThickness = 4
        PageFrame.ScrollBarImageColor3 = PALETTES[self.CurrentTheme]["Primary"]
        PageFrame.Visible = false
        PageFrame.Parent = PagesContainer

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.FillDirection = Enum.FillDirection.Vertical
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = PageFrame

        TabButton.MouseButton1Click:Connect(function()
            for _, page in pairs(PagesContainer:GetChildren()) do
                if page:IsA("ScrollingFrame") then
                    page.Visible = false
                end
            end
            PageFrame.Visible = true

            for _, btn in pairs(TabsContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    btn.BackgroundColor3 = PALETTES[self.CurrentTheme]["Tertiary"]
                end
            end
            TabButton.BackgroundColor3 = PALETTES[self.CurrentTheme]["Primary"]
        end)

        if #TabPages == 0 then
            PageFrame.Visible = true
            TabButton.BackgroundColor3 = PALETTES[self.CurrentTheme]["Primary"]
        end

        TabPages[tabName] = {
            Frame = PageFrame,
            Button = TabButton,
            Layout = PageLayout
        }

        local Tab = {}

        -- ╔═══════════════════════════════════════════════════════════════╗
        -- ║  ADICIONAR ELEMENTOS À ABA                                   ║
        -- ╚═══════════════════════════════════════════════════════════════╝

        function Tab:AddToggle(elementName, callback)
            local toggleContainer = Instance.new("Frame")
            toggleContainer.Name = elementName
            toggleContainer.BackgroundColor3 = PALETTES[self.CurrentTheme]["Tertiary"]
            toggleContainer.BorderSizePixel = 0
            toggleContainer.Size = UDim2.new(1, -16, 0, 40)
            toggleContainer.Parent = PageFrame

            local toggleCorner = Instance.new("UICorner")
            toggleCorner.CornerRadius = UDim.new(0, 6)
            toggleCorner.Parent = toggleContainer

            local toggleLabel = Instance.new("TextLabel")
            toggleLabel.BackgroundTransparency = 1
            toggleLabel.Size = UDim2.new(1, -60, 1, 0)
            toggleLabel.TextColor3 = PALETTES[self.CurrentTheme]["Text"]
            toggleLabel.TextSize = 13
            toggleLabel.Font = Enum.Font.Gotham
            toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            toggleLabel.Text = elementName
            toggleLabel.Parent = toggleContainer

            local toggleButton = Instance.new("TextButton")
            toggleButton.Name = "Toggle"
            toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            toggleButton.BorderSizePixel = 0
            toggleButton.Size = UDim2.new(0, 50, 0, 24)
            toggleButton.Position = UDim2.new(1, -60, 0.5, -12)
            toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            toggleButton.TextSize = 12
            toggleButton.Font = Enum.Font.GothamBold
            toggleButton.Text = "OFF"
            toggleButton.AutoButtonColor = false
            toggleButton.Parent = toggleContainer

            local toggleCornerBtn = Instance.new("UICorner")
            toggleCornerBtn.CornerRadius = UDim.new(0, 4)
            toggleCornerBtn.Parent = toggleButton

            local toggleState = false

            local function UpdateToggle(newState)
                toggleState = newState
                if toggleState then
                    toggleButton.BackgroundColor3 = PALETTES[self.CurrentTheme]["Primary"]
                    toggleButton.Text = "ON"
                else
                    toggleButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
                    toggleButton.Text = "OFF"
                end
                if callback then callback(toggleState) end
            end

            toggleButton.MouseButton1Click:Connect(function()
                UpdateToggle(not toggleState)
            end)

            local element = {}
            function element:Set(state, fromConfig)
                UpdateToggle(state)
            end
            function element:Get()
                return toggleState
            end

            Elements[elementName] = element

            return element
        end

        function Tab:AddButton(buttonName, callback)
            local buttonContainer = Instance.new("TextButton")
            buttonContainer.Name = buttonName
            buttonContainer.BackgroundColor3 = PALETTES[self.CurrentTheme]["Tertiary"]
            buttonContainer.BorderSizePixel = 0
            buttonContainer.Size = UDim2.new(1, -16, 0, 40)
            buttonContainer.TextColor3 = PALETTES[self.CurrentTheme]["Text"]
            buttonContainer.TextSize = 13
            buttonContainer.Font = Enum.Font.GothamBold
            buttonContainer.Text = buttonName
            buttonContainer.AutoButtonColor = false
            buttonContainer.Parent = PageFrame

            local buttonCorner = Instance.new("UICorner")
            buttonCorner.CornerRadius = UDim.new(0, 6)
            buttonCorner.Parent = buttonContainer

            buttonContainer.MouseButton1Click:Connect(function()
                CircleClick(buttonContainer, Mouse.X, Mouse.Y)
                if callback then callback() end
            end)

            return buttonContainer
        end

        function Tab:AddColorPicker(elementName, defaultColor, callback)
            local colorContainer = Instance.new("Frame")
            colorContainer.Name = elementName
            colorContainer.BackgroundColor3 = PALETTES[self.CurrentTheme]["Tertiary"]
            colorContainer.BorderSizePixel = 0
            colorContainer.Size = UDim2.new(1, -16, 0, 40)
            colorContainer.Parent = PageFrame

            local colorCorner = Instance.new("UICorner")
            colorCorner.CornerRadius = UDim.new(0, 6)
            colorCorner.Parent = colorContainer

            local colorLabel = Instance.new("TextLabel")
            colorLabel.BackgroundTransparency = 1
            colorLabel.Size = UDim2.new(1, -80, 1, 0)
            colorLabel.TextColor3 = PALETTES[self.CurrentTheme]["Text"]
            colorLabel.TextSize = 13
            colorLabel.Font = Enum.Font.Gotham
            colorLabel.TextXAlignment = Enum.TextXAlignment.Left
            colorLabel.Text = elementName
            colorLabel.Parent = colorContainer

            local colorPreview = Instance.new("Frame")
            colorPreview.Name = "ColorPreview"
            colorPreview.BackgroundColor3 = defaultColor
            colorPreview.BorderSizePixel = 0
            colorPreview.Size = UDim2.new(0, 30, 0, 24)
            colorPreview.Position = UDim2.new(1, -70, 0.5, -12)
            colorPreview.Parent = colorContainer

            local previewCorner = Instance.new("UICorner")
            previewCorner.CornerRadius = UDim.new(0, 4)
            previewCorner.Parent = colorPreview

            local colorPickerFrame = Instance.new("Frame")
            colorPickerFrame.Name = "ColorPickerFrame"
            colorPickerFrame.BackgroundColor3 = PALETTES[self.CurrentTheme]["Tertiary"]
            colorPickerFrame.BorderSizePixel = 0
            colorPickerFrame.Size = UDim2.new(0, 120, 0, 160)
            colorPickerFrame.Position = UDim2.new(1, -130, 1, 5)
            colorPickerFrame.Visible = false
            colorPickerFrame.ZIndex = 999
            colorPickerFrame.Parent = colorContainer

            local pickerCorner = Instance.new("UICorner")
            pickerCorner.CornerRadius = UDim.new(0, 6)
            pickerCorner.Parent = colorPickerFrame

            -- Cores disponíveis (padrão)
            local colors = {
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(255, 0, 0),
                Color3.fromRGB(0, 255, 0),
                Color3.fromRGB(0, 0, 255),
                Color3.fromRGB(255, 255, 0),
                Color3.fromRGB(255, 0, 255),
            }

            local colorLayout = Instance.new("UIGridLayout")
            colorLayout.CellSize = UDim2.new(0, 30, 0, 30)
            colorLayout.CellPadding = UDim2.new(0, 5, 0, 5)
            colorLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            colorLayout.VerticalAlignment = Enum.VerticalAlignment.Top
            colorLayout.SortOrder = Enum.SortOrder.LayoutOrder
            colorLayout.Parent = colorPickerFrame

            local currentColor = defaultColor

            for _, color in pairs(colors) do
                local colorButton = Instance.new("TextButton")
                colorButton.BackgroundColor3 = color
                colorButton.BorderSizePixel = 0
                colorButton.Size = UDim2.new(0, 30, 0, 30)
                colorButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                colorButton.TextSize = 0
                colorButton.AutoButtonColor = false
                colorButton.Parent = colorPickerFrame

                local colorButtonCorner = Instance.new("UICorner")
                colorButtonCorner.CornerRadius = UDim.new(0, 4)
                colorButtonCorner.Parent = colorButton

                colorButton.MouseButton1Click:Connect(function()
                    currentColor = color
                    colorPreview.BackgroundColor3 = color
                    colorPickerFrame.Visible = false
                    if callback then callback(color) end
                end)
            end

            local openPickerButton = Instance.new("TextButton")
            openPickerButton.Name = "OpenPicker"
            openPickerButton.BackgroundTransparency = 1
            openPickerButton.Size = UDim2.new(0, 30, 1, 0)
            openPickerButton.Position = UDim2.new(1, -70, 0, 0)
            openPickerButton.TextSize = 0
            openPickerButton.AutoButtonColor = false
            openPickerButton.Parent = colorContainer

            openPickerButton.MouseButton1Click:Connect(function()
                colorPickerFrame.Visible = not colorPickerFrame.Visible
            end)

            -- Fechar picker ao clicar fora
            local UserInputService = game:GetService("UserInputService")
            UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if colorPickerFrame.Visible and input.UserInputType == Enum.UserInputType.MouseButton1 then
                    local mousePos = Mouse.X, Mouse.Y
                    local pickerPos = colorPickerFrame.AbsolutePosition
                    local pickerSize = colorPickerFrame.AbsoluteSize
                    
                    if not (Mouse.X >= pickerPos.X and Mouse.X <= pickerPos.X + pickerSize.X and
                            Mouse.Y >= pickerPos.Y and Mouse.Y <= pickerPos.Y + pickerSize.Y) then
                        colorPickerFrame.Visible = false
                    end
                end
            end)

            local element = {}
            function element:Set(color, fromConfig)
                colorPreview.BackgroundColor3 = color
                currentColor = color
            end
            function element:Get()
                return currentColor
            end

            Elements[elementName] = element

            return element
        end

        function Tab:AddLabel(labelText)
            local label = Instance.new("TextLabel")
            label.Name = "Label"
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, -16, 0, 30)
            label.TextColor3 = PALETTES[self.CurrentTheme]["Text"]
            label.TextSize = 13
            label.Font = Enum.Font.Gotham
            label.TextWrapped = true
            label.Text = labelText
            label.Parent = PageFrame

            return label
        end

        function Tab:AddSlider(elementName, min, max, defaultValue, callback)
            local sliderContainer = Instance.new("Frame")
            sliderContainer.Name = elementName
            sliderContainer.BackgroundColor3 = PALETTES[self.CurrentTheme]["Tertiary"]
            sliderContainer.BorderSizePixel = 0
            sliderContainer.Size = UDim2.new(1, -16, 0, 50)
            sliderContainer.Parent = PageFrame

            local sliderCorner = Instance.new("UICorner")
            sliderCorner.CornerRadius = UDim.new(0, 6)
            sliderCorner.Parent = sliderContainer

            local sliderLabel = Instance.new("TextLabel")
            sliderLabel.BackgroundTransparency = 1
            sliderLabel.Size = UDim2.new(1, -16, 0, 20)
            sliderLabel.Position = UDim2.new(0, 8, 0, 5)
            sliderLabel.TextColor3 = PALETTES[self.CurrentTheme]["Text"]
            sliderLabel.TextSize = 13
            sliderLabel.Font = Enum.Font.Gotham
            sliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            sliderLabel.Text = elementName .. ": " .. math.round(defaultValue)
            sliderLabel.Parent = sliderContainer

            local sliderBackground = Instance.new("Frame")
            sliderBackground.Name = "SliderBackground"
            sliderBackground.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            sliderBackground.BorderSizePixel = 0
            sliderBackground.Size = UDim2.new(1, -16, 0, 6)
            sliderBackground.Position = UDim2.new(0, 8, 1, -20)
            sliderBackground.Parent = sliderContainer

            local sliderBackgroundCorner = Instance.new("UICorner")
            sliderBackgroundCorner.CornerRadius = UDim.new(0, 3)
            sliderBackgroundCorner.Parent = sliderBackground

            local sliderBar = Instance.new("Frame")
            sliderBar.Name = "SliderBar"
            sliderBar.BackgroundColor3 = PALETTES[self.CurrentTheme]["Primary"]
            sliderBar.BorderSizePixel = 0
            sliderBar.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
            sliderBar.Parent = sliderBackground

            local sliderBarCorner = Instance.new("UICorner")
            sliderBarCorner.CornerRadius = UDim.new(0, 3)
            sliderBarCorner.Parent = sliderBar

            local currentValue = defaultValue

            sliderBackground.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local pos = input.Position.X - sliderBackground.AbsolutePosition.X
                    local percent = math.clamp(pos / sliderBackground.AbsoluteSize.X, 0, 1)
                    currentValue = math.floor(min + (max - min) * percent)
                    
                    sliderBar.Size = UDim2.new(percent, 0, 1, 0)
                    sliderLabel.Text = elementName .. ": " .. currentValue
                    
                    if callback then callback(currentValue) end
                end
            end)

            local element = {}
            function element:Set(value, fromConfig)
                currentValue = math.clamp(value, min, max)
                sliderBar.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
                sliderLabel.Text = elementName .. ": " .. currentValue
            end
            function element:Get()
                return currentValue
            end

            Elements[elementName] = element

            return element
        end

        return Tab
    end

    function Tabs:LibSettings(config)
        config = config or {}
        if config.Theme        then self:SetTheme(config.Theme) end
        if config.AccentColor  then self:SetAccentColor(config.AccentColor) end
        if config.Transparency then self:SetTransparency(config.Transparency) end
        if config.ToggleKey    then HotKeys.Toggle = config.ToggleKey end
        if config.CloseKey     then HotKeys.Close  = config.CloseKey end
    end

    return Tabs
end

-- ╔══════════════════════════════════════════════════════════════╗
-- ║  BOTÃO FLUTUANTE — cópia fiel do FloatBtn do Nexus UI        ║
-- ║  • Arredondado  • Pulsativo  • Drag  • Toggle correto        ║
-- ╚══════════════════════════════════════════════════════════════╝

local function _RC(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = p; return c
end

local function _SK(p, col, th2, tr)
    local s = Instance.new("UIStroke")
    s.Color = col or Color3.fromRGB(40,40,40)
    s.Thickness = th2 or 1
    s.Transparency = tr or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end

local function _AnimT(inst, props, ti)
    local t = TweenService:Create(inst, ti or TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    t:Play(); return t
end

function BastardXHub:FloatBtn(FloatConfig)
    FloatConfig          = FloatConfig or {}
    local iconNameOrId   = FloatConfig.Icon     or "rbxassetid://112738695202091"
    local accentColor    = FloatConfig.Color    or Color3.fromRGB(255, 255, 255)
    local accentDark     = FloatConfig.ColorDark or Color3.fromRGB(180, 180, 180)
    local surfaceB       = Color3.fromRGB(18, 18, 18)
    local S              = FloatConfig.Size or 46

    local sg = Instance.new("ScreenGui")
    sg.Name           = "BastardFloatBtn"
    sg.ResetOnSpawn   = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder   = 9999
    sg.IgnoreGuiInset = true
    sg.Parent         = game:GetService("CoreGui")

    local ring = Instance.new("Frame")
    ring.Name                   = "_Ring"
    ring.BackgroundColor3       = accentColor
    ring.BackgroundTransparency = 0.55
    ring.BorderSizePixel        = 0
    ring.AnchorPoint            = Vector2.new(0.5, 0.5)
    ring.Position               = UDim2.new(0.05, 0, 0.5, 0)
    ring.Size                   = UDim2.fromOffset(S + 14, S + 14)
    ring.ZIndex                 = 298
    ring.Parent                 = sg
    local ringCorner = Instance.new("UICorner")
    ringCorner.CornerRadius = UDim.new(0, 10)
    ringCorner.Parent = ring

    local fb = Instance.new("ImageButton")
    fb.Name                 = "_FloatBtn"
    fb.AnchorPoint          = Vector2.new(0.5, 0.5)
    fb.Position             = UDim2.new(0.05, 0, 0.5, 0)
    fb.Size                 = UDim2.fromOffset(S, S)
    fb.BackgroundColor3     = accentDark
    fb.BackgroundTransparency = 0
    fb.BorderSizePixel      = 0
    fb.AutoButtonColor      = false
    fb.Image                = ""
    fb.ImageColor3          = Color3.new(1, 1, 1)
    fb.ScaleType            = Enum.ScaleType.Fit
    fb.ZIndex               = 300
    fb.Parent               = sg
    _RC(fb, 10)
    local fbStroke = _SK(fb, accentColor, 1.5, 0)

    local fbPad = Instance.new("UIPadding")
    fbPad.PaddingTop    = UDim.new(0, 9)
    fbPad.PaddingBottom = UDim.new(0, 9)
    fbPad.PaddingLeft   = UDim.new(0, 9)
    fbPad.PaddingRight  = UDim.new(0, 9)
    fbPad.Parent = fb

    local function ApplyIcon(v)
        v = tostring(v or "")
        if v:match("^rbxassetid://") then
            fb.Image = v
        elseif v:match("^%d+$") then
            fb.Image = "rbxassetid://" .. v
        elseif Icons and Icons[v] then
            fb.Image = Icons[v]
        else
            task.spawn(function()
                local ok, res = pcall(function()
                    return loadstring(game:HttpGet(
                        "https://raw.githubusercontent.com/NexorHub/Teste/refs/heads/main/Icons.lua"
                    ))()
                end)
                if ok and res and res[v] and fb and fb.Parent then
                    Icons = res
                    fb.Image = res[v]
                end
            end)
        end
    end
    ApplyIcon(iconNameOrId)

    local toggled = true
    task.spawn(function()
        while ring and ring.Parent do
            _AnimT(ring,
                { BackgroundTransparency = 0.85, Size = UDim2.fromOffset(S + 26, S + 26) },
                TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(1.2)
            _AnimT(ring,
                { BackgroundTransparency = 0.40, Size = UDim2.fromOffset(S + 8, S + 8) },
                TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(1.2)
        end
    end)

    local drag, ds, sp, moved = false, nil, nil, false
    fb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = fb.Position; moved = false
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            if d.Magnitude > 4 then moved = true end
            local np = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                 sp.Y.Scale, sp.Y.Offset + d.Y)
            fb.Position   = np
            ring.Position = np
        end
    end)

    fb.MouseButton1Click:Connect(function()
        if moved then return end
        toggled = not toggled

        _AnimT(fb, { BackgroundColor3 = toggled and accentDark or surfaceB },
            TweenInfo.new(0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))

        _AnimT(fb, { Size = UDim2.fromOffset(S - 4, S - 4) },
            TweenInfo.new(0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        task.delay(0.10, function()
            _AnimT(fb, { Size = UDim2.fromOffset(S, S) },
                TweenInfo.new(0.46, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
        end)

        if FloatConfig.MainHolder then
            FloatConfig.MainHolder.Visible = toggled
        end
        if FloatConfig.Callback then
            task.spawn(FloatConfig.Callback, toggled)
        end
    end)

    local FloatFunc = {}

    function FloatFunc:SetIcon(v) ApplyIcon(v) end

    function FloatFunc:SetColor(col, colDark)
        accentColor = col; accentDark = colDark or col
        _AnimT(fbStroke, { Color = col }, TweenInfo.new(0.3))
        _AnimT(ring, { BackgroundColor3 = col }, TweenInfo.new(0.3))
        if toggled then
            _AnimT(fb, { BackgroundColor3 = accentDark }, TweenInfo.new(0.3))
        end
    end

    function FloatFunc:Destroy()
        sg:Destroy()
    end

    return FloatFunc
end

return BastardXHub
