local okNeo, neoSource = pcall(function()
    return readfile and readfile("bunny.lua")
end)
if okNeo and type(neoSource)=="string" and #neoSource>0 and type(loadstring)=="function" then
    local okRun, errRun = pcall(function() loadstring(neoSource)() end)
    if okRun then
        return
    else
        warn("KyroDev ui error: ", errRun)
    end
end
local okCore, coreSource = pcall(function()
    return readfile and readfile("neo_core.lua")
end)
if okCore and type(coreSource)=="string" and #coreSource>0 and type(loadstring)=="function" then
    local okLoad, errLoad = pcall(function() loadstring(coreSource)() end)
    if not okLoad then
        warn("neo_core error: ", errLoad)
    end
end

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local existingGui = playerGui:FindFirstChild("KyroDev") or playerGui:FindFirstChild("KyroDevNeo")
if existingGui then existingGui:Destroy() end

local accent = Color3.fromRGB(0,255,180)
local accent2 = Color3.fromRGB(80,200,255)
local baseBg = Color3.fromRGB(10,10,16)
local fps = 9000
local frameMs = 16
local cpuMs = 16
local animaciones_gordodemierda = true
local SHOW_OVERLAY = false

local function new(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        if k == "Parent" then obj.Parent = v else obj[k] = v end
    end
    return obj
end

local function animateStroke(stroke)
    task.spawn(function()
        local h = 0
        while stroke.Parent do
            h = (h + 0.002) % 1
            local c1 = Color3.fromHSV(h, 0.9, 1)
            local c2 = Color3.fromHSV((h+0.5)%1, 0.9, 1)
            stroke.Color = c1
            task.wait(0.05)
        end
    end)
end

local function addNeonEffect(btn)
    btn.AutoButtonColor = false
    local originalColor = btn.BackgroundColor3
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.2),{BackgroundColor3=Color3.new(1,1,1), BackgroundTransparency=0.8}):Play()
        local glow = new("UIStroke",{Parent=btn,Color=accent2,Thickness=2,Transparency=0.5,Name="Glow"})
        TweenService:Create(glow,TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,{Repeats=-1,Reverse=true}),{Transparency=0.1,Thickness=3}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn,TweenInfo.new(0.3),{BackgroundColor3=originalColor, BackgroundTransparency=0}):Play()
        local g = btn:FindFirstChild("Glow")
        if g then g:Destroy() end
    end)
end

local function round(obj, r)
    new("UICorner", {Parent=obj, CornerRadius=UDim.new(0,r)})
end

local function makeDraggable(frame, handle)
    local dragging=false
    local dragInput
    local startPos
    local startInputPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            startPos=frame.Position
            startInputPos=input.Position
            dragInput=input
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            dragInput=input
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input==dragInput then
            local delta=input.Position-startInputPos
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
end

local function notify(text)
    local n = new("Frame", {
        Parent = playerGui,
        Size = UDim2.fromOffset(340,50),
        Position = UDim2.new(0.5,-170,1,-110),
        BackgroundColor3 = baseBg
    })
    round(n,10)
    new("UIStroke",{Parent=n,Color=accent,Thickness=1.4,Transparency=0.3})
    local lbl = new("TextLabel", {
        Parent = n,
        Size = UDim2.fromScale(1,1),
        BackgroundTransparency = 1,
        Text = text,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextColor3 = Color3.new(1,1,1)
    })
    TweenService:Create(n,TweenInfo.new(0.25),{Position=UDim2.new(0.5,-170,1,-140)}):Play()
    task.delay(2.4,function()
        TweenService:Create(n,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play()
        TweenService:Create(lbl,TweenInfo.new(0.2),{TextTransparency=1}):Play()
        task.delay(0.22,function() n:Destroy() end)
    end)
end

local gui = new("ScreenGui", {
    Parent = playerGui,
    Name = "KenyahSence",
    IgnoreGuiInset = true,
    ResetOnSpawn = false
})

local overlay = new("Frame",{Parent=gui,Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=1,Visible=false})

local dockIcon = new("Frame",{
    Parent = gui,
    Size = UDim2.fromOffset(46,46),
    Position = UDim2.new(1,-58,0,86),
    BackgroundColor3 = Color3.fromRGB(14,14,24),
    Visible = true
})
round(dockIcon,23)
local dockStroke = new("UIStroke",{Parent=dockIcon,Color=accent2,Thickness=1.2,Transparency=0.3})
local dockBtn = new("TextButton",{Parent=dockIcon,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="◎",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=accent2})

local container = new("Frame", {
    Parent = gui,
    Size = UDim2.fromOffset(360,400),
    Position = UDim2.new(0.5,-180,0.5,-200),
    BackgroundColor3 = baseBg,
    Visible=false
})
round(container,16)
local mainStroke = new("UIStroke",{Parent=container,Color=accent2,Thickness=2,Transparency=0.2})
local strokeGrad = new("UIGradient",{Parent=mainStroke,Rotation=45,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(0,255,200)),ColorSequenceKeypoint.new(0.5,Color3.fromRGB(0,100,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(200,0,255))})})
task.spawn(function()
    while container.Parent do
        strokeGrad.Rotation = (strokeGrad.Rotation + 2) % 360
        task.wait(0.05)
    end
end)

new("UIGradient",{Parent=container,Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(16,20,28)),ColorSequenceKeypoint.new(1,Color3.fromRGB(28,16,36))})})

-- Texture Pattern
local pattern = new("ImageLabel",{Parent=container,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image="rbxassetid://6071575925",ImageTransparency=0.96,ScaleType=Enum.ScaleType.Tile,TileSize=UDim2.fromOffset(50,50),ZIndex=0})


