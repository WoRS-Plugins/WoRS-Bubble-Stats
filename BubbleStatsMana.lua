-- Create a unique table for saved variables
BubbleStatsDB = BubbleStatsDB or {}  -- Unique table name for all your saved variables
BubbleStatsDB.PerCharDBMana = BubbleStatsDB.PerCharDBMana or {}
BubbleStatsDB.PerCharDBMana.offset = BubbleStatsDB.PerCharDBMana.offset or {x = 0, y = 0}  -- Ensure offsets are initialized
BubbleStatsDB.PerCharDBMana.angle = BubbleStatsDB.PerCharDBMana.angle or 0  -- Initialize angle for rotation
BubbleStatsDB.PerCharDBMana.position = BubbleStatsDB.PerCharDBMana.position or {x = 0, y = 0}  -- Initialize position
BubbleStatsDB.PerCharDBMana.size = BubbleStatsDB.PerCharDBMana.size or "small"  -- Default to small size

local buttonSizeX = 0
local buttonSizeY = 0

local buttonOffsetX = 0
local buttonOffsetY = 0

local buttonOSizeX = 0
local buttonOSizeY = 0

local buttonTOffsetX = 0
local buttonTOffsetY = 0

if BubbleStatsDB.PerCharDBMana.size == "small" then
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
local frameMana = CreateFrame("Button", "BubbleStatsButtonMana", Minimap)
local frameCallMana = CreateFrame("Frame")
local radius = 80  -- Radius from the center of the Minimap
frameMana:SetSize(32, 32)  -- Button size
frameMana:SetFrameStrata("MEDIUM")  -- Ensure it's on the right strata

-- Create the button icon texture
frameMana.icon = frameMana:CreateTexture(nil, "BACKGROUND")
frameMana.icon:SetTexture("Interface\\AddOns\\BubbleStats\\img\\Prayer.blp")  -- Adjust file extension as needed
frameMana.icon:SetSize(buttonSizeX, buttonSizeY)  -- Size to fit within the circular frame
frameMana.icon:SetPoint("CENTER", buttonOffsetX, buttonOffsetY)  -- Center the texture in the frame
frameMana.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)  -- Crop to fit the circular border

-- Create the circular border around the button
frameMana.border = frameMana:CreateTexture(nil, "OVERLAY")
frameMana.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")  -- WoW’s built-in circular border texture
frameMana.border:SetSize(buttonOSizeX, buttonOSizeY)  -- Adjusted to fit around the icon
frameMana.border:SetPoint("CENTER")  -- Center the border in the button

-- Create Mana display text on the icon
frameMana.text = frameMana:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
frameMana.text:SetPoint("CENTER", buttonTOffsetX, buttonTOffsetY)  -- Center the text within the button
frameMana.text:SetTextColor(1.0, 1.0, 0)  -- Yellow color for visibility

-- Function to update the displayed Mana
local function UpdateMana()
    local Mana = UnitPower("player", 0)  -- Power type 3 is for Mana in WoW API
    local scaledMana = Mana / 1000  -- Scale the Mana for display
    frameMana.text:SetText(string.format("%.0f", scaledMana))  -- Display scaled Mana
end


-- Function to set the button's position based on the saved variables
local function SetButtonPositionMana()
    local mx, my = Minimap:GetCenter()  -- Get the center of the minimap
    local angleRad = math.rad(BubbleStatsDB.PerCharDBMana.angle)  -- Convert angle to radians

    -- Calculate new position based on saved angle and radius
    local x = mx + math.cos(angleRad) * radius
    local y = my + math.sin(angleRad) * radius
    frameMana:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
end

local function InitializeButtonPositionMana()
    -- Restore the button's position based on saved variables
    SetButtonPositionMana()  -- Set position based on the saved angle and radius
    UpdateMana()  -- Update Mana display
    SetButtonSizeMana()
end

-- Set up event handler
frameMana:RegisterEvent("ADDON_LOADED")  -- Fired when saved variables are loaded
frameMana:RegisterEvent("PLAYER_LOGOUT")  -- Fired when about to log out
frameMana:RegisterEvent("PLAYER_ENTERING_WORLD")  -- Fired when the player enters the world
frameMana:RegisterEvent("UNIT_POWER")  -- Fired when power (Mana, rage, etc.) changes
frameMana:RegisterEvent("UNIT_MAXPOWER")  -- Fired when max power changes

