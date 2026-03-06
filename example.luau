-- Fetch the latest version of the library using a cache buster
local LibraryURL = "https://raw.githubusercontent.com/hovamack/uilib/main/Library.luau?v=" .. tostring(tick())
local Library = loadstring(game:HttpGet(LibraryURL))()

-- 1. Create the Main Window
local Window = Library:CreateWindow({
    Title = "UI Component Demo",
    Size = UDim2.fromOffset(500, 400)
})

-- 2. Create Tabs
local DemoTab    = Window:AddTab("Demo Tab")
local AnotherTab = Window:AddTab("Second Tab")

-- ==========================================
-- GROUPBOX: BUTTONS & TOGGLES
-- ==========================================
local InteractablesGrp = DemoTab:AddGroupbox("Interactable Elements")
InteractablesGrp:AddLabel("These are basic clickable UI elements.")

InteractablesGrp:AddButton("Test Button 1", function()
    print("Test Button 1 was clicked!")
end)

InteractablesGrp:AddButton("Test Button 2", function()
    print("Test Button 2 was clicked!")
end)

local MyToggleState = false
local TestToggle = InteractablesGrp:AddToggle("Example Toggle", {Default = false}, function(state)
    MyToggleState = state
    print("Toggle changed to state:", state)
end)

-- ==========================================
-- GROUPBOX: SLIDERS & DROPDOWNS
-- ==========================================
local ValuesGrp = DemoTab:AddGroupbox("Value Selectors")
ValuesGrp:AddLabel("These UI elements select specific values.")

ValuesGrp:AddSlider("Example Number Slider", {Min = 0, Max = 100, Default = 50}, function(value)
    print("Number Slider changed to:", value)
end)

ValuesGrp:AddSlider("Example Percent Slider", {Min = 0, Max = 100, Default = 10, Format = "%d%%"}, function(value)
    print("Percent Slider changed to:", value, "%")
end)

ValuesGrp:AddDropdown("Example Dropdown", {Values = {"Option A", "Option B", "Option C"}, Default = "Option A"}, function(value)
    print("Dropdown selection changed to:", value)
end)

-- ==========================================
-- GROUPBOX: COLORS
-- ==========================================
local ColorsGrp = DemoTab:AddGroupbox("Color Selection")
ColorsGrp:AddLabel("Click the color square.")

ColorsGrp:AddColorPicker("Example Color Picker", {Default = Color3.fromRGB(150, 150, 255)}, function(color)
    print("Color Picker changed to RGB:", color.R*255, color.G*255, color.B*255)
end)

-- Finish
print("Library Demo loaded! Press F8 to toggle UI visibility.")
