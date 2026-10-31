--!nocheck
-- ============================================================
-- Skibidi Glass  |  discord.gg/vonhub  |  glassmorphic UI library for Roblox
--
--   local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/blookzz/skibidi/refs/heads/main/SkibidiGlassUI.lua"))()
--   local Toggles, Options = Library.Toggles, Library.Options
--
--   local Window = Library:CreateWindow({
--       Title = "Skibidi", Subtitle = "glass", Footer = "v1.0", Icon = "box",
--       Acrylic = true, BoostGraphics = true,   -- both default to on
--       ToggleKeybind = Enum.KeyCode.LeftControl,
--       ScreenClamp = true, ScreenClampPadding = 8,  -- keep the window fully on screen (default off)
--   })
--   Window:SetScreenClamp(On, Padding?)   -- toggle it later
--   local Tab     = Window:AddTab("Main", "home", "Optional description")
--   local Section = Tab:AddSection("Movement", "Optional caption")
--   local Group   = Section:AddLeftGroupbox("Player", "user")   -- or Tab:AddLeftGroupbox
--
--   Group:AddToggle("Fly", { Text = "Fly", Default = false })
--       :AddKeyPicker("FlyKey", { Default = "F", Mode = "Toggle", SyncToggleState = true })
--       :AddColorPicker("FlyColor", { Default = Color3.new(1, 0, 0) })
--   Group:AddCheckbox("Noclip", { Text = "Noclip" })
--   Group:AddSlider("Speed", { Text = "Speed", Min = 16, Max = 200, Default = 32 })
--   Group:AddInput("Target", { Text = "Target", Placeholder = "username" })
--   Group:AddDropdown("Mode", { Text = "Mode", Values = { "A", "B" }, Multi = false, Searchable = true })
--   Group:AddButton("Run", function() end):AddButton("Stop", function() end)
--   Group:AddLabel("Text"), AddParagraph, AddHeader, AddDivider, AddProgressBar,
--   Group:AddImage, AddViewport, AddDependencyBox():SetupDependencies({ { Toggles.Fly, true } })
--   Group:AddChart("Fps", { Type = "Line" | "Area" | "Bar" | "Pie" | "Donut", Data = { ... } })
--
--   Section:AddRightGroupbox / AddFullGroupbox / AddGroup({ Side = "Left", Description = ... })
--   Section:AddLeftTabbox("Box"):AddTab("One"):AddToggle(...)
--   Window:AddSettingsTab()    -- theme, accent, glass tint, acrylic, boost, menu key, configs
--   Library:Notify({ Title, Description, Time, Type = "Info" | "Success" | "Warning" | "Error" })
--   Library:Dialog({ Title, Description, Buttons = { { Title, Variant, Callback } } })
--   Library:SetTheme("Frost" | "Aurora" | "Lilac" | "Rose" | "Amber" | "Mono"), SetAccent, Unload
--
-- Run this file on its own and a demo of every element opens. Scripts that
-- call CreateWindow never see it (getgenv().SkibidiNoDemo = true disables it).
--
-- Everything is built from scratch for this style:
--   * one spring/bezier motion engine drives every animation; drags glide
--   * a single screen-space light source lights every glass edge
--   * acrylic blurs the 3D world behind the window (DepthOfField + Glass)
--   * graphics boost (on by default) raises quality so acrylic renders,
--     and puts the player's settings back afterwards
-- ============================================================

local cloneref = cloneref or clonereference or function(Instance)
	return Instance
end

local function Service(Name)
	return cloneref(game:GetService(Name))
end

local Players = Service("Players")
local RunService = Service("RunService")
local UserInputService = Service("UserInputService")
local TextService = Service("TextService")
local HttpService = Service("HttpService")
local Lighting = Service("Lighting")
local CoreGui = Service("CoreGui")
local GuiService = Service("GuiService")
local Teams = Service("Teams")

local getgenv = getgenv or function()
	return shared
end
local protectgui = protectgui or (syn and syn.protect_gui) or function() end
local gethui = gethui
local setclipboard = setclipboard or toclipboard

local FS = {
	isfile = isfile,
	isfolder = isfolder,
	readfile = readfile,
	writefile = writefile,
	makefolder = makefolder,
	delfile = delfile,
	listfiles = listfiles,
}
FS.Available = FS.isfile and FS.writefile and FS.readfile and FS.makefolder and FS.isfolder and true or false

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

local Library = {
	Name = "Skibidi",
	Version = "glass-1.0.0",

	Toggles = {},
	Options = {},
	Labels = {},
	Buttons = {},

	Unloaded = false,
	WindowsCreated = 0,
	Connections = {},
	UnloadCallbacks = {},
	DependencyBoxes = {},
	KeyPickers = {},

	Window = nil,
	ScreenGui = nil,

	DPIScale = 1,
	NotifySide = "Right",
	ShowKeybinds = false,
	ToggleKeybind = nil,

	AcrylicEnabled = true,
	BoostGraphics = true,
	GlassOpacity = 0.62,

	IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled,
	ConfigFolder = "Skibidi",
	IgnoreIndexes = {},
}
local Toggles = Library.Toggles
local Options = Library.Options

-- ============================================================
-- THEME
-- ============================================================
local Themes = {
	Frost = {
		Accent = Color3.fromRGB(122, 162, 255),
		Background = Color3.fromRGB(13, 15, 23),
		Text = Color3.fromRGB(241, 244, 252),
		SubText = Color3.fromRGB(172, 180, 199),
		Muted = Color3.fromRGB(112, 120, 142),
		Risky = Color3.fromRGB(255, 112, 124),
		Success = Color3.fromRGB(110, 231, 160),
		Warning = Color3.fromRGB(255, 200, 108),
	},
	Aurora = {
		Accent = Color3.fromRGB(94, 234, 212),
		Background = Color3.fromRGB(10, 17, 21),
		Text = Color3.fromRGB(236, 250, 247),
		SubText = Color3.fromRGB(160, 190, 186),
		Muted = Color3.fromRGB(104, 130, 128),
		Risky = Color3.fromRGB(255, 118, 130),
		Success = Color3.fromRGB(120, 236, 160),
		Warning = Color3.fromRGB(255, 204, 110),
	},
	Lilac = {
		Accent = Color3.fromRGB(190, 152, 255),
		Background = Color3.fromRGB(17, 13, 26),
		Text = Color3.fromRGB(246, 241, 255),
		SubText = Color3.fromRGB(186, 174, 206),
		Muted = Color3.fromRGB(128, 116, 150),
		Risky = Color3.fromRGB(255, 116, 140),
		Success = Color3.fromRGB(120, 230, 170),
		Warning = Color3.fromRGB(255, 200, 120),
	},
	Rose = {
		Accent = Color3.fromRGB(255, 130, 172),
		Background = Color3.fromRGB(24, 13, 18),
		Text = Color3.fromRGB(255, 241, 246),
		SubText = Color3.fromRGB(208, 172, 184),
		Muted = Color3.fromRGB(150, 112, 126),
		Risky = Color3.fromRGB(255, 120, 112),
		Success = Color3.fromRGB(130, 230, 170),
		Warning = Color3.fromRGB(255, 205, 120),
	},
	Amber = {
		Accent = Color3.fromRGB(255, 190, 104),
		Background = Color3.fromRGB(21, 17, 12),
		Text = Color3.fromRGB(255, 248, 238),
		SubText = Color3.fromRGB(204, 188, 166),
		Muted = Color3.fromRGB(146, 130, 110),
		Risky = Color3.fromRGB(255, 116, 116),
		Success = Color3.fromRGB(150, 226, 140),
		Warning = Color3.fromRGB(255, 214, 120),
	},
	Mono = {
		Accent = Color3.fromRGB(232, 234, 240),
		Background = Color3.fromRGB(13, 13, 15),
		Text = Color3.fromRGB(245, 245, 247),
		SubText = Color3.fromRGB(176, 176, 184),
		Muted = Color3.fromRGB(118, 118, 128),
		Risky = Color3.fromRGB(255, 112, 112),
		Success = Color3.fromRGB(140, 226, 160),
		Warning = Color3.fromRGB(255, 206, 120),
	},
}
Library.Themes = Themes

local Scheme = table.clone(Themes.Frost)
Scheme.Font = Font.new("rbxasset://fonts/families/BuilderSans.json")
Scheme.Name = "Frost"
Library.Scheme = Scheme

local White = Color3.new(1, 1, 1)
local Black = Color3.new(0, 0, 0)

-- Instances that follow the theme: inst -> { Property = "SchemeKey" | function }.
-- Strong keys on purpose: a weak Instance key is dropped as soon as Lua stops
-- holding that Instance, even though it is still on screen.
local Registry = {}
Library.Registry = Registry
-- Gui -> function, run after a theme change, for anything that bakes colours
-- in (charts take their palette from the accent). Dropped once Gui is gone.
Library.ThemeHooks = {}

local function Resolve(Key)
	if type(Key) == "function" then
		return Key()
	end
	return Scheme[Key]
end

local function Themed(Inst, Props)
	local Entry = Registry[Inst]
	if not Entry then
		Entry = {}
		Registry[Inst] = Entry
		Inst.Destroying:Connect(function()
			Registry[Inst] = nil
		end)
	end
	for Prop, Key in Props do
		Entry[Prop] = Key
		local Value = Resolve(Key)
		if Value ~= nil then
			Inst[Prop] = Value
		end
	end
	return Inst
end

-- ============================================================
-- UTIL
-- ============================================================
local Util = {}

local Defaults = {
	Frame = { BorderSizePixel = 0, BackgroundColor3 = White },
	CanvasGroup = { BorderSizePixel = 0, BackgroundColor3 = White },
	TextLabel = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextColor3 = White,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	},
	TextButton = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		TextColor3 = White,
		TextSize = 14,
	},
	TextBox = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ClearTextOnFocus = false,
		TextColor3 = White,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
	},
	ImageLabel = { BorderSizePixel = 0, BackgroundTransparency = 1 },
	ImageButton = { BorderSizePixel = 0, BackgroundTransparency = 1, AutoButtonColor = false },
	ScrollingFrame = {
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	},
	ViewportFrame = { BorderSizePixel = 0, BackgroundTransparency = 1 },
}

-- New("Frame", { Size = ..., Parent = ..., Theme = { BackgroundColor3 = "Accent" }, childA, childB })
local function New(Class, Props)
	local Inst = Instance.new(Class)
	local Base = Defaults[Class]
	if Base then
		for K, V in Base do
			Inst[K] = V
		end
	end
	local Parent, Theme
	if Props then
		for K, V in Props do
			if K == "Parent" then
				Parent = V
			elseif K == "Theme" then
				Theme = V
			elseif type(K) == "number" then
				V.Parent = Inst
			else
				Inst[K] = V
			end
		end
	end
	if Theme then
		Themed(Inst, Theme)
	end
	if Parent then
		Inst.Parent = Parent
	end
	return Inst
end
Util.New = New

local function Corner(Parent, Radius)
	return New("UICorner", { CornerRadius = UDim.new(0, Radius or 10), Parent = Parent })
end

local function Round(Parent)
	return New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Parent })
end

local function Pad(Parent, T, R, B, L)
	return New("UIPadding", {
		PaddingTop = UDim.new(0, T or 0),
		PaddingRight = UDim.new(0, R or T or 0),
		PaddingBottom = UDim.new(0, B or T or 0),
		PaddingLeft = UDim.new(0, L or R or T or 0),
		Parent = Parent,
	})
end

local function List(Parent, Gap, Direction, HAlign, VAlign)
	return New("UIListLayout", {
		Padding = UDim.new(0, Gap or 0),
		FillDirection = Direction or Enum.FillDirection.Vertical,
		HorizontalAlignment = HAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = VAlign or Enum.VerticalAlignment.Top,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = Parent,
	})
end