local header = new("Frame",{Parent=container,Size=UDim2.new(1,0,0,40),BackgroundColor3=Color3.fromRGB(14,14,24)})
round(header,16)
local title = new("TextLabel",{Parent=header,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Text="$ - Kenyah Sence - $",Font=Enum.Font.GothamBold,TextSize=15,TextColor3=accent2})
local closeBtn = new("TextButton",{Parent=header,Size=UDim2.fromOffset(22,22),Position=UDim2.new(1,-28,0,7),BackgroundColor3=Color3.fromRGB(18,18,30),Text="✕",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=accent2})
round(closeBtn,6)
local minimizeBtn = new("TextButton",{Parent=header,Size=UDim2.fromOffset(22,22),Position=UDim2.new(1,-56,0,9),BackgroundColor3=Color3.fromRGB(18,18,30),Text="—",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=accent2})
round(minimizeBtn,6)

local body = new("Frame",{Parent=container,Position=UDim2.new(0,0,0,40),Size=UDim2.new(1,0,1,-40),BackgroundTransparency=1})
local sidebar = new("Frame",{Parent=body,Size=UDim2.new(0,76,1,0),BackgroundColor3=Color3.fromRGB(16,16,28)})
round(sidebar,12)
local content = new("Frame",{Parent=body,Position=UDim2.new(0,82,0,0),Size=UDim2.new(1,-88,1,0),BackgroundTransparency=1})

local tabFF = new("TextButton",{Parent=sidebar,Size=UDim2.new(1,-10,0,28),Position=UDim2.new(0,5,0,8),BackgroundColor3=Color3.fromRGB(22,22,36),Text="Flags",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1)})
round(tabFF,8)
addNeonEffect(tabFF)
local tabSettings = new("TextButton",{Parent=sidebar,Size=UDim2.new(1,-10,0,28),Position=UDim2.new(0,5,0,40),BackgroundColor3=Color3.fromRGB(22,22,36),Text="Config",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1)})
round(tabSettings,8)
addNeonEffect(tabSettings)
local tabCredits = new("TextButton",{Parent=sidebar,Size=UDim2.new(1,-10,0,28),Position=UDim2.new(0,5,0,72),BackgroundColor3=Color3.fromRGB(22,22,36),Text="Info",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1)})
round(tabCredits,8)
addNeonEffect(tabCredits)

local pageFF = new("Frame",{Parent=content,Size=UDim2.fromScale(1,1),BackgroundTransparency=1})
local pageSettings = new("Frame",{Parent=content,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})
local pageCredits = new("Frame",{Parent=content,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false})

local ffBox = new("TextBox",{Parent=pageFF,Position=UDim2.new(0,6,0,8),Size=UDim2.new(1,-12,1,-130),MultiLine=true,ClearTextOnFocus=false,TextWrapped=true,Font=Enum.Font.Gotham,TextSize=12,BackgroundColor3=Color3.fromRGB(20,20,34),TextColor3=Color3.new(1,1,1),PlaceholderText="Pega JSON aquí..."})
round(ffBox,8)
ffBox.Text = ""
local bufferInfo = new("TextLabel",{Parent=pageFF,Position=UDim2.new(0,6,1,-86),Size=UDim2.new(1,-12,0,14),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=accent2,Text="Texto 0 KB"})
ffBox:GetPropertyChangedSignal("Text"):Connect(function()
    local t = ffBox.Text or ""
    bufferInfo.Text = ("Texto %.1f KB"):format(#t/1024)
end)

local progressBg = new("Frame",{Parent=pageFF,Size=UDim2.new(1,-12,0,8),Position=UDim2.new(0,6,1,-60),BackgroundColor3=Color3.fromRGB(26,26,42)})
round(progressBg,4)
local progressFill = new("Frame",{Parent=progressBg,Size=UDim2.new(0,0,1,0),BackgroundColor3=accent2})
round(progressFill,4)
local progressText = new("TextLabel",{Parent=pageFF,Position=UDim2.new(0,6,1,-50),Size=UDim2.new(1,-12,0,14),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=10,TextColor3=accent2,Text="0%"})
local statusBadge = new("TextLabel",{Parent=pageFF,Position=UDim2.new(0,6,1,-60),Size=UDim2.new(0,100,0,14),BackgroundTransparency=1,Text="Listo",Font=Enum.Font.GothamBold,TextSize=10,TextColor3=accent2,Visible=false}) -- Oculto por defecto para limpiar UI

local pauseBtn = new("TextButton",{Parent=pageFF,Size=UDim2.new(0.5,-8,0,24),Position=UDim2.new(0,6,1,-30),BackgroundColor3=Color3.fromRGB(26,24,40),Text="Pause",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=accent2})
round(pauseBtn,6)
addNeonEffect(pauseBtn)
local cancelBtn = new("TextButton",{Parent=pageFF,Size=UDim2.new(0.5,-8,0,24),Position=UDim2.new(0.5,2,1,-30),BackgroundColor3=Color3.fromRGB(26,24,40),Text="Cancel",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=accent2})
round(cancelBtn,6)
addNeonEffect(cancelBtn)
local sanitizeBtn = new("TextButton",{Parent=pageFF,Size=UDim2.new(0.5,-8,0,24),Position=UDim2.new(0,6,1,-4),BackgroundColor3=Color3.fromRGB(30,26,46),Text="Sanitize",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=accent2})
round(sanitizeBtn,6)
addNeonEffect(sanitizeBtn)
local injectBtn = new("TextButton",{Parent=pageFF,Size=UDim2.new(0.5,-8,0,24),Position=UDim2.new(0.5,2,1,-4),BackgroundColor3=accent2,Text="Inject",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(0,0,0)})
round(injectBtn,6)
addNeonEffect(injectBtn)

local perfOverlay = new("Frame",{Parent=gui,Size=UDim2.fromOffset(170,76),Position=UDim2.new(1,-190,0,24),BackgroundColor3=Color3.fromRGB(16,16,28),Visible=false})
round(perfOverlay,10)
local perfStroke = new("UIStroke",{Parent=perfOverlay,Color=accent2,Thickness=1.2,Transparency=0.3})
local perfText = new("TextLabel",{Parent=perfOverlay,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=accent2,Text="FPS 0\nCPU 0.0 ms | GPU 0.0 ms"})
local perfClose = new("TextButton",{Parent=perfOverlay,Size=UDim2.fromOffset(24,24),Position=UDim2.new(1,-28,0,4),BackgroundColor3=Color3.fromRGB(20,20,34),Text="✕",Font=Enum.Font.GothamBold,TextSize=14,TextColor3=accent2})
round(perfClose,6)
perfClose.MouseButton1Click:Connect(function()
    SHOW_OVERLAY=false
    perfOverlay.Visible=false
end)
makeDraggable(perfOverlay,perfOverlay)

local function showPage(ff,st,cr)
    pageFF.Visible=ff
    pageSettings.Visible=st
    pageCredits.Visible=cr
end
tabFF.MouseButton1Click:Connect(function() showPage(true,false,false) end)
tabSettings.MouseButton1Click:Connect(function() showPage(false,true,false) end)
tabCredits.MouseButton1Click:Connect(function() showPage(false,false,true) end)

local function addSettingLine(y,text,control)
    new("TextLabel",{Parent=pageSettings,Position=UDim2.new(0,8,0,y),Size=UDim2.new(1,-96,0,24),BackgroundTransparency=1,Text=text,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1),TextXAlignment=Enum.TextXAlignment.Left})
    control.Parent=pageSettings
    control.Position=UDim2.new(1,-88,0,y-2)
