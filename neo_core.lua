local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Neo = {}

Neo.State = { fps = 60, frameMs = 16, cpuMs = 16 }

Neo.Perf = {}
Neo.Perf.start = function()
    RunService.RenderStepped:Connect(function(dt)
        Neo.State.fps = math.clamp(math.floor(1/dt),1,240)
        Neo.State.frameMs = math.floor(dt*1000*10)/10
    end)
    RunService.Heartbeat:Connect(function(dt)
        Neo.State.cpuMs = math.floor(dt*1000*10)/10
    end)
end

Neo.Logger = {}
Neo.Logger.buffer = {}
Neo.Logger.max = 1000
Neo.Logger.levels = { debug = 1, info = 2, warn = 3, error = 4 }
Neo.Logger.level = 2
Neo.Logger.log = function(level, msg)
    local lv = Neo.Logger.levels[level] or 2
    if lv < Neo.Logger.level then return end
    local t = os and os.time and os.time() or tick()
    local line = "["..level.."] "..tostring(t).." "..tostring(msg)
    table.insert(Neo.Logger.buffer, line)
    if #Neo.Logger.buffer > Neo.Logger.max then
        table.remove(Neo.Logger.buffer, 1)
    end
end
Neo.Logger.flush = function(filename)
    if not writefile then return false end
    local s = table.concat(Neo.Logger.buffer, "\n")
    local ok = pcall(function() writefile(filename or "NeoLog.txt", s) end)
    return ok
end

Neo.Validator = {}
Neo.Validator.patterns = {
    risk = {"runtime","taskscheduler","targetfps","frametime","bandwidth","compression","crash","oom","memory","preload","preloading","http","network","thread","maxparallel","maxnum","worstcase"},
    intframe = {"frame","microsecond","milliseconds","ms","microseconds"},
}
Neo.Validator.categories = {
    network = {"RakNet","Network","Packet","Bandwidth","Ping","Socket","Mtu","Latency"},
    physics = {"Sim","Physics","Solver","Humanoid","Ragdoll","Aerodynamics","Collision","CSG3DCD"},
    telemetry = {"Telemetry","Analytics","Crash","PerfData","Lightstep","HttpPoints","Report"},
    rendering = {"Render","Lighting","Shadow","CSG","SSAOMip","Texture","Anisotropic","GlobalIllumination"},
    audio = {"Audio","VoiceChat","Sound","Emitter","Panner"},
}
Neo.Validator.clampInt = function(k, n)
    if tostring(k):lower():find("targetfps") then return 60 end
    if tostring(k):lower():find("network") then return math.clamp(n, 0, 100000) end
    if math.abs(n) > 100000 then return 100000 end
    return math.floor(n)
end
Neo.Validator.categorize = function(k)
    for cat, pats in pairs(Neo.Validator.categories) do
        for _,p in ipairs(pats) do
            if tostring(k):find(p) then
                return cat
            end
        end
    end
    return nil
end
Neo.Validator.sanitize = function(k, v)
    local s = tostring(v)
    local lk = tostring(k):lower()
    for _,pat in ipairs(Neo.Validator.patterns.risk) do
        if lk:find(pat) then
            if lk:find("flag") then return "False" end
            if lk:find("int") then
                for _,ip in ipairs(Neo.Validator.patterns.intframe) do
                    if lk:find(ip) then return "16" end
                end
                return "0"
            end
            return "False"
        end
    end
    if lk:find("int") then
        local n = tonumber(s)
        if not n then return "0" end
        return tostring(Neo.Validator.clampInt(k, n))
    end
    if #s > 512 then s = s:sub(1,512) end
    return s
end
Neo.Validator.scan = function(data)
    local risk,bigInt,longStr,extreme = 0,0,0,0
    for k,v in pairs(data) do
        local s = tostring(v)
        local lk = tostring(k):lower()
        for _,pat in ipairs(Neo.Validator.patterns.risk) do
            if lk:find(pat) then
                risk = risk + 1
                break
            end
        end
        if lk:find("int") then
            local n = tonumber(s)
            if not n then
                bigInt = bigInt + 1
            else
                if math.abs(n) > 100000 then bigInt = bigInt + 1 end
                if math.abs(n) > 1000000 then extreme = extreme + 1 end
            end
        else
            if #s > 512 then longStr = longStr + 1 end
        end
    end
    return {risk=risk,bigInt=bigInt,longStr=longStr,extreme=extreme}
end

Neo.Profiles = {}
Neo.Profiles.list = {
    Normal = { maxPerFrame = 3, fastBoost = 2 },
    Seguro = { maxPerFrame = 1, fastBoost = 0 },
    Ultra = { maxPerFrame = 8, fastBoost = 3 },
}
Neo.Profiles.current = "Normal"
Neo.Profiles.set = function(name)
    if Neo.Profiles.list[name] then
        Neo.Profiles.current = name
        return true
    end
    return false
end

Neo.RateController = {}
Neo.RateController.rate = function(bytes,count,fps,failureRate,fastMode,tooAggressive)
    local prof = Neo.Profiles.list[Neo.Profiles.current]
    local base
    if fastMode then
        if bytes >= 30000 or count >= 1200 then base = 3 else
        if bytes >= 20000 or count >= 700 then base = 5 else base = 8 end end
        base = math.min(base + (prof.fastBoost or 0), prof.maxPerFrame or 8)
    else
        if bytes >= 30000 or count >= 1200 then base = 1 else
        if bytes >= 20000 or count >= 700 then base = 2 else base = 3 end end
        base = math.min(base, prof.maxPerFrame or 3)
    end
    if fps < 40 then base = 1 elseif fps < 55 then base = math.max(1, math.floor(base*0.5)) end
    if tooAggressive then base = 1 end
    if failureRate and failureRate > 0.2 then base = math.max(1, math.floor(base*0.5)) end
    return base
end

Neo.Url = {}
Neo.Url.get = function(url)
    local ok, body = pcall(function() return HttpService:GetAsync(url) end)
    if ok and type(body)=="string" then return body end
    return nil
end

getgenv().Neo = Neo
return Neo
