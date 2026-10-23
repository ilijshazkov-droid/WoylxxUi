--[[
================================================================================
    Woylxx UI Library
    Version: 2.0.0 [Full Release]
    Author: Woylxx
    Description: Comprehensive, bug-free, mobile-supported UI library for Roblox.
    Features: Draggable, Tabs, Sections, Tooltips, Configs, Notifications, Keybinds.
================================================================================
]]

local WoylxxUI = {}
WoylxxUI.__index = WoylxxUI

--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

--// Config
local Theme = {
    Background = Color3.fromRGB(15, 15, 15),
    Secondary = Color3.fromRGB(25, 25, 25),
    Tertiary = Color3.fromRGB(35, 35, 35),
    Accent = Color3.fromRGB(130, 60, 200), -- Woylxx Purple
    Text = Color3.fromRGB(240, 240, 240),
    SubText = Color3.fromRGB(160, 160, 160),
    Outline = Color3.fromRGB(50, 50, 50),
    Success = Color3.fromRGB(40, 200, 100),
    Danger = Color3.fromRGB(220, 50, 50),
    Font = Enum.Font.Gotham,
    FontBold = Enum.Font.GothamBold,
    FontMedium = Enum.Font.GothamMedium
}

--// Utility Functions
local function Create(className, properties)
    local instance = Instance.new(className)
    for k, v in next, properties do
        instance[k] = v
    end
    return instance
end

