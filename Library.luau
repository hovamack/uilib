--[[
    IMGui UI Library - Polished Edition v3
    Fixes: tabs visible, dropdown/colorpicker overlay panels that never get clipped
]]

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

local T = {
    Background    = Color3.fromRGB(12, 12, 14),
    Surface       = Color3.fromRGB(20, 20, 24),
    SurfaceHigh   = Color3.fromRGB(30, 30, 36),
    TitleBar      = Color3.fromRGB(16, 16, 20),
    TabBar        = Color3.fromRGB(14, 14, 18),
    TabActive     = Color3.fromRGB(22, 22, 28),
    Accent        = Color3.fromRGB(99, 179, 237),
    AccentDim     = Color3.fromRGB(56, 112, 160),
    TextPrimary   = Color3.fromRGB(235, 235, 240),
    TextSecondary = Color3.fromRGB(140, 140, 155),
    TextMuted     = Color3.fromRGB(75, 75, 90),
    Border        = Color3.fromRGB(40, 40, 50),
    BorderFocus   = Color3.fromRGB(99, 179, 237),
    ControlBg     = Color3.fromRGB(26, 26, 32),
    ControlHov    = Color3.fromRGB(36, 36, 44),
    Font          = Enum.Font.GothamMedium,
    FontLight     = Enum.Font.Gotham,
    TextSize      = 13,
}

local Library = { Theme = T, Windows = {} }

-- ── Global overlay close registry ────────────────────────────────────────────
-- Every dropdown/colorpicker registers a closer here.
-- One global InputBegan fires them all when clicking outside.
local OverlayClosers = {}

local function RegisterCloser(panel, selBtn, onClose)
    table.insert(OverlayClosers, { panel = panel, selBtn = selBtn, onClose = onClose })
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    for _, entry in ipairs(OverlayClosers) do
        if entry.panel.Visible then
            -- Check if click landed inside the panel or the trigger button
            local function insideFrame(frame)
                local pos  = frame.AbsolutePosition
                local size = frame.AbsoluteSize
                local mp   = UserInputService:GetMouseLocation()
                return mp.X >= pos.X and mp.X <= pos.X + size.X
                   and mp.Y >= pos.Y and mp.Y <= pos.Y + size.Y
            end
            if not insideFrame(entry.panel) and not insideFrame(entry.selBtn) then
                entry.onClose()
            end
        end
    end
end)

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function Tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function Corner(p, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 4); c.Parent = p; return c
end

