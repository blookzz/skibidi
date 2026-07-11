-- ============================================================
-- UILib.lua  |  Self-contained loadstring library
-- Usage:
--   local UILib = loadstring(game:HttpGet("YOUR_RAW_URL"))()
-- ============================================================

local UILib = {}
UILib.MobileScaleObjects = {}

-- ============================================================
-- SERVICES
-- ============================================================
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local Players           = game:GetService("Players")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- MOBILE DETECTION
-- ============================================================
local function IsMobileDevice()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end
local IsMobile = IsMobileDevice()

-- ============================================================
-- THEME  (edit these to restyle everything)
-- ============================================================
local Theme = {
	-- Surfaces
	Background       = Color3.fromRGB(15,  15,  20),
	Surface0         = Color3.fromRGB(22,  22,  30),
	Surface2         = Color3.fromRGB(35,  35,  48),
	Surface3         = Color3.fromRGB(50,  50,  65),
	SurfaceHighlight = Color3.fromRGB(45,  45,  60),

	-- Accent
	Accent           = Color3.fromRGB(120, 80, 220),
	AccentDark       = Color3.fromRGB(80,  50, 160),

	-- Text
	TextPrimary      = Color3.fromRGB(230, 230, 240),
	TextSecondary    = Color3.fromRGB(160, 160, 180),
	TextTertiary     = Color3.fromRGB(100, 100, 120),
	TextAccent       = Color3.fromRGB(160, 120, 255),

	-- Borders
	Border           = Color3.fromRGB(70,  70,  90),
	BorderFocused    = Color3.fromRGB(120, 80, 220),

	-- Divider
	Divider          = Color3.fromRGB(45,  45,  60),
	DividerHeight    = 1,

	-- Sizing
	CornerRadius      = 10,
	CornerRadiusSmall = 8,
	CornerRadiusXs    = 6,
	HeaderHeight      = 36,
	TabHeight         = 32,
	CardPadding       = 8,
	Padding           = 10,
	PaddingLarge      = 12,
	PaddingSmall      = 6,
	PaddingXSmall     = 4,

	-- Fonts
	FontBold          = Enum.Font.GothamBold,
	FontMedium        = Enum.Font.GothamMedium,
	FontRegular       = Enum.Font.Gotham,

	-- Text sizes
	TitleSize         = 14,
	BodySize          = 13,
	SmallSize         = 12,
	CaptionSize       = 11,

	-- Variants (keyed by name)
	Variants = {
		red   = { Accent = Color3.fromRGB(220,  60,  60), AccentDark = Color3.fromRGB(160, 30, 30) },
		green = { Accent = Color3.fromRGB( 60, 200,  90), AccentDark = Color3.fromRGB( 30,140, 50) },
		blue  = { Accent = Color3.fromRGB( 60, 140, 220), AccentDark = Color3.fromRGB( 30, 80,160) },
		gold  = { Accent = Color3.fromRGB(220, 170,  40), AccentDark = Color3.fromRGB(160,110, 20) },
	},
}

UILib.Theme = Theme  -- expose so callers can read/override

-- ============================================================
-- INTERNAL HELPERS
-- ============================================================
local QuickTween = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Minimal config shim (no file I/O needed for loadstring usage)
local Config = { Positions = {}, UILocked = false, MobileGuiScale = 80 }

local function ResolveAccent(Variant)
	if Variant and Theme.Variants[Variant] then
		return Theme.Variants[Variant].Accent, Theme.Variants[Variant].AccentDark
	end
	return Theme.Accent, Theme.AccentDark
end