local function Flex(Parent)
	local Ok, Item = pcall(New, "UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill, Parent = Parent })
	return Ok and Item or nil
end

local function FontWeight(Weight)
	return function()
		return Font.new(Scheme.Font.Family, Weight or Enum.FontWeight.Regular, Enum.FontStyle.Normal)
	end
end
local Weights = {
	Regular = FontWeight(Enum.FontWeight.Regular),
	Medium = FontWeight(Enum.FontWeight.Medium),
	SemiBold = FontWeight(Enum.FontWeight.SemiBold),
	Bold = FontWeight(Enum.FontWeight.Bold),
}

-- Text("SubText", "Medium", { ... }) -> themed TextLabel (Props.Class picks another class)
local function Text(ColorKey, Weight, Props)
	Props = Props or {}
	local Class = Props.Class or "TextLabel"
	Props.Class = nil
	local Theme = Props.Theme or {}
	Theme.TextColor3 = Theme.TextColor3 or ColorKey or "Text"
	Theme.FontFace = Weights[Weight or "Regular"]
	Props.Theme = Theme
	return New(Class, Props)
end

function Util.TextBounds(Str, Size, Weight, Width)
	local Params = Instance.new("GetTextBoundsParams")
	Params.Text = tostring(Str)
	Params.Size = Size or 14
	Params.Font = Weights[Weight or "Regular"]()
	Params.Width = Width or 100000
	local Ok, Bounds = pcall(TextService.GetTextBoundsAsync, TextService, Params)
	if Ok then
		return Bounds.X, Bounds.Y
	end
	local Fallback = TextService:GetTextSize(tostring(Str), Size or 14, Enum.Font.SourceSans, Vector2.new(Width or 100000, 100000))
	return Fallback.X, Fallback.Y
end

function Util.Clamp(V, A, B)
	if V < A then
		return A
	end
	if V > B then
		return B
	end
	return V
end

function Util.Lerp(A, B, T)
	return A + (B - A) * T
end

function Util.RoundTo(V, Decimals)
	local M = 10 ^ (Decimals or 0)
	return math.floor(V * M + 0.5) / M
end

function Util.Lighten(C, Amount)
	return C:Lerp(White, Amount)
end

function Util.Darken(C, Amount)
	return C:Lerp(Black, Amount)
end

function Util.HueShift(C, Degrees)
	local H, S, V = C:ToHSV()
	return Color3.fromHSV((H + Degrees / 360) % 1, S, V)
end

function Util.Palette(Count)
	local Out = {}
	local Steps = { 0, 42, -38, 96, 168, -110, 132, 64 }
	for I = 1, Count do
		local Shift = Steps[((I - 1) % #Steps) + 1] + math.floor((I - 1) / #Steps) * 17
		local C = Util.HueShift(Scheme.Accent, Shift)
		local H, S, V = C:ToHSV()
		Out[I] = Color3.fromHSV(H, math.max(S, 0.45), math.max(V, 0.85))
	end
	return Out
end

-- Where the screen's top-left corner sits in AbsolutePosition space. Gui
-- AbsolutePosition and the mouse/viewport don't always share an origin (the
-- topbar inset), so this is measured off a full-screen layer instead of
-- assumed. Pointer/Mouse return AbsolutePosition space; ToViewport undoes it.
function Util.Origin()
	local Frame = Util.OriginFrame
	return Frame and Frame.AbsolutePosition or Vector2.zero
end

function Util.Mouse()
	return UserInputService:GetMouseLocation() + Util.Origin()
end

function Util.ToViewport(V)
	return V - Util.Origin()
end

function Util.Pointer(Input)
	if Input and Input.UserInputType == Enum.UserInputType.Touch then
		local Inset = GuiService:GetGuiInset()
		return Vector2.new(Input.Position.X + Inset.X, Input.Position.Y + Inset.Y) + Util.Origin()
	end
	return Util.Mouse()
end

function Util.IsPress(Input)
	return Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch
end

function Util.IsMove(Input)
	return Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch
end

function Util.Inside(Gui, Point)
	if not Gui or not Gui.Parent then
		return false
	end
	local P, S = Gui.AbsolutePosition, Gui.AbsoluteSize
	return Point.X >= P.X and Point.X <= P.X + S.X and Point.Y >= P.Y and Point.Y <= P.Y + S.Y
end

-- Is this gui (and every ancestor up to the ScreenGui) visible?
function Util.Shown(Gui)
	local Node = Gui
	while Node and Node:IsA("GuiObject") do
		if not Node.Visible then
			return false
		end
		Node = Node.Parent
	end
	return Node ~= nil
end

function Util.KeyName(Key)
	if Key == nil or Key == "None" then
		return "None"
	end
	local Short = {
		MouseButton1 = "MB1",
		MouseButton2 = "MB2",
		MouseButton3 = "MB3",
		LeftShift = "LShift",
		RightShift = "RShift",
		LeftControl = "LCtrl",
		RightControl = "RCtrl",
		LeftAlt = "LAlt",
		RightAlt = "RAlt",
		Backspace = "Bksp",
		Return = "Enter",
		CapsLock = "Caps",
		Insert = "Ins",
		Delete = "Del",
		PageUp = "PgUp",
		PageDown = "PgDn",
	}
	return Short[Key] or Key
end

function Util.Hex(C)
	return string.format("#%02X%02X%02X", math.floor(C.R * 255 + 0.5), math.floor(C.G * 255 + 0.5), math.floor(C.B * 255 + 0.5))
end

function Util.FromHex(Str)
	Str = tostring(Str):gsub("#", "")
	if #Str == 3 then
		Str = Str:sub(1, 1):rep(2) .. Str:sub(2, 2):rep(2) .. Str:sub(3, 3):rep(2)
	end
	if #Str ~= 6 or not Str:match("^%x+$") then
		return nil
	end
	return Color3.fromRGB(tonumber(Str:sub(1, 2), 16), tonumber(Str:sub(3, 4), 16), tonumber(Str:sub(5, 6), 16))
end

function Util.Validate(Info, Template)
	Info = typeof(Info) == "table" and Info or {}
	for K, V in Template do
		if Info[K] == nil then
			Info[K] = V
		end
	end
	return Info
end

-- Round an axis maximum up to something that reads well on a gridline.
function Util.NiceMax(V)
	if V <= 0 then
		return 1
	end
	local Exp = math.floor(math.log10(V))
	local Base = 10 ^ Exp
	for _, Step in { 1, 1.2, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10 } do
		if V <= Step * Base then
			return Step * Base
		end
	end
	return 10 * Base
end

function Util.Short(V)
	local A = math.abs(V)
	local Out
	if A >= 1e9 then
		Out = string.format("%.1fB", V / 1e9)
	elseif A >= 1e6 then
		Out = string.format("%.1fM", V / 1e6)
	elseif A >= 1e4 then
		Out = string.format("%.1fK", V / 1e3)
	elseif A == math.floor(A) then
		return tostring(math.floor(V))
	else
		Out = string.format("%.2f", V):gsub("0+$", "")
	end
	return (Out:gsub("%.0([BMK])", "%1"):gsub("%.$", ""))
end

function Library:Give(Connection)
	table.insert(Library.Connections, Connection)
	return Connection
end

function Library:SafeCallback(Func, ...)
	if type(Func) ~= "function" then
		return
	end
	local Args = table.pack(...)
	task.spawn(function()
		local Ok, Err = pcall(Func, table.unpack(Args, 1, Args.n))
		if not Ok then
			warn("[Skibidi] callback error: " .. tostring(Err))
			if Library.NotifyOnError and Library.Notify then
				Library:Notify({ Title = "Callback error", Description = tostring(Err), Time = 5, Type = "Error" })
			end
		end
	end)
end

function Library:OnUnload(Callback)
	table.insert(Library.UnloadCallbacks, Callback)
end

Library.Util = Util

-- ============================================================
-- MOTION  (springs + cubic-bezier tweens on one render loop)
-- ============================================================
local Motion = {}
local ActiveSprings = {}
local ActiveTweens = {}
local Pack, Unpack = {}, {}

Pack.number = function(V)
	return { V }
end
Pack.Vector2 = function(V)
	return { V.X, V.Y }
end
Pack.Color3 = function(V)
	return { V.R, V.G, V.B }
end
Pack.UDim2 = function(V)
	return { V.X.Scale, V.X.Offset, V.Y.Scale, V.Y.Offset }
end
Pack.Vector3 = function(V)
	return { V.X, V.Y, V.Z }
end
Unpack.number = function(T)
	return T[1]
end
Unpack.Vector2 = function(T)
	return Vector2.new(T[1], T[2])
end
Unpack.Color3 = function(T)
	return Color3.new(Util.Clamp(T[1], 0, 1), Util.Clamp(T[2], 0, 1), Util.Clamp(T[3], 0, 1))
end
Unpack.UDim2 = function(T)
	return UDim2.new(T[1], T[2], T[3], T[4])
end
Unpack.Vector3 = function(T)
	return Vector3.new(T[1], T[2], T[3])
end

local Spring = {}
Spring.__index = Spring

-- Speed is angular frequency (higher = snappier). Damping < 1 overshoots.
function Spring.new(Initial, Speed, Damping, OnStep)
	local Kind = typeof(Initial)
	assert(Pack[Kind], "Spring can't animate " .. Kind)
	local Self = setmetatable({
		Kind = Kind,
		Speed = Speed or 18,
		Damping = Damping or 1,
		OnStep = OnStep,
	}, Spring)
	Self.X = Pack[Kind](Initial)
	Self.T = Pack[Kind](Initial)
	Self.V = table.create(#Self.X, 0)
	return Self
end

function Spring:Set(Target)
	self.T = Pack[self.Kind](Target)
	ActiveSprings[self] = true
	return self
end

function Spring:Snap(Value)
	self.X = Pack[self.Kind](Value)
	self.T = Pack[self.Kind](Value)
	self.V = table.create(#self.X, 0)
	ActiveSprings[self] = nil
	if self.OnStep then
		self.OnStep(Value, self)
	end
	return self
end

function Spring:Kick(Velocity)
	local Packed = type(Velocity) == "number" and { Velocity } or Pack[self.Kind](Velocity)
	for I = 1, #self.V do
		self.V[I] += Packed[I] or 0
	end
	ActiveSprings[self] = true
end

function Spring:Get()
	return Unpack[self.Kind](self.X)
end

function Spring:Goal()
	return Unpack[self.Kind](self.T)
end

function Spring:Velocity(I)
	return self.V[I or 1]
end

function Spring:Stop()
	ActiveSprings[self] = nil
end

Motion.Spring = Spring

-- Named feels so every surface moves the same way. Almost everything is
-- critically damped (no wobble); only the small "tactile" bits get a hint
-- of give, and even that settles in a single soft overshoot.
Motion.Feel = {
	Quick = { Speed = 30, Damping = 1 }, -- hover pills, indicators, small fades
	Smooth = { Speed = 22, Damping = 1 }, -- positions, sizes, layout glides
	Gentle = { Speed = 16, Damping = 1 }, -- big surfaces, toasts, chart data
	Tactile = { Speed = 26, Damping = 0.86 }, -- knobs, checks, press release
}

-- Spring.Feel(0, "Smooth", function(v) ... end)
function Spring.Feel(Initial, Name, OnStep)
	local F = Motion.Feel[Name] or Motion.Feel.Smooth
	return Spring.new(Initial, F.Speed, F.Damping, OnStep)
end

-- Switch an existing spring to another feel (e.g. open vs close).
function Spring:Use(Name)
	local F = Motion.Feel[Name] or Motion.Feel.Smooth
	self.Speed, self.Damping = F.Speed, F.Damping
	return self
end

-- cubic-bezier(x1, y1, x2, y2) easing, the same curves CSS glass UIs use.
function Motion.Bezier(X1, Y1, X2, Y2)
	local function Sample(A1, A2, T)
		return ((1 - 3 * A2 + 3 * A1) * T + (3 * A2 - 6 * A1)) * T * T + 3 * A1 * T
	end
	local function Slope(A1, A2, T)
		return 3 * (1 - 3 * A2 + 3 * A1) * T * T + 2 * (3 * A2 - 6 * A1) * T + 3 * A1
	end
	return function(X)
		if X <= 0 then
			return 0
		elseif X >= 1 then
			return 1
		end
		local T = X
		for _ = 1, 8 do
			local D = Slope(X1, X2, T)
			if math.abs(D) < 1e-6 then
				break
			end
			T -= (Sample(X1, X2, T) - X) / D
		end
		return Sample(Y1, Y2, Util.Clamp(T, 0, 1))
	end
end

Motion.Ease = {
	Glass = Motion.Bezier(0.22, 1, 0.36, 1), -- long, soft settle
	Soft = Motion.Bezier(0.4, 0, 0.2, 1),
	Emphasized = Motion.Bezier(0.2, 0, 0, 1),
	Exit = Motion.Bezier(0.4, 0, 0.6, 1), -- quick, even fade out (no hard stop)
	Linear = function(X)
		return X
	end,
}

-- Motion.Animate(0.4, Motion.Ease.Glass, function(alpha) ... end, onDone)
function Motion.Animate(Duration, Ease, Step, Done)
	local Handle = { Elapsed = 0, Duration = math.max(Duration, 1e-3), Ease = Ease or Motion.Ease.Glass, Step = Step, Done = Done }
	function Handle:Cancel()
		ActiveTweens[self] = nil
	end
	ActiveTweens[Handle] = true
	return Handle
end

local function LerpValue(A, B, T)
	local Kind = typeof(A)
	if Kind == "number" then
		return A + (B - A) * T
	elseif Kind == "Color3" or Kind == "UDim2" or Kind == "Vector2" or Kind == "Vector3" then
		return A:Lerp(B, T)
	elseif Kind == "UDim" then
		return UDim.new(A.Scale + (B.Scale - A.Scale) * T, A.Offset + (B.Offset - A.Offset) * T)
	end
	return T < 1 and A or B
end

-- Property tweens on bezier curves. A new tween on a property cancels the old one.
local PropTweens = setmetatable({}, { __mode = "k" })
function Motion.Tween(Inst, Props, Duration, Ease, Done)
	local Owned = PropTweens[Inst]
	if not Owned then
		Owned = {}
		PropTweens[Inst] = Owned
	end
	local From = {}
	for Prop in Props do
		From[Prop] = Inst[Prop]
		if Owned[Prop] then
			Owned[Prop]:Cancel()
		end
	end
	local Handle
	Handle = Motion.Animate(Duration or 0.3, Ease, function(A)
		for Prop, Goal in Props do
			Inst[Prop] = LerpValue(From[Prop], Goal, A)
		end
	end, function()
		for Prop in Props do
			if Owned[Prop] == Handle then
				Owned[Prop] = nil
			end
		end
		if Done then
			Done()
		end
	end)
	for Prop in Props do
		Owned[Prop] = Handle
	end
	return Handle
end

function Motion.Step(Dt)
	Dt = math.min(Dt, 1 / 15)
	local Steps = math.max(1, math.ceil(Dt * 240))
	local H = Dt / Steps

	local Snapshot = {}
	for S in ActiveSprings do
		table.insert(Snapshot, S)
	end
	for _, S in Snapshot do
		local W, Z = S.Speed, S.Damping
		local X, V, T = S.X, S.V, S.T
		local N = #X
		for _ = 1, Steps do
			for I = 1, N do
				local A = -2 * Z * W * V[I] - W * W * (X[I] - T[I])
				V[I] += A * H
				X[I] += V[I] * H
			end
		end
		local Settled = true
		for I = 1, N do
			if math.abs(X[I] - T[I]) > 1e-3 or math.abs(V[I]) > 1e-2 then
				Settled = false
				break
			end
		end
		if Settled then
			for I = 1, N do
				X[I] = T[I]
				V[I] = 0
			end
			ActiveSprings[S] = nil
		end
		if S.OnStep then
			local Ok, Err = pcall(S.OnStep, Unpack[S.Kind](X), S)
			if not Ok then
				ActiveSprings[S] = nil
				warn("[Skibidi] spring error: " .. tostring(Err))
			end
		end
	end

	local Tweens = {}
	for Tw in ActiveTweens do
		table.insert(Tweens, Tw)
	end
	for _, Tw in Tweens do
		if ActiveTweens[Tw] then
			Tw.Elapsed += Dt
			local Alpha = math.min(Tw.Elapsed / Tw.Duration, 1)
			local Ok, Err = pcall(Tw.Step, Tw.Ease(Alpha))
			if not Ok then
				warn("[Skibidi] tween error: " .. tostring(Err))
				Alpha = 1
			end
			if Alpha >= 1 then
				ActiveTweens[Tw] = nil
				if Tw.Done then
					pcall(Tw.Done)
				end
			end
		end
	end
end

-- Repeating loop helper (pulses, shimmers). Step gets seconds elapsed. Returns a stopper.
function Motion.Loop(Step)
	local Handle
	local function Run()
		Handle = Motion.Animate(3600, Motion.Ease.Linear, function(A)
			Step(A * 3600)
		end, Run)
	end
	Run()
	return function()
		Handle.Done = nil
		Handle:Cancel()
	end
end

Library.Motion = Motion

-- ============================================================
-- GLASS  (lit edges, sheen, light sweeps, shadows, hover light)
-- ============================================================
-- One light source sits above the top-left of the screen. Every glass
-- surface's edge and sheen gradient is rotated so its bright side faces
-- that point, so moving the window across the screen shifts the light a
-- little, the way a real pane catches a fixed lamp.
local Glass = {
	Lights = {},
	Dirty = true,
	LightSource = Vector2.new(0.14, -0.32), -- viewport scale; y < 0 is above the screen
}

local function KP(T, V)
	return NumberSequenceKeypoint.new(T, V)
end

-- Kept deliberately soft: the lit side reads as a highlight, not a line.
local EdgeSequence = NumberSequence.new({
	KP(0, 0.22),
	KP(0.28, 0.58),
	KP(0.55, 0.9),
	KP(0.82, 0.93),
	KP(1, 0.76),
})

function Glass.Register(Gradient, Gui, Offset)
	Glass.Lights[Gradient] = { Gui = Gui, Offset = Offset or 0 }
	Glass.Dirty = true
end

function Glass.Update()
	if not Glass.Dirty then
		return
	end
	Glass.Dirty = false
	local Camera = workspace.CurrentCamera
	local Viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
	local Light = Viewport * Glass.LightSource
	for Gradient, Entry in Glass.Lights do
		local Gui = Entry.Gui
		if not Gradient.Parent or not Gui.Parent then
			Glass.Lights[Gradient] = nil
		else
			local Center = Gui.AbsolutePosition + Gui.AbsoluteSize / 2
			local D = Light - Center
			-- keypoint 0 (the bright end) must sit on the side facing the light
			Gradient.Rotation = math.deg(math.atan2(-D.Y, -D.X)) + Entry.Offset
		end
	end
end

-- A 1px stroke that is bright where it faces the light, nearly gone on the
-- far side, with a faint rim where light would bounce back out of the glass.
function Glass.Edge(Parent, Opts)
	Opts = Opts or {}
	local Stroke = New("UIStroke", {
		Color = Opts.Color or White,
		Thickness = Opts.Thickness or 1,
		Transparency = Opts.Transparency or 0.4,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = Parent,
	})
	local Gradient = New("UIGradient", { Transparency = EdgeSequence, Rotation = 135, Parent = Stroke })
	Glass.Register(Gradient, Parent)
	return Stroke, Gradient
end

-- The broad, soft reflection a pane throws back from the same light.
function Glass.Sheen(Parent, Radius, Strength)
	local Sheen = New("Frame", {
		Name = "Sheen",
		BackgroundColor3 = White,
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 0,
		Parent = Parent,
	})
	Corner(Sheen, Radius)
	local Gradient = New("UIGradient", {
		Transparency = NumberSequence.new({
			KP(0, 1 - (Strength or 0.06)),
			KP(0.35, 1 - (Strength or 0.06) * 0.35),
			KP(0.7, 1),
			KP(1, 1),
		}),
		Parent = Sheen,
	})
	Glass.Register(Gradient, Parent)
	return Sheen
end

-- A band of light that travels across a surface once (window open, clicks).
function Glass.Sweep(Parent, Radius, Opts)
	Opts = Opts or {}
	local Holder = New("Frame", {
		Name = "Sweep",
		BackgroundColor3 = White,
		BackgroundTransparency = Opts.Fill and 0 or 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = Opts.ZIndex or 40,
		Parent = Parent,
	})
	Corner(Holder, Radius)
	local Rotation = Opts.Rotation or 115
	local Band = function(Peak)
		return NumberSequence.new({ KP(0, 1), KP(0.3, 1), KP(0.5, Peak), KP(0.7, 1), KP(1, 1) })
	end
	local Stroke = New("UIStroke", {
		Color = White,
		Thickness = Opts.Thickness or 1.25,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = Holder,
	})
	local StrokeGradient = New("UIGradient", { Transparency = Band(Opts.Peak or 0.55), Rotation = Rotation, Parent = Stroke })
	local FillGradient = Opts.Fill and New("UIGradient", { Transparency = Band(1 - Opts.Fill), Rotation = Rotation, Parent = Holder })
	local Dir = Vector2.new(math.cos(math.rad(Rotation)), math.sin(math.rad(Rotation)))
	Motion.Animate(Opts.Duration or 1.4, Motion.Ease.Soft, function(A)
		local Offset = Dir * Util.Lerp(-1.1, 1.1, A)
		StrokeGradient.Offset = Offset
		if FillGradient then
			FillGradient.Offset = Offset
		end
	end, function()
		Holder:Destroy()
	end)
	return Holder
end

function Glass.Shadow(Parent, Opts)
	Opts = Opts or {}
	return New("ImageLabel", {
		Name = "Shadow",
		Image = "rbxassetid://6014261993",
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ImageColor3 = Opts.Color or Black,
		ImageTransparency = Opts.Transparency or 0.5,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, Opts.Y or 6),
		Size = UDim2.new(1, Opts.Spread or 54, 1, Opts.Spread or 54),
		ZIndex = Opts.ZIndex or 0,
		Parent = Parent,
	})
end

-- Hover light: a soft spot that glides under the cursor across a surface,
-- clipped by the surface's own rounded corners.
function Glass.Hover(Button, Surface, Radius, Opts)
	Opts = Opts or {}
	local Strength = (Opts.Strength or 0.06) * 0.8
	local Glow = New("Frame", {
		Name = "HoverLight",
		BackgroundColor3 = White,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = Opts.ZIndex or 1,
		Parent = Surface,
	})
	Corner(Glow, Radius)
	local Gradient = New("UIGradient", { Parent = Glow })
	local function Band()
		local W = math.max(Surface.AbsoluteSize.X, 1)
		local Half = Util.Clamp((Opts.Width or 120) / W, 0.12, 0.45)
		Gradient.Transparency = NumberSequence.new({
			KP(0, 1),
			KP(0.5 - Half, 0.72),
			KP(0.5, 0),
			KP(0.5 + Half, 0.72),
			KP(1, 1),
		})
	end
	Band()
	Surface:GetPropertyChangedSignal("AbsoluteSize"):Connect(Band)

	local Offset = Spring.Feel(0, "Gentle", function(X)
		Gradient.Offset = Vector2.new(X, 0)
	end)
	local Alpha = Spring.Feel(1, "Smooth", function(A)
		Glow.BackgroundTransparency = A
	end)

	local function Track()
		local Mouse = UserInputService:GetMouseLocation()
		local W = math.max(Surface.AbsoluteSize.X, 1)
		return Util.Clamp((Mouse.X - Surface.AbsolutePosition.X) / W, 0, 1) - 0.5
	end

	local Controller = { Hovered = false, Enabled = true }
	function Controller:Set(State)
		self.Hovered = State
		Alpha:Set((State and self.Enabled) and (1 - Strength) or 1)
		if Opts.OnHover then
			Opts.OnHover(State and self.Enabled)
		end
	end
	Button.MouseEnter:Connect(function()
		Offset:Snap(Track())
		Controller:Set(true)
	end)
	Button.MouseLeave:Connect(function()
		Controller:Set(false)
	end)
	Button.MouseMoved:Connect(function()
		Offset:Set(Track())
	end)
	return Controller
end

-- Press: the surface sinks a hair while held and settles back softly
-- when released.
function Glass.Press(Button, Target, Amount)
	local Scale = New("UIScale", { Parent = Target })
	local S = Spring.Feel(1, "Quick", function(V)
		Scale.Scale = V
	end)
	Button.InputBegan:Connect(function(Input)
		if Util.IsPress(Input) then
			S:Use("Quick")
			S:Set(Amount or 0.98)
		end
	end)
	local function Release()
		S:Use("Tactile")
		S:Set(1)
	end
	Button.InputEnded:Connect(function(Input)
		if Util.IsPress(Input) then
			Release()
		end
	end)
	Button.MouseLeave:Connect(Release)
	return S
end

Library.Glass = Glass

-- ============================================================
-- ACRYLIC  (frosted blur of the 3D world behind a panel)
-- ============================================================
-- Roblox has no backdrop-filter, so the window is backed by flat Glass parts
-- a hair in front of the camera. A DepthOfField effect blurs everything that
-- close, and the glass parts pass the world through, so the world behind the
-- window comes out frosted. Rounded corners are a cross of two rectangles
-- plus four discs. It needs graphics quality around 8+ to show, which is
-- what Graphics.Boost is for.
local Acrylic = {
	Panels = {},
	Depth = 0.001,
	Suspended = {},
	Active = false,
}

local function AcrylicPart(Parent, MeshType)
	local Part = Instance.new("Part")
	Part.Name = "Pane"
	Part.Material = Enum.Material.Glass
	Part.Transparency = 1
	Part.Color = Scheme.Background
	Part.Anchored = true
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CanTouch = false
	Part.CastShadow = false
	Part.Locked = true
	Part.Size = Vector3.one
	local Mesh = Instance.new("SpecialMesh")
	Mesh.MeshType = MeshType
	Mesh.Scale = Vector3.zero
	Mesh.Parent = Part
	Part.Parent = Parent
	return Part, Mesh
end

function Acrylic.Setup()
	if Acrylic.DoF then
		return
	end
	Acrylic.DoF = New("DepthOfFieldEffect", {
		Name = "SkibidiAcrylic",
		FarIntensity = 0,
		FocusDistance = 51.6,
		InFocusRadius = 50,
		NearIntensity = 1,
		Enabled = false,
		Parent = Lighting,
	})
	Acrylic.Folder = New("Folder", { Name = "SkibidiAcrylic", Parent = workspace.CurrentCamera })
	RunService:BindToRenderStep("SkibidiAcrylic", Enum.RenderPriority.Camera.Value + 1, Acrylic.Update)
end

function Acrylic.Attach(Gui, Radius, Visible)
	Acrylic.Setup()
	local Panel = { Gui = Gui, Radius = Radius or 0, Visible = Visible, Shown = false, Parts = {} }
	for _, Key in { "H", "V" } do
		local Part, Mesh = AcrylicPart(Acrylic.Folder, Enum.MeshType.Brick)
		Panel.Parts[Key] = { Part = Part, Mesh = Mesh }
	end
	for I = 1, 4 do
		local Part, Mesh = AcrylicPart(Acrylic.Folder, Enum.MeshType.Cylinder)
		Panel.Parts["C" .. I] = { Part = Part, Mesh = Mesh }
	end
	Acrylic.Panels[Panel] = true
	function Panel:Destroy()
		Acrylic.Panels[self] = nil
		for _, P in self.Parts do
			P.Part:Destroy()
		end
	end
	return Panel
end

local function ToWorld(Camera, X, Y, Depth)
	local Ray = Camera:ViewportPointToRay(X, Y, 0)
	return Ray.Origin + Ray.Direction * Depth
end

-- The panes cover the whole window. Set Acrylic.Inset (pixels) to pull them
-- in from the edges if the blur ever smears out past the window.
function Acrylic.Bleed()
	return Acrylic.Inset or 0
end

local function SetShown(Panel, Shown)
	if Panel.Shown == Shown then
		return
	end
	Panel.Shown = Shown
	for _, P in Panel.Parts do
		P.Part.Transparency = Shown and 0.98 or 1
	end
end

function Acrylic.Place(Panel, Camera)
	local Bleed = Acrylic.Bleed(Camera)
	local Pos = Util.ToViewport(Panel.Gui.AbsolutePosition) + Vector2.one * Bleed
	local Size = Panel.Gui.AbsoluteSize - Vector2.one * (Bleed * 2)
	if Size.X < 4 or Size.Y < 4 then
		SetShown(Panel, false)
		return
	end
	local X0, Y0 = Pos.X, Pos.Y
	local X1, Y1 = Pos.X + Size.X, Pos.Y + Size.Y
	local D = Acrylic.Depth
	local TL = ToWorld(Camera, X0, Y0, D)
	local TR = ToWorld(Camera, X1, Y0, D)
	local BL = ToWorld(Camera, X0, Y1, D)
	local W, H = (TR - TL).Magnitude, (BL - TL).Magnitude
	local R = math.min(math.max(Panel.Radius - Bleed * 0.5, 0) * (W / Size.X), W / 2, H / 2)
	local Center = ToWorld(Camera, (X0 + X1) / 2, (Y0 + Y1) / 2, D)
	local CF = Camera.CFrame
	local Right, Up, Look = CF.RightVector, CF.UpVector, CF.LookVector
	local Flat = CFrame.fromMatrix(Center, Right, Up)

	local P = Panel.Parts
	P.H.Part.CFrame = Flat
	P.H.Mesh.Scale = Vector3.new(W, math.max(H - 2 * R, 0), 0)
	P.V.Part.CFrame = Flat
	P.V.Mesh.Scale = Vector3.new(math.max(W - 2 * R, 0), H, 0)
	local Corners = { { -1, 1 }, { 1, 1 }, { -1, -1 }, { 1, -1 } }
	for I, C in Corners do
		local At = Center + Right * (C[1] * (W / 2 - R)) + Up * (C[2] * (H / 2 - R))
		local Disc = P["C" .. I]
		Disc.Part.CFrame = CFrame.fromMatrix(At, Look, Up)
		Disc.Mesh.Scale = Vector3.new(0, 2 * R, 2 * R)
	end
	SetShown(Panel, true)
end

function Acrylic.Update()
	local Camera = workspace.CurrentCamera
	if not Camera or not Acrylic.Folder then
		return
	end
	if Acrylic.Folder.Parent ~= Camera then
		Acrylic.Folder.Parent = Camera
	end
	local Any = false
	for Panel in Acrylic.Panels do
		local Show = Library.AcrylicEnabled
			and Panel.Gui.Parent ~= nil
			and Util.Shown(Panel.Gui)
			and (Panel.Visible == nil or Panel.Visible())
		if Show then
			Any = true
			Acrylic.Place(Panel, Camera)
		else
			SetShown(Panel, false)
		end
	end
	if Any ~= Acrylic.Active then
		Acrylic.Active = Any
		Acrylic.SetBlur(Any)
	end
end

-- Only one depth of field reads well at a time, so the game's own effects
-- are switched off while the acrylic is showing and handed back after.
function Acrylic.SetBlur(On)
	if not Acrylic.DoF then
		return
	end
	if On then
		local Camera = workspace.CurrentCamera
		local Sources = { Lighting:GetChildren(), Camera and Camera:GetChildren() or {} }
		for _, Children in Sources do
			for _, Effect in Children do
				if Effect ~= Acrylic.DoF and Effect:IsA("DepthOfFieldEffect") and Effect.Enabled then
					Effect.Enabled = false
					table.insert(Acrylic.Suspended, Effect)
				end
			end
		end
	else
		for _, Effect in Acrylic.Suspended do
			if Effect.Parent then
				Effect.Enabled = true
			end
		end
		table.clear(Acrylic.Suspended)
	end
	Acrylic.DoF.Enabled = On
end

function Acrylic.Destroy()
	pcall(RunService.UnbindFromRenderStep, RunService, "SkibidiAcrylic")
	for Panel in Acrylic.Panels do
		Panel:Destroy()
	end
	Acrylic.SetBlur(false)
	if Acrylic.DoF then
		Acrylic.DoF:Destroy()
		Acrylic.DoF = nil
	end
	if Acrylic.Folder then
		Acrylic.Folder:Destroy()
		Acrylic.Folder = nil
	end
end

Library.Acrylic = Acrylic

-- ============================================================
-- GRAPHICS BOOST
-- ============================================================
-- Raises graphics quality for the session so the acrylic renders, and puts
-- the player's own setting back on Unload or when they leave. Because a
-- crash or force-close can skip that, the original value is also written to
-- a marker file and restored the next time the library loads.
local Graphics = {
	Boosted = false,
	Marker = "Skibidi/graphics_restore.txt",
}

local UserGameSettings
pcall(function()
	UserGameSettings = UserSettings():GetService("UserGameSettings")
end)

local function RenderSettings()
	local Ok, Rendering = pcall(function()
		return settings().Rendering
	end)
	return Ok and Rendering or nil
end

function Graphics.Quality()
	if not UserGameSettings then
		return nil
	end
	local Ok, Level = pcall(function()
		return UserGameSettings.SavedQualityLevel
	end)
	if not Ok or Level == Enum.SavedQualitySetting.Automatic then
		return nil
	end
	return Level.Value
end

function Graphics.RecoverFromCrash()
	if not FS.Available then
		return
	end
	local Ok, Exists = pcall(FS.isfile, Graphics.Marker)
	if not Ok or not Exists then
		return
	end
	local Name = FS.readfile(Graphics.Marker)
	local Level = Enum.SavedQualitySetting[Name]
	if Level and UserGameSettings then
		pcall(function()
			UserGameSettings.SavedQualityLevel = Level
		end)
	end
	pcall(FS.delfile, Graphics.Marker)
end

function Graphics.Boost()
	if Graphics.Boosted then
		return true
	end
	local Any = false
	local Rendering = RenderSettings()
	if Rendering then
		local Ok = pcall(function()
			Graphics.PrevRender = Rendering.QualityLevel
			Rendering.QualityLevel = Enum.QualityLevel.Level21
		end)
		Any = Any or Ok
	end
	if UserGameSettings then
		local Ok = pcall(function()
			local Current = UserGameSettings.SavedQualityLevel
			if Current ~= Enum.SavedQualitySetting.QualityLevel10 then
				Graphics.PrevSaved = Current
				UserGameSettings.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel10
			end
		end)
		Any = Any or Ok
	end
	if not Any then
		return false
	end
	Graphics.Boosted = true
	Graphics.UserChanged = false
	if Graphics.PrevSaved and FS.Available then
		pcall(function()
			if not FS.isfolder("Skibidi") then
				FS.makefolder("Skibidi")
			end
			FS.writefile(Graphics.Marker, Graphics.PrevSaved.Name)
		end)
	end
	if UserGameSettings and not Graphics.Watch then
		-- the player moved the slider themselves: their choice wins on restore
		Graphics.Watch = UserGameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
			if Graphics.Boosted and UserGameSettings.SavedQualityLevel ~= Enum.SavedQualitySetting.QualityLevel10 then
				Graphics.UserChanged = true
			end
		end)
	end
	return true
end

function Graphics.Restore()
	if not Graphics.Boosted then
		return
	end
	Graphics.Boosted = false
	local Rendering = RenderSettings()
	if Rendering and Graphics.PrevRender then
		pcall(function()
			Rendering.QualityLevel = Graphics.PrevRender
		end)
	end
	if UserGameSettings and Graphics.PrevSaved and not Graphics.UserChanged then
		pcall(function()
			UserGameSettings.SavedQualityLevel = Graphics.PrevSaved
		end)
	end
	Graphics.PrevSaved = nil
	Graphics.PrevRender = nil
	if Graphics.Watch then
		Graphics.Watch:Disconnect()
		Graphics.Watch = nil
	end
	if FS.Available then
		pcall(FS.delfile, Graphics.Marker)
	end
end

Graphics.RecoverFromCrash()
Library.Graphics = Graphics

-- ============================================================
-- SCREEN + RENDER LOOP
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Skibidi_" .. HttpService:GenerateGUID(false):sub(1, 8)
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 9999
pcall(function()
	ScreenGui.ScreenInsets = Enum.ScreenInsets.None
end)
pcall(protectgui, ScreenGui)
local Parented = pcall(function()
	ScreenGui.Parent = gethui and gethui() or CoreGui
end)
if not Parented or not ScreenGui.Parent then
	ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end
Library.ScreenGui = ScreenGui

local function Layer(Name, Z)
	return New("Frame", {
		Name = Name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = Z,
		Parent = ScreenGui,
	})
end
local WindowLayer = Layer("Windows", 1)
Util.OriginFrame = WindowLayer
local OverlayLayer = Layer("Overlay", 20)
local NotifyLayer = Layer("Notifications", 30)
local TooltipLayer = Layer("Tooltips", 40)

Library.CurrentScale = 1
function Util.Unscale(V)
	return V / math.max(Library.CurrentScale, 0.05)
end

Library:Give(RunService.RenderStepped:Connect(function(Dt)
	Motion.Step(Dt)
	Glass.Update()
end))

Library:Give(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Glass.Dirty = true
end))

-- ============================================================
-- INPUT HELPERS
-- ============================================================
-- Follow one press until release. OnMove gets the pointer in viewport space.
function Util.Track(Input, OnMove, OnEnd)
	local Touch = Input.UserInputType == Enum.UserInputType.Touch
	local Move, Ended
	Move = UserInputService.InputChanged:Connect(function(I)
		if (not Touch and I.UserInputType == Enum.UserInputType.MouseMovement) or (Touch and I == Input) then
			OnMove(Util.Pointer(I))
		end
	end)
	Ended = UserInputService.InputEnded:Connect(function(I)
		if (Touch and I == Input) or (not Touch and I.UserInputType == Enum.UserInputType.MouseButton1) then
			Move:Disconnect()
			Ended:Disconnect()
			if OnEnd then
				OnEnd()
			end
		end
	end)
	OnMove(Util.Pointer(Input))
end

-- Dragging never jumps: the pointer sets a goal and a spring glides to it.
-- Opts: Get() -> Vector2, Set(Vector2), Clamp(Vector2)?, Began()?, Ended()?
function Library:MakeDraggable(Handle, Opts)
	Handle.InputBegan:Connect(function(Input)
		if not Util.IsPress(Input) or (Opts.Enabled and not Opts.Enabled()) then
			return
		end
		local Start = Util.Pointer(Input)
		local Origin = Opts.Get()
		if Opts.Began then
			Opts.Began()
		end
		local Touch = Input.UserInputType == Enum.UserInputType.Touch
		local Move, Ended
		Move = UserInputService.InputChanged:Connect(function(I)
			if (not Touch and I.UserInputType == Enum.UserInputType.MouseMovement) or (Touch and I == Input) then
				local Goal = Origin + (Util.Pointer(I) - Start)
				Opts.Set(Opts.Clamp and Opts.Clamp(Goal) or Goal)
			end
		end)
		Ended = UserInputService.InputEnded:Connect(function(I)
			if (Touch and I == Input) or (not Touch and I.UserInputType == Enum.UserInputType.MouseButton1) then
				Move:Disconnect()
				Ended:Disconnect()
				if Opts.Ended then
					Opts.Ended()
				end
			end
		end)
	end)
end

-- Smooth scrolling. On desktop Roblox's own scrolling is switched off
-- (ScrollingEnabled = false): its wheel steps land on the canvas on their
-- own schedule, and undoing them afterwards showed as a little backwards hop.
-- Instead every notch moves a spring's goal, and the canvas only ever shows
-- the spring. The bar is drawn here too, on a rail beside the frame (the
-- frame's own children are usually under a UIListLayout), and can be dragged.
-- Touch keeps native scrolling, momentum and all.
Library.ScrollStep = 200
local Scrollers = setmetatable({}, { __mode = "k" })

-- the top-level layer a frame lives in, so a popup's list beats the page under it
local function LayerZ(Gui)
	local Node = Gui
	while Node.Parent and Node.Parent:IsA("GuiObject") do
		Node = Node.Parent
	end
	return Node.ZIndex
end

-- The scroller the wheel goes to: only the topmost layer under the mouse
-- counts (so a popup's list wins over the page behind it), and within it the
-- innermost one that can still move that way.
local function ScrollerAt(Point, Dir)
	local Hits, TopZ = {}, nil
	for Frame in Scrollers do
		local P, Sz = Frame.AbsolutePosition, Frame.AbsoluteSize
		if
			Point.X >= P.X
			and Point.X <= P.X + Sz.X
			and Point.Y >= P.Y
			and Point.Y <= P.Y + Sz.Y
			and Util.Shown(Frame)
		then
			local Z = LayerZ(Frame)
			Hits[Frame] = Z
			TopZ = math.max(TopZ or Z, Z)
		end
	end
	local Best
	for Frame, Z in Hits do
		if Z == TopZ and Scrollers[Frame].CanScroll(Dir) and (not Best or Frame:IsDescendantOf(Best)) then
			Best = Frame
		end
	end
	return Best and Scrollers[Best]
end

Library:Give(UserInputService.InputChanged:Connect(function(Input)
	if Input.UserInputType ~= Enum.UserInputType.MouseWheel or Input.Position.Z == 0 then
		return
	end
	local Dir = Input.Position.Z > 0 and -1 or 1
	local Ctl = ScrollerAt(Util.Mouse(), Dir)
	if Ctl then
		Ctl.Nudge(-Input.Position.Z * Library.ScrollStep * math.max(Library.CurrentScale or 1, 0.05))
	end
end))

function Util.SmoothScroll(Frame)
	local Smooth = not Library.IsMobile
	Frame.ScrollBarImageColor3 = White
	pcall(function()
		Frame.VerticalScrollBarInset = Enum.ScrollBarInset.None
	end)
	local LastActivity = 0

	local function MaxY()
		return math.max(0, Frame.AbsoluteCanvasSize.Y - Frame.AbsoluteWindowSize.Y)
	end

	if not Smooth then
		-- touch: native scrolling with a thin bar that shows while it moves
		Frame.ScrollBarThickness = 3
		Frame.ScrollBarImageTransparency = 1
		Frame:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
			LastActivity = os.clock()
			Motion.Tween(Frame, { ScrollBarImageTransparency = 0.7 }, 0.2, Motion.Ease.Soft)
			local Stamp = LastActivity
			task.delay(0.9, function()
				if LastActivity == Stamp and Frame.Parent then
					Motion.Tween(Frame, { ScrollBarImageTransparency = 1 }, 0.5, Motion.Ease.Soft)
				end
			end)
		end)
		return {
			ScrollTo = function(Y)
				Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X, Util.Clamp(Y, 0, MaxY()))
			end,
		}
	end

	Frame.ScrollingEnabled = false
	Frame.ScrollBarThickness = 0
	-- still sink the wheel so the camera doesn't zoom under the window
	Frame.Active = true

	-- the rail copies the frame's placement in its parent and holds the bar
	local Rail = New("Frame", {
		Name = "ScrollRail",
		BackgroundTransparency = 1,
		ZIndex = Frame.ZIndex + 1,
		Parent = Frame.Parent,
	})
	local function Place()
		Rail.AnchorPoint = Frame.AnchorPoint
		Rail.Position = Frame.Position
		Rail.Size = Frame.Size
		Rail.Visible = Frame.Visible
	end
	Place()
	for _, Prop in { "AnchorPoint", "Position", "Size", "Visible" } do
		Frame:GetPropertyChangedSignal(Prop):Connect(Place)
	end
	Frame.Destroying:Connect(function()
		Scrollers[Frame] = nil
		Rail:Destroy()
	end)
	local Grip = New("TextButton", {
		Name = "Grip",
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.new(0, 10, 0, 0),
		Visible = false,
		ZIndex = Rail.ZIndex,
		Parent = Rail,
	})
	local Bar = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -1, 0, 0),
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = White,
		BackgroundTransparency = 1,
		ZIndex = Rail.ZIndex,
		Parent = Grip,
	})
	Round(Bar)

	local Dragging, Hovering = false, false
	local function Reveal()
		LastActivity = os.clock()
		Motion.Tween(Bar, { BackgroundTransparency = Hovering and 0.45 or 0.7 }, 0.2, Motion.Ease.Soft)
		local Stamp = LastActivity
		task.delay(0.9, function()
			if LastActivity == Stamp and Frame.Parent and not Dragging and not Hovering then
				Motion.Tween(Bar, { BackgroundTransparency = 1 }, 0.5, Motion.Ease.Soft)
			end
		end)
	end

	-- the bar's height and travel, as fractions of the frame's height
	local function BarFit()
		local Win = Frame.AbsoluteWindowSize.Y
		local Canvas = Frame.AbsoluteCanvasSize.Y
		if Win <= 0 or Canvas <= Win + 0.5 then
			return nil
		end
		return math.max(Win / Canvas, math.min(28 / Win, 1))
	end

	local Last = 0
	local function Paint()
		local Max = MaxY()
		local Y = Util.Clamp(Last, 0, Max)
		local Ratio = BarFit()
		Grip.Visible = Ratio ~= nil
		if Ratio then
			Grip.Size = UDim2.new(0, 10, Ratio, 0)
			Grip.Position = UDim2.new(1, 0, (Max > 0 and Y / Max or 0) * (1 - Ratio), 0)
		end
	end

	local S = Spring.new(0, 17, 1, function(Y)
		Y = Util.Clamp(Y, 0, MaxY())
		Last = Y
		Frame.CanvasPosition = Vector2.new(Frame.CanvasPosition.X, Y)
		Paint()
	end)
	S:Snap(Util.Clamp(Frame.CanvasPosition.Y, 0, MaxY()))

	-- the canvas grew or shrank: keep the goal inside it
	local function Refit()
		local Max = MaxY()
		if S:Goal() > Max then
			S:Snap(math.min(S:Get(), Max))
		end
		Paint()
	end
	Frame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(Refit)
	Frame:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(Refit)

	-- dragging the bar follows the pointer exactly, no spring lag
	local From
	Library:MakeDraggable(Grip, {
		Get = function()
			return Vector2.zero
		end,
		Began = function()
			Dragging = true
			From = S:Get()
			Reveal()
		end,
		Set = function(P)
			local Ratio = BarFit()
			local Travel = Frame.AbsoluteWindowSize.Y * (1 - (Ratio or 1))
			if Travel > 0 then
				S:Snap(Util.Clamp(From + P.Y * MaxY() / Travel, 0, MaxY()))
				Reveal()
			end
		end,
		Ended = function()
			Dragging = false
			Reveal()
		end,
	})
	Grip.MouseEnter:Connect(function()
		Hovering = true
		Reveal()
	end)
	Grip.MouseLeave:Connect(function()
		Hovering = false
		Reveal()
	end)

	local Ctl = {}
	function Ctl.CanScroll(Dir)
		local Goal, Max = S:Goal(), MaxY()
		return Max > 0 and ((Dir > 0 and Goal < Max - 0.5) or (Dir < 0 and Goal > 0.5))
	end
	function Ctl.Nudge(D)
		Reveal()
		S:Set(Util.Clamp(S:Goal() + D, 0, MaxY()))
	end
	function Ctl.ScrollTo(Y, Instant)
		Y = Util.Clamp(Y, 0, MaxY())
		if Instant then
			S:Snap(Y)
		else
			S:Set(Y)
		end
	end
	Scrollers[Frame] = Ctl
	return Ctl
end

-- ============================================================
-- ICONS  (lucide via a public icon module, or raw asset ids)
-- ============================================================
local IconModule
do
	local Ok, Module = pcall(function()
		return loadstring(game:HttpGet("https://raw.githubusercontent.com/notpoiu/lucide-roblox-direct/refs/heads/main/source.lua"))()
	end)
	if Ok and type(Module) == "table" then
		IconModule = Module
	end
end

function Library:SetIconModule(Module)
	IconModule = Module
end

function Library:GetIcon(Icon)
	if Icon == nil or Icon == "" then
		return nil
	end
	if type(Icon) == "number" or (type(Icon) == "string" and tonumber(Icon)) then
		return { Url = "rbxassetid://" .. tostring(Icon) }
	end
	if type(Icon) == "string" and (Icon:find("rbxassetid://") or Icon:find("rbxasset://") or Icon:find("rbxthumb://") or Icon:find("http")) then
		return { Url = Icon }
	end
	if type(Icon) == "table" then
		return Icon
	end
	if IconModule and IconModule.GetAsset then
		local Ok, Asset = pcall(IconModule.GetAsset, Icon)
		if Ok and Asset then
			return Asset
		end
	end
	return nil
end

function Util.ApplyIcon(Image, Icon)
	local Asset = Library:GetIcon(Icon)
	if not Asset then
		Image.Visible = false
		return false
	end
	Image.Image = Asset.Url or ""
	Image.ImageRectOffset = Asset.ImageRectOffset or Vector2.zero
	Image.ImageRectSize = Asset.ImageRectSize or Vector2.zero
	Image.Visible = true
	return true
end

-- Two short strokes drawn with frames: a chevron that needs no image asset.
function Util.Chevron(Parent, Size, ColorKey)
	local Holder = New("Frame", {
		Name = "Chevron",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(Size or 12, Size or 12),
		Parent = Parent,
	})
	local Len = (Size or 12) * 0.5
	for _, Side in { -1, 1 } do
		local Leg = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, Side * Len * 0.33, 0.5, 0),
			Size = UDim2.fromOffset(Len + 1, 1.6),
			Rotation = Side * -40,
			Theme = { BackgroundColor3 = ColorKey or "SubText" },
			Parent = Holder,
		})
		Round(Leg)
	end
	return Holder
end

-- ============================================================
-- POPUPS  (click-outside closing, one stack for every overlay)
-- ============================================================
local Popups = {}

function Library:OpenPopup(Popup)
	for I = #Popups, 1, -1 do
		if Popups[I] == Popup then
			table.remove(Popups, I)
		end
	end
	table.insert(Popups, Popup)
end

function Library:ClosePopup(Popup)
	for I = #Popups, 1, -1 do
		if Popups[I] == Popup then
			table.remove(Popups, I)
		end
	end
end

function Library:CloseAllPopups()
	for I = #Popups, 1, -1 do
		local P = Popups[I]
		table.remove(Popups, I)
		pcall(P.Close)
	end
end