-- Consolidated event handler function
frameMana:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "BubbleStats" then  -- Check if it's your addon
            frameMana:SetScript("OnEvent", InitializeButtonPositionMana)
            -- Set the button's position based on the saved angle only
            SetButtonPositionMana()  -- This will use the saved angle and position
        end
    elseif event == "PLAYER_LOGOUT" then
        -- Save the angle and position on logout
        BubbleStatsDB.PerCharDBMana.angle = BubbleStatsDB.PerCharDBMana.angle  -- Save the current angle
        BubbleStatsDB.PerCharDBMana.offset.x = 0
        BubbleStatsDB.PerCharDBMana.offset.y = 0
        -- Save the position
        local x, y = frameMana:GetCenter()
        BubbleStatsDB.PerCharDBMana.position.x = x
        BubbleStatsDB.PerCharDBMana.position.y = y
        BubbleStatsDB.PerCharDBMana.size = BubbleStatsDB.PerCharDBMana.size  -- Save the current size
    elseif event == "PLAYER_ENTERING_WORLD" or 
           (event == "UNIT_POWER" and arg1 == "player") or 
           (event == "UNIT_MAXPOWER" and arg1 == "player") then
        UpdateMana()  -- Update Mana display when relevant events occur
    end
end)

-- Variables for dragging functionality
local isDragging = false

-- Enable dragging
frameMana:SetScript("OnMouseDown", function(self, button)
    if button == "RightButton" then
        isDragging = true
        self:SetScript("OnUpdate", function()
            if isDragging then
                local mx, my = Minimap:GetCenter()
                local px, py = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()

                -- Calculate the angle based on the cursor position
                BubbleStatsDB.PerCharDBMana.angle = math.deg(math.atan2(py / scale - my, px / scale - mx))

                SetButtonPositionMana()  -- Update position based on new angle
            end
        end)
    end
end)

frameMana:SetScript("OnMouseUp", function(self, button)
    if button == "RightButton" then
        isDragging = false
        self:SetScript("OnUpdate", nil)
    end
end)

function SetButtonSizeMana()
    local buttonSizeX, buttonSizeY, buttonOffsetX, buttonOffsetY, buttonOSizeX, buttonOSizeY, buttonTOffsetX, buttonTOffsetY

    if BubbleStatsDB.PerCharDBMana.size == "small" then
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

    frameMana.icon:SetSize(buttonSizeX, buttonSizeY)  -- Size to fit within the circular frame
    frameMana.icon:SetPoint("CENTER", buttonOffsetX, buttonOffsetY)  -- Center the texture in the frame
    frameMana.border:SetSize(buttonOSizeX, buttonOSizeY)  -- Adjusted to fit around the icon
    frameMana.text:SetPoint("CENTER", buttonTOffsetX, buttonTOffsetY)  -- Center the text within the button
end


local function OnUpdate(self, elapsed)
    UpdateMana()
    -- Check if Mana is less than 100
    local Mana = UnitPower("player", 0)  -- Get current Mana
    local maxMana = UnitPowerMax("player", 0)  -- Get maximum Mana

    -- Scale the Mana for display
    local scaledMana = math.floor(Mana / 10 + 0.5)  -- Scale the Mana so that 1000 equals 1 and round to the nearest whole number
    
    
    -- Check if scaled Mana is below a certain threshold
    if Mana < 50 then
        frameMana.text:SetTextColor(1.0, 0.0, 0.0)  -- Change text color to red
        frameMana.icon:SetTexture("Interface\\AddOns\\BubbleStats\\img\\PrayerClicked.blp")  -- Change texture
    elseif Mana > 1 and Mana < maxMana then  -- Fixed 'mana' to 'Mana' (case sensitivity)
        frameMana.text:SetTextColor(0.0, 1.0, 0.0)  -- Change text color to green
        frameMana.icon:SetTexture("Interface\\AddOns\\BubbleStats\\img\\PrayerClicked.blp")  -- Change texture
    else
        frameMana.text:SetTextColor(1.0, 1.0, 0.0)  -- Change text color to yellow
        frameMana.icon:SetTexture("Interface\\AddOns\\BubbleStats\\img\\Prayer.blp")  -- Reset texture
    end
end

-- Set up the button's OnUpdate script
frameMana:SetScript("OnUpdate", OnUpdate)


-- Command to reset the button's angle to zero
SLASH_RESETBUTTON1 = "/resetbutton"
SlashCmdList["RESETBUTTON"] = function()
    BubbleStatsDB.PerCharDBMana.angle = 0  -- Reset angle to zero
    SetButtonPositionMana()  -- Reset the position of the button
end

-- Initial Mana update
UpdateMana()  -- Call to initially update Mana display
