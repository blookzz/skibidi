-- ============================================================
-- Skibidi UI  |  Self-contained loadstring library (skibidi edition)
-- Usage:
-- local Skibidi = loadstring(game:HttpGet("https://raw.githubusercontent.com/blookzz/skibidi/refs/heads/main/UILib.lua"))()
-- ============================================================

local Skibidi = {}
Skibidi.Brand   = "skibidi"
Skibidi.Name    = "Skibidi UI"
Skibidi.Version = "skibidi-2.2.0"

-- ============================================================
-- SERVICES
-- ============================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService      = game:GetService("HttpService")
local GuiService       = game:GetService("GuiService")
local TextService      = game:GetService("TextService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- THEME  (matches the gold/dark reference style by default)
-- Override any key before calling Create functions:
--   Skibidi.Theme.Accent = Color3.fromRGB(120, 80, 220)
-- ============================================================
local Theme = {
	-- Surfaces
	Bg0              = Color3.fromRGB(12,  12,  12),
	Bg1              = Color3.fromRGB(18,  18,  18),
	Bg2              = Color3.fromRGB(26,  26,  26),
	Bg3              = Color3.fromRGB(20,  19,  15),

	-- Accent  (gold default — swap to any Color3)
	Accent           = Color3.fromRGB(220, 160,  60),
	AccentDim        = Color3.fromRGB(100,  72,  28),
	AccentSec        = Color3.fromRGB(255, 200,  90),

	-- Toggle
	ToggleOff        = Color3.fromRGB(38,  34,  26),
	ToggleOn         = Color3.fromRGB(180, 120,  40),
	Knob             = Color3.fromRGB(255, 220, 140),

	-- Interaction
	Hover            = Color3.fromRGB(32,  30,  24),
	ToggleW          = 40,
	ToggleH          = 20,
	KnobSz           = 16,

	-- Text
	TextPrimary      = Color3.fromRGB(235, 215, 170),
	TextMuted        = Color3.fromRGB(100,  85,  60),
	ActiveTabText    = Color3.fromRGB(255, 255, 225),

	-- Input
	InputBg          = Color3.fromRGB(14,  13,  10),

	-- Sizing
	HeaderHeight     = 36,
	TabHeight        = 37,
	RowHeight        = 34,
	CornerRadius     = 10,
	CornerRadiusSmall = 8,
	CornerRadiusXs   = 6,
	Padding          = 12,
	PaddingSmall     = 6,
	FontBold         = Enum.Font.GothamBlack,
	FontMedium       = Enum.Font.GothamBold,
	FontRegular      = Enum.Font.Gotham,
	-- Gotham/GothamBold/GothamBlack only cover a limited (mostly Latin)
	-- glyph set. Arrows, chevrons, and checkmarks fall outside that set
	-- and render as tofu boxes. SourceSansBold has full coverage for
	-- these symbols, so it's used anywhere a glyph "icon" is drawn.
	FontIcon         = Enum.Font.SourceSansBold,
	TitleSize        = 14,
	BodySize         = 13,
	SmallSize        = 12,
	CaptionSize      = 11,

	-- ── Semantic colours (notifications, badges, status dots) ──
	Success          = Color3.fromRGB( 70, 200, 120),
	Warning          = Color3.fromRGB(240, 180,  60),
	Danger           = Color3.fromRGB(230,  75,  75),
	Info             = Color3.fromRGB( 80, 160, 240),

	-- ── Decoration switches ────────────────────────────────────
	-- Every one of these can be turned off individually if a game's
	-- performance budget is tight; nothing else in the library depends
	-- on them being enabled.
	Glow             = true,   -- soft accent bloom behind panels/controls
	GlowStrength     = 0.72,   -- transparency of the bloom (0 = solid, 1 = off)
	AnimatedBorder   = true,   -- slowly rotating gradient on panel strokes
	BorderSpeed      = 22,     -- degrees per second for the above
	Ripple           = true,   -- click ripple on buttons/rows
	Shine            = true,   -- diagonal light sweep across hovered buttons
	Grain            = true,   -- faint texture over large surfaces
	GrainStrength    = 0.965,  -- ImageTransparency of the texture layer
	Blur             = false,  -- global 3D blur while any panel is open
	Gloss            = true,   -- vertical light gradient over cards and rows
	LitEdge          = true,   -- outlines that catch light along their top edge
	StrokeAlpha      = 0.34,   -- resting transparency of those outlines
	Stagger          = true,   -- staggered pop-in as rows are built
	Elevation        = 0.38,   -- panel drop-shadow strength (0 = pitch black)
	Flow             = true,   -- travelling shimmer across progress fills
	FlowSpeed        = 0.55,   -- gradient offsets per second for the above

	-- Gradient endpoints used for accent fills (slider fill, active tab,
	-- progress bars). Left nil = derived automatically from Accent.
	AccentGrad1      = nil,
	AccentGrad2      = nil,

	-- Asset ids (swap if your executor blocks these)
	ShadowAsset      = "rbxassetid://6014261993",
	GlowAsset        = "rbxassetid://5028857084",
	GrainAsset       = "rbxassetid://9968344227",
	RippleAsset      = "rbxassetid://266543268",
	SpinnerAsset     = "rbxassetid://4965945816",
}
Skibidi.Theme = Theme

-- ============================================================
-- THEME PRESETS
-- Skibidi.SetTheme("neon")            -- swap the whole palette
-- Skibidi.SetTheme({ Accent = ... })  -- or merge in your own keys
--
-- Themes are read at *construction* time, so call this before you
-- create any panels. Existing widgets keep the palette they were
-- built with.
-- ============================================================
local Presets = {
	gold = {
		Bg0 = Color3.fromRGB(12,12,12), Bg1 = Color3.fromRGB(18,18,18),
		Bg2 = Color3.fromRGB(26,26,26), Bg3 = Color3.fromRGB(20,19,15),
		Accent = Color3.fromRGB(220,160,60), AccentDim = Color3.fromRGB(100,72,28),
		AccentSec = Color3.fromRGB(255,200,90), ToggleOff = Color3.fromRGB(38,34,26),
		ToggleOn = Color3.fromRGB(180,120,40), Knob = Color3.fromRGB(255,220,140),
		Hover = Color3.fromRGB(32,30,24), TextPrimary = Color3.fromRGB(235,215,170),
		TextMuted = Color3.fromRGB(100,85,60), ActiveTabText = Color3.fromRGB(255,255,225),
		InputBg = Color3.fromRGB(14,13,10),
	},
	midnight = {
		Bg0 = Color3.fromRGB(10,11,16), Bg1 = Color3.fromRGB(16,18,26),
		Bg2 = Color3.fromRGB(24,27,38), Bg3 = Color3.fromRGB(19,21,30),
		Accent = Color3.fromRGB(96,140,255), AccentDim = Color3.fromRGB(42,58,110),
		AccentSec = Color3.fromRGB(158,190,255), ToggleOff = Color3.fromRGB(32,36,50),
		ToggleOn = Color3.fromRGB(66,102,205), Knob = Color3.fromRGB(214,228,255),
		Hover = Color3.fromRGB(32,37,52), TextPrimary = Color3.fromRGB(214,222,240),
		TextMuted = Color3.fromRGB(104,116,145), ActiveTabText = Color3.fromRGB(255,255,255),
		InputBg = Color3.fromRGB(12,14,21),
	},
	neon = {
		Bg0 = Color3.fromRGB(8,10,12), Bg1 = Color3.fromRGB(13,17,20),
		Bg2 = Color3.fromRGB(20,26,30), Bg3 = Color3.fromRGB(15,20,23),
		Accent = Color3.fromRGB(60,240,200), AccentDim = Color3.fromRGB(22,96,84),
		AccentSec = Color3.fromRGB(150,255,232), ToggleOff = Color3.fromRGB(26,34,38),
		ToggleOn = Color3.fromRGB(38,170,144), Knob = Color3.fromRGB(198,255,242),
		Hover = Color3.fromRGB(26,36,40), TextPrimary = Color3.fromRGB(214,238,232),
		TextMuted = Color3.fromRGB(88,124,118), ActiveTabText = Color3.fromRGB(240,255,252),
		InputBg = Color3.fromRGB(10,14,16),
	},
	rose = {
		Bg0 = Color3.fromRGB(16,10,14), Bg1 = Color3.fromRGB(23,15,20),
		Bg2 = Color3.fromRGB(33,22,29), Bg3 = Color3.fromRGB(26,17,23),
		Accent = Color3.fromRGB(244,114,160), AccentDim = Color3.fromRGB(112,45,72),
		AccentSec = Color3.fromRGB(255,175,205), ToggleOff = Color3.fromRGB(44,29,38),
		ToggleOn = Color3.fromRGB(190,80,124), Knob = Color3.fromRGB(255,214,230),
		Hover = Color3.fromRGB(43,29,38), TextPrimary = Color3.fromRGB(240,220,230),
		TextMuted = Color3.fromRGB(130,96,112), ActiveTabText = Color3.fromRGB(255,240,246),
		InputBg = Color3.fromRGB(18,11,15),
	},
	emerald = {
		Bg0 = Color3.fromRGB(9,14,11), Bg1 = Color3.fromRGB(14,21,17),
		Bg2 = Color3.fromRGB(22,32,26), Bg3 = Color3.fromRGB(17,25,20),
		Accent = Color3.fromRGB(72,205,120), AccentDim = Color3.fromRGB(30,92,54),
		AccentSec = Color3.fromRGB(146,240,180), ToggleOff = Color3.fromRGB(28,40,32),
		ToggleOn = Color3.fromRGB(50,150,90), Knob = Color3.fromRGB(200,250,220),
		Hover = Color3.fromRGB(28,42,33), TextPrimary = Color3.fromRGB(216,236,224),
		TextMuted = Color3.fromRGB(96,126,108), ActiveTabText = Color3.fromRGB(240,255,246),
		InputBg = Color3.fromRGB(11,17,13),
	},
	crimson = {
		Bg0 = Color3.fromRGB(15,9,9), Bg1 = Color3.fromRGB(22,14,14),
		Bg2 = Color3.fromRGB(32,21,21), Bg3 = Color3.fromRGB(25,16,16),
		Accent = Color3.fromRGB(232,76,76), AccentDim = Color3.fromRGB(110,34,34),
		AccentSec = Color3.fromRGB(255,146,146), ToggleOff = Color3.fromRGB(44,27,27),
		ToggleOn = Color3.fromRGB(180,55,55), Knob = Color3.fromRGB(255,208,208),
		Hover = Color3.fromRGB(43,27,27), TextPrimary = Color3.fromRGB(238,218,218),
		TextMuted = Color3.fromRGB(128,92,92), ActiveTabText = Color3.fromRGB(255,240,240),
		InputBg = Color3.fromRGB(17,10,10),
	},
	violet = {
		Bg0 = Color3.fromRGB(13,10,18), Bg1 = Color3.fromRGB(19,15,27),
		Bg2 = Color3.fromRGB(28,22,40), Bg3 = Color3.fromRGB(22,17,31),
		Accent = Color3.fromRGB(160,110,250), AccentDim = Color3.fromRGB(70,44,124),
		AccentSec = Color3.fromRGB(203,172,255), ToggleOff = Color3.fromRGB(38,30,53),
		ToggleOn = Color3.fromRGB(122,80,200), Knob = Color3.fromRGB(226,210,255),
		Hover = Color3.fromRGB(38,30,54), TextPrimary = Color3.fromRGB(226,218,242),
		TextMuted = Color3.fromRGB(116,104,142), ActiveTabText = Color3.fromRGB(248,244,255),
		InputBg = Color3.fromRGB(15,11,21),
	},
	mono = {
		Bg0 = Color3.fromRGB(10,10,10), Bg1 = Color3.fromRGB(17,17,17),
		Bg2 = Color3.fromRGB(26,26,26), Bg3 = Color3.fromRGB(21,21,21),
		Accent = Color3.fromRGB(225,225,225), AccentDim = Color3.fromRGB(80,80,80),
		AccentSec = Color3.fromRGB(255,255,255), ToggleOff = Color3.fromRGB(38,38,38),
		ToggleOn = Color3.fromRGB(150,150,150), Knob = Color3.fromRGB(255,255,255),
		Hover = Color3.fromRGB(32,32,32), TextPrimary = Color3.fromRGB(228,228,228),
		TextMuted = Color3.fromRGB(115,115,115), ActiveTabText = Color3.fromRGB(255,255,255),
		InputBg = Color3.fromRGB(12,12,12),
	},
}
Skibidi.Presets = Presets

function Skibidi.SetTheme(nameOrTable)
	local src = nameOrTable
	if type(src) == "string" then src = Presets[src:lower()] end
	if type(src) ~= "table" then return Theme end
	for k, v in pairs(src) do Theme[k] = v end
	-- A palette swap invalidates any hand-tuned gradient endpoints.
	if type(nameOrTable) == "string" then
		Theme.AccentGrad1, Theme.AccentGrad2 = nil, nil
	end
	return Theme
end

function Skibidi.GetThemeNames()
	local out = {}
	for k in pairs(Presets) do out[#out+1] = k end
	table.sort(out)
	return out
end

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================
local TweenFast   = TweenInfo.new(0.14, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TweenMed    = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TweenSpring = TweenInfo.new(0.28, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local TweenSnap   = TweenInfo.new(0.09, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TweenSoft   = TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TweenPop    = TweenInfo.new(0.44, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

local function MakeCorner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = radius or UDim.new(0, Theme.CornerRadiusSmall)
	c.Parent = parent
	return c
end

local function MakeStroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color            = color or Theme.AccentDim
	s.Thickness        = thickness or 1
	s.ApplyStrokeMode  = Enum.ApplyStrokeMode.Border
	s.Parent           = parent
	return s
end

local function MakePadding(parent, l, r, t, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft   = UDim.new(0, l or 0)
	p.PaddingRight  = UDim.new(0, r or 0)
	p.PaddingTop    = UDim.new(0, t or 0)
	p.PaddingBottom = UDim.new(0, b or 0)
	p.Parent        = parent
	return p
end

-- Multiplicative vertical gradient: full colour at the top fading a touch
-- darker at the bottom. Because it multiplies the parent's (possibly
-- tweened) BackgroundColor3 it adds depth to any surface without
-- introducing new palette colours or fighting hover/state tweens.
local function MakeSheen(parent, strength)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	local k = 1 - (strength or 0.12)
	g.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(k, k, k))
	g.Parent = parent
	return g
end

local function MakeListLayout(parent, dir, pad, ha, va)
	local l = Instance.new("UIListLayout")
	l.FillDirection       = dir or Enum.FillDirection.Vertical
	l.Padding             = UDim.new(0, pad or 6)
	l.SortOrder           = Enum.SortOrder.LayoutOrder
	l.HorizontalAlignment = ha or Enum.HorizontalAlignment.Left
	l.VerticalAlignment   = va or Enum.VerticalAlignment.Top
	l.Parent              = parent
	return l
end

-- ============================================================
-- VISUAL TOOLKIT
-- Small, composable decorators. Every one of them is a no-op when its
-- corresponding Theme switch is off, so a caller can dial the whole
-- library back to flat surfaces without touching component code.
-- ============================================================

-- ── Colour maths ────────────────────────────────────────────
local function Lighten(c, amt)
	amt = amt or 0.12
	return Color3.new(
		math.clamp(c.R + amt, 0, 1),
		math.clamp(c.G + amt, 0, 1),
		math.clamp(c.B + amt, 0, 1))
end

local function Darken(c, amt)
	amt = amt or 0.12
	return Color3.new(
		math.clamp(c.R - amt, 0, 1),
		math.clamp(c.G - amt, 0, 1),
		math.clamp(c.B - amt, 0, 1))
end

local function Mix(a, b, t)
	t = math.clamp(t or 0.5, 0, 1)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t)
end

-- Shifts a colour's hue while preserving its saturation/value, so a
-- two-stop accent gradient stays in the same family instead of drifting
-- toward grey the way a plain lighten/darken pair does.
local function HueShift(c, deg)
	local h, sat, v = c:ToHSV()
	h = (h + (deg or 0) / 360) % 1
	return Color3.fromHSV(h, sat, v)
end

local function ToHex(c)
	return string.format("%02X%02X%02X",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5))
end
Skibidi.Lighten, Skibidi.Darken, Skibidi.Mix, Skibidi.HueShift = Lighten, Darken, Mix, HueShift

-- The two endpoints every accent fill uses. Explicit Theme overrides win;
-- otherwise a subtle hue rotation either side of Accent gives the fill a
-- gradient that still reads as "the accent colour".
local function AccentPair(accent)
	accent = accent or Theme.Accent
	local a = Theme.AccentGrad1 or Lighten(HueShift(accent,  14), 0.06)
	local b = Theme.AccentGrad2 or Darken (HueShift(accent, -14), 0.06)
	return a, b
end
Skibidi.AccentPair = AccentPair

-- ── Shared animation driver ─────────────────────────────────
-- One Heartbeat connection drives every rotating gradient in the whole
-- library. Registering N animated borders costs one table entry each,
-- not N connections, and the connection tears itself down when the last
-- animated object dies.
local _spinners     = {}   -- [UIGradient] = degreesPerSecond  (rotates)
local _flows        = {}   -- [UIGradient] = offsetsPerSecond   (scrolls)
local _spinnerCount = 0
local _spinnerConn  = nil

local function _spinStep(dt)
	for grad, speed in pairs(_spinners) do
		if grad.Parent then
			grad.Rotation = (grad.Rotation + speed * dt) % 360
		else
			_spinners[grad] = nil
			_spinnerCount = _spinnerCount - 1
		end
	end
	-- Offset wraps through [-1, 1] so a gradient wider than its parent
	-- reads as a highlight travelling across the fill, then repeating.
	for grad, speed in pairs(_flows) do
		if grad.Parent then
			local x = grad.Offset.X + speed * dt
			if x > 1 then x = x - 2 end
			grad.Offset = Vector2.new(x, 0)
		else
			_flows[grad] = nil
			_spinnerCount = _spinnerCount - 1
		end
	end
	if _spinnerCount <= 0 and _spinnerConn then
		_spinnerConn:Disconnect()
		_spinnerConn = nil
	end
end

local function _startDriver()
	if not _spinnerConn then
		_spinnerConn = RunService.Heartbeat:Connect(_spinStep)
	end
end

local function RegisterSpin(grad, speed)
	if _spinners[grad] then return end
	_spinners[grad] = speed or Theme.BorderSpeed or 20
	_spinnerCount   = _spinnerCount + 1
	_startDriver()
	grad.Destroying:Connect(function()
		if _spinners[grad] then
			_spinners[grad] = nil
			_spinnerCount = _spinnerCount - 1
		end
	end)
end

-- Same registry, different axis: used by the shimmer that crawls across
-- progress fills and active tab pills.
local function RegisterFlow(grad, speed)
	if _flows[grad] then return end
	_flows[grad]  = speed or Theme.FlowSpeed or 0.5
	_spinnerCount = _spinnerCount + 1
	_startDriver()
	grad.Destroying:Connect(function()
		if _flows[grad] then
			_flows[grad] = nil
			_spinnerCount = _spinnerCount - 1
		end
	end)
end

-- ── Gradient fills ──────────────────────────────────────────
-- A two-stop accent gradient laid over a solid fill. The parent keeps its
-- BackgroundColor3 as the base, so state tweens (hover, disabled) still
-- work — the gradient only ever multiplies what's underneath.
local function MakeAccentGradient(parent, accent, rotation)
	local a, b = AccentPair(accent)
	local g = Instance.new("UIGradient")
	g.Color    = ColorSequence.new(a, b)
	g.Rotation = rotation or 25
	g.Parent   = parent
	return g
end

-- Three-stop "glass" gradient: bright at the top edge, neutral through
-- the middle, slightly dark at the bottom. Multiplies the parent colour.
local function MakeGlass(parent, strength, rotation)
	local k  = strength or 0.10
	local hi = 1 + k * 0.55
	local lo = 1 - k
	local g = Instance.new("UIGradient")
	g.Rotation = rotation or 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.new(math.min(hi,1), math.min(hi,1), math.min(hi,1))),
		ColorSequenceKeypoint.new(0.45, Color3.new(1, 1, 1)),
		ColorSequenceKeypoint.new(1.00, Color3.new(lo, lo, lo)),
	})
	g.Parent = parent
	return g
end

-- ── Lit edges ───────────────────────────────────────────────
-- The outline every card, row and card-like surface wears.
--
-- A flat 1px outline in one colour is what makes a dark UI look like
-- boxes drawn on paper. A real edge catches light: bright where it faces
-- the light source, nearly gone where it faces away. That's all this is —
-- the stroke colour is lifted a touch, and a vertical gradient rides it
-- so the top edge reads as a highlight and the bottom edge falls away.
--
-- Crucially a UIStroke is *not* a layout item, so this works on surfaces
-- driven by UIListLayout/AutomaticSize (which is most of them) where an
-- extra decorative Frame would shove the content around.
local function EdgeRest(base)
	return Lighten(base or Theme.AccentDim, 0.16)
end

local function MakeEdge(parent, color, thickness, alpha)
	local s = MakeStroke(parent, EdgeRest(color), thickness or 1)
	if not Theme.LitEdge then return s end
	s.Transparency = alpha or Theme.StrokeAlpha or 0.34
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.new(1.00, 1.00, 1.00)),
		ColorSequenceKeypoint.new(0.48, Color3.new(0.66, 0.66, 0.66)),
		ColorSequenceKeypoint.new(1.00, Color3.new(0.40, 0.40, 0.40)),
	})
	g.Parent = s
	return s
end

-- Theme-gated glass wash, for the many call sites that want depth only
-- when decoration is switched on.
local function MakeGloss(parent, strength, rotation)
	if not Theme.Gloss then return nil end
	return MakeGlass(parent, strength, rotation)
end

-- An accent fill that reads as lit metal rather than a flat swatch: a
-- two-stop accent gradient with a bright band travelling through it.
-- Used for slider fills, progress fills and the active tab pill.
local function MakeAccentFill(parent, accent, flow)
	local a, b = AccentPair(accent)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Lighten(a, 0.10)),
		ColorSequenceKeypoint.new(0.55, b),
		ColorSequenceKeypoint.new(1.00, Darken(b, 0.10)),
	})
	g.Parent = parent

	if not (flow and Theme.Flow) then return g end

	-- The shimmer is a second, wider gradient on a transparent overlay —
	-- keeping it off `g` means the fill's colour and its highlight can be
	-- animated independently.
	local Sheen = Instance.new("Frame")
	Sheen.Name                   = "SkibidiFlow"
	Sheen.Size                   = UDim2.new(1, 0, 1, 0)
	Sheen.BackgroundColor3       = Color3.new(1, 1, 1)
	Sheen.BorderSizePixel        = 0
	Sheen.ZIndex                 = (parent.ZIndex or 1) + 1
	Sheen.Parent                 = parent
	local c = parent:FindFirstChildOfClass("UICorner")
	MakeCorner(Sheen, c and c.CornerRadius or UDim.new(1, 0))

	local fg = Instance.new("UIGradient")
	fg.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.50, 0.72),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1.00, 1),
	})
	fg.Parent = Sheen
	RegisterFlow(fg, Theme.FlowSpeed)
	return g, Sheen
end

-- ── Strokes ─────────────────────────────────────────────────
-- A stroke whose colour sweeps around the border. The gradient rides the
-- shared driver above, so an entire screen of panels shares one update.
local function MakeAnimatedStroke(parent, accent, thickness, speed)
	local s = MakeStroke(parent, accent or Theme.Accent, thickness or 1.2)
	if not Theme.AnimatedBorder then return s, nil end
	local a, b = AccentPair(accent)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Darken(b, 0.20)),
		ColorSequenceKeypoint.new(0.28, a),
		ColorSequenceKeypoint.new(0.55, Darken(b, 0.24)),
		ColorSequenceKeypoint.new(0.80, a),
		ColorSequenceKeypoint.new(1.00, Darken(b, 0.20)),
	})
	g.Parent = s
	RegisterSpin(g, speed or Theme.BorderSpeed)
	return s, g
end

-- ── Bloom / glow ────────────────────────────────────────────
-- A tinted, blurred copy of the target's rounded-rect silhouette drawn
-- behind it. Lives as a sibling (not a child) so it is not clipped by a
-- ClipsDescendants parent, and mirrors Position/Size every frame the
-- target changes — which covers dragging, tweening and minimising.
local function MakeGlow(target, color, spread, transparency)
	if not Theme.Glow then return nil end
	spread = spread or 22

	local G = Instance.new("ImageLabel")
	G.Name                   = "SkibidiGlow"
	G.BackgroundTransparency = 1
	G.Image                  = Theme.ShadowAsset
	G.ImageColor3            = color or Theme.Accent
	G.ImageTransparency      = transparency or Theme.GlowStrength
	G.ScaleType              = Enum.ScaleType.Slice
	G.SliceCenter            = Rect.new(49, 49, 450, 450)
	G.ZIndex                 = math.max((target.ZIndex or 1) - 1, 0)
	G.Parent                 = target.Parent

	local function sync()
		local pos, sz = target.Position, target.Size
		G.Position = UDim2.new(pos.X.Scale, pos.X.Offset - spread,
		                       pos.Y.Scale, pos.Y.Offset - spread)
		G.Size     = UDim2.new(sz.X.Scale, sz.X.Offset + spread * 2,
		                       sz.Y.Scale, sz.Y.Offset + spread * 2)
	end
	target:GetPropertyChangedSignal("Position"):Connect(sync)
	target:GetPropertyChangedSignal("Size"):Connect(sync)
	target:GetPropertyChangedSignal("Visible"):Connect(function()
		G.Visible = target.Visible
	end)
	target.Destroying:Connect(function() if G.Parent then G:Destroy() end end)
	sync()
	return G
end

-- Inner bloom: a halo that follows the target's own silhouette.
--
-- This used to stretch a single 9-slice shadow image behind the control.
-- That image's corners are a fixed rounded rectangle, so behind a
-- pill-shaped toggle track or a circular knob it showed square shoulders
-- poking out of the shape it was meant to hug. It also sat *over* the
-- control: under ZIndexBehavior.Sibling a child always draws above its
-- parent, so the bloom washed across the fill it was framing.
--
-- The halo is drawn as a few concentric outlines instead. Each ring copies
-- the target's own UICorner radius (grown by its own inset), so a pill
-- glows as a pill and a knob glows as a circle; and because a ring is
-- hollow, none of it covers the control.
--
-- Returns a handle rather than an Instance, since the effect is no longer
-- one object:  { SetAlpha(alpha, tweenInfo), SetColor(color3) }
-- alpha 1 = fully hidden, matching the ImageTransparency it replaces.
--
-- Three rings is the trade: the old glow was one instance, this is three
-- frames plus their corner and stroke, on every control that blooms. Four
-- read marginally smoother and did not justify another 25% of instances.
local GLOW_RINGS = 3

-- Every caller's `spread` is scaled by this before the rings are laid out.
-- Halving the spread halves both the halo's total width and each ring's
-- stroke, so the combined thickness drops 50% while the rings keep the
-- same overlap ratio — thinning the strokes alone would open gaps between
-- them and split the falloff back into three visible bands.
local GLOW_THICKNESS_SCALE = 0.5

local function MakeInnerGlow(target, color, spread, transparency)
	if not Theme.Glow then return nil end
	spread = (spread or 10) * GLOW_THICKNESS_SCALE

	local corner = target:FindFirstChildOfClass("UICorner")
	local radius = corner and corner.CornerRadius or UDim.new(0, 0)
	-- A scale radius means pill/circle: it stays correct at any size, so
	-- the rings inherit it as-is. A fixed radius has to grow with each
	-- ring or the halo's corners go square while the control's stay round.
	local isPill = radius.Scale > 0

	local step  = spread / GLOW_RINGS
	local rings = {}

	for i = 1, GLOW_RINGS do
		local inset = (i - 1) * step

		local R = Instance.new("Frame")
		R.Name                   = "SkibidiGlowRing"
		R.AnchorPoint            = Vector2.new(0.5, 0.5)
		R.Position               = UDim2.new(0.5, 0, 0.5, 0)
		R.Size                   = UDim2.new(1, inset * 2, 1, inset * 2)
		R.BackgroundTransparency = 1
		R.BorderSizePixel        = 0
		R.ZIndex                 = math.max((target.ZIndex or 1) - 1, 0)
		R.Parent                 = target

		local c = Instance.new("UICorner")
		c.CornerRadius = isPill and radius or UDim.new(0, radius.Offset + inset)
		c.Parent       = R

		local st = Instance.new("UIStroke")
		-- Slightly thicker than the gap so neighbouring rings overlap and
		-- read as one falloff rather than three visible bands.
		st.Thickness    = step * 1.2
		st.Color        = color or Theme.Accent
		st.LineJoinMode = Enum.LineJoinMode.Round
		st.Parent       = R

		rings[i] = { Stroke = st, Falloff = (i - 1) / GLOW_RINGS }
	end

	local handle = {}

	function handle.SetAlpha(alpha, tweenInfo)
		for _, r in ipairs(rings) do
			local a = math.clamp(alpha + (1 - alpha) * r.Falloff, 0, 1)
			if tweenInfo then
				TweenService:Create(r.Stroke, tweenInfo, { Transparency = a }):Play()
			else
				r.Stroke.Transparency = a
			end
		end
	end

	function handle.SetColor(c)
		for _, r in ipairs(rings) do r.Stroke.Color = c end
	end

	handle.SetAlpha(transparency or Theme.GlowStrength or 0.5)
	return handle
end

-- ── Texture ─────────────────────────────────────────────────
-- Barely-there tiled noise. At the default strength it is invisible as
-- "grain" and only shows up as the absence of flat, banded fills on large
-- surfaces.
local function MakeGrain(parent)
	if not Theme.Grain then return nil end
	local N = Instance.new("ImageLabel")
	N.Name                   = "SkibidiGrain"
	N.Size                   = UDim2.new(1, 0, 1, 0)
	N.BackgroundTransparency = 1
	N.Image                  = Theme.GrainAsset
	N.ImageTransparency      = Theme.GrainStrength
	N.ScaleType              = Enum.ScaleType.Tile
	N.TileSize               = UDim2.new(0, 128, 0, 128)
	N.ZIndex                 = 0
	N.Parent                 = parent
	return N
end

-- ── Ripple ──────────────────────────────────────────────────
-- Material-style circle expanding from the click point. Needs a clipping
-- host, so it creates its own rather than requiring the caller's frame to
-- clip (which would cut off strokes and glows).
local function MakeRipple(button, color, radius)
	if not Theme.Ripple then return end

	local Host = Instance.new("Frame")
	Host.Name                   = "SkibidiRippleHost"
	Host.Size                   = UDim2.new(1, 0, 1, 0)
	Host.BackgroundTransparency = 1
	Host.BorderSizePixel        = 0
	Host.ClipsDescendants       = true
	Host.ZIndex                 = (button.ZIndex or 1)
	Host.Parent                 = button
	MakeCorner(Host, UDim.new(0, radius or Theme.CornerRadiusSmall))

	button.MouseButton1Down:Connect(function(x, y)
		local abs = button.AbsolutePosition
		local sz  = button.AbsoluteSize
		local lx, ly = x - abs.X, y - abs.Y

		-- Diameter must reach the farthest corner from the click point,
		-- otherwise the ripple visibly stops short on off-centre clicks.
		local far = math.max(
			math.sqrt(lx ^ 2 + ly ^ 2),
			math.sqrt((sz.X - lx) ^ 2 + ly ^ 2),
			math.sqrt(lx ^ 2 + (sz.Y - ly) ^ 2),
			math.sqrt((sz.X - lx) ^ 2 + (sz.Y - ly) ^ 2))
		local d = far * 2

		local C = Instance.new("ImageLabel")
		C.BackgroundTransparency = 1
		C.Image                  = Theme.RippleAsset
		C.ImageColor3            = color or Theme.Accent
		C.ImageTransparency      = 0.72
		C.AnchorPoint            = Vector2.new(0.5, 0.5)
		C.Position               = UDim2.new(0, lx, 0, ly)
		C.Size                   = UDim2.new(0, 0, 0, 0)
		C.ZIndex                 = Host.ZIndex
		C.Parent                 = Host

		local info = TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		TweenService:Create(C, info, { Size = UDim2.new(0, d, 0, d), ImageTransparency = 1 }):Play()
		task.delay(0.5, function() if C.Parent then C:Destroy() end end)
	end)
end

-- ── Shine sweep ─────────────────────────────────────────────
-- A slanted highlight that crosses the control once per hover. Returns a
-- `play` function so callers can also fire it on click or on state change.
-- `hostParent` is where the sweep layer is parented. It defaults to the
-- target, but a TextButton draws its own label, and under
-- ZIndexBehavior.Sibling every descendant renders above its parent — so a
-- layer inside the button sweeps across the text and the row's decorations
-- instead of behind them. Passing the target's own parent instead puts the
-- sweep on a lower layer, where a lighting effect belongs.
--
-- The band is a UIGradient travelling across a frame that exactly covers
-- the control, not a narrow rotated bar sliding through a clipping host.
-- ClipsDescendants is a screen-axis-aligned scissor that ignores Rotation,
-- so the old slanted bar was never actually clipped: it spilled past the
-- button's edges and swept over whatever sat beside it in the row/stack.
-- A gradient can't leave the frame it paints, so the sweep is now bounded
-- by construction, and a UICorner keeps it off the rounded corners.
local function MakeShine(target, radius, hostParent)
	if not Theme.Shine then return function() end end

	local Bar = Instance.new("Frame")
	Bar.Name                   = "SkibidiShine"
	Bar.Size                   = UDim2.new(1, 0, 1, 0)
	Bar.BackgroundColor3       = Color3.new(1, 1, 1)
	Bar.BorderSizePixel        = 0
	Bar.ZIndex                 = math.max((target.ZIndex or 1) - 1, 0)
	Bar.Parent                 = hostParent or target
	MakeCorner(Bar, UDim.new(0, radius or Theme.CornerRadiusSmall))

	-- Rotating the gradient (rather than the frame) is what slants the
	-- band. Feathered on both sides so it reads as light, not as a white
	-- rectangle, and fully transparent at either end so the frame is
	-- invisible while the sweep is parked off-edge.
	local grad = Instance.new("UIGradient")
	grad.Rotation     = 18
	grad.Offset       = Vector2.new(-1, 0)
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1),
		NumberSequenceKeypoint.new(0.42, 1),
		NumberSequenceKeypoint.new(0.50, 0.80),
		NumberSequenceKeypoint.new(0.58, 1),
		NumberSequenceKeypoint.new(1.00, 1),
	})
	grad.Parent = Bar

	local playing = false
	local function play()
		if playing or not Bar.Parent then return end
		playing = true
		grad.Offset = Vector2.new(-1, 0)
		local t = TweenService:Create(grad,
			TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ Offset = Vector2.new(1, 0) })
		t.Completed:Connect(function() playing = false end)
		t:Play()
	end

	target.MouseEnter:Connect(play)
	return play