-- ============================================================
-- CreatePanel
-- Creates a full draggable panel: ScreenGui > Frame > Header > Content
--
-- Options:
--   Name        string   ScreenGui name                  (default "Panel")
--   Title       string   Header title text               (default "")
--   Width       number   Panel width in pixels           (default 300)
--   Height      number   Panel height in pixels          (default 400)
--   Variant     string   Color variant key               (optional)
--   Visible     bool     Initial visibility              (default true)
--   Transparency number  Background transparency         (default 0.05)
--   Parent      Instance Where to parent the ScreenGui   (default PlayerGui)
--
-- Returns: { Gui, Frame, Header, TitleLabel, Content, Layout, Accent, AccentDark }
-- ============================================================
function UILib.CreatePanel(Options)
	local Accent, AccentDark = ResolveAccent(Options.Variant)
	local Width  = Options.Width  or 300
	local Height = Options.Height or 400

	local Gui = Instance.new("ScreenGui")
	Gui.Name = Options.Name or "Panel"
	Gui.ResetOnSpawn = false
	Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Gui.Parent = Options.Parent or PlayerGui
	if Options.Visible == false then
		Gui.Enabled = false
	end

	local SaveKey  = Options.Name or Options.Title or "default"
	local SavedPos = Config.Positions[SaveKey]
	local PosX     = SavedPos and SavedPos.X or 0.5
	local PosY     = SavedPos and SavedPos.Y or 0.5

	local Frame = Instance.new("TextButton")
	Frame.Size                = UDim2.new(0, Width, 0, Height)
	Frame.Position            = UDim2.new(PosX, -Width/2, PosY, -Height/2)
	Frame.BackgroundColor3    = Theme.Background
	Frame.BackgroundTransparency = Options.Transparency or 0.05
	Frame.BorderSizePixel     = 0
	Frame.ClipsDescendants    = true
	Frame.Text                = ""
	Frame.AutoButtonColor     = false
	Frame.Active              = true
	Frame.Parent              = Gui

	Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, Theme.CornerRadius)

	local Stroke = Instance.new("UIStroke", Frame)
	Stroke.Color        = Theme.Border
	Stroke.Thickness    = 1
	Stroke.Transparency = 0.5

	-- Header bar
	local Header = Instance.new("Frame", Frame)
	Header.Size                = UDim2.new(1, 0, 0, Theme.HeaderHeight)
	Header.BackgroundColor3    = Theme.Surface0
	Header.BackgroundTransparency = 0
	Header.BorderSizePixel     = 0

	local HeaderCorner = Instance.new("UICorner", Header)
	HeaderCorner.CornerRadius  = UDim.new(0, Theme.CornerRadius)

	-- Accent bar at left of header
	local AccentBar = Instance.new("Frame", Header)
	AccentBar.Size             = UDim2.new(0, 3, 0, 18)
	AccentBar.Position         = UDim2.new(0, Theme.PaddingSmall, 0.5, -9)
	AccentBar.BackgroundColor3 = Accent
	AccentBar.BorderSizePixel  = 0
	Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(0, 2)

	local TitleLabel = Instance.new("TextLabel", Header)
	TitleLabel.Size               = UDim2.new(1, -60, 1, 0)
	TitleLabel.Position           = UDim2.new(0, Theme.PaddingLarge + 6, 0, 0)
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Text               = Options.Title or ""
	TitleLabel.Font               = Theme.FontBold
	TitleLabel.TextSize           = Theme.TitleSize
	TitleLabel.TextColor3         = Theme.TextPrimary
	TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left

	-- Minimize button
	local MinBtn = Instance.new("TextButton", Header)
	MinBtn.Size                = UDim2.new(0, 22, 0, 22)
	MinBtn.Position            = UDim2.new(1, -28, 0.5, -11)
	MinBtn.BackgroundColor3    = Theme.Surface2
	MinBtn.Text                = "−"
	MinBtn.Font                = Theme.FontBold
	MinBtn.TextSize            = 16
	MinBtn.TextColor3          = Theme.TextSecondary
	MinBtn.AutoButtonColor     = false
	MinBtn.BorderSizePixel     = 0
	Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

	-- Scrollable content area
	local Content = Instance.new("ScrollingFrame", Frame)
	Content.Size                 = UDim2.new(1, -(Theme.Padding * 2), 1, -(Theme.HeaderHeight + Theme.Padding))
	Content.Position             = UDim2.new(0, Theme.Padding, 0, Theme.HeaderHeight)
	Content.BackgroundTransparency = 1
	Content.BorderSizePixel      = 0
	Content.ScrollBarThickness   = 2
	Content.ScrollBarImageColor3 = Accent
	Content.ScrollingDirection   = Enum.ScrollingDirection.Y

	local Layout = Instance.new("UIListLayout", Content)
	Layout.Padding    = UDim.new(0, Theme.PaddingSmall)
	Layout.SortOrder  = Enum.SortOrder.LayoutOrder

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + Theme.Padding)
	end)

	-- Dragging logic
	UILib.MakeDraggable(Header, Frame, SaveKey)

	-- Minimize toggle
	local Minimized = false
	local FullHeight = Height
	MinBtn.MouseButton1Click:Connect(function()
		Minimized = not Minimized
		if Minimized then
			TweenService:Create(Frame, QuickTween, { Size = UDim2.new(0, Width, 0, Theme.HeaderHeight) }):Play()
			MinBtn.Text = "+"
		else
			TweenService:Create(Frame, QuickTween, { Size = UDim2.new(0, Width, 0, FullHeight) }):Play()
			MinBtn.Text = "−"
		end
	end)

	return {
		Gui        = Gui,
		Frame      = Frame,
		Header     = Header,
		TitleLabel = TitleLabel,
		Content    = Content,
		Layout     = Layout,
		Accent     = Accent,
		AccentDark = AccentDark,
	}
end

-- ============================================================
-- CreateButton
-- A styled text button with hover animation.
--
-- Options:
--   Text        string   Button label
--   Size        UDim2    (default 80×30)
--   Position    UDim2    (optional)
--   Color       Color3   Background color
--   TextColor   Color3   Label color
--   TextSize    number
--   StrokeColor Color3
--   OnClick     function Called on click
--
-- Returns: TextButton instance
-- ============================================================
function UILib.CreateButton(Parent, Options)
	local Btn = Instance.new("TextButton")
	Btn.Size              = Options.Size or UDim2.new(0, 80, 0, 30)
	if Options.Position then Btn.Position = Options.Position end
	Btn.BackgroundColor3  = Options.Color or Theme.SurfaceHighlight
	Btn.Text              = Options.Text or ""
	Btn.Font              = Theme.FontBold
	Btn.TextSize          = Options.TextSize or Theme.BodySize
	Btn.TextColor3        = Options.TextColor or Theme.TextPrimary
	Btn.AutoButtonColor   = false
	Btn.BorderSizePixel   = 0
	Btn.Parent            = Parent

	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, Theme.CornerRadiusSmall)

	local BtnStroke = Instance.new("UIStroke", Btn)
	BtnStroke.Color        = Options.StrokeColor or Theme.Border
	BtnStroke.Thickness    = 1
	BtnStroke.Transparency = 0.8

	local RestColor  = Options.Color or Theme.SurfaceHighlight
	local HoverColor = Color3.fromRGB(
		math.min(RestColor.R * 255 + 15, 255) / 255,
		math.min(RestColor.G * 255 + 15, 255) / 255,
		math.min(RestColor.B * 255 + 15, 255) / 255
	)

	Btn.MouseEnter:Connect(function()
		TweenService:Create(Btn,      QuickTween, { BackgroundColor3 = HoverColor }):Play()
		TweenService:Create(BtnStroke,QuickTween, { Transparency = 0.4, Color = Theme.BorderFocused }):Play()
	end)
	Btn.MouseLeave:Connect(function()
		TweenService:Create(Btn,      QuickTween, { BackgroundColor3 = RestColor }):Play()
		TweenService:Create(BtnStroke,QuickTween, { Transparency = 0.8, Color = Options.StrokeColor or Theme.Border }):Play()
	end)

	if Options.OnClick then
		Btn.MouseButton1Click:Connect(Options.OnClick)
	end

	return Btn
