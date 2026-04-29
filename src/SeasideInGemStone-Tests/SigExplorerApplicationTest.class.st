Class {
	#name : 'SigExplorerApplicationTest',
	#superclass : 'TestCase',
	#instVars : [
		'application'
	],
	#category : 'SeasideInGemStone-Tests',
	#package : 'SeasideInGemStone-Tests'
}

{ #category : 'running' }
SigExplorerApplicationTest >> setUp [
	super setUp.
	application := SigExplorerApplication new
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDefaultSelectedBrowserDictionaryNameIsUserGlobals [
	self assert: application selectedBrowserDictionaryName equals: #UserGlobals
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDefaultSelectedSymbolListDictionaryNameIsUserGlobals [
	self assert: application selectedSymbolListDictionaryName equals: #UserGlobals
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDefaultSelectedRootNameIsBridgeRoot [
	self assert: application selectedRootName equals: #bridgeRoot
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testBrowserSourceHeadingTextUsesSelectedSelector [
	application selectBrowserClassNamed: 'Object'.
	application selectBrowserSelectorNamed: 'printString'.

	self assert: application browserSourceHeadingText equals: 'Object >> printString'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testSelectingBrowserClassClearsProtocolAndSelector [
	application selectBrowserProtocolNamed: 'accessing'.
	application selectBrowserSelectorNamed: 'foo'.
	application selectBrowserClassNamed: 'Object'.

	self assert: application selectedBrowserClassName equals: 'Object'.
	self assert: application selectedBrowserProtocolName isNil.
	self assert: application selectedBrowserSelector isNil
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testSelectingBrowserDictionaryClearsBrowserSelections [
	application selectBrowserClassNamed: 'Object'.
	application selectBrowserProtocolNamed: 'accessing'.
	application selectBrowserSelectorNamed: 'foo'.
	application selectBrowserDictionaryNamed: #Globals.

	self assert: application selectedBrowserDictionaryName equals: #Globals.
	self assert: application selectedBrowserClassName isNil.
	self assert: application selectedBrowserProtocolName isNil.
	self assert: application selectedBrowserSelector isNil
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testSelectingRootClearsSelectedEntry [
	application selectEntryKey: 'Something'.
	application selectRootNamed: #globals.

	self assert: application selectedRootName equals: #globals.
	self assert: application selectedEntryKey isNil
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testSelectingSymbolListDictionaryClearsSelectedBinding [
	application selectSymbolListEntryKey: 'WAAdmin'.
	application selectSymbolListDictionaryNamed: #Globals.

	self assert: application selectedSymbolListDictionaryName equals: #Globals.
	self assert: application selectedSymbolListEntryKey isNil
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testWorkspaceDefaultsArePopulated [
	self assert: application workspaceSourceText size > 0.
	self assert: application workspaceResultText equals: ''
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testExplorerRenderUsesBridgeStyleBrowserShell [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderExplorerOn:) asString.

	self assert: (source includesString: 'exp-wrap').
	self assert: (source includesString: 'Symbol List for').
	self assert: (source includesString: 'currentUserId').
	self assert: (source includesString: 'exp-split').
	self deny: (source includesString: 'attributeAt: ''disabled'' put: ''disabled''').
	self deny: (source includesString: 'with: ''Root''').
	self deny: (source includesString: 'with: ''Selection''').
	self assert: (source includesString: 'exp-scroll-rows-10').
	self assert: (source includesString: 'rowsTitle :=').
	self assert: (source includesString: 'inspectionSnapshotFor: association value').
	self assert: (source includesString: 'PrintString').
	self assert: (source includesString: 'openSelectedEntryInNewWindow').
	self assert: (source includesString: 'inspector-value-link').
	self assert: (source includesString: 'inspectStructuredInspectorRow:').
	self deny: (source includesString: 'label: ''Inspect''')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testRenderSymbolListBrowserUsesOpenWindowAction [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderSymbolListBrowserOn:) asString.

	self assert: (source includesString: 'exp-wrap').
	self assert: (source includesString: 'Keys / Values').
	self assert: (source includesString: 'PrintString').
	self assert: (source includesString: 'openSelectedSymbolListEntryInNewWindow').
	self assert: (source includesString: 'inspectSelectedSymbolListEntry')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testNewInspectorWindowTracksAdditionalObjectWindows [
	| window |
	window := application
		newInspectorWindowForText: 'Class: SmallInteger'
		label: 'Explorer / Answer'.

	self assert: application inspectorWindows size equals: 1.
	self assert: (window at: #id) equals: 'sig-window-object-1'.
	self assert: (window at: #taskbarLabel) equals: 'Obj 1'.
	self assert: (window at: #label) equals: 'Explorer / Answer'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testNewInspectorWindowForObjectBuildsStructuredRows [
	| window rows |
	window := application
		newInspectorWindowForObject: #(1 2 3)
		label: 'Explorer / Numbers'
		title: 'Numbers'.
	rows := window at: #rows.

	self assert: application inspectorWindows size equals: 1.
	self assert: (window at: #title) equals: 'Numbers'.
	self assert: (window at: #taskbarLabel) equals: 'Numbers'.
	self assert: (window at: #rowsTitle) equals: 'Index / Values'.
	self assert: rows size equals: 3.
	self assert: (rows first includesKey: #object).
	self assert: (rows first at: #key) equals: '1'.
	self assert: (rows first at: #value) equals: '1'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testNewInspectorWindowForClassBuildsStructuredSummaryRows [
	| window rows |
	window := application
		newInspectorWindowForObject: Object
		label: 'Symbols / Object'
		title: 'Object'.
	rows := window at: #rows.

	self assert: (window at: #rowsTitle) equals: 'Class Details'.
	self assert: rows isEmpty not.
	self assert: (rows first at: #key) equals: 'Name'.
	self assert: (rows first includesKey: #object)
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testRenderInspectorContentsUsesInspectableValueLinks [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderInspectorContentsOn:label:rowsTitle:rows:text:) asString.

	self assert: (source includesString: 'inspector-wrap').
	self assert: (source includesString: 'inspector-value-link').
	self assert: (source includesString: 'inspectStructuredInspectorRow:')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testRenderBrowserUsesEditableSourceForm [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderBrowserOn:) asString.

	self assert: (source includesString: 'cb-source-form').
	self assert: (source includesString: 'html textArea').
	self assert: (source includesString: 'cb-source-editor').
	self assert: (source includesString: 'browserCompileSource').
	self assert: (source includesString: 'browserResetSourceDraft')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testHiddenWindowPositionAppendsDisplayNone [
	self
		assert: (application hiddenWindowPosition: 'top: 1rem; left: 2rem;')
		equals: 'top: 1rem; left: 2rem; display: none;'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testSelectingRootAppendsTranscriptEntry [
	application selectRootNamed: #globals.

	self assert: (application transcriptEntries last includesString: 'Showing globals')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testTranscriptStartsWithDesktopReadyEntry [
	self assert: application transcriptEntries size > 0.
	self assert: (application transcriptEntries first includesString: 'Desktop ready')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testInspectorDefaultsArePopulated [
	self assert: application inspectorLabel equals: 'Nothing selected'.
	self assert: application inspectorText size > 0
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testWorkspaceDoItFailureUpdatesDebuggerSnapshot [
	application workspaceSourceText: '1 / 0'.

	application workspaceDoIt.

	self assert: application debuggerSnapshotText size > 0.
	self assert: application debuggerWindows size equals: 1.
	self assert: (application debuggerWindows first at: #id) equals: 'sig-window-debugger-exception-1'.
	self assert: (application debuggerWindows first at: #frames) size > 0.
	self assert: (application debuggerWindows first at: #canRestart).
	self assert: (application debuggerWindows first at: #canStepInto).
	self assert: (application debuggerWindows first at: #canStepOver).
	self assert: (application debuggerWindows first at: #canStepOut).
	self assert: (application debuggerWindows first at: #selectedFrameLevel) notNil.
	self assert: application consumePendingWindowIdToShow equals: 'sig-window-debugger-exception-1'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testWorkspaceDebugItFailureShowsBaseDebuggerWindow [
	application workspaceSourceText: '1 / 0'.

	application workspaceDebugIt.

	self assert: application debuggerSnapshotText size > 0.
	self assert: (application debuggerState at: #debugSessionId) notNil.
	self assert: (application debuggerState at: #frames) size > 0.
	self assert: (application debuggerState at: #canRestart).
	self assert: (application debuggerState at: #canStepInto).
	self assert: application consumePendingWindowIdToShow equals: 'sig-window-debugger'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testWorkspaceInspectItShowsInspectorWindow [
	application workspaceSourceText: '1 + 2'.

	application workspaceInspectIt.

	self assert: application inspectorLabel equals: 'Workspace result'.
	self assert: (application inspectorText includesString: 'Class: SmallInteger').
	self assert: application consumePendingWindowIdToShow equals: 'sig-window-inspector'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testBaseInspectorWindowPositionIsVisibleWhenRequested [
	application requestWindowShow: 'sig-window-inspector'.

	self
		assert: application baseInspectorWindowPosition
		equals: 'top: 18rem; left: 48rem; width: 28rem; height: 23rem;'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testWorkspacePrintItUsesPrintedResult [
	application workspaceSourceText: '1 + 2'.

	application workspacePrintIt.

	self assert: application workspaceResultText equals: '=> 3'.
	self assert: (application transcriptEntries last includesString: 'Workspace print it')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testApplyDebuggerSnapshotReplacesNilGatewayText [
	| snapshot state |
	state := application
		newDebuggerStateWithWalkback: 'existing walkback'
		errorText: 'existing error'
		gatewayWalkback: 'existing gateway walkback'
		frames: #().
	snapshot := Dictionary new
		at: #walkback put: 'updated walkback';
		at: #errorText put: nil;
		at: #gatewayWalkback put: nil;
		at: #frames put: #();
		at: #sessionStatusText put: nil;
		yourself.

	application applyDebuggerSnapshot: snapshot toState: state.

	self assert: (state at: #walkback) equals: 'updated walkback'.
	self assert: (state at: #errorText) equals: 'No gateway errors recorded.'.
	self assert: (state at: #gatewayWalkback) equals: 'No gateway walkback recorded.'.
	self assert: (state at: #sessionStatusText) equals: 'No live debug process attached.'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSelectionCommandsRespectBridgeFiltering [
	| state |
	state := Dictionary new.
	state
		at: #walkback put: 'walkback';
		at: #errorText put: 'error';
		at: #gatewayWalkback put: 'gateway walkback';
		at: #frames put: {
			(Dictionary new
				at: #level put: 1;
				at: #description put: 'Frame one';
				at: #isBridge put: false;
				at: #text put: 'Frame one';
				yourself).
			(Dictionary new
				at: #level put: 2;
				at: #description put: 'Frame two';
				at: #isBridge put: true;
				at: #text put: 'Frame two';
				yourself).
			(Dictionary new
				at: #level put: 3;
				at: #description put: 'Frame three';
				at: #isBridge put: false;
				at: #text put: 'Frame three';
				yourself) };
		at: #showBridgeFrames put: false;
		at: #selectedFrameLevel put: nil.

	application ensureDebuggerSelectionInState: state.
	self assert: (application debuggerVisibleFramesInState: state) size equals: 2.
	self assert: (state at: #selectedFrameLevel) equals: 1.

	application moveDebuggerSelectionInState: state offset: 1 includeBridge: false.
	self assert: (state at: #selectedFrameLevel) equals: 3.

	application showDebuggerFramesInState: state includeBridge: true.
	self assert: (application debuggerVisibleFramesInState: state) size equals: 3.

	application moveDebuggerSelectionInState: state offset: -1 includeBridge: true.
	self assert: (state at: #selectedFrameLevel) equals: 2
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testWorkspaceRenderUsesClassicButtons [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderWorkspaceOn:) asString.

	self assert: (source includesString: 'with: ''Do it''').
	self assert: (source includesString: 'with: ''Print it''').
	self assert: (source includesString: 'with: ''Inspect it''').
	self assert: (source includesString: 'with: ''Debug it''')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSourceHelpersUseSelectedFrameSource [
	| frame |
	frame := Dictionary new
		at: #level put: 1;
		at: #description put: 'Object >> printString';
		at: #lineNumber put: 2;
		at: #sourceFile put: '/tmp/Object.st';
		at: #sourceLineNumber put: 19;
		at: #sourceText put: 'line one', String lf, 'line two';
		yourself.

	self assert: (application debuggerFrameSourceLineNumberFor: frame) equals: 2.
	self assert: (application debuggerFrameSourceStatusTextFor: frame) equals: 'Object >> printString at line 2 from /tmp/Object.st:19'.
	self assert: (application debuggerSourceLinesFor: (frame at: #sourceText)) size equals: 2
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSourceLineNumberUsesCursorLocationWhenFrameLineIsStale [
	| frame |
	frame := Dictionary new
		at: #level put: 1;
		at: #description put: 'Executed code';
		at: #lineNumber put: 7;
		at: #quickStepPoint put: 4;
		at: #sourceOffsets put: #(1 1 6 11);
		at: #sourceText put: '1+1.', String lf, '3*3.', String lf, '1/0';
		yourself.

	self assert: (application debuggerFrameSourceLineNumberFor: frame) equals: 3.
	self assert: (application debuggerFrameExecutedCodeLabelFor: frame) equals: 'Executed code @4 line 3'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerRenderUsesPythonStyleTabsAndCursorShell [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderDebuggerContentsOn:state:) asString.

	self assert: (source includesString: 'Stack Trace').
	self assert: (source includesString: 'Thread Local Storage').
	self assert: (source includesString: 'data-sig-tab-panel').
	self assert: (source includesString: 'renderDebuggerLiveCommandsOn: html state: aState').
	self assert: (source includesString: 'renderDebuggerDiagnosticsOn: html state: aState')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSourceRendererUsesInlineCursorClasses [
	| renderSource renderText |
	renderSource := (SigExplorerApplication sourceCodeAt: #renderDebuggerSourceOn:frame:) asString.
	renderText := (SigExplorerApplication sourceCodeAt: #renderDebuggerSourceTextOn:line:cursorColumn:) asString.

	self assert: (renderSource includesString: 'dbg-step-cursor').
	self assert: (renderSource includesString: 'dbg-source-lno').
	self assert: (renderSource includesString: 'debuggerResolvedSourceLocationFor:').
	self assert: (renderSource includesString: 'debuggerSourceLineRecordsFor: aFrame').
	self assert: (renderText includesString: 'dbg-inline-cursor')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerDefaultCursorColumnUsesFirstVisibleCharacter [
	self assert: (application debuggerDefaultCursorColumnForLine: '   "comment" 1/0') equals: 14.
	self assert: (application debuggerDefaultCursorColumnForLine: '   "comment only"   ') equals: nil.
	self assert: (application debuggerDefaultCursorColumnForLine: '') equals: nil
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSourceLineNumberKeepsCommentsAndBlankLinesButHighlightsExecutableStep [
	| frame |
	frame := Dictionary new
		at: #level put: 1;
		at: #description put: 'Executed code';
		at: #lineNumber put: 1;
		at: #quickStepPoint put: 4;
		at: #sourceText put: '"comment"', String lf, '', String lf, '1/0';
		yourself.

	self assert: (application debuggerFrameSourceLineNumberFor: frame) equals: 3.
	self assert: (application debuggerResolvedSourceLocationFor: frame) equals: #(3 1)
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSourceLineRecordsRetainCommentOnlyAndBlankExecutedLines [
	| frame records |
	frame := Dictionary new
		at: #level put: 1;
		at: #description put: 'Executed code';
		at: #lineNumber put: 1;
		at: #quickStepPoint put: 4;
		at: #sourceText put: '"comment"', String lf, '1 + 2.', String lf, '', String lf, '1/0';
		yourself.
	records := application debuggerSourceLineRecordsFor: frame.

	self assert: records equals: #((1 '"comment"') (2 '1 + 2.') (3 '') (4 '1/0'))
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSourceStatusUsesExecutedCodeLabel [
	| frame |
	frame := Dictionary new
		at: #className put: 'SigWorkspaceEvaluator';
		at: #selectorName put: 'sigWorkspaceABC123';
		at: #description put: '[] in SigWorkspaceEvaluator >> sigWorkspaceABC123';
		at: #quickStepPoint put: 3;
		at: #lineNumber put: 2;
		at: #sourceText put: '1+1.', String lf, '1/0';
		yourself.

	self assert: (application debuggerFrameSourceStatusTextFor: frame) equals: 'Executed code @3 line 2'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSourceCursorLocationUsesStepOffsetInsideCommentLine [
	| frame |
	frame := Dictionary new
		at: #sourceText put: '"comment" 1/0';
		at: #sourceOffsets put: #(11);
		at: #quickStepPoint put: 1;
		yourself.

	self assert: (application debuggerFrameSourceCursorLocationFor: frame) equals: #(1 11)
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerExecutedCodeAdvancesVisibleStepToNextExecutableLineWhenOffsetsRepeatOnSameLine [
	| frame |
	frame := Dictionary new
		at: #className put: 'SigWorkspaceEvaluator';
		at: #selectorName put: 'sigWorkspaceABC123';
		at: #description put: '[] in SigWorkspaceEvaluator >> sigWorkspaceABC123';
		at: #quickStepPoint put: 2;
		at: #sourceOffsets put: #(1 3 10 16);
		at: #sourceText put: '1 + 2.', String lf, '', String lf, '1+1.', String lf, '', String lf, '1/0';
		yourself.

	self assert: (application debuggerFrameSourceCursorLocationFor: frame) equals: #(3 1).
	self assert: (application debuggerFrameSourceLineNumberFor: frame) equals: 3.
	self assert: (application debuggerFrameExecutedCodeLabelFor: frame) equals: 'Executed code @2 line 3'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerExecutedCodeKeepsSecondStatementOnSameLineVisible [
	| frame |
	frame := Dictionary new
		at: #className put: 'SigWorkspaceEvaluator';
		at: #selectorName put: 'sigWorkspaceABC123';
		at: #description put: '[] in SigWorkspaceEvaluator >> sigWorkspaceABC123';
		at: #quickStepPoint put: 4;
		at: #sourceOffsets put: #(1 3 9 14 20);
		at: #sourceText put: '1 + 2.', String lf, '', String lf, '1/1. 4*4.', String lf, '', String lf, '1/0';
		yourself.

	self assert: (application debuggerFrameSourceCursorLocationFor: frame) equals: #(3 6).
	self assert: (application debuggerFrameSourceLineNumberFor: frame) equals: 3.
	self assert: (application debuggerFrameExecutedCodeLabelFor: frame) equals: 'Executed code @4 line 3'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerScrollKeysUseWindowId [
	| exceptionState |
	exceptionState := Dictionary new
		at: #id put: 'sig-window-debugger-exception-3';
		yourself.

	self assert: (application debuggerFrameListScrollKeyForState: application debuggerState) equals: 'sig-window-debugger/frames'.
	self assert: (application debuggerSourceScrollKeyForState: application debuggerState) equals: 'sig-window-debugger/source'.
	self assert: (application debuggerFrameListScrollKeyForState: exceptionState) equals: 'sig-window-debugger-exception-3/frames'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSelectionPrefersExecutedCodeFrame [
	| state |
	state := Dictionary new.
	state
		at: #frames put: {
			(Dictionary new
				at: #level put: 9;
				at: #description put: 'Number >> _errorDivideByZero';
				at: #isErrorContext put: true;
				at: #isInfrastructure put: false;
				at: #selectorName put: '_errorDivideByZero';
				at: #sourceText put: '_errorDivideByZero';
				at: #text put: 'error';
				yourself).
			(Dictionary new
				at: #level put: 11;
				at: #className put: 'SigWorkspaceEvaluator';
				at: #description put: '[] in SigWorkspaceEvaluator >> sigWorkspaceABC123';
				at: #isInfrastructure put: false;
				at: #selectorName put: 'sigWorkspaceABC123';
				at: #quickStepPoint put: 3;
				at: #lineNumber put: 2;
				at: #sourceText put: '1+1.', String lf, '1/0';
				at: #text put: 'workspace';
				yourself) };
		at: #showBridgeFrames put: false;
		at: #selectedFrameLevel put: nil.

	application ensureDebuggerSelectionInState: state.

	self assert: (state at: #selectedFrameLevel) equals: 11
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSummaryUsesExecutedCodeLabel [
	| frame |
	frame := Dictionary new
		at: #className put: 'SigWorkspaceEvaluator';
		at: #selectorName put: 'sigWorkspaceABC123';
		at: #description put: '[] in SigWorkspaceEvaluator >> sigWorkspaceABC123';
		at: #quickStepPoint put: 3;
		at: #lineNumber put: 2;
		at: #sourceText put: '1+1.', String lf, '1/0';
		yourself.

	self assert: (application debuggerFrameSummaryFor: frame) equals: 'Executed code @3 line 2'
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSourcePaneFollowsCurrentLine [
	| detailsSource sourceSource |
	detailsSource := (SigExplorerApplication sourceCodeAt: #renderDebuggerFrameDetailsOn:state: ) asString.
	sourceSource := (SigExplorerApplication sourceCodeAt: #renderDebuggerSourceOn:frame: ) asString.

	self assert: (detailsSource includesString: 'data-sig-scroll-follow').
	self assert: (detailsSource includesString: 'put: ''selected''').
	self assert: (sourceSource includesString: 'dbg-source-line sig-debugger-source-line current selected active').
	self assert: (sourceSource includesString: 'renderDebuggerSourceTextOn: html').
	self assert: ((SigExplorerApplication sourceCodeAt: #renderDebuggerSourceTextOn:line:cursorColumn: ) asString includesString: 'dbg-inline-cursor')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testApplyDebuggerSnapshotPreservesWindowMetadata [
	| snapshot state |
	state := Dictionary new
		at: #id put: 'sig-window-debugger-exception-4';
		at: #title put: 'Debugger 4';
		at: #showBridgeFrames put: false;
		at: #selectedFrameLevel put: 99;
		yourself.
	snapshot := Dictionary new
		at: #walkback put: 'walkback';
		at: #errorText put: 'ZeroDivide';
		at: #gatewayWalkback put: 'gateway walkback';
		at: #frames put: {
			(Dictionary new
				at: #level put: 7;
				at: #description put: 'SmallInteger >> /';
				at: #isInfrastructure put: false;
				at: #text put: 'frame';
				yourself) };
		at: #debugSessionId put: 12;
		at: #isLiveSession put: true;
		at: #sessionStatusText put: 'Debug process suspended.';
		at: #canProceed put: true;
		at: #canRestart put: true;
		at: #canStepInto put: true;
		at: #canStepOver put: true;
		at: #canStepOut put: true;
		at: #canTerminate put: true;
		yourself.

	application applyDebuggerSnapshot: snapshot toState: state.

	self assert: (state at: #id) equals: 'sig-window-debugger-exception-4'.
	self assert: (state at: #title) equals: 'Debugger 4'.
	self assert: (state at: #debugSessionId) equals: 12.
	self assert: (state at: #canProceed).
	self assert: (state at: #selectedFrameLevel) equals: 7
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSelectionPrefersNonInfrastructureFrame [
	| state |
	state := Dictionary new.
	state
		at: #frames put: {
			(Dictionary new
				at: #level put: 1;
				at: #description put: 'GsProcess >> suspend';
				at: #isInfrastructure put: true;
				at: #text put: 'internal';
				yourself).
			(Dictionary new
				at: #level put: 2;
				at: #description put: 'SmallInteger >> /';
				at: #isInfrastructure put: false;
				at: #text put: 'user';
				yourself) };
		at: #showBridgeFrames put: false;
		at: #selectedFrameLevel put: nil.

	application ensureDebuggerSelectionInState: state.

	self assert: (state at: #selectedFrameLevel) equals: 2
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerSelectionPrefersExplicitErrorFrame [
	| state |
	state := Dictionary new.
	state
		at: #frames put: {
			(Dictionary new
				at: #level put: 2;
				at: #description put: 'SmallInteger >> /';
				at: #isInfrastructure put: false;
				at: #selectorName put: '/';
				at: #text put: 'user';
				yourself).
			(Dictionary new
				at: #level put: 3;
				at: #description put: 'Number >> _errorDivideByZero';
				at: #isErrorContext put: true;
				at: #isInfrastructure put: false;
				at: #selectorName put: '_errorDivideByZero';
				at: #text put: 'error';
				yourself) };
		at: #showBridgeFrames put: false;
		at: #selectedFrameLevel put: nil.

	application ensureDebuggerSelectionInState: state.

	self assert: (state at: #selectedFrameLevel) equals: 3
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerLayoutPlacesStackBeforeControlsAndSource [
	| diagnosticsIndex liveControlsIndex source sourceIndex stackIndex |
	source := (SigExplorerApplication sourceCodeAt: #renderDebuggerContentsOn:state: ) asString.

	self assert: (source includesString: 'sig-debugger-shell').
	self assert: (source includesString: 'data-sig-tab-panel').
	stackIndex := source findString: 'self renderDebuggerFramesOn: html state: aState' startingAt: 1.
	liveControlsIndex := source findString: 'self renderDebuggerLiveCommandsOn: html state: aState' startingAt: 1.
	sourceIndex := source findString: 'self renderDebuggerFrameDetailsOn: html state: aState' startingAt: 1.
	diagnosticsIndex := source findString: 'self renderDebuggerDiagnosticsOn: html state: aState' startingAt: 1.

	self assert: stackIndex > 0.
	self assert: liveControlsIndex > 0.
	self assert: sourceIndex > 0.
	self assert: diagnosticsIndex > 0.
	self assert: stackIndex < liveControlsIndex.
	self assert: liveControlsIndex < sourceIndex.
	self assert: sourceIndex < diagnosticsIndex
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDesktopScriptSupportsRemoteDesktopUpdates [
	| script |
	script := application desktopScript.

	self assert: (script includesString: 'a[data-sig-remote]').
	self assert: (script includesString: 'form[data-sig-remote]').
	self assert: (script includesString: 'fetch(url').
	self assert: (script includesString: 'DOMParser').
	self assert: (script includesString: 'data-sig-scroll-key').
	self assert: (script includesString: 'saveScrollPanes()').
	self assert: (script includesString: 'sigDesktopState:v4:').
	self assert: (script includesString: 'if (current && !replacement) {').
	self assert: (script includesString: 'sig-window-maximized').
	self assert: (script includesString: 'runtime.newlyVisibleWindowIds').
	self assert: (script includesString: 'scrollIntoView({ block: ''nearest'' })')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerStylesAllowWholeTabPanelScrolling [
	| style |
	style := application stylesheet.

	self assert: (style includesString: '.sig-debugger-shell').
	self assert: (style includesString: '.sig-debugger-tab-panel').
	self assert: (style includesString: 'overflow-y: scroll;').
	self assert: (style includesString: '.sig-floating-window').
	self assert: (style includesString: 'scrollbar-gutter: stable both-edges;')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testDebuggerStylesLimitVisibleStackRowsToTen [
	| style |
	style := application stylesheet.

	self assert: (style includesString: '.sig-debugger-frame-list').
	self assert: (style includesString: 'max-height: 196px;').
	self assert: (style includesString: 'height: 196px;')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testStylesheetIncludesElegantSharedWindowChrome [
	| style |
	style := application stylesheet.

	self assert: (style includesString: '.sig-floating-window::before').
	self assert: (style includesString: '.sig-action,').
	self assert: (style includesString: '.sig-local-command').
	self assert: (style includesString: '.sig-window-body input[type="text"]').
	self assert: (style includesString: '.sig-sidebar > h3').
	self assert: (style includesString: '.sig-workspace-shell').
	self assert: (style includesString: '.cb-wrap').
	self assert: (style includesString: '.cb-source-form').
	self assert: (style includesString: '.cb-source-editor')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testSynchronizeBaseDebuggerStateFromCopiesLiveDebuggerControls [
	| state |
	state := Dictionary new
		at: #walkback put: 'walkback';
		at: #errorText put: 'ZeroDivide';
		at: #gatewayWalkback put: 'gateway walkback';
		at: #frames put: {
			(Dictionary new
				at: #level put: 3;
				at: #description put: 'Executed code @1 line 1';
				at: #text put: 'frame text';
				yourself) };
		at: #debugSessionId put: 17;
		at: #isLiveSession put: true;
		at: #sessionStatusText put: 'Debug process suspended.';
		at: #canProceed put: true;
		at: #canRestart put: true;
		at: #canStepInto put: true;
		at: #canStepOver put: true;
		at: #canStepOut put: true;
		at: #canTerminate put: true;
		at: #showBridgeFrames put: true;
		at: #selectedFrameLevel put: 3;
		yourself.

	application synchronizeBaseDebuggerStateFrom: state.

	self assert: (application debuggerState at: #debugSessionId) equals: 17.
	self assert: (application debuggerState at: #canRestart).
	self assert: (application debuggerState at: #canStepOver).
	self assert: (application debuggerState at: #showBridgeFrames).
	self assert: (application debuggerState at: #selectedFrameLevel) equals: 3
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testRenderContentDoesNotIncludeTopMenuBar [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderContentOn:) asString.

	self deny: (source includesString: 'self renderMenuBarOn: html.').
	self assert: (source includesString: 'renderInspectorWindowsOn: desktop')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testRenderTaskBarIncludesBottomMenus [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderTaskBarOn:) asString.

	self assert: (source includesString: 'sig-taskbar-strip-menus').
	self assert: (source includesString: 'label: ''Close All''').
	self assert: (source includesString: 'label: ''Windows''').
	self assert: (source includesString: 'label: ''Arrange''').
	self assert: (source includesString: 'label: ''Session''').
	self assert: (source includesString: 'label: ''Workspace''')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testRenderArrangeMenuIncludesCloseAllWindows [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderArrangeMenuItemsOn:) asString.

	self assert: (source includesString: 'label: ''Close All Windows''').
	self assert: (source includesString: 'action: ''close-all''')
]

{ #category : 'tests' }
SigExplorerApplicationTest >> testRenderFloatingWindowUsesMacStyleWindowControls [
	| source |
	source := (SigExplorerApplication sourceCodeAt: #renderFloatingWindowOn:id:title:subtitle:position:with:) asString.

	self assert: (source includesString: 'sig-window-control close').
	self assert: (source includesString: 'sig-window-control collapse').
	self assert: (source includesString: 'sig-window-control expand').
	self assert: (source includesString: 'data-sig-window-action').
	self assert: (source includesString: 'Minimise window').
	self assert: (source includesString: 'aSubtitle isEmpty ifFalse:')
]
