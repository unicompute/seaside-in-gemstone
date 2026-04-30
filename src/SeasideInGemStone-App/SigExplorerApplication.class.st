Class {
	#name : 'SigExplorerApplication',
	#superclass : 'WAComponent',
	#instVars : [
		'gatewayOverride',
		'selectedRootName',
		'selectedEntryKey',
		'statusMessage',
		'selectedBrowserDictionaryName',
		'selectedBrowserClassName',
		'selectedBrowserProtocolName',
		'selectedBrowserSelector',
		'browserSourceDraftText',
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
		'nextDebuggerWindowNumber',
		'inspectorWindows',
		'nextInspectorWindowNumber',
		'auxiliaryWindows',
		'nextAuxiliaryWindowNumber'
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
	application preferenceAt: #trackingStrategy put: WACookieIfSupportedSessionTrackingStrategy new.
	application preferenceAt: #sessionClass put: SigExplorerSession
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
	^ self browserClassAssociationsForWindow: nil
]

{ #category : 'querying' }
SigExplorerApplication >> browserClassAssociationsForWindow: aWindow [
	^ self gateway
		classAssociationsForDictionaryNamed: (self browserDictionaryNameForWindow: aWindow)
]

{ #category : 'querying' }
SigExplorerApplication >> browserDictionaryNames [
	^ self gateway browserDictionaryNames
]

{ #category : 'accessing' }
SigExplorerApplication >> browserDictionaryNameForWindow: aWindow [
	^ aWindow
		ifNil: [ selectedBrowserDictionaryName ]
		ifNotNil: [ aWindow selectedDictionaryName ]
]

{ #category : 'querying' }
SigExplorerApplication >> browserProtocolNames [
	^ self browserProtocolNamesForWindow: nil
]

{ #category : 'querying' }
SigExplorerApplication >> browserProtocolNamesForWindow: aWindow [
	(self browserClassNameForWindow: aWindow) ifNil: [ ^ #() ].
	^ self gateway
		protocolNamesForClassNamed: (self browserClassNameForWindow: aWindow)
		inDictionaryNamed: (self browserDictionaryNameForWindow: aWindow)
]

{ #category : 'querying' }
SigExplorerApplication >> browserSelectorNames [
	^ self browserSelectorNamesForWindow: nil
]

{ #category : 'querying' }
SigExplorerApplication >> browserSelectorNamesForWindow: aWindow [
	((self browserClassNameForWindow: aWindow) isNil
		or: [ (self browserProtocolNameForWindow: aWindow) isNil ]) ifTrue: [ ^ #() ].
	^ self gateway
		selectorsForClassNamed: (self browserClassNameForWindow: aWindow)
		protocolNamed: (self browserProtocolNameForWindow: aWindow)
		inDictionaryNamed: (self browserDictionaryNameForWindow: aWindow)
]

{ #category : 'querying' }
SigExplorerApplication >> browserSourceText [
	^ self browserSourceTextForWindow: nil
]

{ #category : 'querying' }
SigExplorerApplication >> browserSourceTextForWindow: aWindow [
	^ self gateway
		methodSourceForClassNamed: (self browserClassNameForWindow: aWindow)
		selectorNamed: (self browserSelectorForWindow: aWindow)
		inDictionaryNamed: (self browserDictionaryNameForWindow: aWindow)
]

{ #category : 'querying' }
SigExplorerApplication >> browserEditableSourceText [
	^ self browserEditableSourceTextForWindow: nil
]

{ #category : 'querying' }
SigExplorerApplication >> browserEditableSourceTextForWindow: aWindow [
	| draft |
	draft := self browserSourceDraftTextForWindow: aWindow.
	draft ifNotNil: [ ^ draft ].
	((self browserClassNameForWindow: aWindow) isNil
		or: [ (self browserSelectorForWindow: aWindow) isNil ]) ifTrue: [ ^ '' ].
	^ self browserSourceTextForWindow: aWindow
]

{ #category : 'querying' }
SigExplorerApplication >> browserSourceHeadingText [
	^ self browserSourceHeadingTextForWindow: nil
]

{ #category : 'querying' }
SigExplorerApplication >> browserSourceHeadingTextForWindow: aWindow [
	(self browserClassNameForWindow: aWindow) ifNil: [ ^ 'Select a class to start browsing.' ].
	(self browserSelectorForWindow: aWindow) isNil ifTrue: [
		^ (self browserClassNameForWindow: aWindow), ' is selected.' ].
	^ (self browserClassNameForWindow: aWindow), ' >> ', (self browserSelectorForWindow: aWindow)
]

{ #category : 'actions' }
SigExplorerApplication >> browserCompileSource [
	^ self browserCompileSourceForWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> browserCompileSourceForWindow: aWindow [
	| categoryName outcome |
	(self browserClassNameForWindow: aWindow) ifNil: [
		self setStatusMessage: 'Select a class before compiling'.
		^ self ].
	categoryName := (self browserProtocolNameForWindow: aWindow) ifNil: [ 'as yet unclassified' ].
	outcome := self gateway
		compileMethodSource: (self browserEditableSourceTextForWindow: aWindow)
		forClassNamed: (self browserClassNameForWindow: aWindow)
		protocolNamed: categoryName
		inDictionaryNamed: (self browserDictionaryNameForWindow: aWindow).
	(outcome at: #success ifAbsent: [ false ])
		ifTrue: [
			(self browserProtocolNameForWindow: aWindow) ifNil: [
				self browserProtocolName: categoryName forWindow: aWindow ].
			self setStatusMessage: (outcome at: #message ifAbsent: [ 'Method compiled' ]) ]
		ifFalse: [
			self setStatusMessage: (outcome at: #message ifAbsent: [ 'Method compile failed' ]) ]
]

{ #category : 'actions' }
SigExplorerApplication >> browserResetSourceDraft [
	^ self browserResetSourceDraftForWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> browserResetSourceDraftForWindow: aWindow [
	self browserSourceDraftText: nil forWindow: aWindow.
	self setStatusMessage: 'Browser source reset'
]

{ #category : 'accessing' }
SigExplorerApplication >> browserClassNameForWindow: aWindow [
	^ aWindow
		ifNil: [ selectedBrowserClassName ]
		ifNotNil: [ aWindow selectedClassName ]
]

{ #category : 'accessing' }
SigExplorerApplication >> browserClassName: aString forWindow: aWindow [
	aWindow
		ifNil: [ selectedBrowserClassName := aString ]
		ifNotNil: [ aWindow selectedClassName: aString ]
]

{ #category : 'accessing' }
SigExplorerApplication >> browserProtocolNameForWindow: aWindow [
	^ aWindow
		ifNil: [ selectedBrowserProtocolName ]
		ifNotNil: [ aWindow selectedProtocolName ]
]

{ #category : 'accessing' }
SigExplorerApplication >> browserProtocolName: aString forWindow: aWindow [
	aWindow
		ifNil: [ selectedBrowserProtocolName := aString ]
		ifNotNil: [ aWindow selectedProtocolName: aString ]
]

{ #category : 'accessing' }
SigExplorerApplication >> browserSelectorForWindow: aWindow [
	^ aWindow
		ifNil: [ selectedBrowserSelector ]
		ifNotNil: [ aWindow selectedSelector ]
]

{ #category : 'accessing' }
SigExplorerApplication >> browserSelector: aString forWindow: aWindow [
	aWindow
		ifNil: [ selectedBrowserSelector := aString ]
		ifNotNil: [ aWindow selectedSelector: aString ]
]

{ #category : 'accessing' }
SigExplorerApplication >> browserSourceDraftTextForWindow: aWindow [
	^ aWindow
		ifNil: [ browserSourceDraftText ]
		ifNotNil: [ aWindow sourceDraftText ]
]

{ #category : 'accessing' }
SigExplorerApplication >> browserSourceDraftText: aString forWindow: aWindow [
	aWindow
		ifNil: [ browserSourceDraftText := aString ]
		ifNotNil: [ aWindow sourceDraftText: aString ]
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
	| resolvedLocation |
	resolvedLocation := self debuggerResolvedSourceLocationFor: aFrame.
	^ resolvedLocation ifNil: [ nil ] ifNotNil: [ resolvedLocation first ]
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
	aFrame ifNil: [ ^ 'Executed code @1 line 1' ].
	stepPoint := (aFrame at: #quickStepPoint ifAbsent: [ nil ]) ifNil: [ 1 ].
	lineNumber := (self debuggerFrameSourceLineNumberFor: aFrame) ifNil: [ 1 ].
	stream := WriteStream on: String new.
	stream
		nextPutAll: 'Executed code @';
		nextPutAll: stepPoint printString;
		nextPutAll: ' line ';
		nextPutAll: lineNumber printString.
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
	^ self debuggerFrameSourceMetaTextFor: aFrame position: 0 count: 0
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameSourceMetaTextFor: aFrame position: framePosition count: frameCount [
	| ipOffset lineNumber quickStepPoint sourceLineNumber stream |
	aFrame ifNil: [ ^ 'Select a frame to see source metadata.' ].
	stream := WriteStream on: String new.
	quickStepPoint := aFrame at: #quickStepPoint ifAbsent: [ nil ].
	lineNumber := self debuggerFrameSourceLineNumberFor: aFrame.
	ipOffset := aFrame
		at: #sourceOffset
		ifAbsent: [ aFrame at: #ipOffset ifAbsent: [ nil ] ].
	sourceLineNumber := aFrame at: #sourceLineNumber ifAbsent: [ nil ].
	(framePosition > 0 and: [ frameCount > 0 ]) ifTrue: [
		stream
			nextPutAll: 'Frame ';
			nextPutAll: framePosition printString;
			nextPut: $/;
			nextPutAll: frameCount printString ].
	quickStepPoint ifNotNil: [
		stream position > 0 ifTrue: [ stream nextPutAll: ' • ' ].
		stream
			nextPutAll: 'Step ';
			nextPutAll: quickStepPoint printString ].
	lineNumber ifNotNil: [
		stream position > 0 ifTrue: [ stream nextPutAll: ' • ' ].
		stream
			nextPutAll: 'Line ';
			nextPutAll: lineNumber printString ].
	ipOffset ifNotNil: [
		stream position > 0 ifTrue: [ stream nextPutAll: ' • ' ].
		stream
			nextPutAll: 'Offset ';
			nextPutAll: ipOffset printString ].
	sourceLineNumber ifNotNil: [
		stream position > 0 ifTrue: [ stream nextPutAll: ' • ' ].
		stream
			nextPutAll: 'File line ';
			nextPutAll: sourceLineNumber printString ].
	^ stream position = 0
		ifTrue: [ 'Source metadata unavailable.' ]
		ifFalse: [ stream contents ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameSourceCursorLocationFor: aFrame [
	| currentStep |
	(self debuggerFrameIsExecutedCode: aFrame) ifFalse: [
		^ self debuggerFrameSourceCursorLocationFor: aFrame stepPoint: (aFrame at: #quickStepPoint ifAbsent: [ nil ]) ].
	currentStep := aFrame at: #quickStepPoint ifAbsent: [ nil ].
	^ self debuggerFrameSourceCursorLocationFor: aFrame stepPoint: currentStep
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameSourceCursorLocationFor: aFrame stepPoint: aStepPoint [
	| offset rawOffset sourceOffsets sourceText stepPoint |
	aFrame ifNil: [ ^ nil ].
	sourceText := aFrame at: #sourceText ifAbsent: [ nil ].
	sourceOffsets := aFrame at: #sourceOffsets ifAbsent: [ nil ].
	stepPoint := aStepPoint.
	(sourceText isNil or: [ sourceText isEmpty ]) ifTrue: [ ^ nil ].
	(sourceOffsets isNil or: [ stepPoint isNil ]) ifTrue: [ ^ nil ].
	stepPoint := [ stepPoint asInteger ] on: Error do: [ nil ].
	(stepPoint isNil or: [ stepPoint <= 0 ]) ifTrue: [ ^ nil ].
	rawOffset := sourceOffsets at: stepPoint ifAbsent: [ nil ].
	rawOffset ifNil: [ ^ nil ].
	offset := [ rawOffset asInteger ] on: Error do: [ nil ].
	offset ifNil: [ ^ nil ].
	offset < 1 ifTrue: [ offset := 1 ].
	offset > (sourceText size + 1) ifTrue: [ offset := sourceText size + 1 ].
	^ self
		debuggerSourceCursorLocationIn: sourceText
		atOffset: offset
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameSourceOffsetFor: aFrame stepPoint: aStepPoint [
	| rawOffset sourceOffsets stepPoint |
	aFrame ifNil: [ ^ nil ].
	sourceOffsets := aFrame at: #sourceOffsets ifAbsent: [ nil ].
	stepPoint := aStepPoint.
	(sourceOffsets isNil or: [ stepPoint isNil ]) ifTrue: [ ^ nil ].
	stepPoint := [ stepPoint asInteger ] on: Error do: [ nil ].
	(stepPoint isNil or: [ stepPoint <= 0 ]) ifTrue: [ ^ nil ].
	rawOffset := sourceOffsets at: stepPoint ifAbsent: [ nil ].
	^ [ rawOffset asInteger ] on: Error do: [ nil ]
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameStepPointStartsNewStatement: aStepPoint in: aFrame [
	| currentLocation currentOffset previousLocation previousOffset sourceText |
	aStepPoint ifNil: [ ^ false ].
	aStepPoint <= 1 ifTrue: [ ^ true ].
	sourceText := self debuggerFrameSourceTextFor: aFrame.
	currentOffset := self debuggerFrameSourceOffsetFor: aFrame stepPoint: aStepPoint.
	previousOffset := self debuggerFrameSourceOffsetFor: aFrame stepPoint: aStepPoint - 1.
	(currentOffset isNil or: [ previousOffset isNil ]) ifTrue: [ ^ false ].
	currentLocation := self debuggerFrameSourceCursorLocationFor: aFrame stepPoint: aStepPoint.
	previousLocation := self debuggerFrameSourceCursorLocationFor: aFrame stepPoint: aStepPoint - 1.
	(currentLocation isNil or: [ previousLocation isNil ]) ifTrue: [ ^ false ].
	(currentLocation first ~= previousLocation first) ifTrue: [ ^ true ].
	^ self
		debuggerStatementBoundaryExistsIn: sourceText
		fromOffset: previousOffset
		toOffset: currentOffset - 1
]

{ #category : 'private' }
SigExplorerApplication >> debuggerStatementBoundaryExistsIn: sourceText fromOffset: startOffset toOffset: endOffset [
	| current inComment inString limit |
	(sourceText isNil or: [ sourceText isEmpty ]) ifTrue: [ ^ false ].
	(startOffset isNil or: [ endOffset isNil ]) ifTrue: [ ^ false ].
	startOffset >= endOffset ifTrue: [ ^ false ].
	inComment := false.
	inString := false.
	current := startOffset max: 1.
	limit := endOffset min: sourceText size.
	[ current <= limit ] whileTrue: [
		| character |
		character := sourceText at: current.
		inComment
			ifTrue: [
				character = $" ifTrue: [ inComment := false ] ]
			ifFalse: [
				inString
					ifTrue: [
						character = $' ifTrue: [ inString := false ] ]
					ifFalse: [
						character = $" ifTrue: [ inComment := true ].
						character = $' ifTrue: [ inString := true ].
						character = $. ifTrue: [ ^ true ] ] ].
		current := current + 1 ].
	^ false
]

{ #category : 'private' }
SigExplorerApplication >> debuggerDefaultCursorColumnForLine: aString [
	^ self debuggerExecutableCursorColumnForLine: aString
]

{ #category : 'private' }
SigExplorerApplication >> debuggerDisplayLineIndexForSourceLine: sourceLineNumber records: recordCollection [
	recordCollection doWithIndex: [ :each :displayIndex |
		(each first = sourceLineNumber) ifTrue: [ ^ displayIndex ] ].
	^ nil
]

{ #category : 'private' }
SigExplorerApplication >> debuggerExecutableCursorColumnForLine: aString [
	| index lineText size |
	lineText := aString ifNil: [ '' ].
	size := lineText size.
	index := 1.
	[ index <= size ] whileTrue: [
		[ index <= size and: [ (lineText at: index) isSeparator ] ] whileTrue: [
			index := index + 1 ].
		index > size ifTrue: [ ^ nil ].
		(lineText at: index) = $"
			ifTrue: [
				index := index + 1.
				[ index <= size and: [ (lineText at: index) ~= $" ] ] whileTrue: [
					index := index + 1 ].
				index <= size ifTrue: [ index := index + 1 ] ]
			ifFalse: [ ^ index ] ].
	^ nil
]

{ #category : 'private' }
SigExplorerApplication >> debuggerExecutableLineNumberNear: aLineNumber inLines: lineCollection [
	| lineCount startIndex |
	aLineNumber ifNil: [ ^ nil ].
	lineCount := lineCollection size.
	lineCount = 0 ifTrue: [ ^ nil ].
	startIndex := (aLineNumber max: 1) min: lineCount.
	startIndex to: lineCount do: [ :index |
		(self debuggerExecutableCursorColumnForLine: (lineCollection at: index))
			ifNotNil: [ ^ index ] ].
	startIndex - 1 to: 1 by: -1 do: [ :index |
		(self debuggerExecutableCursorColumnForLine: (lineCollection at: index))
			ifNotNil: [ ^ index ] ].
	^ nil
]

{ #category : 'private' }
SigExplorerApplication >> debuggerRawSourceLineNumberFor: aFrame cursorLocation: cursorLocation lineCount: lineCount [
	| lineNumber sourceLineNumber |
	cursorLocation ifNotNil: [
		^ ((cursorLocation first max: 1) min: lineCount) ].
	lineNumber := aFrame at: #lineNumber ifAbsent: [ nil ].
	lineNumber ifNotNil: [ ^ ((lineNumber max: 1) min: lineCount) ].
	sourceLineNumber := aFrame at: #sourceLineNumber ifAbsent: [ nil ].
	sourceLineNumber ifNotNil: [ ^ ((sourceLineNumber max: 1) min: lineCount) ].
	^ nil
]

{ #category : 'private' }
SigExplorerApplication >> debuggerResolvedSourceLocationFor: aFrame [
	| cursorColumn cursorLocation displayLine displayRecords lines rawLine resolvedLine sourceText |
	aFrame ifNil: [ ^ nil ].
	sourceText := aFrame at: #sourceText ifAbsent: [ nil ].
	lines := self debuggerSourceLinesFor: sourceText.
	lines isEmpty ifTrue: [ ^ nil ].
	displayRecords := self debuggerSourceLineRecordsFor: aFrame.
	cursorLocation := self debuggerFrameSourceCursorLocationFor: aFrame.
	rawLine := self
		debuggerRawSourceLineNumberFor: aFrame
		cursorLocation: cursorLocation
		lineCount: lines size.
	resolvedLine := (self debuggerFrameIsExecutedCode: aFrame)
		ifTrue: [ self debuggerExecutableLineNumberNear: rawLine inLines: lines ]
		ifFalse: [ rawLine ].
	resolvedLine ifNil: [
		rawLine ifNil: [ ^ nil ].
		^ { rawLine. 1 } ].
	displayLine := self
		debuggerDisplayLineIndexForSourceLine: resolvedLine
		records: displayRecords.
	displayLine ifNil: [ displayLine := 1 ].
	cursorColumn := (self debuggerFrameIsExecutedCode: aFrame)
		ifTrue: [ self debuggerExecutableCursorColumnForLine: (lines at: resolvedLine) ]
		ifFalse: [
			(cursorLocation notNil and: [ cursorLocation first = resolvedLine ])
				ifTrue: [ cursorLocation second ]
				ifFalse: [ self debuggerDefaultCursorColumnForLine: (lines at: resolvedLine) ] ].
	((cursorLocation notNil and: [ cursorLocation first = resolvedLine ])
		and: [ self debuggerFrameIsExecutedCode: aFrame ]) ifTrue: [
		cursorColumn := cursorColumn
			ifNil: [ cursorLocation second ]
			ifNotNil: [ cursorLocation second max: cursorColumn ] ].
	cursorColumn ifNil: [ cursorColumn := 1 ].
	^ { displayLine. cursorColumn }
]

{ #category : 'private' }
SigExplorerApplication >> debuggerSourceLineRecordsFor: aFrame [
	| lines records |
	lines := self debuggerSourceLinesFor: (self debuggerFrameSourceTextFor: aFrame).
	records := OrderedCollection new.
	1 to: lines size do: [ :index |
		records add: { index. (lines at: index) } ].
	^ records asArray
]

{ #category : 'private' }
SigExplorerApplication >> debuggerFrameStepCursorLabelFor: aFrame [
	| stepPoint |
	aFrame ifNil: [ ^ '>' ].
	stepPoint := aFrame at: #quickStepPoint ifAbsent: [ nil ].
	^ stepPoint
		ifNil: [ '>' ]
		ifNotNil: [ 'S', stepPoint printString ]
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
	| executedLevel frames |
	frames := self debuggerFramesInState: aState.
	(aState at: #showBridgeFrames ifAbsent: [ false ]) ifTrue: [ ^ frames ].
	frames := frames reject: [ :each | each at: #isBridge ifAbsent: [ false ] ].
	executedLevel := (frames detect: [ :each | self debuggerFrameIsExecutedCode: each ] ifNone: [ nil ])
		ifNil: [ nil ]
		ifNotNil: [ :f | f at: #level ifAbsent: [ nil ] ].
	executedLevel ifNil: [ ^ frames ].
	^ frames reject: [ :each |
		| level |
		level := each at: #level ifAbsent: [ 0 ].
		level < executedLevel and: [
			(each at: #isInfrastructure ifAbsent: [ false ])
				or: [ (each at: #className ifAbsent: [ '' ]) = 'SigWorkspaceEvaluator' ]
				or: [ (each at: #sourceText ifAbsent: [ '' ]) isEmpty ] ] ]
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
SigExplorerApplication >> debuggerSourceCursorLocationIn: sourceText atOffset: offsetInteger [
	| lineIndex resolvedOffset |
	sourceText ifNil: [ ^ nil ].
	resolvedOffset := offsetInteger ifNil: [ ^ nil ].
	lineIndex := 0.
	sourceText lineIndicesDo: [ :start :endWithoutDelimiters :end |
		| caretColumn lineLength |
		lineIndex := lineIndex + 1.
		lineLength := (endWithoutDelimiters - start + 1) max: 0.
		(resolvedOffset between: start and: endWithoutDelimiters + 1)
			ifTrue: [
				caretColumn := (resolvedOffset - start + 1) min: lineLength + 1.
				^ { lineIndex. caretColumn max: 1 } ] ].
	^ nil
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
	^ self clearWorkspaceOutputForWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> clearWorkspaceOutputForWindow: aWindow [
	self workspaceResultText: 'Workspace output cleared.' forWindow: aWindow.
	self setStatusMessage: 'Workspace output cleared'
]

{ #category : 'actions' }
SigExplorerApplication >> closeAllTransientWindows [
	auxiliaryWindows := OrderedCollection new.
	inspectorWindows := OrderedCollection new.
	debuggerWindows := OrderedCollection new.
	pendingWindowIdToShow := nil.
	self setStatusMessage: 'Closed all windows'
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
	window at: #subtitle put: ''.
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
SigExplorerApplication >> inspectorTaskbarLabelForWindowNumber: anInteger [
	^ 'Obj ', anInteger printString
]

{ #category : 'private' }
SigExplorerApplication >> inspectorWindowTitleForWindowNumber: anInteger [
	^ 'Object ', anInteger printString
]

{ #category : 'private' }
SigExplorerApplication >> inspectorWindowPositionForIndex: anInteger [
	| offset top left |
	offset := (anInteger - 1) \\ 6.
	top := 6 + (offset * 1.5).
	left := 46 + (offset * 1.5).
	^ 'top: ', top printString, 'rem; left: ', left printString, 'rem; width: 26rem; height: 22rem;'
]

{ #category : 'private' }
SigExplorerApplication >> maximumInspectorWindows [
	^ 20
]

{ #category : 'private' }
SigExplorerApplication >> pruneOldInspectorWindows [
	[ inspectorWindows size >= self maximumInspectorWindows ]
		whileTrue: [ inspectorWindows removeFirst ]
]

{ #category : 'private' }
SigExplorerApplication >> newInspectorWindowForText: aString label: aLabel [
	| window windowNumber |
	self pruneOldInspectorWindows.
	windowNumber := nextInspectorWindowNumber := nextInspectorWindowNumber + 1.
	window := SigInspectorWindow
		id: 'sig-window-object-', windowNumber printString
		title: (self inspectorWindowTitleForWindowNumber: windowNumber)
		taskbarLabel: (self inspectorTaskbarLabelForWindowNumber: windowNumber)
		position: (self inspectorWindowPositionForIndex: windowNumber)
		label: aLabel
		text: aString.
	inspectorWindows addLast: window.
	^ window
]

{ #category : 'private' }
SigExplorerApplication >> auxiliaryWindowTitleForKind: aSymbol number: anInteger [
	aSymbol = #explorer ifTrue: [ ^ 'Explorer ', anInteger printString ].
	aSymbol = #workspace ifTrue: [ ^ 'Workspace ', anInteger printString ].
	aSymbol = #browser ifTrue: [ ^ 'Class Browser ', anInteger printString ].
	aSymbol = #symbolList ifTrue: [ ^ 'Symbol List Browser ', anInteger printString ].
	aSymbol = #session ifTrue: [ ^ 'Session ', anInteger printString ].
	aSymbol = #transcript ifTrue: [ ^ 'Transcript ', anInteger printString ].
	^ 'Window ', anInteger printString
]

{ #category : 'private' }
SigExplorerApplication >> auxiliaryWindowTaskbarLabelForKind: aSymbol number: anInteger [
	aSymbol = #explorer ifTrue: [ ^ 'Exp ', anInteger printString ].
	aSymbol = #workspace ifTrue: [ ^ 'Ws ', anInteger printString ].
	aSymbol = #browser ifTrue: [ ^ 'Br ', anInteger printString ].
	aSymbol = #symbolList ifTrue: [ ^ 'Sym ', anInteger printString ].
	aSymbol = #session ifTrue: [ ^ 'Ses ', anInteger printString ].
	aSymbol = #transcript ifTrue: [ ^ 'Tx ', anInteger printString ].
	^ 'Win ', anInteger printString
]

{ #category : 'private' }
SigExplorerApplication >> auxiliaryWindowPositionForKind: aSymbol index: anInteger [
	| offset top left width height |
	offset := (anInteger - 1) \\ 6.
	aSymbol = #explorer ifTrue: [
		top := 2.25.
		left := 2.25.
		width := 29.
		height := 34 ].
	aSymbol = #workspace ifTrue: [
		top := 2.25.
		left := 31.
		width := 50.
		height := 34 ].
	aSymbol = #browser ifTrue: [
		top := 3.5.
		left := 33.
		width := 50.
		height := 31 ].
	aSymbol = #symbolList ifTrue: [
		top := 4.
		left := 73.
		width := 34.
		height := 28 ].
	aSymbol = #session ifTrue: [
		top := 36.
		left := 31.
		width := 24.
		height := 18 ].
	aSymbol = #transcript ifTrue: [
		top := 36.
		left := 56.
		width := 35.
		height := 18 ].
	top ifNil: [
		top := 4.
		left := 4.
		width := 30.
		height := 20 ].
	top := top + (offset * 1.25).
	left := left + (offset * 1.75).
	^ 'top: ', top printString, 'rem; left: ', left printString, 'rem; width: ', width printString, 'rem; height: ', height printString, 'rem;'
]

{ #category : 'private' }
SigExplorerApplication >> newAuxiliaryWindowForKind: aSymbol [
	| window windowId windowNumber windowTitle windowTaskbarLabel windowPosition |
	windowNumber := nextAuxiliaryWindowNumber := nextAuxiliaryWindowNumber + 1.
	windowId := 'sig-window-', aSymbol asString, '-aux-', windowNumber printString.
	windowTitle := self auxiliaryWindowTitleForKind: aSymbol number: windowNumber.
	windowTaskbarLabel := self auxiliaryWindowTaskbarLabelForKind: aSymbol number: windowNumber.
	windowPosition := self auxiliaryWindowPositionForKind: aSymbol index: windowNumber.
	aSymbol = #browser ifTrue: [
		window := SigBrowserWindow
			id: windowId
			title: windowTitle
			taskbarLabel: windowTaskbarLabel
			position: windowPosition.
		auxiliaryWindows addLast: window.
		^ window ].
	window := Dictionary new
		at: #id put: windowId;
		at: #kind put: aSymbol;
		at: #title put: windowTitle;
		at: #taskbarLabel put: windowTaskbarLabel;
		at: #subtitle put: '';
		at: #position put: windowPosition;
		yourself.
	aSymbol = #workspace ifTrue: [
		window
			at: #workspaceSourceText put: '1 + 2';
			at: #workspaceResultText put: '' ].
	aSymbol = #symbolList ifTrue: [
		window
			at: #selectedSymbolListDictionaryName put: #UserGlobals;
			at: #selectedSymbolListEntryKey put: nil ].
	auxiliaryWindows addLast: window.
	^ window
]

{ #category : 'actions' }
SigExplorerApplication >> openAdditionalWindowOfKind: aSymbol [
	| window |
	window := self newAuxiliaryWindowForKind: aSymbol.
	self requestWindowShow: (window at: #id).
	self setStatusMessage: 'Opened ', (window at: #title)
]

{ #category : 'private' }
SigExplorerApplication >> newInspectorWindowForObject: anObject label: aLabel title: aTitle [
	^ self
		newInspectorWindowForSnapshot: (self gateway inspectionSnapshotFor: anObject)
		label: aLabel
		title: aTitle
]

{ #category : 'private' }
SigExplorerApplication >> newInspectorWindowForSnapshot: anInspection label: aLabel title: aTitle [
	| window windowNumber windowTitle |
	self pruneOldInspectorWindows.
	windowNumber := nextInspectorWindowNumber := nextInspectorWindowNumber + 1.
	windowTitle := aTitle ifNil: [ self inspectorWindowTitleForWindowNumber: windowNumber ].
	window := SigInspectorWindow
		id: 'sig-window-object-', windowNumber printString
		title: windowTitle
		taskbarLabel: (aTitle ifNil: [ self inspectorTaskbarLabelForWindowNumber: windowNumber ])
		position: (self inspectorWindowPositionForIndex: windowNumber)
		label: aLabel
		rowsTitle: (anInspection at: #rowsTitle ifAbsent: [ 'Details' ])
		rows: (anInspection at: #rows ifAbsent: [ #() ])
		text: (anInspection at: #printString ifAbsent: [ '' ]).
	window className: (anInspection at: #className ifAbsent: [ '' ]).
	window displayString: (anInspection at: #displayString ifAbsent: [ '' ]).
	inspectorWindows addLast: window.
	^ window
]

{ #category : 'actions' }
SigExplorerApplication >> openSelectedEntryInNewWindow [
	| association window |
	association := self selectedAssociation.
	association ifNil: [
		self setStatusMessage: 'Select an explorer entry before opening it'.
		^ self ].
	window := self
		newInspectorWindowForObject: association value
		label: 'Explorer / ', association key asString
		title: association key asString.
	self requestWindowShow: window windowId.
	self setStatusMessage: 'Opened ', association key asString, ' in a new window'
]

{ #category : 'actions' }
SigExplorerApplication >> inspectSelectedEntry [
	| association window |
	association := self selectedAssociation.
	association ifNil: [
		self setStatusMessage: 'Select an explorer entry before inspecting it'.
		^ self ].
	window := self
		newInspectorWindowForObject: association value
		label: 'Explorer / ', association key asString
		title: association key asString.
	self requestWindowShow: window windowId.
	self setStatusMessage: 'Inspecting ', association key asString
]

{ #category : 'actions' }
SigExplorerApplication >> openSelectedSymbolListEntryInNewWindow [
	^ self openSelectedSymbolListEntryInNewWindowFor: nil
]

{ #category : 'actions' }
SigExplorerApplication >> openSelectedSymbolListEntryInNewWindowFor: aWindow [
	| association window |
	association := self selectedSymbolListAssociationForWindow: aWindow.
	association ifNil: [
		self setStatusMessage: 'Select a symbol binding before opening it'.
		^ self ].
	window := self
		newInspectorWindowForObject: association value
		label: 'Symbols / ', association key asString
		title: association key asString.
	self requestWindowShow: window windowId.
	self setStatusMessage: 'Opened ', association key asString, ' in a new window'
]

{ #category : 'actions' }
SigExplorerApplication >> inspectSelectedSymbolListEntry [
	^ self inspectSelectedSymbolListEntryFor: nil
]

{ #category : 'actions' }
SigExplorerApplication >> inspectSelectedSymbolListEntryFor: aWindow [
	| association window |
	association := self selectedSymbolListAssociationForWindow: aWindow.
	association ifNil: [
		self setStatusMessage: 'Select a symbol binding before inspecting it'.
		^ self ].
	window := self
		newInspectorWindowForObject: association value
		label: 'Symbols / ', association key asString
		title: association key asString.
	self requestWindowShow: window windowId.
	self setStatusMessage: 'Inspecting ', association key asString
]

{ #category : 'actions' }
SigExplorerApplication >> inspectStructuredInspectorRow: aRow [
	| object title window |
	(aRow includesKey: #object) ifFalse: [ ^ self ].
	object := aRow at: #object.
	title := aRow at: #key ifAbsent: [ self gateway displayStringFor: object ].
	window := self
		newInspectorWindowForObject: object
		label: 'Inspector / ', title asString
		title: title asString.
	self requestWindowShow: window windowId.
	self setStatusMessage: 'Inspecting ', title asString
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

  function resetWindowFrameScroll() {
    getManagedWindows().forEach(function (win) {
      win.scrollLeft = 0;
      win.scrollTop = 0;
    });
  }

  function dedupeGemStoneLogo() {
    var logos = Array.prototype.slice.call(document.querySelectorAll(''.sig-gemstone-logo''));
    logos.slice(1).forEach(function (logo) {
      logo.remove();
    });
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
            manualPosition: win.classList.contains(''sig-window-manual-position''),
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
    var forcedVisibleIds;
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
    forcedVisibleIds = [];
    restoredIds = {};
    state.windows.forEach(function (saved) {
      var forceVisible;
      var serverWantsVisible;
      var win = document.getElementById(saved.id);
      if (!win) return;
      serverWantsVisible = win.style.display !== ''none'';
      forceVisible = serverWantsVisible
        && saved.display === ''none''
        && saved.id === window.SIGAutoShowWindow;
      restoredIds[saved.id] = true;
      if (saved.left) win.style.left = saved.left;
      if (saved.top) win.style.top = saved.top;
      if (saved.width) win.style.width = saved.width;
      if (saved.height) win.style.height = saved.height;
      if (saved.zIndex) win.style.zIndex = saved.zIndex;
      win.classList.toggle(''sig-window-manual-position'', !!saved.manualPosition);
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
      win.style.display = forceVisible
        ? ''block''
        : (saved.display || ''block'');
      win.classList.toggle(''sig-window-collapsed'', forceVisible
        ? false
        : !!saved.collapsed);
      win.classList.toggle(''sig-window-maximized'', !!saved.maximized);
      if (saved.maximized) {
        applyMaximizedBounds(win);
      }
      win.classList.toggle(''sig-window-active'', forceVisible
        ? false
        : !!saved.active);
      clampWindowToDesktop(win);
      if (forceVisible) {
        forcedVisibleIds.push(win.id);
      }
      restored = true;
    });
    runtime.newlyVisibleWindowIds = restored
      ? forcedVisibleIds.concat(getManagedWindows()
          .filter(function (win) {
            return !restoredIds[win.id] && window.getComputedStyle(win).display !== ''none'';
          })
          .map(function (win) { return win.id; }))
      : [];
    if (restored) {
      focusTopVisibleWindow();
      syncTaskbarButtons();
    }
    return restored;
  }

  function extractAutoShowWindow(sourceDocument) {
    var bodyWindow = sourceDocument.body && sourceDocument.body.getAttribute(''data-sig-auto-show-window'');
    var scripts = sourceDocument.querySelectorAll(''script'');
    var index;
    if (bodyWindow) return bodyWindow;
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
    var selectors = [''#sig-context-menu'', ''#sig-desktop'', ''#sig-taskbar''];
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
    hideWorkspaceContextMenus();
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

  function enableManualWindowPosition(win) {
    var metrics = desktopMetrics();
    var box = currentWindowBox(win, metrics);
    win.classList.add(''sig-window-manual-position'');
    if (box.width) win.style.width = Math.round(box.width) + ''px'';
    if (box.height) win.style.height = Math.round(box.height) + ''px'';
    setWindowPosition(win, box.left, box.top);
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
      win.classList.remove(''sig-window-manual-position'');
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
    if (!metrics.desktop || window.matchMedia(''(max-width: 760px)'').matches) return;
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
    if (!metrics.desktop || window.matchMedia(''(max-width: 760px)'').matches) return;
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
    if (!metrics.desktop || window.matchMedia(''(max-width: 760px)'').matches) return;
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
    if (!metrics.desktop || window.matchMedia(''(max-width: 760px)'').matches || !windows.length) return;
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
    var closeForm;
    var submit;
    getManagedWindows().forEach(function (win) {
      win.style.display = ''none'';
      win.classList.remove(''sig-window-active'');
      win.classList.remove(''sig-window-collapsed'');
      win.classList.remove(''sig-window-maximized'');
    });
    setActiveWindow(null);
    syncTaskbarButtons();
    saveDesktopState();
    closeForm = document.querySelector(''form[data-sig-close-all-windows]'');
    submit = closeForm && closeForm.querySelector(''[type="submit"]'');
    if (submit) {
      submit.click();
    }
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
      var metrics;
      var box;
      if (event.target.closest(''.sig-window-controls'')) return;
      if (win.classList.contains(''sig-window-maximized'')) {
        win.classList.remove(''sig-window-maximized'');
        restoreRememberedWindowBounds(win);
      }
      if (window.matchMedia(''(max-width: 760px)'').matches) {
        enableManualWindowPosition(win);
      }
      metrics = desktopMetrics();
      box = currentWindowBox(win, metrics);
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
        var closeForm = win.querySelector(''form[data-sig-window-close]'');
        if (closeForm) {
          win.style.display = ''none'';
          syncTaskbarButtons();
          var btn = closeForm.querySelector(''[type="submit"]'');
          if (btn) btn.click();
        } else {
          hideWindow(win);
        }
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

  function hideWorkspaceContextMenus() {
    Array.prototype.forEach.call(document.querySelectorAll(''.ws-context-menu''), function (menu) {
      menu.style.display = ''none'';
    });
  }

  function installWorkspaceContextMenus() {
    if (runtime.workspaceContextMenusInstalled) return;
    runtime.workspaceContextMenusInstalled = true;

    document.addEventListener(''contextmenu'', function (event) {
      var shell = event.target.closest(''.sig-workspace-shell'');
      var menu;
      if (!shell) return;
      menu = shell.querySelector(''.ws-context-menu'');
      if (!menu) return;
      event.preventDefault();
      closeMenus();
      hideContextMenu();
      hideWorkspaceContextMenus();
      menu.style.display = ''block'';
      menu.style.left = event.clientX + ''px'';
      menu.style.top = event.clientY + ''px'';
    });

    document.addEventListener(''click'', function (event) {
      var action = event.target.closest(''[data-workspace-menu-action]'');
      var button;
      var form;
      var shell;
      if (action) {
        event.preventDefault();
        shell = action.closest(''.sig-workspace-shell'');
        form = shell && shell.querySelector(''form[data-sig-remote]'');
        button = form && form.querySelector(''[data-workspace-action="'' + action.getAttribute(''data-workspace-menu-action'') + ''"]'');
        hideWorkspaceContextMenus();
        if (button) {
          button.click();
        }
        return;
      }
      if (!event.target.closest(''.ws-context-menu'')) {
        hideWorkspaceContextMenus();
      }
    });

    document.addEventListener(''keydown'', function (event) {
      if (event.key === ''Escape'') {
        hideWorkspaceContextMenus();
      }
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
    installWorkspaceContextMenus();
    installLocalCommands();
    installRemoteInteractions();
    restoreScrollPanes();
    resetWindowFrameScroll();
    dedupeGemStoneLogo();
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
	inspectorWindows := OrderedCollection new.
	nextInspectorWindowNumber := 0.
	auxiliaryWindows := OrderedCollection new.
	nextAuxiliaryWindowNumber := 0.
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
	gatewayOverride ifNotNil: [ ^ gatewayOverride ].
	^ self session gateway
]

{ #category : 'accessing' }
SigExplorerApplication >> gateway: aGateway [
	gatewayOverride := aGateway
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
	browserSourceDraftText := nil.
	selectedSymbolListDictionaryName := #UserGlobals.
	selectedSymbolListEntryKey := nil.
	debuggerSnapshotText := nil.
	debuggerState := self
		newDebuggerStateWithWalkback: 'No debugger snapshot captured yet.'
		errorText: 'No gateway errors recorded.'
		gatewayWalkback: 'No gateway walkback recorded.'
		frames: #().
	workspaceSourceText := '1 + 2'.
	workspaceResultText := ''.
	transcriptEntries := OrderedCollection new.
	pendingWindowIdToShow := nil.
	debuggerWindows := OrderedCollection new.
	nextDebuggerWindowNumber := 0.
	inspectorWindows := OrderedCollection new.
	nextInspectorWindowNumber := 0.
	auxiliaryWindows := OrderedCollection new.
	nextAuxiliaryWindowNumber := 0.
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
	^ self renderBrowserOn: html window: nil
]

{ #category : 'rendering' }
SigExplorerApplication >> renderBrowserOn: html window: aWindow [
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
				selected: (self browserDictionaryNameForWindow: aWindow) asString
				callback: [ :each | self selectBrowserDictionaryNamed: each forWindow: aWindow ]
				filterPlaceholder: 'Filter dictionaries'.
			html div class: 'cb-splitter'; with: ''.
			self
				renderClassBrowserColumnOn: html
				title: 'Classes'
				items: ((self browserClassAssociationsForWindow: aWindow) collect: [ :each | each key asString ])
				selected: (self browserClassNameForWindow: aWindow)
				callback: [ :each | self selectBrowserClassNamed: each asString forWindow: aWindow ]
				filterPlaceholder: 'Filter classes'.
			html div class: 'cb-splitter'; with: ''.
			self
				renderClassBrowserColumnOn: html
				title: 'Categories'
				items: (self browserProtocolNamesForWindow: aWindow)
				selected: (self browserProtocolNameForWindow: aWindow)
				callback: [ :each | self selectBrowserProtocolNamed: each asString forWindow: aWindow ]
				filterPlaceholder: 'Filter categories'.
			html div class: 'cb-splitter'; with: ''.
			self
				renderClassBrowserColumnOn: html
				title: 'Methods'
				items: (self browserSelectorNamesForWindow: aWindow)
				selected: (self browserSelectorForWindow: aWindow)
				callback: [ :each | self selectBrowserSelectorNamed: each asString forWindow: aWindow ]
				filterPlaceholder: 'Filter methods' ].
			html div class: 'cb-source-wrap'; with: [
				html form
					class: 'cb-source-form';
					attributeAt: 'data-sig-remote' put: 'true';
					with: [
						html div class: 'cb-source-hdr'; with: [
							html div class: 'cb-source-title-group'; with: [
								html span: 'Source'.
								html span class: 'cb-source-note'; with: (self browserSourceHeadingTextForWindow: aWindow) ].
							html div class: 'cb-source-actions'; with: [
								html submitButton
									class: 'btn-ghost cb-source-btn';
									callback: [ self browserResetSourceDraftForWindow: aWindow ];
									with: 'Revert'.
								html submitButton
									class: 'btn cb-source-btn';
									callback: [ self browserCompileSourceForWindow: aWindow ];
									with: 'Compile' ] ].
						html div class: 'cb-source sig-scroll-pane'; with: [
							html textArea
								class: 'cb-source-editor';
								attributeAt: 'spellcheck' put: 'false';
								attributeAt: 'wrap' put: 'off';
								attributeAt: 'placeholder' put: 'Smalltalk method source';
								rows: 18;
								callback: [ :value | self browserSourceDraftText: value forWindow: aWindow ];
								value: (self browserEditableSourceTextForWindow: aWindow) ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderAuxiliaryWindowOn: html window: aWindow [
	| kind |
	kind := aWindow at: #kind ifAbsent: [ #explorer ].
	kind = #explorer ifTrue: [ ^ self renderExplorerOn: html ].
	kind = #workspace ifTrue: [ ^ self renderWorkspaceOn: html window: aWindow ].
	kind = #browser ifTrue: [ ^ self renderBrowserOn: html window: aWindow ].
	kind = #symbolList ifTrue: [ ^ self renderSymbolListBrowserOn: html window: aWindow ].
	kind = #session ifTrue: [ ^ self renderSessionOn: html ].
	kind = #transcript ifTrue: [ ^ self renderTranscriptOn: html ].
	self renderExplorerOn: html
]

{ #category : 'rendering' }
SigExplorerApplication >> renderAuxiliaryWindowsOn: html [
	auxiliaryWindows do: [ :each |
		self
			renderFloatingWindowOn: html
			id: (each at: #id)
			title: (each at: #title)
			subtitle: (each at: #subtitle)
			position: (each at: #position)
			closeCallback: [ auxiliaryWindows remove: each ifAbsent: [] ]
			with: [ :body | self renderAuxiliaryWindowOn: body window: each ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderContentOn: html [
	self renderDesktopContextMenuOn: html.
	html div
		id: 'sig-desktop';
		class: 'sig-desktop';
		with: [ :desktop |
			self renderGemStoneLogoOn: desktop.
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-explorer'
				title: 'Explorer'
				subtitle: ''
				position: 'top: 1.25rem; left: 1.25rem; width: 29rem; height: 34rem;'
				with: [ :body | self renderExplorerOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-workspace'
				title: 'Workspace'
				subtitle: ''
				position: 'top: 1.25rem; left: 31rem; width: 50rem; height: 34rem;'
				with: [ :body | self renderWorkspaceOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-browser'
				title: 'Class Browser'
				subtitle: ''
				position: (self hiddenWindowPosition: 'top: 1.75rem; left: 31rem; width: 50rem; height: 31rem;')
				with: [ :body | self renderBrowserOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-symbol-list'
				title: 'Symbol List Browser'
				subtitle: ''
				position: (self hiddenWindowPosition: 'top: 2.5rem; left: 82rem; width: 30rem; height: 28rem;')
				with: [ :body | self renderSymbolListBrowserOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-inspector'
				title: 'Inspector'
				subtitle: ''
				position: self baseInspectorWindowPosition
				with: [ :body | self renderInspectorOn: body ].
			self
				renderFloatingWindowOn: desktop
					id: 'sig-window-debugger'
					title: 'Debugger'
					subtitle: ''
					position: (self baseDebuggerWindowPosition)
					with: [ :body | self renderDebuggerOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-session'
				title: 'Session'
				subtitle: ''
				position: (self hiddenWindowPosition: 'top: 36rem; left: 31rem; width: 24rem; height: 18rem;')
				with: [ :body | self renderSessionOn: body ].
			self
				renderFloatingWindowOn: desktop
				id: 'sig-window-transcript'
				title: 'Transcript'
				subtitle: ''
				position: (self hiddenWindowPosition: 'top: 36rem; left: 56rem; width: 35rem; height: 18rem;')
				with: [ :body | self renderTranscriptOn: body ].
			self renderAuxiliaryWindowsOn: desktop.
			self renderInspectorWindowsOn: desktop.
			self renderExceptionDebuggerWindowsOn: desktop ].
	self renderTaskBarOn: html
]

{ #category : 'rendering' }
SigExplorerApplication >> gemStoneLogoPngDataUri [
	^ 'data:image/png;base64,',
		'iVBORw0KGgoAAAANSUhEUgAAAG8AAACACAYAAAAF1zc3AAAS9UlEQVR4nO2de3Ac1ZWHv9MjjUa2MXZMDDgh4WUwoZYkwG6ILZOYIrVZNiy7Cxbe',
		'hbC1yVZRtcliyRgTYkNkE97vRwwYwpsYMC9XFjawgL2AcR7IMgFjyRbGwRCQDci2XqOZ7nv2jxnJI2ke3T3d0kiZr0o1M9333tPqMz3d997fOVcY',
		'A8T/OP5Uk+BUKwkkDCQBWyEOOAaJg9VrsBIGeklY7WaZNGB7taPXcToWswZvtzvA2QP2HkjsgeQu6HmPZNcOLj8WEm7bb4ZZFpzu6ljAqfBy8KWK',
		'LbwlyJOKTgQBFBRE0q9oahuAcp0fx6XrvoOyCqgatL3fgqQ/C9zsxXEACXinCp4BDnBRfIXlpfFSZcJfdbVZyrUuiu60qs0Vfu3IIt5F+YUbOybC',
		'Uq/tHwftwM9cFO2w4WdjwnkAsUmd14O25iujIovlfPYUZaiKpcDHee3A4sO2s9tP80fBXcAfCxRbeix8PGacJ9PpVbEuyV1CN0YmO/cVbecC9kLe',
		'q6rpwIPwbUfAUajPU+RdC24HGDPOAxh3UucTiK7Nvteqk1qcQAx9ibvJfnUoSp2sKs7ODHiZ1L1vCBbUT4fe9PuxRUSsOhh48kT0icof2P8XlA2p',
		'xUGoG7JDWTn5KV4JxAZcSNpJGbw8HX7d92HMOS86u+tN0F9mbIrbdsWioO3Ihaxh4NXRXVFJnp9tbxwF2wRuydjkGAZ+Ycac8wDsRMUSEd0NoHBD',
		'9Xnx90IxFMm4OoQrq1fwfpDNG/g58FH6453HwFuZ+8ek8/Y7rXOXwfo50BaLJ9x0IXwh9WwDbhHYFpvIDUG3PwM6FJZIqgvREHT7JYs+TjS+uuo7',
		'odu5lYnJBk4NrX2wmuG7YbVfpkyZMmXKlClTpkyZMmXKlClTpswoRUb6AABOaefL1cL0mA3jqaDKgQnAeDul9Jlgw3i7gvHAeCf9mQj726kyE6nc',
		'Ovn43X8qZKdn48TvG0erI0kHDCmVmQMk04ozAzgOVjK9L2mIpN9bSQeSPC8LyWtHr+evEc7Mtd/uBNMD2rPvvd0Ddjsk2yCxi+2HfcKdbs5bSajH',
		'7CqMJmS1WIzDMVgIGFAEMSntl7EM6gggIIIYxSCoJT0oX3Fjx8CRonqZIqB9arLUq0j6vQqqiqj26dAQFEXek059sKCRajbTw/eBadl2i2SYlbSm',
		'LS09UwFR/tnN/wIlMiX0yjh2CHKzz+pXTf767u1uCo7r3ns1SMErNBsiulAaiBcs9yM6Ed+TsmsO/ZSn3RYuCecBdCXMVcCfPVZ7P2p3up5Hk5n0',
		'COanHm0g6Bq5gKdcV1jAQwjrPJpx1MoirchDyThv7VQ6VdTTiRX0gmkn0u2lTuyErpXAqx6qOILWeTqu1O/sfFJ3UbfcdcjbBSV/AygZ5wE8OYkH',
		'QX7vsviLxx7XvdqrDRHUqNbh9sQKd8l/ejupALKQRpSHXRZvt8WV2HYAJeU8BMVy6ujXpuckaZzIf/k1M/6b3RuAB1wUbY84jueT2k8li4C9hYqJ',
		'0DBtLZ94bb60nAc8OIX1AivzlVG4ZeZxHc3F2HEicgnkV08r2iDnez+pfUgdbcA1+QuxedLnucNP+yXnPAAiziKgK8feNqKxnxdrYsJJXW2KXJWn',
		'yObKXuPrpA6gk+uBrTn3GxbICpJ+mi5J5915AB8qel22fSpc9J0j2ouLN0hTfUDXTcCWbPtEqJfz/Z3UAe00kAB+kmP3f++/kt/4bbsknQcgtrl2',
		'aJ9M1//jkXG3DwGFbRxLwhIZKsgVXV15jv18YHYW8hTCC4M2J4xhYTHtlqzzbjqEHjCZnV2D6HyRgg8znqg6pXs1SqajEmoigSusUephX1ygwK0T',
		'76WlmCZL1nkAV0xzHtX+Ppncc+4RyT+EYccyZgH0/0TeFJvXm/WntBhkIe8AKwAEdlbFKfq+XdLOQ1C1mA98GrV7l4Rlpuq0xDuo3AW0VdmJfA8x',
		'xWFxKfApsFhWFBknOFq48U/RY8O2ob+Z+LneZ6JnhW3HXsrf6VwiYdspU6ZMmTJlypQpCQLTsMxYdcIlRvXQoNoTpfvgqRMvWjtnbX/Hdq4Sad/L',
		'ddWONT4KVCtEbahGiCpU25DabhE1FtUGYgoxWxinMM5AtbEYpxYxG8YBMcPGA4/vHDCGqc0H7NfTG78Th0ocxXJIaV0cUsHFDqmcDYO2STJd1k5t',
		'y/wsjnlL6rk8qPMDAWpYVM1WQa4Mqj2QyzIdB7BKcE7dwx4VrRcFVaFfjqKgkhKFaFoYknqRtD4F+r6rqppOlCSqas0cYnnGJx3dTRN2oczvb08z',
		'0hyl/2Tw9rTVvixIfS+CgsPdwZ2bFIF10ltqm56AXGk0PLNjwrjsYcJdE7kWAor9FnnwoBP2/jbbrkQkshT8TwcNtMPTspD/DaStDAIdYVFDHQSR',
		'60QXNJ7emFXesF7oETSI0ZYOcZycsotJx+1pV+WyAOwkxOjFAbQzhECdt2Ve05sKvyxcMi+vtcxtejJfgV9P4mEEt3KJrAhc/qXju/MKnsZt61yB',
		'eJdADOImmZ9nPq8IAh/bNKmrYrfP6o4a/TGFZg4EFaN1FJZL5EBbI+O6bi1USmpxxJE6fzYA2GlFTGhjpYE7r7W2aZeiPp+qdMWWeU1vuim5agrr',
		'UR73Y0WU+dOnD8kulJXqkzrXCOpe9jfAkFxSdKK6PIQyq7Bfu3UbeJ6ralfb8nSPcSxzEXiT/iG88PXjup/zUkUtsxAKC24H1WqK/Nm531sdb4Ti',
		'vMbzG5MGudBTJZWGLf/a6Onp7tEp7ABu9lAloVbkAk/HBVR/I/4ecKOnSmrVSYMn3aZnQpvP21rb+CzwPy6Lb56w25+CKoa5in0pnvIj3Fwzo8PX',
		'7HUs2e1a0a3I45X/YQeSQC4foU7GqiWZM9T5WNB4fqMvsc/yqXSiXOqiaJtWxnwPIsgcOkHcxCDEHRMJpWswmFCdt+WsxubCaX1ldUvtBt8KKoCp',
		'Bzr3AY15rcCiYlVnsZO7HoL8MQiq3FD97/HtxdhxS+gyiN6oyTdSkRBjFy32aRCMIjmVWAJvNB5VvOpMBDVIzhgEgbYodmiJ6gYTuvO2/9PG3SBZ',
		'nyIFvbF53puBiH1uPtheS/bssAYjP2qQYB4exp/S3QiS64uwSM4tLG8PimERILVw+ApgQP9N0TY7EQ20A6sVFUOywwp6f+3RPUWNxgzGSWk9Bztp',
		'Q2VzMjBNqRuGRz1Wu8pBZUDSa0uti1vP/V2g39KrD4xvI508O02HFakIXHU24dSuwTEIqsbMD7trMJhhk/61nN24RukPUGxs3tz4UCiGqu1lQBsA',
		'Iku/f2i3u26ER2ImfgNKK4DCyupa+7Uw7ORjWHWbgr0QiCtSR0jf0oYp7BVYBrQmk723F6zgEzmNXhH5CdCDsTxH245Kjnr8hJqwbTQoFTe+X3li',
		'2HYA4qur/n447GQjQwax/hgw/xZc09oNOmTw98tX3LojdmTrIcHZyc6BczZ/XB1NHBM1KWlEpYGYgUosogpRA5WktxmLKClJRSVQreyNKU7URKh2',
		'UvWrDMSMlXoFqoxF1ECVZT98wNd6Pgz7/8lGhgwivhUqvwcEqE4eIpFpqjjkw/MQeYAQ04gIvBipjteJI/cgVKQWZhK0P11HupxKv2QipVeQlLSB',
		'fdtTdfr+D03l4jCp9wIbpny1J2so2nCQcc+bY+MxcN4jCsx/97zX30ZTARchYYux6tfsxyZB7gnRjmJkvgTUf/TDoAeW2S/ifjDZK7+CmlcBKqSq',
		'L+AicES4bfO8N94GMGIWh2YHeWTaiR3D/oSZSZanTcvtYLIXuoH+J7JNtes/AwlUBpdmV7zCLOv78Pz+fAZadCjVULQzgp0r2nXYyOK8mc0gy4M1',
		'I1dCzQDF18Gf3+8XwNtBWlFlcWo4bh8dk7gd2BSoHeTKQ0boISWTHP28vIPJXnkPEkNkfGvnrLVVgrvHCjRtkSPuHWJHsDFB3stlW2xi103Bteef',
		'HM6b3Q7qP//IQBbCnKwSgi1zm14iY1WqYnBU66hdlVV2+OQBvIioJ+lDLlTNgsMO8yqJCIc8IywfuVlBsRAvQ01e8Y5jpJ6hS415QkVWbj27Ke/M',
		'dcTR+XhcwzWLpZe+7iPrUljkcV6tAwMHkz3igClYv3Ve47sItxVhpydimYIz3A9PpRVcrfeaC9sxVjHnI3AKjG3Oehnw+027A052d+VGq5fhVocy',
		'GJWrNp/Z5CoNo22ZBvoGrb0iLJ95XNdbhQsOHy4GpnUB3n/W2iHperXiljPWdahkn7AtQM6Yhmw8MoW9qDb4sPNZkoplhYsNLy6cN3sbUFBdPBBd',
		'AnM8Pa1u2dR4L+ApVYeo1ueKacjF7qnmblBXwt5+VH566jEdoXT2i8HtlNDluP9Z2wS29+GvBoyIqcO9hH1N89n5YxqysUpwVL3cu3Tj7hndYQ6z',
		'+cal82o6wHXETH1qnNQ7zXM3vg6uJOwOHrPCZrL8YHsNuMtcq5bU1UpAqzwHjIfJ2Fn3Am8UKPQk1BQVh+ZE7IXkzvgHgAh3tpy1oahuTEScghJ2',
		'gcf+YXo8sFWeg8aD88RA3p+1ODgXFXtArWf+8QNRrs9TpN0kpaFYO9cfxHsC+UZKeiTCsIhn/eJRBnHyOtBc95nr4FuBrIrcKVXXQPb1C1S51GtM',
		'Qy5iFfaV5JCwi+g1Zx4e95UJfrjwoWExCxgamfMhdOXP6OqBD2rX94jqkI63wDvTpk68Kyg7DVPpFLImJd/hdCbyXf0lgQ/nfStLZI5eBH+b9z7l',
		'lebapkcZnIVdpH5wkoFiWfYF50EYGGWr6IXnfTX/fbcU8KkeS2ZGzKyHmkeDOqB+BHUsK1Na/mTz3MbBCUcDsSPCfPru5SKv/fCwxBOB2wkBn86b',
		'00lqctWAzE8ntQic1rPeaEK4H4iDXfTDUC6WfDH5W5RfAY5jzI+DTsgaFkUk0VEL1i0GfSS4wxnKlNNe/fyUc545l5imngydRG9V0niLhnXBt4/Z',
		'dfChkz794YWHJ70FhY4gRSi4xMC6F4FWQlwN7NPnTm6bXPvs8khlz7upLRESlcGnq3yhddrHE/jCjAKRYiVFkYrpWetBgr/fDUAXVY3bfTVI4KmD',
		'ByAsbKxtHFXZZwO4Yn77RbCbgfHFtzWERpj1NyDm6FVfOwO1ngnBBsDrLXM31BRMIVJiBBCrcNIHoGH0iRT0R6mfZ2iZu3E1EFi6/AyMGlM32hwHgQWaRHKOiBTBgzD7d5kbjKGeoGWJyt1b',
		'5m0MJWt82ATkvJk9ZOgyA6CvKzKArfM2bFYIbIQFaHdE3SQjKEkCDPGatRIISkF8BdRkHXOsSiYvIyBZooj+rLW2aVcQbY0EATpPFIzXBf+ysQ2',
		'SN+fa+dY5b7ULuJZY5ELgnfGfWa4W1i1VAg6uPHkDuF7wLweyIJfOs49mjrgDKE4MJFLvN/dLqRBCZGyFqwX/sqMvwazCarWUuLbOnw0AVoUyTj',
		'rMhOC8k9pA/OQisSHiWlvSUrvhZRA/ssQecUzwCz2NACHFpCduALZ7q6PLYaann0KNWJ5liSpc0/wvG7d7qVOqhOS8OXFQL9/uzyDqWRe55cw/b',
		'EM8ra/+/n4xGbFI1qAJMRvE7FUgLsU7sgS+4U8XGY1dgUtZogiedZ6lTNipPOoonDB8EyR8p61vOWNdB8JiF0Vfbp67wV/G2hIlZOfN2gjcV6CQ',
		'b51nHy2bNjwAmi9FlS0UlSu6JBmGJDqymJxLWusTxeo8gZTaOnWVZx9cVm5vrm0sqSCRIBgG583aCVyRZUccgntkb65tWg+abX31nem0kWOOYUp',
		'fNfkWhi5pHZjOsw9NfRkGqL5UZEic+lhhmJx3bAIGLGkdqM6zjy21b36oAwcINqSjj8Ykw5g4btZq6F8rfFHQOs8+uoleR2qAQFUILUHdXyCvfA',
		'VeeyUjH1QoHP3Y8bUzHjvhgTBtlAKhnsTsvPoDsL4bqglLuw687K6L2xoe2hmqnRFmBJz3+ufAbAGmhGjkMqgJI8NSSTECi9zP/AwIIaVUPzsg5',
		'jpOfTQzAs4DSAaeUmofeiGcOGbGL/MxQs6bYwNhzKmtg5pRESQSBCPkPICa5wg2PaQBDS3opRQZQedBwOkh74bZoyfQIABG2Hkzm0F9rd41iL2Q',
		'bAignVHFCDsPgAaK12E2wJyPiz+U0UUJOG92O/hKKdVHM8RCWz+hlCkB5wF8dCf+dZgL4MRRrb/0ywiMsORi3Skp3aYnnoWa74VyOKOAErnyIJ',
		'0e0kvW2yQwakKQw6CEnAfp5KwudZhyK9T4Wv91rFBizpv1Loibh4+dkAhzfHRUUGLOA9ClQIHHflkCc3YPx9GUMiXovJqOApnlN8KHY1ba4IUSe',
		'trMRC1Y93vghKH7zLfh5JJNoziclOCVB+kkAnUM1WE+VnbcPkrUeQA1rwFPZ2zogciIr99TSpSw8wAys9HqtfDN7SN5NGU889pV8OoOeD6MJD2j',
		'mv8Hd2vGzbb+e84AAAAASUVORK5CYII='
]

{ #category : 'rendering' }
SigExplorerApplication >> renderGemStoneLogoOn: html [
	html image
		id: 'sig-gemstone-logo';
		class: 'sig-gemstone-logo';
		attributeAt: 'src' put: self gemStoneLogoPngDataUri;
		altText: 'GemStone'
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
					self renderContextActionOn: html label: 'Open Explorer' callback: [ self openAdditionalWindowOfKind: #explorer ].
					self renderContextActionOn: html label: 'Open Workspace' callback: [ self openAdditionalWindowOfKind: #workspace ].
					self renderContextActionOn: html label: 'Open Class Browser' callback: [ self openAdditionalWindowOfKind: #browser ].
					self renderContextActionOn: html label: 'Open Symbol List Browser' callback: [ self openAdditionalWindowOfKind: #symbolList ].
					auxiliaryWindows do: [ :each |
						self
							renderLocalWindowCommandOn: html
							label: ('Open ', (each at: #title))
							target: (each at: #id) ].
					self renderContextActionOn: html label: 'Open Session' callback: [ self openAdditionalWindowOfKind: #session ].
					self renderContextActionOn: html label: 'Open Transcript' callback: [ self openAdditionalWindowOfKind: #transcript ] ].
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
	| association inspection rows rowsTitle |
	association := self selectedAssociation.
	inspection := association
		ifNil: [ nil ]
		ifNotNil: [ self gateway inspectionSnapshotFor: association value ].
	rows := inspection
		ifNil: [ #() ]
		ifNotNil: [ inspection at: #rows ifAbsent: [ #() ] ].
	rowsTitle := inspection
		ifNil: [ 'Keys / Values' ]
		ifNotNil: [ inspection at: #rowsTitle ifAbsent: [ 'Keys / Values' ] ].
	html div class: 'exp-wrap'; with: [
		html div class: 'exp-user-row'; with: [
			html span class: 'exp-toolbar-label'; with: 'Symbol List for'.
			html select
				class: 'exp-user-select';
				with: [
					html option
						attributeAt: 'selected' put: 'selected';
						with: self gateway currentUserId ] ].
		html div class: 'exp-split'; with: [
			html div class: 'exp-section'; with: [
				html div class: 'exp-pane-title'; with: 'Roots'.
				html div class: 'sig-scroll-pane exp-scroll exp-scroll-rows-10'; with: [
					html unorderedList class: 'exp-list-entries'; with: [
						self gateway rootNames do: [ :each |
							html listItem: [
								html anchor
									class: (each = selectedRootName
										ifTrue: [ 'exp-item selected' ]
										ifFalse: [ 'exp-item' ]);
									attributeAt: 'data-sig-remote' put: 'true';
									callback: [ self selectRootNamed: each ];
									with: each asString ] ] ] ] ].
			html div class: 'exp-section'; with: [
				html div class: 'exp-pane-title'; with: 'Entries'.
				html div class: 'sig-scroll-pane exp-scroll exp-scroll-rows-10'; with: [
					self entryAssociations isEmpty
						ifTrue: [ html paragraph class: 'sig-window-note'; with: 'No entries available.' ]
						ifFalse: [
							html unorderedList class: 'exp-list-entries'; with: [
								self entryAssociations do: [ :each |
									html listItem: [
										html anchor
											class: (each key asString = selectedEntryKey
												ifTrue: [ 'exp-item selected' ]
												ifFalse: [ 'exp-item' ]);
											attributeAt: 'data-sig-remote' put: 'true';
											callback: [ self selectEntryKey: each key asString ];
											with: each key asString, '  ', (self gateway displayStringFor: each value) ] ] ] ] ] ] ].
		html div class: 'sig-command-row exp-command-row'; with: [
			self renderActionLinkOn: html label: 'Open' callback: [ self openSelectedEntryInNewWindow ] ].
		html div class: 'exp-section'; with: [
			html div class: 'exp-pane-title'; with: rowsTitle.
			html div class: 'sig-scroll-pane exp-scroll exp-scroll-short'; with: [
				association
					ifNil: [ html paragraph class: 'sig-window-note'; with: 'Select an entry to inspect its value.' ]
					ifNotNil: [
						html table class: 'sig-table exp-table'; with: [
							html tableHead: [
								html tableRow: [
									html tableHeading: 'Key / Index'.
									html tableHeading: 'Value' ] ].
							html tableBody: [
								rows do: [ :each |
									html tableRow
										class: 'exp-table-row';
										with: [
											html tableData
												class: 'exp-table-key';
												with: (each at: #key ifAbsent: [ '' ]).
											html tableData
												class: 'exp-table-value';
												with: [
													(each includesKey: #object)
														ifTrue: [
															html anchor
																class: 'inspector-value-link';
																attributeAt: 'data-sig-remote' put: 'true';
																callback: [ self inspectStructuredInspectorRow: each ];
																with: (each at: #value ifAbsent: [ '' ]) ]
														ifFalse: [ html text: (each at: #value ifAbsent: [ '' ]) ] ] ] ] ] ] ] ] ].
		html div class: 'exp-section'; with: [
			html div class: 'exp-pane-title'; with: 'PrintString'.
			html div class: 'sig-scroll-pane exp-scroll exp-scroll-tall'; with: [
				html preformatted
					class: 'sig-pre';
					with: (association
						ifNil: [ 'Nothing selected.' ]
						ifNotNil: [ self gateway longDisplayStringFor: association value ]) ] ] ]
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
			label: 'Restart'
			enabled: (aState at: #canRestart ifAbsent: [ false ])
			callback: [ self performDebuggerAction: #restart inState: aState ].
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
	html div
		class: 'sig-debugger-shell';
		attributeAt: 'data-sig-tab-scope' put: 'debugger';
		with: [
			html div class: 'tab-strip'; with: [
				html div
					class: 'tab-item active';
					attributeAt: 'data-sig-tab' put: 'stack';
					with: 'Stack Trace'.
				html div
					class: 'tab-item';
					attributeAt: 'data-sig-tab' put: 'diagnostics';
					with: 'Thread Local Storage' ].
			html div
				class: 'sig-debugger-tab-panel active';
				attributeAt: 'data-sig-tab-panel' put: 'stack';
				with: [
					| selectedFrame |
					selectedFrame := self selectedDebuggerFrameInState: aState.
					html div class: 'dbg-summary'; with: [
						html div class: 'dbg-summary-source'; with: (self debuggerFrameSourceStatusTextFor: selectedFrame).
						html div class: 'dbg-summary-error'; with: (aState at: #errorText ifAbsent: [ 'No gateway errors recorded.' ]) ].
					self renderDebuggerFramesOn: html state: aState.
					self renderDebuggerLiveCommandsOn: html state: aState.
					self renderDebuggerFrameDetailsOn: html state: aState ].
			html div
				class: 'sig-debugger-tab-panel';
				attributeAt: 'data-sig-tab-panel' put: 'diagnostics';
				with: [
					self renderDebuggerCommandsOn: html state: aState.
					self renderDebuggerDiagnosticsOn: html state: aState ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerFrameDetailsOn: html state: aState [
	| frameCount framePosition selectedFrame visibleFrames |
	selectedFrame := self selectedDebuggerFrameInState: aState.
	visibleFrames := self debuggerVisibleFramesInState: aState.
	frameCount := visibleFrames size.
	framePosition := selectedFrame
		ifNil: [ 0 ]
		ifNotNil: [ visibleFrames indexOf: selectedFrame ifAbsent: [ 0 ] ].
	html div class: 'dbg-source-pane'; with: [
		html div
			class: 'dbg-source-meta';
			with: (self
				debuggerFrameSourceMetaTextFor: selectedFrame
				position: framePosition
				count: frameCount).
	html div
		class: 'dbg-source-code';
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
									html span class: 'sig-debugger-frame-text'; with: (self debuggerFrameSummaryFor: each) ] ] ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerSourceOn: html frame: aFrame [
	| currentLineNumber cursorLocation lineRecords resolvedLocation sourceText |
	sourceText := self debuggerFrameSourceTextFor: aFrame.
	((aFrame isNil) or: [ sourceText = 'Source unavailable for this frame.' ]) ifTrue: [
		html preformatted class: 'sig-pre'; with: sourceText.
		^ self ].
	lineRecords := self debuggerSourceLineRecordsFor: aFrame.
	resolvedLocation := self debuggerResolvedSourceLocationFor: aFrame.
	currentLineNumber := resolvedLocation ifNil: [ nil ] ifNotNil: [ resolvedLocation first ].
	cursorLocation := resolvedLocation.
	html div class: 'sig-debugger-source-lines'; with: [
		lineRecords withIndexDo: [ :record :displayIndex |
			| cursorColumn isCurrentLine lineText |
			lineText := record second.
			isCurrentLine := displayIndex = currentLineNumber.
			cursorColumn := ((cursorLocation notNil and: [ cursorLocation first = displayIndex ])
				ifTrue: [ cursorLocation second ]
				ifFalse: [
					isCurrentLine
						ifTrue: [ self debuggerDefaultCursorColumnForLine: lineText ]
						ifFalse: [ nil ] ]).
			html div
				class: (isCurrentLine
					ifTrue: [ 'dbg-source-line sig-debugger-source-line current selected active' ]
					ifFalse: [ 'dbg-source-line sig-debugger-source-line' ]);
				with: [
					html span class: 'dbg-source-marker'; with: [
						isCurrentLine
							ifTrue: [
								html span
									class: 'dbg-step-cursor';
									with: (self debuggerFrameStepCursorLabelFor: aFrame) ]
							ifFalse: [
								html span
									class: 'dbg-step-cursor-spacer';
									with: ' ' ] ].
					html span class: 'dbg-source-lno'; with: displayIndex printString.
					self
						renderDebuggerSourceTextOn: html
						line: lineText
						cursorColumn: cursorColumn ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderDebuggerSourceTextOn: html line: aString cursorColumn: anInteger [
	| after before caretColumn lineText |
	lineText := aString ifNil: [ '' ].
	anInteger ifNil: [
		html span
			class: 'dbg-source-text';
			with: lineText.
		^ self ].
	caretColumn := anInteger max: 1.
	caretColumn := caretColumn min: lineText size + 1.
	before := caretColumn <= 1
		ifTrue: [ '' ]
		ifFalse: [ lineText copyFrom: 1 to: caretColumn - 1 ].
	after := caretColumn > lineText size
		ifTrue: [ '' ]
		ifFalse: [ lineText copyFrom: caretColumn to: lineText size ].
	html span
		class: 'dbg-source-text';
		with: [
			before isEmpty ifFalse: [ html text: before ].
			html span
				class: 'dbg-inline-cursor';
				attributeAt: 'aria-label' put: 'Next instruction';
				with: '|'.
			after isEmpty ifFalse: [ html text: after ] ]
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
			closeCallback: [ debuggerWindows remove: each ifAbsent: [] ]
			with: [ :body | self renderExceptionDebuggerOn: body window: each ] ]
]

{ #category : 'private' }
SigExplorerApplication >> hiddenWindowPosition: aPositionString [
	^ aPositionString, ' display: none;'
]

{ #category : 'private' }
SigExplorerApplication >> baseDebuggerWindowPosition [
	| defaultPosition state |
	defaultPosition := 'top: 8rem; left: 31rem; width: 50rem; height: 40rem;'.
	(pendingWindowIdToShow = 'sig-window-debugger') ifTrue: [ ^ defaultPosition ].
	state := self debuggerState.
	((self debuggerFramesInState: state) isEmpty not
		or: [ (state at: #debugSessionId ifAbsent: [ nil ]) notNil ])
		ifTrue: [ ^ defaultPosition ].
	((state at: #errorText ifAbsent: [ 'No gateway errors recorded.' ]) ~= 'No gateway errors recorded.')
		ifTrue: [ ^ defaultPosition ].
	^ self hiddenWindowPosition: defaultPosition
]

{ #category : 'private' }
SigExplorerApplication >> baseInspectorWindowPosition [
	| defaultPosition |
	defaultPosition := 'top: 18rem; left: 48rem; width: 28rem; height: 23rem;'.
	(pendingWindowIdToShow = 'sig-window-inspector') ifTrue: [ ^ defaultPosition ].
	inspectorLabel = 'Nothing selected' ifFalse: [ ^ defaultPosition ].
	^ self hiddenWindowPosition: defaultPosition
]

{ #category : 'rendering' }
SigExplorerApplication >> renderFloatingWindowOn: html id: anId title: aTitle subtitle: aSubtitle position: aPositionString with: aBlock [
	self
		renderFloatingWindowOn: html
		id: anId title: aTitle subtitle: aSubtitle position: aPositionString
		closeCallback: nil
		with: aBlock
]

{ #category : 'rendering' }
SigExplorerApplication >> renderFloatingWindowOn: html id: anId title: aTitle subtitle: aSubtitle position: aPositionString closeCallback: aCloseBlock with: aBlock [
	html div
		id: anId;
		class: 'sig-floating-window';
		style: aPositionString;
		with: [ :window |
			window div class: 'sig-window-titlebar'; with: [ :titleBar |
				titleBar div class: 'sig-window-headings'; with: [ :headings |
					headings heading level2; with: aTitle.
					aSubtitle isEmpty ifFalse: [
						headings span class: 'sig-window-subtitle'; with: aSubtitle ] ].
				titleBar div class: 'sig-window-controls'; with: [ :controls |
					controls anchor
						class: 'sig-window-control collapse';
						attributeAt: 'href' put: '#';
						attributeAt: 'data-sig-window-action' put: 'collapse';
						attributeAt: 'title' put: 'Minimise window';
						attributeAt: 'aria-label' put: 'Minimise window';
						with: '_'.
					controls anchor
						class: 'sig-window-control expand';
						attributeAt: 'href' put: '#';
						attributeAt: 'data-sig-window-action' put: 'expand';
						attributeAt: 'title' put: 'Expand window';
						attributeAt: 'aria-label' put: 'Expand window';
						with: '[]'.
					controls anchor
						class: 'sig-window-control close';
						attributeAt: 'href' put: '#';
						attributeAt: 'data-sig-window-action' put: 'close';
						attributeAt: 'title' put: 'Close window';
						attributeAt: 'aria-label' put: 'Close window';
						with: 'x' ] ].
			aCloseBlock ifNotNil: [
				window form
					attributeAt: 'data-sig-window-close' put: 'true';
					attributeAt: 'data-sig-remote' put: 'true';
					with: [
						window submitButton
							style: 'display:none';
							callback: aCloseBlock ] ].
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
SigExplorerApplication >> renderContextActionOn: html label: aLabel callback: aBlock [
	html anchor
		class: 'sig-local-command';
		attributeAt: 'data-sig-remote' put: 'true';
		callback: aBlock;
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
					self renderActionLinkOn: html label: 'Open' callback: [ self openSelectedEntryInNewWindow ].
					self renderActionLinkOn: html label: 'Inspect' callback: [ self inspectSelectedEntry ] ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderInspectorOn: html [
	self
		renderInspectorContentsOn: html
		label: inspectorLabel
		rowsTitle: 'PrintString'
		rows: #()
		text: inspectorText
]

{ #category : 'rendering' }
SigExplorerApplication >> renderInspectorContentsOn: html label: aLabel className: aClassName displayString: aDisplayString rowsTitle: rowsTitle rows: rows text: aString [
	(aClassName notNil and: [ aClassName notEmpty ]) ifTrue: [
		html div class: 'insp-header'; with: [
			html span class: 'insp-class'; with: aClassName.
			(aDisplayString notNil and: [ aDisplayString notEmpty and: [ aDisplayString ~= aClassName ] ]) ifTrue: [
				html span class: 'insp-display'; with: aDisplayString ] ] ].
	(rows notNil and: [ rows isEmpty not ])
		ifTrue: [
			html div class: 'exp-wrap inspector-wrap'; with: [
				html div class: 'exp-section inspector-section inspector-keys'; with: [
					html div class: 'exp-pane-title'; with: rowsTitle.
					html div class: 'sig-scroll-pane exp-scroll inspector-scroll'; with: [
						html unorderedList class: 'inspector-key-list'; with: [
							rows do: [ :each |
								html listItem
									class: 'inspector-key-item';
									with: (each at: #key ifAbsent: [ '' ]) ] ] ] ].
				html div class: 'exp-section inspector-section inspector-values'; with: [
					html div class: 'exp-pane-title'; with: 'Values'.
					html div class: 'sig-scroll-pane exp-scroll inspector-scroll'; with: [
						html div class: 'inspector-value-list'; with: [
							rows do: [ :each |
								html div class: 'inspector-value-row'; with: [
									html div class: 'inspector-value-key'; with: (each at: #key ifAbsent: [ '' ]).
									html div class: 'inspector-value-cell'; with: [
										(each includesKey: #object)
											ifTrue: [
												html anchor
													class: 'inspector-value-link';
													attributeAt: 'data-sig-remote' put: 'true';
													callback: [ self inspectStructuredInspectorRow: each ];
													with: (each at: #value ifAbsent: [ '' ]) ]
											ifFalse: [ html text: (each at: #value ifAbsent: [ '' ]) ] ] ] ].
							html div class: 'inspector-print-inline'; with: [
								html div class: 'exp-pane-title'; with: 'PrintString'.
								html preformatted class: 'sig-pre'; with: aString ] ] ] ] ] ]
		ifFalse: [
			html div class: 'sig-source-window'; with: [
				html heading level3; with: aLabel.
				html div class: 'sig-scroll-pane sig-inspector-pane'; with: [
					html preformatted class: 'sig-pre'; with: aString ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderInspectorContentsOn: html label: aLabel rowsTitle: rowsTitle rows: rows text: aString [
	self
		renderInspectorContentsOn: html
		label: aLabel
		className: ''
		displayString: ''
		rowsTitle: rowsTitle
		rows: rows
		text: aString
]

{ #category : 'rendering' }
SigExplorerApplication >> renderInspectorWindowOn: html window: aWindow [
	self
		renderInspectorContentsOn: html
		label: aWindow label
		className: aWindow className
		displayString: aWindow displayString
		rowsTitle: aWindow rowsTitle
		rows: aWindow rows
		text: aWindow text
]

{ #category : 'rendering' }
SigExplorerApplication >> renderInspectorWindowsOn: html [
	inspectorWindows do: [ :each |
		self
			renderFloatingWindowOn: html
			id: (each at: #id)
			title: (each at: #title)
			subtitle: (each at: #subtitle)
			position: (each at: #position)
			closeCallback: [ inspectorWindows remove: each ifAbsent: [] ]
			with: [ :body | self renderInspectorWindowOn: body window: each ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderSessionOn: html [
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
			html div class: 'sig-taskbar-strip sig-taskbar-strip-secondary sig-taskbar-strip-menus'; with: [ :strip |
				self renderMenuDropdownOn: strip label: 'Windows' with: [ :menu |
					self renderWindowMenuItemsOn: menu ].
				self renderMenuDropdownOn: strip label: 'Session' with: [ :menu |
					self renderSessionMenuItemsOn: menu ].
				self renderMenuDropdownOn: strip label: 'Arrange' with: [ :menu |
					self renderArrangeMenuItemsOn: menu ] ].
				html div class: 'sig-taskbar-strip sig-taskbar-strip-secondary'; with: [
					self renderTaskBarActionCommandOn: html label: 'Cascade' action: 'cascade'.
					self renderTaskBarActionCommandOn: html label: 'Tile' action: 'tile'.
					self renderTaskBarActionCommandOn: html label: 'Show All' action: 'show-all'.
					self renderTaskBarActionCommandOn: html label: 'Minimise All' action: 'minimise-all'.
					self renderTaskBarActionCommandOn: html label: 'Close All' action: 'close-all' ].
			html div class: 'sig-taskbar-strip'; with: [
				self renderTaskBarWindowCommandOn: html label: 'Explorer' target: 'sig-window-explorer' pinned: true.
				self renderTaskBarWindowCommandOn: html label: 'Workspace' target: 'sig-window-workspace' pinned: true.
				self renderTaskBarWindowCommandOn: html label: 'Class Browser' target: 'sig-window-browser'.
				self renderTaskBarWindowCommandOn: html label: 'Symbols' target: 'sig-window-symbol-list'.
				self renderTaskBarWindowCommandOn: html label: 'Inspector' target: 'sig-window-inspector'.
				inspectorWindows do: [ :each |
					self
						renderTaskBarWindowCommandOn: html
						label: (each at: #taskbarLabel)
						target: (each at: #id) ].
				self renderTaskBarWindowCommandOn: html label: 'Debugger' target: 'sig-window-debugger'.
				debuggerWindows do: [ :each |
					self
						renderTaskBarWindowCommandOn: html
						label: (each at: #taskbarLabel)
						target: (each at: #id) ].
				auxiliaryWindows do: [ :each |
					self
						renderTaskBarWindowCommandOn: html
						label: (each at: #taskbarLabel)
						target: (each at: #id) ].
				self renderTaskBarWindowCommandOn: html label: 'Session' target: 'sig-window-session'.
				self renderTaskBarWindowCommandOn: html label: 'Transcript' target: 'sig-window-transcript' ].
			html form
				style: 'display:none';
				attributeAt: 'data-sig-close-all-windows' put: 'true';
				attributeAt: 'data-sig-remote' put: 'true';
				with: [
					html submitButton
						callback: [ self closeAllTransientWindows ];
						with: 'Close All Windows' ].
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
	self renderMenuActionOn: html label: 'Explorer' callback: [ self openAdditionalWindowOfKind: #explorer ].
	self renderMenuActionOn: html label: 'Workspace' callback: [ self openAdditionalWindowOfKind: #workspace ].
	self renderMenuActionOn: html label: 'Class Browser' callback: [ self openAdditionalWindowOfKind: #browser ].
	self renderMenuActionOn: html label: 'Symbol List Browser' callback: [ self openAdditionalWindowOfKind: #symbolList ].
	auxiliaryWindows do: [ :each |
		self
			renderMenuWindowCommandOn: html
			label: (each at: #title)
			target: (each at: #id) ].
	self renderMenuActionOn: html label: 'Session' callback: [ self openAdditionalWindowOfKind: #session ].
	self renderMenuActionOn: html label: 'Transcript' callback: [ self openAdditionalWindowOfKind: #transcript ]
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
SigExplorerApplication >> renderBrowserMenuItemsOn: html [
	self renderMenuActionOn: html label: 'Open Class Browser' callback: [ self openAdditionalWindowOfKind: #browser ].
	self renderMenuActionOn: html label: 'Compile' callback: [ self browserCompileSource ].
	self renderMenuActionOn: html label: 'Revert Source' callback: [ self browserResetSourceDraft ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderExplorerMenuItemsOn: html [
	self renderMenuActionOn: html label: 'Open Explorer' callback: [ self openAdditionalWindowOfKind: #explorer ].
	self renderMenuActionOn: html label: 'Open Selection' callback: [ self openSelectedEntryInNewWindow ]
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
SigExplorerApplication >> renderSymbolListMenuItemsOn: html [
	self renderMenuActionOn: html label: 'Open Symbol List Browser' callback: [ self openAdditionalWindowOfKind: #symbolList ].
	self renderMenuActionOn: html label: 'Open Selection' callback: [ self openSelectedSymbolListEntryInNewWindow ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderTranscriptMenuItemsOn: html [
	self renderMenuActionOn: html label: 'Open Transcript' callback: [ self openAdditionalWindowOfKind: #transcript ].
	self renderMenuActionOn: html label: 'Clear Transcript' callback: [ self clearTranscript ].
	self renderMenuActionOn: html label: 'Capture Walkback' callback: [ self captureDebuggerSnapshot ]
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
	^ self renderWorkspaceOn: html window: nil
]

{ #category : 'rendering' }
SigExplorerApplication >> renderWorkspaceOn: html window: aWindow [
	html div class: 'sig-workspace-shell'; with: [
		html form
			class: 'sig-workspace-form';
			attributeAt: 'data-sig-remote' put: 'true';
			with: [
				html div class: 'ws-input-row'; with: [
					html textArea
						class: 'ws-code-area';
						attributeAt: 'spellcheck' put: 'false';
						attributeAt: 'wrap' put: 'off';
						attributeAt: 'placeholder' put: 'Smalltalk expression...';
						rows: 8;
						callback: [ :value | self workspaceSourceText: value forWindow: aWindow ];
						value: (self workspaceSourceTextForWindow: aWindow).
					html div class: 'ws-controls'; with: [
						| doItButton |
						doItButton := html submitButton.
						doItButton
							class: 'btn';
							attributeAt: 'data-sig-primary-submit' put: 'workspace-doit';
							attributeAt: 'data-workspace-action' put: 'doit';
							callback: [ self workspaceDoItForWindow: aWindow ];
							with: 'Do it'.
						html submitButton
							class: 'btn-ghost';
							attributeAt: 'data-workspace-action' put: 'print';
							callback: [ self workspacePrintItForWindow: aWindow ];
							with: 'Print it'.
						html submitButton
							class: 'btn-ghost';
							attributeAt: 'data-workspace-action' put: 'inspect';
							callback: [ self workspaceInspectItForWindow: aWindow ];
							with: 'Inspect it'.
						html submitButton
							class: 'btn-ghost';
							attributeAt: 'data-workspace-action' put: 'debug';
							callback: [ self workspaceDebugItForWindow: aWindow ];
							with: 'Debug it'.
						html submitButton
							class: 'btn-ghost';
							attributeAt: 'data-workspace-action' put: 'clear';
							callback: [ self clearWorkspaceOutputForWindow: aWindow ];
							with: 'Clear' ] ].
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
						with: 'Continue' ] ].
		html div class: 'ws-context-menu'; with: [
			html anchor
				url: '#';
				class: 'sig-local-command ws-context-action';
				attributeAt: 'data-workspace-menu-action' put: 'doit';
				with: 'Do it'.
			html anchor
				url: '#';
				class: 'sig-local-command ws-context-action';
				attributeAt: 'data-workspace-menu-action' put: 'print';
				with: 'Print it'.
			html anchor
				url: '#';
				class: 'sig-local-command ws-context-action';
				attributeAt: 'data-workspace-menu-action' put: 'inspect';
				with: 'Inspect it'.
			html anchor
				url: '#';
				class: 'sig-local-command ws-context-action';
				attributeAt: 'data-workspace-menu-action' put: 'debug';
				with: 'Debug it'.
			html anchor
				url: '#';
				class: 'sig-local-command ws-context-action';
				attributeAt: 'data-workspace-menu-action' put: 'clear';
				with: 'Clear' ] ]
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

{ #category : 'querying' }
SigExplorerApplication >> selectedSymbolListAssociationForWindow: aWindow [
	(self selectedSymbolListEntryKeyForWindow: aWindow) ifNil: [ ^ nil ].
	^ (self symbolListEntryAssociationsForWindow: aWindow)
		detect: [ :each | each key asString = (self selectedSymbolListEntryKeyForWindow: aWindow) ]
		ifNone: [ nil ]
]

{ #category : 'querying' }
SigExplorerApplication >> symbolListEntryAssociationsForWindow: aWindow [
	^ self gateway
		symbolListEntryAssociationsForDictionaryNamed: (self selectedSymbolListDictionaryNameForWindow: aWindow)
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedSymbolListDictionaryName [
	^ selectedSymbolListDictionaryName
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedSymbolListDictionaryNameForWindow: aWindow [
	^ aWindow
		ifNil: [ selectedSymbolListDictionaryName ]
		ifNotNil: [ aWindow at: #selectedSymbolListDictionaryName ifAbsent: [ #UserGlobals ] ]
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedSymbolListEntryKey [
	^ selectedSymbolListEntryKey
]

{ #category : 'accessing' }
SigExplorerApplication >> selectedSymbolListEntryKeyForWindow: aWindow [
	^ aWindow
		ifNil: [ selectedSymbolListEntryKey ]
		ifNotNil: [ aWindow at: #selectedSymbolListEntryKey ifAbsent: [ nil ] ]
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceResultText [
	^ workspaceResultText
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceResultTextForWindow: aWindow [
	^ aWindow
		ifNil: [ workspaceResultText ]
		ifNotNil: [ aWindow at: #workspaceResultText ifAbsent: [ '' ] ]
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceResultText: aString forWindow: aWindow [
	aWindow
		ifNil: [ workspaceResultText := aString ]
		ifNotNil: [ aWindow at: #workspaceResultText put: aString ]
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceSourceText [
	^ workspaceSourceText
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceSourceTextForWindow: aWindow [
	^ aWindow
		ifNil: [ workspaceSourceText ]
		ifNotNil: [ aWindow at: #workspaceSourceText ifAbsent: [ '1 + 2' ] ]
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceSourceText: aString [
	workspaceSourceText := aString
]

{ #category : 'accessing' }
SigExplorerApplication >> workspaceSourceText: aString forWindow: aWindow [
	aWindow
		ifNil: [ workspaceSourceText := aString ]
		ifNotNil: [ aWindow at: #workspaceSourceText put: aString ]
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
SigExplorerApplication >> inspectorWindows [
	^ inspectorWindows
]

{ #category : 'accessing' }
SigExplorerApplication >> auxiliaryWindows [
	^ auxiliaryWindows
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
	^ self selectBrowserClassNamed: aString forWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserClassNamed: aString forWindow: aWindow [
	self browserClassName: aString forWindow: aWindow.
	self browserProtocolName: nil forWindow: aWindow.
	self browserSelector: nil forWindow: aWindow.
	self browserSourceDraftText: nil forWindow: aWindow.
	self setStatusMessage: 'Browsing class ', aString
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserDictionaryNamed: aSymbol [
	^ self selectBrowserDictionaryNamed: aSymbol forWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserDictionaryNamed: aSymbol forWindow: aWindow [
	aWindow
		ifNil: [
			selectedBrowserDictionaryName := aSymbol.
			selectedBrowserClassName := nil.
			selectedBrowserProtocolName := nil.
			selectedBrowserSelector := nil.
			browserSourceDraftText := nil ]
		ifNotNil: [ aWindow selectedDictionaryName: aSymbol ].
	self setStatusMessage: 'Browsing dictionary ', aSymbol asString
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserProtocolNamed: aString [
	^ self selectBrowserProtocolNamed: aString forWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserProtocolNamed: aString forWindow: aWindow [
	self browserProtocolName: aString forWindow: aWindow.
	self browserSelector: nil forWindow: aWindow.
	self browserSourceDraftText: nil forWindow: aWindow.
	self setStatusMessage: 'Browsing protocol ', aString
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserSelectorNamed: aString [
	^ self selectBrowserSelectorNamed: aString forWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserSelectorNamed: aString forWindow: aWindow [
	self browserSelector: aString forWindow: aWindow.
	self browserSourceDraftText: nil forWindow: aWindow.
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
	^ self selectSymbolListDictionaryNamed: aSymbol forWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> selectSymbolListDictionaryNamed: aSymbol forWindow: aWindow [
	aWindow
		ifNil: [
			selectedSymbolListDictionaryName := aSymbol.
			selectedSymbolListEntryKey := nil ]
		ifNotNil: [
			aWindow at: #selectedSymbolListDictionaryName put: aSymbol.
			aWindow at: #selectedSymbolListEntryKey put: nil ].
	aWindow ifNil: [ self clearInspector ].
	self setStatusMessage: 'Browsing symbol dictionary ', aSymbol asString
]

{ #category : 'actions' }
SigExplorerApplication >> selectSymbolListEntryKey: aString [
	^ self selectSymbolListEntryKey: aString forWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> selectSymbolListEntryKey: aString forWindow: aWindow [
	| association |
	aWindow
		ifNil: [ selectedSymbolListEntryKey := aString ]
		ifNotNil: [ aWindow at: #selectedSymbolListEntryKey put: aString ].
	association := self selectedSymbolListAssociationForWindow: aWindow.
	(aWindow isNil and: [ association ifNotNil: [ true ] ifNil: [ false ] ]) ifTrue: [
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
	^ self renderSymbolListBrowserOn: html window: nil
]

{ #category : 'rendering' }
SigExplorerApplication >> renderSymbolListBrowserOn: html window: aWindow [
	| association |
	association := self selectedSymbolListAssociationForWindow: aWindow.
	html div class: 'exp-wrap slb-wrap'; with: [
		html div class: 'exp-toolbar'; with: [
			html div class: 'exp-toolbar-group'; with: [
				html span class: 'exp-toolbar-label'; with: 'Dictionary'.
				html span class: 'exp-toolbar-value'; with: (self selectedSymbolListDictionaryNameForWindow: aWindow) asString ].
			html div class: 'exp-toolbar-group'; with: [
				html span class: 'exp-toolbar-label'; with: 'Selection'.
				html span
					class: 'exp-toolbar-value';
					with: ((self selectedSymbolListEntryKeyForWindow: aWindow)
						ifNil: [ 'None' ]
						ifNotNil: [ self selectedSymbolListEntryKeyForWindow: aWindow ]) ] ].
		html div class: 'exp-main-grid slb-main-grid'; with: [
			html div class: 'exp-pane'; with: [
				html div class: 'exp-pane-title'; with: 'Dictionaries'.
				html div class: 'sig-scroll-pane exp-list exp-scroll exp-scroll-rows-10'; with: [
					html unorderedList class: 'exp-list-entries'; with: [
						self symbolListDictionaryNames do: [ :each |
							html listItem: [
								html anchor
									class: (each asString = (self selectedSymbolListDictionaryNameForWindow: aWindow) asString
										ifTrue: [ 'exp-item selected' ]
										ifFalse: [ 'exp-item' ]);
									attributeAt: 'data-sig-remote' put: 'true';
									callback: [ self selectSymbolListDictionaryNamed: each forWindow: aWindow ];
									with: each asString ] ] ] ] ].
			html div class: 'exp-pane'; with: [
				html div class: 'exp-pane-title'; with: 'Bindings'.
				html div class: 'sig-scroll-pane exp-list exp-scroll exp-scroll-rows-10'; with: [
					(self symbolListEntryAssociationsForWindow: aWindow) isEmpty
						ifTrue: [ html paragraph class: 'sig-window-note'; with: 'No bindings.' ]
						ifFalse: [
							html unorderedList class: 'exp-list-entries'; with: [
								(self symbolListEntryAssociationsForWindow: aWindow) do: [ :each |
									html listItem: [
										html anchor
											class: (each key asString = (self selectedSymbolListEntryKeyForWindow: aWindow)
												ifTrue: [ 'exp-item selected' ]
												ifFalse: [ 'exp-item' ]);
											attributeAt: 'data-sig-remote' put: 'true';
											callback: [ self selectSymbolListEntryKey: each key asString forWindow: aWindow ];
											with: each key asString ] ] ] ] ] ] ].
		html div class: 'exp-selection-row'; with: [
			html span class: 'exp-selection-label'; with: 'Selection'.
			html span
				class: 'exp-selection-value';
				with: (association
					ifNil: [ 'No symbol binding selected.' ]
					ifNotNil: [ association key asString ]) ].
		html div class: 'sig-command-row exp-command-row'; with: [
			self renderActionLinkOn: html label: 'Open' callback: [ self openSelectedSymbolListEntryInNewWindowFor: aWindow ].
			self renderActionLinkOn: html label: 'Inspect' callback: [ self inspectSelectedSymbolListEntryFor: aWindow ] ].
		html div class: 'exp-detail-grid slb-detail-grid'; with: [
			html div class: 'exp-pane'; with: [
				html div class: 'exp-pane-title'; with: 'Keys / Values'.
				html div class: 'sig-scroll-pane exp-scroll slb-detail-scroll'; with: [
					association
						ifNil: [ html paragraph class: 'sig-window-note'; with: 'Select a binding to inspect its value.' ]
						ifNotNil: [
							html table class: 'sig-table exp-table'; with: [
								html tableHead: [
									html tableRow: [
										html tableHeading: 'Key / Index'.
										html tableHeading: 'Value' ] ].
								html tableBody: [
									html tableRow: [
										html tableData: 'Value'.
										html tableData: (self gateway displayStringFor: association value) ].
									html tableRow: [
										html tableData: 'Class'.
										html tableData: association value class name asString ] ] ] ] ] ].
			html div class: 'exp-pane'; with: [
				html div class: 'exp-pane-title'; with: 'PrintString'.
				html div class: 'sig-scroll-pane exp-scroll exp-print-pane slb-print-pane'; with: [
					html preformatted class: 'sig-pre'; with: (association
						ifNil: [ 'Nothing selected.' ]
						ifNotNil: [ self gateway longDisplayStringFor: association value ]) ] ] ] ]
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
		--sig-bg: #e8e8e8;
		--sig-surface-0: #f5f5f5;
		--sig-surface-1: #ffffff;
		--sig-surface-2: #eeeeee;
		--sig-surface-3: #d4d4d4;
		--sig-surface-4: #c8c8c8;
		--sig-window-bg: #f5f5f5;
		--sig-window-border: #b0b0b0;
		--sig-border: #b0b0b0;
		--sig-border-soft: #c0c0c0;
		--sig-text: #1c1c1c;
		--sig-muted: #555555;
		--sig-subtle: #777777;
		--sig-accent: #1874CD;
		--sig-accent-strong: #1874CD;
		--sig-success: #1a7a1a;
		--sig-warning: #8a6000;
		--sig-danger: #aa0000;
		--sig-shadow: none;
		--sig-panel-shadow: none;
		--sig-window-glow: none;
		--sig-inset-highlight: none;
}

html,
body {
	height: 100%;
}

body {
		font-family: "SF Pro Text", "Segoe UI", system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
		margin: 0;
		color: var(--sig-text);
		background: #e8e8e8;
	background-attachment: fixed;
	letter-spacing: 0;
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




.sig-menu {
	position: relative;
}

.sig-menu-trigger {
	display: inline-flex;
	align-items: center;
	justify-content: center;
		padding: 0.14rem 0.44rem;
		min-height: 1.55rem;
		border-radius: 0;
		background: #d4d4d4;
		border: 1px solid #b0b0b0;
	color: #1c1c1c;
	font-size: 0.72rem;
	font-weight: 500;
	box-shadow: none;
}

.sig-menu-trigger:hover {
	background: #c4c4c4;
	text-decoration: none;
}

.sig-menu-panel {
	position: absolute;
	top: calc(100% + 0.3rem);
	left: 0;
	display: none;
	min-width: 13rem;
		padding: 0.22rem;
		border-radius: 0;
		background: #f5f5f5;
		border: 1px solid #b0b0b0;
		box-shadow: none;
	backdrop-filter: none;
}

.sig-menu.open .sig-menu-panel {
	display: block;
}

.sig-menu-item {
	display: block;
	padding: 0.32rem 0.44rem;
	border-radius: 0;
	color: #1c1c1c;
	font-size: 0.72rem;
	white-space: nowrap;
}

.sig-menu-item:hover {
	background: #1874CD;
	color: #ffffff;
	text-decoration: none;
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
	gap: 0.25rem 0.35rem;
		padding: 0.22rem 0.42rem;
		background: #d4d4d4;
	backdrop-filter: none;
		border-top: 1px solid #b0b0b0;
	box-shadow: none;
}


.sig-taskbar-strip {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	gap: 0.35rem;
}

.sig-taskbar-strip-secondary {
		padding-left: 0.35rem;
		border-left: 1px solid #b0b0b0;
}

.sig-taskbar-strip-menus .sig-menu-trigger {
	display: inline-flex;
	align-items: center;
	justify-content: center;
		padding: 0.14rem 0.44rem;
		border-radius: 0;
		background: #d4d4d4;
		border: 1px solid #b0b0b0;
	color: #1c1c1c;
	font-size: 0.7rem;
	font-weight: 500;
	box-shadow: none;
}

.sig-taskbar-strip-menus .sig-menu-trigger:hover,
.sig-taskbar-strip-menus .sig-menu.open .sig-menu-trigger {
	background: #c4c4c4;
	color: #1c1c1c;
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
		padding: 0.14rem 0.42rem;
		border-radius: 0;
		background: #d4d4d4;
		border: 1px solid #b0b0b0;
	color: #1c1c1c;
	font-size: 0.7rem;
	white-space: nowrap;
	box-shadow: none;
}

.sig-taskbar-button:not(.sig-taskbar-command):not(.open):not([data-sig-taskbar-pinned="true"]) {
	display: none;
}

.sig-taskbar-button.open {
	background: #c4c4c4;
	border-color: #b0b0b0;
}

.sig-taskbar-button.active {
	background: #1874CD;
	border-color: #1874CD;
	color: #ffffff;
	font-weight: 600;
}

.sig-taskbar-button:hover {
	text-decoration: none;
	background: #c4c4c4;
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

.sig-taskbar-session {
	font-weight: 600;
	color: #1c1c1c;
}

.sig-taskbar-note {
	padding: 0.18rem 0.5rem;
	border-radius: 0;
	background: #e8e8e8;
	color: #1c1c1c;
	border: 1px solid #b0b0b0;
}

.wa-toolbar {
	position: fixed !important;
	right: 0.85rem !important;
	left: auto !important;
	top: auto !important;
	bottom: 5rem !important;
	max-width: calc(100vw - 2rem);
	z-index: 2300 !important;
		border-radius: 0;
		border: 1px solid #b0b0b0;
		background: #f5f5f5;
	box-shadow: none;
}

.sig-desktop {
	position: relative;
	min-height: 100vh;
	padding-top: 1rem;
	padding-right: 1rem;
	padding-bottom: 4.2rem;
	overflow: auto;
}

.sig-gemstone-logo {
	position: fixed;
	right: 1rem;
	bottom: 7rem;
	width: 111px;
	height: 128px;
	z-index: 1;
	pointer-events: none;
	opacity: 1;
	background: #e8e8e8;
	display: block;
	object-fit: contain;
}

.sig-floating-window {
	position: absolute;
	min-width: 22rem;
	max-width: calc(100vw - 2rem);
	min-height: 18rem;
	max-height: calc(100vh - 5.5rem);
	height: min(32rem, calc(68vh - 1rem));
		background: #f5f5f5;
		border: 1px solid #b0b0b0;
		border-radius: 0;
		box-shadow: none;
	backdrop-filter: none;
	overflow: hidden;
	scrollbar-gutter: stable both-edges;
	scrollbar-width: thin;
	scrollbar-color: #a0a0a0 #e0e0e0;
	resize: both;
	display: flex;
	flex-direction: column;
	z-index: 10;
}

.sig-floating-window::before {
	content: none;
}

.sig-floating-window.sig-window-active {
		border-color: #1874CD;
		box-shadow: none;
}

.sig-window-titlebar {
	display: flex;
	align-items: center;
	justify-content: flex-start;
		gap: 0.32rem;
		padding: 0 0.42rem;
		height: 20px;
		background: #d4d4d4;
		border-bottom: 1px solid #b0b0b0;
	box-shadow: none;
	color: var(--sig-text);
	cursor: grab;
	flex: 0 0 auto;
	position: sticky;
	top: 0;
	z-index: 2;
}

.sig-window-headings h2 {
	margin: 0;
		font-size: 11px;
	font-weight: 600;
	letter-spacing: 0;
	color: #1c1c1c;
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
}

.sig-window-headings {
	flex: 1;
	min-width: 0;
	display: flex;
	align-items: center;
}

.sig-window-subtitle {
	display: none;
}

.sig-window-controls {
		display: flex;
		gap: 0.24rem;
		flex-shrink: 0;
}

.sig-window-control {
	display: inline-flex;
	align-items: center;
	justify-content: center;
		padding: 0.1rem 0.38rem;
		height: 16px;
	border-radius: 0;
		border: 1px solid #b0b0b0;
	background: #d4d4d4;
	color: #1c1c1c;
	font-size: 9px;
	line-height: 1;
	cursor: pointer;
	box-shadow: none;
}

.sig-window-control:hover {
	text-decoration: none;
	background: #c4c4c4;
}

.sig-window-body {
	padding: 0;
	flex: 1 1 auto;
	min-height: 0;
	overflow-x: auto;
	overflow-y: scroll;
	display: flex;
	flex-direction: column;
		background: #ffffff;
	overscroll-behavior: contain;
	scrollbar-gutter: stable both-edges;
	scrollbar-width: thin;
	scrollbar-color: #a0a0a0 #e0e0e0;
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
	gap: 0.55rem;
	min-height: 0;
}

.sig-session-grid {
	display: grid;
	grid-template-columns: repeat(3, minmax(0, 1fr));
	gap: 0.55rem;
}

.sig-session-panel {
		background: transparent;
		border: none;
		border-radius: 0;
		padding: 0.42rem 0.48rem;
	box-shadow: none;
}

.sig-summary-list {
	margin: 0;
	display: grid;
	grid-template-columns: max-content minmax(0, 1fr);
	gap: 0.3rem 0.8rem;
}

.sig-summary-list dt {
	font-size: 0.76rem;
	font-weight: 700;
	letter-spacing: 0.04em;
	text-transform: uppercase;
	color: var(--sig-muted);
}

.sig-summary-list dd {
	margin: 0;
	line-height: 1.45;
	color: #eef6ff;
	min-width: 0;
	word-break: break-word;
}

.sig-sidebar,
.sig-main,
.sig-browser-column,
.sig-source-window,
.sig-debugger-panel {
		position: relative;
		background: transparent;
		border: none;
		border-radius: 0;
		padding: 0.42rem 0.48rem;
		box-shadow: none;
}

.sig-sidebar,
.sig-main,
.sig-source-window {
	display: flex;
	flex-direction: column;
	gap: 0.5rem;
	min-height: 0;
}

.sig-browser-grid {
	display: grid;
	grid-template-columns: repeat(4, minmax(0, 1fr));
	gap: 0.55rem;
	margin-bottom: 0.55rem;
}

.sig-symbol-list-grid {
	display: grid;
	grid-template-columns: 13rem 1fr 1fr;
	gap: 0.55rem;
}

.exp-wrap {
	display: flex;
	flex-direction: column;
	flex: 0 0 auto;
	gap: 0.35rem;
	min-height: max-content;
	padding: 0.35rem;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.8rem;
	line-height: 1.42;
	overflow-x: auto;
	overflow-y: scroll;
	overscroll-behavior: contain;
	scrollbar-gutter: stable both-edges;
	scrollbar-width: thin;
	scrollbar-color: #a0a0a0 #e0e0e0;
}

.slb-wrap {
	flex: 1 1 auto;
	min-height: 0;
	height: 100%;
	overflow: hidden;
}

.inspector-wrap {
		display: grid;
		grid-template-columns: minmax(10rem, 0.46fr) minmax(0, 1fr);
		grid-template-rows: minmax(0, 1fr);
		flex: 1 1 0;
		min-height: 0;
		overflow: hidden;
}

.exp-meta {
		display: grid;
		gap: 0.3rem;
}

.exp-user-row {
		display: grid;
		grid-template-columns: max-content minmax(0, 1fr);
		gap: 0.45rem;
		align-items: center;
}

.exp-meta-row {
			display: grid;
			grid-template-columns: max-content minmax(0, 1fr);
			gap: 0.4rem;
			align-items: center;
}

.exp-split {
		display: grid;
		grid-template-columns: minmax(0, 12rem) minmax(0, 1fr);
		gap: 0.35rem;
		align-items: start;
}

.exp-toolbar,
.exp-pane {
		position: relative;
		background: transparent;
		border: none;
		border-radius: 0;
		box-shadow: none;
}

.exp-toolbar {
		display: flex;
		flex-wrap: wrap;
		align-items: center;
		gap: 0.35rem 0.55rem;
		padding: 0.3rem 0.38rem;
}

.exp-toolbar-group {
		display: inline-flex;
	align-items: center;
	gap: 0.35rem;
	min-width: 0;
}

.exp-toolbar-label,
.exp-selection-label,
.exp-pane-title {
	font-size: 0.68rem;
	font-weight: 700;
	letter-spacing: 0.08em;
	text-transform: uppercase;
	color: #555555;
}

.exp-toolbar-value,
.exp-selection-value {
	display: inline-flex;
	align-items: center;
	min-height: 1.9rem;
	padding: 0.18rem 0.42rem;
	border: 1px solid #b0b0b0;
	border-radius: 0;
	background: #ffffff;
	color: #1c1c1c;
	min-width: 0;
}

.exp-user-select {
		width: 100%;
		min-height: 1.95rem;
		padding: 0.28rem 2rem 0.28rem 0.55rem;
		background: #ffffff;
		color: #1c1c1c;
		border: 1px solid #b0b0b0;
		border-radius: 0;
		font: inherit;
		appearance: none;
		-webkit-appearance: none;
		background-image:
			linear-gradient(45deg, transparent 50%, #555555 50%),
			linear-gradient(135deg, #555555 50%, transparent 50%);
		background-position:
			calc(100% - 1rem) 50%,
			calc(100% - 0.7rem) 50%;
		background-size: 0.38rem 0.38rem, 0.38rem 0.38rem;
		background-repeat: no-repeat;
		opacity: 1;
}

.exp-main-grid,
.exp-detail-grid {
	display: grid;
	grid-template-columns: repeat(2, minmax(0, 1fr));
	gap: 0.55rem;
	align-items: start;
}

.slb-main-grid,
.slb-detail-grid {
	align-items: stretch;
	min-height: 0;
}

.slb-detail-grid {
	flex: 1 1 auto;
}

.exp-section {
		display: flex;
		flex-direction: column;
		gap: 0.35rem;
		padding: 0.35rem;
		background: transparent;
		border: none;
		border-radius: 0;
}

.inspector-section {
		display: flex;
		flex-direction: column;
		flex: 1 1 auto;
		min-height: 0;
		height: 100%;
		overflow: hidden;
}

.inspector-summary {
		flex: 1 1 auto;
}

.inspector-print {
		flex: 1 1 auto;
}

.inspector-key-list {
	list-style: none;
	margin: 0;
	padding: 0;
	display: flex;
	flex-direction: column;
	gap: 0.16rem;
}

.inspector-key-item {
	padding: 0.24rem 0.34rem;
	border-bottom: 1px solid #e0e0e0;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.78rem;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.inspector-value-list {
	display: flex;
	flex-direction: column;
	gap: 0.3rem;
}

.inspector-value-row {
	display: grid;
	grid-template-columns: minmax(8rem, 0.32fr) minmax(0, 1fr);
	gap: 0.5rem;
	align-items: start;
	padding: 0.3rem 0.36rem;
	border-bottom: 1px solid #e0e0e0;
}

.inspector-value-key {
	color: #555555;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.76rem;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.inspector-value-cell {
	min-width: 0;
	white-space: pre-wrap;
	word-break: break-word;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.78rem;
}

.inspector-print-inline {
	margin-top: 0.45rem;
	padding: 0.42rem 0.36rem;
	border-top: 1px solid #d0d0d0;
}

.exp-pane {
	display: flex;
	flex-direction: column;
	gap: 0.45rem;
	padding: 0.38rem 0.42rem;
	min-height: auto;
}

.slb-wrap .exp-pane {
	min-height: 0;
}

.exp-scroll {
	overflow-x: auto;
	overflow-y: scroll;
	padding: 0.28rem 0.3rem;
	background: #ffffff;
	border: 1px solid #b0b0b0;
	border-radius: 0;
}

.exp-scroll-short {
		max-height: 8rem;
}

.exp-scroll-medium {
		max-height: 12rem;
}

.exp-scroll-rows-10 {
		min-height: calc((10 * 1.42em) + 0.7rem);
		max-height: calc((10 * 1.42em) + 0.7rem);
}

.exp-scroll-tall {
		max-height: 14rem;
}

.inspector-scroll {
	flex: 1 1 0;
	min-height: 0;
	max-height: none;
	box-sizing: border-box;
}

.exp-list {
	flex: 1 1 auto;
	min-height: 0;
}

.slb-detail-scroll,
.slb-print-pane {
	flex: 1 1 auto;
	min-height: 0;
	max-height: none;
}

.slb-print-pane {
	min-height: 6rem;
}

.exp-list-entries {
	list-style: none;
	padding: 0;
	margin: 0;
}

.exp-list-entries li {
	list-style: none;
	margin-bottom: 0.22rem;
}

.exp-item {
	display: block;
	padding: 0.26rem 0.4rem;
	border-radius: 0;
	border: 1px solid transparent;
	color: #1c1c1c;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.exp-item:hover {
	background: #dce9f8;
	color: #1c1c1c;
	text-decoration: none;
}

.exp-item.selected {
	background: #1874CD;
	border-color: #1874CD;
	color: #ffffff;
	font-weight: 600;
}

.exp-selection-row {
	display: grid;
	grid-template-columns: max-content minmax(0, 1fr);
	gap: 0.45rem;
	align-items: center;
}

.exp-command-row {
	margin-bottom: 0;
}

.exp-table th,
.exp-table td {
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.76rem;
}

.exp-table tbody tr.exp-table-row {
		background: #ffffff;
		border-bottom: 1px solid #d0d0d0;
}

.exp-table tbody tr.exp-table-row:nth-child(even) {
		background: #f5f5f5;
}

.exp-table tbody tr.exp-table-row:hover {
		background: #dce9f8;
}

.exp-table-key {
		color: #1c1c1c;
		font-weight: 700;
}

.exp-table-value {
		color: #1c1c1c;
}

.insp-header {
	display: flex;
	align-items: baseline;
	gap: 0.5rem;
	padding: 0.3rem 0.42rem;
	border-bottom: 1px solid #d0d0d0;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.78rem;
	flex-shrink: 0;
}

.insp-class {
	font-weight: 700;
	color: #1c1c1c;
}

.insp-display {
	color: #555555;
	overflow: hidden;
	text-overflow: ellipsis;
	white-space: nowrap;
}

.inspector-value-link {
		color: #1c1c1c;
		text-decoration: none;
		border-bottom: 1px solid #1874CD;
}

.inspector-value-link:hover {
		color: #1874CD;
		border-bottom-color: #1874CD;
}

.sig-debugger-layout {
	display: flex;
	flex-direction: column;
	gap: 0.5rem;
	margin-top: 0.5rem;
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
	background: #1874CD;
	border-color: #1874CD;
	color: #ffffff;
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
	padding: 0.28rem 0.44rem;
	border-radius: 0;
	background: transparent;
	border: 1px solid transparent;
	color: #1c1c1c;
}

.sig-browser-item:hover,
.sig-root:hover {
	background: #dce9f8;
	color: #1c1c1c;
	text-decoration: none;
}

.sig-browser-item.selected,
.sig-root.selected {
	background: #1874CD;
	border-color: #1874CD;
	color: #ffffff;
	font-weight: 600;
}

.sig-window-note {
		color: #555555;
		margin: 0;
		padding: 0.34rem 0.4rem;
		border-left: 2px solid #1874CD;
		border-radius: 0;
		background: #eef4fc;
	line-height: 1.45;
}

.sig-command-row {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	gap: 0.32rem;
	margin-bottom: 0.45rem;
}

.sig-error {
	color: var(--sig-danger);
}

.sig-action,
.sig-local-command {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	margin: 0;
		padding: 0.18rem 0.42rem;
		border-radius: 0;
		background: #d4d4d4;
		border: 1px solid #b0b0b0;
	color: #1c1c1c;
	font-size: 0.72rem;
	font-weight: 500;
	box-shadow: none;
}

.sig-action:hover,
.sig-local-command:hover {
	background: #c4c4c4;
	color: #1c1c1c;
	text-decoration: none;
}

.sig-table {
	width: 100%;
	border-collapse: collapse;
	border-spacing: 0;
}

.sig-table th {
	font-size: 0.68rem;
	font-weight: 700;
	letter-spacing: 0.08em;
	text-transform: uppercase;
	color: #555555;
	background: #e8e8e8;
}

.sig-table th,
.sig-table td {
	border-top: 1px solid #d0d0d0;
	padding: 0.34rem 0.42rem;
	text-align: left;
	vertical-align: top;
}

.sig-table tr:hover td {
	background: #dce9f8;
}

.sig-pre {
	white-space: pre-wrap;
	word-break: break-word;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.8rem;
	line-height: 1.42;
	margin: 0;
}

.sig-scroll-pane {
	overflow: auto;
	padding-right: 0.08rem;
	overscroll-behavior: contain;
	scrollbar-gutter: stable both-edges;
	scrollbar-width: thin;
	scrollbar-color: #a0a0a0 #e0e0e0;
}

.sig-window-body::-webkit-scrollbar,
.exp-wrap::-webkit-scrollbar,
.sig-scroll-pane::-webkit-scrollbar {
	width: 0.72rem;
	height: 0.72rem;
}

.sig-window-body::-webkit-scrollbar-track,
.exp-wrap::-webkit-scrollbar-track,
.sig-scroll-pane::-webkit-scrollbar-track {
	background: #e0e0e0;
	border-radius: 0;
}

.sig-window-body::-webkit-scrollbar-thumb,
.exp-wrap::-webkit-scrollbar-thumb,
.sig-scroll-pane::-webkit-scrollbar-thumb {
	background: #a0a0a0;
	border: 2px solid #e0e0e0;
	border-radius: 0;
}

.sig-window-body::-webkit-scrollbar-thumb:hover,
.exp-wrap::-webkit-scrollbar-thumb:hover,
.sig-scroll-pane::-webkit-scrollbar-thumb:hover {
	background: #888888;
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
	background: #ffffff;
	border: 1px solid #b0b0b0;
	border-radius: 0;
	padding: 0.34rem 0.4rem;
	box-shadow: none;
}

.sig-debugger-source-note {
	margin-bottom: 0.55rem;
}

.sig-debugger-source-pane {
	max-height: 24rem;
	min-height: 14rem;
	padding: 0.4rem 0;
	border: 1px solid #b0b0b0;
	border-radius: 0;
	background: #ffffff;
	overflow-y: scroll;
	overflow-x: auto;
}

.sig-debugger-source-lines {
	display: flex;
	flex-direction: column;
}

.sig-debugger-source-line {
	display: grid;
	grid-template-columns: 1.15rem 3rem minmax(0, 1fr);
	gap: 0.75rem;
	align-items: start;
	padding: 0.16rem 0.8rem;
	border-left: 3px solid transparent;
}

.sig-debugger-source-line.current {
	background: #dce9f8;
	border-left-color: #1874CD;
	box-shadow: none;
	scroll-margin-block: 1rem;
}

.sig-debugger-source-line.current .sig-debugger-source-gutter,
.sig-debugger-source-line.current .sig-debugger-source-code {
	color: #1c1c1c;
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

.sig-debugger-step-caret {
	display: inline-block;
	width: 0;
	height: 1.05em;
	margin-right: 0.14rem;
	border-left: 2px solid #1874CD;
	vertical-align: -0.12em;
	box-shadow: none;
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
	border-radius: 0;
	background: #ffffff;
	border: 1px solid #d0d0d0;
	color: var(--sig-text);
}

.sig-debugger-frame:hover {
	background: #dce9f8;
	color: #1c1c1c;
	text-decoration: none;
}

.sig-debugger-frame.selected {
	background: #1874CD;
	border-color: #1874CD;
	color: #ffffff;
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
	min-width: 13rem;
	padding: 0.45rem;
	border-radius: 0;
	background: #f5f5f5;
	border: 1px solid #b0b0b0;
	box-shadow: none;
	backdrop-filter: none;
	z-index: 2500;
}

.sig-context-group + .sig-context-group {
	margin-top: 0.8rem;
	padding-top: 0.8rem;
	border-top: 1px solid #d0d0d0;
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
	padding: 0.3rem 0.4rem;
	border-radius: 0;
	color: #1c1c1c;
}

.sig-context-menu .sig-action:hover,
.sig-context-menu .sig-local-command:hover {
	background: #1874CD;
	color: #ffffff;
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
	overflow-y: scroll;
	overflow-x: hidden;
	scrollbar-gutter: stable both-edges;
}

.sig-transcript-pane {
	display: flex;
	flex-direction: column;
	gap: 0.35rem;
	max-height: 18rem;
}

.sig-transcript-entry {
	padding: 0.34rem 0.44rem;
	border-radius: 0;
	background: #ffffff;
	border: 1px solid #d0d0d0;
	box-shadow: none;
	font-size: 0.8rem;
	line-height: 1.38;
}

.sig-empty-state {
	color: var(--sig-muted);
	margin: 0;
	padding: 0.4rem 0;
}

.sig-workspace-form {
	display: flex;
	flex-direction: column;
	gap: 0.7rem;
}

.sig-workspace-editor {
	width: 100%;
	min-height: 15rem;
	padding: 0.9rem;
	border-radius: 0;
	border: 1px solid #b0b0b0;
	background: #ffffff;
	box-sizing: border-box;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.86rem;
	line-height: 1.5;
	color: #000000;
	box-shadow: none;
}

.sig-workspace-editor:focus {
	outline: none;
	border-color: #1874CD;
	box-shadow: none;
}

.sig-workspace-toolbar {
	display: flex;
	flex-wrap: wrap;
	gap: 0.45rem;
}

.sig-workspace-button {
	border: 1px solid #b0b0b0;
	padding: 0.3rem 0.62rem;
	border-radius: 0;
	background: #d4d4d4;
	color: #1c1c1c;
	font-size: 0.8rem;
	cursor: pointer;
	font-weight: 600;
}

.sig-workspace-button:hover {
	background: #c4c4c4;
}

.sig-workspace-button.sig-workspace-button-secondary {
	background: #e8e8e8;
	border-color: #b0b0b0;
	color: #1c1c1c;
}

.sig-workspace-output {
	background: #f5f5f5;
	border: 1px solid #b0b0b0;
	border-radius: 0;
	padding: 0.8rem;
	box-shadow: none;
}

.sig-workspace-output h3 {
	margin-top: 0;
}

.sig-workspace-output-pane {
	max-height: 14rem;
}

.sig-sidebar > h3,
.sig-main > h3,
.sig-browser-column > h3,
.sig-source-window > h3,
.sig-session-panel > h3,
.sig-workspace-output > h3 {
	margin: 0 0 0.75rem;
	padding-bottom: 0.45rem;
	border-bottom: 1px solid #b0b0b0;
	font-size: 0.68rem;
	font-weight: 700;
	letter-spacing: 0.08em;
	text-transform: uppercase;
	color: var(--sig-subtle);
}

.sig-detail-pane dl,
.sig-source-window dl,
.sig-session-panel dl {
	display: grid;
	grid-template-columns: max-content minmax(0, 1fr);
	gap: 0.3rem 0.8rem;
	margin: 0;
}

.sig-detail-pane dt,
.sig-source-window dt,
.sig-session-panel dt {
	font-size: 0.72rem;
	font-weight: 700;
	letter-spacing: 0.04em;
	color: var(--sig-muted);
}

.sig-detail-pane dd,
.sig-source-window dd,
.sig-session-panel dd {
	margin: 0;
	min-width: 0;
	color: #1c1c1c;
	word-break: break-word;
}

.sig-window-body input[type="text"],
.sig-window-body textarea,
.sig-window-body select {
	border: 1px solid #b0b0b0;
	border-radius: 0;
	background: #ffffff;
	color: #1c1c1c;
	box-shadow: none;
}

.sig-window-body input[type="text"]:focus,
.sig-window-body textarea:focus,
.sig-window-body select:focus {
	outline: none;
	border-color: #1874CD;
	box-shadow: none;
}

.sig-window-body input[type="text"]::placeholder,
.sig-window-body textarea::placeholder {
	color: #888888;
}

button.btn,
.btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.26rem 0.68rem;
	border-radius: 0;
	border: 1px solid #b0b0b0;
	background: #d4d4d4;
	color: #1c1c1c;
	font-size: 11px;
	font-weight: 600;
	cursor: pointer;
	text-decoration: none;
	box-shadow: none;
}

button.btn:hover,
.btn:hover {
	background: #c4c4c4;
	text-decoration: none;
}

button.btn-ghost,
.btn-ghost {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.26rem 0.62rem;
	border-radius: 0;
	border: 1px solid #b0b0b0;
	background: #e8e8e8;
	color: #1c1c1c;
	font-size: 11px;
	font-weight: 500;
	cursor: pointer;
	text-decoration: none;
	box-shadow: none;
}

button.btn-ghost:hover,
.btn-ghost:hover {
	background: #d4d4d4;
	text-decoration: none;
}

button.btn-tx,
.btn-tx {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.26rem 0.68rem;
	border-radius: 0;
	border: 1px solid #b0b0b0;
	background: #e8e8e8;
	color: #1c1c1c;
	font-size: 11px;
	font-weight: 500;
	cursor: pointer;
	text-decoration: none;
}

button.btn-tx:hover,
.btn-tx:hover {
	background: #d4d4d4;
	text-decoration: none;
}

.btn-tx-active {
	background: #1874CD;
	border-color: #1874CD;
	color: #ffffff;
}

.btn-dbg {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.34rem 0.72rem;
	border-radius: 0;
	border: 1px solid #b0b0b0;
	background: #d4d4d4;
	color: #1c1c1c;
	font-size: 12px;
	font-weight: 600;
	cursor: pointer;
	text-decoration: none;
	flex: 1;
	box-shadow: none;
}

.btn-dbg:hover {
	background: #c4c4c4;
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
	position: relative;
	background: #ffffff;
	overflow-y: scroll;
	overflow-x: hidden;
	scrollbar-gutter: stable both-edges;
}

.sig-workspace-form {
	display: flex;
	flex-direction: column;
	gap: 0;
}







.ws-input-row {
	display: flex;
	flex-direction: column;
	flex-shrink: 0;
	background: #ffffff;
}

.ws-code-area {
	width: 100%;
	min-height: 6.5rem;
	padding: 0.52rem;
	border: none;
	background: #ffffff;
	color: #000000;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.82rem;
	line-height: 1.4;
	resize: vertical;
	outline: none;
}

.ws-controls {
	display: flex;
	align-items: center;
	gap: 0.32rem;
	padding: 0.38rem 0.52rem;
	flex-wrap: wrap;
}


.ws-context-menu {
	display: none;
	position: fixed;
	z-index: 1200;
	min-width: 10rem;
	padding: 0.28rem;
	border: 1px solid #4d5c76;
	background: #1e232c;
	box-shadow: 0 0.35rem 1.2rem rgba(0, 0, 0, 0.35);
}

.ws-context-menu .ws-context-action {
	display: block;
	width: 100%;
	margin: 0;
	border: none;
	background: transparent;
	color: #f3f6fb;
	text-align: left;
	padding: 0.38rem 0.52rem;
}

.ws-context-menu .ws-context-action:hover {
	background: #2a73b9;
	color: #ffffff;
}

.txbar {
	display: flex;
	align-items: center;
	gap: 0.45rem;
	padding: 0.45rem 0.75rem;
	border-top: 1px solid #d0d0d0;
	background: #f5f5f5;
	flex-wrap: wrap;
}

.txbar span {
	font-size: 0.72rem;
	color: #777777;
}

.tab-strip {
	display: flex;
	border-bottom: 1px solid #d0d0d0;
	background: #e8e8e8;
	flex-shrink: 0;
	overflow-x: auto;
}

.tab-item {
	padding: 5px 12px;
	font-size: 11px;
	color: #1c1c1c;
	cursor: pointer;
	border-bottom: 2px solid transparent;
	margin-bottom: -1px;
	white-space: nowrap;
	user-select: none;
}

.tab-item:hover {
	color: #1c1c1c;
	text-decoration: none;
}

.tab-item.active {
	color: #1c1c1c;
	border-bottom-color: #1874CD;
	background: #dce9f8;
}

.sig-debugger-shell {
	display: flex;
	flex-direction: column;
	height: 100%;
	min-height: 0;
	background: #ffffff;
	overflow-y: scroll;
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
	overflow-y: scroll;
	overflow-x: hidden;
	scrollbar-gutter: stable both-edges;
}

.sig-debugger-tab-panel.active {
	display: flex;
}

.dbg-summary {
	display: flex;
	flex-direction: column;
	gap: 2px;
	padding: 6px 8px;
	border-bottom: 1px solid #d0d0d0;
	background: #f5f5f5;
	flex-shrink: 0;
}

.dbg-summary-source,
.dbg-summary-error {
	font-family: monospace;
	font-size: 11px;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.dbg-summary-source {
	color: #1c1c1c;
}

.dbg-summary-error {
	color: #aa0000;
}

.sig-debugger-frame-list {
	flex: 1;
	min-height: 80px;
	max-height: 196px;
	height: 196px;
	padding: 0;
	border: none;
	border-bottom: 1px solid #d0d0d0;
	border-radius: 0;
	background: #ffffff;
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
	gap: 6px;
	padding: 3px 8px;
	border: 0;
	border-left: 3px solid transparent;
	border-radius: 0;
	background: transparent;
	color: inherit;
	font-family: monospace;
	font-size: 11px;
	text-align: left;
	cursor: pointer;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.dbg-frame-item:hover {
	background: #dce9f8;
	text-decoration: none;
}

.dbg-frame-item.active,
.sig-debugger-frame.selected {
	background: #1874CD;
	border-left-color: #1874CD;
	color: #ffffff;
}

.dbg-frame-icon {
	width: 12px;
	height: 12px;
	border-radius: 0;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 7px;
	flex-shrink: 0;
	background: #1874CD;
	color: #ffffff;
}

.dbg-frame-icon.ruby {
	background: #aa0000;
}

.sig-debugger-utility-bar {
	display: flex;
	align-items: center;
	flex-wrap: wrap;
	gap: 0.3rem;
	padding: 0.45rem 0.6rem;
	border-bottom: 1px solid #d0d0d0;
	background: #f5f5f5;
}

.sig-debugger-utility-bar .sig-action {
	margin: 0;
}

.sig-debugger-command {
	margin: 0;
	padding: 0.2rem 0.55rem;
	font-size: 10px;
}

.sig-debugger-status-row {
	padding: 0.35rem 0.65rem;
	border-top: 1px solid #d0d0d0;
	background: #f5f5f5;
}

.dbg-action-bar {
	display: flex;
	align-items: stretch;
	gap: 0;
	padding: 0;
	border-bottom: 1px solid #d0d0d0;
	background: #e8e8e8;
	flex-wrap: wrap;
}

.dbg-source-pane {
	display: flex;
	flex-direction: column;
	flex: 1;
	min-height: 0;
	overflow: hidden;
}

.dbg-source-meta {
	display: flex;
	align-items: center;
	gap: 8px;
	padding: 4px 8px;
	border-bottom: 1px solid #d0d0d0;
	background: #f5f5f5;
	color: #1c1c1c;
	font-size: 10px;
	font-family: monospace;
}

.dbg-source-code {
	flex: 1;
	min-height: 0;
	background: #ffffff;
	color: #000000;
	padding: 6px 8px;
	overflow: auto;
	white-space: pre;
	line-height: 1.45;
}

.dbg-source-line {
	display: flex;
	align-items: flex-start;
	gap: 10px;
	padding: 0 4px;
	border-left: 3px solid transparent;
}

.dbg-source-line.active {
	background: #dce9f8;
	border-left-color: #1874CD;
}

.dbg-source-marker {
	color: #1874CD;
	min-width: 28px;
	text-align: center;
	user-select: none;
	flex-shrink: 0;
	opacity: 0.3;
}

.dbg-step-cursor,
.dbg-step-cursor-spacer {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	min-width: 22px;
	height: 16px;
	border-radius: 0;
	font-size: 10px;
	line-height: 1;
	font-weight: 700;
}

.dbg-step-cursor {
	background: #1874CD;
	color: #ffffff;
	box-shadow: none;
}

.dbg-step-cursor-spacer {
	background: transparent;
	color: transparent;
	user-select: none;
}

.dbg-source-line.active .dbg-source-marker {
	opacity: 1;
}

.dbg-source-lno {
	color: #777777;
	min-width: 26px;
	text-align: right;
	user-select: none;
	flex-shrink: 0;
	font-family: monospace;
}

.dbg-source-text {
	min-width: 0;
	color: inherit;
	white-space: pre;
}

.dbg-self-bar,
.dbg-var-row {
	display: flex;
	align-items: center;
	gap: 0.45rem;
	padding: 0.3rem 0.65rem;
	border-top: 1px solid #d0d0d0;
	background: #f5f5f5;
	flex-shrink: 0;
}

.dbg-self-label {
	color: #777777;
	font-size: 10px;
}

.dbg-self-val {
	font-family: monospace;
	color: #1c1c1c;
	flex: 1;
	overflow: hidden;
	text-overflow: ellipsis;
	display: flex;
	align-items: center;
	gap: 6px;
	min-width: 0;
}

.dbg-var-val {
	font-family: monospace;
	color: #1a5c1a;
	display: flex;
	align-items: center;
	gap: 6px;
	min-width: 0;
	flex: 1;
}

.dbg-inline-cursor {
	display: inline-block;
	min-width: 0.5ch;
	margin: 0 1px 0 0;
	background: transparent;
	border-left: none;
	border-radius: 0;
	color: #1874CD;
	font-weight: 700;
	box-shadow: none;
	text-shadow: none;
	line-height: 1;
	user-select: none;
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
	color: #1c1c1c;
	min-width: 7rem;
}

.tls-val {
	color: #1a5c1a;
	min-width: 0;
}

.cb-wrap {
	display: flex;
	flex-direction: column;
	height: 100%;
	min-height: 0;
	background: #ffffff;
	overflow-y: scroll;
	overflow-x: hidden;
	scrollbar-gutter: stable both-edges;
}

.cb-toolbar {
	display: flex;
	align-items: center;
	gap: 0.28rem;
	flex-wrap: wrap;
	padding: 0.28rem 0.42rem;
	border-bottom: 1px solid #d0d0d0;
	background: #e8e8e8;
	flex-shrink: 0;
}

.cb-static-btn {
	pointer-events: none;
}

.cb-meta {
	display: inline-flex;
	align-items: center;
	gap: 0.24rem;
	color: #1c1c1c;
	font-size: 0.72rem;
	white-space: nowrap;
}

.cb-toolbar .cb-meta:first-of-type {
	margin-left: auto;
}

.cb-lists {
	display: grid;
	grid-template-columns: minmax(9rem, 12rem) 0.45rem minmax(12rem, 1fr) 0.45rem minmax(10rem, 12rem) 0.45rem minmax(12rem, 1fr);
	min-height: 11.5rem;
	height: 11.5rem;
	border-bottom: 1px solid #d0d0d0;
	flex-shrink: 0;
}

.cb-pane {
	display: flex;
	flex-direction: column;
	min-width: 0;
	min-height: 0;
	overflow: hidden;
	border-right: 1px solid #d0d0d0;
}

.cb-pane:last-child {
	border-right: none;
}

.cb-splitter {
	position: relative;
	background: #e8e8e8;
	border-right: 1px solid #d0d0d0;
	border-left: 1px solid #d0d0d0;
}

.cb-splitter::after {
	content: "";
	position: absolute;
	left: 50%;
	top: 50%;
	transform: translate(-50%, -50%);
	width: 2px;
	height: 1.75rem;
	border-radius: 0;
	background: #a0a0a0;
}

.cb-pane-label {
	padding: 0.24rem 0.38rem;
	background: #e8e8e8;
	border-bottom: 1px solid #d0d0d0;
	font-size: 0.62rem;
	text-transform: uppercase;
	letter-spacing: 0.06em;
	color: #555555;
}

.cb-filter-wrap {
	padding: 0.24rem 0.3rem;
	border-bottom: 1px solid #d0d0d0;
	background: #f5f5f5;
}

.cb-filter {
	width: 100%;
	box-sizing: border-box;
	border: 1px solid #b0b0b0;
	border-radius: 0;
	background: #ffffff;
	color: #1c1c1c;
	font-size: 0.68rem;
	padding: 0.26rem 0.36rem;
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
	padding: 0.24rem 0.38rem;
	font-size: 0.72rem;
	color: #1c1c1c;
	border-left: 3px solid transparent;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.cb-item:hover {
	background: #dce9f8;
	text-decoration: none;
}

.cb-item.selected {
	border-left-color: #1874CD;
	background: #1874CD;
	color: #ffffff;
}

.cb-source-wrap {
	display: flex;
	flex-direction: column;
	flex: 1;
	min-height: 0;
}

.cb-source-form {
	display: flex;
	flex-direction: column;
	flex: 1;
	min-height: 0;
}

.cb-source-hdr {
	display: flex;
	align-items: center;
	justify-content: space-between;
	padding: 0.26rem 0.42rem;
	background: #e8e8e8;
	border-bottom: 1px solid #d0d0d0;
	flex-shrink: 0;
}

.cb-source-title-group,
.cb-source-actions {
	display: flex;
	align-items: center;
	gap: 0.28rem;
	min-width: 0;
}

.cb-source-actions {
	margin-left: auto;
	flex-shrink: 0;
}

.cb-source-note {
	font-size: 0.68rem;
	color: #555555;
}

.cb-source-btn {
	padding: 0.18rem 0.46rem;
	font-size: 0.68rem;
}

.cb-source {
	flex: 1;
	min-height: 0;
	padding: 0.38rem 0.46rem;
	background: #ffffff;
	display: flex;
}

.cb-source-editor {
	width: 100%;
	min-height: 100%;
	height: 100%;
	padding: 0;
	border: none;
	background: transparent;
	color: #000000;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.78rem;
	line-height: 1.42;
	resize: none;
	outline: none;
}

.cb-source-editor::placeholder {
	color: #888888;
}

.cb-status {
	padding: 0.38rem 0.65rem;
	border-top: 1px solid #d0d0d0;
	background: #e8e8e8;
	color: #555555;
	font-size: 0.72rem;
	flex-shrink: 0;
}

@media (max-width: 760px) {
	.sig-floating-window:not(.sig-window-manual-position) {
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
	.exp-split,
	.exp-main-grid,
	.exp-detail-grid,
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
		anHtmlRoot bodyAttributes at: 'data-sig-auto-show-window' put: windowId.
		anHtmlRoot addScript: 'window.SIGAutoShowWindow = ', windowId printString, ';' ]
]

{ #category : 'actions' }
SigExplorerApplication >> workspaceDebugIt [
	^ self workspaceDebugItForWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> workspaceDebugItForWindow: aWindow [
	| hadFailure sessionId snapshot |
	self
		workspaceResultText: (self gateway workspaceDebugIt: (self workspaceSourceTextForWindow: aWindow))
		forWindow: aWindow.
	hadFailure := self workspaceHasCapturedFailure.
	hadFailure
		ifTrue: [
			self showDebuggerForLastError.
			self setStatusMessage: 'Workspace debug opened the debugger' ]
		ifFalse: [
			sessionId := self gateway lastDebugSessionId.
			sessionId
				ifNil: [ self refreshBaseDebuggerStateFromGateway ]
				ifNotNil: [
					snapshot := self gateway debuggerSnapshotForSessionId: sessionId.
					self applyDebuggerSnapshot: snapshot toState: self debuggerState.
					self selectPreferredDebuggerFrameInState: self debuggerState ].
			self requestWindowShow: 'sig-window-debugger'.
			self setStatusMessage: 'Workspace debug opened the debugger' ].
	self
		addTranscriptLine: 'Workspace debug output: ',
			(self transcriptPreviewOf: (self workspaceResultTextForWindow: aWindow))
]

{ #category : 'actions' }
SigExplorerApplication >> workspaceDoIt [
	^ self workspaceDoItForWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> workspaceDoItForWindow: aWindow [
	| hadFailure |
	self
		workspaceResultText: (self gateway workspaceDoIt: (self workspaceSourceTextForWindow: aWindow))
		forWindow: aWindow.
	hadFailure := self workspaceHasCapturedFailure.
	hadFailure
		ifTrue: [
			self requestExceptionDebuggerForLastError.
			self setStatusMessage: 'Workspace do it failed' ]
		ifFalse: [ self setStatusMessage: 'Workspace do it completed' ].
	self
		addTranscriptLine: 'Workspace result: ',
			(self transcriptPreviewOf: (self workspaceResultTextForWindow: aWindow))
]

{ #category : 'actions' }
SigExplorerApplication >> workspacePrintIt [
	^ self workspacePrintItForWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> workspacePrintItForWindow: aWindow [
	| hadFailure result |
	result := self gateway workspaceDoIt: (self workspaceSourceTextForWindow: aWindow).
	self workspaceResultText: result forWindow: aWindow.
	hadFailure := self workspaceHasCapturedFailure.
	hadFailure
		ifTrue: [
			self requestExceptionDebuggerForLastError.
			self setStatusMessage: 'Workspace print it failed' ]
		ifFalse: [
			self
				workspaceSourceText: (self workspaceSourceTextForWindow: aWindow), ' "', (result copyReplaceAll: '"' with: '""'), '"'
				forWindow: aWindow.
			self workspaceResultText: '' forWindow: aWindow.
			self setStatusMessage: 'Workspace print it completed' ].
	self
		addTranscriptLine: 'Workspace print it: ',
			(self transcriptPreviewOf: result)
]

{ #category : 'actions' }
SigExplorerApplication >> workspaceInspectIt [
	^ self workspaceInspectItForWindow: nil
]

{ #category : 'actions' }
SigExplorerApplication >> workspaceInspectItForWindow: aWindow [
	| hadFailure snapshot window |
	snapshot := self gateway workspaceInspectionSnapshotFor: (self workspaceSourceTextForWindow: aWindow).
	self
		workspaceResultText: (snapshot
			ifNil: [ self gateway workspaceErrorText ]
			ifNotNil: [ snapshot at: #printString ifAbsent: [ '' ] ])
		forWindow: aWindow.
	hadFailure := self workspaceHasCapturedFailure.
	hadFailure
		ifTrue: [
			self requestExceptionDebuggerForLastError.
			self setStatusMessage: 'Workspace inspect failed' ]
		ifFalse: [ self setStatusMessage: 'Workspace inspect completed' ].
	hadFailure ifFalse: [
		window := self
			newInspectorWindowForSnapshot: snapshot
			label: 'Workspace result'
			title: 'Workspace result'.
		self requestWindowShow: window windowId ].
	self
		addTranscriptLine: 'Workspace inspect output: ',
			(self transcriptPreviewOf: (self workspaceResultTextForWindow: aWindow))
]