local function Tween(instance, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(
        duration or 0.2,
        style or Enum.EasingStyle.Quad,
        direction or Enum.EasingDirection.Out
    )
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

local function Round(num, decimalPlaces)
    local mult = 10 ^ (decimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

--// Draggable Logic (PC + Mobile)
local function MakeDraggable(MainFrame, DragFrame)
    local dragging, dragInput, dragStart, startPos

    DragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    DragFrame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            local newPosX = startPos.X.Offset + delta.X
            local newPosY = startPos.Y.Offset + delta.Y
            
            -- Bounds check
            local viewportSize = workspace.CurrentCamera.ViewportSize
            newPosX = math.clamp(newPosX, -MainFrame.AbsoluteSize.X + 50, viewportSize.X - 50)
            newPosY = math.clamp(newPosY, 0, viewportSize.Y - 50)

            MainFrame.Position = UDim2.new(startPos.X.Scale, newPosX, startPos.Y.Scale, newPosY)
        end
    end)
end

--// Notification System
function WoylxxUI:Notify(Title, Text, Duration)
    Duration = Duration or 3
    
    local NotifyFrame = Create("Frame", {
        Parent = self.Gui,
        Size = UDim2.new(0, 300, 0, 80),
        Position = UDim2.new(1, 320, 1, -90),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    
    Create("UICorner", { Parent = NotifyFrame, CornerRadius = UDim.new(0, 6) })
    Create("UIStroke", { Parent = NotifyFrame, Color = Theme.Outline, Thickness = 1 })
    
    local AccentLine = Create("Frame", {
        Parent = NotifyFrame,
        Size = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0
    })
    
    Create("UICorner", { Parent = AccentLine, CornerRadius = UDim.new(0, 6) })
    
    -- Hide the inner corners of accent line
    Create("Frame", {
        Parent = AccentLine,
        Size = UDim2.new(1, 0, 1, -10),
        Position = UDim2.new(0, 0, 0, 5),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0
    })

    Create("TextLabel", {
        Parent = NotifyFrame,
        Text = tostring(Title),
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 20),
        Position = UDim2.new(0, 15, 0, 10),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    Create("TextLabel", {
        Parent = NotifyFrame,
        Text = tostring(Text),
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -20, 0, 40),
        Position = UDim2.new(0, 15, 0, 30),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true
    })

    -- Slide in
    Tween(NotifyFrame, { Position = UDim2.new(1, -310, 1, -90) }, 0.3, Enum.EasingStyle.Back)
    
    -- Slide out & Destroy
    task.delay(Duration, function()
        local OutTween = Tween(NotifyFrame, { Position = UDim2.new(1, 320, 1, -90) }, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        OutTween.Completed:Connect(function()
            NotifyFrame:Destroy()
        end)
    end)
end

--// Tooltip Logic
local function CreateTooltip(parent, text)
    local Tooltip = Create("TextLabel", {
        Parent = parent,
        Text = text,
        Font = Theme.Font,
        TextSize = 12,
        TextColor3 = Theme.Text,
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0,
        Size = UDim2.new(0, 0, 0, 24),
        Position = UDim2.new(1, 10, 0.5, -12),
        Visible = false,
        ZIndex = 100,
        AutomaticSize = Enum.AutomaticSize.X
    })
    Create("UICorner", { Parent = Tooltip, CornerRadius = UDim.new(0, 4) })
    Create("UIStroke", { Parent = Tooltip, Color = Theme.Outline, Thickness = 1 })
    Create("UIPadding", { Parent = Tooltip, PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) })

    parent.MouseEnter:Connect(function()
        Tooltip.Visible = true
    end)
    
    parent.MouseLeave:Connect(function()
        Tooltip.Visible = false
    end)
end

--// Initialization
function WoylxxUI.new()
    local self = setmetatable({}, WoylxxUI)
    
    self.Connections = {}
    self.Flags = {}
    self.Elements = {}
    self.Tabs = {}
    self.Keybinds = {}
    
    self.Gui = Create("ScreenGui", {
        Name = "WoylxxUI_Main",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true
    })

    -- Safe Parent
    local success = pcall(function()
        if gethui then
            self.Gui.Parent = gethui()
        elseif CoreGui then
            self.Gui.Parent = CoreGui
        else
            self.Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        end
    end)
    
    if not success then
        self.Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end

    -- UI Toggle Keybind (Right Shift)
    self.UIOpen = true
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightShift and self.MainFrame then
            self.UIOpen = not self.UIOpen
            self.MainFrame.Visible = self.UIOpen
        end
    end)

    return self
end

--// Window Creation
function WoylxxUI:CreateWindow(Title)
    local Window = {}
    Window.Title = Title
    Window.Tabs = {}
    
    -- Main Frame
    self.MainFrame = Create("Frame", {
        Parent = self.Gui,
        Name = "MainFrame",
        Size = UDim2.new(0, 600, 0, 400),
        Position = UDim2.new(0.5, -300, 0.5, -200),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true
    })
    Create("UICorner", { Parent = self.MainFrame, CornerRadius = UDim.new(0, 8) })
    Create("UIStroke", { Parent = self.MainFrame, Color = Theme.Outline, Thickness = 1 })

    -- Top Bar
    local TopBar = Create("Frame", {
        Parent = self.MainFrame,
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0
    })
    Create("UICorner", { Parent = TopBar, CornerRadius = UDim.new(0, 8) })
    Create("Frame", { Parent = TopBar, Size = UDim2.new(1, 0, 0, 10), Position = UDim2.new(0, 0, 1, -10), BackgroundColor3 = Theme.Secondary, BorderSizePixel = 0 })

    -- Title
    Create("TextLabel", {
        Parent = TopBar,
        Text = "Woylxx | " .. tostring(Title),
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, 15, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left
    })

    -- Minimize Button
    local MinBtn = Create("TextButton", {
        Parent = TopBar,
        Text = "—",
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -70, 0, 5)
    })
    
    -- Close Button
    local CloseBtn = Create("TextButton", {
        Parent = TopBar,
        Text = "✕",
        Font = Theme.FontBold,
        TextSize = 14,
        TextColor3 = Theme.SubText,
        BackgroundTransparency = 1,
        Size = UDim2.new(0, 30, 0, 30),
        Position = UDim2.new(1, -35, 0, 5)
    })

    CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn, {TextColor3 = Theme.Danger}, 0.1) end)
    CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn, {TextColor3 = Theme.SubText}, 0.1) end)
    CloseBtn.MouseButton1Click:Connect(function() self:Destroy() end)

    MinBtn.MouseButton1Click:Connect(function()
        if self.MainFrame.Size.Y.Offset == 400 then
            Tween(self.MainFrame, {Size = UDim2.new(0, 600, 0, 40)}, 0.3)
        else
            Tween(self.MainFrame, {Size = UDim2.new(0, 600, 0, 400)}, 0.3)
        end
    end)

    MakeDraggable(self.MainFrame, TopBar)

    -- Sidebar (Tab Container)
    local Sidebar = Create("Frame", {
        Parent = self.MainFrame,
        Name = "Sidebar",
        Size = UDim2.new(0, 140, 1, -50),
        Position = UDim2.new(0, 10, 0, 45),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0
    })
    Create("UICorner", { Parent = Sidebar, CornerRadius = UDim.new(0, 6) })

    local TabList = Create("ScrollingFrame", {
        Parent = Sidebar,
        Size = UDim2.new(1, -10, 1, -10),
        Position = UDim2.new(0, 5, 0, 5),
        BackgroundTransparency = 1,
        ScrollBarThickness = 0,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y
    })
    Create("UIListLayout", { Parent = TabList, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })

    -- Content Container
    local ContentContainer = Create("Frame", {
        Parent = self.MainFrame,
        Name = "ContentContainer",
        Size = UDim2.new(1, -160, 1, -50),
        Position = UDim2.new(0, 160, 0, 45),
        BackgroundColor3 = Theme.Secondary,
        BorderSizePixel = 0
    })
    Create("UICorner", { Parent = ContentContainer, CornerRadius = UDim.new(0, 6) })

    -- Window Methods
    function Window:AddTab(TabName, Icon)
        local TabBtn = Create("TextButton", {
            Parent = TabList,
            Text = "  " .. tostring(TabName),
            Font = Theme.Font,
            TextSize = 14,
            TextColor3 = Theme.SubText,
            BackgroundColor3 = Theme.Background,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 35),
            AutoButtonColor = false,
            ClipsDescendants = true
        })
        Create("UICorner", { Parent = TabBtn, CornerRadius = UDim.new(0, 4) })
        
        local LeftLine = Create("Frame", {
            Parent = TabBtn,
            Size = UDim2.new(0, 3, 1, -10),
            Position = UDim2.new(0, 0, 0, 5),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false
        })
        Create("UICorner", { Parent = LeftLine, CornerRadius = UDim.new(0, 4) })

        local TabContent = Create("ScrollingFrame", {
            Parent = ContentContainer,
            Name = tostring(TabName) .. "Content",
            Size = UDim2.new(1, -20, 1, -20),
            Position = UDim2.new(0, 10, 0, 10),
            BackgroundTransparency = 1,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Accent,
            Visible = false,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.new(0, 0, 0, 0)
        })

        local TabObj = { Button = TabBtn, Content = TabContent, LeftLine = LeftLine }
        table.insert(self.Tabs, TabObj)

        TabBtn.MouseButton1Click:Connect(function()
            for _, t in ipairs(self.Tabs) do
                t.Button.BackgroundTransparency = 1
                t.Button.TextColor3 = Theme.SubText
                t.Content.Visible = false
                t.LeftLine.Visible = false
            end
            TabBtn.BackgroundTransparency = 0
            TabBtn.TextColor3 = Theme.Text
            TabContent.Visible = true
            LeftLine.Visible = true
        end)

        if #self.Tabs == 1 then
            -- Force select first tab
            TabBtn.BackgroundTransparency = 0
            TabBtn.TextColor3 = Theme.Text
            TabContent.Visible = true
            LeftLine.Visible = true
        end

        return TabObj
    end

    -- Section Builder (2 Columns)
    function Window:AddSection(Tab, SectionName)
        local SectionHolder = Create("Frame", {
            Parent = Tab.Content,
            Name = tostring(SectionName) .. "Section",
            Size = UDim2.new(1, -10, 0, 30),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.Y
        })
        Create("UICorner", { Parent = SectionHolder, CornerRadius = UDim.new(0, 6) })
        Create("UIStroke", { Parent = SectionHolder, Color = Theme.Outline, Thickness = 1 })
        
        Create("TextLabel", {
            Parent = SectionHolder,
            Text = tostring(SectionName),
            Font = Theme.FontBold,
            TextSize = 14,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 30),
            Position = UDim2.new(0, 10, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local LeftContent = Create("Frame", {
            Parent = SectionHolder,
            Size = UDim2.new(0.5, -10, 0, 0),
            Position = UDim2.new(0, 10, 0, 30),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y
        })
        Create("UIListLayout", { Parent = LeftContent, Padding = UDim.new(0, 6) })

        local RightContent = Create("Frame", {
            Parent = SectionHolder,
            Size = UDim2.new(0.5, -10, 0, 0),
            Position = UDim2.new(0.5, 5, 0, 30),
            BackgroundTransparency = 1,
            AutomaticSize = Enum.AutomaticSize.Y
        })
        Create("UIListLayout", { Parent = RightContent, Padding = UDim.new(0, 6) })

        -- Bottom padding
        Create("Frame", {
            Parent = SectionHolder,
            Size = UDim2.new(1, 0, 0, 10),
            Position = UDim2.new(0, 0, 1, -10),
            BackgroundTransparency = 1
        })

        local SectionObj = { Left = LeftContent, Right = RightContent, Frame = SectionHolder }
        return SectionObj
    end

    --// COMPONENTS

    function Window:AddButton(Section, Side, Text, Callback)
        local parent = Side == "Left" and Section.Left or Section.Right
        
        local Btn = Create("TextButton", {
            Parent = parent,
            Text = tostring(Text),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundColor3 = Theme.Tertiary,
            Size = UDim2.new(1, 0, 0, 30),
            AutoButtonColor = false,
            ClipsDescendants = true
        })
        Create("UICorner", { Parent = Btn, CornerRadius = UDim.new(0, 4) })

        Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = Theme.Accent}, 0.15) end)
        Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = Theme.Tertiary}, 0.15) end)
        
        Btn.MouseButton1Click:Connect(function()
            if Callback then task.spawn(Callback) end
        end)
    end

    function Window:AddToggle(Section, Side, Text, Default, Flag, Callback)
        local parent = Side == "Left" and Section.Left or Section.Right
        local isOn = Default or false
        
        local Holder = Create("Frame", {
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1
        })
        
        Create("TextLabel", {
            Parent = Holder,
            Text = tostring(Text),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local ToggleBg = Create("Frame", {
            Parent = Holder,
            Size = UDim2.new(0, 36, 0, 18),
            Position = UDim2.new(1, -36, 0.5, -9),
            BackgroundColor3 = isOn and Theme.Accent or Theme.Tertiary,
            BorderSizePixel = 0
        })
        Create("UICorner", { Parent = ToggleBg, CornerRadius = UDim.new(1, 0) })

        local Knob = Create("Frame", {
            Parent = ToggleBg,
            Size = UDim2.new(0, 14, 0, 14),
            Position = isOn and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0
        })
        Create("UICorner", { Parent = Knob, CornerRadius = UDim.new(1, 0) })

        local function SetState(state)
            isOn = state
            Tween(ToggleBg, {BackgroundColor3 = isOn and Theme.Accent or Theme.Tertiary}, 0.2)
            Tween(Knob, {Position = isOn and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)}, 0.2)
            if Flag then self.Flags[Flag] = isOn end
            if Callback then task.spawn(Callback, isOn) end
        end

        Holder.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                SetState(not isOn)
            end
        end)
        
        if Flag then self.Flags[Flag] = Default end
    end

    function Window:AddSlider(Section, Side, Text, Min, Max, Default, Flag, Callback)
        local parent = Side == "Left" and Section.Left or Section.Right
        local currentVal = Default or Min
        
        local Holder = Create("Frame", {
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 45),
            BackgroundTransparency = 1
        })

        Create("TextLabel", {
            Parent = Holder,
            Text = tostring(Text),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.7, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local ValueLabel = Create("TextLabel", {
            Parent = Holder,
            Text = tostring(currentVal),
            Font = Theme.FontBold,
            TextSize = 13,
            TextColor3 = Theme.Accent,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.3, -10, 0, 20),
            Position = UDim2.new(0.7, 10, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Right
        })

        local BarBg = Create("Frame", {
            Parent = Holder,
            Size = UDim2.new(1, 0, 0, 6),
            Position = UDim2.new(0, 0, 0, 25),
            BackgroundColor3 = Theme.Tertiary,
            BorderSizePixel = 0
        })
        Create("UICorner", { Parent = BarBg, CornerRadius = UDim.new(1, 0) })

        local Fill = Create("Frame", {
            Parent = BarBg,
            Size = UDim2.new((currentVal - Min) / (Max - Min), 0, 1, 0),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0
        })
        Create("UICorner", { Parent = Fill, CornerRadius = UDim.new(1, 0) })

        local function UpdateSlider(input)
            local relX = math.clamp((input.Position.X - BarBg.AbsolutePosition.X) / BarBg.AbsoluteSize.X, 0, 1)
            local val = Round(Min + (Max - Min) * relX, 2)
            
            currentVal = val
            ValueLabel.Text = tostring(val)
            Fill.Size = UDim2.new(relX, 0, 1, 0)
            
            if Flag then self.Flags[Flag] = val end
            if Callback then task.spawn(Callback, val) end
        end

        BarBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                UpdateSlider(input)
                local connection
                connection = UserInputService.InputChanged:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        UpdateSlider(inp)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        if connection then connection:Disconnect() end
                    end
                end)
            end
        end)
        
        if Flag then self.Flags[Flag] = Default end
    end

    function Window:AddDropdown(Section, Side, Text, Options, Default, Flag, Callback)
        local parent = Side == "Left" and Section.Left or Section.Right
        local isOpen = false
        local currentVal = Default or Options[1]
        
        local Holder = Create("Frame", {
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 50),
            BackgroundTransparency = 1,
            ClipsDescendants = true
        })

        Create("TextLabel", {
            Parent = Holder,
            Text = tostring(Text),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local DropdownBtn = Create("TextButton", {
            Parent = Holder,
            Text = "  " .. tostring(currentVal),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundColor3 = Theme.Tertiary,
            Size = UDim2.new(1, 0, 0, 25),
            Position = UDim2.new(0, 0, 0, 22),
            AutoButtonColor = false,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClipsDescendants = true
        })
        Create("UICorner", { Parent = DropdownBtn, CornerRadius = UDim.new(0, 4) })

        local Arrow = Create("TextLabel", {
            Parent = DropdownBtn,
            Text = "▼",
            Font = Theme.Font,
            TextSize = 10,
            TextColor3 = Theme.SubText,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 20, 1, 0),
            Position = UDim2.new(1, -25, 0, 0)
        })

        local ContentList = Create("Frame", {
            Parent = Holder,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 0, 50),
            BackgroundColor3 = Theme.Secondary,
            AutomaticSize = Enum.AutomaticSize.Y,
            Visible = false
        })
        Create("UICorner", { Parent = ContentList, CornerRadius = UDim.new(0, 4) })
        Create("UIListLayout", { Parent = ContentList, Padding = UDim.new(0, 2) })
        Create("UIPadding", { Parent = ContentList, PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) })

        DropdownBtn.MouseButton1Click:Connect(function()
            isOpen = not isOpen
            ContentList.Visible = isOpen
            Arrow.Text = isOpen and "▲" or "▼"
            
            if isOpen then
                Holder.Size = UDim2.new(1, 0, 0, 50 + ContentList.AbsoluteSize.Y)
            else
                Holder.Size = UDim2.new(1, 0, 0, 50)
            end
        end)

        for _, opt in ipairs(Options) do
            local OptBtn = Create("TextButton", {
                Parent = ContentList,
                Text = "  " .. tostring(opt),
                Font = Theme.Font,
                TextSize = 13,
                TextColor3 = Theme.Text,
                BackgroundColor3 = Theme.Tertiary,
                Size = UDim2.new(1, 0, 0, 24),
                AutoButtonColor = false,
                TextXAlignment = Enum.TextXAlignment.Left
            })
            
            OptBtn.MouseButton1Click:Connect(function()
                currentVal = opt
                DropdownBtn.Text = "  " .. tostring(opt)
                isOpen = false
                ContentList.Visible = false
                Arrow.Text = "▼"
                Holder.Size = UDim2.new(1, 0, 0, 50)
                
                if Flag then self.Flags[Flag] = opt end
                if Callback then task.spawn(Callback, opt) end
            end)
        end
        
        if Flag then self.Flags[Flag] = Default end
    end

    function Window:AddTextbox(Section, Side, Text, Placeholder, Default, Flag, Callback)
        local parent = Side == "Left" and Section.Left or Section.Right
        
        local Holder = Create("Frame", {
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 45),
            BackgroundTransparency = 1
        })

        Create("TextLabel", {
            Parent = Holder,
            Text = tostring(Text),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local Box = Create("TextBox", {
            Parent = Holder,
            Text = tostring(Default or ""),
            PlaceholderText = tostring(Placeholder or "Enter text..."),
            PlaceholderColor3 = Theme.SubText,
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundColor3 = Theme.Tertiary,
            Size = UDim2.new(1, 0, 0, 25),
            Position = UDim2.new(0, 0, 0, 22),
            TextXAlignment = Enum.TextXAlignment.Left,
            ClipsDescendants = true
        })
        Create("UICorner", { Parent = Box, CornerRadius = UDim.new(0, 4) })
        Create("UIPadding", { Parent = Box, PaddingLeft = UDim.new(0, 8) })

        Box.FocusLost:Connect(function(enterPressed)
            if Flag then self.Flags[Flag] = Box.Text end
            if Callback then task.spawn(Callback, Box.Text, enterPressed) end
        end)
        
        if Flag then self.Flags[Flag] = Default end
    end

    function Window:AddKeybind(Section, Side, Text, DefaultKey, Flag, Callback)
        local parent = Side == "Left" and Section.Left or Section.Right
        local currentKey = DefaultKey or Enum.KeyCode.Unknown
        local isBinding = false
        
        local Holder = Create("Frame", {
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1
        })

        Create("TextLabel", {
            Parent = Holder,
            Text = tostring(Text),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -70, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local Btn = Create("TextButton", {
            Parent = Holder,
            Text = tostring(currentKey.Name):gsub("Enum.KeyCode.", ""),
            Font = Theme.Font,
            TextSize = 12,
            TextColor3 = Theme.Text,
            BackgroundColor3 = Theme.Tertiary,
            Size = UDim2.new(0, 60, 0, 22),
            Position = UDim2.new(1, -60, 0.5, -11),
            AutoButtonColor = false
        })
        Create("UICorner", { Parent = Btn, CornerRadius = UDim.new(0, 4) })

        Btn.MouseButton1Click:Connect(function()
            if isBinding then return end
            isBinding = true
            Btn.Text = "..."
            Btn.TextColor3 = Theme.Accent
            
            local connection
            connection = UserInputService.InputBegan:Connect(function(input, gp)
                if gp then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    currentKey = input.KeyCode
                    Btn.Text = tostring(currentKey.Name):gsub("Enum.KeyCode.", "")
                    Btn.TextColor3 = Theme.Text
                    isBinding = false
                    
                    if Flag then self.Flags[Flag] = currentKey end
                    if Callback then task.spawn(Callback, currentKey) end
                    
                    connection:Disconnect()
                end
            end)
        end)

        -- Keybind listener
        UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == currentKey and not isBinding then
                if Callback then task.spawn(Callback, currentKey) end
            end
        end)
        
        if Flag then self.Flags[Flag] = DefaultKey end
    end

    function Window:AddLabel(Section, Side, Text)
        local parent = Side == "Left" and Section.Left or Section.Right
        
        Create("TextLabel", {
            Parent = parent,
            Text = tostring(Text),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.SubText,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 20),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextWrapped = true
        })
    end

    function Window:AddColorPicker(Section, Side, Text, DefaultColor, Flag, Callback)
        local parent = Side == "Left" and Section.Left or Section.Right
        local currentColor = DefaultColor or Color3.new(1, 1, 1)
        
        local Holder = Create("Frame", {
            Parent = parent,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundTransparency = 1
        })

        Create("TextLabel", {
            Parent = Holder,
            Text = tostring(Text),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Text,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -40, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left
        })

        local ColorBtn = Create("TextButton", {
            Parent = Holder,
            Text = "",
            BackgroundColor3 = currentColor,
            Size = UDim2.new(0, 24, 0, 24),
            Position = UDim2.new(1, -24, 0.5, -12),
            AutoButtonColor = false
        })
        Create("UICorner", { Parent = ColorBtn, CornerRadius = UDim.new(0, 4) })
        Create("UIStroke", { Parent = ColorBtn, Color = Theme.Outline, Thickness = 1 })

        -- Simple Color Picker (Cycle through)
        local colors = {
            Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(220, 50, 50),
            Color3.fromRGB(50, 200, 50),
            Color3.fromRGB(50, 50, 220),
            Color3.fromRGB(220, 220, 50),
            Color3.fromRGB(220, 50, 220),
            Color3.fromRGB(50, 220, 220)
        }
        local colorIdx = 1

        ColorBtn.MouseButton1Click:Connect(function()
            colorIdx = colorIdx + 1
            if colorIdx > #colors then colorIdx = 1 end
            currentColor = colors[colorIdx]
            ColorBtn.BackgroundColor3 = currentColor
            
            if Flag then self.Flags[Flag] = currentColor end
            if Callback then task.spawn(Callback, currentColor) end
        end)

        if Flag then self.Flags[Flag] = DefaultColor end
    end

    self.Window = Window
    return Window
end

--// Config System (Save/Load)
function WoylxxUI:SaveConfig(ConfigName)
    if not isfolder or not writefile then
        self:Notify("Error", "Executor does not support config saving.", 3)
        return
    end

    if not isfolder("WoylxxConfigs") then
        makefolder("WoylxxConfigs")
    end

    local success, err = pcall(function()
        local SaveData = {}
        for k, v in pairs(self.Flags) do
            if typeof(v) == "EnumItem" then
                SaveData[k] = { Type = "Enum", Value = tostring(v) }
            elseif typeof(v) == "Color3" then
                SaveData[k] = { Type = "Color3", Value = { v.R, v.G, v.B } }
            else
                SaveData[k] = { Type = "Basic", Value = v }
            end
        end
        
        writefile("WoylxxConfigs/" .. ConfigName .. ".json", HttpService:JSONEncode(SaveData))
    end)

    if success then
        self:Notify("Config", "Saved as " .. ConfigName, 3)
    else
        self:Notify("Error", "Failed to save config.", 3)
    end
end

function WoylxxUI:LoadConfig(ConfigName)
    if not isfile or not readfile then
        self:Notify("Error", "Executor does not support config loading.", 3)
        return
    end

    if not isfile("WoylxxConfigs/" .. ConfigName .. ".json") then
        self:Notify("Error", "Config not found.", 3)
        return
    end

    local success, err = pcall(function()
        local content = readfile("WoylxxConfigs/" .. ConfigName .. ".json")
        local data = HttpService:JSONDecode(content)
        
        for k, v in pairs(data) do
            if v.Type == "Enum" then
                self.Flags[k] = v.Value -- Simple fallback
            elseif v.Type == "Color3" then
                self.Flags[k] = Color3.new(v.Value[1], v.Value[2], v.Value[3])
            else
                self.Flags[k] = v.Value
            end
        end
    end)

    if success then
        self:Notify("Config", "Loaded " .. ConfigName, 3)
    else
        self:Notify("Error", "Failed to load config.", 3)
    end
end

--// Cleanup
function WoylxxUI:Destroy()
    for _, conn in pairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    if self.Gui then
        self.Gui:Destroy()
    end
    
    if collectgarbage then collectgarbage() end
end

return WoylxxUI