end

-- ── Spinner ─────────────────────────────────────────────────
-- Indeterminate loading ring. Rotates on the shared driver via a dummy
-- gradient would be wrong here (we need the *image* to spin), so it owns a
-- tween loop that stops the moment it's hidden or destroyed.
local function MakeSpinner(parent, size, color)
	local S = Instance.new("ImageLabel")
	S.Name                   = "SkibidiSpinner"
	S.AnchorPoint            = Vector2.new(0.5, 0.5)
	S.Position               = UDim2.new(0.5, 0, 0.5, 0)
	S.Size                   = UDim2.new(0, size or 18, 0, size or 18)
	S.BackgroundTransparency = 1
	S.Image                  = Theme.SpinnerAsset
	S.ImageColor3            = color or Theme.Accent
	S.Parent                 = parent

	task.spawn(function()
		while S.Parent do
			if S.Visible then
				S.Rotation = (S.Rotation + 9) % 360
			end
			RunService.Heartbeat:Wait()
		end
	end)
	return S
end

-- ── Entrance ────────────────────────────────────────────────
-- Rows settle into place instead of appearing all at once.
--
-- The stagger index is read from how many siblings already exist rather
-- than being passed in, so a tab built top-to-bottom in one pass cascades
-- for free and no call site has to keep a counter. The delay is capped so
-- a fifty-row tab doesn't take two seconds to finish arriving.
--
-- UIScale is deliberate: a UIListLayout measures a child's *Size*, not its
-- rendered scale, so this can never disturb the layout it animates inside.
local function PlayEntrance(inst, index)
	if not Theme.Stagger then return end
	if not index then
		local n = 0
		local parent = inst.Parent
		if parent then
			for _, c in ipairs(parent:GetChildren()) do
				if c ~= inst and c:IsA("GuiObject") then n = n + 1 end
			end
		end
		index = n
	end
	local delaySec = math.min(index * 0.028, 0.30)

	local scale = Instance.new("UIScale")
	scale.Scale  = 0.965
	scale.Parent = inst

	-- Fading the outline in alongside the scale is what turns a bare pop
	-- into something that reads as "settling": the edge resolves last.
	local stroke = inst:FindFirstChildOfClass("UIStroke")
	local restAlpha = stroke and stroke.Transparency or 0
	if stroke then stroke.Transparency = 1 end

	task.delay(delaySec, function()
		if not inst.Parent then return end
		TweenService:Create(scale, TweenPop, { Scale = 1 }):Play()
		if stroke and stroke.Parent then
			TweenService:Create(stroke, TweenSoft, { Transparency = restAlpha }):Play()
		end
	end)
end

