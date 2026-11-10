local ADDON, ns = ...

local L = {
  title       = "Emote Codex",
  search      = "Search emotes...",
  tabFav      = "Favorites",
  tabRecent   = "Recent",
  tabAnim     = "Animated",
  tabVoice    = "Voice",
  tabAll      = "All",
  target      = "Target: %s",
  noTarget    = "No target",
  count       = "%d emotes",
  closeOn     = "Auto-close: on",
  closeOff    = "Auto-close: off",
  closeTip    = "On: the panel closes after you pick an emote.\nOff: it stays open.\nClick to toggle.",
  emptyFav    = "Right-click any emote to add it here",
  emptyRecent = "Emotes you use will show up here",
  emptySearch = "Nothing found",
  tipUse      = "Left-click: perform",
  tipFavAdd   = "Right-click: add to favorites",
  tipFavDel   = "Right-click: remove from favorites",
  tipAnim     = "Animated",
  tipVoice    = "Has voice",
  launcherTip = "Left-click: emote panel\nDrag: move",
  help        = "/ec - toggle panel, /ec launcher - show/hide button, /ec reset - reset positions",
  bindHeader  = "Emote Codex",
  bindToggle  = "Toggle emote panel",
}

if GetLocale() == "ruRU" then
  L.search      = "Поиск эмоции..."
  L.tabFav      = "Избранное"
  L.tabRecent   = "Недавние"
  L.tabAnim     = "Анимация"
  L.tabVoice    = "Голос"
  L.tabAll      = "Все"
  L.target      = "Цель: %s"
  L.noTarget    = "Без цели"
  L.count       = "Эмоций: %d"
  L.closeOn     = "Автозакрытие: вкл"
  L.closeOff    = "Автозакрытие: выкл"
  L.closeTip    = "Вкл — панель закрывается после выбора эмоции.\nВыкл — остаётся открытой.\nЩёлкни, чтобы переключить."
  L.emptyFav    = "ПКМ по эмоции — добавить сюда"
  L.emptyRecent = "Здесь появятся использованные эмоции"
  L.emptySearch = "Ничего не найдено"
  L.tipUse      = "ЛКМ: выполнить"
  L.tipFavAdd   = "ПКМ: в избранное"
  L.tipFavDel   = "ПКМ: убрать из избранного"
  L.tipAnim     = "С анимацией"
  L.tipVoice    = "Со звуком"
  L.launcherTip = "ЛКМ: панель эмоций\nПеретащить: переместить"
  L.help        = "/ec - панель, /ec launcher - кнопка вкл/выкл, /ec reset - сбросить позиции"
  L.bindToggle  = "Показать/скрыть панель эмоций"
end

ns.L = L
BINDING_HEADER_EMOTECODEX = L.bindHeader
BINDING_NAME_EMOTECODEX_TOGGLE = L.bindToggle
