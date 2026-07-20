-- ============================================================
-- UILib.lua  |  Self-contained loadstring library
-- Usage:
-- local UILib = loadstring(game:HttpGet("https://raw.githubusercontent.com/blookzz/skibidi/refs/heads/main/UILib.lua"))()
-- ============================================================

local UILib = {}

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
}
UILib.Theme = Theme

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================
local TweenFast   = TweenInfo.new(0.14, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TweenMed    = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TweenSpring = TweenInfo.new(0.28, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)

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

	Head.MouseEnter:Connect(function()
		TweenService:Create(Fill, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
		Fill.BackgroundTransparency = 0
	end)
	Head.MouseLeave:Connect(function()
		TweenService:Create(Fill, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
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
UILib.Flags = Flags

-- ── Panel registry ──────────────────────────────────────────
-- Every ScreenGui the library creates is tracked here so
-- UILib.Unload() can tear the whole UI down in one call.
local _allGuis = {}

-- ── Tooltip ─────────────────────────────────────────────────
-- One shared tooltip for the whole library. Components opt in with
-- Options.Tooltip = "text"; it follows the mouse, clamps to the screen
-- and hides itself when the hovered element dies.
local _tooltipSg, _tooltipFrame, _tooltipLbl

local function _ensureTooltip()
	if _tooltipSg and _tooltipSg.Parent then return end
	_tooltipSg = Instance.new("ScreenGui")
	_tooltipSg.Name           = "UILibTooltip"
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
	MakeStroke(_tooltipFrame, Theme.AccentDim, 1)
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
--
-- Returns:
--   {
--     Gui, Frame, Header, TitleLabel,
--     Content,           -- Frame/ScrollingFrame for the active content area
--                        --   (if Tabs given, this is the current tab's frame)
--     GetTab(index),     -- returns the Frame for tab[index]  (nil if no tabs)
--     SetTab(index),     -- switches active tab
--     GetActiveTab(),    -- returns current tab index
--     GetTabButton(index), SetTitle(text),
--     SetVisible(bool), ToggleVisible(), IsVisible(),
--     SetMinimized(bool), IsMinimized(), Close(),
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
	Gui.Name           = Options.Name or "Panel"
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
	MakeStroke(Frame, Accent, 1.2)
	MakeSheen(Frame, 0.10)

	-- Drop shadow. The panel clips its descendants, so the shadow lives
	-- as a sibling underneath it and mirrors the panel's Position/Size
	-- (property signals fire every frame during drags and tweens, so it
	-- tracks minimize/restore and dragging for free).
	local SHADOW_PAD = 27
	local Shadow = Instance.new("ImageLabel")
	Shadow.Name                   = "Shadow"
	Shadow.BackgroundTransparency = 1
	Shadow.Image                  = "rbxassetid://6014261993"
	Shadow.ImageColor3            = Color3.new(0, 0, 0)
	Shadow.ImageTransparency      = 0.42
	Shadow.ScaleType              = Enum.ScaleType.Slice
	Shadow.SliceCenter            = Rect.new(49, 49, 450, 450)
	Shadow.ZIndex                 = 0
	Shadow.Parent                 = Gui

	local function syncShadow()
		local p, s = Frame.Position, Frame.Size
		Shadow.Position = UDim2.new(p.X.Scale, p.X.Offset - SHADOW_PAD, p.Y.Scale, p.Y.Offset - SHADOW_PAD + 5)
		Shadow.Size     = UDim2.new(s.X.Scale, s.X.Offset + SHADOW_PAD * 2, s.Y.Scale, s.Y.Offset + SHADOW_PAD * 2)
	end
	Frame:GetPropertyChangedSignal("Position"):Connect(syncShadow)
	Frame:GetPropertyChangedSignal("Size"):Connect(syncShadow)
	syncShadow()

	-- Entrance: gentle pop-in on creation (UIScale rests at 1 afterwards,
	-- so it never affects layout or dragging). The shadow scales in with
	-- the panel so it doesn't hang oversized around the smaller frame.
	local OpenScale = Instance.new("UIScale")
	OpenScale.Scale  = 0.92
	OpenScale.Parent = Frame
	local ShadowScale = Instance.new("UIScale")
	ShadowScale.Scale  = 0.92
	ShadowScale.Parent = Shadow
	TweenService:Create(OpenScale,   TweenSpring, { Scale = 1 }):Play()
	TweenService:Create(ShadowScale, TweenSpring, { Scale = 1 }):Play()

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

	local showDiscord = Options.Discord == true
	local reservedRight = 86 + (showDiscord and 34 or 0)

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size                   = UDim2.new(1, -reservedRight, 1, 0)
	TitleLabel.Position               = UDim2.new(0, 14, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font                   = Theme.FontBold
	TitleLabel.TextSize               = Theme.TitleSize
	TitleLabel.TextColor3             = Theme.AccentSec
	TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
	TitleLabel.Text                   = Options.Title or ""
	TitleLabel.ZIndex                 = 3
	TitleLabel.Parent                 = Header

	-- Optional small muted subtitle rendered inline after the title
	if Options.SubTitle and Options.SubTitle ~= "" then
		local m = Theme.TextMuted
		TitleLabel.RichText = true
		TitleLabel.Text     = string.format(
			'%s  <font size="%d" color="#%02X%02X%02X">%s</font>',
			Options.Title or "", Theme.CaptionSize,
			math.floor(m.R * 255 + 0.5),
			math.floor(m.G * 255 + 0.5),
			math.floor(m.B * 255 + 0.5),
			Options.SubTitle)
	end

	-- Accent underline on header
	local AccentLine = Instance.new("Frame")
	AccentLine.Size                   = UDim2.new(1, -20, 0, 1)
	AccentLine.Position               = UDim2.new(0, 10, 1, -1)
	AccentLine.BackgroundColor3       = Accent
	AccentLine.BackgroundTransparency = 0.5
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

	-- Close button
	local CloseBtn = Instance.new("TextButton")
	CloseBtn.Size                   = UDim2.new(0, 28, 0, 20)
	CloseBtn.AnchorPoint            = Vector2.new(1, 0.5)
	CloseBtn.Position               = UDim2.new(1, -8, 0.5, 0)
	CloseBtn.BackgroundColor3       = AccentDim
	CloseBtn.BorderSizePixel        = 0
	CloseBtn.Font                   = Theme.FontIcon
	CloseBtn.TextSize               = 16
	CloseBtn.TextColor3             = Theme.AccentSec
	CloseBtn.Text                   = "×"
	CloseBtn.AutoButtonColor        = false
	CloseBtn.ZIndex                 = 4
	CloseBtn.Parent                 = Header
	MakeCorner(CloseBtn, UDim.new(0, 5))

	-- Minimize button (shifted left to make room for the close button)
	local MinBtn = Instance.new("TextButton")
	MinBtn.Size                   = UDim2.new(0, 28, 0, 20)
	MinBtn.AnchorPoint            = Vector2.new(1, 0.5)
	MinBtn.Position               = UDim2.new(1, -8 - 28 - 6, 0.5, 0)
	MinBtn.BackgroundColor3       = AccentDim
	MinBtn.BorderSizePixel        = 0
	MinBtn.Font                   = Theme.FontIcon
	MinBtn.TextSize               = 16
	MinBtn.TextColor3             = Theme.AccentSec
	MinBtn.Text                   = "–"
	MinBtn.AutoButtonColor        = false
	MinBtn.ZIndex                 = 4
	MinBtn.Parent                 = Header
	MakeCorner(MinBtn, UDim.new(0, 5))

	-- Discord button (optional, off by default)
	-- Options.Discord = true enables it. Clicking copies the invite link
	-- to the clipboard via setclipboard (when the executor supports it).
	local DISCORD_INVITE  = "https://discord.gg/rNvAU6cjVB"
	local DISCORD_ICON_ID = "rbxassetid://94434236999817" -- simple Discord mark; swap if it doesn't render for you

	local DiscordBtn
	if showDiscord then
		DiscordBtn = Instance.new("TextButton")
		DiscordBtn.Size                   = UDim2.new(0, 28, 0, 20)
		DiscordBtn.AnchorPoint            = Vector2.new(1, 0.5)
		DiscordBtn.Position               = UDim2.new(1, -8 - 28 - 6 - 28 - 6, 0.5, 0)
		DiscordBtn.BackgroundColor3       = AccentDim
		DiscordBtn.BorderSizePixel        = 0
		DiscordBtn.Text                   = ""
		DiscordBtn.AutoButtonColor        = false
		DiscordBtn.ZIndex                 = 4
		DiscordBtn.Parent                 = Header
		MakeCorner(DiscordBtn, UDim.new(0, 5))

		local DiscordIcon = Instance.new("ImageLabel")
		DiscordIcon.Size                   = UDim2.new(0, 14, 0, 14)
		DiscordIcon.AnchorPoint            = Vector2.new(0.5, 0.5)
		DiscordIcon.Position               = UDim2.new(0.5, 0, 0.5, 0)
		DiscordIcon.BackgroundTransparency = 1
		DiscordIcon.Image                  = DISCORD_ICON_ID
		DiscordIcon.ImageColor3            = Theme.AccentSec
		DiscordIcon.ZIndex                 = 5
		DiscordIcon.Parent                 = DiscordBtn

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

	-- ── Tab bar (optional) ─────────────────────────────────
	-- "top"  — horizontal bar of equal-width buttons under the header
	-- "left" — vertical rail of full-width buttons beside the content
	local TabBar, TabBtns, TabUnderline
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
		local tabGap = 6
		local tabW   = (Width - 20 - tabGap * (#Tabs - 1)) / #Tabs

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
			MakeCorner(btn, UDim.new(0, 6))
			MakeStroke(btn, AccentDim, 1)
			local fit = Instance.new("UITextSizeConstraint", btn)
			fit.MaxTextSize = 12; fit.MinTextSize = 8
			TabBtns[i] = btn
		end
	elseif sideTabs then
		-- Vertical tab rail on a slightly darker strip so it reads as
		-- navigation, separated from content by a 1px divider.
		TabBar = Instance.new("Frame")
		TabBar.Position               = UDim2.new(0, 0, 0, HEADER_H)
		TabBar.Size                   = UDim2.new(0, RAIL_W, 1, -HEADER_H)
		TabBar.BackgroundColor3       = Theme.Bg0
		TabBar.BackgroundTransparency = 0.35
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
			MakeCorner(btn, UDim.new(0, 6))
			MakeStroke(btn, AccentDim, 1)
			MakePadding(btn, 10, 6, 0, 0)
			TabBtns[i] = btn
		end
	end

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
		sf.ScrollBarThickness     = 3
		sf.ScrollBarImageColor3   = AccentDim
		sf.ScrollBarImageTransparency = 0.25
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
		end
	end

	local function SetTab(idx)
		if not hasTabs then return end
		activeTab = idx
		for i, sf in ipairs(tabFrames) do
			sf.Visible = (i == idx)
		end
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
	local BTN_GAP       = 6    -- gap between MinBtn and CloseBtn
	local MIN_BTN_RIGHT = 8    -- CloseBtn's right margin (see Position above)
	local TITLE_LEFT    = 14   -- TitleLabel's left offset (see Position above)
	local TITLE_GAP     = 10   -- breathing room between title text and buttons

	local function computeMinimizedWidth()
		-- Prefer the label's own rendered TextBounds: it accounts for
		-- RichText markup (e.g. the inline subtitle <font> tag), which
		-- GetTextSize does not — GetTextSize would measure the raw tag
		-- characters and blow the width up past Width, defeating the
		-- horizontal shrink. Fall back to GetTextSize if TextBounds is
		-- not yet populated.
		local textW = TitleLabel.TextBounds.X
		if not textW or textW <= 0 then
			local ok, bounds = pcall(TextService.GetTextSize, TextService,
				TitleLabel.Text, Theme.TitleSize, Theme.FontBold, Vector2.new(2000, HEADER_H))
			textW = (ok and bounds and bounds.X) or 60
		end
		local mw = TITLE_LEFT + textW + TITLE_GAP + DISCORD_BTN_W + MIN_BTN_W + BTN_GAP + CLOSE_BTN_W + MIN_BTN_RIGHT
		return math.clamp(mw, 90, Width)
	end

	local isMinimized = Options.Minimized == true
	local minimizeToken = 0

	local function setBodyVisible(visible)
		if TabBar       then TabBar.Visible       = visible end
		if TabUnderline then TabUnderline.Visible = visible end
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

	local function CloseWindow()
		if Gui then Gui:Destroy() end
	end

	CloseBtn.MouseButton1Click:Connect(CloseWindow)
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
		GetTabButton = function(i) return TabBtns and TabBtns[i] end,
		SetTitle     = function(t) TitleLabel.Text = t or "" end,
		SetMinimized = SetMinimized,
		IsMinimized  = function() return isMinimized end,
		SetVisible   = SetVisible,
		ToggleVisible = ToggleVisible,
		IsVisible    = function() return Gui.Enabled end,
		CloseBtn     = CloseBtn,
		Close        = CloseWindow,
		DiscordBtn   = DiscordBtn,
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
--   Open      bool     Start open (default false)
--   Tooltip   string   Hover tooltip (optional)
--
-- Returns:
--   { Frame, Content, SetOpen(bool), IsOpen(), SetTitle(text) }
-- ============================================================
function UILib.CreateSection(Parent, Options)
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
	MakeStroke(Wrapper, Theme.AccentDim, 1)

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
	Arrow.Text                   = "▼"

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
		TweenService:Create(Arrow, TweenMed,
			{ Rotation   = open and 180 or 0,
			  TextColor3 = open and Theme.Accent or Theme.AccentDim }):Play()
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
--
-- Returns: { Frame, Button, SetText(text), SetDisabled(bool) }
-- ============================================================
function UILib.CreateButton(Parent, Options)
	Options = Options or {}

	local RowBg = Instance.new("Frame")
	RowBg.Size             = UDim2.new(1, 0, 0, Options.Height or 34)
	RowBg.BackgroundColor3 = Options.Color or Theme.Bg2
	RowBg.BorderSizePixel  = 0
	RowBg.Parent           = Parent
	MakeCorner(RowBg, UDim.new(0, Theme.CornerRadiusSmall))
	MakeStroke(RowBg, Theme.AccentDim, 1)

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
		TweenService:Create(RowBg,    TweenFast, { BackgroundColor3 = hoverColor }):Play()
		TweenService:Create(Btn,      TweenFast, { TextColor3 = Theme.Accent }):Play()
		TweenService:Create(BtnScale, TweenFast, { Scale = 1.02 }):Play()
	end)
	Btn.MouseLeave:Connect(function()
		if disabled then return end
		TweenService:Create(RowBg,    TweenFast, { BackgroundColor3 = restColor }):Play()
		TweenService:Create(Btn,      TweenFast, { TextColor3 = Options.TextColor or Theme.TextPrimary }):Play()
		TweenService:Create(BtnScale, TweenFast, { Scale = 1 }):Play()
	end)
	-- Press feedback: dip below rest colour + shrink slightly on press,
	-- release back to the hover state
	Btn.MouseButton1Down:Connect(function()
		if disabled then return end
		TweenService:Create(RowBg,    TweenFast, { BackgroundColor3 = pressColor }):Play()
		TweenService:Create(BtnScale, TweenFast, { Scale = 0.97 }):Play()
	end)
	Btn.MouseButton1Up:Connect(function()
		if disabled then return end
		TweenService:Create(RowBg,    TweenFast, { BackgroundColor3 = hoverColor }):Play()
		TweenService:Create(BtnScale, TweenSpring, { Scale = 1.02 }):Play()
	end)

	-- Confirm mode: first click arms, second click (within 2s) fires.
	local armed, armToken = false, 0
	local baseText = Options.Text or ""
	local function disarm()
		armed = false
		armToken = armToken + 1
		Btn.Text = baseText
	end

	Btn.MouseButton1Click:Connect(function()
		if disabled then return end
		if Options.Confirm and not armed then
			armed = true
			armToken = armToken + 1
			local myToken = armToken
			Btn.Text = Options.ConfirmText or "Confirm?"
			TweenService:Create(Btn, TweenFast, { TextColor3 = Theme.AccentSec }):Play()
			task.delay(2, function()
				if armed and myToken == armToken and Btn.Parent then disarm() end
			end)
			return
		end
		if armed then disarm() end
		if Options.OnClick then Options.OnClick() end
	end)

	AttachTooltip(RowBg, Options.Tooltip)

	local function SetDisabled(on)
		disabled = on == true
		if armed then disarm() end
		TweenService:Create(Btn,   TweenFast, { TextTransparency = disabled and 0.55 or 0 }):Play()
		TweenService:Create(RowBg, TweenFast, { BackgroundColor3 = restColor }):Play()
	end

	return {
		Frame       = RowBg,
		Button      = Btn,
		SetText     = function(t) baseText = t or ""; if not armed then Btn.Text = baseText end end,
		SetDisabled = SetDisabled,
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
-- Returns: { Frame, Set(bool), GetValue(), SetDisabled(bool) }
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
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
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
	MakeSheen(Track, 0.18)

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
		TweenService:Create(Knob,  TweenSpring,
			{ Position = on
				and UDim2.new(0, W - K - 2, 0.5, -K/2)
				or  UDim2.new(0, 2,         0.5, -K/2) }):Play()
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
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
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
		TweenService:Create(boxStroke, TweenFast, { Color = Theme.Accent, Thickness = 1.5 }):Play()
	end)
	Box.FocusLost:Connect(function(ep)
		TweenService:Create(boxStroke, TweenFast, { Color = Theme.AccentDim, Thickness = 1 }):Play()
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
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
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
	Track.BackgroundColor3 = Theme.ToggleOff
	Track.BorderSizePixel  = 0
	MakeCorner(Track, UDim.new(1, 0))

	local Fill = Instance.new("Frame", Track)
	Fill.Size             = UDim2.new(0, 0, 1, 0)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.BorderSizePixel  = 0
	MakeCorner(Fill, UDim.new(1, 0))
	MakeSheen(Fill, 0.20)

	local Knob = Instance.new("Frame", Track)
	Knob.Size             = UDim2.new(0, 12, 0, 12)
	Knob.AnchorPoint      = Vector2.new(0.5, 0.5)
	Knob.Position         = UDim2.new(0, 0, 0.5, 0)
	Knob.BackgroundColor3 = Theme.Knob
	Knob.BorderSizePixel  = 0
	MakeCorner(Knob, UDim.new(1, 0))

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
			TweenService:Create(Knob, TweenSpring, { Size = UDim2.new(0, 15, 0, 15) }):Play()
			local x = inp.Position.X
			Update(Min + ((x - Track.AbsolutePosition.X) / Track.AbsoluteSize.X) * (Max - Min))
		end
	end)
	ConnectScoped(Row, UserInputService.InputEnded, function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1
		or inp.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				TweenService:Create(Knob, TweenFast, { Size = UDim2.new(0, 12, 0, 12) }):Play()
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
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
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
			TweenService:Create(slotStroke, TweenFast, { Color = Theme.Accent, Thickness = 1.5 }):Play()
		end)
		TB.FocusLost:Connect(function()
			TweenService:Create(slotStroke, TweenFast, { Color = Theme.AccentDim, Thickness = 1 }):Play()
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

	local entries  = {}
	local maxLines = Options.MaxLines

	local function Log(msg, color)
		local t = (os and os.date) and os.date("%H:%M:%S") or "??"
		local entry = "[" .. t .. "] " .. msg
		local lbl = Instance.new("TextLabel", Scroll)
		lbl.Size                   = UDim2.new(1, -8, 0, 0)
		lbl.AutomaticSize          = Enum.AutomaticSize.Y
		lbl.BackgroundTransparency = 1
		lbl.Font                   = Enum.Font.Code
		lbl.TextSize               = 10
		lbl.TextColor3             = color or Theme.TextPrimary
		lbl.TextXAlignment         = Enum.TextXAlignment.Left
		lbl.TextWrapped            = true
		lbl.Text                   = entry
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
	end)
	ClearBtn.MouseLeave:Connect(function()
		TweenService:Create(ClearRow, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
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
function UILib.CreateDivider(Parent, Options)
	Options = Options or {}

	if not Options.Text or Options.Text == "" then
		local d = Instance.new("Frame")
		d.Size             = UDim2.new(1, 0, 0, 1)
		d.BackgroundColor3 = Theme.AccentDim
		d.BackgroundTransparency = 0.5
		d.BorderSizePixel  = 0
		d.Parent           = Parent
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
	Line.BackgroundColor3       = Theme.AccentDim
	Line.BackgroundTransparency = 0.5
	Line.BorderSizePixel        = 0

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
	Cap.TextColor3             = Theme.TextMuted
	Cap.Text                   = Options.Text
	MakePadding(Cap, 8, 8, 1, 1)

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
			TweenService:Create(f, TweenMed,
				{ Position = UDim2.new(1, -(NOTIF_W + 12), 1, targetY) }):Play()
			totalY = totalY + NOTIF_H + NOTIF_PAD
		end
	end
end

function UILib.ShowNotification(Title, Text, Duration)
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
	MakeSheen(F, 0.10)

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
	task.delay(tonumber(Duration) or 2.5, function()
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
--
-- Options (optional third argument):
--   ClampToScreen  bool   Keep Target inside its parent container
--                         while dragging (default false)
-- ============================================================
function UILib.MakeDraggable(Handle, Target, Options)
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
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
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
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
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
	Track.BackgroundColor3 = Theme.ToggleOff
	Track.BorderSizePixel  = 0
	MakeCorner(Track, UDim.new(1, 0))

	local Fill = Instance.new("Frame", Track)
	Fill.Size             = UDim2.new(0, 0, 1, 0)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.BorderSizePixel  = 0
	MakeCorner(Fill, UDim.new(1, 0))
	MakeSheen(Fill, 0.20)

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
--   Tooltip    string   Hover tooltip (optional)
--   Flag       string   Config key for SaveConfig/LoadConfig
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
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
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
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
			Row.BackgroundTransparency = 0
		end)
		Row.MouseLeave:Connect(function()
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
			task.delay(0.14, function() Row.BackgroundTransparency = 1 end)
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
-- Returns: { Frame, SetOpen(bool), GetValue(),
--            SetItems(items, keepSelection) }
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
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
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
			TweenService:Create(row.Dot, TweenFast,
				{ BackgroundColor3 = on and Theme.Accent or Theme.Bg3 }):Play()
			TweenService:Create(row.Ring, TweenFast,
				{ Color = on and Theme.Accent or Theme.AccentDim }):Play()
			row.Lbl.TextColor3 = on and Theme.ActiveTabText or Theme.TextPrimary
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
		MakeCorner(Row, UDim.new(0, 5))

		local RingHolder = Instance.new("Frame", Row)
		RingHolder.Size             = UDim2.new(0, 14, 0, 14)
		RingHolder.Position         = UDim2.new(0, 5, 0.5, -7)
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
		RLbl.Size                   = UDim2.new(1, -28, 1, 0)
		RLbl.Position               = UDim2.new(0, 30, 0, 0)
		RLbl.BackgroundTransparency = 1
		RLbl.Font                   = Theme.FontRegular
		RLbl.TextSize               = Theme.SmallSize + 1
		RLbl.TextColor3             = selected[text] and Theme.ActiveTabText or Theme.TextPrimary
		RLbl.TextXAlignment         = Enum.TextXAlignment.Left
		RLbl.Text                   = text

		optRows[text] = { Row = Row, Dot = Dot, Ring = ring, Lbl = RLbl }

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
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
			Row.BackgroundTransparency = 0
		end)
		Row.MouseLeave:Connect(function()
			TweenService:Create(Row, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
			task.delay(0.14, function() Row.BackgroundTransparency = 1 end)
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
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusSmall))
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
		TweenService:Create(keyStroke, TweenFast, { Color = Theme.AccentDim, Thickness = 1 }):Play()
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
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
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

		CopyBtn.MouseEnter:Connect(function()
			TweenService:Create(CopyBtn, TweenFast, { TextColor3 = Theme.Accent }):Play()
		end)
		CopyBtn.MouseLeave:Connect(function()
			TweenService:Create(CopyBtn, TweenFast, { TextColor3 = Theme.TextMuted }):Play()
		end)

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
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
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
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
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
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
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
--   Tooltip    string    Hover tooltip (optional)
--   Flag       string    Config key for SaveConfig/LoadConfig
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
	Card.ClipsDescendants  = true
	Card.Parent            = Parent
	MakeCorner(Card, UDim.new(0, Theme.CornerRadiusSmall))
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
	local hexStroke = MakeStroke(HexBox, Theme.AccentDim, 1)

	HexBox.Focused:Connect(function()
		TweenService:Create(hexStroke, TweenFast, { Color = Theme.Accent, Thickness = 1.5 }):Play()
	end)

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
		TweenService:Create(hexStroke, TweenFast, { Color = Theme.AccentDim, Thickness = 1 }):Play()
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
-- SaveConfig / LoadConfig
-- Optional persistence for component values, backed by the
-- executor's writefile/readfile. Both are safe no-ops (returning
-- false + a reason) when the executor doesn't support file APIs,
-- so scripts that never call them — or run without file access —
-- are completely unaffected.
--
-- To opt a component in, give it a Flag key at creation:
--   UILib.CreateToggle(tab, { Label = "ESP", Flag = "esp", ... })
-- Supported: Toggle (bool), Slider (number), TextInput (string),
-- Dropdown (string / array if Multi), Keybind (key name string),
-- ColorPicker (RGB table), Group (index), InputList (array).
--
--   UILib.SaveConfig(name)  → true  |  false, err
--   UILib.LoadConfig(name)  → true  |  false, err
--
-- `name` defaults to "UILibConfig"; files are stored as
-- "<name>.json" in the executor's workspace folder. Loading
-- applies each saved value through the component's setter and
-- fires its OnChanged/OnSubmit so consuming scripts stay in sync.
-- ============================================================
local function configFileName(name)
	return tostring(name or "UILibConfig") .. ".json"
end

function UILib.SaveConfig(name)
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

function UILib.LoadConfig(name)
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
-- CreateCardList
-- A scrollable list of selectable cards.  Each card has a big
-- title and a smaller description line.  Clicking a card calls
-- OnSelect, and the card is toggled into a highlighted selected
-- state.  Multiple cards can be selected simultaneously.
--
-- Options:
--   Items        table   Array of { Title, Description } tables
--   Multi        bool    Allow multiple selections (default true)
--   Height       number  Fixed scroll-frame height (default 220)
--   OnSelect     function(index, title, selected)
--                        Called when a card is toggled.
--                        `selected` is the new state of *this* card.
--   OnChange     function(selectedIndices)
--                        Called after any selection change with the
--                        full array of currently selected indices.
--
-- Returns:
--   {
--     Frame,
--     GetSelected()            → table of selected indices (sorted)
--     SetSelected(indices)     → set selection programmatically
--     ClearSelected()          → deselect all
--     SetItems(items)          → replace the whole list
--   }
-- ============================================================
function UILib.CreateCardList(Parent, Options)
	Options = Options or {}
	local multi    = Options.Multi ~= false   -- default true
	local items    = Options.Items or {}
	local listH    = Options.Height or 220      -- height of the scroll container (px)
	local cardH    = Options.CardHeight         -- fixed card height (px); nil = auto-size

	-- Selected state: index → bool
	local selectedSet = {}

	-- ── Outer wrapper ─────────────────────────────────────────
	local Wrapper = Instance.new("Frame")
	Wrapper.Size             = UDim2.new(1, 0, 0, listH)
	Wrapper.BackgroundColor3 = Theme.Bg2
	Wrapper.BorderSizePixel  = 0
	Wrapper.ClipsDescendants = true
	Wrapper.Parent           = Parent
	MakeCorner(Wrapper, UDim.new(0, Theme.CornerRadiusSmall))
	MakeStroke(Wrapper, Theme.AccentDim, 1)

	-- ── ScrollingFrame ────────────────────────────────────────
	local Scroll = Instance.new("ScrollingFrame", Wrapper)
	Scroll.Size                    = UDim2.new(1, 0, 1, 0)
	Scroll.BackgroundTransparency  = 1
	Scroll.BorderSizePixel         = 0
	Scroll.ScrollBarThickness      = 3
	Scroll.ScrollBarImageColor3    = Theme.AccentDim
	Scroll.CanvasSize              = UDim2.new(0, 0, 0, 0)
	Scroll.AutomaticCanvasSize     = Enum.AutomaticSize.Y
	Scroll.VerticalScrollBarInset  = Enum.ScrollBarInset.ScrollBar
	Scroll.ClipsDescendants        = true
	MakePadding(Scroll, 6, 6, 6, 6)
	MakeListLayout(Scroll, Enum.FillDirection.Vertical, 5)

	-- ── Card builder ──────────────────────────────────────────
	local cardObjects = {}   -- index → { Card, TitleLbl, DescLbl, Dot, Stroke, Index }

	local function fireCallbacks(idx, newState)
		if Options.OnSelect then
			Options.OnSelect(idx, items[idx] and items[idx].Title or "", newState)
		end
		if Options.OnChange then
			local sel = {}
			for i in pairs(selectedSet) do table.insert(sel, i) end
			table.sort(sel)
			Options.OnChange(sel)
		end
	end

	local function refreshCard(obj)
		local on = selectedSet[obj.Index] == true
		-- Background
		TweenService:Create(obj.Card, TweenFast, {
			BackgroundColor3 = on and Color3.fromRGB(38, 30, 10) or Theme.Bg3,
		}):Play()
		-- Outer stroke
		TweenService:Create(obj.Stroke, TweenFast, {
			Color = on and Theme.Accent or Theme.AccentDim,
		}):Play()
		-- Selection dot
		TweenService:Create(obj.Ring, TweenFast, {
			Color = on and Theme.Accent or Theme.AccentDim,
		}):Play()
		TweenService:Create(obj.Dot, TweenFast, {
			BackgroundColor3 = on and Theme.Accent or Theme.Bg2,
		}):Play()
		-- Title colour
		TweenService:Create(obj.TitleLbl, TweenFast, {
			TextColor3 = on and Theme.AccentSec or Theme.TextPrimary,
		}):Play()
	end

	local function buildCard(i, item)
		item = item or {}
		local Card = Instance.new("TextButton")
		if cardH then
			-- Fixed card height: scroll container is independent of card content
			Card.Size          = UDim2.new(1, 0, 0, cardH)
			Card.AutomaticSize = Enum.AutomaticSize.None
		else
			-- Auto-size: card grows to fit its title + description text
			Card.Size          = UDim2.new(1, 0, 0, 0)
			Card.AutomaticSize = Enum.AutomaticSize.Y
		end
		Card.BackgroundColor3       = Theme.Bg3
		Card.BorderSizePixel        = 0
		Card.AutoButtonColor        = false
		Card.Text                   = ""
		Card.LayoutOrder            = i
		Card.ClipsDescendants       = true
		Card.Parent                 = Scroll
		MakeCorner(Card, UDim.new(0, 6))
		local stroke = MakeStroke(Card, Theme.AccentDim, 1)
		MakePadding(Card, 10, 10, 8, 9)

		-- When CardHeight is fixed we can't use UIListLayout on the card
		-- (it has no way to stretch DescLbl into remaining space).
		-- Instead: TitleRow sits at the top with a fixed height; DescLbl
		-- is positioned below it and fills the rest of the card.
		local TITLE_ROW_H = 20

		if not cardH then
			MakeListLayout(Card, Enum.FillDirection.Vertical, 3)
		end

		-- Row: selection ring/dot + title
		local TitleRow = Instance.new("Frame", Card)
		if cardH then
			TitleRow.Size     = UDim2.new(1, 0, 0, TITLE_ROW_H)
			TitleRow.Position = UDim2.new(0, 0, 0, 0)
		else
			TitleRow.Size          = UDim2.new(1, 0, 0, 0)
			TitleRow.AutomaticSize = Enum.AutomaticSize.Y
		end
		TitleRow.BackgroundTransparency = 1
		TitleRow.LayoutOrder            = 0
		MakeListLayout(TitleRow, Enum.FillDirection.Horizontal, 8,
			Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

		-- Ring + dot (same visual language as Group / Dropdown)
		local RingHolder = Instance.new("Frame", TitleRow)
		RingHolder.Size             = UDim2.new(0, 14, 0, 14)
		RingHolder.BackgroundColor3 = Theme.Bg2
		RingHolder.BorderSizePixel  = 0
		RingHolder.LayoutOrder      = 0
		MakeCorner(RingHolder, UDim.new(1, 0))
		local ring = MakeStroke(RingHolder, Theme.AccentDim, 1.5)

		local Dot = Instance.new("Frame", RingHolder)
		Dot.AnchorPoint      = Vector2.new(0.5, 0.5)
		Dot.Position         = UDim2.new(0.5, 0, 0.5, 0)
		Dot.Size             = UDim2.new(0, 7, 0, 7)
		Dot.BackgroundColor3 = Theme.Bg2
		Dot.BorderSizePixel  = 0
		MakeCorner(Dot, UDim.new(1, 0))

		local TitleLbl = Instance.new("TextLabel", TitleRow)
		TitleLbl.Size                   = UDim2.new(1, -(14 + 8), 0, 0)
		TitleLbl.AutomaticSize          = Enum.AutomaticSize.Y
		TitleLbl.BackgroundTransparency = 1
		TitleLbl.Font                   = Theme.FontMedium
		TitleLbl.TextSize               = Theme.BodySize + 1
		TitleLbl.TextColor3             = Theme.TextPrimary
		TitleLbl.TextXAlignment         = Enum.TextXAlignment.Left
		TitleLbl.TextWrapped            = true
		TitleLbl.LayoutOrder            = 1
		TitleLbl.Text                   = item.Title or ""

		-- Description line
		local DescLbl = Instance.new("TextLabel", Card)
		if cardH then
			-- Position below TitleRow, fill remaining card height
			local pad = 8 + 9   -- top + bottom padding from MakePadding
			local gap = 3
			DescLbl.Position      = UDim2.new(0, 0, 0, TITLE_ROW_H + gap)
			DescLbl.Size          = UDim2.new(1, 0, 0, cardH - pad - TITLE_ROW_H - gap)
			DescLbl.AutomaticSize = Enum.AutomaticSize.None
		else
			DescLbl.Size          = UDim2.new(1, 0, 0, 0)
			DescLbl.AutomaticSize = Enum.AutomaticSize.Y
		end
		DescLbl.BackgroundTransparency = 1
		DescLbl.Font                   = Theme.FontRegular
		DescLbl.TextSize               = Theme.SmallSize
		DescLbl.TextColor3             = Theme.TextMuted
		DescLbl.TextXAlignment         = Enum.TextXAlignment.Left
		DescLbl.TextYAlignment         = Enum.TextYAlignment.Top
		DescLbl.TextWrapped            = true
		DescLbl.LayoutOrder            = 1
		DescLbl.Text                   = item.Description or ""

		local obj = {
			Card     = Card,
			TitleLbl = TitleLbl,
			DescLbl  = DescLbl,
			Dot      = Dot,
			Ring     = ring,
			Stroke   = stroke,
			Index    = i,
		}
		cardObjects[i] = obj

		-- Hover feedback (inset fill, same pattern as other heads)
		-- Hover fill must escape the card's UIPadding (10,10,8,9) to cover
		-- the full card. We negate the padding in size and position manually.
		local hf = Instance.new("Frame")
		hf.Size                   = UDim2.new(1, 10 + 10, 1, 8 + 9)
		hf.Position               = UDim2.new(0, -10, 0, -8)
		hf.BackgroundColor3       = Theme.Bg2
		hf.BackgroundTransparency = 1
		hf.BorderSizePixel        = 0
		hf.ZIndex                 = 0
		hf.Parent                 = Card
		MakeCorner(hf, UDim.new(0, 6))
		Card.MouseEnter:Connect(function()
			TweenService:Create(hf, TweenFast, { BackgroundColor3 = Theme.Hover }):Play()
			hf.BackgroundTransparency = 0
		end)
		Card.MouseLeave:Connect(function()
			TweenService:Create(hf, TweenFast, { BackgroundColor3 = Theme.Bg2 }):Play()
			task.delay(0.14, function() hf.BackgroundTransparency = 1 end)
		end)

		Card.MouseButton1Click:Connect(function()
			if multi then
				if selectedSet[i] then
					selectedSet[i] = nil
				else
					selectedSet[i] = true
				end
			else
				-- single-select: deselect everyone else first
				for j, o in pairs(cardObjects) do
					if j ~= i and selectedSet[j] then
						selectedSet[j] = nil
						refreshCard(o)
					end
				end
				if selectedSet[i] then
					selectedSet[i] = nil
				else
					selectedSet[i] = true
				end
			end
			refreshCard(obj)
			fireCallbacks(i, selectedSet[i] == true)
		end)

		return obj
	end

	local function buildAll(newItems)
		-- Destroy existing cards
		for _, obj in pairs(cardObjects) do
			obj.Card:Destroy()
		end
		cardObjects = {}
		selectedSet = {}
		items = newItems or {}
		for i, item in ipairs(items) do
			buildCard(i, item)
		end
	end

	buildAll(items)

	-- ── Public API ────────────────────────────────────────────
	local function GetSelected()
		local sel = {}
		for i in pairs(selectedSet) do table.insert(sel, i) end
		table.sort(sel)
		return sel
	end

	local function SetSelected(indices)
		selectedSet = {}
		for _, i in ipairs(indices) do
			if cardObjects[i] then selectedSet[i] = true end
		end
		for _, obj in pairs(cardObjects) do refreshCard(obj) end
	end

	local function ClearSelected()
		selectedSet = {}
		for _, obj in pairs(cardObjects) do refreshCard(obj) end
	end

	local function SetItems(newItems)
		buildAll(newItems)
	end

	return {
		Frame        = Wrapper,
		GetSelected  = GetSelected,
		SetSelected  = SetSelected,
		ClearSelected = ClearSelected,
		SetItems     = SetItems,
	}
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
--
-- Returns: { Frame, Label, SetText(text) }
-- ============================================================
function UILib.CreateLabel(Parent, Options)
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
-- Returns: { Frame, SetValue(v), SetLabel(t), GetValue() }
-- ============================================================
function UILib.CreateKeyValue(Parent, Options)
	Options = Options or {}
	local value = Options.Value ~= nil and tostring(Options.Value) or "-"

	local Row = Instance.new("Frame")
	Row.Size             = UDim2.new(1, 0, 0, 26)
	Row.BackgroundColor3 = Theme.Bg2
	Row.BorderSizePixel  = 0
	Row.Parent           = Parent
	MakeCorner(Row, UDim.new(0, Theme.CornerRadiusXs))
	MakeStroke(Row, Theme.AccentDim, 1)

	local KeyLbl = Instance.new("TextLabel", Row)
	KeyLbl.Size                   = UDim2.new(0.5, -14, 1, 0)
	KeyLbl.Position               = UDim2.new(0, 12, 0, 0)
	KeyLbl.BackgroundTransparency = 1
	KeyLbl.Font                   = Theme.FontRegular
	KeyLbl.TextSize               = Theme.SmallSize
	KeyLbl.TextColor3             = Theme.TextMuted
	KeyLbl.TextXAlignment         = Enum.TextXAlignment.Left
	KeyLbl.TextTruncate           = Enum.TextTruncate.AtEnd
	KeyLbl.Text                   = Options.Label or ""

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

	AttachTooltip(Row, Options.Tooltip)

	return {
		Frame    = Row,
		SetValue = function(v)
			value = tostring(v)
			ValLbl.Text = value
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
function UILib.Unload()
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
UILib.init        = UILib.Init
UILib.unload      = UILib.Unload
UILib.saveconfig  = UILib.SaveConfig
UILib.loadconfig  = UILib.LoadConfig
UILib.notify      = UILib.ShowNotification
UILib.label       = UILib.CreateLabel
UILib.keyvalue    = UILib.CreateKeyValue
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
UILib.cardlist    = UILib.CreateCardList
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