-- Some rows (Section headers, Dropdown/ColorPicker heads) are clickable
-- TextButtons that span edge-to-edge inside a rounded card, with no
-- corner/inset of their own. Tinting them directly on hover causes two
-- problems: the very first hover flashes because BackgroundColor3 was
-- never initialized (it defaults to white, so the tween starts from
-- white instead of the theme colour), and the opaque fill paints
-- straight over the card's rounded corner + outline stroke since it
-- touches the same edge pixels.
--
-- This creates a small inset, independently-rounded highlight layer
-- inside Head instead of tinting Head itself, so hovering can never
-- cover the parent card's corners/stroke, and pre-seeds its colour so
-- there's nothing to flash from.
local function MakeHoverFill(Head, inset, radius)
	local Fill = Instance.new("Frame")
	Fill.Size                   = UDim2.new(1, -inset * 2, 1, -inset * 2)
	Fill.Position               = UDim2.new(0, inset, 0, inset)
	Fill.BackgroundColor3       = Theme.Bg2
	Fill.BackgroundTransparency = 1
	Fill.BorderSizePixel        = 0
	Fill.ZIndex                 = 0   -- render behind all card content
	Fill.Parent                 = Head
	MakeCorner(Fill, UDim.new(0, radius or 6))

	-- A short accent tick that grows out of the left edge on hover. It
	-- lives inside Fill so it inherits the same inset and can never touch
	-- the parent card's corners either.
	local Tick = Instance.new("Frame")
	Tick.Size             = UDim2.new(0, 2, 0, 0)
	Tick.Position         = UDim2.new(0, 0, 0.5, 0)
	Tick.AnchorPoint      = Vector2.new(0, 0.5)
	Tick.BackgroundColor3 = Theme.Accent
	Tick.BorderSizePixel  = 0
	Tick.ZIndex           = 1
	Tick.Parent           = Fill
	MakeCorner(Tick, UDim.new(1, 0))

	Head.MouseEnter:Connect(function()
		TweenService:Create(Fill, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
		Fill.BackgroundTransparency = 0
		TweenService:Create(Tick, TweenSpring, { Size = UDim2.new(0, 2, 0.55, 0) }):Play()
	end)
	Head.MouseLeave:Connect(function()
		TweenService:Create(Fill, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
		TweenService:Create(Tick, TweenFast, { Size = UDim2.new(0, 2, 0, 0) }):Play()
		task.delay(0.14, function() Fill.BackgroundTransparency = 1 end)
	end)

	return Fill
end

-- Connects a service-level signal (UserInputService etc.) and disconnects
-- it automatically when `owner` is destroyed. Without this, every slider,
-- color picker, keybind and panel drag handler would keep its global
-- connection alive forever after its GUI is gone — a slow leak for any
-- script that creates panels repeatedly.
local function ConnectScoped(owner, signal, fn)
	local conn = signal:Connect(fn)
	owner.Destroying:Connect(function()
		conn:Disconnect()
	end)
	return conn
end

-- ── Overlay registry ────────────────────────────────────────
-- At most one expanding overlay (Dropdown list / ColorPicker panel) is
-- open at a time: opening one closes the previous, and clicking anywhere
-- outside the open overlay's card closes it. The outside-click watcher
-- only exists while an overlay is open, so idle cost is zero.
local _openOverlay  = nil   -- { Card = GuiObject, Close = fn }
local _overlayWatch = nil

local function OverlayClosed(card)
	if _openOverlay and _openOverlay.Card == card then
		_openOverlay = nil
		if _overlayWatch then
			_overlayWatch:Disconnect()
			_overlayWatch = nil
		end
	end
end

local function OverlayOpened(card, closeFn)
	if _openOverlay and _openOverlay.Card ~= card then
		_openOverlay.Close()
	end
	_openOverlay = { Card = card, Close = closeFn }
	if not _overlayWatch then
		_overlayWatch = UserInputService.InputBegan:Connect(function(inp)
			if inp.UserInputType ~= Enum.UserInputType.MouseButton1
			and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			local o = _openOverlay
			if not o or not o.Card.Parent then return end
			local p, s = o.Card.AbsolutePosition, o.Card.AbsoluteSize
			local x, y = inp.Position.X, inp.Position.Y
			if x < p.X or x > p.X + s.X or y < p.Y or y > p.Y + s.Y then
				o.Close()
			end
		end)
	end
end

-- ── Config flags ────────────────────────────────────────────
-- Components created with Options.Flag = "someKey" register themselves
-- here so SaveConfig/LoadConfig can persist and restore their values.
-- Purely opt-in: components without a Flag are never registered.
local Flags = {}
Skibidi.Flags = Flags

-- ── Panel registry ──────────────────────────────────────────
-- Every ScreenGui the library creates is tracked here so
-- Skibidi.Unload() can tear the whole UI down in one call.
local _allGuis = {}

-- ── Tooltip ─────────────────────────────────────────────────
-- One shared tooltip for the whole library. Components opt in with
-- Options.Tooltip = "text"; it follows the mouse, clamps to the screen
-- and hides itself when the hovered element dies.
local _tooltipSg, _tooltipFrame, _tooltipLbl

local function _ensureTooltip()
	if _tooltipSg and _tooltipSg.Parent then return end
	_tooltipSg = Instance.new("ScreenGui")
	_tooltipSg.Name           = "SkibidiTooltip"
	_tooltipSg.ResetOnSpawn   = false
	_tooltipSg.DisplayOrder   = 2000
	_tooltipSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_tooltipSg.Parent         = PlayerGui

	_tooltipFrame = Instance.new("Frame")
	_tooltipFrame.AutomaticSize          = Enum.AutomaticSize.XY
	_tooltipFrame.BackgroundColor3       = Theme.Bg0
	_tooltipFrame.BackgroundTransparency = 0.05
	_tooltipFrame.BorderSizePixel        = 0
	_tooltipFrame.Visible                = false
	_tooltipFrame.Parent                 = _tooltipSg
	MakeCorner(_tooltipFrame, UDim.new(0, Theme.CornerRadiusXs))
	MakeEdge(_tooltipFrame, Theme.AccentDim, 1)
	MakeGloss(_tooltipFrame, 0.10)
	MakePadding(_tooltipFrame, 8, 8, 5, 5)

	_tooltipLbl = Instance.new("TextLabel")
	_tooltipLbl.AutomaticSize          = Enum.AutomaticSize.XY
	_tooltipLbl.BackgroundTransparency = 1
	_tooltipLbl.Font                   = Theme.FontRegular
	_tooltipLbl.TextSize               = Theme.SmallSize
	_tooltipLbl.TextColor3             = Theme.TextPrimary
	_tooltipLbl.Parent                 = _tooltipFrame
end

local function _positionTooltip()
	local loc   = UserInputService:GetMouseLocation()
	local inset = GuiService:GetGuiInset()
	local x, y  = loc.X - inset.X + 16, loc.Y - inset.Y + 14
	local screen, sz = _tooltipSg.AbsoluteSize, _tooltipFrame.AbsoluteSize
	x = math.max(0, math.min(x, screen.X - sz.X - 4))
	y = math.max(0, math.min(y, screen.Y - sz.Y - 4))
	_tooltipFrame.Position = UDim2.fromOffset(x, y)
end

local function AttachTooltip(target, text)
	if not text or text == "" then return end
	target.MouseEnter:Connect(function()
		_ensureTooltip()
		_tooltipLbl.Text      = text
		_tooltipFrame.Visible = true
		_positionTooltip()
	end)
	target.MouseMoved:Connect(function()
		if _tooltipFrame and _tooltipFrame.Visible then _positionTooltip() end
	end)
	target.MouseLeave:Connect(function()
		if _tooltipFrame then _tooltipFrame.Visible = false end
	end)
	target.Destroying:Connect(function()
		if _tooltipFrame then _tooltipFrame.Visible = false end
	end)
end

-- Default parent used by CreatePanel when Options.Parent is omitted.
-- Overridable in one place via Skibidi.Init({ Parent = someInstance }).
local DefaultParent = PlayerGui

-- ============================================================
-- FetchCachedImage(url, fileName) → asset string | nil
-- Downloads a web image once, caches it in the executor workspace
-- via writefile, and returns a getcustomasset path for it. Later
-- runs skip the download and read the cached file. Returns nil
-- (never throws) when the executor lacks file/asset APIs or the
-- request fails, so callers can keep a rbxassetid fallback.
-- ============================================================
local function FetchCachedImage(url, fileName)
	if type(getcustomasset) ~= "function" then return nil end

	local cached = type(isfile) == "function" and isfile(fileName)
	if not cached then
		if type(writefile) ~= "function" then return nil end

		local body
		local req = (type(request) == "function" and request)
			or (type(http_request) == "function" and http_request)
			or (type(syn) == "table" and type(syn.request) == "function" and syn.request)
		if req then
			local ok, res = pcall(req, { Url = url, Method = "GET" })
			if ok and type(res) == "table" and res.Success ~= false and type(res.Body) == "string" then
				body = res.Body
			end
		end
		if not body then
			local ok, res = pcall(game.HttpGet, game, url)
			if ok and type(res) == "string" then body = res end
		end
		if not body or #body == 0 then return nil end

		local okWrite = pcall(writefile, fileName, body)
		if not okWrite then return nil end
	end

	local okAsset, asset = pcall(getcustomasset, fileName)
	if okAsset and type(asset) == "string" and #asset > 0 then
		return asset
	end
	return nil
end

-- ============================================================
-- ICONS
-- Lucide glyphs, served from the same asset set WindUI ships with
-- (github.com/Footagesus/Icons). Every component that takes an
-- `Icon` option accepts any of:
--   "house"                lucide name   (see lucide.dev/icons)
--   "lucide:house"         WindUI-style pack prefix
--   "rbxassetid://123"     raw asset id
--   123                    numeric asset id
-- A few hundred common names are embedded below so the usual icons
-- need no HTTP request. Any other lucide name is fetched from the
-- full ~1700-glyph map the first time it is asked for; the label is
-- created immediately and fills in when the download lands.
--
-- Public API:
--   Skibidi.ResolveIcon(spec)          -> asset id string | nil (sync)
--   Skibidi.PreloadIcons([pack], [cb]) -> warm the full map up front
--   Skibidi.AddIcons([pack], {name = id, ...})
--   Skibidi.CreateIcon(parent, spec, size, color) -> { Label, Set(spec) }
--   Skibidi.SetIcon(imageLabel, spec)
-- ============================================================
local ICON_PACK_URLS = {
	lucide = "https://raw.githubusercontent.com/Footagesus/Icons/refs/heads/main/lucide/dist/Icons.lua",
}
local DEFAULT_ICON_PACK = "lucide"

-- Asset ids are stored without the "rbxassetid://" prefix to keep the
-- table compact; lookupIcon puts it back.
local IconPacks = {
	lucide = {
		["house"] = "98755624629571", ["settings"] = "80758916183665", ["settings-2"] = "135684703553372",
		["cog"] = "116544501716299", ["sliders-horizontal"] = "85538382643347",
		["sliders-vertical"] = "101190569086853", ["user"] = "81589895647169", ["users"] = "115398113982385",
		["user-round"] = "136485052187963", ["users-round"] = "103005444008339", ["user-plus"] = "118514469915884",
		["user-minus"] = "126976941957511", ["user-check"] = "81775205032725", ["user-x"] = "139748155894754",
		["search"] = "121018724060431", ["x"] = "110786993356448", ["check"] = "93898873302694",
		["plus"] = "111774323017047", ["minus"] = "118026365011536", ["menu"] = "77021539815611",
		["info"] = "124560466474914", ["circle-alert"] = "83898160590116", ["triangle-alert"] = "125920361880643",
		["octagon-alert"] = "140438367956051", ["circle-check"] = "85262178816537",
		["circle-check-big"] = "93202927221730", ["circle-x"] = "76821953846248",
		["circle-plus"] = "113157136350384", ["circle-minus"] = "133556159576809",
		["circle-slash"] = "125206439913049", ["ban"] = "90767043015246",
		["circle-question-mark"] = "97516698664325", ["badge-check"] = "76078495178149",
		["badge-alert"] = "101829200081951", ["badge-info"] = "131995373201472", ["bell"] = "97392696311902",
		["bell-ring"] = "94612128913941", ["bell-off"] = "78560046118930", ["star"] = "136141469398409",
		["heart"] = "116559368303288", ["heart-pulse"] = "129352925579546", ["zap"] = "130551565616516",
		["zap-off"] = "81385483183652", ["eye"] = "100033680381365", ["eye-off"] = "135928786788378",
		["eye-closed"] = "111063268625789", ["lock"] = "134724289526879", ["lock-open"] = "93597915325122",
		["lock-keyhole"] = "78672912777756", ["key"] = "96510194465420", ["key-round"] = "83619031955390",
		["shield"] = "110987169760162", ["shield-check"] = "87354736164608", ["shield-alert"] = "114995877719925",
		["shield-off"] = "133426959132690", ["shield-ban"] = "108765041044649", ["sword"] = "124448418211665",
		["swords"] = "81872698913435", ["crosshair"] = "134242818164054", ["target"] = "87563802520297",
		["gamepad"] = "121607283959010", ["gamepad-2"] = "92483947987410", ["joystick"] = "99416790224739",
		["play"] = "135609604299893", ["pause"] = "74873705394436", ["square"] = "86304921356806",
		["skip-forward"] = "124844823753990", ["skip-back"] = "70466132711334",
		["circle-play"] = "120408917249739", ["circle-pause"] = "139337739700879",
		["circle-stop"] = "87400503942659", ["square-check"] = "134682053539509", ["square-x"] = "125136183850190",
		["refresh-cw"] = "138133190015277", ["refresh-ccw"] = "117913330389477", ["rotate-cw"] = "84183336178654",
		["rotate-ccw"] = "110116685948665", ["repeat"] = "121886242955173", ["shuffle"] = "132382786975101",
		["rewind"] = "95205297521988", ["fast-forward"] = "121615540167909", ["download"] = "134814648082393",
		["upload"] = "138212042425501", ["save"] = "126116963775616", ["folder"] = "80846616596607",
		["folder-open"] = "76018996254888", ["file"] = "74748492079329", ["file-text"] = "90496405707281",
		["file-code"] = "130978036895504", ["files"] = "102806336233202", ["code"] = "107380207681249",
		["code-xml"] = "130150477351734", ["terminal"] = "106783148545356", ["cpu"] = "77549309870247",
		["database"] = "126791525623846", ["server"] = "92188766517878", ["hard-drive"] = "88183305858463",
		["globe"] = "114238209622913", ["earth"] = "76231597751076", ["wifi"] = "104669375183960",
		["wifi-off"] = "74113634330106", ["link"] = "131607023382430", ["link-2"] = "86072351557466",
		["unlink"] = "139835795227752", ["external-link"] = "129331830773832", ["copy"] = "78979572434545",
		["clipboard"] = "89601995828423", ["clipboard-check"] = "92649798577170", ["scissors"] = "118665510911274",
		["trash"] = "106723740584310", ["trash-2"] = "109843431391323", ["pencil"] = "137986121120732",
		["pen"] = "72037878096321", ["pen-line"] = "109108135755303", ["eraser"] = "133957773112410",
		["wrench"] = "112148279212860", ["hammer"] = "83545120140895", ["bug"] = "83626408925438",
		["flask-conical"] = "128406680901165", ["beaker"] = "80902539995520", ["sparkles"] = "138635884129147",
		["sparkle"] = "111044800239623", ["wand"] = "114580617777835", ["wand-sparkles"] = "82546429942392",
		["flame"] = "98218034436456", ["snowflake"] = "101235206534566", ["sun"] = "110150589884127",
		["moon"] = "83380517901735", ["cloud"] = "121226497050352", ["cloud-off"] = "131907154501444",
		["cloud-download"] = "121435581993566", ["cloud-upload"] = "93307473217005", ["map"] = "95107167260947",
		["map-pin"] = "84279202219901", ["map-pinned"] = "103963788475034", ["compass"] = "115123411028382",
		["navigation"] = "79308213542922", ["locate"] = "84467676590391", ["locate-fixed"] = "137367361548433",
		["move"] = "116138709011735", ["move-horizontal"] = "88513523439149", ["move-vertical"] = "86234730730899",
		["arrow-up"] = "89282378235317", ["arrow-down"] = "98764963621439", ["arrow-left"] = "102531941843733",
		["arrow-right"] = "113692007244654", ["arrow-up-right"] = "129280608535523",
		["arrow-left-right"] = "131324733048447", ["arrow-up-down"] = "81019887641527",
		["chevron-up"] = "122444883127455", ["chevron-down"] = "134243273101015",
		["chevron-left"] = "73780377692148", ["chevron-right"] = "92473583511724",
		["chevrons-up"] = "100467452364672", ["chevrons-down"] = "100524612205956",
		["chevrons-left"] = "82617201744347", ["chevrons-right"] = "139121276490483", ["list"] = "113179976918783",
		["list-checks"] = "99809353635593", ["layout-grid"] = "81344910161871",
		["layout-dashboard"] = "139929981863901", ["layout-list"] = "87462136296578",
		["layers"] = "81973586053257", ["box"] = "101768155599700", ["package"] = "97261141732706",
		["gift"] = "109855212076373", ["coins"] = "116510979641930", ["dollar-sign"] = "127320961224019",
		["wallet"] = "132331555762628", ["credit-card"] = "99163352872346", ["shopping-cart"] = "128420521375441",
		["shopping-bag"] = "71885477293226", ["tag"] = "129104970103940", ["tags"] = "107179263080798",
		["bookmark"] = "121093149326239", ["flag"] = "78183383236196", ["clock"] = "121808839832144",
		["timer"] = "85473888890506", ["timer-reset"] = "110052125369932", ["hourglass"] = "86160434939203",
		["calendar"] = "114792700814035", ["calendar-days"] = "99072017568595",
		["alarm-clock"] = "126259032907535", ["watch"] = "130544621618405", ["activity"] = "94212016861936",
		["chart-bar"] = "105389816384108", ["chart-line"] = "101833156055618", ["chart-pie"] = "113412261630136",
		["trending-up"] = "81819858538839", ["trending-down"] = "139309232226438", ["gauge"] = "110273524101447",
		["power"] = "96479131758775", ["power-off"] = "118768311012214", ["log-in"] = "103768533135201",
		["log-out"] = "84895399304975", ["rocket"] = "87412317685854", ["ghost"] = "113822048130017",
		["skull"] = "137726256442333", ["bot"] = "80451686744860", ["brain"] = "92424107303177",
		["message-square"] = "83881670383280", ["message-circle"] = "127255077587058",
		["messages-square"] = "97532166733358", ["send"] = "127751956873796", ["mail"] = "103945161245599",
		["phone"] = "128804946640049", ["camera"] = "79950339943067", ["image"] = "112751259236831",
		["images"] = "79350649395557", ["video"] = "107587444636945", ["film"] = "120978945609706",
		["music"] = "113343203848535", ["volume"] = "103236289817396", ["volume-1"] = "98514588731639",
		["volume-2"] = "89344380902620", ["volume-x"] = "139252359189540", ["mic"] = "89640799126523",
		["mic-off"] = "82123034444822", ["monitor"] = "72664649203050", ["smartphone"] = "96623008834511",
		["tv"] = "135687724791776", ["keyboard"] = "121474456068237", ["mouse"] = "73096068864710",
		["mouse-pointer"] = "72322454962935", ["palette"] = "86350350950064", ["paintbrush"] = "125572663700289",
		["brush"] = "127035535799640", ["droplet"] = "100597455015098", ["droplets"] = "140111846025180",
		["pipette"] = "133167932934404", ["scaling"] = "122360365318466", ["maximize"] = "76045941763188",
		["maximize-2"] = "73085922906397", ["minimize"] = "121304296213645", ["minimize-2"] = "116269596042539",
		["expand"] = "137492887754537", ["shrink"] = "90953687918880", ["fullscreen"] = "77793665526178",
		["funnel"] = "108829540827529", ["toggle-left"] = "85887872573050", ["toggle-right"] = "90411952142550",
		["circle"] = "130359823580534", ["circle-dot"] = "82947033619201", ["dot"] = "137321056643916",
		["grip"] = "109058783556768", ["grip-vertical"] = "137183678565296",
		["grip-horizontal"] = "136255899715930", ["ellipsis"] = "140019550645825",
		["ellipsis-vertical"] = "117978708573781", ["lightbulb"] = "103871245626488", ["book"] = "125383279695672",
		["book-open"] = "129845326810392", ["scroll"] = "74072101474951", ["history"] = "123980022019922",
		["undo"] = "111258459077271", ["redo"] = "116150342119054", ["undo-2"] = "113885292059932",
		["redo-2"] = "70451039017914", ["car"] = "121065933462582", ["car-front"] = "87380942739063",
		["plane"] = "126985561580989", ["footprints"] = "139192589041315", ["person-standing"] = "125020872044147",
		["bike"] = "102930322246035", ["ship"] = "83995100553930", ["anchor"] = "92181172123618",
		["trophy"] = "131545003268773", ["crown"] = "127843403295538", ["medal"] = "79016002264450",
		["award"] = "132740088158419", ["gem"] = "112904952151156", ["diamond"] = "105846996304890",
		["dice-5"] = "72768312430593", ["puzzle"] = "136837798892463", ["infinity"] = "98083086936965",
		["percent"] = "130155041032013", ["hash"] = "82890331678520", ["at-sign"] = "79059152889146",
		["type"] = "133543553793564", ["bold"] = "116141470019166", ["italic"] = "96220378864282",
		["languages"] = "90816903776498", ["radio"] = "85611589536956", ["rss"] = "131789058984793",
		["share"] = "87340985053299", ["share-2"] = "71210767962065", ["github"] = "120349554354380",
		["youtube"] = "123663668456341", ["twitch"] = "71383308134888", ["twitter"] = "88791703276842",
		["instagram"] = "119864798614855", ["facebook"] = "72098528632192", ["cat"] = "124252153404931",
		["dog"] = "71920105558570", ["bird"] = "132284145117371", ["fish"] = "124360663785796",
		["rabbit"] = "98580518804206", ["bone"] = "111242153474115", ["leaf"] = "119951075637174",
		["trees"] = "121203841375919", ["tree-pine"] = "124662547202594", ["mountain"] = "73269957566415",
		["waves"] = "96340135183647", ["wind"] = "114551690399915", ["umbrella"] = "127502210274589",
		["thermometer"] = "106546011492311", ["battery"] = "70765800346189",
		["battery-charging"] = "80139357470047", ["battery-low"] = "139659256984314", ["plug"] = "99782373064495",
		["plug-zap"] = "74506269884055", ["bluetooth"] = "90506573139443", ["signal"] = "78424889355261",
		["radar"] = "138528222906635", ["satellite"] = "134967053164645", ["scan"] = "123104789658180",
		["qr-code"] = "105329945723350", ["fingerprint"] = "112173305232811", ["id-card"] = "75354294622640",
		["contact"] = "75868297719012", ["handshake"] = "78442115255814", ["thumbs-up"] = "111137070767020",
		["thumbs-down"] = "87794009914015", ["smile"] = "105880397565283", ["frown"] = "124407301067982",
		["meh"] = "132197867028557", ["laugh"] = "104491311361166", ["angry"] = "74237056000103",
		["party-popper"] = "111626795712193", ["cake"] = "103131590503275", ["pizza"] = "126964453193501",
		["coffee"] = "106864403231093", ["beer"] = "116404978807744", ["utensils"] = "139952569804235",
		["apple"] = "104349242902442", ["pill"] = "73280534813448", ["syringe"] = "123891270479254",
		["bandage"] = "129660129590770", ["cross"] = "101833377863588", ["biohazard"] = "95956532900432",
		["radiation"] = "104499586848433", ["bomb"] = "139223800924636", ["axe"] = "132405197863294",
		["pickaxe"] = "105888023317688", ["shovel"] = "102465000512056", ["magnet"] = "135162361226972",
		["highlighter"] = "77411555641113", ["ruler"] = "81432445547423", ["paint-bucket"] = "124275586663284",
		["shapes"] = "129989433311409", ["triangle"] = "126330486745540", ["hexagon"] = "127592089339199",
		["pentagon"] = "79184802179890", ["octagon"] = "120803515514852", ["component"] = "110027788875080",
		["blocks"] = "72212693357737", ["door-open"] = "91306356501736", ["door-closed"] = "136249099949073",
		["bed"] = "97726529032925", ["lamp"] = "110730830653382", ["speaker"] = "96227183003618",
		["headphones"] = "118833729589183", ["clapperboard"] = "132660667070200", ["airplay"] = "115020759309179",
		["cast"] = "98202245922071", ["printer"] = "76080649734247", ["usb"] = "117230058949613",
		["binary"] = "91751953950088", ["braces"] = "117761094704041", ["brackets"] = "74368995728099",
		["regex"] = "100727200791841", ["variable"] = "104743088438151", ["sigma"] = "126884244870899",
		["pi"] = "74936036243146", ["calculator"] = "74915716529646", ["table"] = "109109148250737",
		["kanban"] = "125934100055431", ["workflow"] = "99186544029189", ["git-branch"] = "90490195516649",
		["git-merge"] = "131833355158059", ["git-pull-request"] = "138463010991471",
		["network"] = "127410729922644", ["route"] = "89968303228953", ["waypoints"] = "102450133666017",
		["milestone"] = "101618292325920", ["inbox"] = "112591360302868", ["archive"] = "122180020814574",
		["truck"] = "86662707764771", ["bus"] = "133798469717463", ["fuel"] = "106447647274511",
		["construction"] = "106539489968173", ["traffic-cone"] = "74110220470369", ["siren"] = "134210267818039",
		["loader"] = "78408734580845", ["loader-circle"] = "116535712789945", ["wallet-cards"] = "129728715308337",
		["gavel"] = "78952298198456", ["scale"] = "108203682317477", ["text-cursor"] = "115984654447300",
		["text-cursor-input"] = "107551944047171", ["tally-5"] = "88031817475886",
		["badge-percent"] = "121359224294885", ["sunrise"] = "134705665494098", ["sunset"] = "75904872203588",
		["cloud-rain"] = "105547081967408", ["cloud-snow"] = "72307126270226",
		["cloud-lightning"] = "133517088924849", ["cloud-sun"] = "86114208148727",
		["cloud-moon"] = "71938114737914", ["zoom-in"] = "127956924984803", ["zoom-out"] = "108334162607319",
		["focus"] = "87493973153317", ["aperture"] = "83396154449972", ["camera-off"] = "81057636835256",
		["image-plus"] = "70391970623917", ["image-off"] = "81934811700938", ["file-plus"] = "78881710800060",
		["file-minus"] = "111014798459222", ["file-check"] = "82604001452455", ["file-x"] = "107333775515154",
		["file-search"] = "97780235974933", ["file-lock"] = "72170228691242", ["file-cog"] = "101385347151368",
		["folder-plus"] = "91865663406119", ["folder-minus"] = "85648718999010",
		["folder-lock"] = "119201572260567", ["folder-cog"] = "85299519462846", ["folder-tree"] = "85577554337861",
		["folders"] = "110351216219061", ["import"] = "116545008906029", ["step-back"] = "108672750005121",
		["step-forward"] = "126131872136145", ["disc"] = "101908120120777", ["podcast"] = "109577075549215",
		["antenna"] = "99628923540956", ["square-plus"] = "114713264461873", ["square-minus"] = "116764432015770",
		["square-play"] = "108186325238481", ["square-pause"] = "86608552787615",
		["square-stop"] = "80018708472943", ["octagon-x"] = "90498161006311", ["check-check"] = "95183312173858",
	},
}
-- Names lucide has renamed over the years (WindUI scripts still use the
-- old ones), plus a few plain-English spellings.
local ICON_ALIASES = {
	["aimbot"] = "crosshair", ["alert"] = "circle-alert", ["alert-circle"] = "circle-alert",
	["alert-octagon"] = "octagon-alert", ["alert-triangle"] = "triangle-alert",
	["badge-help"] = "badge-question-mark", ["bar-chart"] = "chart-bar", ["bin"] = "trash-2",
	["bulb"] = "lightbulb", ["check-circle"] = "circle-check", ["check-square"] = "square-check",
	["circle-help"] = "circle-question-mark", ["close"] = "x", ["cogwheel"] = "settings", ["color"] = "palette",
	["colour"] = "palette", ["combat"] = "swords", ["config"] = "save", ["configs"] = "save",
	["credits"] = "info", ["crosshairs"] = "crosshair", ["discord"] = "message-circle",
	["download-cloud"] = "cloud-download", ["edit"] = "pencil", ["edit-2"] = "pen", ["edit-3"] = "pen-line",
	["enter"] = "log-in", ["error"] = "circle-x", ["esp"] = "eye", ["exit"] = "log-out", ["filter"] = "funnel",
	["fire"] = "flame", ["fly"] = "plane", ["function-square"] = "square-function", ["gauge-circle"] = "gauge",
	["gear"] = "settings", ["git-commit"] = "git-commit-horizontal", ["globe-2"] = "earth",
	["grid"] = "grid-3x3", ["help"] = "circle-question-mark", ["help-circle"] = "circle-question-mark",
	["home"] = "house", ["lightning"] = "zap", ["line-chart"] = "chart-line", ["loader-2"] = "loader-circle",
	["location"] = "map-pin", ["magnifier"] = "search", ["minus-circle"] = "circle-minus",
	["minus-square"] = "square-minus", ["misc"] = "layout-grid", ["more-horizontal"] = "ellipsis",
	["more-vertical"] = "ellipsis-vertical", ["mute"] = "volume-x", ["paint"] = "palette",
	["pause-circle"] = "circle-pause", ["people"] = "users", ["person"] = "user", ["photo"] = "image",
	["picture"] = "image", ["pie-chart"] = "chart-pie", ["play-circle"] = "circle-play", ["player"] = "user",
	["plus-circle"] = "circle-plus", ["plus-square"] = "square-plus", ["question"] = "circle-question-mark",
	["refresh"] = "refresh-cw", ["reload"] = "rotate-cw", ["remove"] = "trash-2",
	["shield-question"] = "shield-question-mark", ["sliders"] = "sliders-horizontal", ["sound"] = "volume-2",
	["speed"] = "gauge", ["stop-circle"] = "circle-stop", ["success"] = "circle-check",
	["teleport"] = "map-pinned", ["text"] = "type", ["tick"] = "check", ["tool"] = "wrench",
	["unlock"] = "lock-open", ["upload-cloud"] = "cloud-upload", ["user-2"] = "user-round",
	["users-2"] = "users-round", ["visuals"] = "eye", ["wand-2"] = "wand-sparkles",
	["warning"] = "triangle-alert", ["world"] = "globe", ["x-circle"] = "circle-x", ["x-square"] = "square-x",
}

local iconPackState   = {}   -- pack -> "loading" | "loaded" | "failed"
local iconPackWaiters = {}   -- pack -> { fn(ok), ... }
local iconWarned      = {}   -- spec -> true once an "unknown icon" warning fired
Skibidi.Icons = IconPacks

local function httpGet(url)
	local ok, res = pcall(function() return game:HttpGet(url) end)
	if ok and type(res) == "string" and #res > 0 then return res end
	ok, res = pcall(function() return HttpService:GetAsync(url) end)
	if ok and type(res) == "string" and #res > 0 then return res end
	return nil
end

local function isRawAsset(spec)
	return type(spec) == "string"
	   and (string.find(spec, "^rbxasset") or string.find(spec, "^http") or string.match(spec, "^%d+$")) ~= nil
end

local function parseIconSpec(spec)
	local pack, name = string.match(spec, "^([%w_%-]+):(.+)$")
	if pack and (ICON_PACK_URLS[pack] or IconPacks[pack]) then
		return pack, name
	end
	return DEFAULT_ICON_PACK, spec
end

local function lookupIcon(pack, name)
	local set = IconPacks[pack]
	if not set then return nil end
	name = string.lower(name)
	local id = set[name] or (ICON_ALIASES[name] and set[ICON_ALIASES[name]])
	if id == nil then return nil end
	if type(id) == "number" then id = tostring(id) end
	if not string.find(id, "://") then id = "rbxassetid://" .. id end
	return id
end

-- Synchronous lookup. nil means "not known *yet*" for a lucide name that
-- is outside the embedded subset and hasn't been downloaded.
function Skibidi.ResolveIcon(spec)
	if spec == nil or spec == "" then return nil end
	if type(spec) == "number" then return "rbxassetid://" .. tostring(spec) end
	if type(spec) ~= "string" then return nil end
	if string.match(spec, "^%d+$") then return "rbxassetid://" .. spec end
	if isRawAsset(spec) then return spec end
	return lookupIcon(parseIconSpec(spec))
end

local function loadIconPack(pack, onDone)
	local state = iconPackState[pack]
	if state == "loaded" or state == "failed" then
		if onDone then task.spawn(onDone, state == "loaded") end
		return
	end
	if onDone then
		iconPackWaiters[pack] = iconPackWaiters[pack] or {}
		table.insert(iconPackWaiters[pack], onDone)
	end
	if state == "loading" then return end
	iconPackState[pack] = "loading"
	task.spawn(function()
		local ok  = false
		local url = ICON_PACK_URLS[pack]
		local src = url and httpGet(url)
		if src then
			local okc, chunk = pcall(loadstring, src)
			local okr, data  = false, nil
			if okc and type(chunk) == "function" then okr, data = pcall(chunk) end
			if okr and type(data) == "table" then
				local set = IconPacks[pack] or {}
				for k, v in pairs(data) do
					if type(k) == "string" and set[k] == nil then
						if type(v) == "number" then v = tostring(v) end
						if type(v) == "table" and v.Image then v = v.Image end
						if type(v) == "string" then set[k] = v end
					end
				end
				IconPacks[pack] = set
				ok = true
			end
		end
		iconPackState[pack] = ok and "loaded" or "failed"
		if not ok then
			warn(("[Skibidi] icon pack %q could not be downloaded; only the embedded icons are available"):format(pack))
		end
		local waiters = iconPackWaiters[pack]
		iconPackWaiters[pack] = nil
		for _, fn in ipairs(waiters or {}) do task.spawn(fn, ok) end
	end)
end

-- Downloads the full map now (e.g. at script start) so no icon ever
-- shows up a beat late. `cb(ok)` is optional.
function Skibidi.PreloadIcons(pack, cb)
	if type(pack) == "function" then pack, cb = nil, pack end
	loadIconPack(pack or DEFAULT_ICON_PACK, cb)
end

-- Register custom names, WindUI AddIcons style: { name = id, ... }.
-- The id may be a number, "rbxassetid://…", or a WindUI spritesheet
-- entry (only its Image is used).
function Skibidi.AddIcons(pack, tbl)
	if type(pack) == "table" and tbl == nil then pack, tbl = DEFAULT_ICON_PACK, pack end
	if type(tbl) ~= "table" then return end
	IconPacks[pack] = IconPacks[pack] or {}
	for k, v in pairs(tbl) do
		if type(v) == "number" then v = tostring(v) end
		if type(v) == "table" and v.Image then v = v.Image end
		if type(k) == "string" and type(v) == "string" then
			IconPacks[pack][string.lower(k)] = v
		end
	end
end

-- Points an ImageLabel at an icon spec. Unknown lucide names trigger a
-- download of the full map and the label is filled in once it lands
-- (unless it was re-pointed somewhere else in the meantime).
local function SetIconImage(label, spec)
	if not label then return false end
	local key = (spec ~= nil and spec ~= "") and tostring(spec) or nil
	label:SetAttribute("IconSpec", key)
	local id = Skibidi.ResolveIcon(spec)
	if id then
		label.Image = id
		return true
	end
	label.Image = ""
	if type(spec) ~= "string" or spec == "" then return false end
	local pack = parseIconSpec(spec)
	local function unknown()
		if not iconWarned[spec] then
			iconWarned[spec] = true
			warn(("[Skibidi] unknown icon %q"):format(spec))
		end
	end
	if iconPackState[pack] == "loaded" or iconPackState[pack] == "failed" then
		if iconPackState[pack] == "loaded" then unknown() end
		return false
	end
	loadIconPack(pack, function(ok)
		if label:GetAttribute("IconSpec") ~= key then return end
		local late = Skibidi.ResolveIcon(spec)
		if late then
			label.Image = late
		elseif ok then
			unknown()
		end
	end)
	return false
end
Skibidi.SetIcon = SetIconImage

local function MakeIcon(parent, spec, size, color, zindex)
	local L = Instance.new("ImageLabel")
	L.Name                   = "SkibidiIcon"
	L.Size                   = UDim2.new(0, size or 14, 0, size or 14)
	L.BackgroundTransparency = 1
	L.BorderSizePixel        = 0
	L.ImageColor3            = color or Theme.TextPrimary
	L.ScaleType              = Enum.ScaleType.Fit
	L.ZIndex                 = zindex or (parent and parent.ZIndex) or 1
	SetIconImage(L, spec)
	L.Parent                 = parent
	return L
end

-- Standalone icon for callers building their own layouts.
function Skibidi.CreateIcon(Parent, spec, size, color)
	if type(spec) == "table" then
		local o = spec
		spec, size, color = o.Icon, o.Size or size, o.Color or color
	end
	local L = MakeIcon(Parent, spec, size or 16, color)
	return {
		Frame = L,
		Label = L,
		Set   = function(sp) return SetIconImage(L, sp) end,
	}
end

-- ── Layout helpers ─────────────────────────────────────────
-- Three ways to put an icon next to text, depending on how the text
-- is laid out. Each returns the ImageLabel.

-- Left-aligned label positioned by offset inside a row: the icon takes
-- the label's slot and the label slides right by (size + gap).
local function PrefixIcon(Lbl, spec, size, color, gap)
	size = size or 14
	gap  = gap  or 6
	local shift = size + gap
	local L = MakeIcon(Lbl.Parent, spec, size, color or Lbl.TextColor3, Lbl.ZIndex)
	local px, py, sy = Lbl.Position.X, Lbl.Position.Y, Lbl.Size.Y
	L.AnchorPoint = Vector2.new(0, 0.5)
	L.Position    = UDim2.new(px.Scale, px.Offset,
	                          py.Scale + sy.Scale / 2, py.Offset + sy.Offset / 2)
	Lbl.Position  = Lbl.Position + UDim2.new(0, shift, 0, 0)
	Lbl.Size      = Lbl.Size     - UDim2.new(0, shift, 0, 0)
	return L
end

-- Left-aligned text on an object that carries (or can carry) a
-- UIPadding: the padding grows and the icon sits inside it.
local function PadIcon(obj, spec, size, color, gap)
	size = size or 14
	gap  = gap  or 6
	local pad = obj:FindFirstChildOfClass("UIPadding")
	if not pad then
		pad = Instance.new("UIPadding")
		pad.Parent = obj
	end
	pad.PaddingLeft = UDim.new(pad.PaddingLeft.Scale, pad.PaddingLeft.Offset + size + gap)
	local L = MakeIcon(obj, spec, size, color or obj.TextColor3, obj.ZIndex)
	L.AnchorPoint = Vector2.new(0, 0.5)
	L.Position    = UDim2.new(0, -(size + gap), 0.5, 0)
	return L
end

-- Centred text (buttons, top tabs): the icon rides just left of the
-- rendered text and the pair stays centred as a block. The text is
-- measured again whenever Text/Font/TextSize change, so confirm-mode
-- relabels and active-tab font swaps keep the icon glued to the text.
local function InlineIcon(btn, spec, size, color, gap)
	size = size or 14
	gap  = gap  or 6
	local block = size + gap
	local pad = btn:FindFirstChildOfClass("UIPadding")
	if not pad then
		pad = Instance.new("UIPadding")
		pad.Parent = btn
	end
	pad.PaddingLeft = UDim.new(pad.PaddingLeft.Scale, pad.PaddingLeft.Offset + block)
	-- Full-size overlay layers (the ripple host) must keep covering the
	-- whole control even though the padding just shrank the content box.
	for _, c in ipairs(btn:GetChildren()) do
		if c:IsA("GuiObject") and c.Size == UDim2.new(1, 0, 1, 0)
		   and c.Position == UDim2.new(0, 0, 0, 0) then
			c.Size     = UDim2.new(1, block, 1, 0)
			c.Position = UDim2.new(0, -block, 0, 0)
		end
	end
	local L = MakeIcon(btn, spec, size, color or btn.TextColor3, btn.ZIndex)
	L.AnchorPoint = Vector2.new(0, 0.5)
	local function relayout()
		local t, w = btn.Text, 0
		if t ~= "" then
			local ok, b = pcall(TextService.GetTextSize, TextService,
				t, btn.TextSize, btn.Font, Vector2.new(4000, 100))
			w = (ok and b and b.X) or (#t * btn.TextSize * 0.55)
		end
		if w == 0 then
			-- Icon alone: centre it in the *unpadded* box.
			L.Position = UDim2.new(0.5, -(size + block) / 2, 0.5, 0)
		else
			L.Position = UDim2.new(0.5, -(w / 2 + block), 0.5, 0)
		end
	end
	relayout()
	for _, p in ipairs({ "Text", "Font", "TextSize" }) do
		btn:GetPropertyChangedSignal(p):Connect(relayout)
	end
	return L
end

-- ============================================================
-- CreatePanel
-- Creates a draggable panel with optional tab bar.
--
-- Options:
--   Name         string    ScreenGui name              (default "SkibidiPanel")
--   Title        string    Header title text           (default "")
--   Width        number    Width in pixels             (default 310)
--   Height       number    Content height in pixels    (default 300)
--   Icon         string    Lucide icon shown in place of the title pip
--                          (optional, see ICONS above)
--   Tabs         table     Array of tab names, or of tables
--                          { Name = "Main", Icon = "house" }
--                                                      (optional — omit for no tabs)
--   TabIcons     table     Parallel list of icon specs for string
--                          Tabs entries, e.g. { "house", "settings" }
--                          (optional)
--   DefaultTab   number    Initially active tab index  (default 1)
--   TabSide      string    "top" | "left"              (default "top")
--                          "left" renders a vertical tab rail instead
--                          of the horizontal bar under the header
--   TabWidth     number    Rail width when TabSide="left" (default 96)
--   SubTitle     string    Small muted text after the title (optional)
--   Variant      string    "gold"|"blue"|"green"|"red" (optional)
--   Minimized    bool      Start minimized             (default false)
--   ClampToScreen bool     Keep the panel inside the screen while
--                          dragging                    (default false)
--   ToggleKey    Enum.KeyCode | string   Hotkey that shows/hides the
--                          whole panel (optional)
--   Discord      bool      Discord chip in the header; click copies
--                          the invite link             (default false)
--   Search       bool      Search chip in the header (lucide "search"
--                          icon). Opens a search box in place of the
--                          title that live-filters the panel's rows
--                          by their text, across every tab
--                                                      (default true)
--   Scaler       bool      Resize grip in the bottom-right corner;
--                          drag it to resize the panel (default false)
--   MinSize      Vector2 | {w, h}   Smallest size the grip allows
--                          (default half the panel's initial size)
--   MaxSize      Vector2 | {w, h}   Largest size the grip allows
--                          (default double the panel's initial size)
--   ConfirmClose bool      Close chip asks "are you sure?" before
--                          closing                     (default true)
--   CloseTitle   string    Dialog heading   (default "Close panel?")
--   CloseMessage string    Dialog body text (optional)
--   MinWidth / MinHeight / MaxWidth / MaxHeight   number
--                          Per-axis overrides of the two above
--
-- Returns:
--   {
--     Gui, Frame, Header, TitleLabel,
--     Content,           -- Frame/ScrollingFrame for the active content area
--                        --   (if Tabs given, this is the current tab's frame)
--     GetTab(index),     -- returns the Frame for tab[index]  (nil if no tabs)
--     SetTab(index),     -- switches active tab
--     GetActiveTab(),    -- returns current tab index
--     GetTabButton(index), SetTitle(text), SetSubTitle(text),
--     SetIcon(spec), SetTabIcon(index, spec), GetTabIcon(index),
--     SetVisible(bool), ToggleVisible(), IsVisible(),
--     SetMinimized(bool), IsMinimized(), Close(), ConfirmClose(),
--     SetSearchOpen(bool), IsSearchOpen(), SetSearch(text),
--     SetSize(w, h), GetSize(),
--     SearchBtn, ScaleBtn (nil when the option is off)
--   }
-- ============================================================
function Skibidi.CreatePanel(Options)
	Options = Options or {}

	local Width      = Options.Width  or 310
	-- Tab entries may be plain strings or { Name = "…", Icon = "…" }
	-- tables; Options.TabIcons is an equivalent parallel list of icon
	-- specs for callers who'd rather keep Tabs as strings.
	local Tabs, tabIconSpecs = nil, {}   -- nil = no tab bar
	if type(Options.Tabs) == "table" then
		Tabs = {}
		for i, t in ipairs(Options.Tabs) do
			if type(t) == "table" then
				Tabs[i] = tostring(t.Name or t.Title or t.Text or t[1] or "")
				tabIconSpecs[i] = t.Icon or t[2]
			else
				Tabs[i] = tostring(t)
			end
			if type(Options.TabIcons) == "table" and Options.TabIcons[i] then
				tabIconSpecs[i] = Options.TabIcons[i]
			end
		end
	end
	local hasTabs    = Tabs and #Tabs > 0
	local activeTab  = Options.DefaultTab or 1

	-- Resolve accent
	local Accent, AccentDim
	if Options.Variant then
		local V = {
			gold  = { Color3.fromRGB(220,160, 60), Color3.fromRGB(100, 72,28) },
			blue  = { Color3.fromRGB( 60,140,220), Color3.fromRGB( 30, 80,160) },
			green = { Color3.fromRGB( 60,200, 90), Color3.fromRGB( 30,140, 50) },
			red   = { Color3.fromRGB(220, 60, 60), Color3.fromRGB(160, 30, 30) },
		}
		local v = V[Options.Variant]
		Accent    = v and v[1] or Theme.Accent
		AccentDim = v and v[2] or Theme.AccentDim
	else
		Accent    = Theme.Accent
		AccentDim = Theme.AccentDim
	end

	-- Layout constants. Side tabs replace the horizontal bar with a
	-- vertical rail, so the bar contributes no height in that mode.
	local sideTabs   = hasTabs and Options.TabSide == "left"
	local HEADER_H   = Theme.HeaderHeight
	local TABBAR_H   = (hasTabs and not sideTabs) and Theme.TabHeight or 0
	local RAIL_W     = sideTabs and (Options.TabWidth or 96) or 0
	local CONTENT_H  = Options.Height or 300
	local FULL_H     = HEADER_H + TABBAR_H + CONTENT_H

	-- ── ScreenGui ──────────────────────────────────────────
	local Gui = Instance.new("ScreenGui")
	Gui.Name           = Options.Name or "SkibidiPanel"
	Gui.ResetOnSpawn   = false
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Gui.Parent         = Options.Parent or DefaultParent
	table.insert(_allGuis, Gui)

	-- ── Main frame ─────────────────────────────────────────
	local Frame = Instance.new("Frame")
	Frame.Size                   = UDim2.new(0, Width, 0, FULL_H)
	Frame.Position               = UDim2.new(0.5, -(Width/2), 0.5, -(FULL_H/2))
	Frame.BackgroundColor3       = Theme.Bg1
	Frame.BackgroundTransparency = 0.04
	Frame.BorderSizePixel        = 0
	Frame.ClipsDescendants       = true
	Frame.Active                 = true
	Frame.Parent                 = Gui
	MakeCorner(Frame, UDim.new(0, Theme.CornerRadius))
	-- Border shimmers slowly around the panel when Theme.AnimatedBorder is
	-- on; falls back to a plain accent stroke when it isn't.
	local FrameStroke = MakeAnimatedStroke(Frame, Accent, 1.4)
	MakeGlass(Frame, 0.14)
	MakeGrain(Frame)

	-- Drop shadow. The panel clips its descendants, so the shadow lives
	-- as a sibling underneath it and mirrors the panel's Position/Size
	-- (property signals fire every frame during drags and tweens, so it
	-- tracks minimize/restore and dragging for free).
	-- Two shadow layers, not one. A wide, faint falloff lifts the window
	-- off whatever is behind it; a tighter, darker one hugs the edges as a
	-- contact shadow. A single blur can be soft or grounded, never both,
	-- and that is exactly what makes one-layer windows look pasted on.
	local shadowLayers = {}
	local function makeShadowLayer(pad, alpha, drop)
		local L = Instance.new("ImageLabel")
		L.Name                   = "SkibidiShadow"
		L.BackgroundTransparency = 1
		L.Image                  = Theme.ShadowAsset
		L.ImageColor3            = Color3.new(0, 0, 0)
		L.ImageTransparency      = alpha
		L.ScaleType              = Enum.ScaleType.Slice
		L.SliceCenter            = Rect.new(49, 49, 450, 450)
		L.ZIndex                 = 0
		L.Parent                 = Gui
		local sc = Instance.new("UIScale")
		sc.Scale  = 0.92
		sc.Parent = L
		table.insert(shadowLayers, { Obj = L, Pad = pad, Drop = drop, Scale = sc })
		return L
	end

	local elev = Theme.Elevation or 0.38
	makeShadowLayer(38, math.clamp(elev + 0.26, 0, 1), 12)   -- ambient
	local Shadow = makeShadowLayer(16, elev, 4)              -- contact

	local function syncShadow()
		local p, sz = Frame.Position, Frame.Size
		for _, L in ipairs(shadowLayers) do
			L.Obj.Position = UDim2.new(p.X.Scale, p.X.Offset - L.Pad,
			                           p.Y.Scale, p.Y.Offset - L.Pad + L.Drop)
			L.Obj.Size     = UDim2.new(sz.X.Scale, sz.X.Offset + L.Pad * 2,
			                           sz.Y.Scale, sz.Y.Offset + L.Pad * 2)
		end
	end
	Frame:GetPropertyChangedSignal("Position"):Connect(syncShadow)
	Frame:GetPropertyChangedSignal("Size"):Connect(syncShadow)
	Frame:GetPropertyChangedSignal("Visible"):Connect(function()
		for _, L in ipairs(shadowLayers) do L.Obj.Visible = Frame.Visible end
	end)
	syncShadow()

	-- Ambient accent bloom. Sits between the shadow and the panel so the
	-- window looks lit rather than pasted onto the screen.
	local Bloom = MakeGlow(Frame, Accent, 26, 0.86)
	if Bloom then Bloom.ZIndex = 0 end

	-- Entrance: gentle pop-in on creation (UIScale rests at 1 afterwards,
	-- so it never affects layout or dragging). The shadow scales in with
	-- the panel so it doesn't hang oversized around the smaller frame.
	local OpenScale = Instance.new("UIScale")
	OpenScale.Scale  = 0.92
	OpenScale.Parent = Frame
	TweenService:Create(OpenScale, TweenSpring, { Scale = 1 }):Play()
	for _, L in ipairs(shadowLayers) do
		TweenService:Create(L.Scale, TweenSpring, { Scale = 1 }):Play()
	end

	-- ── Title / Header bar ─────────────────────────────────
	local Header = Instance.new("Frame")
	Header.Size             = UDim2.new(1, 0, 0, HEADER_H)
	Header.Position         = UDim2.new(0, 0, 0, 0)
	Header.BackgroundColor3 = Theme.Bg0
	Header.BorderSizePixel  = 0
	Header.Active           = true
	Header.Selectable       = true
	Header.ZIndex           = 2
	Header.Parent           = Frame
	MakeCorner(Header, UDim.new(0, Theme.CornerRadius))
	MakeGloss(Header, 0.14)

	-- Accent wash across the header: strongest on the left behind the
	-- title, gone by the middle, so the title sits in its own pool of
	-- colour without tinting the buttons on the right.
	local HeaderWash = Instance.new("Frame")
	HeaderWash.Size                   = UDim2.new(1, 0, 1, 0)
	HeaderWash.BackgroundColor3       = Accent
	HeaderWash.BorderSizePixel        = 0
	HeaderWash.ZIndex                 = 2
	HeaderWash.Parent                 = Header
	MakeCorner(HeaderWash, UDim.new(0, Theme.CornerRadius))
	do
		local g = Instance.new("UIGradient")
		g.Rotation = 0
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 0.86),
			NumberSequenceKeypoint.new(0.42, 0.97),
			NumberSequenceKeypoint.new(1.00, 1.00),
		})
		g.Parent = HeaderWash
	end

	local showDiscord = Options.Discord == true
	local showSearch  = Options.Search ~= false   -- on unless explicitly disabled
	local showScaler  = Options.Scaler == true
	-- Close + minimize chips, then one 28px chip + 6px gap per optional chip.
	local reservedRight = 86 + (showDiscord and 34 or 0) + (showSearch and 34 or 0)

	-- Small accent pip left of the title — a window "app icon" stand-in
	-- that also gives the header a fixed optical left margin.
	local TitlePip = Instance.new("Frame")
	TitlePip.Size             = UDim2.new(0, 3, 0, 16)
	TitlePip.Position         = UDim2.new(0, 12, 0.5, -8)
	TitlePip.BackgroundColor3 = Accent
	TitlePip.BorderSizePixel  = 0
	TitlePip.ZIndex           = 3
	TitlePip.Parent           = Header
	MakeCorner(TitlePip, UDim.new(1, 0))
	MakeAccentFill(TitlePip, Accent)

	-- Optional lucide icon (Options.Icon). It replaces the pip rather
	-- than sitting beside it: the pip *is* the stand-in for an icon.
	local TITLE_ICON   = 16
	local TITLE_X_PIP  = 21                    -- pip + gap
	local TITLE_X_ICON = 11 + TITLE_ICON + 7   -- icon + gap
	local TitleIcon
	if Options.Icon then
		TitleIcon = MakeIcon(Header, Options.Icon, TITLE_ICON, Theme.AccentSec, 3)
		TitleIcon.Name        = "SkibidiTitleIcon"
		TitleIcon.AnchorPoint = Vector2.new(0, 0.5)
		TitleIcon.Position    = UDim2.new(0, 11, 0.5, 0)
		TitlePip.Visible      = false
	end

	local TITLE_X = TitleIcon and TITLE_X_ICON or TITLE_X_PIP   -- left edge of the title text

	-- Title and subtitle are separate labels rather than one RichText
	-- string. Keeping them apart is what lets the minimize logic below
	-- measure each with its own font/size — measuring RichText markup as
	-- plain text is what previously made a subtitled panel refuse to
	-- shrink past full width.
	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size                   = UDim2.new(1, -(reservedRight + TITLE_X), 1, 0)
	TitleLabel.Position               = UDim2.new(0, TITLE_X, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font                   = Theme.FontBold
	TitleLabel.TextSize               = Theme.TitleSize
	TitleLabel.TextColor3             = Theme.AccentSec
	TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	TitleLabel.TextTruncate           = Enum.TextTruncate.AtEnd
	TitleLabel.Text                   = Options.Title or ""
	TitleLabel.ZIndex                 = 3
	TitleLabel.Parent                 = Header

	-- Title text carries the accent gradient so it doesn't read as flat.
	do
		local a, b = AccentPair(Accent)
		local g = Instance.new("UIGradient")
		g.Color    = ColorSequence.new(Lighten(a, 0.28), Lighten(b, 0.12))
		g.Rotation = 90
		g.Parent   = TitleLabel
	end

	-- Optional subtitle, rendered as a rounded muted pill after the title
	local plainTitle    = Options.Title    or ""
	local plainSubTitle = Options.SubTitle or ""
	local SubPill, SubLabel

	local function measureText(str, size, font)
		if not str or str == "" then return 0 end
		local ok, b = pcall(TextService.GetTextSize, TextService,
			str, size, font, Vector2.new(4000, HEADER_H))
		return (ok and b and b.X) or (#str * size * 0.55)
	end

	if plainSubTitle ~= "" then
		SubPill = Instance.new("Frame")
		SubPill.AutomaticSize          = Enum.AutomaticSize.X
		SubPill.Size                   = UDim2.new(0, 0, 0, 16)
		SubPill.AnchorPoint            = Vector2.new(0, 0.5)
		SubPill.BackgroundColor3       = Theme.Bg2
		SubPill.BackgroundTransparency = 0.15
		SubPill.BorderSizePixel        = 0
		SubPill.ZIndex                 = 3
		SubPill.Parent                 = Header
		MakeCorner(SubPill, UDim.new(1, 0))
		MakeEdge(SubPill, Theme.AccentDim, 1)
		MakeGloss(SubPill, 0.10)
		MakePadding(SubPill, 7, 7, 0, 0)

		SubLabel = Instance.new("TextLabel")
		SubLabel.AutomaticSize          = Enum.AutomaticSize.X
		SubLabel.Size                   = UDim2.new(0, 0, 1, 0)
		SubLabel.BackgroundTransparency = 1
		SubLabel.Font                   = Theme.FontMedium
		SubLabel.TextSize               = Theme.CaptionSize
		SubLabel.TextColor3             = Theme.TextMuted
		SubLabel.TextXAlignment         = Enum.TextXAlignment.Left
		SubLabel.Text                   = plainSubTitle
		SubLabel.ZIndex                 = 4
		SubLabel.Parent                 = SubPill
	end

	local SUB_GAP  = 8    -- gap between title text and the subtitle pill
	local SUB_PADX = 14   -- the pill's own horizontal padding (7 + 7)

	-- Places the pill immediately after the *rendered* title text, and
	-- keeps the title label's width honest so a long title truncates
	-- instead of running under the pill or the header buttons.
	-- TextService measures a hair short of what the font actually renders,
	-- and the label used to be sized to exactly that number. Overflowing by
	-- even a sub-pixel arms AtEnd truncation, which then has to free room
	-- for the ellipsis itself — and "…" is wider than the character it
	-- replaces, so it ate a second one too. That is how a 420px header
	-- managed to render "UILib" as "UIL…".
	--
	-- The slack absorbs the measurement error, and truncation is only armed
	-- when the title genuinely cannot fit.
	local TITLE_SLACK = 6   -- kept under SUB_GAP so it can never reach the pill

	local function layoutTitle()
		if not SubPill then
			TitleLabel.TextTruncate = Enum.TextTruncate.AtEnd
			TitleLabel.Size = UDim2.new(1, -(reservedRight + TITLE_X), 1, 0)
			return
		end
		local subW  = SUB_PADX + measureText(plainSubTitle, Theme.CaptionSize, Theme.FontMedium)
		local avail = math.max(Width - TITLE_X - reservedRight - SUB_GAP - subW, 20)
		local textW = math.ceil(measureText(plainTitle, Theme.TitleSize, Theme.FontBold))
		local fits  = (textW + TITLE_SLACK) <= avail

		TitleLabel.TextTruncate = fits and Enum.TextTruncate.None
		                              or   Enum.TextTruncate.AtEnd

		local tw = fits and textW or avail
		SubPill.Position = UDim2.new(0, TITLE_X + tw + SUB_GAP, 0.5, 0)
		TitleLabel.Size  = UDim2.new(0, tw + (fits and TITLE_SLACK or 0), 1, 0)
	end
	layoutTitle()

	-- Accent underline on header
	local AccentLine = Instance.new("Frame")
	AccentLine.Size                   = UDim2.new(1, -20, 0, 1)
	AccentLine.Position               = UDim2.new(0, 10, 1, -1)
	AccentLine.BackgroundColor3       = Lighten(Accent, 0.10)
	AccentLine.BackgroundTransparency = 0.35
	AccentLine.BorderSizePixel        = 0
	AccentLine.ZIndex                 = 3
	AccentLine.Parent                 = Header

	-- Fade the underline out toward both ends so it reads as a glow
	-- rather than a hard rule.
	local AccentLineGrad = Instance.new("UIGradient")
	AccentLineGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.00, 1),
		NumberSequenceKeypoint.new(0.18, 0),
		NumberSequenceKeypoint.new(0.82, 0),
		NumberSequenceKeypoint.new(1.00, 1),
	})
	AccentLineGrad.Parent = AccentLine

	-- Header buttons share one recipe: a soft translucent chip that lifts
	-- toward the accent on hover and dips on press.
	local function MakeHeaderChip(glyph, xOffset)
		local B = Instance.new("TextButton")
		B.Size                   = UDim2.new(0, 28, 0, 20)
		B.AnchorPoint            = Vector2.new(1, 0.5)
		B.Position               = UDim2.new(1, xOffset, 0.5, 0)
		B.BackgroundColor3       = AccentDim
		B.BackgroundTransparency = 0.30
		B.BorderSizePixel        = 0
		B.Font                   = Theme.FontIcon
		B.TextSize               = 16
		B.TextColor3             = Theme.AccentSec
		B.Text                   = glyph or ""
		B.AutoButtonColor        = false
		B.ZIndex                 = 4
		B.Parent                 = Header
		MakeCorner(B, UDim.new(0, 7))
		MakeEdge(B, Accent, 1, 0.55)
		MakeGloss(B, 0.18)
		MakeRipple(B, Theme.AccentSec, 7)

		-- Chips are small, so colour alone barely registers as a press.
		-- Scaling the whole chip is what actually reads at this size.
		local sc = Instance.new("UIScale")
		sc.Parent = B
		B.MouseButton1Down:Connect(function()
			TweenService:Create(sc, TweenSnap, { Scale = 0.87 }):Play()
		end)
		B.MouseButton1Up:Connect(function()
			TweenService:Create(sc, TweenPop, { Scale = 1 }):Play()
		end)
		B.MouseEnter:Connect(function()
			TweenService:Create(sc, TweenFast, { Scale = 1.06 }):Play()
		end)
		B.MouseLeave:Connect(function()
			TweenService:Create(sc, TweenFast, { Scale = 1 }):Play()
		end)
		return B
	end

	-- Chips are laid out right-to-left: each one claims a 28px slot plus
	-- a 6px gap, so optional chips can be added without hand-tuning offsets.
	local chipX = -8
	local function nextChipX()
		local x = chipX
		chipX = chipX - (28 + 6)
		return x
	end

	-- Close button
	local CloseBtn = MakeHeaderChip("×", nextChipX())

	-- Minimize button (shifted left to make room for the close button)
	local MinBtn = MakeHeaderChip("–", nextChipX())

	-- Discord button (optional, off by default)
	-- Options.Discord = true enables it. Clicking copies the invite link
	-- to the clipboard via setclipboard (when the executor supports it).
	local DISCORD_INVITE    = "https://discord.gg/vonhub"
	-- The Discord mark is fetched from the web and cached as a PNG in the
	-- executor workspace (see FetchCachedImage). DISCORD_ICON_ID is only
	-- the fallback shown while the download runs or when the executor has
	-- no writefile/getcustomasset.
	local DISCORD_ICON_URL  = "https://files.catbox.moe/gvgnul.png"
	local DISCORD_ICON_FILE = "skibidi_discord.png"
	local DISCORD_ICON_ID   = "rbxassetid://94434236999817"

	local DiscordBtn
	if showDiscord then
		DiscordBtn = Instance.new("TextButton")
		DiscordBtn.Size                   = UDim2.new(0, 28, 0, 20)
		DiscordBtn.AnchorPoint            = Vector2.new(1, 0.5)
		DiscordBtn.Position               = UDim2.new(1, nextChipX(), 0.5, 0)
		DiscordBtn.BackgroundColor3       = AccentDim
		DiscordBtn.BorderSizePixel        = 0
		DiscordBtn.Text                   = ""
		DiscordBtn.AutoButtonColor        = false
		DiscordBtn.ZIndex                 = 4
		DiscordBtn.Parent                 = Header
		MakeCorner(DiscordBtn, UDim.new(0, 7))
		MakeEdge(DiscordBtn, Accent, 1, 0.55)
		MakeSheen(DiscordBtn, 0.16)
		MakeRipple(DiscordBtn, Theme.AccentSec, 7)

		local DiscordIcon = Instance.new("ImageLabel")
		DiscordIcon.Size                   = UDim2.new(0, 16, 0, 16)
		DiscordIcon.AnchorPoint            = Vector2.new(0.5, 0.5)
		DiscordIcon.Position               = UDim2.new(0.5, 0, 0.5, 0)
		DiscordIcon.BackgroundTransparency = 1
		DiscordIcon.Image                  = DISCORD_ICON_ID
		DiscordIcon.ImageColor3            = Theme.AccentSec
		DiscordIcon.ScaleType              = Enum.ScaleType.Fit
		DiscordIcon.ZIndex                 = 5
		DiscordIcon.Parent                 = DiscordBtn

		-- Swap in the cached PNG once it's available (first run downloads
		-- it, later runs read it straight from the workspace file).
		task.spawn(function()
			local asset = FetchCachedImage(DISCORD_ICON_URL, DISCORD_ICON_FILE)
			if asset and DiscordIcon.Parent then
				DiscordIcon.Image = asset
			end
		end)

		DiscordBtn.MouseButton1Click:Connect(function()
			if setclipboard then
				pcall(setclipboard, DISCORD_INVITE)
			end
			DiscordIcon.ImageColor3 = Theme.Accent
			task.delay(1, function()
				if DiscordIcon and DiscordIcon.Parent then
					DiscordIcon.ImageColor3 = Theme.AccentSec
				end
			end)
		end)
		DiscordBtn.MouseEnter:Connect(function()
			TweenService:Create(DiscordBtn, TweenFast, { BackgroundColor3 = Theme.ToggleOn }):Play()
		end)
		DiscordBtn.MouseLeave:Connect(function()
			TweenService:Create(DiscordBtn, TweenFast, { BackgroundColor3 = AccentDim }):Play()
		end)
	end

	-- Search button (optional, on by default)
	-- Options.Search = false disables it. Clicking swaps the title for a
	-- search box; typing live-filters every tab's rows by their text.
	-- The glyph is lucide's "search" from the icon set WindUI ships with.
	local SEARCH_ICON_ID = "rbxassetid://121018724060431"
	local SearchBtn, SearchIcon, SearchBox
	if showSearch then
		SearchBtn = MakeHeaderChip("", nextChipX())
		SearchBtn.Name = "SkibidiSearch"

		SearchIcon = Instance.new("ImageLabel")
		SearchIcon.Size                   = UDim2.new(0, 13, 0, 13)
		SearchIcon.AnchorPoint            = Vector2.new(0.5, 0.5)
		SearchIcon.Position               = UDim2.new(0.5, 0, 0.5, 0)
		SearchIcon.BackgroundTransparency = 1
		SearchIcon.Image                  = SEARCH_ICON_ID
		SearchIcon.ImageColor3            = Theme.AccentSec
		SearchIcon.ZIndex                 = 5
		SearchIcon.Parent                 = SearchBtn

		-- The box takes over the title's slot so nothing else in the
		-- header has to move; it is only visible while search is open.
		SearchBox = Instance.new("TextBox")
		SearchBox.Name                   = "SkibidiSearchBox"
		SearchBox.Size                   = UDim2.new(1, -(reservedRight + TITLE_X), 0, 22)
		SearchBox.AnchorPoint            = Vector2.new(0, 0.5)
		SearchBox.Position               = UDim2.new(0, TITLE_X, 0.5, 0)
		SearchBox.BackgroundColor3       = Theme.InputBg
		SearchBox.BackgroundTransparency = 0.10
		SearchBox.BorderSizePixel        = 0
		SearchBox.Font                   = Theme.FontMedium
		SearchBox.TextSize               = Theme.SmallSize
		SearchBox.TextColor3             = Theme.TextPrimary
		SearchBox.PlaceholderText        = "Search…"
		SearchBox.PlaceholderColor3      = Theme.TextMuted
		SearchBox.TextXAlignment         = Enum.TextXAlignment.Left
		SearchBox.TextTruncate           = Enum.TextTruncate.AtEnd
		SearchBox.ClearTextOnFocus       = false
		SearchBox.Text                   = ""
		SearchBox.Visible                = false
		SearchBox.ZIndex                 = 4
		SearchBox.Parent                 = Header
		MakeCorner(SearchBox, UDim.new(0, 7))
		MakeEdge(SearchBox, Accent, 1, 0.55)
		MakePadding(SearchBox, 8, 8, 0, 0)
	end

	-- ── Tab bar (optional) ─────────────────────────────────
	-- "top"  — horizontal bar of equal-width buttons under the header
	-- "left" — vertical rail of full-width buttons beside the content
	local TabBar, TabBtns, TabUnderline, TabInd, RailBg
	local tabGrads = {}
	local tabIcons = {}   -- index -> ImageLabel (only tabs that have one)
	local TAB_ICON = 14
	local tabGap, tabW = 6, 0
	local SIDE_TAB_H, SIDE_TAB_GAP, SIDE_TAB_TOP = 28, 4, 8
	if hasTabs and not sideTabs then
		TabBar = Instance.new("Frame")
		TabBar.Position               = UDim2.new(0, 0, 0, HEADER_H)
		TabBar.Size                   = UDim2.new(1, 0, 0, TABBAR_H)
		TabBar.BackgroundTransparency = 1
		TabBar.ZIndex                 = 2
		TabBar.Parent                 = Frame
		-- Shifted down 2px from the previous pass (top 4->6, bottom 9->7)
		-- so the tab buttons sit centered between the header underline
		-- above and the tab underline below.
		MakePadding(TabBar, 10, 10, 6, 7)
		MakeListLayout(TabBar, Enum.FillDirection.Horizontal, 6,
			Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

		TabUnderline = Instance.new("Frame")
		TabUnderline.Size                   = UDim2.new(1, -20, 0, 1)
		TabUnderline.Position               = UDim2.new(0, 10, 0, HEADER_H + TABBAR_H - 1)
		TabUnderline.BackgroundColor3       = AccentDim
		TabUnderline.BackgroundTransparency = 0.3
		TabUnderline.BorderSizePixel        = 0
		TabUnderline.ZIndex                 = 2
		TabUnderline.Parent                 = Frame

		-- Every tab gets an equal share of the bar's width instead of
		-- sizing itself to its own text — long labels can overflow their
		-- button, which is fine, but the buttons themselves stay uniform.
		tabGap = 6
		tabW   = (Width - 20 - tabGap * (#Tabs - 1)) / #Tabs

		TabBtns = {}
		for i, name in ipairs(Tabs) do
			local btn = Instance.new("TextButton")
			btn.Size              = UDim2.new(0, tabW, 1, 0)
			btn.LayoutOrder       = i
			btn.BackgroundColor3  = Theme.Bg2
			btn.BorderSizePixel   = 0
			btn.AutoButtonColor   = false
			btn.Font              = Theme.FontMedium
			btn.TextSize          = Theme.SmallSize
			btn.TextColor3        = Theme.TextMuted
			btn.Text              = "  " .. name .. "  "
			btn.ZIndex            = 3
			btn.Parent            = TabBar
			MakeCorner(btn, UDim.new(0, 7))
			MakeEdge(btn, AccentDim, 1)
			-- One gradient per tab, re-coloured on activation rather than
			-- created and destroyed, so switching tabs allocates nothing.
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Parent   = btn
			tabGrads[i] = g
			local fit = Instance.new("UITextSizeConstraint", btn)
			fit.MaxTextSize = 12; fit.MinTextSize = 8
			TabBtns[i] = btn
		end

		-- The sliding indicator. It lives on Frame, not on TabBar, because
		-- TabBar is driven by a UIListLayout and any child of it would be
		-- treated as another tab to lay out.
		TabInd = Instance.new("Frame")
		TabInd.Size             = UDim2.new(0, math.floor(tabW), 0, 2)
		TabInd.Position         = UDim2.new(0, 10, 0, HEADER_H + TABBAR_H - 2)
		TabInd.BackgroundColor3 = Accent
		TabInd.BorderSizePixel  = 0
		TabInd.ZIndex           = 4
		TabInd.Parent           = Frame
		MakeCorner(TabInd, UDim.new(1, 0))
		MakeAccentFill(TabInd, Accent)
	elseif sideTabs then
		-- Vertical tab rail on a slightly darker strip so it reads as
		-- navigation, separated from content by a 1px divider.
		-- The rail runs to the panel's bottom edge, and ClipsDescendants
		-- clips to a rectangle, so a plain square rail would poke past
		-- the panel's rounded bottom-left corner. The rail's fill lives in
		-- a clipped sibling instead: the fill is oversized by one corner
		-- radius up and to the right, so the clip keeps only its
		-- bottom-left rounding and every other corner stays square.
		local R = Theme.CornerRadius
		RailBg = Instance.new("Frame")
		RailBg.Position               = UDim2.new(0, 0, 0, HEADER_H)
		RailBg.Size                   = UDim2.new(0, RAIL_W, 1, -HEADER_H)
		RailBg.BackgroundTransparency = 1
		RailBg.BorderSizePixel        = 0
		RailBg.ClipsDescendants       = true
		RailBg.ZIndex                 = 2
		RailBg.Parent                 = Frame
		local RailFill = Instance.new("Frame")
		RailFill.Position               = UDim2.new(0, 0, 0, -R)
		RailFill.Size                   = UDim2.new(1, R, 1, R)
		RailFill.BackgroundColor3       = Theme.Bg0
		RailFill.BackgroundTransparency = 0.35
		RailFill.BorderSizePixel        = 0
		RailFill.ZIndex                 = 2
		RailFill.Parent                 = RailBg
		MakeCorner(RailFill, UDim.new(0, R))

		TabBar = Instance.new("Frame")
		TabBar.Position               = UDim2.new(0, 0, 0, HEADER_H)
		TabBar.Size                   = UDim2.new(0, RAIL_W, 1, -HEADER_H)
		TabBar.BackgroundTransparency = 1
		TabBar.BorderSizePixel        = 0
		TabBar.ZIndex                 = 2
		TabBar.Parent                 = Frame
		MakePadding(TabBar, 6, 6, 8, 8)
		MakeListLayout(TabBar, Enum.FillDirection.Vertical, 4)

		-- Vertical divider between the rail and the content area
		-- (kept in TabUnderline so minimize/restore hides it too)
		TabUnderline = Instance.new("Frame")
		TabUnderline.Size                   = UDim2.new(0, 1, 1, -(HEADER_H + 10))
		TabUnderline.Position               = UDim2.new(0, RAIL_W, 0, HEADER_H + 5)
		TabUnderline.BackgroundColor3       = AccentDim
		TabUnderline.BackgroundTransparency = 0.3
		TabUnderline.BorderSizePixel        = 0
		TabUnderline.ZIndex                 = 2
		TabUnderline.Parent                 = Frame

		TabBtns = {}
		for i, name in ipairs(Tabs) do
			local btn = Instance.new("TextButton")
			btn.Size              = UDim2.new(1, 0, 0, 28)
			btn.LayoutOrder       = i
			btn.BackgroundColor3  = Theme.Bg2
			btn.BorderSizePixel   = 0
			btn.AutoButtonColor   = false
			btn.Font              = Theme.FontMedium
			btn.TextSize          = Theme.SmallSize
			btn.TextColor3        = Theme.TextMuted
			btn.TextXAlignment    = Enum.TextXAlignment.Left
			btn.TextTruncate      = Enum.TextTruncate.AtEnd
			btn.Text              = name
			btn.ZIndex            = 3
			btn.Parent            = TabBar
			MakeCorner(btn, UDim.new(0, 7))
			MakeEdge(btn, AccentDim, 1)
			MakePadding(btn, 12, 6, 0, 0)
			local g = Instance.new("UIGradient")
			g.Rotation = 90
			g.Parent   = btn
			tabGrads[i] = g
			TabBtns[i] = btn
		end

		TabInd = Instance.new("Frame")
		TabInd.Size             = UDim2.new(0, 3, 0, 16)
		TabInd.Position         = UDim2.new(0, 2, 0, HEADER_H + SIDE_TAB_TOP + 6)
		TabInd.BackgroundColor3 = Accent
		TabInd.BorderSizePixel  = 0
		TabInd.ZIndex           = 4
		TabInd.Parent           = Frame
		MakeCorner(TabInd, UDim.new(1, 0))
		MakeAccentFill(TabInd, Accent)
	end

	-- Icons on tabs. Top tabs centre their text, so the icon rides the
	-- text (InlineIcon); the side rail is left-aligned, so the icon
	-- simply widens the rail's padding (PadIcon). Also the backing for
	-- SetTabIcon, which re-points an existing icon or adds one late.
	local function makeTabIcon(i, spec)
		local btn = TabBtns and TabBtns[i]
		if not btn then return nil end
		if tabIcons[i] then
			SetIconImage(tabIcons[i], spec)
			return tabIcons[i]
		end
		if spec == nil or spec == "" then return nil end
		local color = (i == activeTab) and Theme.ActiveTabText or Theme.TextMuted
		tabIcons[i] = sideTabs
			and PadIcon(btn, spec, TAB_ICON, color, 6)
			or  InlineIcon(btn, spec, TAB_ICON, color, 5)
		return tabIcons[i]
	end
	for i, spec in pairs(tabIconSpecs) do makeTabIcon(i, spec) end

	-- ── Content area ───────────────────────────────────────
	-- One scrolling frame per tab (or just one if no tabs)
	local tabCount  = hasTabs and #Tabs or 1
	local tabFrames = {}

	for i = 1, tabCount do
		local sf = Instance.new("ScrollingFrame")
		sf.Position               = UDim2.new(0, RAIL_W, 0, HEADER_H + TABBAR_H)
		sf.Size                   = UDim2.new(1, -RAIL_W, 1, -(HEADER_H + TABBAR_H))
		sf.BackgroundTransparency = 1
		sf.BorderSizePixel        = 0
		sf.ScrollBarThickness     = 4
		sf.ScrollBarImageColor3   = Accent
		sf.ScrollBarImageTransparency = 0.45
		sf.ScrollingDirection     = Enum.ScrollingDirection.Y
		sf.AutomaticCanvasSize    = Enum.AutomaticSize.Y
		sf.CanvasSize             = UDim2.new(0, 0, 0, 0)
		sf.ClipsDescendants       = true
		sf.Visible                = (i == 1)
		sf.Parent                 = Frame
		MakePadding(sf, Theme.Padding, Theme.Padding, Theme.Padding, Theme.Padding)
		MakeListLayout(sf, Enum.FillDirection.Vertical, 6)
		tabFrames[i] = sf
	end

	-- ── Tab switching logic ────────────────────────────────
	-- Active tabs are lit from the top; inactive ones stay almost flat.
	-- Both live on the same gradient object so the difference is a colour
	-- swap rather than a structural change.
	local GRAD_ON = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.new(1.00, 1.00, 1.00)),
		ColorSequenceKeypoint.new(1.00, Color3.new(0.74, 0.74, 0.74)),
	})
	local GRAD_OFF = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.new(1.00, 1.00, 1.00)),
		ColorSequenceKeypoint.new(1.00, Color3.new(0.93, 0.93, 0.93)),
	})

	local function tabIndicatorTarget(idx)
		if sideTabs then
			local y = HEADER_H + SIDE_TAB_TOP
			      + (idx - 1) * (SIDE_TAB_H + SIDE_TAB_GAP)
			      + (SIDE_TAB_H - 16) / 2
			return UDim2.new(0, 2, 0, math.floor(y))
		end
		return UDim2.new(0, math.floor(10 + (idx - 1) * (tabW + tabGap)),
		                 0, HEADER_H + TABBAR_H - 2)
	end

	local function applyTabStyle(animate)
		if not hasTabs then return end
		for i, btn in ipairs(TabBtns) do
			local on = (i == activeTab)
			local bg   = on and Theme.ToggleOn or Theme.Bg2
			local text = on and Theme.ActiveTabText or Theme.TextMuted
			if animate then
				TweenService:Create(btn, TweenFast,
					{ BackgroundColor3 = bg, TextColor3 = text }):Play()
			else
				btn.BackgroundColor3 = bg
				btn.TextColor3       = text
			end
			btn.Font = on and Theme.FontBold or Theme.FontMedium
			if tabGrads[i] then
				tabGrads[i].Color = on and GRAD_ON or GRAD_OFF
			end
			if tabIcons[i] then
				if animate then
					TweenService:Create(tabIcons[i], TweenFast, { ImageColor3 = text }):Play()
				else
					tabIcons[i].ImageColor3 = text
				end
			end
		end
		if TabInd then
			local target = tabIndicatorTarget(activeTab)
			if animate then
				-- Quint-out is what sells this as one object gliding to a
				-- new tab rather than two bars blinking in and out.
				TweenService:Create(TabInd, TweenSoft, { Position = target }):Play()
			else
				TabInd.Position = target
			end
		end
	end

	local lastTab = activeTab
	local function SetTab(idx)
		if not hasTabs then return end
		local dir = (idx > lastTab) and 1 or -1
		activeTab = idx
		for i, sf in ipairs(tabFrames) do
			sf.Visible = (i == idx)
		end

		-- The incoming page slides in from the side it came from, so tab
		-- order stays legible instead of every switch looking identical.
		local sf = tabFrames[idx]
		if sf and idx ~= lastTab then
			local restX = RAIL_W
			sf.Position = UDim2.new(0, restX + dir * 16, 0, HEADER_H + TABBAR_H)
			TweenService:Create(sf, TweenSoft,
				{ Position = UDim2.new(0, restX, 0, HEADER_H + TABBAR_H) }):Play()
		end

		lastTab = idx
		applyTabStyle(true)
	end

	if hasTabs then
		applyTabStyle()
		for i, btn in ipairs(TabBtns) do
			local idx = i
			btn.MouseButton1Click:Connect(function() SetTab(idx) end)
			btn.MouseEnter:Connect(function()
				if activeTab ~= idx then
					TweenService:Create(btn, TweenFast,
						{ BackgroundColor3 = Theme.Hover }):Play()
				end
			end)
			btn.MouseLeave:Connect(function()
				if activeTab ~= idx then
					TweenService:Create(btn, TweenFast,
						{ BackgroundColor3 = Theme.Bg2 }):Play()
				end
			end)
		end
		SetTab(activeTab)
	end

	-- ── Minimize logic ─────────────────────────────────────
	-- Minimizing happens in two stages instead of collapsing straight
	-- into the topbar:
	--   1) collapse height normally (FULL_H -> HEADER_H)
	--   2) slide the width in sideways until the panel hugs the title,
	--      so the minimized button sits directly beside the title text
	--      instead of covering it or leaving a dead gap.
	-- Restoring reverses the two stages (width out, then height open).
	-- The hugging width is computed from the *actual rendered* title
	-- text each time, so it adapts automatically to any title length.
	local MIN_BTN_W     = 28   -- MinBtn.Size.X
	local CLOSE_BTN_W   = 28   -- CloseBtn.Size.X
	local DISCORD_BTN_W = showDiscord and (28 + 6) or 0  -- DiscordBtn.Size.X + gap, if present
	local SEARCH_BTN_W  = showSearch  and (28 + 6) or 0  -- SearchBtn.Size.X + gap, if present
	local BTN_GAP       = 6    -- gap between MinBtn and CloseBtn
	local MIN_BTN_RIGHT = 8    -- CloseBtn's right margin (see Position above)
	local TITLE_GAP     = 10   -- breathing room between title text and buttons

	-- Width the panel shrinks to when minimized: enough to hold the pip,
	-- the title, the subtitle pill (if any) and the header buttons.
	--
	-- The title and subtitle are measured *separately, as plain strings,
	-- with their own font and size*. The previous version measured
	-- TitleLabel.Text, which — once a SubTitle was supplied — held RichText
	-- markup (`Foo  <font size="11" color="#...">bar</font>`). TextService
	-- has no idea those are tags, so it measured ~40 extra characters at
	-- title size, the result blew past Width, the clamp pinned it to Width,
	-- and stage 2 of the animation became a no-op: the panel collapsed its
	-- height and then just sat there at full width, "half minimized".
	local function computeMinimizedWidth()
		local w = TITLE_X + (SubPill and TitleLabel.Size.X.Offset
		                     or measureText(plainTitle, Theme.TitleSize, Theme.FontBold))
		if plainSubTitle ~= "" then
			w = w + SUB_GAP + SUB_PADX
			   + measureText(plainSubTitle, Theme.CaptionSize, Theme.FontMedium)
		end
		w = w + TITLE_GAP + SEARCH_BTN_W + DISCORD_BTN_W + MIN_BTN_W + BTN_GAP + CLOSE_BTN_W + MIN_BTN_RIGHT
		-- Clamp to the panel's own width so minimizing never makes the
		-- window *wider*; a title long enough to hit that ceiling simply
		-- truncates instead.
		return math.clamp(math.ceil(w), 90, Width)
	end

	local isMinimized = Options.Minimized == true
	local minimizeToken = 0

	-- Defined further down (search / resize sections); declared here so
	-- the minimize logic can reach them.
	local ScaleBtn
	local SetSearchOpen = function() end

	local function setBodyVisible(visible)
		if TabBar       then TabBar.Visible       = visible end
		if RailBg       then RailBg.Visible       = visible end
		if TabUnderline then TabUnderline.Visible = visible end
		if TabInd       then TabInd.Visible       = visible end
		if ScaleBtn     then ScaleBtn.Visible     = visible end
		if visible then
			for i, sf in ipairs(tabFrames) do
				if hasTabs then
					sf.Visible = (i == activeTab)
				else
					sf.Visible = (i == 1)
				end
			end
		else
			for _, sf in ipairs(tabFrames) do sf.Visible = false end
		end
	end

	local function applyMinimize(instant)
		minimizeToken = minimizeToken + 1
		local myToken = minimizeToken

		MinBtn.Text = isMinimized and "+" or "–"
		AccentLine.Visible = not isMinimized

		if instant then
			if isMinimized then
				setBodyVisible(false)
				Frame.Size = UDim2.new(0, computeMinimizedWidth(), 0, HEADER_H)
			else
				setBodyVisible(true)
				Frame.Size = UDim2.new(0, Width, 0, FULL_H)
			end
			return
		end

		if isMinimized then
			-- Stage 1: minimize normally (collapse height into the topbar)
			setBodyVisible(false)
			local heightTween = TweenService:Create(Frame, TweenMed,
				{ Size = UDim2.new(0, Width, 0, HEADER_H) })
			heightTween.Completed:Connect(function(state)
				if myToken ~= minimizeToken or state ~= Enum.PlaybackState.Completed then return end
				-- Stage 2: slide sideways to hug the title
				local mw = computeMinimizedWidth()
				TweenService:Create(Frame, TweenMed,
					{ Size = UDim2.new(0, mw, 0, HEADER_H) }):Play()
			end)
			heightTween:Play()
		else
			-- Stage 1: slide back out to full width
			local widthTween = TweenService:Create(Frame, TweenMed,
				{ Size = UDim2.new(0, Width, 0, HEADER_H) })
			widthTween.Completed:Connect(function(state)
				if myToken ~= minimizeToken or state ~= Enum.PlaybackState.Completed then return end
				-- Stage 2: open back up normally
				setBodyVisible(true)
				TweenService:Create(Frame, TweenMed,
					{ Size = UDim2.new(0, Width, 0, FULL_H) }):Play()
			end)
			widthTween:Play()
		end
	end
	applyMinimize(true)

	local function SetMinimized(minimized)
		if isMinimized == minimized then return end
		isMinimized = minimized
		-- A search box has nowhere to live in a collapsed header.
		if minimized then SetSearchOpen(false) end
		applyMinimize(false)
	end

	MinBtn.MouseButton1Click:Connect(function()
		SetMinimized(not isMinimized)
	end)
	MinBtn.MouseEnter:Connect(function()
		TweenService:Create(MinBtn, TweenFast, { BackgroundColor3 = Theme.ToggleOn }):Play()
	end)
	MinBtn.MouseLeave:Connect(function()
		TweenService:Create(MinBtn, TweenFast, { BackgroundColor3 = AccentDim }):Play()
	end)

	-- ── Search ─────────────────────────────────────────────
	-- Rows are the direct children of each tab's scrolling frame. A row
	-- matches when any text inside it (its own label, a section title, a
	-- toggle's caption…) contains the query, case-insensitively. Rows the
	-- search hides are remembered so clearing it restores exactly those
	-- and never un-hides something the caller hid on purpose.
	local searchOpen   = false
	local searchHidden = {}   -- row -> true while hidden by the search

	local function rowMatches(row, q)
		local objs = row:GetDescendants()
		table.insert(objs, row)
		for _, d in ipairs(objs) do
			if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
				-- RichText labels carry markup; strip it so "<font" can't match.
				local plain = string.lower((string.gsub(d.Text, "<[^>]->", "")))
				if string.find(plain, q, 1, true) then return true end
			end
		end
		return false
	end

	local function applySearch(query)
		local q = string.lower(query or "")
		local hits = {}
		for i, sf in ipairs(tabFrames) do
			local n = 0
			for _, row in ipairs(sf:GetChildren()) do
				if row:IsA("GuiObject") then
					if q == "" or rowMatches(row, q) then
						if searchHidden[row] then
							row.Visible = true
							searchHidden[row] = nil
						end
						if row.Visible then n = n + 1 end
					elseif row.Visible then
						row.Visible = false
						searchHidden[row] = true
					end
				end
			end
			hits[i] = n
		end
		-- Nothing on the current tab but hits elsewhere: jump to the first
		-- tab that has some, so a search never looks like it found nothing.
		if q ~= "" and hasTabs and hits[activeTab] == 0 then
			for i, n in ipairs(hits) do
				if n > 0 then SetTab(i) break end
			end
		end
	end

	SetSearchOpen = function(open)
		if not SearchBtn then return end
		open = open == true
		if open == searchOpen then return end
		if open and isMinimized then SetMinimized(false) end
		searchOpen = open

		-- Only the title and subtitle give way to the box; the header
		-- icon stays put, like the pip does, so the window keeps its
		-- identity while you type.
		TitleLabel.Visible = not open
		if SubPill then SubPill.Visible = (not open) and plainSubTitle ~= "" end
		SearchBox.Visible = open
		SearchBox.Text    = ""
		TweenService:Create(SearchIcon, TweenFast,
			{ ImageColor3 = open and Theme.Accent or Theme.AccentSec }):Play()
		TweenService:Create(SearchBtn, TweenFast,
			{ BackgroundColor3 = open and Theme.ToggleOn or AccentDim }):Play()

		if open then
			-- Deferred: focusing in the same frame the box becomes visible
			-- is dropped by the engine.
			task.defer(function()
				if SearchBox.Parent and searchOpen then SearchBox:CaptureFocus() end
			end)
		else
			SearchBox:ReleaseFocus()
			applySearch("")
		end
	end

	if SearchBtn then
		SearchBtn.MouseButton1Click:Connect(function()
			SetSearchOpen(not searchOpen)
		end)
		SearchBtn.MouseEnter:Connect(function()
			TweenService:Create(SearchBtn, TweenFast, { BackgroundColor3 = Theme.ToggleOn }):Play()
		end)
		SearchBtn.MouseLeave:Connect(function()
			if searchOpen then return end
			TweenService:Create(SearchBtn, TweenFast, { BackgroundColor3 = AccentDim }):Play()
		end)
		SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
			if searchOpen then applySearch(SearchBox.Text) end
		end)
		-- Escape closes and clears. Enter or clicking away keeps the
		-- filter in place so the user can interact with what they found.
		SearchBox.FocusLost:Connect(function(enterPressed, inp)
			if typeof(inp) == "Instance" and inp:IsA("InputObject")
			and inp.KeyCode == Enum.KeyCode.Escape then
				SetSearchOpen(false)
			end
		end)
	end

	-- ── Resize grip (optional, off by default) ─────────────
	-- Options.Scaler = true adds a small grip in the bottom-right corner.
	-- Dragging it resizes the panel between MinSize and MaxSize (each axis
	-- clamped on its own; defaults are half and double the initial size).
	-- Width / FULL_H are rebound on every change, so minimize/restore and
	-- the title layout keep working at the new size.
	local SCALE_ICON_ID = "rbxassetid://122360365318466"   -- lucide "scaling"

	local function sizePair(v)
		if typeof(v) == "Vector2" then return v.X, v.Y end
		if typeof(v) == "UDim2"   then return v.X.Offset, v.Y.Offset end
		if type(v) == "table" then
			return v[1] or v.X or v.Width or v.w, v[2] or v.Y or v.Height or v.h
		end
		return nil, nil
	end
	local minSizeW, minSizeH = sizePair(Options.MinSize)
	local maxSizeW, maxSizeH = sizePair(Options.MaxSize)
	local MIN_W = Options.MinWidth  or minSizeW or math.floor(Width  / 2)
	local MIN_H = Options.MinHeight or minSizeH or math.floor(FULL_H / 2)
	local MAX_W = Options.MaxWidth  or maxSizeW or Width  * 2
	local MAX_H = Options.MaxHeight or maxSizeH or FULL_H * 2
	-- The body can never collapse past the header and tab bar.
	MIN_H = math.max(MIN_H, HEADER_H + TABBAR_H + 24)
	MIN_W = math.max(MIN_W, 90)
	MAX_W = math.max(MAX_W, MIN_W)
	MAX_H = math.max(MAX_H, MIN_H)

	-- Re-derives everything that was sized from Width at build time.
	local function relayoutForSize()
		layoutTitle()
		if hasTabs and not sideTabs and TabBtns then
			tabW = (Width - 20 - tabGap * (#Tabs - 1)) / #Tabs
			for _, btn in ipairs(TabBtns) do
				btn.Size = UDim2.new(0, tabW, 1, 0)
			end
			if TabInd then
				TabInd.Size     = UDim2.new(0, math.floor(tabW), 0, 2)
				TabInd.Position = tabIndicatorTarget(activeTab)
			end
		end
	end

	local function SetSize(w, h)
		w = math.floor(tonumber(w) or Width)
		h = math.floor(tonumber(h) or FULL_H)
		if showScaler then
			w = math.clamp(w, MIN_W, MAX_W)
			h = math.clamp(h, MIN_H, MAX_H)
		end
		Width  = w
		FULL_H = h
		if not isMinimized then
			Frame.Size = UDim2.new(0, Width, 0, FULL_H)
		end
		relayoutForSize()
	end

	if showScaler then
		ScaleBtn = Instance.new("ImageButton")
		ScaleBtn.Name                   = "SkibidiResizeGrip"
		ScaleBtn.Size                   = UDim2.new(0, 16, 0, 16)
		ScaleBtn.AnchorPoint            = Vector2.new(1, 1)
		ScaleBtn.Position               = UDim2.new(1, -5, 1, -5)
		ScaleBtn.BackgroundTransparency = 1
		ScaleBtn.Image                  = SCALE_ICON_ID
		ScaleBtn.ImageColor3            = Theme.TextMuted
		ScaleBtn.ImageTransparency      = 0.25
		ScaleBtn.AutoButtonColor        = false
		ScaleBtn.ZIndex                 = 8
		ScaleBtn.Visible                = not isMinimized
		ScaleBtn.Parent                 = Frame

		local resizing, resizeStart, startW, startH = false, nil, 0, 0
		local function restGrip()
			if resizing then return end
			TweenService:Create(ScaleBtn, TweenFast,
				{ ImageColor3 = Theme.TextMuted, ImageTransparency = 0.25 }):Play()
		end
		ScaleBtn.MouseEnter:Connect(function()
			TweenService:Create(ScaleBtn, TweenFast,
				{ ImageColor3 = Accent, ImageTransparency = 0 }):Play()
		end)
		ScaleBtn.MouseLeave:Connect(restGrip)
		ScaleBtn.InputBegan:Connect(function(inp)
			if inp.UserInputType ~= Enum.UserInputType.MouseButton1
			and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			if isMinimized then return end
			resizing    = true
			resizeStart = inp.Position
			startW, startH = Width, FULL_H
			TweenService:Create(ScaleBtn, TweenFast,
				{ ImageColor3 = Accent, ImageTransparency = 0 }):Play()
		end)
		ConnectScoped(Gui, UserInputService.InputEnded, function(inp)
			if not resizing then return end
			if inp.UserInputType ~= Enum.UserInputType.MouseButton1
			and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			resizing = false
			restGrip()
		end)
		ConnectScoped(Gui, UserInputService.InputChanged, function(inp)
			if not resizing then return end
			if inp.UserInputType ~= Enum.UserInputType.MouseMovement
			and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			local d = inp.Position - resizeStart
			SetSize(startW + d.X, startH + d.Y)
		end)
	end

	-- ── Closing ────────────────────────────────────────────
	-- Fade helpers: every transparency-bearing descendant remembers its
	-- resting value so the whole tree can be faded out (t = 1) and back
	-- in (t = 0) without a per-element special case.
	local function CollectFade(root, extra)
		local list = {}
		local function add(o)
			if o:IsA("UIStroke") then
				list[#list+1] = { o, "Transparency", o.Transparency }
			elseif o:IsA("GuiObject") then
				list[#list+1] = { o, "BackgroundTransparency", o.BackgroundTransparency }
				if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
					list[#list+1] = { o, "TextTransparency", o.TextTransparency }
				end
				if o:IsA("ImageLabel") or o:IsA("ImageButton") then
					list[#list+1] = { o, "ImageTransparency", o.ImageTransparency }
				end
				if o:IsA("ScrollingFrame") then
					list[#list+1] = { o, "ScrollBarImageTransparency", o.ScrollBarImageTransparency }
				end
			end
		end
		add(root)
		for _, d in ipairs(root:GetDescendants()) do add(d) end
		for _, o in ipairs(extra or {}) do add(o) end
		return list
	end
	local function FadeTo(list, t, info)
		for _, e in ipairs(list) do
			local obj, prop, rest = e[1], e[2], e[3]
			local v = rest + (1 - rest) * t
			if info then
				TweenService:Create(obj, info, { [prop] = v }):Play()
			else
				obj[prop] = v
			end
		end
	end

	local TweenCloseOut = TweenInfo.new(0.26, Enum.EasingStyle.Back,  Enum.EasingDirection.In)
	local TweenFadeOut  = TweenInfo.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
	local TweenDlgOut   = TweenInfo.new(0.16, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)

	local closing = false
	-- Shrinks the panel back the way it arrived, fades everything (shadow
	-- and bloom included) and only then destroys the ScreenGui.
	local function CloseWindow()
		if closing or not Gui or not Gui.Parent then return end
		closing = true
		local extra = {}
		for _, L in ipairs(shadowLayers) do extra[#extra+1] = L.Obj end
		if Bloom then extra[#extra+1] = Bloom end
		local fade = CollectFade(Frame, extra)
		FadeTo(fade, 1, TweenFadeOut)
		TweenService:Create(OpenScale, TweenCloseOut, { Scale = 0.86 }):Play()
		for _, L in ipairs(shadowLayers) do
			TweenService:Create(L.Scale, TweenCloseOut, { Scale = 0.86 }):Play()
		end
		task.delay(0.28, function()
			if Gui then Gui:Destroy() end
		end)
	end

	-- "Are you sure?" dialog. A dimmer covers just the panel (mirroring
	-- its position, size and corner radius, and eating clicks meant for
	-- it) while a small card pops in over the middle. Escape / clicking
	-- the dimmer cancels, Return confirms.
	local confirmOpen = false
	local function ConfirmClose()
		if closing or confirmOpen then return end
		confirmOpen = true

		-- The dimmer is a sibling of the panel (not a child) so a card
		-- taller than a minimized panel can still hang past its edges.
		local Dim = Instance.new("Frame")
		Dim.Name                   = "SkibidiCloseDim"
		Dim.Position               = Frame.Position
		Dim.Size                   = Frame.Size
		Dim.BackgroundColor3       = Color3.new(0, 0, 0)
		Dim.BackgroundTransparency = 1
		Dim.BorderSizePixel        = 0
		Dim.Active                 = true
		Dim.ZIndex                 = 100
		Dim.Parent                 = Gui
		MakeCorner(Dim, UDim.new(0, Theme.CornerRadius))
		local dimPosConn = Frame:GetPropertyChangedSignal("Position"):Connect(function()
			Dim.Position = Frame.Position
		end)
		local dimSizeConn = Frame:GetPropertyChangedSignal("Size"):Connect(function()
			Dim.Size = Frame.Size
		end)

		-- Holder carries the anchor and the pop scale so the card itself
		-- (and the glow MakeGlow hangs off it) can stay top-left anchored.
		local CARD_W, CARD_H = 250, 118
		local Holder = Instance.new("Frame")
		Holder.Size                   = UDim2.new(0, CARD_W, 0, CARD_H)
		Holder.AnchorPoint            = Vector2.new(0.5, 0.5)
		Holder.Position               = UDim2.new(0.5, 0, 0.5, 0)
		Holder.BackgroundTransparency = 1
		Holder.ZIndex                 = 100
		Holder.Parent                 = Dim

		local CardScale = Instance.new("UIScale")
		CardScale.Scale  = 0.82
		CardScale.Parent = Holder

		local Card = Instance.new("Frame")
		Card.Size                   = UDim2.new(1, 0, 1, 0)
		Card.BackgroundColor3       = Theme.Bg1
		Card.BackgroundTransparency = 0.02
		Card.BorderSizePixel        = 0
		Card.Active                 = true
		Card.ZIndex                 = 101
		Card.Parent                 = Holder
		MakeCorner(Card, UDim.new(0, Theme.CornerRadius))
		MakeEdge(Card, Theme.Danger, 1.2, 0.35)
		MakeGloss(Card, 0.14)
		MakeGrain(Card)
		local CardGlow = MakeGlow(Card, Theme.Danger, 14, 0.84)
		if CardGlow then CardGlow.ZIndex = 100 end

		local Title = Instance.new("TextLabel")
		Title.Size                   = UDim2.new(1, -28, 0, 18)
		Title.Position               = UDim2.new(0, 14, 0, 14)
		Title.BackgroundTransparency = 1
		Title.Font                   = Theme.FontBold
		Title.TextSize               = Theme.TitleSize
		Title.TextColor3             = Theme.TextPrimary
		Title.TextXAlignment         = Enum.TextXAlignment.Left
		Title.Text                   = Options.CloseTitle or "Close panel?"
		Title.ZIndex                 = 102
		Title.Parent                 = Card

		local Body = Instance.new("TextLabel")
		Body.Size                   = UDim2.new(1, -28, 0, 30)
		Body.Position               = UDim2.new(0, 14, 0, 34)
		Body.BackgroundTransparency = 1
		Body.Font                   = Theme.FontRegular
		Body.TextSize               = Theme.SmallSize
		Body.TextColor3             = Theme.TextMuted
		Body.TextWrapped            = true
		Body.TextXAlignment         = Enum.TextXAlignment.Left
		Body.TextYAlignment         = Enum.TextYAlignment.Top
		Body.Text                   = Options.CloseMessage
			or "Are you sure? Everything in this window will be closed."
		Body.ZIndex                 = 102
		Body.Parent                 = Card

		local function MakeDialogButton(text, x, w, bg, bgAlpha, fg, edge)
			local B = Instance.new("TextButton")
			B.Size                   = UDim2.new(0, w, 0, 28)
			B.AnchorPoint            = Vector2.new(1, 1)
			B.Position               = UDim2.new(1, x, 1, -12)
			B.BackgroundColor3       = bg
			B.BackgroundTransparency = bgAlpha
			B.BorderSizePixel        = 0
			B.Font                   = Theme.FontMedium
			B.TextSize               = Theme.SmallSize
			B.TextColor3             = fg
			B.Text                   = text
			B.AutoButtonColor        = false
			B.ZIndex                 = 102
			B.Parent                 = Card
			MakeCorner(B, UDim.new(0, Theme.CornerRadiusSmall))
			MakeEdge(B, edge, 1, 0.5)
			MakeGloss(B, 0.16)
			MakeRipple(B, fg, 8)
			local sc = Instance.new("UIScale")
			sc.Parent = B
			B.MouseEnter:Connect(function()
				TweenService:Create(sc, TweenFast, { Scale = 1.04 }):Play()
				TweenService:Create(B, TweenFast, { BackgroundTransparency = math.max(bgAlpha - 0.15, 0) }):Play()
			end)
			B.MouseLeave:Connect(function()
				TweenService:Create(sc, TweenFast, { Scale = 1 }):Play()
				TweenService:Create(B, TweenFast, { BackgroundTransparency = bgAlpha }):Play()
			end)
			B.MouseButton1Down:Connect(function()
				TweenService:Create(sc, TweenSnap, { Scale = 0.94 }):Play()
			end)
			B.MouseButton1Up:Connect(function()
				TweenService:Create(sc, TweenPop, { Scale = 1 }):Play()
			end)
			return B
		end

		local YesBtn = MakeDialogButton("Close",  -14,        76, Theme.Danger, 0.12, Color3.new(1, 1, 1), Theme.Danger)
		local NoBtn  = MakeDialogButton("Cancel", -14 - 76 - 6, 76, Theme.Bg2, 0, Theme.TextPrimary, Accent)

		-- Pop in: dimmer darkens, card scales up from 0.82 while its
		-- contents fade in from fully transparent.
		local fade = CollectFade(Card, CardGlow and { CardGlow } or nil)
		FadeTo(fade, 1)
		TweenService:Create(Dim, TweenMed, { BackgroundTransparency = 0.45 }):Play()
		TweenService:Create(CardScale, TweenPop, { Scale = 1 }):Play()
		FadeTo(fade, 0, TweenMed)

		local keyConn
		local function Dismiss(confirmed)
			if not confirmOpen then return end
			confirmOpen = false
			if keyConn then keyConn:Disconnect(); keyConn = nil end
			dimPosConn:Disconnect()
			dimSizeConn:Disconnect()
			TweenService:Create(Dim, TweenDlgOut, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(CardScale, TweenDlgOut, { Scale = 0.88 }):Play()
			FadeTo(fade, 1, TweenDlgOut)
			task.delay(0.18, function() if Dim.Parent then Dim:Destroy() end end)
			if confirmed then CloseWindow() end
		end

		YesBtn.MouseButton1Click:Connect(function() Dismiss(true) end)
		NoBtn.MouseButton1Click:Connect(function() Dismiss(false) end)
		Dim.InputBegan:Connect(function(inp)
			if inp.UserInputType ~= Enum.UserInputType.MouseButton1
			and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			local p, s = Card.AbsolutePosition, Card.AbsoluteSize
			local x, y = inp.Position.X, inp.Position.Y
			if x < p.X or x > p.X + s.X or y < p.Y or y > p.Y + s.Y then
				Dismiss(false)
			end
		end)
		keyConn = ConnectScoped(Gui, UserInputService.InputBegan, function(inp, gp)
			if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
			if inp.KeyCode == Enum.KeyCode.Escape then
				Dismiss(false)
			elseif inp.KeyCode == Enum.KeyCode.Return and not gp then
				Dismiss(true)
			end
		end)
	end

	-- Options.ConfirmClose = false skips the dialog and closes on click.
	CloseBtn.MouseButton1Click:Connect(function()
		if Options.ConfirmClose == false then CloseWindow() else ConfirmClose() end
	end)
	CloseBtn.MouseEnter:Connect(function()
		TweenService:Create(CloseBtn, TweenFast, { BackgroundColor3 = Color3.fromRGB(200, 60, 60) }):Play()
	end)
	CloseBtn.MouseLeave:Connect(function()
		TweenService:Create(CloseBtn, TweenFast, { BackgroundColor3 = AccentDim }):Play()
	end)

	-- ── Dragging ───────────────────────────────────────────
	do
		local clampToScreen = Options.ClampToScreen == true
		local dragging, dragStart, startPos = false, nil, nil
		Header.InputBegan:Connect(function(inp)
			if inp.UserInputType ~= Enum.UserInputType.MouseButton1
			and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			dragging  = true
			dragStart = inp.Position
			startPos  = Frame.Position
			inp.Changed:Connect(function()
				if inp.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end)
		-- Scoped: the service-level connection dies with the panel's Gui
		-- instead of leaking after Close().
		ConnectScoped(Gui, UserInputService.InputChanged, function(inp)
			if not dragging then return end
			if inp.UserInputType ~= Enum.UserInputType.MouseMovement
			and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			local d = inp.Position - dragStart
			local pos = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
			if clampToScreen then
				local screen = Gui.AbsoluteSize
				local fw, fh = Frame.AbsoluteSize.X, Frame.AbsoluteSize.Y
				local absX = math.clamp(pos.X.Scale * screen.X + pos.X.Offset, 0, math.max(0, screen.X - fw))
				local absY = math.clamp(pos.Y.Scale * screen.Y + pos.Y.Offset, 0, math.max(0, screen.Y - fh))
				pos = UDim2.new(
					pos.X.Scale, absX - pos.X.Scale * screen.X,
					pos.Y.Scale, absY - pos.Y.Scale * screen.Y)
			end
			Frame.Position = pos
		end)
	end

	-- ── Visibility (programmatic + optional hotkey) ────────
	local function SetVisible(visible)
		Gui.Enabled = visible == true
	end
	local function ToggleVisible()
		Gui.Enabled = not Gui.Enabled
	end
	do
		local tk = Options.ToggleKey
		if type(tk) == "string" then
			local ok, parsed = pcall(function() return Enum.KeyCode[tk] end)
			tk = ok and parsed or nil
		end
		if typeof(tk) == "EnumItem" then
			ConnectScoped(Gui, UserInputService.InputBegan, function(inp, gameProcessed)
				if gameProcessed then return end
				if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == tk then
					ToggleVisible()
				end
			end)
		end
	end

	-- Swaps the header icon at runtime. Passing nil brings the pip back.
	-- TITLE_X is an upvalue of layoutTitle / computeMinimizedWidth, so
	-- re-assigning it here is enough for those; only the things sized
	-- from it at build time need touching by hand.
	local function SetTitleIcon(spec)
		if spec == nil or spec == "" then
			if TitleIcon then TitleIcon:Destroy() end
			TitleIcon        = nil
			TitlePip.Visible = true
			TITLE_X          = TITLE_X_PIP
		else
			if not TitleIcon then
				TitleIcon = MakeIcon(Header, spec, TITLE_ICON, Theme.AccentSec, 3)
				TitleIcon.Name        = "SkibidiTitleIcon"
				TitleIcon.AnchorPoint = Vector2.new(0, 0.5)
				TitleIcon.Position    = UDim2.new(0, 11, 0.5, 0)
			else
				SetIconImage(TitleIcon, spec)
			end
			TitlePip.Visible = false
			TITLE_X          = TITLE_X_ICON
		end
		TitleLabel.Position = UDim2.new(0, TITLE_X, 0, 0)
		if SearchBox then
			SearchBox.Position = UDim2.new(0, TITLE_X, 0.5, 0)
			SearchBox.Size     = UDim2.new(1, -(reservedRight + TITLE_X), 0, 22)
		end
		layoutTitle()
		if isMinimized then
			Frame.Size = UDim2.new(0, computeMinimizedWidth(), 0, HEADER_H)
		end
	end

	-- ── Return ─────────────────────────────────────────────
	return {
		Gui          = Gui,
		Frame        = Frame,
		Header       = Header,
		TitleLabel   = TitleLabel,
		GetTitleIcon = function() return TitleIcon end,
		SetIcon      = SetTitleIcon,
		SetTabIcon   = makeTabIcon,
		GetTabIcon   = function(i) return tabIcons[i] end,
		-- Content is the first (or only) tab frame for convenience
		Content      = tabFrames[1],
		GetTab       = function(i) return tabFrames[i] end,
		SetTab       = SetTab,
		GetActiveTab = function() return activeTab end,
		GetTabButton = function(i) return TabBtns and TabBtns[i] end,
		SetTitle     = function(t)
			plainTitle      = t or ""
			TitleLabel.Text = plainTitle
			layoutTitle()
			if isMinimized then
				Frame.Size = UDim2.new(0, computeMinimizedWidth(), 0, HEADER_H)
			end
		end,
		SetSubTitle  = function(t)
			if not SubLabel then return end
			plainSubTitle  = t or ""
			SubLabel.Text  = plainSubTitle
			SubPill.Visible = plainSubTitle ~= ""
			layoutTitle()
			if isMinimized then
				Frame.Size = UDim2.new(0, computeMinimizedWidth(), 0, HEADER_H)
			end
		end,
		SetMinimized = SetMinimized,
		IsMinimized  = function() return isMinimized end,
		SetVisible   = SetVisible,
		ToggleVisible = ToggleVisible,
		IsVisible    = function() return Gui.Enabled end,
		CloseBtn     = CloseBtn,
		Close        = CloseWindow,   -- animated, no prompt
		ConfirmClose = ConfirmClose,  -- opens the "are you sure?" dialog
		DiscordBtn   = DiscordBtn,
		SearchBtn    = SearchBtn,
		SetSearchOpen = SetSearchOpen,
		IsSearchOpen = function() return searchOpen end,
		SetSearch    = function(text)
			if not SearchBox then return end
			SetSearchOpen(true)
			SearchBox.Text = tostring(text or "")
		end,
		ScaleBtn     = ScaleBtn,
		SetSize      = SetSize,
		GetSize      = function() return Width, FULL_H end,
		Accent       = Accent,
		AccentDim    = AccentDim,
	}
end

-- ============================================================
-- CreateSection
-- A collapsible section group with a clickable header.
-- Children added to the returned .Content frame will be
-- shown/hidden when the header is clicked.
--
-- Options:
--   Title     string   Section label
--   Icon      string   Lucide icon before the label (optional)
--   Open      bool     Start open (default false)
--   Tooltip   string   Hover tooltip (optional)
--
-- Returns:
--   { Frame, Content, SetOpen(bool), IsOpen(), SetTitle(text), SetIcon(spec) }
-- ============================================================
function Skibidi.CreateSection(Parent, Options)
	Options = Options or {}
	local title    = Options.Title or ""
	local startOpen = Options.Open == true  -- default false

	-- Outer wrapper — AutomaticSize so it grows with content
	local Wrapper = Instance.new("Frame")
	Wrapper.Size             = UDim2.new(1, 0, 0, 0)
	Wrapper.AutomaticSize    = Enum.AutomaticSize.Y
	Wrapper.BackgroundColor3 = Theme.Bg2
	Wrapper.BorderSizePixel  = 0
	Wrapper.ClipsDescendants = true
	Wrapper.Parent           = Parent
	MakeCorner(Wrapper, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Wrapper, Theme.AccentDim, 1)
	MakeGloss(Wrapper, 0.09)

	local WrapLayout = Instance.new("UIListLayout", Wrapper)
	WrapLayout.Padding    = UDim.new(0, 0)
	WrapLayout.SortOrder  = Enum.SortOrder.LayoutOrder
	WrapLayout.FillDirection = Enum.FillDirection.Vertical
	-- Center children so the inset divider (1, -16) gets an even 8px
	-- margin on both sides instead of hugging the left edge.
	WrapLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	-- Header row (clickable)
	local HeaderRow = Instance.new("TextButton")
	HeaderRow.Size                   = UDim2.new(1, 0, 0, 34)
	HeaderRow.LayoutOrder            = 0
	HeaderRow.BackgroundTransparency = 1
	HeaderRow.BorderSizePixel        = 0
	HeaderRow.Text                   = ""
	HeaderRow.AutoButtonColor        = false
	HeaderRow.Parent                 = Wrapper
	MakeHoverFill(HeaderRow, 3, 5)

	-- Accent bar
	local AccentBar = Instance.new("Frame", HeaderRow)
	AccentBar.AnchorPoint      = Vector2.new(0, 0.5)
	AccentBar.Size             = UDim2.new(0, 3, 0, 12)
	AccentBar.Position         = UDim2.new(0, 8, 0.5, 0)
	AccentBar.BackgroundColor3 = Theme.Accent
	AccentBar.BorderSizePixel  = 0
	AccentBar.ZIndex           = 2
	MakeCorner(AccentBar, UDim.new(1, 0))
	MakeAccentFill(AccentBar, Theme.Accent)

	local TitleLbl = Instance.new("TextLabel", HeaderRow)
	TitleLbl.Size                   = UDim2.new(1, -50, 1, 0)
	TitleLbl.Position               = UDim2.new(0, 18, 0, 0)
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.Font                   = Theme.FontMedium
	TitleLbl.TextSize               = Theme.SmallSize + 1
	TitleLbl.TextColor3             = Theme.Accent
	TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	TitleLbl.Text                   = title

	local SecIcon = Options.Icon and PrefixIcon(TitleLbl, Options.Icon, 14, Theme.Accent) or nil

	-- Arrow indicator
	local Arrow = Instance.new("TextLabel", HeaderRow)
	Arrow.Size                   = UDim2.new(0, 20, 1, 0)
	Arrow.Position               = UDim2.new(1, -24, 0, 0)
	Arrow.BackgroundTransparency = 1
	Arrow.Font                   = Theme.FontIcon
	Arrow.TextSize               = 14
	Arrow.TextColor3             = Theme.AccentDim
	Arrow.TextXAlignment         = Enum.TextXAlignment.Center
	Arrow.Text                   = "▼"

	-- Divider below header
	local Divider = Instance.new("Frame", Wrapper)
	Divider.Size             = UDim2.new(1, -16, 0, 1)
	Divider.Position         = UDim2.new(0, 8, 0, 34)
	Divider.BackgroundColor3 = Theme.Accent
	Divider.BackgroundTransparency = 0.35
	Divider.BorderSizePixel  = 0
	Divider.LayoutOrder      = 1
	do
		local g = Instance.new("UIGradient", Divider)
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1),
			NumberSequenceKeypoint.new(0.15, 0.25),
			NumberSequenceKeypoint.new(0.85, 0.25),
			NumberSequenceKeypoint.new(1.00, 1),
		})
	end

	-- Content frame
	local Content = Instance.new("Frame", Wrapper)
	Content.Size              = UDim2.new(1, 0, 0, 0)
	Content.AutomaticSize     = Enum.AutomaticSize.Y
	Content.BackgroundTransparency = 1
	Content.BorderSizePixel   = 0
	Content.LayoutOrder       = 2
	Content.ClipsDescendants  = false
	MakePadding(Content, 8, 8, 6, 8)
	MakeListLayout(Content, Enum.FillDirection.Vertical, 6)

	-- Open/close state
	local isOpen = startOpen
	local function SetOpen(open)
		isOpen = open
		Content.Visible  = open
		Divider.Visible  = open
		TweenService:Create(Arrow, TweenMed,
			{ Rotation   = open and 180 or 0,
			  TextColor3 = open and Theme.Accent or Theme.AccentDim }):Play()
		-- The accent bar stretching to full height is the cue that reads
		-- from across the panel, well before the small chevron does.
		TweenService:Create(AccentBar, TweenSpring,
			{ Size = UDim2.new(0, 3, 0, open and 18 or 12) }):Play()
		TweenService:Create(TitleLbl, TweenFast,
			{ TextColor3 = open and Theme.AccentSec or Theme.Accent }):Play()
		if SecIcon then
			TweenService:Create(SecIcon, TweenFast,
				{ ImageColor3 = open and Theme.AccentSec or Theme.Accent }):Play()
		end
	end
	SetOpen(startOpen)

	HeaderRow.MouseButton1Click:Connect(function()
		SetOpen(not isOpen)
	end)
	AttachTooltip(HeaderRow, Options.Tooltip)

	return {
		Frame    = Wrapper,
		Content  = Content,
		SetOpen  = SetOpen,
		IsOpen   = function() return isOpen end,
		SetTitle = function(t) TitleLbl.Text = t or "" end,
		SetIcon  = function(spec)
			if SecIcon then
				SetIconImage(SecIcon, spec)
			elseif spec and spec ~= "" then
				SecIcon = PrefixIcon(TitleLbl, spec, 14, TitleLbl.TextColor3)
			end
		end,
		Icon     = SecIcon,
	}
end

-- ============================================================
-- CreateButton
-- A full-width row button with hover tween.
--
-- Options:
--   Text        string
--   Color       Color3   Background  (default Theme.Bg2)
--   TextColor   Color3               (default Theme.TextPrimary)
--   Height      number               (default 34)
--   OnClick     function
--   Tooltip     string   Hover tooltip (optional)
--   Confirm     bool     First click arms the button ("Confirm?"),
--                        second click within 2s fires OnClick
--   ConfirmText string   Armed label (default "Confirm?")
--   Icon        string   Lucide icon left of the label (optional)
--   IconColor   Color3   Resting icon colour (default TextColor)
--
-- Returns: { Frame, Button, SetText(text), SetDisabled(bool), SetIcon(spec) }
-- ============================================================
function Skibidi.CreateButton(Parent, Options)
	Options = Options or {}

	local RowBg = Instance.new("Frame")
	RowBg.Size             = UDim2.new(1, 0, 0, Options.Height or 34)
	RowBg.BackgroundColor3 = Options.Color or Theme.Bg2
	RowBg.BorderSizePixel  = 0
	RowBg.Parent           = Parent
	local RowRadius = Theme.CornerRadiusSmall
	MakeCorner(RowBg, UDim.new(0, RowRadius))
	local RowEdge = MakeEdge(RowBg, Theme.AccentDim, 1)
	MakeGloss(RowBg, 0.12)
	local RowGlow = MakeInnerGlow(RowBg, Theme.Accent, 12, 1)

	local Btn = Instance.new("TextButton")
	Btn.Size                   = UDim2.new(1, 0, 1, 0)
	-- Centered anchor so the hover/press UIScale below scales the label
	-- symmetrically about the middle of the row.
	Btn.AnchorPoint            = Vector2.new(0.5, 0.5)
	Btn.Position               = UDim2.new(0.5, 0, 0.5, 0)
	Btn.BackgroundTransparency = 1
	Btn.BorderSizePixel        = 0
	Btn.Font                   = Theme.FontRegular
	Btn.TextSize               = Theme.BodySize
	Btn.TextColor3             = Options.TextColor or Theme.TextPrimary
	Btn.TextXAlignment         = Enum.TextXAlignment.Center
	Btn.Text                   = Options.Text or ""
	Btn.AutoButtonColor        = false
	Btn.Parent                 = RowBg

	-- The two decorations that do the most work on a button: a ripple
	-- from the exact click point, and a light sweep on hover. Both stay
	-- inside their own layer, so neither crops the row's stroke nor
	-- spills past the row's edges.
	MakeRipple(Btn, Theme.Accent, RowRadius)
	local playShine = MakeShine(Btn, RowRadius, RowBg)

	-- Optional icon riding just left of the centred label. Added after
	-- the ripple so InlineIcon can widen the ripple host past the
	-- padding it introduces.
	local iconRest = Options.IconColor or Options.TextColor or Theme.TextPrimary
	local BtnIcon
	if Options.Icon then
		BtnIcon = InlineIcon(Btn, Options.Icon, Options.IconSize or 14, iconRest, 6)
	end

	-- A hairline that grows out of the centre on hover. It gives the row
	-- a focal point, which a uniform background tint never does.
	local Underline = Instance.new("Frame")
	Underline.AnchorPoint      = Vector2.new(0.5, 1)
	Underline.Position         = UDim2.new(0.5, 0, 1, -1)
	Underline.Size             = UDim2.new(0, 0, 0, 2)
	Underline.BackgroundColor3 = Theme.Accent
	Underline.BorderSizePixel  = 0
	Underline.ZIndex           = 3
	Underline.Parent           = RowBg
	MakeCorner(Underline, UDim.new(1, 0))
	MakeAccentFill(Underline, Theme.Accent)

	local BtnScale = Instance.new("UIScale")
	BtnScale.Parent = Btn

	local restColor  = Options.Color or Theme.Bg2
	local hoverColor = Color3.fromRGB(
		math.min(restColor.R * 255 + 14, 255) / 255,
		math.min(restColor.G * 255 + 14, 255) / 255,
		math.min(restColor.B * 255 + 14, 255) / 255)
	local pressColor = Color3.fromRGB(
		math.max(restColor.R * 255 - 8, 0) / 255,
		math.max(restColor.G * 255 - 8, 0) / 255,
		math.max(restColor.B * 255 - 8, 0) / 255)

	local disabled = false

	Btn.MouseEnter:Connect(function()
		if disabled then return end
		TweenService:Create(RowBg,     TweenFast, { BackgroundColor3 = hoverColor }):Play()
		TweenService:Create(Btn,       TweenFast, { TextColor3 = Theme.Accent }):Play()
		if BtnIcon then TweenService:Create(BtnIcon, TweenFast, { ImageColor3 = Theme.Accent }):Play() end
		TweenService:Create(BtnScale,  TweenFast, { Scale = 1.02 }):Play()
		TweenService:Create(RowEdge,   TweenFast, { Color = Theme.Accent, Transparency = 0.05 }):Play()
		TweenService:Create(Underline, TweenSpring, { Size = UDim2.new(0.5, 0, 0, 2) }):Play()
		if RowGlow then RowGlow.SetAlpha(0.78, TweenMed) end
	end)
	Btn.MouseLeave:Connect(function()
		if disabled then return end
		TweenService:Create(RowBg,     TweenFast, { BackgroundColor3 = restColor }):Play()
		TweenService:Create(Btn,       TweenFast, { TextColor3 = Options.TextColor or Theme.TextPrimary }):Play()
		if BtnIcon then TweenService:Create(BtnIcon, TweenFast, { ImageColor3 = iconRest }):Play() end
		TweenService:Create(BtnScale,  TweenFast, { Scale = 1 }):Play()
		TweenService:Create(RowEdge,   TweenFast, { Color = EdgeRest(), Transparency = Theme.StrokeAlpha or 0.34 }):Play()
		TweenService:Create(Underline, TweenFast, { Size = UDim2.new(0, 0, 0, 2) }):Play()
		if RowGlow then RowGlow.SetAlpha(1, TweenMed) end
	end)
	-- Press feedback: dip below rest colour + shrink slightly on press,
	-- release back to the hover state
	Btn.MouseButton1Down:Connect(function()
		if disabled then return end
		TweenService:Create(RowBg,    TweenSnap, { BackgroundColor3 = pressColor }):Play()
		TweenService:Create(BtnScale, TweenSnap, { Scale = 0.97 }):Play()
	end)
	Btn.MouseButton1Up:Connect(function()
		if disabled then return end
		TweenService:Create(RowBg,    TweenFast,   { BackgroundColor3 = hoverColor }):Play()
		TweenService:Create(BtnScale, TweenSpring, { Scale = 1.02 }):Play()
		-- Re-firing the sweep on release confirms the click landed even
		-- when the handler itself has nothing visible to show for it.
		playShine()
	end)

	-- Confirm mode: first click arms, second click (within 2s) fires.
	local armed, armToken = false, 0
	local baseText = Options.Text or ""
	local function disarm()
		armed = false
		armToken = armToken + 1
		Btn.Text = baseText
		TweenService:Create(RowEdge, TweenFast,
			{ Color = EdgeRest(), Transparency = Theme.StrokeAlpha or 0.34 }):Play()
		TweenService:Create(Underline, TweenFast, { Size = UDim2.new(0, 0, 0, 2) }):Play()
		if BtnIcon then TweenService:Create(BtnIcon, TweenFast, { ImageColor3 = iconRest }):Play() end
	end

	Btn.MouseButton1Click:Connect(function()
		if disabled then return end
		if Options.Confirm and not armed then
			armed = true
			armToken = armToken + 1
			local myToken = armToken
			Btn.Text = Options.ConfirmText or "Confirm?"
			TweenService:Create(Btn, TweenFast, { TextColor3 = Theme.Warning }):Play()
			if BtnIcon then TweenService:Create(BtnIcon, TweenFast, { ImageColor3 = Theme.Warning }):Play() end
			TweenService:Create(RowEdge, TweenFast,
				{ Color = Theme.Warning, Transparency = 0 }):Play()
			TweenService:Create(Underline, TweenSpring,
				{ Size = UDim2.new(0.8, 0, 0, 2) }):Play()
			task.delay(2, function()
				if armed and myToken == armToken and Btn.Parent then disarm() end
			end)
			return
		end
		if armed then disarm() end
		if Options.OnClick then Options.OnClick() end
	end)

	AttachTooltip(RowBg, Options.Tooltip)
	PlayEntrance(RowBg)

	local function SetDisabled(on)
		disabled = on == true
		if armed then disarm() end
		TweenService:Create(Btn,   TweenFast, { TextTransparency = disabled and 0.55 or 0 }):Play()
		if BtnIcon then TweenService:Create(BtnIcon, TweenFast, { ImageTransparency = disabled and 0.55 or 0 }):Play() end
		TweenService:Create(RowBg, TweenFast, { BackgroundColor3 = restColor }):Play()
		TweenService:Create(RowEdge, TweenFast, {
			Transparency = disabled and 0.75 or (Theme.StrokeAlpha or 0.34),
			Color        = EdgeRest(),
		}):Play()
		Underline.Size = UDim2.new(0, 0, 0, 2)
	end

	return {
		Frame       = RowBg,
		Button      = Btn,
		SetText     = function(t) baseText = t or ""; if not armed then Btn.Text = baseText end end,
		SetDisabled = SetDisabled,
		SetIcon     = function(spec)
			if BtnIcon then
				SetIconImage(BtnIcon, spec)
			elseif spec and spec ~= "" then
				BtnIcon = InlineIcon(Btn, spec, Options.IconSize or 14, iconRest, 6)
			end
		end,
		Icon        = BtnIcon,
	}
end

-- ============================================================
-- CreateToggle
-- A labeled row with an animated toggle switch on the right.
--
-- Options:
--   Label        string
--   Default      bool     Initial state (default false)
--   OnChanged    function(newState, SetFn)
--   Tooltip      string   Hover tooltip (optional)
--   Flag         string   Config key for SaveConfig/LoadConfig
--
--   Icon         string   Lucide icon before the label (optional)
-- Returns: { Frame, Set(bool), GetValue(), SetDisabled(bool) }
-- ============================================================
function Skibidi.CreateToggle(Parent, Options)
	Options = Options or {}
	local state = Options.Default == true

	local W = Theme.ToggleW
	local H = Theme.ToggleH
	local K = Theme.KnobSz

	local Row = Instance.new("Frame")
	Row.Size             = UDim2.new(1, 0, 0, 34)
	Row.BackgroundColor3 = Theme.Bg2
	Row.BorderSizePixel  = 0
	Row.Parent           = Parent
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
	local RowEdge = MakeEdge(Row, Theme.AccentDim, 1)
	MakeGloss(Row, 0.10)
	if state then
		RowEdge.Color        = Theme.Accent
		RowEdge.Transparency = 0.18
	end

	local Lbl = Instance.new("TextLabel", Row)
	Lbl.Size                   = UDim2.new(1, -(W + 20), 1, 0)
	Lbl.Position               = UDim2.new(0, 12, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.BodySize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.Text                   = Options.Label or ""
	if Options.Icon then PrefixIcon(Lbl, Options.Icon, 14, Theme.TextPrimary) end

	-- Track
	local Track = Instance.new("Frame", Row)
	Track.AnchorPoint      = Vector2.new(1, 0.5)
	Track.Position         = UDim2.new(1, -10, 0.5, 0)
	Track.Size             = UDim2.new(0, W, 0, H)
	Track.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
	Track.BorderSizePixel  = 0
	MakeCorner(Track, UDim.new(1, 0))

	-- One gradient, re-coloured per state. A lit track reads as "on" even
	-- before the eye registers which end the knob is sitting at.
	local TRACK_ON = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.new(1.00, 1.00, 1.00)),
		ColorSequenceKeypoint.new(1.00, Color3.new(0.70, 0.70, 0.70)),
	})
	local TRACK_OFF = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.new(0.86, 0.86, 0.86)),
		ColorSequenceKeypoint.new(1.00, Color3.new(1.00, 1.00, 1.00)),
	})
	local TrackGrad = Instance.new("UIGradient")
	TrackGrad.Rotation = 90
	TrackGrad.Color    = state and TRACK_ON or TRACK_OFF
	TrackGrad.Parent   = Track
	local TrackGlow = MakeInnerGlow(Track, Theme.Accent, 9, state and 0.55 or 1)

	-- Knob
	local Knob = Instance.new("Frame", Track)
	Knob.Size             = UDim2.new(0, K, 0, K)
	Knob.Position         = state
		and UDim2.new(0, W - K - 2, 0.5, -K/2)
		or  UDim2.new(0, 2,         0.5, -K/2)
	Knob.BackgroundColor3 = Theme.Knob
	Knob.BorderSizePixel  = 0
	Knob.ZIndex           = 2
	MakeCorner(Knob, UDim.new(1, 0))
	MakeGloss(Knob, 0.22)
	local KnobScale = Instance.new("UIScale")
	KnobScale.Parent = Knob

	-- Invisible click target over entire row
	local ClickBtn = Instance.new("TextButton", Row)
	ClickBtn.Size                   = UDim2.new(1, 0, 1, 0)
	ClickBtn.BackgroundTransparency = 1
	ClickBtn.Text                   = ""
	ClickBtn.AutoButtonColor        = false
	ClickBtn.ZIndex                 = 3
	MakeRipple(ClickBtn, Theme.Accent, Theme.CornerRadiusSmall)

	local function Set(on)
		state = on
		TweenService:Create(Track, TweenFast,
			{ BackgroundColor3 = on and Theme.ToggleOn or Theme.ToggleOff }):Play()
		TweenService:Create(Knob,  TweenSpring,
			{ Position = on
				and UDim2.new(0, W - K - 2, 0.5, -K/2)
				or  UDim2.new(0, 2,         0.5, -K/2) }):Play()
		TrackGrad.Color = on and TRACK_ON or TRACK_OFF

		-- A brief overshoot on the knob makes the switch feel physical.
		KnobScale.Scale = on and 1.16 or 0.88
		TweenService:Create(KnobScale, TweenPop, { Scale = 1 }):Play()

		if TrackGlow then TrackGlow.SetAlpha(on and 0.5 or 1, TweenMed) end
		-- Tinting the row's own outline is what lets a column of toggles
		-- be read at a glance without inspecting each switch.
		TweenService:Create(RowEdge, TweenMed, {
			Color        = on and Theme.Accent or EdgeRest(),
			Transparency = on and 0.18 or (Theme.StrokeAlpha or 0.34),
		}):Play()
	end

	local disabled = false

	ClickBtn.MouseButton1Click:Connect(function()
		if disabled then return end
		local newState = not state
		Set(newState)
		if Options.OnChanged then Options.OnChanged(newState, Set) end
	end)
	ClickBtn.MouseEnter:Connect(function()
		if disabled then return end
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
	end)
	ClickBtn.MouseLeave:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
	end)
	AttachTooltip(Row, Options.Tooltip)
	PlayEntrance(Row)

	local function SetDisabled(on)
		disabled = on == true
		local t = disabled and 0.5 or 0
		TweenService:Create(Lbl,   TweenFast, { TextTransparency = t }):Play()
		TweenService:Create(Track, TweenFast, { BackgroundTransparency = disabled and 0.4 or 0 }):Play()
		TweenService:Create(Knob,  TweenFast, { BackgroundTransparency = disabled and 0.4 or 0 }):Play()
	end

	if Options.Flag then
		Flags[Options.Flag] = {
			Kind = "toggle",
			Get  = function() return state end,
			Set  = function(v)
				local on = v == true
				Set(on)
				if Options.OnChanged then Options.OnChanged(on, Set) end
			end,
		}
	end

	return { Frame = Row, Set = Set, GetValue = function() return state end, SetDisabled = SetDisabled }
end

-- ============================================================
-- CreateTextInput
-- A labeled row with a text box on the right.
--
-- Options:
--   Label        string
--   Placeholder  string
--   Default      string
--   Width        number   Box width (default 60)
--   NumericOnly  bool     Only allow numeric input
--   MaxLength    number   Hard cap on text length (optional)
--   OnSubmit     function(text)  called on FocusLost
--   Tooltip      string   Hover tooltip (optional)
--   Flag         string   Config key for SaveConfig/LoadConfig
--
--   Icon         string   Lucide icon before the label (optional)
-- Returns: { Frame, TextBox, GetValue() }
-- ============================================================
function Skibidi.CreateTextInput(Parent, Options)
	Options = Options or {}
	local boxW = Options.Width or 60

	local Row = Instance.new("Frame")
	Row.Size             = UDim2.new(1, 0, 0, 34)
	Row.BackgroundColor3 = Theme.Bg2
	Row.BorderSizePixel  = 0
	Row.Parent           = Parent
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Row, Theme.AccentDim, 1)
	MakeGloss(Row, 0.10)

	local Lbl = Instance.new("TextLabel", Row)
	Lbl.Size                   = UDim2.new(1, -(boxW + 20), 1, 0)
	Lbl.Position               = UDim2.new(0, 12, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.BodySize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.Text                   = Options.Label or ""
	if Options.Icon then PrefixIcon(Lbl, Options.Icon, 14, Theme.TextPrimary) end

	local Box = Instance.new("TextBox", Row)
	Box.AnchorPoint       = Vector2.new(1, 0.5)
	Box.Position          = UDim2.new(1, -10, 0.5, 0)
	Box.Size              = UDim2.new(0, boxW, 0, Theme.ToggleH)
	Box.BackgroundColor3  = Theme.InputBg
	Box.BorderSizePixel   = 0
	Box.Font              = Theme.FontMedium
	Box.TextSize          = Theme.SmallSize
	Box.TextColor3        = Theme.AccentSec
	Box.PlaceholderText   = Options.Placeholder or ""
	Box.PlaceholderColor3 = Theme.TextMuted
	Box.TextXAlignment    = Enum.TextXAlignment.Center
	Box.ClearTextOnFocus  = false
	Box.Text              = tostring(Options.Default or "")
	MakeCorner(Box, UDim.new(0, 6))
	local boxStroke = MakeEdge(Box, Theme.AccentDim, 1)
	MakeGloss(Box, 0.14)
	-- A focus ring rather than a focus *outline*: the bloom spills past
	-- the box, so the focused field wins attention against a dense column
	-- of rows without the border having to get heavier.
	local boxGlow = MakeInnerGlow(Box, Theme.Accent, 9, 1)

	Box.Focused:Connect(function()
		TweenService:Create(boxStroke, TweenFast,
			{ Color = Theme.Accent, Thickness = 1.5, Transparency = 0 }):Play()
		if boxGlow then boxGlow.SetAlpha(0.5, TweenMed) end
	end)
	Box.FocusLost:Connect(function(ep)
		TweenService:Create(boxStroke, TweenFast,
			{ Color = EdgeRest(), Thickness = 1, Transparency = Theme.StrokeAlpha or 0.34 }):Play()
		if boxGlow then boxGlow.SetAlpha(1, TweenMed) end
		local val = Box.Text
		if Options.NumericOnly then
			local n = tonumber(val:match("%d+"))
			val = n and tostring(n) or ""
			Box.Text = val
		end
		if Options.OnSubmit then Options.OnSubmit(val) end
	end)

	if Options.MaxLength then
		Box:GetPropertyChangedSignal("Text"):Connect(function()
			if #Box.Text > Options.MaxLength then
				Box.Text = string.sub(Box.Text, 1, Options.MaxLength)
			end
		end)
	end

	Row.MouseEnter:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
	end)
	Row.MouseLeave:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
	end)
	AttachTooltip(Row, Options.Tooltip)
	PlayEntrance(Row)

	if Options.Flag then
		Flags[Options.Flag] = {
			Kind = "text",
			Get  = function() return Box.Text end,
			Set  = function(v)
				v = tostring(v)
				if Options.NumericOnly then
					local n = tonumber(v:match("%d+"))
					v = n and tostring(n) or ""
				end
				Box.Text = v
				if Options.OnSubmit then Options.OnSubmit(v) end
			end,
		}
	end

	return { Frame = Row, TextBox = Box, GetValue = function() return Box.Text end }