end

local overlayToggle=new("TextButton",{Size=UDim2.fromOffset(80,26),BackgroundColor3=Color3.fromRGB(24,24,38),Text="OFF",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1)})
round(overlayToggle,6)
addSettingLine(42,"Mostrar FPS:",overlayToggle)
overlayToggle.MouseButton1Click:Connect(function()
    overlayToggle.Text=(overlayToggle.Text=="OFF") and "ON" or "OFF"
    SHOW_OVERLAY = (overlayToggle.Text=="ON")
    perfOverlay.Visible = SHOW_OVERLAY
end)
local autoSanitizeToggle=new("TextButton",{Size=UDim2.fromOffset(80,26),BackgroundColor3=Color3.fromRGB(24,24,38),Text="OFF",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1)})
round(autoSanitizeToggle,6)
addSettingLine(74,"Auto-sanitizar:",autoSanitizeToggle)
autoSanitizeToggle.MouseButton1Click:Connect(function()
    autoSanitizeToggle.Text=(autoSanitizeToggle.Text=="OFF") and "ON" or "OFF"
    AUTO_SANITIZE_MODE = (autoSanitizeToggle.Text=="ON")
end)
local themeToggle=new("TextButton",{Size=UDim2.fromOffset(80,26),BackgroundColor3=Color3.fromRGB(24,24,38),Text="Azul",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1)})
round(themeToggle,6)
addSettingLine(138,"Tema:",themeToggle)
local function applyTheme(name)
    if name=="Verde" then
        accent = Color3.fromRGB(0,255,180)
        accent2 = Color3.fromRGB(80,200,255)
    else
        accent = Color3.fromRGB(0,230,255)
        accent2 = Color3.fromRGB(0,180,255)
    end
    perfText.TextColor3 = accent2
    perfStroke.Color = accent2
    progressFill.BackgroundColor3 = accent2
    mainStroke.Color = accent2
    dockStroke.Color = accent2
    title.TextColor3 = accent2
    injectBtn.BackgroundColor3 = accent2
end
themeToggle.MouseButton1Click:Connect(function()
    themeToggle.Text = (themeToggle.Text=="Azul") and "Verde" or "Azul"
    applyTheme(themeToggle.Text)
end)
local cpuBoostDisabledEmitters = {}
local cpuBoostDisabledTrails = {}
local function setCpuBoost(on)
    task.spawn(function()
        if on then
            cpuBoostDisabledEmitters = {}
            cpuBoostDisabledTrails = {}
            for _,o in pairs(workspace:GetDescendants()) do
                if o:IsA("BasePart") then o.Material=Enum.Material.Plastic o.Reflectance=0 end
                if o:IsA("ParticleEmitter") and o.Enabled then table.insert(cpuBoostDisabledEmitters,o) o.Enabled=false end
                if o:IsA("Trail") and o.Enabled then table.insert(cpuBoostDisabledTrails,o) o.Enabled=false end
            end
            notify("CPU Boost ON")
        else
            for _,e in ipairs(cpuBoostDisabledEmitters) do if e and e.Parent then e.Enabled=true end end
            for _,t in ipairs(cpuBoostDisabledTrails) do if t and t.Parent then t.Enabled=true end end
            cpuBoostDisabledEmitters = {}
            cpuBoostDisabledTrails = {}
            notify("CPU Boost OFF")
        end
    end)
end
local cpuToggle=new("TextButton",{Size=UDim2.fromOffset(80,26),BackgroundColor3=Color3.fromRGB(24,24,38),Text="OFF",Font=Enum.Font.GothamBold,TextSize=12,TextColor3=Color3.new(1,1,1)})
round(cpuToggle,6)
addSettingLine(106,"CPU Boost:",cpuToggle)
cpuToggle.MouseButton1Click:Connect(function()
    cpuToggle.Text=(cpuToggle.Text=="OFF") and "ON" or "OFF"
    setCpuBoost(cpuToggle.Text=="ON")
end)
pauseBtn.MouseButton1Click:Connect(function()
    if not injectionState.running then return end
    injectionState.paused = not injectionState.paused
    pauseBtn.Text = injectionState.paused and "Resume" or "Pause"
end)
cancelBtn.MouseButton1Click:Connect(function()
    if not injectionState.running then return end
    injectionState.cancel = true
end)

