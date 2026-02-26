--[[
╔══════════════════════════════════════════════════════════════╗
║  NexusUI  ·  v3.1.0  ·  Professional Roblox GUI Library     ║
║  Theme    : Neon Cyan / Deep Black                           ║
║  Tabs     : Horizontal top bar  (Rayfield style)             ║
║  Fix v3.1 : Dropdown overlay  ·  Layout  ·  Section divider ║
╚══════════════════════════════════════════════════════════════╝

  QUICK START:
    local NexusUI = loadstring(game:HttpGet("YOUR_URL"))()
    NexusUI:SetToggleIcon("rbxassetid://104112878732002")
    local Win = NexusUI:CreateWindow({ Title = "Hub", Icon = "bolt" })
    local Tab = Win:CreateTab({ Name = "Farm", Icon = "axe" })
    local Sec = Tab:CreateSection("Auto Farm")
    Sec:CreateButton({ Name = "Start", Callback = function() end })
    Sec:CreateToggle({ Name = "AutoFarm", Default = false, Callback = function(v) end })
    Sec:CreateSlider({ Name = "Speed", Min=0, Max=200, Default=16, Callback=function(v) end })
    Sec:CreateDropdown({ Name = "Mob", Options={"Boss","Mob1"}, Callback=function(v) end })
    Win:Notify({ Title="Ready", Content="Loaded!", Type="Success" })
]]

-- ═══════════════════════════════════════════════════════════════
--  SERVICES
-- ═══════════════════════════════════════════════════════════════
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")

-- ═══════════════════════════════════════════════════════════════
--  SCREEN ADAPTER
-- ═══════════════════════════════════════════════════════════════
local SA = {}
do
    local Camera = workspace.CurrentCamera
    function SA:Refresh()
        local vp     = Camera.ViewportSize
        self.Compact = vp.X < 1280 or vp.Y < 720
        self.Pad     = self.Compact and 8  or 10
        self.BtnH    = self.Compact and 34 or 38
        self.FS      = self.Compact and 13 or 14
        self.Rad     = 8
        self.WinW    = self.Compact and 460 or 500
        self.WinH    = self.Compact and 280 or 310
    end
    SA:Refresh()
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() SA:Refresh() end)
end

-- ═══════════════════════════════════════════════════════════════
--  SAFE NAME HELPER
--  Instance names with unicode/emoji crash some Roblox executors.
--  Uses a monotonic counter — keeps names unique and ASCII-safe.
-- ═══════════════════════════════════════════════════════════════
local _N = 0
local function SafeName(prefix)
    _N = _N + 1
    return prefix .. tostring(_N)
end

