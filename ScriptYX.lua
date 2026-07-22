local success, err = pcall(function()
    -- 🔄 Авто-перезапуск скрипта при телепортации/реконнекте
    local queueteleport = (queue_on_teleport or syn and syn.queue_on_teleport or fluxus and fluxus.queue_on_teleport)
    if queueteleport then
        queueteleport([[
            task.wait(3)
            loadstring(game:HttpGet("https://raw.githubusercontent.com/blegbot1/YXA-UZ-YX/refs/heads/main/ScriptYX.lua"))()
        ]])
    end

    print("[Nexus] Загрузка интерфейса V67 (Anti-AFK + Auto-Reconnect)...")
    local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    
    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local VirtualUser = game:GetService("VirtualUser")
    local VirtualInputManager = game:GetService("VirtualInputManager")
    local TeleportService = game:GetService("TeleportService")
    local CoreGui = game:GetService("CoreGui")

    -- 🛡️ АВТО-РЕКОННЕКТ ПРИ КИКЕ ИЛИ ВЫЛЕТЕ СЕРВЕРА
    pcall(function()
        CoreGui.RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
            if child.Name == "ErrorPrompt" then
                task.spawn(function()
                    while true do
                        TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                        task.wait(2)
                    end
                end)
            end
        end)
    end)

    -- 🛡️ АНТИ-AFK (работает всегда)
    task.spawn(function()
        Players.LocalPlayer.Idled:Connect(function()
            pcall(function()
                VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            end)
        end)
    end)

    local Window = Rayfield:CreateWindow({
       Name = "Smart Farm & Fixes V67",
       LoadingTitle = "Загрузка фармилки...",
       LoadingSubtitle = "by Nexus",
    })

    local autoFarm = false
    local autoSpawnPet = false
    local autoBountyQuest = false
    local autoEmote = false
    local continuousAutoClicker = false 
    local spawnDelay = 0.5
    local collectPriority = "Приоритет: Бойцы"
    local speed = 35 

    local blockSettings = {
        ["Wood Lucky Block"] = false,
        ["Iron Lucky Block"] = false,
        ["Castle Lucky Block"] = false,
        ["Desert Lucky Block"] = false,
        ["Lucky Block"] = false,
        ["Egg Tier 1"] = false,
        ["War Machines Crate"] = false,
    }

    local activeNPCs = {
        ["Normal"] = false,
        ["Bob"] = false,
        ["Shooter"] = false,
        ["Tank"] = false,
        ["Ramming Jeep"] = false,
    }

    local remoteFolder = ReplicatedStorage:WaitForChild("Remotes", 5)
    local spawnPetRemote = remoteFolder and remoteFolder:WaitForChild("SpawnPet", 5)
    local buyCoinsRemote = remoteFolder and remoteFolder:WaitForChild("BuyCoins", 5)
    local bountyHunterRemote = remoteFolder and remoteFolder:WaitForChild("BountyHunter", 5)
    local emoteRemote = ReplicatedStorage:WaitForChild("Emote", 5)

    -- Покупка блоков
    local function buySpecificBlock(blockName)
        if not buyCoinsRemote then return end
        pcall(function()
            buyCoinsRemote:FireServer(tostring(blockName), 1)
        end)
    end

    -- Цикл авто-покупки
    task.spawn(function()
        while true do
            for blockName, isEnabled in pairs(blockSettings) do
                if isEnabled then
                    buySpecificBlock(blockName)
                    task.wait(1.5)
                end
            end
            task.wait(2)
        end
    end)

    -- Цикл авто-эмодзи
    task.spawn(function()
        while true do
            if autoEmote and emoteRemote then
                pcall(function()
                    emoteRemote:FireServer("Cat Heart")
                end)
            end
            task.wait(5)
        end
    end)

    local function tweenTo(targetPos, keepAnchored)
        local character = Players.LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid or humanoid.Health <= 0 then return false end

        hrp.Anchored = true 
        local distance = (hrp.Position - targetPos).Magnitude
        if distance < 1 then 
            if not keepAnchored then hrp.Anchored = false end
            return true
        end
        
        local timeToTravel = distance / speed 
        pcall(function() humanoid:MoveTo(targetPos) end)

        local tween = TweenService:Create(hrp, TweenInfo.new(timeToTravel, Enum.EasingStyle.Linear), {CFrame = CFrame.new(targetPos)})
        tween:Play()
        
        while tween.PlaybackState == Enum.PlaybackState.Playing and autoFarm do
            local currentHumanoid = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if not currentHumanoid or currentHumanoid.Health <= 0 then
                tween:Cancel()
                return false
            end
            task.wait(0.1)
        end
        
        if not keepAnchored then
            local hrpCurrent = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrpCurrent then hrpCurrent.Anchored = false end
        end
        return true
    end

    local function getPartFromModel(model)
        if not model then return nil end
        if model:IsA("BasePart") then return model end
        if model.PrimaryPart then return model.PrimaryPart end
        for _, child in pairs(model:GetDescendants()) do
            if child:IsA("BasePart") then return child end
        end
        return nil
    end

    local function isNegativeBoost(model)
        for _, desc in pairs(model:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local text = desc.Text
                if text:find("-") or text:find("÷") then return true end
            end
        end
        return false 
    end

    local function getBoostValue(model)
        local highestVal = 1
        for _, desc in pairs(model:GetDescendants()) do
            if desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox") then
                local num = tonumber(desc.Text:match("%d+"))
                if num and num > highestVal then
                    highestVal = num
                end
            end
        end
        return highestVal
    end

    local function getBestBoost(boostsFolder)
        local wantCash = (collectPriority == "Приоритет: Деньги")
        
        local bestPreferredBoost = nil
        local maxPreferredValue = -1
        local bestAnyBoost = nil
        local maxAnyValue = -1

        for _, boost in pairs(boostsFolder:GetChildren()) do
            local isNeg = isNegativeBoost(boost)
            local val = getBoostValue(boost)
            local nameLower = boost.Name:lower()
            
            local isCash = nameLower:find("cash") or nameLower:find("coin") or nameLower:find("money")
            local isFighter = nameLower:find("classic") or nameLower:find("fighter") or nameLower:find("pet") or nameLower:find("unit")

            if not isNeg then
                local matchesPreference = false
                if wantCash then
                    matchesPreference = isCash
                else
                    matchesPreference = isFighter
                end

                if matchesPreference then
                    if val > maxPreferredValue then
                        maxPreferredValue = val
                        bestPreferredBoost = boost
                    end
                end

                if val > maxAnyValue then
                    maxAnyValue = val
                    bestAnyBoost = boost
                end
            end
        end

        if bestPreferredBoost then return bestPreferredBoost end
        if bestAnyBoost then return bestAnyBoost end
        
        for _, boost in pairs(boostsFolder:GetChildren()) do 
            if not isNegativeBoost(boost) then return boost end
        end
        return nil
    end

    -- Цикл квестов (раз в час)
    task.spawn(function()
        while true do
            if autoBountyQuest then
                if bountyHunterRemote then
                    pcall(function() 
                        bountyHunterRemote:FireServer() 
                        print("[Nexus] Квест Bounty успешно запрошен!")
                    end)
                end
                
                local elapsed = 0
                while elapsed < 3600 and autoBountyQuest do
                    task.wait(1)
                    elapsed = elapsed + 1
                end
            else
                task.wait(1)
            end
        end
    end)

    local function triggerSpawn()
        pcall(function()
            if spawnPetRemote then
                local player = Players.LocalPlayer
                local equippedNPCs = player:FindFirstChild("EquippedNPCs") or player:FindFirstChild("Pets") or player:FindFirstChild("Units")
                if equippedNPCs then
                    for npcName, isEnabled in pairs(activeNPCs) do
                        if isEnabled then
                            local targetSlot = equippedNPCs:FindFirstChild(npcName)
                            if not targetSlot then
                                for _, child in pairs(equippedNPCs:GetChildren()) do
                                    if child.Name:find(npcName) then
                                        targetSlot = child
                                        break
                                    end
                                end
                            end
                            if targetSlot then
                                spawnPetRemote:FireServer(targetSlot)
                                task.wait(0.15)
                            end
                        end
                    end
                end
            end
        end)
    end

    task.spawn(function()
        while true do
            if autoSpawnPet then triggerSpawn() end
            task.wait(spawnDelay)
        end
    end)

    local function startFarm()
        task.spawn(function()
            while autoFarm do
                local grassland = workspace:FindFirstChild("Worlds") and workspace.Worlds:FindFirstChild("Grassland")
                if grassland then
                    local level = 1
                    while autoFarm do
                        local character = Players.LocalPlayer.Character
                        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                        
                        if not character or not humanoid or humanoid.Health <= 0 then
                            repeat
                                task.wait(0.5)
                                if not autoFarm then break end
                                character = Players.LocalPlayer.Character
                                humanoid = character and character:FindFirstChildOfClass("Humanoid")
                            until character and humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart")
                            
                            if not autoFarm then break end
                            level = 1
                            task.wait(1)
                            continue
                        end

                        local levelFolder = grassland:FindFirstChild(tostring(level))
                        if not levelFolder then 
                            level = 1
                            task.wait(0.5)
                            continue
                        end

                        local boostsFolder = levelFolder:FindFirstChild("Boosts")
                        local box = levelFolder:FindFirstChild("Box")
                        local hitBox = levelFolder:FindFirstChild("HitBox")
                        local spawnPoint = levelFolder:FindFirstChild("Spawn") 

                        if boostsFolder and autoFarm then
                            local targetModel = getBestBoost(boostsFolder)
                            if targetModel then
                                local partToTween = getPartFromModel(targetModel)
                                local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if partToTween and hrp then
                                    local startPos = hrp.Position
                                    local endPos = partToTween.Position
                                    local midPos = (startPos + endPos) / 2
                                    midPos = Vector3.new(midPos.X, endPos.Y + 1, midPos.Z)

                                    if not tweenTo(midPos, false) then continue end
                                    task.wait(3) 
                                    if not tweenTo(endPos, false) then continue end
                                    task.wait(0.2)
                                end
                            end
                        end

                        if box and autoFarm then
                            local boxPart = getPartFromModel(box)
                            if boxPart then
                                if not tweenTo(boxPart.Position, false) then continue end
                                task.wait(0.1)
                            end
                        end

                        if hitBox and autoFarm then
                            local hitBoxPart = getPartFromModel(hitBox)
                            if hitBoxPart then
                                if not tweenTo(hitBoxPart.Position, false) then continue end
                                task.wait(0.1)
                            end
                        end

                        if spawnPoint and spawnPoint:IsA("BasePart") and autoFarm then
                            if not tweenTo(spawnPoint.Position + Vector3.new(0, 1, 0), true) then continue end
                            
                            local waitTime = 0
                            local maxWait = 35 
                            
                            while waitTime < maxWait and autoFarm do
                                local currentHum = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                                if not currentHum or currentHum.Health <= 0 then break end

                                local hasEnemies = false
                                local playerName = Players.LocalPlayer.Name 
                                local battleFolder = workspace:FindFirstChild("Battle")
                                
                                if battleFolder then
                                    local playerBattle = battleFolder:FindFirstChild(playerName)
                                    if playerBattle then
                                        local enemyFolder = playerBattle:FindFirstChild("Enemy")
                                        if enemyFolder and #enemyFolder:GetChildren() > 0 then
                                            for _, enemy in pairs(enemyFolder:GetChildren()) do
                                                local hum = enemy:FindFirstChildOfClass("Humanoid")
                                                if hum and hum.Health > 0 then
                                                    hasEnemies = true
                                                    break
                                                elseif not hum and enemy:FindFirstChild("Torso") then
                                                    hasEnemies = true
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                if not hasEnemies then break end
                                task.wait(0.5)
                                waitTime = waitTime + 0.5
                            end

                            local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if hrp then hrp.Anchored = false end
                        end
                        
                        if not autoFarm then break end
                        level = level + 1
                        task.wait(0.3)
                    end
                end
                task.wait(1)
            end
            
            local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then hrp.Anchored = false end
        end)
    end

    -- Вкладки GUI
    local FarmTab = Window:CreateTab("Фарм", "zap")

    FarmTab:CreateToggle({
        Name = "Включить Автофарм",
        CurrentValue = false,
        Callback = function(Value)
            autoFarm = Value
            if not Value then
                local hrp = Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then hrp.Anchored = false end
            else
                startFarm()
            end
        end,
    })

    FarmTab:CreateToggle({
        Name = "Авто-взятие квестов (раз в час)",
        CurrentValue = false,
        Callback = function(Value) autoBountyQuest = Value end,
    })

    FarmTab:CreateToggle({
        Name = "Авто-эмодзи (Cat Heart)",
        CurrentValue = false,
        Callback = function(Value) autoEmote = Value end,
    })

    FarmTab:CreateDropdown({
        Name = "Приоритет сбора",
        Options = {"Приоритет: Деньги", "Приоритет: Бойцы"},
        CurrentOption = {"Приоритет: Бойцы"},
        MultipleOptions = false,
        Callback = function(Option) 
            if type(Option) == "table" then
                collectPriority = Option[1]
            else
                collectPriority = tostring(Option)
            end
            print("[Nexus] Выбран приоритет: " .. tostring(collectPriority))
        end,
    })

    local LuckyTab = Window:CreateTab("Лаки Блоки", "box")

    LuckyTab:CreateToggle({
        Name = "🖱️ Плавный авто-кликер (по центру)",
        CurrentValue = false,
        Callback = function(Value)
            continuousAutoClicker = Value
            if Value then
                task.spawn(function()
                    while continuousAutoClicker do
                        local camera = workspace.CurrentCamera
                        if camera then
                            local x = camera.ViewportSize.X / 2
                            local y = camera.ViewportSize.Y / 2

                            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 1)
                            task.wait(0.05)
                            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 1)
                        end
                        task.wait(0.3) 
                    end
                end)
            end
        end,
    })

    local blocksList = {
        "Wood Lucky Block", 
        "Iron Lucky Block", 
        "Castle Lucky Block", 
        "Desert Lucky Block", 
        "Lucky Block", 
        "Egg Tier 1", 
        "War Machines Crate"
    }

    for _, bName in ipairs(blocksList) do
        LuckyTab:CreateToggle({
            Name = "Авто-покупать: " .. bName,
            CurrentValue = false,
            Callback = function(Value)
                blockSettings[bName] = Value
            end,
        })
    end

    local SpawnTab = Window:CreateTab("Спавн бойцов", "users")

    SpawnTab:CreateToggle({
        Name = "Включить общий авто-спавн бойцов",
        CurrentValue = false,
        Callback = function(Value) autoSpawnPet = Value end,
    })

    SpawnTab:CreateSlider({
        Name = "Задержка спавна (сек)",
        Range = {0.1, 2.0},
        Increment = 0.1,
        CurrentValue = 0.5,
        Callback = function(Value) spawnDelay = Value end,
    })

    SpawnTab:CreateToggle({
        Name = "Спавнить: Normal",
        CurrentValue = false,
        Callback = function(Value) activeNPCs["Normal"] = Value end,
    })

    SpawnTab:CreateToggle({
        Name = "Спавнить: Bob",
        CurrentValue = false,
        Callback = function(Value) activeNPCs["Bob"] = Value end,
    })

    SpawnTab:CreateToggle({
        Name = "Спавнить: Shooter",
        CurrentValue = false,
        Callback = function(Value) activeNPCs["Shooter"] = Value end,
    })

    SpawnTab:CreateToggle({
        Name = "Спавнить: Tank",
        CurrentValue = false,
        Callback = function(Value) activeNPCs["Tank"] = Value end,
    })

    SpawnTab:CreateToggle({
        Name = "Спавнить: Ramming Jeep",
        CurrentValue = false,
        Callback = function(Value) activeNPCs["Ramming Jeep"] = Value end,
    })
end)

if not err and success then
    print("[Success] Скрипт V67 успешно загружен!")
else
    warn("[Error] Ошибка загрузки V67: " .. tostring(err))
end