end

-- ============================================================
-- CreateSlider
-- A labeled row with a horizontal drag slider.
--
-- Options:
--   Label      string
--   Min        number  (default 0)
--   Max        number  (default 100)
--   Default    number
--   Step       number  Snap values to this increment (optional)
--   Format     string  string.format pattern (default "%.0f")
--   OnChanged  function(value)
--   Tooltip    string  Hover tooltip (optional)
--   Flag       string  Config key for SaveConfig/LoadConfig
--
--   Icon       string   Lucide icon before the label (optional)
-- Returns: { Frame, Update(value), GetValue() }
-- ============================================================
function Skibidi.CreateSlider(Parent, Options)
	Options = Options or {}
	local Min   = Options.Min     or 0
	local Max   = Options.Max     or 100
	local cur   = Options.Default or Min
	local fmt   = Options.Format  or "%.0f"

	local Row = Instance.new("Frame")
	Row.Size             = UDim2.new(1, 0, 0, 34)
	Row.BackgroundColor3 = Theme.Bg2
	Row.BorderSizePixel  = 0
	Row.Parent           = Parent
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Row, Theme.AccentDim, 1)
	MakeGloss(Row, 0.10)

	local LabelW = 0
	if Options.Label and Options.Label ~= "" then
		LabelW = Options.Icon and 100 or 80
		local Lbl = Instance.new("TextLabel", Row)
		Lbl.Size             = UDim2.new(0, LabelW, 1, 0)
		Lbl.Position         = UDim2.new(0, 12, 0, 0)
		Lbl.BackgroundTransparency = 1
		Lbl.Font             = Theme.FontRegular
		Lbl.TextSize         = Theme.SmallSize + 1
		Lbl.TextColor3       = Theme.TextPrimary
		Lbl.TextXAlignment   = Enum.TextXAlignment.Left
		Lbl.TextTruncate     = Enum.TextTruncate.AtEnd
		Lbl.Text             = Options.Label
		if Options.Icon then PrefixIcon(Lbl, Options.Icon, 14, Theme.TextPrimary) end
	end

	local ValLbl = Instance.new("TextLabel", Row)
	ValLbl.Size                   = UDim2.new(0, 40, 0, 18)
	ValLbl.Position               = UDim2.new(1, -46, 0.5, -9)
	ValLbl.BackgroundColor3       = Theme.InputBg
	ValLbl.BackgroundTransparency = 0.25
	ValLbl.BorderSizePixel        = 0
	ValLbl.Font                   = Theme.FontMedium
	ValLbl.TextSize               = Theme.SmallSize
	ValLbl.TextColor3             = Theme.AccentSec
	ValLbl.TextXAlignment         = Enum.TextXAlignment.Center
	MakeCorner(ValLbl, UDim.new(0, 5))
	MakeStroke(ValLbl, Theme.AccentDim, 1).Transparency = 0.5

	local trackX  = LabelW + 14
	local trackW  = -(LabelW + 64)

	local Track = Instance.new("Frame", Row)
	Track.Size             = UDim2.new(1, trackW, 0, 5)
	Track.Position         = UDim2.new(0, trackX, 0.5, -2.5)
	Track.BackgroundColor3 = Theme.ToggleOff
	Track.BorderSizePixel  = 0
	MakeCorner(Track, UDim.new(1, 0))
	-- Dark at the top, lighter at the bottom: the inverse of a raised
	-- surface, which is what makes an empty track read as a groove.
	do
		local g = Instance.new("UIGradient", Track)
		g.Rotation = 90
		g.Color = ColorSequence.new(Color3.new(0.72, 0.72, 0.72), Color3.new(1, 1, 1))
	end

	local Fill = Instance.new("Frame", Track)
	Fill.Size             = UDim2.new(0, 0, 1, 0)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.BorderSizePixel  = 0
	Fill.ClipsDescendants = true
	MakeCorner(Fill, UDim.new(1, 0))
	MakeAccentFill(Fill, Theme.Accent, true)

	local Knob = Instance.new("Frame", Track)
	Knob.Size             = UDim2.new(0, 13, 0, 13)
	Knob.AnchorPoint      = Vector2.new(0.5, 0.5)
	Knob.Position         = UDim2.new(0, 0, 0.5, 0)
	Knob.BackgroundColor3 = Theme.Knob
	Knob.BorderSizePixel  = 0
	Knob.ZIndex           = 2
	MakeCorner(Knob, UDim.new(1, 0))
	MakeGloss(Knob, 0.22)
	MakeStroke(Knob, Darken(Theme.Accent, 0.24), 1).Transparency = 0.45
	local KnobGlow = MakeInnerGlow(Knob, Theme.Accent, 9, 0.62)

	local step = Options.Step

	local function Update(val)
		if step and step > 0 then
			val = Min + math.floor((val - Min) / step + 0.5) * step
		end
		val = math.clamp(val, Min, Max)
		cur = val
		ValLbl.Text = string.format(fmt, val)
		local pct = (val - Min) / (Max - Min)
		Fill.Size     = UDim2.new(pct, 0, 1, 0)
		Knob.Position = UDim2.new(pct, 0, 0.5, 0)
		if Options.OnChanged then Options.OnChanged(val) end
	end
	Update(cur)

	local dragging = false
	Track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			TweenService:Create(Knob, TweenSpring, { Size = UDim2.new(0, 17, 0, 17) }):Play()
			if KnobGlow then KnobGlow.SetAlpha(0.32, TweenFast) end
			local x = inp.Position.X
			Update(Min + ((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X) * (Max - Min))
		end
	end)
	ConnectScoped(Row, UserInputService.InputEnded, function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				TweenService:Create(Knob, TweenSpring, { Size = UDim2.new(0, 13, 0, 13) }):Play()
				if KnobGlow then KnobGlow.SetAlpha(0.62, TweenMed) end
			end
			dragging = false
		end
	end)
	ConnectScoped(Row, UserInputService.InputChanged, function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
		or inp.UserInputType == Enum.UserInputType.Touch) then
			local x = inp.Position.X
			Update(Min + math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1) * (Max - Min))
		end
	end)

	Row.MouseEnter:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
	end)
	Row.MouseLeave:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
	end)
	AttachTooltip(Row, Options.Tooltip)
	PlayEntrance(Row)

	if Options.Flag then
		Flags[Options.Flag] = {
			Kind = "number",
			Get  = function() return cur end,
			Set  = function(val) if type(val) == "number" then Update(val) end end,
		}
	end

	return { Frame = Row, Update = Update, GetValue = function() return cur end }
