local targetWords = {"https://", "PerformHttpRequest", "GetConvar", "print", "execute", "command", "txAdmin"}
local foundScripts = {}

local Shared = {
    Enable = true,
    DiscordAnnounceDetection = true,
    DiscordWebhook = "", -- dodaj webhook
    ConsolePrint = true,
    StopServer = true,
    BackdoorStrings = {
        "cipher-panel",
        "Enchanced_Tabs",
        "helperServer",
        "ketamin.cc",
        "\x63\x69\x70\x68\x65\x72\x2d\x70\x61\x6e\x65\x6c\x2e\x6d\x65",
        "\x6b\x65\x74\x61\x6d\x69\x6e\x2e\x63\x63",
        "MpWxwQeLMRJaDFLKmxVIFNeVfzVKaTBiVRvjBoePYciqfpJzxjNPIXedbOtvIbpDxqdoJR"
    }
}

local function split(inputstr, sep)
    sep = sep or "%s"
    local t = {}
    for str in inputstr:gmatch("([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

local function logDetection(resource, targetWord, snippet, color)
    print(("^3[script:%s]^7 Found Word: %s"):format(resource, targetWord))
    print(("^5Code Snippet (JSON): %s"):format(json.encode(snippet)))
end

local function scanFile(resourceName, luaFilePath)
    local fileContent = LoadResourceFile(resourceName, luaFilePath)
    if not fileContent then return end

    for lineNum, line in ipairs(split(fileContent, "\n")) do
        for _, targetWord in ipairs(targetWords) do
            if line:find(targetWord) then
                foundScripts[luaFilePath] = true
                logDetection(resourceName, targetWord, line, "yellow")
                break
            end
        end
    end
end

local function scanScriptsForResource(resourceName)
    local numFiles = GetNumResourceMetadata(resourceName, "server_script") or 0
    for j = 0, numFiles - 1 do
        local luaFilePath = GetResourceMetadata(resourceName, "server_script", j)
        if luaFilePath and not foundScripts[luaFilePath] then
            scanFile(resourceName, luaFilePath)
        end
    end
end

local function scanForBackdoors()
    local detectedResources = {}

    for i = 0, GetNumResources() - 1 do
        local resourceName = GetResourceByFindIndex(i)
        if resourceName ~= GetCurrentResourceName() then
            local numFiles = GetNumResourceMetadata(resourceName, 'server_script')
            for j = 0, numFiles - 1 do
                local filePath = GetResourceMetadata(resourceName, 'server_script', j)
                local fileContent = LoadResourceFile(resourceName, filePath)

                if fileContent then
                    for _, backdoorString in ipairs(Shared.BackdoorStrings) do
                        if fileContent:find(backdoorString) then
                            table.insert(detectedResources, {resource = resourceName .. '/' .. filePath, stringFound = backdoorString})
                            break 
                        end
                    end
                end
            end
        end
    end

    return detectedResources
end

local function sendToDiscord(detectedResources)
    if Shared.DiscordWebhook == "" then return end

    local descriptions = ""
    for _, v in ipairs(detectedResources) do
        descriptions = descriptions .. ("**Resource:** %s **Detected String:** %s\n"):format(v.resource, v.stringFound)
    end

    local message = {
        {
            ["color"] = 16711680,
            ["title"] = "Wykryto Backdoora!",
            ["description"] = descriptions,
            ["footer"] = {["text"] = "Developed By Krupowski Studio"}
        }
    }

    PerformHttpRequest(Shared.DiscordWebhook, function(err, text, headers) end, 'POST', json.encode({username = "Anti Backdoor", embeds = message}), {['Content-Type'] = 'application/json'})
end

local function handleBackdoorDetection()
    local detectedResources = scanForBackdoors()

    if #detectedResources > 0 then
        if Shared.ConsolePrint then
            print("^1[DEBUG]^0 Found Backdoor in:")
            for _, v in ipairs(detectedResources) do
                print("^1[DEBUG]^0 Resource: " .. v.resource .. ", Detected String: " .. v.stringFound)
            end
        end

        if Shared.DiscordAnnounceDetection then
            sendToDiscord(detectedResources)
        end

        if Shared.StopServer then
            Citizen.Wait(2000)
            os.exit()
        end
    end
end

-- Triggered when a resource starts
AddEventHandler('onResourceStart', function(res)
    if GetCurrentResourceName() == res and Shared.Enable then
        handleBackdoorDetection()
    end
end)

-- Initial scan on all resources
for i = 0, GetNumResources() - 1 do
    local resourceName = GetResourceByFindIndex(i)
    scanScriptsForResource(resourceName)
end