Library:Give(UserInputService.InputBegan:Connect(function(Input)
	if not Util.IsPress(Input) and Input.UserInputType ~= Enum.UserInputType.MouseButton2 then
		return
	end
	local Top = Popups[#Popups]
	if not Top then
		return
	end
	local Point = Util.Pointer(Input)
	if Util.Inside(Top.Frame, Point) then
		return
	end
	for _, Anchor in Top.Anchors or {} do
		if Util.Inside(Anchor, Point) then
			return
		end
	end
	Library:ClosePopup(Top)
	Top.Close()
end))

-- ============================================================
-- TOOLTIP  (one shared glass bubble that glides after the cursor)
-- ============================================================
local Tooltip = {}
do
	local Frame = New("Frame", {
		Name = "Tooltip",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = false,
		ZIndex = 5,
		Theme = { BackgroundColor3 = "Background" },
		Parent = TooltipLayer,
	})
	Corner(Frame, 8)
	Pad(Frame, 7, 11, 7, 11)
	local Stroke = Glass.Edge(Frame, { Transparency = 1 })
	local Label = Text("SubText", "Medium", {
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		TextSize = 13,
		TextWrapped = true,
		TextTransparency = 1,
		ZIndex = 6,
		Parent = Frame,
	})
	New("UISizeConstraint", { MaxSize = Vector2.new(260, 400), Parent = Label })

	local Position = Spring.Feel(Vector2.zero, "Smooth", function(P)
		Frame.Position = UDim2.fromOffset(P.X, P.Y)
	end)
	local Follow

	local function Goal()
		local M = UserInputService:GetMouseLocation()
		return Vector2.new(M.X + 14, M.Y + 18)
	end

	-- One tooltip is shared by everything. It remembers who opened it, so it can
	-- close itself when that owner is hidden (tab switch, window closed) instead
	-- of waiting for a MouseLeave that Roblox never fires for hidden frames.
	local function Lose()
		local OnLost = Tooltip.OnLost
		Tooltip.Owner, Tooltip.OnLost = nil, nil
		if OnLost then
			task.spawn(OnLost)
		end
	end

	function Tooltip.Show(Str, Owner, OnLost)
		if Tooltip.Owner ~= Owner then
			Lose()
		end
		Tooltip.Owner, Tooltip.OnLost = Owner, OnLost
		Label.Text = Str
		Position:Snap(Goal() + Vector2.new(0, 4))
		Position:Set(Goal())
		Frame.Visible = true
		Motion.Tween(Frame, { BackgroundTransparency = 0.12 }, 0.22, Motion.Ease.Glass)
		Motion.Tween(Label, { TextTransparency = 0 }, 0.22, Motion.Ease.Glass)
		Motion.Tween(Stroke, { Transparency = 0.5 }, 0.22, Motion.Ease.Glass)
		if Follow then
			Follow:Disconnect()
		end
		Follow = RunService.RenderStepped:Connect(function()
			-- MouseLeave is skipped when the cursor moves fast, so also check
			-- every frame that the cursor is still over the owner
			local Gone = Owner and (Owner.Parent == nil or not Util.Shown(Owner) or not Util.Inside(Owner, Util.Mouse()))
			if Gone or (Library.Window and not Library.Window.Visible) then
				Tooltip.Hide()
				return
			end
			Position:Set(Goal())
		end)
	end

	function Tooltip.Update(Str)
		Label.Text = Str
	end

	-- Hide(Owner) only closes the tooltip if that owner still holds it;
	-- Hide() with no owner always closes it.
	function Tooltip.Hide(Owner)
		if Owner and Owner ~= Tooltip.Owner then
			return
		end
		Lose()
		if Follow then
			Follow:Disconnect()
			Follow = nil
		end
		Motion.Tween(Frame, { BackgroundTransparency = 1 }, 0.14, Motion.Ease.Soft)
		Motion.Tween(Stroke, { Transparency = 1 }, 0.14, Motion.Ease.Soft)
		Motion.Tween(Label, { TextTransparency = 1 }, 0.14, Motion.Ease.Soft, function()
			if not Follow then
				Frame.Visible = false
			end
		end)
	end
end

function Library:HideTooltip()
	Tooltip.Hide()
end

function Library:AddTooltip(Str, DisabledStr, Hover)
	local Tip = { Text = Str, DisabledText = DisabledStr, Disabled = false }
	local Token = 0
	local function Current()
		if Tip.Disabled then
			return Tip.DisabledText
		end
		return Tip.Text
	end
	Hover.MouseEnter:Connect(function()
		Token += 1
		local Mine = Token
		task.delay(0.35, function()
			local Str2 = Current()
			if Mine == Token and Str2 and Str2 ~= "" and Util.Shown(Hover) then
				Tooltip.Show(Str2, Hover)
			end
		end)
	end)
	Hover.MouseLeave:Connect(function()
		Token += 1
		Tooltip.Hide(Hover)
	end)
	function Tip:SetText(NewText)
		self.Text = NewText
	end
	return Tip
end

-- ============================================================
-- NOTIFICATIONS
-- ============================================================
-- Toasts drift in from the screen edge on a soft spring, stack with springs
-- (so removing one lets the rest glide up), pause while hovered and drain a
-- hairline timer along the bottom.
local Notifications = { Items = {}, Width = 320, Gap = 10 }

local NotifyHolder = New("Frame", {
	Name = "Stack",
	BackgroundTransparency = 1,
	Size = UDim2.new(0, Notifications.Width, 1, -32),
	Parent = NotifyLayer,
})

function Notifications.Restack()
	local Y = 0
	for _, Item in Notifications.Items do
		Item.YSpring:Set(Y)
		Y += Item.Height + Notifications.Gap
	end
end

function Library:SetNotifySide(Side)
	Side = tostring(Side or "Right"):lower() == "left" and "Left" or "Right"
	Library.NotifySide = Side
	local Right = Side == "Right"
	NotifyHolder.AnchorPoint = Vector2.new(Right and 1 or 0, 0)
	NotifyHolder.Position = Right and UDim2.new(1, -16, 0, 16) or UDim2.new(0, 16, 0, 16)
	for _, Item in Notifications.Items do
		Item.Card.AnchorPoint = Vector2.new(Right and 1 or 0, 0)
		Item.Card.Position = UDim2.new(Right and 1 or 0, Item.XSpring:Get(), 0, Item.YSpring:Get())
	end
end
Library:SetNotifySide("Right")

local NotifyColors = {
	Info = "Accent",
	Success = "Success",
	Warning = "Warning",
	Error = "Risky",
}

function Library:Notify(...)
	local Info = ...
	local Data
	if typeof(Info) == "table" then
		Data = Info
	else
		Data = { Description = tostring(Info), Time = select(2, ...) }
	end
	Data.Time = Data.Time or 5
	local Kind = NotifyColors[Data.Type or "Info"] and (Data.Type or "Info") or "Info"
	local Right = Library.NotifySide == "Right"
	local Width = Notifications.Width
	local Inner = Width - 28 - 18

	local Title = Data.Title and tostring(Data.Title) or nil
	local Desc = Data.Description and tostring(Data.Description) or nil
	local TitleH = Title and select(2, Util.TextBounds(Title, 14, "SemiBold", Inner)) or 0
	local DescH = Desc and select(2, Util.TextBounds(Desc, 13, "Regular", Inner)) or 0
	local Height = 14 + TitleH + ((Title and Desc) and 3 or 0) + DescH + 16

	local Item = { Height = Height, Hovered = false, Dead = false }

	local Card = New("CanvasGroup", {
		Name = "Toast",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(Right and 1 or 0, 0),
		Size = UDim2.fromOffset(Width, Height),
		GroupTransparency = 1,
		Parent = NotifyHolder,
	})
	Item.Card = Card
	local Surface = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 0.1,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Card,
	})
	Corner(Surface, 12)
	Glass.Edge(Surface, { Transparency = 0.45 })
	Glass.Sheen(Surface, 12, 0.05)

	local Dot = New("Frame", {
		Position = UDim2.fromOffset(14, 14 + math.max(TitleH, 16) / 2 - 4),
		Size = UDim2.fromOffset(8, 8),
		Theme = { BackgroundColor3 = NotifyColors[Kind] },
		Parent = Surface,
	})
	Round(Dot)
	local DotGlow = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 0.88,
		Theme = { BackgroundColor3 = NotifyColors[Kind] },
		Parent = Dot,
	})
	Round(DotGlow)

	if Data.Icon then
		local Icon = New("ImageLabel", {
			Position = UDim2.fromOffset(10, 14 + math.max(TitleH, 16) / 2 - 8),
			Size = UDim2.fromOffset(16, 16),
			Theme = { ImageColor3 = NotifyColors[Kind] },
			Parent = Surface,
		})
		if Util.ApplyIcon(Icon, Data.Icon) then
			Dot.Visible = false
		end
	end

	local Y = 14
	local TitleLabel, DescLabel
	if Title then
		TitleLabel = Text("Text", "SemiBold", {
			Position = UDim2.fromOffset(32, Y),
			Size = UDim2.new(1, -46, 0, TitleH),
			Text = Title,
			TextWrapped = true,
			Parent = Surface,
		})
		Y += TitleH + 3
	end
	if Desc then
		DescLabel = Text("SubText", "Regular", {
			Position = UDim2.fromOffset(32, Y),
			Size = UDim2.new(1, -46, 0, DescH),
			Text = Desc,
			TextSize = 13,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = Surface,
		})
	end

	local Track = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -6),
		Size = UDim2.new(1, -28, 0, 2),
		BackgroundTransparency = 0.92,
		Parent = Surface,
	})
	Round(Track)
	local Fill = New("Frame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0.45,
		Theme = { BackgroundColor3 = NotifyColors[Kind] },
		Parent = Track,
	})
	Round(Fill)

	local Hit = New("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 10, Parent = Card })

	Item.XSpring = Spring.Feel((Right and 1 or -1) * 56, "Gentle", function(X)
		Card.Position = UDim2.new(Right and 1 or 0, X, 0, Item.YSpring and Item.YSpring:Get() or 0)
	end)
	Item.YSpring = Spring.Feel(0, "Gentle", function(V)
		Card.Position = UDim2.new(Right and 1 or 0, Item.XSpring:Get(), 0, V)
	end)

	table.insert(Notifications.Items, 1, Item)
	Notifications.Restack()
	Item.YSpring:Snap(0)
	Item.XSpring:Set(0)
	Motion.Tween(Card, { GroupTransparency = 0 }, 0.4, Motion.Ease.Glass)

	if Data.SoundId then
		pcall(function()
			local Sound = New("Sound", {
				SoundId = "rbxassetid://" .. tostring(Data.SoundId):gsub("%D", ""),
				Volume = Data.Volume or 1,
				PlayOnRemove = true,
				Parent = Service("SoundService"),
			})
			Sound:Destroy()
		end)
	end

	function Item:Destroy()
		if self.Dead then
			return
		end
		self.Dead = true
		for I, Other in Notifications.Items do
			if Other == self then
				table.remove(Notifications.Items, I)
				break
			end
		end
		Notifications.Restack()
		self.XSpring:Set((Right and 1 or -1) * 40)
		Motion.Tween(Card, { GroupTransparency = 1 }, 0.24, Motion.Ease.Exit, function()
			Card:Destroy()
		end)
	end
	function Item:SetTitle(Str)
		if TitleLabel then
			TitleLabel.Text = tostring(Str)
		end
	end
	function Item:SetDescription(Str)
		if DescLabel then
			DescLabel.Text = tostring(Str)
		end
	end

	Hit.MouseEnter:Connect(function()
		Item.Hovered = true
	end)
	Hit.MouseLeave:Connect(function()
		Item.Hovered = false
	end)
	Hit.Activated:Connect(function()
		if Data.Callback then
			Library:SafeCallback(Data.Callback)
		end
		if Data.Closable ~= false then
			Item:Destroy()
		end
	end)

	local Persist = Data.Persist or Data.Time == math.huge or typeof(Data.Time) == "Instance"
	if typeof(Data.Time) == "Instance" then
		Data.Time.Destroying:Connect(function()
			Item:Destroy()
		end)
	end
	task.spawn(function()
		if Persist then
			Fill.Visible = false
			return
		end
		local Total = math.max(tonumber(Data.Time) or 5, 0.1)
		local Left = Total
		while Left > 0 and not Item.Dead and not Library.Unloaded do
			local Dt = task.wait()
			if not Item.Hovered then
				Left -= Dt
			end
			Fill.Size = UDim2.fromScale(math.max(Left / Total, 0), 1)
		end
		Item:Destroy()
	end)

	return Item
end

-- ============================================================
-- DIALOG
-- ============================================================
function Library:Dialog(Info)
	Info = Util.Validate(Info, { Title = "Are you sure?", Description = "", Buttons = { { Title = "OK" } } })
	local Width = 380
	local Inner = Width - 48
	local _, TitleH = Util.TextBounds(Info.Title, 18, "Bold", Inner)
	local _, DescH = Util.TextBounds(Info.Description, 14, "Regular", Inner)
	if Info.Description == "" then
		DescH = 0
	end
	local Height = 24 + TitleH + (DescH > 0 and 8 + DescH or 0) + 22 + 36 + 22

	local Dialog = { Closed = false }
	local Backdrop = New("TextButton", {
		Name = "Dialog",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BackgroundColor3 = Black,
		ZIndex = 30,
		Parent = OverlayLayer,
	})
	local Card = New("CanvasGroup", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(Width, Height),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 31,
		Parent = Backdrop,
	})
	local Scale = New("UIScale", { Scale = 0.96, Parent = Card })
	local Surface = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 0.06,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Card,
	})
	Corner(Surface, 16)
	Glass.Edge(Surface, { Transparency = 0.4 })
	Glass.Sheen(Surface, 16, 0.05)

	Text("Text", "Bold", {
		Position = UDim2.fromOffset(24, 24),
		Size = UDim2.new(1, -48, 0, TitleH),
		Text = Info.Title,
		TextSize = 18,
		TextWrapped = true,
		Parent = Surface,
	})
	if DescH > 0 then
		Text("SubText", "Regular", {
			Position = UDim2.fromOffset(24, 24 + TitleH + 8),
			Size = UDim2.new(1, -48, 0, DescH),
			Text = Info.Description,
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			Parent = Surface,
		})
	end

	local Row = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 24, 1, -22),
		Size = UDim2.new(1, -48, 0, 36),
		BackgroundTransparency = 1,
		Parent = Surface,
	})
	List(Row, 8, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

	local ScaleSpring = Spring.Feel(0.96, "Smooth", function(V)
		Scale.Scale = V
	end)

	function Dialog:Close()
		if self.Closed then
			return
		end
		self.Closed = true
		Library:ClosePopup(Dialog.Popup)
		ScaleSpring:Set(0.97)
		Motion.Tween(Backdrop, { BackgroundTransparency = 1 }, 0.2, Motion.Ease.Exit)
		Motion.Tween(Card, { GroupTransparency = 1 }, 0.18, Motion.Ease.Exit, function()
			Backdrop:Destroy()
		end)
	end

	for I, Button in Info.Buttons do
		local Label = Button.Title or Button.Text or "OK"
		local W = Util.TextBounds(Label, 14, "SemiBold") + 34
		local Variant = Button.Variant or (I == #Info.Buttons and "Primary" or "Default")
		local B = New("TextButton", {
			Size = UDim2.fromOffset(W, 36),
			LayoutOrder = I,
			BackgroundTransparency = Variant == "Primary" and 0 or 0.9,
			Theme = {
				BackgroundColor3 = Variant == "Primary" and "Accent" or Variant == "Danger" and "Risky" or function()
					return White
				end,
			},
			Parent = Row,
		})
		if Variant == "Danger" then
			B.BackgroundTransparency = 0.78
		end
		Corner(B, 10)
		Glass.Edge(B, { Transparency = Variant == "Primary" and 0.2 or 0.5 })
		Text(Variant == "Primary" and "Background" or Variant == "Danger" and "Risky" or "Text", "SemiBold", {
			Size = UDim2.fromScale(1, 1),
			Text = Label,
			TextXAlignment = Enum.TextXAlignment.Center,
			Parent = B,
		})
		Glass.Hover(B, B, 10, { Strength = 0.08, ZIndex = 2 })
		Glass.Press(B, B)
		B.Activated:Connect(function()
			Dialog:Close()
			if Button.Callback then
				Library:SafeCallback(Button.Callback)
			end
		end)
	end

	Dialog.Popup = {
		Frame = Card,
		Close = function()
			if Info.Dismissable ~= false then
				Dialog:Close()
			else
				Library:OpenPopup(Dialog.Popup)
			end
		end,
	}
	Library:OpenPopup(Dialog.Popup)

	Motion.Tween(Backdrop, { BackgroundTransparency = 0.6 }, 0.35, Motion.Ease.Glass)
	Motion.Tween(Card, { GroupTransparency = 0 }, 0.3, Motion.Ease.Glass)
	ScaleSpring:Set(1)
	return Dialog
end

-- ============================================================
-- FLOATING PANELS  (keybind list, watermark)
-- ============================================================
-- A small draggable glass card that glides after the pointer.
local function FloatingPanel(Name, Position, OnDrag)
	local Root = New("Frame", {
		Name = Name,
		BackgroundTransparency = 0.18,
		AutomaticSize = Enum.AutomaticSize.XY,
		Visible = false,
		ZIndex = 5,
		Theme = { BackgroundColor3 = "Background" },
		Parent = WindowLayer,
	})
	Corner(Root, 12)
	Glass.Edge(Root, { Transparency = 0.4 })
	Glass.Sheen(Root, 12, 0.06)
	local Pos = Spring.Feel(Position, "Smooth", function(P)
		Root.Position = UDim2.fromOffset(P.X, P.Y)
		Glass.Dirty = true
	end)
	Pos:Snap(Position)
	Library:MakeDraggable(Root, {
		Get = function()
			return Pos:Goal()
		end,
		Began = OnDrag,
		Set = function(P)
			Pos:Set(P)
		end,
		Clamp = function(P)
			local Camera = workspace.CurrentCamera
			local V = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
			local S = Root.AbsoluteSize
			return Vector2.new(Util.Clamp(P.X, 0, math.max(V.X - S.X, 0)), Util.Clamp(P.Y, 0, math.max(V.Y - S.Y, 0)))
		end,
	})
	return Root, Pos
end

do
	local Root = FloatingPanel("Keybinds", Vector2.new(16, 260))
	Pad(Root, 12, 14, 12, 14)
	local Holder = New("Frame", {
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Parent = Root,
	})
	List(Holder, 6)
	New("UISizeConstraint", { MinSize = Vector2.new(170, 0), Parent = Holder })
	Text("Text", "SemiBold", {
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = "Keybinds",
		LayoutOrder = 0,
		Parent = Holder,
	})
	Library.KeybindFrame = Root
	Library.KeybindContainer = Holder

	function Library:UpdateKeybindFrame()
		for _, Child in Holder:GetChildren() do
			if Child.Name == "Bind" then
				Child:Destroy()
			end
		end
		local Count = 0
		for _, Picker in Library.KeyPickers do
			if not Picker.NoUI and Picker.Value ~= "None" and Picker.Text and Picker.Text ~= "" then
				Count += 1
				local Active = Picker:GetState()
				local Row = New("Frame", {
					Name = "Bind",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 20),
					AutomaticSize = Enum.AutomaticSize.X,
					LayoutOrder = Count,
					Parent = Holder,
				})
				List(Row, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
				local Dot = New("Frame", {
					Size = UDim2.fromOffset(6, 6),
					BackgroundTransparency = Active and 0 or 0.7,
					Theme = { BackgroundColor3 = Active and "Accent" or "Muted" },
					Parent = Row,
				})
				Round(Dot)
				local Chip = Text("SubText", "SemiBold", {
					Size = UDim2.fromOffset(0, 20),
					AutomaticSize = Enum.AutomaticSize.X,
					Text = Util.KeyName(Picker.Value),
					TextSize = 12,
					BackgroundTransparency = 0.9,
					BackgroundColor3 = White,
					TextXAlignment = Enum.TextXAlignment.Center,
					LayoutOrder = 1,
					Parent = Row,
				})
				Pad(Chip, 0, 7, 0, 7)
				Corner(Chip, 6)
				Text(Active and "Text" or "SubText", "Medium", {
					Size = UDim2.fromOffset(0, 20),
					AutomaticSize = Enum.AutomaticSize.X,
					Text = Picker.Text .. "  ·  " .. Picker.Mode,
					TextSize = 13,
					LayoutOrder = 2,
					Parent = Row,
				})
			end
		end
		Root.Visible = Library.ShowKeybinds and Count > 0
	end
end

do
	-- sits top-centre until it's dragged somewhere else
	local Moved = false
	local Root, Pos = FloatingPanel("Watermark", Vector2.new(16, 16), function()
		Moved = true
	end)
	Pad(Root, 8, 14, 8, 14)
	local function Place()
		if Moved then
			return
		end
		local Camera = workspace.CurrentCamera
		local V = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
		Pos:Snap(Vector2.new(math.max((V.X - Root.AbsoluteSize.X) / 2, 0), 16))
	end
	Root:GetPropertyChangedSignal("AbsoluteSize"):Connect(Place)
	WindowLayer:GetPropertyChangedSignal("AbsoluteSize"):Connect(Place)
	local Label = Text("Text", "Medium", {
		Size = UDim2.fromOffset(0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 13,
		Text = "",
		Parent = Root,
	})
	function Library:SetWatermark(Str)
		Label.Text = tostring(Str)
	end
	function Library:SetWatermarkVisibility(Visible)
		Root.Visible = Visible and true or false
		Place()
	end
	Library.Watermark = Root
end

-- ============================================================
-- ELEMENTS
-- ============================================================
-- Funcs holds every element constructor. Groups, tabbox pages and
-- dependency boxes are all "containers": they own a List frame and an
-- order counter, and inherit Funcs through their metatable.
local Funcs = {}
local AddonFuncs = {}
local Base = {}
Base.__index = Base

local ROW = 36
local RADIUS = 10

function Funcs:Next()
	self.Order = (self.Order or 0) + 1
	return self.Order
end

local function Row(Container, Height, Name)
	return New("Frame", {
		Name = Name or "Element",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Height),
		LayoutOrder = Container:Next(),
		Parent = Container.List,
	})
end

local function Register(Container, Element)
	Element.Container = Container
	table.insert(Container.Elements, Element)
	if Container.Tab then
		table.insert(Container.Tab.Elements, Element)
	end
	local Owner = Container.Group
	if Owner and Owner.AllElements then
		table.insert(Owner.AllElements, Element)
	end
	return Element
end

-- Accept (Idx, Info), (Info) with Info.Idx, or (Info, Idx).
local function Args(A, B)
	if type(A) == "table" then
		return A.Idx or B, A
	end
	return A, B or {}
end

function Library:UpdateDependencyBoxes()
	for _, Depbox in Library.DependencyBoxes do
		Depbox:Update()
	end
end

function Base:Fire()
	Library:SafeCallback(self.Callback, self.Value)
	Library:SafeCallback(self.Changed, self.Value)
	Library:UpdateDependencyBoxes()
end

function Base:OnChanged(Fn)
	self.Changed = Fn
	if self.Value ~= nil then
		Library:SafeCallback(Fn, self.Value)
	end
end

function Base:SetVisible(Visible)
	self.Visible = Visible and true or false
	self.Holder.Visible = self.Visible and not self.SearchHidden
end

function Base:SetDisabled(Disabled)
	self.Disabled = Disabled and true or false
	if self.TooltipObj then
		self.TooltipObj.Disabled = self.Disabled
	end
	if self.Hover then
		self.Hover.Enabled = not self.Disabled
	end
	if self.Dim then
		self:Dim(self.Disabled)
	end
end

function Base:Destroy()
	self.Holder:Destroy()
	if self.Idx then
		if Toggles[self.Idx] == self then
			Toggles[self.Idx] = nil
		end
		if Options[self.Idx] == self then
			Options[self.Idx] = nil
		end
	end
end

local function Tooltipify(Element, Info, Hover)
	if Info.Tooltip or Info.DisabledTooltip then
		Element.TooltipObj = Library:AddTooltip(Info.Tooltip, Info.DisabledTooltip, Hover)
		Element.TooltipObj.Disabled = Element.Disabled
	end
end

local function Meta(Methods)
	Methods.__index = function(_, K)
		return rawget(Methods, K) or AddonFuncs[K] or Base[K]
	end
	return Methods
end

-- The hover surface every row-type element shares. It hangs 8px past the
-- row on each side so text keeps its alignment with the group's padding.
local function RowSurface(Holder, Hit)
	local Surface = New("Frame", {
		Name = "Surface",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(-8, 0),
		Size = UDim2.new(1, 16, 1, 0),
		ZIndex = 0,
		Parent = Holder,
	})
	Corner(Surface, RADIUS)
	return Surface, Glass.Hover(Hit, Surface, RADIUS, { Strength = 0.045, Width = 170 })
end

-- Right-aligned strip that key pickers and color pickers dock into.
local function AddonStrip(Parent, Order)
	local Strip = New("Frame", {
		Name = "Addons",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.new(0, 0, 1, 0),
		LayoutOrder = Order or 5,
		ZIndex = 3,
		Parent = Parent,
	})
	List(Strip, 6, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
	return Strip
end

-- ------------------------------------------------------------
-- LABEL
-- ------------------------------------------------------------
local LabelMeta = Meta({})

function Funcs:AddLabel(A, B, C)
	local Info, Idx
	if type(A) == "table" then
		Info, Idx = A, A.Idx or B
	elseif type(B) == "table" then
		Idx, Info = A, B
	else
		Info, Idx = { Text = A, DoesWrap = B }, C
	end
	Info = Util.Validate(Info, { Text = "Label", DoesWrap = false, Visible = true, Size = 14 })

	local Label = setmetatable({
		Type = "Label",
		Idx = Idx,
		Text = tostring(Info.Text),
		SearchText = tostring(Info.Text),
		Visible = Info.Visible,
		Addons = {},
	}, LabelMeta)

	local Holder = Row(self, Info.DoesWrap and 0 or 24, "Label")
	local TextLabel
	if Info.DoesWrap then
		-- wrapped text sizes the row, so nothing in it may be sized by the
		-- row's height (a scale-height strip or a flex item makes Roblox's
		-- auto size feed back into itself and grow every frame). The addon
		-- strip floats top-right and the text makes room for it.
		Holder.AutomaticSize = Enum.AutomaticSize.Y
		TextLabel = Text("SubText", "Regular", {
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = Label.Text,
			TextSize = Info.Size,
			TextWrapped = true,
			RichText = true,
			Parent = Holder,
		})
		local Strip = AddonStrip(Holder, 2)
		Strip.AnchorPoint = Vector2.new(1, 0)
		Strip.Position = UDim2.fromScale(1, 0)
		Strip.Size = UDim2.fromOffset(0, 20)
		Strip:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			local W = Util.Unscale(Strip.AbsoluteSize.X)
			TextLabel.Size = UDim2.new(1, W > 0.5 and -(W + 8) or 0, 0, 0)
		end)
		Label.AddonsFrame = Strip
	else
		List(Holder, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
		TextLabel = Text("SubText", "Regular", {
			Size = UDim2.new(1, -60, 1, 0),
			Text = Label.Text,
			TextSize = Info.Size,
			RichText = true,
			TextTruncate = Enum.TextTruncate.AtEnd,
			LayoutOrder = 1,
			Parent = Holder,
		})
		Flex(TextLabel)
		Label.AddonsFrame = AddonStrip(Holder, 2)
	end
	Label.Holder = Holder
	Label.TextLabel = TextLabel

	function Label:SetText(Str)
		self.Text = tostring(Str)
		self.SearchText = self.Text
		TextLabel.Text = self.Text
	end

	Label:SetVisible(Info.Visible)
	if Idx then
		Library.Labels[Idx] = Label
	end
	return Register(self, Label)
end

-- ------------------------------------------------------------
-- PARAGRAPH / HEADER / DIVIDER
-- ------------------------------------------------------------
function Funcs:AddParagraph(A, B)
	local Info = type(A) == "table" and A or { Title = A, Content = B }
	Info = Util.Validate(Info, { Title = "", Content = "", Visible = true })
	local Paragraph = setmetatable({
		Type = "Paragraph",
		SearchText = Info.Title .. " " .. Info.Content,
		Visible = Info.Visible,
	}, Meta({}))
	local Holder = Row(self, 0, "Paragraph")
	Holder.AutomaticSize = Enum.AutomaticSize.Y
	List(Holder, 4)
	local Title = Text("Text", "SemiBold", {
		Size = UDim2.new(1, 0, 0, 18),
		Text = Info.Title,
		Visible = Info.Title ~= "",
		Parent = Holder,
	})
	local Body = Text("SubText", "Regular", {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = Info.Content,
		TextSize = 13,
		TextWrapped = true,
		RichText = true,
		LayoutOrder = 1,
		Parent = Holder,
	})
	Paragraph.Holder = Holder
	function Paragraph:SetTitle(Str)
		Title.Text = tostring(Str)
		Title.Visible = Title.Text ~= ""
	end
	function Paragraph:SetContent(Str)
		Body.Text = tostring(Str)
	end
	Paragraph:SetVisible(Info.Visible)
	return Register(self, Paragraph)
end

function Funcs:AddHeader(Str)
	local Header = setmetatable({ Type = "Header", SearchText = tostring(Str), Visible = true }, Meta({}))
	local Holder = Row(self, 26, "Header")
	Text("Muted", "SemiBold", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, 16),
		Text = tostring(Str):upper(),
		TextSize = 11,
		Parent = Holder,
	})
	Header.Holder = Holder
	return Register(self, Header)
end

function Funcs:AddDivider(Str)
	local Divider = setmetatable({ Type = "Divider", Visible = true }, Meta({}))
	local Holder = Row(self, Str and 22 or 13, "Divider")
	local Line = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = White,
		Parent = Holder,
	})
	New("UIGradient", {
		Transparency = NumberSequence.new({ KP(0, 1), KP(0.25, 0.86), KP(0.75, 0.86), KP(1, 1) }),
		Parent = Line,
	})
	if Str then
		local W = Util.TextBounds(Str, 12, "SemiBold")
		Text("Muted", "SemiBold", {
			Size = UDim2.new(0, W, 1, 0),
			Text = tostring(Str),
			TextSize = 12,
			Parent = Holder,
		})
		Line.Size = UDim2.new(1, -(W + 10), 0, 1)
	end
	Divider.Holder = Holder
	return Register(self, Divider)
end

-- ------------------------------------------------------------
-- TOGGLE  (switch, or Style = "Checkbox")
-- ------------------------------------------------------------
local ToggleMeta = Meta({})

function Funcs:AddToggle(A, B)
	local Idx, Info = Args(A, B)
	Info = Util.Validate(Info, {
		Text = "Toggle",
		Default = false,
		Style = "Switch",
		Risky = false,
		Disabled = false,
		Visible = true,
		Callback = function() end,
		Changed = function() end,
	})

	local Toggle = setmetatable({
		Type = "Toggle",
		Idx = Idx,
		Value = Info.Default == true,
		Text = Info.Text,
		SearchText = Info.Text,
		Risky = Info.Risky,
		Disabled = Info.Disabled,
		Visible = Info.Visible,
		Callback = Info.Callback,
		Changed = Info.Changed,
		Addons = {},
	}, ToggleMeta)

	local Checkbox = Info.Style == "Checkbox"
	local Holder = Row(self, ROW, "Toggle")
	local Hit = New("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = Holder })
	local _, Hover = RowSurface(Holder, Hit)
	Toggle.Hover = Hover

	local Content = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 2,
		Parent = Holder,
	})
	List(Content, 10, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)

	local Label = Text(Info.Risky and "Risky" or "Text", "Medium", {
		Size = UDim2.new(1, -120, 1, 0),
		Text = Info.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		RichText = true,
		LayoutOrder = 2,
		Parent = Content,
	})
	Flex(Label)
	Toggle.TextLabel = Label
	Toggle.AddonsFrame = AddonStrip(Content, 3)

	local Display
	if Checkbox then
		local Box = New("Frame", {
			Size = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 0.88,
			LayoutOrder = 1,
			Parent = Content,
		})
		Corner(Box, 6)
		local BoxEdge = Glass.Edge(Box, { Transparency = 0.45 })
		Glass.Sheen(Box, 6, 0.16)
		local Check = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Parent = Box,
		})
		local CheckScale = New("UIScale", { Scale = 0, Parent = Check })
		local function Leg(X, Y, Len, Rot)
			local L = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(X, Y),
				Size = UDim2.fromOffset(Len, 2.2),
				Rotation = Rot,
				Theme = { BackgroundColor3 = "Background" },
				Parent = Check,
			})
			Round(L)
		end
		Leg(7, 11.4, 5.6, 45)
		Leg(11.8, 9.6, 10.4, -48)

		local Fill = Spring.Feel(Toggle.Value and 0 or 1, "Smooth", function(A)
			-- on stays tinted glass, not a solid chip
			Box.BackgroundTransparency = Util.Lerp(0.45, 0.88, A)
			BoxEdge.Transparency = Util.Lerp(0.1, 0.45, A)
		end)
		local Mark = Spring.Feel(Toggle.Value and 1 or 0, "Tactile", function(S)
			CheckScale.Scale = math.max(S, 0)
		end)
		Themed(Box, {
			BackgroundColor3 = function()
				return Toggle.Value and Scheme.Accent or White
			end,
		})
		Display = function(Instant)
			Box.BackgroundColor3 = Toggle.Value and Scheme.Accent or White
			if Instant then
				Fill:Snap(Toggle.Value and 0 or 1)
				Mark:Snap(Toggle.Value and 1 or 0)
			else
				Fill:Set(Toggle.Value and 0 or 1)
				Mark:Set(Toggle.Value and 1 or 0)
			end
		end
	else
		local Track = New("Frame", {
			Size = UDim2.fromOffset(40, 22),
			BackgroundTransparency = 0.86,
			LayoutOrder = 4,
			Parent = Content,
		})
		Round(Track)
		local TrackEdge = Glass.Edge(Track, { Transparency = 0.5 })
		Glass.Sheen(Track, 11, 0.16)
		local Glow = Glass.Shadow(Track, { Spread = 18, Y = 0, Transparency = 1 })
		Themed(Glow, { ImageColor3 = "Accent" })
		local Knob = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0, 11, 0.5, 0),
			Size = UDim2.fromOffset(16, 16),
			ZIndex = 3,
			Parent = Track,
		})
		Round(Knob)
		Glass.Shadow(Knob, { Spread = 10, Y = 1, Transparency = 0.7, ZIndex = 2 })

		-- the knob stretches a touch with its own speed, then settles
		local KnobX = Spring.Feel(Toggle.Value and 29 or 11, "Tactile", function(X, S)
			local Stretch = math.min(math.abs(S:Velocity()) * 0.008, 3)
			Knob.Position = UDim2.new(0, X, 0.5, 0)
			Knob.Size = UDim2.fromOffset(16 + Stretch, 16 - Stretch * 0.3)
		end)
		local On = Spring.Feel(Toggle.Value and 1 or 0, "Smooth", function(A)
			Track.BackgroundColor3 = White:Lerp(Scheme.Accent, A)
			-- on stays tinted glass, not a solid pill
			Track.BackgroundTransparency = Util.Lerp(0.86, 0.48, A)
			TrackEdge.Transparency = Util.Lerp(0.5, 0.15, A)
			Glow.ImageTransparency = Util.Lerp(1, 0.8, A)
		end)
		Display = function(Instant)
			local Target = Toggle.Value and 1 or 0
			if Instant then
				KnobX:Snap(Toggle.Value and 29 or 11)
				On:Snap(Target)
			else
				KnobX:Set(Toggle.Value and 29 or 11)
				On:Set(Target)
			end
		end
		Themed(Track, {
			BackgroundColor3 = function()
				return White:Lerp(Scheme.Accent, On:Get())
			end,
		})
	end

	function Toggle:Dim(Disabled)
		Motion.Tween(Label, { TextTransparency = Disabled and 0.55 or 0 }, 0.2, Motion.Ease.Soft)
	end

	function Toggle:SetText(Str)
		self.Text = tostring(Str)
		self.SearchText = self.Text
		Label.Text = self.Text
	end

	function Toggle:SetValue(Value)
		Value = Value and true or false
		if Value == self.Value then
			return
		end
		self.Value = Value
		Display(false)
		for _, Addon in self.Addons do
			if Addon.Type == "KeyPicker" and Addon.SyncToggleState then
				Addon.Toggled = Value
				Library:UpdateKeybindFrame()
			end
		end
		self:Fire()
	end

	Hit.Activated:Connect(function()
		if not Toggle.Disabled then
			Toggle:SetValue(not Toggle.Value)
		end
	end)

	Display(true)
	Toggle.Holder = Holder
	Tooltipify(Toggle, Info, Hit)
	Toggle:SetVisible(Info.Visible)
	if Info.Disabled then
		Toggle:SetDisabled(true)
	end
	if Idx then
		Toggles[Idx] = Toggle
	end
	return Register(self, Toggle)
end

function Funcs:AddCheckbox(A, B)
	local Idx, Info = Args(A, B)
	Info.Style = "Checkbox"
	return self:AddToggle(Idx, Info)
end

-- ------------------------------------------------------------
-- BUTTON
-- ------------------------------------------------------------
local ButtonMeta = Meta({})

local function MakeButton(Container, Holder, Info, Order)
	local Button = setmetatable({
		Type = "Button",
		Text = Info.Text,
		SearchText = Info.Text,
		Func = Info.Func,
		DoubleClick = Info.DoubleClick,
		Risky = Info.Risky,
		Disabled = Info.Disabled,
		Visible = Info.Visible,
		Holder = Holder,
		Container = Container,
	}, ButtonMeta)

	local Base_ = New("TextButton", {
		Name = "Button",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 0.91,
		BackgroundColor3 = White,
		LayoutOrder = Order,
		Parent = Holder,
	})
	Flex(Base_)
	Corner(Base_, RADIUS)
	Glass.Edge(Base_, { Transparency = 0.55 })
	local Arm = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 0.82,
		Theme = { BackgroundColor3 = Info.Risky and "Risky" or "Accent" },
		Parent = Base_,
	})
	Corner(Arm, RADIUS)
	local Label = Text(Info.Risky and "Risky" or "Text", "Medium", {
		Size = UDim2.fromScale(1, 1),
		Text = Info.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 3,
		Parent = Base_,
	})
	Button.Base = Base_
	Button.TextLabel = Label
	Button.Hover = Glass.Hover(Base_, Base_, RADIUS, { Strength = 0.07, ZIndex = 2 })
	Glass.Press(Base_, Base_)

	local Armed = false
	local ArmTween
	local function Disarm()
		Armed = false
		Label.Text = Button.Text
		if ArmTween then
			ArmTween:Cancel()
		end
		Motion.Tween(Arm, { Size = UDim2.fromScale(0, 1) }, 0.25, Motion.Ease.Soft)
	end

	Base_.Activated:Connect(function()
		if Button.Disabled then
			return
		end
		if Button.DoubleClick and not Armed then
			Armed = true
			Label.Text = "Click again to confirm"
			Arm.Size = UDim2.fromScale(1, 1)
			ArmTween = Motion.Tween(Arm, { Size = UDim2.fromScale(0, 1) }, 1.8, Motion.Ease.Linear, function()
				if Armed then
					Disarm()
				end
			end)
			return
		end
		if Armed then
			Disarm()
		end
		-- a brief, soft brighten instead of a light sweep
		Base_.BackgroundTransparency = 0.85
		Motion.Tween(Base_, { BackgroundTransparency = Button.Disabled and 0.96 or 0.91 }, 0.45, Motion.Ease.Glass)
		Library:SafeCallback(Button.Func)
	end)

	function Button:SetText(Str)
		self.Text = tostring(Str)
		self.SearchText = self.Text
		Label.Text = self.Text
	end
	function Button:Dim(Disabled)
		Motion.Tween(Label, { TextTransparency = Disabled and 0.55 or 0 }, 0.2, Motion.Ease.Soft)
		Motion.Tween(Base_, { BackgroundTransparency = Disabled and 0.96 or 0.91 }, 0.2, Motion.Ease.Soft)
	end
	function Button:SetVisible(Visible)
		self.Visible = Visible and true or false
		Base_.Visible = self.Visible
	end

	-- a second button sharing this row
	function Button:AddButton(A, B)
		local SubInfo = type(A) == "table" and A or { Text = A, Func = B }
		SubInfo = Util.Validate(SubInfo, { Text = "Button", Func = function() end, Disabled = false, Visible = true })
		local Sub = MakeButton(Container, Holder, SubInfo, Order + 1)
		Sub.Type = "SubButton"
		Tooltipify(Sub, SubInfo, Sub.Base)
		if SubInfo.Disabled then
			Sub:SetDisabled(true)
		end
		if SubInfo.Idx then
			Library.Buttons[SubInfo.Idx] = Sub
		end
		return Sub
	end

	return Button
end