end

-- ============================================================
-- CreateInputList / multi-line text input list
-- A labeled header with a scrollable list of text boxes.
--
-- Options:
--   Label       string    Header label
--   Count       number    Number of input slots (default 10)
--   Defaults    table     Array of default strings
--   Placeholder string    Placeholder for each box (or function(i))
--   OnChanged   function(index, value)
--   Height      number    Scroll area height (default 120)
--   Flag        string    Config key for SaveConfig/LoadConfig
--
--   Icon        string   Lucide icon before the label (optional)
-- Returns:
--   { Frame, GetValues(), SetValue(i, text) }
-- ============================================================
function Skibidi.CreateInputList(Parent, Options)
	Options = Options or {}
	local count  = Options.Count    or 10
	local h      = Options.Height   or 120
	local label  = Options.Label    or "Items"
	local defs   = Options.Defaults or {}

	local BOX_H = 22
	local BOX_G = 4

	-- Outer card
	local Card = Instance.new("Frame")
	Card.Size             = UDim2.new(1, 0, 0, 34 + 1 + h + 8)
	Card.BackgroundColor3 = Theme.Bg2
	Card.BorderSizePixel  = 0
	Card.ClipsDescendants = true
	Card.Parent           = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Card, Theme.AccentDim, 1)
	MakeGloss(Card, 0.10)

	-- Header
	local HeaderRow = Instance.new("Frame", Card)
	HeaderRow.Size                   = UDim2.new(1, 0, 0, 34)
	HeaderRow.BackgroundTransparency = 1

	local Lbl = Instance.new("TextLabel", HeaderRow)
	Lbl.Size                   = UDim2.new(1, -20, 1, 0)
	Lbl.Position               = UDim2.new(0, 12, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.BodySize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.Text                   = label
	if Options.Icon then PrefixIcon(Lbl, Options.Icon, 14, Theme.TextPrimary) end

	local Div = Instance.new("Frame", Card)
	Div.Size             = UDim2.new(1, -16, 0, 1)
	Div.Position         = UDim2.new(0, 8, 0, 34)
	Div.BackgroundColor3 = Theme.AccentDim
	Div.BorderSizePixel  = 0

	-- Scroll
	local Scroll = Instance.new("ScrollingFrame", Card)
	Scroll.Size                   = UDim2.new(1, -8, 0, h)
	Scroll.Position               = UDim2.new(0, 4, 0, 39)
	Scroll.BackgroundColor3       = Theme.Bg3
	Scroll.BackgroundTransparency = 0.2
	Scroll.BorderSizePixel        = 0
	Scroll.ScrollBarThickness     = 3
	Scroll.ScrollBarImageColor3   = Theme.AccentDim
	Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	Scroll.CanvasSize             = UDim2.new(0,0,0,0)
	Scroll.ClipsDescendants       = true
	MakeCorner(Scroll, UDim.new(0, 5))
	MakePadding(Scroll, 5, 5, 5, 5)
	MakeListLayout(Scroll, Enum.FillDirection.Vertical, BOX_G)

	local values = {}
	local boxes  = {}

	for i = 1, count do
		values[i] = defs[i] or ""

		local Slot = Instance.new("Frame", Scroll)
		Slot.Size                   = UDim2.new(1, 0, 0, BOX_H)
		Slot.BackgroundColor3       = Theme.InputBg
		Slot.BackgroundTransparency = 0.2
		Slot.BorderSizePixel        = 0
		Slot.LayoutOrder            = i
		MakeCorner(Slot, UDim.new(0, 4))
		local slotStroke = MakeEdge(Slot, Theme.AccentDim, 1)
		MakeGloss(Slot, 0.10)

		local Badge = Instance.new("TextLabel", Slot)
		Badge.Size                   = UDim2.new(0, 14, 1, 0)
		Badge.Position               = UDim2.new(0, 4, 0, 0)
		Badge.BackgroundTransparency = 1
		Badge.Font                   = Theme.FontMedium
		Badge.TextSize               = 9
		Badge.TextColor3             = Theme.TextMuted
		Badge.TextXAlignment         = Enum.TextXAlignment.Center
		Badge.Text                   = tostring(i)

		local ph
		if type(Options.Placeholder) == "function" then
			ph = Options.Placeholder(i)
		else
			ph = (Options.Placeholder or ("item " .. i))
		end

		local TB = Instance.new("TextBox", Slot)
		TB.Size               = UDim2.new(1, -22, 1, -4)
		TB.Position           = UDim2.new(0, 20, 0, 2)
		TB.BackgroundTransparency = 1
		TB.BorderSizePixel    = 0
		TB.Font               = Theme.FontMedium
		TB.TextSize           = 11
		TB.TextColor3         = Theme.TextPrimary
		TB.PlaceholderText    = ph
		TB.PlaceholderColor3  = Theme.TextMuted
		TB.TextXAlignment     = Enum.TextXAlignment.Left
		TB.ClearTextOnFocus   = false
		TB.Text               = values[i]

		TB.Focused:Connect(function()
			TweenService:Create(slotStroke, TweenFast,
				{ Color = Theme.Accent, Thickness = 1.5, Transparency = 0 }):Play()
			TweenService:Create(Badge, TweenFast, { TextColor3 = Theme.Accent }):Play()
		end)
		TB.FocusLost:Connect(function()
			TweenService:Create(slotStroke, TweenFast,
				{ Color = EdgeRest(), Thickness = 1, Transparency = Theme.StrokeAlpha or 0.34 }):Play()
			TweenService:Create(Badge, TweenFast, { TextColor3 = Theme.TextMuted }):Play()
			values[i] = TB.Text
			if Options.OnChanged then Options.OnChanged(i, TB.Text) end
		end)
		TB:GetPropertyChangedSignal("Text"):Connect(function()
			values[i] = TB.Text
		end)

		boxes[i] = TB
	end

	if Options.Flag then
		Flags[Options.Flag] = {
			Kind = "table",
			Get  = function() return values end,
			Set  = function(t)
				if type(t) ~= "table" then return end
				for i = 1, count do
					if t[i] ~= nil then
						values[i] = tostring(t[i])
						if boxes[i] then boxes[i].Text = values[i] end
						if Options.OnChanged then Options.OnChanged(i, values[i]) end
					end
				end
			end,
		}
	end

	return {
		Frame     = Card,
		GetValues = function() return values end,
		SetValue  = function(i, text)
			values[i] = text
			if boxes[i] then boxes[i].Text = text end
		end,
	}
end

-- ============================================================
-- CreateStatusLog
-- A scrollable text log with a "Clear" button.
--
-- Options:
--   Height    number   Scroll area height (default 200)
--   MaxLines  number   Drop the oldest entries beyond this count
--                      (optional — unlimited when omitted)
--
-- Returns:
--   { Frame, Log(msg, color?), Clear() }
--   Log's optional color tints that entry (e.g. red for errors).
-- ============================================================
function Skibidi.CreateStatusLog(Parent, Options)
	Options = Options or {}
	local h = Options.Height or 200

	local Wrapper = Instance.new("Frame")
	Wrapper.Size             = UDim2.new(1, 0, 0, h + 34)
	Wrapper.BackgroundTransparency = 1
	Wrapper.BorderSizePixel  = 0
	Wrapper.Parent           = Parent

	local Scroll = Instance.new("ScrollingFrame", Wrapper)
	Scroll.Size                   = UDim2.new(1, 0, 1, -34)
	Scroll.Position               = UDim2.new(0, 0, 0, 0)
	Scroll.BackgroundColor3       = Theme.Bg3
	Scroll.BackgroundTransparency = 0.2
	Scroll.BorderSizePixel        = 0
	Scroll.ScrollBarThickness     = 3
	Scroll.ScrollBarImageColor3   = Theme.AccentDim
	Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
	Scroll.CanvasSize             = UDim2.new(0,0,0,0)
	Scroll.ClipsDescendants       = true
	MakeCorner(Scroll, UDim.new(0, 5))
	MakeEdge(Scroll, Theme.AccentDim, 1)
	MakeGloss(Scroll, 0.10)
	MakePadding(Scroll, 4, 4, 4, 4)
	MakeListLayout(Scroll, Enum.FillDirection.Vertical, 2)

	local ClearRow = Instance.new("Frame", Wrapper)
	ClearRow.Size             = UDim2.new(1, 0, 0, 28)
	ClearRow.Position         = UDim2.new(0, 0, 1, -28)
	ClearRow.BackgroundColor3 = Theme.Bg2
	ClearRow.BorderSizePixel  = 0
	MakeCorner(ClearRow, UDim.new(0, 6))
	MakeEdge(ClearRow, Theme.AccentDim, 1)
	MakeGloss(ClearRow, 0.10)

	local ClearBtn = Instance.new("TextButton", ClearRow)
	ClearBtn.Size                   = UDim2.new(1, 0, 1, 0)
	ClearBtn.BackgroundTransparency = 1
	ClearBtn.Font                   = Theme.FontMedium
	ClearBtn.TextSize               = Theme.SmallSize
	ClearBtn.TextColor3             = Theme.TextMuted
	ClearBtn.Text                   = "Clear Log"
	ClearBtn.AutoButtonColor        = false
	MakeRipple(ClearBtn, Theme.Accent, 6)

	local entries  = {}
	local maxLines = Options.MaxLines

	-- Log text is arbitrary, and RichText treats < & > as markup, so the
	-- message is escaped before the timestamp span is wrapped around it.
	local function escapeRich(str)
		str = string.gsub(tostring(str), "&", "&amp;")
		str = string.gsub(str, "<", "&lt;")
		str = string.gsub(str, ">", "&gt;")
		return str
	end

	local stampHex = ToHex(Theme.TextMuted)

	local function Log(msg, color)
		local t = (os and os.date) and os.date("%H:%M:%S") or "??"
		local lbl = Instance.new("TextLabel", Scroll)
		lbl.Size                   = UDim2.new(1, -8, 0, 0)
		lbl.AutomaticSize          = Enum.AutomaticSize.Y
		lbl.BackgroundTransparency = 1
		lbl.RichText               = true
		lbl.Font                   = Enum.Font.Code
		lbl.TextSize               = 11
		lbl.TextColor3             = color or Theme.TextPrimary
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.TextWrapped            = true
		-- Dimming the timestamp lets the eye skip straight to the message
		-- when scanning a fast-moving log.
		lbl.Text = string.format("<font color='#%s'>%s</font>  %s",
			stampHex, t, escapeRich(msg))

		-- New lines fade up rather than snapping in, which makes a busy
		-- log much easier to follow.
		lbl.TextTransparency = 1
		TweenService:Create(lbl, TweenMed, { TextTransparency = 0 }):Play()
		table.insert(entries, lbl)
		if maxLines then
			while #entries > maxLines do
				local oldest = table.remove(entries, 1)
				if oldest then oldest:Destroy() end
			end
		end
		task.defer(function()
			Scroll.CanvasPosition = Vector2.new(0, math.huge)
		end)
	end

	local function Clear()
		for _, c in ipairs(Scroll:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		entries = {}
	end

	ClearBtn.MouseButton1Click:Connect(Clear)
	ClearBtn.MouseEnter:Connect(function()
		TweenService:Create(ClearRow, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
		TweenService:Create(ClearBtn, TweenFast, { TextColor3 = Theme.Accent }):Play()
	end)
	ClearBtn.MouseLeave:Connect(function()
		TweenService:Create(ClearRow, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
		TweenService:Create(ClearBtn, TweenFast, { TextColor3 = Theme.TextMuted }):Play()
	end)

	return { Frame = Wrapper, Log = Log, Clear = Clear }
end

-- ============================================================
-- CreateDivider
-- A thin 1px horizontal line. Pass Options.Text for a labeled
-- divider (line with a small centered caption).
--
-- Options (all optional):
--   Text   string   Centered caption
--
-- Returns the divider Frame.
-- ============================================================
function Skibidi.CreateDivider(Parent, Options)
	Options = Options or {}

	-- A rule that stops dead at both edges boxes the content in. Fading
	-- the ends turns the same one pixel into a separator that belongs to
	-- the surface it sits on.
	local function fadeEnds(inst, mid)
		local g = Instance.new("UIGradient", inst)
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 1),
			NumberSequenceKeypoint.new(0.20, mid),
			NumberSequenceKeypoint.new(0.80, mid),
			NumberSequenceKeypoint.new(1.00, 1),
		})
		return g
	end

	if not Options.Text or Options.Text == "" then
		local d = Instance.new("Frame")
		d.Size             = UDim2.new(1, 0, 0, 1)
		d.BackgroundColor3 = Theme.Accent
		d.BackgroundTransparency = 0.4
		d.BorderSizePixel  = 0
		d.Parent           = Parent
		fadeEnds(d, 0)
		return d
	end

	local Holder = Instance.new("Frame")
	Holder.Size                   = UDim2.new(1, 0, 0, 14)
	Holder.BackgroundTransparency = 1
	Holder.BorderSizePixel        = 0
	Holder.Parent                 = Parent

	local Line = Instance.new("Frame", Holder)
	Line.Size                   = UDim2.new(1, 0, 0, 1)
	Line.Position               = UDim2.new(0, 0, 0.5, 0)
	Line.BackgroundColor3       = Theme.Accent
	Line.BackgroundTransparency = 0.45
	Line.BorderSizePixel        = 0
	fadeEnds(Line, 0)

	-- The caption sits on top of the line and masks it with the panel's
	-- surface colour, reading as "line — text — line".
	local Cap = Instance.new("TextLabel", Holder)
	Cap.AnchorPoint            = Vector2.new(0.5, 0.5)
	Cap.Position               = UDim2.new(0.5, 0, 0.5, 0)
	Cap.AutomaticSize          = Enum.AutomaticSize.XY
	Cap.BackgroundColor3       = Theme.Bg1
	Cap.BorderSizePixel        = 0
	Cap.Font                   = Theme.FontMedium
	Cap.TextSize               = Theme.CaptionSize
	Cap.TextColor3             = Theme.Accent
	Cap.Text                   = string.upper(Options.Text)
	MakePadding(Cap, 10, 10, 1, 1)

	return Holder
end

-- ============================================================
-- ShowNotification
-- Bottom-right slide-in banner, auto-dismissed after 2.5s.
-- Multiple calls stack vertically.
--
-- Args:
--   Title     string
--   Text      string
--   Duration  number   Seconds before auto-dismiss (default 2.5)
-- ============================================================
local _notifList = {}
local _notifSg   = nil
local NOTIF_W    = 268
local NOTIF_H    = 48
local NOTIF_PAD  = 8

local function _ensureNotifGui()
	if _notifSg and _notifSg.Parent then return end
	_notifSg = Instance.new("ScreenGui")
	_notifSg.Name           = "SkibidiNotifs"
	_notifSg.ResetOnSpawn   = false
	_notifSg.DisplayOrder   = 999
	_notifSg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	_notifSg.Parent         = PlayerGui
end

local function _repositionNotifs()
	-- Arrange from bottom up, right-aligned
	local bottomMargin = 12
	local totalY = 0
	for i = #_notifList, 1, -1 do
		local f = _notifList[i]
		if f and f.Parent then
			local targetY = -(bottomMargin + totalY + NOTIF_H)
			TweenService:Create(f, TweenSoft,
				{ Position = UDim2.new(1, -(NOTIF_W + 12), 1, targetY) }):Play()
			totalY = totalY + NOTIF_H + NOTIF_PAD
		end
	end
end

-- ShowNotification(Title, Text, Duration, Icon)
-- or ShowNotification({ Title=, Text=, Duration=, Icon= })
-- Icon is a lucide spec, or one of "success" | "warning" | "error" |
-- "info", which also tints the banner's rail with the matching
-- semantic colour.
local NOTIF_KINDS = {
	success = { "circle-check",   "Success" },
	warning = { "triangle-alert", "Warning" },
	error   = { "circle-x",       "Danger"  },
	danger  = { "circle-x",       "Danger"  },
	info    = { "info",           "Info"    },
}
function Skibidi.ShowNotification(Title, Text, Duration, Icon)
	_ensureNotifGui()

	if type(Title) == "table" then
		local o = Title
		Title, Text, Duration, Icon = o.Title, o.Text or o.Content, o.Duration, o.Icon
	end
	local dur = tonumber(Duration) or 2.5

	local kind = type(Icon) == "string" and NOTIF_KINDS[string.lower(Icon)] or nil
	local iconSpec  = kind and kind[1] or Icon
	local iconColor = kind and Theme[kind[2]] or Theme.AccentSec

	local F = Instance.new("Frame", _notifSg)
	F.Size                   = UDim2.new(0, NOTIF_W, 0, NOTIF_H)
	F.Position               = UDim2.new(1, 12, 1, 0)   -- starts off-screen right
	F.BackgroundColor3       = Theme.Bg1
	F.BackgroundTransparency = 0.04
	F.BorderSizePixel        = 0
	F.ClipsDescendants       = true
	MakeCorner(F, UDim.new(0, Theme.CornerRadius))
	MakeEdge(F, Theme.Accent, 1.2, 0.12)
	MakeGloss(F, 0.14)
	MakeGrain(F)
	-- Banners land over arbitrary game content, so they carry their own
	-- shadow and bloom instead of relying on the backdrop for contrast.
	MakeGlow(F, Theme.Accent, 20, 0.84)

	-- Accent rail down the left edge
	local Bar = Instance.new("Frame", F)
	Bar.Size             = UDim2.new(0, 3, 1, -12)
	Bar.Position         = UDim2.new(0, 5, 0, 6)
	Bar.BackgroundColor3 = Theme.Accent
	Bar.BorderSizePixel  = 0
	Bar.ZIndex           = 2
	MakeCorner(Bar, UDim.new(1, 0))
	MakeAccentFill(Bar, kind and iconColor or Theme.Accent)

	-- Optional icon between the rail and the text
	local textX, textW = 16, -26
	if iconSpec then
		local NI = MakeIcon(F, iconSpec, 18, iconColor, 2)
		NI.AnchorPoint = Vector2.new(0, 0.5)
		NI.Position    = UDim2.new(0, 15, 0.5, 0)
		textX, textW   = 15 + 18 + 7, -(26 + 18 + 6)
	end

	-- Title and body on separate lines. Packing both into one truncated
	-- RichText run meant a long title ate the message; stacked, each gets
	-- its own budget and its own weight.
	local TitleLbl = Instance.new("TextLabel", F)
	TitleLbl.Size                   = UDim2.new(1, textW, 0, 16)
	TitleLbl.Position               = UDim2.new(0, textX, 0, 8)
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.Font                   = Theme.FontBold
	TitleLbl.TextSize               = Theme.CaptionSize
	TitleLbl.TextColor3             = Theme.AccentSec
	TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	TitleLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	TitleLbl.ZIndex                 = 2
	TitleLbl.Text                   = (Title or ""):upper()

	local Lbl = Instance.new("TextLabel", F)
	Lbl.Size                   = UDim2.new(1, textW, 0, 16)
	Lbl.Position               = UDim2.new(0, textX, 0, 24)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.SmallSize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.TextTruncate           = Enum.TextTruncate.AtEnd
	Lbl.ZIndex                 = 2
	Lbl.Text                   = Text or ""

	-- Countdown rule along the bottom: the banner shows how long it has
	-- left instead of vanishing without warning.
	local Timer = Instance.new("Frame", F)
	Timer.AnchorPoint      = Vector2.new(0, 1)
	Timer.Size             = UDim2.new(1, 0, 0, 2)
	Timer.Position         = UDim2.new(0, 0, 1, 0)
	Timer.BackgroundColor3 = Theme.Accent
	Timer.BackgroundTransparency = 0.25
	Timer.BorderSizePixel  = 0
	Timer.ZIndex           = 3
	TweenService:Create(Timer, TweenInfo.new(dur, Enum.EasingStyle.Linear),
		{ Size = UDim2.new(0, 0, 0, 2) }):Play()

	-- Arriving on a Back curve gives the banner a little settle at the
	-- end of its slide, which is what makes it read as landing.
	local Pop = Instance.new("UIScale")
	Pop.Scale  = 0.9
	Pop.Parent = F
	TweenService:Create(Pop, TweenPop, { Scale = 1 }):Play()

	table.insert(_notifList, F)
	_repositionNotifs()

	-- Auto-dismiss
	task.delay(dur, function()
		if not F.Parent then return end
		-- Slide out to the right
		TweenService:Create(F, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 12, F.Position.Y.Scale, F.Position.Y.Offset) }):Play()
		TweenService:Create(Pop, TweenInfo.new(0.24, Enum.EasingStyle.Quad), { Scale = 0.92 }):Play()
		task.delay(0.26, function()
			if F.Parent then F:Destroy() end
			-- Remove from list
			for i, v in ipairs(_notifList) do
				if v == F then table.remove(_notifList, i) break end
			end
			_repositionNotifs()
		end)
	end)