new("TextLabel",{Parent=pageCredits,Position=UDim2.new(0,16,0,18),Size=UDim2.new(1,-32,0,120),BackgroundTransparency=1,Text="KenyahSenceNeo\n\nOwner: @0_kenyah\nLead Devs: @0_kenyah",Font=Enum.Font.GothamBold,TextSize=16,TextColor3=accent2})

local function openUI()
    container.Visible=true
    if animaciones_gordodemierda then
        overlay.Visible=true
        overlay.BackgroundTransparency=1
        TweenService:Create(overlay,TweenInfo.new(0.25),{BackgroundTransparency=0.35}):Play()
        if UserInputService.TouchEnabled then
            container.Size=UDim2.fromOffset(340,380)
            sidebar.Size=UDim2.new(0,80,1,0)
            content.Position=UDim2.new(0,86,0,0)
            content.Size=UDim2.new(1,-92,1,0)
            dockIcon.Position = UDim2.new(1,-50,0,80)
        else
            container.Size=UDim2.fromOffset(360,420)
            sidebar.Size=UDim2.new(0,84,1,0)
            content.Position=UDim2.new(0,90,0,0)
            content.Size=UDim2.new(1,-96,1,0)
            dockIcon.Position = UDim2.new(1,-50,0,80)
        end
        container.BackgroundTransparency=1
        if UserInputService.TouchEnabled then
            TweenService:Create(container,TweenInfo.new(0.36,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(360,400),BackgroundTransparency=0}):Play()
        else
            TweenService:Create(container,TweenInfo.new(0.36,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.fromOffset(400,440),BackgroundTransparency=0}):Play()
        end
    else
        overlay.Visible=false
        if UserInputService.TouchEnabled then
            container.Size=UDim2.fromOffset(360,400)
        else
            container.Size=UDim2.fromOffset(400,440)
        end
    end
    dockIcon.Visible=false
end

local function closeUI()
    if animaciones_gordodemierda then
        TweenService:Create(container,TweenInfo.new(0.22,Enum.EasingStyle.Sine,Enum.EasingDirection.In),{Size=UDim2.fromOffset(280,300),BackgroundTransparency=1}):Play()
        TweenService:Create(overlay,TweenInfo.new(0.2),{BackgroundTransparency=1}):Play()
        task.delay(0.22,function()
            overlay.Visible=false
            container.Visible=false
        end)
    else
        overlay.Visible=false
        container.Visible=false
    end
    dockIcon.Visible=true
end
closeBtn.MouseButton1Click:Connect(closeUI)>

minimizeBtn.MouseButton1Click:Connect(closeUI)
container.Active = true
container.Selectable = true 
makeDraggable(container, container)
openUI()
dockBtn.MouseButton1Click:Connect(openUI)

local FLAG_DELAY  = 0.002
local FAST_MODE   = false
local ALLOW_UNSAFE = false
local ALLOW_BIG_INT = false
local ALLOW_LONG_STRING = false
local UI_THROTTLE = 3
local injectionState = {running=false, paused=false, cancel=false}
local AUTO_SANITIZE_MODE = false
local crash_guard_activadoputo = true
local HISTORY_FILE = "NeoHistory.json"
local history = {}
local function loadHistory()
    local ok, s = pcall(function() return readfile and readfile(HISTORY_FILE) end)
    if ok and type(s)=="string" and #s>0 then
        local okj, tbl = pcall(function() return HttpService:JSONDecode(s) end)
        if okj and type(tbl)=="table" then history = tbl end
    end
end
local function saveHistory()
    local ok, s = pcall(function() return writefile and writefile(HISTORY_FILE, HttpService:JSONEncode(history)) end)
    return ok
end
local function pushHistory(kind, value)
    table.insert(history, 1, {kind=kind, value=value, t=tick()})
    while #history > 25 do table.remove(history) end
    saveHistory()
end

local prefixes = {"DFFlag","FFlag","SFFlag","DFInt","FInt","DFString","FString","FLog"}
local unsafePatterns = {"runtime","taskscheduler","targetfps","frametime","bandwidth","compression","crash","oom","memory","preload","preloading","http","network","thread","maxparallel","maxnum","worstcase"}
local categoryPatterns = {
    network = {"RakNet","Network","Packet","Bandwidth","Ping","Socket","Mtu","Latency"},
    physics = {"Sim","Physics","Solver","Humanoid","Ragdoll","Aerodynamics","Collision","CSG3DCD"},
    telemetry = {"Telemetry","Analytics","Crash","PerfData","Lightstep","HttpPoints","Report"},
    rendering = {"Render","Lighting","Shadow","CSG","SSAOMip","Texture","Anisotropic","GlobalIllumination"},
    audio = {"Audio","VoiceChat","Sound","Emitter","Panner"}
}
local ignoreCategories = {network=false, physics=false, telemetry=false, rendering=false, audio=false}

local function setMaxFrameTime(sizeBytes)
    
    sizeBytes = math.max(0, math.min(sizeBytes, INT_MAX_SAFE))

    if FAST_MODE then
        if sizeBytes >= 65000 then
            MAX_FRAME_TIME = 0.006
        else
            MAX_FRAME_TIME = 0.008
        end
    else
        if sizeBytes >= 65000 then
            MAX_FRAME_TIME = 0.003
        else
            MAX_FRAME_TIME = 0.004
        end
    end
end

local INT_MAX_SAFE = 2000000
local INT_MAX_ABS  = 2147483647
local function isLogOrDebug(k)
    local lk = tostring(k):lower()
    return tostring(k):sub(1,4)=="FLog" or lk:find("debug") or lk:find("log")