function Funcs:AddButton(A, B)
	local Info, Idx
	if type(A) == "table" then
		Info, Idx = A, A.Idx
	elseif type(B) == "table" then
		Idx, Info = A, B
	else
		Info = { Text = A, Func = B }
	end
	Info = Util.Validate(Info, {
		Text = "Button",
		Func = Info.Callback or function() end,
		DoubleClick = false,
		Risky = false,
		Disabled = false,
		Visible = true,
	})
	local Holder = Row(self, ROW, "Buttons")
	List(Holder, 8, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
	local Button = MakeButton(self, Holder, Info, 1)
	Button.Idx = Idx
	Tooltipify(Button, Info, Button.Base)
	if Info.Disabled then
		Button:SetDisabled(true)
	end
	Holder.Visible = Info.Visible
	if Idx then
		Library.Buttons[Idx] = Button
	end
	return Register(self, Button)
end

-- ------------------------------------------------------------
-- SLIDER
-- ------------------------------------------------------------
local SliderMeta = Meta({})

local function FormatNumber(V, Rounding)
	if Rounding <= 0 then
		return tostring(math.floor(V + 0.5))
	end
	return string.format("%." .. Rounding .. "f", V)
end

function Funcs:AddSlider(A, B)
	local Idx, Info = Args(A, B)
	Info = Util.Validate(Info, {
		Text = "Slider",
		Default = 0,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Prefix = "",
		Suffix = "",
		Compact = false,
		HideMax = true,
		Disabled = false,
		Visible = true,
		Callback = function() end,
		Changed = function() end,
	})
	local Slider = setmetatable({
		Type = "Slider",
		Idx = Idx,
		Text = Info.Text,
		SearchText = Info.Text,
		Min = Info.Min,
		Max = Info.Max,
		Rounding = Info.Rounding,
		Prefix = Info.Prefix,
		Suffix = Info.Suffix,
		HideMax = Info.HideMax,
		Value = Util.Clamp(Info.Default, Info.Min, Info.Max),
		Disabled = Info.Disabled,
		Visible = Info.Visible,
		Callback = Info.Callback,
		Changed = Info.Changed,
		FormatDisplayValue = Info.FormatDisplayValue,
	}, SliderMeta)

	local Holder = Row(self, Info.Compact and 30 or 48, "Slider")
	local Label = Text("Text", "Medium", {
		Size = UDim2.new(1, -90, 0, 18),
		Text = Info.Text,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = not Info.Compact,
		Parent = Holder,
	})
	local ValueBox = Text("SubText", "Medium", {
		Class = "TextBox",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 84, 0, 18),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		ClearTextOnFocus = false,
		Visible = not Info.Compact,
		Parent = Holder,
	})

	local Track = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 1, -9),
		Size = UDim2.new(1, 0, 0, 6),
		BackgroundTransparency = 0.88,
		Parent = Holder,
	})
	Round(Track)
	Glass.Edge(Track, { Transparency = 0.65 })
	local Fill = New("Frame", {
		Size = UDim2.fromScale(0, 1),
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Track,
	})
	Round(Fill)
	New("UIGradient", {
		Transparency = NumberSequence.new({ KP(0, 0.35), KP(1, 0) }),
		Parent = Fill,
	})
	local Knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromOffset(14, 14),
		ZIndex = 3,
		Parent = Track,
	})
	Round(Knob)
	Glass.Shadow(Knob, { Spread = 10, Y = 1, Transparency = 0.6, ZIndex = 2 })
	local KnobScale = New("UIScale", { Parent = Knob })

	local Bubble = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0, 0, 0, -10),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		ZIndex = 6,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Track,
	})
	Corner(Bubble, 7)
	Pad(Bubble, 0, 8, 0, 8)
	local BubbleEdge = Glass.Edge(Bubble, { Transparency = 1 })
	local BubbleText = Text("Text", "SemiBold", {
		Size = UDim2.fromScale(0, 1),
		AutomaticSize = Enum.AutomaticSize.X,
		TextSize = 12,
		TextTransparency = 1,
		ZIndex = 7,
		Parent = Bubble,
	})
	local BubbleScale = New("UIScale", { Scale = 0.9, Parent = Bubble })

	local Hit = New("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, -6, 1, -9),
		Size = UDim2.new(1, 12, 0, 22),
		ZIndex = 5,
		Parent = Holder,
	})

	-- the fill glides to the value instead of snapping under the cursor
	local Frac = Spring.Feel(0, "Smooth", function(F)
		Fill.Size = UDim2.fromScale(F, 1)
		Knob.Position = UDim2.fromScale(F, 0.5)
		Bubble.Position = UDim2.new(F, 0, 0, -10)
	end)
	local Grab = Spring.Feel(1, "Tactile", function(S)
		KnobScale.Scale = S
	end)
	local Pop = Spring.Feel(0.9, "Smooth", function(S)
		BubbleScale.Scale = S
	end)

	local function Format()
		if Slider.FormatDisplayValue then
			local Ok, Str = pcall(Slider.FormatDisplayValue, Slider, Slider.Value)
			if Ok and Str then
				return tostring(Str)
			end
		end
		local Str = Slider.Prefix .. FormatNumber(Slider.Value, Slider.Rounding) .. Slider.Suffix
		if not Slider.HideMax then
			Str ..= " / " .. Slider.Prefix .. FormatNumber(Slider.Max, Slider.Rounding) .. Slider.Suffix
		end
		return Str
	end

	local function Display(Instant)
		local Range = Slider.Max - Slider.Min
		local F = Range == 0 and 0 or (Slider.Value - Slider.Min) / Range
		if Instant then
			Frac:Snap(F)
		else
			Frac:Set(F)
		end
		local Str = Format()
		if not ValueBox:IsFocused() then
			ValueBox.Text = Str
		end
		BubbleText.Text = Str
	end

	local function ShowBubble(Show)
		Pop:Set(Show and 1 or 0.9)
		Motion.Tween(Bubble, { BackgroundTransparency = Show and 0.08 or 1 }, 0.18, Motion.Ease.Soft)
		Motion.Tween(BubbleText, { TextTransparency = Show and 0 or 1 }, 0.18, Motion.Ease.Soft)
		Motion.Tween(BubbleEdge, { Transparency = Show and 0.5 or 1 }, 0.18, Motion.Ease.Soft)
	end

	function Slider:SetValue(V)
		V = tonumber(V)
		if not V then
			return
		end
		V = Util.Clamp(Util.RoundTo(V, self.Rounding), self.Min, self.Max)
		if V == self.Value then
			Display(false)
			return
		end
		self.Value = V
		Display(false)
		self:Fire()
	end
	function Slider:SetMin(V)
		self.Min = V
		self.Value = Util.Clamp(self.Value, self.Min, self.Max)
		Display(false)
	end
	function Slider:SetMax(V)
		self.Max = V
		self.Value = Util.Clamp(self.Value, self.Min, self.Max)
		Display(false)
	end
	function Slider:SetPrefix(Str)
		self.Prefix = tostring(Str)
		Display(true)
	end
	function Slider:SetSuffix(Str)
		self.Suffix = tostring(Str)
		Display(true)
	end
	function Slider:SetText(Str)
		self.Text = tostring(Str)
		self.SearchText = self.Text
		Label.Text = self.Text
	end
	function Slider:Dim(Disabled)
		Motion.Tween(Label, { TextTransparency = Disabled and 0.55 or 0 }, 0.2)
		Motion.Tween(Fill, { BackgroundTransparency = Disabled and 0.6 or 0 }, 0.2)
		ValueBox.TextEditable = not Disabled
	end

	Hit.InputBegan:Connect(function(Input)
		if not Util.IsPress(Input) or Slider.Disabled then
			return
		end
		Grab:Set(1.15)
		ShowBubble(true)
		Util.Track(Input, function(P)
			local F = Util.Clamp((P.X - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1), 0, 1)
			Slider:SetValue(Slider.Min + F * (Slider.Max - Slider.Min))
		end, function()
			Grab:Set(1)
			ShowBubble(false)
		end)
	end)
	Hit.MouseEnter:Connect(function()
		if not Slider.Disabled then
			Grab:Set(1.07)
		end
	end)
	Hit.MouseLeave:Connect(function()
		if Grab:Goal() < 1.1 then
			Grab:Set(1)
		end
	end)

	ValueBox.Focused:Connect(function()
		ValueBox.Text = FormatNumber(Slider.Value, Slider.Rounding)
	end)
	ValueBox.FocusLost:Connect(function()
		local N = tonumber((ValueBox.Text:gsub("[^%d%.%-]", "")))
		if N and not Slider.Disabled then
			Slider:SetValue(N)
		end
		ValueBox.Text = Format()
	end)

	Display(true)
	Slider.Holder = Holder
	Tooltipify(Slider, Info, Hit)
	Slider:SetVisible(Info.Visible)
	if Info.Disabled then
		Slider:SetDisabled(true)
	end
	if Idx then
		Options[Idx] = Slider
	end
	return Register(self, Slider)
end

-- ------------------------------------------------------------
-- INPUT
-- ------------------------------------------------------------
local InputMeta = Meta({})

-- A glass field with a soft accent halo when focused.
local function Field(Parent, Y)
	local Frame = New("Frame", {
		Name = "Field",
		Position = UDim2.fromOffset(0, Y or 0),
		Size = UDim2.new(1, 0, 0, ROW),
		BackgroundTransparency = 0.93,
		Parent = Parent,
	})
	Corner(Frame, RADIUS)
	local Halo = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 6, 1, 6),
		BackgroundTransparency = 1,
		ZIndex = 0,
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Frame,
	})
	Corner(Halo, RADIUS + 3)
	local Stroke = Glass.Edge(Frame, { Transparency = 0.5 })
	local function Focus(On)
		Motion.Tween(Halo, { BackgroundTransparency = On and 0.9 or 1 }, 0.3, Motion.Ease.Glass)
		Motion.Tween(Stroke, { Color = On and Scheme.Accent or White, Transparency = On and 0.25 or 0.5 }, 0.3, Motion.Ease.Glass)
		Motion.Tween(Frame, { BackgroundTransparency = On and 0.9 or 0.93 }, 0.3, Motion.Ease.Glass)
	end
	return Frame, Focus
end

function Funcs:AddInput(A, B)
	local Idx, Info = Args(A, B)
	Info = Util.Validate(Info, {
		Text = "Input",
		Default = "",
		Placeholder = "",
		Numeric = false,
		Finished = false,
		ClearTextOnFocus = false,
		MaxLength = nil,
		Disabled = false,
		Visible = true,
		Callback = function() end,
		Changed = function() end,
	})
	local Input = setmetatable({
		Type = "Input",
		Idx = Idx,
		Text = Info.Text,
		SearchText = Info.Text,
		Value = tostring(Info.Default),
		Numeric = Info.Numeric,
		Finished = Info.Finished,
		MaxLength = Info.MaxLength,
		Disabled = Info.Disabled,
		Visible = Info.Visible,
		Callback = Info.Callback,
		Changed = Info.Changed,
	}, InputMeta)

	local HasLabel = Info.Text and Info.Text ~= ""
	local Top = HasLabel and 24 or 0
	local Holder = Row(self, Top + ROW, "Input")
	local Label
	if HasLabel then
		Label = Text("Text", "Medium", { Size = UDim2.new(1, 0, 0, 18), Text = Info.Text, Parent = Holder })
	end
	local Frame, Focus = Field(Holder, Top)
	local Box = Text("Text", "Regular", {
		Class = "TextBox",
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 1, 0),
		Text = Input.Value,
		PlaceholderText = Info.Placeholder,
		ClearTextOnFocus = Info.ClearTextOnFocus,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Theme = { PlaceholderColor3 = "Muted" },
		Parent = Frame,
	})
	Input.Box = Box

	local Last = Input.Value
	Box:GetPropertyChangedSignal("Text"):Connect(function()
		local T = Box.Text
		if Input.Numeric and T ~= "" and T ~= "-" and T ~= "." and T ~= "-." and not tonumber(T) then
			Box.Text = Last
			return
		end
		if Input.MaxLength and #T > Input.MaxLength then
			Box.Text = T:sub(1, Input.MaxLength)
			return
		end
		Last = T
		if not Input.Finished then
			Input:SetValue(T)
		end
	end)
	Box.Focused:Connect(function()
		if Input.Disabled then
			Box:ReleaseFocus()
			return
		end
		Focus(true)
	end)
	Box.FocusLost:Connect(function(Enter)
		Focus(false)
		if Input.Finished and Enter then
			Input:SetValue(Box.Text)
		end
	end)

	function Input:SetValue(V)
		V = tostring(V)
		if self.MaxLength and #V > self.MaxLength then
			V = V:sub(1, self.MaxLength)
		end
		if Box.Text ~= V then
			Last = V
			Box.Text = V
		end
		if V == self.Value then
			return
		end
		self.Value = V
		self:Fire()
	end
	function Input:SetText(Str)
		self.Text = tostring(Str)
		self.SearchText = self.Text
		if Label then
			Label.Text = self.Text
		end
	end
	function Input:SetPlaceholder(Str)
		Box.PlaceholderText = tostring(Str)
	end
	function Input:Dim(Disabled)
		Box.TextEditable = not Disabled
		Motion.Tween(Box, { TextTransparency = Disabled and 0.5 or 0 }, 0.2)
		if Label then
			Motion.Tween(Label, { TextTransparency = Disabled and 0.55 or 0 }, 0.2)
		end
	end

	Input.Holder = Holder
	Tooltipify(Input, Info, Frame)
	Input:SetVisible(Info.Visible)
	if Info.Disabled then
		Input:SetDisabled(true)
	end
	if Idx then
		Options[Idx] = Input
	end
	return Register(self, Input)
end

-- ------------------------------------------------------------
-- SHEETS  (floating glass panels that morph out of their anchor)
-- ------------------------------------------------------------
-- Dropdowns, color pickers and the key mode menu all open a sheet: it starts
-- as the exact rectangle of the thing you clicked and springs out to its
-- full size, then folds back into it on close.
local function Sheet(Name)
	local Root = New("CanvasGroup", {
		Name = Name,
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		Visible = false,
		ZIndex = 10,
		Parent = OverlayLayer,
	})
	local Surface = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -2, 1, -2),
		BackgroundTransparency = 0.04,
		Theme = { BackgroundColor3 = "Background" },
		Parent = Root,
	})
	Corner(Surface, 12)
	Glass.Edge(Surface, { Transparency = 0.42 })
	Glass.Sheen(Surface, 12, 0.05)
	Glass.Shadow(Root, { Spread = 30, Transparency = 0.65, Y = 4 })

	local Object = { Root = Root, Surface = Surface, Open = false }
	local Pos = Spring.new(Vector2.zero, 26, 1, function(P)
		local O = Util.Origin()
		Root.Position = UDim2.fromOffset(P.X - O.X, P.Y - O.Y)
	end)
	local Size = Spring.new(Vector2.zero, 26, 1, function(S)
		Root.Size = UDim2.fromOffset(math.max(S.X, 0), math.max(S.Y, 0))
	end)
	Object.PosSpring, Object.SizeSpring = Pos, Size

	-- Anchor: the gui it grows from. GetRect(): target position, size.
	function Object:Show(Anchor, GetRect, OnClose)
		self.Anchor = Anchor
		self.GetRect = GetRect
		self.OnClose = OnClose
		self.Open = true
		local AP, AS = Anchor.AbsolutePosition, Anchor.AbsoluteSize
		Pos:Snap(AP)
		Size:Snap(AS)
		local P, S = GetRect()
		Pos:Set(P)
		Size:Set(S)
		Root.Visible = true
		Motion.Tween(Root, { GroupTransparency = 0 }, 0.26, Motion.Ease.Glass)
		self.Popup = {
			Frame = Root,
			Anchors = { Anchor },
			Close = function()
				Object:Hide()
			end,
		}
		Library:OpenPopup(self.Popup)
		if self.Follow then
			self.Follow:Disconnect()
		end
		-- keep riding the anchor if the window glides away underneath
		self.Follow = RunService.RenderStepped:Connect(function()
			if not Anchor.Parent or not Util.Shown(Anchor) then
				Object:Hide()
				return
			end
			local NP, NS = Object.GetRect()
			Pos:Set(NP)
			Size:Set(NS)
		end)
	end

	function Object:Hide()
		if not self.Open then
			return
		end
		self.Open = false
		Library:ClosePopup(self.Popup)
		if self.Follow then
			self.Follow:Disconnect()
			self.Follow = nil
		end
		local Anchor = self.Anchor
		if Anchor and Anchor.Parent then
			Pos:Set(Anchor.AbsolutePosition)
			Size:Set(Anchor.AbsoluteSize)
		end
		Motion.Tween(Root, { GroupTransparency = 1 }, 0.16, Motion.Ease.Exit, function()
			if not Object.Open then
				Root.Visible = false
			end
		end)
		if self.OnClose then
			self.OnClose()
		end
	end

	return Object
end

-- Place a sheet of size S under (or above) an anchor, aligned to Align.
local function PlaceBelow(Anchor, S, Align)
	local Camera = workspace.CurrentCamera
	local V = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
	local AP, AS = Anchor.AbsolutePosition, Anchor.AbsoluteSize
	local X = Align == "Right" and (AP.X + AS.X - S.X) or AP.X
	local Y = AP.Y + AS.Y + 6
	if Y + S.Y > V.Y - 8 and AP.Y - 6 - S.Y > 8 then
		Y = AP.Y - 6 - S.Y
	end
	X = Util.Clamp(X, 8, math.max(V.X - S.X - 8, 8))
	return Vector2.new(X, Y), S
end

-- One highlight pill that glides between hovered rows of a list.
local function HoverPill(Parent, Height)
	local Pill = New("Frame", {
		Name = "Pill",
		BackgroundColor3 = White,
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Height),
		ZIndex = 1,
		Parent = Parent,
	})
	Corner(Pill, 8)
	local Y = Spring.Feel(0, "Quick", function(V)
		Pill.Position = UDim2.fromOffset(0, V)
	end)
	local Alpha = Spring.Feel(1, "Smooth", function(A)
		Pill.BackgroundTransparency = A
	end)
	return {
		Move = function(To, Snap)
			if Snap or Alpha:Goal() >= 1 then
				Y:Snap(To)
			else
				Y:Set(To)
			end
			Alpha:Set(0.94)
		end,
		Hide = function()
			Alpha:Set(1)
		end,
	}
end

-- ------------------------------------------------------------
-- DROPDOWN
-- ------------------------------------------------------------
local DropdownMeta = Meta({})

function Funcs:AddDropdown(A, B)
	local Idx, Info = Args(A, B)
	Info = Util.Validate(Info, {
		Text = "Dropdown",
		Values = {},
		Default = nil,
		Multi = false,
		AllowNull = false,
		Searchable = false,
		SpecialType = nil,
		ExcludeLocalPlayer = false,
		MaxVisible = 7,
		Placeholder = "Select…",
		Disabled = false,
		Visible = true,
		Callback = function() end,
		Changed = function() end,
	})

	local Dropdown = setmetatable({
		Type = "Dropdown",
		Idx = Idx,
		Text = Info.Text,
		SearchText = Info.Text,
		Values = table.clone(Info.Values),
		Multi = Info.Multi,
		AllowNull = Info.AllowNull,
		SpecialType = Info.SpecialType,
		Value = Info.Multi and {} or nil,
		Disabled = Info.Disabled,
		Visible = Info.Visible,
		Callback = Info.Callback,
		Changed = Info.Changed,
	}, DropdownMeta)

	local function SpecialValues()
		local Out = {}
		if Dropdown.SpecialType == "Player" then
			for _, P in Players:GetPlayers() do
				if not (Info.ExcludeLocalPlayer and P == LocalPlayer) then
					table.insert(Out, P.Name)
				end
			end
		elseif Dropdown.SpecialType == "Team" then
			for _, T in Teams:GetTeams() do
				table.insert(Out, T.Name)
			end
		end
		table.sort(Out, function(X, Y)
			return X:lower() < Y:lower()
		end)
		return Out
	end
	if Dropdown.SpecialType then
		Dropdown.Values = SpecialValues()
	end

	local HasLabel = Info.Text and Info.Text ~= ""
	local Top = HasLabel and 24 or 0
	local Holder = Row(self, Top + ROW, "Dropdown")
	local Label
	if HasLabel then
		Label = Text("Text", "Medium", { Size = UDim2.new(1, 0, 0, 18), Text = Info.Text, Parent = Holder })
	end
	local FieldButton = New("TextButton", {
		Name = "Field",
		Position = UDim2.fromOffset(0, Top),
		Size = UDim2.new(1, 0, 0, ROW),
		BackgroundColor3 = White,
		BackgroundTransparency = 0.93,
		Parent = Holder,
	})
	Corner(FieldButton, RADIUS)
	Glass.Edge(FieldButton, { Transparency = 0.5 })
	Dropdown.Hover = Glass.Hover(FieldButton, FieldButton, RADIUS, { Strength = 0.06, ZIndex = 1 })
	local ValueLabel = Text("Text", "Regular", {
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -44, 1, 0),
		TextTruncate = Enum.TextTruncate.AtEnd,
		ZIndex = 2,
		Parent = FieldButton,
	})
	local Chevron = Util.Chevron(FieldButton, 12, "SubText")
	Chevron.Position = UDim2.new(1, -18, 0.5, 1)
	Chevron.ZIndex = 2
	local ChevronSpin = Spring.Feel(0, "Smooth", function(R)
		Chevron.Rotation = R
	end)

	local function Ordered()
		local Out = {}
		if Dropdown.Multi then
			for _, V in Dropdown.Values do
				if Dropdown.Value[V] then
					table.insert(Out, V)
				end
			end
		elseif Dropdown.Value ~= nil then
			table.insert(Out, Dropdown.Value)
		end
		return Out
	end

	local function Display()
		local Active = Ordered()
		if #Active == 0 then
			ValueLabel.Text = Info.Placeholder
			Themed(ValueLabel, { TextColor3 = "Muted" })
			return
		end
		Themed(ValueLabel, { TextColor3 = "Text" })
		local Parts = {}
		for _, V in Active do
			table.insert(Parts, tostring(V))
		end
		local Str = table.concat(Parts, ", ")
		local Avail = Util.Unscale(FieldButton.AbsoluteSize.X) - 56
		if #Active > 1 and Avail > 0 and Util.TextBounds(Str, 14, "Regular") > Avail then
			Str = #Active .. " selected"
		end
		ValueLabel.Text = Str
	end

	function Dropdown:GetActiveValues()
		if self.Multi then
			return Ordered()
		end
		return self.Value
	end

	-- the sheet ---------------------------------------------------------------
	local ItemH, Gap = 30, 2
	local Panel = Sheet("Dropdown")
	local SearchBox
	local ListTop = 6
	if Info.Searchable then
		local SearchField = New("Frame", {
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.new(1, -12, 0, 30),
			BackgroundTransparency = 0.93,
			Parent = Panel.Surface,
		})
		Corner(SearchField, 8)
		SearchBox = Text("Text", "Regular", {
			Class = "TextBox",
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -20, 1, 0),
			PlaceholderText = "Search…",
			Text = "",
			TextSize = 13,
			Theme = { PlaceholderColor3 = "Muted" },
			Parent = SearchField,
		})
		ListTop = 42
	end
	local Scroll = New("ScrollingFrame", {
		Position = UDim2.fromOffset(0, ListTop),
		Size = UDim2.new(1, 0, 1, -ListTop),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Panel.Surface,
	})
	Util.SmoothScroll(Scroll)
	local Inner = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(6, 0),
		Size = UDim2.new(1, -12, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Scroll,
	})
	local Pill = HoverPill(Inner, ItemH)
	local Items = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
		Parent = Inner,
	})
	List(Items, Gap)
	Pad(Items, 0, 0, 6, 0)
	local Rows = {}

	local function VisibleCount()
		local N = 0
		for _, R in Rows do
			if R.Button.Visible then
				N += 1
			end
		end
		return N
	end

	local function SheetRect()
		local N = math.max(math.min(VisibleCount(), Info.MaxVisible), 1)
		local W = math.max(FieldButton.AbsoluteSize.X, 170)
		local H = ListTop + N * (ItemH + Gap) + 6
		return PlaceBelow(FieldButton, Vector2.new(W, H))
	end

	local function PaintRow(R, Instant)
		local On = Dropdown.Multi and Dropdown.Value[R.Value] or (not Dropdown.Multi and Dropdown.Value == R.Value)
		if Instant then
			R.Mark:Snap(On and 1 or 0)
		else
			R.Mark:Set(On and 1 or 0)
		end
		Themed(R.Label, {
			TextColor3 = On and "Text" or "SubText",
			FontFace = On and Weights.SemiBold or Weights.Regular,
		})
	end

	local function Build()
		for _, R in Rows do
			R.Button:Destroy()
		end
		table.clear(Rows)
		for I, V in Dropdown.Values do
			local Button = New("TextButton", {
				Size = UDim2.new(1, 0, 0, ItemH),
				LayoutOrder = I,
				Parent = Items,
			})
			local Content = New("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Parent = Button,
			})
			local Indicator
			if Dropdown.Multi then
				Indicator = New("Frame", {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 10, 0.5, 0),
					Size = UDim2.fromOffset(14, 14),
					BackgroundTransparency = 0.85,
					Parent = Content,
				})
				Corner(Indicator, 4)
				Glass.Edge(Indicator, { Transparency = 0.5 })
			else
				Indicator = New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0, 14, 0.5, 0),
					Size = UDim2.fromOffset(6, 6),
					Theme = { BackgroundColor3 = "Accent" },
					Parent = Content,
				})
				Round(Indicator)
			end
			local RowLabel = Text("SubText", "Regular", {
				Position = UDim2.fromOffset(Dropdown.Multi and 32 or 28, 0),
				Size = UDim2.new(1, -40, 1, 0),
				Text = tostring(V),
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = Content,
			})
			local R = { Value = V, Button = Button, Content = Content, Label = RowLabel }
			local IndicatorScale = New("UIScale", { Parent = Indicator })
			R.Mark = Spring.Feel(0, "Tactile", function(M)
				if Dropdown.Multi then
					Indicator.BackgroundColor3 = White:Lerp(Scheme.Accent, Util.Clamp(M, 0, 1))
					Indicator.BackgroundTransparency = Util.Lerp(0.85, 0, Util.Clamp(M, 0, 1))
					IndicatorScale.Scale = 0.85 + 0.15 * M
				else
					IndicatorScale.Scale = math.max(M, 0)
				end
			end)
			if Dropdown.Multi then
				Themed(Indicator, {
					BackgroundColor3 = function()
						return White:Lerp(Scheme.Accent, Util.Clamp(R.Mark:Get(), 0, 1))
					end,
				})
			end
			-- each row rises into place a beat after the one above it
			R.Rise = Spring.Feel(0, "Smooth", function(Y)
				Content.Position = UDim2.fromOffset(0, Y)
			end)
			PaintRow(R, true)

			Button.MouseEnter:Connect(function()
				Pill.Move(Button.AbsolutePosition.Y - Items.AbsolutePosition.Y)
			end)
			Button.Activated:Connect(function()
				if Dropdown.Multi then
					local Next = table.clone(Dropdown.Value)
					Next[V] = not Next[V] or nil
					Dropdown:SetValue(Next)
				else
					if Dropdown.Value == V and Dropdown.AllowNull then
						Dropdown:SetValue(nil)
					else
						Dropdown:SetValue(V)
					end
					Panel:Hide()
				end
			end)
			table.insert(Rows, R)
		end
	end
	Scroll.MouseLeave:Connect(Pill.Hide)

	local function Filter()
		local Query = SearchBox and SearchBox.Text:lower() or ""
		for _, R in Rows do
			R.Button.Visible = Query == "" or tostring(R.Value):lower():find(Query, 1, true) ~= nil
		end
	end
	if SearchBox then
		SearchBox:GetPropertyChangedSignal("Text"):Connect(Filter)
	end

	function Dropdown:Open()
		if self.Disabled or Panel.Open then
			return
		end
		Library:CloseAllPopups()
		Build()
		if SearchBox then
			SearchBox.Text = ""
		end
		Filter()
		Pill.Hide()
		Panel:Show(FieldButton, SheetRect, function()
			ChevronSpin:Set(0)
		end)
		ChevronSpin:Set(180)
		for I, R in Rows do
			if I > Info.MaxVisible + 2 then
				break
			end
			R.Rise:Snap(5)
			R.Label.TextTransparency = 1
			task.delay(0.02 * I, function()
				R.Rise:Set(0)
				Motion.Tween(R.Label, { TextTransparency = 0 }, 0.32, Motion.Ease.Glass)
			end)
		end
	end
	function Dropdown:Close()
		Panel:Hide()
	end

	FieldButton.Activated:Connect(function()
		if Panel.Open then
			Panel:Hide()
		else
			Dropdown:Open()
		end
	end)

	-- values ------------------------------------------------------------------
	local function Normalize(V)
		if Dropdown.Multi then
			local Out = {}
			if type(V) == "table" then
				for K, X in V do
					if type(K) == "number" then
						Out[X] = true
					elseif X then
						Out[K] = true
					end
				end
			elseif V ~= nil then
				Out[V] = true
			end
			for K in Out do
				if not table.find(Dropdown.Values, K) then
					Out[K] = nil
				end
			end
			return Out
		end
		if V ~= nil and not table.find(Dropdown.Values, V) then
			return nil
		end
		return V
	end

	function Dropdown:SetValue(V)
		self.Value = Normalize(V)
		Display()
		for _, R in Rows do
			PaintRow(R)
		end
		if Panel.Open then
			local P, S = SheetRect()
			Panel.PosSpring:Set(P)
			Panel.SizeSpring:Set(S)
		end
		self:Fire()
	end

	function Dropdown:SetValues(Values)
		self.Values = table.clone(Values or {})
		self.Value = Normalize(self.Value)
		Display()
		if Panel.Open then
			Build()
			Filter()
		end
	end

	function Dropdown:AddValues(Values)
		local Next = table.clone(self.Values)
		for _, V in typeof(Values) == "table" and Values or { Values } do
			table.insert(Next, V)
		end
		self:SetValues(Next)
	end

	function Dropdown:SetText(Str)
		self.Text = tostring(Str)
		self.SearchText = self.Text
		if Label then
			Label.Text = self.Text
		end
	end

	function Dropdown:Dim(Disabled)
		Motion.Tween(ValueLabel, { TextTransparency = Disabled and 0.5 or 0 }, 0.2)
		if Label then
			Motion.Tween(Label, { TextTransparency = Disabled and 0.55 or 0 }, 0.2)
		end
		if Disabled then
			Panel:Hide()
		end
	end

	if Dropdown.SpecialType then
		local function Refresh()
			Dropdown:SetValues(SpecialValues())
		end
		if Dropdown.SpecialType == "Player" then
			Library:Give(Players.PlayerAdded:Connect(Refresh))
			Library:Give(Players.PlayerRemoving:Connect(function()
				task.defer(Refresh)
			end))
		elseif Dropdown.SpecialType == "Team" then
			Library:Give(Teams.ChildAdded:Connect(Refresh))
			Library:Give(Teams.ChildRemoved:Connect(Refresh))
		end
	end

	-- default may be an index, a value, or (multi) a list of either
	local Default = Info.Default
	if type(Default) == "number" and Dropdown.Values[Default] ~= nil then
		Default = Dropdown.Values[Default]
	elseif type(Default) == "table" then
		local Resolved = {}
		for _, D in Default do
			table.insert(Resolved, type(D) == "number" and Dropdown.Values[D] or D)
		end
		Default = Resolved
	end
	Dropdown.Value = Normalize(Default)
	FieldButton:GetPropertyChangedSignal("AbsoluteSize"):Connect(Display)
	Display()

	Dropdown.Holder = Holder
	Tooltipify(Dropdown, Info, FieldButton)
	Dropdown:SetVisible(Info.Visible)
	if Info.Disabled then
		Dropdown:SetDisabled(true)
	end
	if Idx then
		Options[Idx] = Dropdown
	end
	return Register(self, Dropdown)
end

-- ------------------------------------------------------------
-- KEY PICKER  (docks onto a toggle or label)
-- ------------------------------------------------------------
local KeyPickerMeta = Meta({})

local function InputKey(Input)
	if Input.UserInputType == Enum.UserInputType.Keyboard then
		return Input.KeyCode.Name
	elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
		return "MB1"
	elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
		return "MB2"
	elseif Input.UserInputType == Enum.UserInputType.MouseButton3 then
		return "MB3"
	end
	return nil
end

local ModeMenu = Sheet("KeyModes")
do
	Pad(ModeMenu.Surface, 5, 5, 5, 5)
end

function AddonFuncs:AddKeyPicker(Idx, Info)
	Info = Util.Validate(Info, {
		Default = "None",
		Mode = "Toggle",
		Modes = { "Always", "Toggle", "Hold" },
		Text = self.Text or "Keybind",
		SyncToggleState = false,
		NoUI = false,
		Callback = function() end,
		ChangedCallback = function() end,
		Changed = function() end,
		Clicked = function() end,
	})
	local Parent = self
	if typeof(Info.Default) == "EnumItem" then
		Info.Default = Info.Default.Name
	end
	if Info.Mode == "Press" then
		Info.Modes = { "Press" }
	end

	local Picker = setmetatable({
		Type = "KeyPicker",
		Idx = Idx,
		Text = Info.Text,
		Value = tostring(Info.Default),
		Modifiers = {},
		Mode = Info.Mode,
		Modes = Info.Modes,
		Toggled = false,
		Holding = false,
		SyncToggleState = Info.SyncToggleState and Parent.Type == "Toggle",
		NoUI = Info.NoUI,
		Callback = Info.Callback,
		ChangedCallback = Info.ChangedCallback,
		Changed = Info.Changed,
		Clicked = Info.Clicked,
		Parent = Parent,
	}, KeyPickerMeta)
	if Picker.SyncToggleState then
		Picker.Toggled = Parent.Value
	end

	local Chip = Text("SubText", "SemiBold", {
		Class = "TextButton",
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = White,
		BackgroundTransparency = 0.9,
		TextSize = 12,
		Text = Util.KeyName(Picker.Value),
		LayoutOrder = #Parent.Addons + 1,
		Parent = Parent.AddonsFrame,
	})
	Pad(Chip, 0, 9, 0, 9)
	New("UISizeConstraint", { MinSize = Vector2.new(30, 24), Parent = Chip })
	Corner(Chip, 7)
	local ChipStroke = Glass.Edge(Chip, { Transparency = 0.5 })
	Glass.Press(Chip, Chip, 0.94)
	Picker.Chip = Chip

	local StopPulse
	local function Listen(On)
		Picker.Listening = On
		if StopPulse then
			StopPulse()
			StopPulse = nil
		end
		if On then
			Chip.Text = "…"
			ChipStroke.Color = Scheme.Accent
			-- a slow breathing ring while it waits for a key
			StopPulse = Motion.Loop(function(T)
				ChipStroke.Transparency = 0.15 + 0.35 * (0.5 + 0.5 * math.sin(T * 5))
			end)
		else
			Chip.Text = Util.KeyName(Picker.Value)
			Motion.Tween(ChipStroke, { Color = White, Transparency = 0.5 }, 0.25, Motion.Ease.Soft)
		end
	end
	Picker.Listen = Listen

	function Picker:GetState()
		if self.Mode == "Always" then
			return true
		elseif self.Mode == "Hold" then
			if self.Value == "None" then
				return false
			end
			return self.Holding
		elseif self.Mode == "Press" then
			return false
		end
		return self.Toggled
	end

	function Picker:SetValue(Data)
		local Key, Mode = Data, nil
		if type(Data) == "table" then
			Key, Mode = Data[1], Data[2]
		end
		if typeof(Key) == "EnumItem" then
			Key = Key.Name
		end
		self.Value = tostring(Key or "None")
		if Mode and table.find(self.Modes, Mode) then
			self.Mode = Mode
		end
		Chip.Text = Util.KeyName(self.Value)
		Library:SafeCallback(self.ChangedCallback, self.Value, self.Modifiers)
		Library:SafeCallback(self.Changed, self.Value, self.Modifiers)
		Library:UpdateKeybindFrame()
	end

	function Picker:OnClick(Fn)
		self.Clicked = Fn
	end
	function Picker:OnChanged(Fn)
		self.Changed = Fn
	end
	function Picker:SetMode(Mode)
		if table.find(self.Modes, Mode) then
			self.Mode = Mode
			Library:UpdateKeybindFrame()
		end
	end

	-- the bind fired (press, or release for Hold)
	function Picker:Trigger(Down)
		if Down then
			Library:SafeCallback(self.Clicked, self:GetState())
		end
		if self.Mode == "Toggle" then
			if not Down then
				return
			end
			self.Toggled = not self.Toggled
			if self.SyncToggleState then
				self.Parent:SetValue(self.Toggled)
			end
			Library:SafeCallback(self.Callback, self.Toggled)
		elseif self.Mode == "Hold" then
			self.Holding = Down
			Library:SafeCallback(self.Callback, Down)
		elseif self.Mode == "Press" and Down then
			Library:SafeCallback(self.Callback, true)
		end
		Library:UpdateKeybindFrame()
	end

	Chip.Activated:Connect(function()
		if Picker.Listening then
			return
		end
		task.defer(Listen, true)
	end)
	Chip.MouseButton2Click:Connect(function()
		if #Picker.Modes <= 1 then
			return
		end
		for _, Child in ModeMenu.Surface:GetChildren() do
			if Child:IsA("TextButton") or Child.Name == "Pill" then
				Child:Destroy()
			end
		end
		local Pill = HoverPill(ModeMenu.Surface, 28)
		for I, Mode in Picker.Modes do
			local B = Text(Picker.Mode == Mode and "Accent" or "SubText", Picker.Mode == Mode and "SemiBold" or "Medium", {
				Class = "TextButton",
				Position = UDim2.fromOffset(0, (I - 1) * 30),
				Size = UDim2.new(1, 0, 0, 28),
				Text = Mode,
				TextSize = 13,
				ZIndex = 2,
				Parent = ModeMenu.Surface,
			})
			B.MouseEnter:Connect(function()
				Pill.Move((I - 1) * 30)
			end)
			B.Activated:Connect(function()
				Picker:SetMode(Mode)
				ModeMenu:Hide()
			end)
		end
		local H = #Picker.Modes * 30 + 8
		ModeMenu:Show(Chip, function()
			return PlaceBelow(Chip, Vector2.new(112, H), "Right")
		end)
	end)

	table.insert(Parent.Addons, Picker)
	table.insert(Library.KeyPickers, Picker)
	if Idx then
		Options[Idx] = Picker
	end
	Library:UpdateKeybindFrame()
	return self
