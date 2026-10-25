-- Prompt Spy: logs outgoing HTTP / WebSocket requests that look like AI calls.
-- Click an entry to copy the full extracted prompt. "RAW" copies the whole request body.
-- Run this BEFORE the target script.

if getgenv().__PromptSpy then pcall(function() getgenv().__PromptSpy.gui:Destroy() end) end

local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local env = getgenv()
local clip = setclipboard or toclipboard or (Clipboard and Clipboard.set)

local entries, showAll = {}, false
local AI_HOSTS = { "openai", "anthropic", "googleapis", "generativelanguage", "openrouter", "groq", "mistral",
	"together", "deepseek", "cohere", "perplexity", "x.ai", "huggingface", "pollinations", "claude", "gemini", "chatgpt" }
local AI_KEYS = { '"messages"', '"prompt"', '"contents"', '"model"', '"input"', '"system"', '"inputs"' }

local function looksAI(url, body)
	url = tostring(url or ""):lower()
	for _, h in ipairs(AI_HOSTS) do if url:find(h, 1, true) then return true end end
	body = tostring(body or "")
	local hits = 0
	for _, k in ipairs(AI_KEYS) do if body:find(k, 1, true) then hits += 1 end end
	return hits >= 2 or body:find('"messages"', 1, true) ~= nil
end