end
local function isHeavyKey(k)
    local lk = tostring(k):lower()
    return lk:find("datasender") or lk:find("bandwidth") or lk:find("maxdatapacketpersend") or lk:find("taskschedulertargetfps") or lk:find("assetpreloading") or lk:find("teleportclientassetpreloading") or lk:find("raknetuseslidingwindow") or lk:find("clientpacket")
end
local Support = {
    setfflag   = type(setfflag)   == "function",
    setfint    = type(setfint)    == "function",
    setfstring = type(setfstring) == "function",
}

local function stripPrefix(flag)
    for _, p in ipairs(prefixes) do
        if flag:sub(1,#p) == p then
            return flag:sub(#p+1)
        end
    end
    return flag
end

local function safeSetter(key, value)
    local pref = nil
    for _,p in ipairs(prefixes) do
        if key:sub(1,#p) == p then
            pref = p
            break
        end
    end
    if not ALLOW_UNSAFE then
        local lk = key:lower()
        for _,pat in ipairs(unsafePatterns) do
            if lk:find(pat) then
                return false, "Saltado por seguridad ("..pat..")"
            end
        end
    end
    local name = stripPrefix(key)
    local vstr = tostring(value)
    local isLD = isLogOrDebug(key)
    if pref and pref:find("Int") then
        local n = tonumber(vstr)
        if not n then return false, "Valor entero inválido" end
        if not ALLOW_BIG_INT and not isLD then
            if math.abs(n) > 100000 then
                return false, "Entero grande saltado"
            end
        else
            local maxAbs = isLD and INT_MAX_ABS or INT_MAX_SAFE
            if n >  maxAbs then n =  maxAbs end
            if n < -maxAbs then n = -maxAbs end
        end
        if Support.setfint then
            local ok,err = pcall(function() setfint(name, math.floor(n)) end)
            if ok then return true, nil end
            local ok2,err2 = pcall(function() setfint(key, math.floor(n)) end)
            if ok2 then return true, nil end
        end
        if Support.setfflag then
            local ok3,err3 = pcall(function() setfflag(key, tostring(math.floor(n))) end)
            if ok3 then return true, nil end
            local ok4,err4 = pcall(function() setfflag(name, tostring(math.floor(n))) end)
            if ok4 then return true, nil end
        end
        return false, "Executor sin setfint/setfflag"
    elseif pref and pref:find("Flag") then
        local l = vstr:lower()
        local b = (l=="true" or l=="1" or l=="yes") and "True" or ((l=="false" or l=="0" or l=="no") and "False" or vstr)
        if not Support.setfflag then
            return false, "Executor sin setfflag"
        end
        local ok,err = pcall(function() setfflag(key, b) end)
        if ok then return true, nil end
        local ok2,err2 = pcall(function() setfflag(name, b) end)
        return ok2, ok2 and nil or tostring(err2)
    else
        local maxLen = isLD and 4096 or 512
        if not ALLOW_LONG_STRING and #vstr > maxLen then
            vstr = vstr:sub(1, maxLen)
        end
        if Support.setfstring then
            local ok,err = pcall(function() setfstring(key, vstr) end)
            if ok then return true, nil end
            local ok2,err2 = pcall(function() setfstring(name, vstr) end)
            if ok2 then return true, nil end
        end
        if Support.setfflag then
            local ok3,err3 = pcall(function() setfflag(key, vstr) end)
            if ok3 then return true, nil end
            local ok4,err4 = pcall(function() setfflag(name, vstr) end)
            if ok4 then return true, nil end
        end
        return false, "Executor sin setfstring/setfflag"
    end
end

local function resolveInput(text)
    local t = text:match("^%s*(.-)%s*$")
    t = t:gsub("#L%d+%-?%d*$","")
    if t:lower():sub(-5) == ".json" then
        local ok,content = pcall(function() return readfile and readfile(t) end)
        if ok and type(content)=="string" and #content>0 then
            return content
        end
    end
    return text
end

local function parsePairsFallback(text)
    local tbl = {}
    local cleanText = text:gsub("//[^\n]*",""):gsub("/%*.-%*/","")
    
    for line in cleanText:gmatch("[^\r\n]+") do
        local l = line:gsub("[,%s]*$","") 
        local k,v
    
        k,v = l:match('"%s*(.-)%s*"%s*:%s*"%s*(.-)%s*"')
        if not k then
            k,v = l:match('^%s*([%w_%-]+)%s*:%s*(.+)%s*$')
        end

        if not k then
             local kk,vv = l:match("^%s*([^=%s]+)%s*=%s*(.+)%s*$")
             if kk then k,v = kk, vv end
        end
        
        if k and v then
            local vClean = v:match('^"(.+)"$') or v:match("^'(.+)'$") or v
            tbl[k] = vClean
        end
    end
    local count = 0
    for _ in pairs(tbl) do count += 1 end
    if count > 0 then return tbl end
    return nil
end

local function sanitizeValue(key, v)
    local s = tostring(v)
    local lk = key:lower()
    if isLogOrDebug(key) then
        return s
    end
    if crash_guard_activadoputo then
        if lk:find("taskschedulertargetfps") then return "240" end
        if lk:find("assetpreloading") then return "0" end
        if lk:find("numassetsmaxtopreload") then return "1000" end
        if lk:find("maxdatapacketpersend") then
            local n = tonumber(s) or 65536
            if n > 65536 then return "65536" end
        end
        if lk:find("datasendermaxbandwidthbps") then
            local n = tonumber(s) or 2000000
            if n > 2000000 then return "2000000" end
        end
        if lk:find("startinitspeed") then
            local n = tonumber(s) or 10000
            if n > 10000 then return "10000" end
        end
        if lk:find("minrtt") then
            local n = tonumber(s) or 10
            if n < 10 then return "10" end
        end
        if lk:find("waitms") or lk:find("delayms") or lk:find("loopms") or lk:find("interval") or lk:find("timeout") or lk:find("timer") or lk:find("millisecond") then
            local n = tonumber(s) or 10
            if n < 10 then return "10" end
        end
        if lk:find("rate") or lk:find("frequency") then
            local n = tonumber(s) or 1
            if n < 1 then return "1" end
        end
        if lk:find("cache") and lk:find("size") then
            local n = tonumber(s) or 4096
            if n > 4096 then return "4096" end
        end
        if lk:find("clientpacket") and lk:find("delay") then
            local n = tonumber(s) or 10
            if n < 5 then return "5" end
        end
        if lk:find("hundredths") or lk:find("hundreths") or lk:find("hundredth") or lk:find("percent") or lk:find("percentage") then
            local n = tonumber(s) or 0
            if n < 0 then n = 0 end
            if n > 10000 then n = 10000 end
            return tostring(n)
        end
        if s == "null" then return "" end
    end
    for _,pat in ipairs(unsafePatterns) do
        if lk:find(pat) then
            if lk:find("flag") then return "False" end
            if lk:find("int") then
                if lk:find("targetfps") then return "60" end
                if lk:find("frame") or lk:find("microsecond") or lk:find("milliseconds") then return "16" end
                return "0"
            end
            return "False"
        end
    end
    for _,p in ipairs(prefixes) do
        if key:sub(1,#p)==p then
            if p:find("Flag") then
                local l = s:lower()
                if l=="true" or l=="1" or l=="yes" then return "True" end
                if l=="false" or l=="0" or l=="no" then return "False" end
                return s
            elseif p:find("Int") then
                local n = tonumber(s)
                if not n then return "0" end
                if lk:find("targetfps") then n = 60 end
                if math.abs(n) > 20000 then n = 20000 end
                return tostring(math.floor(n))
            else
                if #s > 512 then s = s:sub(1,512) end
                return s
            end
        end
    end
    return s
end

local function preSanitizeAll(data)
    local out = {}
    local sanitized = 0
    local blocked = 0
    for k,v in pairs(data) do
        local lk = tostring(k):lower()
        if crash_guard_activadoputo and lk:find("runtime") then
            blocked += 1
        else
            local sv = sanitizeValue(k,v)
            if tostring(sv) ~= tostring(v) then sanitized += 1 end
            out[k] = sv
        end
    end
    return out, sanitized, blocked
end

local function tryInjectWithFallback(key, value)
    if crash_guard_activadoputo then
        local lk = key:lower()
        if lk:find("runtime") then
            injectionState.blocked = (injectionState.blocked or 0) + 1
            return false, "Bloqueado por guardia: runtime"
        end
    end
    if AUTO_SANITIZE_MODE then
        local sv = sanitizeValue(key, value)
        local ok1, err1 = safeSetter(key, sv)
        if ok1 then return true, nil end
    else
        local ok, err = safeSetter(key, value)
        if ok then return true, nil end
    end
    
    local vstr = tostring(value):lower()
    local name = stripPrefix(key)
    
    if vstr=="true" or vstr=="1" or vstr=="yes" or vstr=="on" then
        if Support.setfflag then
            local ok, err = pcall(function() setfflag(name, "True") end)
            if ok then return true, nil end
        end
    elseif vstr=="false" or vstr=="0" or vstr=="no" or vstr=="off" then
        if Support.setfflag then
            local ok, err = pcall(function() setfflag(name, "False") end)
            if ok then return true, nil end
        end
    end
    
    local n = tonumber(value)
    if n and Support.setfint then
        local ok, err = pcall(function() setfint(name, math.floor(n)) end)
        if ok then return true, nil end
    end
    
    if Support.setfstring then
         local ok, err = pcall(function() setfstring(name, tostring(value)) end)
         if ok then return true, nil end
    end
    
    if not AUTO_SANITIZE_MODE then
        local sv = sanitizeValue(key, value)
        local ok2, err2 = safeSetter(key, sv)
        if ok2 then injectionState.sanitized = (injectionState.sanitized or 0) + 1 end
        return ok2, ok2 and nil or (err2)
    end
    
    return false, "Fallaron todos los métodos"
end

local function groupFlags(data)
    local seen = {}
    local ints, flags, strings = {}, {}, {}
    for k,v in pairs(data) do
        local catMatch = nil
        for cat, pats in pairs(categoryPatterns) do
            for _,p in ipairs(pats) do
                if tostring(k):find(p) then
                    catMatch = cat
                    break
                end
            end
            if catMatch then break end
        end
        if catMatch and ignoreCategories[catMatch] then
        else
            local name = stripPrefix(k)
            if not seen[name] then
                seen[name] = true
                if k:find("Int") then
                    table.insert(ints, {k, tostring(v)})
                elseif k:find("Flag") then
                    table.insert(flags, {k, tostring(v)})
                else
                    table.insert(strings, {k, tostring(v)})
                end
            end
        end
    end
    local res = {}
    for _,x in ipairs(ints) do table.insert(res,x) end
    for _,x in ipairs(flags) do table.insert(res,x) end
    for _,x in ipairs(strings) do table.insert(res,x) end
    return res
end

local function reorderFlagsList(list)
    local late = {}
    local early = {}
    for _,pair in ipairs(list) do
        local k = pair[1]
        local lk = tostring(k):lower()
        if lk:find("datasender") or lk:find("raknetuseslidingwindow") or lk:find("httpbatch") or lk:find("taskschedulertargetfps") or lk:find("assetpreloading") or lk:find("numassetsmaxtopreload") or lk:find("bandwidth") or lk:find("clientpacket") or lk:find("teleportclientassetpreloading") then
            table.insert(late, pair)
        else
            table.insert(early, pair)
        end
    end
    local res = {}
    for _,p in ipairs(early) do table.insert(res,p) end
    for _,p in ipairs(late) do table.insert(res,p) end
    return res
end

local function assessRisks(data)
    local risk,bigInt,longStr,extreme = 0,0,0,0
    for k,v in pairs(data) do
        local s = tostring(v)
        local lk = k:lower()
        for _,pat in ipairs(unsafePatterns) do
            if lk:find(pat) then
                risk += 1
                break
            end
        end
        for _,p in ipairs(prefixes) do
            if k:sub(1,#p)==p then
                if p:find("Int") then
                    local n = tonumber(s)
                    if not n then
                        bigInt += 1
                    else
                        if math.abs(n) > 100000 then bigInt += 1 end
                        if math.abs(n) > 1000000 then extreme += 1 end
                    end
                elseif p=="DFString" or p=="FString" or p=="FLog" then
                    if #s > 512 then longStr += 1 end
                end
                break
            end
        end
    end
    return {risk=risk,bigInt=bigInt,longStr=longStr,extreme=extreme}
end

local function injectFastFlags(text)
    local src = resolveInput(text)
    local sizeBytes = #src
    if sizeBytes > 66560 then
        notify("Entrada supera 65 KB")
        injectBtn.Text="Inject Fastflags"
        injectBtn.Active=true
        return
    end
    local data
    local preferFallback = sizeBytes >= 2147483647
    local ok,tmp=pcall(function() return (not preferFallback) and HttpService:JSONDecode(src) or nil end)
    if preferFallback or not ok or type(tmp)~="table" then
        local fb = parsePairsFallback(src)
        if fb then
            data = fb
        else
            notify("JSON inválido o formato no reconocido")
            injectBtn.Text="Inject Fastflags"
            injectBtn.Active=true
            return
        end
    else
        data = tmp
    end
    if crash_guard_activadoputo then
        local outSanitized, preSanitCount, preBlocked = preSanitizeAll(data)
        injectionState.sanitized = (injectionState.sanitized or 0) + preSanitCount
        injectionState.blocked = (injectionState.blocked or 0) + preBlocked
        progressText.Text = ("Modo protegido: sanitizadas %d, bloqueadas %d"):format(preSanitCount, preBlocked)
        data = outSanitized
    end
    local counts
    if getgenv().Neo and getgenv().Neo.Validator and getgenv().Neo.Validator.scan then
        counts = getgenv().Neo.Validator.scan(data)
    else
        counts = assessRisks(data)
    end
    local tooAggressive = (counts.risk >= 20) or (counts.extreme >= 5) or (counts.bigInt >= 30) or (counts.longStr >= 30)
    if tooAggressive and not ALLOW_UNSAFE then
        local msg = ("FF exagerada: riesgos %d, enteros grandes %d, strings largas %d"):format(counts.risk,counts.bigInt,counts.longStr)
        progressText.Text = msg
        notify(msg.." | Inyectando con modo seguro y fallback")
    end
    local flags = groupFlags(data)
    flags = reorderFlagsList(flags)
    local total = #flags
    local done = 0
    local successCount = 0
    local failures = {}
    local skippedInvalid = 0
    task.spawn(function()
        local okThread, threadErr = pcall(function()
            injectionState.running = true
            injectionState.cancel = false
            local idx = 1
            local perFrame
            if getgenv().Neo and getgenv().Neo.RateController then
                local failRate = (#failures>0 and math.min(#failures/total,1)) or 0
                local sfps = getgenv().Neo.State.fps or fps
                perFrame = getgenv().Neo.RateController.rate(sizeBytes,total,sfps,failRate,FAST_MODE,tooAggressive)
            else
                perFrame = computeRate(sizeBytes,total)
                if tooAggressive and not FAST_MODE then
                    perFrame = 1
                end
            end
            if tooAggressive and not FAST_MODE then
                perFrame = 1
            end
            progressText.Text = ("Inyectando %d flags..."):format(total)
            statusBadge.Text = "Inyectando..."
            local consecutiveFailures = 0
            local lowFpsStreak = 0
            local MAX_FRAME_TIME
            if sizeBytes >= 65000 then
                MAX_FRAME_TIME = 0.006
            else
                MAX_FRAME_TIME = 0.008
            end
            if FAST_MODE then
                if sizeBytes >= 65000 then
                    MAX_FRAME_TIME = 0.003
                else
                    MAX_FRAME_TIME = 0.004
                end
            end
            
            while idx <= total do
                if injectionState.cancel then break end
                if injectionState.paused then
                    progressText.Text = "Pausado"
                    statusBadge.Text = "Pausado"
                    RunService.Heartbeat:Wait()
                    task.wait(0.1)
                    continue
                end
                
                -- Ajuste dinámico por FPS
                if fps > 65 then
                    MAX_FRAME_TIME = FAST_MODE and 0.009 or 0.005
                elseif fps < 50 then
                    MAX_FRAME_TIME = 0.002
                end
                if fps < 30 then
                    lowFpsStreak += 1
                else
                    lowFpsStreak = math.max(0, lowFpsStreak - 1)
                end
                -- TIME BUDGET LOOP
                local tStart = tick()
                local processedInFrame = 0
                
                while (tick() - tStart) < MAX_FRAME_TIME and idx <= total do
                    local pair = flags[idx]
                    local k, v = pair[1], pair[2]
                    local okItem, errItem = tryInjectWithFallback(k, v)
                    if isHeavyKey(k) then
                        task.wait(0.03)
                    end
                    if processedInFrame % 200 == 0 then
                        task.wait(0.02)
                    end
                    if okItem then
                        successCount += 1
                        consecutiveFailures = 0
                        if getgenv().Neo and getgenv().Neo.Logger then
                            getgenv().Neo.Logger.log("info","OK "..k)
                        end
                    else
                        local emsg = tostring(errItem or "error desconocido")
                        local el = emsg:lower()
                        -- Muchos ejecutores devuelven "invalid flag" para flags que no existen en esta versión.
                        -- Las marcamos como "saltadas" pero no como error crítico.
                        if el:find("invalid flag") or el:find("cannot set") then
                            skippedInvalid += 1
                            if getgenv().Neo and getgenv().Neo.Logger then
                                getgenv().Neo.Logger.log("info","SKIP "..k.." "..emsg)
                            end
                        else
                            consecutiveFailures += 1
                            table.insert(failures, (k..": "..emsg))
                            if getgenv().Neo and getgenv().Neo.Logger then
                                getgenv().Neo.Logger.log("warn","FAIL "..k.." "..emsg)
                            end
                        end
                    end
                    done += 1
                    idx += 1
                    processedInFrame += 1
                end
                
                if consecutiveFailures > 10 then
                    MAX_FRAME_TIME = 0.001 
                    task.wait() 
                elseif consecutiveFailures == 0 and fps > 55 then
                    MAX_FRAME_TIME = FAST_MODE and 0.008 or 0.004
                end
                if lowFpsStreak > 60 then
                    injectionState.paused = true
                    statusBadge.Text = "Protección anticrash (FPS bajos)"
                    notify("Protección anticrash: inyección pausada por FPS < 30")
                    lowFpsStreak = 0
                end
                
                local pct = math.floor(done/total*100)
                progressFill.Size = UDim2.new(done/total,0,1,0)
                progressText.Text = pct.."%"
                if pct==25 or pct==50 or pct==75 or pct==100 then
                    notify(("Inyectadas %d/%d (%d%%)"):format(done,total,pct))
                end
                RunService.Heartbeat:Wait()
            end
        end)
        local msg
        if not okThread then
            msg = "Error de hilo: "..tostring(threadErr)
        else
            msg = ("FFlags inyectadas: %d/%d OK"):format(successCount,total)
            if #failures>0 then
                local sample = table.concat(failures, "; ", 1, math.min(10,#failures))
                msg = msg .. (" | fallidas: %d (%s)"):format(#failures, sample)
            end
            if skippedInvalid>0 then
                msg = msg .. (" | inválidas saltadas: %d"):format(skippedInvalid)
            end
            if injectionState.sanitized then
                msg = msg .. (" | sanitizadas: %d"):format(injectionState.sanitized)
            end
            if injectionState.blocked then
                msg = msg .. (" | bloqueadas: %d"):format(injectionState.blocked)
            end
        end
        injectionState.running = false
        injectionState.paused = false
        progressText.Text = msg
        statusBadge.Text = "Completado"
        notify(msg)
        if getgenv().Neo and getgenv().Neo.Logger then
            getgenv().Neo.Logger.flush("NeoLog.txt")
        end
        injectBtn.Text="Inject Fastflags"
        injectBtn.Active=true
    end)
end

injectBtn.MouseButton1Click:Connect(function()
    injectBtn.Text="Injecting..."
    injectBtn.Active=false
    progressFill.Size = UDim2.new(0,0,1,0)
    progressText.Text = "0%"
    injectionState.running = false
    injectionState.paused = false
    injectionState.cancel = false
    local ok,err = pcall(function() injectFastFlags(ffBox.Text) end)
    if not ok then
        notify("Error al iniciar la inyección")
        injectBtn.Text="Inject Fastflags"
        injectBtn.Active=true
    end
end)

local function sanitizeAndSave(text)
    local src = resolveInput(text)
    local ok,data=pcall(function() return HttpService:JSONDecode(src) end)
    if not ok or type(data)~="table" then
        notify("JSON inválido")
        return
    end
    local out={}
    local count=0
    for k,v in pairs(data) do
        out[k]=sanitizeValue(k,v)
        count+=1
    end
    local encoded = HttpService:JSONEncode(out)
    local name = "KenyahSenceSAFE.json"
    local t = text:match("^%s*(.-)%s*$")
    if t:lower():sub(-5)==".json" then
        name = t:gsub("%.json$","-SAFE.json")
    end
    local okWrite = pcall(function() return writefile and writefile(name, encoded) end)
    if okWrite then
        notify("Guardado: "..name.." ("..#encoded.." bytes)")
    else
        ffBox.Text = encoded
        notify("No se pudo guardar se pegó en el cuadro")
    end
end
satisfyConn = sanitizeBtn.MouseButton1Click:Connect(function()
    sanitizeBtn.Text="Sanitizing..."
    sanitizeBtn.Active=false
    task.spawn(function()
        sanitizeAndSave(ffBox.Text)
        task.delay(0.3,function()
            sanitizeBtn.Text="Sanitize & Save"
            sanitizeBtn.Active=true
        end)
    end)
end)

RunService.RenderStepped:Connect(function(dt)
    fps = math.clamp(math.floor(1/dt),1,240)
    frameMs = math.floor(dt*1000*10)/10
end)
RunService.Heartbeat:Connect(function(dt)
    cpuMs = math.floor(dt*1000*10)/10
end)
task.spawn(function()
    while perfOverlay.Parent do
        local sfps = getgenv().Neo and getgenv().Neo.State.fps or fps
        local scpu = getgenv().Neo and getgenv().Neo.State.cpuMs or cpuMs
        local sfrm = getgenv().Neo and getgenv().Neo.State.frameMs or frameMs
        perfText.Text = ("FPS %d\nCPU %.1f ms | GPU %.1f ms"):format(sfps,scpu,sfrm)
        task.wait(0.25)
    end
end)
