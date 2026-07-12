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
local TextService      = game:GetService("TextService")
local RunService       = game:GetService("RunService")
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
	-- Gotham/GothamBold/GothamBlack only cover a limited (mostly Latin)
	-- glyph set. Arrows, chevrons, and checkmarks fall outside that set
	-- and render as tofu boxes. SourceSansBold has full coverage for
	-- these symbols, so it's used anywhere a glyph "icon" is drawn.
	FontIcon         = Enum.Font.SourceSansBold,
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

-- Default parent used by CreatePanel when Options.Parent is omitted.
-- Overridable in one place via UILib.Init({ Parent = someInstance }).
local DefaultParent = PlayerGui

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

	-- ── ScreenGui ──────────────────────────────────────────
	local Gui = Instance.new("ScreenGui")
	Gui.Name           = Options.Name or "Panel"
	Gui.ResetOnSpawn   = false
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Gui.Parent         = Options.Parent or DefaultParent

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
		-- Top/bottom padding shifted by 7px (11->4, 2->9) so the tab
		-- buttons sit centered between the header underline above and
		-- the tab underline below, instead of hugging the bottom.
		MakePadding(TabBar, 10, 10, 4, 9)
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
	local MIN_BTN_RIGHT = 8    -- MinBtn's right margin (see Position above)
	local TITLE_LEFT    = 14   -- TitleLabel's left offset (see Position above)
	local TITLE_GAP     = 10   -- breathing room between title text and button

	local function computeMinimizedWidth()
		local ok, bounds = pcall(TextService.GetTextSize, TextService,
			TitleLabel.Text, Theme.TitleSize, Theme.FontBold, Vector2.new(2000, HEADER_H))
		local textW = (ok and bounds and bounds.X) or 60
		local mw = TITLE_LEFT + textW + TITLE_GAP + MIN_BTN_W + MIN_BTN_RIGHT
		return math.clamp(mw, 90, Width)
	end

	local isMinimized = Options.Minimized == true
	local minimizeToken = 0

	local function setBodyVisible(visible)
		if TabBar       then TabBar.Visible       = visible end
		if TabUnderline then TabUnderline.Visible = visible end
		if visible then
			for i, sf in ipairs(tabFrames) do
				sf.Visible = hasTabs and (i == activeTab) or (i == 1)
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
		SetMinimized = SetMinimized,
		IsMinimized  = function() return isMinimized end,
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
	Arrow.Font                   = Theme.FontIcon
	Arrow.TextSize               = 14
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

