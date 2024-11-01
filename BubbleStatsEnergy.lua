-- Create a unique table for saved variables
BubbleStatsDB = BubbleStatsDB or {}  -- Unique table name for all your saved variables
BubbleStatsDB.PerCharDBEnergy = BubbleStatsDB.PerCharDBEnergy or {}
BubbleStatsDB.PerCharDBEnergy.offset = BubbleStatsDB.PerCharDBEnergy.offset or {x = 0, y = 0}  -- Ensure offsets are initialized
BubbleStatsDB.PerCharDBEnergy.angle = BubbleStatsDB.PerCharDBEnergy.angle or 0  -- Initialize angle for rotation
BubbleStatsDB.PerCharDBEnergy.position = BubbleStatsDB.PerCharDBEnergy.position or {x = 0, y = 0}  -- Initialize position
BubbleStatsDB.PerCharDBEnergy.size = BubbleStatsDB.PerCharDBEnergy.size or "small"  -- Default to small size

local buttonSizeX = 0
local buttonSizeY = 0

local buttonOffsetX = 0
local buttonOffsetY = 0

local buttonOSizeX = 0
local buttonOSizeY = 0

local buttonTOffsetX = 0
local buttonTOffsetY = 0

if BubbleStatsDB.PerCharDBEnergy.size == "small" then
    buttonSizeX = 24
    buttonSizeY = 24
    buttonOffsetX = -11
    buttonOffsetY = 10
    buttonOSizeX = 54
    buttonOSizeY = 54
    buttonTOffsetX = -11
    buttonTOffsetY = 11
else
    buttonSizeX = 30
    buttonSizeY = 30
    buttonOffsetX = -13.5
    buttonOffsetY = 13
    buttonOSizeX = 65
    buttonOSizeY = 65
    buttonTOffsetX = -13
    buttonTOffsetY = 13
end

-- Create the minimap button
local frameEnergy = CreateFrame("Button", "BubbleStatsButton", Minimap)
local FrameCall = CreateFrame("Frame")
local radius = 80  -- Radius from the center of the Minimap
frameEnergy:SetSize(32, 32)  -- Button size
frameEnergy:SetFrameStrata("MEDIUM")  -- Ensure it's on the right strata

-- Create the button icon texture
frameEnergy.icon = frameEnergy:CreateTexture(nil, "BACKGROUND")
frameEnergy.icon:SetTexture("Interface\\AddOns\\BubbleStats\\img\\Energy.blp")  -- Adjust file extension as needed
frameEnergy.icon:SetSize(buttonSizeX, buttonSizeY)  -- Size to fit within the circular frame
frameEnergy.icon:SetPoint("CENTER", buttonOffsetX, buttonOffsetY)  -- Center the texture in the frame
frameEnergy.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- Crop to fit the circular border

-- Create the circular border around the button
frameEnergy.border = frameEnergy:CreateTexture(nil, "OVERLAY")
frameEnergy.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")  -- WoW’s built-in circular border texture
frameEnergy.border:SetSize(buttonOSizeX, buttonOSizeY)  -- Adjusted to fit around the icon
frameEnergy.border:SetPoint("CENTER")  -- Center the border in the button

-- Create energy display text on the icon
frameEnergy.text = frameEnergy:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frameEnergy.text:SetPoint("CENTER", buttonTOffsetX, buttonTOffsetY)  -- Center the text within the button
frameEnergy.text:SetTextColor(1.0, 1.0, 0)  -- Yellow color for visibility

-- Function to update the displayed energy
local function UpdateEnergy()
    local energy = UnitPower("player", 3)  -- Power type 3 is for energy in WoW API
    local scaledEnergy = energy / 100  -- Scale the energy for display
    frameEnergy.text:SetText(string.format("%.0f", scaledEnergy))  -- Display scaled energy
end

-- Function to set the button's position based on the saved variables
local function SetButtonPositionEnergy()
    local mx, my = Minimap:GetCenter()  -- Get the center of the minimap
    local angleRad = math.rad(BubbleStatsDB.PerCharDBEnergy.angle)  -- Convert angle to radians

    -- Calculate new position based on saved angle and radius
    local x = mx + math.cos(angleRad) * radius
    local y = my + math.sin(angleRad) * radius
    frameEnergy:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

local function InitializeButtonPositionEnergy()
    -- Restore the button's position based on saved variables
    SetButtonPositionEnergy()  -- Set position based on the saved angle and radius
    UpdateEnergy()  -- Update energy display
    SetButtonSizeEnergy()
end

-- Set up event handler
frameEnergy:RegisterEvent("ADDON_LOADED")  -- Fired when saved variables are loaded
frameEnergy:RegisterEvent("PLAYER_LOGOUT")  -- Fired when about to log out
frameEnergy:RegisterEvent("PLAYER_ENTERING_WORLD")  -- Fired when the player enters the world
frameEnergy:RegisterEvent("UNIT_POWER")  -- Fired when power (energy, rage, etc.) changes
frameEnergy:RegisterEvent("UNIT_MAXPOWER")  -- Fired when max power changes

