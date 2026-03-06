--[[
    Ui lib
]]

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Library = {
    Theme = {
        MainColor = Color3.fromRGB(15, 15, 15),
        HeaderColor = Color3.fromRGB(45, 45, 45),
        AccentColor = Color3.fromRGB(66, 150, 250),
        TextColor = Color3.fromRGB(240, 240, 240),
        BorderColor = Color3.fromRGB(60, 60, 60),
        GroupColor = Color3.fromRGB(25, 25, 25),
        Font = Enum.Font.SourceSans,
        TextSize = 14
    },
    Windows = {},
    Signals = {}
}

-- Utility: Dragging
local function MakeDraggable(frame, handle)
    local dragging = false
    local dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function Library:CreateWindow(options)
    options = options or {}
    local Title = options.Title or "IMGui Window"
    local Size = options.Size or UDim2.fromOffset(500, 400)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "IMGuiLib"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.DisplayOrder = 100
    ScreenGui.Parent = (RunService:IsStudio() and LocalPlayer:WaitForChild("PlayerGui") or game:GetService("CoreGui"))

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = Size
    MainFrame.Position = UDim2.new(0.5, -Size.X.Offset/2, 0.5, -Size.Y.Offset/2)
    MainFrame.BackgroundColor3 = self.Theme.MainColor
    MainFrame.BorderSizePixel = 1
    MainFrame.BorderColor3 = self.Theme.BorderColor
    MainFrame.Parent = ScreenGui

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 22)
    Header.BackgroundColor3 = self.Theme.HeaderColor
    Header.BorderSizePixel = 0
    Header.Parent = MainFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "TitleLabel"
    TitleLabel.Size = UDim2.new(1, -10, 1, 0)
    TitleLabel.Position = UDim2.new(0, 8, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = Title
    TitleLabel.TextColor3 = self.Theme.TextColor
    TitleLabel.TextSize = self.Theme.TextSize
    TitleLabel.Font = self.Theme.Font
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Header

    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 0, 22)
    TabContainer.Position = UDim2.new(0, 0, 0, 22)
    TabContainer.BackgroundColor3 = self.Theme.HeaderColor
    TabContainer.BorderSizePixel = 0
    TabContainer.Parent = MainFrame

    local TabList = Instance.new("UIListLayout")
    TabList.FillDirection = Enum.FillDirection.Horizontal
    TabList.SortOrder = Enum.SortOrder.LayoutOrder
    TabList.Parent = TabContainer

    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -10, 1, -50)
    ContentContainer.Position = UDim2.new(0, 5, 0, 47)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Parent = MainFrame

    MakeDraggable(MainFrame, Header)

    local Window = {
        Tabs = {},
        CurrentTab = nil
    }

    function Window:AddTab(name)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name .. "Tab"
        TabButton.Size = UDim2.new(0, 80, 1, 0)
        TabButton.BackgroundColor3 = Library.Theme.HeaderColor
        TabButton.BorderSizePixel = 0
        TabButton.Text = name
        TabButton.TextColor3 = Library.Theme.TextColor
        TabButton.TextSize = Library.Theme.TextSize
        TabButton.Font = Library.Theme.Font
        TabButton.Parent = TabList.Parent

        local TabContent = Instance.new("ScrollingFrame")
        TabContent.Name = name .. "Content"
        TabContent.Size = UDim2.new(1, 0, 1, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.BorderSizePixel = 0
        TabContent.Visible = false
        TabContent.ScrollBarThickness = 2
        TabContent.ScrollBarImageColor3 = Library.Theme.AccentColor
        TabContent.Parent = ContentContainer

        local ContentPadding = Instance.new("UIPadding")
        ContentPadding.PaddingTop = UDim.new(0, 5)
        ContentPadding.PaddingLeft = UDim.new(0, 5)
        ContentPadding.PaddingRight = UDim.new(0, 5)
        ContentPadding.Parent = TabContent

        local ContentList = Instance.new("UIListLayout")
        ContentList.SortOrder = Enum.SortOrder.LayoutOrder
        ContentList.Padding = UDim.new(0, 5)
        ContentList.Parent = TabContent

        local function Select()
            for _, t in pairs(Window.Tabs) do
                t.Content.Visible = false
                t.Button.BackgroundColor3 = Library.Theme.HeaderColor
            end
            TabContent.Visible = true
            TabButton.BackgroundColor3 = Library.Theme.MainColor
            Window.CurrentTab = name
        end

        TabButton.MouseButton1Click:Connect(Select)

        if #Window.Tabs == 0 then
            Select()
        end

        local Tab = {
            Button = TabButton,
            Content = TabContent
        }

        function Tab:AddGroupbox(title)
            local GroupFrame = Instance.new("Frame")
            GroupFrame.Name = title .. "Group"
            GroupFrame.Size = UDim2.new(1, 0, 0, 30)
            GroupFrame.BackgroundColor3 = Library.Theme.GroupColor
            GroupFrame.BorderColor3 = Library.Theme.BorderColor
            GroupFrame.Parent = TabContent

            local GroupTitle = Instance.new("TextLabel")
            GroupTitle.Size = UDim2.new(1, -10, 0, 18)
            GroupTitle.Position = UDim2.new(0, 5, 0, -9)
            GroupTitle.BackgroundColor3 = Library.Theme.GroupColor
            GroupTitle.BorderSizePixel = 0
            GroupTitle.Text = " " .. title .. " "
            GroupTitle.TextColor3 = Library.Theme.TextColor
            GroupTitle.TextSize = 12
            GroupTitle.Font = Library.Theme.Font
            GroupTitle.SizeToContents = true
            GroupTitle.AutomaticSize = Enum.AutomaticSize.X
            GroupTitle.ZIndex = 5
            GroupTitle.Parent = GroupFrame

            local Container = Instance.new("Frame")
            Container.Name = "Container"
            Container.Size = UDim2.new(1, 0, 0, 0)
            Container.BackgroundTransparency = 1
            Container.AutomaticSize = Enum.AutomaticSize.Y
            Container.Parent = GroupFrame
            
            local GroupList = Instance.new("UIListLayout")
            GroupList.SortOrder = Enum.SortOrder.LayoutOrder
            GroupList.Padding = UDim.new(0, 4)
            GroupList.Parent = Container
            
            local GroupPadding = Instance.new("UIPadding")
            GroupPadding.PaddingTop = UDim.new(0, 12)
            GroupPadding.PaddingBottom = UDim.new(0, 5)
            GroupPadding.PaddingLeft = UDim.new(0, 5)
            GroupPadding.PaddingRight = UDim.new(0, 5)
            GroupPadding.Parent = Container

            GroupList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                GroupFrame.Size = UDim2.new(1, 0, 0, GroupList.AbsoluteContentSize.Y + 17)
                TabContent.CanvasSize = UDim2.new(0, 0, 0, ContentList.AbsoluteContentSize.Y + 10)
            end)

            local Group = {}

            function Group:AddToggle(text, options, callback)
                local Default = options.Default or false
                local Toggled = Default

                local ToggleFrame = Instance.new("TextButton")
                ToggleFrame.Name = text .. "Toggle"
                ToggleFrame.Size = UDim2.new(1, 0, 0, 20)
                ToggleFrame.BackgroundTransparency = 1
                ToggleFrame.Text = ""
                ToggleFrame.Parent = Container

                local Box = Instance.new("Frame")
                Box.Size = UDim2.fromOffset(14, 14)
                Box.Position = UDim2.new(0, 0, 0.5, -7)
                Box.BackgroundColor3 = Library.Theme.HeaderColor
                Box.BorderColor3 = Library.Theme.BorderColor
                Box.Parent = ToggleFrame

                local Inner = Instance.new("Frame")
                Inner.Size = UDim2.fromOffset(10, 10)
                Inner.Position = UDim2.new(0.5, -5, 0.5, -5)
                Inner.BackgroundColor3 = Library.Theme.AccentColor
                Inner.BorderSizePixel = 0
                Inner.Visible = Toggled
                Inner.Parent = Box

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -20, 1, 0)
                Label.Position = UDim2.new(0, 20, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Library.Theme.TextColor
                Label.TextSize = Library.Theme.TextSize
                Label.Font = Library.Theme.Font
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = ToggleFrame

                local function Update()
                    Inner.Visible = Toggled
                    if callback then callback(Toggled) end
                end

                ToggleFrame.MouseButton1Click:Connect(function()
                    Toggled = not Toggled
                    Update()
                end)

                return {OnChanged = function(self, cb) callback = cb return self end}
            end

            function Group:AddButton(text, callback)
                local Button = Instance.new("TextButton")
                Button.Name = text .. "Button"
                Button.Size = UDim2.new(1, 0, 0, 22)
                Button.BackgroundColor3 = Library.Theme.HeaderColor
                Button.BorderColor3 = Library.Theme.BorderColor
                Button.Text = text
                Button.TextColor3 = Library.Theme.TextColor
                Button.TextSize = Library.Theme.TextSize
                Button.Font = Library.Theme.Font
                Button.Parent = Container

                Button.MouseEnter:Connect(function() Button.BackgroundColor3 = Library.Theme.HeaderColor:Lerp(Color3.new(1,1,1), 0.1) end)
                Button.MouseLeave:Connect(function() Button.BackgroundColor3 = Library.Theme.HeaderColor end)
                Button.MouseButton1Click:Connect(callback)
            end

            function Group:AddSlider(text, options, callback)
                local Min = options.Min or 0
                local Max = options.Max or 100
                local Default = options.Default or Min
                local Value = Default

                local SliderFrame = Instance.new("Frame")
                SliderFrame.Name = text .. "Slider"
                SliderFrame.Size = UDim2.new(1, 0, 0, 32)
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.Parent = Container

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, 0, 0, 14)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Library.Theme.TextColor
                Label.TextSize = 12
                Label.Font = Library.Theme.Font
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = SliderFrame

                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Size = UDim2.new(1, 0, 0, 14)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Text = tostring(Value)
                ValueLabel.TextColor3 = Library.Theme.TextColor
                ValueLabel.TextSize = 12
                ValueLabel.Font = Library.Theme.Font
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValueLabel.Parent = SliderFrame

                local Bar = Instance.new("TextButton")
                Bar.Size = UDim2.new(1, 0, 0, 12)
                Bar.Position = UDim2.new(0, 0, 0, 16)
                Bar.BackgroundColor3 = Library.Theme.HeaderColor
                Bar.BorderColor3 = Library.Theme.BorderColor
                Bar.Text = ""
                Bar.Parent = SliderFrame

                local Fill = Instance.new("Frame")
                Fill.Size = UDim2.new((Value - Min) / (Max - Min), 0, 1, 0)
                Fill.BackgroundColor3 = Library.Theme.AccentColor
                Fill.BorderSizePixel = 0
                Fill.Parent = Bar

                local function Update(input)
                    local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                    Value = math.floor(Min + (Max - Min) * pos)
                    Fill.Size = UDim2.new(pos, 0, 1, 0)
                    ValueLabel.Text = tostring(Value)
                    if callback then callback(Value) end
                end

                local dragging = false
                Bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        Update(input)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        Update(input)
                    end
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = false
                    end
                end)

                return {OnChanged = function(self, cb) callback = cb return self end}
            end

            function Group:AddDropdown(text, options, callback)
                local List = options.Values or {}
                local Default = options.Default or List[1]
                local Selected = Default
                local Opened = false

                local DropdownFrame = Instance.new("Frame")
                DropdownFrame.Name = text .. "Dropdown"
                DropdownFrame.Size = UDim2.new(1, 0, 0, 36)
                DropdownFrame.BackgroundTransparency = 1
                DropdownFrame.Parent = Container

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, 0, 0, 14)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Library.Theme.TextColor
                Label.TextSize = 12
                Label.Font = Library.Theme.Font
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = DropdownFrame

                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, 0, 0, 18)
                Button.Position = UDim2.new(0, 0, 0, 16)
                Button.BackgroundColor3 = Library.Theme.HeaderColor
                Button.BorderColor3 = Library.Theme.BorderColor
                Button.Text = " " .. Selected
                Button.TextColor3 = Library.Theme.TextColor
                Button.TextSize = 12
                Button.Font = Library.Theme.Font
                Button.TextXAlignment = Enum.TextXAlignment.Left
                Button.Parent = DropdownFrame

                local Arrow = Instance.new("TextLabel")
                Arrow.Size = UDim2.new(0, 18, 1, 0)
                Arrow.Position = UDim2.new(1, -18, 0, 0)
                Arrow.BackgroundTransparency = 1
                Arrow.Text = "v"
                Arrow.TextColor3 = Library.Theme.TextColor
                Arrow.TextSize = 12
                Arrow.Font = Library.Theme.Font
                Arrow.Parent = Button

                local ListFrame = Instance.new("ScrollingFrame")
                ListFrame.Size = UDim2.new(1, 0, 0, 100)
                ListFrame.Position = UDim2.new(0, 0, 1, 1)
                ListFrame.BackgroundColor3 = Library.Theme.MainColor
                ListFrame.BorderColor3 = Library.Theme.BorderColor
                ListFrame.BorderSizePixel = 1
                ListFrame.Visible = false
                ListFrame.ZIndex = 10
                ListFrame.CanvasSize = UDim2.new(0,0,0,0)
                ListFrame.ScrollBarThickness = 2
                ListFrame.Parent = Button

                local UIList = Instance.new("UIListLayout")
                UIList.Parent = ListFrame

                local function UpdateList()
                    for _, v in ipairs(List) do
                        local Item = Instance.new("TextButton")
                        Item.Size = UDim2.new(1, 0, 0, 18)
                        Item.BackgroundColor3 = Library.Theme.MainColor
                        Item.BorderSizePixel = 0
                        Item.Text = " " .. v
                        Item.TextColor3 = Library.Theme.TextColor
                        Item.TextSize = 12
                        Item.Font = Library.Theme.Font
                        Item.TextXAlignment = Enum.TextXAlignment.Left
                        Item.ZIndex = 11
                        Item.Parent = ListFrame

                        Item.MouseButton1Click:Connect(function()
                            Selected = v
                            Button.Text = " " .. Selected
                            Opened = false
                            ListFrame.Visible = false
                            if callback then callback(Selected) end
                        end)
                    end
                    ListFrame.CanvasSize = UDim2.new(0, 0, 0, #List * 18)
                end

                UpdateList()

                Button.MouseButton1Click:Connect(function()
                    Opened = not Opened
                    ListFrame.Visible = Opened
                end)

                return {OnChanged = function(self, cb) callback = cb return self end}
            end

            function Group:AddLabel(text)
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, 0, 0, 18)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Library.Theme.TextColor
                Label.TextSize = Library.Theme.TextSize
                Label.Font = Library.Theme.Font
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = Container
            end

            function Group:AddColorPicker(text, options, callback)
                local Default = options.Default or Color3.new(1, 1, 1)
                local Color = Default
                local Opened = false

                local ColorFrame = Instance.new("Frame")
                ColorFrame.Name = text .. "ColorPicker"
                ColorFrame.Size = UDim2.new(1, 0, 0, 20)
                ColorFrame.BackgroundTransparency = 1
                ColorFrame.Parent = Container

                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -25, 1, 0)
                Label.Position = UDim2.new(0, 0, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Library.Theme.TextColor
                Label.TextSize = Library.Theme.TextSize
                Label.Font = Library.Theme.Font
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.Parent = ColorFrame

                local Preview = Instance.new("TextButton")
                Preview.Size = UDim2.fromOffset(18, 14)
                Preview.Position = UDim2.new(1, -18, 0.5, -7)
                Preview.BackgroundColor3 = Color
                Preview.BorderColor3 = Library.Theme.BorderColor
                Preview.Text = ""
                Preview.Parent = ColorFrame

                local PickerFrame = Instance.new("Frame")
                PickerFrame.Size = UDim2.fromOffset(120, 80)
                PickerFrame.Position = UDim2.new(1, 2, 0, 0)
                PickerFrame.BackgroundColor3 = Library.Theme.MainColor
                PickerFrame.BorderColor3 = Library.Theme.BorderColor
                PickerFrame.BorderSizePixel = 1
                PickerFrame.Visible = false
                PickerFrame.ZIndex = 20
                PickerFrame.Parent = Preview

                local function CreateSlider(name, color, offset)
                    local SFrame = Instance.new("Frame")
                    SFrame.Size = UDim2.new(1, -10, 0, 15)
                    SFrame.Position = UDim2.new(0, 5, 0, offset)
                    SFrame.BackgroundTransparency = 1
                    SFrame.ZIndex = 21
                    SFrame.Parent = PickerFrame

                    local SBar = Instance.new("TextButton")
                    SBar.Size = UDim2.new(1, 0, 1, 0)
                    SBar.BackgroundColor3 = Library.Theme.HeaderColor
                    SBar.BorderColor3 = Library.Theme.BorderColor
                    SBar.Text = ""
                    SBar.ZIndex = 22
                    SBar.Parent = SFrame

                    local SFill = Instance.new("Frame")
                    SFill.Size = UDim2.new(color, 0, 1, 0)
                    SFill.BackgroundColor3 = Library.Theme.AccentColor
                    SFill.BorderSizePixel = 0
                    SFill.ZIndex = 23
                    SFill.Parent = SBar

                    local dragging = false
                    local function update(input)
                        local pos = math.clamp((input.Position.X - SBar.AbsolutePosition.X) / SBar.AbsoluteSize.X, 0, 1)
                        SFill.Size = UDim2.new(pos, 0, 1, 0)
                        return pos
                    end

                    SBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                        end
                    end)

                    return SBar, function(v) SFill.Size = UDim2.new(v, 0, 1, 0) end
                end

                local rBar, rSet = CreateSlider("R", Color.R, 10)
                local gBar, gSet = CreateSlider("G", Color.G, 30)
                local bBar, bSet = CreateSlider("B", Color.B, 50)

                local function UpdateColor()
                    Preview.BackgroundColor3 = Color
                    if callback then callback(Color) end
                end

                local function HandleInput(bar, channel)
                    local dragging = false
                    bar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                        end
                    end)
                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                            local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                            if channel == "R" then Color = Color3.new(pos, Color.G, Color.B) rSet(pos)
                            elseif channel == "G" then Color = Color3.new(Color.R, pos, Color.B) gSet(pos)
                            elseif channel == "B" then Color = Color3.new(Color.R, Color.G, pos) bSet(pos) end
                            UpdateColor()
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)
                end

                HandleInput(rBar, "R")
                HandleInput(gBar, "G")
                HandleInput(bBar, "B")

                Preview.MouseButton1Click:Connect(function()
                    Opened = not Opened
                    PickerFrame.Visible = Opened
                end)

                return {OnChanged = function(self, cb) callback = cb return self end}
            end

            return Group
        end

        table.insert(Window.Tabs, Tab)
        return Tab
    end

    return Window
end

return Library