-- ============================================================
-- CreateParagraph
-- A static text block: optional bold title + wrapped body text.
--
-- Options:
--   Title     string
--   Content   string   (also accepts Options.Text)
--
-- Returns: { Frame, SetTitle(text), SetText(text) }
-- ============================================================
function UILib.CreateParagraph(Parent, Options)
	Options = Options or {}

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, 0)
	Card.AutomaticSize     = Enum.AutomaticSize.Y
	Card.BackgroundColor3  = Theme.Bg2
	Card.BorderSizePixel   = 0
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, 7))
	MakeStroke(Card, Theme.AccentDim, 1)
	MakePadding(Card, 12, 12, 10, 10)
	MakeListLayout(Card, Enum.FillDirection.Vertical, 4)

	local TitleLbl
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
	Body.LayoutOrder            = 1
	Body.Text                   = Options.Content or Options.Text or ""

	return {
		Frame    = Card,
		SetTitle = function(t) if TitleLbl then TitleLbl.Text = t end end,
		SetText  = function(t) Body.Text = t end,
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
--
-- Returns: { Frame, Update(value, instant), GetValue() }
-- ============================================================
function UILib.CreateProgressBar(Parent, Options)
	Options = Options or {}
	local Min = Options.Min or 0
	local Max = Options.Max or 100
	local cur = math.clamp(Options.Default or Min, Min, Max)

	local Row = Instance.new("Frame")
	Row.Size             = UDim2.new(1, 0, 0, 40)
	Row.BackgroundColor3 = Theme.Bg2
	Row.BorderSizePixel  = 0
	Row.Parent           = Parent
	MakeCorner(Row, UDim.new(0, 7))
	MakeStroke(Row, Theme.AccentDim, 1)
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
	Track.Size             = UDim2.new(1, 0, 0, 6)
	Track.BackgroundColor3 = Color3.fromRGB(38, 34, 26)
	Track.BorderSizePixel  = 0
	MakeCorner(Track, UDim.new(1, 0))

	local Fill = Instance.new("Frame", Track)
	Fill.Size             = UDim2.new(0, 0, 1, 0)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.BorderSizePixel  = 0
	MakeCorner(Fill, UDim.new(1, 0))

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

	return { Frame = Row, Update = Update, GetValue = function() return cur end }
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
function UILib.CreateSpace(Parent, Options)
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
function UILib.CreateHStack(Parent, Options)
	Options = Options or {}
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
	MakeListLayout(Stack, Enum.FillDirection.Horizontal, Options.Spacing or 6,
		Options.HorizontalAlignment or Enum.HorizontalAlignment.Left,
		Options.VerticalAlignment or Enum.VerticalAlignment.Center)
	return { Frame = Stack }
end

function UILib.CreateVStack(Parent, Options)
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
--
-- Returns: { Frame, SetValue(index), GetValue() }
-- ============================================================
function UILib.CreateGroup(Parent, Options)
	Options = Options or {}
	local items   = Options.Options or {}
	local current = Options.Default or 1

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, 0)
	Card.AutomaticSize     = Enum.AutomaticSize.Y
	Card.BackgroundColor3  = Theme.Bg2
	Card.BorderSizePixel   = 0
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, 7))
	MakeStroke(Card, Theme.AccentDim, 1)
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
	local function refresh()
		for i, row in ipairs(rows) do
			local on = (i == current)
			TweenService:Create(row.Dot, TweenFast,
				{ BackgroundColor3 = on and Theme.Accent or Theme.Bg3 }):Play()
			TweenService:Create(row.Ring, TweenFast,
				{ Color = on and Theme.Accent or Theme.AccentDim }):Play()
			row.Lbl.TextColor3 = on and Theme.ActiveTabText or Theme.TextPrimary
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
		MakeCorner(Row, UDim.new(0, 5))

		local RingHolder = Instance.new("Frame", Row)
		RingHolder.Size             = UDim2.new(0, 16, 0, 16)
		RingHolder.Position         = UDim2.new(0, 2, 0.5, -8)
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
		Lbl.Size                   = UDim2.new(1, -30, 1, 0)
		Lbl.Position               = UDim2.new(0, 26, 0, 0)
		Lbl.BackgroundTransparency = 1
		Lbl.Font                   = Theme.FontRegular
		Lbl.TextSize               = Theme.BodySize
		Lbl.TextColor3             = Theme.TextPrimary
		Lbl.TextXAlignment         = Enum.TextXAlignment.Left
		Lbl.Text                   = text

		rows[i] = { Dot = Dot, Ring = ring, Lbl = Lbl }

		Row.MouseButton1Click:Connect(function()
			current = i
			refresh()
			if Options.OnChanged then Options.OnChanged(i, text) end
		end)
		Row.MouseEnter:Connect(function()
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
			Row.BackgroundTransparency = 0
		end)
		Row.MouseLeave:Connect(function()
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
			task.delay(0.14, function() Row.BackgroundTransparency = 1 end)
		end)
	end

	refresh()

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
--
-- Returns: { Frame, SetOpen(bool), GetValue() }
-- ============================================================
function UILib.CreateDropdown(Parent, Options)
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
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, 7))
	MakeStroke(Card, Theme.AccentDim, 1)
	local CardLayout = Instance.new("UIListLayout", Card)
	CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	CardLayout.Padding   = UDim.new(0, 0)

	local Head = Instance.new("TextButton", Card)
	Head.Size                   = UDim2.new(1, 0, 0, 34)
	Head.LayoutOrder            = 0
	Head.BackgroundTransparency = 1
	Head.AutoButtonColor        = false
	Head.Text                   = ""

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
	Chevron.Text                   = "▾"

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

	local function refreshLabel()
		local out = {}
		for _, val in ipairs(items) do
			if selected[val] then table.insert(out, val) end
		end
		ValueLbl.Text = (#out > 0) and table.concat(out, ", ") or (Options.Placeholder or "Select...")
	end

	local function refreshRows()
		for val, row in pairs(optRows) do
			local on = selected[val] == true
			row.Check.TextTransparency = on and 0 or 1
			row.Lbl.TextColor3 = on and Theme.ActiveTabText or Theme.TextPrimary
		end
	end

	local isOpen = false
	local function setOpen(open)
		isOpen = open
		List.Visible = open
		Chevron.Text = open and "▴" or "▾"
	end

	for i, text in ipairs(items) do
		local Row = Instance.new("TextButton", List)
		Row.Size                   = UDim2.new(1, 0, 0, 26)
		Row.LayoutOrder            = i
		Row.BackgroundColor3       = Theme.Bg2
		Row.BackgroundTransparency = 1
		Row.AutoButtonColor        = false
		Row.Text                   = ""
		MakeCorner(Row, UDim.new(0, 5))

		local Check = Instance.new("TextLabel", Row)
		Check.Size                   = UDim2.new(0, 18, 1, 0)
		Check.Position               = UDim2.new(0, 4, 0, 0)
		Check.BackgroundTransparency = 1
		Check.Font                   = Theme.FontIcon
		Check.TextSize               = 12
		Check.TextColor3             = Theme.Accent
		Check.Text                   = "✓"
		Check.TextTransparency       = selected[text] and 0 or 1

		local RLbl = Instance.new("TextLabel", Row)
		RLbl.Size                   = UDim2.new(1, -28, 1, 0)
		RLbl.Position               = UDim2.new(0, 24, 0, 0)
		RLbl.BackgroundTransparency = 1
		RLbl.Font                   = Theme.FontRegular
		RLbl.TextSize               = Theme.SmallSize + 1
		RLbl.TextColor3             = selected[text] and Theme.ActiveTabText or Theme.TextPrimary
		RLbl.TextXAlignment         = Enum.TextXAlignment.Left
		RLbl.Text                   = text

		optRows[text] = { Check = Check, Lbl = RLbl }

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
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
			Row.BackgroundTransparency = 0
		end)
		Row.MouseLeave:Connect(function()
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
			task.delay(0.14, function() Row.BackgroundTransparency = 1 end)
		end)
	end

	refreshLabel()

	Head.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)
	Head.MouseEnter:Connect(function()
		TweenService:Create(Head, TweenFast, { BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
		Head.BackgroundTransparency = 0
	end)
	Head.MouseLeave:Connect(function()
		TweenService:Create(Head, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
		task.delay(0.14, function() Head.BackgroundTransparency = 1 end)
	end)

	return {
		Frame    = Card,
		SetOpen  = setOpen,
		GetValue = function()
			if multi then
				local out = {}
				for _, val in ipairs(items) do if selected[val] then table.insert(out, val) end end
				return out
			end
			for _, val in ipairs(items) do if selected[val] then return val end end
			return nil
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
--
-- Returns: { Frame, Set(keyCode), GetValue() }
-- ============================================================
function UILib.CreateKeybind(Parent, Options)
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
	MakeCorner(Row, UDim.new(0, 7))
	MakeStroke(Row, Theme.AccentDim, 1)

	local Lbl = Instance.new("TextLabel", Row)
	Lbl.Size                   = UDim2.new(1, -90, 1, 0)
	Lbl.Position               = UDim2.new(0, 12, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.BodySize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.Text                   = Options.Label or ""

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
	local keyStroke = MakeStroke(KeyBtn, Theme.AccentDim, 1)

	local listening = false
	local conn

	local function stopListening()
		listening = false
		TweenService:Create(keyStroke, TweenFast, { Color = Theme.AccentDim }):Play()
		if conn then conn:Disconnect(); conn = nil end
	end

	KeyBtn.MouseButton1Click:Connect(function()
		if listening then stopListening(); return end
		listening = true
		KeyBtn.Text = "..."
		TweenService:Create(keyStroke, TweenFast, { Color = Theme.Accent }):Play()
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
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Color3.fromRGB(32,30,24) }):Play()
	end)
	Row.MouseLeave:Connect(function()
		TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
	end)

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
function UILib.CreateCode(Parent, Options)
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
	MakeCorner(Card, UDim.new(0, 7))
	MakeStroke(Card, Theme.AccentDim, 1)
	local CardLayout = Instance.new("UIListLayout", Card)
	CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	CardLayout.Padding   = UDim.new(0, 0)
	if hasHeader then
		local HeaderRow = Instance.new("Frame", Card)
		HeaderRow.Size             = UDim2.new(1, 0, 0, 22)
		HeaderRow.LayoutOrder      = 0
		HeaderRow.BackgroundColor3 = Theme.Bg2
		HeaderRow.BorderSizePixel  = 0

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
		MakeCorner(CopyBtn, UDim.new(0, 4))

		CopyBtn.MouseButton1Click:Connect(function()
			if setclipboard then
				pcall(setclipboard, Options.Text or "")
				CopyBtn.Text = "Copied"
				task.delay(1, function() CopyBtn.Text = "Copy" end)
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
function UILib.CreateImage(Parent, Options)
	Options = Options or {}
	local h = Options.Height or 150

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, h)
	Card.BackgroundColor3  = Theme.Bg3
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, 7))
	MakeStroke(Card, Theme.AccentDim, 1)

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
function UILib.CreateVideo(Parent, Options)
	Options = Options or {}
	local h = Options.Height or 180

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, h + 30)
	Card.BackgroundColor3  = Theme.Bg3
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, 7))
	MakeStroke(Card, Theme.AccentDim, 1)

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
	MakeStroke(PlayBtn, Theme.AccentDim, 1)

	local function updateBtn()
		PlayBtn.Text = Vid.IsPlaying and "Pause" or "Play"
	end

	local function Play() Vid:Play(); updateBtn() end
	local function Pause() Vid:Pause(); updateBtn() end

	PlayBtn.MouseButton1Click:Connect(function()
		if Vid.IsPlaying then Pause() else Play() end
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
function UILib.CreateViewport(Parent, Options)
	Options = Options or {}
	local h = Options.Height or 180

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, h)
	Card.BackgroundColor3  = Options.BackgroundColor3 or Theme.Bg3
	Card.BorderSizePixel   = 0
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, 7))
	MakeStroke(Card, Theme.AccentDim, 1)

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
--
-- Returns: { Frame, SetOpen(bool), SetValue(color3), GetValue() }
-- ============================================================
function UILib.CreateColorPicker(Parent, Options)
	Options = Options or {}
	local current = Options.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = Color3.toHSV(current)

	local Card = Instance.new("Frame")
	Card.Size              = UDim2.new(1, 0, 0, 0)
	Card.AutomaticSize     = Enum.AutomaticSize.Y
	Card.BackgroundColor3  = Theme.Bg2
	Card.BorderSizePixel   = 0
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, 7))
	MakeStroke(Card, Theme.AccentDim, 1)
	local CardLayout = Instance.new("UIListLayout", Card)
	CardLayout.SortOrder = Enum.SortOrder.LayoutOrder
	CardLayout.Padding   = UDim.new(0, 0)

	local Head = Instance.new("TextButton", Card)
	Head.Size                   = UDim2.new(1, 0, 0, 34)
	Head.LayoutOrder            = 0
	Head.BackgroundTransparency = 1
	Head.AutoButtonColor        = false
	Head.Text                   = ""

	local Lbl = Instance.new("TextLabel", Head)
	Lbl.Size                   = UDim2.new(1, -60, 1, 0)
	Lbl.Position               = UDim2.new(0, 12, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Font                   = Theme.FontRegular
	Lbl.TextSize               = Theme.BodySize
	Lbl.TextColor3             = Theme.TextPrimary
	Lbl.TextXAlignment         = Enum.TextXAlignment.Left
	Lbl.Text                   = Options.Label or ""

	local Swatch = Instance.new("Frame", Head)
	Swatch.AnchorPoint      = Vector2.new(1, 0.5)
	Swatch.Position         = UDim2.new(1, -10, 0.5, 0)
	Swatch.Size             = UDim2.new(0, 36, 0, 20)
	Swatch.BackgroundColor3 = current
	Swatch.BorderSizePixel  = 0
	MakeCorner(Swatch, UDim.new(0, 5))
	MakeStroke(Swatch, Theme.AccentDim, 1)

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
	MakeCorner(SVBox, UDim.new(0, 5))

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
	MakeStroke(HexBox, Theme.AccentDim, 1)

	local function updateFromHSV(fireEvent)
		current = Color3.fromHSV(h, s, v)
		Swatch.BackgroundColor3 = current
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
	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			draggingSV, draggingHue = false, false
		end
	end)
	UserInputService.InputChanged:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
		if draggingSV then jumpSV(inp.Position)
		elseif draggingHue then jumpHue(inp.Position) end
	end)

	HexBox.FocusLost:Connect(function()
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
	end

	Head.MouseButton1Click:Connect(function()
		setOpen(not isOpen)
	end)
	Head.MouseEnter:Connect(function()
		TweenService:Create(Head, TweenFast, { BackgroundColor3 = Color3.fromRGB(32, 30, 24) }):Play()
		Head.BackgroundTransparency = 0
	end)
	Head.MouseLeave:Connect(function()
		TweenService:Create(Head, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
		task.delay(0.14, function() Head.BackgroundTransparency = 1 end)
	end)

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
-- without having to reach into UILib.Theme directly.
--
-- Options:
--   Theme    table      Partial theme override, merged into UILib.Theme
--   Parent   Instance   Default parent for new panels (default PlayerGui)
--
-- Returns: UILib (so calls can be chained, e.g.
--   UILib.Init({ Theme = { Accent = Color3.fromRGB(120,80,220) } }).CreatePanel({...})
-- ============================================================
function UILib.Init(Options)
	Options = Options or {}
	if Options.Theme then
		for k, val in pairs(Options.Theme) do
			Theme[k] = val
		end
	end
	if Options.Parent then
		DefaultParent = Options.Parent
	end
	return UILib
end

-- ============================================================
-- Convenience lowercase aliases
-- Exposes each component under a short name in addition to the
-- primary CreateXxx API, without altering how the components
-- themselves are implemented.
-- ============================================================
UILib.init        = UILib.Init
UILib.button      = UILib.CreateButton
UILib.code        = UILib.CreateCode
UILib.colorpicker = UILib.CreateColorPicker
UILib.divider     = UILib.CreateDivider
UILib.dropdown    = UILib.CreateDropdown
UILib.group       = UILib.CreateGroup
UILib.hstack      = UILib.CreateHStack
UILib.image       = UILib.CreateImage
UILib.input       = UILib.CreateTextInput
UILib.keybind     = UILib.CreateKeybind
UILib.paragraph   = UILib.CreateParagraph
UILib.progressbar = UILib.CreateProgressBar
UILib.section     = UILib.CreateSection
UILib.slider      = UILib.CreateSlider
UILib.space       = UILib.CreateSpace
UILib.toggle      = UILib.CreateToggle
UILib.vstack      = UILib.CreateVStack
UILib.video       = UILib.CreateVideo
UILib.viewport    = UILib.CreateViewport


return UILib