end

-- one listener for every bind
Library:Give(UserInputService.InputBegan:Connect(function(Input)
	local Key = InputKey(Input)
	if not Key then
		return
	end
	for _, Picker in Library.KeyPickers do
		if Picker.Listening then
			if Key == "Escape" then
				Picker.Listen(false)
			elseif Key == "Backspace" then
				Picker.Listen(false)
				Picker:SetValue({ "None" })
			else
				Picker.Listen(false)
				Picker:SetValue({ Key })
			end
			return
		end
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end
	local Toggle = Library.ToggleKeybind
	local ToggleKey = typeof(Toggle) == "EnumItem" and Toggle.Name or (type(Toggle) == "table" and Toggle.Value)
	if ToggleKey and Key == ToggleKey then
		Library:Toggle()
	end
	for _, Picker in Library.KeyPickers do
		if Picker.Value == Key and Picker ~= Toggle then
			Picker:Trigger(true)
		end
	end
end))

Library:Give(UserInputService.InputEnded:Connect(function(Input)
	local Key = InputKey(Input)
	if not Key then
		return
	end
	for _, Picker in Library.KeyPickers do
		if Picker.Value == Key and Picker.Mode == "Hold" and Picker.Holding then
			Picker:Trigger(false)
		end
	end
end))

-- ------------------------------------------------------------
-- COLOR PICKER  (docks onto a toggle or label)
-- ------------------------------------------------------------
local ColorPickerMeta = Meta({})
local Rainbow = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
	ColorSequenceKeypoint.new(1 / 6, Color3.fromHSV(1 / 6, 1, 1)),
	ColorSequenceKeypoint.new(2 / 6, Color3.fromHSV(2 / 6, 1, 1)),
	ColorSequenceKeypoint.new(3 / 6, Color3.fromHSV(3 / 6, 1, 1)),
	ColorSequenceKeypoint.new(4 / 6, Color3.fromHSV(4 / 6, 1, 1)),
	ColorSequenceKeypoint.new(5 / 6, Color3.fromHSV(5 / 6, 1, 1)),
	ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1)),
})

function AddonFuncs:AddColorPicker(Idx, Info)
	Info = Util.Validate(Info, {
		Default = White,
		Title = self.Text or "Color",
		Transparency = nil,
		Callback = function() end,
		Changed = function() end,
	})
	local Parent = self
	local Picker = setmetatable({
		Type = "ColorPicker",
		Idx = Idx,
		Title = Info.Title,
		Value = Info.Default,
		Transparency = Info.Transparency or 0,
		HasAlpha = Info.Transparency ~= nil,
		Callback = Info.Callback,
		Changed = Info.Changed,
		Parent = Parent,
	}, ColorPickerMeta)
	Picker.Hue, Picker.Sat, Picker.Vib = Picker.Value:ToHSV()

	local Swatch = New("TextButton", {
		Size = UDim2.fromOffset(30, 20),
		BackgroundColor3 = Picker.Value,
		LayoutOrder = #Parent.Addons + 1,
		Parent = Parent.AddonsFrame,
	})
	Corner(Swatch, 6)
	Glass.Edge(Swatch, { Transparency = 0.35 })
	Glass.Press(Swatch, Swatch, 0.92)

	-- popover -----------------------------------------------------------------
	local W, Pad_ = 236, 12
	local SVH = 148
	local Height = Pad_ + SVH + 12 + 12 + (Picker.HasAlpha and 24 or 0) + 12 + 30 + Pad_
	local Pop = Sheet("ColorPicker")
	local S = Pop.Surface

	local SV = New("Frame", {
		Position = UDim2.fromOffset(Pad_, Pad_),
		Size = UDim2.new(1, -Pad_ * 2, 0, SVH),
		Parent = S,
	})
	Corner(SV, 8)
	local WhiteLayer = New("Frame", { Size = UDim2.fromScale(1, 1), Parent = SV })
	Corner(WhiteLayer, 8)
	New("UIGradient", { Transparency = NumberSequence.new({ KP(0, 0), KP(1, 1) }), Parent = WhiteLayer })
	local BlackLayer = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Black, Parent = SV })
	Corner(BlackLayer, 8)
	New("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ KP(0, 1), KP(1, 0) }), Parent = BlackLayer })
	local SVCursor = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 0,
		ZIndex = 3,
		Parent = SV,
	})
	Round(SVCursor)
	New("UIStroke", { Color = White, Thickness = 2, Parent = SVCursor })
	local SVHit = New("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = SV })

	local function Bar(Y)
		local B = New("Frame", {
			Position = UDim2.fromOffset(Pad_, Y),
			Size = UDim2.new(1, -Pad_ * 2, 0, 12),
			Parent = S,
		})
		Round(B)
		local Cursor = New("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.fromOffset(8, 18),
			ZIndex = 3,
			Parent = B,
		})
		Round(Cursor)
		New("UIStroke", { Color = Black, Transparency = 0.6, Parent = Cursor })
		local Hit = New("TextButton", {
			Position = UDim2.fromOffset(-4, -4),
			Size = UDim2.new(1, 8, 1, 8),
			ZIndex = 4,
			Parent = B,
		})
		return B, Cursor, Hit
	end

	local HueBar, HueCursor, HueHit = Bar(Pad_ + SVH + 12)
	New("UIGradient", { Color = Rainbow, Parent = HueBar })
	local AlphaBar, AlphaCursor, AlphaHit, AlphaGradient
	if Picker.HasAlpha then
		AlphaBar, AlphaCursor, AlphaHit = Bar(Pad_ + SVH + 12 + 24)
		AlphaGradient = New("UIGradient", { Transparency = NumberSequence.new({ KP(0, 0), KP(1, 1) }), Parent = AlphaBar })
	end

	local Footer = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, Pad_, 1, -Pad_),
		Size = UDim2.new(1, -Pad_ * 2, 0, 30),
		BackgroundTransparency = 1,
		Parent = S,
	})
	local Preview = New("Frame", { Size = UDim2.fromOffset(30, 30), Parent = Footer })
	Corner(Preview, 8)
	Glass.Edge(Preview, { Transparency = 0.4 })
	local HexField = New("Frame", {
		Position = UDim2.fromOffset(38, 0),
		Size = UDim2.new(1, -38, 1, 0),
		BackgroundTransparency = 0.93,
		Parent = Footer,
	})
	Corner(HexField, 8)
	local HexBox = Text("Text", "Medium", {
		Class = "TextBox",
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, -20, 1, 0),
		TextSize = 13,
		Parent = HexField,
	})

	-- cursors glide after the pointer
	local SVPos = Spring.new(Vector2.new(Picker.Sat, 1 - Picker.Vib), 26, 1, function(P)
		SVCursor.Position = UDim2.fromScale(P.X, P.Y)
	end)
	local HuePos = Spring.new(Picker.Hue, 26, 1, function(H)
		HueCursor.Position = UDim2.fromScale(H, 0.5)
	end)
	local AlphaPos = Spring.new(Picker.Transparency, 26, 1, function(A)
		if AlphaCursor then
			AlphaCursor.Position = UDim2.fromScale(A, 0.5)
		end
	end)

	local function Paint(Instant)
		local Hue = Color3.fromHSV(Picker.Hue, 1, 1)
		SV.BackgroundColor3 = Hue
		SVCursor.BackgroundColor3 = Picker.Value
		Swatch.BackgroundColor3 = Picker.Value
		Swatch.BackgroundTransparency = Picker.Transparency * 0.8
		Preview.BackgroundColor3 = Picker.Value
		Preview.BackgroundTransparency = Picker.Transparency
		if AlphaBar then
			AlphaBar.BackgroundColor3 = Picker.Value
		end
		if not HexBox:IsFocused() then
			HexBox.Text = Util.Hex(Picker.Value) .. (Picker.HasAlpha and string.format("  %d%%", math.floor((1 - Picker.Transparency) * 100 + 0.5)) or "")
		end
		local Fn = Instant and "Snap" or "Set"
		SVPos[Fn](SVPos, Vector2.new(Picker.Sat, 1 - Picker.Vib))
		HuePos[Fn](HuePos, Picker.Hue)
		AlphaPos[Fn](AlphaPos, Picker.Transparency)
	end

	local function Commit()
		Picker.Value = Color3.fromHSV(Picker.Hue, Picker.Sat, Picker.Vib)
		Paint(false)
		Library:SafeCallback(Picker.Callback, Picker.Value, Picker.Transparency)
		Library:SafeCallback(Picker.Changed, Picker.Value, Picker.Transparency)
	end

	SVHit.InputBegan:Connect(function(Input)
		if not Util.IsPress(Input) then
			return
		end
		Util.Track(Input, function(P)
			local Rel = (P - SV.AbsolutePosition) / SV.AbsoluteSize
			Picker.Sat = Util.Clamp(Rel.X, 0, 1)
			Picker.Vib = 1 - Util.Clamp(Rel.Y, 0, 1)
			Commit()
		end)
	end)
	HueHit.InputBegan:Connect(function(Input)
		if not Util.IsPress(Input) then
			return
		end
		Util.Track(Input, function(P)
			Picker.Hue = Util.Clamp((P.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 0.9999)
			Commit()
		end)
	end)
	if AlphaHit then
		AlphaHit.InputBegan:Connect(function(Input)
			if not Util.IsPress(Input) then
				return
			end
			Util.Track(Input, function(P)
				Picker.Transparency = Util.Clamp((P.X - AlphaBar.AbsolutePosition.X) / AlphaBar.AbsoluteSize.X, 0, 1)
				Commit()
			end)
		end)
	end
	HexBox.FocusLost:Connect(function()
		local C = Util.FromHex(HexBox.Text:match("#?%x+") or "")
		if C then
			Picker.Hue, Picker.Sat, Picker.Vib = C:ToHSV()
			Commit()
		else
			Paint(true)
		end
	end)

	Swatch.Activated:Connect(function()
		if Pop.Open then
			Pop:Hide()
			return
		end
		Library:CloseAllPopups()
		Paint(true)
		Pop:Show(Swatch, function()
			return PlaceBelow(Swatch, Vector2.new(W, Height), "Right")
		end)
	end)

	function Picker:SetValueRGB(Color, Transparency)
		self.Hue, self.Sat, self.Vib = Color:ToHSV()
		if Transparency ~= nil then
			self.Transparency = Transparency
		end
		Commit()
	end
	function Picker:SetValue(HSV, Transparency)
		if typeof(HSV) == "Color3" then
			return self:SetValueRGB(HSV, Transparency)
		end
		self.Hue, self.Sat, self.Vib = HSV[1], HSV[2], HSV[3]
		if Transparency ~= nil then
			self.Transparency = Transparency
		end
		Commit()
	end
	function Picker:OnChanged(Fn)
		self.Changed = Fn
		Library:SafeCallback(Fn, self.Value, self.Transparency)
	end

	Paint(true)
	table.insert(Parent.Addons, Picker)
	if Idx then
		Options[Idx] = Picker
	end
	return self
end

-- ------------------------------------------------------------
-- PROGRESS BAR
-- ------------------------------------------------------------
function Funcs:AddProgressBar(A, B)
	local Idx, Info = Args(A, B)
	Info = Util.Validate(Info, { Text = "Progress", Value = 0, Max = 100, Suffix = "%", Rounding = 0, Visible = true, Shimmer = true })
	local Bar = setmetatable({
		Type = "ProgressBar",
		Idx = Idx,
		Text = Info.Text,
		SearchText = Info.Text,
		Value = Info.Value,
		Max = Info.Max,
		Visible = Info.Visible,
	}, Meta({}))
	local Holder = Row(self, 40, "Progress")
	local Label = Text("Text", "Medium", { Size = UDim2.new(1, -70, 0, 18), Text = Info.Text, Parent = Holder })
	local ValueLabel = Text("SubText", "Medium", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(70, 18),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = Holder,
	})
	local Track = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -4),
		Size = UDim2.new(1, 0, 0, 8),
		BackgroundTransparency = 0.88,
		Parent = Holder,
	})
	Round(Track)
	Glass.Edge(Track, { Transparency = 0.65 })
	local Fill = New("Frame", { Size = UDim2.fromScale(0, 1), Theme = { BackgroundColor3 = "Accent" }, Parent = Track })
	Round(Fill)
	local Shine = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = White, Parent = Fill })
	Round(Shine)
	local ShineGradient = New("UIGradient", {
		Transparency = NumberSequence.new({ KP(0, 1), KP(0.4, 1), KP(0.5, 0.55), KP(0.6, 1), KP(1, 1) }),
		Parent = Shine,
	})
	local FillSpring = Spring.new(0, 16, 0.9, function(F)
		Fill.Size = UDim2.fromScale(Util.Clamp(F, 0, 1), 1)
	end)
	if Info.Shimmer then
		local Stop
		Stop = Motion.Loop(function(T)
			if not Shine.Parent then
				Stop()
				return
			end
			ShineGradient.Offset = Vector2.new(((T * 0.45) % 1.6) * 1.6 - 1.3, 0)
		end)
	else
		Shine.Visible = false
	end
	function Bar:SetValue(V, Max)
		self.Value = tonumber(V) or 0
		self.Max = tonumber(Max) or self.Max
		local F = self.Max == 0 and 0 or self.Value / self.Max
		FillSpring:Set(F)
		if Info.Suffix == "%" then
			ValueLabel.Text = FormatNumber(F * 100, Info.Rounding) .. "%"
		else
			ValueLabel.Text = FormatNumber(self.Value, Info.Rounding) .. Info.Suffix
		end
	end
	function Bar:SetText(Str)
		self.Text = tostring(Str)
		self.SearchText = self.Text
		Label.Text = self.Text
	end
	Bar:SetValue(Info.Value)
	Bar.Holder = Holder
	Bar:SetVisible(Info.Visible)
	if Idx then
		Options[Idx] = Bar
	end
	return Register(self, Bar)
end

-- ------------------------------------------------------------
-- IMAGE
-- ------------------------------------------------------------
function Funcs:AddImage(A, B)
	local Idx, Info = Args(A, B)
	Info = Util.Validate(Info, { Image = "", Height = 140, ScaleType = Enum.ScaleType.Crop, Color = White, Transparency = 0, Visible = true })
	local Img = setmetatable({ Type = "Image", Idx = Idx, Visible = Info.Visible }, Meta({}))
	local Holder = Row(self, Info.Height, "Image")
	local Frame = New("ImageLabel", {
		Size = UDim2.fromScale(1, 1),
		ScaleType = Info.ScaleType,
		ImageColor3 = Info.Color,
		ImageTransparency = Info.Transparency,
		Parent = Holder,
	})
	Corner(Frame, 12)
	Glass.Edge(Frame, { Transparency = 0.5 })
	Util.ApplyIcon(Frame, Info.Image)
	Frame.Visible = true
	function Img:SetImage(Image)
		Util.ApplyIcon(Frame, Image)
		Frame.Visible = true
	end
	function Img:SetHeight(H)
		Holder.Size = UDim2.new(1, 0, 0, H)
	end
	function Img:SetColor(C)
		Frame.ImageColor3 = C
	end
	Img.Holder = Holder
	Img.Image = Frame
	Img:SetVisible(Info.Visible)
	if Idx then
		Options[Idx] = Img
	end
	return Register(self, Img)
end