end

-- ============================================================
-- MakeDraggable (standalone utility)
--
-- Options (optional third argument):
--   ClampToScreen  bool   Keep Target inside its parent container
--                         while dragging (default false)
-- ============================================================
function Skibidi.MakeDraggable(Handle, Target, Options)
	Options = Options or {}
	local clampToScreen = Options.ClampToScreen == true
	local dragging, dragStart, startPos = false, nil, nil
	Handle.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1
		and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging  = true
		dragStart = inp.Position
		startPos  = Target.Position
		inp.Changed:Connect(function()
			if inp.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end)
	ConnectScoped(Target, UserInputService.InputChanged, function(inp)
		if not dragging then return end
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement
		and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = inp.Position - dragStart
		local pos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y)
		if clampToScreen and Target.Parent then
			local ok, screen = pcall(function() return Target.Parent.AbsoluteSize end)
			if ok and screen and screen.X > 0 and screen.Y > 0 then
				local tw, th = Target.AbsoluteSize.X, Target.AbsoluteSize.Y
				local absX = math.clamp(pos.X.Scale * screen.X + pos.X.Offset, 0, math.max(0, screen.X - tw))
				local absY = math.clamp(pos.Y.Scale * screen.Y + pos.Y.Offset, 0, math.max(0, screen.Y - th))
				pos = UDim2.new(
					pos.X.Scale, absX - pos.X.Scale * screen.X,
					pos.Y.Scale, absY - pos.Y.Scale * screen.Y)
			end
		end
		Target.Position = pos
	end)
