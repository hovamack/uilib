# Custom UI Library

A lightweight, pure-Luau custom UI library for Roblox. It features a robust layout management system, custom fade animations, and floating overlay panels that ensure dropdowns and color pickers are never clipped by scrolling frames.

## Features
- **Tabs**: Organize settings into clean navigation pages.
- **Groupboxes**: Group related controls together with titled outlines.
- **Toggles**: Clean boolean true/false switches.
- **Buttons**: Clickable actions with hover and active states.
- **Sliders**: Number value selection with support for custom formatting (e.g., percentages).
- **Dropdowns**: List selection menus with automatic z-index handling and click-off dismissal.
- **Color Pickers**: Fully functional RGB slidebars with a floating preview swatch.
- **Animations**: Custom recursive transparency tweening for smooth window fading (Toggle via F8).

## Using the Demo

The `example.luau` script provides a generic feature showcase of every component in the library. To load it into your executor, you do not need to download the source files manually.

Simply execute the script containing the loadstring:

```lua
local LibraryURL = "https://raw.githubusercontent.com/hovamack/uilib/main/Library.luau?v=" .. tostring(tick())
local Library = loadstring(game:HttpGet(LibraryURL))()
```

You can then view `example.luau` to see exactly how to write the code that instantiates Windows, Tabs, Groupboxes, and Interactive Controls.

## Documentation

The library is initialized by calling `Library:CreateWindow(options)`.
```lua
local Window = Library:CreateWindow({
    Title = "My Window",
    Size = UDim2.fromOffset(500, 400)
})
```

From the returned `Window` object, you can add tabs:
```lua
local Tab = Window:AddTab("Tab Name")
```

Inside those tabs, you can add groupboxes:
```lua
local Group = Tab:AddGroupbox("Group Name")
```

And finally, you populate groupboxes with your controls:
```lua
Group:AddToggle("God Mode", {Default = false}, function(state)
    print("God mode is:", state)
end)
```

Refer to `example.luau` for the exact function signatures of Buttons, Sliders, Dropdowns, and ColorPickers.