-- Consolidated event handler function
frameEnergy:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "BubbleStats" then  -- Check if it's your addon
            frameEnergy:SetScript("OnEvent", InitializeButtonPositionEnergy)
            -- Set the button's position based on the saved angle only
            SetButtonPositionEnergy()  -- This will use the saved angle and position
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Save the angle and position on logout
        BubbleStatsDB.PerCharDBEnergy.angle = BubbleStatsDB.PerCharDBEnergy.angle  -- Save the current angle
        BubbleStatsDB.PerCharDBEnergy.offset.x = 0
        BubbleStatsDB.PerCharDBEnergy.offset.y = 0
        -- Save the position
        local x, y = frameEnergy:GetCenter()
        BubbleStatsDB.PerCharDBEnergy.position.x = x
        BubbleStatsDB.PerCharDBEnergy.position.y = y
        BubbleStatsDB.PerCharDBEnergy.size = BubbleStatsDB.PerCharDBEnergy.size  -- Save the current size
    elseif event == "PLAYER_ENTERING_WORLD" or 
           (event == "UNIT_POWER" and arg1 == "player") or 
           (event == "UNIT_MAXPOWER" and arg1 == "player") then
        UpdateEnergy()  -- Update energy display when relevant events occur
    end
end)

-- Variables for dragging functionality
local isDragging = false

-- Enable dragging
frameEnergy:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        isDragging = true
        self:SetScript("OnUpdate", function()
            if isDragging then
                local mx, my = Minimap:GetCenter()
                local px, py = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()

                -- Calculate the angle based on the cursor position
                BubbleStatsDB.PerCharDBEnergy.angle = math.deg(math.atan2(py / scale - my, px / scale - mx))

                SetButtonPositionEnergy()  -- Update position based on new angle
            end
        end)
    end
end)

frameEnergy:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        isDragging = false
        self:SetScript("OnUpdate", nil)
    end
end)

function SetButtonSizeEnergy()
    local buttonSizeX, buttonSizeY, buttonOffsetX, buttonOffsetY, buttonOSizeX, buttonOSizeY, buttonTOffsetX, buttonTOffsetY

    if BubbleStatsDB.PerCharDBEnergy.size == "small" then
        buttonSizeX = 24
        buttonSizeY = 24
        buttonOffsetX = -11
        buttonOffsetY = 10
        buttonOSizeX = 54
        buttonOSizeY = 54
        buttonTOffsetX = -11
        buttonTOffsetY = 11
    else  -- Assume large is the only other option
        buttonSizeX = 30
        buttonSizeY = 30
        buttonOffsetX = -13.5
        buttonOffsetY = 13
        buttonOSizeX = 65
        buttonOSizeY = 65
        buttonTOffsetX = -13
        buttonTOffsetY = 13
    end

    frameEnergy.icon:SetSize(buttonSizeX, buttonSizeY)  -- Size to fit within the circular frame
    frameEnergy.icon:SetPoint("CENTER", buttonOffsetX, buttonOffsetY)  -- Center the texture in the frame
    frameEnergy.border:SetSize(buttonOSizeX, buttonOSizeY)  -- Adjusted to fit around the icon
    frameEnergy.text:SetPoint("CENTER", buttonTOffsetX, buttonTOffsetY)  -- Center the text within the button
end


local function OnUpdate(self, elapsed)
    -- Check if energy is less than 100
    local energy = UnitPower("player", 3)  -- Get current energy
    local scaledEnergy = energy / 100  -- Scale the energy for display

    if scaledEnergy < 100 then
        frameEnergy.text:SetTextColor(1.0, 0.0, 0.0)  -- Change text color to red
        frameEnergy.icon:SetTexture("Interface\\AddOns\\BubbleStats\\img\\EnergyClicked.blp")  -- Change texture
    else
        frameEnergy.text:SetTextColor(1.0, 1.0, 1.0)  -- Change text color to white
        frameEnergy.icon:SetTexture("Interface\\AddOns\\BubbleStats\\img\\Energy.blp")  -- Reset texture
    end

    -- Update the displayed energy
    frameEnergy.text:SetText(string.format("%.0f", scaledEnergy))  -- Display scaled energy
end

-- Set up the button's OnUpdate script
frameEnergy:SetScript("OnUpdate", OnUpdate)


-- Command to reset the button's angle to zero
SLASH_RESETBUTTON1 = "/resetbutton"
SlashCmdList["RESETBUTTON"] = function()
    BubbleStatsDB.PerCharDBEnergy.angle = 0  -- Reset angle to zero
    SetButtonPositionEnergy()  -- Reset the position of the button
end

-- Initial energy update
UpdateEnergy()  -- Call to initially update energy display