end

-- ============================================================
-- CreateParagraph
-- A static text block: optional bold title + wrapped body text.
--
-- Options:
--   Title     string
--   Icon      string   Lucide icon before the title (optional)
--   Content   string   (also accepts Options.Text)
--
-- Returns: { Frame, SetTitle(text), SetText(text), SetIcon(spec) }
-- ============================================================
function Skibidi.CreateParagraph(Parent, Options)
	Options = Options or {}

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, 0)
	Card.AutomaticSize     = Enum.AutomaticSize.Y
	Card.BackgroundColor3  = Theme.Bg2
	Card.BorderSizePixel   = 0
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Card, Theme.AccentDim, 1)
	MakeGloss(Card, 0.10)
	MakePadding(Card, 12, 12, 10, 10)
	MakeListLayout(Card, Enum.FillDirection.Vertical, 4)

	local TitleLbl, ParaIcon
	if Options.Title and Options.Title ~= "" then
		TitleLbl = Instance.new("TextLabel", Card)
		TitleLbl.Size                   = UDim2.new(1, 0, 0, 0)
		TitleLbl.AutomaticSize          = Enum.AutomaticSize.Y
		TitleLbl.BackgroundTransparency = 1
		TitleLbl.Font                   = Theme.FontMedium
		TitleLbl.TextSize               = Theme.BodySize
		TitleLbl.TextColor3             = Theme.Accent
		TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
		TitleLbl.TextWrapped            = true
		TitleLbl.LayoutOrder            = 0
		TitleLbl.Text                   = Options.Title
		if Options.Icon then
			ParaIcon = PadIcon(TitleLbl, Options.Icon, 14, Theme.Accent)
		end

		-- Layout-safe because Card stacks vertically: the rule is simply
		-- the next item in the list, not an overlay.
		local Rule = Instance.new("Frame", Card)
		Rule.Size                   = UDim2.new(1, 0, 0, 1)
		Rule.BackgroundColor3       = Theme.Accent
		Rule.BackgroundTransparency = 0.55
		Rule.BorderSizePixel        = 0
		Rule.LayoutOrder            = 1
		local rg = Instance.new("UIGradient", Rule)
		rg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.00, 0),
			NumberSequenceKeypoint.new(0.55, 0.45),
			NumberSequenceKeypoint.new(1.00, 1),
		})
	end

	local Body = Instance.new("TextLabel", Card)
	Body.Size                   = UDim2.new(1, 0, 0, 0)
	Body.AutomaticSize          = Enum.AutomaticSize.Y
	Body.BackgroundTransparency = 1
	Body.Font                   = Theme.FontRegular
	Body.TextSize               = Theme.SmallSize
	Body.TextColor3             = Theme.TextMuted
	Body.TextXAlignment         = Enum.TextXAlignment.Left
	Body.TextYAlignment         = Enum.TextYAlignment.Top
	Body.TextWrapped            = true
	Body.LayoutOrder            = 2
	Body.Text                   = Options.Content or Options.Text or ""

	return {
		Frame    = Card,
		SetTitle = function(t) if TitleLbl then TitleLbl.Text = t end end,
		SetText  = function(t) Body.Text = t end,
		SetIcon  = function(spec)
			if ParaIcon then
				SetIconImage(ParaIcon, spec)
			elseif TitleLbl and spec and spec ~= "" then
				ParaIcon = PadIcon(TitleLbl, spec, 14, Theme.Accent)
			end
		end,
	}
end

-- ============================================================
-- CreateProgressBar
-- A labeled row with a filled progress track.
--
-- Options:
--   Label     string
--   Min       number   (default 0)
--   Max       number   (default 100)
--   Default   number   (default Min)
--   Format    string   string.format pattern for the percent text
--                      (default "%d%%", receives 0-100)
--   Icon      string   Lucide icon before the label (optional)
--
-- Returns: { Frame, Update(value, instant), GetValue() }
-- ============================================================
function Skibidi.CreateProgressBar(Parent, Options)
	Options = Options or {}
	local Min = Options.Min or 0
	local Max = Options.Max or 100
	local cur = math.clamp(Options.Default or Min, Min, Max)

	local Row = Instance.new("Frame")
	Row.Size             = UDim2.new(1, 0, 0, 40)
	Row.BackgroundColor3 = Theme.Bg2
	Row.BorderSizePixel  = 0
	Row.Parent           = Parent
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Row, Theme.AccentDim, 1)
	MakeGloss(Row, 0.10)
	MakePadding(Row, 12, 12, 6, 8)

	local TopRow = Instance.new("Frame", Row)
	TopRow.Size                   = UDim2.new(1, 0, 0, 16)
	TopRow.BackgroundTransparency = 1

	local Lbl = Instance.new("TextLabel", TopRow)
	Lbl.Size                   = UDim2.new(1, -46, 1, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.SmallSize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.TextTruncate           = Enum.TextTruncate.AtEnd
	Lbl.Text                   = Options.Label or ""
	if Options.Icon then PrefixIcon(Lbl, Options.Icon, 14, Theme.TextPrimary) end

	local PctLbl = Instance.new("TextLabel", TopRow)
	PctLbl.Size                   = UDim2.new(0, 46, 1, 0)
	PctLbl.Position               = UDim2.new(1, -46, 0, 0)
	PctLbl.BackgroundTransparency = 1
	PctLbl.Font                   = Theme.FontMedium
	PctLbl.TextSize               = Theme.SmallSize
	PctLbl.TextColor3             = Theme.AccentSec
	PctLbl.TextXAlignment         = Enum.TextXAlignment.Right

	local Track = Instance.new("Frame", Row)
	Track.Position         = UDim2.new(0, 0, 0, 22)
	Track.Size             = UDim2.new(1, 0, 0, 7)
	Track.BackgroundColor3 = Theme.ToggleOff
	Track.BorderSizePixel  = 0
	MakeCorner(Track, UDim.new(1, 0))
	do
		local g = Instance.new("UIGradient", Track)
		g.Rotation = 90
		g.Color = ColorSequence.new(Color3.new(0.72, 0.72, 0.72), Color3.new(1, 1, 1))
	end

	local Fill = Instance.new("Frame", Track)
	Fill.Size             = UDim2.new(0, 0, 1, 0)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.BorderSizePixel  = 0
	Fill.ClipsDescendants = true
	MakeCorner(Fill, UDim.new(1, 0))
	-- The travelling highlight is the difference between a bar that has
	-- stopped and a bar that is still working.
	MakeAccentFill(Fill, Theme.Accent, true)

	local function Update(val, instant)
		val = math.clamp(val, Min, Max)
		cur = val
		local pct = (Max > Min) and (val - Min) / (Max - Min) or 0
		local fmt = Options.Format or "%d%%"
		PctLbl.Text = string.format(fmt, math.floor(pct * 100 + 0.5))
		if instant then
			Fill.Size = UDim2.new(pct, 0, 1, 0)
		else
			TweenService:Create(Fill, TweenMed, { Size = UDim2.new(pct, 0, 1, 0) }):Play()
		end
	end
	Update(cur, true)
	PlayEntrance(Row)

	return {
		Frame    = Row,
		Update   = Update,
		GetValue = function() return cur end,
		SetLabel = function(t) Lbl.Text = t or "" end,
	}
end

-- ============================================================
-- CreateSpace
-- An invisible spacer, useful inside sections/stacks to add
-- breathing room without a divider or a component.
--
-- Options:
--   Height   number   (default 8) — used when the parent stacks vertically
--   Width    number   (default 8) — used when the parent stacks horizontally
-- ============================================================
function Skibidi.CreateSpace(Parent, Options)
	Options = Options or {}
	local Spacer = Instance.new("Frame")
	Spacer.Size                   = UDim2.new(0, Options.Width or 0, 0, Options.Height or 8)
	if not Options.Width then
		Spacer.Size = UDim2.new(1, 0, 0, Options.Height or 8)
	end
	Spacer.BackgroundTransparency = 1
	Spacer.BorderSizePixel        = 0
	Spacer.Parent                 = Parent
	return { Frame = Spacer }
end

-- ============================================================
-- CreateHStack / CreateVStack
-- Generic layout containers for arranging components in a row
-- or column, mirroring the section/content building blocks used
-- throughout the rest of the library.
--
-- Options:
--   Spacing               number   Gap between children (default 6)
--   HorizontalAlignment    Enum.HorizontalAlignment
--   VerticalAlignment      Enum.VerticalAlignment
--   Height                 number   (HStack only — fixes the row height;
--                                    default auto-fits the tallest child)
--
-- Returns: { Frame }
-- ============================================================
function Skibidi.CreateHStack(Parent, Options)
	Options = Options or {}
	local gap = Options.Spacing or 6

	local Stack = Instance.new("Frame")
	Stack.BackgroundTransparency = 1
	Stack.BorderSizePixel        = 0
	Stack.Parent                 = Parent
	if Options.Height then
		Stack.Size = UDim2.new(1, 0, 0, Options.Height)
	else
		Stack.Size          = UDim2.new(1, 0, 0, 0)
		Stack.AutomaticSize = Enum.AutomaticSize.Y
	end
	MakeListLayout(Stack, Enum.FillDirection.Horizontal, gap,
		Options.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		Options.VerticalAlignment or Enum.VerticalAlignment.Center)

	-- Every other CreateXxx helper builds a full-width "row" component
	-- (Size.X.Scale = 1) since it's normally the only thing in its row.
	-- Dropped into a horizontal stack that would make each child fight
	-- for the whole width, so give every direct child an equal share
	-- instead — the same fixed, non-text-dependent split used for tabs.
	local function relayout()
		local kids = {}
		for _, c in ipairs(Stack:GetChildren()) do
			if c:IsA("GuiObject") then table.insert(kids, c) end
		end
		local n = #kids
		if n == 0 then return end
		local shareOffset = -(gap * (n - 1)) / n
		for _, c in ipairs(kids) do
			c.Size = UDim2.new(1 / n, shareOffset, c.Size.Y.Scale, c.Size.Y.Offset)
		end
	end
	Stack.ChildAdded:Connect(relayout)
	Stack.ChildRemoved:Connect(relayout)

	return { Frame = Stack }
end

function Skibidi.CreateVStack(Parent, Options)
	Options = Options or {}
	local Stack = Instance.new("Frame")
	Stack.Size                   = UDim2.new(1, 0, 0, 0)
	Stack.AutomaticSize          = Enum.AutomaticSize.Y
	Stack.BackgroundTransparency = 1
	Stack.BorderSizePixel        = 0
	Stack.Parent                 = Parent
	MakeListLayout(Stack, Enum.FillDirection.Vertical, Options.Spacing or 6,
		Options.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		Options.VerticalAlignment or Enum.VerticalAlignment.Top)
	return { Frame = Stack }
end

-- ============================================================
-- CreateGroup
-- A labeled set of mutually-exclusive radio-style options.
--
-- Options:
--   Label      string
--   Options    table    Array of option strings
--   Default    number   Initially selected index (default 1)
--   OnChanged  function(index, value)
--   Tooltip    string   Hover tooltip (optional)
--   Flag       string   Config key for SaveConfig/LoadConfig
--
-- Returns: { Frame, SetValue(index), GetValue() }
-- ============================================================
function Skibidi.CreateGroup(Parent, Options)
	Options = Options or {}
	local items   = Options.Options or {}
	local current = Options.Default or 1

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, 0)
	Card.AutomaticSize     = Enum.AutomaticSize.Y
	Card.BackgroundColor3  = Theme.Bg2
	Card.BorderSizePixel   = 0
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Card, Theme.AccentDim, 1)
	MakeGloss(Card, 0.10)
	MakePadding(Card, 8, 8, 8, 8)
	MakeListLayout(Card, Enum.FillDirection.Vertical, 2)

	if Options.Label and Options.Label ~= "" then
		local Lbl = Instance.new("TextLabel", Card)
		Lbl.Size                   = UDim2.new(1, 0, 0, 20)
		Lbl.BackgroundTransparency = 1
		Lbl.Font                   = Theme.FontMedium
		Lbl.TextSize               = Theme.SmallSize
		Lbl.TextColor3             = Theme.Accent
		Lbl.TextXAlignment         = Enum.TextXAlignment.Left
		Lbl.LayoutOrder            = 0
		Lbl.Text                   = Options.Label
	end

	local rows = {}
	-- The selected wash is mixed from the palette rather than hard-coded,
	-- so it lands correctly on every preset instead of only the gold one.
	local SEL_BG = Mix(Theme.Bg2, Theme.Accent, 0.16)

	local function refresh()
		for i, row in ipairs(rows) do
			local on = (i == current)
			TweenService:Create(row.Dot, TweenSpring, {
				BackgroundColor3 = on and Theme.Accent or Theme.Bg3,
				Size             = on and UDim2.new(0, 8, 0, 8) or UDim2.new(0, 5, 0, 5),
			}):Play()
			TweenService:Create(row.Ring, TweenFast, {
				Color     = on and Theme.Accent or Theme.AccentDim,
				Thickness = on and 2 or 1.5,
			}):Play()
			TweenService:Create(row.Lbl, TweenFast,
				{ TextColor3 = on and Theme.ActiveTabText or Theme.TextPrimary }):Play()
			row.Lbl.Font = on and Theme.FontMedium or Theme.FontRegular
			-- Selected rows hold a standing wash; hover only borrows the
			-- row while the pointer is on it.
			if on then row.Row.BackgroundTransparency = 0 end
			TweenService:Create(row.Row, TweenFast, {
				BackgroundColor3       = on and SEL_BG or Theme.Bg2,
				BackgroundTransparency = on and 0 or 1,
			}):Play()
			TweenService:Create(row.Tick, TweenSpring,
				{ Size = UDim2.new(0, 2, 0, on and 14 or 0) }):Play()
		end
	end

	for i, text in ipairs(items) do
		local Row = Instance.new("TextButton", Card)
		Row.Size                   = UDim2.new(1, 0, 0, 28)
		Row.LayoutOrder            = i
		Row.BackgroundColor3       = Theme.Bg2
		Row.BackgroundTransparency = 1
		Row.AutoButtonColor        = false
		Row.Text                   = ""
		MakeCorner(Row, UDim.new(0, 6))

		local Tick = Instance.new("Frame", Row)
		Tick.AnchorPoint      = Vector2.new(0, 0.5)
		Tick.Size             = UDim2.new(0, 2, 0, 0)
		Tick.Position         = UDim2.new(0, 0, 0.5, 0)
		Tick.BackgroundColor3 = Theme.Accent
		Tick.BorderSizePixel  = 0
		Tick.ZIndex           = 2
		MakeCorner(Tick, UDim.new(1, 0))

		local RingHolder = Instance.new("Frame", Row)
		RingHolder.Size             = UDim2.new(0, 16, 0, 16)
		RingHolder.Position         = UDim2.new(0, 6, 0.5, -8)
		RingHolder.BackgroundColor3 = Theme.Bg3
		RingHolder.BorderSizePixel  = 0
		MakeCorner(RingHolder, UDim.new(1, 0))
		local ring = MakeStroke(RingHolder, Theme.AccentDim, 1.5)

		local Dot = Instance.new("Frame", RingHolder)
		Dot.AnchorPoint      = Vector2.new(0.5, 0.5)
		Dot.Position         = UDim2.new(0.5, 0, 0.5, 0)
		Dot.Size             = UDim2.new(0, 8, 0, 8)
		Dot.BackgroundColor3 = Theme.Bg3
		Dot.BorderSizePixel  = 0
		MakeCorner(Dot, UDim.new(1, 0))

		local Lbl = Instance.new("TextLabel", Row)
		Lbl.Size                   = UDim2.new(1, -34, 1, 0)
		Lbl.Position               = UDim2.new(0, 30, 0, 0)
		Lbl.BackgroundTransparency = 1
		Lbl.Font                   = Theme.FontRegular
		Lbl.TextSize               = Theme.BodySize
		Lbl.TextColor3             = Theme.TextPrimary
		Lbl.TextXAlignment         = Enum.TextXAlignment.Left
		Lbl.ZIndex                 = 2
		Lbl.Text                   = text

		rows[i] = { Row = Row, Tick = Tick, Dot = Dot, Ring = ring, Lbl = Lbl }

		Row.MouseButton1Click:Connect(function()
			current = i
			refresh()
			if Options.OnChanged then Options.OnChanged(i, text) end
		end)
		Row.MouseEnter:Connect(function()
			if current == i then return end
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
			Row.BackgroundTransparency = 0
			TweenService:Create(Tick, TweenSpring, { Size = UDim2.new(0, 2, 0, 8) }):Play()
		end)
		Row.MouseLeave:Connect(function()
			if current == i then return end
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
			TweenService:Create(Tick, TweenFast, { Size = UDim2.new(0, 2, 0, 0) }):Play()
			task.delay(0.14, function()
				if current ~= i then Row.BackgroundTransparency = 1 end
			end)
		end)
	end

	refresh()
	AttachTooltip(Card, Options.Tooltip)

	if Options.Flag then
		Flags[Options.Flag] = {
			Kind = "number",
			Get  = function() return current end,
			Set  = function(i)
				if type(i) == "number" and items[i] then
					current = i
					refresh()
					if Options.OnChanged then Options.OnChanged(i, items[i]) end
				end
			end,
		}
	end

	return {
		Frame    = Card,
		SetValue = function(i) current = i; refresh() end,
		GetValue = function() return current, items[current] end,
	}
end

-- ============================================================
-- CreateDropdown
-- A collapsible labeled select list (single or multi-select).
--
-- Options:
--   Label        string
--   Options      table     Array of option strings
--   Default      any       Selected value/index (or array of values if Multi)
--   Multi        bool      Allow multiple selections   (default false)
--   Placeholder  string    Shown when nothing is selected
--   OnChanged    function(value)   -- value is a string, or an array if Multi
--   Tooltip      string    Hover tooltip (optional)
--   Flag         string    Config key for SaveConfig/LoadConfig
--
--   Icon         string   Lucide icon before the label (optional)
-- Returns: { Frame, SetOpen(bool), GetValue(),
--            SetItems(items, keepSelection) }
-- ============================================================
function Skibidi.CreateDropdown(Parent, Options)
	Options = Options or {}
	local items = Options.Options or {}
	local multi = Options.Multi == true
	local selected = {}

	if multi then
		for _, val in ipairs(Options.Default or {}) do selected[val] = true end
	else
		local d = Options.Default
		if type(d) == "number" then d = items[d] end
		if d ~= nil then selected[d] = true end
	end

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, 0)
	Card.AutomaticSize     = Enum.AutomaticSize.Y
	Card.BackgroundColor3  = Theme.Bg2
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Card, Theme.AccentDim, 1)
	MakeGloss(Card, 0.10)
	local CardLayout = Instance.new("UIListLayout", Card)
	CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	CardLayout.Padding   = UDim.new(0, 0)

	local Head = Instance.new("TextButton", Card)
	Head.Size                   = UDim2.new(1, 0, 0, 34)
	Head.LayoutOrder            = 0
	Head.BackgroundTransparency = 1
	Head.AutoButtonColor        = false
	Head.Text                   = ""
	MakeHoverFill(Head, 3, 5)

	local hasLabel = Options.Label and Options.Label ~= ""
	if hasLabel then
		local Lbl = Instance.new("TextLabel", Head)
		Lbl.Size                   = UDim2.new(0.45, 0, 1, 0)
		Lbl.Position               = UDim2.new(0, 12, 0, 0)
		Lbl.BackgroundTransparency = 1
		Lbl.Font                   = Theme.FontRegular
		Lbl.TextSize               = Theme.BodySize
		Lbl.TextColor3             = Theme.TextPrimary
		Lbl.TextXAlignment         = Enum.TextXAlignment.Left
		Lbl.Text                   = Options.Label
		if Options.Icon then PrefixIcon(Lbl, Options.Icon, 14, Theme.TextPrimary) end
	end

	local ValueLbl = Instance.new("TextLabel", Head)
	ValueLbl.Size                   = hasLabel and UDim2.new(0.55, -28, 1, 0) or UDim2.new(1, -40, 1, 0)
	ValueLbl.Position               = hasLabel and UDim2.new(0.45, 0, 0, 0) or UDim2.new(0, 12, 0, 0)
	ValueLbl.BackgroundTransparency = 1
	ValueLbl.Font                   = Theme.FontMedium
	ValueLbl.TextSize               = Theme.SmallSize
	ValueLbl.TextColor3             = Theme.AccentSec
	ValueLbl.TextXAlignment         = Enum.TextXAlignment.Right
	ValueLbl.TextTruncate           = Enum.TextTruncate.AtEnd

	local Chevron = Instance.new("TextLabel", Head)
	Chevron.Size                   = UDim2.new(0, 20, 1, 0)
	Chevron.Position               = UDim2.new(1, -24, 0, 0)
	Chevron.BackgroundTransparency = 1
	Chevron.Font                   = Theme.FontIcon
	Chevron.TextSize               = 12
	Chevron.TextColor3             = Theme.AccentDim
	Chevron.Text                   = "▼"

	local List = Instance.new("Frame", Card)
	List.Size                   = UDim2.new(1, 0, 0, 0)
	List.AutomaticSize          = Enum.AutomaticSize.Y
	List.LayoutOrder            = 1
	List.BackgroundTransparency = 1
	List.Visible                = false
	MakePadding(List, 6, 6, 0, 6)
	MakeListLayout(List, Enum.FillDirection.Vertical, 3)

	local Div = Instance.new("Frame", List)
	Div.Size                   = UDim2.new(1, 0, 0, 1)
	Div.LayoutOrder            = 0
	Div.BackgroundColor3       = Theme.AccentDim
	Div.BackgroundTransparency = 0.4
	Div.BorderSizePixel        = 0

	local optRows = {}

	local SEL_BG = Mix(Theme.Bg2, Theme.Accent, 0.16)

	local function refreshLabel()
		local out = {}
		for _, val in ipairs(items) do
			if selected[val] then table.insert(out, val) end
		end
		local any = #out > 0
		ValueLbl.Text = any and table.concat(out, ", ") or (Options.Placeholder or "Select...")
		-- An empty select should look empty. Painting the placeholder in
		-- the accent made "nothing chosen" read as a live value.
		TweenService:Create(ValueLbl, TweenFast,
			{ TextColor3 = any and Theme.AccentSec or Theme.TextMuted }):Play()
	end

	local function refreshRows()
		for val, row in pairs(optRows) do
			local on = selected[val] == true
			TweenService:Create(row.Dot, TweenSpring, {
				BackgroundColor3 = on and Theme.Accent or Theme.Bg3,
				Size             = on and UDim2.new(0, 7, 0, 7) or UDim2.new(0, 4, 0, 4),
			}):Play()
			TweenService:Create(row.Ring, TweenFast, {
				Color     = on and Theme.Accent or Theme.AccentDim,
				Thickness = on and 2 or 1.5,
			}):Play()
			TweenService:Create(row.Lbl, TweenFast,
				{ TextColor3 = on and Theme.ActiveTabText or Theme.TextPrimary }):Play()
			row.Lbl.Font = on and Theme.FontMedium or Theme.FontRegular
			if on then row.Row.BackgroundTransparency = 0 end
			TweenService:Create(row.Row, TweenFast, {
				BackgroundColor3       = on and SEL_BG or Theme.Bg2,
				BackgroundTransparency = on and 0 or 1,
			}):Play()
			TweenService:Create(row.Tick, TweenSpring,
				{ Size = UDim2.new(0, 2, 0, on and 12 or 0) }):Play()
		end
	end

	local isOpen = false
	local function setOpen(open)
		isOpen = open
		List.Visible = open
		TweenService:Create(Chevron, TweenMed,
			{ Rotation   = open and 180 or 0,
			  TextColor3 = open and Theme.Accent or Theme.AccentDim }):Play()
		if open then
			-- Rows arrive in list order rather than all at once, which is
			-- what makes an opening dropdown read as unfolding.
			for _, row in pairs(optRows) do
				if row.Scale then
					row.Scale.Scale = 0.94
					task.delay(math.min((row.Order or 1) * 0.022, 0.22), function()
						if row.Scale.Parent and isOpen then
							TweenService:Create(row.Scale, TweenPop, { Scale = 1 }):Play()
						end
					end)
				end
			end
			OverlayOpened(Card, function() setOpen(false) end)
		else
			OverlayClosed(Card)
		end
	end
	Card.Destroying:Connect(function() OverlayClosed(Card) end)

	local function buildRow(i, text)
		local Row = Instance.new("TextButton", List)
		Row.Size                   = UDim2.new(1, 0, 0, 26)
		Row.LayoutOrder            = i
		Row.BackgroundColor3       = Theme.Bg2
		Row.BackgroundTransparency = 1
		Row.AutoButtonColor        = false
		Row.Text                   = ""
		MakeCorner(Row, UDim.new(0, 6))

		-- Created once and reused on every open, so repeatedly toggling
		-- the list doesn't pile up UIScale instances on each row.
		local scale = Instance.new("UIScale")
		scale.Parent = Row

		local Tick = Instance.new("Frame", Row)
		Tick.AnchorPoint      = Vector2.new(0, 0.5)
		Tick.Size             = UDim2.new(0, 2, 0, 0)
		Tick.Position         = UDim2.new(0, 0, 0.5, 0)
		Tick.BackgroundColor3 = Theme.Accent
		Tick.BorderSizePixel  = 0
		Tick.ZIndex           = 2
		MakeCorner(Tick, UDim.new(1, 0))

		local RingHolder = Instance.new("Frame", Row)
		RingHolder.Size             = UDim2.new(0, 14, 0, 14)
		RingHolder.Position         = UDim2.new(0, 8, 0.5, -7)
		RingHolder.BackgroundColor3 = Theme.Bg3
		RingHolder.BorderSizePixel  = 0
		MakeCorner(RingHolder, UDim.new(1, 0))
		local ring = MakeStroke(RingHolder, selected[text] and Theme.Accent or Theme.AccentDim, 1.5)

		local Dot = Instance.new("Frame", RingHolder)
		Dot.AnchorPoint      = Vector2.new(0.5, 0.5)
		Dot.Position         = UDim2.new(0.5, 0, 0.5, 0)
		Dot.Size             = UDim2.new(0, 7, 0, 7)
		Dot.BackgroundColor3 = selected[text] and Theme.Accent or Theme.Bg3
		Dot.BorderSizePixel  = 0
		MakeCorner(Dot, UDim.new(1, 0))

		local RLbl = Instance.new("TextLabel", Row)
		RLbl.Size                   = UDim2.new(1, -32, 1, 0)
		RLbl.Position               = UDim2.new(0, 32, 0, 0)
		RLbl.BackgroundTransparency = 1
		RLbl.Font                   = Theme.FontRegular
		RLbl.TextSize               = Theme.SmallSize + 1
		RLbl.TextColor3             = selected[text] and Theme.ActiveTabText or Theme.TextPrimary
		RLbl.TextXAlignment         = Enum.TextXAlignment.Left
		RLbl.ZIndex                 = 2
		RLbl.Text                   = text

		optRows[text] = { Row = Row, Tick = Tick, Dot = Dot, Ring = ring,
		                  Lbl = RLbl, Scale = scale, Order = i }

		Row.MouseButton1Click:Connect(function()
			if multi then
				if selected[text] then selected[text] = nil else selected[text] = true end
			else
				selected = {}
				selected[text] = true
			end
			refreshRows()
			refreshLabel()
			if Options.OnChanged then
				if multi then
					local out = {}
					for _, val in ipairs(items) do if selected[val] then table.insert(out, val) end end
					Options.OnChanged(out)
				else
					Options.OnChanged(text)
				end
			end
			if not multi then setOpen(false) end
		end)
		Row.MouseEnter:Connect(function()
			if selected[text] then return end
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
			Row.BackgroundTransparency = 0
			TweenService:Create(Tick, TweenSpring, { Size = UDim2.new(0, 2, 0, 7) }):Play()
		end)
		Row.MouseLeave:Connect(function()
			if selected[text] then return end
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
			TweenService:Create(Tick, TweenFast, { Size = UDim2.new(0, 2, 0, 0) }):Play()
			task.delay(0.14, function()
				if not selected[text] then Row.BackgroundTransparency = 1 end
			end)
		end)
	end

	local function buildRows()
		for _, row in pairs(optRows) do
			if row.Row then row.Row:Destroy() end
		end
		optRows = {}
		for i, text in ipairs(items) do
			buildRow(i, text)
		end
	end

	buildRows()
	refreshLabel()
	AttachTooltip(Head, Options.Tooltip)

	Head.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)

	local function getValue()
		if multi then
			local out = {}
			for _, val in ipairs(items) do if selected[val] then table.insert(out, val) end end
			return out
		end
		for _, val in ipairs(items) do if selected[val] then return val end end
		return nil
	end

	if Options.Flag then
		Flags[Options.Flag] = {
			Kind = multi and "table" or "value",
			Get  = getValue,
			Set  = function(v)
				selected = {}
				if multi then
					if type(v) == "table" then
						for _, val in ipairs(v) do selected[val] = true end
					end
				else
					if type(v) == "number" then v = items[v] end
					if v ~= nil then selected[v] = true end
				end
				refreshRows()
				refreshLabel()
				if Options.OnChanged then Options.OnChanged(getValue()) end
			end,
		}
	end

	return {
		Frame    = Card,
		SetOpen  = setOpen,
		GetValue = getValue,
		-- Replace the option list. Selections for values that still
		-- exist are kept when keepSelection is true.
		SetItems = function(newItems, keepSelection)
			items = newItems or {}
			if keepSelection then
				local lookup = {}
				for _, val in ipairs(items) do lookup[val] = true end
				for val in pairs(selected) do
					if not lookup[val] then selected[val] = nil end
				end
			else
				selected = {}
			end
			buildRows()
			refreshLabel()
		end,
	}
end

-- ============================================================
-- CreateKeybind
-- A labeled row with a capture button; click it, then press a
-- key to bind it.
--
-- Options:
--   Label      string
--   Default    Enum.KeyCode | string   (e.g. Enum.KeyCode.E or "E")
--   OnChanged  function(keyCode)
--   Tooltip    string   Hover tooltip (optional)
--   Flag       string   Config key for SaveConfig/LoadConfig
--
--   Icon       string   Lucide icon before the label (optional)
-- Returns: { Frame, Set(keyCode), GetValue() }
-- ============================================================
function Skibidi.CreateKeybind(Parent, Options)
	Options = Options or {}
	local current = Options.Default
	if type(current) == "string" then
		current = Enum.KeyCode[current]
	end

	local Row = Instance.new("Frame")
	Row.Size             = UDim2.new(1, 0, 0, 34)
	Row.BackgroundColor3 = Theme.Bg2
	Row.BorderSizePixel  = 0
	Row.Parent           = Parent
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Row, Theme.AccentDim, 1)
	MakeGloss(Row, 0.10)

	local Lbl = Instance.new("TextLabel", Row)
	Lbl.Size                   = UDim2.new(1, -90, 1, 0)
	Lbl.Position               = UDim2.new(0, 12, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.BodySize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.Text                   = Options.Label or ""
	if Options.Icon then PrefixIcon(Lbl, Options.Icon, 14, Theme.TextPrimary) end

	local KeyBtn = Instance.new("TextButton", Row)
	KeyBtn.AnchorPoint            = Vector2.new(1, 0.5)
	KeyBtn.Position               = UDim2.new(1, -10, 0.5, 0)
	KeyBtn.Size                   = UDim2.new(0, 74, 0, Theme.ToggleH + 2)
	KeyBtn.BackgroundColor3       = Theme.InputBg
	KeyBtn.BorderSizePixel        = 0
	KeyBtn.Font                   = Theme.FontMedium
	KeyBtn.TextSize               = Theme.SmallSize
	KeyBtn.TextColor3             = Theme.AccentSec
	KeyBtn.AutoButtonColor        = false
	KeyBtn.Text                   = current and current.Name or "None"
	MakeCorner(KeyBtn, UDim.new(0, 5))
	local keyStroke = MakeEdge(KeyBtn, Theme.AccentDim, 1)
	MakeGloss(KeyBtn, 0.10)

	local listening = false
	local conn

	local function stopListening()
		listening = false
		TweenService:Create(keyStroke, TweenFast, { Color = EdgeRest(), Thickness = 1 }):Play()
		if conn then conn:Disconnect(); conn = nil end
	end
	-- If the row dies while capturing, drop the global InputBegan hook
	Row.Destroying:Connect(function()
		if conn then conn:Disconnect(); conn = nil end
	end)

	KeyBtn.MouseButton1Click:Connect(function()
		if listening then stopListening(); return end
		listening = true
		KeyBtn.Text = "..."
		TweenService:Create(keyStroke, TweenFast, { Color = Theme.Accent, Thickness = 1.5 }):Play()
		conn = UserInputService.InputBegan:Connect(function(inp)
			if inp.UserInputType == Enum.UserInputType.Keyboard then
				current = inp.KeyCode
				KeyBtn.Text = current.Name
				stopListening()
				if Options.OnChanged then Options.OnChanged(current) end
			end
		end)
	end)

	Row.MouseEnter:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
	end)
	Row.MouseLeave:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
	end)
	AttachTooltip(Row, Options.Tooltip)
	PlayEntrance(Row)

	if Options.Flag then
		Flags[Options.Flag] = {
			Kind = "keybind",
			Get  = function() return current and current.Name or nil end,
			Set  = function(v)
				local kc = v
				if type(kc) == "string" then
					local ok, parsed = pcall(function() return Enum.KeyCode[kc] end)
					kc = ok and parsed or nil
				end
				if typeof(kc) == "EnumItem" then
					current = kc
					KeyBtn.Text = kc.Name
					if Options.OnChanged then Options.OnChanged(current) end
				end
			end,
		}
	end

	return {
		Frame = Row,
		Set = function(kc)
			current = kc
			KeyBtn.Text = kc and kc.Name or "None"
		end,
		GetValue = function() return current end,
	}