end

-- ============================================================
-- CreateIconButton
-- A square button typically used for emoji or icon text.
--
-- Options:
--   Icon        string   Text/emoji shown in the button
--   Size        UDim2
--   Color       Color3
--   TextSize    number
--   StrokeColor Color3
--   OnClick     function
--
-- Returns: TextButton instance
-- ============================================================
function UILib.CreateIconButton(Parent, Options)
	local Btn = Instance.new("TextButton")
	Btn.Size              = Options.Size or UDim2.new(0, 30, 0, 30)
	if Options.Position then Btn.Position = Options.Position end
	Btn.BackgroundColor3  = Options.Color or Theme.Surface2
	Btn.Text              = Options.Icon or ""
	Btn.TextSize          = Options.TextSize or 18
	Btn.TextColor3        = Theme.TextPrimary
	Btn.Font              = Theme.FontBold
	Btn.AutoButtonColor   = false
	Btn.BorderSizePixel   = 0
	Btn.Parent            = Parent

	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)

	local BtnStroke = Instance.new("UIStroke", Btn)
	BtnStroke.Color        = Options.StrokeColor or Theme.Border
	BtnStroke.Thickness    = 1
	BtnStroke.Transparency = 0.7

	if Options.OnClick then
		Btn.MouseButton1Click:Connect(Options.OnClick)
	end

	return Btn
end

-- ============================================================
-- CreateSlider
-- A horizontal drag slider with optional label and value display.
--
-- Options:
--   Label      string   Left-side label          (optional)
--   Min        number   Minimum value            (default 0)
--   Max        number   Maximum value            (default 100)
--   Default    number   Starting value           (default Min)
--   Format     string   string.format pattern    (default "%.0f")
--   OnChanged  function Called with (value) when dragged
--
-- Returns: { Frame, Update(value), GetValue() }
-- ============================================================
function UILib.CreateSlider(Parent, Options)
	local Min          = Options.Min     or 0
	local Max          = Options.Max     or 100
	local CurrentValue = Options.Default or Min
	local Format       = Options.Format  or "%.0f"

	local Row = Instance.new("Frame")
	Row.Size                 = UDim2.new(1, 0, 0, 26)
	Row.BackgroundTransparency = 1
	Row.BorderSizePixel      = 0
	Row.Parent               = Parent

	local LabelW = 0
	if Options.Label then
		LabelW = 70
		local Lbl = Instance.new("TextLabel", Row)
		Lbl.Size             = UDim2.new(0, LabelW, 1, 0)
		Lbl.Position         = UDim2.new(0, 2, 0, 0)
		Lbl.BackgroundTransparency = 1
		Lbl.Text             = Options.Label
		Lbl.Font             = Theme.FontRegular
		Lbl.TextSize         = Theme.SmallSize + 1
		Lbl.TextColor3       = Theme.TextSecondary
		Lbl.TextXAlignment   = Enum.TextXAlignment.Left
		Lbl.TextTruncate     = Enum.TextTruncate.AtEnd
	end

	local SliderBg = Instance.new("Frame", Row)
	SliderBg.Size             = UDim2.new(1, -(LabelW + 54), 0, 4)
	SliderBg.Position         = UDim2.new(0, LabelW + 4, 0.5, -2)
	SliderBg.BackgroundColor3 = Theme.Surface3
	SliderBg.BorderSizePixel  = 0
	Instance.new("UICorner", SliderBg).CornerRadius = UDim.new(1, 0)

	local Fill = Instance.new("Frame", SliderBg)
	Fill.BackgroundColor3 = Theme.Accent
	Fill.Size             = UDim2.new(0, 0, 1, 0)
	Fill.BorderSizePixel  = 0
	Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

	local Knob = Instance.new("Frame", SliderBg)
	Knob.Size             = UDim2.new(0, 10, 0, 10)
	Knob.BackgroundColor3 = Theme.TextPrimary
	Knob.AnchorPoint      = Vector2.new(0.5, 0.5)
	Knob.Position         = UDim2.new(0, 0, 0.5, 0)
	Knob.BorderSizePixel  = 0
	Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

	local ValueLabel = Instance.new("TextLabel", Row)
	ValueLabel.Size               = UDim2.new(0, 40, 0, 16)
	ValueLabel.Position           = UDim2.new(1, -44, 0.5, -8)
	ValueLabel.BackgroundTransparency = 1
	ValueLabel.TextColor3         = Theme.TextPrimary
	ValueLabel.Font               = Theme.FontMedium
	ValueLabel.TextSize           = Theme.SmallSize + 1
	ValueLabel.TextXAlignment     = Enum.TextXAlignment.Right

	local function Update(Val)
		Val           = math.clamp(Val, Min, Max)
		CurrentValue  = Val
		ValueLabel.Text = string.format(Format, Val)
		local Pct = (Val - Min) / (Max - Min)
		Fill.Size     = UDim2.new(Pct, 0, 1, 0)
		Knob.Position = UDim2.new(Pct, 0, 0.5, 0)
		if Options.OnChanged then Options.OnChanged(Val) end
	end
	Update(CurrentValue)

	local Dragging = false
	SliderBg.InputBegan:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = true
			local X = Input.Position.X
			local R = SliderBg.AbsolutePosition.X
			local W = SliderBg.AbsoluteSize.X
			Update(Min + ((X - R) / W) * (Max - Min))
		end
	end)
	UserInputService.InputEnded:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(Input)
		if Dragging and (Input.UserInputType == Enum.UserInputType.MouseMovement
		or Input.UserInputType == Enum.UserInputType.Touch) then
			local X = Input.Position.X
			local R = SliderBg.AbsolutePosition.X
			local W = SliderBg.AbsoluteSize.X
			Update(Min + math.clamp((X - R) / W, 0, 1) * (Max - Min))
		end
	end)

	return {
		Frame    = Row,
		Update   = Update,
		GetValue = function() return CurrentValue end,
	}
