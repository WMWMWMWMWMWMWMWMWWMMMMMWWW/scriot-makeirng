local yesorno = false
local result = messagebox(
    "Do you really want to continue, this might be detected??",
    "Confirmation",
    48 -- Yes / No / Cancel
)

if result == 1 then
    yesorno = true
else
    yesorno = false
end

if yesorno == true then
    wait(1)

    local TweenService = game:GetService("TweenService")
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService("HttpService")

    local player = Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")
    local Backpack = player:WaitForChild("Backpack")

    local garbageFolder = workspace:WaitForChild("PrinterGame"):WaitForChild("Garbage")
    local tryPickUp = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("TryPickUp")
    local binsFolder = workspace.PrinterGame.Bins

    local trashCount = 0        -- counts to 20 before firing bins
    local totalTrashCount = 0   -- full session total

    local steps = {
        {cf =  CFrame.new(-38.272995, 15.0156355, 701.851685, 0.0533493198, -5.00630719e-08, -0.998575926, 7.89764414e-08, 1, -4.59151224e-08, 0.998575926, -7.64144303e-08, 0.0533493198), time = 3},
        { cf = CFrame.new(-202.964127, 3.99999976, 703.783936, -0.0157073159, -3.97297928e-09, 0.999876618, 3.53278673e-09, 1, 4.02896694e-09, -0.999876618, 3.59563512e-09, -0.0157073159), time = 2 },
        { cf = CFrame.new(-202.248657, 3.99999976, 652.996094, 0.0219905712, -1.40403209e-08, 0.999758184, 7.32728944e-09, 1, 1.38825467e-08, -0.999758184, 7.0202324e-09, 0.0219905712), time = 2 },
        { cf = CFrame.new(-395.970215, 4.99999952, 652.537781, -9.44024592e-08, 8.21478068e-08, 1, -4.48650503e-08, 1, -8.21478139e-08, -1, -4.48650574e-08, -9.44024592e-08), time = 3 },
        { cf = CFrame.new(-397.201965, 2.0025351, 642.991943, 0.999839127, -5.91003122e-08, -0.0179376844, 5.97214083e-08, 1, 3.40896129e-08, 0.0179376844, -3.51553915e-08, 0.999839127), time = 4 }
    }

    for _, step in ipairs(steps) do
        local tweenInfo = TweenInfo.new(step.time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(rootPart, tweenInfo, {CFrame = step.cf})
        tween:Play()
        tween.Completed:Wait()
    end

    rootPart.Anchored = true

    local function sendWebhook(count)
        local success, err = pcall(function()
            request({
                Url = getgenv().WebhookURL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode({
                    content = "**Session Trash Count:** " .. tostring(count)
                })
            })
        end)
        if success then
            print("[Webhook] Sent trash count: " .. tostring(count))
        else
            warn("Failed to send webhook: " .. tostring(err))
        end
    end

    while task.wait(0.01) do
        local trashItems = garbageFolder:GetChildren()
        if #trashItems > 0 then
            for _, trash in ipairs(trashItems) do
                if trash:IsA("BasePart") then
                    trash.CanCollide = false
                elseif trash:IsA("Model") then
                    for _, part in ipairs(trash:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end

            local tools = Backpack:GetChildren()
            if #tools >= 2 then
                local secondTool = tools[2]
                if not character:FindFirstChildOfClass("Tool") then
                    secondTool.Parent = character
                end
            end

            local trash = trashItems[math.random(1, #trashItems)]
            if trash:IsA("BasePart") then
                trash.CFrame = rootPart.CFrame * CFrame.new(2, 0, 0)
            elseif trash:IsA("Model") and trash:FindFirstChild("PrimaryPart") then
                trash:SetPrimaryPartCFrame(rootPart.CFrame * CFrame.new(2, 0, 0))
            end

            local litterPicker = character:FindFirstChildOfClass("Tool")
            if litterPicker then
                tryPickUp:InvokeServer(trash, litterPicker)
                trashCount += 1
                totalTrashCount += 1
                if trashCount >= 20 then
                    for i = 1, 19 do
                        local ProximityPrompt = binsFolder:GetChildren()[i].Lid.ProxHolder.BinProx
                        fireproximityprompt(ProximityPrompt)
                    end
                    sendWebhook(totalTrashCount) -- Send total accumulated count
                    trashCount = 0
                end
            end
        end
    end
end