-- pull readable text out of the common request schemas
local function textOf(v)
	if type(v) == "string" then return v end
	if type(v) ~= "table" then return "" end
	if type(v.text) == "string" then return v.text end
	local out = {}
	for _, p in ipairs(v) do
		local t = textOf(p)
		if t ~= "" then out[#out + 1] = t end
	end
	if v.parts then out[#out + 1] = textOf(v.parts) end
	if v.content and #out == 0 then out[#out + 1] = textOf(v.content) end
	return table.concat(out, "\n")
end

local function extract(body)
	local ok, j = pcall(HttpService.JSONDecode, HttpService, body)
	if not ok or type(j) ~= "table" then return body end
	local out = {}
	local function add(role, t) if t and t ~= "" then out[#out + 1] = "[" .. role .. "]\n" .. t end end
	add("system", textOf(j.system))
	add("system", textOf(j.systemInstruction or j.system_instruction))
	add("instructions", textOf(j.instructions))
	for _, key in ipairs({ "messages", "contents", "input" }) do
		if type(j[key]) == "table" then
			if j[key][1] ~= nil and type(j[key][1]) == "table" then
				for _, m in ipairs(j[key]) do add(m.role or "msg", textOf(m.content ~= nil and m.content or m)) end
			else
				add("input", textOf(j[key]))
			end
		elseif type(j[key]) == "string" then
			add(key, j[key])
		end
	end
	add("prompt", textOf(j.prompt))
	if #out == 0 then return body end
	return table.concat(out, "\n\n")
end

----------------------------------------------------------------- UI
local gui = Instance.new("ScreenGui")
gui.Name = "PromptSpy"; gui.ResetOnSpawn = false; gui.DisplayOrder = 999999
pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
if not gui.Parent then gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui") end
env.__PromptSpy = { gui = gui }

local main = Instance.new("Frame")
main.Size = UDim2.fromOffset(340, 300); main.Position = UDim2.new(1, -360, 0, 60)
main.BackgroundColor3 = Color3.fromRGB(24, 24, 28); main.BorderSizePixel = 0; main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local bar = Instance.new("Frame")
bar.Size = UDim2.new(1, 0, 0, 30); bar.BackgroundColor3 = Color3.fromRGB(36, 36, 44); bar.BorderSizePixel = 0; bar.Parent = main
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -120, 1, 0); title.Position = UDim2.fromOffset(10, 0); title.BackgroundTransparency = 1
title.Text = "Prompt Spy (0)"; title.TextColor3 = Color3.new(1, 1, 1); title.Font = Enum.Font.GothamBold
title.TextSize = 13; title.TextXAlignment = Enum.TextXAlignment.Left; title.Parent = bar

local function barBtn(text, xOff, w)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(w, 20); b.Position = UDim2.new(1, xOff, 0, 5)
	b.BackgroundColor3 = Color3.fromRGB(56, 56, 68); b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.Gotham; b.TextSize = 11; b.Text = text; b.BorderSizePixel = 0; b.Parent = bar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
	return b
end
local closeBtn = barBtn("X", -26, 20)
local clearBtn = barBtn("Clear", -72, 42)
local filterBtn = barBtn("AI only", -134, 58)

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -12, 1, -38); list.Position = UDim2.fromOffset(6, 34)
list.BackgroundTransparency = 1; list.BorderSizePixel = 0; list.ScrollBarThickness = 4
list.CanvasSize = UDim2.new(); list.AutomaticCanvasSize = Enum.AutomaticSize.Y; list.Parent = main
local layout = Instance.new("UIListLayout", list)
layout.Padding = UDim.new(0, 4); layout.SortOrder = Enum.SortOrder.LayoutOrder

-- drag
do
	local dragging, start, startPos
	bar.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, start, startPos = true, i.Position, main.Position
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - start
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

local function refreshCount()
	local n = 0
	for _, e in ipairs(entries) do if showAll or e.ai then n += 1 end end
	title.Text = ("Prompt Spy (%d)"):format(n)
end

local function applyFilter()
	for _, e in ipairs(entries) do e.row.Visible = showAll or e.ai end
	filterBtn.Text = showAll and "All" or "AI only"
	refreshCount()
end

local function copy(text, label, original)
	if clip then clip(text) end
	label.Text = clip and ("Copied %d chars"):format(#text) or "setclipboard unavailable"
	task.delay(1.2, function() if label.Parent then label.Text = original end end)
end

local counter = 0
local function addEntry(kind, url, body)
	body = tostring(body or "")
	counter += 1
	local ai = looksAI(url, body)
	local prompt = extract(body)
	local host = tostring(url):match("^%a+://([^/]+)") or tostring(url)
	local preview = prompt:gsub("%s+", " "):sub(1, 70)
	local info = ("#%d %s %s  %s  %d chars"):format(counter, os.date("%H:%M:%S"), kind, host, #prompt)

	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, -6, 0, 52); row.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
	row.BorderSizePixel = 0; row.LayoutOrder = -counter; row.Parent = list
	Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -46, 1, 0); btn.BackgroundTransparency = 1; btn.Parent = row
	btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.TextWrapped = true; btn.RichText = false
	btn.TextXAlignment = Enum.TextXAlignment.Left; btn.TextYAlignment = Enum.TextYAlignment.Top
	btn.TextColor3 = Color3.fromRGB(220, 220, 230)
	local label = info .. "\n" .. preview
	btn.Text = label
	local pad = Instance.new("UIPadding", btn); pad.PaddingLeft = UDim.new(0, 8); pad.PaddingTop = UDim.new(0, 6)
	btn.MouseButton1Click:Connect(function() copy(prompt, btn, label) end)

	local raw = Instance.new("TextButton")
	raw.Size = UDim2.fromOffset(38, 20); raw.Position = UDim2.new(1, -42, 0.5, -10)
	raw.BackgroundColor3 = Color3.fromRGB(56, 56, 68); raw.TextColor3 = Color3.new(1, 1, 1)
	raw.Font = Enum.Font.Gotham; raw.TextSize = 10; raw.Text = "RAW"; raw.BorderSizePixel = 0; raw.Parent = row
	Instance.new("UICorner", raw).CornerRadius = UDim.new(0, 4)
	raw.MouseButton1Click:Connect(function() copy(body, btn, label) end)

	row.Visible = showAll or ai
	entries[#entries + 1] = { row = row, ai = ai }
	refreshCount()
end

filterBtn.MouseButton1Click:Connect(function() showAll = not showAll; applyFilter() end)
clearBtn.MouseButton1Click:Connect(function()
	for _, e in ipairs(entries) do e.row:Destroy() end
	table.clear(entries); refreshCount()
end)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

----------------------------------------------------------------- hooks
local function log(kind, url, body)
	task.spawn(function() pcall(addEntry, kind, url, body) end)
end

-- executor request functions
local function hookRequest(name)
	local fn = env[name] or (name == "request" and request) or (name == "http_request" and http_request)
	if type(fn) ~= "function" then return end
	local old
	old = hookfunction(fn, newcclosure(function(opts, ...)
		if type(opts) == "table" then log("HTTP " .. tostring(opts.Method or "GET"), opts.Url or opts.URL, opts.Body) end
		return old(opts, ...)
	end))
end
for _, n in ipairs({ "request", "http_request" }) do pcall(hookRequest, n) end
if syn and syn.request then
	pcall(function()
		local old
		old = hookfunction(syn.request, newcclosure(function(opts, ...)
			if type(opts) == "table" then log("HTTP " .. tostring(opts.Method or "GET"), opts.Url, opts.Body) end
			return old(opts, ...)
		end))
	end)
end

-- HttpService:PostAsync / RequestAsync (executor-allowed contexts)
pcall(function()
	local old
	old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
		if typeof(self) == "Instance" and self == HttpService and not checkcaller() then
			local m, a = getnamecallmethod(), { ... }
			if m == "PostAsync" then log("POST", a[1], a[2])
			elseif m == "RequestAsync" and type(a[1]) == "table" then log("HTTP " .. tostring(a[1].Method), a[1].Url, a[1].Body) end
		end
		return old(self, ...)
	end))
end)

-- WebSocket.connect -> proxy that logs :Send
pcall(function()
	if not (WebSocket and WebSocket.connect) then return end
	local oldConnect = WebSocket.connect
	WebSocket.connect = function(url, ...)
		local ws = oldConnect(url, ...)
		return setmetatable({}, { __index = function(_, k)
			if k == "Send" then return function(_, msg, ...) log("WS", url, msg); return ws:Send(msg, ...) end end
			local v = ws[k]
			if type(v) == "function" then return function(_, ...) return v(ws, ...) end end
			return v
		end })
	end
end)

print("[PromptSpy] active. Execute the target script now.")