-- ------------------------------------------------------------
-- VIEWPORT  (drag to orbit; the camera glides)
-- ------------------------------------------------------------
function Funcs:AddViewport(A, B)
	local Idx, Info = Args(A, B)
	Info = Util.Validate(Info, { Object = nil, Camera = nil, Clone = true, AutoFocus = true, Interactive = true, Height = 200, Visible = true })
	local VP = setmetatable({ Type = "Viewport", Idx = Idx, Visible = Info.Visible }, Meta({}))
	local Holder = Row(self, Info.Height, "Viewport")
	local Frame = New("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0.95, Parent = Holder })
	Corner(Frame, 12)
	Glass.Edge(Frame, { Transparency = 0.5 })
	local View = New("ViewportFrame", { Size = UDim2.fromScale(1, 1), Ambient = Color3.fromRGB(170, 170, 180), LightColor = White, Parent = Frame })
	Corner(View, 12)
	local Camera = Info.Camera or New("Camera", { FieldOfView = 40, Parent = View })
	View.CurrentCamera = Camera

	local Center, Distance = Vector3.zero, 10
	local Orbit = Spring.new(Vector2.new(0.6, -0.25), 14, 1, function()
		VP:Render()
	end)
	local Zoom = Spring.new(1, 14, 1, function()
		VP:Render()
	end)

	function VP:Render()
		local O = Orbit:Get()
		local Rot = CFrame.Angles(0, O.X, 0) * CFrame.Angles(Util.Clamp(O.Y, -1.4, 1.4), 0, 0)
		Camera.CFrame = CFrame.new(Center) * Rot * CFrame.new(0, 0, Distance * Zoom:Get())
	end

	function VP:Focus()
		local Obj = self.Object
		if not Obj then
			return
		end
		local CF, Size
		if Obj:IsA("Model") then
			CF, Size = Obj:GetBoundingBox()
		elseif Obj:IsA("BasePart") then
			CF, Size = Obj.CFrame, Obj.Size
		else
			return
		end
		Center = CF.Position
		Distance = Size.Magnitude / (2 * math.tan(math.rad(Camera.FieldOfView) / 2)) * 1.05
		self:Render()
	end

	function VP:SetObject(Obj, Clone)
		if self.Object and self.Owned then
			self.Object:Destroy()
		end
		self.Object, self.Owned = nil, false
		if not Obj then
			return
		end
		if Clone == nil then
			Clone = Info.Clone
		end
		if Clone then
			local Archivable = Obj.Archivable
			Obj.Archivable = true
			Obj = Obj:Clone()
			self.Owned = true
			if not Archivable then
				pcall(function()
					Obj.Archivable = false
				end)
			end
		end
		Obj.Parent = View
		self.Object = Obj
		if Info.AutoFocus then
			self:Focus()
		end
	end

	function VP:SetHeight(H)
		Holder.Size = UDim2.new(1, 0, 0, H)
	end
	function VP:SetZoom(Z)
		Zoom:Set(Util.Clamp(Z, 0.3, 4))
	end

	if Info.Interactive then
		local Hit = New("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 3, Parent = Frame })
		Hit.InputBegan:Connect(function(Input)
			if not Util.IsPress(Input) then
				return
			end
			local Start = Util.Pointer(Input)
			local From = Orbit:Goal()
			Util.Track(Input, function(P)
				local D = (P - Start) * 0.01
				Orbit:Set(Vector2.new(From.X - D.X, Util.Clamp(From.Y - D.Y, -1.4, 1.4)))
			end)
		end)
	end

	VP.Holder = Holder
	VP.Viewport = View
	VP.Camera = Camera
	if Info.Object then
		VP:SetObject(Info.Object)
	end
	VP:Render()
	VP:SetVisible(Info.Visible)
	if Idx then
		Options[Idx] = VP
	end
	return Register(self, VP)
end

-- ------------------------------------------------------------
-- DEPENDENCY BOX
-- ------------------------------------------------------------
local DepboxMeta = {}
DepboxMeta.__index = Funcs

function Funcs:AddDependencyBox()
	local Holder = Row(self, 0, "DependencyBox")
	Holder.AutomaticSize = Enum.AutomaticSize.Y
	List(Holder, 6)
	local Depbox = setmetatable({
		Type = "DependencyBox",
		Order = 0,
		Elements = {},
		Dependencies = {},
		Tab = self.Tab,
		Group = self.Group,
		List = Holder,
		Holder = Holder,
		Visible = true,
	}, DepboxMeta)

	function Depbox:Update()
		local Show = true
		for _, Dep in self.Dependencies do
			local Obj, Want = Dep[1], Dep[2]
			if Obj then
				local Ok
				if Obj.Type == "Dropdown" and Obj.Multi then
					Ok = Obj.Value[Want] == true
				else
					Ok = Obj.Value == Want
				end
				if not Ok then
					Show = false
					break
				end
			end
		end
		self.Shown = Show
		Holder.Visible = Show and self.Visible
	end
	function Depbox:SetupDependencies(Deps)
		self.Dependencies = Deps or {}
		self:Update()
	end
	function Depbox:SetVisible(V)
		self.Visible = V and true or false
		self:Update()
	end

	table.insert(Library.DependencyBoxes, Depbox)
	return Depbox
end

-- ------------------------------------------------------------
-- CHARTS  (Bar, Line, Area, Pie, Donut)
-- ------------------------------------------------------------
-- Group:AddChart("Fps", {
--     Type = "Line", Title = "Frame rate", Height = 160,
--     Labels = { "Mon", "Tue", "Wed" },
--     Series = { { Name = "FPS", Values = { 58, 61, 60 } } },   -- or Data = { 58, 61, 60 }
-- })
-- Data may also be { { Label = "A", Value = 3, Color = ... }, ... } (pie-style)
-- or a dictionary { A = 3, B = 5 }.
--
-- Bars grow in on springs with a stagger, lines draw themselves left to
-- right, pies sweep around once; hovering glides a highlight to the nearest
-- column/point/slice and the shared tooltip shows the values.
local ChartMeta = Meta({})

local function Sum(T)
	local S = 0
	for _, V in T do
		S += math.max(tonumber(V) or 0, 0)
	end
	return S
end

function Funcs:AddChart(A, B)
	local Idx, Info = Args(A, B)
	Info = Util.Validate(Info, {
		Type = "Bar",
		Height = 170,
		ShowLegend = true,
		ShowGrid = true,
		Smooth = true,
		Fill = nil,
		Dots = true,
		MaxPoints = 30,
		Prefix = "",
		Suffix = "",
		Thickness = 2.5,
		Visible = true,
	})
	if Info.Fill == nil then
		Info.Fill = Info.Type == "Area" or Info.Type == "Line"
	end

	local Chart = setmetatable({
		Type = "Chart",
		Idx = Idx,
		ChartType = Info.Type,
		SearchText = Info.Title or "Chart",
		Visible = Info.Visible,
		Labels = {},
		Series = {},
	}, ChartMeta)

	local Holder = Row(self, 0, "Chart")
	Holder.AutomaticSize = Enum.AutomaticSize.Y
	List(Holder, 10)

	local TitleLabel, SubLabel
	if Info.Title or Info.Subtitle then
		local Head = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 20), Parent = Holder })
		TitleLabel = Text("Text", "SemiBold", { Size = UDim2.new(0.6, 0, 1, 0), Text = Info.Title or "", Parent = Head })
		SubLabel = Text("Muted", "Medium", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0.4, 0, 1, 0),
			Text = Info.Subtitle or "",
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Right,
			Parent = Head,
		})
	end

	local Plot = New("Frame", {
		Name = "Plot",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, Info.Height),
		LayoutOrder = 2,
		Parent = Holder,
	})
	local Legend = New("Frame", {
		Name = "Legend",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = 3,
		Parent = Holder,
	})
	local LegendLayout = List(Legend, 14, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
	pcall(function()
		LegendLayout.Wraps = true
	end)

	-- data ----------------------------------------------------------------
	local function Normalize(Data, Labels, Series)
		local L, S = {}, {}
		if Series then
			for I, Entry in Series do
				S[I] = {
					Name = Entry.Name or ("Series " .. I),
					Values = table.clone(Entry.Values or {}),
					Color = Entry.Color,
					Colors = Entry.Colors or {},
				}
			end
			L = table.clone(Labels or {})
		elseif type(Data) == "table" then
			local First = Data[1]
			if type(First) == "table" and First.Values then
				return Normalize(nil, Labels, Data)
			elseif type(First) == "table" then
				local V, C = {}, {}
				for I, D in Data do
					L[I] = tostring(D.Label or D.Name or D[1] or I)
					V[I] = tonumber(D.Value or D[2]) or 0
					C[I] = D.Color
				end
				S[1] = { Name = Info.Title or "Value", Values = V, Colors = C }
			elseif First ~= nil then
				S[1] = { Name = Info.Title or "Value", Values = table.clone(Data), Colors = {} }
				L = table.clone(Labels or {})
			else
				local Keys = {}
				for K in Data do
					table.insert(Keys, K)
				end
				table.sort(Keys, function(X, Y)
					return tostring(X) < tostring(Y)
				end)
				local V = {}
				for I, K in Keys do
					L[I] = tostring(K)
					V[I] = tonumber(Data[K]) or 0
				end
				S[1] = { Name = Info.Title or "Value", Values = V, Colors = {} }
			end
		end
		local Palette = Util.Palette(math.max(#S, 1))
		for I, Entry in S do
			Entry.Color = Entry.Color or (Info.Colors and Info.Colors[I])
			if not Entry.Color then
				Entry.Color, Entry.AutoColor = Palette[I], true
			end
		end
		return L, S
	end

	local function Count()
		local N = #Chart.Labels
		for _, S in Chart.Series do
			N = math.max(N, #S.Values)
		end
		return N
	end

	local function Range()
		local Lo, Hi = math.huge, -math.huge
		for _, S in Chart.Series do
			for _, V in S.Values do
				Lo = math.min(Lo, V)
				Hi = math.max(Hi, V)
			end
		end
		if Lo == math.huge then
			Lo, Hi = 0, 1
		end
		local Min = Info.Min or math.min(0, Lo)
		if Min < 0 and not Info.Min then
			Min = -Util.NiceMax(-Min)
		end
		local Max = Info.Max or Util.NiceMax(math.max(Hi, 0))
		if Max <= Min then
			Max = Min + 1
		end
		return Min, Max
	end

	local function Fmt(V)
		return Info.Prefix .. Util.Short(Util.RoundTo(V, 2)) .. Info.Suffix
	end

	local function LegendItem(Color, Str, Order)
		local Item = New("Frame", {
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 16),
			LayoutOrder = Order,
			Parent = Legend,
		})
		List(Item, 6, Enum.FillDirection.Horizontal, nil, Enum.VerticalAlignment.Center)
		local Dot = New("Frame", { Size = UDim2.fromOffset(8, 8), BackgroundColor3 = Color, Parent = Item })
		Round(Dot)
		Text("SubText", "Medium", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 16),
			Text = Str,
			TextSize = 12,
			LayoutOrder = 1,
			Parent = Item,
		})
	end

	local function ClearLegend()
		for _, C in Legend:GetChildren() do
			if C:IsA("GuiObject") then
				C:Destroy()
			end
		end
	end

	-- shared axis frame for bar/line ------------------------------------------
	local Canvas, Area, GridLayer, XLabels
	local function BuildAxes()
		if Canvas then
			Canvas:Destroy()
		end
		Canvas = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = Plot })
		Area = New("Frame", {
			Name = "Area",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(Info.ShowGrid and 34 or 0, 4),
			Size = UDim2.new(1, Info.ShowGrid and -34 or 0, 1, -24),
			Parent = Canvas,
		})
		GridLayer = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = Area })
		XLabels = New("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 0, 1, 6),
			Size = UDim2.new(1, 0, 0, 14),
			Parent = Area,
		})
	end

	local function DrawGrid(Min, Max)
		GridLayer:ClearAllChildren()
		if not Info.ShowGrid then
			return
		end
		for I = 0, 4 do
			local F = I / 4
			New("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 1 - F),
				Size = UDim2.new(1, 0, 0, 1),
				BackgroundColor3 = White,
				BackgroundTransparency = I == 0 and 0.86 or 0.95,
				Parent = GridLayer,
			})
			Text("Muted", "Medium", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(0, -8, 1 - F, 0),
				Size = UDim2.fromOffset(40, 14),
				Text = Util.Short(Util.RoundTo(Min + (Max - Min) * F, 2)),
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = GridLayer,
			})
		end
	end

	local function DrawXLabels(N, Centered)
		XLabels:ClearAllChildren()
		local Step = math.max(1, math.ceil(N / 8))
		for I = 1, N, Step do
			local L = Chart.Labels[I]
			if L then
				local X = Centered and (I - 0.5) / N or (N == 1 and 0.5 or (I - 1) / (N - 1))
				Text("Muted", "Medium", {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(X, 0),
					Size = UDim2.fromOffset(60, 14),
					Text = tostring(L),
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Center,
					TextTruncate = Enum.TextTruncate.AtEnd,
					Parent = XLabels,
				})
			end
		end
	end

	local function TipText(I)
		local Lines = { tostring(Chart.Labels[I] or ("#" .. I)) }
		for _, S in Chart.Series do
			local V = S.Values[I]
			if V ~= nil then
				table.insert(Lines, (#Chart.Series > 1 and (S.Name .. ": ") or "") .. Fmt(V))
			end
		end
		return table.concat(Lines, "\n")
	end

	local ResetHover
	local function ShowTip(Str)
		if Tooltip.Owner ~= Plot then
			Tooltip.Show(Str, Plot, function()
				ResetHover()
			end)
		else
			Tooltip.Update(Str)
		end
	end
	local function HideTip()
		Tooltip.Hide(Plot)
	end

	-- BAR --------------------------------------------------------------------
	local Bars, BarShape
	local function RenderBar(Intro)
		local N, M = Count(), #Chart.Series
		local Shape = N .. "x" .. M
		if Shape ~= BarShape or not Canvas then
			BuildAxes()
			BarShape = Shape
			Bars = {}
			local Column = New("Frame", {
				Name = "Column",
				BackgroundColor3 = White,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1 / math.max(N, 1), 1),
				ZIndex = 1,
				Parent = Area,
			})
			Corner(Column, 8)
			local ColumnX = Spring.new(0, 26, 0.9, function(X)
				Column.Position = UDim2.fromScale(X, 0)
			end)
			Chart.Column, Chart.ColumnX = Column, ColumnX
			local GroupW = 1 / math.max(N, 1)
			local InnerW = GroupW * 0.62
			local BarW = InnerW / math.max(M, 1)
			for I = 1, N do
				Bars[I] = {}
				for J = 1, M do
					local X = (I - 1) * GroupW + (GroupW - InnerW) / 2 + (J - 1) * BarW + BarW * 0.08
					local Frame = New("Frame", {
						BackgroundColor3 = Chart.Series[J].Colors[I] or Chart.Series[J].Color,
						Size = UDim2.new(BarW * 0.84, 0, 0, 0),
						Position = UDim2.fromScale(X, 1),
						AnchorPoint = Vector2.new(0, 1),
						ZIndex = 2,
						Parent = Area,
					})
					Corner(Frame, 5)
					New("UIGradient", {
						Rotation = 90,
						Transparency = NumberSequence.new({ KP(0, 0), KP(1, 0.45) }),
						Parent = Frame,
					})
					local Top = New("Frame", {
						BackgroundColor3 = White,
						BackgroundTransparency = 0.55,
						Position = UDim2.fromOffset(2, 1),
						Size = UDim2.new(1, -4, 0, 1),
						ZIndex = 3,
						Parent = Frame,
					})
					local Entry = { Frame = Frame, X = X, W = BarW * 0.84, Base = 0, Top = Top }
					Entry.Spring = Spring.new(0, 15, 0.92, function(H)
						local Base = Entry.Base
						if H >= 0 then
							Frame.AnchorPoint = Vector2.new(0, 1)
							Frame.Position = UDim2.fromScale(Entry.X, 1 - Base)
						else
							Frame.AnchorPoint = Vector2.new(0, 0)
							Frame.Position = UDim2.fromScale(Entry.X, 1 - Base)
						end
						Frame.Size = UDim2.new(Entry.W, 0, math.abs(H), 0)
						Top.Visible = math.abs(H) > 0.02
					end)
					Bars[I][J] = Entry
				end
			end
			Intro = true
		end
		local Min, Max = Range()
		DrawGrid(Min, Max)
		DrawXLabels(N, true)
		local Base = (0 - Min) / (Max - Min)
		for I = 1, N do
			for J = 1, M do
				local Entry = Bars[I][J]
				local S = Chart.Series[J]
				Entry.Frame.BackgroundColor3 = S.Colors[I] or S.Color
				Entry.Base = Base
				local Goal = (S.Values[I] or 0) / (Max - Min)
				if Intro then
					Entry.Spring:Snap(0)
					task.delay(0.035 * (I - 1) + 0.02 * (J - 1), function()
						Entry.Spring:Set(Goal)
					end)
				else
					Entry.Spring:Set(Goal)
				end
			end
		end
	end

	-- LINE / AREA ------------------------------------------------------------
	local Pools = {}
	local Shown = {}
	local Reveal = 1
	local LineMin, LineMax = 0, 1
	local Crosshair, CrossX, HoverDots

	local function Points(Values, W, H)
		local N, P = #Values, {}
		for I, V in Values do
			local X = N == 1 and W / 2 or (I - 1) / (N - 1) * W
			P[I] = Vector2.new(X, H - (V - LineMin) / (LineMax - LineMin) * H)
		end
		return P
	end

	local function Curve(P, H)
		if not Info.Smooth or #P < 3 then
			return P
		end
		local Out = {}
		for I = 1, #P - 1 do
			local P0, P1, P2, P3 = P[math.max(I - 1, 1)], P[I], P[I + 1], P[math.min(I + 2, #P)]
			for K = 0, 5 do
				local T = K / 6
				local T2, T3 = T * T, T * T * T
				local Pt = 0.5 * ((2 * P1) + (P2 - P0) * T + (2 * P0 - 5 * P1 + 4 * P2 - P3) * T2 + (3 * P1 - P0 - 3 * P2 + P3) * T3)
				table.insert(Out, Vector2.new(Pt.X, Util.Clamp(Pt.Y, 0, H)))
			end
		end
		table.insert(Out, P[#P])
		return Out
	end

	-- Path2D draws an anti-aliased stroke. Where the engine lacks it, fall
	-- back to rotated frames feathered across their width, which hides the
	-- stair-stepping a hard-edged rotated frame shows on a bend.
	local HasPath2D = pcall(function()
		local Test = Instance.new("Path2D")
		local Zero = UDim2.new()
		Test:SetControlPoints({ Path2DControlPoint.new(Zero, Zero, Zero), Path2DControlPoint.new(UDim2.fromOffset(1, 1), Zero, Zero) })
		Test.Color3, Test.Thickness = White, 2
		Test:Destroy()
	end)
	local Feather = NumberSequence.new({ KP(0, 1), KP(0.3, 0), KP(0.7, 0), KP(1, 1) })

	local function Pool(S)
		local P = Pools[S]
		if not P then
			P = { Segs = {}, Strips = {}, Dots = {} }
			Pools[S] = P
		end
		return P
	end

	local function DrawLine()
		if not Area then
			return
		end
		local W, H = Util.Unscale(Area.AbsoluteSize.X), Util.Unscale(Area.AbsoluteSize.Y)
		if W < 4 or H < 4 then
			return
		end
		local Limit = W * Reveal
		for S, Series in Chart.Series do
			local P = Pool(S)
			local Color = Series.Color
			local Pts = Points(Shown[S] or {}, W, H)
			local C = Curve(Pts, H)

			-- the part of the curve revealed so far
			local Cut = {}
			for I, Pt in C do
				if Pt.X <= Limit then
					Cut[I] = Pt
				else
					local Prev = C[I - 1]
					if Prev then
						Cut[I] = Prev:Lerp(Pt, (Limit - Prev.X) / math.max(Pt.X - Prev.X, 1e-3))
					end
					break
				end
			end

			local Used = 0
			if HasPath2D then
				if not P.Path then
					P.Path = New("Path2D", { Thickness = Info.Thickness, ZIndex = 4, Parent = Area })
				end
				local Zero = UDim2.new()
				local Control = table.create(#Cut)
				for I, Pt in Cut do
					-- scale, not offset: Path2D offsets don't go through the
					-- window's UIScale, so offset points drift out of the plot
					Control[I] = Path2DControlPoint.new(UDim2.fromScale(Pt.X / W, Pt.Y / H), Zero, Zero)
				end
				P.Path.Color3 = Color
				P.Path:SetControlPoints(Control)
				P.Path.Visible = #Control >= 2
			else
				local Width = Info.Thickness + 1.5
				for I = 1, #Cut - 1 do
					local A1, B1 = Cut[I], Cut[I + 1]
					Used += 1
					local Seg = P.Segs[Used]
					if not Seg then
						Seg = New("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 4, Parent = Area })
						Round(Seg)
						New("UIGradient", { Rotation = 90, Transparency = Feather, Parent = Seg })
						P.Segs[Used] = Seg
					end
					local D = B1 - A1
					Seg.BackgroundColor3 = Color
					Seg.Position = UDim2.fromOffset((A1.X + B1.X) / 2, (A1.Y + B1.Y) / 2)
					Seg.Size = UDim2.fromOffset(D.Magnitude + Width * 0.6, Width)
					Seg.Rotation = math.deg(math.atan2(D.Y, D.X))
					Seg.Visible = true
				end
			end
			for I = Used + 1, #P.Segs do
				P.Segs[I].Visible = false
			end

			-- The fill is thin vertical strips. They're opaque and live in a
			-- CanvasGroup that carries the translucency and the fade, so where
			-- neighbours overlap they don't stack into darker seams. Each strip's
			-- top sits on the curve at its centre, so the gap or overshoot at
			-- its corners stays inside the stroke's half-thickness.
			Used = 0
			if Info.Fill and #C > 0 then
				if not P.Fill then
					P.Fill = New("CanvasGroup", {
						BackgroundTransparency = 1,
						GroupTransparency = 0.74,
						ZIndex = 2,
						Parent = Area,
					})
					New("UIGradient", {
						Rotation = 90,
						Transparency = NumberSequence.new({ KP(0, 0), KP(1, 1) }),
						Parent = P.Fill,
					})
				end
				local Top = H
				for _, Pt in C do
					Top = math.min(Top, Pt.Y)
				end
				P.Fill.Position = UDim2.fromOffset(0, Top)
				P.Fill.Size = UDim2.fromOffset(W, math.max(H - Top, 1))
				P.Fill.Visible = true

				local Step = 1.5
				local CI = 1
				local X = 0
				local Stop = math.min(W, Limit)
				while X < Stop do
					local Mid = math.min(X + Step / 2, Stop)
					while CI < #C - 1 and C[CI + 1].X < Mid do
						CI += 1
					end
					local A1, B1 = C[CI], C[math.min(CI + 1, #C)]
					local T = (B1.X - A1.X) > 1e-3 and Util.Clamp((Mid - A1.X) / (B1.X - A1.X), 0, 1) or 0
					local Y = Util.Lerp(A1.Y, B1.Y, T)
					Used += 1
					local Strip = P.Strips[Used]
					if not Strip then
						Strip = New("Frame", { BackgroundTransparency = 0, Parent = P.Fill })
						P.Strips[Used] = Strip
					end
					Strip.BackgroundColor3 = Color
					Strip.Position = UDim2.fromOffset(X, Y - Top)
					Strip.Size = UDim2.fromOffset(math.min(Step + 0.5, Stop - X), math.max(H - Y, 0))
					Strip.Visible = true
					X += Step
				end
			elseif P.Fill then
				P.Fill.Visible = false
			end
			for I = Used + 1, #P.Strips do
				P.Strips[I].Visible = false
			end

			local ShowDots = Info.Dots and #Pts <= 24
			for I, Pt in Pts do
				local Dot = P.Dots[I]
				if not Dot then
					Dot = New("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						Size = UDim2.fromOffset(7, 7),
						ZIndex = 5,
						Theme = { BackgroundColor3 = "Background" },
						Parent = Area,
					})
					Round(Dot)
					New("UIStroke", { Thickness = 2, Color = Color, Parent = Dot })
					P.Dots[I] = Dot
				end
				Dot.UIStroke.Color = Color
				Dot.Position = UDim2.fromOffset(Pt.X, Pt.Y)
				Dot.Visible = ShowDots and Pt.X <= Limit + 0.5
			end
			for I = #Pts + 1, #P.Dots do
				P.Dots[I].Visible = false
			end
		end
	end

	local function RenderLine(Intro, From)
		if not Canvas or Chart.Built ~= "Line" then
			BuildAxes()
			Pools, Shown = {}, {}
			Chart.Built = "Line"
			Crosshair = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				Size = UDim2.new(0, 1, 1, 0),
				BackgroundColor3 = White,
				BackgroundTransparency = 1,
				ZIndex = 3,
				Parent = Area,
			})
			CrossX = Spring.new(0, 26, 0.9, function(X)
				Crosshair.Position = UDim2.fromOffset(X, 0)
			end)
			HoverDots = {}
			Area:GetPropertyChangedSignal("AbsoluteSize"):Connect(DrawLine)
			Intro = true
		end
		for _, H in HoverDots do
			H:Destroy()
		end
		table.clear(HoverDots)
		for S, Series in Chart.Series do
			local Dot = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromOffset(11, 11),
				BackgroundColor3 = Series.Color,
				Visible = false,
				ZIndex = 6,
				Parent = Area,
			})
			Round(Dot)
			New("UIStroke", { Thickness = 2, Color = White, Transparency = 0.2, Parent = Dot })
			HoverDots[S] = Dot
		end
		-- drop pools for series that no longer exist
		for S, P in Pools do
			if not Chart.Series[S] then
				for _, List_ in { P.Segs, P.Strips, P.Dots } do
					for _, F in List_ do
						F:Destroy()
					end
				end
				if P.Path then
					P.Path:Destroy()
				end
				if P.Fill then
					P.Fill:Destroy()
				end
				Pools[S] = nil
			end
		end

		LineMin, LineMax = Range()
		DrawGrid(LineMin, LineMax)
		DrawXLabels(Count(), false)

		local Targets = {}
		for S, Series in Chart.Series do
			Targets[S] = table.clone(Series.Values)
		end
		local Same = not Intro
		for S in Targets do
			if not Shown[S] or #Shown[S] ~= #Targets[S] then
				Same = false
			end
		end
		if From then
			Shown = From
			Same = true
		end

		if Same then
			-- morph from what is on screen to the new values
			local Start = {}
			for S, V in Shown do
				Start[S] = table.clone(V)
			end
			Reveal = 1
			Motion.Animate(0.45, Motion.Ease.Glass, function(A)
				for S, T in Targets do
					local Cur = {}
					for I, V in T do
						Cur[I] = Util.Lerp(Start[S] and Start[S][I] or V, V, A)
					end
					Shown[S] = Cur
				end
				DrawLine()
			end)
		else
			Shown = Targets
			Reveal = 0
			Motion.Animate(1.0, Motion.Ease.Soft, function(A)
				Reveal = A
				DrawLine()
			end)
		end
	end

	-- PIE / DONUT ------------------------------------------------------------
	local Pie
	local function RenderPie()
		if Canvas then
			Canvas:Destroy()
		end
		Chart.Built = nil
		BarShape = nil
		Canvas = New("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = Plot })
		local Series = Chart.Series[1] or { Values = {}, Colors = {} }
		local Values = Series.Values
		local Total = Sum(Values)
		local POP = 6 -- how far a hovered slice slides out
		local GAP = 5 -- space between neighbouring slices
		local D = Info.Height - 2 * (POP + 4)
		local R = D / 2
		local Donut = Chart.ChartType == "Donut"
		local InnerR = Donut and R * 0.62 or 0
		local Palette = Util.Palette(math.max(#Values, 1))

		local Disc = New("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(POP + 4, POP + 4),
			Size = UDim2.fromOffset(D, D),
			Parent = Canvas,
		})
		local Slices = {}
		local Acc = 0
		for I, V in Values do
			local F = Total > 0 and math.max(V, 0) / Total or 0
			Slices[I] = {
				From = Acc,
				To = Acc + F,
				Frac = F,
				Color = Series.Colors[I] or (Info.Colors and Info.Colors[I]) or Palette[I],
			}
			Acc += F
		end

		-- Each slice is a disc (or, for a donut, a ring) cut down to a wedge
		-- by two hard-stepped UIGradients, each on its own CanvasGroup so the
		-- two cuts intersect. A gradient edge is a straight line shifted by
		-- GAP/2 off the slice's edge, so the gaps come out with parallel sides
		-- and every slice keeps the same outer edge. The step is about a pixel
		-- wide, which anti-aliases the cut. Slices over 180 degrees are drawn
		-- as two wedges that overlap a pixel at the seam.
		local Box = D + 4 -- room for the ring's anti-aliased rim
		local Soft = 1.2 / Box
		local function Cut(Rotation, Offset)
			-- keep the side the gradient's axis points to, past Offset px from the centre
			local T = Util.Clamp(0.5 + Offset / Box, Soft, 1 - Soft)
			return New("UIGradient", {
				Rotation = Rotation,
				Transparency = NumberSequence.new({ KP(0, 1), KP(T - Soft / 2, 1), KP(T + Soft / 2, 0), KP(1, 0) }),
			})
		end
		local function Wedge(S, A1, A2, Gap1, Gap2)
			local Outer = New("CanvasGroup", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(Box, Box),
				GroupTransparency = 1,
				Parent = Disc,
			})
			local Inner = New("CanvasGroup", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Parent = Outer,
			})
			-- clockwise of the start edge, anticlockwise of the end edge
			Cut(A1 + 90, Gap1).Parent = Inner
			Cut(A2 - 90, Gap2).Parent = Outer
			local Shape
			if Donut then
				Shape = New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(InnerR * 2, InnerR * 2),
					BackgroundTransparency = 1,
					Parent = Inner,
				})
				Round(Shape)
				New("UIStroke", { Thickness = R - InnerR, Color = S.Color, Parent = Shape })
			else
				Shape = New("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(D, D),
					BackgroundColor3 = S.Color,
					Parent = Inner,
				})
				Round(Shape)
			end
			table.insert(S.Parts, Outer)
			return Outer
		end

		local Many = 0
		for _, S in Slices do
			if S.Frac > 0 then
				Many += 1
			end
		end
		local Half = Many > 1 and GAP / 2 or 0
		for _, S in Slices do
			S.Parts = {}
			if S.Frac > 0 then
				local A1, A2 = S.From * 360 - 90, S.To * 360 - 90
				if Many == 1 then
					Wedge(S, -90, 90, -Box, -Box)
					Wedge(S, 90, 270, -Box, -Box)
				elseif A2 - A1 > 180 then
					local AM = (A1 + A2) / 2
					Wedge(S, A1, AM, Half, -1)
					Wedge(S, AM, A2, -1, Half)
				else
					Wedge(S, A1, A2, Half, Half)
				end
			end
		end

		-- a hovered slice slides out along its middle and grows a little;
		-- every slice moves the same distance whatever its size
		for _, S in Slices do
			local Mid = math.rad((S.From + S.To) / 2 * 360 - 90)
			local Dir = Vector2.new(math.cos(Mid), math.sin(Mid))
			local Scales = {}
			for I, Part in S.Parts do
				Scales[I] = New("UIScale", { Parent = Part })
			end
			S.Pop = Spring.Feel(0, "Tactile", function(O)
				local Shift = Dir * O
				for I, Part in S.Parts do
					Part.Position = UDim2.new(0.5, Shift.X, 0.5, Shift.Y)
					Scales[I].Scale = 1 + math.max(O, 0) * 0.006
				end
			end)
		end

		local CenterValue, CenterCaption
		if Donut then
			CenterValue = Text("Text", "Bold", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, -7),
				Size = UDim2.fromOffset(InnerR * 1.6, 22),
				Text = Fmt(Total),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Center,
				ZIndex = 4,
				Parent = Disc,
			})
			CenterCaption = Text("Muted", "Medium", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 11),
				Size = UDim2.fromOffset(InnerR * 1.6, 14),
				Text = "Total",
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 4,
				Parent = Disc,
			})
		end

		-- legend to the right of the disc
		local Side = New("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(D + 2 * POP + 24, 0),
			Size = UDim2.new(1, -(D + 2 * POP + 24), 1, 0),
			Parent = Canvas,
		})
		List(Side, 6, nil, nil, Enum.VerticalAlignment.Center)
		local LegendRows = {}
		for I, S in Slices do
			if I > 8 then
				break
			end
			local RowF = New("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = I, Parent = Side })
			local Dot = New("Frame", {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(8, 8),
				BackgroundColor3 = S.Color,
				Parent = RowF,
			})
			Round(Dot)
			local Name = Text("SubText", "Medium", {
				Position = UDim2.fromOffset(16, 0),
				Size = UDim2.new(1, -60, 1, 0),
				Text = tostring(Chart.Labels[I] or ("#" .. I)),
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = RowF,
			})
			Text("Text", "SemiBold", {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 44, 1, 0),
				Text = string.format("%d%%", math.floor(S.Frac * 100 + 0.5)),
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = RowF,
			})
			LegendRows[I] = Name
		end

		Motion.Animate(1.0, Motion.Ease.Soft, function(A)
			-- slices fade in one after another, clockwise
			for _, S in Slices do
				local T = Util.Clamp((A * 1.15 - S.From) / math.max(S.Frac, 0.12), 0, 1)
				for _, Part in S.Parts do
					Part.GroupTransparency = 1 - T
				end
			end
		end)

		Pie = {
			Disc = Disc,
			R = R,
			InnerR = InnerR,
			Slices = Slices,
			Hovered = nil,
			Total = Total,
			SetHover = function(Index)
				if Pie.Hovered == Index then
					return
				end
				Pie.Hovered = Index
				for I, S in Slices do
					S.Pop:Set(I == Index and POP or 0)
					if LegendRows[I] then
						Themed(LegendRows[I], { TextColor3 = I == Index and "Text" or "SubText" })
					end
				end
				if CenterValue then
					if Index then
						CenterValue.Text = Fmt(Values[Index] or 0)
						CenterCaption.Text = tostring(Chart.Labels[Index] or ("#" .. Index))
					else
						CenterValue.Text = Fmt(Total)
						CenterCaption.Text = "Total"
					end
				end
			end,
		}
	end

	-- hover ------------------------------------------------------------------
	Plot.InputChanged:Connect(function(Input)
		if Input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local Mouse = Util.Mouse()
		local T = Chart.ChartType
		if T == "Pie" or T == "Donut" then
			if not Pie then
				return
			end
			local Center = Pie.Disc.AbsolutePosition + Pie.Disc.AbsoluteSize / 2
			local Rel = (Mouse - Center) / math.max(Library.CurrentScale, 0.05)
			local Dist = Rel.Magnitude
			local Index
			if Dist <= Pie.R + 12 and Dist >= Pie.InnerR - 2 then
				local F = ((math.deg(math.atan2(Rel.Y, Rel.X)) + 90) % 360) / 360
				for I, S in Pie.Slices do
					if F >= S.From and F < S.To then
						Index = I
						break
					end
				end
			end
			Pie.SetHover(Index)
			if Index and T == "Pie" then
				local S = Pie.Slices[Index]
				ShowTip(tostring(Chart.Labels[Index] or ("#" .. Index)) .. "\n" .. Fmt(Chart.Series[1].Values[Index] or 0) .. string.format("  (%d%%)", math.floor(S.Frac * 100 + 0.5)))
			else
				HideTip()
			end
			return
		end
		if not Area then
			return
		end
		local N = Count()
		if N == 0 then
			return
		end
		local Rel = (Mouse.X - Area.AbsolutePosition.X) / math.max(Area.AbsoluteSize.X, 1)
		if Rel < -0.02 or Rel > 1.02 then
			HideTip()
			return
		end
		Rel = Util.Clamp(Rel, 0, 1)
		if T == "Bar" then
			local I = Util.Clamp(math.floor(Rel * N) + 1, 1, N)
			if Chart.Column then
				if Chart.Column.BackgroundTransparency >= 0.99 then
					Chart.ColumnX:Snap((I - 1) / N)
				else
					Chart.ColumnX:Set((I - 1) / N)
				end
				Motion.Tween(Chart.Column, { BackgroundTransparency = 0.95 }, 0.15, Motion.Ease.Soft)
			end
			ShowTip(TipText(I))
		else
			local I = N == 1 and 1 or Util.Clamp(math.floor(Rel * (N - 1) + 0.5) + 1, 1, N)
			local W, H = Util.Unscale(Area.AbsoluteSize.X), Util.Unscale(Area.AbsoluteSize.Y)
			local X = N == 1 and W / 2 or (I - 1) / (N - 1) * W
			if Crosshair then
				if Crosshair.BackgroundTransparency >= 0.99 then
					CrossX:Snap(X)
				else
					CrossX:Set(X)
				end
				Motion.Tween(Crosshair, { BackgroundTransparency = 0.75 }, 0.15, Motion.Ease.Soft)
				for S, Dot in HoverDots do
					local V = Shown[S] and Shown[S][I]
					if V then
						Dot.Visible = true
						Dot.Position = UDim2.fromOffset(X, H - (V - LineMin) / (LineMax - LineMin) * H)
					end
				end
			end
			ShowTip(TipText(I))
		end
	end)
	-- also runs when the tooltip is taken away (tab switch, window hidden)
	function ResetHover()
		if Chart.Column then
			Motion.Tween(Chart.Column, { BackgroundTransparency = 1 }, 0.2, Motion.Ease.Soft)
		end
		if Crosshair then
			Motion.Tween(Crosshair, { BackgroundTransparency = 1 }, 0.2, Motion.Ease.Soft)
			for _, Dot in HoverDots do
				Dot.Visible = false
			end
		end
		if Pie then
			Pie.SetHover(nil)
		end
	end
	Plot.MouseLeave:Connect(function()
		HideTip()
		ResetHover()
	end)

	-- render -----------------------------------------------------------------
	local function Render(Intro, From)
		if Intro and not Util.Shown(Plot) then
			Chart.Pending = true
		end
		ClearLegend()
		local T = Chart.ChartType
		if T == "Pie" or T == "Donut" then
			Legend.Visible = false
			RenderPie()
			return
		end
		Pie = nil
		Legend.Visible = Info.ShowLegend and #Chart.Series > 1
		if Legend.Visible then
			for I, S in Chart.Series do
				LegendItem(S.Color, S.Name, I)
			end
		end
		if T == "Bar" then
			Chart.Built = nil
			RenderBar(Intro)
		else
			BarShape = nil
			RenderLine(Intro, From)
		end
	end

	function Chart:OnShown()
		if self.Pending and Util.Shown(Plot) then
			self.Pending = false
			Render(true)
		end
	end

	function Chart:SetData(Data, Labels)
		self.Labels, self.Series = Normalize(Data, Labels or self.Labels, nil)
		Render(false)
	end
	function Chart:SetSeries(Series, Labels)
		self.Labels, self.Series = Normalize(nil, Labels or self.Labels, Series)
		Render(false)
	end
	function Chart:SetLabels(Labels)
		self.Labels = table.clone(Labels)
		Render(false)
	end
	function Chart:SetType(T)
		self.ChartType = T
		Canvas = nil
		Plot:ClearAllChildren()
		Chart.Built, BarShape = nil, nil
		Render(true)
	end
	function Chart:SetTitle(Str, Sub)
		if TitleLabel then
			TitleLabel.Text = tostring(Str or "")
		end
		if SubLabel and Sub ~= nil then
			SubLabel.Text = tostring(Sub)
		end
	end
	-- live data: append a point (number, or one number per series) and slide
	function Chart:Push(Value, Label)
		local Values = type(Value) == "table" and Value or { Value }
		local Before = {}
		for S, Series in self.Series do
			Before[S] = table.clone(Shown[S] or Series.Values)
		end
		for S, Series in self.Series do
			table.insert(Series.Values, tonumber(Values[S]) or Series.Values[#Series.Values] or 0)
		end
		table.insert(self.Labels, Label or "")
		local Trim = Info.MaxPoints and Count() > Info.MaxPoints
		if Trim then
			table.remove(self.Labels, 1)
			for _, Series in self.Series do
				table.remove(Series.Values, 1)
			end
		end
		if self.ChartType == "Line" or self.ChartType == "Area" then
			-- start the new point where the line used to end so it slides in
			for S, B in Before do
				if Trim then
					table.remove(B, 1)
				end
				table.insert(B, B[#B] or 0)
			end
			Render(false, Before)
		else
			Render(false)
		end
	end

	Chart.Labels, Chart.Series = Normalize(Info.Data, Info.Labels, Info.Series)
	Chart.Holder = Holder
	Library.ThemeHooks[Holder] = function()
		local Palette = Util.Palette(math.max(#Chart.Series, 1))
		for I, S in Chart.Series do
			if S.AutoColor then
				S.Color = Palette[I]
			end
		end
		if Canvas then
			Render(false)
		end
	end
	Chart:SetVisible(Info.Visible)
	-- wait for a real size before the first draw so the intro plays on screen
	task.defer(function()
		Render(true)
	end)
	if Idx then
		Options[Idx] = Chart
	end
	return Register(self, Chart)
end

-- ============================================================
-- GROUPS  (glass cards whose height glides with their content)
-- ============================================================
-- A group is a card: a header row (icon, title, optional description and a
-- collapse chevron) over a clipped body. The body's height is driven by a
-- spring that follows the content, so anything that changes size inside it
-- (dependency boxes opening, rows hiding, collapsing) glides instead of
-- jumping.
local GroupMeta = {}
GroupMeta.__index = function(_, K)
	return rawget(GroupMeta, K) or Funcs[K]
end

local CARD_RADIUS = 14

local function Card(Parent, Order)
	local Frame = New("Frame", {
		Name = "Card",
		BackgroundColor3 = White,
		BackgroundTransparency = 0.955,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = Order or 0,
		Parent = Parent,
	})
	Corner(Frame, CARD_RADIUS)
	local Stroke = Glass.Edge(Frame, { Transparency = 0.6 })
	Glass.Sheen(Frame, CARD_RADIUS, 0.03)
	Frame.MouseEnter:Connect(function()
		Motion.Tween(Stroke, { Transparency = 0.48 }, 0.4, Motion.Ease.Glass)
	end)
	Frame.MouseLeave:Connect(function()
		Motion.Tween(Stroke, { Transparency = 0.6 }, 0.6, Motion.Ease.Soft)
	end)
	-- the sheen fills the card, so it can't share a UIListLayout with the
	-- content: it would take the first slot and push everything out below
	local Stack = New("Frame", {
		Name = "Stack",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 1,
		Parent = Frame,
	})
	List(Stack, 0)
	return Frame, Stack
end

-- Body whose height follows List with a spring. Returns body, list, controller.
local function GlidingBody(Parent, Order)
	local Body = New("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Size = UDim2.new(1, 0, 0, 0),
		LayoutOrder = Order or 2,
		Parent = Parent,
	})
	local Height = Spring.Feel(0, "Smooth", function(H)
		Body.Size = UDim2.new(1, 0, 0, math.max(H, 0))
	end)
	local Ctl = { Collapsed = false, Spring = Height }
	local Last = -1
	local Queued = false
	function Ctl:Follow(Content)
		local function Update()
			Queued = false
			if not Body.Parent then
				return
			end
			local H = self.Collapsed and 0 or Util.Unscale(Content.AbsoluteSize.Y)
			if math.abs(H - Last) < 0.5 then
				return
			end
			Last = H
			if Util.Shown(Body) and Library.Window and Library.Window.Visible then
				Height:Set(H)
			else
				Height:Snap(H)
			end
		end
		-- resizing Body from inside its own AbsoluteSize signal re-enters the
		-- layout pass, so batch changes and apply them once, a frame later
		local function Queue()
			if not Queued then
				Queued = true
				task.defer(Update)
			end
		end
		Content:GetPropertyChangedSignal("AbsoluteSize"):Connect(Queue)
		self.Update = function()
			Last = -1
			Update()
		end
		Update()
	end
	return Body, Ctl
end

local function CreateGroup(Tab, Column, Info)
	Info = Util.Validate(Info, { Title = "Group", Icon = nil, Description = nil, Collapsed = false, Collapsible = true, Visible = true })
	local Group = setmetatable({
		Type = "Groupbox",
		Tab = Tab,
		Title = Info.Title,
		Order = 0,
		Elements = {},
		AllElements = {},
		Visible = Info.Visible,
		Collapsed = Info.Collapsed,
	}, GroupMeta)
	Group.Group = Group

	local Frame, Stack = Card(Column, #Column:GetChildren())
	Group.Card = Frame
	local HasDesc = Info.Description and Info.Description ~= ""
	local Header = New("TextButton", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, HasDesc and 62 or 50),
		LayoutOrder = 1,
		Parent = Stack,
	})
	local X = 18
	local Icon = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 18, 0, 25),
		Size = UDim2.fromOffset(17, 17),
		Theme = { ImageColor3 = "Accent" },
		Parent = Header,
	})
	if Util.ApplyIcon(Icon, Info.Icon) then
		X = 44
	end
	local TitleLabel = Text("Text", "SemiBold", {
		Position = UDim2.fromOffset(X, 16),
		Size = UDim2.new(1, -X - 44, 0, 18),
		Text = Info.Title,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Header,
	})
	local DescLabel = Text("Muted", "Regular", {
		Position = UDim2.fromOffset(X, 35),
		Size = UDim2.new(1, -X - 44, 0, 16),
		Text = Info.Description or "",
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = HasDesc,
		Parent = Header,
	})
	local Chevron = Util.Chevron(Header, 11, "Muted")
	Chevron.Position = UDim2.new(1, -24, 0, 25)
	Chevron.Visible = Info.Collapsible
	local Spin = Spring.Feel(Info.Collapsed and -90 or 0, "Smooth", function(R)
		Chevron.Rotation = R
	end)
	Spin:Snap(Info.Collapsed and -90 or 0)

	local Body, Ctl = GlidingBody(Stack, 2)
	local Content = New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Body,
	})
	Pad(Content, 0, 18, 16, 18)
	List(Content, 6)
	Group.List = Content
	Ctl.Collapsed = Info.Collapsed
	Ctl:Follow(Content)

	function Group:SetCollapsed(State)
		self.Collapsed = State and true or false
		Ctl.Collapsed = self.Collapsed
		Spin:Set(self.Collapsed and -90 or 0)
		Ctl.Update()
		Library:CloseAllPopups()
	end
	function Group:ToggleCollapsed()
		self:SetCollapsed(not self.Collapsed)
	end
	function Group:SetTitle(Str)
		self.Title = tostring(Str)
		TitleLabel.Text = self.Title
	end
	function Group:SetDescription(Str)
		DescLabel.Text = Str and tostring(Str) or ""
		DescLabel.Visible = Str ~= nil and Str ~= ""
		Header.Size = UDim2.new(1, 0, 0, DescLabel.Visible and 62 or 50)
	end
	function Group:SetVisible(V)
		self.Visible = V and true or false
		Frame.Visible = self.Visible and not self.SearchHidden
	end
	function Group:Show()
		self:SetVisible(true)
	end
	function Group:Hide()
		self:SetVisible(false)
	end
	function Group:Destroy()
		Frame:Destroy()
		for I, G in Tab.Groups do
			if G == self then
				table.remove(Tab.Groups, I)
				break
			end
		end
	end

	Header.Activated:Connect(function()
		if Info.Collapsible then
			Group:ToggleCollapsed()
		end
	end)

	table.insert(Tab.Groups, Group)
	Group:SetVisible(Info.Visible)
	return Group
end

-- ============================================================
-- TABBOX  (a card with a segmented control and swappable pages)
-- ============================================================
local function CreateTabbox(Tab, Column, Name)
	local Tabbox = { Type = "Tabbox", Tabs = {}, Tab = Tab, Title = Name or "", AllElements = {}, Visible = true }
	Tabbox.Group = Tabbox
	local Frame, Stack = Card(Column, #Column:GetChildren())
	Tabbox.Card = Frame

	local Top = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 58),
		LayoutOrder = 1,
		Parent = Stack,
	})
	local Track = New("Frame", {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.new(1, -24, 0, 34),
		BackgroundTransparency = 0.955,
		Parent = Top,
	})
	Corner(Track, 10)
	local Indicator = New("Frame", {
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.new(0, 0, 1, -6),
		BackgroundTransparency = 0.88,
		ZIndex = 1,
		Parent = Track,
	})
	Corner(Indicator, 8)
	Glass.Edge(Indicator, { Transparency = 0.45 })
	local Buttons = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(3, 3),
		Size = UDim2.new(1, -6, 1, -6),
		ZIndex = 2,
		Parent = Track,
	})
	List(Buttons, 0, Enum.FillDirection.Horizontal)

	-- the indicator's two edges are separate springs: the leading edge runs
	-- ahead and the trailing one catches up, so it stretches as it travels.
	local Left, Right
	local function PaintIndicator()
		local L, R = Left:Get(), Right:Get()
		Indicator.Position = UDim2.new(L, 3 - 6 * L, 0, 3)
		Indicator.Size = UDim2.new(math.max(R - L, 0.02), -6 * (R - L), 1, -6)
	end
	Left = Spring.new(0, 24, 1, PaintIndicator)
	Right = Spring.new(1, 24, 1, PaintIndicator)

	local Body, Ctl = GlidingBody(Stack, 2)
	local Pages = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = Body,
	})
	Ctl:Follow(Pages)

	local function Layout()
		local N = #Tabbox.Tabs
		for _, T in Tabbox.Tabs do
			T.Button.Size = UDim2.new(1 / math.max(N, 1), 0, 1, 0)
		end
	end

	function Tabbox:Select(Target)
		local N = #self.Tabs
		local Index = table.find(self.Tabs, Target)
		if not Index then
			return
		end
		local Prev = self.Active
		self.Active = Target
		local L, R = (Index - 1) / N, Index / N
		local Forward = L > Left:Goal()
		Left.Speed, Right.Speed = Forward and 20 or 26, Forward and 26 or 20
		if Prev == nil then
			Left:Snap(L)
			Right:Snap(R)
		else
			Left:Set(L)
			Right:Set(R)
		end
		for _, T in self.Tabs do
			local On = T == Target
			Themed(T.Label, { TextColor3 = On and "Text" or "SubText", FontFace = On and Weights.SemiBold or Weights.Medium })
			if On then
				T.Page.Visible = true
				T.Page.GroupTransparency = 1
				T.Rise:Snap(Prev and (Forward and 6 or -6) or 0)
				T.Rise:Set(0)
				Motion.Tween(T.Page, { GroupTransparency = 0 }, 0.32, Motion.Ease.Glass)
			else
				T.Page.Visible = false
			end
		end
		Library:CloseAllPopups()
	end

	function Tabbox:AddTab(TabName)
		local Sub = setmetatable({
			Type = "TabboxTab",
			Name = TabName,
			Order = 0,
			Elements = {},
			Tab = Tab,
			Group = Tabbox,
		}, { __index = Funcs })
		local Button = New("TextButton", { Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = Buttons })
		Sub.Button = Button
		Sub.Label = Text("SubText", "Medium", {
			Size = UDim2.fromScale(1, 1),
			Text = TabName,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Button,
		})
		local Page = New("CanvasGroup", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Visible = false,
			Parent = Pages,
		})
		local Content = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = Page,
		})
		Pad(Content, 0, 18, 16, 18)
		List(Content, 6)
		Sub.Page = Page
		Sub.List = Content
		Sub.Rise = Spring.Feel(0, "Smooth", function(Y)
			Content.Position = UDim2.fromOffset(0, Y)
		end)
		Button.Activated:Connect(function()
			Tabbox:Select(Sub)
		end)
		function Sub:Show()
			Tabbox:Select(self)
		end
		table.insert(Tabbox.Tabs, Sub)
		Layout()
		if not Tabbox.Active then
			Tabbox:Select(Sub)
		else
			local I, N = table.find(Tabbox.Tabs, Tabbox.Active), #Tabbox.Tabs
			Left:Snap((I - 1) / N)
			Right:Snap(I / N)
		end
		return Sub
	end

	function Tabbox:SetVisible(V)
		self.Visible = V and true or false
		Frame.Visible = self.Visible and not self.SearchHidden
	end

	table.insert(Tab.Groups, Tabbox)
	return Tabbox
