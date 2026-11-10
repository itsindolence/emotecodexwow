-- Emote Codex: one-click panel with every emote the game client knows.
-- Emotes are read from the client itself (EMOTE<n>_TOKEN / EMOTE<n>_CMD1), so the list
-- always matches the game version and locale. Works on WoW Forever, Classic and Retail.

local ADDON, ns = ...
local L = ns.L
local MEDIA = "Interface\\AddOns\\" .. ADDON .. "\\media\\"

---------------------------------------------------------------------------
-- Palette
---------------------------------------------------------------------------
local C = {
  bg      = { 0.055, 0.06, 0.075, 0.94 },
  edge    = { 0.78, 0.62, 0.32, 0.55 },   -- bronze
  cell    = { 1, 1, 1, 0.035 },
  hover   = { 0.25, 0.85, 0.80, 0.16 },   -- teal glow
  accent  = { 0.30, 0.90, 0.84, 1 },
  gold    = { 1.00, 0.82, 0.35, 1 },
  text    = { 0.92, 0.90, 0.86, 1 },
  muted   = { 0.55, 0.55, 0.58, 1 },
  field   = { 0, 0, 0, 0.45 },
}

---------------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------------
local DEFAULTS = {
  point = { "CENTER", "UIParent", "CENTER", 0, 60 },
  launcher = { "CENTER", "UIParent", "CENTER", -300, 60 },
  showLauncher = true,
  closeOnUse = false,
  tab = "ALL",
  fav = {},
  recent = {},
}
local DB

local function CopyDefaults(src, dst)
  for k, v in pairs(src) do
    if dst[k] == nil then
      if type(v) == "table" then
        local t = {}
        for i, x in pairs(v) do t[i] = x end
        dst[k] = t
      else
        dst[k] = v
      end
    end
  end
end

---------------------------------------------------------------------------
-- Emote list (read from the client)
---------------------------------------------------------------------------
local FALLBACK = {
  "AGREE","AMAZE","ANGRY","APOLOGIZE","APPLAUD","BASHFUL","BECKON","BEG","BITE","BLEED","BLINK",
  "BLUSH","BONK","BORED","BOUNCE","BOW","BURP","BYE","CACKLE","CHEER","CHICKEN","CHUCKLE","CLAP",
  "CONFUSED","CONGRATULATE","COUGH","COWER","CRACK","CRINGE","CRY","CURIOUS","CURTSEY","DANCE",
  "DRINK","DROOL","EAT","EYE","FART","FIDGET","FLEX","FROWN","GASP","GAZE","GIGGLE","GLARE",
  "GLOAT","GREET","GRIN","GROAN","GROVEL","GUFFAW","HAIL","HAPPY","HELLO","HUG","HUNGRY","KISS",
  "KNEEL","LAUGH","LAYDOWN","LICK","LISTEN","LOST","LOVE","MASSAGE","MOAN","MOCK","MOO","MOON",
  "MOURN","NO","NOD","NOSEPICK","PANIC","PEER","PLEAD","POINT","POKE","PRAY","ROAR","ROFL","RUDE",
  "SALUTE","SCRATCH","SEXY","SHAKE","SHOUT","SHRUG","SHY","SIGH","SIT","SLAP","SLEEP","SMILE",
  "SMIRK","SNARL","SNICKER","SNIFF","SNUB","SOOTHE","SORRY","SPIT","STARE","STAND","SURPRISED",
  "SURRENDER","TALK","TALKEX","TALKQ","TAP","THANK","THREATEN","TIRED","VICTORY","WAVE","WELCOME",
  "WHINE","WHISTLE","WINK","WORK","YAWN",
}

local EMOTES, BY_TOKEN = {}, {}

local function SetOf(list)
  local s = {}
  if type(list) == "table" then
    for _, v in pairs(list) do if type(v) == "string" then s[v] = true end end
  end
  return s
end

