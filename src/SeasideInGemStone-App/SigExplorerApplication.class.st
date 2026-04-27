Class {
	#name : 'SigExplorerApplication',
	#superclass : 'WAComponent',
	#instVars : [
		'gateway',
		'selectedRootName',
		'selectedEntryKey',
		'statusMessage',
		'selectedBrowserDictionaryName',
		'selectedBrowserClassName',
		'selectedBrowserProtocolName',
		'selectedBrowserSelector',
		'selectedSymbolListDictionaryName',
		'selectedSymbolListEntryKey',
		'debuggerSnapshotText',
		'debuggerState',
		'workspaceSourceText',
		'workspaceResultText',
		'transcriptEntries',
		'inspectorLabel',
		'inspectorText',
		'pendingWindowIdToShow',
		'debuggerWindows',
		'nextDebuggerWindowNumber'
	],
	#category : 'SeasideInGemStone-App',
	#package : 'SeasideInGemStone-App'
}

{ #category : 'testing' }
SigExplorerApplication class >> canBeRoot [
	^ true
]

{ #category : 'accessing' }
SigExplorerApplication class >> applicationPath [
	^ 'sig'
]

{ #category : 'registration' }
SigExplorerApplication class >> register [
	<applicationName>
	^ 'SeasideInGemStone'
]

{ #category : 'registration' }
SigExplorerApplication class >> initializeApplication [
	| application |
	WAAdmin unregister: self applicationPath.
	application := WAAdmin register: self asApplicationAt: self applicationPath.
	application preferenceAt: #trackingStrategy put: WACookieIfSupportedSessionTrackingStrategy new
]

{ #category : 'actions' }
SigExplorerApplication >> abortTransaction [
	(self gateway abortTransaction)
		ifTrue: [ self setStatusMessage: 'GemStone transaction aborted' ]
		ifFalse: [ self setStatusMessage: 'GemStone abort did not succeed' ].
	self refreshBaseDebuggerStateFromGateway
]

{ #category : 'querying' }
SigExplorerApplication >> browserClassAssociations [
	^ self gateway classAssociationsForDictionaryNamed: selectedBrowserDictionaryName
]

{ #category : 'querying' }
SigExplorerApplication >> browserDictionaryNames [
	^ self gateway browserDictionaryNames
]

{ #category : 'querying' }
SigExplorerApplication >> browserProtocolNames [
	selectedBrowserClassName ifNil: [ ^ #() ].
	^ self gateway
		protocolNamesForClassNamed: selectedBrowserClassName
		inDictionaryNamed: selectedBrowserDictionaryName
]

{ #category : 'querying' }
SigExplorerApplication >> browserSelectorNames [
	(selectedBrowserClassName isNil or: [ selectedBrowserProtocolName isNil ]) ifTrue: [ ^ #() ].
	^ self gateway
		selectorsForClassNamed: selectedBrowserClassName
		protocolNamed: selectedBrowserProtocolName
		inDictionaryNamed: selectedBrowserDictionaryName
]

{ #category : 'querying' }
SigExplorerApplication >> browserSourceText [
	^ self gateway
		methodSourceForClassNamed: selectedBrowserClassName
		selectorNamed: selectedBrowserSelector
		inDictionaryNamed: selectedBrowserDictionaryName
]

{ #category : 'querying' }
SigExplorerApplication >> browserSourceHeadingText [
	selectedBrowserClassName ifNil: [ ^ 'Select a class to start browsing.' ].
	selectedBrowserSelector isNil ifTrue: [ ^ selectedBrowserClassName, ' is selected.' ].
	^ selectedBrowserClassName, ' >> ', selectedBrowserSelector
]

{ #category : 'actions' }
SigExplorerApplication >> captureDebuggerSnapshot [
	self refreshBaseDebuggerStateFromGateway.
	self requestWindowShow: 'sig-window-debugger'.
	self setStatusMessage: 'Captured GemStone walkback'
]

{ #category : 'private' }
SigExplorerApplication >> debuggerBridgeStatusTextForState: aState [
	^ (aState at: #showBridgeFrames ifAbsent: [ false ])
		ifTrue: [ 'Bridge frames visible.' ]
		ifFalse: [ 'Bridge frames hidden.' ]
]

{ #category : 'private' }
SigExplorerApplication >> applyDebuggerSnapshot: aSnapshot toState: aState [
	| selectedFrameLevel showBridgeFrames |
	aSnapshot ifNil: [ ^ self ].
	showBridgeFrames := aState at: #showBridgeFrames ifAbsent: [ false ].
	selectedFrameLevel := aState at: #selectedFrameLevel ifAbsent: [ nil ].
	aState
		at: #walkback
		put: ((aSnapshot at: #walkback ifAbsent: [ nil ])
			ifNil: [ 'No debugger snapshot captured yet.' ]).
	aState
		at: #errorText
		put: ((aSnapshot at: #errorText ifAbsent: [ nil ])
			ifNil: [ 'No gateway errors recorded.' ]).
	aState
		at: #gatewayWalkback
		put: ((aSnapshot at: #gatewayWalkback ifAbsent: [ nil ])
			ifNil: [ 'No gateway walkback recorded.' ]).
	aState
		at: #frames
		put: ((aSnapshot at: #frames ifAbsent: [ nil ])
			ifNil: [ #() ]).
	aState at: #debugSessionId put: (aSnapshot at: #debugSessionId ifAbsent: [ nil ]).
	aState at: #isLiveSession put: (aSnapshot at: #isLiveSession ifAbsent: [ false ]).
	aState
		at: #sessionStatusText
		put: ((aSnapshot at: #sessionStatusText ifAbsent: [ nil ])
			ifNil: [ 'No live debug process attached.' ]).
	aState at: #resultText put: (aSnapshot at: #resultText ifAbsent: [ nil ]).
	aState at: #canProceed put: (aSnapshot at: #canProceed ifAbsent: [ false ]).
	aState at: #canRestart put: (aSnapshot at: #canRestart ifAbsent: [ false ]).
	aState at: #canStepInto put: (aSnapshot at: #canStepInto ifAbsent: [ false ]).
	aState at: #canStepOver put: (aSnapshot at: #canStepOver ifAbsent: [ false ]).
	aState at: #canStepOut put: (aSnapshot at: #canStepOut ifAbsent: [ false ]).
	aState at: #canTerminate put: (aSnapshot at: #canTerminate ifAbsent: [ false ]).
	aState at: #showBridgeFrames put: showBridgeFrames.
	aState at: #selectedFrameLevel put: selectedFrameLevel.
	self ensureDebuggerSelectionInState: aState
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameDetailTextFor: aFrame [
	aFrame ifNil: [ ^ 'Select a context frame to inspect it.' ].
	^ aFrame at: #text ifAbsent: [ aFrame at: #description ifAbsent: [ 'Unknown frame' ] ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameListScrollKeyForState: aState [
	^ (self debuggerScrollKeyPrefixForState: aState), '/frames'
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameSourceLineNumberFor: aFrame [
	| lineCount lineNumber sourceLineNumber sourceText |
	aFrame ifNil: [ ^ nil ].
	sourceText := aFrame at: #sourceText ifAbsent: [ nil ].
	lineCount := (self debuggerSourceLinesFor: sourceText) size.
	lineNumber := aFrame at: #lineNumber ifAbsent: [ nil ].
	(lineNumber notNil and: [ lineNumber between: 1 and: lineCount ])
		ifTrue: [ ^ lineNumber ].
	sourceLineNumber := aFrame at: #sourceLineNumber ifAbsent: [ nil ].
	(sourceLineNumber notNil and: [ sourceLineNumber between: 1 and: lineCount ])
		ifTrue: [ ^ sourceLineNumber ].
	^ nil
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameSourceStatusTextFor: aFrame [
	| description lineNumber sourceFile sourceLineNumber stream |
	aFrame ifNil: [ ^ 'Select a context frame from the stack to inspect its source.' ].
	(self debuggerFrameIsExecutedCode: aFrame) ifTrue: [
		^ self debuggerFrameExecutedCodeLabelFor: aFrame ].
	description := aFrame at: #description ifAbsent: [ 'Unknown frame' ].
	lineNumber := self debuggerFrameSourceLineNumberFor: aFrame.
	sourceFile := aFrame at: #sourceFile ifAbsent: [ nil ].
	sourceLineNumber := aFrame at: #sourceLineNumber ifAbsent: [ nil ].
	stream := WriteStream on: String new.
	stream nextPutAll: description.
	lineNumber ifNotNil: [
		stream
			nextPutAll: ' at line ';
			nextPutAll: lineNumber printString ].
	sourceFile ifNotNil: [
		stream
			nextPutAll: ' from ';
			nextPutAll: sourceFile.
		sourceLineNumber ifNotNil: [
			stream
				nextPutAll: ':';
				nextPutAll: sourceLineNumber printString ] ].
	^ stream contents
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameExecutedCodeLabelFor: aFrame [
	| lineNumber stepPoint stream |
	aFrame ifNil: [ ^ 'Executed code' ].
	stepPoint := aFrame at: #quickStepPoint ifAbsent: [ nil ].
	lineNumber := self debuggerFrameSourceLineNumberFor: aFrame.
	stream := WriteStream on: String new.
	stream nextPutAll: 'Executed code'.
	stepPoint ifNotNil: [
		stream
			nextPutAll: ' @';
			nextPutAll: stepPoint printString ].
	lineNumber ifNotNil: [
		stream
			nextPutAll: ' line ';
			nextPutAll: lineNumber printString ].
	^ stream contents
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameIsExecutedCode: aFrame [
	| className description selectorName sourceText |
	aFrame ifNil: [ ^ false ].
	(aFrame at: #isExecutedCode ifAbsent: [ false ]) ifTrue: [ ^ true ].
	description := (aFrame at: #description ifAbsent: [ '' ]) asString.
	selectorName := (aFrame at: #selectorName ifAbsent: [ '' ]) asString.
	className := (aFrame at: #className ifAbsent: [ '' ]) asString.
	sourceText := aFrame at: #sourceText ifAbsent: [ '' ].
	sourceText := sourceText ifNil: [ '' ] ifNotNil: [ sourceText asString ].
	(description beginsWith: '[] in SigWorkspaceEvaluator >> sigWorkspace')
		ifTrue: [ ^ true ].
	((className = 'SigWorkspaceEvaluator')
		and: [ selectorName beginsWith: 'sigWorkspace' ]) ifFalse: [ ^ false ].
	sourceText isEmpty ifTrue: [ ^ false ].
	(sourceText includesString: '^ [')
		ifTrue: [ ^ false ].
	^ true
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameSourceTextFor: aFrame [
	| sourceText |
	aFrame ifNil: [ ^ 'Select a context frame to inspect its source.' ].
	sourceText := aFrame at: #sourceText ifAbsent: [ nil ].
	(sourceText isNil or: [ sourceText isEmpty ])
		ifTrue: [ ^ 'Source unavailable for this frame.' ].
	^ sourceText
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameReceiverTextFor: aFrame [
	| receiverText |
	aFrame ifNil: [ ^ 'self unavailable' ].
	receiverText := aFrame at: #receiverText ifAbsent: [ nil ].
	^ receiverText
		ifNil: [ 'self unavailable' ]
		ifNotNil: [ receiverText ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameSourceMetaTextFor: aFrame [
	| ipOffset lineNumber quickStepPoint sourceLineNumber stream |
	aFrame ifNil: [ ^ 'Select a frame to see source metadata.' ].
	stream := WriteStream on: String new.
	quickStepPoint := aFrame at: #quickStepPoint ifAbsent: [ nil ].
	lineNumber := self debuggerFrameSourceLineNumberFor: aFrame.
	ipOffset := aFrame at: #ipOffset ifAbsent: [ nil ].
	sourceLineNumber := aFrame at: #sourceLineNumber ifAbsent: [ nil ].
	quickStepPoint ifNotNil: [
		stream
			nextPutAll: 'Step ';
			nextPutAll: quickStepPoint printString ].
	lineNumber ifNotNil: [
		stream position > 0 ifTrue: [ stream nextPutAll: ' | ' ].
		stream
			nextPutAll: 'Line ';
			nextPutAll: lineNumber printString ].
	ipOffset ifNotNil: [
		stream position > 0 ifTrue: [ stream nextPutAll: ' | ' ].
		stream
			nextPutAll: 'PC ';
			nextPutAll: ipOffset printString ].
	sourceLineNumber ifNotNil: [
		stream position > 0 ifTrue: [ stream nextPutAll: ' | ' ].
		stream
			nextPutAll: 'File line ';
			nextPutAll: sourceLineNumber printString ].
	^ stream position = 0
		ifTrue: [ 'Source metadata unavailable.' ]
		ifFalse: [ stream contents ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameVariableRecordsFor: aFrame [
	| records |
	aFrame ifNil: [ ^ #() ].
	records := aFrame at: #variables ifAbsent: [ nil ].
	^ records ifNil: [ #() ] ifNotNil: [ records ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameVariableSummaryTextFor: aFrame [
	| records |
	records := self debuggerFrameVariableRecordsFor: aFrame.
	records isEmpty ifTrue: [ ^ 'No arguments or temporaries reported for this frame.' ].
	^ String streamContents: [ :stream |
		records
			doWithIndex: [ :each :index |
				index > 1 ifTrue: [ stream nextPutAll: ' | ' ].
				stream
					nextPutAll: (each at: #name ifAbsent: [ 'var' ]);
					nextPutAll: ' = ';
					nextPutAll: (each at: #value ifAbsent: [ 'nil' ]) ] ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameSummaryFor: aFrame [
	| lineNumber stream |
	(self debuggerFrameIsExecutedCode: aFrame) ifTrue: [
		^ self debuggerFrameExecutedCodeLabelFor: aFrame ].
	stream := WriteStream on: String new.
	stream nextPutAll: (aFrame at: #description ifAbsent: [ 'Unknown frame' ]).
	lineNumber := aFrame at: #lineNumber ifAbsent: [ nil ].
	lineNumber ifNotNil: [
		stream
			nextPutAll: ' (line ';
			nextPutAll: lineNumber printString;
			nextPutAll: ')' ].
	(aFrame at: #isBridge ifAbsent: [ false ]) ifTrue: [
		stream nextPutAll: ' [bridge]' ].
	(aFrame at: #isInfrastructure ifAbsent: [ false ]) ifTrue: [
		stream nextPutAll: ' [internal]' ].
	^ stream contents
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFramesInState: aState [
	^ aState at: #frames ifAbsent: [ #() ]
]

{ #category : 'accessing' }
SigExplorerApplication >> debuggerGatewayStatusTextForState: aState [
	| errorText gatewayWalkback stream |
	errorText := (aState at: #errorText ifAbsent: [ nil ])
		ifNil: [ 'No gateway errors recorded.' ].
	gatewayWalkback := (aState at: #gatewayWalkback ifAbsent: [ nil ])
		ifNil: [ 'No gateway walkback recorded.' ].
	stream := WriteStream on: String new.
	stream nextPutAll: errorText.
	((gatewayWalkback isNil or: [ gatewayWalkback = 'No gateway walkback recorded.' ])
		or: [ gatewayWalkback = errorText ]) ifFalse: [
		stream
			cr;
			cr;
			nextPutAll: gatewayWalkback ].
	^ stream contents
]

{ #category : 'accessing' }
SigExplorerApplication >> debuggerState [
	^ debuggerState ifNil: [
		debuggerState := self
			newDebuggerStateWithWalkback: 'No debugger snapshot captured yet.'
				errorText: 'No gateway errors recorded.'
				gatewayWalkback: 'No gateway walkback recorded.'
				frames: #() ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerSessionStatusTextForState: aState [
	^ aState
		at: #sessionStatusText
		ifAbsent: [
			(aState at: #debugSessionId ifAbsent: [ nil ])
				ifNil: [ 'No live debug process attached.' ]
				ifNotNil: [ 'Debugger session available.' ] ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerVisibleFramesInState: aState [
	| frames |
	frames := self debuggerFramesInState: aState.
	(aState at: #showBridgeFrames ifAbsent: [ false ]) ifTrue: [ ^ frames ].
	^ frames reject: [ :each | each at: #isBridge ifAbsent: [ false ] ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerSourceLinesFor: aString [
	| lines text |
	text := aString ifNil: [ '' ].
	text isEmpty ifTrue: [ ^ #('') ].
	lines := OrderedCollection new.
	text lineIndicesDo: [ :start :endWithoutDelimiters :end |
		lines add: (text copyFrom: start to: endWithoutDelimiters) ].
	^ lines isEmpty
		ifTrue: [ #('') ]
		ifFalse: [ lines asArray ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerScrollKeyPrefixForState: aState [
	^ aState at: #id ifAbsent: [ 'sig-window-debugger' ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerSourceScrollKeyForState: aState [
	^ (self debuggerScrollKeyPrefixForState: aState), '/source'
]

{ #category : 'private' }
SigExplorerApplication >> ensureDebuggerSelectionInState: aState [
	| selectedFrameLevel visibleFrames |
	visibleFrames := self debuggerVisibleFramesInState: aState.
	visibleFrames isEmpty ifTrue: [
		aState at: #selectedFrameLevel put: nil.
		^ self ].
	selectedFrameLevel := aState at: #selectedFrameLevel ifAbsent: [ nil ].
	(visibleFrames anySatisfy: [ :each | (each at: #level ifAbsent: [ 0 ]) = selectedFrameLevel ])
		ifFalse: [ aState at: #selectedFrameLevel put: (self preferredDebuggerFrameLevelIn: visibleFrames) ]
]

{ #category : 'private' }
SigExplorerApplication >> addTranscriptLine: aString [
	| text |
	text := aString ifNil: [ '(no message)' ].
	transcriptEntries ifNil: [ transcriptEntries := OrderedCollection new ].
	transcriptEntries addLast: ((transcriptEntries size + 1) printString, '. ', text).
	transcriptEntries size > 200 ifTrue: [ transcriptEntries removeFirst ]
]

{ #category : 'actions' }
SigExplorerApplication >> clearTranscript [
	transcriptEntries := OrderedCollection new.
	self setStatusMessage: 'Transcript cleared'
]

{ #category : 'actions' }
SigExplorerApplication >> clearWorkspaceOutput [
	workspaceResultText := 'Workspace output cleared.'.
	self setStatusMessage: 'Workspace output cleared'
]

{ #category : 'actions' }
SigExplorerApplication >> clearInspector [
	inspectorLabel := 'Nothing selected'.
	inspectorText := 'Select an explorer entry, a symbol binding, or use Workspace Inspect to inspect a live object.'
]

{ #category : 'hooks' }
SigExplorerApplication >> children [
	^ #()
]

{ #category : 'actions' }
SigExplorerApplication >> commitTransaction [
	(self gateway commitTransactionOrSignalConflict)
		ifTrue: [ self setStatusMessage: 'GemStone commit succeeded' ]
		ifFalse: [ self setStatusMessage: 'GemStone commit did not succeed' ].
	self refreshBaseDebuggerStateFromGateway
]

{ #category : 'actions' }
SigExplorerApplication >> continueTransaction [
	self refreshBaseDebuggerStateFromGateway.
	self setStatusMessage: 'GemStone transaction continues'
]

{ #category : 'private' }
SigExplorerApplication >> consumePendingWindowIdToShow [
	| windowId |
	windowId := pendingWindowIdToShow.
	pendingWindowIdToShow := nil.
	^ windowId
]

{ #category : 'accessing' }
SigExplorerApplication >> debuggerSnapshotText [
	^ debuggerSnapshotText
]

{ #category : 'accessing' }
SigExplorerApplication >> debuggerWindows [
	^ debuggerWindows
]

{ #category : 'private' }
SigExplorerApplication >> moveDebuggerSelectionInState: aState offset: anInteger includeBridge: aBoolean [
	| currentIndex nextIndex selectedFrameLevel visibleFrames |
	aState at: #showBridgeFrames put: aBoolean.
	self ensureDebuggerSelectionInState: aState.
	visibleFrames := self debuggerVisibleFramesInState: aState.
	visibleFrames isEmpty ifTrue: [ ^ self ].
	selectedFrameLevel := aState at: #selectedFrameLevel ifAbsent: [ visibleFrames first at: #level ].
	currentIndex := visibleFrames findFirst: [ :each | (each at: #level ifAbsent: [ 0 ]) = selectedFrameLevel ].
	currentIndex = 0 ifTrue: [ currentIndex := 1 ].
	nextIndex := currentIndex + anInteger.
	nextIndex < 1 ifTrue: [ nextIndex := 1 ].
	nextIndex > visibleFrames size ifTrue: [ nextIndex := visibleFrames size ].
	aState at: #selectedFrameLevel put: ((visibleFrames at: nextIndex) at: #level)
]

{ #category : 'private' }
SigExplorerApplication >> newDebuggerStateWithWalkback: currentWalkback errorText: errorText gatewayWalkback: gatewayWalkback frames: frames [
	| state |
	state := Dictionary new.
	state at: #walkback put: (currentWalkback ifNil: [ 'No debugger snapshot captured yet.' ]).
	state at: #errorText put: (errorText ifNil: [ 'No gateway errors recorded.' ]).
	state at: #gatewayWalkback put: (gatewayWalkback ifNil: [ 'No gateway walkback recorded.' ]).
	state at: #frames put: (frames ifNil: [ #() ]).
	state at: #debugSessionId put: nil.
	state at: #isLiveSession put: false.
	state at: #sessionStatusText put: 'No live debug process attached.'.
	state at: #resultText put: nil.
	state at: #canProceed put: false.
	state at: #canRestart put: false.
	state at: #canStepInto put: false.
	state at: #canStepOver put: false.
	state at: #canStepOut put: false.
	state at: #canTerminate put: false.
	state at: #showBridgeFrames put: false.
	state at: #selectedFrameLevel put: nil.
	self ensureDebuggerSelectionInState: state.
	^ state
]

{ #category : 'private' }
SigExplorerApplication >> exceptionDebuggerTaskbarLabelForWindowNumber: anInteger [
	^ 'Dbg ', anInteger printString
]

{ #category : 'private' }
SigExplorerApplication >> exceptionDebuggerTitleForWindowNumber: anInteger [
	^ 'Debugger ', anInteger printString
]

{ #category : 'private' }
SigExplorerApplication >> exceptionDebuggerWindowPositionForIndex: anInteger [
	| offset top left |
	offset := (anInteger - 1) \\ 5.
	top := 5 + (offset * 2).
	left := 22 + (offset * 3).
	^ 'top: ', top printString, 'rem; left: ', left printString, 'rem; width: 50rem; height: 40rem;'
]

{ #category : 'private' }
SigExplorerApplication >> newExceptionDebuggerWindowForLastError [
	| errorText gatewayWalkback sessionId snapshot window windowId windowNumber |
	windowNumber := nextDebuggerWindowNumber := nextDebuggerWindowNumber + 1.
	windowId := 'sig-window-debugger-exception-', windowNumber printString.
	errorText := self gateway lastErrorText ifNil: [ 'GemStone exception' ].
	gatewayWalkback := self gateway lastErrorStackText ifNil: [ 'No gateway walkback recorded.' ].
	window := self
		newDebuggerStateWithWalkback: gatewayWalkback
		errorText: errorText
		gatewayWalkback: gatewayWalkback
		frames: self gateway lastErrorFrames.
	sessionId := self gateway lastDebugSessionId.
	sessionId ifNotNil: [
		snapshot := self gateway debuggerSnapshotForSessionId: sessionId.
		self applyDebuggerSnapshot: snapshot toState: window ].
	self selectPreferredDebuggerFrameInState: window.
	self synchronizeBaseDebuggerStateFrom: window.
	debuggerSnapshotText := window at: #walkback.
	window at: #id put: windowId.
	window at: #title put: (self exceptionDebuggerTitleForWindowNumber: windowNumber).
	window at: #taskbarLabel put: (self exceptionDebuggerTaskbarLabelForWindowNumber: windowNumber).
	window at: #subtitle put: (self transcriptPreviewOf: errorText).
	window at: #position put: (self exceptionDebuggerWindowPositionForIndex: windowNumber).
	debuggerWindows addLast: window.
	^ window
]

{ #category : 'private' }
SigExplorerApplication >> showDebuggerForLastError [
	| sessionId snapshot walkback |
	walkback := self gateway lastErrorStackText.
	self
		storeBaseDebuggerStateWithWalkback: (walkback
			ifNil: [ 'No gateway walkback recorded.' ]
			ifNotNil: [ walkback ])
		errorText: self gateway lastErrorText
		gatewayWalkback: walkback
		frames: self gateway lastErrorFrames.
	sessionId := self gateway lastDebugSessionId.
	sessionId ifNotNil: [
		snapshot := self gateway debuggerSnapshotForSessionId: sessionId.
		self applyDebuggerSnapshot: snapshot toState: self debuggerState ].
	self selectPreferredDebuggerFrameInState: self debuggerState.
	self requestWindowShow: 'sig-window-debugger'
]

{ #category : 'private' }
SigExplorerApplication >> refreshBaseDebuggerStateFromGateway [
	self
		storeBaseDebuggerStateWithWalkback: self gateway currentStackReport
		errorText: self gateway lastErrorText
		gatewayWalkback: self gateway lastErrorStackText
		frames: self gateway currentStackFrames
]

{ #category : 'private' }
SigExplorerApplication >> preferredDebuggerFrameLevelIn: visibleFrames [
	| preferredFrame |
	preferredFrame := visibleFrames
		detect: [ :each | self debuggerFrameIsExecutedCode: each ]
		ifNone: [ nil ].
	preferredFrame ifNotNil: [ ^ preferredFrame at: #level ].
	preferredFrame := visibleFrames
		detect: [ :each | each at: #isErrorContext ifAbsent: [ false ] ]
		ifNone: [
			visibleFrames
				detect: [ :each |
					((each at: #selectorName ifAbsent: [ '' ]) beginsWith: '_error')
						and: [ (each at: #isInfrastructure ifAbsent: [ false ]) not ] ]
				ifNone: [ nil ] ].
	preferredFrame ifNil: [
		preferredFrame := visibleFrames
			detect: [ :each | (each at: #isInfrastructure ifAbsent: [ false ]) not ]
			ifNone: [ visibleFrames first ] ].
	^ preferredFrame at: #level
]

{ #category : 'actions' }
SigExplorerApplication >> performDebuggerAction: anActionSymbol inState: aState [
	| sessionId snapshot |
	sessionId := aState at: #debugSessionId ifAbsent: [ nil ].
	sessionId ifNil: [
		self setStatusMessage: 'No live debug process attached'.
		^ self ].
	snapshot := anActionSymbol = #refresh
		ifTrue: [ self gateway debuggerSnapshotForSessionId: sessionId ]
		ifFalse: [
			self gateway
				performDebugAction: anActionSymbol
				forSessionId: sessionId
				atLevel: (self selectedDebuggerProcessLevelInState: aState) ].
	self applyDebuggerSnapshot: snapshot toState: aState.
	(#(refresh restart step stepInto stepOver stepReturn proceed resume terminate) includes: anActionSymbol)
		ifTrue: [ self selectPreferredDebuggerFrameInState: aState ].
	aState == self debuggerState ifFalse: [
		self synchronizeBaseDebuggerStateFrom: aState ].
	self setStatusMessage: (self debuggerSessionStatusTextForState: aState).
	self addTranscriptLine: 'Debugger ', anActionSymbol asString, ': ', (self transcriptPreviewOf: (self debuggerSessionStatusTextForState: aState))
]

{ #category : 'private' }
SigExplorerApplication >> selectedDebuggerProcessLevelInState: aState [
	| frame |
	frame := self selectedDebuggerFrameInState: aState.
	frame ifNil: [ ^ nil ].
	^ frame at: #level ifAbsent: [ nil ]
]

{ #category : 'private' }
SigExplorerApplication >> selectDebuggerFrameLevel: anInteger inState: aState [
	aState at: #selectedFrameLevel put: anInteger.
	self ensureDebuggerSelectionInState: aState
]

{ #category : 'private' }
SigExplorerApplication >> selectedDebuggerFrameInState: aState [
	| selectedFrameLevel visibleFrames |
	self ensureDebuggerSelectionInState: aState.
	selectedFrameLevel := aState at: #selectedFrameLevel ifAbsent: [ nil ].
	selectedFrameLevel ifNil: [ ^ nil ].
	visibleFrames := self debuggerVisibleFramesInState: aState.
	^ visibleFrames
		detect: [ :each | (each at: #level ifAbsent: [ 0 ]) = selectedFrameLevel ]
		ifNone: [ nil ]
]

{ #category : 'private' }
SigExplorerApplication >> selectPreferredDebuggerFrameInState: aState [
	| visibleFrames |
	visibleFrames := self debuggerVisibleFramesInState: aState.
	visibleFrames isEmpty
		ifTrue: [ aState at: #selectedFrameLevel put: nil ]
		ifFalse: [ aState at: #selectedFrameLevel put: (self preferredDebuggerFrameLevelIn: visibleFrames) ]
]

{ #category : 'private' }
SigExplorerApplication >> showDebuggerFramesInState: aState includeBridge: aBoolean [
	aState at: #showBridgeFrames put: aBoolean.
	self ensureDebuggerSelectionInState: aState
]

{ #category : 'private' }
SigExplorerApplication >> storeBaseDebuggerStateWithWalkback: currentWalkback errorText: errorText gatewayWalkback: gatewayWalkback frames: frames [
	debuggerSnapshotText := currentWalkback
		ifNil: [ 'No debugger snapshot captured yet.' ]
		ifNotNil: [ currentWalkback ].
	debuggerState := self
		newDebuggerStateWithWalkback: debuggerSnapshotText
			errorText: errorText
			gatewayWalkback: gatewayWalkback
			frames: frames
]

{ #category : 'private' }
SigExplorerApplication >> synchronizeBaseDebuggerStateFrom: aState [
	aState ifNil: [ ^ self ].
	self
		storeBaseDebuggerStateWithWalkback: (aState at: #walkback ifAbsent: [ nil ])
		errorText: (aState at: #errorText ifAbsent: [ nil ])
		gatewayWalkback: (aState at: #gatewayWalkback ifAbsent: [ nil ])
		frames: (aState at: #frames ifAbsent: [ #() ]).
	self applyDebuggerSnapshot: aState toState: self debuggerState.
	self debuggerState
		at: #showBridgeFrames put: (aState at: #showBridgeFrames ifAbsent: [ false ]);
		at: #selectedFrameLevel put: (aState at: #selectedFrameLevel ifAbsent: [ nil ]).
	self ensureDebuggerSelectionInState: self debuggerState
]

{ #category : 'rendering' }
SigExplorerApplication >> desktopScript [
	^ '
(function () {
  var runtime = window.SIGDesktopRuntime || (window.SIGDesktopRuntime = {
    dragState: null,
    requestInFlight: false
  });

  function desktopElement() {
    return document.getElementById(''sig-desktop'');
  }

  function taskbarElement() {
    return document.getElementById(''sig-taskbar'');
  }

  function getManagedWindows() {
    return Array.prototype.slice.call(document.querySelectorAll(''.sig-floating-window''));
  }

  function desktopMetrics() {
    var desktop = desktopElement();
    var taskbar = taskbarElement();
    var rect = desktop ? desktop.getBoundingClientRect() : { left: 0, top: 0 };
    return {
      desktop: desktop,
      rect: rect,
      taskbarHeight: taskbar ? taskbar.getBoundingClientRect().height : 0,
      viewportWidth: window.innerWidth || document.documentElement.clientWidth,
      viewportHeight: window.innerHeight || document.documentElement.clientHeight,
      availableWidth: (window.innerWidth || document.documentElement.clientWidth) - rect.left,
      availableHeight: (window.innerHeight || document.documentElement.clientHeight) - rect.top - (taskbar ? taskbar.getBoundingClientRect().height : 0),
      margin: 16,
      gap: 16
    };
  }

  function desktopStateKey() {
    return ''sigDesktopState:v4:'' + window.location.pathname;
  }

  function restoreScrollPanes() {
    var state = runtime.scrollPaneState;
    Array.prototype.forEach.call(document.querySelectorAll(''[data-sig-scroll-key]''), function (pane) {
      var key = pane.getAttribute(''data-sig-scroll-key'');
      var saved = state && state[key];
      if (saved) {
        pane.scrollLeft = saved.left || 0;
        pane.scrollTop = saved.top || 0;
      }
      if (pane.getAttribute(''data-sig-scroll-follow'') === ''selected'') {
        var selected = pane.querySelector(''.selected'');
        if (selected && selected.scrollIntoView) {
          selected.scrollIntoView({ block: ''nearest'' });
        }
      }
    });
    runtime.scrollPaneState = null;
  }

  function saveScrollPanes() {
    var state = {};
    Array.prototype.forEach.call(document.querySelectorAll(''[data-sig-scroll-key]''), function (pane) {
      var key = pane.getAttribute(''data-sig-scroll-key'');
      if (!key) return;
      state[key] = {
        left: pane.scrollLeft,
        top: pane.scrollTop
      };
    });
    runtime.scrollPaneState = state;
  }

  function saveDesktopState() {
    if (!window.sessionStorage) return;
    try {
      var active = document.querySelector(''.sig-floating-window.sig-window-active'');
      var state = {
        windows: getManagedWindows().map(function (win) {
          return {
            id: win.id,
            collapsed: win.classList.contains(''sig-window-collapsed''),
            display: win.style.display || window.getComputedStyle(win).display,
            collapsedHeight: win.dataset.sigCollapsedHeight || '''',
            left: win.style.left || '''',
            maximized: win.classList.contains(''sig-window-maximized''),
            restoreHeight: win.dataset.sigRestoreHeight || '''',
            restoreLeft: win.dataset.sigRestoreLeft || '''',
            restoreTop: win.dataset.sigRestoreTop || '''',
            restoreWidth: win.dataset.sigRestoreWidth || '''',
            top: win.style.top || '''',
            width: win.style.width || '''',
            height: win.style.height || '''',
            zIndex: win.style.zIndex || '''',
            active: !!active && active.id === win.id
          };
        })
      };
      window.sessionStorage.setItem(desktopStateKey(), JSON.stringify(state));
    } catch (error) {}
  }

  function restoreDesktopState() {
    var raw;
    var restoredIds;
    var state;
    var restored;
    if (!window.sessionStorage) return false;
    try {
      raw = window.sessionStorage.getItem(desktopStateKey());
      state = raw ? JSON.parse(raw) : null;
    } catch (error) {
      return false;
    }
    if (!state || !state.windows || !state.windows.length) return false;
    restored = false;
    restoredIds = {};
    state.windows.forEach(function (saved) {
      var win = document.getElementById(saved.id);
      if (!win) return;
      restoredIds[saved.id] = true;
      if (saved.left) win.style.left = saved.left;
      if (saved.top) win.style.top = saved.top;
      if (saved.width) win.style.width = saved.width;
      if (saved.height) win.style.height = saved.height;
      if (saved.zIndex) win.style.zIndex = saved.zIndex;
      if (saved.restoreLeft) {
        win.dataset.sigRestoreLeft = saved.restoreLeft;
      } else {
        delete win.dataset.sigRestoreLeft;
      }
      if (saved.restoreTop) {
        win.dataset.sigRestoreTop = saved.restoreTop;
      } else {
        delete win.dataset.sigRestoreTop;
      }
      if (saved.restoreWidth) {
        win.dataset.sigRestoreWidth = saved.restoreWidth;
      } else {
        delete win.dataset.sigRestoreWidth;
      }
      if (saved.restoreHeight) {
        win.dataset.sigRestoreHeight = saved.restoreHeight;
      } else {
        delete win.dataset.sigRestoreHeight;
      }
      if (saved.collapsedHeight) {
        win.dataset.sigCollapsedHeight = saved.collapsedHeight;
      } else {
        delete win.dataset.sigCollapsedHeight;
      }
      win.style.display = saved.display || ''block'';
      win.classList.toggle(''sig-window-collapsed'', !!saved.collapsed);
      win.classList.toggle(''sig-window-maximized'', !!saved.maximized);
      if (saved.maximized) {
        applyMaximizedBounds(win);
      }
      win.classList.toggle(''sig-window-active'', !!saved.active);
      clampWindowToDesktop(win);
      restored = true;
    });
    runtime.newlyVisibleWindowIds = restored
      ? getManagedWindows()
          .filter(function (win) {
            return !restoredIds[win.id] && window.getComputedStyle(win).display !== ''none'';
          })
          .map(function (win) { return win.id; })
      : [];
    if (restored) {
      focusTopVisibleWindow();
      syncTaskbarButtons();
    }
    return restored;
  }

  function extractAutoShowWindow(sourceDocument) {
    var scripts = sourceDocument.querySelectorAll(''script'');
    var index;
    for (index = 0; index < scripts.length; index += 1) {
      var match = (scripts[index].textContent || '''').match(/window\\.SIGAutoShowWindow\\s*=\\s*([''"])(.*?)\\1/);
      if (match) {
        return match[2];
      }
    }
    return null;
  }

  function replaceFragmentFromDocument(selector, sourceDocument) {
    var current = document.querySelector(selector);
    var replacement = sourceDocument.querySelector(selector);
    if (current && !replacement) {
      current.remove();
      return true;
    }
    if (!current || !replacement) return false;
    current.replaceWith(document.importNode(replacement, true));
    return true;
  }

  function fallbackToRenderedDocument(sourceDocument) {
    if (!sourceDocument.body) return;
    if (sourceDocument.title) {
      document.title = sourceDocument.title;
    }
    document.body.className = sourceDocument.body.className || '''';
    document.body.innerHTML = sourceDocument.body.innerHTML;
  }

  function applyRemoteResponse(htmlText) {
    var sourceDocument = new DOMParser().parseFromString(htmlText, ''text/html'');
    var autoShowWindowId = extractAutoShowWindow(sourceDocument);
    var selectors = [''.sig-menu-bar'', ''#sig-context-menu'', ''#sig-desktop'', ''#sig-taskbar''];
    var replaced = false;

    if (sourceDocument.title) {
      document.title = sourceDocument.title;
    }
    if (sourceDocument.body) {
      document.body.className = sourceDocument.body.className || document.body.className;
    }
    selectors.forEach(function (selector) {
      replaced = replaceFragmentFromDocument(selector, sourceDocument) || replaced;
    });
    if (!replaced) {
      fallbackToRenderedDocument(sourceDocument);
      return;
    }
    runtime.dragState = null;
    document.body.classList.remove(''sig-dragging'');
    if (autoShowWindowId) {
      window.SIGAutoShowWindow = autoShowWindowId;
    }
    boot();
  }

  function performRemoteRequest(url, options, fallback) {
    var requestOptions;
    var headers;
    if (runtime.requestInFlight) return;
    runtime.requestInFlight = true;
    closeMenus();
    hideContextMenu();
    saveScrollPanes();
    saveDesktopState();
    requestOptions = options ? Object.assign({}, options) : {};
    headers = Object.assign({}, requestOptions.headers || {});
    headers[''X-Requested-With''] = ''SIGDesktop'';
    requestOptions.credentials = ''same-origin'';
    requestOptions.headers = headers;
    fetch(url, requestOptions)
      .then(function (response) { return response.text(); })
      .then(function (htmlText) { applyRemoteResponse(htmlText); })
      .catch(function () {
        if (fallback) {
          fallback();
        } else {
          window.location.assign(url);
        }
      })
      .finally(function () {
        runtime.requestInFlight = false;
      });
  }

  function buildRemoteFormRequest(form, submitter) {
    var action = (submitter && submitter.getAttribute(''formaction'')) || form.getAttribute(''action'') || window.location.href;
    var method = ((submitter && submitter.getAttribute(''formmethod'')) || form.getAttribute(''method'') || ''POST'').toUpperCase();
    var enctype = (form.getAttribute(''enctype'') || ''application/x-www-form-urlencoded'').toLowerCase();
    var formData = new FormData(form);
    var query;
    if (submitter && submitter.name) {
      formData.append(submitter.name, submitter.value);
    }
    if (method === ''GET'') {
      query = new URLSearchParams(formData).toString();
      if (query) {
        action += (action.indexOf(''?'') === -1 ? ''?'' : ''&'') + query;
      }
      return {
        url: action,
        options: { method: ''GET'' }
      };
    }
    if (enctype.indexOf(''multipart/form-data'') === 0) {
      return {
        url: action,
        options: {
          method: method,
          body: formData
        }
      };
    }
    if (enctype === ''text/plain'') {
      return null;
    }
    return {
      url: action,
      options: {
        method: method,
        headers: {
          ''Content-Type'': ''application/x-www-form-urlencoded;charset=UTF-8''
        },
        body: new URLSearchParams(formData).toString()
      }
    };
  }

  function syncTaskbarButtons() {
    Array.prototype.forEach.call(document.querySelectorAll(''.sig-taskbar-button[data-window-target]''), function (button) {
      var target = button.getAttribute(''data-window-target'');
      var win = document.getElementById(target);
      var visible = !!win && window.getComputedStyle(win).display !== ''none'';
      var active = visible && win.classList.contains(''sig-window-active'');
      button.classList.toggle(''open'', visible);
      button.classList.toggle(''active'', active);
    });
  }

  function setActiveWindow(win) {
    getManagedWindows().forEach(function (each) {
      each.classList.remove(''sig-window-active'');
    });
    if (win) {
      win.classList.add(''sig-window-active'');
    }
    syncTaskbarButtons();
  }

  function focusTopVisibleWindow() {
    var visible = getManagedWindows()
      .filter(function (win) { return window.getComputedStyle(win).display !== ''none''; })
      .sort(function (left, right) {
        return (parseInt(left.style.zIndex || ''10'', 10) || 10) - (parseInt(right.style.zIndex || ''10'', 10) || 10);
      });
    if (visible.length) {
      setActiveWindow(visible[visible.length - 1]);
    } else {
      setActiveWindow(null);
    }
  }

  function bringToFront(win) {
    var top = 20;
    getManagedWindows().forEach(function (each) {
      var z = parseInt(each.style.zIndex || ''10'', 10);
      if (!isNaN(z) && z > top) top = z;
    });
    win.style.zIndex = String(top + 1);
    setActiveWindow(win);
    saveDesktopState();
  }

  function closeMenus() {
    Array.prototype.forEach.call(document.querySelectorAll(''.sig-menu.open''), function (menu) {
      menu.classList.remove(''open'');
    });
  }

  function hideContextMenu() {
    var menu = document.getElementById(''sig-context-menu'');
    if (menu) {
      menu.style.display = ''none'';
    }
  }

  function setWindowPosition(win, left, top) {
    win.style.left = Math.round(left) + ''px'';
    win.style.top = Math.round(top) + ''px'';
  }

  function currentWindowBox(win, metrics) {
    var rect = win.getBoundingClientRect();
    return {
      left: rect.left - metrics.rect.left,
      top: rect.top - metrics.rect.top,
      width: rect.width || win.offsetWidth,
      height: rect.height || win.offsetHeight
    };
  }

  function hideWindow(win) {
    win.style.display = ''none'';
    win.classList.remove(''sig-window-active'');
    focusTopVisibleWindow();
    syncTaskbarButtons();
    saveDesktopState();
  }

  function rememberWindowRestoreBounds(win) {
    var box = currentWindowBox(win, desktopMetrics());
    win.dataset.sigRestoreLeft = Math.round(box.left) + ''px'';
    win.dataset.sigRestoreTop = Math.round(box.top) + ''px'';
    win.dataset.sigRestoreWidth = Math.round(box.width) + ''px'';
    win.dataset.sigRestoreHeight = Math.round(box.height) + ''px'';
  }

  function restoreRememberedWindowBounds(win) {
    if (win.dataset.sigRestoreLeft) win.style.left = win.dataset.sigRestoreLeft;
    if (win.dataset.sigRestoreTop) win.style.top = win.dataset.sigRestoreTop;
    if (win.dataset.sigRestoreWidth) win.style.width = win.dataset.sigRestoreWidth;
    if (win.dataset.sigRestoreHeight) win.style.height = win.dataset.sigRestoreHeight;
  }

  function applyMaximizedBounds(win) {
    var metrics = desktopMetrics();
    if (!metrics.desktop) return;
    win.style.left = metrics.margin + ''px'';
    win.style.top = metrics.margin + ''px'';
    win.style.width = Math.max(320, metrics.availableWidth - (metrics.margin * 2)) + ''px'';
    win.style.height = Math.max(220, metrics.availableHeight - (metrics.margin * 2)) + ''px'';
  }

  function minimiseWindow(win) {
    if (win.classList.contains(''sig-window-collapsed'')) {
      win.classList.remove(''sig-window-collapsed'');
      if (win.dataset.sigCollapsedHeight) {
        win.style.height = win.dataset.sigCollapsedHeight;
      }
    }
    hideWindow(win);
  }

  function toggleWindowExpand(win) {
    if (win.classList.contains(''sig-window-collapsed'')) {
      win.classList.remove(''sig-window-collapsed'');
      if (win.dataset.sigCollapsedHeight) {
        win.style.height = win.dataset.sigCollapsedHeight;
      }
    }
    if (win.classList.contains(''sig-window-maximized'')) {
      win.classList.remove(''sig-window-maximized'');
      restoreRememberedWindowBounds(win);
      clampWindowToDesktop(win);
    } else {
      rememberWindowRestoreBounds(win);
      win.classList.add(''sig-window-maximized'');
      applyMaximizedBounds(win);
    }
    bringToFront(win);
    syncTaskbarButtons();
    saveDesktopState();
  }

  function clampWindowToDesktop(win) {
    var metrics = desktopMetrics();
    var box;
    var left;
    var top;
    if (!metrics.desktop || window.matchMedia(''(max-width: 1100px)'').matches) return;
    if (win.classList.contains(''sig-window-maximized'')) {
      applyMaximizedBounds(win);
      return;
    }
    box = currentWindowBox(win, metrics);
    left = Math.min(
      Math.max(box.left, metrics.margin),
      Math.max(metrics.margin, metrics.availableWidth - box.width - metrics.margin)
    );
    top = Math.min(
      Math.max(box.top, metrics.margin),
      Math.max(metrics.margin, metrics.availableHeight - box.height - metrics.margin)
    );
    setWindowPosition(win, left, top);
  }

  function layoutWindows() {
    var metrics = desktopMetrics();
    var cursorLeft;
    var cursorTop;
    var rowHeight;
    if (!metrics.desktop || window.matchMedia(''(max-width: 1100px)'').matches) return;
    cursorLeft = metrics.margin;
    cursorTop = metrics.margin;
    rowHeight = 0;
    Array.prototype.forEach.call(document.querySelectorAll(''.sig-floating-window''), function (win) {
      var hidden = window.getComputedStyle(win).display === ''none'';
      var box;
      var width;
      if (hidden) {
        win.style.display = ''block'';
      }
      box = currentWindowBox(win, metrics);
      width = Math.min(box.width, Math.max(320, metrics.availableWidth - (metrics.margin * 2)));
      if (cursorLeft + width > metrics.availableWidth - metrics.margin) {
        cursorLeft = metrics.margin;
        cursorTop += rowHeight + metrics.gap;
        rowHeight = 0;
      }
      setWindowPosition(win, cursorLeft, cursorTop);
      cursorLeft += width + metrics.gap;
      rowHeight = Math.max(rowHeight, box.height);
      if (hidden) {
        win.style.display = ''none'';
      }
    });
  }

  function cascadeWindows() {
    var metrics = desktopMetrics();
    var step = 28;
    var left = metrics.margin;
    var top = metrics.margin;
    var maxLeft = Math.max(metrics.margin, metrics.availableWidth - 360);
    var maxTop = Math.max(metrics.margin, metrics.availableHeight - 240);
    if (!metrics.desktop || window.matchMedia(''(max-width: 1100px)'').matches) return;
    getManagedWindows().forEach(function (win) {
      win.style.display = ''block'';
      setWindowPosition(win, left, top);
      clampWindowToDesktop(win);
      bringToFront(win);
      left += step;
      top += step;
      if (left > maxLeft || top > maxTop) {
        left = metrics.margin;
        top = metrics.margin;
      }
    });
    syncTaskbarButtons();
    saveDesktopState();
  }

  function tileWindows() {
    var metrics = desktopMetrics();
    var windows = getManagedWindows();
    var cols;
    var rows;
    var cellWidth;
    var cellHeight;
    if (!metrics.desktop || window.matchMedia(''(max-width: 1100px)'').matches || !windows.length) return;
    cols = Math.max(1, Math.ceil(Math.sqrt(windows.length)));
    rows = Math.max(1, Math.ceil(windows.length / cols));
    cellWidth = Math.max(320, Math.floor((metrics.availableWidth - (metrics.margin * 2) - (metrics.gap * (cols - 1))) / cols));
    cellHeight = Math.max(220, Math.floor((metrics.availableHeight - (metrics.margin * 2) - (metrics.gap * (rows - 1))) / rows));
    windows.forEach(function (win, index) {
      var col = index % cols;
      var row = Math.floor(index / cols);
      win.style.display = ''block'';
      win.style.width = Math.max(320, cellWidth) + ''px'';
      win.style.height = Math.max(220, cellHeight) + ''px'';
      setWindowPosition(
        win,
        metrics.margin + (col * (cellWidth + metrics.gap)),
        metrics.margin + (row * (cellHeight + metrics.gap))
      );
      clampWindowToDesktop(win);
      bringToFront(win);
    });
    syncTaskbarButtons();
    saveDesktopState();
  }

  function showAllWindows() {
    getManagedWindows().forEach(function (win) {
      win.style.display = ''block'';
    });
    layoutWindows();
    focusTopVisibleWindow();
    syncTaskbarButtons();
    saveDesktopState();
  }

  function minimiseAllWindows() {
    getManagedWindows().forEach(function (win) {
      win.style.display = ''none'';
      win.classList.remove(''sig-window-active'');
    });
    syncTaskbarButtons();
    saveDesktopState();
  }

  function closeAllWindows() {
    minimiseAllWindows();
  }

  function showWindow(windowId) {
    var win = document.getElementById(windowId);
    if (!win) return;
    win.style.display = ''block'';
    if (win.classList.contains(''sig-window-maximized'')) {
      applyMaximizedBounds(win);
    }
    clampWindowToDesktop(win);
    bringToFront(win);
    syncTaskbarButtons();
    saveDesktopState();
  }

  function handleDesktopAction(action) {
    if (action === ''cascade'') {
      cascadeWindows();
      return;
    }
    if (action === ''tile'') {
      tileWindows();
      return;
    }
    if (action === ''show-all'') {
      showAllWindows();
      return;
    }
    if (action === ''minimise-all'') {
      minimiseAllWindows();
      return;
    }
    if (action === ''close-all'') {
      closeAllWindows();
    }
  }

  function installWindowDragging(win) {
    var handle = win.querySelector(''.sig-window-titlebar'');
    if (!handle || handle.dataset.sigDragInstalled === ''true'') return;
    handle.dataset.sigDragInstalled = ''true'';

    if (!runtime.dragSupportInstalled) {
      runtime.dragSupportInstalled = true;
      document.addEventListener(''mousemove'', function (event) {
        var dragging = runtime.dragState;
        if (!dragging || !dragging.window) return;
        dragging.window.style.left = (dragging.originX + event.clientX - dragging.startX) + ''px'';
        dragging.window.style.top = (dragging.originY + event.clientY - dragging.startY) + ''px'';
      });

      document.addEventListener(''mouseup'', function () {
        var dragging = runtime.dragState;
        if (!dragging || !dragging.window) return;
        clampWindowToDesktop(dragging.window);
        saveDesktopState();
        runtime.dragState = null;
        document.body.classList.remove(''sig-dragging'');
      });
    }

    handle.addEventListener(''mousedown'', function (event) {
      var metrics = desktopMetrics();
      var box = currentWindowBox(win, metrics);
      if (event.target.closest(''.sig-window-controls'')) return;
      if (win.classList.contains(''sig-window-maximized'')) return;
      runtime.dragState = {
        window: win,
        startX: event.clientX,
        startY: event.clientY,
        originX: box.left,
        originY: box.top
      };
      bringToFront(win);
      document.body.classList.add(''sig-dragging'');
      event.preventDefault();
    });
  }

  function installWindowControls(win) {
    if (win.dataset.sigControlsInstalled === ''true'') return;
    win.dataset.sigControlsInstalled = ''true'';
    var close = win.querySelector(''[data-sig-window-action="close"]'');
    var collapse = win.querySelector(''[data-sig-window-action="collapse"]'');
    var expand = win.querySelector(''[data-sig-window-action="expand"]'');
    if (close) {
      close.addEventListener(''click'', function (event) {
        event.preventDefault();
        hideWindow(win);
      });
    }
    if (collapse) {
      collapse.addEventListener(''click'', function (event) {
        event.preventDefault();
        minimiseWindow(win);
      });
    }
    if (expand) {
      expand.addEventListener(''click'', function (event) {
        event.preventDefault();
        toggleWindowExpand(win);
      });
    }
    win.addEventListener(''mousedown'', function () { bringToFront(win); });
  }

  function installWindowResizing(win) {
    if (typeof ResizeObserver === ''undefined'' || win.dataset.sigResizeInstalled === ''true'') return;
    win.dataset.sigResizeInstalled = ''true'';
    var observer = new ResizeObserver(function () {
      clampWindowToDesktop(win);
      saveDesktopState();
    });
    win._sigResizeObserver = observer;
    observer.observe(win);
  }

  function installDesktopMenu() {
    if (runtime.desktopMenuInstalled) return;
    runtime.desktopMenuInstalled = true;

    document.addEventListener(''contextmenu'', function (event) {
      var desktop = document.getElementById(''sig-desktop'');
      var menu = document.getElementById(''sig-context-menu'');
      if (!desktop || !menu || !desktop.contains(event.target)) return;
      if (event.target.closest(''.sig-floating-window'')) return;
      event.preventDefault();
      menu.style.display = ''block'';
      menu.style.left = event.clientX + ''px'';
      menu.style.top = event.clientY + ''px'';
    });

    document.addEventListener(''click'', function (event) {
      var menu = document.getElementById(''sig-context-menu'');
      if (menu && menu.style.display === ''block'' && !event.target.closest(''#sig-context-menu'')) {
        hideContextMenu();
      }
    });

    document.addEventListener(''keydown'', function (event) {
      if (event.key === ''Escape'') {
        hideContextMenu();
        closeMenus();
      }
    });
  }

  function installTopMenus() {
    if (runtime.topMenusInstalled) return;
    runtime.topMenusInstalled = true;

    document.addEventListener(''click'', function (event) {
      var trigger = event.target.closest(''[data-menu-trigger]'');
      if (trigger) {
        var menu = trigger.closest(''.sig-menu'');
        var isOpen = menu && menu.classList.contains(''open'');
        event.preventDefault();
        event.stopPropagation();
        closeMenus();
        if (!isOpen && menu) {
          menu.classList.add(''open'');
        }
        return;
      }
      if (!event.target.closest(''.sig-menu'')) {
        closeMenus();
      }
    });
  }

  function installTabbedPanes() {
    if (runtime.tabbedPanesInstalled) return;
    runtime.tabbedPanesInstalled = true;

    document.addEventListener(''click'', function (event) {
      var tab = event.target.closest(''[data-sig-tab]'');
      var scope;
      var tabName;
      if (!tab) return;
      scope = tab.closest(''[data-sig-tab-scope]'');
      tabName = tab.getAttribute(''data-sig-tab'');
      if (!scope || !tabName) return;
      event.preventDefault();
      Array.prototype.forEach.call(scope.querySelectorAll(''[data-sig-tab]''), function (each) {
        each.classList.toggle(''active'', each === tab);
      });
      Array.prototype.forEach.call(scope.querySelectorAll(''[data-sig-tab-panel]''), function (panel) {
        panel.classList.toggle(''active'', panel.getAttribute(''data-sig-tab-panel'') === tabName);
      });
    });

    document.addEventListener(''keydown'', function (event) {
      var area;
      var form;
      var submit;
      if (!(event.ctrlKey || event.metaKey) || event.key !== ''Enter'') return;
      area = event.target.closest(''.ws-code-area'');
      if (!area) return;
      form = area.closest(''form[data-sig-remote]'');
      if (!form) return;
      submit = form.querySelector(''[data-sig-primary-submit]'');
      if (!submit) return;
      event.preventDefault();
      submit.click();
    });
  }

  function installLocalCommands() {
    if (runtime.localCommandsInstalled) return;
    runtime.localCommandsInstalled = true;

    document.addEventListener(''click'', function (event) {
      var link = event.target.closest(''[data-window-target]'');
      if (link && link.getAttribute(''href'') === ''#'') {
        event.preventDefault();
        showWindow(link.getAttribute(''data-window-target''));
        hideContextMenu();
        closeMenus();
        return;
      }
      link = event.target.closest(''[data-desktop-action]'');
      if (link && link.getAttribute(''href'') === ''#'') {
        event.preventDefault();
        handleDesktopAction(link.getAttribute(''data-desktop-action''));
        hideContextMenu();
        closeMenus();
      }
    });
  }

  function installRemoteInteractions() {
    if (runtime.remoteInteractionsInstalled) return;
    runtime.remoteInteractionsInstalled = true;

    document.addEventListener(''click'', function (event) {
      var link = event.target.closest(''a[data-sig-remote]'');
      if (!link) return;
      if (event.defaultPrevented || event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      if (!link.getAttribute(''href'') || link.getAttribute(''href'') === ''#'') return;
      event.preventDefault();
      performRemoteRequest(link.href, { method: ''GET'' }, function () {
        window.location.assign(link.href);
      });
    });

    document.addEventListener(''submit'', function (event) {
      var form = event.target;
      var request;
      if (!form.matches(''form[data-sig-remote]'')) return;
      event.preventDefault();
      request = buildRemoteFormRequest(form, event.submitter || document.activeElement);
      if (!request) {
        HTMLFormElement.prototype.submit.call(form);
        return;
      }
      performRemoteRequest(request.url, request.options, function () {
        HTMLFormElement.prototype.submit.call(form);
      });
    });
  }

  function boot() {
    var restored;
    getManagedWindows().forEach(function (win) {
      installWindowDragging(win);
      installWindowControls(win);
      installWindowResizing(win);
    });
    restored = restoreDesktopState();
    if (!restored) {
      layoutWindows();
    }
    if (getManagedWindows().length && !document.querySelector(''.sig-floating-window.sig-window-active'')) {
      bringToFront(getManagedWindows()[0]);
    }
    installDesktopMenu();
    installTopMenus();
    installTabbedPanes();
    installLocalCommands();
    installRemoteInteractions();
    restoreScrollPanes();
    if (!runtime.resizeListenerInstalled) {
      runtime.resizeListenerInstalled = true;
      window.addEventListener(''resize'', function () {
        getManagedWindows().forEach(function (win) {
          if (win.classList.contains(''sig-window-maximized'')) {
            applyMaximizedBounds(win);
          } else {
            clampWindowToDesktop(win);
          }
        });
      });
    }
    syncTaskbarButtons();
    if (window.SIGAutoShowWindow) {
      showWindow(window.SIGAutoShowWindow);
      window.SIGAutoShowWindow = null;
    } else if (runtime.newlyVisibleWindowIds && runtime.newlyVisibleWindowIds.length) {
      showWindow(runtime.newlyVisibleWindowIds[runtime.newlyVisibleWindowIds.length - 1]);
    }
    runtime.newlyVisibleWindowIds = [];
    saveDesktopState();
  }

  if (document.readyState === ''loading'') {
    document.addEventListener(''DOMContentLoaded'', boot);
  } else {
    boot();
  }
}());
'
]

{ #category : 'actions' }
SigExplorerApplication >> disconnect [
	self gateway disconnect.
	debuggerSnapshotText := nil.
	debuggerState := nil.
	debuggerWindows := OrderedCollection new.
	nextDebuggerWindowNumber := 0.
	selectedEntryKey := nil.
	self clearInspector.
	self setStatusMessage: 'Gateway state cleared'
]

{ #category : 'querying' }
SigExplorerApplication >> entryAssociations [
	^ self gateway entryAssociationsForRootNamed: selectedRootName
]

{ #category : 'accessing' }
SigExplorerApplication >> gateway [
	gateway ifNil: [ gateway := SigGemStoneGateway new ].
	gateway sanitizeDebugSessions.
	^ gateway
]

{ #category : 'accessing' }
SigExplorerApplication >> gateway: anObject [
	gateway := anObject
]

{ #category : 'initialization' }
SigExplorerApplication >> initialize [
	super initialize.
	selectedRootName := #bridgeRoot.
	selectedEntryKey := nil.
	statusMessage := nil.
	selectedBrowserDictionaryName := #UserGlobals.
	selectedBrowserClassName := nil.
	selectedBrowserProtocolName := nil.
	selectedBrowserSelector := nil.
	selectedSymbolListDictionaryName := #UserGlobals.
	selectedSymbolListEntryKey := nil.
	debuggerSnapshotText := nil.
	debuggerState := self
		newDebuggerStateWithWalkback: 'No debugger snapshot captured yet.'
		errorText: 'No gateway errors recorded.'
		gatewayWalkback: 'No gateway walkback recorded.'
		frames: #().
	workspaceSourceText := '"Evaluate Smalltalk in the live stone"
1 + 2'.
	workspaceResultText := 'Do it prints the result here. Inspect fills the Inspector window and prints the same object view here. Debug captures a walkback only when the code signals an error or halt.'.
	transcriptEntries := OrderedCollection new.
	pendingWindowIdToShow := nil.
	debuggerWindows := OrderedCollection new.
	nextDebuggerWindowNumber := 0.
	self clearInspector.
	self addTranscriptLine: 'Desktop ready'
]

{ #category : 'rendering' }
SigExplorerApplication >> renderActionLinkOn: html label: aString callback: aBlock [
	html anchor
		class: 'sig-action';
		attributeAt: 'data-sig-remote' put: 'true';
		callback: aBlock;
		with: aString.
	html space
]

{ #category : 'rendering' }
SigExplorerApplication >> renderBrowserColumnOn: html title: aString items: aCollection selected: selectedValue callback: aBlock [
	html div class: 'sig-browser-column'; with: [
		html heading level3; with: aString.
		html div class: 'sig-scroll-pane sig-list-pane'; with: [
			aCollection isEmpty
				ifTrue: [ html paragraph class: 'sig-window-note'; with: 'No entries.' ]
				ifFalse: [
					html unorderedList class: 'sig-browser-list'; with: [
						aCollection do: [ :each |
							| label |
							label := each asString.
							html listItem: [
								html anchor
									class: (label = selectedValue ifTrue: [ 'sig-browser-item selected' ] ifFalse: [ 'sig-browser-item' ]);
									attributeAt: 'data-sig-remote' put: 'true';
									callback: [ aBlock value: each ];
									with: label ] ] ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderBrowserToolbarChipOn: html label: aLabel accent: aBoolean [
	html span
		class: (aBoolean
			ifTrue: [ 'btn cb-static-btn' ]
			ifFalse: [ 'btn-ghost cb-static-btn' ]);
		with: aLabel
]

{ #category : 'rendering' }
SigExplorerApplication >> renderClassBrowserColumnOn: html title: aString items: aCollection selected: selectedValue callback: aBlock filterPlaceholder: aPlaceholder [
	html div class: 'cb-pane'; with: [
		html div class: 'cb-pane-label'; with: aString.
		html div class: 'cb-filter-wrap'; with: [
			html div class: 'cb-filter cb-filter-placeholder'; with: aPlaceholder ].
		html div class: 'cb-list sig-scroll-pane'; with: [
			aCollection isEmpty
				ifTrue: [ html paragraph class: 'sig-window-note'; with: 'No entries.' ]
				ifFalse: [
					html unorderedList class: 'cb-list-entries'; with: [
						aCollection do: [ :each |
							| label |
							label := each asString.
							html listItem: [
								html anchor
									class: (label = selectedValue ifTrue: [ 'cb-item selected' ] ifFalse: [ 'cb-item' ]);
									attributeAt: 'data-sig-remote' put: 'true';
									callback: [ aBlock value: each ];
									with: label ] ] ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderBrowserOn: html [
	html div class: 'cb-wrap'; with: [
		html div class: 'cb-toolbar'; with: [
			self renderBrowserToolbarChipOn: html label: 'Find v' accent: false.
			self renderBrowserToolbarChipOn: html label: 'Dictionary v' accent: false.
			self renderBrowserToolbarChipOn: html label: 'Class v' accent: false.
			self renderBrowserToolbarChipOn: html label: 'Category v' accent: false.
			self renderBrowserToolbarChipOn: html label: 'Method v' accent: false.
			self renderBrowserToolbarChipOn: html label: 'Variables v' accent: false.
			self renderBrowserToolbarChipOn: html label: 'Query v' accent: false.
			self renderBrowserToolbarChipOn: html label: 'Inspect v' accent: false.
			self renderBrowserToolbarChipOn: html label: 'Transaction v' accent: false.
			self renderBrowserToolbarChipOn: html label: 'Compile' accent: true.
			html span class: 'cb-meta'; with: '[ ] Auto Commit'.
			html span class: 'cb-meta'; with: '[ ] Class side' ].
		html div class: 'cb-lists'; with: [
			self
				renderClassBrowserColumnOn: html
				title: 'Dictionaries'
				items: self browserDictionaryNames
				selected: selectedBrowserDictionaryName asString
				callback: [ :each | self selectBrowserDictionaryNamed: each ]
				filterPlaceholder: 'Filter dictionaries'.
			html div class: 'cb-splitter'; with: ''.
			self
				renderClassBrowserColumnOn: html
				title: 'Classes'
				items: (self browserClassAssociations collect: [ :each | each key asString ])
				selected: selectedBrowserClassName
				callback: [ :each | self selectBrowserClassNamed: each asString ]
				filterPlaceholder: 'Filter classes'.
			html div class: 'cb-splitter'; with: ''.
			self
				renderClassBrowserColumnOn: html
				title: 'Categories'
				items: self browserProtocolNames
				selected: selectedBrowserProtocolName
				callback: [ :each | self selectBrowserProtocolNamed: each asString ]
				filterPlaceholder: 'Filter categories'.
			html div class: 'cb-splitter'; with: ''.
			self
				renderClassBrowserColumnOn: html
				title: 'Methods'
				items: self browserSelectorNames
				selected: selectedBrowserSelector
				callback: [ :each | self selectBrowserSelectorNamed: each asString ]
				filterPlaceholder: 'Filter methods' ].
		html div class: 'cb-source-wrap'; with: [
			html div class: 'cb-source-hdr'; with: [
				html span: 'Source'.
				html span class: 'cb-source-note'; with: self browserSourceHeadingText ].
			html div class: 'cb-source sig-scroll-pane'; with: [
				html preformatted class: 'sig-pre'; with: self browserSourceText ].
			html div class: 'cb-status'; with: 'Read-only Class Browser running directly in the current GemStone session.' ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderContentOn: html [
	self renderDesktopContextMenuOn: html.
	html div
		id: 'sig-desktop';
		class: 'sig-desktop';
		with: [ :desktop |
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-explorer'
				title: 'Explorer'
				subtitle: 'Roots, entries, and object summaries'
				position: 'top: 1.25rem; left: 1.25rem; width: 29rem; height: 34rem;'
				with: [ :body | self renderExplorerOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-workspace'
				title: 'Workspace'
				subtitle: 'Evaluate Smalltalk in the live stone'
				position: 'top: 1.25rem; left: 31rem; width: 50rem; height: 34rem;'
				with: [ :body | self renderWorkspaceOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-browser'
				title: 'Class Browser'
				subtitle: 'Dictionaries, categories, and source'
				position: (self hiddenWindowPosition: 'top: 1.75rem; left: 31rem; width: 50rem; height: 31rem;')
				with: [ :body | self renderBrowserOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-symbol-list'
				title: 'Symbol List Browser'
				subtitle: 'Session symbol dictionaries and bindings'
				position: (self hiddenWindowPosition: 'top: 2.5rem; left: 82rem; width: 30rem; height: 28rem;')
				with: [ :body | self renderSymbolListBrowserOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-inspector'
				title: 'Inspector'
				subtitle: 'Live object inspection for explorer, symbols, and workspace'
				position: (self hiddenWindowPosition: 'top: 22rem; left: 83rem; width: 29rem; height: 25rem;')
				with: [ :body | self renderInspectorOn: body ].
			self
				renderFloatingWindowOn: desktop
					id: 'sig-window-debugger'
					title: 'Debugger'
					subtitle: 'Walkbacks and last gateway failures'
					position: (self hiddenWindowPosition: 'top: 8rem; left: 31rem; width: 50rem; height: 40rem;')
					with: [ :body | self renderDebuggerOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-session'
				title: 'Session'
				subtitle: 'Connection state, selections, and transaction controls'
				position: (self hiddenWindowPosition: 'top: 36rem; left: 31rem; width: 24rem; height: 18rem;')
				with: [ :body | self renderSessionOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-transcript'
				title: 'Transcript'
				subtitle: 'Recent desktop actions and workspace activity'
				position: (self hiddenWindowPosition: 'top: 36rem; left: 56rem; width: 35rem; height: 18rem;')
				with: [ :body | self renderTranscriptOn: body ].
			self renderExceptionDebuggerWindowsOn: desktop ].
	self renderTaskBarOn: html
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerOn: html [
	self renderDebuggerContentsOn: html state: self debuggerState
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDesktopContextMenuOn: html [
	html div
		id: 'sig-context-menu';
		class: 'sig-context-menu';
		with: [
				html div class: 'sig-context-group'; with: [
					html paragraph class: 'sig-context-title'; with: 'Windows'.
					self renderLocalWindowCommandOn: html label: 'Open Explorer' target: 'sig-window-explorer'.
					self renderLocalWindowCommandOn: html label: 'Open Workspace' target: 'sig-window-workspace'.
					self renderLocalWindowCommandOn: html label: 'Open Class Browser' target: 'sig-window-browser'.
					self renderLocalWindowCommandOn: html label: 'Open Symbol List Browser' target: 'sig-window-symbol-list'.
					self renderLocalWindowCommandOn: html label: 'Open Inspector' target: 'sig-window-inspector'.
					self renderLocalWindowCommandOn: html label: 'Open Debugger' target: 'sig-window-debugger'.
					debuggerWindows do: [ :each |
						self
							renderLocalWindowCommandOn: html
							label: ('Open ', (each at: #title))
							target: (each at: #id) ].
					self renderLocalWindowCommandOn: html label: 'Open Session' target: 'sig-window-session'.
					self renderLocalWindowCommandOn: html label: 'Open Transcript' target: 'sig-window-transcript' ].
					html div class: 'sig-context-group'; with: [
						html paragraph class: 'sig-context-title'; with: 'Arrange'.
						self renderLocalDesktopActionOn: html label: 'Cascade Windows' action: 'cascade'.
						self renderLocalDesktopActionOn: html label: 'Tile Windows' action: 'tile'.
						self renderLocalDesktopActionOn: html label: 'Show All Windows' action: 'show-all'.
						self renderLocalDesktopActionOn: html label: 'Minimise All Windows' action: 'minimise-all'.
						self renderLocalDesktopActionOn: html label: 'Close All Windows' action: 'close-all' ].
				html div class: 'sig-context-group'; with: [
					html paragraph class: 'sig-context-title'; with: 'Session'.
					self renderActionLinkOn: html label: 'Refresh' callback: [ self refresh ].
				self renderActionLinkOn: html label: 'Commit' callback: [ self commitTransaction ].
				self renderActionLinkOn: html label: 'Abort' callback: [ self abortTransaction ].
				self renderActionLinkOn: html label: 'Capture Walkback' callback: [ self captureDebuggerSnapshot ].
				self renderActionLinkOn: html label: 'Disconnect' callback: [ self disconnect ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderEntriesOn: html [
	| associations |
	associations := self entryAssociations.
	html heading level3; with: selectedRootName asString.
	html div class: 'sig-scroll-pane sig-entry-pane'; with: [
		associations isEmpty
			ifTrue: [ html paragraph: 'No entries available.' ]
			ifFalse: [
				html table class: 'sig-table'; with: [
					html tableHead: [
						html tableRow: [
							html tableHeading: 'Key'.
							html tableHeading: 'Value summary' ] ].
					html tableBody: [
						associations do: [ :each |
							html tableRow: [
								html tableData: [
									html anchor
										attributeAt: 'data-sig-remote' put: 'true';
										callback: [ self selectEntryKey: each key asString ];
										with: each key asString ].
								html tableData: (self gateway displayStringFor: each value) ] ] ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderExplorerOn: html [
	html div class: 'sig-layout'; with: [
		html div class: 'sig-sidebar'; with: [ self renderRootsOn: html ].
		html div class: 'sig-main'; with: [
			self renderEntriesOn: html.
			self renderSelectedEntryOn: html ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerCommandOn: html label: aLabel selected: aBoolean enabled: isEnabled callback: aBlock [
	isEnabled
		ifTrue: [
			html anchor
				class: (aBoolean
					ifTrue: [ 'sig-action sig-debugger-command selected' ]
					ifFalse: [ 'sig-action sig-debugger-command' ]);
				attributeAt: 'data-sig-remote' put: 'true';
				callback: aBlock;
				with: aLabel ]
		ifFalse: [
			html span
				class: (aBoolean
					ifTrue: [ 'sig-action sig-debugger-command selected disabled' ]
					ifFalse: [ 'sig-action sig-debugger-command disabled' ]);
				with: aLabel ].
	html space
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerCommandsOn: html state: aState [
	| showBridgeFrames |
	showBridgeFrames := aState at: #showBridgeFrames ifAbsent: [ false ].
	html div class: 'sig-debugger-utility-bar'; with: [
			self
				renderDebuggerCommandOn: html
				label: 'Frames'
				selected: showBridgeFrames not
				enabled: true
				callback: [ self showDebuggerFramesInState: aState includeBridge: false ].
			self
				renderDebuggerCommandOn: html
				label: 'Previous'
				selected: false
				enabled: true
				callback: [ self moveDebuggerSelectionInState: aState offset: -1 includeBridge: false ].
			self
				renderDebuggerCommandOn: html
				label: 'Next'
				selected: false
				enabled: true
				callback: [ self moveDebuggerSelectionInState: aState offset: 1 includeBridge: false ].
			self
				renderDebuggerCommandOn: html
				label: 'Frames + Bridge'
				selected: showBridgeFrames
				enabled: true
				callback: [ self showDebuggerFramesInState: aState includeBridge: true ].
			self
				renderDebuggerCommandOn: html
				label: 'Prev + Bridge'
				selected: false
				enabled: true
				callback: [ self moveDebuggerSelectionInState: aState offset: -1 includeBridge: true ].
			self
				renderDebuggerCommandOn: html
				label: 'Next + Bridge'
				selected: false
				enabled: true
				callback: [ self moveDebuggerSelectionInState: aState offset: 1 includeBridge: true ].
			html span class: 'sig-debugger-bridge-note'; with: (self debuggerBridgeStatusTextForState: aState ) ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerLiveActionOn: html label: aLabel enabled: isEnabled callback: aBlock [
	isEnabled
		ifTrue: [
			html anchor
				class: 'btn-dbg';
				attributeAt: 'data-sig-remote' put: 'true';
				callback: aBlock;
				with: aLabel ]
		ifFalse: [
			html span
				class: 'btn-dbg disabled';
				with: aLabel ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerLiveCommandsOn: html state: aState [
	html div class: 'dbg-action-bar'; with: [
		self
			renderDebuggerLiveActionOn: html
			label: 'Refresh'
			enabled: ((aState at: #debugSessionId ifAbsent: [ nil ]) notNil)
			callback: [ self performDebuggerAction: #refresh inState: aState ].
		self
			renderDebuggerLiveActionOn: html
			label: 'Proceed'
			enabled: (aState at: #canProceed ifAbsent: [ false ])
			callback: [ self performDebuggerAction: #resume inState: aState ].
		self
			renderDebuggerLiveActionOn: html
			label: 'Restart'
			enabled: (aState at: #canRestart ifAbsent: [ false ])
			callback: [ self performDebuggerAction: #restart inState: aState ].
		self
			renderDebuggerLiveActionOn: html
			label: 'Step'
			enabled: (aState at: #canStepInto ifAbsent: [ false ])
			callback: [ self performDebuggerAction: #step inState: aState ].
		self
			renderDebuggerLiveActionOn: html
			label: 'Step into'
			enabled: (aState at: #canStepInto ifAbsent: [ false ])
			callback: [ self performDebuggerAction: #stepInto inState: aState ].
		self
			renderDebuggerLiveActionOn: html
			label: 'Step over'
			enabled: (aState at: #canStepOver ifAbsent: [ false ])
			callback: [ self performDebuggerAction: #stepOver inState: aState ].
		self
			renderDebuggerLiveActionOn: html
			label: 'Step out'
			enabled: (aState at: #canStepOut ifAbsent: [ false ])
			callback: [ self performDebuggerAction: #stepReturn inState: aState ].
		self
			renderDebuggerLiveActionOn: html
			label: 'Terminate'
			enabled: (aState at: #canTerminate ifAbsent: [ false ])
			callback: [ self performDebuggerAction: #terminate inState: aState ] ].
	html div class: 'sig-debugger-status-row'; with: [
		html span class: 'sig-debugger-session-note'; with: (self debuggerSessionStatusTextForState: aState) ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerContentsOn: html state: aState [
	| selectedFrame |
	selectedFrame := self selectedDebuggerFrameInState: aState.
	html div
		class: 'sig-debugger-shell';
		with: [
			html div class: 'dbg-summary'; with: [
				html div class: 'dbg-summary-source'; with: (self debuggerFrameSourceStatusTextFor: selectedFrame).
				html div class: 'dbg-summary-error'; with: (aState at: #errorText ifAbsent: [ 'No gateway errors recorded.' ]) ].
			self renderDebuggerFramesOn: html state: aState.
			self renderDebuggerCommandsOn: html state: aState.
			self renderDebuggerLiveCommandsOn: html state: aState.
			self renderDebuggerFrameDetailsOn: html state: aState.
			self renderDebuggerDiagnosticsOn: html state: aState ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerFrameDetailsOn: html state: aState [
	| selectedFrame |
	selectedFrame := self selectedDebuggerFrameInState: aState.
	html div class: 'dbg-source-pane'; with: [
		html div class: 'dbg-source-meta'; with: (self debuggerFrameSourceMetaTextFor: selectedFrame).
	html div
		class: 'dbg-source-code sig-scroll-pane sig-debugger-pane sig-debugger-source-pane';
		attributeAt: 'data-sig-scroll-follow' put: 'selected';
		attributeAt: 'data-sig-scroll-key' put: (self debuggerSourceScrollKeyForState: aState);
		with: [
		self renderDebuggerSourceOn: html frame: selectedFrame ].
		html div class: 'dbg-self-bar'; with: [
			html span class: 'dbg-self-label'; with: 'self:'.
			html span class: 'dbg-self-val'; with: (self debuggerFrameReceiverTextFor: selectedFrame) ].
		html div class: 'dbg-var-row'; with: [
			html span class: 'dbg-self-label'; with: 'variables:'.
			html span class: 'dbg-var-val'; with: (self debuggerFrameVariableSummaryTextFor: selectedFrame) ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerDiagnosticsOn: html state: aState [
	| currentWalkback selectedFrame variableRecords |
	selectedFrame := self selectedDebuggerFrameInState: aState.
	variableRecords := self debuggerFrameVariableRecordsFor: selectedFrame.
	currentWalkback := aState at: #walkback ifAbsent: [ 'No debugger snapshot captured yet.' ].
	html div class: 'sig-debugger-diagnostic-grid'; with: [
		html div class: 'sig-debugger-panel sig-debugger-diagnostic-panel'; with: [
			html heading level3; with: 'Frame details'.
			html div class: 'sig-scroll-pane sig-debugger-pane sig-debugger-pane-short sig-debugger-detail-pane'; with: [
				html preformatted class: 'sig-pre'; with: (self debuggerFrameDetailTextFor: selectedFrame) ] ].
		html div class: 'sig-debugger-panel sig-debugger-diagnostic-panel'; with: [
			html heading level3; with: 'Locals'.
			html div class: 'sig-scroll-pane sig-debugger-pane sig-debugger-pane-short'; with: [
				variableRecords isEmpty
					ifTrue: [ html paragraph class: 'sig-window-note'; with: 'No arguments or temporaries reported for this frame.' ]
					ifFalse: [
						html unorderedList class: 'dbg-tls-list'; with: [
							variableRecords do: [ :each |
								html listItem: [
									html span class: 'tls-key'; with: (each at: #name ifAbsent: [ 'var' ]).
									html span class: 'tls-val'; with: (each at: #value ifAbsent: [ 'nil' ]) ] ] ] ] ] ] ].
	html div class: 'sig-debugger-diagnostic-grid'; with: [
		html div class: 'sig-debugger-panel sig-debugger-diagnostic-panel'; with: [
			html heading level3; with: 'Gateway status'.
			html div class: 'sig-scroll-pane sig-debugger-pane sig-debugger-pane-short'; with: [
				html preformatted class: 'sig-pre'; with: (self debuggerGatewayStatusTextForState: aState) ] ] ].
	html heading level3; with: 'Current walkback'.
	html div class: 'sig-scroll-pane sig-debugger-pane'; with: [
		html preformatted class: 'sig-pre'; with: currentWalkback ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerFramesOn: html state: aState [
	| selectedFrameLevel visibleFrames |
	self ensureDebuggerSelectionInState: aState.
	visibleFrames := self debuggerVisibleFramesInState: aState.
	selectedFrameLevel := aState at: #selectedFrameLevel ifAbsent: [ nil ].
	html div
		class: 'sig-scroll-pane sig-debugger-frame-list';
		attributeAt: 'aria-label' put: 'Stack contexts';
		attributeAt: 'data-sig-scroll-follow' put: 'selected';
		attributeAt: 'data-sig-scroll-key' put: (self debuggerFrameListScrollKeyForState: aState);
		with: [
		visibleFrames isEmpty
			ifTrue: [
				html paragraph
					class: 'sig-window-note';
					with: 'No visible context frames. Use Show With Bridge to include bridge frames.' ]
			ifFalse: [
				html unorderedList class: 'sig-debugger-frames'; with: [
					visibleFrames do: [ :each |
						| frameLevel isBridge |
						frameLevel := each at: #level.
						isBridge := each at: #isBridge ifAbsent: [ false ].
						html listItem: [
							html anchor
								class: (frameLevel = selectedFrameLevel
									ifTrue: [ 'dbg-frame-item sig-debugger-frame selected active' ]
									ifFalse: [ 'dbg-frame-item sig-debugger-frame' ]);
								attributeAt: 'data-sig-remote' put: 'true';
								callback: [ self selectDebuggerFrameLevel: frameLevel inState: aState ];
								with: [
									html span
										class: (isBridge ifTrue: [ 'dbg-frame-icon ruby' ] ifFalse: [ 'dbg-frame-icon' ]);
										with: (isBridge ifTrue: [ 'R' ] ifFalse: [ 'S' ]).
									html span class: 'sig-debugger-frame-level'; with: frameLevel printString.
									html span class: 'sig-debugger-frame-text'; with: (self debuggerFrameSummaryFor: each) ] ] ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerSourceOn: html frame: aFrame [
	| currentLineNumber lines sourceText |
	sourceText := self debuggerFrameSourceTextFor: aFrame.
	((aFrame isNil) or: [ sourceText = 'Source unavailable for this frame.' ]) ifTrue: [
		html preformatted class: 'sig-pre'; with: sourceText.
		^ self ].
	lines := self debuggerSourceLinesFor: sourceText.
	currentLineNumber := self debuggerFrameSourceLineNumberFor: aFrame.
	html div class: 'sig-debugger-source-lines'; with: [
		1 to: lines size do: [ :index |
			html div
				class: (index = currentLineNumber
					ifTrue: [ 'dbg-source-line sig-debugger-source-line current selected active' ]
					ifFalse: [ 'dbg-source-line sig-debugger-source-line' ]);
				with: [
					html span class: 'dbg-source-marker'; with: (index = currentLineNumber ifTrue: [ '>' ] ifFalse: [ ' ' ]).
					html span class: 'sig-debugger-source-gutter'; with: index printString.
					html preformatted
						class: 'sig-pre dbg-source-text sig-debugger-source-code';
						with: (lines at: index) ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderExceptionDebuggerOn: html window: aWindow [
	self renderDebuggerContentsOn: html state: aWindow
]

{ #category : 'rendering' }
SigExplorerApplication >> renderExceptionDebuggerWindowsOn: html [
	debuggerWindows do: [ :each |
		self
			renderFloatingWindowOn: html
			id: (each at: #id)
			title: (each at: #title)
			subtitle: (each at: #subtitle)
			position: (each at: #position)
			with: [ :body | self renderExceptionDebuggerOn: body window: each ] ]
]

{ #category : 'private' }
SigExplorerApplication >> hiddenWindowPosition: aPositionString [
	^ aPositionString, ' display: none;'
]

{ #category : 'rendering' }
SigExplorerApplication >> renderFloatingWindowOn: html id: anId title: aTitle subtitle: aSubtitle position: aPositionString with: aBlock [
	html div
		id: anId;
		class: 'sig-floating-window';
		style: aPositionString;
		with: [ :window |
			window div class: 'sig-window-titlebar'; with: [ :titleBar |
				titleBar div class: 'sig-window-controls'; with: [ :controls |
					controls anchor
						class: 'sig-window-control close';
						attributeAt: 'href' put: '#';
						attributeAt: 'data-sig-window-action' put: 'close';
						attributeAt: 'title' put: 'Close window';
						attributeAt: 'aria-label' put: 'Close window';
						with: ''.
						controls anchor
							class: 'sig-window-control collapse';
							attributeAt: 'href' put: '#';
							attributeAt: 'data-sig-window-action' put: 'collapse';
							attributeAt: 'title' put: 'Minimise window';
							attributeAt: 'aria-label' put: 'Minimise window';
							with: ''.
					controls anchor
						class: 'sig-window-control expand';
						attributeAt: 'href' put: '#';
						attributeAt: 'data-sig-window-action' put: 'expand';
						attributeAt: 'title' put: 'Expand window';
						attributeAt: 'aria-label' put: 'Expand window';
						with: '' ].
					titleBar div class: 'sig-window-headings'; with: [ :headings |
						headings heading level2; with: aTitle.
						headings span class: 'sig-window-subtitle'; with: aSubtitle ] ].
				window div class: 'sig-window-body'; with: [ :body | aBlock value: body ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderLocalWindowCommandOn: html label: aLabel target: aTargetId [
	html anchor
		class: 'sig-local-command';
		attributeAt: 'href' put: '#';
		attributeAt: 'data-window-target' put: aTargetId;
		with: aLabel
]

{ #category : 'rendering' }
SigExplorerApplication >> renderLocalDesktopActionOn: html label: aLabel action: anAction [
	html anchor
		class: 'sig-local-command';
		attributeAt: 'href' put: '#';
		attributeAt: 'data-desktop-action' put: anAction;
		with: aLabel
]

{ #category : 'rendering' }
SigExplorerApplication >> renderMenuActionOn: html label: aLabel callback: aBlock [
	html anchor
		class: 'sig-menu-item';
		attributeAt: 'data-sig-remote' put: 'true';
		callback: aBlock;
		with: aLabel
]

{ #category : 'rendering' }
SigExplorerApplication >> renderMenuBarOn: html [
	html div class: 'sig-menu-bar'; with: [ :bar |
		bar div class: 'sig-menu-brand'; with: 'GemStone Desktop'.
		bar div class: 'sig-menu-strip'; with: [ :strip |
			self renderMenuDropdownOn: strip label: 'Windows' with: [ :menu |
				self renderMenuWindowCommandOn: menu label: 'Explorer' target: 'sig-window-explorer'.
				self renderMenuWindowCommandOn: menu label: 'Workspace' target: 'sig-window-workspace'.
				self renderMenuWindowCommandOn: menu label: 'Class Browser' target: 'sig-window-browser'.
				self renderMenuWindowCommandOn: menu label: 'Symbol List Browser' target: 'sig-window-symbol-list'.
				self renderMenuWindowCommandOn: menu label: 'Inspector' target: 'sig-window-inspector'.
				self renderMenuWindowCommandOn: menu label: 'Debugger' target: 'sig-window-debugger'.
				debuggerWindows do: [ :each |
					self
						renderMenuWindowCommandOn: menu
						label: (each at: #title)
						target: (each at: #id) ].
				self renderMenuWindowCommandOn: menu label: 'Session' target: 'sig-window-session'.
				self renderMenuWindowCommandOn: menu label: 'Transcript' target: 'sig-window-transcript' ].
			self renderMenuDropdownOn: strip label: 'Arrange' with: [ :menu |
				self renderMenuDesktopActionOn: menu label: 'Cascade Windows' action: 'cascade'.
				self renderMenuDesktopActionOn: menu label: 'Tile Windows' action: 'tile'.
				self renderMenuDesktopActionOn: menu label: 'Show All Windows' action: 'show-all'.
				self renderMenuDesktopActionOn: menu label: 'Minimise All Windows' action: 'minimise-all' ].
			self renderMenuDropdownOn: strip label: 'Session' with: [ :menu |
				self renderMenuActionOn: menu label: 'Refresh' callback: [ self refresh ].
				self renderMenuActionOn: menu label: 'Commit' callback: [ self commitTransaction ].
				self renderMenuActionOn: menu label: 'Abort' callback: [ self abortTransaction ].
				self renderMenuActionOn: menu label: 'Capture Walkback' callback: [ self captureDebuggerSnapshot ].
				self renderMenuActionOn: menu label: 'Disconnect' callback: [ self disconnect ] ].
			self renderMenuDropdownOn: strip label: 'Workspace' with: [ :menu |
				self renderMenuWindowCommandOn: menu label: 'Open Workspace' target: 'sig-window-workspace'.
				self renderMenuWindowCommandOn: menu label: 'Open Transcript' target: 'sig-window-transcript'.
				self renderMenuActionOn: menu label: 'Clear Output' callback: [ self clearWorkspaceOutput ].
				self renderMenuActionOn: menu label: 'Clear Transcript' callback: [ self clearTranscript ] ] ].
		bar div class: 'sig-menu-status'; with: [
			bar span class: 'sig-session-label'; with: self gateway connectionSummary.
			statusMessage ifNotNil: [
				bar span class: 'sig-status-badge'; with: statusMessage ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderMenuDesktopActionOn: html label: aLabel action: anAction [
	html anchor
		class: 'sig-menu-item';
		attributeAt: 'href' put: '#';
		attributeAt: 'data-desktop-action' put: anAction;
		with: aLabel
]

{ #category : 'rendering' }
SigExplorerApplication >> renderMenuDropdownOn: html label: aLabel with: aBlock [
	html div class: 'sig-menu'; with: [ :menu |
		menu anchor
			class: 'sig-menu-trigger';
			attributeAt: 'href' put: '#';
			attributeAt: 'data-menu-trigger' put: 'true';
			with: aLabel.
		menu div class: 'sig-menu-panel'; with: [ :panel | aBlock value: panel ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderMenuWindowCommandOn: html label: aLabel target: aTargetId [
	html anchor
		class: 'sig-menu-item';
		attributeAt: 'href' put: '#';
		attributeAt: 'data-window-target' put: aTargetId;
		with: aLabel
]

{ #category : 'actions' }
SigExplorerApplication >> refresh [
	self setStatusMessage: 'Refreshed explorer, workspace, browser, symbol list browser, inspector, debugger, session, and transcript'
]

{ #category : 'rendering' }
SigExplorerApplication >> renderRootsOn: html [
	html heading level3; with: 'Roots'.
	html div class: 'sig-scroll-pane sig-root-pane'; with: [
		html unorderedList: [
			self gateway rootNames do: [ :each |
				html listItem: [
					html anchor
						class: (each = selectedRootName ifTrue: [ 'sig-root selected' ] ifFalse: [ 'sig-root' ]);
						attributeAt: 'data-sig-remote' put: 'true';
						callback: [ self selectRootNamed: each ];
						with: each asString ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderSelectedEntryOn: html [
	| association |
	association := self selectedAssociation.
	html heading level3; with: 'Selected entry'.
	html div class: 'sig-scroll-pane sig-detail-pane'; with: [
		association
			ifNil: [ html paragraph: 'Select an entry to inspect its value.' ]
			ifNotNil: [
				html definitionList: [
					html definitionTerm: 'Key'.
					html definitionData: association key asString.
					html definitionTerm: 'Value'.
					html definitionData: (self gateway displayStringFor: association value) ].
				html div class: 'sig-command-row'; with: [
					self renderWindowActionLinkOn: html label: 'Open Inspector' target: 'sig-window-inspector' ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderInspectorOn: html [
	html div class: 'sig-source-window'; with: [
		html heading level3; with: inspectorLabel.
		html div class: 'sig-scroll-pane sig-inspector-pane'; with: [
			html preformatted class: 'sig-pre'; with: inspectorText ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderSessionOn: html [
	html paragraph class: 'sig-window-note'; with: 'A compact session window inspired by the client-side GemStone tools: connection state, transaction commands, and current navigation focus.'.
	html div class: 'sig-command-row'; with: [
		self renderActionLinkOn: html label: 'Refresh' callback: [ self refresh ].
		self renderActionLinkOn: html label: 'Commit' callback: [ self commitTransaction ].
		self renderActionLinkOn: html label: 'Abort' callback: [ self abortTransaction ].
		self renderActionLinkOn: html label: 'Capture Walkback' callback: [ self captureDebuggerSnapshot ].
		self renderActionLinkOn: html label: 'Disconnect' callback: [ self disconnect ] ].
	html div class: 'sig-session-grid'; with: [
		html div class: 'sig-session-panel'; with: [
			html heading level3; with: 'Connection'.
			html definitionList class: 'sig-summary-list'; with: [
				html definitionTerm: 'Gateway'.
				html definitionData: self gateway connectionSummary.
				html definitionTerm: 'Root'.
				html definitionData: selectedRootName asString.
				html definitionTerm: 'Status'.
				html definitionData: (statusMessage ifNil: [ 'No status yet.' ] ifNotNil: [ statusMessage ]) ] ].
		html div class: 'sig-session-panel'; with: [
			html heading level3; with: 'Focus'.
			html definitionList class: 'sig-summary-list'; with: [
				html definitionTerm: 'Browser'.
				html definitionData: self selectedBrowserSummary.
				html definitionTerm: 'Symbol List'.
				html definitionData: self selectedSymbolListSummary.
				html definitionTerm: 'Explorer Entry'.
				html definitionData: (selectedEntryKey ifNil: [ 'No explorer entry selected.' ] ifNotNil: [ selectedEntryKey ]).
				html definitionTerm: 'Inspector'.
				html definitionData: inspectorLabel ] ].
		html div class: 'sig-session-panel'; with: [
			html heading level3; with: 'Diagnostics'.
			html definitionList class: 'sig-summary-list'; with: [
				html definitionTerm: 'Last Error'.
				html definitionData: (self gateway lastErrorText ifNil: [ 'No gateway errors recorded.' ] ifNotNil: [ self gateway lastErrorText ]).
				html definitionTerm: 'Workspace'.
				html definitionData: (self transcriptPreviewOf: workspaceResultText) ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderTaskBarOn: html [
	html div
		id: 'sig-taskbar';
		class: 'sig-taskbar';
		with: [
			html div class: 'sig-taskbar-brand'; with: 'GemStone Desktop'.
			html div class: 'sig-taskbar-strip'; with: [
				self renderTaskBarWindowCommandOn: html label: 'Explorer' target: 'sig-window-explorer' pinned: true.
				self renderTaskBarWindowCommandOn: html label: 'Workspace' target: 'sig-window-workspace' pinned: true.
				self renderTaskBarWindowCommandOn: html label: 'Class Browser' target: 'sig-window-browser'.
				self renderTaskBarWindowCommandOn: html label: 'Symbols' target: 'sig-window-symbol-list'.
				self renderTaskBarWindowCommandOn: html label: 'Inspector' target: 'sig-window-inspector'.
				self renderTaskBarWindowCommandOn: html label: 'Debugger' target: 'sig-window-debugger'.
				debuggerWindows do: [ :each |
					self
						renderTaskBarWindowCommandOn: html
						label: (each at: #taskbarLabel)
						target: (each at: #id) ].
				self renderTaskBarWindowCommandOn: html label: 'Session' target: 'sig-window-session'.
				self renderTaskBarWindowCommandOn: html label: 'Transcript' target: 'sig-window-transcript' ].
				html div class: 'sig-taskbar-strip sig-taskbar-strip-secondary'; with: [
					self renderTaskBarActionCommandOn: html label: 'Cascade' action: 'cascade'.
					self renderTaskBarActionCommandOn: html label: 'Tile' action: 'tile'.
					self renderTaskBarActionCommandOn: html label: 'Show All' action: 'show-all'.
					self renderTaskBarActionCommandOn: html label: 'Minimise All' action: 'minimise-all'.
					self renderTaskBarActionCommandOn: html label: 'Close All' action: 'close-all' ].
			html div class: 'sig-taskbar-strip sig-taskbar-strip-secondary sig-taskbar-strip-menus'; with: [ :strip |
				self renderMenuDropdownOn: strip label: 'Windows' with: [ :menu |
					self renderWindowMenuItemsOn: menu ].
				self renderMenuDropdownOn: strip label: 'Arrange' with: [ :menu |
					self renderArrangeMenuItemsOn: menu ].
				self renderMenuDropdownOn: strip label: 'Session' with: [ :menu |
					self renderSessionMenuItemsOn: menu ].
				self renderMenuDropdownOn: strip label: 'Workspace' with: [ :menu |
					self renderWorkspaceMenuItemsOn: menu ] ].
			html div class: 'sig-taskbar-status'; with: [
				html span class: 'sig-taskbar-session'; with: self gateway connectionSummary.
				statusMessage ifNotNil: [
					html span class: 'sig-taskbar-note'; with: statusMessage ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderTaskBarActionCommandOn: html label: aLabel action: anAction [
	html anchor
		class: 'sig-taskbar-button sig-taskbar-command';
		attributeAt: 'href' put: '#';
		attributeAt: 'data-desktop-action' put: anAction;
		with: aLabel
]

{ #category : 'rendering' }
SigExplorerApplication >> renderTaskBarWindowCommandOn: html label: aLabel target: aTargetId [
	self renderTaskBarWindowCommandOn: html label: aLabel target: aTargetId pinned: false
]

{ #category : 'rendering' }
SigExplorerApplication >> renderTaskBarWindowCommandOn: html label: aLabel target: aTargetId pinned: aBoolean [
	| anchor |
	anchor := html anchor.
	anchor
		class: 'sig-taskbar-button';
		attributeAt: 'href' put: '#';
		attributeAt: 'data-window-target' put: aTargetId.
	aBoolean ifTrue: [
		anchor attributeAt: 'data-sig-taskbar-pinned' put: 'true' ].
	anchor with: aLabel
]

{ #category : 'rendering' }
SigExplorerApplication >> renderWindowMenuItemsOn: html [
	self renderMenuWindowCommandOn: html label: 'Explorer' target: 'sig-window-explorer'.
	self renderMenuWindowCommandOn: html label: 'Workspace' target: 'sig-window-workspace'.
	self renderMenuWindowCommandOn: html label: 'Class Browser' target: 'sig-window-browser'.
	self renderMenuWindowCommandOn: html label: 'Symbol List Browser' target: 'sig-window-symbol-list'.
	self renderMenuWindowCommandOn: html label: 'Inspector' target: 'sig-window-inspector'.
	self renderMenuWindowCommandOn: html label: 'Debugger' target: 'sig-window-debugger'.
	debuggerWindows do: [ :each |
		self
			renderMenuWindowCommandOn: html
			label: (each at: #title)
			target: (each at: #id) ].
	self renderMenuWindowCommandOn: html label: 'Session' target: 'sig-window-session'.
	self renderMenuWindowCommandOn: html label: 'Transcript' target: 'sig-window-transcript'
]

{ #category : 'rendering' }
SigExplorerApplication >> renderArrangeMenuItemsOn: html [
	self renderMenuDesktopActionOn: html label: 'Cascade Windows' action: 'cascade'.
	self renderMenuDesktopActionOn: html label: 'Tile Windows' action: 'tile'.
	self renderMenuDesktopActionOn: html label: 'Show All Windows' action: 'show-all'.
	self renderMenuDesktopActionOn: html label: 'Minimise All Windows' action: 'minimise-all'.
	self renderMenuDesktopActionOn: html label: 'Close All Windows' action: 'close-all'
]

{ #category : 'rendering' }
SigExplorerApplication >> renderSessionMenuItemsOn: html [
	self renderMenuActionOn: html label: 'Refresh' callback: [ self refresh ].
	self renderMenuActionOn: html label: 'Commit' callback: [ self commitTransaction ].
	self renderMenuActionOn: html label: 'Abort' callback: [ self abortTransaction ].
	self renderMenuActionOn: html label: 'Capture Walkback' callback: [ self captureDebuggerSnapshot ].
	self renderMenuActionOn: html label: 'Disconnect' callback: [ self disconnect ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderWorkspaceMenuItemsOn: html [
	self renderMenuWindowCommandOn: html label: 'Open Workspace' target: 'sig-window-workspace'.
	self renderMenuWindowCommandOn: html label: 'Open Transcript' target: 'sig-window-transcript'.
	self renderMenuActionOn: html label: 'Do it' callback: [ self workspaceDoIt ].
	self renderMenuActionOn: html label: 'Print it' callback: [ self workspacePrintIt ].
	self renderMenuActionOn: html label: 'Inspect it' callback: [ self workspaceInspectIt ].
	self renderMenuActionOn: html label: 'Debug it' callback: [ self workspaceDebugIt ].
	self renderMenuActionOn: html label: 'Clear Output' callback: [ self clearWorkspaceOutput ].
	self renderMenuActionOn: html label: 'Clear Transcript' callback: [ self clearTranscript ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderTranscriptOn: html [
	html div class: 'sig-transcript-shell'; with: [
		html paragraph class: 'sig-window-note'; with: 'Transcript follows recent desktop activity, much like the client-side Jade and Jasper tools.'.
		html div class: 'sig-command-row'; with: [
			self renderActionLinkOn: html label: 'Clear Transcript' callback: [ self clearTranscript ].
			self renderActionLinkOn: html label: 'Capture Walkback' callback: [ self captureDebuggerSnapshot ] ].
		html div class: 'sig-scroll-pane sig-transcript-pane'; with: [
			transcriptEntries isEmpty
				ifTrue: [ html paragraph class: 'sig-empty-state'; with: 'Transcript is empty.' ]
				ifFalse: [
					transcriptEntries reverseDo: [ :each |
						html div class: 'sig-transcript-entry'; with: each ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderWorkspaceOn: html [
	html div class: 'sig-workspace-shell'; with: [
		html div class: 'ws-history sig-scroll-pane'; with: [
			html div class: 'ws-entry'; with: [
				html div class: 'ws-code'; with: [
					html preformatted class: 'sig-pre'; with: workspaceSourceText ].
				html div
					class: (self workspaceHasCapturedFailure ifTrue: [ 'ws-result error' ] ifFalse: [ 'ws-result' ]);
					with: [
						html span class: 'ws-result-text'; with: workspaceResultText ] ] ].
		html form
			class: 'sig-workspace-form';
			attributeAt: 'data-sig-remote' put: 'true';
			with: [
				html div class: 'ws-input-row'; with: [
					html textArea
						class: 'ws-code-area';
						attributeAt: 'spellcheck' put: 'false';
						attributeAt: 'wrap' put: 'off';
						attributeAt: 'placeholder' put: 'Smalltalk expression... (Ctrl+Enter)';
						rows: 8;
						callback: [ :value | workspaceSourceText := value ];
						value: workspaceSourceText.
					html div class: 'ws-controls'; with: [
						| doItButton |
						doItButton := html submitButton.
						doItButton
							class: 'btn';
							attributeAt: 'data-sig-primary-submit' put: 'workspace-doit';
							callback: [ self workspaceDoIt ];
							with: 'Do it'.
						html submitButton
							class: 'btn-ghost';
							callback: [ self workspacePrintIt ];
							with: 'Print it'.
						html submitButton
							class: 'btn-ghost';
							callback: [ self workspaceInspectIt ];
							with: 'Inspect it'.
						html submitButton
							class: 'btn-ghost';
							callback: [ self workspaceDebugIt ];
							with: 'Debug it'.
						html submitButton
							class: 'btn-ghost';
							callback: [ self clearWorkspaceOutput ];
							with: 'Clear'.
						html span class: 'ws-hint'; with: 'Ctrl+Enter' ] ].
				html div class: 'txbar'; with: [
					html span: 'Transaction:'.
					html submitButton
						class: 'btn-tx';
						callback: [ self abortTransaction ];
						with: 'Abort'.
					html submitButton
						class: 'btn-tx';
						callback: [ self commitTransaction ];
						with: 'Commit'.
					html submitButton
						class: 'btn-tx btn-tx-active';
						callback: [ self continueTransaction ];
						with: 'Continue' ] ] ]
]

{ #category : 'querying' }
SigExplorerApplication >> selectedAssociation [
	selectedEntryKey ifNil: [ ^ nil ].
	^ self entryAssociations
		detect: [ :each | each key asString = selectedEntryKey ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedBrowserClassName [
	^ selectedBrowserClassName
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedBrowserDictionaryName [
	^ selectedBrowserDictionaryName
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedBrowserProtocolName [
	^ selectedBrowserProtocolName
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedBrowserSelector [
	^ selectedBrowserSelector
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedEntryKey [
	^ selectedEntryKey
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedRootName [
	^ selectedRootName
]

{ #category : 'querying' }
SigExplorerApplication >> selectedSymbolListAssociation [
	selectedSymbolListEntryKey ifNil: [ ^ nil ].
	^ self symbolListEntryAssociations
		detect: [ :each | each key asString = selectedSymbolListEntryKey ]
		ifNone: [ nil ]
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedSymbolListDictionaryName [
	^ selectedSymbolListDictionaryName
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedSymbolListEntryKey [
	^ selectedSymbolListEntryKey
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceResultText [
	^ workspaceResultText
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceSourceText [
	^ workspaceSourceText
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceSourceText: aString [
	workspaceSourceText := aString
]

{ #category : 'accessing' }
SigExplorerApplication >> transcriptEntries [
	^ transcriptEntries
]

{ #category : 'accessing' }
SigExplorerApplication >> inspectorLabel [
	^ inspectorLabel
]

{ #category : 'accessing' }
SigExplorerApplication >> inspectorText [
	^ inspectorText
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedBrowserSummary [
	selectedBrowserClassName ifNil: [ ^ 'No browser class selected.' ].
	selectedBrowserSelector ifNotNil: [ ^ selectedBrowserClassName, ' >> ', selectedBrowserSelector ].
	selectedBrowserProtocolName ifNotNil: [ ^ selectedBrowserClassName, ' / ', selectedBrowserProtocolName ].
	^ selectedBrowserClassName
]

{ #category : 'private' }
SigExplorerApplication >> showInspectorForObject: anObject label: aString [
	inspectorLabel := aString.
	inspectorText := anObject
		ifNil: [ 'Nothing selected for inspection.' ]
		ifNotNil: [ self gateway inspectionStringFor: anObject ]
]

{ #category : 'private' }
SigExplorerApplication >> showInspectorText: aString label: aLabel [
	inspectorLabel := aLabel.
	inspectorText := aString ifNil: [ 'Nothing selected for inspection.' ]
]

{ #category : 'private' }
SigExplorerApplication >> requestExceptionDebuggerForLastError [
	| window |
	window := self newExceptionDebuggerWindowForLastError.
	self requestWindowShow: (window at: #id)
]

{ #category : 'private' }
SigExplorerApplication >> requestWindowShow: aWindowId [
	pendingWindowIdToShow := aWindowId
]

{ #category : 'private' }
SigExplorerApplication >> workspaceHasCapturedFailure [
	^ self gateway lastErrorStackText notNil
		or: [
			self gateway lastErrorText notNil
				or: [ self gateway lastErrorFrames notNil ] ]
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedSymbolListSummary [
	selectedSymbolListEntryKey ifNil: [ ^ selectedSymbolListDictionaryName asString ].
	^ selectedSymbolListDictionaryName asString, ' / ', selectedSymbolListEntryKey
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserClassNamed: aString [
	selectedBrowserClassName := aString.
	selectedBrowserProtocolName := nil.
	selectedBrowserSelector := nil.
	self setStatusMessage: 'Browsing class ', aString
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserDictionaryNamed: aSymbol [
	selectedBrowserDictionaryName := aSymbol.
	selectedBrowserClassName := nil.
	selectedBrowserProtocolName := nil.
	selectedBrowserSelector := nil.
	self setStatusMessage: 'Browsing dictionary ', aSymbol asString
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserProtocolNamed: aString [
	selectedBrowserProtocolName := aString.
	selectedBrowserSelector := nil.
	self setStatusMessage: 'Browsing protocol ', aString
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserSelectorNamed: aString [
	selectedBrowserSelector := aString.
	self setStatusMessage: 'Inspecting method ', aString
]

{ #category : 'actions' }
SigExplorerApplication >> selectEntryKey: aString [
	| association |
	selectedEntryKey := aString.
	association := self selectedAssociation.
	association ifNotNil: [
		self showInspectorForObject: association value label: 'Explorer / ', aString ].
	self setStatusMessage: 'Selected ', aString
]

{ #category : 'actions' }
SigExplorerApplication >> selectRootNamed: aSymbol [
	selectedRootName := aSymbol.
	selectedEntryKey := nil.
	self clearInspector.
	self setStatusMessage: 'Showing ', aSymbol asString
]

{ #category : 'actions' }
SigExplorerApplication >> selectSymbolListDictionaryNamed: aSymbol [
	selectedSymbolListDictionaryName := aSymbol.
	selectedSymbolListEntryKey := nil.
	self clearInspector.
	self setStatusMessage: 'Browsing symbol dictionary ', aSymbol asString
]

{ #category : 'actions' }
SigExplorerApplication >> selectSymbolListEntryKey: aString [
	| association |
	selectedSymbolListEntryKey := aString.
	association := self selectedSymbolListAssociation.
	association ifNotNil: [
		self showInspectorForObject: association value label: 'Symbol List / ', aString ].
	self setStatusMessage: 'Selected symbol binding ', aString
]

{ #category : 'private' }
SigExplorerApplication >> setStatusMessage: aString [
	statusMessage := aString.
	self addTranscriptLine: aString
]

{ #category : 'private' }
SigExplorerApplication >> transcriptPreviewOf: aString [
	| flattened text |
	text := aString ifNil: [ '' ].
	flattened := (text copyReplaceAll: String cr with: ' / ') copyReplaceAll: String lf with: ' / '.
	^ flattened size > 180
		ifTrue: [ (flattened first: 177), '...' ]
		ifFalse: [ flattened ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderSymbolListBrowserOn: html [
	| association |
	association := self selectedSymbolListAssociation.
	html paragraph class: 'sig-window-note'; with: 'Browse the current session symbol list in dictionary order, then inspect live bindings.'.
	html div class: 'sig-symbol-list-grid'; with: [
		self
			renderBrowserColumnOn: html
			title: 'Symbol dictionaries'
			items: self symbolListDictionaryNames
			selected: selectedSymbolListDictionaryName asString
			callback: [ :each | self selectSymbolListDictionaryNamed: each ].
		html div class: 'sig-browser-column'; with: [
			html heading level3; with: 'Bindings'.
			html div class: 'sig-scroll-pane sig-list-pane'; with: [
				self symbolListEntryAssociations isEmpty
					ifTrue: [ html paragraph class: 'sig-window-note'; with: 'No bindings.' ]
					ifFalse: [
						html unorderedList class: 'sig-browser-list'; with: [
							self symbolListEntryAssociations do: [ :each |
								html listItem: [
									html anchor
										class: (each key asString = selectedSymbolListEntryKey ifTrue: [ 'sig-browser-item selected' ] ifFalse: [ 'sig-browser-item' ]);
										attributeAt: 'data-sig-remote' put: 'true';
										callback: [ self selectSymbolListEntryKey: each key asString ];
										with: each key asString ] ] ] ] ] ].
		html div class: 'sig-source-window'; with: [
			html heading level3; with: 'Selected binding'.
			html div class: 'sig-scroll-pane sig-detail-pane'; with: [
				association ifNil: [
					html paragraph: 'Select a binding to inspect its value.' ]
				ifNotNil: [
					html definitionList: [
						html definitionTerm: 'Key'.
						html definitionData: association key asString.
						html definitionTerm: 'Value'.
						html definitionData: (self gateway displayStringFor: association value) ].
					html div class: 'sig-command-row'; with: [
						self renderWindowActionLinkOn: html label: 'Open Inspector' target: 'sig-window-inspector' ] ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderWindowActionLinkOn: html label: aLabel target: aTargetId [
	html anchor
		class: 'sig-action';
		attributeAt: 'href' put: '#';
		attributeAt: 'data-window-target' put: aTargetId;
		with: aLabel.
	html space
]

{ #category : 'rendering' }
SigExplorerApplication >> stylesheet [
	^ '
:root {
	--sig-bg: #11111b;
	--sig-surface-0: rgba(24, 24, 37, 0.96);
	--sig-surface-1: rgba(30, 30, 46, 0.96);
	--sig-surface-2: rgba(49, 50, 68, 0.94);
	--sig-surface-3: rgba(17, 17, 27, 0.82);
	--sig-window-bg: rgba(30, 30, 46, 0.96);
	--sig-window-border: rgba(69, 71, 90, 0.98);
	--sig-border: rgba(88, 91, 112, 0.88);
	--sig-border-soft: rgba(69, 71, 90, 0.92);
	--sig-text: #cdd6f4;
	--sig-muted: #a6adc8;
	--sig-subtle: #6c7086;
	--sig-accent: #89b4fa;
	--sig-accent-strong: #74c7ec;
	--sig-success: #a6e3a1;
	--sig-warning: #f9e2af;
	--sig-danger: #f38ba8;
	--sig-shadow: 0 28px 70px rgba(0, 0, 0, 0.42);
}

html,
body {
	height: 100%;
}

body {
	font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
	margin: 0;
	color: var(--sig-text);
	background:
		radial-gradient(circle at top left, rgba(137, 180, 250, 0.14), transparent 24rem),
		radial-gradient(circle at bottom right, rgba(203, 166, 247, 0.10), transparent 24rem),
		linear-gradient(180deg, #11111b 0%, #181825 45%, #11111b 100%);
}

body.sig-dragging {
	user-select: none;
	cursor: grabbing;
}

a {
	color: var(--sig-accent);
	text-decoration: none;
}

a:hover {
	text-decoration: underline;
}

.sig-menu-bar {
	position: fixed;
	top: 0;
	left: 0;
	right: 0;
	z-index: 2000;
	display: grid;
	grid-template-columns: auto 1fr auto;
	gap: 0.65rem;
	align-items: center;
	padding: 0.42rem 0.8rem;
	background: rgba(24, 24, 37, 0.96);
	border-bottom: 1px solid var(--sig-border-soft);
	backdrop-filter: blur(18px);
	box-shadow: 0 16px 38px rgba(0, 0, 0, 0.32);
	color: var(--sig-text);
}

.sig-menu-brand {
	font-size: 0.82rem;
	font-weight: 700;
	letter-spacing: 0.04em;
	color: var(--sig-accent);
	text-transform: uppercase;
}

.sig-menu-strip {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	gap: 0.4rem;
}

.sig-menu {
	position: relative;
}

.sig-menu-trigger {
	display: inline-flex;
	align-items: center;
	padding: 0.28rem 0.68rem;
	border-radius: 8px;
	background: rgba(49, 50, 68, 0.88);
	border: 1px solid var(--sig-border-soft);
	color: var(--sig-text);
	font-size: 0.78rem;
	font-weight: 600;
}

.sig-menu-trigger:hover {
	background: rgba(69, 71, 90, 0.96);
	text-decoration: none;
}

.sig-menu-panel {
	position: absolute;
	top: calc(100% + 0.45rem);
	left: 0;
	display: none;
	min-width: 14rem;
	padding: 0.5rem;
	border-radius: 12px;
	background: rgba(24, 24, 37, 0.98);
	border: 1px solid var(--sig-border);
	box-shadow: 0 20px 40px rgba(0, 0, 0, 0.42);
}

.sig-menu.open .sig-menu-panel {
	display: block;
}

.sig-menu-item {
	display: block;
	padding: 0.45rem 0.55rem;
	border-radius: 8px;
	color: var(--sig-text);
	font-size: 0.8rem;
	white-space: nowrap;
}

.sig-menu-item:hover {
	background: rgba(137, 180, 250, 0.12);
	color: #eef6ff;
	text-decoration: none;
}

.sig-menu-status {
	display: flex;
	flex-direction: column;
	align-items: flex-end;
	gap: 0.15rem;
}

.sig-session-label {
	font-size: 0.76rem;
	color: var(--sig-muted);
}

.sig-status-badge {
	max-width: 22rem;
	padding: 0.18rem 0.55rem;
	border-radius: 999px;
	background: rgba(137, 180, 250, 0.18);
	color: #eef6ff;
	font-size: 0.76rem;
	border: 1px solid rgba(137, 180, 250, 0.22);
}

.sig-taskbar {
	position: fixed;
	left: 0;
	right: 0;
	bottom: 0;
	z-index: 2400;
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	gap: 0.35rem 0.45rem;
	padding: 0.42rem 0.75rem;
	background: rgba(24, 24, 37, 0.96);
	backdrop-filter: blur(18px);
	border-top: 1px solid var(--sig-border-soft);
	box-shadow: 0 -12px 30px rgba(0, 0, 0, 0.28);
}

.sig-taskbar-brand {
	font-size: 0.78rem;
	font-weight: 700;
	color: var(--sig-accent);
	text-transform: uppercase;
	letter-spacing: 0.04em;
}

.sig-taskbar-strip {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	gap: 0.35rem;
}

.sig-taskbar-strip-secondary {
	padding-left: 0.35rem;
	border-left: 1px solid var(--sig-border-soft);
}

.sig-taskbar-strip-menus .sig-menu-trigger {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.28rem 0.72rem;
	border-radius: 8px;
	background: rgba(49, 50, 68, 0.88);
	border: 1px solid var(--sig-border-soft);
	color: var(--sig-text);
	font-size: 0.76rem;
	font-weight: 500;
}

.sig-taskbar-strip-menus .sig-menu-trigger:hover,
.sig-taskbar-strip-menus .sig-menu.open .sig-menu-trigger {
	background: rgba(69, 71, 90, 0.96);
	color: #eef6ff;
	text-decoration: none;
}

.sig-taskbar-strip-menus .sig-menu-panel {
	top: auto;
	bottom: calc(100% + 0.45rem);
}

.sig-taskbar-button {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.28rem 0.72rem;
	border-radius: 8px;
	background: rgba(49, 50, 68, 0.88);
	border: 1px solid var(--sig-border-soft);
	color: var(--sig-text);
	font-size: 0.76rem;
	white-space: nowrap;
}

.sig-taskbar-button:not(.sig-taskbar-command):not(.open):not([data-sig-taskbar-pinned="true"]) {
	display: none;
}

.sig-taskbar-button.open {
	background: rgba(137, 180, 250, 0.12);
	border-color: rgba(137, 180, 250, 0.22);
}

.sig-taskbar-button.active {
	background: rgba(137, 180, 250, 0.18);
	border-color: var(--sig-accent);
	color: #eef6ff;
	font-weight: 700;
}

.sig-taskbar-button:hover {
	text-decoration: none;
	background: rgba(69, 71, 90, 0.96);
}

.sig-taskbar-status {
	margin-left: auto;
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	justify-content: flex-end;
	gap: 0.45rem;
	font-size: 0.76rem;
	color: var(--sig-muted);
}

.sig-taskbar-note {
	padding: 0.18rem 0.5rem;
	border-radius: 999px;
	background: rgba(137, 180, 250, 0.16);
	color: #eef6ff;
	border: 1px solid rgba(137, 180, 250, 0.22);
}

.wa-toolbar {
	position: fixed !important;
	right: 0.85rem !important;
	left: auto !important;
	top: auto !important;
	bottom: 5rem !important;
	max-width: calc(100vw - 2rem);
	z-index: 2300 !important;
	border-radius: 12px;
	border: 1px solid var(--sig-border-soft);
	background: rgba(24, 24, 37, 0.94);
	box-shadow: 0 16px 36px rgba(0, 0, 0, 0.36);
}

.sig-desktop {
	position: relative;
	min-height: 100vh;
	padding-top: 1rem;
	padding-right: 1rem;
	padding-bottom: 4.2rem;
	overflow: auto;
}

.sig-floating-window {
	position: absolute;
	min-width: 22rem;
	max-width: calc(100vw - 2rem);
	min-height: 18rem;
	max-height: calc(100vh - 5.5rem);
	height: min(32rem, calc(68vh - 1rem));
	background: var(--sig-window-bg);
	border: 1px solid var(--sig-window-border);
	border-radius: 14px;
	box-shadow: var(--sig-shadow);
	backdrop-filter: blur(18px);
	overflow: hidden;
	resize: both;
	display: flex;
	flex-direction: column;
	z-index: 10;
}

.sig-floating-window.sig-window-active {
	border-color: rgba(137, 180, 250, 0.95);
	box-shadow: 0 18px 42px rgba(137, 180, 250, 0.10), 0 34px 84px rgba(0, 0, 0, 0.55);
}

.sig-window-titlebar {
	display: flex;
	align-items: center;
	justify-content: flex-start;
	gap: 0.75rem;
	padding: 0.55rem 0.75rem;
	background: #181825;
	border-bottom: 1px solid var(--sig-border-soft);
	color: var(--sig-text);
	cursor: grab;
}

.sig-window-headings h2 {
	margin: 0;
	font-size: 0.84rem;
	font-weight: 800;
	letter-spacing: 0.03em;
	color: #c7c9dd;
}

.sig-window-headings {
	flex: 1;
	min-width: 0;
}

.sig-window-subtitle {
	display: block;
	margin-top: 0.12rem;
	font-size: 0.68rem;
	color: var(--sig-subtle);
}

.sig-window-controls {
	display: flex;
	gap: 0.45rem;
	flex-shrink: 0;
}

.sig-window-control {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	width: 1.1rem;
	height: 1.1rem;
	padding: 0;
	border-radius: 999px;
	border: none;
	color: transparent;
	font-size: 0;
	line-height: 0;
	cursor: pointer;
}

.sig-window-control:hover {
	text-decoration: none;
	filter: brightness(1.06);
}

.sig-window-control.close {
	background: #ff5f57;
}

.sig-window-control.collapse {
	background: #febc2e;
}

.sig-window-control.expand {
	background: #28c840;
}

.sig-window-body {
	padding: 0;
	flex: 1 1 auto;
	min-height: 0;
	overflow-x: auto;
	overflow-y: scroll;
	display: flex;
	flex-direction: column;
	overscroll-behavior: contain;
	scrollbar-gutter: stable both-edges;
	scrollbar-width: thin;
	scrollbar-color: rgba(137, 180, 250, 0.55) rgba(17, 17, 27, 0.42);
}

.sig-window-body > * {
	min-height: 0;
}

.sig-floating-window.sig-window-collapsed {
	height: auto !important;
	min-height: 0;
	max-height: none;
	resize: none;
}

.sig-floating-window.sig-window-collapsed .sig-window-body {
	display: none;
}

.sig-floating-window.sig-window-maximized {
	resize: none;
}

.sig-layout {
	display: grid;
	grid-template-columns: 13rem 1fr;
	gap: 1rem;
	min-height: 0;
}

.sig-session-grid {
	display: grid;
	grid-template-columns: repeat(3, minmax(0, 1fr));
	gap: 0.75rem;
}

.sig-session-panel {
	background: var(--sig-surface-0);
	border: 1px solid var(--sig-border-soft);
	border-radius: 10px;
	padding: 0.85rem;
}

.sig-summary-list {
	margin: 0;
}

.sig-summary-list dt {
	font-size: 0.76rem;
	font-weight: 700;
	letter-spacing: 0.04em;
	text-transform: uppercase;
	color: var(--sig-muted);
}

.sig-summary-list dd {
	margin: 0.2rem 0 0.8rem;
	line-height: 1.45;
}

.sig-sidebar,
.sig-main,
.sig-browser-column,
.sig-source-window,
.sig-debugger-panel {
	background: var(--sig-surface-0);
	border: 1px solid var(--sig-border-soft);
	border-radius: 10px;
	padding: 0.85rem;
}

.sig-sidebar,
.sig-main,
.sig-source-window {
	display: flex;
	flex-direction: column;
	gap: 0.75rem;
	min-height: 0;
}

.sig-browser-grid {
	display: grid;
	grid-template-columns: repeat(4, minmax(0, 1fr));
	gap: 0.75rem;
	margin-bottom: 1rem;
}

.sig-symbol-list-grid {
	display: grid;
	grid-template-columns: 13rem 1fr 1fr;
	gap: 0.75rem;
}

.sig-debugger-layout {
	display: flex;
	flex-direction: column;
	gap: 0.75rem;
	margin-top: 0.8rem;
}

.sig-debugger-stack-panel,
.sig-debugger-controls-panel,
.sig-debugger-source-panel {
	display: flex;
	flex-direction: column;
	min-height: 0;
}

.sig-debugger-stack-panel h3,
.sig-debugger-controls-panel h3,
.sig-debugger-source-panel h3 {
	margin-top: 0;
}

.sig-debugger-command-row {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	gap: 0.35rem;
}

.sig-debugger-command {
	min-width: 3.5rem;
	margin: 0;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.76rem;
}

.sig-debugger-command.selected {
	background: rgba(137, 180, 250, 0.18);
	border-color: rgba(137, 180, 250, 0.36);
	font-weight: 700;
}

.sig-debugger-command.disabled {
	opacity: 0.5;
	border-style: dashed;
	cursor: default;
}

.sig-debugger-bridge-note {
	color: var(--sig-muted);
	font-size: 0.8rem;
}

.sig-debugger-session-note {
	color: var(--sig-muted);
	font-size: 0.8rem;
}

.sig-browser-list {
	list-style: none;
	padding: 0;
	margin: 0;
}

.sig-browser-list li,
.sig-sidebar li {
	margin-bottom: 0.28rem;
	list-style: none;
}

.sig-browser-item,
.sig-root {
	display: block;
	padding: 0.42rem 0.55rem;
	border-radius: 8px;
	background: rgba(17, 17, 27, 0.42);
	border: 1px solid transparent;
	color: var(--sig-muted);
}

.sig-browser-item:hover,
.sig-root:hover {
	background: rgba(49, 50, 68, 0.96);
	color: #eef6ff;
	text-decoration: none;
}

.sig-browser-item.selected,
.sig-root.selected {
	background: rgba(137, 180, 250, 0.14);
	border-color: rgba(137, 180, 250, 0.28);
	color: #eef6ff;
	font-weight: 700;
}

.sig-window-note {
	color: var(--sig-muted);
	margin-top: 0;
	line-height: 1.45;
}

.sig-command-row {
	margin-bottom: 0.8rem;
}

.sig-error {
	color: var(--sig-danger);
}

.sig-action {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	margin: 0 0.35rem 0.35rem 0;
	padding: 0.34rem 0.72rem;
	border-radius: 8px;
	background: rgba(49, 50, 68, 0.9);
	border: 1px solid var(--sig-border-soft);
	color: var(--sig-text);
	font-size: 0.78rem;
}

.sig-action:hover {
	background: rgba(69, 71, 90, 0.96);
	color: #eef6ff;
	text-decoration: none;
}

.sig-table {
	width: 100%;
	border-collapse: collapse;
}

.sig-table th {
	font-size: 0.68rem;
	font-weight: 700;
	letter-spacing: 0.08em;
	text-transform: uppercase;
	color: var(--sig-subtle);
	background: rgba(17, 17, 27, 0.55);
}

.sig-table th,
.sig-table td {
	border-top: 1px solid rgba(49, 50, 68, 0.82);
	padding: 0.48rem 0.52rem;
	text-align: left;
	vertical-align: top;
}

.sig-table tr:hover td {
	background: rgba(49, 50, 68, 0.26);
}

.sig-pre {
	white-space: pre-wrap;
	word-break: break-word;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.84rem;
	line-height: 1.5;
	margin: 0;
}

.sig-scroll-pane {
	overflow: auto;
	padding-right: 0.18rem;
	overscroll-behavior: contain;
	scrollbar-gutter: stable both-edges;
	scrollbar-width: thin;
	scrollbar-color: rgba(137, 180, 250, 0.55) rgba(17, 17, 27, 0.42);
}

.sig-window-body::-webkit-scrollbar,
.sig-scroll-pane::-webkit-scrollbar {
	width: 0.72rem;
	height: 0.72rem;
}

.sig-window-body::-webkit-scrollbar-track,
.sig-scroll-pane::-webkit-scrollbar-track {
	background: rgba(17, 17, 27, 0.42);
	border-radius: 999px;
}

.sig-window-body::-webkit-scrollbar-thumb,
.sig-scroll-pane::-webkit-scrollbar-thumb {
	background: linear-gradient(180deg, rgba(88, 145, 229, 0.9), rgba(48, 96, 170, 0.92));
	border: 2px solid rgba(17, 17, 27, 0.42);
	border-radius: 999px;
}

.sig-window-body::-webkit-scrollbar-thumb:hover,
.sig-scroll-pane::-webkit-scrollbar-thumb:hover {
	background: linear-gradient(180deg, rgba(120, 170, 240, 0.94), rgba(58, 108, 182, 0.96));
}

.sig-root-pane,
.sig-detail-pane {
	max-height: 15rem;
}

.sig-entry-pane {
	max-height: 19rem;
}

.sig-list-pane {
	max-height: 17rem;
}

.sig-source-pane {
	max-height: 18rem;
}

.sig-inspector-pane {
	max-height: 24rem;
}

.sig-debugger-pane {
	max-height: 16rem;
	overflow-y: scroll;
	overflow-x: auto;
}

.sig-debugger-pane-short {
	max-height: 7rem;
}

.sig-debugger-detail-pane {
	max-height: 8rem;
}

.sig-debugger-frame-list {
	max-height: 14rem;
	overflow-y: scroll;
	overflow-x: auto;
}

.sig-root-pane,
.sig-entry-pane,
.sig-detail-pane,
.sig-list-pane,
.sig-source-pane,
.sig-inspector-pane,
.sig-workspace-output-pane,
.sig-transcript-pane,
.sig-debugger-pane,
.sig-debugger-frame-list {
	background: rgba(17, 17, 27, 0.46);
	border: 1px solid rgba(49, 50, 68, 0.82);
	border-radius: 8px;
	padding: 0.45rem;
}

.sig-debugger-source-note {
	margin-bottom: 0.55rem;
}

.sig-debugger-source-pane {
	max-height: 24rem;
	min-height: 14rem;
	padding: 0.4rem 0;
	border: 1px solid rgba(69, 71, 90, 0.92);
	border-radius: 8px;
	background: rgba(17, 17, 27, 0.62);
	overflow-y: scroll;
	overflow-x: auto;
}

.sig-debugger-source-lines {
	display: flex;
	flex-direction: column;
}

.sig-debugger-source-line {
	display: grid;
	grid-template-columns: 3rem minmax(0, 1fr);
	gap: 0.75rem;
	align-items: start;
	padding: 0.16rem 0.8rem;
	border-left: 3px solid transparent;
}

.sig-debugger-source-line.current {
	background: rgba(137, 180, 250, 0.18);
	border-left-color: rgba(137, 180, 250, 0.98);
	box-shadow: inset 0 0 0 1px rgba(137, 180, 250, 0.12);
	scroll-margin-block: 1rem;
}

.sig-debugger-source-line.current .sig-debugger-source-gutter,
.sig-debugger-source-line.current .sig-debugger-source-code {
	color: #eef6ff;
}

.sig-debugger-source-gutter {
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.78rem;
	line-height: 1.5;
	text-align: right;
	color: var(--sig-muted);
	user-select: none;
}

.sig-debugger-source-code {
	min-width: 0;
}

.sig-debugger-diagnostic-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 0.75rem;
	margin-top: 0.8rem;
}

.sig-debugger-diagnostic-panel h3 {
	margin-top: 0;
}

.sig-debugger-frames {
	list-style: none;
	padding: 0;
	margin: 0;
	display: flex;
	flex-direction: column;
	gap: 0.35rem;
}

.sig-debugger-frame {
	display: grid;
	grid-template-columns: 2rem minmax(0, 1fr);
	gap: 0.55rem;
	align-items: start;
	padding: 0.55rem 0.65rem;
	border-radius: 8px;
	background: rgba(17, 17, 27, 0.55);
	border: 1px solid rgba(49, 50, 68, 0.92);
	color: var(--sig-text);
}

.sig-debugger-frame:hover {
	background: rgba(49, 50, 68, 0.96);
	color: #eef6ff;
	text-decoration: none;
}

.sig-debugger-frame.selected {
	background: rgba(137, 180, 250, 0.14);
	border-color: rgba(137, 180, 250, 0.34);
	font-weight: 700;
}

.sig-debugger-frame-level {
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	color: var(--sig-muted);
}

.sig-debugger-frame-text {
	min-width: 0;
	word-break: break-word;
}

.sig-context-menu {
	position: fixed;
	display: none;
	min-width: 15rem;
	padding: 0.85rem;
	border-radius: 12px;
	background: rgba(24, 24, 37, 0.98);
	border: 1px solid var(--sig-border);
	box-shadow: 0 24px 70px rgba(0, 0, 0, 0.48);
	z-index: 2500;
}

.sig-context-group + .sig-context-group {
	margin-top: 0.8rem;
	padding-top: 0.8rem;
	border-top: 1px solid var(--sig-border-soft);
}

.sig-context-title {
	margin: 0 0 0.55rem;
	font-size: 0.78rem;
	font-weight: 700;
	letter-spacing: 0.08em;
	text-transform: uppercase;
	color: var(--sig-muted);
}

.sig-context-menu .sig-action,
.sig-context-menu .sig-local-command {
	display: block;
	margin: 0 0 0.35rem;
	padding: 0.35rem 0.45rem;
	border-radius: 8px;
	color: var(--sig-text);
}

.sig-context-menu .sig-action:hover,
.sig-context-menu .sig-local-command:hover {
	background: rgba(49, 50, 68, 0.96);
	color: #eef6ff;
	text-decoration: none;
}

.sig-workspace-shell {
	display: flex;
	flex-direction: column;
	gap: 0.75rem;
}

.sig-transcript-shell {
	display: flex;
	flex-direction: column;
	gap: 0.75rem;
	height: 100%;
}

.sig-transcript-pane {
	display: flex;
	flex-direction: column;
	gap: 0.55rem;
	max-height: 18rem;
}

.sig-transcript-entry {
	padding: 0.6rem 0.75rem;
	border-radius: 8px;
	background: rgba(17, 17, 27, 0.58);
	border: 1px solid rgba(49, 50, 68, 0.92);
	font-size: 0.84rem;
	line-height: 1.45;
}

.sig-empty-state {
	color: var(--sig-muted);
	margin: 0;
}

.sig-workspace-form {
	display: flex;
	flex-direction: column;
	gap: 0.7rem;
}

.sig-workspace-editor {
	width: 100%;
	min-height: 15rem;
	padding: 0.85rem;
	border-radius: 8px;
	border: 1px solid rgba(69, 71, 90, 0.96);
	background: rgba(17, 17, 27, 0.82);
	box-sizing: border-box;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.86rem;
	line-height: 1.5;
	color: var(--sig-text);
}

.sig-workspace-editor:focus {
	outline: none;
	border-color: rgba(137, 180, 250, 0.86);
	box-shadow: inset 0 0 0 1px rgba(137, 180, 250, 0.22);
}

.sig-workspace-toolbar {
	display: flex;
	flex-wrap: wrap;
	gap: 0.45rem;
}

.sig-workspace-button {
	border: 1px solid rgba(137, 180, 250, 0.32);
	padding: 0.38rem 0.78rem;
	border-radius: 8px;
	background: linear-gradient(180deg, rgba(64, 119, 199, 0.94), rgba(36, 82, 153, 0.98));
	color: white;
	font-size: 0.8rem;
	cursor: pointer;
	font-weight: 600;
}

.sig-workspace-button:hover {
	background: linear-gradient(180deg, rgba(88, 145, 229, 0.96), rgba(48, 96, 170, 0.98));
}

.sig-workspace-button.sig-workspace-button-secondary {
	background: rgba(49, 50, 68, 0.92);
	border-color: rgba(69, 71, 90, 0.96);
	color: var(--sig-text);
}

.sig-workspace-output {
	background: var(--sig-surface-0);
	border: 1px solid var(--sig-border-soft);
	border-radius: 10px;
	padding: 0.85rem;
}

.sig-workspace-output h3 {
	margin-top: 0;
}

.sig-workspace-output-pane {
	max-height: 14rem;
}

button.btn,
.btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.3rem 0.72rem;
	border-radius: 0.35rem;
	border: none;
	background: #cba6f7;
	color: #1e1e2e;
	font-size: 0.78rem;
	font-weight: 700;
	cursor: pointer;
	text-decoration: none;
}

button.btn:hover,
.btn:hover {
	background: #b4befe;
	text-decoration: none;
}

button.btn-ghost,
.btn-ghost {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.24rem 0.62rem;
	border-radius: 0.35rem;
	border: 1px solid #45475a;
	background: transparent;
	color: #cdd6f4;
	font-size: 0.78rem;
	cursor: pointer;
	text-decoration: none;
}

button.btn-ghost:hover,
.btn-ghost:hover {
	background: #313244;
	text-decoration: none;
}

button.btn-tx,
.btn-tx {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.28rem 0.82rem;
	border-radius: 0.35rem;
	border: none;
	background: #e08020;
	color: white;
	font-size: 0.78rem;
	font-weight: 700;
	cursor: pointer;
	text-decoration: none;
}

button.btn-tx:hover,
.btn-tx:hover {
	background: #c06010;
	text-decoration: none;
}

.btn-tx-active {
	background: #4a90d9;
}

.btn-dbg {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.35rem 0.9rem;
	border-radius: 0.35rem;
	border: none;
	background: #1e6fba;
	color: white;
	font-size: 0.8rem;
	font-weight: 700;
	cursor: pointer;
	text-decoration: none;
	flex: 1;
}

.btn-dbg:hover {
	background: #1559a0;
	text-decoration: none;
}

.btn-dbg.disabled {
	opacity: 0.45;
	cursor: not-allowed;
}

.sig-workspace-shell {
	display: flex;
	flex-direction: column;
	height: 100%;
	min-height: 0;
	gap: 0;
	background: #11111b;
}

.sig-workspace-form {
	display: flex;
	flex-direction: column;
	gap: 0;
}

.ws-history {
	flex: 1;
	min-height: 0;
	overflow-y: auto;
	padding: 0.55rem 0.75rem;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.8rem;
	border-bottom: 1px solid #313244;
}

.ws-entry {
	margin-bottom: 0.5rem;
}

.ws-code {
	color: #cdd6f4;
	white-space: pre-wrap;
	word-break: break-word;
}

.ws-result {
	margin-top: 0.24rem;
	padding: 0.28rem 0.55rem;
	border-radius: 0.35rem;
	background: #1a3a1a;
	color: #a6e3a1;
}

.ws-result.error {
	background: #3a1a1a;
	color: #f38ba8;
}

.ws-result-text {
	white-space: pre-wrap;
	word-break: break-word;
}

.ws-input-row {
	border-top: 1px solid #313244;
	display: flex;
	flex-direction: column;
	flex-shrink: 0;
	background: #181825;
}

.ws-code-area {
	width: 100%;
	min-height: 7.5rem;
	padding: 0.75rem;
	border: none;
	background: #1e1e2e;
	color: #cdd6f4;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.86rem;
	line-height: 1.45;
	resize: vertical;
	outline: none;
}

.ws-controls {
	display: flex;
	align-items: center;
	gap: 0.45rem;
	padding: 0.55rem 0.75rem;
	flex-wrap: wrap;
}

.ws-hint {
	margin-left: auto;
	font-size: 0.72rem;
	color: #6c7086;
}

.txbar {
	display: flex;
	align-items: center;
	gap: 0.45rem;
	padding: 0.45rem 0.75rem;
	border-top: 1px solid #313244;
	background: #181825;
	flex-wrap: wrap;
}

.txbar span {
	font-size: 0.72rem;
	color: #6c7086;
}

.tab-strip {
	display: flex;
	border-bottom: 1px solid #313244;
	background: #181825;
	flex-shrink: 0;
	overflow-x: auto;
}

.tab-item {
	padding: 0.45rem 0.8rem;
	font-size: 0.76rem;
	color: #a6adc8;
	cursor: pointer;
	border-bottom: 2px solid transparent;
	margin-bottom: -1px;
	white-space: nowrap;
	user-select: none;
}

.tab-item:hover {
	color: #cdd6f4;
	text-decoration: none;
}

.tab-item.active {
	color: #89dceb;
	border-bottom-color: #89dceb;
}

.sig-debugger-shell {
	--sig-debugger-frame-row-height: 1.82rem;
	--sig-debugger-visible-rows: 10;
	display: flex;
	flex-direction: column;
	height: 100%;
	min-height: 0;
	background: #11111b;
	overflow-y: auto;
	overflow-x: hidden;
	overscroll-behavior: contain;
	scrollbar-gutter: stable both-edges;
}

.sig-debugger-shell > * {
	flex-shrink: 0;
}

.sig-debugger-tab-panel {
	display: none;
	flex-direction: column;
	flex: 1;
	min-height: 0;
}

.sig-debugger-tab-panel.active {
	display: flex;
	overflow-y: scroll;
	overflow-x: hidden;
	overscroll-behavior: contain;
	scrollbar-gutter: stable both-edges;
}

.dbg-summary {
	display: flex;
	flex-direction: column;
	gap: 0.18rem;
	padding: 0.5rem 0.65rem;
	border-bottom: 1px solid #313244;
	background: #181825;
	flex-shrink: 0;
}

.dbg-summary-source,
.dbg-summary-error {
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.76rem;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.dbg-summary-source {
	color: #cdd6f4;
}

.dbg-summary-error {
	color: #f38ba8;
}

.sig-debugger-frame-list {
	flex: 1;
	min-height: 5rem;
	max-height: calc(var(--sig-debugger-frame-row-height) * var(--sig-debugger-visible-rows) + 0.9rem);
	min-height: calc(var(--sig-debugger-frame-row-height) * var(--sig-debugger-visible-rows) + 0.9rem);
	height: calc(var(--sig-debugger-frame-row-height) * var(--sig-debugger-visible-rows) + 0.9rem);
	padding: 0;
	border: none;
	border-bottom: 1px solid #313244;
	border-radius: 0;
	background: #181825;
	overflow-y: auto;
	overflow-x: auto;
}

.sig-debugger-frames {
	list-style: none;
	padding: 0;
	margin: 0;
	gap: 0;
}

.sig-debugger-frames li {
	margin: 0;
}

.dbg-frame-item {
	width: 100%;
	display: flex;
	align-items: center;
	gap: 0.45rem;
	padding: 0.32rem 0.6rem;
	border: 0;
	border-left: 3px solid transparent;
	border-radius: 0;
	background: transparent;
	color: inherit;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.76rem;
	text-align: left;
	cursor: pointer;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.dbg-frame-item:hover {
	background: #313244;
	text-decoration: none;
}

.dbg-frame-item.active,
.sig-debugger-frame.selected {
	background: #1e4f9f;
	border-left-color: #89b4fa;
	color: #cdd6f4;
}

.dbg-frame-icon {
	width: 0.9rem;
	height: 0.9rem;
	border-radius: 999px;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 0.48rem;
	flex-shrink: 0;
	background: #f9e2af;
	color: #1e1e2e;
}

.dbg-frame-icon.ruby {
	background: #f38ba8;
}

.sig-debugger-utility-bar {
	display: flex;
	align-items: center;
	flex-wrap: wrap;
	gap: 0.35rem;
	padding: 0.45rem 0.6rem;
	border-bottom: 1px solid #313244;
	background: #181825;
}

.sig-debugger-utility-bar .sig-action {
	margin: 0;
}

.sig-debugger-command {
	margin: 0;
	padding: 0.24rem 0.62rem;
	font-size: 0.74rem;
}

.sig-debugger-status-row {
	padding: 0.35rem 0.65rem;
	border-top: 1px solid #313244;
	background: #181825;
}

.dbg-action-bar {
	display: flex;
	align-items: stretch;
	gap: 0.35rem;
	padding: 0.5rem 0.6rem;
	border-bottom: 1px solid #313244;
	background: #181825;
	flex-wrap: wrap;
}

.dbg-source-pane {
	display: flex;
	flex-direction: column;
	flex: 0 0 auto;
	min-height: 0;
	height: 20rem;
	overflow: hidden;
}

.dbg-source-meta {
	padding: 0.3rem 0.65rem;
	border-bottom: 1px solid #313244;
	background: #181825;
	color: #89b4fa;
	font-size: 0.7rem;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
}

.dbg-source-code {
	flex: 1;
	min-height: 0;
	background: #181825;
	color: #cdd6f4;
	padding: 0.4rem 0;
	overflow: auto;
}

.dbg-source-line {
	display: grid;
	grid-template-columns: 1rem 2.5rem minmax(0, 1fr);
	gap: 0.65rem;
	align-items: start;
	padding: 0.08rem 0.75rem;
	border-left: 3px solid transparent;
}

.dbg-source-line.active {
	background: #313244;
	border-left-color: #89b4fa;
}

.dbg-source-marker {
	color: #89b4fa;
	text-align: center;
	opacity: 0.18;
	user-select: none;
}

.dbg-source-line.active .dbg-source-marker {
	opacity: 1;
}

.dbg-source-text {
	min-width: 0;
	white-space: pre;
}

.dbg-self-bar,
.dbg-var-row {
	display: flex;
	align-items: center;
	gap: 0.45rem;
	padding: 0.3rem 0.65rem;
	border-top: 1px solid #313244;
	background: #181825;
	flex-shrink: 0;
}

.dbg-self-label {
	color: #6c7086;
	font-size: 0.72rem;
}

.dbg-self-val {
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	color: #cba6f7;
	min-width: 0;
}

.dbg-var-val {
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	color: #a6e3a1;
	min-width: 0;
}

.dbg-tls-list {
	list-style: none;
	padding: 0;
	margin: 0;
}

.dbg-tls-list li {
	display: flex;
	align-items: center;
	gap: 0.55rem;
	padding: 0.2rem 0;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.76rem;
}

.tls-key {
	color: #f5c2e7;
	min-width: 7rem;
}

.tls-val {
	color: #a6e3a1;
	min-width: 0;
}

.cb-wrap {
	display: flex;
	flex-direction: column;
	height: 100%;
	min-height: 0;
	background: #11111b;
}

.cb-toolbar {
	display: flex;
	align-items: center;
	gap: 0.4rem;
	flex-wrap: wrap;
	padding: 0.45rem 0.65rem;
	border-bottom: 1px solid #313244;
	background: #181825;
	flex-shrink: 0;
}

.cb-static-btn {
	pointer-events: none;
}

.cb-meta {
	display: inline-flex;
	align-items: center;
	gap: 0.35rem;
	color: #a6adc8;
	font-size: 0.76rem;
	white-space: nowrap;
}

.cb-toolbar .cb-meta:first-of-type {
	margin-left: auto;
}

.cb-lists {
	display: grid;
	grid-template-columns: minmax(9rem, 12rem) 0.45rem minmax(12rem, 1fr) 0.45rem minmax(10rem, 12rem) 0.45rem minmax(12rem, 1fr);
	min-height: 13rem;
	height: 13rem;
	border-bottom: 1px solid #313244;
	flex-shrink: 0;
}

.cb-pane {
	display: flex;
	flex-direction: column;
	min-width: 0;
	min-height: 0;
	overflow: hidden;
	border-right: 1px solid #313244;
}

.cb-pane:last-child {
	border-right: none;
}

.cb-splitter {
	position: relative;
	background: #0f1019;
	border-right: 1px solid #1e1e2e;
	border-left: 1px solid #1e1e2e;
}

.cb-splitter::after {
	content: "";
	position: absolute;
	left: 50%;
	top: 50%;
	transform: translate(-50%, -50%);
	width: 2px;
	height: 1.75rem;
	border-radius: 999px;
	background: #45475a;
}

.cb-pane-label {
	padding: 0.35rem 0.55rem;
	background: #1e1e2e;
	border-bottom: 1px solid #313244;
	font-size: 0.66rem;
	text-transform: uppercase;
	letter-spacing: 0.06em;
	color: #6c7086;
}

.cb-filter-wrap {
	padding: 0.35rem 0.45rem;
	border-bottom: 1px solid #313244;
	background: #181825;
}

.cb-filter {
	width: 100%;
	box-sizing: border-box;
	border: 1px solid #313244;
	border-radius: 0.35rem;
	background: #11111b;
	color: #6c7086;
	font-size: 0.72rem;
	padding: 0.35rem 0.45rem;
}

.cb-filter-placeholder {
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.cb-list {
	flex: 1;
	min-height: 0;
	padding: 0;
}

.cb-list-entries {
	list-style: none;
	padding: 0;
	margin: 0;
}

.cb-item {
	display: block;
	padding: 0.32rem 0.55rem;
	font-size: 0.76rem;
	color: #cdd6f4;
	border-left: 3px solid transparent;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.cb-item:hover {
	background: #313244;
	text-decoration: none;
}

.cb-item.selected {
	border-left-color: #cba6f7;
	background: rgba(203, 166, 247, 0.12);
	color: #f5f7ff;
}

.cb-source-wrap {
	display: flex;
	flex-direction: column;
	flex: 1;
	min-height: 0;
}

.cb-source-hdr {
	display: flex;
	align-items: center;
	justify-content: space-between;
	padding: 0.45rem 0.65rem;
	background: #181825;
	border-bottom: 1px solid #313244;
	flex-shrink: 0;
}

.cb-source-note {
	font-size: 0.72rem;
	color: #89dceb;
}

.cb-source {
	flex: 1;
	min-height: 0;
	padding: 0.65rem 0.75rem;
	background: #11111b;
}

.cb-status {
	padding: 0.38rem 0.65rem;
	border-top: 1px solid #313244;
	background: #181825;
	color: #a6adc8;
	font-size: 0.72rem;
	flex-shrink: 0;
}

@media (max-width: 1100px) {
	.sig-floating-window {
		position: relative;
		top: auto !important;
		left: auto !important;
		width: auto !important;
		max-width: none;
		max-height: none;
		margin: 1rem;
		resize: none;
	}

	.sig-desktop {
		padding-top: 1rem;
		padding-bottom: 1rem;
	}

	.sig-browser-grid,
	.cb-lists,
	.sig-debugger-diagnostic-grid,
	.sig-debugger-grid,
	.sig-session-grid,
	.sig-symbol-list-grid,
	.sig-layout {
		grid-template-columns: 1fr;
	}

	.cb-splitter {
		display: none;
	}

	.sig-taskbar {
		position: static;
	}

	.wa-toolbar {
		position: static !important;
		margin: 1rem;
		max-width: none;
	}

	.sig-menu-panel {
		position: static;
		margin-top: 0.35rem;
	}
}
'
]

{ #category : 'querying' }
SigExplorerApplication >> symbolListDictionaryNames [
	^ self gateway symbolListDictionaryNames
]

{ #category : 'querying' }
SigExplorerApplication >> symbolListEntryAssociations [
	^ self gateway symbolListEntryAssociationsForDictionaryNamed: selectedSymbolListDictionaryName
]

{ #category : 'rendering' }
SigExplorerApplication >> updateRoot: anHtmlRoot [
	| windowId |
	super updateRoot: anHtmlRoot.
	anHtmlRoot title: 'Seaside in GemStone'.
	anHtmlRoot meta
		name: 'viewport';
		content: 'width=device-width, initial-scale=1'.
	anHtmlRoot bodyAttributes addClass: 'sig-desktop-body'.
	anHtmlRoot addStyle: self stylesheet.
	anHtmlRoot addScript: self desktopScript.
	windowId := self consumePendingWindowIdToShow.
	windowId ifNotNil: [
		anHtmlRoot addScript: 'window.SIGAutoShowWindow = ', windowId printString, ';' ]
]

{ #category : 'actions' }
SigExplorerApplication >> workspaceDebugIt [
	| hadFailure |
	workspaceResultText := self gateway workspaceDebugIt: workspaceSourceText.
	hadFailure := self workspaceHasCapturedFailure.
	hadFailure
		ifTrue: [
			self showDebuggerForLastError.
			self setStatusMessage: 'Workspace debug opened the debugger' ]
		ifFalse: [
			self refreshBaseDebuggerStateFromGateway.
			self requestWindowShow: 'sig-window-debugger'.
			self setStatusMessage: 'Workspace debug run completed' ].
	self addTranscriptLine: 'Workspace debug output: ', (self transcriptPreviewOf: workspaceResultText)
]

{ #category : 'actions' }
SigExplorerApplication >> workspaceDoIt [
	| hadFailure |
	workspaceResultText := self gateway workspaceDoIt: workspaceSourceText.
	hadFailure := self workspaceHasCapturedFailure.
	hadFailure
		ifTrue: [
			self requestExceptionDebuggerForLastError.
			self setStatusMessage: 'Workspace do it failed' ]
		ifFalse: [ self setStatusMessage: 'Workspace do it completed' ].
	self addTranscriptLine: 'Workspace result: ', (self transcriptPreviewOf: workspaceResultText)
]

{ #category : 'actions' }
SigExplorerApplication >> workspacePrintIt [
	| hadFailure |
	workspaceResultText := self gateway workspaceDoIt: workspaceSourceText.
	hadFailure := self workspaceHasCapturedFailure.
	hadFailure
		ifTrue: [
			self requestExceptionDebuggerForLastError.
			self setStatusMessage: 'Workspace print it failed' ]
		ifFalse: [ self setStatusMessage: 'Workspace print it completed' ].
	self addTranscriptLine: 'Workspace print it: ', (self transcriptPreviewOf: workspaceResultText)
]

{ #category : 'actions' }
SigExplorerApplication >> workspaceInspectIt [
	| hadFailure |
	workspaceResultText := self gateway workspaceInspectIt: workspaceSourceText.
	hadFailure := self workspaceHasCapturedFailure.
	hadFailure
		ifTrue: [
			self requestExceptionDebuggerForLastError.
			self setStatusMessage: 'Workspace inspect failed' ]
		ifFalse: [ self setStatusMessage: 'Workspace inspect completed' ].
	hadFailure ifFalse: [
		self showInspectorText: workspaceResultText label: 'Workspace result'.
		self requestWindowShow: 'sig-window-inspector' ].
	self addTranscriptLine: 'Workspace inspect output: ', (self transcriptPreviewOf: workspaceResultText)
]