local function Stroke(p, col, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or T.Border; s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Parent = p; return s
end

local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos = false
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = i.Position; startPos = frame.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    handle.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if i == dragInput and dragging then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ── CreateWindow ─────────────────────────────────────────────────────────────

function Library:CreateWindow(options)
    options = options or {}
    local Title = options.Title or "Window"
    local Size  = options.Size  or UDim2.fromOffset(520, 420)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "IMGuiLib"
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.DisplayOrder   = 100
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.Parent = RunService:IsStudio()
        and LocalPlayer:WaitForChild("PlayerGui")
        or game:GetService("CoreGui")

    -- Overlay frame for dropdowns/colorpickers that need to float above everything
    local Overlay = Instance.new("Frame")
    Overlay.Name                = "Overlay"
    Overlay.Size                = UDim2.new(1, 0, 1, 0)
    Overlay.BackgroundTransparency = 1
    Overlay.BorderSizePixel     = 0
    Overlay.ZIndex              = 500
    Overlay.Parent              = ScreenGui

    -- Main window frame
    local Main = Instance.new("Frame")
    Main.Name             = "Main"
    Main.Size             = Size
    Main.Position         = UDim2.new(0.5, -Size.X.Offset/2, 0.5, -Size.Y.Offset/2)
    Main.BackgroundColor3 = T.Background
    Main.BorderSizePixel  = 0
    Main.ClipsDescendants = false   -- must be false so overlay can receive input
    Main.ZIndex           = 1
    Main.Parent           = ScreenGui
    Corner(Main, 6); Stroke(Main, T.Border, 1)

    -- ── Titlebar ─────────────────────────────────────────────────────────────
    local TitleBar = Instance.new("Frame")
    TitleBar.Size             = UDim2.new(1, 0, 0, 32)
    TitleBar.BackgroundColor3 = T.TitleBar
    TitleBar.BorderSizePixel  = 0
    TitleBar.ZIndex           = 2
    TitleBar.Parent           = Main
    Corner(TitleBar, 0)

    -- Top rounded corners only (fake via inner fill)
    local TitleBarTop = Instance.new("Frame")
    TitleBarTop.Size             = UDim2.new(1, 0, 0, 10)
    TitleBarTop.BackgroundColor3 = T.TitleBar
    TitleBarTop.BorderSizePixel  = 0
    TitleBarTop.ZIndex           = 2
    TitleBarTop.Parent           = Main

    local AccentLine = Instance.new("Frame")
    AccentLine.Size                   = UDim2.new(1, 0, 0, 1)
    AccentLine.Position               = UDim2.new(0, 0, 1, -1)
    AccentLine.BackgroundColor3       = T.Accent
    AccentLine.BackgroundTransparency = 0.5
    AccentLine.BorderSizePixel        = 0
    AccentLine.ZIndex                 = 3
    AccentLine.Parent                 = TitleBar

    -- Traffic light dots
    for i, col in ipairs({ Color3.fromRGB(255,95,87), Color3.fromRGB(255,189,46), Color3.fromRGB(40,200,64) }) do
        local dot = Instance.new("Frame")
        dot.Size             = UDim2.fromOffset(10, 10)
        dot.Position         = UDim2.new(0, 8 + (i-1)*16, 0.5, -5)
        dot.BackgroundColor3 = col
        dot.BorderSizePixel  = 0
        dot.ZIndex           = 3
        dot.Parent           = TitleBar
        Corner(dot, 5)
    end

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size               = UDim2.new(1, 0, 1, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Text               = Title
    TitleLbl.TextColor3         = T.TextPrimary
    TitleLbl.TextSize           = 13
    TitleLbl.Font               = Enum.Font.GothamBold
    TitleLbl.TextXAlignment     = Enum.TextXAlignment.Center
    TitleLbl.ZIndex             = 3
    TitleLbl.Parent             = TitleBar
    MakeDraggable(Main, TitleBar)

    -- ── Tab bar (NO UIPadding — it was shrinking buttons to zero height) ─────
    local TAB_H = 28
    local TabBar = Instance.new("Frame")
    TabBar.Name             = "TabBar"
    TabBar.Size             = UDim2.new(1, 0, 0, TAB_H)
    TabBar.Position         = UDim2.new(0, 0, 0, 32)
    TabBar.BackgroundColor3 = T.TabBar
    TabBar.BorderSizePixel  = 0
    TabBar.ClipsDescendants = false
    TabBar.ZIndex           = 2
    TabBar.Parent           = Main

    local TabSep = Instance.new("Frame")
    TabSep.Size             = UDim2.new(1, 0, 0, 1)
    TabSep.Position         = UDim2.new(0, 0, 1, -1)
    TabSep.BackgroundColor3 = T.Border
    TabSep.BorderSizePixel  = 0
    TabSep.ZIndex           = 3
    TabSep.Parent           = TabBar

    -- Tab buttons are positioned manually (no UIListLayout on TabBar itself —
    -- that was competing with UIPadding and misaligning everything)
    local tabXOffset = 6  -- running X position for next tab button

    -- Content area
    local HEADER_H = 32 + TAB_H  -- 60px total
    local ContentArea = Instance.new("Frame")
    ContentArea.Name                = "ContentArea"
    ContentArea.Size                = UDim2.new(1, 0, 1, -HEADER_H)
    ContentArea.Position            = UDim2.new(0, 0, 0, HEADER_H)
    ContentArea.BackgroundTransparency = 1
    ContentArea.BorderSizePixel     = 0
    ContentArea.ZIndex              = 1
    ContentArea.Parent              = Main

    local Window = { Tabs = {} }

    -- ── AddTab ───────────────────────────────────────────────────────────────
    function Window:AddTab(name)
        local TAB_W     = math.max(70, #name * 8 + 20)
        local TAB_INNER = TAB_H - 8  -- vertical padding of 4px each side

        local TabBtn = Instance.new("TextButton")
        TabBtn.Name             = name .. "_TabBtn"
        TabBtn.Size             = UDim2.fromOffset(TAB_W, TAB_INNER)
        TabBtn.Position         = UDim2.new(0, tabXOffset, 0, 4)  -- 4px top padding
        TabBtn.BackgroundColor3 = T.TabBar
        TabBtn.BorderSizePixel  = 0
        TabBtn.Text             = name
        TabBtn.TextColor3       = T.TextMuted
        TabBtn.TextSize         = 12
        TabBtn.Font             = Enum.Font.GothamMedium
        TabBtn.AutoButtonColor  = false
        TabBtn.ZIndex           = 3
        TabBtn.Parent           = TabBar
        Corner(TabBtn, 3)

        tabXOffset = tabXOffset + TAB_W + 2  -- advance position for next tab

        local TabInd = Instance.new("Frame")
        TabInd.Size             = UDim2.new(0.6, 0, 0, 2)
        TabInd.Position         = UDim2.new(0.2, 0, 1, 0)
        TabInd.BackgroundColor3 = T.Accent
        TabInd.BorderSizePixel  = 0
        TabInd.Visible          = false
        TabInd.ZIndex           = 4
        TabInd.Parent           = TabBtn
        Corner(TabInd, 1)

        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Name                       = name .. "_Scroll"
        Scroll.Size                       = UDim2.new(1, 0, 1, 0)
        Scroll.BackgroundTransparency     = 1
        Scroll.BorderSizePixel            = 0
        Scroll.Visible                    = false
        Scroll.ScrollBarThickness         = 3
        Scroll.ScrollBarImageColor3       = T.Accent
        Scroll.ScrollBarImageTransparency = 0.4
        Scroll.CanvasSize                 = UDim2.new(0, 0, 0, 0)
        Scroll.ClipsDescendants           = true
        Scroll.ZIndex                     = 2
        Scroll.Parent                     = ContentArea

        local ScrollPad = Instance.new("UIPadding")
        ScrollPad.PaddingTop    = UDim.new(0, 10)
        ScrollPad.PaddingBottom = UDim.new(0, 10)
        ScrollPad.PaddingLeft   = UDim.new(0, 10)
        ScrollPad.PaddingRight  = UDim.new(0, 13)
        ScrollPad.Parent        = Scroll

        local ScrollList = Instance.new("UIListLayout")
        ScrollList.SortOrder = Enum.SortOrder.LayoutOrder
        ScrollList.Padding   = UDim.new(0, 8)
        ScrollList.Parent    = Scroll

        ScrollList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0, 0, 0, ScrollList.AbsoluteContentSize.Y + 20)
        end)

        local Tab = { Button = TabBtn, Content = Scroll, Indicator = TabInd }

        local function Select()
            for _, t in pairs(Window.Tabs) do
                t.Content.Visible = false
                Tween(t.Button, { TextColor3 = T.TextMuted, BackgroundColor3 = T.TabBar }, 0.1)
                t.Indicator.Visible = false
            end
            Scroll.Visible          = true
            TabInd.Visible          = true
            Tween(TabBtn, { TextColor3 = T.TextPrimary, BackgroundColor3 = T.TabActive }, 0.1)
        end

        TabBtn.MouseButton1Click:Connect(Select)
        TabBtn.MouseEnter:Connect(function()
            if not Scroll.Visible then Tween(TabBtn, { TextColor3 = T.TextSecondary }, 0.1) end
        end)
        TabBtn.MouseLeave:Connect(function()
            if not Scroll.Visible then Tween(TabBtn, { TextColor3 = T.TextMuted }, 0.1) end
        end)

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then Select() end

        -- ── AddGroupbox ──────────────────────────────────────────────────────
        function Tab:AddGroupbox(title)
            local GroupFrame = Instance.new("Frame")
            GroupFrame.Name             = title .. "_Group"
            GroupFrame.Size             = UDim2.new(1, 0, 0, 20)
            GroupFrame.BackgroundColor3 = T.Surface
            GroupFrame.BorderSizePixel  = 0
            GroupFrame.ClipsDescendants = false
            GroupFrame.ZIndex           = 3
            GroupFrame.Parent           = Scroll
            Corner(GroupFrame, 5); Stroke(GroupFrame, T.Border, 1)

            local TitlePill = Instance.new("Frame")
            TitlePill.Size             = UDim2.new(0, 10, 0, 18)
            TitlePill.Position         = UDim2.new(0, 10, 0, -9)
            TitlePill.BackgroundColor3 = T.Surface
            TitlePill.BorderSizePixel  = 0
            TitlePill.AutomaticSize    = Enum.AutomaticSize.X
            TitlePill.ZIndex           = 5
            TitlePill.Parent           = GroupFrame

            local TitleTxt = Instance.new("TextLabel")
            TitleTxt.Size               = UDim2.new(1, 0, 1, 0)
            TitleTxt.BackgroundTransparency = 1
            TitleTxt.Text               = title
            TitleTxt.TextColor3         = T.Accent
            TitleTxt.TextSize           = 11
            TitleTxt.Font               = Enum.Font.GothamBold
            TitleTxt.AutomaticSize      = Enum.AutomaticSize.X
            TitleTxt.ZIndex             = 6
            TitleTxt.Parent             = TitlePill
            local tp = Instance.new("UIPadding")
            tp.PaddingLeft = UDim.new(0,5); tp.PaddingRight = UDim.new(0,5); tp.Parent = TitlePill

            local Inner = Instance.new("Frame")
            Inner.Size                = UDim2.new(1, 0, 1, 0)
            Inner.BackgroundTransparency = 1
            Inner.ZIndex              = 3
            Inner.Parent              = GroupFrame

            local InnerList = Instance.new("UIListLayout")
            InnerList.SortOrder = Enum.SortOrder.LayoutOrder
            InnerList.Padding   = UDim.new(0, 5)
            InnerList.Parent    = Inner

            local InnerPad = Instance.new("UIPadding")
            InnerPad.PaddingTop    = UDim.new(0, 16)
            InnerPad.PaddingBottom = UDim.new(0, 10)
            InnerPad.PaddingLeft   = UDim.new(0, 8)
            InnerPad.PaddingRight  = UDim.new(0, 8)
            InnerPad.Parent        = Inner

            local function RefreshSize()
                local h = InnerList.AbsoluteContentSize.Y + 26
                GroupFrame.Size = UDim2.new(1, 0, 0, h)
                Inner.Size      = UDim2.new(1, 0, 0, h)
            end
            InnerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshSize)

            local Gb = {}

            -- ── Toggle ───────────────────────────────────────────────────────
            function Gb:AddToggle(text, opts, callback)
                opts = opts or {}
                local state = opts.Default or false

                local Row = Instance.new("TextButton")
                Row.Size               = UDim2.new(1, 0, 0, 22)
                Row.BackgroundTransparency = 1
                Row.Text               = ""; Row.AutoButtonColor = false
                Row.ZIndex             = 4; Row.Parent = Inner

                local Track = Instance.new("Frame")
                Track.Size             = UDim2.fromOffset(32, 16)
                Track.Position         = UDim2.new(1, -32, 0.5, -8)
                Track.BackgroundColor3 = state and T.Accent or T.ControlBg
                Track.BorderSizePixel  = 0; Track.ZIndex = 5; Track.Parent = Row
                Corner(Track, 8); Stroke(Track, T.Border, 1)

                local Knob = Instance.new("Frame")
                Knob.Size             = UDim2.fromOffset(12, 12)
                Knob.Position         = state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
                Knob.BackgroundColor3 = Color3.new(1,1,1)
                Knob.BorderSizePixel  = 0; Knob.ZIndex = 6; Knob.Parent = Track
                Corner(Knob, 6)

                local Lbl = Instance.new("TextLabel")
                Lbl.Size               = UDim2.new(1, -44, 1, 0)
                Lbl.BackgroundTransparency = 1
                Lbl.Text               = text; Lbl.TextColor3 = T.TextPrimary
                Lbl.TextSize           = T.TextSize; Lbl.Font = T.FontLight
                Lbl.TextXAlignment     = Enum.TextXAlignment.Left
                Lbl.ZIndex             = 4; Lbl.Parent = Row

                local function SetState(v)
                    state = v
                    Tween(Track, { BackgroundColor3 = v and T.Accent or T.ControlBg }, 0.15)
                    Tween(Knob,  { Position = v and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6) }, 0.15)
                    if callback then callback(state) end
                end
                Row.MouseButton1Click:Connect(function() SetState(not state) end)
                Row.MouseEnter:Connect(function() Tween(Lbl, { TextColor3 = Color3.new(1,1,1) }, 0.1) end)
                Row.MouseLeave:Connect(function() Tween(Lbl, { TextColor3 = T.TextPrimary }, 0.1) end)

                task.defer(RefreshSize)
                return { Set = SetState, OnChanged = function(s, cb) callback = cb return s end }
            end

            -- ── Button ───────────────────────────────────────────────────────
            function Gb:AddButton(text, callback)
                local Btn = Instance.new("TextButton")
                Btn.Size             = UDim2.new(1, 0, 0, 26)
                Btn.BackgroundColor3 = T.ControlBg; Btn.BorderSizePixel = 0
                Btn.Text             = text; Btn.TextColor3 = T.TextSecondary
                Btn.TextSize         = T.TextSize; Btn.Font = T.Font
                Btn.AutoButtonColor  = false; Btn.ZIndex = 4; Btn.Parent = Inner
                Corner(Btn, 4); Stroke(Btn, T.Border, 1)

                Btn.MouseEnter:Connect(function()    Tween(Btn, { BackgroundColor3 = T.ControlHov, TextColor3 = T.TextPrimary }, 0.1) end)
                Btn.MouseLeave:Connect(function()    Tween(Btn, { BackgroundColor3 = T.ControlBg,  TextColor3 = T.TextSecondary }, 0.1) end)
                Btn.MouseButton1Down:Connect(function() Tween(Btn, { BackgroundColor3 = T.AccentDim }, 0.07) end)
                Btn.MouseButton1Up:Connect(function()
                    Tween(Btn, { BackgroundColor3 = T.ControlHov }, 0.07)
                    if callback then callback() end
                end)
                task.defer(RefreshSize)
            end

            -- ── Slider ───────────────────────────────────────────────────────
            function Gb:AddSlider(text, opts, callback)
                opts = opts or {}
                local Min = opts.Min or 0; local Max = opts.Max or 100
                local Val = math.clamp(opts.Default or Min, Min, Max)
                local Fmt = opts.Format or "%d"

                local Wrap = Instance.new("Frame")
                Wrap.Size = UDim2.new(1, 0, 0, 36); Wrap.BackgroundTransparency = 1
                Wrap.ZIndex = 4; Wrap.Parent = Inner

                local TopRow = Instance.new("Frame")
                TopRow.Size = UDim2.new(1, 0, 0, 16); TopRow.BackgroundTransparency = 1; TopRow.Parent = Wrap

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(0.75, 0, 1, 0); Lbl.BackgroundTransparency = 1
                Lbl.Text = text; Lbl.TextColor3 = T.TextPrimary; Lbl.TextSize = T.TextSize
                Lbl.Font = T.FontLight; Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = TopRow

                local ValLbl = Instance.new("TextLabel")
                ValLbl.Size = UDim2.new(0.25, 0, 1, 0); ValLbl.Position = UDim2.new(0.75, 0, 0, 0)
                ValLbl.BackgroundTransparency = 1; ValLbl.Text = string.format(Fmt, Val)
                ValLbl.TextColor3 = T.Accent; ValLbl.TextSize = 12; ValLbl.Font = Enum.Font.GothamMedium
                ValLbl.TextXAlignment = Enum.TextXAlignment.Right; ValLbl.Parent = TopRow

                local Track = Instance.new("TextButton")
                Track.Size = UDim2.new(1, 0, 0, 8); Track.Position = UDim2.new(0, 0, 0, 22)
                Track.BackgroundColor3 = T.ControlBg; Track.BorderSizePixel = 0
                Track.Text = ""; Track.AutoButtonColor = false; Track.Parent = Wrap
                Corner(Track, 4); Stroke(Track, T.Border, 1)

                local Fill = Instance.new("Frame")
                Fill.Size = UDim2.new((Val-Min)/(Max-Min), 0, 1, 0)
                Fill.BackgroundColor3 = T.Accent; Fill.BorderSizePixel = 0; Fill.Parent = Track
                Corner(Fill, 4)

                local Thumb = Instance.new("Frame")
                Thumb.Size = UDim2.fromOffset(14, 14); Thumb.AnchorPoint = Vector2.new(0.5, 0.5)
                Thumb.Position = UDim2.new((Val-Min)/(Max-Min), 0, 0.5, 0)
                Thumb.BackgroundColor3 = Color3.new(1,1,1); Thumb.BorderSizePixel = 0; Thumb.ZIndex = 3; Thumb.Parent = Track
                Corner(Thumb, 7); Stroke(Thumb, T.AccentDim, 2)

                local dragging = false
                local function UpdateVal(i)
                    local pct = math.clamp((i.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    Val = math.floor(Min + (Max-Min)*pct + 0.5); pct = (Val-Min)/(Max-Min)
                    Fill.Size = UDim2.new(pct, 0, 1, 0); Thumb.Position = UDim2.new(pct, 0, 0.5, 0)
                    ValLbl.Text = string.format(Fmt, Val)
                    if callback then callback(Val) end
                end
                Track.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true; UpdateVal(i); Tween(Thumb, { Size = UDim2.fromOffset(16,16) }, 0.1)
                    end
                end)
                UserInputService.InputChanged:Connect(function(i)
                    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then UpdateVal(i) end
                end)
                UserInputService.InputEnded:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false; Tween(Thumb, { Size = UDim2.fromOffset(14,14) }, 0.1)
                    end
                end)
                task.defer(RefreshSize)
                return { OnChanged = function(s, cb) callback = cb return s end }
            end

            -- ── Dropdown ─────────────────────────────────────────────────────
            -- Panel is parented to Overlay (ScreenGui-level) and repositioned
            -- every time it opens using AbsolutePosition, so it is NEVER clipped.
            function Gb:AddDropdown(text, opts, callback)
                opts = opts or {}
                local Values   = opts.Values or {}
                local Selected = opts.Default or Values[1] or ""
                local Open     = false
                local ITEM_H   = 24
                local MAX_VIS  = 5

                -- Wrapper sits in the group layout (gives us a stable anchor)
                local Wrap = Instance.new("Frame")
                Wrap.Name                = text .. "_DDWrap"
                Wrap.Size                = UDim2.new(1, 0, 0, 42)
                Wrap.BackgroundTransparency = 1
                Wrap.ClipsDescendants    = false
                Wrap.ZIndex              = 4
                Wrap.Parent              = Inner

                local TopLbl = Instance.new("TextLabel")
                TopLbl.Size = UDim2.new(1, 0, 0, 16); TopLbl.BackgroundTransparency = 1
                TopLbl.Text = text; TopLbl.TextColor3 = T.TextSecondary; TopLbl.TextSize = 11
                TopLbl.Font = T.Font; TopLbl.TextXAlignment = Enum.TextXAlignment.Left; TopLbl.Parent = Wrap

                local SelBtn = Instance.new("TextButton")
                SelBtn.Size             = UDim2.new(1, 0, 0, 24)
                SelBtn.Position         = UDim2.new(0, 0, 0, 18)
                SelBtn.BackgroundColor3 = T.ControlBg; SelBtn.BorderSizePixel = 0
                SelBtn.Text             = ""; SelBtn.AutoButtonColor = false
                SelBtn.ZIndex           = 5; SelBtn.Parent = Wrap
                Corner(SelBtn, 4); local SelStroke = Stroke(SelBtn, T.Border, 1)

                local SelText = Instance.new("TextLabel")
                SelText.Size = UDim2.new(1, -28, 1, 0); SelText.Position = UDim2.new(0, 8, 0, 0)
                SelText.BackgroundTransparency = 1; SelText.Text = Selected
                SelText.TextColor3 = T.TextPrimary; SelText.TextSize = T.TextSize
                SelText.Font = T.FontLight; SelText.TextXAlignment = Enum.TextXAlignment.Left
                SelText.ZIndex = 6; SelText.Parent = SelBtn

                local Chevron = Instance.new("TextLabel")
                Chevron.Size = UDim2.fromOffset(20, 24); Chevron.Position = UDim2.new(1, -24, 0, 0)
                Chevron.BackgroundTransparency = 1; Chevron.Text = "▾"
                Chevron.TextColor3 = T.TextMuted; Chevron.TextSize = 14
                Chevron.Font = T.Font; Chevron.ZIndex = 6; Chevron.Parent = SelBtn

                -- The floating panel lives on the Overlay, not inside any scrollframe
                local listH = math.min(#Values, MAX_VIS) * ITEM_H + 6
                local Panel = Instance.new("ScrollingFrame")
                Panel.Name                       = text .. "_DDPanel"
                Panel.Size                       = UDim2.fromOffset(1, listH) -- width set on open
                Panel.BackgroundColor3           = T.SurfaceHigh
                Panel.BorderSizePixel            = 0
                Panel.Visible                    = false
                Panel.ZIndex                     = 600
                Panel.ScrollBarThickness         = 3
                Panel.ScrollBarImageColor3       = T.Accent
                Panel.ScrollBarImageTransparency = 0.4
                Panel.CanvasSize                 = UDim2.new(0, 0, 0, #Values * ITEM_H + 6)
                Panel.ClipsDescendants           = true
                Panel.Parent                     = Overlay  -- ← KEY FIX
                Corner(Panel, 5); Stroke(Panel, T.Border, 1)

                local PPad = Instance.new("UIPadding")
                PPad.PaddingTop = UDim.new(0,3); PPad.PaddingBottom = UDim.new(0,3)
                PPad.PaddingLeft = UDim.new(0,3); PPad.PaddingRight = UDim.new(0,3)
                PPad.Parent = Panel

                local PList = Instance.new("UIListLayout")
                PList.SortOrder = Enum.SortOrder.LayoutOrder; PList.Padding = UDim.new(0,2); PList.Parent = Panel

                local ItemButtons = {}
                for _, v in ipairs(Values) do
                    local isSel = (v == Selected)
                    local Item = Instance.new("TextButton")
                    Item.Size = UDim2.new(1, 0, 0, ITEM_H); Item.BackgroundColor3 = isSel and T.ControlHov or T.SurfaceHigh
                    Item.BorderSizePixel = 0; Item.Text = ""; Item.AutoButtonColor = false; Item.ZIndex = 601; Item.Parent = Panel
                    Corner(Item, 3)

                    local ItemTxt = Instance.new("TextLabel")
                    ItemTxt.Size = UDim2.new(1, -28, 1, 0); ItemTxt.Position = UDim2.new(0, 8, 0, 0)
                    ItemTxt.BackgroundTransparency = 1; ItemTxt.Text = v
                    ItemTxt.TextColor3 = isSel and T.TextPrimary or T.TextSecondary
                    ItemTxt.TextSize = T.TextSize; ItemTxt.Font = T.FontLight
                    ItemTxt.TextXAlignment = Enum.TextXAlignment.Left; ItemTxt.ZIndex = 602; ItemTxt.Parent = Item

                    local Chk = Instance.new("TextLabel")
                    Chk.Size = UDim2.fromOffset(20, ITEM_H); Chk.Position = UDim2.new(1, -22, 0, 0)
                    Chk.BackgroundTransparency = 1; Chk.Text = "✓"
                    Chk.TextColor3 = T.Accent; Chk.TextSize = 11; Chk.Font = T.Font
                    Chk.Visible = isSel; Chk.ZIndex = 602; Chk.Parent = Item

                    table.insert(ItemButtons, { btn = Item, lbl = ItemTxt, chk = Chk, val = v })

                    Item.MouseEnter:Connect(function()
                        if v ~= Selected then Tween(Item, { BackgroundColor3 = T.ControlBg }, 0.08) end
                    end)
                    Item.MouseLeave:Connect(function()
                        if v ~= Selected then Tween(Item, { BackgroundColor3 = T.SurfaceHigh }, 0.08) end
                    end)
                    Item.MouseButton1Click:Connect(function()
                        for _, ib in ipairs(ItemButtons) do
                            ib.btn.BackgroundColor3 = T.SurfaceHigh
                            ib.lbl.TextColor3 = T.TextSecondary; ib.chk.Visible = false
                        end
                        Selected = v; SelText.Text = v
                        Item.BackgroundColor3 = T.ControlHov
                        ItemTxt.TextColor3 = T.TextPrimary; Chk.Visible = true
                        Open = false; Panel.Visible = false
                        SelStroke.Color = T.Border
                        Tween(SelBtn, { BackgroundColor3 = T.ControlBg }, 0.1)
                        if callback then callback(Selected) end
                    end)
                end

                local function OpenPanel()
                    -- Calculate absolute position of SelBtn on screen
                    local abs = SelBtn.AbsolutePosition
                    local wid = SelBtn.AbsoluteSize.X
                    local screenH = ScreenGui.AbsoluteSize.Y

                    -- Decide: open downward or upward?
                    local spaceBelow = screenH - (abs.Y + SelBtn.AbsoluteSize.Y)
                    local openUp     = spaceBelow < listH + 10

                    Panel.Size = UDim2.fromOffset(wid, listH)
                    if openUp then
                        Panel.Position = UDim2.fromOffset(abs.X, abs.Y - listH - 4)
                    else
                        Panel.Position = UDim2.fromOffset(abs.X, abs.Y + SelBtn.AbsoluteSize.Y + 4)
                    end
                    Panel.Visible = true
                end

                local function CloseDD()
                    Open = false; Panel.Visible = false
                    SelStroke.Color = T.Border
                    Tween(SelBtn, { BackgroundColor3 = T.ControlBg }, 0.1)
                end

                SelBtn.MouseEnter:Connect(function()
                    if not Open then Tween(SelBtn, { BackgroundColor3 = T.ControlHov }, 0.1) end
                end)
                SelBtn.MouseLeave:Connect(function()
                    if not Open then Tween(SelBtn, { BackgroundColor3 = T.ControlBg }, 0.1) end
                end)
                SelBtn.MouseButton1Click:Connect(function()
                    Open = not Open
                    if Open then
                        SelStroke.Color = T.BorderFocus
                        Tween(SelBtn, { BackgroundColor3 = T.ControlHov }, 0.1)
                        OpenPanel()
                    else
                        CloseDD()
                    end
                end)

                RegisterCloser(Panel, SelBtn, CloseDD)

                task.defer(RefreshSize)
                return { OnChanged = function(s, cb) callback = cb return s end }
            end

            -- ── Label ─────────────────────────────────────────────────────────
            function Gb:AddLabel(text)
                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, 0, 0, 18); Lbl.BackgroundTransparency = 1
                Lbl.Text = text; Lbl.TextColor3 = T.TextSecondary
                Lbl.TextSize = T.TextSize; Lbl.Font = T.FontLight
                Lbl.TextXAlignment = Enum.TextXAlignment.Left
                Lbl.ZIndex = 4; Lbl.Parent = Inner
                task.defer(RefreshSize)
            end

            -- ── ColorPicker ──────────────────────────────────────────────────
            -- Same approach: panel lives on Overlay, positioned via AbsolutePosition
            function Gb:AddColorPicker(text, opts, callback)
                opts = opts or {}
                local Col  = opts.Default or Color3.new(1, 1, 1)
                local Open = false
                local r, g, b = Col.R, Col.G, Col.B

                local Wrap = Instance.new("Frame")
                Wrap.Size = UDim2.new(1, 0, 0, 22); Wrap.BackgroundTransparency = 1
                Wrap.ClipsDescendants = false; Wrap.ZIndex = 4; Wrap.Parent = Inner

                local Lbl = Instance.new("TextLabel")
                Lbl.Size = UDim2.new(1, -38, 1, 0); Lbl.BackgroundTransparency = 1
                Lbl.Text = text; Lbl.TextColor3 = T.TextPrimary
                Lbl.TextSize = T.TextSize; Lbl.Font = T.FontLight
                Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.ZIndex = 5; Lbl.Parent = Wrap

                local Swatch = Instance.new("TextButton")
                Swatch.Size = UDim2.fromOffset(30, 18); Swatch.Position = UDim2.new(1, -30, 0.5, -9)
                Swatch.BackgroundColor3 = Col; Swatch.BorderSizePixel = 0
                Swatch.Text = ""; Swatch.AutoButtonColor = false
                Swatch.ZIndex = 6; Swatch.Parent = Wrap
                Corner(Swatch, 4); local SwatchStroke = Stroke(Swatch, T.Border, 1)

                -- Panel on Overlay
                local PANEL_W, PANEL_H = 192, 94
                local Panel = Instance.new("Frame")
                Panel.Name             = text .. "_CPPanel"
                Panel.Size             = UDim2.fromOffset(PANEL_W, PANEL_H)
                Panel.BackgroundColor3 = T.SurfaceHigh
                Panel.BorderSizePixel  = 0; Panel.Visible = false
                Panel.ZIndex           = 600; Panel.Parent = Overlay
                Corner(Panel, 6); Stroke(Panel, T.Border, 1)

                local PPad = Instance.new("UIPadding")
                PPad.PaddingTop = UDim.new(0,8); PPad.PaddingBottom = UDim.new(0,8)
                PPad.PaddingLeft = UDim.new(0,10); PPad.PaddingRight = UDim.new(0,10); PPad.Parent = Panel

                local PList = Instance.new("UIListLayout")
                PList.SortOrder = Enum.SortOrder.LayoutOrder; PList.Padding = UDim.new(0,7); PList.Parent = Panel

                local function Rebuild()
                    Col = Color3.new(r, g, b); Swatch.BackgroundColor3 = Col
                    if callback then callback(Col) end
                end

                local chDefs = {
                    { id="R", getV=function() return r end, setV=function(v) r=v end, clr=Color3.fromRGB(220,80,80)  },
                    { id="G", getV=function() return g end, setV=function(v) g=v end, clr=Color3.fromRGB(80,200,100) },
                    { id="B", getV=function() return b end, setV=function(v) b=v end, clr=Color3.fromRGB(80,140,230) },
                }
                for _, ch in ipairs(chDefs) do
                    local Row = Instance.new("Frame")
                    Row.Size = UDim2.new(1, 0, 0, 16); Row.BackgroundTransparency = 1
                    Row.ZIndex = 601; Row.Parent = Panel

                    local ChLbl = Instance.new("TextLabel")
                    ChLbl.Size = UDim2.fromOffset(10, 16); ChLbl.BackgroundTransparency = 1
                    ChLbl.Text = ch.id; ChLbl.TextColor3 = ch.clr; ChLbl.TextSize = 11
                    ChLbl.Font = Enum.Font.GothamBold; ChLbl.ZIndex = 602; ChLbl.Parent = Row

                    local NumLbl = Instance.new("TextLabel")
                    NumLbl.Size = UDim2.fromOffset(26, 16); NumLbl.Position = UDim2.new(1, -26, 0, 0)
                    NumLbl.BackgroundTransparency = 1; NumLbl.Text = tostring(math.floor(ch.getV()*255))
                    NumLbl.TextColor3 = T.TextMuted; NumLbl.TextSize = 10; NumLbl.Font = T.Font
                    NumLbl.TextXAlignment = Enum.TextXAlignment.Right; NumLbl.ZIndex = 602; NumLbl.Parent = Row

                    local Bar = Instance.new("TextButton")
                    Bar.Size = UDim2.new(1, -44, 1, 0); Bar.Position = UDim2.new(0, 14, 0, 0)
                    Bar.BackgroundColor3 = T.ControlBg; Bar.BorderSizePixel = 0
                    Bar.Text = ""; Bar.AutoButtonColor = false; Bar.ZIndex = 602; Bar.Parent = Row
                    Corner(Bar, 3)

                    local Fill = Instance.new("Frame")
                    Fill.Size = UDim2.new(ch.getV(), 0, 1, 0); Fill.BackgroundColor3 = ch.clr
                    Fill.BorderSizePixel = 0; Fill.ZIndex = 603; Fill.Parent = Bar
                    Corner(Fill, 3)

                    local dragging = false
                    local function doUpdate(i)
                        local pct = math.clamp((i.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                        ch.setV(pct); Fill.Size = UDim2.new(pct, 0, 1, 0)
                        NumLbl.Text = tostring(math.floor(pct*255)); Rebuild()
                    end
                    Bar.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; doUpdate(i) end
                    end)
                    UserInputService.InputChanged:Connect(function(i)
                        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then doUpdate(i) end
                    end)
                    UserInputService.InputEnded:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                    end)
                end

                local function OpenPanel()
                    local abs      = Swatch.AbsolutePosition
                    local screenH  = ScreenGui.AbsoluteSize.Y
                    local openUp   = (screenH - (abs.Y + Swatch.AbsoluteSize.Y)) < PANEL_H + 10
                    if openUp then
                        Panel.Position = UDim2.fromOffset(abs.X - PANEL_W + Swatch.AbsoluteSize.X, abs.Y - PANEL_H - 4)
                    else
                        Panel.Position = UDim2.fromOffset(abs.X - PANEL_W + Swatch.AbsoluteSize.X, abs.Y + Swatch.AbsoluteSize.Y + 4)
                    end
                    Panel.Visible = true
                end

                local function CloseCP()
                    Open = false; Panel.Visible = false
                    SwatchStroke.Color = T.Border
                end

                Swatch.MouseButton1Click:Connect(function()
                    Open = not Open
                    SwatchStroke.Color = Open and T.BorderFocus or T.Border
                    if Open then OpenPanel() else CloseCP() end
                end)

                RegisterCloser(Panel, Swatch, CloseCP)

                task.defer(RefreshSize)
                return { OnChanged = function(s, cb) callback = cb return s end }
            end

            task.defer(RefreshSize)
            return Gb
        end

        return Tab
    end

    return Window
end

return Library