local function Pretty(cmd)
  cmd = cmd:gsub("^/", "")
  local first = cmd:sub(1, 1)
  if first:match("%a") then cmd = first:upper() .. cmd:sub(2) end
  return cmd
end

local function AddEmote(token, cmd, anim, voice)
  if BY_TOKEN[token] then return end
  if type(cmd) ~= "string" or cmd == "" then cmd = "/" .. token:lower() end
  local e = { token = token, cmd = cmd, name = Pretty(cmd), anim = anim[token], voice = voice[token] }
  e.sort = e.name:lower()
  e.search = (e.name .. " " .. token .. " " .. cmd):lower()
  BY_TOKEN[token] = e
  EMOTES[#EMOTES + 1] = e
end

local function CollectEmotes()
  wipe(EMOTES); wipe(BY_TOKEN)
  local anim, voice = SetOf(EmoteList), SetOf(TextEmoteSpeechList)
  local max = tonumber(MAXEMOTEINDEX)
  local misses = 0
  for i = 1, max or 2000 do
    local token = _G["EMOTE" .. i .. "_TOKEN"]
    if type(token) == "string" and token ~= "" then
      misses = 0
      AddEmote(token, _G["EMOTE" .. i .. "_CMD1"], anim, voice)
    else
      misses = misses + 1
      if not max and misses > 200 then break end
    end
  end
  if #EMOTES == 0 then
    for _, token in ipairs(FALLBACK) do AddEmote(token, nil, anim, voice) end
  end
  table.sort(EMOTES, function(a, b) return a.sort < b.sort end)
end

---------------------------------------------------------------------------
-- Doing emotes
---------------------------------------------------------------------------
local panel, Refresh

local function Perform(e)
  local fn = DoEmote or (C_ChatInfo and C_ChatInfo.DoEmote)
  if fn then fn(e.token) end
  -- move to the front of the recent list
  for i = #DB.recent, 1, -1 do if DB.recent[i] == e.token then table.remove(DB.recent, i) end end
  table.insert(DB.recent, 1, e.token)
  while #DB.recent > 24 do table.remove(DB.recent) end
  if DB.closeOnUse then panel:Hide() elseif DB.tab == "RECENT" then Refresh() end
end

local function ToggleFav(e)
  DB.fav[e.token] = (not DB.fav[e.token]) or nil
  Refresh()
end

---------------------------------------------------------------------------
-- Small UI helpers
---------------------------------------------------------------------------
local function Tex(parent, layer, c)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  if c then t:SetColorTexture(c[1], c[2], c[3], c[4] or 1) end
  return t
end

-- 1px border around a frame
local function Border(f, c, layer)
  local function line()
    local t = Tex(f, layer or "BORDER", c)
    return t
  end
  local top, bot, left, right = line(), line(), line(), line()
  top:SetPoint("TOPLEFT"); top:SetPoint("TOPRIGHT"); top:SetHeight(1)
  bot:SetPoint("BOTTOMLEFT"); bot:SetPoint("BOTTOMRIGHT"); bot:SetHeight(1)
  left:SetPoint("TOPLEFT"); left:SetPoint("BOTTOMLEFT"); left:SetWidth(1)
  right:SetPoint("TOPRIGHT"); right:SetPoint("BOTTOMRIGHT"); right:SetWidth(1)
  return { top, bot, left, right }
end

local function SetBorderColor(lines, c)
  for _, t in ipairs(lines) do t:SetColorTexture(c[1], c[2], c[3], c[4] or 1) end
end

local function Font(parent, template, c)
  local fs = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
  if c then fs:SetTextColor(c[1], c[2], c[3], c[4] or 1) end
  return fs
end

local function SavePoint(frame, key)
  local p, _, rp, x, y = frame:GetPoint()
  DB[key] = { p, "UIParent", rp, x, y }
end

local function ApplyPoint(frame, key)
  local pt = DB[key]
  frame:ClearAllPoints()
  frame:SetPoint(pt[1], UIParent, pt[3], pt[4], pt[5])
end

---------------------------------------------------------------------------
-- Panel layout
---------------------------------------------------------------------------
local W         = 380
local HEADER_H  = 95       -- header plate is 4:1
local PAD       = 12
local COLS      = 3
local ROWS      = 11
local CELL_H    = 22
local GAP       = 3
local SCROLL_W  = 4
local GRID_W    = W - PAD * 2 - SCROLL_W - 6
local CELL_W    = math.floor((GRID_W - GAP * (COLS - 1)) / COLS)
local GRID_H    = ROWS * CELL_H + (ROWS - 1) * GAP

local TABS = {
  { key = "FAV",    label = L.tabFav },
  { key = "RECENT", label = L.tabRecent },
  { key = "ANIM",   label = L.tabAnim },
  { key = "VOICE",  label = L.tabVoice },
  { key = "ALL",    label = L.tabAll },
}

local cells, tabButtons = {}, {}
local view, offset = {}, 0
local searchBox, emptyText, countText, targetText, closeBtn, thumb, track

local function BuildView()
  wipe(view)
  local query = searchBox and searchBox:GetText() or ""
  query = query:lower():gsub("^%s+", ""):gsub("%s+$", "")
  local tab = DB.tab

  local source = EMOTES
  if tab == "RECENT" and query == "" then
    source = {}
    for _, token in ipairs(DB.recent) do
      if BY_TOKEN[token] then source[#source + 1] = BY_TOKEN[token] end
    end
  end

  for _, e in ipairs(source) do
    local ok
    if query ~= "" then
      ok = e.search:find(query, 1, true) ~= nil
    elseif tab == "FAV" then ok = DB.fav[e.token]
    elseif tab == "ANIM" then ok = e.anim
    elseif tab == "VOICE" then ok = e.voice
    else ok = true end
    if ok then view[#view + 1] = e end
  end
end

local function UpdateTarget()
  if not targetText then return end
  local name = UnitName("target")
  if name then
    targetText:SetText(L.target:format("|cffffd25a" .. name .. "|r"))
  else
    targetText:SetText(L.noTarget)
  end
end

local function MaxOffset()
  local rows = math.ceil(#view / COLS)
  return math.max(0, rows - ROWS)
end

local function UpdateGrid()
  local maxOff = MaxOffset()
  if offset > maxOff then offset = maxOff end
  if offset < 0 then offset = 0 end

  for i, cell in ipairs(cells) do
    local e = view[offset * COLS + i]
    cell.emote = e
    if e then
      cell.label:SetText(e.name)
      cell.star:SetShown(DB.fav[e.token] and true or false)
      cell.dotAnim:SetShown(e.anim and true or false)
      cell.dotVoice:SetShown(e.voice and true or false)
      cell:Show()
    else
      cell:Hide()
    end
  end

  -- scroll thumb
  local rows = math.ceil(#view / COLS)
  if rows > ROWS then
    local h = math.max(18, GRID_H * ROWS / rows)
    thumb:SetHeight(h)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOP", track, "TOP", 0, -(GRID_H - h) * offset / maxOff)
    track:Show()
  else
    track:Hide()
  end

  local query = searchBox:GetText()
  if #view == 0 then
    emptyText:SetText(query ~= "" and L.emptySearch
      or DB.tab == "FAV" and L.emptyFav
      or DB.tab == "RECENT" and L.emptyRecent
      or L.emptySearch)
    emptyText:Show()
  else
    emptyText:Hide()
  end
  countText:SetText(L.count:format(#view))
end

Refresh = function()
  if not panel or not panel:IsShown() then return end
  BuildView()
  for _, b in ipairs(tabButtons) do
    local active = b.key == DB.tab and searchBox:GetText() == ""
    b.text:SetTextColor(unpack(active and C.gold or C.muted))
    b.line:SetShown(active)
  end
  closeBtn.text:SetText(DB.closeOnUse and L.closeOn or L.closeOff)
  UpdateGrid()
end

local function ShowTooltip(owner, lines)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  for i, l in ipairs(lines) do
    if i == 1 then GameTooltip:SetText(l, C.gold[1], C.gold[2], C.gold[3])
    else GameTooltip:AddLine(l, 0.85, 0.85, 0.85, true) end
  end
  GameTooltip:Show()
end

local function CreateCell(parent, index)
  local col = (index - 1) % COLS
  local row = math.floor((index - 1) / COLS)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(CELL_W, CELL_H)
  b:SetPoint("TOPLEFT", col * (CELL_W + GAP), -row * (CELL_H + GAP))
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  b.bg = Tex(b, "BACKGROUND", C.cell); b.bg:SetAllPoints()
  b.hl = Tex(b, "ARTWORK", C.hover); b.hl:SetAllPoints(); b.hl:Hide()
  b.bar = Tex(b, "OVERLAY", C.accent); b.bar:SetPoint("TOPLEFT"); b.bar:SetPoint("BOTTOMLEFT"); b.bar:SetWidth(2); b.bar:Hide()

  b.star = b:CreateTexture(nil, "OVERLAY")
  b.star:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_1")
  b.star:SetSize(11, 11)
  b.star:SetPoint("LEFT", 6, 0)

  b.label = Font(b, "GameFontHighlightSmall", C.text)
  b.label:SetPoint("LEFT", 20, 0)
  b.label:SetPoint("RIGHT", -16, 0)
  b.label:SetJustifyH("LEFT")
  b.label:SetWordWrap(false)

  b.dotVoice = Tex(b, "OVERLAY", C.gold); b.dotVoice:SetSize(4, 4); b.dotVoice:SetPoint("RIGHT", -6, 0)
  b.dotAnim = Tex(b, "OVERLAY", C.accent); b.dotAnim:SetSize(4, 4); b.dotAnim:SetPoint("RIGHT", -12, 0)

  b:SetScript("OnEnter", function(self)
    self.hl:Show(); self.bar:Show()
    local e = self.emote
    if not e then return end
    local lines = { e.name, "|cff9a9aa0" .. e.cmd .. "|r" }
    if e.anim then lines[#lines + 1] = "|cff4de6d6" .. L.tipAnim .. "|r" end
    if e.voice then lines[#lines + 1] = "|cffffd25a" .. L.tipVoice .. "|r" end
    lines[#lines + 1] = " "
    lines[#lines + 1] = L.tipUse
    lines[#lines + 1] = DB.fav[e.token] and L.tipFavDel or L.tipFavAdd
    ShowTooltip(self, lines)
  end)
  b:SetScript("OnLeave", function(self) self.hl:Hide(); self.bar:Hide(); GameTooltip:Hide() end)
  b:SetScript("OnMouseDown", function(self) self.label:SetPoint("LEFT", 21, -1) end)
  b:SetScript("OnMouseUp", function(self) self.label:SetPoint("LEFT", 20, 0) end)
  b:SetScript("OnClick", function(self, button)
    local e = self.emote
    if not e then return end
    if button == "RightButton" then ToggleFav(e) else Perform(e) end
    if self:IsMouseOver() and self:IsShown() then self:GetScript("OnEnter")(self) end
  end)
  return b
end

local function CreatePanel()
  local f = CreateFrame("Frame", "EmoteCodexFrame", UIParent)
  panel = f
  f:SetSize(W, HEADER_H + PAD + 24 + 8 + 20 + 8 + GRID_H + 10 + 18 + PAD)
  f:SetFrameStrata("DIALOG")
  f:SetClampedToScreen(true)
  f:SetMovable(true)
  f:EnableMouse(true)
  f:Hide()
  ApplyPoint(f, "point")
  tinsert(UISpecialFrames, "EmoteCodexFrame")

  -- body
  local body = CreateFrame("Frame", nil, f)
  body:SetPoint("TOPLEFT", 0, -HEADER_H + 14)
  body:SetPoint("BOTTOMRIGHT")
  local bg = Tex(body, "BACKGROUND", C.bg); bg:SetAllPoints()
  local glow = Tex(body, "BACKGROUND")
  glow:SetPoint("TOPLEFT", 1, -1); glow:SetPoint("TOPRIGHT", -1, -1); glow:SetHeight(120)
  glow:SetColorTexture(1, 1, 1, 1)
  if glow.SetGradient and CreateColor then
    glow:SetGradient("VERTICAL", CreateColor(0.3, 0.9, 0.84, 0), CreateColor(0.3, 0.9, 0.84, 0.07))
  else
    glow:SetColorTexture(0.3, 0.9, 0.84, 0.03)
  end
  Border(body, C.edge)

  -- header plate (drag handle)
  local header = CreateFrame("Frame", nil, f)
  header:SetPoint("TOPLEFT"); header:SetPoint("TOPRIGHT"); header:SetHeight(HEADER_H)
  header:SetFrameLevel(body:GetFrameLevel() + 5)
  header:EnableMouse(true)
  header:RegisterForDrag("LeftButton")
  header:SetScript("OnDragStart", function() f:StartMoving() end)
  header:SetScript("OnDragStop", function() f:StopMovingOrSizing(); SavePoint(f, "point") end)
  local plate = header:CreateTexture(nil, "ARTWORK")
  plate:SetTexture(MEDIA .. "header")
  plate:SetAllPoints()
  local title = Font(header, "GameFontNormalLarge", C.gold)
  title:SetPoint("CENTER", 0, 0)
  title:SetText(L.title)
  title:SetShadowOffset(1, -1)

  local close = CreateFrame("Button", nil, header)
  close:SetSize(20, 20)
  close:SetPoint("RIGHT", -34, 0)
  close.text = Font(close, "GameFontNormal", C.muted)
  close.text:SetPoint("CENTER")
  close.text:SetText("x")
  close:SetScript("OnEnter", function(self) self.text:SetTextColor(unpack(C.gold)) end)
  close:SetScript("OnLeave", function(self) self.text:SetTextColor(unpack(C.muted)) end)
  close:SetScript("OnClick", function() f:Hide() end)

  -- search field
  local top = -HEADER_H - 4
  local sb = CreateFrame("EditBox", nil, body)
  searchBox = sb
  sb:SetFontObject(ChatFontNormal)
  sb:SetAutoFocus(false)
  sb:SetHeight(24)
  sb:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, top)
  sb:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, top)
  sb:SetTextInsets(26, 8, 0, 0)
  local sbg = Tex(sb, "BACKGROUND", C.field); sbg:SetAllPoints()
  local sbBorder = Border(sb, { 1, 1, 1, 0.08 })
  local glass = sb:CreateTexture(nil, "OVERLAY")
  glass:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
  glass:SetSize(14, 14)
  glass:SetPoint("LEFT", 7, -1)
  glass:SetVertexColor(0.6, 0.6, 0.65)
  local hint = Font(sb, "GameFontDisableSmall", C.muted)
  hint:SetPoint("LEFT", 26, 0)
  hint:SetText(L.search)
  sb:SetScript("OnEditFocusGained", function() SetBorderColor(sbBorder, { C.accent[1], C.accent[2], C.accent[3], 0.6 }) end)
  sb:SetScript("OnEditFocusLost", function() SetBorderColor(sbBorder, { 1, 1, 1, 0.08 }) end)
  sb:SetScript("OnEscapePressed", function(self)
    if self:GetText() ~= "" then self:SetText("") else self:ClearFocus(); f:Hide() end
  end)
  sb:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
    if view[1] and self:GetText() ~= "" then Perform(view[1]) end
  end)
  sb:SetScript("OnTextChanged", function(self)
    hint:SetShown(self:GetText() == "")
    offset = 0
    Refresh()
  end)

  -- tabs
  local tabW = (W - PAD * 2) / #TABS
  for i, t in ipairs(TABS) do
    local b = CreateFrame("Button", nil, body)
    b.key = t.key
    b:SetSize(tabW, 20)
    b:SetPoint("TOPLEFT", sb, "BOTTOMLEFT", (i - 1) * tabW, -8)
    b.text = Font(b, "GameFontNormalSmall")
    b.text:SetPoint("CENTER", 0, 1)
    b.text:SetText(t.label)
    b.line = Tex(b, "OVERLAY", C.gold)
    b.line:SetPoint("BOTTOMLEFT", 10, 0); b.line:SetPoint("BOTTOMRIGHT", -10, 0); b.line:SetHeight(2)
    local base = Tex(b, "BACKGROUND", { 1, 1, 1, 0.06 })
    base:SetPoint("BOTTOMLEFT"); base:SetPoint("BOTTOMRIGHT"); base:SetHeight(1)
    b:SetScript("OnEnter", function(self) if DB.tab ~= self.key then self.text:SetTextColor(unpack(C.text)) end end)
    b:SetScript("OnLeave", function() Refresh() end)
    b:SetScript("OnClick", function(self)
      DB.tab = self.key
      offset = 0
      searchBox:SetText("")
      searchBox:ClearFocus()
      Refresh()
    end)
    tabButtons[i] = b
  end

  -- grid
  local grid = CreateFrame("Frame", nil, body)
  grid:SetSize(GRID_W, GRID_H)
  grid:SetPoint("TOPLEFT", tabButtons[1], "BOTTOMLEFT", 0, -8)
  grid:EnableMouseWheel(true)
  grid:SetScript("OnMouseWheel", function(_, delta)
    offset = offset - delta * (IsShiftKeyDown() and ROWS or 2)
    UpdateGrid()
  end)
  for i = 1, COLS * ROWS do cells[i] = CreateCell(grid, i) end

  emptyText = Font(grid, "GameFontDisable", C.muted)
  emptyText:SetPoint("CENTER")
  emptyText:SetWidth(GRID_W - 40)

  track = CreateFrame("Frame", nil, body)
  track:SetSize(SCROLL_W, GRID_H)
  track:SetPoint("TOPLEFT", grid, "TOPRIGHT", 6, 0)
  local tbg = Tex(track, "BACKGROUND", { 1, 1, 1, 0.05 }); tbg:SetAllPoints()
  thumb = Tex(track, "ARTWORK", { C.accent[1], C.accent[2], C.accent[3], 0.55 })
  thumb:SetWidth(SCROLL_W)

  -- footer
  local sep = Tex(body, "ARTWORK", { 1, 1, 1, 0.06 })
  sep:SetHeight(1)
  sep:SetPoint("TOPLEFT", grid, "BOTTOMLEFT", 0, -7)
  sep:SetPoint("RIGHT", f, "RIGHT", -PAD, 0)

  targetText = Font(body, "GameFontHighlightSmall", C.text)
  targetText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", PAD, PAD)

  countText = Font(body, "GameFontDisableSmall", C.muted)
  countText:SetPoint("BOTTOM", f, "BOTTOM", 0, PAD)

  closeBtn = CreateFrame("Button", nil, body)
  closeBtn:SetSize(110, 16)
  closeBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PAD, PAD - 2)
  closeBtn.text = Font(closeBtn, "GameFontDisableSmall", C.muted)
  closeBtn.text:SetPoint("RIGHT")
  closeBtn:SetScript("OnEnter", function(self)
    self.text:SetTextColor(unpack(C.gold))
    ShowTooltip(self, { self.text:GetText(), L.closeTip })
  end)
  closeBtn:SetScript("OnLeave", function(self) self.text:SetTextColor(unpack(C.muted)); GameTooltip:Hide() end)
  closeBtn:SetScript("OnClick", function() DB.closeOnUse = not DB.closeOnUse; Refresh() end)

  f:SetScript("OnShow", function()
    if PlaySound and SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_OPEN then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN) end
    UpdateTarget()
    Refresh()
  end)
  f:SetScript("OnHide", function()
    searchBox:ClearFocus()
    if PlaySound and SOUNDKIT and SOUNDKIT.IG_CHARACTER_INFO_CLOSE then PlaySound(SOUNDKIT.IG_CHARACTER_INFO_CLOSE) end
  end)
end

local function Toggle()
  if panel:IsShown() then panel:Hide() else panel:Show() end
end
EmoteCodex_Toggle = function() if panel then Toggle() end end

---------------------------------------------------------------------------
-- Launcher button
---------------------------------------------------------------------------
local launcher

local function CreateLauncher()
  local b = CreateFrame("Button", "EmoteCodexLauncher", UIParent)
  launcher = b
  b:SetSize(38, 38)
  b:SetFrameStrata("MEDIUM")
  b:SetClampedToScreen(true)
  b:SetMovable(true)
  b:RegisterForDrag("LeftButton")
  ApplyPoint(b, "launcher")

  local shadow = Tex(b, "BACKGROUND", { 0, 0, 0, 0.6 })
  shadow:SetPoint("TOPLEFT", -2, 2); shadow:SetPoint("BOTTOMRIGHT", 2, -2)
  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetTexture(MEDIA .. "icon")
  icon:SetAllPoints()
  local edge = Border(b, { C.edge[1], C.edge[2], C.edge[3], 0.9 }, "OVERLAY")
  local hl = b:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.15)

  b:SetScript("OnDragStart", function(self) self:StartMoving() end)
  b:SetScript("OnDragStop", function(self) self:StopMovingOrSizing(); SavePoint(self, "launcher") end)
  b:SetScript("OnMouseDown", function() icon:SetPoint("TOPLEFT", 1, -1); icon:SetPoint("BOTTOMRIGHT", -1, 1) end)
  b:SetScript("OnMouseUp", function() icon:SetAllPoints() end)
  b:SetScript("OnClick", Toggle)
  b:SetScript("OnEnter", function(self)
    SetBorderColor(edge, C.accent)
    ShowTooltip(self, { L.title, L.launcherTip })
  end)
  b:SetScript("OnLeave", function()
    SetBorderColor(edge, { C.edge[1], C.edge[2], C.edge[3], 0.9 })
    GameTooltip:Hide()
  end)
  b:SetShown(DB.showLauncher)
end

---------------------------------------------------------------------------
-- Boot
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    EmoteCodexDB = EmoteCodexDB or {}
    DB = EmoteCodexDB
    CopyDefaults(DEFAULTS, DB)
    CollectEmotes()
    CreatePanel()
    CreateLauncher()
  elseif event == "PLAYER_TARGET_CHANGED" then
    if panel and panel:IsShown() then UpdateTarget() end
  end
end)

SLASH_EMOTECODEX1 = "/ec"
SLASH_EMOTECODEX2 = "/codex"
SLASH_EMOTECODEX3 = "/emotecodex"
SlashCmdList.EMOTECODEX = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if not panel then return end
  if msg == "launcher" or msg == "button" then
    DB.showLauncher = not DB.showLauncher
    launcher:SetShown(DB.showLauncher)
  elseif msg == "reset" then
    DB.point = { unpack(DEFAULTS.point) }
    DB.launcher = { unpack(DEFAULTS.launcher) }
    ApplyPoint(panel, "point")
    ApplyPoint(launcher, "launcher")
    DB.showLauncher = true
    launcher:Show()
  elseif msg == "help" or msg == "?" then
    print("|cffffd25aEmote Codex|r: " .. L.help)
  else
    Toggle()
  end
end