end

-- ============================================================
-- CreateTextInput
-- A labeled text box that fires OnSubmit when focus is lost.
--
-- Options:
--   Label       string   Row label
--   Placeholder string
--   Default     string   Initial text
--   Width       number   Box width in pixels (default 90)
--   OnSubmit    function Called with (text) on FocusLost
--
-- Returns: { Frame, TextBox }
-- ============================================================
function UILib.CreateTextInput(Parent, Options)
	local Row  = UILib.CreateRow(Parent, Options.Label or "")
	local BoxW = Options.Width or 90

	local Box = Instance.new("TextBox", Row)
	Box.Size               = UDim2.new(0, BoxW, 0, 20)
	Box.Position           = UDim2.new(1, -BoxW - 4, 0.5, -10)
	Box.BackgroundColor3   = Theme.Surface2
	Box.Text               = tostring(Options.Default or "")
	Box.Font               = Theme.FontRegular
	Box.TextSize           = Theme.SmallSize
	Box.TextColor3         = Theme.TextPrimary
	Box.PlaceholderText    = Options.Placeholder or ""
	Box.PlaceholderColor3  = Theme.TextTertiary
	Box.ClearTextOnFocus   = false
	Box.BorderSizePixel    = 0
	Instance.new("UICorner", Box).CornerRadius = UDim.new(0, Theme.CornerRadiusXs)

	local BoxStroke = Instance.new("UIStroke", Box)
	BoxStroke.Color        = Theme.Border
	BoxStroke.Thickness    = 1
	BoxStroke.Transparency = 0.5

	Box.Focused:Connect(function()
		TweenService:Create(BoxStroke, QuickTween, { Transparency = 0.2, Color = Theme.BorderFocused }):Play()
	end)
	Box.FocusLost:Connect(function()
		TweenService:Create(BoxStroke, QuickTween, { Transparency = 0.5, Color = Theme.Border }):Play()
		if Options.OnSubmit then Options.OnSubmit(Box.Text) end
	end)

	return { Frame = Row, TextBox = Box }
end