end

-- ============================================================
-- SECTIONS  (titled bands inside a tab, each with its own columns)
-- ============================================================
-- A tab is a vertical stack of sections. A section has an optional title and
-- caption, then rows of two columns (or one full-width column). Groups and
-- tabboxes go into the current row's columns. On a narrow window both
-- columns stack into one.
local SectionMeta = {}
SectionMeta.__index = SectionMeta

local function ApplyColumns(Row, Single)
	if Row.Full then
		return
	end
	Row.Layout.FillDirection = Single and Enum.FillDirection.Vertical or Enum.FillDirection.Horizontal
	Row.Left.Size = Single and UDim2.fromScale(1, 0) or UDim2.new(0.5, -8, 0, 0)
	Row.Right.Size = Row.Left.Size
end

function SectionMeta:NewRow(Full)
	self.RowCount += 1
	local Frame = New("Frame", {
		Name = "Row",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = self.RowCount + 1,
		Parent = self.Frame,
	})
	local Layout = List(Frame, 16, Enum.FillDirection.Horizontal)
	local function Column(Order)
		local C = New("Frame", {
			BackgroundTransparency = 1,
			Size = Full and UDim2.fromScale(1, 0) or UDim2.new(0.5, -8, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			LayoutOrder = Order,
			Parent = Frame,
		})
		List(C, 16)
		return C
	end
	local Row = { Frame = Frame, Layout = Layout, Full = Full, Left = Column(1) }
	if not Full then
		Row.Right = Column(2)
	end
	ApplyColumns(Row, self.Tab.Window.SingleColumn)
	table.insert(self.Rows, Row)
	self.Current = Row
	return Row
end

function SectionMeta:Column(Side)
	if Side == "Full" then
		local Row = self:NewRow(true)
		self.Current = nil
		return Row.Left
	end
	local Row = self.Current or self:NewRow(false)
	return Side == "Right" and Row.Right or Row.Left
end

function SectionMeta:AddGroup(Info)
	Info = Info or {}
	return CreateGroup(self.Tab, self:Column(Info.Side or "Left"), Info)
end
function SectionMeta:AddLeftGroupbox(Name, Icon, Visible, Collapsed)
	local Info = type(Name) == "table" and Name or { Title = Name, Icon = Icon, Visible = Visible, Collapsed = Collapsed }
	Info.Side = "Left"
	Info.Title = Info.Title or Info.Name
	return self:AddGroup(Info)
end
function SectionMeta:AddRightGroupbox(Name, Icon, Visible, Collapsed)
	local Info = type(Name) == "table" and Name or { Title = Name, Icon = Icon, Visible = Visible, Collapsed = Collapsed }
	Info.Side = "Right"
	Info.Title = Info.Title or Info.Name
	return self:AddGroup(Info)
end
function SectionMeta:AddFullGroupbox(Name, Icon)
	local Info = type(Name) == "table" and Name or { Title = Name, Icon = Icon }
	Info.Side = "Full"
	Info.Title = Info.Title or Info.Name
	return self:AddGroup(Info)
end
function SectionMeta:AddLeftTabbox(Name)
	return CreateTabbox(self.Tab, self:Column("Left"), Name)
end
function SectionMeta:AddRightTabbox(Name)
	return CreateTabbox(self.Tab, self:Column("Right"), Name)
end

local function CreateSection(Tab, Title, Info)
	if type(Info) == "string" then
		Info = { Description = Info }
	end
	Info = Info or {}
	Tab.SectionCount += 1
	local Section = setmetatable({ Tab = Tab, Rows = {}, RowCount = 0 }, SectionMeta)
	local Frame = New("Frame", {
		Name = "Section",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = Tab.SectionCount,
		Parent = Tab.Scroll,
	})
	List(Frame, 14)
	Section.Frame = Frame
	if Title then
		local Head = New("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, Info.Description and 40 or 24),
			LayoutOrder = 1,
			Parent = Frame,
		})
		local W = Util.TextBounds(Title, 16, "Bold")
		Text("Text", "Bold", { Size = UDim2.new(0, W + 4, 0, 22), Text = Title, TextSize = 16, Parent = Head })
		local Rule = New("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, W + 18, 0, 11),
			Size = UDim2.new(1, -(W + 18), 0, 1),
			BackgroundColor3 = White,
			Parent = Head,
		})
		New("UIGradient", { Transparency = NumberSequence.new({ KP(0, 0.85), KP(1, 1) }), Parent = Rule })
		if Info.Description then
			Text("Muted", "Regular", {
				Position = UDim2.fromOffset(0, 24),
				Size = UDim2.new(1, 0, 0, 16),
				Text = Info.Description,
				TextSize = 13,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = Head,
			})
		end
	end
	table.insert(Tab.Sections, Section)
	return Section
end

-- ============================================================
-- WINDOW
-- ============================================================
local TabMeta = {}
TabMeta.__index = TabMeta

function TabMeta:AddSection(Title, Info)
	return CreateSection(self, Title, Info)
end
function TabMeta:DefaultSection()
	if not self.Default then
		self.Default = CreateSection(self, nil)
	end
	return self.Default
end
function TabMeta:AddLeftGroupbox(...)
	return self:DefaultSection():AddLeftGroupbox(...)
end
function TabMeta:AddRightGroupbox(...)
	return self:DefaultSection():AddRightGroupbox(...)
end
function TabMeta:AddFullGroupbox(...)
	return self:DefaultSection():AddFullGroupbox(...)
end
function TabMeta:AddGroup(Info)
	return self:DefaultSection():AddGroup(Info)
end
function TabMeta:AddLeftTabbox(Name)
	return self:DefaultSection():AddLeftTabbox(Name)
end
function TabMeta:AddRightTabbox(Name)
	return self:DefaultSection():AddRightTabbox(Name)
end
TabMeta.AddGroupbox = function(self, Info)
	return self:AddGroup(Info)
end

function Library:SetTheme(Theme, Instant)
	local Source = type(Theme) == "string" and Themes[Theme] or Theme
	if type(Source) ~= "table" then
		return
	end
	for K, V in Source do
		Scheme[K] = V
	end
	Scheme.Name = type(Theme) == "string" and Theme or "Custom"
	Library:UpdateColors(not Instant)
end

function Library:SetAccent(Color)
	Scheme.Accent = Color
	Library:UpdateColors(true)
end

function Library:SetFont(FontFace)
	if typeof(FontFace) == "EnumItem" then
		FontFace = Font.fromEnum(FontFace)
	end
	Scheme.Font = FontFace
	Library:UpdateColors(false)
end

function Library:UpdateColors(Animate)
	for Inst, Props in Registry do
		if Inst.Parent then
			for Prop, Key in Props do
				local V = Resolve(Key)
				if V ~= nil then
					if Animate and typeof(V) == "Color3" then
						Motion.Tween(Inst, { [Prop] = V }, 0.45, Motion.Ease.Glass)
					else
						Inst[Prop] = V
					end
				end
			end
		end
	end
	for Panel in Acrylic.Panels do
		for _, P in Panel.Parts do
			P.Part.Color = Scheme.Background
		end
	end
	for Key, Hook in Library.ThemeHooks do
		if Key.Parent == nil then
			Library.ThemeHooks[Key] = nil
		else
			task.spawn(Hook)
		end
	end
	if Library.Window then
		Library.Window:ApplyGlass()
	end
end

function Library:Toggle(Visible)
	if Library.Window then
		Library.Window:Toggle(Visible)
	end
end

function Library:SetDPIScale(Scale)
	Scale = tonumber(Scale) or 1
	if Scale > 5 then
		Scale /= 100
	end
	Library.DPIScale = Util.Clamp(Scale, 0.5, 2)
	if Library.Window then
		Library.Window:ApplyScale()
		if Library.Window.Reclamp then
			Library.Window:Reclamp()
		end
	end
end

function Library:SetGlassOpacity(V)
	Library.GlassOpacity = Util.Clamp(V, 0, 1)
	if Library.Window then
		Library.Window:ApplyGlass()
	end
end

function Library:SetAcrylic(On)
	Library.AcrylicEnabled = On and true or false
	if Library.Window then
		Library.Window:ApplyGlass()
	end
end

function Library:SetBoostGraphics(On)
	Library.BoostGraphics = On and true or false
	if Library.BoostGraphics then
		Graphics.Boost()
	else
		Graphics.Restore()
	end
	if Library.Window then
		Library.Window:ApplyGlass()
	end
end

-- Is the frosted blur actually going to render?
function Library:AcrylicActive()
	if not Library.AcrylicEnabled then
		return false
	end
	if Graphics.Boosted then
		return true
	end
	local Q = Graphics.Quality()
	return Q == nil or Q >= 8
end

function Library:UpdateSearch(Query)
	local Window = Library.Window
	if not Window or not Window.ActiveTab then
		return
	end
	Query = tostring(Query or ""):lower()
	Library.SearchText = Query
	local Tab = Window.ActiveTab
	for _, Group in Tab.Groups do
		local TitleHit = Query ~= "" and tostring(Group.Title or ""):lower():find(Query, 1, true) ~= nil
		local Any = false
		for _, Element in Group.AllElements do
			local Hit = Query == "" or TitleHit or (Element.SearchText and tostring(Element.SearchText):lower():find(Query, 1, true) ~= nil)
			Element.SearchHidden = not Hit
			if Element.Holder and Element.Type ~= "SubButton" then
				Element.Holder.Visible = (Element.Visible ~= false) and Hit
			end
			if Hit and Element.Visible ~= false then
				Any = true
			end
		end
		Group.SearchHidden = Query ~= "" and not (Any or TitleHit)
		Group.Card.Visible = Group.Visible ~= false and not Group.SearchHidden
	end
end

function Library:CreateWindow(Info)
	Info = Util.Validate(Info, {
		Title = "Skibidi",
		Subtitle = nil,
		Footer = nil,
		Icon = nil,
		Size = Vector2.new(860, 580),
		Center = true,
		AutoShow = true,
		ToggleKeybind = Enum.KeyCode.LeftControl,
		NotifySide = "Right",
		Acrylic = true,
		BoostGraphics = true,
		GlassOpacity = 0.62,
		SidebarWidth = 214,
		Resizable = true,
		MinSize = Vector2.new(640, 440),
		MobileButton = Library.IsMobile,
		ShowProfile = true,
		Theme = "Frost",
		DPIScale = 1,
		ConfigFolder = "Skibidi",
		ScreenClamp = false,
		ScreenClampPadding = 8,
	})
	if typeof(Info.Size) == "UDim2" then
		Info.Size = Vector2.new(Info.Size.X.Offset, Info.Size.Y.Offset)
	end
	if Info.Font then
		Library:SetFont(Info.Font)
	end

	Library.ConfigFolder = Info.ConfigFolder
	Library.ToggleKeybind = Info.ToggleKeybind
	Library.AcrylicEnabled = Info.Acrylic
	Library.BoostGraphics = Info.BoostGraphics
	Library.GlassOpacity = Info.GlassOpacity
	Library.DPIScale = Info.DPIScale
	Library:SetNotifySide(Info.NotifySide)
	if Info.Theme and Themes[Info.Theme] then
		Library:SetTheme(Info.Theme, true)
	end
	Library:LoadPrefs()
	if Library.BoostGraphics then
		Graphics.Boost()
	end

	local Camera = workspace.CurrentCamera
	local Viewport = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
	local SW = Info.SidebarWidth

	local Window = {
		Tabs = {},
		Visible = false,
		ActiveTab = nil,
		SingleColumn = false,
		MinSize = Info.MinSize,
	}
	Library.Window = Window

	-- frame ------------------------------------------------------------------
	local Root = New("Frame", {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(Info.Size.X, Info.Size.Y),
		Visible = false,
		Parent = WindowLayer,
	})
	local Scale = New("UIScale", { Parent = Root })
	local Shadow = Glass.Shadow(Root, { Spread = 80, Y = 14, Transparency = 1 })
	local Main = New("CanvasGroup", {
		Name = "Main",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = 1,
		ZIndex = 1,
		Parent = Root,
	})
	local Surface = New("Frame", {
		Name = "Surface",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -2, 1, -2),
		Theme = { BackgroundColor3 = "Background" },
		Parent = Main,
	})
	Corner(Surface, 16)
	Glass.Edge(Surface, { Transparency = 0.38, Thickness = 1 })
	Glass.Sheen(Surface, 16, 0.05)
	-- a faint wash of the accent, so the glass has a little colour of its own
	local Wash = New("Frame", {
		Name = "Wash",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 0,
		ZIndex = 0,
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Surface,
	})
	Corner(Wash, 16)
	New("UIGradient", {
		Rotation = 35,
		Transparency = NumberSequence.new({ KP(0, 0.93), KP(0.45, 0.98), KP(1, 1) }),
		Parent = Wash,
	})
	Window.Root, Window.Main, Window.Surface = Root, Main, Surface

	-- springs that drive position, size and the open/close scale
	local PosSpring = Spring.new(Vector2.new(Viewport.X / 2, Viewport.Y / 2), 22, 1, function(P)
		Root.Position = UDim2.fromOffset(P.X, P.Y)
		Glass.Dirty = true
	end)
	PosSpring:Snap(Vector2.new(Viewport.X / 2, Viewport.Y / 2))
	local SizeSpring = Spring.new(Info.Size, 24, 1, function(S)
		Root.Size = UDim2.fromOffset(S.X, S.Y)
		Glass.Dirty = true
	end)
	local OpenScale = Spring.Feel(0.965, "Gentle", function(S)
		Scale.Scale = S * Library.DPIScale
		Library.CurrentScale = Scale.Scale
	end)
	OpenScale:Snap(0.965)

	function Window:ApplyScale()
		Scale.Scale = OpenScale:Get() * Library.DPIScale
		Library.CurrentScale = Scale.Scale
	end

	function Window:ApplyGlass()
		local Active = Library:AcrylicActive()
		local Opacity = Active and Library.GlassOpacity or math.max(Library.GlassOpacity, 0.88)
		Motion.Tween(Surface, { BackgroundTransparency = 1 - Opacity }, 0.4, Motion.Ease.Glass)
	end
	Surface.BackgroundTransparency = 1 - Library.GlassOpacity
	Window:ApplyGlass()

	Window.Acrylic = Acrylic.Attach(Surface, 16, function()
		return Window.Visible and Main.GroupTransparency < 0.6 and Library:AcrylicActive()
	end)

	-- sidebar ------------------------------------------------------------------
	local Sidebar = New("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, SW, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = Surface,
	})
	-- rounded on the outer edge, cut square where it meets the content
	local SidebarTint = New("Frame", {
		Size = UDim2.new(1, 16, 1, 0),
		BackgroundColor3 = White,
		BackgroundTransparency = 0.975,
		ZIndex = 0,
		Parent = Sidebar,
	})
	Corner(SidebarTint, 16)
	local Divider = New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = White,
		Parent = Sidebar,
	})
	New("UIGradient", {
		Rotation = 90,
		Transparency = NumberSequence.new({ KP(0, 0.95), KP(0.5, 0.88), KP(1, 0.95) }),
		Parent = Divider,
	})

	local Brand = New("Frame", {
		Name = "Brand",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 74),
		Parent = Sidebar,
	})
	local BrandX = 20
	local BrandIcon = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 20, 0, 38),
		Size = UDim2.fromOffset(28, 28),
		Parent = Brand,
	})
	Corner(BrandIcon, 8)
	if Util.ApplyIcon(BrandIcon, Info.Icon) then
		BrandX = 58
	end
	local TitleLabel = Text("Text", "Bold", {
		Position = UDim2.fromOffset(BrandX, Info.Subtitle and 21 or 28),
		Size = UDim2.new(1, -BrandX - 14, 0, 20),
		Text = Info.Title,
		TextSize = 17,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = Brand,
	})
	local SubtitleLabel = Text("Muted", "Medium", {
		Position = UDim2.fromOffset(BrandX, 41),
		Size = UDim2.new(1, -BrandX - 14, 0, 16),
		Text = Info.Subtitle or "",
		TextSize = 12,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Visible = Info.Subtitle ~= nil,
		Parent = Brand,
	})

	local SearchField = New("Frame", {
		Position = UDim2.fromOffset(14, 76),
		Size = UDim2.new(1, -28, 0, 34),
		BackgroundTransparency = 0.94,
		Parent = Sidebar,
	})
	Corner(SearchField, 10)
	local SearchStroke = Glass.Edge(SearchField, { Transparency = 0.6 })
	local SearchIcon = New("ImageLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 11, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		Theme = { ImageColor3 = "Muted" },
		Parent = SearchField,
	})
	local SearchX = Util.ApplyIcon(SearchIcon, "search") and 32 or 12
	local SearchBox = Text("Text", "Regular", {
		Class = "TextBox",
		Position = UDim2.fromOffset(SearchX, 0),
		Size = UDim2.new(1, -SearchX - 10, 1, 0),
		PlaceholderText = "Search",
		Text = "",
		TextSize = 13,
		Theme = { PlaceholderColor3 = "Muted" },
		Parent = SearchField,
	})
	SearchBox.Focused:Connect(function()
		Motion.Tween(SearchStroke, { Transparency = 0.25, Color = Scheme.Accent }, 0.3, Motion.Ease.Glass)
	end)
	SearchBox.FocusLost:Connect(function()
		Motion.Tween(SearchStroke, { Transparency = 0.6, Color = White }, 0.3, Motion.Ease.Soft)
	end)
	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		Library:UpdateSearch(SearchBox.Text)
	end)

	local ProfileH = Info.ShowProfile and 64 or 0
	local TabScroll = New("ScrollingFrame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(0, 122),
		Size = UDim2.new(1, 0, 1, -122 - ProfileH),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Parent = Sidebar,
	})
	Util.SmoothScroll(TabScroll)
	local TabHolder = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(12, 0),
		Size = UDim2.new(1, -24, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Parent = TabScroll,
	})
	local TabList = New("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 2,
		Parent = TabHolder,
	})
	List(TabList, 2)

	-- the liquid pill behind the active tab
	local Pill = New("Frame", {
		Name = "Pill",
		BackgroundColor3 = White,
		BackgroundTransparency = 0.9,
		Size = UDim2.new(1, 0, 0, 38),
		ZIndex = 1,
		Visible = false,
		Parent = TabHolder,
	})
	Corner(Pill, 10)
	Glass.Edge(Pill, { Transparency = 0.55 })
	local PillMark = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(3, 16),
		Theme = { BackgroundColor3 = "Accent" },
		Parent = Pill,
	})
	Round(PillMark)
	local PillTop, PillBottom
	local function PaintPill()
		local T, B = PillTop:Get(), PillBottom:Get()
		Pill.Position = UDim2.fromOffset(0, T)
		Pill.Size = UDim2.new(1, 0, 0, math.max(B - T, 10))
	end
	PillTop = Spring.new(0, 24, 1, PaintPill)
	PillBottom = Spring.new(38, 24, 1, PaintPill)
	local function MovePill(Y, H, Snap)
		Pill.Visible = true
		if Snap then
			PillTop:Snap(Y)
			PillBottom:Snap(Y + H)
			return
		end
		local Down = Y > PillTop:Goal()
		PillTop.Speed = Down and 20 or 26
		PillBottom.Speed = Down and 26 or 20
		PillTop:Set(Y)
		PillBottom:Set(Y + H)
	end

	if Info.ShowProfile then
		local Profile = New("Frame", {
			Name = "Profile",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = UDim2.new(1, 0, 0, ProfileH),
			BackgroundTransparency = 1,
			Parent = Sidebar,
		})
		local Rule = New("Frame", {
			Position = UDim2.fromOffset(16, 0),
			Size = UDim2.new(1, -32, 0, 1),
			BackgroundColor3 = White,
			Parent = Profile,
		})
		New("UIGradient", { Transparency = NumberSequence.new({ KP(0, 1), KP(0.5, 0.9), KP(1, 1) }), Parent = Rule })
		local Avatar = New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 18, 0.5, 0),
			Size = UDim2.fromOffset(32, 32),
			BackgroundTransparency = 0.9,
			BackgroundColor3 = White,
			Parent = Profile,
		})
		Round(Avatar)
		Glass.Edge(Avatar, { Transparency = 0.4 })
		task.spawn(function()
			local Ok, Image = pcall(Players.GetUserThumbnailAsync, Players, LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48)
			if Ok and Avatar.Parent then
				Avatar.Image = Image
			end
		end)
		Text("Text", "SemiBold", {
			Position = UDim2.new(0, 60, 0.5, -16),
			Size = UDim2.new(1, -74, 0, 17),
			Text = LocalPlayer.DisplayName,
			TextSize = 13,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Profile,
		})
		Window.FooterLabel = Text("Muted", "Regular", {
			Position = UDim2.new(0, 60, 0.5, 1),
			Size = UDim2.new(1, -74, 0, 15),
			Text = Info.Footer or ("@" .. LocalPlayer.Name),
			TextSize = 12,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Profile,
		})
	end

	-- content ----------------------------------------------------------------
	local Content = New("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(SW, 0),
		Size = UDim2.new(1, -SW, 1, 0),
		Parent = Surface,
	})
	local Header = New("Frame", {
		Name = "Header",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 74),
		Parent = Content,
	})
	local HeaderText = New("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(26, 0),
		Size = UDim2.new(1, -130, 1, 0),
		Parent = Header,
	})
	local TabTitle = Text("Text", "Bold", {
		Position = UDim2.fromOffset(0, 18),
		Size = UDim2.new(1, 0, 0, 24),
		TextSize = 21,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = HeaderText,
	})
	local TabDesc = Text("Muted", "Regular", {
		Position = UDim2.fromOffset(0, 43),
		Size = UDim2.new(1, 0, 0, 16),
		TextSize = 13,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = HeaderText,
	})
	local TitleRise = Spring.Feel(0, "Smooth", function(Y)
		HeaderText.Position = UDim2.fromOffset(26, Y)
	end)

	local Controls = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -18, 0, 37),
		Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		Parent = Header,
	})
	List(Controls, 4, Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
	local function Control(Icon, Glyph, Order, Danger)
		-- just the icon at rest; the glass button only appears on hover
		local B = New("TextButton", {
			Size = UDim2.fromOffset(34, 34),
			BackgroundColor3 = White,
			BackgroundTransparency = 1,
			LayoutOrder = Order,
			Parent = Controls,
		})
		Corner(B, 10)
		local Edge = Glass.Edge(B, { Transparency = 1 })
		local Img = New("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(16, 16),
			Theme = { ImageColor3 = "SubText" },
			Parent = B,
		})
		local GlyphLabel
		if not Util.ApplyIcon(Img, Icon) then
			GlyphLabel = Text("SubText", "Bold", {
				Size = UDim2.fromScale(1, 1),
				Text = Glyph,
				TextSize = 17,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = B,
			})
		end
		Glass.Press(B, B, 0.94)
		B.MouseEnter:Connect(function()
			Motion.Tween(B, {
				BackgroundTransparency = Danger and 0.84 or 0.91,
				BackgroundColor3 = Danger and Scheme.Risky or White,
			}, 0.2, Motion.Ease.Soft)
			Motion.Tween(Edge, { Transparency = 0.6 }, 0.2, Motion.Ease.Soft)
			Motion.Tween(Img, { ImageColor3 = Danger and Scheme.Risky or Scheme.Text }, 0.2, Motion.Ease.Soft)
		end)
		B.MouseLeave:Connect(function()
			Motion.Tween(B, { BackgroundTransparency = 1, BackgroundColor3 = White }, 0.3, Motion.Ease.Soft)
			Motion.Tween(Edge, { Transparency = 1 }, 0.3, Motion.Ease.Soft)
			Motion.Tween(Img, { ImageColor3 = Scheme.SubText }, 0.3, Motion.Ease.Soft)
		end)
		-- Instances can't hold custom members, so the setter travels alongside the button
		local function SetIcon(NewIcon, NewGlyph)
			if GlyphLabel then
				GlyphLabel.Text = NewGlyph
			else
				Util.ApplyIcon(Img, NewIcon)
			end
		end
		return B, SetIcon
	end
	local MinimizeButton = Control("minus", "–", 1)
	local FullscreenButton, SetFullscreenIcon = Control("maximize-2", "□", 2)
	local CloseButton = Control("x", "×", 3, true)
	Window.FullscreenButton = FullscreenButton
	MinimizeButton.Activated:Connect(function()
		Window:Toggle(false)
		if not Window.MobileButton then
			local Key = Library.ToggleKeybind
			local Name = typeof(Key) == "EnumItem" and Key.Name or (type(Key) == "table" and Key.Value) or nil
			if Name and Name ~= "None" then
				Library:Notify({ Title = "Hidden", Description = "Press " .. Util.KeyName(Name) .. " to bring it back.", Time = 3 })
			end
		end
	end)
	CloseButton.Activated:Connect(function()
		Library:Dialog({
			Title = "Close " .. Info.Title .. "?",
			Description = "This unloads the interface and puts your settings back.",
			Buttons = {
				{ Title = "Cancel", Variant = "Default" },
				{
					Title = "Close",
					Variant = "Danger",
					Callback = function()
						Library:Unload()
					end,
				},
			},
		})
	end)

	local HeaderRule = New("Frame", {
		Position = UDim2.fromOffset(26, 73),
		Size = UDim2.new(1, -52, 0, 1),
		BackgroundColor3 = White,
		Parent = Content,
	})
	New("UIGradient", { Transparency = NumberSequence.new({ KP(0, 0.9), KP(1, 1) }), Parent = HeaderRule })

	local Pages = New("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(0, 74),
		Size = UDim2.new(1, 0, 1, -74),
		Parent = Content,
	})
	Window.Pages = Pages

	Pages:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		local Single = Util.Unscale(Pages.AbsoluteSize.X) < 560
		if Single ~= Window.SingleColumn then
			Window.SingleColumn = Single
			for _, Tab in Window.Tabs do
				for _, Section in Tab.Sections do
					for _, Row in Section.Rows do
						ApplyColumns(Row, Single)
					end
				end
			end
		end
	end)

	-- dragging and resizing --------------------------------------------------
	local function ViewportNow()
		local Cam = workspace.CurrentCamera
		return Cam and Cam.ViewportSize or Viewport
	end

	-- Screen clamp (optional): the whole window stays inside the viewport,
	-- ScreenClampPadding px from every edge. Sizes are spring goals scaled by
	-- DPIScale only, not the open animation, so the bounds don't shift while
	-- the window is still settling. A window wider or taller than the screen
	-- is centred on that axis.
	Window.ScreenClamp = Info.ScreenClamp and true or false
	Window.ScreenClampPadding = math.max(tonumber(Info.ScreenClampPadding) or 8, 0)
	-- the size the user asked for; the clamp may show it smaller on a small
	-- screen, and it comes back once there is room again
	local WantedSize = SizeSpring:Goal()

	local function ClampPos(P, Size)
		local V = ViewportNow()
		local Half = (Size or SizeSpring:Goal()) * Library.DPIScale / 2
		if Window.ScreenClamp then
			local Pad = Window.ScreenClampPadding
			local function Axis(C, H, Max)
				local Lo, Hi = H + Pad, Max - H - Pad
				return Lo <= Hi and Util.Clamp(C, Lo, Hi) or Max / 2
			end
			return Vector2.new(Axis(P.X, Half.X, V.X), Axis(P.Y, Half.Y, V.Y))
		end
		-- keep the header on screen; the rest may hang off the edges
		return Vector2.new(
			Util.Clamp(P.X, -Half.X + 80, V.X + Half.X - 80),
			Util.Clamp(P.Y, Half.Y, V.Y + Half.Y - 60)
		)
	end

	-- the biggest size that still fits on screen inside the padding
	local function FitSize(S)
		local Room = (ViewportNow() - Vector2.one * Window.ScreenClampPadding * 2) / Library.DPIScale
		return Vector2.new(
			math.max(math.min(S.X, Room.X), Window.MinSize.X),
			math.max(math.min(S.Y, Room.Y), Window.MinSize.Y)
		)
	end

	-- pull the window back inside after anything that could push it out
	-- (viewport resize, DPI change, SetSize, restoring from fullscreen)
	local function Reclamp(Instant)
		if not Window.ScreenClamp or Window.Fullscreen then
			return
		end
		local V = ViewportNow()
		if V.X < 64 or V.Y < 64 then
			return -- the camera reports a 1x1 viewport for a moment at startup
		end
		local Size = FitSize(WantedSize)
		if Size ~= SizeSpring:Goal() then
			if Instant then
				SizeSpring:Snap(Size)
			else
				SizeSpring:Set(Size)
			end
		end
		local Pos = ClampPos(PosSpring:Goal(), Size)
		if Pos ~= PosSpring:Goal() then
			if Instant then
				PosSpring:Snap(Pos)
			else
				PosSpring:Set(Pos)
			end
		end
	end
	Window.Reclamp = function(_, Instant)
		Reclamp(Instant)
	end

	function Window:SetScreenClamp(On, Padding)
		On = On and true or false
		local Was = self.ScreenClamp
		self.ScreenClamp = On
		if tonumber(Padding) then
			self.ScreenClampPadding = math.max(tonumber(Padding), 0)
		end
		if On then
			Reclamp()
		elseif Was and not self.Fullscreen then
			SizeSpring:Set(WantedSize)
		end
	end
	for _, Handle in { Header, Brand } do
		Library:MakeDraggable(Handle, {
			Get = function()
				return PosSpring:Goal()
			end,
			Set = function(P)
				PosSpring:Set(P)
				Window:SetFullscreen(false, true)
			end,
			Clamp = ClampPos,
			Began = function()
				Library:CloseAllPopups()
			end,
		})
	end

	if Info.Resizable then
		local Grip = New("TextButton", {
			Name = "Resize",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1, 1),
			Size = UDim2.fromOffset(22, 22),
			ZIndex = 20,
			Parent = Surface,
		})
		for I = 1, 3 do
			local Dot = New("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(16 - (I - 1) * 4, 16 - (3 - I) * 4),
				Size = UDim2.fromOffset(2.5, 2.5),
				BackgroundTransparency = 0.6,
				Parent = Grip,
			})
			Round(Dot)
		end
		Grip.InputBegan:Connect(function(Input)
			if not Util.IsPress(Input) then
				return
			end
			local Start = Util.Pointer(Input)
			local StartSize = SizeSpring:Goal()
			local StartPos = PosSpring:Goal()
			Library:CloseAllPopups()
			Util.Track(Input, function(P)
				local V = ViewportNow()
				local D = (P - Start) / Library.DPIScale
				local Max = V / Library.DPIScale - Vector2.new(20, 20)
				if Window.ScreenClamp then
					-- the top-left corner stays put, so the room left is what
					-- lies between it and the bottom-right padding
					local TopLeft = StartPos - StartSize * Library.DPIScale / 2
					local Room = (V - Vector2.one * Window.ScreenClampPadding - TopLeft) / Library.DPIScale
					Max = Vector2.new(math.min(Max.X, Room.X), math.min(Max.Y, Room.Y))
				end
				local NewSize = Vector2.new(
					Util.Clamp(StartSize.X + D.X, Window.MinSize.X, math.max(Max.X, Window.MinSize.X)),
					Util.Clamp(StartSize.Y + D.Y, Window.MinSize.Y, math.max(Max.Y, Window.MinSize.Y))
				)
				SizeSpring:Set(NewSize)
				WantedSize = NewSize
				PosSpring:Set(StartPos + (NewSize - StartSize) * Library.DPIScale / 2)
				Window:SetFullscreen(false, true)
			end)
		end)
	end

	-- fullscreen: grow to nearly the whole screen, leaving a small margin
	local FULLSCREEN_MARGIN = 16
	local Restore
	Window.Fullscreen = false
	function Window:SetFullscreen(On, KeepSize)
		On = On and true or false
		if On == self.Fullscreen then
			return
		end
		self.Fullscreen = On
		SetFullscreenIcon(On and "minimize-2" or "maximize-2", On and "▣" or "□")
		Library:CloseAllPopups()
		if On then
			Restore = { Size = WantedSize, Pos = PosSpring:Goal() }
			local Cam = workspace.CurrentCamera
			local V = Cam and Cam.ViewportSize or Viewport
			local Max = V / Library.DPIScale - Vector2.new(FULLSCREEN_MARGIN, FULLSCREEN_MARGIN) * 2
			SizeSpring:Set(Vector2.new(math.max(Max.X, self.MinSize.X), math.max(Max.Y, self.MinSize.Y)))
			PosSpring:Set(V / 2)
		elseif Restore and not KeepSize then
			SizeSpring:Set(Restore.Size)
			PosSpring:Set(Restore.Pos)
			WantedSize = Restore.Size
			-- the screen may have shrunk while it was fullscreen
			Reclamp()
		else
			-- dragged or resized out of fullscreen: the big size is kept
			WantedSize = SizeSpring:Goal()
		end
	end
	function Window:ToggleFullscreen()
		self:SetFullscreen(not self.Fullscreen)
	end
	FullscreenButton.Activated:Connect(function()
		Window:ToggleFullscreen()
	end)

	-- tabs -------------------------------------------------------------------
	local function SwapHeader(Title, Desc, Direction)
		Motion.Tween(TabTitle, { TextTransparency = 1 }, 0.12, Motion.Ease.Exit)
		Motion.Tween(TabDesc, { TextTransparency = 1 }, 0.12, Motion.Ease.Exit, function()
			TabTitle.Text = Title
			TabDesc.Text = Desc or ""
			TitleRise:Snap(5 * Direction)
			TitleRise:Set(0)
			Motion.Tween(TabTitle, { TextTransparency = 0 }, 0.34, Motion.Ease.Glass)
			Motion.Tween(TabDesc, { TextTransparency = 0 }, 0.42, Motion.Ease.Glass)
		end)
		TitleRise:Set(-4 * Direction)
	end

	local function TabY(Target)
		local Y = 0
		for _, T in Window.Tabs do
			if T == Target then
				return Y
			end
			if T.Button.Visible then
				Y += 38 + 2
			end
		end
		return Y
	end

	function Window:AddTab(A, B, C)
		local TabInfo = type(A) == "table" and A or { Name = A, Icon = B, Description = C }
		TabInfo.Name = TabInfo.Name or TabInfo.Title or "Tab"
		local Tab = setmetatable({
			Name = TabInfo.Name,
			Description = TabInfo.Description,
			Window = Window,
			Groups = {},
			Sections = {},
			Elements = {},
			SectionCount = 0,
			Index = #Window.Tabs + 1,
		}, TabMeta)

		local Button = New("TextButton", {
			Name = "Tab",
			Size = UDim2.new(1, 0, 0, 38),
			LayoutOrder = Tab.Index,
			Parent = TabList,
		})
		Tab.Button = Button
		local Icon = New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, 0),
			Size = UDim2.fromOffset(17, 17),
			Theme = { ImageColor3 = "Muted" },
			Parent = Button,
		})
		local LX = Util.ApplyIcon(Icon, TabInfo.Icon) and 42 or 16
		local Label = Text("SubText", "Medium", {
			Position = UDim2.fromOffset(LX, 0),
			Size = UDim2.new(1, -LX - 10, 1, 0),
			Text = Tab.Name,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = Button,
		})
		local Nudge = Spring.Feel(0, "Smooth", function(X)
			Label.Position = UDim2.fromOffset(LX + X, 0)
			Icon.Position = UDim2.new(0, 14 + X * 0.5, 0.5, 0)
		end)
		Button.MouseEnter:Connect(function()
			if Window.ActiveTab ~= Tab then
				Nudge:Set(2)
				Motion.Tween(Label, { TextColor3 = Scheme.Text }, 0.2, Motion.Ease.Soft)
			end
		end)
		Button.MouseLeave:Connect(function()
			Nudge:Set(0)
			if Window.ActiveTab ~= Tab then
				Motion.Tween(Label, { TextColor3 = Scheme.SubText }, 0.3, Motion.Ease.Soft)
			end
		end)

		local Page = New("CanvasGroup", {
			Name = Tab.Name,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			GroupTransparency = 1,
			Visible = false,
			Parent = Pages,
		})
		local Scroll = New("ScrollingFrame", {
			Size = UDim2.fromScale(1, 1),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			Parent = Page,
		})
		Pad(Scroll, 20, 24, 26, 24)
		List(Scroll, 26)
		Util.SmoothScroll(Scroll)
		Tab.Page, Tab.Scroll = Page, Scroll
		Tab.Rise = Spring.Feel(0, "Gentle", function(Y)
			Page.Position = UDim2.fromOffset(0, Y)
		end)

		function Tab:Show()
			local Prev = Window.ActiveTab
			if Prev == self then
				return
			end
			Window.ActiveTab = self
			Library:CloseAllPopups()
			Tooltip.Hide()
			Glass.Dirty = true
			local Dir = (Prev and Prev.Index > self.Index) and -1 or 1
			if Prev then
				Prev:Hide(Dir)
			end
			Page.Visible = true
			self.Rise:Snap(10 * Dir)
			self.Rise:Set(0)
			Motion.Tween(Page, { GroupTransparency = 0 }, 0.38, Motion.Ease.Glass)
			Themed(Label, { TextColor3 = "Text", FontFace = Weights.SemiBold })
			Themed(Icon, { ImageColor3 = "Accent" })
			Nudge:Set(0)
			MovePill(TabY(self), 38, Prev == nil)
			if Prev then
				SwapHeader(self.Name, self.Description, Dir)
			else
				TabTitle.Text = self.Name
				TabDesc.Text = self.Description or ""
			end
			Library:UpdateSearch(SearchBox.Text)
			for _, Element in self.Elements do
				if Element.OnShown then
					Element:OnShown()
				end
			end
		end

		function Tab:Hide(Dir)
			Themed(Label, { TextColor3 = "SubText", FontFace = Weights.Medium })
			Themed(Icon, { ImageColor3 = "Muted" })
			self.Rise:Set(-6 * (Dir or 1))
			Motion.Tween(Page, { GroupTransparency = 1 }, 0.16, Motion.Ease.Exit, function()
				if Window.ActiveTab ~= self then
					Page.Visible = false
				end
			end)
			if Library.SearchText and Library.SearchText ~= "" then
				-- leave the hidden tab unfiltered
				for _, Group in self.Groups do
					Group.SearchHidden = false
					Group.Card.Visible = Group.Visible ~= false
					for _, Element in Group.AllElements do
						Element.SearchHidden = false
						if Element.Holder and Element.Type ~= "SubButton" then
							Element.Holder.Visible = Element.Visible ~= false
						end
					end
				end
			end
		end

		function Tab:SetVisible(V)
			Button.Visible = V and true or false
			if Window.ActiveTab then
				MovePill(TabY(Window.ActiveTab), 38)
			end
		end
		function Tab:SetName(Str)
			self.Name = tostring(Str)
			Label.Text = self.Name
			if Window.ActiveTab == self then
				TabTitle.Text = self.Name
			end
		end
		function Tab:SetDescription(Str)
			self.Description = Str
			if Window.ActiveTab == self then
				TabDesc.Text = Str or ""
			end
		end
		function Tab:Select()
			self:Show()
		end

		Button.Activated:Connect(function()
			Tab:Show()
		end)

		table.insert(Window.Tabs, Tab)
		if not Window.ActiveTab then
			Tab:Show()
		end
		return Tab
	end

	-- visibility -------------------------------------------------------------
	function Window:Toggle(Visible)
		if Visible == nil then
			Visible = not self.Visible
		end
		if Visible == self.Visible then
			return
		end
		self.Visible = Visible
		Library:CloseAllPopups()
		Tooltip.Hide()
		if Visible then
			Root.Visible = true
			OpenScale:Use("Gentle")
			OpenScale:Set(1)
			Motion.Tween(Main, { GroupTransparency = 0 }, 0.4, Motion.Ease.Glass)
			Motion.Tween(Shadow, { ImageTransparency = 0.45 }, 0.55, Motion.Ease.Glass)
			-- one faint pass of light across the pane as it settles
			task.delay(0.18, function()
				if self.Visible then
					Glass.Sweep(Surface, 16, { Fill = 0.025, Peak = 0.6, Duration = 1.6 })
				end
			end)
			if self.ActiveTab then
				for _, Element in self.ActiveTab.Elements do
					if Element.OnShown then
						Element:OnShown()
					end
				end
			end
		else
			OpenScale:Use("Smooth")
			OpenScale:Set(0.975)
			Motion.Tween(Shadow, { ImageTransparency = 1 }, 0.22, Motion.Ease.Exit)
			Motion.Tween(Main, { GroupTransparency = 1 }, 0.22, Motion.Ease.Exit, function()
				if not self.Visible then
					Root.Visible = false
					OpenScale:Snap(0.965)
				end
			end)
		end
		if self.MobileButton then
			Motion.Tween(self.MobileButton, { BackgroundTransparency = Visible and 0.3 or 0.12 }, 0.3, Motion.Ease.Soft)
		end
	end

	function Window:SetTitle(Str)
		TitleLabel.Text = tostring(Str)
	end
	Window.ChangeTitle = Window.SetTitle
	function Window:SetSubtitle(Str)
		SubtitleLabel.Text = Str and tostring(Str) or ""
		SubtitleLabel.Visible = Str ~= nil
		TitleLabel.Position = UDim2.fromOffset(BrandX, Str and 21 or 28)
	end
	function Window:SetFooter(Str)
		if self.FooterLabel then
			self.FooterLabel.Text = tostring(Str)
		end
	end
	function Window:SetSize(V)
		if typeof(V) == "UDim2" then
			V = Vector2.new(V.X.Offset, V.Y.Offset)
		end
		SizeSpring:Set(V)
		WantedSize = V
		Reclamp()
	end
	function Window:Center()
		local Cam = workspace.CurrentCamera
		local V = Cam and Cam.ViewportSize or Viewport
		PosSpring:Set(V / 2)
	end

	-- mobile: a floating glass button to bring the window back
	if Info.MobileButton then
		local MB = New("TextButton", {
			Name = "Toggle",
			Size = UDim2.fromOffset(48, 48),
			BackgroundTransparency = 0.12,
			ZIndex = 8,
			Theme = { BackgroundColor3 = "Background" },
			Parent = WindowLayer,
		})
		Round(MB)
		Glass.Edge(MB, { Transparency = 0.3 })
		local MBIcon = New("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(22, 22),
			Theme = { ImageColor3 = "Accent" },
			Parent = MB,
		})
		if not Util.ApplyIcon(MBIcon, Info.Icon or "layout-grid") then
			Text("Accent", "Bold", {
				Size = UDim2.fromScale(1, 1),
				Text = Info.Title:sub(1, 1),
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = MB,
			})
		end
		local MBPos = Spring.Feel(Vector2.new(20, 120), "Smooth", function(P)
			MB.Position = UDim2.fromOffset(P.X, P.Y)
		end)
		MBPos:Snap(Vector2.new(20, 120))
		local Moved = 0
		local From
		Library:MakeDraggable(MB, {
			Get = function()
				return MBPos:Goal()
			end,
			Set = function(P)
				Moved = math.max(Moved, (P - From).Magnitude)
				MBPos:Set(P)
			end,
			Clamp = function(P)
				if not Window.ScreenClamp then
					return P
				end
				local Room = ViewportNow() - MB.AbsoluteSize - Vector2.one * Window.ScreenClampPadding
				local Pad = Window.ScreenClampPadding
				return Vector2.new(Util.Clamp(P.X, Pad, math.max(Room.X, Pad)), Util.Clamp(P.Y, Pad, math.max(Room.Y, Pad)))
			end,
			Began = function()
				Moved = 0
				From = MBPos:Goal()
			end,
			Ended = function()
				if Moved < 6 then
					Window:Toggle()
				end
			end,
		})
		Window.MobileButton = MB
		Window.MobileButtonPos = MBPos
	end

	if Info.Position then
		local P = typeof(Info.Position) == "UDim2" and Vector2.new(Info.Position.X.Offset, Info.Position.Y.Offset) or Info.Position
		PosSpring:Snap(P + Info.Size / 2)
	end
	Reclamp(true)

	-- follow the screen: a resized viewport refits fullscreen and reclamps
	local ViewportConn
	local function OnViewport()
		if Library.Unloaded then
			return
		end
		if Window.Fullscreen then
			local V = ViewportNow()
			local Max = V / Library.DPIScale - Vector2.new(FULLSCREEN_MARGIN, FULLSCREEN_MARGIN) * 2
			SizeSpring:Set(Vector2.new(math.max(Max.X, Window.MinSize.X), math.max(Max.Y, Window.MinSize.Y)))
			PosSpring:Set(V / 2)
		else
			Reclamp()
		end
		if Window.ScreenClamp and Window.MobileButtonPos then
			local MBPos = Window.MobileButtonPos
			local Pad = Window.ScreenClampPadding
			local Room = ViewportNow() - Window.MobileButton.AbsoluteSize - Vector2.one * Pad
			local G = MBPos:Goal()
			MBPos:Set(Vector2.new(Util.Clamp(G.X, Pad, math.max(Room.X, Pad)), Util.Clamp(G.Y, Pad, math.max(Room.Y, Pad))))
		end
	end
	local function WatchCamera()
		if ViewportConn then
			ViewportConn:Disconnect()
			ViewportConn = nil
		end
		local Cam = workspace.CurrentCamera
		if Cam then
			ViewportConn = Library:Give(Cam:GetPropertyChangedSignal("ViewportSize"):Connect(OnViewport))
		end
		OnViewport()
	end
	Library:Give(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(WatchCamera))
	WatchCamera()
	if Info.AutoShow then
		task.defer(function()
			Window:Toggle(true)
		end)
	end
	return Window
