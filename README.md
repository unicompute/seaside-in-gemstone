# Seaside in GemStone

`seaside-in-gemstone` is a Seaside application that runs inside a GemStone stone and browses live GemStone state directly. It does not load or depend on the `GemStone-Pharo-Bridge` client stack.

## Quick Start From GemStone

1. Make sure your Seaside stone and netldi are running.
2. Bootstrap Rowan into a plain GemStone image as `SystemUser`.

`topaz -l` usually reuses the login from `~/.topazini`. If that file logs you in as `DataCurator`, the bootstrap will not install `RwSpecification` for the right environment and the next step will fail.

```bash
topaz -l < /Users/tariq/src/gemtools/seaside-in-gemstone/scripts/topaz-bootstrap-rowan.topaz
```

3. Load Seaside plus this project through Rowan as `SystemUser`.

```bash
topaz -l < /Users/tariq/src/gemtools/seaside-in-gemstone/scripts/topaz-load-seaside-in-gemstone-rowan.topaz
```

4. Start the GemStone Seaside web server:

```bash
topaz -l < /Users/tariq/src/gemtools/seaside-in-gemstone/scripts/topaz-start-seaside-in-gemstone.topaz
```

5. Open:

```text
http://localhost:9001/sig
```

If `http://127.0.0.1:9001/sig` is refusing connections, nothing is listening on port `9001` yet. On April 27, 2026, that was the observed local failure mode in `gs64stone`.

On April 27, 2026, the product script
`/Users/tariq/GemStone64Bit3.7.5-arm64.Darwin/rowan3/bin/installProject.stone`
was also failing locally with:

```text
ERROR 2318 ... input file is expected to be specified on the command line
```

That failure happens inside the `superdoit_stone` launcher, so this repo now uses plain Topaz Rowan scripts instead of that wrapper.

Current script assumptions:
- stone name: `gs64stone`
- netldi name: `gs64ldi`
- bootstrap user: `SystemUser`
- load/start user: `SystemUser`
- pass: `swordfish`
- load-time gem temp memory: `-T 200000`

Edit the login lines in the Topaz scripts if your local setup differs.

On April 27, 2026, `DataCurator` in the stock local `gs64stone` image still resolved `#'name' -> 'foo'` to `Association` instead of `SymbolAssociation`, while `SystemUser` resolved the same expression correctly. Rowan `spec resolve` depends on the `SymbolAssociation` behavior, so the repo now documents and scripts the `SystemUser` load/start path.

## Tonel Caveat

The plain `tonel:///...` Metacello load path is not available in a stock GemStone image unless Tonel support has already been bootstrapped.

On April 27, 2026, the local `gs64stone` image had:
- `FileSystem`
- `FileReference`
- `MCFileTreeRepository`

and did not have:
- `TonelRepository`
- `TonelReader`
- `STONJSON`
- `NeoJSONReader`

That means the current Metacello Tonel examples only work in an image where `MonticelloTonel-*` plus JSON/STON support are already loaded. For GemStone-native load/save against GitHub, Rowan is the intended path in this repo.

Bootstrapping Rowan does not add the legacy `TonelRepository` and `TonelReader` globals. Instead, it installs `Rowan`, `RwSpecification`, `STON`, and the Rowan symbol dictionaries needed to load and save the project through Rowan.

## Runtime Model

The app uses the current Gem session directly.

Browsable roots:
- `bridgeRoot`
- `userGlobals`
- `globals`
- `published` when present
- `sessionMethods` when present

`bridgeRoot` is a local dictionary stored at `UserGlobals at: #GbsBridgeRoot`. If it does not exist yet, the gateway creates it on first access.

The toolbar actions operate on the current Gem session:
- `Refresh` rereads the selected root
- `Commit` runs `System commitTransaction`
- `Abort` runs `System abortTransaction`
- `Disconnect` just clears gateway state in the UI

## Loading

In a GemStone image where Tonel support is already present:

```smalltalk
Metacello new
  baseline: 'Seaside3';
  repository: 'github://SeasideSt/Seaside:v3.5.x/repository';
  load: #('Core' 'Javascript' 'Zinc').

Metacello new
  baseline: 'SeasideInGemStone';
  repository: 'tonel:///Users/tariq/src/gemtools/seaside-in-gemstone/src';
  load: 'default'.
```

If that second load fails with unresolved `BaselineOfSeasideInGemStone`, missing `TonelRepository`, or missing `TonelReader`, use the Rowan workflow above instead of trying to patch the image with only two classes.

Then register the app:

```smalltalk
SigExplorerApplication initializeApplication.
```

## Starting

For a local dev server after loading:

```smalltalk
SigExplorerApplication initializeApplication.
(Smalltalk at: #WAGsZincAdaptor ifAbsent: [ Smalltalk at: #ZnZincServerAdaptor ]) startOn: 8080.
```

URLs:
- `http://localhost:8080/sig`
- `http://localhost:9001/sig` when started from GemStone using the Topaz workflow above

## Project Layout

- `src/BaselineOfSeasideInGemStone`
  baseline and package declarations
- `src/SeasideInGemStone-Model`
  stone-native gateway logic
- `src/SeasideInGemStone-App`
  Seaside application/component classes
- `src/SeasideInGemStone-Tests`
  initial unit tests
- `doc/ARCHITECTURE.md`
  architecture notes and next steps
- `rowan/`
  Rowan project and load specifications for GemStone-native loading
- `scripts/load.st`
  local Tonel/Metacello load script, for images that already have Tonel support
- `scripts/topaz-bootstrap-rowan.topaz`
  bootstraps full Rowan V3 into a plain GemStone image
- `scripts/topaz-load-seaside-in-gemstone-rowan.topaz`
  loads Seaside and this project via Rowan without `installProject.stone`
- `scripts/start-local.st`
  local Tonel/Metacello load-and-start script for images that already have Tonel support

## Current Scope

This is an MVP explorer, not a full database explorer yet.

Current capabilities:
- browse well-known GemStone roots directly in the stone
- inspect key/value pairs
- view a simple detail pane for the selected entry
- commit or abort the current transaction

Planned next steps:
- object graph drilling beyond first-level associations
- instance variable and collection element browsing
- expression evaluation in object context
- write flows for dictionary entries
- Seaside session ownership of gateway state