-- ============================================================
-- CreateTabBar
-- A horizontal tab selector row.
--
-- Options:
--   Tabs          table    Array of tab name strings
--   Default       number   Initially active tab index (default 1)
--   OnTabChanged  function Called with (index, name) on tab click
--
-- Returns: { Frame, SetActiveTab(index), GetActiveTab() }
-- ============================================================
function UILib.CreateTabBar(Parent, Options)
	local Tabs        = Options.Tabs    or {}
	local ActiveIndex = Options.Default or 1

	local Bar = Instance.new("Frame")
	Bar.Size              = UDim2.new(1, 0, 0, Theme.TabHeight)
	Bar.BackgroundColor3  = Theme.Surface0
	Bar.BorderSizePixel   = 0
	Bar.ClipsDescendants  = true
	Bar.Parent            = Parent

	local Inner = Instance.new("Frame", Bar)
	Inner.Size                 = UDim2.new(1, 0, 1, -Theme.DividerHeight)
	Inner.BackgroundTransparency = 1
	Inner.BorderSizePixel      = 0

	local Layout = Instance.new("UIListLayout", Inner)
	Layout.FillDirection      = Enum.FillDirection.Horizontal
	Layout.SortOrder          = Enum.SortOrder.LayoutOrder
	Layout.VerticalAlignment  = Enum.VerticalAlignment.Center

	local BottomLine = Instance.new("Frame", Bar)
	BottomLine.Size             = UDim2.new(1, 0, 0, Theme.DividerHeight)
	BottomLine.Position         = UDim2.new(0, 0, 1, -Theme.DividerHeight)
	BottomLine.BackgroundColor3 = Theme.Divider
	BottomLine.BorderSizePixel  = 0

	local TabButtons = {}
	local Indicators = {}

	local function SetActiveTab(Index)
		ActiveIndex = Index
		for I, Btn in ipairs(TabButtons) do
			local IsActive = (I == Index)
			TweenService:Create(Btn, QuickTween, {
				BackgroundColor3 = IsActive and Theme.Surface2 or Theme.Surface0,
			}):Play()
			Btn.TextColor3 = IsActive and Theme.TextAccent or Theme.TextSecondary
			Btn.Font       = IsActive and Theme.FontBold    or Theme.FontMedium
			Indicators[I].Visible = IsActive
		end
		if Options.OnTabChanged then Options.OnTabChanged(Index, Tabs[Index]) end
	end

	for I, TabName in ipairs(Tabs) do
		local Btn = Instance.new("TextButton")
		Btn.Size              = UDim2.new(0, math.max(#TabName * 7 + 16, 50), 1, 0)
		Btn.BackgroundColor3  = (I == ActiveIndex) and Theme.Surface2 or Theme.Surface0
		Btn.BackgroundTransparency = 0
		Btn.Text              = TabName
		Btn.Font              = (I == ActiveIndex) and Theme.FontBold or Theme.FontMedium
		Btn.TextSize          = Theme.SmallSize
		Btn.TextColor3        = (I == ActiveIndex) and Theme.TextAccent or Theme.TextSecondary
		Btn.AutoButtonColor   = false
		Btn.BorderSizePixel   = 0
		Btn.LayoutOrder       = I
		Btn.Parent            = Inner

		local Indicator = Instance.new("Frame", Btn)
		Indicator.Size             = UDim2.new(1, 0, 0, 2)
		Indicator.Position         = UDim2.new(0, 0, 1, -2)
		Indicator.BackgroundColor3 = Theme.Accent
		Indicator.BorderSizePixel  = 0
		Indicator.Visible          = (I == ActiveIndex)
		Indicators[I] = Indicator

		Btn.MouseEnter:Connect(function()
			if I ~= ActiveIndex then
				TweenService:Create(Btn, QuickTween, { BackgroundColor3 = Theme.Surface3 }):Play()
			end
		end)
		Btn.MouseLeave:Connect(function()
			if I ~= ActiveIndex then
				TweenService:Create(Btn, QuickTween, { BackgroundColor3 = Theme.Surface0 }):Play()
			end
		end)
		Btn.MouseButton1Click:Connect(function() SetActiveTab(I) end)

		TabButtons[I] = Btn
	end

	return {
		Frame        = Bar,
		SetActiveTab = SetActiveTab,
		GetActiveTab = function() return ActiveIndex end,
	}
end

-- ============================================================
-- CreateCard
-- An elevated content group with an optional title and divider.
--
-- Options:
--   Title    string   Card header text (optional)
--   Padding  number   Inner padding    (default Theme.CardPadding)
--
-- Returns: { Frame, Content, TitleLabel }
-- ============================================================
function UILib.CreateCard(Parent, Options)
	Options = Options or {}
	local CardPad = Options.Padding or Theme.CardPadding

	local Card = Instance.new("Frame")
	Card.Size                 = UDim2.new(1, 0, 0, 0)
	Card.BackgroundColor3     = Theme.Surface0
	Card.BorderSizePixel      = 0
	Card.ClipsDescendants     = true
	Card.Parent               = Parent

	Instance.new("UICorner", Card).CornerRadius = UDim.new(0, Theme.CornerRadiusSmall)

	local TitleLabel = nil
	local HeaderH    = 0

	if Options.Title then
		HeaderH = 22
		TitleLabel = Instance.new("TextLabel", Card)
		TitleLabel.Size               = UDim2.new(1, -(CardPad * 2), 0, HeaderH)
		TitleLabel.Position           = UDim2.new(0, CardPad, 0, 0)
		TitleLabel.BackgroundTransparency = 1
		TitleLabel.Text               = Options.Title
		TitleLabel.Font               = Theme.FontBold
		TitleLabel.TextSize           = Theme.CaptionSize + 1
		TitleLabel.TextColor3         = Theme.TextTertiary
		TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left

		local Div = Instance.new("Frame", Card)
		Div.Size             = UDim2.new(1, -(CardPad * 2), 0, Theme.DividerHeight)
		Div.Position         = UDim2.new(0, CardPad, 0, HeaderH)
		Div.BackgroundColor3 = Theme.Divider
		Div.BorderSizePixel  = 0
		HeaderH = HeaderH + Theme.DividerHeight
	end

	local Content = Instance.new("Frame", Card)
	Content.Position          = UDim2.new(0, 0, 0, HeaderH)
	Content.Size              = UDim2.new(1, 0, 0, 0)
	Content.AutomaticSize     = Enum.AutomaticSize.Y
	Content.BackgroundTransparency = 1
	Content.BorderSizePixel   = 0

	local ContentLayout = Instance.new("UIListLayout", Content)
	ContentLayout.Padding     = UDim.new(0, 2)
	ContentLayout.SortOrder   = Enum.SortOrder.LayoutOrder

	local ContentPadding = Instance.new("UIPadding", Content)
	ContentPadding.PaddingLeft   = UDim.new(0, Theme.PaddingSmall)
	ContentPadding.PaddingRight  = UDim.new(0, Theme.PaddingSmall)
	ContentPadding.PaddingTop    = UDim.new(0, Theme.PaddingXSmall)
	ContentPadding.PaddingBottom = UDim.new(0, Theme.PaddingXSmall)

	local function UpdateCardSize()
		Card.Size = UDim2.new(1, 0, 0,
			HeaderH + ContentLayout.AbsoluteContentSize.Y + Theme.PaddingXSmall * 2)
	end
	ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateCardSize)
	task.defer(UpdateCardSize)

	return { Frame = Card, Content = Content, TitleLabel = TitleLabel }
end

-- ============================================================
-- CreateDivider
-- A thin 1 px horizontal separator line.
--
-- Returns: Frame instance
-- ============================================================
function UILib.CreateDivider(Parent)
	local Div = Instance.new("Frame")
	Div.Size             = UDim2.new(1, 0, 0, Theme.DividerHeight)
	Div.BackgroundColor3 = Theme.Divider
	Div.BorderSizePixel  = 0
	Div.Parent           = Parent
	return Div
end

-- ============================================================
-- CreateStatusBadge
-- A small colored pill with a dot and label.
--
-- Options:
--   Text   string   Badge label
--   Color  Color3   Dot and text color
--
-- Returns: { Frame, SetStatus(text, color) }
-- ============================================================
function UILib.CreateStatusBadge(Parent, Options)
	local Badge = Instance.new("Frame")
	Badge.Size                  = UDim2.new(0, 0, 0, 20)
	Badge.AutomaticSize         = Enum.AutomaticSize.X
	Badge.BackgroundColor3      = Options.Color or Theme.TextSecondary
	Badge.BackgroundTransparency = 0.88
	Badge.BorderSizePixel       = 0
	Badge.Parent                = Parent

	Instance.new("UICorner", Badge).CornerRadius = UDim.new(0, Theme.CornerRadiusXs)

	local BP = Instance.new("UIPadding", Badge)
	BP.PaddingLeft  = UDim.new(0, 6)
	BP.PaddingRight = UDim.new(0, 8)

	local Dot = Instance.new("Frame", Badge)
	Dot.Size             = UDim2.new(0, 6, 0, 6)
	Dot.Position         = UDim2.new(0, 0, 0.5, -3)
	Dot.BackgroundColor3 = Options.Color or Theme.TextSecondary
	Dot.BorderSizePixel  = 0
	Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

	local Label = Instance.new("TextLabel", Badge)
	Label.Size               = UDim2.new(0, 0, 1, 0)
	Label.AutomaticSize      = Enum.AutomaticSize.X
	Label.Position           = UDim2.new(0, 10, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text               = Options.Text or ""
	Label.Font               = Theme.FontMedium
	Label.TextSize           = Theme.CaptionSize + 1
	Label.TextColor3         = Options.Color or Theme.TextSecondary

	local function SetStatus(Text, Color)
		Label.Text = Text
		if Color then
			Label.TextColor3     = Color
			Dot.BackgroundColor3 = Color
			Badge.BackgroundColor3 = Color
		end
	end

	return { Frame = Badge, SetStatus = SetStatus }
end

-- ============================================================
-- CreateProgressBar
-- A tween-animated horizontal fill bar.
--
-- Options:
--   Height  number   Bar height in pixels  (default 4)
--   Color   Color3   Fill color            (default Theme.Accent)
--
-- Returns: { Frame, SetProgress(0–1), SetColor(Color3) }
-- ============================================================
function UILib.CreateProgressBar(Parent, Options)
	Options   = Options or {}
	local BarH = Options.Height or 4
	local BarC = Options.Color  or Theme.Accent

	local Bg = Instance.new("Frame")
	Bg.Size             = UDim2.new(1, 0, 0, BarH)
	Bg.BackgroundColor3 = Theme.Surface0
	Bg.BorderSizePixel  = 0
	Bg.Parent           = Parent
	Instance.new("UICorner", Bg).CornerRadius = UDim.new(1, 0)

	local Fill = Instance.new("Frame", Bg)
	Fill.Size             = UDim2.new(0, 0, 1, 0)
	Fill.BackgroundColor3 = BarC
	Fill.BorderSizePixel  = 0
	Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

	local function SetProgress(Pct)
		Pct = math.clamp(Pct, 0, 1)
		TweenService:Create(Fill, QuickTween, { Size = UDim2.new(Pct, 0, 1, 0) }):Play()
	end

	local function SetColor(Color)
		Fill.BackgroundColor3 = Color
	end

	return { Frame = Bg, SetProgress = SetProgress, SetColor = SetColor }
end

-- ============================================================
-- CreateButtonGroup
-- Mutually-exclusive horizontal segmented control.
--
-- Options:
--   Buttons    table    Array of {Text, Key} pairs (or {Text=, Key=})
--   Default    string   Initially active key
--   OnChanged  function Called with (key) on selection
--
-- Returns: { Frame, SetActive(key), GetActive() }
-- ============================================================
function UILib.CreateButtonGroup(Parent, Options)
	local ActiveKey = Options.Default
	local Buttons   = Options.Buttons or {}

	local Group = Instance.new("Frame")
	Group.Size                 = UDim2.new(1, 0, 0, 28)
	Group.BackgroundTransparency = 1
	Group.BorderSizePixel      = 0
	Group.Parent               = Parent

	local GL = Instance.new("UIListLayout", Group)
	GL.FillDirection  = Enum.FillDirection.Horizontal
	GL.Padding        = UDim.new(0, Theme.PaddingXSmall)
	GL.SortOrder      = Enum.SortOrder.LayoutOrder

	local BtnRefs = {}

	local function SetActive(Key)
		ActiveKey = Key
		for _, Entry in ipairs(BtnRefs) do
			local IsActive = (Entry.Key == Key)
			TweenService:Create(Entry.Btn, QuickTween, {
				BackgroundColor3 = IsActive and Theme.Accent or Theme.Surface2,
			}):Play()
			Entry.Btn.TextColor3 = IsActive and Color3.new(0,0,0) or Theme.TextSecondary
			Entry.Btn.Font       = IsActive and Theme.FontBold   or Theme.FontMedium
		end
		if Options.OnChanged then Options.OnChanged(Key) end
	end

	for I, BtnDef in ipairs(Buttons) do
		local Text = BtnDef[1] or BtnDef.Text
		local Key  = BtnDef[2] or BtnDef.Key or Text
		local IsActive = (Key == ActiveKey)

		local Btn = Instance.new("TextButton")
		Btn.Size              = UDim2.new(0, 0, 1, 0)
		Btn.AutomaticSize     = Enum.AutomaticSize.X
		Btn.BackgroundColor3  = IsActive and Theme.Accent or Theme.Surface2
		Btn.Text              = "  " .. Text .. "  "
		Btn.Font              = IsActive and Theme.FontBold or Theme.FontMedium
		Btn.TextSize          = Theme.SmallSize
		Btn.TextColor3        = IsActive and Color3.new(0,0,0) or Theme.TextSecondary
		Btn.AutoButtonColor   = false
		Btn.BorderSizePixel   = 0
		Btn.LayoutOrder       = I
		Btn.Parent            = Group

		Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, Theme.CornerRadiusXs)

		Btn.MouseButton1Click:Connect(function() SetActive(Key) end)
		table.insert(BtnRefs, { Btn = Btn, Key = Key })
	end

	return {
		Frame     = Group,
		SetActive = SetActive,
		GetActive = function() return ActiveKey end,
	}
end

-- ============================================================
-- CreateToggleSwitch
-- A compact animated on/off toggle.
--
-- Args:
--   Parent       Instance
--   InitialState bool
--   Callback     function(newState, SetFn)   -- called on click
--
-- Returns: { Set(bool), Container }
-- ============================================================
function UILib.CreateToggleSwitch(Parent, InitialState, Callback)
	local Sw = Instance.new("Frame")
	Sw.Size             = UDim2.new(0, 28, 0, 14)
	Sw.Position         = UDim2.new(1, -32, 0.5, -7)
	Sw.BackgroundColor3 = InitialState and Theme.Accent or Theme.Surface3
	Sw.BorderSizePixel  = 0
	Instance.new("UICorner", Sw).CornerRadius = UDim.new(1, 0)
	Sw.Parent = Parent

	local Dot = Instance.new("Frame")
	Dot.Size             = UDim2.new(0, 10, 0, 10)
	Dot.Position         = InitialState and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)
	Dot.BackgroundColor3 = Color3.new(1,1,1)
	Dot.BorderSizePixel  = 0
	Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)
	Dot.Parent = Sw

	local Btn = Instance.new("TextButton")
	Btn.Size                = UDim2.new(1,0,1,0)
	Btn.BackgroundTransparency = 1
	Btn.Text                = ""
	Btn.Parent              = Sw

	local IsOn = InitialState
	local function SetState(S)
		IsOn = S
		TweenService:Create(Dot, QuickTween,
			{ Position = IsOn and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5) }):Play()
		TweenService:Create(Sw,  QuickTween,
			{ BackgroundColor3 = IsOn and Theme.Accent or Theme.Surface3 }):Play()
	end

	Btn.MouseButton1Click:Connect(function()
		if Callback then Callback(not IsOn, SetState) end
	end)

	return { Set = SetState, Container = Sw }
