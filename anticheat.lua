local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local BanStore = DataStoreService:GetDataStore("BannedUsers")
local WEBHOOK = "YOUR_DISCORD_WEBHOOK"
local Detected = {}

local function LogBan(plr, reason)
	local data = {
		["content"] = "",
		["embeds"] = {{
			["title"] = "Banned",
			["description"] = plr.Name.." | "..plr.UserId.." was **banned**",
			["color"] = 16711680,
			["fields"] = {
				{["name"] = "Reason", ["value"] = reason}
			}
		}}
	}
	pcall(function()
		HttpService:PostAsync(WEBHOOK, HttpService:JSONEncode(data))
	end)
end

local function Ban(plr, reason)
	if Detected[plr] then return end
	Detected[plr] = true
	BanStore:SetAsync(tostring(plr.UserId), reason)
	LogBan(plr, reason)
	plr:Kick("Anti-Cheat Ban: "..reason)
end

Players.PlayerAdded:Connect(function(plr)
	local banReason = BanStore:GetAsync(tostring(plr.UserId))
	if banReason then
		plr:Kick("Banned: "..banReason)
		return
	end

	plr.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		local hrp = char:WaitForChild("HumanoidRootPart")
		local lastPos = hrp.Position

		RunService.Heartbeat:Connect(function()
			local delta = (hrp.Position - lastPos).Magnitude
			if delta > 100 then Ban(plr, "Speed/Teleport Hack") end
			if hrp.Velocity.Y > 120 and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
				Ban(plr, "Fly Detected")
			end
			lastPos = hrp.Position
		end)

		RunService.Stepped:Connect(function()
			if hum.Health > 150 or hum.MaxHealth > 150 then
				Ban(plr, "Godmode")
			end
		end)

		local stamina = plr:FindFirstChild("Stamina")
		if stamina then
			RunService.Heartbeat:Connect(function()
				if stamina.Value > 100 then
					Ban(plr, "Infinite Stamina")
				end
			end)
		end

		if not workspace:FindFirstChild(char.Name) then
			Ban(plr, "Noclip Detected")
		end
	end)

	RunService.Heartbeat:Connect(function()
		local mouse = plr:GetMouse()
		if mouse and mouse.Target and mouse.Target.Name == "Head" then
			local dir = (mouse.Target.Position - workspace.CurrentCamera.CFrame.Position).Unit
			local dot = workspace.CurrentCamera.CFrame.LookVector:Dot(dir)
			if dot > 0.995 then
				Ban(plr, "Camlock")
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= plr and p.Character and p.Character:FindFirstChild("Head") then
				local pos, visible = cam:WorldToViewportPoint(p.Character.Head.Position)
				if visible and pos.Z > 0 then
					if math.random(1, 1200) == 1 then
						Ban(plr, "ESP")
					end
				end
			end
		end
	end)

	RunService.Heartbeat:Connect(function()
		local mouse = plr:GetMouse()
		if mouse and mouse.Target and mouse.Target.Name == "Head" then
			if math.random(1, 1200) == 1 then
				Ban(plr, "Triggerbot")
			end
		end
	end)

	plr.Backpack.ChildAdded:Connect(function(tool)
		if not tool:GetAttribute("Legit") then
			Ban(plr, "Injected Tool")
		end
	end)

	for _, r in pairs(ReplicatedStorage:GetDescendants()) do
		if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
			r.OnServerEvent:Connect(function(_, ...)
				for _, arg in ipairs({...}) do
					if typeof(arg) == "function" or typeof(arg) == "thread" then
						Ban(plr, "Remote Spoof")
					end
				end
			end)
		end
	end

	local env = getfenv and getfenv(0)
	if env then
		for _, v in pairs(env) do
			if typeof(v) == "table" then
				local tag = tostring(v)
				if tag:find("syn") or tag:find("krnl") or tag:find("exploit") then
					Ban(plr, "Module Inject")
				end
			end
		end
	end

	local mt = getrawmetatable and getrawmetatable(game)
	if mt and typeof(mt.__index) == "function" then
		Ban(plr, "Metamethod Hook")
	end

	local flags = {
		clicks = 0,
		jumps = 0,
		fov = workspace.CurrentCamera.FieldOfView
	}

	plr:GetMouse().Button1Down:Connect(function()
		flags.clicks += 1
		if flags.clicks > 20 then
			Ban(plr, "Auto Clicker")
		end
		task.delay(1, function() flags.clicks = math.max(0, flags.clicks - 1) end)
	end)

	plr:GetMouse().KeyDown:Connect(function(key)
		if key == " " then
			flags.jumps += 1
			if flags.jumps > 15 then
				Ban(plr, "Auto Jump")
			end
			task.delay(1, function() flags.jumps = math.max(0, flags.jumps - 1) end)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local fov = workspace.CurrentCamera.FieldOfView
		if math.abs(fov - flags.fov) > 30 then
			Ban(plr, "FOV Spoof")
		end
	end)
end)
