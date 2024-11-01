-- Create a unique table for saved variables
BubbleStatsDB = BubbleStatsDB or {}  -- Unique table name for all your saved variables
BubbleStatsDB.PerCharDBHealth = BubbleStatsDB.PerCharDBHealth or {}
BubbleStatsDB.PerCharDBHealth.offset = BubbleStatsDB.PerCharDBHealth.offset or {x = 0, y = 0}  -- Ensure offsets are initialized
BubbleStatsDB.PerCharDBHealth.angle = BubbleStatsDB.PerCharDBHealth.angle or 0  -- Initialize angle for rotation
BubbleStatsDB.PerCharDBHealth.position = BubbleStatsDB.PerCharDBHealth.position or {x = 0, y = 0}  -- Initialize position
BubbleStatsDB.PerCharDBHealth.size = BubbleStatsDB.PerCharDBHealth.size or "small"  -- Default to small size



local buttonSizeX = 0
local buttonSizeY = 0

local buttonOffsetX = 0
local buttonOffsetY = 0

local buttonOSizeX = 0
local buttonOSizeY = 0

local buttonTOffsetX = 0
local buttonTOffsetY = 0



if BubbleStatsDB.PerCharDBHealth.size == "small" then
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
local frame = CreateFrame("Button", "BubbleStatsButton", Minimap)
local radius = 80  -- Radius from the center of the Minimap
frame:SetSize(32, 32)  -- Button size
frame:SetFrameStrata("MEDIUM")  -- Ensure it's on the right strata

-- Create the button icon texture
frame.icon = frame:CreateTexture(nil, "BACKGROUND")
frame.icon:SetTexture("Interface\\AddOns\\BubbleStats\\img\\Hitpoints.blp")  -- Adjust file extension as needed
frame.icon:SetSize(buttonSizeX, buttonSizeY)  -- Size to fit within the circular frame
frame.icon:SetPoint("CENTER", buttonOffsetX, buttonOffsetY)  -- Center the texture in the frame
frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- Crop to fit the circular border

-- Create the circular border around the button
frame.border = frame:CreateTexture(nil, "OVERLAY")
frame.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")  -- WoW’s built-in circular border texture
frame.border:SetSize(buttonOSizeX, buttonOSizeY)  -- Adjusted to fit around the icon
frame.border:SetPoint("CENTER")  -- Center the border in the button

-- Create health display text on the icon
frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frame.text:SetPoint("CENTER", buttonTOffsetX, buttonTOffsetY)  -- Center the text within the button
frame.text:SetTextColor(1.0, 1.0, 0)  -- Yellow color for visibility

-- Function to update the displayed health
local function UpdateHealth()
    local health = UnitHealth("player")
    frame.text:SetText(string.format("%d", health))  -- Display current health
end

-- Function to set the button's position based on the saved variables
local function SetButtonPosition()
    local mx, my = Minimap:GetCenter()  -- Get the center of the minimap
    local angleRad = math.rad(BubbleStatsDB.PerCharDBHealth.angle)  -- Convert angle to radians

    -- Calculate new position based on saved angle and radius
    local x = mx + math.cos(angleRad) * radius
    local y = my + math.sin(angleRad) * radius
    frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

local function InitializeButtonPosition()
    -- Restore the button's position based on saved variables
    SetButtonPosition()  -- Set position based on the saved angle and radius
    UpdateHealth()  -- Update health display
    SetButtonSize()
end

-- Set up event handler
frame:RegisterEvent("ADDON_LOADED")  -- Fired when saved variables are loaded
frame:RegisterEvent("PLAYER_LOGOUT")  -- Fired when about to log out
frame:RegisterEvent("PLAYER_ENTERING_WORLD")  -- Fired when the player enters the world
frame:RegisterEvent("UNIT_HEALTH")  -- Fired when health changes
frame:RegisterEvent("UNIT_MAXHEALTH")  -- Fired when max health changes

-- Consolidated event handler function
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "BubbleStats" then  -- Check if it's your addon
            frame:SetScript("OnEvent", InitializeButtonPosition)
            -- Set the button's position based on the saved angle only
            SetButtonPosition()  -- This will use the saved angle and position
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Save the angle and position on logout
        BubbleStatsDB.PerCharDBHealth.angle = BubbleStatsDB.PerCharDBHealth.angle  -- Save the current angle
        BubbleStatsDB.PerCharDBHealth.offset.x = 0
        BubbleStatsDB.PerCharDBHealth.offset.y = 0
        -- Save the position
        local x, y = frame:GetCenter()
        BubbleStatsDB.PerCharDBHealth.position.x = x
        BubbleStatsDB.PerCharDBHealth.position.y = y
        BubbleStatsDB.PerCharDBHealth.size = BubbleStatsDB.PerCharDBHealth.size  -- Save the current size
    elseif event == "PLAYER_ENTERING_WORLD" or 
           (event == "UNIT_HEALTH" and arg1 == "player") or 
           (event == "UNIT_MAXHEALTH" and arg1 == "player") then
        UpdateHealth()  -- Update health display when relevant events occur
    end
end)

-- Variables for dragging functionality
local isDragging = false

-- Enable dragging
frame:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        isDragging = true
        self:SetScript("OnUpdate", function()
            if isDragging then
                local mx, my = Minimap:GetCenter()
                local px, py = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()

                -- Calculate the angle based on the cursor position
                BubbleStatsDB.PerCharDBHealth.angle = math.deg(math.atan2(py / scale - my, px / scale - mx))

                SetButtonPosition()  -- Update position based on new angle
            end
        end)
    end
end)

frame:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        isDragging = false
        self:SetScript("OnUpdate", nil)
    end
end)


function SetButtonSize()
    local buttonSizeX, buttonSizeY, buttonOffsetX, buttonOffsetY, buttonOSizeX, buttonOSizeY, buttonTOffsetX, buttonTOffsetY

    if BubbleStatsDB.PerCharDBHealth.size == "small" then
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

    frame.icon:SetSize(buttonSizeX, buttonSizeY)  -- Size to fit within the circular frame
    frame.icon:SetPoint("CENTER", buttonOffsetX, buttonOffsetY)  -- Center the texture in the frame
    frame.border:SetSize(buttonOSizeX, buttonOSizeY)  -- Adjusted to fit around the icon
    frame.text:SetPoint("CENTER", buttonTOffsetX, buttonTOffsetY)  -- Center the text within the button
end

-- Command to reset the button's angle to zero
SLASH_RESETBUTTON1 = "/resetbutton"
SlashCmdList["RESETBUTTON"] = function()
    BubbleStatsDB.PerCharDBHealth.angle = 0  -- Reset angle to zero
    SetButtonPosition()  -- Reset the position of the button
end

-- Command to set the button size to large
SLASH_BS_LARGE1 = "/bslarge"
SlashCmdList["BS_LARGE"] = function()
    BubbleStatsDB.PerCharDBHealth.size = "large"
    BubbleStatsDB.PerCharDBEnergy.size = "large"
    SetButtonSize()  -- Call the function to update the button size
    print("[BUBBLE STATS]: Button size set to large.")
    ReloadUI();
end

-- Command to set the button size to small
SLASH_BS_SMALL1 = "/bssmall"
SlashCmdList["BS_SMALL"] = function()
    BubbleStatsDB.PerCharDBHealth.size = "small"
    BubbleStatsDB.PerCharDBEnergy.size = "small"
    SetButtonSize()  -- Call the function to update the button size
    print("[BUBBLE STATS]: Button size set to small.")
    ReloadUI();
end

-- Initial health update
UpdateHealth()  -- Call to initially update health display