end

-- ============================================================
-- CreateRow
-- A flat label+control container row (used internally and externally).
--
-- Args:
--   Parent  Instance
--   Text    string   Left-side label
--   Height  number   Row height (default 26)
--
-- Returns: Frame
-- ============================================================
function UILib.CreateRow(Parent, Text, Height)
	local RowH = Height or 26

	local Row = Instance.new("Frame")
	Row.Size                 = UDim2.new(1, 0, 0, RowH)
	Row.BackgroundTransparency = 1
	Row.BorderSizePixel      = 0

	local Lbl = Instance.new("TextLabel", Row)
	Lbl.Size             = UDim2.new(0.65, 0, 1, 0)
	Lbl.Position         = UDim2.new(0, 2, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Text             = Text
	Lbl.Font             = Theme.FontRegular
	Lbl.TextColor3       = Theme.TextSecondary
	Lbl.TextSize         = Theme.SmallSize + 1
	Lbl.TextXAlignment   = Enum.TextXAlignment.Left
	Lbl.TextTruncate     = Enum.TextTruncate.AtEnd
	Row.Parent = Parent
	return Row
end

-- ============================================================
-- CreateSectionHeader
-- A bold accent-colored section label with a decorative bar.
--
-- Args:
--   Parent  Instance
--   Text    string
--
-- Returns: Frame
-- ============================================================
function UILib.CreateSectionHeader(Parent, Text)
	local Row = Instance.new("Frame")
	Row.Size                 = UDim2.new(1, 0, 0, 28)
	Row.BackgroundTransparency = 1
	Row.Parent               = Parent

	local AccentBar = Instance.new("Frame", Row)
	AccentBar.Size             = UDim2.new(0, 3, 0, 16)
	AccentBar.Position         = UDim2.new(0, 4, 0.5, -8)
	AccentBar.BackgroundColor3 = Theme.Accent
	AccentBar.BorderSizePixel  = 0
	Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(0, 2)

	local Lbl = Instance.new("TextLabel", Row)
	Lbl.Size             = UDim2.new(1, -20, 1, 0)
	Lbl.Position         = UDim2.new(0, 14, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Text             = Text
	Lbl.TextColor3       = Theme.Accent
	Lbl.TextSize         = Theme.SmallSize + 1
	Lbl.Font             = Theme.FontBold
	Lbl.TextXAlignment   = Enum.TextXAlignment.Left

	local Line = Instance.new("Frame", Row)
	Line.Size             = UDim2.new(1, -80, 0, 1)
	Line.Position         = UDim2.new(0, 75, 0.5, 0)
	Line.BackgroundColor3 = Theme.Accent
	Line.BackgroundTransparency = 0.7
	Line.BorderSizePixel  = 0

	return Row
end

-- ============================================================
-- CreateGradient
-- Applies a UIGradient to a parent frame.
--
-- Args:
--   Parent  Instance
--   Color   Color3   (default Theme.AccentDark)
--
-- Returns: UIGradient instance
-- ============================================================
function UILib.CreateGradient(Parent, Color)
	local G = Instance.new("UIGradient", Parent)
	G.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color or Theme.AccentDark),
		ColorSequenceKeypoint.new(1, Color or Theme.AccentDark),
	})
	G.Rotation = 45
	return G