end

-- ============================================================
-- CreateCode
-- A monospace code block with an optional language tag and
-- copy-to-clipboard button.
--
-- Options:
--   Text       string   The code contents
--   Language   string   Optional language label (e.g. "lua")
--   Height     number   Fixed scrollable height (default: auto-fit)
--
-- Returns: { Frame, SetText(text) }
-- ============================================================
function Skibidi.CreateCode(Parent, Options)
	Options = Options or {}
	local fixedH = Options.Height

	local hasHeader = Options.Language and Options.Language ~= ""

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, fixedH and (fixedH + (hasHeader and 22 or 0)) or 0)
	Card.AutomaticSize     = fixedH and Enum.AutomaticSize.None or Enum.AutomaticSize.Y
	Card.BackgroundColor3  = Theme.Bg3
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Card, Theme.AccentDim, 1)
	MakeGloss(Card, 0.10)
	local CardLayout = Instance.new("UIListLayout", Card)
	CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	CardLayout.Padding   = UDim.new(0, 0)
	if hasHeader then
		local HeaderRow = Instance.new("Frame", Card)
		HeaderRow.Size             = UDim2.new(1, 0, 0, 24)
		HeaderRow.LayoutOrder      = 0
		HeaderRow.BackgroundColor3 = Theme.Bg2
		HeaderRow.BorderSizePixel  = 0
		MakeGloss(HeaderRow, 0.16)

		local LangLbl = Instance.new("TextLabel", HeaderRow)
		LangLbl.Size                   = UDim2.new(1, -54, 1, 0)
		LangLbl.Position               = UDim2.new(0, 10, 0, 0)
		LangLbl.BackgroundTransparency = 1
		LangLbl.Font                   = Theme.FontMedium
		LangLbl.TextSize               = Theme.CaptionSize
		LangLbl.TextColor3             = Theme.TextMuted
		LangLbl.TextXAlignment         = Enum.TextXAlignment.Left
		LangLbl.Text                   = string.upper(Options.Language)

		local CopyBtn = Instance.new("TextButton", HeaderRow)
		CopyBtn.Size                   = UDim2.new(0, 44, 1, -6)
		CopyBtn.Position               = UDim2.new(1, -48, 0, 3)
		CopyBtn.BackgroundColor3       = Theme.Bg3
		CopyBtn.BorderSizePixel        = 0
		CopyBtn.Font                   = Theme.FontMedium
		CopyBtn.TextSize               = 10
		CopyBtn.TextColor3             = Theme.TextMuted
		CopyBtn.Text                   = "Copy"
		CopyBtn.AutoButtonColor        = false
		MakeCorner(CopyBtn, UDim.new(0, 5))
		MakeEdge(CopyBtn, Theme.AccentDim, 1)
		MakeRipple(CopyBtn, Theme.Accent, 5)

		CopyBtn.MouseEnter:Connect(function()
			TweenService:Create(CopyBtn, TweenFast, { TextColor3 = Theme.Accent }):Play()
		end)
		CopyBtn.MouseLeave:Connect(function()
			TweenService:Create(CopyBtn, TweenFast, { TextColor3 = Theme.TextMuted }):Play()
		end)

		CopyBtn.MouseButton1Click:Connect(function()
			if setclipboard then
				pcall(setclipboard, Options.Text or "")
				CopyBtn.Text       = "Copied"
				CopyBtn.TextColor3 = Theme.Success
				task.delay(1, function()
					if not CopyBtn.Parent then return end
					CopyBtn.Text       = "Copy"
					CopyBtn.TextColor3 = Theme.TextMuted
				end)
			end
		end)
	end

	local Scroll = Instance.new("ScrollingFrame", Card)
	Scroll.LayoutOrder            = 1
	Scroll.BackgroundTransparency = 1
	Scroll.BorderSizePixel        = 0
	Scroll.ScrollBarThickness     = 3
	Scroll.ScrollBarImageColor3   = Theme.AccentDim
	Scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
	Scroll.ClipsDescendants       = true
	if fixedH then
		Scroll.Size                = UDim2.new(1, 0, 0, fixedH)
		Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	else
		Scroll.Size                = UDim2.new(1, 0, 0, 0)
		Scroll.AutomaticSize       = Enum.AutomaticSize.Y
		Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	end
	MakePadding(Scroll, 10, 10, 8, 8)

	local CodeLbl = Instance.new("TextLabel", Scroll)
	CodeLbl.Size                   = UDim2.new(1, -20, 0, 0)
	CodeLbl.AutomaticSize          = Enum.AutomaticSize.Y
	CodeLbl.BackgroundTransparency = 1
	CodeLbl.Font                   = Enum.Font.Code
	CodeLbl.TextSize               = Theme.SmallSize
	CodeLbl.TextColor3             = Theme.TextPrimary
	CodeLbl.TextXAlignment         = Enum.TextXAlignment.Left
	CodeLbl.TextYAlignment         = Enum.TextYAlignment.Top
	CodeLbl.TextWrapped            = true
	CodeLbl.Text                   = Options.Text or ""

	return {
		Frame   = Card,
		SetText = function(t) CodeLbl.Text = t end,
	}
end

-- ============================================================
-- CreateImage
-- A bordered image display.
--
-- Options:
--   Image       string          Asset id, e.g. "rbxassetid://123..."
--   Height      number          (default 150)
--   ScaleType   Enum.ScaleType  (default Fit)
--
-- Returns: { Frame, Image, SetImage(id) }
-- ============================================================
function Skibidi.CreateImage(Parent, Options)
	Options = Options or {}
	local h = Options.Height or 150

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, h)
	Card.BackgroundColor3  = Theme.Bg3
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Card, Theme.AccentDim, 1)
	MakeGloss(Card, 0.10)

	local Img = Instance.new("ImageLabel", Card)
	Img.Size                   = UDim2.new(1, 0, 1, 0)
	Img.BackgroundTransparency = 1
	Img.Image                  = Options.Image or ""
	Img.ScaleType               = Options.ScaleType or Enum.ScaleType.Fit

	return {
		Frame    = Card,
		Image    = Img,
		SetImage = function(id) Img.Image = id end,
	}
end

-- ============================================================
-- CreateVideo
-- A bordered video player with a play/pause control.
--
-- Options:
--   Video      string   Asset id, e.g. "rbxassetid://123..."
--   Height     number   (default 180)
--   Looped     bool     (default false)
--   Volume     number   (default 1)
--   Autoplay   bool     (default false)
--
-- Returns: { Frame, Video, Play(), Pause() }
-- ============================================================
function Skibidi.CreateVideo(Parent, Options)
	Options = Options or {}
	local h = Options.Height or 180

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, h + 30)
	Card.BackgroundColor3  = Theme.Bg3
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Card, Theme.AccentDim, 1)
	MakeGloss(Card, 0.10)

	local Vid = Instance.new("VideoFrame", Card)
	Vid.Size             = UDim2.new(1, 0, 0, h)
	Vid.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Vid.BorderSizePixel  = 0
	Vid.Video            = Options.Video or ""
	Vid.Looped           = Options.Looped == true
	Vid.Volume           = Options.Volume or 1

	local Controls = Instance.new("Frame", Card)
	Controls.Position               = UDim2.new(0, 0, 0, h)
	Controls.Size                   = UDim2.new(1, 0, 0, 30)
	Controls.BackgroundTransparency = 1

	local PlayBtn = Instance.new("TextButton", Controls)
	PlayBtn.Size             = UDim2.new(0, 60, 0, 22)
	PlayBtn.Position         = UDim2.new(0, 8, 0.5, -11)
	PlayBtn.BackgroundColor3 = Theme.Bg2
	PlayBtn.BorderSizePixel  = 0
	PlayBtn.Font             = Theme.FontMedium
	PlayBtn.TextSize         = Theme.SmallSize
	PlayBtn.TextColor3       = Theme.TextPrimary
	PlayBtn.Text             = "Play"
	PlayBtn.AutoButtonColor  = false
	MakeCorner(PlayBtn, UDim.new(0, 5))
	MakeEdge(PlayBtn, Theme.AccentDim, 1)
	MakeGloss(PlayBtn, 0.10)

	local function updateBtn()
		PlayBtn.Text = Vid.Playing and "Pause" or "Play"
	end

	local function Play() Vid:Play(); updateBtn() end
	local function Pause() Vid:Pause(); updateBtn() end

	PlayBtn.MouseButton1Click:Connect(function()
		if Vid.Playing then Pause() else Play() end
	end)

	if Options.Autoplay then Play() else updateBtn() end

	return { Frame = Card, Video = Vid, Play = Play, Pause = Pause }
end

-- ============================================================
-- CreateViewport
-- A ViewportFrame for previewing a 3D model, with optional
-- auto-rotate.
--
-- Options:
--   Model        Instance   A Model/BasePart to clone into the viewport
--   Height       number     (default 180)
--   AutoRotate   bool       (default false)
--
-- Returns: { Frame, Viewport, Camera, SetModel(instance) }
-- ============================================================
function Skibidi.CreateViewport(Parent, Options)
	Options = Options or {}
	local h = Options.Height or 180

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, h)
	Card.BackgroundColor3  = Options.BackgroundColor3 or Theme.Bg3
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Card, Theme.AccentDim, 1)
	MakeGloss(Card, 0.10)

	local VP = Instance.new("ViewportFrame", Card)
	VP.Size                   = UDim2.new(1, 0, 1, 0)
	VP.BackgroundTransparency = 1

	local Cam = Instance.new("Camera", VP)
	VP.CurrentCamera = Cam

	local modelClone
	local rotConn

	local function frameCamera(target)
		local cf, size = target:GetBoundingBox()
		local dist = math.max(size.Magnitude, 4)
		Cam.CFrame = CFrame.new(cf.Position + Vector3.new(0, size.Y * 0.2, dist), cf.Position)
	end

	local function SetModel(model)
		if modelClone then modelClone:Destroy() end
		if rotConn then rotConn:Disconnect(); rotConn = nil end
		if not model then return end
		modelClone = model:Clone()
		modelClone.Parent = VP
		task.defer(function()
			local ok = pcall(frameCamera, modelClone)
			if not ok then
				Cam.CFrame = CFrame.new(Vector3.new(0, 0, 10), Vector3.new(0, 0, 0))
			end
			if Options.AutoRotate then
				local angle = 0
				rotConn = RunService.RenderStepped:Connect(function(dt)
					angle = angle + dt * 0.5
					local ok2, cf2, size2 = pcall(function() return modelClone:GetBoundingBox() end)
					if ok2 then
						local dist2 = math.max(size2.Magnitude, 4)
						Cam.CFrame = CFrame.new(
							cf2.Position + Vector3.new(math.sin(angle) * dist2, size2.Y * 0.2, math.cos(angle) * dist2),
							cf2.Position)
					end
				end)
			end
		end)
	end

	if Options.Model then SetModel(Options.Model) end

	return { Frame = Card, Viewport = VP, Camera = Cam, SetModel = SetModel }
end

-- ============================================================
-- CreateColorPicker
-- A labeled swatch that expands into a saturation/value box,
-- a hue slider, and a hex input.
--
-- Options:
--   Label      string
--   Default    Color3    (default white)
--   OnChanged  function(color3)
--   Tooltip    string    Hover tooltip (optional)
--   Flag       string    Config key for SaveConfig/LoadConfig
--
--   Icon       string   Lucide icon before the label (optional)
-- Returns: { Frame, SetOpen(bool), SetValue(color3), GetValue() }
-- ============================================================
function Skibidi.CreateColorPicker(Parent, Options)
	Options = Options or {}
	local current = Options.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = Color3.toHSV(current)

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, 0)
	Card.AutomaticSize     = Enum.AutomaticSize.Y
	Card.BackgroundColor3  = Theme.Bg2
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
	MakeEdge(Card, Theme.AccentDim, 1)
	MakeGloss(Card, 0.10)
	local CardLayout = Instance.new("UIListLayout", Card)
	CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	CardLayout.Padding   = UDim.new(0, 0)

	local Head = Instance.new("TextButton", Card)
	Head.Size                   = UDim2.new(1, 0, 0, 34)
	Head.LayoutOrder            = 0
	Head.BackgroundTransparency = 1
	Head.AutoButtonColor        = false
	Head.Text                   = ""
	MakeHoverFill(Head, 3, 5)

	local Lbl = Instance.new("TextLabel", Head)
	Lbl.Size                   = UDim2.new(1, -60, 1, 0)
	Lbl.Position               = UDim2.new(0, 12, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.BodySize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.Text                   = Options.Label or ""
	if Options.Icon then PrefixIcon(Lbl, Options.Icon, 14, Theme.TextPrimary) end

	local Swatch = Instance.new("Frame", Head)
	Swatch.AnchorPoint      = Vector2.new(1, 0.5)
	Swatch.Position         = UDim2.new(1, -10, 0.5, 0)
	Swatch.Size             = UDim2.new(0, 36, 0, 20)
	Swatch.BackgroundColor3 = current
	Swatch.BorderSizePixel  = 0
	MakeCorner(Swatch, UDim.new(0, 6))
	MakeEdge(Swatch, Theme.AccentDim, 1)
	-- The swatch blooms in whatever colour it is currently showing, which
	-- doubles as a preview of that colour against the panel surface.
	local SwatchGlow = MakeInnerGlow(Swatch, current, 9, 0.55)

	local Panel = Instance.new("Frame", Card)
	Panel.Size                   = UDim2.new(1, 0, 0, 0)
	Panel.AutomaticSize          = Enum.AutomaticSize.Y
	Panel.LayoutOrder            = 1
	Panel.BackgroundTransparency = 1
	Panel.Visible                = false
	MakePadding(Panel, 10, 10, 4, 10)
	MakeListLayout(Panel, Enum.FillDirection.Vertical, 8)

	local SVBox = Instance.new("Frame", Panel)
	SVBox.Size              = UDim2.new(1, 0, 0, 90)
	SVBox.LayoutOrder        = 0
	SVBox.BackgroundColor3  = Color3.fromHSV(h, 1, 1)
	SVBox.BorderSizePixel   = 0
	SVBox.ClipsDescendants  = true
	MakeCorner(SVBox, UDim.new(0, 6))
	MakeStroke(SVBox, Theme.AccentDim, 1).Transparency = 0.4

	local SatOverlay = Instance.new("Frame", SVBox)
	SatOverlay.Size             = UDim2.new(1, 0, 1, 0)
	SatOverlay.BackgroundColor3 = Color3.new(1, 1, 1)
	SatOverlay.BorderSizePixel  = 0
	local satGrad = Instance.new("UIGradient", SatOverlay)
	satGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})

	local ValOverlay = Instance.new("Frame", SVBox)
	ValOverlay.Size             = UDim2.new(1, 0, 1, 0)
	ValOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
	ValOverlay.BorderSizePixel  = 0
	local valGrad = Instance.new("UIGradient", ValOverlay)
	valGrad.Rotation = 90
	valGrad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0),
	})

	local SVCursor = Instance.new("Frame", SVBox)
	SVCursor.Size             = UDim2.new(0, 10, 0, 10)
	SVCursor.AnchorPoint      = Vector2.new(0.5, 0.5)
	SVCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	SVCursor.BorderSizePixel  = 0
	SVCursor.ZIndex           = 2
	MakeCorner(SVCursor, UDim.new(1, 0))
	MakeStroke(SVCursor, Color3.new(0, 0, 0), 1.5)

	local HueTrack = Instance.new("Frame", Panel)
	HueTrack.Size            = UDim2.new(1, 0, 0, 14)
	HueTrack.LayoutOrder     = 1
	HueTrack.BorderSizePixel = 0
	MakeCorner(HueTrack, UDim.new(1, 0))
	local hueGrad = Instance.new("UIGradient", HueTrack)
	hueGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.000, Color3.fromHSV(0 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.166, Color3.fromHSV(1 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.333, Color3.fromHSV(2 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.500, Color3.fromHSV(3 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.666, Color3.fromHSV(4 / 6, 1, 1)),
		ColorSequenceKeypoint.new(0.833, Color3.fromHSV(5 / 6, 1, 1)),
		ColorSequenceKeypoint.new(1.000, Color3.fromHSV(6 / 6, 1, 1)),
	})

	local HueCursor = Instance.new("Frame", HueTrack)
	HueCursor.Size             = UDim2.new(0, 4, 1, 4)
	HueCursor.AnchorPoint      = Vector2.new(0.5, 0.5)
	HueCursor.Position         = UDim2.new(h, 0, 0.5, 0)
	HueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
	HueCursor.BorderSizePixel  = 0
	MakeCorner(HueCursor, UDim.new(0, 2))
	MakeStroke(HueCursor, Color3.new(0, 0, 0), 1)

	local HexBox = Instance.new("TextBox", Panel)
	HexBox.Size              = UDim2.new(1, 0, 0, 24)
	HexBox.LayoutOrder       = 2
	HexBox.BackgroundColor3  = Theme.InputBg
	HexBox.BorderSizePixel   = 0
	HexBox.Font              = Theme.FontMedium
	HexBox.TextSize          = Theme.SmallSize
	HexBox.TextColor3        = Theme.AccentSec
	HexBox.ClearTextOnFocus  = false
	MakeCorner(HexBox, UDim.new(0, 5))
	local hexStroke = MakeEdge(HexBox, Theme.AccentDim, 1)
	MakeGloss(HexBox, 0.10)

	HexBox.Focused:Connect(function()
		TweenService:Create(hexStroke, TweenFast, { Color = Theme.Accent, Thickness = 1.5 }):Play()
	end)

	local function updateFromHSV(fireEvent)
		current = Color3.fromHSV(h, s, v)
		Swatch.BackgroundColor3 = current
		if SwatchGlow then SwatchGlow.SetColor(current) end
		SVBox.BackgroundColor3  = Color3.fromHSV(h, 1, 1)
		SVCursor.Position       = UDim2.new(s, 0, 1 - v, 0)
		HueCursor.Position      = UDim2.new(h, 0, 0.5, 0)
		HexBox.Text             = string.format("#%02X%02X%02X",
			math.floor(current.R * 255 + 0.5),
			math.floor(current.G * 255 + 0.5),
			math.floor(current.B * 255 + 0.5))
		if fireEvent and Options.OnChanged then Options.OnChanged(current) end
	end
	updateFromHSV(false)

	local draggingSV, draggingHue = false, false

	local function jumpSV(pos)
		local rel = Vector2.new(
			(pos.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X,
			(pos.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y)
		s = math.clamp(rel.X, 0, 1)
		v = 1 - math.clamp(rel.Y, 0, 1)
		updateFromHSV(true)
	end
	local function jumpHue(pos)
		local rel = (pos.X - HueTrack.AbsolutePosition.X) / HueTrack.AbsoluteSize.X
		h = math.clamp(rel, 0, 1)
		updateFromHSV(true)
	end

	SVBox.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			draggingSV = true
			jumpSV(inp.Position)
		end
	end)
	HueTrack.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			draggingHue = true
			jumpHue(inp.Position)
		end
	end)
	ConnectScoped(Card, UserInputService.InputEnded, function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			draggingSV, draggingHue = false, false
		end
	end)
	ConnectScoped(Card, UserInputService.InputChanged, function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		if draggingSV then jumpSV(inp.Position)
		elseif draggingHue then jumpHue(inp.Position) end
	end)

	HexBox.FocusLost:Connect(function()
		TweenService:Create(hexStroke, TweenFast, { Color = EdgeRest(), Thickness = 1 }):Play()
		local hex = string.gsub(HexBox.Text, "#", "")
		if #hex == 6 and string.match(hex, "^%x+$") then
			local r = tonumber(string.sub(hex, 1, 2), 16) / 255
			local g = tonumber(string.sub(hex, 3, 4), 16) / 255
			local b = tonumber(string.sub(hex, 5, 6), 16) / 255
			h, s, v = Color3.toHSV(Color3.new(r, g, b))
			updateFromHSV(true)
		else
			updateFromHSV(false)
		end
	end)

	local isOpen = false
	local function setOpen(open)
		isOpen = open
		Panel.Visible = open
		if open then
			OverlayOpened(Card, function() setOpen(false) end)
		else
			OverlayClosed(Card)
		end
	end
	Card.Destroying:Connect(function() OverlayClosed(Card) end)

	Head.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)
	AttachTooltip(Head, Options.Tooltip)

	if Options.Flag then
		Flags[Options.Flag] = {
			Kind = "color",
			Get  = function() return current end,
			Set  = function(c)
				if typeof(c) == "Color3" then
					h, s, v = Color3.toHSV(c)
					updateFromHSV(true)
				end
			end,
		}
	end

	return {
		Frame    = Card,
		SetOpen  = setOpen,
		SetValue = function(c)
			h, s, v = Color3.toHSV(c)
			updateFromHSV(false)
		end,
		GetValue = function() return current end,
	}
end

-- ============================================================
-- Init
-- Optional bootstrap call. Lets you override theme values and
-- set a default Parent for future CreatePanel calls in one go,
-- without having to reach into Skibidi.Theme directly.
--
-- Options:
--   Theme    table      Partial theme override, merged into Skibidi.Theme
--   Parent   Instance   Default parent for new panels (default PlayerGui)
--
-- Returns: Skibidi (so calls can be chained, e.g.
--   Skibidi.Init({ Theme = { Accent = Color3.fromRGB(120,80,220) } }).CreatePanel({...})
-- ============================================================
function Skibidi.Init(Options)
	Options = Options or {}
	if Options.Theme then
		for k, val in pairs(Options.Theme) do
			Theme[k] = val
		end
	end
	if Options.Parent then
		DefaultParent = Options.Parent
	end
	return Skibidi
end

-- ============================================================
-- SaveConfig / LoadConfig
-- Optional persistence for component values, backed by the
-- executor's writefile/readfile. Both are safe no-ops (returning
-- false + a reason) when the executor doesn't support file APIs,
-- so scripts that never call them — or run without file access —
-- are completely unaffected.
--
-- To opt a component in, give it a Flag key at creation:
--   Skibidi.CreateToggle(tab, { Label = "ESP", Flag = "esp", ... })
-- Supported: Toggle (bool), Slider (number), TextInput (string),
-- Dropdown (string / array if Multi), Keybind (key name string),
-- ColorPicker (RGB table), Group (index), InputList (array).
--
--   Skibidi.SaveConfig(name)  → true  |  false, err
--   Skibidi.LoadConfig(name)  → true  |  false, err
--
-- `name` defaults to "UILibConfig"; files are stored as
-- "<name>.json" in the executor's workspace folder. Loading
-- applies each saved value through the component's setter and
-- fires its OnChanged/OnSubmit so consuming scripts stay in sync.
-- ============================================================
local function configFileName(name)
	return tostring(name or "UILibConfig") .. ".json"
end

function Skibidi.SaveConfig(name)
	if type(writefile) ~= "function" then
		return false, "writefile is not supported by this executor"
	end
	local data = {}
	for flag, entry in pairs(Flags) do
		local ok, v = pcall(entry.Get)
		if ok and v ~= nil then
			if entry.Kind == "color" then
				v = {
					R = math.floor(v.R * 255 + 0.5),
					G = math.floor(v.G * 255 + 0.5),
					B = math.floor(v.B * 255 + 0.5),
				}
			end
			data[flag] = v
		end
	end
	local okEncode, json = pcall(HttpService.JSONEncode, HttpService, data)
	if not okEncode then return false, json end
	local okWrite, err = pcall(writefile, configFileName(name), json)
	if not okWrite then return false, err end
	return true
end

function Skibidi.LoadConfig(name)
	if type(readfile) ~= "function" then
		return false, "readfile is not supported by this executor"
	end
	local file = configFileName(name)
	if type(isfile) == "function" and not isfile(file) then
		return false, "no such config: " .. file
	end
	local okRead, json = pcall(readfile, file)
	if not okRead then return false, json end
	local okDecode, data = pcall(HttpService.JSONDecode, HttpService, json)
	if not okDecode or type(data) ~= "table" then
		return false, "invalid config file: " .. file
	end
	for flag, v in pairs(data) do
		local entry = Flags[flag]
		if entry then
			if entry.Kind == "color" and type(v) == "table" then
				v = Color3.fromRGB(v.R or 255, v.G or 255, v.B or 255)
			end
			pcall(entry.Set, v)
		end
	end
	return true
end

-- ============================================================
-- CreateLabel
-- A lightweight single-line text row — for captions, hints and
-- section lead-ins that don't need a full Paragraph card.
--
-- Options:
--   Text       string
--   Color      Color3                    (default Theme.TextMuted)
--   TextSize   number                    (default Theme.SmallSize)
--   Font       Enum.Font                 (default Theme.FontRegular)
--   Alignment  Enum.TextXAlignment       (default Left)
--   Height     number                    (default 18)
--   Icon       string   Lucide icon before the text (optional)
--
-- Returns: { Frame, Label, SetText(text) }
-- ============================================================
function Skibidi.CreateLabel(Parent, Options)
	Options = Options or {}

	local Lbl = Instance.new("TextLabel")
	Lbl.Size                   = UDim2.new(1, 0, 0, Options.Height or 18)
	Lbl.BackgroundTransparency = 1
	Lbl.BorderSizePixel        = 0
	Lbl.Font                   = Options.Font or Theme.FontRegular
	Lbl.TextSize               = Options.TextSize or Theme.SmallSize
	Lbl.TextColor3             = Options.Color or Theme.TextMuted
	Lbl.TextXAlignment         = Options.Alignment or Enum.TextXAlignment.Left
	Lbl.TextTruncate           = Enum.TextTruncate.AtEnd
	Lbl.Text                   = Options.Text or ""
	Lbl.Parent                 = Parent
	if Options.Icon then PadIcon(Lbl, Options.Icon, 14, Lbl.TextColor3) end

	return {
		Frame   = Lbl,
		Label   = Lbl,
		SetText = function(t) Lbl.Text = t or "" end,
	}
end

-- ============================================================
-- CreateKeyValue
-- A compact stat row: muted key on the left, highlighted value
-- on the right. Ideal for live status readouts.
--
-- Options:
--   Label      string
--   Value      string | number   Initial value (default "-")
--   Tooltip    string            Hover tooltip (optional)
--
--   Icon       string   Lucide icon before the label (optional)
-- Returns: { Frame, SetValue(v), SetLabel(t), GetValue() }
-- ============================================================
function Skibidi.CreateKeyValue(Parent, Options)
	Options = Options or {}
	local value = Options.Value ~= nil and tostring(Options.Value) or "-"

	local Row = Instance.new("Frame")
	Row.Size             = UDim2.new(1, 0, 0, 26)
	Row.BackgroundColor3 = Theme.Bg2
	Row.BorderSizePixel  = 0
	Row.Parent           = Parent
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusXs))
	MakeEdge(Row, Theme.AccentDim, 1)
	MakeGloss(Row, 0.10)

	local KeyLbl = Instance.new("TextLabel", Row)
	KeyLbl.Size                   = UDim2.new(0.5, -18, 1, 0)
	KeyLbl.Position               = UDim2.new(0, 16, 0, 0)
	KeyLbl.BackgroundTransparency = 1
	KeyLbl.Font                   = Theme.FontRegular
	KeyLbl.TextSize               = Theme.SmallSize
	KeyLbl.TextColor3             = Theme.TextMuted
	KeyLbl.TextXAlignment         = Enum.TextXAlignment.Left
	KeyLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	KeyLbl.Text                   = Options.Label or ""
	if Options.Icon then PrefixIcon(KeyLbl, Options.Icon, 14, Theme.TextMuted) end

	local ValLbl = Instance.new("TextLabel", Row)
	ValLbl.Size                   = UDim2.new(0.5, -14, 1, 0)
	ValLbl.Position               = UDim2.new(0.5, 2, 0, 0)
	ValLbl.BackgroundTransparency = 1
	ValLbl.Font                   = Theme.FontMedium
	ValLbl.TextSize               = Theme.SmallSize
	ValLbl.TextColor3             = Theme.AccentSec
	ValLbl.TextXAlignment         = Enum.TextXAlignment.Right
	ValLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	ValLbl.Text                   = value

	-- A stat row is read in bulk, so it gets a marker rather than a
	-- border: the eye can run down a column of ticks far faster than it
	-- can pick labels out of a stack of identical boxes.
	local Tick = Instance.new("Frame", Row)
	Tick.AnchorPoint      = Vector2.new(0, 0.5)
	Tick.Size             = UDim2.new(0, 2, 0, 10)
	Tick.Position         = UDim2.new(0, 7, 0.5, 0)
	Tick.BackgroundColor3 = Theme.Accent
	Tick.BackgroundTransparency = 0.35
	Tick.BorderSizePixel  = 0
	MakeCorner(Tick, UDim.new(1, 0))

	Row.MouseEnter:Connect(function()
		TweenService:Create(Row,  TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
		TweenService:Create(Tick, TweenSpring,
			{ Size = UDim2.new(0, 2, 0, 16), BackgroundTransparency = 0 }):Play()
	end)
	Row.MouseLeave:Connect(function()
		TweenService:Create(Row,  TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
		TweenService:Create(Tick, TweenFast,
			{ Size = UDim2.new(0, 2, 0, 10), BackgroundTransparency = 0.35 }):Play()
	end)

	AttachTooltip(Row, Options.Tooltip)
	PlayEntrance(Row)

	return {
		Frame    = Row,
		SetValue = function(v)
			value = tostring(v)
			ValLbl.Text = value
			-- A value that just changed should say so; the flash decays
			-- back to the resting colour on its own.
			ValLbl.TextColor3 = Lighten(Theme.AccentSec, 0.2)
			TweenService:Create(ValLbl, TweenSoft,
				{ TextColor3 = Theme.AccentSec }):Play()
		end,
		SetLabel = function(t) KeyLbl.Text = t or "" end,
		GetValue = function() return value end,
	}
end

-- ============================================================
-- Unload
-- Destroys every panel, notification and tooltip the library has
-- created and clears internal state. Safe to call multiple times.
-- ============================================================
function Skibidi.Unload()
	for _, g in ipairs(_allGuis) do
		if g and g.Parent then g:Destroy() end
	end
	_allGuis = {}
	if _notifSg then _notifSg:Destroy(); _notifSg = nil end
	_notifList = {}
	if _tooltipSg then _tooltipSg:Destroy(); _tooltipSg = nil end
	_tooltipFrame, _tooltipLbl = nil, nil
	if _overlayWatch then _overlayWatch:Disconnect(); _overlayWatch = nil end
	_openOverlay = nil
	for k in pairs(Flags) do Flags[k] = nil end
end

-- ============================================================
-- Convenience lowercase aliases
-- Exposes each component under a short name in addition to the
-- primary CreateXxx API, without altering how the components
-- themselves are implemented.
-- ============================================================
Skibidi.init        = Skibidi.Init
Skibidi.unload      = Skibidi.Unload
Skibidi.saveconfig  = Skibidi.SaveConfig
Skibidi.loadconfig  = Skibidi.LoadConfig
Skibidi.notify      = Skibidi.ShowNotification
Skibidi.label       = Skibidi.CreateLabel
Skibidi.keyvalue    = Skibidi.CreateKeyValue
Skibidi.button      = Skibidi.CreateButton
Skibidi.code        = Skibidi.CreateCode
Skibidi.colorpicker = Skibidi.CreateColorPicker
Skibidi.divider     = Skibidi.CreateDivider
Skibidi.dropdown    = Skibidi.CreateDropdown
Skibidi.group       = Skibidi.CreateGroup
Skibidi.hstack      = Skibidi.CreateHStack
Skibidi.image       = Skibidi.CreateImage
Skibidi.input       = Skibidi.CreateTextInput
Skibidi.keybind     = Skibidi.CreateKeybind
Skibidi.paragraph   = Skibidi.CreateParagraph
Skibidi.progressbar = Skibidi.CreateProgressBar
Skibidi.section     = Skibidi.CreateSection
Skibidi.slider      = Skibidi.CreateSlider
Skibidi.space       = Skibidi.CreateSpace
Skibidi.toggle      = Skibidi.CreateToggle
Skibidi.vstack      = Skibidi.CreateVStack
Skibidi.video       = Skibidi.CreateVideo
Skibidi.viewport    = Skibidi.CreateViewport

return Skibidi
