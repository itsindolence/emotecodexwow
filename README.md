# Emote Codex

Every emote in World of Warcraft, one click away. A small fantasy-styled panel that lists every emote your game client knows, with search, favorites, recent emotes, Animated / Voice tabs, a draggable launcher button, a key binding and `/ec`.

Built for **WoW Forever**, also works on Classic Era, Anniversary, MoP Classic and Retail.

## Usage

- Left-click an emote: do it (on your target, if you have one)
- Right-click an emote: add to / remove from Favorites
- Type to search, Enter does the first match
- `/ec` toggle panel, `/ec launcher` show/hide button, `/ec reset` reset positions

## Releasing

Bump the version heading in `CHANGELOG.md`, commit, then push a tag `vX.Y.Z`. The GitHub workflow runs the BigWigs packager and uploads to CurseForge (needs the `CF_API_KEY` secret and `X-Curse-Project-ID` in the TOC).

## License

MIT
