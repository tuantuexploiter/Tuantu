local Players = game:GetService('Players')
if #Players:GetPlayers() > 1 then
    Players.LocalPlayer:Kick("stop using this in public.")
    return
end
Players.PlayerAdded:Connect(function()
    if #Players:GetPlayers() > 1 then
        Players.LocalPlayer:Kick("am not letting you ruin other ppl fun anymore.")
    end
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = 'ayin work ui, LoadingTitle = 'anti fun ui'})

local RepStorage = game:GetService('ReplicatedStorage')
local Workspace = game:GetService('workspace')
local LocalPlayer = Players.LocalPlayer

local function listChildren(folder)
	local t = {}
	if folder then
		for _, v in ipairs(folder:GetChildren()) do
			table.insert(t, v.Name)
		end
	end
	table.sort(t)
	return t
end

local function getFolder(root, ...)
	local cur = root
	for i = 1, select('#', ...) do
		local n = select(i, ...)
		if not cur then return nil end
		cur = cur:FindFirstChild(n)
	end
	return cur
end

local function normalizeSelected(v)
	if type(v) == 'string' then return v end
	if typeof(v) == 'Instance' then return v.Name end
	if type(v) == 'table' then
		if v[1] then return v[1] end
		if v.Name then return v.Name end
	end
	return tostring(v)
end

local function titleCase(s)
	if not s or #s == 0 then return '' end
	return s:sub(1, 1):upper() .. s:sub(2):lower()
end

local abnoList = listChildren(getFolder(Workspace, 'Abnormalities'))
local talentList = listChildren(getFolder(RepStorage, 'Assets', 'Talents'))

local selectedWork = 'Instinct'
local selectedTalentRaw = talentList[1] or ''
local selectedAbnos = {}

local Tab = Window:CreateTab('abno working')
Tab:CreateSection('Controls')
Tab:CreateDropdown({
	Name = 'Work Type',
	Options = { 'Instinct', 'Insight', 'Attachment', 'Repression' },
	CurrentOption = selectedWork,
	Callback = function(opt)
		selectedWork = opt
	end,
})
Tab:CreateButton({
	Name = 'Work',
	Callback = function()
		pcall(function()
			if #selectedAbnos == 0 then return end
			local abnoRoot = getFolder(Workspace, 'Abnormalities')
			local remote = getFolder(RepStorage, 'Assets', 'RemoteEvents', 'WorkEvent')
			if not abnoRoot or not remote then return end

			local flavor = titleCase(selectedWork)
			for _, abnoName in ipairs(selectedAbnos) do
				local abno = abnoRoot:FindFirstChild(abnoName)
				if abno then
					local wt = abno:FindFirstChild('WorkTablet')
					if wt then remote:FireServer(wt, flavor) end
				end
			end
		end)
	end,
})

Tab:CreateSection('Select Abnormalities')
local abnormalityToggles = {}
for _, abno in ipairs(abnoList) do
	abnormalityToggles[abno] = Tab:CreateToggle({
		Name = abno,
		CurrentValue = false,
		Callback = function(Value)
			if Value then
				if not table.find(selectedAbnos, abno) then
					table.insert(selectedAbnos, abno)
				end
			else
				local index = table.find(selectedAbnos, abno)
				if index then
					table.remove(selectedAbnos, index)
				end
			end
		end,
	})
end
Tab:CreateButton({
	Name = 'Clear Selection',
	Callback = function()
		selectedAbnos = {}
		for _, toggle in pairs(abnormalityToggles) do
			toggle:Set(false)
		end
	end,
})

local CardTab = Window:CreateTab('card selector')
CardTab:CreateSection('Talent')
CardTab:CreateDropdown({
	Name = 'Talent',
	Options = talentList,
	CurrentOption = selectedTalentRaw,
	Callback = function(opt)
		selectedTalentRaw = opt
	end,
})
CardTab:CreateButton({
	Name = 'Select card',
	Callback = function()
		pcall(function()
			local sel = normalizeSelected(selectedTalentRaw)
			if sel == '' then return end
			local remote = getFolder(RepStorage, 'Assets', 'RemoteEvents', 'SelectCardEvent')
			if remote then
				remote:FireServer(sel)
			end
		end)
	end,
})

local WeaponTab = Window:CreateTab('weapon mod')
WeaponTab:CreateSection('Hitbox Settings')
local hitboxSize = 10
WeaponTab:CreateInput({
	Name = 'Hitbox Size',
	PlaceholderText = '10',
	Callback = function(text)
		local v = tonumber(text)
		if v and v > 0 then hitboxSize = v end
	end,
})

local function applyHitboxToWeapon(tool)
    if not (tool and tool:IsA("Tool")) then return end
    local attackAnims = tool:FindFirstChildOfClass("Folder") and tool:FindFirstChildOfClass("Folder"):FindFirstChild("AttackAnimations")
    if not attackAnims then return end

    for _, animFolder in ipairs(attackAnims:GetChildren()) do
        local hitboxValue = animFolder:FindFirstChild("HitboxSize")
        if hitboxValue and hitboxValue:IsA("Vector3Value") then
            hitboxValue.Value = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        end
    end
end

WeaponTab:CreateSection('Damage Settings')
local dmgMax = 1500
local dmgMin = 1500
WeaponTab:CreateInput({
	Name = 'Max Damage',
	PlaceholderText = '1500',
	Callback = function(text)
		local v = tonumber(text)
		if v then dmgMax = v end
	end,
})
WeaponTab:CreateInput({
	Name = 'Min Damage',
	PlaceholderText = '1500',
	Callback = function(text)
		local v = tonumber(text)
		if v then dmgMin = v end
	end,
})

local function applyDamageToTool(tool)
	if not (tool and tool:IsA('Tool')) then return end
	local settings = tool:FindFirstChild('SettingValues')
	if not settings then return end

	local maxVal = settings:FindFirstChild('MaxDamageValue')
	if maxVal then pcall(function() maxVal.Value = dmgMax end) end
	
	local minVal = settings:FindFirstChild('MinDamageValue')
	if minVal then pcall(function() minVal.Value = dmgMin end) end
end

local function applyAllModsToWeapons()
    local character = LocalPlayer.Character
    local backpack = LocalPlayer:FindFirstChild("Backpack")

    if character then
        for _, child in ipairs(character:GetChildren()) do
            if child:IsA("Tool") then
                applyHitboxToWeapon(child)
                applyDamageToTool(child)
            end
        end
    end

    if backpack then
        for _, child in ipairs(backpack:GetChildren()) do
            if child:IsA("Tool") then
                applyHitboxToWeapon(child)
                applyDamageToTool(child)
            end
        end
    end
end

WeaponTab:CreateButton({
	Name = 'Apply All Weapon Mods',
	Callback = applyAllModsToWeapons,
})

WeaponTab:CreateSection('Attack Speed')
local attackSpeedValue = 5
local infiniteAttackSpeed = false

local function setAttackSpeedValue(val)
	pcall(function()
		local units = Workspace:WaitForChild('Units', 2)
		local playerUnit = units and units:FindFirstChild(LocalPlayer.Name)
		local charStats = playerUnit and playerUnit:FindFirstChild('CharStats')
		local attackSpeed = charStats and charStats:FindFirstChild('AttackSpeed')
		if attackSpeed then attackSpeed.Value = val end
	end)
end

WeaponTab:CreateInput({
	Name = 'Attack Speed',
	PlaceholderText = '5',
	Callback = function(text)
		local v = tonumber(text)
		if v then
			attackSpeedValue = v
			if not infiniteAttackSpeed then
				setAttackSpeedValue(attackSpeedValue)
			end
		end
	end,
})
WeaponTab:CreateToggle({
	Name = 'Infinite Attack Speed',
	CurrentValue = false,
	Callback = function(Value)
		infiniteAttackSpeed = Value
		setAttackSpeedValue(infiniteAttackSpeed and math.huge or attackSpeedValue)
	end,
})
WeaponTab:CreateButton({
	Name = 'Apply Attack Speed',
	Callback = function()
		setAttackSpeedValue(infiniteAttackSpeed and math.huge or attackSpeedValue)
	end,
})

WeaponTab:CreateSection('Utilities')
WeaponTab:CreateButton({
    Name = "Load Unit Tracker",
    Callback = function()
        pcall(function()
			loadstring(game:HttpGet('https://raw.githubusercontent.com/bendzrt/tuantu-lcorp-script/refs/heads/main/unit-tracker'))()
        end)
    end,
})

local function onToolAdded(tool)
    if tool:IsA("Tool") then
        task.wait(0.1) 
        applyHitboxToWeapon(tool)
        applyDamageToTool(tool)
    end
end

LocalPlayer.Backpack.ChildAdded:Connect(onToolAdded)

LocalPlayer.CharacterAdded:Connect(function(character)
	task.wait(1)
	setAttackSpeedValue(infiniteAttackSpeed and math.huge or attackSpeedValue)
	applyAllModsToWeapons()
    character.ChildAdded:Connect(onToolAdded)
end)

task.spawn(function()
	while task.wait(1.5) do
		applyAllModsToWeapons()
	end
end)