end

-- ============================================================
-- ShowNotification
-- Shows a temporary floating notification banner.
--
-- Args:
--   Title  string
--   Text   string
-- ============================================================
function UILib.ShowNotification(Title, Text)
	local Existing = PlayerGui:FindFirstChild("UILibNotif")
	if Existing then Existing:Destroy() end

	local Sg = Instance.new("ScreenGui", PlayerGui)
	Sg.Name          = "UILibNotif"
	Sg.ResetOnSpawn  = false
	Sg.DisplayOrder  = 999

	local W, H = 260, 36

	local F = Instance.new("Frame", Sg)
	F.Size             = UDim2.new(0, W, 0, H)
	F.Position         = UDim2.new(0.5, -W/2, 0, -H)
	F.BackgroundColor3 = Theme.Surface0
	F.BackgroundTransparency = 0
	F.BorderSizePixel  = 0
	Instance.new("UICorner", F).CornerRadius = UDim.new(0, Theme.CornerRadiusSmall)

	local Stroke = Instance.new("UIStroke", F)
	Stroke.Color        = Theme.Accent
	Stroke.Thickness    = 1
	Stroke.Transparency = 0.6

	local Label = Instance.new("TextLabel", F)
	Label.Size               = UDim2.new(1, -16, 1, 0)
	Label.Position           = UDim2.new(0, 8, 0, 0)
	Label.BackgroundTransparency = 1
	Label.RichText           = true
	Label.Text               = string.format(
		"<font color='rgb(%d,%d,%d)'><b>%s</b></font>  %s",
		math.floor(Theme.Accent.R * 255),
		math.floor(Theme.Accent.G * 255),
		math.floor(Theme.Accent.B * 255),
		Title:upper(), Text
	)
	Label.Font               = Theme.FontMedium
	Label.TextSize           = Theme.SmallSize
	Label.TextColor3         = Theme.TextSecondary
	Label.TextXAlignment     = Enum.TextXAlignment.Left
	Label.TextTruncate       = Enum.TextTruncate.AtEnd

	-- Slide in → wait → slide out
	TweenService:Create(F, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -W/2, 0, 10) }):Play()
	task.delay(2.5, function()
		if Sg.Parent then
			TweenService:Create(F, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = UDim2.new(0.5, -W/2, 0, -H) }):Play()
			task.delay(0.25, function() if Sg.Parent then Sg:Destroy() end end)
		end
	end)
