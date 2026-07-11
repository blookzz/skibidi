-- ============================================================
-- UILib.lua  |  Self-contained loadstring library
-- Usage:
--   local UILib = loadstring(game:HttpGet("YOUR_RAW_URL"))()
-- ============================================================

local UILib = {}

-- ============================================================
-- SERVICES
-- ============================================================
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer
local PlayerGui        = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- THEME  (matches the gold/dark reference style by default)
-- Override any key before calling Create functions:
--   UILib.Theme.Accent = Color3.fromRGB(120, 80, 220)
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
	Padding          = 10,
	PaddingSmall     = 6,
	FontBold         = Enum.Font.GothamBlack,
	FontMedium       = Enum.Font.GothamBold,
	FontRegular      = Enum.Font.Gotham,
	TitleSize        = 14,
	BodySize         = 13,
	SmallSize        = 12,
	CaptionSize      = 11,
}
UILib.Theme = Theme

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================
local TweenFast = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenMed  = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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
-- CreatePanel
-- Creates a draggable panel with optional tab bar.
--
-- Options:
--   Name         string    ScreenGui name              (default "Panel")
--   Title        string    Header title text           (default "")
--   Width        number    Width in pixels             (default 310)
--   Height       number    Content height in pixels    (default 300)
--   Tabs         table     Array of tab name strings   (optional — omit for no tabs)
--   DefaultTab   number    Initially active tab index  (default 1)
--   Variant      string    "gold"|"blue"|"green"|"red" (optional)
--   Minimized    bool      Start minimized             (default false)
--
-- Returns:
--   {
--     Gui, Frame, Header, TitleLabel,
--     Content,           -- Frame/ScrollingFrame for the active content area
--                        --   (if Tabs given, this is the current tab's frame)
--     GetTab(index),     -- returns the Frame for tab[index]  (nil if no tabs)
--     SetTab(index),     -- switches active tab
--     GetActiveTab(),    -- returns current tab index
--   }
-- ============================================================
function UILib.CreatePanel(Options)
	Options = Options or {}

	local Width      = Options.Width  or 310
	local Tabs       = Options.Tabs   -- nil = no tab bar
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

	-- Height constants
	local HEADER_H   = Theme.HeaderHeight
	local TABBAR_H   = hasTabs and Theme.TabHeight or 0
	local CONTENT_H  = Options.Height or 300
	local FULL_H     = HEADER_H + TABBAR_H + CONTENT_H
	local MIN_H      = HEADER_H   -- exact fit when minimized

	-- ── ScreenGui ──────────────────────────────────────────
	local Gui = Instance.new("ScreenGui")
	Gui.Name           = Options.Name or "Panel"
	Gui.ResetOnSpawn   = false
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Gui.Parent         = Options.Parent or PlayerGui

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
	MakeStroke(Frame, Accent, 1.2)

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

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size                   = UDim2.new(1, -52, 1, 0)
	TitleLabel.Position               = UDim2.new(0, 14, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font                   = Theme.FontBold
	TitleLabel.TextSize               = Theme.TitleSize
	TitleLabel.TextColor3             = Theme.AccentSec
	TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	TitleLabel.Text                   = Options.Title or ""
	TitleLabel.ZIndex                 = 3
	TitleLabel.Parent                 = Header

	-- Accent underline on header
	local AccentLine = Instance.new("Frame")
	AccentLine.Size                   = UDim2.new(1, -20, 0, 1)
	AccentLine.Position               = UDim2.new(0, 10, 1, -1)
	AccentLine.BackgroundColor3       = Accent
	AccentLine.BackgroundTransparency = 0.5
	AccentLine.BorderSizePixel        = 0
	AccentLine.ZIndex                 = 3
	AccentLine.Parent                 = Header

	-- Minimize button
	local MinBtn = Instance.new("TextButton")
	MinBtn.Size                   = UDim2.new(0, 28, 0, 20)
	MinBtn.AnchorPoint            = Vector2.new(1, 0.5)
	MinBtn.Position               = UDim2.new(1, -8, 0.5, 0)
	MinBtn.BackgroundColor3       = AccentDim
	MinBtn.BorderSizePixel        = 0
	MinBtn.Font                   = Theme.FontBold
	MinBtn.TextSize               = Theme.TitleSize
	MinBtn.TextColor3             = Theme.AccentSec
	MinBtn.Text                   = "–"
	MinBtn.AutoButtonColor        = false
	MinBtn.ZIndex                 = 4
	MinBtn.Parent                 = Header
	MakeCorner(MinBtn, UDim.new(0, 5))

	-- ── Tab bar (optional) ─────────────────────────────────
	local TabBar, TabBtns, TabUnderline
	if hasTabs then
		TabBar = Instance.new("Frame")
		TabBar.Position               = UDim2.new(0, 0, 0, HEADER_H)
		TabBar.Size                   = UDim2.new(1, 0, 0, TABBAR_H)
		TabBar.BackgroundTransparency = 1
		TabBar.ZIndex                 = 2
		TabBar.Parent                 = Frame
		MakePadding(TabBar, 10, 10, 11, 2)
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

		TabBtns = {}
		for i, name in ipairs(Tabs) do
			local btn = Instance.new("TextButton")
			btn.Size              = UDim2.new(0, 0, 1, 0)
			btn.AutomaticSize     = Enum.AutomaticSize.X
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
			MakeCorner(btn, UDim.new(0, 6))
			MakeStroke(btn, AccentDim, 1)
			local fit = Instance.new("UITextSizeConstraint", btn)
			fit.MaxTextSize = 12; fit.MinTextSize = 8
			TabBtns[i] = btn
		end
	end

	-- ── Content area ───────────────────────────────────────
	-- One scrolling frame per tab (or just one if no tabs)
	local tabCount  = hasTabs and #Tabs or 1
	local tabFrames = {}

	for i = 1, tabCount do
		local sf = Instance.new("ScrollingFrame")
		sf.Position               = UDim2.new(0, 0, 0, HEADER_H + TABBAR_H)
		sf.Size                   = UDim2.new(1, 0, 1, -(HEADER_H + TABBAR_H))
		sf.BackgroundTransparency = 1
		sf.BorderSizePixel        = 0
		sf.ScrollBarThickness     = 3
		sf.ScrollBarImageColor3   = AccentDim
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
	local function applyTabStyle()
		if not hasTabs then return end
		for i, btn in ipairs(TabBtns) do
			local on = (i == activeTab)
			btn.BackgroundColor3 = on and Theme.ToggleOn or Theme.Bg2
			btn.TextColor3       = on and Theme.ActiveTabText or Theme.TextMuted
			btn.Font             = on and Theme.FontBold or Theme.FontMedium
		end
	end

	local function SetTab(idx)
		if not hasTabs then return end
		activeTab = idx
		for i, sf in ipairs(tabFrames) do
			sf.Visible = (i == idx)
		end
		applyTabStyle()
	end

	if hasTabs then
		applyTabStyle()
		for i, btn in ipairs(TabBtns) do
			local idx = i
			btn.MouseButton1Click:Connect(function() SetTab(idx) end)
			btn.MouseEnter:Connect(function()
				if activeTab ~= idx then
					TweenService:Create(btn, TweenFast,
						{ BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
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
	local isMinimized = Options.Minimized == true
	local function applyMinimize(instant)
		local targetH = isMinimized and MIN_H or FULL_H
		-- Hide content + tabs when minimized
		for _, sf in ipairs(tabFrames) do
			sf.Visible = (not isMinimized) and (tabFrames[1] == sf or
				(hasTabs and tabFrames[activeTab] == sf))
		end
		if not isMinimized and hasTabs then
			for i, sf in ipairs(tabFrames) do sf.Visible = (i == activeTab) end
		end
		if TabBar     then TabBar.Visible     = not isMinimized end
		if TabUnderline then TabUnderline.Visible = not isMinimized end
		-- Hide all tab frames when minimized
		if isMinimized then
			for _, sf in ipairs(tabFrames) do sf.Visible = false end
		end
		MinBtn.Text = isMinimized and "+" or "–"
		AccentLine.Visible = not isMinimized
		if instant then
			Frame.Size = UDim2.new(0, Width, 0, targetH)
		else
			TweenService:Create(Frame, TweenMed,
				{ Size = UDim2.new(0, Width, 0, targetH) }):Play()
		end
	end
	applyMinimize(true)

	MinBtn.MouseButton1Click:Connect(function()
		isMinimized = not isMinimized
		applyMinimize(false)
	end)
	MinBtn.MouseEnter:Connect(function()
		TweenService:Create(MinBtn, TweenFast, { BackgroundColor3 = Theme.ToggleOn }):Play()
	end)
	MinBtn.MouseLeave:Connect(function()
		TweenService:Create(MinBtn, TweenFast, { BackgroundColor3 = AccentDim }):Play()
	end)

	-- ── Dragging ───────────────────────────────────────────
	do
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
		UserInputService.InputChanged:Connect(function(inp)
			if not dragging then return end
			if inp.UserInputType ~= Enum.UserInputType.MouseMovement
			and inp.UserInputType ~= Enum.UserInputType.Touch then return end
			local d = inp.Position - dragStart
			Frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end)
	end

	-- ── Return ─────────────────────────────────────────────
	return {
		Gui          = Gui,
		Frame        = Frame,
		Header       = Header,
		TitleLabel   = TitleLabel,
		-- Content is the first (or only) tab frame for convenience
		Content      = tabFrames[1],
		GetTab       = function(i) return tabFrames[i] end,
		SetTab       = SetTab,
		GetActiveTab = function() return activeTab end,
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
--   Open      bool     Start open (default true)
--
-- Returns:
--   { Frame, Content, SetOpen(bool), IsOpen() }
-- ============================================================
function UILib.CreateSection(Parent, Options)
	Options = Options or {}
	local title    = Options.Title or ""
	local startOpen = Options.Open ~= false  -- default true

	-- Outer wrapper — AutomaticSize so it grows with content
	local Wrapper = Instance.new("Frame")
	Wrapper.Size             = UDim2.new(1, 0, 0, 0)
	Wrapper.AutomaticSize    = Enum.AutomaticSize.Y
	Wrapper.BackgroundColor3 = Theme.Bg2
	Wrapper.BorderSizePixel  = 0
	Wrapper.ClipsDescendants = false
	Wrapper.Parent           = Parent
	MakeCorner(Wrapper, UDim.new(0, 7))
	MakeStroke(Wrapper, Theme.AccentDim, 1)

	local WrapLayout = Instance.new("UIListLayout", Wrapper)
	WrapLayout.Padding    = UDim.new(0, 0)
	WrapLayout.SortOrder  = Enum.SortOrder.LayoutOrder
	WrapLayout.FillDirection = Enum.FillDirection.Vertical

	-- Header row (clickable)
	local HeaderRow = Instance.new("TextButton")
	HeaderRow.Size                   = UDim2.new(1, 0, 0, 34)
	HeaderRow.LayoutOrder            = 0
	HeaderRow.BackgroundTransparency = 1
	HeaderRow.BorderSizePixel        = 0
	HeaderRow.Text                   = ""
	HeaderRow.AutoButtonColor        = false
	HeaderRow.Parent                 = Wrapper

	-- Accent bar
	local AccentBar = Instance.new("Frame", HeaderRow)
	AccentBar.Size             = UDim2.new(0, 3, 0, 16)
	AccentBar.Position         = UDim2.new(0, 8, 0.5, -8)
	AccentBar.BackgroundColor3 = Theme.Accent
	AccentBar.BorderSizePixel  = 0
	MakeCorner(AccentBar, UDim.new(0, 2))

	local TitleLbl = Instance.new("TextLabel", HeaderRow)
	TitleLbl.Size                   = UDim2.new(1, -50, 1, 0)
	TitleLbl.Position               = UDim2.new(0, 18, 0, 0)
	TitleLbl.BackgroundTransparency = 1
	TitleLbl.Font                   = Theme.FontMedium
	TitleLbl.TextSize               = Theme.SmallSize + 1
	TitleLbl.TextColor3             = Theme.Accent
	TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
	TitleLbl.Text                   = title

	-- Arrow indicator
	local Arrow = Instance.new("TextLabel", HeaderRow)
	Arrow.Size                   = UDim2.new(0, 20, 1, 0)
	Arrow.Position               = UDim2.new(1, -24, 0, 0)
	Arrow.BackgroundTransparency = 1
	Arrow.Font                   = Theme.FontBold
	Arrow.TextSize               = 12
	Arrow.TextColor3             = Theme.AccentDim
	Arrow.TextXAlignment         = Enum.TextXAlignment.Center
	Arrow.Text                   = "▾"

	-- Divider below header
	local Divider = Instance.new("Frame", Wrapper)
	Divider.Size             = UDim2.new(1, -16, 0, 1)
	Divider.Position         = UDim2.new(0, 8, 0, 34)
	Divider.BackgroundColor3 = Theme.AccentDim
	Divider.BorderSizePixel  = 0
	Divider.LayoutOrder      = 1

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
		Arrow.Text       = open and "▾" or "▸"
		TweenService:Create(Arrow, TweenFast,
			{ TextColor3 = open and Theme.Accent or Theme.AccentDim }):Play()
	end
	SetOpen(startOpen)

	HeaderRow.MouseButton1Click:Connect(function()
		SetOpen(not isOpen)
	end)
	HeaderRow.MouseEnter:Connect(function()
		TweenService:Create(HeaderRow, TweenFast,
			{ BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
		HeaderRow.BackgroundTransparency = 0
	end)
	HeaderRow.MouseLeave:Connect(function()
		TweenService:Create(HeaderRow, TweenFast,
			{ BackgroundColor3 = Theme.Bg2 }):Play()
		task.delay(0.14, function() HeaderRow.BackgroundTransparency = 1 end)
	end)

	return {
		Frame   = Wrapper,
		Content = Content,
		SetOpen = SetOpen,
		IsOpen  = function() return isOpen end,
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
--
-- Returns: { Frame, Button }
-- ============================================================
function UILib.CreateButton(Parent, Options)
	Options = Options or {}

	local RowBg = Instance.new("Frame")
	RowBg.Size             = UDim2.new(1, 0, 0, Options.Height or 34)
	RowBg.BackgroundColor3 = Options.Color or Theme.Bg2
	RowBg.BorderSizePixel  = 0
	RowBg.Parent           = Parent
	MakeCorner(RowBg, UDim.new(0, 7))
	MakeStroke(RowBg, Theme.AccentDim, 1)

	local Btn = Instance.new("TextButton")
	Btn.Size                   = UDim2.new(1, 0, 1, 0)
	Btn.BackgroundTransparency = 1
	Btn.BorderSizePixel        = 0
	Btn.Font                   = Theme.FontRegular
	Btn.TextSize               = Theme.BodySize
	Btn.TextColor3             = Options.TextColor or Theme.TextPrimary
	Btn.TextXAlignment         = Enum.TextXAlignment.Center
	Btn.Text                   = Options.Text or ""
	Btn.AutoButtonColor        = false
	Btn.Parent                 = RowBg

	local restColor  = Options.Color or Theme.Bg2
	local hoverColor = Color3.fromRGB(
		math.min(restColor.R * 255 + 14, 255) / 255,
		math.min(restColor.G * 255 + 14, 255) / 255,
		math.min(restColor.B * 255 + 14, 255) / 255)

	Btn.MouseEnter:Connect(function()
		TweenService:Create(RowBg, TweenFast, { BackgroundColor3 = hoverColor }):Play()
		TweenService:Create(Btn,   TweenFast, { TextColor3 = Theme.Accent }):Play()
	end)
	Btn.MouseLeave:Connect(function()
		TweenService:Create(RowBg, TweenFast, { BackgroundColor3 = restColor }):Play()
		TweenService:Create(Btn,   TweenFast, { TextColor3 = Options.TextColor or Theme.TextPrimary }):Play()
	end)

	if Options.OnClick then
		Btn.MouseButton1Click:Connect(Options.OnClick)
	end

	return { Frame = RowBg, Button = Btn }
end

-- ============================================================
-- CreateToggle
-- A labeled row with an animated toggle switch on the right.
--
-- Options:
--   Label        string
--   Default      bool     Initial state (default false)
--   OnChanged    function(newState, SetFn)
--
-- Returns: { Frame, Set(bool), GetValue() }
-- ============================================================
function UILib.CreateToggle(Parent, Options)
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
	MakeCorner(Row, UDim.new(0, 7))
	MakeStroke(Row, Theme.AccentDim, 1)

	local Lbl = Instance.new("TextLabel", Row)
	Lbl.Size                   = UDim2.new(1, -(W + 20), 1, 0)
	Lbl.Position               = UDim2.new(0, 12, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.BodySize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.Text                   = Options.Label or ""

	-- Track
	local Track = Instance.new("Frame", Row)
	Track.AnchorPoint      = Vector2.new(1, 0.5)
	Track.Position         = UDim2.new(1, -10, 0.5, 0)
	Track.Size             = UDim2.new(0, W, 0, H)
	Track.BackgroundColor3 = state and Theme.ToggleOn or Theme.ToggleOff
	Track.BorderSizePixel  = 0
	MakeCorner(Track, UDim.new(1, 0))

	-- Knob
	local Knob = Instance.new("Frame", Track)
	Knob.Size             = UDim2.new(0, K, 0, K)
	Knob.Position         = state
		and UDim2.new(0, W - K - 2, 0.5, -K/2)
		or  UDim2.new(0, 2,         0.5, -K/2)
	Knob.BackgroundColor3 = Theme.Knob
	Knob.BorderSizePixel  = 0
	MakeCorner(Knob, UDim.new(1, 0))

	-- Invisible click target over entire row
	local ClickBtn = Instance.new("TextButton", Row)
	ClickBtn.Size                   = UDim2.new(1, 0, 1, 0)
	ClickBtn.BackgroundTransparency = 1
	ClickBtn.Text                   = ""
	ClickBtn.AutoButtonColor        = false

	local function Set(on)
		state = on
		TweenService:Create(Track, TweenFast,
			{ BackgroundColor3 = on and Theme.ToggleOn or Theme.ToggleOff }):Play()
		TweenService:Create(Knob,  TweenFast,
			{ Position = on
				and UDim2.new(0, W - K - 2, 0.5, -K/2)
				or  UDim2.new(0, 2,         0.5, -K/2) }):Play()
	end

	ClickBtn.MouseButton1Click:Connect(function()
		local newState = not state
		Set(newState)
		if Options.OnChanged then Options.OnChanged(newState, Set) end
	end)
	ClickBtn.MouseEnter:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
	end)
	ClickBtn.MouseLeave:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
	end)

	return { Frame = Row, Set = Set, GetValue = function() return state end }
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
--   OnSubmit     function(text)  called on FocusLost
--
-- Returns: { Frame, TextBox, GetValue() }
-- ============================================================
function UILib.CreateTextInput(Parent, Options)
	Options = Options or {}
	local boxW = Options.Width or 60

	local Row = Instance.new("Frame")
	Row.Size             = UDim2.new(1, 0, 0, 34)
	Row.BackgroundColor3 = Theme.Bg2
	Row.BorderSizePixel  = 0
	Row.Parent           = Parent
	MakeCorner(Row, UDim.new(0, 7))
	MakeStroke(Row, Theme.AccentDim, 1)

	local Lbl = Instance.new("TextLabel", Row)
	Lbl.Size                   = UDim2.new(1, -(boxW + 20), 1, 0)
	Lbl.Position               = UDim2.new(0, 12, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.BodySize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.Text                   = Options.Label or ""

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
	MakeCorner(Box, UDim.new(0, 5))
	local boxStroke = MakeStroke(Box, Theme.AccentDim, 1)

	Box.Focused:Connect(function()
		TweenService:Create(boxStroke, TweenFast, { Color = Theme.Accent }):Play()
	end)
	Box.FocusLost:Connect(function(ep)
		TweenService:Create(boxStroke, TweenFast, { Color = Theme.AccentDim }):Play()
		local val = Box.Text
		if Options.NumericOnly then
			local n = tonumber(val:match("%d+"))
			val = n and tostring(n) or ""
			Box.Text = val
		end
		if Options.OnSubmit then Options.OnSubmit(val) end
	end)

	Row.MouseEnter:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
	end)
	Row.MouseLeave:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
	end)

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
--   Format     string  string.format pattern (default "%.0f")
--   OnChanged  function(value)
--
-- Returns: { Frame, Update(value), GetValue() }
-- ============================================================
function UILib.CreateSlider(Parent, Options)
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
	MakeCorner(Row, UDim.new(0, 7))
	MakeStroke(Row, Theme.AccentDim, 1)

	local LabelW = 0
	if Options.Label and Options.Label ~= "" then
		LabelW = 80
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
	end

	local ValLbl = Instance.new("TextLabel", Row)
	ValLbl.Size               = UDim2.new(0, 36, 0, 16)
	ValLbl.Position           = UDim2.new(1, -40, 0.5, -8)
	ValLbl.BackgroundTransparency = 1
	ValLbl.Font               = Theme.FontMedium
	ValLbl.TextSize           = Theme.SmallSize
	ValLbl.TextColor3         = Theme.AccentSec
	ValLbl.TextXAlignment     = Enum.TextXAlignment.Right

	local trackX  = LabelW + 14
	local trackW  = -(LabelW + 58)

	local Track = Instance.new("Frame", Row)
	Track.Size             = UDim2.new(1, trackW, 0, 4)
	Track.Position         = UDim2.new(0, trackX, 0.5, -2)
	Track.BackgroundColor3 = Color3.fromRGB(38, 34, 26)
	Track.BorderSizePixel  = 0
	MakeCorner(Track, UDim.new(1, 0))

	local Fill = Instance.new("Frame", Track)
	Fill.Size             = UDim2.new(0, 0, 1, 0)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.BorderSizePixel  = 0
	MakeCorner(Fill, UDim.new(1, 0))

	local Knob = Instance.new("Frame", Track)
	Knob.Size             = UDim2.new(0, 12, 0, 12)
	Knob.AnchorPoint      = Vector2.new(0.5, 0.5)
	Knob.Position         = UDim2.new(0, 0, 0.5, 0)
	Knob.BackgroundColor3 = Theme.Knob
	Knob.BorderSizePixel  = 0
	MakeCorner(Knob, UDim.new(1, 0))

	local function Update(val)
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
			local x = inp.Position.X
			Update(Min + ((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X) * (Max - Min))
		end
	end)
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
		or inp.UserInputType == Enum.UserInputType.Touch) then
			local x = inp.Position.X
			Update(Min + math.clamp((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1) * (Max - Min))
		end
	end)

	Row.MouseEnter:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
	end)
	Row.MouseLeave:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
	end)

	return { Frame = Row, Update = Update, GetValue = function() return cur end }
end

-- ============================================================
-- CreateDropdown / multi-line text input list
-- A labeled header with a scrollable list of text boxes.
--
-- Options:
--   Label       string    Header label
--   Count       number    Number of input slots (default 10)
--   Defaults    table     Array of default strings
--   Placeholder string    Placeholder for each box (or function(i))
--   OnChanged   function(index, value)
--   Height      number    Scroll area height (default 120)
--
-- Returns:
--   { Frame, GetValues(), SetValue(i, text) }
-- ============================================================
function UILib.CreateInputList(Parent, Options)
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
	MakeCorner(Card, UDim.new(0, 7))
	MakeStroke(Card, Theme.AccentDim, 1)

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
		local slotStroke = MakeStroke(Slot, Theme.AccentDim, 1)

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
			TweenService:Create(slotStroke, TweenFast, { Color = Theme.Accent }):Play()
		end)
		TB.FocusLost:Connect(function()
			TweenService:Create(slotStroke, TweenFast, { Color = Theme.AccentDim }):Play()
			values[i] = TB.Text
			if Options.OnChanged then Options.OnChanged(i, TB.Text) end
		end)
		TB:GetPropertyChangedSignal("Text"):Connect(function()
			values[i] = TB.Text
		end)

		boxes[i] = TB
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
--
-- Returns:
--   { Frame, Log(msg), Clear() }
-- ============================================================
function UILib.CreateStatusLog(Parent, Options)
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
	MakeStroke(Scroll, Theme.AccentDim, 1)
	MakePadding(Scroll, 4, 4, 4, 4)
	MakeListLayout(Scroll, Enum.FillDirection.Vertical, 2)

	local ClearRow = Instance.new("Frame", Wrapper)
	ClearRow.Size             = UDim2.new(1, 0, 0, 28)
	ClearRow.Position         = UDim2.new(0, 0, 1, -28)
	ClearRow.BackgroundColor3 = Theme.Bg2
	ClearRow.BorderSizePixel  = 0
	MakeCorner(ClearRow, UDim.new(0, 6))
	MakeStroke(ClearRow, Theme.AccentDim, 1)

	local ClearBtn = Instance.new("TextButton", ClearRow)
	ClearBtn.Size                   = UDim2.new(1, 0, 1, 0)
	ClearBtn.BackgroundTransparency = 1
	ClearBtn.Font                   = Theme.FontRegular
	ClearBtn.TextSize               = Theme.SmallSize
	ClearBtn.TextColor3             = Theme.TextMuted
	ClearBtn.Text                   = "Clear Log"
	ClearBtn.AutoButtonColor        = false

	local function Log(msg)
		local t = (os and os.date) and os.date("%H:%M:%S") or "??"
		local entry = "[" .. t .. "] " .. msg
		local lbl = Instance.new("TextLabel", Scroll)
		lbl.Size                   = UDim2.new(1, -8, 0, 0)
		lbl.AutomaticSize          = Enum.AutomaticSize.Y
		lbl.BackgroundTransparency = 1
		lbl.Font                   = Enum.Font.Code
		lbl.TextSize               = 10
		lbl.TextColor3             = Theme.TextPrimary
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.TextWrapped            = true
		lbl.Text                   = entry
		task.defer(function()
			Scroll.CanvasPosition = Vector2.new(0, math.huge)
		end)
	end

	local function Clear()
		for _, c in ipairs(Scroll:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
	end

	ClearBtn.MouseButton1Click:Connect(Clear)
	ClearBtn.MouseEnter:Connect(function()
		TweenService:Create(ClearRow, TweenFast, { BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
	end)
	ClearBtn.MouseLeave:Connect(function()
		TweenService:Create(ClearRow, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
	end)

	return { Frame = Wrapper, Log = Log, Clear = Clear }
end

-- ============================================================
-- CreateDivider
-- A thin 1px horizontal line.
-- ============================================================
function UILib.CreateDivider(Parent)
	local d = Instance.new("Frame")
	d.Size             = UDim2.new(1, 0, 0, 1)
	d.BackgroundColor3 = Theme.AccentDim
	d.BackgroundTransparency = 0.5
	d.BorderSizePixel  = 0
	d.Parent           = Parent
	return d
end

-- ============================================================
-- ShowNotification
-- Bottom-right slide-in banner, auto-dismissed after 2.5s.
-- Multiple calls stack vertically.
--
-- Args:
--   Title  string
--   Text   string
-- ============================================================
local _notifList = {}
local _notifSg   = nil
local NOTIF_W    = 250
local NOTIF_H    = 36
local NOTIF_PAD  = 6

local function _ensureNotifGui()
	if _notifSg and _notifSg.Parent then return end
	_notifSg = Instance.new("ScreenGui")
	_notifSg.Name           = "UILibNotifs"
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
			TweenService:Create(f, TweenFast,
				{ Position = UDim2.new(1, -(NOTIF_W + 12), 1, targetY) }):Play()
			totalY = totalY + NOTIF_H + NOTIF_PAD
		end
	end
end

function UILib.ShowNotification(Title, Text)
	_ensureNotifGui()

	local F = Instance.new("Frame", _notifSg)
	F.Size                   = UDim2.new(0, NOTIF_W, 0, NOTIF_H)
	F.Position               = UDim2.new(1, 12, 1, 0)   -- starts off-screen right
	F.BackgroundColor3       = Theme.Bg1
	F.BackgroundTransparency = 0.04
	F.BorderSizePixel        = 0
	F.ClipsDescendants       = true
	MakeCorner(F, UDim.new(0, Theme.CornerRadiusSmall))
	MakeStroke(F, Theme.Accent, 1.2)

	-- Thin accent left bar
	local Bar = Instance.new("Frame", F)
	Bar.Size             = UDim2.new(0, 3, 1, -8)
	Bar.Position         = UDim2.new(0, 0, 0, 4)
	Bar.BackgroundColor3 = Theme.Accent
	Bar.BorderSizePixel  = 0
	MakeCorner(Bar, UDim.new(0, 2))

	local Lbl = Instance.new("TextLabel", F)
	Lbl.Size               = UDim2.new(1, -16, 1, 0)
	Lbl.Position           = UDim2.new(0, 10, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.RichText           = true
	Lbl.Font               = Theme.FontMedium
	Lbl.TextSize           = Theme.SmallSize
	Lbl.TextColor3         = Theme.TextPrimary
	Lbl.TextXAlignment     = Enum.TextXAlignment.Left
	Lbl.TextTruncate       = Enum.TextTruncate.AtEnd
	Lbl.Text               = string.format(
		"<font color='rgb(%d,%d,%d)'><b>%s</b></font>  %s",
		math.floor(Theme.Accent.R * 255),
		math.floor(Theme.Accent.G * 255),
		math.floor(Theme.Accent.B * 255),
		(Title or ""):upper(), Text or "")

	table.insert(_notifList, F)
	_repositionNotifs()

	-- Auto-dismiss
	task.delay(2.5, function()
		if not F.Parent then return end
		-- Slide out to the right
		TweenService:Create(F, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Position = UDim2.new(1, 12, F.Position.Y.Scale, F.Position.Y.Offset) }):Play()
		task.delay(0.22, function()
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
-- ============================================================
function UILib.MakeDraggable(Handle, Target)
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
	UserInputService.InputChanged:Connect(function(inp)
		if not dragging then return end
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement
		and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = inp.Position - dragStart
		Target.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y)
	end)
end

return UILib