end

-- ============================================================
-- PREFS + CONFIGS
-- ============================================================
local function EnsureFolder(Path)
	if not FS.Available then
		return false
	end
	return (pcall(function()
		local Built = ""
		for Segment in Path:gmatch("[^/]+") do
			Built = Built == "" and Segment or (Built .. "/" .. Segment)
			if not FS.isfolder(Built) then
				FS.makefolder(Built)
			end
		end
	end))
end

function Library:SetFolder(Folder)
	Library.ConfigFolder = tostring(Folder)
end

function Library:SetIgnoreIndexes(List_)
	for _, Idx in List_ do
		Library.IgnoreIndexes[Idx] = true
	end
end

local function PrefsPath()
	return Library.ConfigFolder .. "/prefs.json"
end

function Library:SavePrefs()
	if not EnsureFolder(Library.ConfigFolder) then
		return
	end
	pcall(function()
		FS.writefile(PrefsPath(), HttpService:JSONEncode({
			Theme = Scheme.Name,
			Accent = Util.Hex(Scheme.Accent),
			Acrylic = Library.AcrylicEnabled,
			BoostGraphics = Library.BoostGraphics,
			GlassOpacity = Library.GlassOpacity,
			NotifySide = Library.NotifySide,
			DPIScale = Library.DPIScale,
		}))
	end)
end

function Library:LoadPrefs()
	if not FS.Available then
		return
	end
	local Ok, Data = pcall(function()
		if not FS.isfile(PrefsPath()) then
			return nil
		end
		return HttpService:JSONDecode(FS.readfile(PrefsPath()))
	end)
	if not Ok or type(Data) ~= "table" then
		return
	end
	if Data.Theme and Themes[Data.Theme] then
		Library:SetTheme(Data.Theme, true)
	end
	local Accent = Data.Accent and Util.FromHex(Data.Accent)
	if Accent then
		Scheme.Accent = Accent
		Library:UpdateColors(false)
	end
	if Data.Acrylic ~= nil then
		Library.AcrylicEnabled = Data.Acrylic
	end
	if Data.BoostGraphics ~= nil then
		Library.BoostGraphics = Data.BoostGraphics
	end
	if tonumber(Data.GlassOpacity) then
		Library.GlassOpacity = Data.GlassOpacity
	end
	if Data.NotifySide then
		Library:SetNotifySide(Data.NotifySide)
	end
	if tonumber(Data.DPIScale) then
		Library.DPIScale = Data.DPIScale
	end
end

local function ConfigDir()
	return Library.ConfigFolder .. "/configs"
end

function Library:SaveConfig(Name)
	Name = tostring(Name or ""):gsub("[^%w%-_ ]", "")
	if Name == "" then
		return false, "Enter a config name"
	end
	if not EnsureFolder(ConfigDir()) then
		return false, "Your executor has no file functions"
	end
	local Objects = {}
	for Idx, T in Toggles do
		if not Library.IgnoreIndexes[Idx] then
			table.insert(Objects, { Type = "Toggle", Idx = Idx, Value = T.Value })
		end
	end
	for Idx, O in Options do
		if not Library.IgnoreIndexes[Idx] then
			if O.Type == "Slider" or O.Type == "Input" then
				table.insert(Objects, { Type = O.Type, Idx = Idx, Value = O.Value })
			elseif O.Type == "Dropdown" then
				local V = O.Value
				if O.Multi then
					V = O:GetActiveValues()
				end
				table.insert(Objects, { Type = "Dropdown", Idx = Idx, Value = V, Multi = O.Multi })
			elseif O.Type == "ColorPicker" then
				table.insert(Objects, { Type = "ColorPicker", Idx = Idx, Value = Util.Hex(O.Value), Transparency = O.Transparency })
			elseif O.Type == "KeyPicker" then
				table.insert(Objects, { Type = "KeyPicker", Idx = Idx, Key = O.Value, Mode = O.Mode })
			end
		end
	end
	local Ok, Err = pcall(function()
		FS.writefile(ConfigDir() .. "/" .. Name .. ".json", HttpService:JSONEncode({ Version = 1, Objects = Objects }))
	end)
	return Ok, Err
end

function Library:LoadConfig(Name)
	if not FS.Available then
		return false, "Your executor has no file functions"
	end
	local Path = ConfigDir() .. "/" .. tostring(Name) .. ".json"
	if not FS.isfile(Path) then
		return false, "Config not found"
	end
	local Ok, Data = pcall(function()
		return HttpService:JSONDecode(FS.readfile(Path))
	end)
	if not Ok or type(Data) ~= "table" then
		return false, "Config is corrupted"
	end
	for _, O in Data.Objects or {} do
		pcall(function()
			if O.Type == "Toggle" and Toggles[O.Idx] then
				Toggles[O.Idx]:SetValue(O.Value)
			elseif O.Type == "KeyPicker" and Options[O.Idx] then
				Options[O.Idx]:SetValue({ O.Key, O.Mode })
			elseif O.Type == "ColorPicker" and Options[O.Idx] then
				local C = Util.FromHex(O.Value)
				if C then
					Options[O.Idx]:SetValueRGB(C, O.Transparency)
				end
			elseif Options[O.Idx] then
				Options[O.Idx]:SetValue(O.Value)
			end
		end)
	end
	return true
end

function Library:DeleteConfig(Name)
	if not FS.Available then
		return false
	end
	local Path = ConfigDir() .. "/" .. tostring(Name) .. ".json"
	if FS.isfile(Path) then
		FS.delfile(Path)
		return true
	end
	return false
end

function Library:ListConfigs()
	if not FS.Available or not FS.listfiles or not EnsureFolder(ConfigDir()) then
		return {}
	end
	local Out = {}
	for _, File in FS.listfiles(ConfigDir()) do
		local Name = tostring(File):gsub("\\", "/"):match("([^/]+)%.json$")
		if Name then
			table.insert(Out, Name)
		end
	end
	table.sort(Out)
	return Out
end

function Library:SetAutoload(Name)
	if EnsureFolder(ConfigDir()) then
		FS.writefile(ConfigDir() .. "/autoload.txt", tostring(Name or ""))
	end
end

function Library:GetAutoload()
	if not FS.Available then
		return nil
	end
	local Path = ConfigDir() .. "/autoload.txt"
	if FS.isfile(Path) then
		local Name = FS.readfile(Path)
		return Name ~= "" and Name or nil
	end
	return nil
end

function Library:LoadAutoloadConfig()
	local Name = Library:GetAutoload()
	if Name then
		local Ok, Err = Library:LoadConfig(Name)
		if Ok then
			Library:Notify({ Title = "Config loaded", Description = "Autoloaded \"" .. Name .. "\".", Type = "Success", Time = 3 })
		else
			Library:Notify({ Title = "Autoload failed", Description = tostring(Err), Type = "Error" })
		end
	end
end

-- ============================================================
-- SETTINGS TAB  (appearance, graphics, menu bind, configs)
-- ============================================================
function Library.Window_AddSettingsTab(Window, Info)
	Info = Info or {}
	local Tab = Window:AddTab({ Name = Info.Name or "Settings", Icon = Info.Icon or "settings", Description = "Appearance, graphics and configs" })

	local Interface = Tab:AddSection("Interface", "How the window looks and behaves")
	local Look = Interface:AddLeftGroupbox("Appearance", "palette")
	local ThemeNames = {}
	for Name in Themes do
		table.insert(ThemeNames, Name)
	end
	table.sort(ThemeNames)
	Look:AddDropdown("Skibidi_Theme", {
		Text = "Theme",
		Values = ThemeNames,
		Default = Themes[Scheme.Name] and Scheme.Name or "Frost",
		Callback = function(V)
			if V and Themes[V] then
				Library:SetTheme(V)
				if Options.Skibidi_Accent then
					Options.Skibidi_Accent:SetValueRGB(Scheme.Accent)
				end
				Library:SavePrefs()
			end
		end,
	})
	Look:AddLabel("Accent"):AddColorPicker("Skibidi_Accent", {
		Default = Scheme.Accent,
		Title = "Accent",
		Callback = function(C)
			if C ~= Scheme.Accent then
				Library:SetAccent(C)
				Library:SavePrefs()
			end
		end,
	})
	Look:AddSlider("Skibidi_Glass", {
		Text = "Glass tint",
		Min = 0,
		Max = 100,
		Default = math.floor(Library.GlassOpacity * 100 + 0.5),
		Suffix = "%",
		Callback = function(V)
			Library:SetGlassOpacity(V / 100)
			Library:SavePrefs()
		end,
	})
	Look:AddDropdown("Skibidi_DPI", {
		Text = "Interface scale",
		Values = { "75%", "90%", "100%", "110%", "125%" },
		Default = tostring(math.floor(Library.DPIScale * 100 + 0.5)) .. "%",
		Callback = function(V)
			if V then
				Library:SetDPIScale(tonumber((V:gsub("%%", ""))))
				Library:SavePrefs()
			end
		end,
	})
	Look:AddToggle("Skibidi_ScreenClamp", {
		Text = "Keep on screen",
		Default = Window.ScreenClamp or false,
		Tooltip = "Stops the window being dragged or resized past the screen edges.",
		Callback = function(V)
			if Window.SetScreenClamp then
				Window:SetScreenClamp(V)
			end
		end,
	})
	Look:AddDropdown("Skibidi_NotifySide", {
		Text = "Notifications",
		Values = { "Left", "Right" },
		Default = Library.NotifySide,
		Callback = function(V)
			if V then
				Library:SetNotifySide(V)
				Library:SavePrefs()
			end
		end,
	})

	local Render = Interface:AddRightGroupbox({ Title = "Graphics", Icon = "sparkles", Description = "The frosted blur behind the window" })
	Render:AddToggle("Skibidi_Acrylic", {
		Text = "Acrylic blur",
		Default = Library.AcrylicEnabled,
		Tooltip = "Blurs the game world behind the window.",
		Callback = function(V)
			Library:SetAcrylic(V)
			Library:SavePrefs()
		end,
	})
	Render:AddToggle("Skibidi_Boost", {
		Text = "Boost graphics",
		Default = Library.BoostGraphics,
		Tooltip = "Raises graphics quality so the blur can render. Your own setting is put back on close.",
		Callback = function(V)
			Library:SetBoostGraphics(V)
			Library:SavePrefs()
		end,
	})
	Render:AddLabel("Blur needs graphics quality 8 or higher. With boost off, the glass gets a denser tint instead.", true)

	local Menu = Interface:AddRightGroupbox("Menu", "keyboard")
	local DefaultKey = typeof(Library.ToggleKeybind) == "EnumItem" and Library.ToggleKeybind.Name or "LeftControl"
	Menu:AddLabel("Toggle key"):AddKeyPicker("MenuKeybind", { Default = DefaultKey, Text = "Menu", NoUI = true, Modes = { "Toggle" } })
	Library.ToggleKeybind = Options.MenuKeybind
	Menu:AddToggle("Skibidi_ShowKeybinds", {
		Text = "Keybind list",
		Default = Library.ShowKeybinds,
		Callback = function(V)
			Library.ShowKeybinds = V
			Library:UpdateKeybindFrame()
		end,
	})
	Menu:AddButton({
		Text = "Unload",
		Risky = true,
		DoubleClick = true,
		Func = function()
			Library:Unload()
		end,
	})

	local Configs = Tab:AddSection("Configs", "Save and load every toggle, slider and bind")
	local Manage = Configs:AddLeftGroupbox("Configuration", "save")
	Manage:AddInput("Skibidi_ConfigName", { Text = "Config name", Placeholder = "my config" })
	Manage:AddDropdown("Skibidi_ConfigList", { Text = "Saved configs", Values = Library:ListConfigs(), AllowNull = true })
	local function Refresh()
		Options.Skibidi_ConfigList:SetValues(Library:ListConfigs())
	end
	local function Selected()
		return Options.Skibidi_ConfigList.Value
	end
	Manage:AddButton("Save", function()
		local Name = Options.Skibidi_ConfigName.Value
		local Ok, Err = Library:SaveConfig(Name)
		if Ok then
			Refresh()
			Library:Notify({ Title = "Saved", Description = "Config \"" .. Name .. "\" saved.", Type = "Success", Time = 3 })
		else
			Library:Notify({ Title = "Couldn't save", Description = tostring(Err), Type = "Error" })
		end
	end):AddButton("Load", function()
		local Name = Selected()
		if not Name then
			return Library:Notify({ Title = "Pick a config", Description = "Choose one from the list first.", Type = "Warning", Time = 3 })
		end
		local Ok, Err = Library:LoadConfig(Name)
		Library:Notify(Ok and { Title = "Loaded", Description = "Config \"" .. Name .. "\" loaded.", Type = "Success", Time = 3 }
			or { Title = "Couldn't load", Description = tostring(Err), Type = "Error" })
	end)
	Manage:AddButton("Overwrite", function()
		local Name = Selected()
		if Name then
			Library:SaveConfig(Name)
			Library:Notify({ Title = "Saved", Description = "Overwrote \"" .. Name .. "\".", Type = "Success", Time = 3 })
		end
	end):AddButton("Refresh", Refresh)
	Manage:AddButton({
		Text = "Delete",
		Risky = true,
		DoubleClick = true,
		Func = function()
			local Name = Selected()
			if Name and Library:DeleteConfig(Name) then
				Refresh()
				Library:Notify({ Title = "Deleted", Description = "Removed \"" .. Name .. "\".", Time = 3 })
			end
		end,
	})

	local Auto = Configs:AddRightGroupbox("Autoload", "rotate-ccw")
	local AutoLabel = Auto:AddLabel("Autoload: " .. (Library:GetAutoload() or "none"), true)
	Auto:AddButton("Set selected", function()
		local Name = Selected()
		if Name then
			Library:SetAutoload(Name)
			AutoLabel:SetText("Autoload: " .. Name)
		end
	end):AddButton("Clear", function()
		Library:SetAutoload("")
		AutoLabel:SetText("Autoload: none")
	end)

	Library:SetIgnoreIndexes({
		"Skibidi_Theme",
		"Skibidi_Accent",
		"Skibidi_Glass",
		"Skibidi_DPI",
		"Skibidi_NotifySide",
		"Skibidi_Acrylic",
		"Skibidi_Boost",
		"Skibidi_ShowKeybinds",
		"Skibidi_ConfigName",
		"Skibidi_ConfigList",
	})
	return Tab
end

-- ============================================================
-- UNLOAD
-- ============================================================
function Library:Unload()
	if Library.Unloaded then
		return
	end
	Library.Unloaded = true
	for _, Callback in Library.UnloadCallbacks do
		pcall(Callback)
	end
	Library:CloseAllPopups()
	for _, Connection in Library.Connections do
		pcall(function()
			Connection:Disconnect()
		end)
	end
	table.clear(ActiveSprings)
	table.clear(ActiveTweens)
	Acrylic.Destroy()
	Graphics.Restore()
	ScreenGui:Destroy()
	if getgenv().Skibidi == Library then
		getgenv().Skibidi = nil
	end
end

-- best effort: put graphics back if the player leaves without unloading
Library:Give(Players.PlayerRemoving:Connect(function(Player)
	if Player == LocalPlayer then
		Graphics.Restore()
	end
end))
pcall(function()
	game:BindToClose(Graphics.Restore)
end)

-- Window:AddSettingsTab() is attached to every window CreateWindow returns.
do
	local Create = Library.CreateWindow
	function Library:CreateWindow(Info)
		if Library.Demo and not Library.BuildingDemo then
			Library.Demo:Destroy()
		end
		Library.WindowsCreated += 1
		local Window = Create(self, Info)
		Window.AddSettingsTab = Library.Window_AddSettingsTab
		return Window
	end
end

-- ============================================================
-- DEMO
-- ============================================================
-- Run this file on its own and a tour of every element appears. Any script
-- that loads the library and calls CreateWindow soon after never sees it;
-- one that creates its window later replaces the demo. Opt out with
-- getgenv().SkibidiNoDemo = true before loading.
function Library:ShowDemo()
	if Library.Demo or Library.Unloaded then
		return
	end
	local Registries = { Toggles, Options, Library.Labels, Library.Buttons }
	local Before = {}
	for I, Registry in Registries do
		Before[I] = {}
		for Key in Registry do
			Before[I][Key] = true
		end
	end
	local Lists = { Library.KeyPickers, Library.DependencyBoxes }
	local Counts = { #Library.KeyPickers, #Library.DependencyBoxes }

	Library.BuildingDemo = true
	local Ok, Err = pcall(function()
		local Window = Library:CreateWindow({ Title = "Skibidi", Subtitle = "glass demo", Footer = "demo", Icon = "sparkles", ScreenClamp = true })

		-- elements ----------------------------------------------------------
		local Elements = Window:AddTab("Elements", "layout-grid", "One of every control")
		local Basics = Elements:AddSection("Controls", "Things you click, drag and type into")
		local Left = Basics:AddLeftGroupbox({ Title = "Inputs", Icon = "mouse-pointer-click", Description = "Hover any row for a tooltip" })
		Left:AddToggle("DemoToggle", { Text = "Toggle", Default = true, Tooltip = "A switch. Pass Style = \"Checkbox\" for a box instead" })
			:AddKeyPicker("DemoKey", { Default = "F", Mode = "Toggle", SyncToggleState = true, Text = "Toggle" })
			:AddColorPicker("DemoColor", { Default = Color3.fromRGB(120, 180, 255), Transparency = 0, Title = "Colour picker" })
		Left:AddCheckbox("DemoCheckbox", { Text = "Checkbox", Default = false, Tooltip = "Same as a toggle, drawn as a box" })
		Left:AddSlider("DemoSlider", { Text = "Slider", Min = 0, Max = 100, Default = 40, Rounding = 0, Suffix = "%", Tooltip = "Drag it: the fill glides after the cursor. Click the number to type one" })
		Left:AddInput("DemoInput", { Text = "Input", Placeholder = "Type something", Tooltip = "A text box" })
		Left:AddDropdown("DemoDropdown", { Text = "Dropdown", Values = { "Head", "Torso", "Arms", "Legs" }, Multi = true, Searchable = true, Default = { "Head" }, Tooltip = "Multi-select with search" })
		Left:AddButton({ Text = "Button", Tooltip = "Sends a notification", Func = function()
			Library:Notify({ Title = "Button pressed", Description = "Notifications stack and pause while hovered", Type = "Success", Time = 4 })
		end }):AddButton({ Text = "Dialog", Tooltip = "Opens a dialog", Func = function()
			Library:Dialog({
				Title = "A dialog",
				Description = "Asks the player to confirm something.",
				Buttons = { { Title = "Cancel" }, { Title = "Got it", Variant = "Primary" } },
			})
		end })

		local Right = Basics:AddRightGroupbox({ Title = "Display", Icon = "type", Description = "Things that show information" })
		Right:AddLabel("Label, with a colour picker attached"):AddColorPicker("DemoLabelColor", { Default = Color3.fromRGB(255, 140, 190) })
		Right:AddParagraph({ Title = "Paragraph", Content = "A title with wrapped body text, for longer explanations." })
		Right:AddDivider("Divider")
		Right:AddProgressBar("DemoProgress", { Text = "Progress bar", Value = 65 })
		Right:AddHeader("Dependency box")
		Right:AddToggle("DemoReveal", { Text = "Show hidden options", Default = false })
		local Depbox = Right:AddDependencyBox()
		Depbox:AddLabel("Only shown while the toggle above is on", true)
		Depbox:SetupDependencies({ { Toggles.DemoReveal, true } })

		local Layout = Elements:AddSection("Layout", "Ways to arrange groups")
		local Tabbox = Layout:AddLeftTabbox("Tabbox")
		Tabbox:AddTab("First"):AddLabel("A tabbox holds several pages in one group", true)
		Tabbox:AddTab("Second"):AddLabel("Switch pages with the bar above", true)
		local Media = Layout:AddRightGroupbox({ Title = "Media", Icon = "image" })
		Media:AddImage("DemoImage", { Image = "rbxthumb://type=AvatarHeadShot&id=" .. (LocalPlayer and LocalPlayer.UserId or 1) .. "&w=150&h=150", Height = 110, ScaleType = Enum.ScaleType.Fit })
		local Model = Instance.new("Model")
		local Part = Instance.new("Part")
		Part.Size = Vector3.new(4, 4, 4)
		Part.Color = Color3.fromRGB(120, 180, 255)
		Part.Material = Enum.Material.SmoothPlastic
		Part.Parent = Model
		Media:AddViewport("DemoViewport", { Object = Model, Clone = false, Height = 140 })
		Layout:AddFullGroupbox({ Title = "Full-width group", Icon = "rows-3" })
			:AddLabel("AddFullGroupbox spans both columns. Click a group's header to collapse it.", true)

		-- charts ------------------------------------------------------------
		local Charts = Window:AddTab("Charts", "chart-pie", "Bar, line, area, pie and donut")
		local Graphs = Charts:AddSection("Charts", "Hover a chart to read its values")
		Graphs:AddLeftGroupbox("Bar"):AddChart("DemoBar", { Type = "Bar", Title = "Bar chart", Labels = { "Mon", "Tue", "Wed", "Thu", "Fri" }, Data = { 4, 7, 5, 9, 6 } })
		local Live = Graphs:AddRightGroupbox("Line"):AddChart("DemoLine", {
			Type = "Line",
			Title = "Line chart (live)",
			Series = { { Name = "FPS", Values = { 58, 60, 57, 61, 60, 59 } }, { Name = "Ping", Values = { 40, 42, 39, 45, 41, 40 } } },
		})
		Graphs:AddLeftGroupbox("Area"):AddChart("DemoArea", { Type = "Area", Title = "Area chart", Data = { 2, 5, 3, 8, 6, 9, 7 } })
		Graphs:AddRightGroupbox("Pie"):AddChart("DemoPie", {
			Type = "Pie",
			Title = "Pie chart",
			Data = { { Label = "Wins", Value = 6 }, { Label = "Losses", Value = 3 }, { Label = "Draws", Value = 1 } },
		})
		Graphs:AddFullGroupbox("Donut"):AddChart("DemoDonut", { Type = "Donut", Title = "Donut chart", Data = { Scripts = 42, Textures = 28, Sounds = 18, Meshes = 12 } })
		task.spawn(function()
			while Library.Demo and not Library.Unloaded do
				task.wait(1.5)
				if Library.Demo and Options.DemoLine == Live then
					Live:Push({ math.random(55, 62), math.random(36, 48) })
				end
			end
		end)

		-- settings ----------------------------------------------------------
		Window:AddSettingsTab()

		Library:SetWatermark("Skibidi | demo")
		Library:SetWatermarkVisibility(true)
		task.delay(0.6, function()
			Library:Notify({ Title = "Skibidi demo", Description = "You ran the library on its own, so here's every element.", Time = 6 })
		end)

		Library.Demo = { Window = Window }
	end)
	Library.BuildingDemo = false
	if not Ok then
		warn("[Skibidi] demo failed: " .. tostring(Err))
	end
	if not Library.Demo then
		return
	end

	function Library.Demo:Destroy()
		Library.Demo = nil
		local Window = self.Window
		Library:CloseAllPopups()
		Library:SetWatermarkVisibility(false)
		for I, Registry in Registries do
			for Key in Registry do
				if not Before[I][Key] then
					Registry[Key] = nil
				end
			end
		end
		for I, List in Lists do
			for J = #List, Counts[I] + 1, -1 do
				table.remove(List, J)
			end
		end
		if Library.Window == Window then
			Library.Window = nil
		end
		if Window.Acrylic then
			Window.Acrylic:Destroy()
		end
		if Window.MobileButton then
			Window.MobileButton:Destroy()
		end
		Window.Root:Destroy()
		Library:UpdateKeybindFrame()
	end
end

task.delay(1, function()
	if Library.WindowsCreated == 0 and not Library.Unloaded and not getgenv().SkibidiNoDemo then
		Library:ShowDemo()
	end
end)

getgenv().Skibidi = Library
return Library
