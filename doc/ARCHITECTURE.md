# Architecture

## Goal

Build a Seaside web interface that runs inside a GemStone stone and exposes live GemStone state directly.

## First Slice

The first slice keeps the boundary simple:

```text
Browser
  -> Seaside component (`SigExplorerApplication`)
  -> stone-native gateway (`SigGemStoneGateway`)
  -> current Gem session
  -> `UserGlobals`, `Globals`, `Published`, `SessionMethods`
```

## Runtime Model

- the Seaside component keeps one gateway instance
- the gateway reads and mutates the current Gem session directly
- `bridgeRoot` is a convenience dictionary stored at `UserGlobals at: #GbsBridgeRoot`
- commit and abort are explicit UI actions mapped to `System commitTransaction` and `System abortTransaction`
- disconnect is only a UI-level reset; there is no separate bridge session to close

## Main Classes

- `SigGemStoneGateway`
  reads GemStone roots and transaction state from the current session
- `SigExplorerApplication`
  Seaside root component registered at `/sig`

## Why This Shape

- it avoids loading the Pharo-side `GemStone-Pharo-Bridge` client into the stone
- it keeps the first server-side version small and mechanically simple
- it uses Seaside where it belongs, inside the GemStone Seaside stone
- it leaves room for a later bridge-backed Pharo client without coupling that client to the stone app

## Next Steps

1. Add deeper object browsing by object identity.
2. Add collection and instance-variable expansion.
3. Add object-context evaluation.
4. Add write operations for dictionary entries.
5. Add a Seaside session class to own gateway lifecycle more explicitly.
6. Add browser-level tests once the UI stabilizes.