end

-- ============================================================
-- MakeDraggable
-- Makes any Frame/TextButton draggable by a handle.
--
-- Args:
--   Handle   Instance   The part the user grabs
--   Target   Instance   The part that actually moves
--   SaveKey  string     Optional key for position persistence
-- ============================================================
function UILib.MakeDraggable(Handle, Target, SaveKey)
	local Dragging, DragInput, DragStart, StartPos

	Handle.InputBegan:Connect(function(Input)
		if Config.UILocked then return end
		if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
			Dragging  = true
			DragStart = Input.Position
			StartPos  = Target.Position
			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
					if SaveKey then
						local PS = Target.Parent.AbsoluteSize
						Config.Positions[SaveKey] = {
							X = Target.AbsolutePosition.X / PS.X,
							Y = Target.AbsolutePosition.Y / PS.Y,
						}
					end
				end
			end)
		end
	end)

	Handle.InputChanged:Connect(function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseMovement
		or Input.UserInputType == Enum.UserInputType.Touch then
			DragInput = Input
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if Input == DragInput and Dragging then
			local Delta = Input.Position - DragStart
			Target.Position = UDim2.new(
				StartPos.X.Scale,  StartPos.X.Offset + Delta.X,
				StartPos.Y.Scale,  StartPos.Y.Offset + Delta.Y
			)
		end
	end)
end

-- ============================================================
-- Expose internal config for advanced users
-- ============================================================
UILib.Config = Config

return UILib