-- ═══════════════════════════════════════════════════════════════
--  THEME
-- ═══════════════════════════════════════════════════════════════
local TH = {
    Bg         = Color3.fromHex("080808"),
    BgAlt      = Color3.fromHex("0C0C0C"),
    Surface    = Color3.fromHex("111111"),
    SurfaceB   = Color3.fromHex("181818"),
    Border     = Color3.fromHex("202020"),
    BorderH    = Color3.fromHex("2C2C2C"),
    Cyan       = Color3.fromHex("00FFFF"),
    CyanD      = Color3.fromHex("00AAAA"),
    CyanS      = Color3.fromHex("00CCCC"),
    T1         = Color3.fromHex("EEEEEE"),
    T2         = Color3.fromHex("777777"),
    T3         = Color3.fromHex("363636"),
    TAcc       = Color3.fromHex("00FFFF"),
    Ok         = Color3.fromHex("00EE77"),
    Warn       = Color3.fromHex("FFFFFF"),
    Err        = Color3.fromHex("FF4455"),
    Info       = Color3.fromHex("00CCFF"),
    FB         = Enum.Font.GothamBold,
    FR         = Enum.Font.Gotham,
    FM         = Enum.Font.Code,
    Fast       = TweenInfo.new(0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Med        = TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
    Elastic    = TweenInfo.new(0.46, Enum.EasingStyle.Back,  Enum.EasingDirection.Out),
    Sine       = TweenInfo.new(1.40, Enum.EasingStyle.Sine,  Enum.EasingDirection.InOut),
}

-- ═══════════════════════════════════════════════════════════════
--  ACCENT PALETTES  (Cyan=padrão | Red | Purple=Gojo)
-- ═══════════════════════════════════════════════════════════════
local PALETTES = {
    Cyan = {
        Cyan  = Color3.fromHex("00FFFF"),
        CyanD = Color3.fromHex("00AAAA"),
        CyanS = Color3.fromHex("00CCCC"),
        TAcc  = Color3.fromHex("00FFFF"),
        Info  = Color3.fromHex("00CCFF"),
    },
    Red = {
        Cyan  = Color3.fromHex("FF3333"),
        CyanD = Color3.fromHex("BB1111"),
        CyanS = Color3.fromHex("DD2222"),
        TAcc  = Color3.fromHex("FF3333"),
        Info  = Color3.fromHex("FF6655"),
    },
    Purple = {  -- Satoru Gojo
        Cyan  = Color3.fromHex("9B59FF"),
        CyanD = Color3.fromHex("6633CC"),
        CyanS = Color3.fromHex("7F44EE"),
        TAcc  = Color3.fromHex("9B59FF"),
        Info  = Color3.fromHex("BB88FF"),
    },
}

-- ── Registro global de elementos com cor de acento ──────────────
-- Suporta dois modos:
--   Simples : { inst, prop, key }  → sempre aplica pal[key]
--   Callback: { fn }               → fn(pal) decide o que fazer (para elementos condicionais como ícone de tab ativa/inativa)
local _AC = {}
local _currentPalName = "Cyan"

local function RegAC(inst, prop, key)
    if not inst or not prop or not key then return end
    table.insert(_AC, {inst=inst, prop=prop, key=key})
end
local function RegACFn(fn)
    if fn then table.insert(_AC, {fn=fn}) end
end

-- ── Persistência de tema ─────────────────────────────────────────
local THEME_FILE = "NexusUI_theme.txt"
local function SaveTheme(name)
    pcall(function() writefile(THEME_FILE, name) end)
end
local function LoadTheme()
    local ok, data = pcall(function() return readfile(THEME_FILE) end)
    if ok and data and PALETTES[data] then return data end
    return "Cyan"
end

-- Aplica nova paleta em tempo real com tween suave
local function ApplyAccent(palName, noSave)
    local pal = PALETTES[palName] or PALETTES.Cyan
    _currentPalName = palName
    -- Salva automaticamente (a menos que seja carga inicial)
    if not noSave then SaveTheme(palName) end
    -- Atualiza TH primeiro (afeta logica de toggles/sliders futuros)
    for k,v in pairs(pal) do TH[k]=v end
    -- Anima todos os elementos registrados
    for _, e in ipairs(_AC) do
        if e.fn then
            -- callback condicional
            pcall(e.fn, pal)
        else
            local ok, inst = pcall(function() return e.inst end)
            if ok and inst and inst.Parent then
                local newCol = pal[e.key]
                if newCol then
                    local props = {}; props[e.prop] = newCol
                    TweenService:Create(inst, TH.Med, props):Play()
                end
            end
        end
    end
end

-- Carrega tema salvo na inicialização (noSave=true para não re-salvar)
local _savedTheme = LoadTheme()
if _savedTheme ~= "Cyan" then
    -- aplica após TH estar pronto, sem tween (sem TweenService ainda disponível aqui;
    -- será aplicado logo após o Anim ser definido, via flag)
    _currentPalName = _savedTheme
    for k,v in pairs(PALETTES[_savedTheme]) do TH[k]=v end
end
local Anim = {}
function Anim.T(i, p, ti)
    local t = TweenService:Create(i, ti or TH.Med, p); t:Play(); return t
end
function Anim.Ripple(parent, px, py)
    local r = Instance.new("Frame")
    r.AnchorPoint = Vector2.new(0.5,0.5)
    r.BackgroundColor3 = TH.Cyan; r.BackgroundTransparency = 0.76
    r.BorderSizePixel = 0
    r.Position = UDim2.fromOffset(px,py); r.Size = UDim2.fromOffset(0,0)
    r.ZIndex = parent.ZIndex + 50
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(1); c.Parent = r
    r.Parent = parent
    local mx = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2.8
    local t = TweenService:Create(r, TweenInfo.new(0.5, Enum.EasingStyle.Quint),
        {Size=UDim2.fromOffset(mx,mx), BackgroundTransparency=1})
    t:Play(); t.Completed:Connect(function() r:Destroy() end)
end

-- ═══════════════════════════════════════════════════════════════
--  ICON MANAGER
-- ═══════════════════════════════════════════════════════════════
local Icons = {}
Icons._cache = nil; Icons._ready = false; Icons._queue = {}
Icons.URL = "https://raw.githubusercontent.com/hid1ey/EthuX-xyz/refs/heads/main/Lib/Icons.lua"

task.spawn(function()
    local ok, res = pcall(function()
        return loadstring(game:HttpGet(Icons.URL, true))()
    end)
    Icons._cache = (ok and type(res)=="table") and res or {}
    Icons._ready = true
    if not ok then warn("[NexusUI] Icons: "..tostring(res)) end
    for _, cb in ipairs(Icons._queue) do pcall(cb) end
    Icons._queue = {}
end)

function Icons.Get(v)
    if not v then return "" end
    if type(v)=="number" then return "rbxassetid://"..v end
    if type(v)=="string" then
        if v:match("^rbxassetid://") or v:match("^%d+$") then return v end
        if Icons._ready and Icons._cache then
            local r = Icons._cache[v]
            if r then return type(r)=="number" and "rbxassetid://"..r or r end
        end
    end
    return ""
end

function Icons.Apply(name, inst)
    if not name or not inst then return end
    if type(name)=="string" and (name:match("^rbxassetid://") or name:match("^%d+$")) then
        inst.Image = name; return
    end
    if type(name)=="number" then inst.Image = "rbxassetid://"..name; return end
    if Icons._ready then
        inst.Image = Icons.Get(name)
    else
        table.insert(Icons._queue, function()
            if inst and inst.Parent then inst.Image = Icons.Get(name) end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════
--  BUILD UTILITIES
-- ═══════════════════════════════════════════════════════════════
local function RC(p,r)
    local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or SA.Rad); c.Parent=p; return c
end
local function SK(p,col,th2,tr)
    local s=Instance.new("UIStroke"); s.Color=col or TH.Border
    s.Thickness=th2 or 1; s.Transparency=tr or 0
    s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Parent=p; return s
end
local function PD(p,t,b,l,r)
    local u=Instance.new("UIPadding")
    u.PaddingTop=UDim.new(0,t or SA.Pad); u.PaddingBottom=UDim.new(0,b or SA.Pad)
    u.PaddingLeft=UDim.new(0,l or SA.Pad); u.PaddingRight=UDim.new(0,r or SA.Pad)
    u.Parent=p; return u
end
local function LH(p,gap,ha,va)
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Horizontal
    l.Padding=UDim.new(0,gap or 6); l.HorizontalAlignment=ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment=va or Enum.VerticalAlignment.Center
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=p; return l
end
local function LV(p,gap)
    local l=Instance.new("UIListLayout"); l.FillDirection=Enum.FillDirection.Vertical
    l.Padding=UDim.new(0,gap or 6); l.HorizontalAlignment=Enum.HorizontalAlignment.Left
    l.VerticalAlignment=Enum.VerticalAlignment.Top
    l.SortOrder=Enum.SortOrder.LayoutOrder; l.Parent=p; return l
end
local function Fr(bg,bt,name,z)
    local f=Instance.new("Frame"); f.BackgroundColor3=bg or TH.Surface
    f.BackgroundTransparency=bt or 0; f.BorderSizePixel=0
    f.Name=name or "Fr"; f.ZIndex=z or 1; return f
end
local function Lb(text,tc,fs,font,xa,z)
    local l=Instance.new("TextLabel"); l.BackgroundTransparency=1; l.BorderSizePixel=0
    l.Text=text or ""; l.TextColor3=tc or TH.T1; l.TextSize=fs or SA.FS
    l.Font=font or TH.FR; l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.TextYAlignment=Enum.TextYAlignment.Center; l.TextTruncate=Enum.TextTruncate.AtEnd
    l.ZIndex=z or 1; return l
end
local function IL(ic,z)
    local i=Instance.new("ImageLabel"); i.BackgroundTransparency=1; i.BorderSizePixel=0
    i.ImageColor3=ic or TH.T1; i.ScaleType=Enum.ScaleType.Fit; i.ZIndex=z or 1; return i
end
local function IB(ic,z)
    local b=Instance.new("ImageButton"); b.BackgroundColor3=TH.Surface
    b.BackgroundTransparency=0; b.BorderSizePixel=0; b.Image=""
    b.ImageColor3=ic or TH.T2; b.ScaleType=Enum.ScaleType.Fit
    b.AutoButtonColor=false; b.ZIndex=z or 1; return b
end
local function TB(bg,bt,z)
    local b=Instance.new("TextButton"); b.BackgroundColor3=bg or TH.Surface
    b.BackgroundTransparency=bt or 0; b.BorderSizePixel=0; b.Text=""
    b.AutoButtonColor=false; b.ClipsDescendants=true; b.ZIndex=z or 1; return b
end
local function SV(z)
    local s=Instance.new("ScrollingFrame"); s.BackgroundTransparency=1; s.BorderSizePixel=0
    s.CanvasSize=UDim2.fromScale(0,0); s.AutomaticCanvasSize=Enum.AutomaticSize.Y
    s.ScrollBarThickness=4; s.ScrollBarImageColor3=TH.Cyan
    s.ScrollingDirection=Enum.ScrollingDirection.Y; s.ZIndex=z or 1
    RegAC(s,"ScrollBarImageColor3","Cyan")
    return s
end
local function Shadow(parent)
    local s=Instance.new("ImageLabel"); s.Name="_Shadow"
    s.BackgroundTransparency=1; s.AnchorPoint=Vector2.new(0.5,0.5)
    s.Position=UDim2.new(0.5,0,0.5,7); s.Size=UDim2.new(1,32,1,32)
    s.Image="rbxassetid://6014261993"; s.ImageColor3=TH.Cyan
    s.ImageTransparency=0.82; s.ScaleType=Enum.ScaleType.Slice
    s.SliceCenter=Rect.new(49,49,450,450); s.ZIndex=parent.ZIndex-1
    s.Parent=parent; return s
end

-- ═══════════════════════════════════════════════════════════════
--  DROPDOWN OVERLAY LAYER
--  All dropdown panels live here so z-index / ClipsDescendants
--  on scroll frames never clip them.
-- ═══════════════════════════════════════════════════════════════
local _OV = nil          -- set by Library:_Init() to the ScreenGui
local _DD = nil          -- currently open {panel, onClose}

local function CloseDD()
    if not _DD then return end
    local d = _DD; _DD = nil
    local w = d.panel.AbsoluteSize.X
    Anim.T(d.panel, {Size=UDim2.fromOffset(w,0)}, TH.Fast)
    task.delay(0.12, function()
        if d.panel and d.panel.Parent then d.panel.Visible = false end
        if d.onClose then d.onClose() end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  NOTIFICATION SYSTEM
--  Usa StarterGui:SetCore("SendNotification") — notificacao nativa Roblox
--  Suporta: Title, Content, Duration, Icon (rbxassetid:// ou numero)
-- ═══════════════════════════════════════════════════════════════
local Notif = {}
local StarterGui = game:GetService("StarterGui")

function Notif.Init(_sg) end  -- mantido por compatibilidade

function Notif.Send(o)
    o = o or {}
    -- Guard: StarterGui:SetCore não está disponível em alguns contextos (LocalScript não inited)
    if not pcall(function() return game:GetService("StarterGui") end) then return end
    local iconId = o.Icon
    -- Resolve nome do icone (ex: "shield-check", "bell") via repositorio Icons
    -- tambem aceita numero direto ou string "rbxassetid://..."
    if type(iconId) == "number" then
        iconId = "rbxassetid://" .. tostring(iconId)
    elseif type(iconId) == "string" then
        if iconId:match("^%d+$") then
            iconId = "rbxassetid://" .. iconId
        elseif not iconId:match("^rbxassetid://") then
            -- e um nome de icone: resolve via Icons.Get (igual as tabs/botoes)
            local resolved = Icons.Get(iconId)
            iconId = (resolved ~= "") and resolved or nil
        end
    end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = o.Title    or "NexusUI",
            Text     = o.Content  or "",
            Duration = o.Duration or 5,
            Icon     = iconId,
        })
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  DRAG MIXIN
-- ═══════════════════════════════════════════════════════════════
local function MakeDraggable(win,handle)
    local drag,ds,sp=false,nil,nil
    handle.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            drag=true; ds=i.Position; sp=win.Position
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-ds
            win.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════
--  COMPONENT FACTORY
-- ═══════════════════════════════════════════════════════════════
local CF={}

-- ─── BUTTON ────────────────────────────────────────────────────
function CF.Button(o,parent,z)
    o=o or{}; z=z or 5
    local wrap=Fr(TH.Surface,0,SafeName("Btn"),z)
    wrap.Size=UDim2.new(1,0,0,SA.BtnH); wrap.ClipsDescendants=true; wrap.Parent=parent
    RC(wrap); local sk=SK(wrap,TH.Border,1,0)
    local row=Fr(TH.Bg,1,"_R",z+1); row.Size=UDim2.fromScale(1,1); row.Parent=wrap
    LH(row,8,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center); PD(row,0,0,12,12)
    if o.Icon then
        local ic=IL(TH.T2,z+2); ic.Size=UDim2.fromOffset(15,15); ic.Parent=row; Icons.Apply(o.Icon,ic)
    end
    local lb=Lb(o.Name or"Button",TH.T1,SA.FS,TH.FR,Enum.TextXAlignment.Left,z+2)
    lb.Size=UDim2.new(1,-(o.Icon and 38 or 8),1,0); lb.Parent=row
    local hit=TB(TH.Bg,1,z+10); hit.Size=UDim2.fromScale(1,1); hit.Parent=wrap
    hit.MouseEnter:Connect(function() Anim.T(wrap,{BackgroundColor3=TH.SurfaceB},TH.Fast); Anim.T(sk,{Color=TH.BorderH},TH.Fast) end)
    hit.MouseLeave:Connect(function() Anim.T(wrap,{BackgroundColor3=TH.Surface},TH.Fast); Anim.T(sk,{Color=TH.Border},TH.Fast) end)
    hit.MouseButton1Down:Connect(function() Anim.T(wrap,{BackgroundColor3=TH.CyanD},TH.Fast) end)
    hit.MouseButton1Up:Connect(function() Anim.T(wrap,{BackgroundColor3=TH.SurfaceB},TH.Fast) end)
    hit.MouseButton1Click:Connect(function()
        -- MouseButton1Click não passa coordenadas no Roblox — usa GetMouseLocation
        local mp = UserInputService:GetMouseLocation()
        Anim.Ripple(hit, mp.X - hit.AbsolutePosition.X, mp.Y - hit.AbsolutePosition.Y)
        Anim.T(sk,{Color=TH.Cyan,Transparency=0.4},TH.Fast)
        task.delay(0.22,function() Anim.T(sk,{Color=TH.Border,Transparency=0},TH.Med) end)
        if o.Callback then
            task.spawn(function() local ok,err=pcall(o.Callback); if not ok then warn("[NexusUI Btn]",err) end end)
        end
    end)
    return wrap
end

-- ─── TOGGLE ────────────────────────────────────────────────────
function CF.Toggle(o,parent,z)
    o=o or{}; z=z or 5; local state=o.Default==true
    local wrap=Fr(TH.Surface,0,SafeName("Tog"),z)
    wrap.Size=UDim2.new(1,0,0,SA.BtnH); wrap.Parent=parent
    RC(wrap); SK(wrap,TH.Border,1,0)
    local row=Fr(TH.Bg,1,"_R",z+1); row.Size=UDim2.fromScale(1,1); row.Parent=wrap
    LH(row,8,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center); PD(row,0,0,12,12)
    if o.Icon then
        local ic=IL(TH.T2,z+2); ic.Size=UDim2.fromOffset(15,15); ic.Parent=row; Icons.Apply(o.Icon,ic)
    end
    local lb=Lb(o.Name or"Toggle",TH.T1,SA.FS,TH.FR,Enum.TextXAlignment.Left,z+2)
    lb.Size=UDim2.new(1,-(o.Icon and 90 or 70),1,0); lb.Parent=row
    local TW,TRACK_H,TP=36,18,3
    local track=Fr(state and TH.Cyan or TH.Border,0,"_Tr",z+2)
    track.AnchorPoint=Vector2.new(1,0.5); track.Position=UDim2.new(1,-12,0.5,0)
    track.Size=UDim2.fromOffset(TW,TRACK_H); track.Parent=wrap; RC(track,TRACK_H/2)
    -- Registra callback condicional: cor depende do estado atual do toggle
    RegACFn(function(pal)
        if track and track.Parent then
            TweenService:Create(track, TH.Med, {BackgroundColor3 = state and pal.Cyan or TH.Border}):Play()
        end
    end)
    local ts=TRACK_H-TP*2
    local thumb=Fr(Color3.new(1,1,1),0,"_Th",z+3)
    thumb.AnchorPoint=Vector2.new(0,0.5)
    thumb.Position=UDim2.new(0,state and(TW-ts-TP)or TP,0.5,0)
    thumb.Size=UDim2.fromOffset(ts,ts); thumb.Parent=track; RC(thumb,ts/2)
    local function Set(v,fire)
        state=v
        Anim.T(track,{BackgroundColor3=v and TH.Cyan or TH.Border},TH.Fast)
        Anim.T(thumb,{Position=UDim2.new(0,v and(TW-ts-TP)or TP,0.5,0)},TH.Fast)
        if fire and o.Callback then task.spawn(function() local ok,err=pcall(o.Callback,state); if not ok then warn("[NexusUI Tog]",err) end end) end
    end
    local hit=TB(TH.Bg,1,z+10); hit.Size=UDim2.fromScale(1,1); hit.Parent=wrap
    hit.MouseEnter:Connect(function() Anim.T(wrap,{BackgroundColor3=TH.SurfaceB},TH.Fast) end)
    hit.MouseLeave:Connect(function() Anim.T(wrap,{BackgroundColor3=TH.Surface},TH.Fast) end)
    hit.MouseButton1Click:Connect(function() Set(not state,true) end)
    local api={}; function api:Set(v) Set(v,true) end; function api:Get() return state end
    return wrap,api
end

-- ─── SLIDER ────────────────────────────────────────────────────
function CF.Slider(o,parent,z)
    o=o or{}; z=z or 5
    local mn,mx,step=o.Min or 0,o.Max or 100,o.Step or 1
    local val=math.clamp(o.Default or mn,mn,mx); local suf=o.Suffix or""
    local wrap=Fr(TH.Surface,0,SafeName("Sld"),z)
    wrap.Size=UDim2.new(1,0,0,SA.BtnH+22); wrap.Parent=parent
    RC(wrap); SK(wrap,TH.Border,1,0)
    local nameL=Lb(o.Name or"Slider",TH.T1,SA.FS,TH.FR,Enum.TextXAlignment.Left,z+1)
    nameL.AnchorPoint=Vector2.new(0,0); nameL.Position=UDim2.fromOffset(12,8)
    nameL.Size=UDim2.new(1,-90,0,SA.FS+2); nameL.Parent=wrap
    local valL=Lb(tostring(val)..suf,TH.TAcc,SA.FS,TH.FB,Enum.TextXAlignment.Right,z+1)
    valL.AnchorPoint=Vector2.new(1,0); valL.Position=UDim2.new(1,-12,0,8)
    valL.Size=UDim2.fromOffset(80,SA.FS+2); valL.Parent=wrap
    RegAC(valL,"TextColor3","TAcc")
    local TRH=4; local trkY=8+SA.FS+2+8
    local track=Fr(TH.Border,0,"_Tr",z+1)
    track.Position=UDim2.new(0,12,0,trkY+2)
    track.Size=UDim2.new(1,-24,0,TRH); track.Parent=wrap; RC(track,TRH/2)
    local pct=(val-mn)/(mx-mn)
    local fill=Fr(TH.Cyan,0,"_F",z+2); fill.Size=UDim2.new(pct,0,1,0); fill.Parent=track; RC(fill,TRH/2)
    RegAC(fill,"BackgroundColor3","Cyan")
    local glow=IL(TH.Cyan,z+3); glow.Size=UDim2.fromOffset(10,10)
    glow.AnchorPoint=Vector2.new(1,0.5); glow.Position=UDim2.new(1,0,0.5,0)
    glow.Image="rbxassetid://6014261993"; glow.ImageTransparency=0.35; glow.Parent=fill
    RegAC(glow,"ImageColor3","Cyan")
    local TS=13
    local thmb=Fr(TH.Cyan,0,"_Th",z+4)
    thmb.AnchorPoint=Vector2.new(0.5,0.5); thmb.Position=UDim2.new(pct,0,0.5,0)
    thmb.Size=UDim2.fromOffset(TS,TS); thmb.Parent=track
    RC(thmb,TS/2); local thmbSk=SK(thmb,TH.CyanS,2,0.4)
    RegAC(thmb,"BackgroundColor3","Cyan")
    RegAC(thmbSk,"Color","CyanS")
    local function Snap(v) if step>0 then v=math.round(v/step)*step end return math.clamp(v,mn,mx) end
    local function SetVal(v,fire)
        val=Snap(v); local p=(val-mn)/(mx-mn)
        Anim.T(fill,{Size=UDim2.new(p,0,1,0)},TH.Fast)
        Anim.T(thmb,{Position=UDim2.new(p,0,0.5,0)},TH.Fast)
        valL.Text=tostring(val)..suf
        if fire and o.Callback then task.spawn(function() local ok,err=pcall(o.Callback,val); if not ok then warn("[NexusUI Sld]",err) end end) end
    end
    local dragging=false; local conns={}
    conns[1]=track.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true end
    end)
    conns[2]=UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end
    end)
    conns[3]=UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
            local rx=math.clamp((i.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
            SetVal(mn+rx*(mx-mn),true)
        end
    end)
    wrap.AncestryChanged:Connect(function()
        if not wrap.Parent then for _,c in ipairs(conns) do c:Disconnect() end end
    end)
    local api={}; function api:Set(v) SetVal(v,true) end; function api:Get() return val end
    return wrap,api
end

-- ─── DROPDOWN ──────────────────────────────────────────────────
-- Panel is parented to _OV (overlay ScreenGui) so it always
-- renders above every scroll frame / ClipsDescendants boundary.
function CF.Dropdown(o,parent,z)
    o=o or{}; z=z or 5
    local options=o.Options or{}
    local selected=o.Default or(options[1] or"Select...")
    local isOpen=false

    -- Wrap: AutomaticSize=Y para crescer e empurrar elementos abaixo ao abrir
    local wrap=Fr(TH.Surface,0,SafeName("DD"),z)
    wrap.Size=UDim2.new(1,0,0,0)
    wrap.AutomaticSize=Enum.AutomaticSize.Y
    wrap.ClipsDescendants=false; wrap.Parent=parent
    RC(wrap); local wsk=SK(wrap,TH.Border,1,0)

    -- Header (altura fixa = BtnH, sempre visivel)
    local header=Fr(TH.Bg,1,"_Hdr",z+1)
    header.Size=UDim2.new(1,0,0,SA.BtnH); header.Parent=wrap
    LH(header,8,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center); PD(header,0,0,12,8)
    if o.Icon then
        local ic=IL(TH.T2,z+2); ic.Size=UDim2.fromOffset(15,15); ic.Parent=header; Icons.Apply(o.Icon,ic)
    end
    local lb=Lb(o.Name or"Dropdown",TH.T1,SA.FS,TH.FR,Enum.TextXAlignment.Left,z+2)
    -- Limite de largura: deixa ~55% direito livre para selLbl + arrow flutuantes
    lb.Size=UDim2.new(0.45,0,1,0); lb.Parent=header
    local selLbl=Lb(selected,TH.TAcc,SA.FS-1,TH.FR,Enum.TextXAlignment.Right,z+2)
    -- Flutua sobre o header sem entrar no UIListLayout (LayoutOrder ignorado pelo Roblox
    -- apenas para itens que têm Size absoluta e Position absoluta com AnchorPoint definido)
    selLbl.AnchorPoint=Vector2.new(1,0.5); selLbl.Position=UDim2.new(1,-28,0.5,0)
    selLbl.Size=UDim2.new(0.44,0,1,0); selLbl.TextTruncate=Enum.TextTruncate.AtEnd
    -- Pai: wrap com Position relativa ao header já que wrap começa no topo
    selLbl.Parent=wrap
    RegAC(selLbl,"TextColor3","TAcc")
    local arrow=IL(TH.T2,z+2); arrow.Size=UDim2.fromOffset(12,12)
    -- Fixa no canto direito dentro da altura do header (SA.BtnH)
    arrow.AnchorPoint=Vector2.new(1,0.5)
    arrow.Position=UDim2.new(1,-10,0,SA.BtnH/2)
    arrow.Parent=wrap; Icons.Apply("chevron-down",arrow)

    -- Panel inline: filho do wrap, aparece abaixo do header
    local ITEM_H=SA.BtnH-8
    local fullH=math.min(#options,6)*(ITEM_H+4)+10
    local panel=Fr(TH.SurfaceB,0,"_DDPan",z+1)
    panel.Position=UDim2.new(0,0,0,SA.BtnH+4)
    panel.Size=UDim2.new(1,0,0,0)
    panel.ClipsDescendants=true; panel.Visible=false; panel.Parent=wrap
    RC(panel,SA.Rad); local panSk=SK(panel,TH.CyanD,1,0.6)
    RegAC(panSk,"Color","CyanD")

    local sf=SV(panel.ZIndex+1); sf.Size=UDim2.fromScale(1,1); sf.Parent=panel
    PD(sf,4,4,4,4); LV(sf,3)

    local function BuildItems()
        for _,c in ipairs(sf:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        for _,opt in ipairs(options) do
            local rb=TB(TH.Surface,selected==opt and 0 or 1,sf.ZIndex+1)
            rb.Name="O_"..opt; rb.Size=UDim2.new(1,0,0,ITEM_H)
            rb.Text=opt; rb.Font=TH.FR; rb.TextSize=SA.FS-1
            rb.TextColor3=selected==opt and TH.TAcc or TH.T1
            rb.TextXAlignment=Enum.TextXAlignment.Left
            rb.ClipsDescendants=false; rb.Parent=sf
            RC(rb,6); PD(rb,0,0,9,9)
            rb.MouseEnter:Connect(function()
                if selected~=opt then Anim.T(rb,{BackgroundTransparency=0,BackgroundColor3=TH.SurfaceB},TH.Fast) end
            end)
            rb.MouseLeave:Connect(function()
                if selected~=opt then Anim.T(rb,{BackgroundTransparency=1},TH.Fast) end
            end)
            rb.MouseButton1Click:Connect(function()
                selected=opt; selLbl.Text=opt
                for _,c2 in ipairs(sf:GetChildren()) do
                    if c2:IsA("TextButton") then
                        local on=c2.Name=="O_"..opt
                        c2.BackgroundTransparency=on and 0 or 1
                        c2.BackgroundColor3=TH.Surface; c2.TextColor3=on and TH.TAcc or TH.T1
                    end
                end
                -- fecha inline
                isOpen=false
                Anim.T(panel,{Size=UDim2.new(1,0,0,0)},TH.Fast)
                task.delay(0.12,function() panel.Visible=false end)
                Anim.T(arrow,{Rotation=0},TH.Fast)
                Anim.T(wsk,{Color=TH.Border,Transparency=0},TH.Fast)
                Anim.T(wrap,{BackgroundColor3=TH.Surface},TH.Fast)
                if o.Callback then task.spawn(function() local ok,err=pcall(o.Callback,selected); if not ok then warn("[NexusUI DD]",err) end end) end
            end)
        end
    end
    BuildItems()

    local function Open()
        isOpen=true; panel.Visible=true
        Anim.T(panel,{Size=UDim2.new(1,0,0,fullH)},TH.Elastic)
        Anim.T(arrow,{Rotation=180},TH.Fast)
        Anim.T(wsk,{Color=TH.Cyan,Transparency=0.4},TH.Fast)
        Anim.T(wrap,{BackgroundColor3=TH.SurfaceB},TH.Fast)
    end
    local function Close()
        isOpen=false
        Anim.T(panel,{Size=UDim2.new(1,0,0,0)},TH.Fast)
        task.delay(0.12,function() panel.Visible=false end)
        Anim.T(arrow,{Rotation=0},TH.Fast)
        Anim.T(wsk,{Color=TH.Border,Transparency=0},TH.Fast)
        Anim.T(wrap,{BackgroundColor3=TH.Surface},TH.Fast)
    end

    local hit=TB(TH.Bg,1,z+5); hit.Size=UDim2.new(1,0,0,SA.BtnH)
    hit.ClipsDescendants=false; hit.Parent=wrap
    hit.MouseButton1Click:Connect(function() if isOpen then Close() else Open() end end)
    hit.MouseEnter:Connect(function() if not isOpen then Anim.T(wrap,{BackgroundColor3=TH.SurfaceB},TH.Fast) end end)
    hit.MouseLeave:Connect(function() if not isOpen then Anim.T(wrap,{BackgroundColor3=TH.Surface},TH.Fast) end end)

    -- Fechar ao clicar fora
    UserInputService.InputBegan:Connect(function(i)
        if not isOpen then return end
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            task.defer(function()
                if not(wrap and wrap.Parent) then return end
                local mp=UserInputService:GetMouseLocation()
                local wp=wrap.AbsolutePosition; local ws=wrap.AbsoluteSize
                local inW=mp.X>=wp.X and mp.X<=wp.X+ws.X and mp.Y>=wp.Y and mp.Y<=wp.Y+ws.Y
                if not inW then Close() end
            end)
        end
    end)

    local api={}
    function api:Set(v) selected=v; selLbl.Text=v end
    function api:Get() return selected end
    function api:SetOptions(n) options=n; BuildItems() end
    return wrap,api
end

-- ─── KEYBIND ───────────────────────────────────────────────────
function CF.Keybind(o,parent,z)
    o=o or{}; z=z or 5; local key=o.Default or Enum.KeyCode.Unknown; local listening=false
    local wrap=Fr(TH.Surface,0,SafeName("KB"),z)
    wrap.Size=UDim2.new(1,0,0,SA.BtnH); wrap.Parent=parent
    RC(wrap); SK(wrap,TH.Border,1,0)
    local lb=Lb(o.Name or"Keybind",TH.T1,SA.FS,TH.FR,Enum.TextXAlignment.Left,z+1)
    lb.AnchorPoint=Vector2.new(0,0.5); lb.Position=UDim2.new(0,12,0.5,0)
    lb.Size=UDim2.new(0.6,0,1,0); lb.Parent=wrap
    local kbox=Fr(TH.Bg,0,"_KB",z+1)
    kbox.AnchorPoint=Vector2.new(1,0.5); kbox.Position=UDim2.new(1,-10,0.5,0)
    kbox.Size=UDim2.fromOffset(88,22); kbox.Parent=wrap
    RC(kbox,5); local ksk=SK(kbox,TH.Border,1,0)
    local klbl=Lb(key.Name,TH.TAcc,SA.FS-1,TH.FM,Enum.TextXAlignment.Center,z+2)
    klbl.Size=UDim2.fromScale(1,1); klbl.Parent=kbox
    RegAC(klbl,"TextColor3","TAcc")
    local hit=TB(TH.Bg,1,z+5); hit.Size=UDim2.fromScale(1,1); hit.Parent=wrap
    hit.MouseEnter:Connect(function() Anim.T(wrap,{BackgroundColor3=TH.SurfaceB},TH.Fast) end)
    hit.MouseLeave:Connect(function() Anim.T(wrap,{BackgroundColor3=TH.Surface},TH.Fast) end)
    hit.MouseButton1Click:Connect(function()
        listening=true; klbl.Text="..."; klbl.TextColor3=TH.Warn
        Anim.T(ksk,{Color=TH.Warn},TH.Fast)
    end)
    UserInputService.InputBegan:Connect(function(i,gp)
        if not listening or gp then return end
        if i.UserInputType==Enum.UserInputType.Keyboard then
            key=i.KeyCode; listening=false
            klbl.Text=key.Name; klbl.TextColor3=TH.TAcc
            Anim.T(ksk,{Color=TH.Border},TH.Fast)
            if o.Callback then task.spawn(function() local ok,err=pcall(o.Callback,key); if not ok then warn("[NexusUI KB]",err) end end) end
        end
    end)
    local api={}; function api:Set(k) key=k; klbl.Text=k.Name end; function api:Get() return key end
    return wrap,api
end

-- ─── INPUT ─────────────────────────────────────────────────────
function CF.Input(o,parent,z)
    o=o or{}; z=z or 5
    local value = o.Default or ""
    local wrap=Fr(TH.Surface,0,SafeName("Inp"),z)
    wrap.Size=UDim2.new(1,0,0,SA.BtnH+22); wrap.Parent=parent
    RC(wrap); local sk=SK(wrap,TH.Border,1,0)

    -- Label nome
    local nameL=Lb(o.Name or"Input",TH.T1,SA.FS,TH.FR,Enum.TextXAlignment.Left,z+1)
    nameL.AnchorPoint=Vector2.new(0,0); nameL.Position=UDim2.fromOffset(12,7)
    nameL.Size=UDim2.new(1,-24,0,SA.FS+2); nameL.Parent=wrap

    -- Caixa de texto
    local box=Fr(TH.Bg,0,"_Box",z+1)
    box.Position=UDim2.new(0,10,0,SA.FS+14); box.Size=UDim2.new(1,-20,0,SA.BtnH-10)
    box.Parent=wrap; RC(box,6); local bsk=SK(box,TH.Border,1,0)
    -- NÃO registra bsk no RegAC global: a cor já é animada no Focus/FocusLost abaixo

    -- Ícone opcional à esquerda
    local iconW = 0
    if o.Icon then
        local ic=IL(TH.T2,z+2); ic.Size=UDim2.fromOffset(14,14)
        ic.AnchorPoint=Vector2.new(0,0.5); ic.Position=UDim2.new(0,8,0.5,0); ic.Parent=box
        Icons.Apply(o.Icon,ic); iconW=22
    end

    -- TextBox real
    local tb=Instance.new("TextBox")
    tb.BackgroundTransparency=1; tb.BorderSizePixel=0
    tb.Text=value
    tb.PlaceholderText=o.Placeholder or "Digite aqui..."
    tb.PlaceholderColor3=TH.T3
    tb.TextColor3=TH.T1; tb.TextSize=SA.FS-1; tb.Font=TH.FR
    tb.TextXAlignment=Enum.TextXAlignment.Left
    tb.ClearTextOnFocus=o.ClearOnFocus==true
    tb.ZIndex=z+2
    tb.AnchorPoint=Vector2.new(0,0.5); tb.Position=UDim2.new(0,8+iconW,0.5,0)
    tb.Size=UDim2.new(1,-(16+iconW),1,0)
    tb.Parent=box

    -- Foco: borda acende com a cor do tema
    tb.Focused:Connect(function()
        Anim.T(bsk,{Color=TH.Cyan,Transparency=0.3},TH.Fast)
        Anim.T(wrap,{BackgroundColor3=TH.SurfaceB},TH.Fast)
    end)
    tb.FocusLost:Connect(function(enter)
        value=tb.Text
        Anim.T(bsk,{Color=TH.Border,Transparency=0},TH.Fast)
        Anim.T(wrap,{BackgroundColor3=TH.Surface},TH.Fast)
        if o.Callback then task.spawn(function() local ok,err=pcall(o.Callback,value,enter); if not ok then warn("[NexusUI Inp]",err) end end) end
    end)
    -- Atualiza em tempo real se quiser (opcional via o.Live=true)
    if o.Live then
        tb:GetPropertyChangedSignal("Text"):Connect(function()
            value=tb.Text
            if o.Callback then task.spawn(o.Callback, value, false) end
        end)
    end

    local api={}
    function api:Set(v) value=v; tb.Text=v end
    function api:Get() return value end
    function api:Focus() tb:CaptureFocus() end
    return wrap, api
end

-- ─── SEARCH ────────────────────────────────────────────────────
-- Filtra elementos visíveis dentro de uma Tab em tempo real.
-- Suporta elementos soltos E elementos dentro de Sections.
function CF.Search(parent, z)
    z = z or 5
    local wrap = Fr(TH.Surface, 0, SafeName("Srch"), z)
    wrap.Size = UDim2.new(1, 0, 0, SA.BtnH)
    wrap.Parent = parent
    RC(wrap); local sk = SK(wrap, TH.Border, 1, 0)

    -- Ícone de lupa
    local ic = IL(TH.T2, z+1)
    ic.Size = UDim2.fromOffset(14, 14)
    ic.AnchorPoint = Vector2.new(0, 0.5)
    ic.Position = UDim2.new(0, 10, 0.5, 0)
    ic.Parent = wrap
    Icons.Apply("search", ic)

    -- TextBox de busca
    local tb = Instance.new("TextBox")
    tb.BackgroundTransparency = 1; tb.BorderSizePixel = 0
    tb.Text = ""
    tb.PlaceholderText = "Pesquisar elementos..."
    tb.PlaceholderColor3 = TH.T3
    tb.TextColor3 = TH.T1; tb.TextSize = SA.FS - 1; tb.Font = TH.FR
    tb.TextXAlignment = Enum.TextXAlignment.Left
    tb.ClearTextOnFocus = false
    tb.ZIndex = z + 2
    tb.AnchorPoint = Vector2.new(0, 0.5)
    tb.Position = UDim2.new(0, 32, 0.5, 0)
    tb.Size = UDim2.new(1, -48, 1, 0)
    tb.Parent = wrap

    -- Botão limpar (X) — aparece só quando há texto
    local clrBtn = IB(TH.T3, z+3)
    clrBtn.Size = UDim2.fromOffset(14, 14)
    clrBtn.AnchorPoint = Vector2.new(1, 0.5)
    clrBtn.Position = UDim2.new(1, -10, 0.5, 0)
    clrBtn.BackgroundTransparency = 1
    clrBtn.Visible = false
    clrBtn.Parent = wrap
    Icons.Apply("x", clrBtn)

    -- Extrai o texto do nome principal de um componente.
    -- Usa TextXAlignment.Left para diferenciar labels de nome (Left)
    -- de labels de valor como Slider/Dropdown (Right).
    local function GetName(inst)
        local fallback = nil
        for _, d in ipairs(inst:GetDescendants()) do
            if d:IsA("TextLabel") and #d.Text > 0 and d.TextSize >= (SA.FS - 2) then
                if d.TextXAlignment == Enum.TextXAlignment.Left then
                    return d.Text:lower()   -- nome exato → retorna imediatamente
                elseif not fallback then
                    fallback = d.Text:lower() -- guarda como plano B
                end
            end
        end
        return fallback or inst.Name:lower()
    end

    -- Um frame é Section se tiver o filho interno "_In"
    local function IsSection(inst)
        return inst:IsA("Frame") and inst:FindFirstChild("_In") ~= nil
    end

    -- Pega o texto do header da Section (_In > _Hdr > TextLabel)
    local function GetSectionTitle(inst)
        local inner = inst:FindFirstChild("_In")
        if not inner then return "" end
        local hdr = inner:FindFirstChild("_Hdr")
        if not hdr then return "" end
        for _, d in ipairs(hdr:GetChildren()) do
            if d:IsA("TextLabel") and #d.Text > 0 then
                return d.Text:lower()
            end
        end
        return ""
    end

    local function Filter(query)
        local q = query:lower()
        for _, child in ipairs(parent:GetChildren()) do
            if child == wrap then
                -- nunca oculta a própria barra de busca
            elseif not child:IsA("Frame") then
                -- ignora UILayout, ScrollBarImage, etc.
            elseif IsSection(child) then
                local inner = child:FindFirstChild("_In")
                -- Se o TÍTULO da section bater → mostra a section inteira com todos os filhos
                local titleMatch = (q == "") or (GetSectionTitle(child):find(q, 1, true) ~= nil)
                if titleMatch then
                    if inner then
                        for _, el in ipairs(inner:GetChildren()) do
                            if el:IsA("Frame") and el.Name ~= "_Hdr" and el.Name ~= "_Div" then
                                el.Visible = true
                            end
                        end
                    end
                    child.Visible = true
                else
                    -- Título não bateu: filtra elemento por elemento dentro da section
                    local anyMatch = false
                    if inner then
                        for _, el in ipairs(inner:GetChildren()) do
                            if el:IsA("Frame") and el.Name ~= "_Hdr" and el.Name ~= "_Div" then
                                local match = GetName(el):find(q, 1, true) ~= nil
                                el.Visible = match
                                if match then anyMatch = true end
                            end
                        end
                    end
                    child.Visible = anyMatch
                end
            else
                -- Elemento solto na tab
                child.Visible = (q == "") or (GetName(child):find(q, 1, true) ~= nil)
            end
        end
    end

    -- Contador de resultados (label flutuante no canto direito)
    local countLbl = Lb("", TH.T2, SA.FS - 2, TH.FR, Enum.TextXAlignment.Right, z+2)
    countLbl.AnchorPoint = Vector2.new(1, 0.5)
    countLbl.Position = UDim2.new(1, -30, 0.5, 0)
    countLbl.Size = UDim2.fromOffset(60, SA.BtnH)
    countLbl.Visible = false
    countLbl.Parent = wrap

    local function CountVisible(query)
        local q = query:lower()
        if q == "" then countLbl.Visible = false; return end
        local total, found = 0, 0
        for _, child in ipairs(parent:GetChildren()) do
            if child ~= wrap and child:IsA("Frame") then
                if IsSection(child) then
                    -- Conta a section pelo título primeiro
                    total += 1
                    if GetSectionTitle(child):find(q, 1, true) then
                        found += 1
                    else
                        -- Título não bateu: conta filhos individualmente
                        local inner = child:FindFirstChild("_In")
                        if inner then
                            for _, el in ipairs(inner:GetChildren()) do
                                if el:IsA("Frame") and el.Name ~= "_Hdr" and el.Name ~= "_Div" then
                                    if GetName(el):find(q, 1, true) then found += 1 end
                                end
                            end
                        end
                    end
                else
                    total += 1
                    if GetName(child):find(q, 1, true) then found += 1 end
                end
            end
        end
        countLbl.Text = found.."/"..total
        countLbl.TextColor3 = found > 0 and TH.TAcc or TH.Err
        countLbl.Visible = true
    end

    tb.Focused:Connect(function()
        Anim.T(sk, {Color = TH.Cyan, Transparency = 0.3}, TH.Fast)
        Anim.T(ic, {ImageColor3 = TH.Cyan}, TH.Fast)
    end)
    tb.FocusLost:Connect(function()
        Anim.T(sk, {Color = TH.Border, Transparency = 0}, TH.Fast)
        Anim.T(ic, {ImageColor3 = TH.T2}, TH.Fast)
    end)
    tb:GetPropertyChangedSignal("Text"):Connect(function()
        local t = tb.Text
        clrBtn.Visible = (t ~= "")
        Filter(t)
        CountVisible(t)
    end)
    clrBtn.MouseButton1Click:Connect(function()
        tb.Text = ""; clrBtn.Visible = false
        Filter(""); CountVisible("")
    end)
    clrBtn.MouseEnter:Connect(function() Anim.T(clrBtn, {ImageColor3 = TH.T1}, TH.Fast) end)
    clrBtn.MouseLeave:Connect(function() Anim.T(clrBtn, {ImageColor3 = TH.T3}, TH.Fast) end)
    wrap.MouseEnter:Connect(function() Anim.T(wrap, {BackgroundColor3 = TH.SurfaceB}, TH.Fast) end)
    wrap.MouseLeave:Connect(function() Anim.T(wrap, {BackgroundColor3 = TH.Surface}, TH.Fast) end)

    local api = {}
    function api:Clear()
        tb.Text = ""; clrBtn.Visible = false
        Filter(""); CountVisible("")
    end
    function api:Get() return tb.Text end
    function api:SetPlaceholder(t) tb.PlaceholderText = t end
    return wrap, api
end

-- ─── LABEL ─────────────────────────────────────────────────────
function CF.Label(text,parent,z)
    z=z or 5
    local wrap=Fr(TH.Surface,0,"Lbl",z)
    wrap.Size=UDim2.new(1,0,0,0); wrap.AutomaticSize=Enum.AutomaticSize.Y; wrap.Parent=parent
    RC(wrap); PD(wrap,7,7,12,12)
    local l=Lb(text or"",TH.T2,SA.FS-1,TH.FR,Enum.TextXAlignment.Left,z+1)
    l.Size=UDim2.fromScale(1,0); l.AutomaticSize=Enum.AutomaticSize.Y
    l.TextWrapped=true; l.RichText=true; l.Parent=wrap
    return wrap
end

-- ─── PARAGRAPH ─────────────────────────────────────────────────
function CF.Paragraph(o,parent,z)
    o=o or{}; z=z or 5
    local wrap=Fr(TH.SurfaceB,0,SafeName("Para"),z)
    wrap.Size=UDim2.new(1,0,0,0); wrap.AutomaticSize=Enum.AutomaticSize.Y; wrap.Parent=parent
    RC(wrap); SK(wrap,TH.Border,1,0); PD(wrap,10,10,12,12); LV(wrap,5)
    if o.Title and o.Title~="" then
        local tl=Lb(o.Title,TH.TAcc,SA.FS,TH.FB,Enum.TextXAlignment.Left,z+1)
        tl.Size=UDim2.fromScale(1,0); tl.AutomaticSize=Enum.AutomaticSize.Y; tl.Parent=wrap
        RegAC(tl,"TextColor3","TAcc")
    end
    local cl=Lb(o.Content or"",TH.T2,SA.FS-1,TH.FR,Enum.TextXAlignment.Left,z+1)
    cl.Size=UDim2.fromScale(1,0); cl.AutomaticSize=Enum.AutomaticSize.Y
    cl.TextWrapped=true; cl.RichText=true; cl.Parent=wrap
    return wrap
end

-- ─── SECTION ───────────────────────────────────────────────────
function CF.Section(name,parent,z)
    z=z or 4
    local wrap=Fr(TH.Bg,0,SafeName("Sec"),z)
    wrap.Size=UDim2.new(1,0,0,0); wrap.AutomaticSize=Enum.AutomaticSize.Y; wrap.Parent=parent
    RC(wrap,10); SK(wrap,TH.Border,1,0)
    local inner=Fr(TH.Bg,1,"_In",z+1)
    -- Tamanho fixo em X (100% largura), Y cresce via AutomaticSize
    -- fromScale(1,1) criava dependência circular com o wrap que também tem AutomaticSize=Y
    inner.Size=UDim2.new(1,0,0,0); inner.AutomaticSize=Enum.AutomaticSize.Y; inner.Parent=wrap
    PD(inner,8,10,10,10); LV(inner,6)
    -- Header
    local hdr=Fr(TH.Bg,1,"_Hdr",z+2); hdr.Size=UDim2.new(1,0,0,16); hdr.Parent=inner
    LH(hdr,6,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)
    local dot=Fr(TH.Cyan,0,"_Dot",z+3); dot.Size=UDim2.fromOffset(5,5); dot.Parent=hdr; RC(dot,3)
    RegAC(dot,"BackgroundColor3","Cyan")
    local hl=Lb(name,TH.T2,SA.FS-1,TH.FB,Enum.TextXAlignment.Left,z+3)
    hl.Size=UDim2.new(1,-12,1,0); hl.Parent=hdr
    -- Divider
    local div=Fr(TH.Border,0,"_Div",z+2); div.Size=UDim2.new(1,0,0,1); div.Parent=inner
    local api={}
    function api:CreateButton(o)    return CF.Button(o,   inner,z+3) end
    function api:CreateToggle(o)    return CF.Toggle(o,   inner,z+3) end
    function api:CreateSlider(o)    return CF.Slider(o,   inner,z+3) end
    function api:CreateDropdown(o)  return CF.Dropdown(o, inner,z+3) end
    function api:CreateKeybind(o)   return CF.Keybind(o,  inner,z+3) end
    function api:CreateInput(o)     return CF.Input(o,    inner,z+3) end
    function api:CreateLabel(t)     return CF.Label(t,    inner,z+3) end
    function api:CreateParagraph(o) return CF.Paragraph(o,inner,z+3) end
    return wrap,api
end

-- ═══════════════════════════════════════════════════════════════
--  FLOATING TOGGLE BUTTON
-- ═══════════════════════════════════════════════════════════════
local function FloatBtn(sg,iconNameOrId,onToggle)
    local S = 46

    -- ── Ring: irmão do botão no ScreenGui (ZIndex menor = fica atrás)
    -- Parear ao sg diretamente garante que UICorner.CornerRadius=UDim.new(1,0)
    -- sempre renderiza como círculo perfeito, sem interferência do pai.
    local ring = Instance.new("Frame")
    ring.Name              = "_NexFloatRing"
    ring.BackgroundColor3  = TH.Cyan
    ring.BackgroundTransparency = 0.55
    ring.BorderSizePixel   = 0
    ring.AnchorPoint       = Vector2.new(0.5, 0.5)
    ring.Position          = UDim2.new(0.05, 0, 0.5, 0)
    ring.Size              = UDim2.fromOffset(S + 14, S + 14)
    ring.ZIndex            = 298
    ring.Parent            = sg
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(0, 999)
    rc.Parent = ring
    RegAC(ring, "BackgroundColor3", "Cyan")

    local fb = IB(TH.Cyan, 300); fb.Name = "_NexFloat"
    fb.AnchorPoint       = Vector2.new(0.5, 0.5)
    fb.BackgroundColor3  = TH.SurfaceB
    fb.Position          = UDim2.new(0.05, 0, 0.5, 0)
    fb.Size              = UDim2.fromOffset(S, S)
    fb.Parent            = sg
    RC(fb, S / 2)
    local fbStroke = SK(fb, TH.Cyan, 1.5, 0)
    RegAC(fbStroke, "Color", "Cyan")
    RegAC(fb, "ImageColor3", "Cyan")
    -- toggled começa true; callback atualiza bg correto
    local toggled = true
    RegACFn(function(pal)
        if fb and fb.Parent then
            TweenService:Create(fb, TH.Med, {BackgroundColor3 = toggled and pal.CyanD or TH.SurfaceB}):Play()
        end
    end)
    if iconNameOrId then Icons.Apply(iconNameOrId, fb) end

    -- ── Pulso animado (só tamanho + transparência; forma nunca muda = sempre círculo)
    task.spawn(function()
        while ring and ring.Parent do
            Anim.T(ring,
                { BackgroundTransparency = 0.85, Size = UDim2.fromOffset(S + 26, S + 26) },
                TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(1.2)
            Anim.T(ring,
                { BackgroundTransparency = 0.40, Size = UDim2.fromOffset(S + 8,  S + 8)  },
                TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut))
            task.wait(1.2)
        end
    end)

    -- ── Drag: move botão E ring juntos
    local drag, ds, sp, moved = false, nil, nil, false
    fb.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            drag = true; ds = i.Position; sp = fb.Position; moved = false
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - ds
            if d.Magnitude > 4 then moved = true end
            local newPos = UDim2.new(sp.X.Scale, sp.X.Offset + d.X,
                                     sp.Y.Scale, sp.Y.Offset + d.Y)
            fb.Position   = newPos
            ring.Position = newPos   -- ring acompanha o botão ao arrastar
        end
    end)

    -- ── Click: toggle + micro-bounce no botão
    fb.MouseButton1Click:Connect(function()
        if moved then return end
        toggled = not toggled
        Anim.T(fb, { BackgroundColor3 = toggled and TH.CyanD or TH.SurfaceB }, TH.Fast)
        Anim.T(fb, { Size = UDim2.fromOffset(S - 4, S - 4) }, TH.Fast)
        task.delay(0.10, function()
            Anim.T(fb, { Size = UDim2.fromOffset(S, S) }, TH.Elastic)
        end)
        if onToggle then task.spawn(onToggle, toggled) end
    end)

    return fb
end

-- ═══════════════════════════════════════════════════════════════
--  TAB SYSTEM  (horizontal pills)
-- ═══════════════════════════════════════════════════════════════
local function BuildTabSystem(body,tabScroll,z)
    local tabs={}; local current=nil; local PILL_H=32
    -- Tamanhos de icone por quantidade de tabs
    -- <= 4 tabs: 20px | <= 6: 17px | <= 9: 14px | > 9: 11px (minimo)
    local IC_MAX=20; local IC_MIN=11
    local function CalcIconSize()
        local n=#tabs
        if n<=4 then return 20
        elseif n<=6 then return 17
        elseif n<=9 then return 14
        else return IC_MIN end
    end
    local function RefreshSizes()
        local sz=CalcIconSize()
        local pillW=sz+20  -- padding de 10px cada lado
        for _,t in pairs(tabs) do
            t.Pill.Size=UDim2.fromOffset(pillW,PILL_H)
            if t.Ic then t.Ic.Size=UDim2.fromOffset(sz,sz) end
        end
    end
    local function Activate(id)
        for tid,t in pairs(tabs) do
            local on=(tid==id)
            Anim.T(t.Pill,{BackgroundTransparency=on and 0 or 1,BackgroundColor3=on and TH.SurfaceB or TH.Surface},TH.Fast)
            Anim.T(t.Lbl,{TextColor3=on and TH.TAcc or TH.T2},TH.Fast)
            if t.Ic then Anim.T(t.Ic,{ImageColor3=on and TH.Cyan or TH.T3},TH.Fast) end
            Anim.T(t.Ind,{BackgroundTransparency=on and 0 or 1},TH.Fast)
            t.Content.Visible=on
        end
        current=id
    end
    local api={}
    function api:AddTab(o)
        local id=o.Name or("Tab"..tostring(#tabs+1))
        local hasIcon=o.Icon~=nil
        local sz=CalcIconSize()
        local pillW=sz+20
        local pill=Fr(TH.Surface,1,"Pill_"..id,z+1)
        pill.Size=UDim2.fromOffset(pillW,PILL_H); pill.ClipsDescendants=true; pill.Parent=tabScroll
        RC(pill,6)
        local pillRow=Fr(TH.Bg,1,"_PR",pill.ZIndex+1); pillRow.Size=UDim2.fromScale(1,1); pillRow.Parent=pill
        LH(pillRow,0,Enum.HorizontalAlignment.Center,Enum.VerticalAlignment.Center); PD(pillRow,0,0,0,0)
        local tabIc
        if hasIcon then
            tabIc=IL(TH.T3,pillRow.ZIndex+1); tabIc.Size=UDim2.fromOffset(sz,sz); tabIc.Parent=pillRow
            Icons.Apply(o.Icon,tabIc)
            -- Registra callback condicional: cor depende se esta tab está ativa
            RegACFn(function(pal)
                if tabIc and tabIc.Parent then
                    local isActive = (current == id)
                    TweenService:Create(tabIc, TH.Med, {ImageColor3 = isActive and pal.Cyan or TH.T3}):Play()
                end
            end)
        else
            local fallback=Lb(string.sub(id,1,1):upper(),TH.T2,SA.FS,TH.FB,Enum.TextXAlignment.Center,pillRow.ZIndex+1)
            fallback.Size=UDim2.fromScale(1,1); fallback.Parent=pillRow
        end
        local tabLbl=Lb("",TH.T2,1,TH.FR,Enum.TextXAlignment.Center,pillRow.ZIndex+1)
        tabLbl.Size=UDim2.fromOffset(0,0); tabLbl.Visible=false; tabLbl.Parent=pillRow
        local ind=Fr(TH.Cyan,1,"_Ind",pill.ZIndex+4)
        ind.AnchorPoint=Vector2.new(0.5,1); ind.Position=UDim2.new(0.5,0,1,0)
        ind.Size=UDim2.new(0.55,0,0,2); ind.Parent=pill; RC(ind,1)
        RegAC(ind,"BackgroundColor3","Cyan")
        local hit=TB(TH.Bg,1,pill.ZIndex+5); hit.Size=UDim2.fromScale(1,1); hit.ClipsDescendants=false; hit.Parent=pill
        local content=SV(z+1); content.Name="Content_"..id
        content.Size=UDim2.fromScale(1,1); content.Visible=false; content.Parent=body
        PD(content,SA.Pad+2,SA.Pad+2,SA.Pad,SA.Pad); LV(content,8)
        tabs[id]={Pill=pill,Lbl=tabLbl,Ic=tabIc,Ind=ind,Content=content}
        RefreshSizes()  -- reajusta todos ao adicionar nova tab
        if not current then Activate(id) end
        hit.MouseButton1Click:Connect(function() Anim.Ripple(pill,pill.AbsoluteSize.X/2,pill.AbsoluteSize.Y/2); Activate(id) end)
        hit.MouseEnter:Connect(function() if current~=id then Anim.T(pill,{BackgroundTransparency=0.65},TH.Fast) end end)
        hit.MouseLeave:Connect(function() if current~=id then Anim.T(pill,{BackgroundTransparency=1},TH.Fast) end end)
        local tabAPI={}
        function tabAPI:CreateSection(name) local _,s=CF.Section(name,content,z+2); return s end
        function tabAPI:CreateButton(opts)    return CF.Button(opts,   content,z+2) end
        function tabAPI:CreateToggle(opts)    return CF.Toggle(opts,   content,z+2) end
        function tabAPI:CreateSlider(opts)    return CF.Slider(opts,   content,z+2) end
        function tabAPI:CreateDropdown(opts)  return CF.Dropdown(opts, content,z+2) end
        function tabAPI:CreateKeybind(opts)   return CF.Keybind(opts,  content,z+2) end
        function tabAPI:CreateInput(opts)     return CF.Input(opts,    content,z+2) end
        function tabAPI:CreateLabel(t)        return CF.Label(t,       content,z+2) end
        function tabAPI:CreateParagraph(opts) return CF.Paragraph(opts,content,z+2) end
        function tabAPI:CreateSearch()        return CF.Search(        content,z+2) end
        return tabAPI
    end
    return api
end

-- ═══════════════════════════════════════════════════════════════
--  WINDOW
-- ═══════════════════════════════════════════════════════════════
local function BuildWindow(opts,sg)
    opts=opts or{}
    local title=opts.Title or"NexusUI"
    local wW=(opts.Size and opts.Size.X.Offset)or SA.WinW
    local wH=(opts.Size and opts.Size.Y.Offset)or SA.WinH
    local z=5
    local root=Fr(TH.Bg,1,"_NexWin",z)
    root.AnchorPoint=Vector2.new(0.5,0.5); root.Position=UDim2.new(0.5,0,0.5,-10)
    root.Size=UDim2.fromOffset(wW,0); root.ClipsDescendants=false; root.Parent=sg
    RC(root,10)
    -- Neon border: UIStroke pulsante que acompanha exatamente o CornerRadius do root
    local neonStroke=Instance.new("UIStroke")
    neonStroke.Color=TH.Cyan; neonStroke.Thickness=1.5
    neonStroke.Transparency=0.3
    neonStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    neonStroke.Parent=root
    RegAC(neonStroke,"Color","Cyan")
    task.spawn(function()
        while root and root.Parent do
            Anim.T(neonStroke,{Transparency=0.82},TH.Sine); task.wait(1.4)
            Anim.T(neonStroke,{Transparency=0.15},TH.Sine); task.wait(1.4)
        end
    end)
    -- Title bar
    local TBH=42
    local titleBar=Fr(TH.BgAlt,0,"_TB",z+1)
    titleBar.Size=UDim2.new(1,0,0,TBH); titleBar.ClipsDescendants=false; titleBar.Parent=root
    -- ClipsDescendants=false é OBRIGATÓRIO: com true o Roblox respeita UICorner e
    -- recorta o tbm (máscara de canto) para fora da área curva, destruindo o efeito.
    RC(titleBar,10)
    -- tbm: frame filho da mesma cor que preenche os 10px inferiores,
    -- cobrindo os dois cantos arredondados inferiores do titleBar → borda reta embaixo.
    local tbm=Fr(TH.BgAlt,0,"_TBM",z+2); tbm.Position=UDim2.new(0,0,1,-10); tbm.Size=UDim2.new(1,0,0,10); tbm.Parent=titleBar
    local tbRow=Fr(TH.Bg,1,"_TBR",z+2); tbRow.Size=UDim2.fromScale(1,1); tbRow.Parent=titleBar
    LH(tbRow,0,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center); PD(tbRow,0,0,14,4)
    if opts.Icon then
        local wi=IL(TH.Cyan,z+3); wi.Size=UDim2.fromOffset(18,18); wi.Parent=tbRow; Icons.Apply(opts.Icon,wi)
        RegAC(wi,"ImageColor3","Cyan")
        local sp=Fr(TH.Bg,1,"_Sp",z+2); sp.Size=UDim2.fromOffset(7,1); sp.Parent=tbRow
    end
    local titleLbl=Lb(title,TH.T1,SA.FS,TH.FB,Enum.TextXAlignment.Left,z+3)
    titleLbl.Size=UDim2.new(1,-90,1,0); titleLbl.Parent=tbRow
    local ctrlRow=Fr(TH.Bg,1,"_Ctrl",z+3)
    ctrlRow.AnchorPoint=Vector2.new(1,0.5); ctrlRow.Position=UDim2.new(1,-10,0.5,0)
    ctrlRow.Size=UDim2.fromOffset(58,TBH); ctrlRow.Parent=titleBar
    LH(ctrlRow,5,Enum.HorizontalAlignment.Right,Enum.VerticalAlignment.Center)
    local function CtrlBtn(iconKey,hoverCol)
        local cb=IB(TH.T3,z+4); cb.Size=UDim2.fromOffset(16,16); cb.BackgroundColor3=TH.Surface; cb.Parent=ctrlRow
        RC(cb,4); Icons.Apply(iconKey,cb)
        cb.MouseEnter:Connect(function() Anim.T(cb,{BackgroundColor3=hoverCol,ImageColor3=Color3.new(1,1,1)},TH.Fast) end)
        cb.MouseLeave:Connect(function() Anim.T(cb,{BackgroundColor3=TH.Surface,ImageColor3=TH.T3},TH.Fast) end)
        return cb
    end
    local minBtn=CtrlBtn("minus",TH.Warn); local closeBtn=CtrlBtn("x",TH.Err)
    -- Tab band
    local TAB_H=46
    local tabBand=Fr(TH.BgAlt,0,"_TabBand",z+1)
    tabBand.Position=UDim2.new(0,0,0,TBH); tabBand.Size=UDim2.new(1,0,0,TAB_H); tabBand.Parent=root
    local tabScroll=Instance.new("ScrollingFrame"); tabScroll.Name="_TabSF"
    tabScroll.BackgroundTransparency=1; tabScroll.BorderSizePixel=0
    tabScroll.Size=UDim2.fromScale(1,1); tabScroll.CanvasSize=UDim2.fromScale(0,0)
    tabScroll.AutomaticCanvasSize=Enum.AutomaticSize.X; tabScroll.ScrollBarThickness=0
    tabScroll.ScrollingDirection=Enum.ScrollingDirection.X
    tabScroll.ZIndex=tabBand.ZIndex+1; tabScroll.Parent=tabBand
    PD(tabScroll,7,7,10,10); LH(tabScroll,5,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center)
    -- Divider below tab band
    local tabDiv=Fr(TH.Border,0,"_TDiv",z+2)
    tabDiv.AnchorPoint=Vector2.new(0,1); tabDiv.Position=UDim2.new(0,0,1,0)
    tabDiv.Size=UDim2.new(1,0,0,1); tabDiv.Parent=tabBand
    -- Body: ClipsDescendants+RC(body,10) → Roblox respeita UICorner no clip.
    -- Conteudo opaco eh recortado pelo arco, nunca sangrando nos cantos do root.
    local TOP=TBH+TAB_H
    local body=Fr(TH.Bg,1,"_Body",z+1)
    body.Position=UDim2.new(0,0,0,TOP); body.Size=UDim2.new(1,0,1,-TOP)
    body.ClipsDescendants=true; body.Parent=root
    RC(body,10)
    local tabSys=BuildTabSystem(body,tabScroll,z+2)
    -- Drag
    MakeDraggable(root,titleBar)
    -- Min / Close
    local minimized=false
    minBtn.MouseButton1Click:Connect(function()
        minimized=not minimized
        if minimized then
            -- Esconde a mascara de cantos inferiores do titleBar → cantos arredondam
            tbm.Visible=false
            root.ClipsDescendants=true
            Anim.T(root,{Size=UDim2.fromOffset(wW,TBH)},TH.Med)
        else
            Anim.T(root,{Size=UDim2.fromOffset(wW,wH)},TH.Med)
            task.delay(0.24,function()
                root.ClipsDescendants=false
                tbm.Visible=true  -- restaura mascara para a juncao reta com tabBand
            end)
        end
    end)
    closeBtn.MouseButton1Click:Connect(function()
        CloseDD()
        minimized = false
        tbm.Visible = false
        root.ClipsDescendants = true
        Anim.T(root,{Size=UDim2.fromOffset(wW,0),BackgroundTransparency=1},TH.Med)
        task.delay(0.28,function() root.Visible=false end)
    end)
    -- Open animation
    Anim.T(root,{Size=UDim2.fromOffset(wW,wH),BackgroundTransparency=0},TH.Elastic)
    local wAPI={}
    function wAPI:CreateTab(o) return tabSys:AddTab(o) end
    function wAPI:Notify(o)    Notif.Send(o) end
    function wAPI:Show()
        minimized = false
        tbm.Visible = false
        root.ClipsDescendants = true
        root.Visible = true
        Anim.T(root,{Size=UDim2.fromOffset(wW,wH),BackgroundTransparency=0},TH.Elastic)
        task.delay(0.50, function()
            root.ClipsDescendants = false
            tbm.Visible = true
        end)
    end
    function wAPI:Hide()
        CloseDD()
        tbm.Visible = false
        root.ClipsDescendants = true
        Anim.T(root,{Size=UDim2.fromOffset(wW,0),BackgroundTransparency=1},TH.Med)
        task.delay(0.28,function() root.Visible=false end)
    end
    return wAPI,root
end

-- ═══════════════════════════════════════════════════════════════
--  LIBRARY
-- ═══════════════════════════════════════════════════════════════
local Library={Icons=Icons}
Library._sg=nil; Library._inited=false; Library._wins={}; Library._float=nil

function Library:_Init()
    if self._inited then return end; self._inited=true
    local old=CoreGui:FindFirstChild("_NexusUI"); if old then old:Destroy() end
    local sg=Instance.new("ScreenGui"); sg.Name="_NexusUI"; sg.ResetOnSpawn=false
    sg.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; sg.DisplayOrder=9990
    sg.IgnoreGuiInset=true; sg.Parent=CoreGui
    self._sg=sg; _OV=sg; Notif.Init(sg)
end
function Library:SetTheme(o) for k,v in pairs(o) do TH[k]=v end end
function Library:SetAccent(name)
    ApplyAccent(name)
end
function Library:GetAccent()
    return _currentPalName
end
function Library:CreateWindow(opts)
    self:_Init()
    local api,root=BuildWindow(opts,self._sg)
    table.insert(self._wins,{api=api,root=root}); return api
end
function Library:SetToggleIcon(iconNameOrId)
    self:_Init()
    if self._float then self._float:Destroy(); self._float=nil end
    local wins=self._wins
    self._float=FloatBtn(self._sg,iconNameOrId,function(vis)
        for _,w in ipairs(wins) do if vis then w.api:Show() else w.api:Hide() end end
    end)
end
function Library:Notify(o) self:_Init(); Notif.Send(o) end
function Library:Destroy()
    if self._sg then self._sg:Destroy() end
    self._sg=nil; self._inited=false; self._wins={}; self._float=nil
end
return Library
