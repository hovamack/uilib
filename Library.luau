local UIS = game:GetService'UserInputService'
local RS  = game:GetService'RunService'
local TS  = game:GetService'TweenService'
local Players = game:GetService'Players'
local lp = Players.LocalPlayer

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

local Lib = { Theme = T, Windows = {} }

local overlayClosers = {}

local function regCloser(panel, btn, onClose)
	table.insert(overlayClosers, { panel = panel, selBtn = btn, onClose = onClose })
end

local function closeOthers(exempt)
	for _, e in ipairs(overlayClosers) do
		if e.panel ~= exempt and e.panel.Visible then
			e.onClose()
		end
	end
end

UIS.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
	for _, e in ipairs(overlayClosers) do
		if e.panel.Visible then
			local function inside(f)
				local p, s, m = f.AbsolutePosition, f.AbsoluteSize, input.Position
				return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
			end
			if not inside(e.panel) and not inside(e.selBtn) then
				task.spawn(function()
					task.wait(0.05)
					e.onClose()
				end)
			end
		end
	end
end)

-- helpers

local function tween(obj, props, t)
	TS:Create(obj, TweenInfo.new(t or 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
end

local function tweenFade(gui, alpha, dur)
	local ti = TweenInfo.new(dur or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function go(obj)
		if obj:IsA'Frame' or obj:IsA'TextButton' or obj:IsA'ScrollingFrame' then
			local orig = obj:GetAttribute'OrigBgTrans'
			if not orig then
				orig = obj.BackgroundTransparency
				obj:SetAttribute('OrigBgTrans', orig)
			end
			TS:Create(obj, ti, { BackgroundTransparency = alpha == 1 and 1 or orig }):Play()
		end
		if obj:IsA'TextLabel' or obj:IsA'TextButton' then
			local orig = obj:GetAttribute'OrigTxtTrans'
			if not orig then
				orig = obj.TextTransparency
				obj:SetAttribute('OrigTxtTrans', orig)
			end
			TS:Create(obj, ti, { TextTransparency = alpha == 1 and 1 or orig }):Play()
		end
		if obj:IsA'UIStroke' then
			local orig = obj:GetAttribute'OrigStrTrans'
			if not orig then
				orig = obj.Transparency
				obj:SetAttribute('OrigStrTrans', orig)
			end
			TS:Create(obj, ti, { Transparency = alpha == 1 and 1 or orig }):Play()
		end
		if obj:IsA'ScrollingFrame' then
			local orig = obj:GetAttribute'OrigScrollTrans'
			if not orig then
				orig = obj.ScrollBarImageTransparency
				obj:SetAttribute('OrigScrollTrans', orig)
			end
			TS:Create(obj, ti, { ScrollBarImageTransparency = alpha == 1 and 1 or orig }):Play()
		end
	end

	go(gui)
	for _, c in ipairs(gui:GetDescendants()) do go(c) end
end

local function corner(p, r)
	local c = Instance.new'UICorner'
	c.CornerRadius = UDim.new(0, r or 4)
	c.Parent = p
	return c
end

local function stroke(p, col, thick)
	local s = Instance.new'UIStroke'
	s.Color = col or T.Border
	s.Thickness = thick or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function makeDraggable(frame, handle)
	local dragging, dragInput, dragStart, startPos
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = i.Position
			startPos = frame.Position
			i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	handle.InputChanged:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseMovement then dragInput = i end
	end)
	UIS.InputChanged:Connect(function(i)
		if i == dragInput and dragging then
			local d = i.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + d.X,
				startPos.Y.Scale, startPos.Y.Offset + d.Y
			)
		end
	end)
end

-- window

function Lib:CreateWindow(opts)
	opts = opts or {}
	local title = opts.Title or "Window"
	local size  = opts.Size  or UDim2.fromOffset(520, 420)

	local gui = Instance.new'ScreenGui'
	gui.Name           = "IMGuiLib"
	gui.ResetOnSpawn   = false
	gui.DisplayOrder   = 100
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
	gui.Parent = RS:IsStudio()
		and lp:WaitForChild'PlayerGui'
		or game:GetService'CoreGui'

	local overlay = Instance.new'Frame'
	overlay.Name                   = "Overlay"
	overlay.Size                   = UDim2.new(1,0,1,0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel        = 0
	overlay.ZIndex                 = 500
	overlay.Parent                 = gui

	local main = Instance.new'Frame'
	main.Name             = "Main"
	main.Size             = size
	main.Position         = UDim2.new(0.5, -size.X.Offset/2, 0.5, -size.Y.Offset/2)
	main.BackgroundColor3 = T.Background
	main.BorderSizePixel  = 0
	main.ClipsDescendants = false
	main.ZIndex           = 1
	main.Parent           = gui
	corner(main, 6); stroke(main, T.Border, 1)

	-- titlebar
	local titleBar = Instance.new'Frame'
	titleBar.Size             = UDim2.new(1,0,0,32)
	titleBar.BackgroundColor3 = T.TitleBar
	titleBar.BorderSizePixel  = 0
	titleBar.ZIndex           = 2
	titleBar.Parent           = main
	corner(titleBar, 0)

	local titleBarTop = Instance.new'Frame'
	titleBarTop.Size             = UDim2.new(1,0,0,10)
	titleBarTop.BackgroundColor3 = T.TitleBar
	titleBarTop.BorderSizePixel  = 0
	titleBarTop.ZIndex           = 2
	titleBarTop.Parent           = main

	local accentLine = Instance.new'Frame'
	accentLine.Size                   = UDim2.new(1,0,0,1)
	accentLine.Position               = UDim2.new(0,0,1,-1)
	accentLine.BackgroundColor3       = T.Accent
	accentLine.BackgroundTransparency = 0.5
	accentLine.BorderSizePixel        = 0
	accentLine.ZIndex                 = 3
	accentLine.Parent                 = titleBar

	for i, col in ipairs({ Color3.fromRGB(255,95,87), Color3.fromRGB(255,189,46), Color3.fromRGB(40,200,64) }) do
		local dot = Instance.new'Frame'
		dot.Size             = UDim2.fromOffset(10,10)
		dot.Position         = UDim2.new(0, 8 + (i-1)*16, 0.5, -5)
		dot.BackgroundColor3 = col
		dot.BorderSizePixel  = 0
		dot.ZIndex           = 3
		dot.Parent           = titleBar
		corner(dot, 5)
	end

	local titleLbl = Instance.new'TextLabel'
	titleLbl.Size                   = UDim2.new(1,0,1,0)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                   = title
	titleLbl.TextColor3             = T.TextPrimary
	titleLbl.TextSize               = 13
	titleLbl.Font                   = Enum.Font.GothamBold
	titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
	titleLbl.ZIndex                 = 3
	titleLbl.Parent                 = titleBar
	makeDraggable(main, titleBar)

	local fading, visible = false, true
	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode ~= Enum.KeyCode.F8 then return end
		if fading then return end
		fading = true
		if visible then
			closeOthers(nil)
			tweenFade(main, 1, 0.2)
			task.delay(0.2, function()
				main.Visible = false
				visible = false
				fading = false
			end)
		else
			main.Visible = true
			tweenFade(main, 0, 0.2)
			task.delay(0.2, function()
				visible = true
				fading = false
			end)
		end
	end)

	-- tab bar
	local TAB_H = 28
	local tabBar = Instance.new'Frame'
	tabBar.Name             = "TabBar"
	tabBar.Size             = UDim2.new(1,0,0,TAB_H)
	tabBar.Position         = UDim2.new(0,0,0,32)
	tabBar.BackgroundColor3 = T.TabBar
	tabBar.BorderSizePixel  = 0
	tabBar.ClipsDescendants = false
	tabBar.ZIndex           = 2
	tabBar.Parent           = main

	local tabSep = Instance.new'Frame'
	tabSep.Size             = UDim2.new(1,0,0,1)
	tabSep.Position         = UDim2.new(0,0,1,-1)
	tabSep.BackgroundColor3 = T.Border
	tabSep.BorderSizePixel  = 0
	tabSep.ZIndex           = 3
	tabSep.Parent           = tabBar

	local tabX = 6

	local HEADER_H = 32 + TAB_H
	local contentArea = Instance.new'Frame'
	contentArea.Name                   = "ContentArea"
	contentArea.Size                   = UDim2.new(1,0,1,-HEADER_H)
	contentArea.Position               = UDim2.new(0,0,0,HEADER_H)
	contentArea.BackgroundTransparency = 1
	contentArea.BorderSizePixel        = 0
	contentArea.ZIndex                 = 1
	contentArea.Parent                 = main

	local win = { Tabs = {} }

	function win:AddTab(name)
		local TAB_W     = math.max(70, #name * 8 + 20)
		local TAB_INNER = TAB_H - 8

		local tabBtn = Instance.new'TextButton'
		tabBtn.Name             = name.."_TabBtn"
		tabBtn.Size             = UDim2.fromOffset(TAB_W, TAB_INNER)
		tabBtn.Position         = UDim2.new(0, tabX, 0, 4)
		tabBtn.BackgroundColor3 = T.TabBar
		tabBtn.BorderSizePixel  = 0
		tabBtn.Text             = name
		tabBtn.TextColor3       = T.TextMuted
		tabBtn.TextSize         = 12
		tabBtn.Font             = Enum.Font.GothamMedium
		tabBtn.AutoButtonColor  = false
		tabBtn.ZIndex           = 3
		tabBtn.Parent           = tabBar
		corner(tabBtn, 3)

		tabX = tabX + TAB_W + 2

		local tabInd = Instance.new'Frame'
		tabInd.Size             = UDim2.new(0.6,0,0,2)
		tabInd.Position         = UDim2.new(0.2,0,1,0)
		tabInd.BackgroundColor3 = T.Accent
		tabInd.BorderSizePixel  = 0
		tabInd.Visible          = false
		tabInd.ZIndex           = 4
		tabInd.Parent           = tabBtn
		corner(tabInd, 1)

		local scroll = Instance.new'ScrollingFrame'
		scroll.Name                       = name.."_Scroll"
		scroll.Size                       = UDim2.new(1,0,1,0)
		scroll.BackgroundTransparency     = 1
		scroll.BorderSizePixel            = 0
		scroll.Visible                    = false
		scroll.ScrollBarThickness         = 3
		scroll.ScrollBarImageColor3       = T.Accent
		scroll.ScrollBarImageTransparency = 0.4
		scroll.CanvasSize                 = UDim2.new(0,0,0,0)
		scroll.ClipsDescendants           = true
		scroll.ZIndex                     = 2
		scroll.Parent                     = contentArea

		local sp = Instance.new'UIPadding'
		sp.PaddingTop    = UDim.new(0,10)
		sp.PaddingBottom = UDim.new(0,10)
		sp.PaddingLeft   = UDim.new(0,10)
		sp.PaddingRight  = UDim.new(0,13)
		sp.Parent        = scroll

		local sl = Instance.new'UIListLayout'
		sl.SortOrder = Enum.SortOrder.LayoutOrder
		sl.Padding   = UDim.new(0,8)
		sl.Parent    = scroll

		sl:GetPropertyChangedSignal'AbsoluteContentSize':Connect(function()
			scroll.CanvasSize = UDim2.new(0,0,0, sl.AbsoluteContentSize.Y + 20)
		end)

		local tab = { Button = tabBtn, Content = scroll, Indicator = tabInd }

		local function selectTab()
			for _, t in pairs(win.Tabs) do
				t.Content.Visible = false
				tween(t.Button, { TextColor3 = T.TextMuted, BackgroundColor3 = T.TabBar }, 0.1)
				t.Indicator.Visible = false
			end
			scroll.Visible  = true
			tabInd.Visible  = true
			tween(tabBtn, { TextColor3 = T.TextPrimary, BackgroundColor3 = T.TabActive }, 0.1)
		end

		tabBtn.MouseButton1Click:Connect(selectTab)
		tabBtn.MouseEnter:Connect(function()
			if not scroll.Visible then tween(tabBtn, { TextColor3 = T.TextSecondary }, 0.1) end
		end)
		tabBtn.MouseLeave:Connect(function()
			if not scroll.Visible then tween(tabBtn, { TextColor3 = T.TextMuted }, 0.1) end
		end)

		table.insert(win.Tabs, tab)
		if #win.Tabs == 1 then selectTab() end

		function tab:AddGroupbox(title)
			local gf = Instance.new'Frame'
			gf.Name             = title.."_Group"
			gf.Size             = UDim2.new(1,0,0,20)
			gf.BackgroundColor3 = T.Surface
			gf.BorderSizePixel  = 0
			gf.ClipsDescendants = false
			gf.ZIndex           = 3
			gf.Parent           = scroll
			corner(gf, 5); stroke(gf, T.Border, 1)

			local pill = Instance.new'Frame'
			pill.Size             = UDim2.new(0,10,0,18)
			pill.Position         = UDim2.new(0,10,0,-9)
			pill.BackgroundColor3 = T.Surface
			pill.BorderSizePixel  = 0
			pill.AutomaticSize    = Enum.AutomaticSize.X
			pill.ZIndex           = 5
			pill.Parent           = gf

			local pillTxt = Instance.new'TextLabel'
			pillTxt.Size                   = UDim2.new(1,0,1,0)
			pillTxt.BackgroundTransparency = 1
			pillTxt.Text                   = title
			pillTxt.TextColor3             = T.Accent
			pillTxt.TextSize               = 11
			pillTxt.Font                   = Enum.Font.GothamBold
			pillTxt.AutomaticSize          = Enum.AutomaticSize.X
			pillTxt.ZIndex                 = 6
			pillTxt.Parent                 = pill
			local pp = Instance.new'UIPadding'
			pp.PaddingLeft = UDim.new(0,5); pp.PaddingRight = UDim.new(0,5); pp.Parent = pill

			local inner = Instance.new'Frame'
			inner.Size                   = UDim2.new(1,0,1,0)
			inner.BackgroundTransparency = 1
			inner.ZIndex                 = 3
			inner.Parent                 = gf

			local il = Instance.new'UIListLayout'
			il.SortOrder = Enum.SortOrder.LayoutOrder
			il.Padding   = UDim.new(0,5)
			il.Parent    = inner

			local ip = Instance.new'UIPadding'
			ip.PaddingTop    = UDim.new(0,16)
			ip.PaddingBottom = UDim.new(0,10)
			ip.PaddingLeft   = UDim.new(0,8)
			ip.PaddingRight  = UDim.new(0,8)
			ip.Parent        = inner

			local function resize()
				local h = il.AbsoluteContentSize.Y + 26
				gf.Size    = UDim2.new(1,0,0,h)
				inner.Size = UDim2.new(1,0,0,h)
			end
			il:GetPropertyChangedSignal'AbsoluteContentSize':Connect(resize)

			local gb = {}

			-- toggle
			function gb:AddToggle(text, opts2, callback)
				opts2 = opts2 or {}
				local state = opts2.Default or false

				local row = Instance.new'TextButton'
				row.Size                   = UDim2.new(1,0,0,22)
				row.BackgroundTransparency = 1
				row.Text                   = ""
				row.AutoButtonColor        = false
				row.ZIndex                 = 4
				row.Parent                 = inner

				local track = Instance.new'Frame'
				track.Size             = UDim2.fromOffset(32,16)
				track.Position         = UDim2.new(1,-32,0.5,-8)
				track.BackgroundColor3 = state and T.Accent or T.ControlBg
				track.BorderSizePixel  = 0
				track.ZIndex           = 5
				track.Parent           = row
				corner(track, 8); stroke(track, T.Border, 1)

				local knob = Instance.new'Frame'
				knob.Size             = UDim2.fromOffset(12,12)
				knob.Position         = state and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)
				knob.BackgroundColor3 = Color3.new(1,1,1)
				knob.BorderSizePixel  = 0
				knob.ZIndex           = 6
				knob.Parent           = track
				corner(knob, 6)

				local lbl = Instance.new'TextLabel'
				lbl.Size                   = UDim2.new(1,-44,1,0)
				lbl.BackgroundTransparency = 1
				lbl.Text                   = text
				lbl.TextColor3             = T.TextPrimary
				lbl.TextSize               = T.TextSize
				lbl.Font                   = T.FontLight
				lbl.TextXAlignment         = Enum.TextXAlignment.Left
				lbl.ZIndex                 = 4
				lbl.Parent                 = row

				local function set(v)
					state = v
					tween(track, { BackgroundColor3 = v and T.Accent or T.ControlBg }, 0.15)
					tween(knob,  { Position = v and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6) }, 0.15)
					if callback then callback(state) end
				end
				row.MouseButton1Click:Connect(function() set(not state) end)
				row.MouseEnter:Connect(function() tween(lbl, { TextColor3 = Color3.new(1,1,1) }, 0.1) end)
				row.MouseLeave:Connect(function() tween(lbl, { TextColor3 = T.TextPrimary }, 0.1) end)

				task.defer(resize)
				return { Set = set, OnChanged = function(s, cb) callback = cb return s end }
			end

			-- button
			function gb:AddButton(text, callback)
				local btn = Instance.new'TextButton'
				btn.Size             = UDim2.new(1,0,0,26)
				btn.BackgroundColor3 = T.ControlBg
				btn.BorderSizePixel  = 0
				btn.Text             = text
				btn.TextColor3       = T.TextSecondary
				btn.TextSize         = T.TextSize
				btn.Font             = T.Font
				btn.AutoButtonColor  = false
				btn.ZIndex           = 4
				btn.Parent           = inner
				corner(btn, 4); stroke(btn, T.Border, 1)

				btn.MouseEnter:Connect(function()    tween(btn, { BackgroundColor3 = T.ControlHov, TextColor3 = T.TextPrimary },   0.1) end)
				btn.MouseLeave:Connect(function()    tween(btn, { BackgroundColor3 = T.ControlBg,  TextColor3 = T.TextSecondary }, 0.1) end)
				btn.MouseButton1Down:Connect(function() tween(btn, { BackgroundColor3 = T.AccentDim }, 0.07) end)
				btn.MouseButton1Up:Connect(function()
					tween(btn, { BackgroundColor3 = T.ControlHov }, 0.07)
					if callback then callback() end
				end)
				task.defer(resize)
			end

			-- slider
			function gb:AddSlider(text, opts2, callback)
				opts2 = opts2 or {}
				local min = opts2.Min or 0
				local max = opts2.Max or 100
				local val = math.clamp(opts2.Default or min, min, max)
				local fmt = opts2.Format or "%d"

				local wrap = Instance.new'Frame'
				wrap.Size                   = UDim2.new(1,0,0,36)
				wrap.BackgroundTransparency = 1
				wrap.ZIndex                 = 4
				wrap.Parent                 = inner

				local topRow = Instance.new'Frame'
				topRow.Size                   = UDim2.new(1,0,0,16)
				topRow.BackgroundTransparency = 1
				topRow.ZIndex                 = 4
				topRow.Parent                 = wrap

				local lbl = Instance.new'TextLabel'
				lbl.Size               = UDim2.new(0.75,0,1,0)
				lbl.BackgroundTransparency = 1
				lbl.Text               = text
				lbl.TextColor3         = T.TextPrimary
				lbl.TextSize           = T.TextSize
				lbl.ZIndex             = 4
				lbl.Font               = T.FontLight
				lbl.TextXAlignment     = Enum.TextXAlignment.Left
				lbl.Parent             = topRow

				local valLbl = Instance.new'TextLabel'
				valLbl.Size               = UDim2.new(0.25,0,1,0)
				valLbl.Position           = UDim2.new(0.75,0,0,0)
				valLbl.BackgroundTransparency = 1
				valLbl.Text               = string.format(fmt, val)
				valLbl.TextColor3         = T.Accent
				valLbl.TextSize           = 12
				valLbl.Font               = Enum.Font.GothamMedium
				valLbl.ZIndex             = 4
				valLbl.TextXAlignment     = Enum.TextXAlignment.Right
				valLbl.Parent             = topRow

				local track = Instance.new'TextButton'
				track.Size             = UDim2.new(1,0,0,8)
				track.Position         = UDim2.new(0,0,0,22)
				track.BackgroundColor3 = T.ControlBg
				track.BorderSizePixel  = 0
				track.ZIndex           = 4
				track.Text             = ""
				track.AutoButtonColor  = false
				track.Parent           = wrap
				corner(track, 4); stroke(track, T.Border, 1)

				local fill = Instance.new'Frame'
				fill.Size             = UDim2.new((val-min)/(max-min), 0, 1, 0)
				fill.BackgroundColor3 = T.Accent
				fill.BorderSizePixel  = 0
				fill.ZIndex           = 4
				fill.Parent           = track
				corner(fill, 4)

				local thumb = Instance.new'Frame'
				thumb.Size             = UDim2.fromOffset(14,14)
				thumb.AnchorPoint      = Vector2.new(0.5, 0.5)
				thumb.Position         = UDim2.new((val-min)/(max-min), 0, 0.5, 0)
				thumb.BackgroundColor3 = Color3.new(1,1,1)
				thumb.BorderSizePixel  = 0
				thumb.ZIndex           = 5
				thumb.Parent           = track
				corner(thumb, 7); stroke(thumb, T.AccentDim, 2)

				local dragging = false
				local function update(i)
					local pct = math.clamp((i.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
					val = math.floor(min + (max-min)*pct + 0.5)
					pct = (val-min)/(max-min)
					fill.Size = UDim2.new(pct, 0, 1, 0)
					thumb.Position = UDim2.new(pct, 0, 0.5, 0)
					valLbl.Text = string.format(fmt, val)
					if callback then callback(val) end
				end
				track.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = true; update(i)
						tween(thumb, { Size = UDim2.fromOffset(16,16) }, 0.1)
					end
				end)
				UIS.InputChanged:Connect(function(i)
					if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end
				end)
				UIS.InputEnded:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 then
						dragging = false
						tween(thumb, { Size = UDim2.fromOffset(14,14) }, 0.1)
					end
				end)
				task.defer(resize)
				return { OnChanged = function(s, cb) callback = cb return s end }
			end

			-- dropdown
			function gb:AddDropdown(text, opts2, callback)
				opts2 = opts2 or {}
				local values   = opts2.Values or {}
				local selected = opts2.Default or values[1] or ""
				local open     = false
				local ITEM_H   = 24
				local MAX_VIS  = 5

				local wrap = Instance.new'Frame'
				wrap.Name                = text.."_DDWrap"
				wrap.Size                = UDim2.new(1,0,0,42)
				wrap.BackgroundTransparency = 1
				wrap.ClipsDescendants    = false
				wrap.ZIndex              = 4
				wrap.Parent              = inner

				local topLbl = Instance.new'TextLabel'
				topLbl.Size                   = UDim2.new(1,0,0,16)
				topLbl.BackgroundTransparency = 1
				topLbl.Text                   = text
				topLbl.TextColor3             = T.TextSecondary
				topLbl.TextSize               = 11
				topLbl.Font                   = T.Font
				topLbl.TextXAlignment         = Enum.TextXAlignment.Left
				topLbl.Parent                 = wrap

				local selBtn = Instance.new'TextButton'
				selBtn.Size             = UDim2.new(1,0,0,24)
				selBtn.Position         = UDim2.new(0,0,0,18)
				selBtn.BackgroundColor3 = T.ControlBg
				selBtn.BorderSizePixel  = 0
				selBtn.Text             = ""
				selBtn.AutoButtonColor  = false
				selBtn.ZIndex           = 5
				selBtn.Parent           = wrap
				corner(selBtn, 4)
				local selStroke = stroke(selBtn, T.Border, 1)

				local selText = Instance.new'TextLabel'
				selText.Size                   = UDim2.new(1,-28,1,0)
				selText.Position               = UDim2.new(0,8,0,0)
				selText.BackgroundTransparency = 1
				selText.Text                   = selected
				selText.TextColor3             = T.TextPrimary
				selText.TextSize               = T.TextSize
				selText.Font                   = T.FontLight
				selText.TextXAlignment         = Enum.TextXAlignment.Left
				selText.ZIndex                 = 6
				selText.Parent                 = selBtn

				local chevron = Instance.new'TextLabel'
				chevron.Size                   = UDim2.fromOffset(20,24)
				chevron.Position               = UDim2.new(1,-24,0,0)
				chevron.BackgroundTransparency = 1
				chevron.Text                   = "▾"
				chevron.TextColor3             = T.TextMuted
				chevron.TextSize               = 14
				chevron.Font                   = T.Font
				chevron.ZIndex                 = 6
				chevron.Parent                 = selBtn

				local listH = math.min(#values, MAX_VIS) * ITEM_H + 6
				local panel = Instance.new'ScrollingFrame'
				panel.Name                       = text.."_DDPanel"
				panel.Size                       = UDim2.fromOffset(1, listH)
				panel.BackgroundColor3           = T.SurfaceHigh
				panel.BorderSizePixel            = 0
				panel.Visible                    = false
				panel.ZIndex                     = 600
				panel.ScrollBarThickness         = 3
				panel.ScrollBarImageColor3       = T.Accent
				panel.ScrollBarImageTransparency = 0.4
				panel.CanvasSize                 = UDim2.new(0,0,0, #values * ITEM_H + 6)
				panel.ClipsDescendants           = true
				panel.Parent                     = overlay
				corner(panel, 5); stroke(panel, T.Border, 1)

				local pp = Instance.new'UIPadding'
				pp.PaddingTop = UDim.new(0,3); pp.PaddingBottom = UDim.new(0,3)
				pp.PaddingLeft = UDim.new(0,3); pp.PaddingRight = UDim.new(0,3)
				pp.Parent = panel

				local pl = Instance.new'UIListLayout'
				pl.SortOrder = Enum.SortOrder.LayoutOrder
				pl.Padding   = UDim.new(0,2)
				pl.Parent    = panel

				local items = {}
				for _, v in ipairs(values) do
					local isSel = v == selected
					local item = Instance.new'TextButton'
					item.Size             = UDim2.new(1,0,0,ITEM_H)
					item.BackgroundColor3 = isSel and T.ControlHov or T.SurfaceHigh
					item.BorderSizePixel  = 0
					item.Text             = ""
					item.AutoButtonColor  = false
					item.ZIndex           = 601
					item.Parent           = panel
					corner(item, 3)

					local itemTxt = Instance.new'TextLabel'
					itemTxt.Size                   = UDim2.new(1,-28,1,0)
					itemTxt.Position               = UDim2.new(0,8,0,0)
					itemTxt.BackgroundTransparency = 1
					itemTxt.Text                   = v
					itemTxt.TextColor3             = isSel and T.TextPrimary or T.TextSecondary
					itemTxt.TextSize               = T.TextSize
					itemTxt.Font                   = T.FontLight
					itemTxt.TextXAlignment         = Enum.TextXAlignment.Left
					itemTxt.ZIndex                 = 602
					itemTxt.Parent                 = item

					local chk = Instance.new'TextLabel'
					chk.Size                   = UDim2.fromOffset(20, ITEM_H)
					chk.Position               = UDim2.new(1,-22,0,0)
					chk.BackgroundTransparency = 1
					chk.Text                   = "✓"
					chk.TextColor3             = T.Accent
					chk.TextSize               = 11
					chk.Font                   = T.Font
					chk.Visible                = isSel
					chk.ZIndex                 = 602
					chk.Parent                 = item

					table.insert(items, { btn = item, lbl = itemTxt, chk = chk, val = v })

					item.MouseEnter:Connect(function()
						if v ~= selected then tween(item, { BackgroundColor3 = T.ControlBg }, 0.08) end
					end)
					item.MouseLeave:Connect(function()
						if v ~= selected then tween(item, { BackgroundColor3 = T.SurfaceHigh }, 0.08) end
					end)
					item.MouseButton1Click:Connect(function()
						for _, ib in ipairs(items) do
							ib.btn.BackgroundColor3 = T.SurfaceHigh
							ib.lbl.TextColor3 = T.TextSecondary
							ib.chk.Visible = false
						end
						selected = v
						selText.Text = v
						item.BackgroundColor3 = T.ControlHov
						itemTxt.TextColor3 = T.TextPrimary
						chk.Visible = true
						open = false; panel.Visible = false
						selStroke.Color = T.Border
						tween(selBtn, { BackgroundColor3 = T.ControlBg }, 0.1)
						if callback then callback(selected) end
					end)
				end

				local function openPanel()
					local abs    = selBtn.AbsolutePosition
					local wid    = selBtn.AbsoluteSize.X
					local scrH   = gui.AbsoluteSize.Y
					local openUp = (scrH - (abs.Y + selBtn.AbsoluteSize.Y)) < listH + 10
					panel.Size = UDim2.fromOffset(wid, listH)
					if openUp then
						panel.Position = UDim2.fromOffset(abs.X, abs.Y - listH - 4)
					else
						panel.Position = UDim2.fromOffset(abs.X, abs.Y + selBtn.AbsoluteSize.Y + 4)
					end
					panel.Visible = true
				end

				local function closeDD()
					open = false; panel.Visible = false
					selStroke.Color = T.Border
					tween(selBtn, { BackgroundColor3 = T.ControlBg }, 0.1)
				end

				selBtn.MouseEnter:Connect(function()
					if not open then tween(selBtn, { BackgroundColor3 = T.ControlHov }, 0.1) end
				end)
				selBtn.MouseLeave:Connect(function()
					if not open then tween(selBtn, { BackgroundColor3 = T.ControlBg }, 0.1) end
				end)
				selBtn.MouseButton1Click:Connect(function()
					open = not open
					if open then
						closeOthers(panel)
						selStroke.Color = T.BorderFocus
						tween(selBtn, { BackgroundColor3 = T.ControlHov }, 0.1)
						openPanel()
					else
						closeDD()
					end
				end)

				regCloser(panel, selBtn, closeDD)
				task.defer(resize)
				return { OnChanged = function(s, cb) callback = cb return s end }
			end

			-- label
			function gb:AddLabel(text)
				local lbl = Instance.new'TextLabel'
				lbl.Size               = UDim2.new(1,0,0,18)
				lbl.BackgroundTransparency = 1
				lbl.Text               = text
				lbl.TextColor3         = T.TextSecondary
				lbl.TextSize           = T.TextSize
				lbl.Font               = T.FontLight
				lbl.TextXAlignment     = Enum.TextXAlignment.Left
				lbl.ZIndex             = 4
				lbl.Parent             = inner
				task.defer(resize)
			end

			-- colorpicker
			function gb:AddColorPicker(text, opts2, callback)
				opts2 = opts2 or {}
				local col  = opts2.Default or Color3.new(1,1,1)
				local open = false
				local r, g, b = col.R, col.G, col.B

				local wrap = Instance.new'Frame'
				wrap.Size               = UDim2.new(1,0,0,22)
				wrap.BackgroundTransparency = 1
				wrap.ClipsDescendants   = false
				wrap.ZIndex             = 4
				wrap.Parent             = inner

				local lbl = Instance.new'TextLabel'
				lbl.Size               = UDim2.new(1,-38,1,0)
				lbl.BackgroundTransparency = 1
				lbl.Text               = text
				lbl.TextColor3         = T.TextPrimary
				lbl.TextSize           = T.TextSize
				lbl.Font               = T.FontLight
				lbl.TextXAlignment     = Enum.TextXAlignment.Left
				lbl.ZIndex             = 5
				lbl.Parent             = wrap

				local swatch = Instance.new'TextButton'
				swatch.Size             = UDim2.fromOffset(30,18)
				swatch.Position         = UDim2.new(1,-30,0.5,-9)
				swatch.BackgroundColor3 = col
				swatch.BorderSizePixel  = 0
				swatch.Text             = ""
				swatch.AutoButtonColor  = false
				swatch.ZIndex           = 6
				swatch.Parent           = wrap
				corner(swatch, 4)
				local swStroke = stroke(swatch, T.Border, 1)

				local PW, PH = 192, 94
				local panel = Instance.new'Frame'
				panel.Name             = text.."_CPPanel"
				panel.Size             = UDim2.fromOffset(PW, PH)
				panel.BackgroundColor3 = T.SurfaceHigh
				panel.BorderSizePixel  = 0
				panel.Visible          = false
				panel.ZIndex           = 600
				panel.Parent           = overlay
				corner(panel, 6); stroke(panel, T.Border, 1)

				local pp = Instance.new'UIPadding'
				pp.PaddingTop = UDim.new(0,8); pp.PaddingBottom = UDim.new(0,8)
				pp.PaddingLeft = UDim.new(0,10); pp.PaddingRight = UDim.new(0,10)
				pp.Parent = panel

				local pl = Instance.new'UIListLayout'
				pl.SortOrder = Enum.SortOrder.LayoutOrder
				pl.Padding   = UDim.new(0,7)
				pl.Parent    = panel

				local function rebuild()
					col = Color3.new(r, g, b)
					swatch.BackgroundColor3 = col
					if callback then callback(col) end
				end

				local channels = {
					{ id="R", get=function() return r end, set=function(v) r=v end, clr=Color3.fromRGB(220,80,80)  },
					{ id="G", get=function() return g end, set=function(v) g=v end, clr=Color3.fromRGB(80,200,100) },
					{ id="B", get=function() return b end, set=function(v) b=v end, clr=Color3.fromRGB(80,140,230) },
				}
				for _, ch in ipairs(channels) do
					local row = Instance.new'Frame'
					row.Size                   = UDim2.new(1,0,0,16)
					row.BackgroundTransparency = 1
					row.ZIndex                 = 601
					row.Parent                 = panel

					local chLbl = Instance.new'TextLabel'
					chLbl.Size                   = UDim2.fromOffset(10,16)
					chLbl.BackgroundTransparency = 1
					chLbl.Text                   = ch.id
					chLbl.TextColor3             = ch.clr
					chLbl.TextSize               = 11
					chLbl.Font                   = Enum.Font.GothamBold
					chLbl.ZIndex                 = 602
					chLbl.Parent                 = row

					local numLbl = Instance.new'TextLabel'
					numLbl.Size               = UDim2.fromOffset(26,16)
					numLbl.Position           = UDim2.new(1,-26,0,0)
					numLbl.BackgroundTransparency = 1
					numLbl.Text               = tostring(math.floor(ch.get()*255))
					numLbl.TextColor3         = T.TextMuted
					numLbl.TextSize           = 10
					numLbl.Font               = T.Font
					numLbl.TextXAlignment     = Enum.TextXAlignment.Right
					numLbl.ZIndex             = 602
					numLbl.Parent             = row

					local bar = Instance.new'TextButton'
					bar.Size             = UDim2.new(1,-44,1,0)
					bar.Position         = UDim2.new(0,14,0,0)
					bar.BackgroundColor3 = T.ControlBg
					bar.BorderSizePixel  = 0
					bar.Text             = ""
					bar.AutoButtonColor  = false
					bar.ZIndex           = 602
					bar.Parent           = row
					corner(bar, 3)

					local fill = Instance.new'Frame'
					fill.Size             = UDim2.new(ch.get(), 0, 1, 0)
					fill.BackgroundColor3 = ch.clr
					fill.BorderSizePixel  = 0
					fill.ZIndex           = 603
					fill.Parent           = bar
					corner(fill, 3)

					local dragging = false
					local function doUpdate(i)
						local pct = math.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
						ch.set(pct)
						fill.Size = UDim2.new(pct, 0, 1, 0)
						numLbl.Text = tostring(math.floor(pct*255))
						rebuild()
					end
					bar.InputBegan:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then
							dragging = true; doUpdate(i)
						end
					end)
					UIS.InputChanged:Connect(function(i)
						if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then doUpdate(i) end
					end)
					UIS.InputEnded:Connect(function(i)
						if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
					end)
				end

				local function openPanel()
					local abs   = swatch.AbsolutePosition
					local scrH  = gui.AbsoluteSize.Y
					local up    = (scrH - (abs.Y + swatch.AbsoluteSize.Y)) < PH + 10
					if up then
						panel.Position = UDim2.fromOffset(abs.X - PW + swatch.AbsoluteSize.X, abs.Y - PH - 4)
					else
						panel.Position = UDim2.fromOffset(abs.X - PW + swatch.AbsoluteSize.X, abs.Y + swatch.AbsoluteSize.Y + 4)
					end
					panel.Visible = true
				end

				local function closeCP()
					open = false; panel.Visible = false
					swStroke.Color = T.Border
				end

				swatch.MouseButton1Click:Connect(function()
					open = not open
					swStroke.Color = open and T.BorderFocus or T.Border
					if open then
						closeOthers(panel)
						openPanel()
					else
						closeCP()
					end
				end)

				regCloser(panel, swatch, closeCP)
				task.defer(resize)
				return { OnChanged = function(s, cb) callback = cb return s end }
			end

			task.defer(resize)
			return gb
		end

		return tab
	end

	return win
end

return Lib
