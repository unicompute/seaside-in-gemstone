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
		'nextInspectorWindowNumber'
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
SigExplorerApplication >> browserEditableSourceText [
	browserSourceDraftText ifNotNil: [ ^ browserSourceDraftText ].
	(selectedBrowserClassName isNil or: [ selectedBrowserSelector isNil ]) ifTrue: [ ^ '' ].
	^ self browserSourceText
]

{ #category : 'querying' }
SigExplorerApplication >> browserSourceHeadingText [
	selectedBrowserClassName ifNil: [ ^ 'Select a class to start browsing.' ].
	selectedBrowserSelector isNil ifTrue: [ ^ selectedBrowserClassName, ' is selected.' ].
	^ selectedBrowserClassName, ' >> ', selectedBrowserSelector
]

{ #category : 'actions' }
SigExplorerApplication >> browserCompileSource [
	| categoryName outcome |
	selectedBrowserClassName ifNil: [
		self setStatusMessage: 'Select a class before compiling'.
		^ self ].
	categoryName := selectedBrowserProtocolName ifNil: [ 'as yet unclassified' ].
	outcome := self gateway
		compileMethodSource: self browserEditableSourceText
		forClassNamed: selectedBrowserClassName
		protocolNamed: categoryName
		inDictionaryNamed: selectedBrowserDictionaryName.
	(outcome at: #success ifAbsent: [ false ])
		ifTrue: [
			selectedBrowserProtocolName ifNil: [ selectedBrowserProtocolName := categoryName ].
			self setStatusMessage: (outcome at: #message ifAbsent: [ 'Method compiled' ]) ]
		ifFalse: [
			self setStatusMessage: (outcome at: #message ifAbsent: [ 'Method compile failed' ]) ]
]

{ #category : 'actions' }
SigExplorerApplication >> browserResetSourceDraft [
	browserSourceDraftText := nil.
	self setStatusMessage: 'Browser source reset'
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
	| cursorLocation currentStep nextLocation |
	(self debuggerFrameIsExecutedCode: aFrame) ifFalse: [
		^ self debuggerFrameSourceCursorLocationFor: aFrame stepPoint: (aFrame at: #quickStepPoint ifAbsent: [ nil ]) ].
	currentStep := aFrame at: #quickStepPoint ifAbsent: [ nil ].
	cursorLocation := self debuggerFrameSourceCursorLocationFor: aFrame stepPoint: currentStep.
	cursorLocation ifNil: [ ^ nil ].
	currentStep := [ currentStep asInteger ] on: Error do: [ nil ].
	(currentStep isNil or: [ currentStep <= 1 ]) ifTrue: [ ^ cursorLocation ].
	(self debuggerFrameStepPointStartsNewStatement: currentStep in: aFrame) ifFalse: [
		nextLocation := self debuggerFrameNextStatementCursorLocationFor: aFrame afterStepPoint: currentStep.
		nextLocation ifNotNil: [ ^ nextLocation ] ].
	^ cursorLocation
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
SigExplorerApplication >> debuggerFrameNextStatementCursorLocationFor: aFrame afterStepPoint: aStepPoint [
	| nextStep sourceOffsets |
	aFrame ifNil: [ ^ nil ].
	sourceOffsets := aFrame at: #sourceOffsets ifAbsent: [ nil ].
	sourceOffsets ifNil: [ ^ nil ].
	nextStep := aStepPoint + 1.
	[ nextStep <= sourceOffsets size ] whileTrue: [
		(self debuggerFrameStepPointStartsNewStatement: nextStep in: aFrame)
			ifTrue: [ ^ self debuggerFrameSourceCursorLocationFor: aFrame stepPoint: nextStep ].
		nextStep := nextStep + 1 ].
	^ nil
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
SigExplorerApplication >> newInspectorWindowForText: aString label: aLabel [
	| window windowId windowNumber |
	windowNumber := nextInspectorWindowNumber := nextInspectorWindowNumber + 1.
	windowId := 'sig-window-object-', windowNumber printString.
	window := Dictionary new
		at: #id put: windowId;
		at: #title put: (self inspectorWindowTitleForWindowNumber: windowNumber);
		at: #taskbarLabel put: (self inspectorTaskbarLabelForWindowNumber: windowNumber);
		at: #subtitle put: '';
		at: #position put: (self inspectorWindowPositionForIndex: windowNumber);
		at: #label put: aLabel;
		at: #text put: (aString ifNil: [ 'Nothing selected for inspection.' ]);
		yourself.
	inspectorWindows addLast: window.
	^ window
]

{ #category : 'private' }
SigExplorerApplication >> newInspectorWindowForObject: anObject label: aLabel title: aTitle [
	| inspection window windowId windowNumber |
	inspection := self gateway inspectionSnapshotFor: anObject.
	windowNumber := nextInspectorWindowNumber := nextInspectorWindowNumber + 1.
	windowId := 'sig-window-object-', windowNumber printString.
	window := Dictionary new
		at: #id put: windowId;
		at: #title put: (aTitle ifNil: [ self inspectorWindowTitleForWindowNumber: windowNumber ]);
		at: #taskbarLabel put: (aTitle ifNil: [ self inspectorTaskbarLabelForWindowNumber: windowNumber ]);
		at: #subtitle put: '';
		at: #position put: (self inspectorWindowPositionForIndex: windowNumber);
		at: #label put: aLabel;
		at: #rowsTitle put: (inspection at: #rowsTitle ifAbsent: [ 'Index / Values' ]);
		at: #rows put: (inspection at: #rows ifAbsent: [ #() ]);
		at: #text put: (inspection at: #printString ifAbsent: [ self gateway longDisplayStringFor: anObject ]);
		yourself.
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
	self requestWindowShow: (window at: #id).
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
	self requestWindowShow: (window at: #id).
	self setStatusMessage: 'Inspecting ', association key asString
]

{ #category : 'actions' }
SigExplorerApplication >> openSelectedSymbolListEntryInNewWindow [
	| association window |
	association := self selectedSymbolListAssociation.
	association ifNil: [
		self setStatusMessage: 'Select a symbol binding before opening it'.
		^ self ].
	window := self
		newInspectorWindowForObject: association value
		label: 'Symbols / ', association key asString
		title: association key asString.
	self requestWindowShow: (window at: #id).
	self setStatusMessage: 'Opened ', association key asString, ' in a new window'
]

{ #category : 'actions' }
SigExplorerApplication >> inspectSelectedSymbolListEntry [
	| association window |
	association := self selectedSymbolListAssociation.
	association ifNil: [
		self setStatusMessage: 'Select a symbol binding before inspecting it'.
		^ self ].
	window := self
		newInspectorWindowForObject: association value
		label: 'Symbols / ', association key asString
		title: association key asString.
	self requestWindowShow: (window at: #id).
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
	self requestWindowShow: (window at: #id).
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
	inspectorWindows := OrderedCollection new.
	nextInspectorWindowNumber := 0.
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
				html form
					class: 'cb-source-form';
					attributeAt: 'data-sig-remote' put: 'true';
					with: [
						html div class: 'cb-source-hdr'; with: [
							html div class: 'cb-source-title-group'; with: [
								html span: 'Source'.
								html span class: 'cb-source-note'; with: self browserSourceHeadingText ].
							html div class: 'cb-source-actions'; with: [
								html submitButton
									class: 'btn-ghost cb-source-btn';
									callback: [ self browserResetSourceDraft ];
									with: 'Revert'.
								html submitButton
									class: 'btn cb-source-btn';
									callback: [ self browserCompileSource ];
									with: 'Compile' ] ].
						html div class: 'cb-source sig-scroll-pane'; with: [
							html textArea
								class: 'cb-source-editor';
								attributeAt: 'spellcheck' put: 'false';
								attributeAt: 'wrap' put: 'off';
								attributeAt: 'placeholder' put: 'Smalltalk method source';
								rows: 18;
								callback: [ :value | browserSourceDraftText := value ];
								value: self browserEditableSourceText ] ] ] ]
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
			self renderInspectorWindowsOn: desktop.
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
					inspectorWindows do: [ :each |
						self
							renderLocalWindowCommandOn: html
							label: ('Open ', (each at: #title))
							target: (each at: #id) ].
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
						aSubtitle isEmpty ifFalse: [
							headings span class: 'sig-window-subtitle'; with: aSubtitle ] ] ].
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
				inspectorWindows do: [ :each |
					self
						renderMenuWindowCommandOn: menu
						label: (each at: #title)
						target: (each at: #id) ].
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
SigExplorerApplication >> renderInspectorContentsOn: html label: aLabel rowsTitle: rowsTitle rows: rows text: aString [
	(rows notNil and: [ rows isEmpty not ])
		ifTrue: [
			html div class: 'exp-wrap inspector-wrap'; with: [
				html div class: 'exp-section inspector-section inspector-summary'; with: [
					html div class: 'exp-pane-title'; with: rowsTitle.
					html div class: 'sig-scroll-pane exp-scroll inspector-scroll inspector-scroll-short'; with: [
						html table class: 'sig-table exp-table'; with: [
							html tableHead: [
								html tableRow: [
									html tableHeading: 'Key'.
									html tableHeading: 'Value' ] ].
							html tableBody: [
								rows do: [ :each |
									html tableRow: [
										html tableData: (each at: #key ifAbsent: [ '' ]).
										html tableData: [
											(each includesKey: #object)
												ifTrue: [
													html anchor
														class: 'inspector-value-link';
														attributeAt: 'data-sig-remote' put: 'true';
														callback: [ self inspectStructuredInspectorRow: each ];
														with: (each at: #value ifAbsent: [ '' ]) ]
												ifFalse: [ html text: (each at: #value ifAbsent: [ '' ]) ] ] ] ] ] ] ] ].
				html div class: 'exp-section inspector-section inspector-print'; with: [
					html div class: 'exp-pane-title'; with: 'PrintString'.
					html div class: 'sig-scroll-pane exp-scroll inspector-scroll inspector-scroll-tall'; with: [
						html preformatted class: 'sig-pre'; with: aString ] ] ] ]
		ifFalse: [
			html div class: 'sig-source-window'; with: [
				html heading level3; with: aLabel.
				html div class: 'sig-scroll-pane sig-inspector-pane'; with: [
					html preformatted class: 'sig-pre'; with: aString ] ] ]
]

{ #category : 'rendering' }
SigExplorerApplication >> renderInspectorWindowOn: html window: aWindow [
	self
		renderInspectorContentsOn: html
		label: (aWindow at: #label ifAbsent: [ 'Object' ])
		rowsTitle: (aWindow at: #rowsTitle ifAbsent: [ 'Index / Values' ])
		rows: (aWindow at: #rows ifAbsent: [ #() ])
		text: (aWindow at: #text ifAbsent: [ 'Nothing selected for inspection.' ])
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
			html div class: 'sig-taskbar-brand'; with: 'GemStone Desktop'.
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
	inspectorWindows do: [ :each |
		self
			renderMenuWindowCommandOn: html
			label: (each at: #title)
			target: (each at: #id) ].
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
SigExplorerApplication >> inspectorWindows [
	^ inspectorWindows
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
	browserSourceDraftText := nil.
	self setStatusMessage: 'Browsing class ', aString
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserDictionaryNamed: aSymbol [
	selectedBrowserDictionaryName := aSymbol.
	selectedBrowserClassName := nil.
	selectedBrowserProtocolName := nil.
	selectedBrowserSelector := nil.
	browserSourceDraftText := nil.
	self setStatusMessage: 'Browsing dictionary ', aSymbol asString
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserProtocolNamed: aString [
	selectedBrowserProtocolName := aString.
	selectedBrowserSelector := nil.
	browserSourceDraftText := nil.
	self setStatusMessage: 'Browsing protocol ', aString
]

{ #category : 'actions' }
SigExplorerApplication >> selectBrowserSelectorNamed: aString [
	selectedBrowserSelector := aString.
	browserSourceDraftText := nil.
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
	html div class: 'exp-wrap'; with: [
		html div class: 'exp-toolbar'; with: [
			html div class: 'exp-toolbar-group'; with: [
				html span class: 'exp-toolbar-label'; with: 'Dictionary'.
				html span class: 'exp-toolbar-value'; with: selectedSymbolListDictionaryName asString ].
			html div class: 'exp-toolbar-group'; with: [
				html span class: 'exp-toolbar-label'; with: 'Selection'.
				html span
					class: 'exp-toolbar-value';
					with: (selectedSymbolListEntryKey ifNil: [ 'None' ] ifNotNil: [ selectedSymbolListEntryKey ]) ] ].
		html div class: 'exp-main-grid'; with: [
			html div class: 'exp-pane'; with: [
				html div class: 'exp-pane-title'; with: 'Dictionaries'.
				html div class: 'sig-scroll-pane exp-list'; with: [
					html unorderedList class: 'exp-list-entries'; with: [
						self symbolListDictionaryNames do: [ :each |
							html listItem: [
								html anchor
									class: (each asString = selectedSymbolListDictionaryName asString
										ifTrue: [ 'exp-item selected' ]
										ifFalse: [ 'exp-item' ]);
									attributeAt: 'data-sig-remote' put: 'true';
									callback: [ self selectSymbolListDictionaryNamed: each ];
									with: each asString ] ] ] ] ].
			html div class: 'exp-pane'; with: [
				html div class: 'exp-pane-title'; with: 'Bindings'.
				html div class: 'sig-scroll-pane exp-list'; with: [
					self symbolListEntryAssociations isEmpty
						ifTrue: [ html paragraph class: 'sig-window-note'; with: 'No bindings.' ]
						ifFalse: [
							html unorderedList class: 'exp-list-entries'; with: [
								self symbolListEntryAssociations do: [ :each |
									html listItem: [
										html anchor
											class: (each key asString = selectedSymbolListEntryKey
												ifTrue: [ 'exp-item selected' ]
												ifFalse: [ 'exp-item' ]);
											attributeAt: 'data-sig-remote' put: 'true';
											callback: [ self selectSymbolListEntryKey: each key asString ];
											with: each key asString ] ] ] ] ] ] ].
		html div class: 'exp-selection-row'; with: [
			html span class: 'exp-selection-label'; with: 'Selection'.
			html span
				class: 'exp-selection-value';
				with: (association
					ifNil: [ 'No symbol binding selected.' ]
					ifNotNil: [ association key asString ]) ].
		html div class: 'sig-command-row exp-command-row'; with: [
			self renderActionLinkOn: html label: 'Open' callback: [ self openSelectedSymbolListEntryInNewWindow ].
			self renderActionLinkOn: html label: 'Inspect' callback: [ self inspectSelectedSymbolListEntry ] ].
		html div class: 'exp-detail-grid'; with: [
			html div class: 'exp-pane'; with: [
				html div class: 'exp-pane-title'; with: 'Keys / Values'.
				html div class: 'sig-scroll-pane'; with: [
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
				html div class: 'sig-scroll-pane exp-print-pane'; with: [
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
		--sig-bg: #111417;
		--sig-surface-0: #171b20;
		--sig-surface-1: #1b2026;
		--sig-surface-2: #212730;
		--sig-surface-3: #0f1318;
		--sig-surface-4: #0b0e12;
		--sig-window-bg: #171b20;
		--sig-window-border: #39424d;
		--sig-border: #39424d;
		--sig-border-soft: #323a44;
		--sig-text: #dbe4ee;
		--sig-muted: #93a0ae;
		--sig-subtle: #6f7a86;
		--sig-accent: #7ec8ff;
		--sig-accent-strong: #7ec8ff;
		--sig-success: #9fd49a;
		--sig-warning: #d8c07a;
		--sig-danger: #de8f9a;
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
		background: #0d1014;
	background-attachment: fixed;
	letter-spacing: 0.01em;
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
	gap: 0.7rem;
	align-items: center;
		padding: 0.24rem 0.45rem;
		background: #12161b;
		border-bottom: 1px solid #323a44;
	backdrop-filter: none;
	box-shadow: none;
	color: var(--sig-text);
}

.sig-menu-brand {
	font-size: 0.72rem;
	font-weight: 600;
	letter-spacing: 0;
	color: #d7dde6;
	text-transform: none;
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
	justify-content: center;
		padding: 0.14rem 0.44rem;
		min-height: 1.55rem;
		border-radius: 3px;
		background: #1a1f26;
		border: 1px solid #323a44;
	color: #d7dde6;
	font-size: 0.72rem;
	font-weight: 500;
	box-shadow: none;
}

.sig-menu-trigger:hover {
	background: rgba(36, 42, 50, 0.98);
	text-decoration: none;
}

.sig-menu-panel {
	position: absolute;
	top: calc(100% + 0.3rem);
	left: 0;
	display: none;
	min-width: 13rem;
		padding: 0.22rem;
		border-radius: 3px;
		background: #161b21;
		border: 1px solid #323a44;
		box-shadow: none;
	backdrop-filter: none;
}

.sig-menu.open .sig-menu-panel {
	display: block;
}

.sig-menu-item {
	display: block;
	padding: 0.32rem 0.44rem;
	border-radius: 4px;
	color: #d7dde6;
	font-size: 0.72rem;
	white-space: nowrap;
	transition: background 120ms ease, color 120ms ease;
}

.sig-menu-item:hover {
	background: rgba(126, 200, 255, 0.1);
	color: #edf1f6;
	text-decoration: none;
	transform: none;
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
	padding: 0.16rem 0.5rem;
	border-radius: 999px;
	background: rgba(126, 200, 255, 0.08);
	color: #dce5ef;
	font-size: 0.76rem;
	border: 1px solid rgba(126, 200, 255, 0.16);
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
		background: #12161b;
	backdrop-filter: none;
		border-top: 1px solid #323a44;
	box-shadow: none;
}

.sig-taskbar-brand {
	font-size: 0.66rem;
	font-weight: 600;
	color: #d7dde6;
	text-transform: none;
	letter-spacing: 0;
}

.sig-taskbar-strip {
	display: flex;
	flex-wrap: wrap;
	align-items: center;
	gap: 0.35rem;
}

.sig-taskbar-strip-secondary {
		padding-left: 0.35rem;
		border-left: 1px solid #323a44;
}

.sig-taskbar-strip-menus .sig-menu-trigger {
	display: inline-flex;
	align-items: center;
	justify-content: center;
		padding: 0.14rem 0.44rem;
		border-radius: 3px;
		background: #1a1f26;
		border: 1px solid #323a44;
	color: #d7dde6;
	font-size: 0.7rem;
	font-weight: 500;
	box-shadow: none;
}

.sig-taskbar-strip-menus .sig-menu-trigger:hover,
.sig-taskbar-strip-menus .sig-menu.open .sig-menu-trigger {
	background: rgba(36, 42, 50, 0.98);
	color: #edf1f6;
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
		border-radius: 3px;
		background: #1a1f26;
		border: 1px solid #323a44;
	color: #d7dde6;
	font-size: 0.7rem;
	white-space: nowrap;
	box-shadow: none;
}

.sig-taskbar-button:not(.sig-taskbar-command):not(.open):not([data-sig-taskbar-pinned="true"]) {
	display: none;
}

.sig-taskbar-button.open {
	background: rgba(126, 200, 255, 0.08);
	border-color: rgba(126, 200, 255, 0.16);
}

.sig-taskbar-button.active {
	background: rgba(126, 200, 255, 0.14);
	border-color: rgba(126, 200, 255, 0.24);
	color: #edf1f6;
	font-weight: 600;
}

.sig-taskbar-button:hover {
	text-decoration: none;
	background: rgba(36, 42, 50, 0.98);
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
	color: #d7dde6;
}

.sig-taskbar-note {
	padding: 0.18rem 0.5rem;
	border-radius: 999px;
	background: rgba(126, 200, 255, 0.08);
	color: #dce5ef;
	border: 1px solid rgba(126, 200, 255, 0.16);
}

.wa-toolbar {
	position: fixed !important;
	right: 0.85rem !important;
	left: auto !important;
	top: auto !important;
	bottom: 5rem !important;
	max-width: calc(100vw - 2rem);
	z-index: 2300 !important;
		border-radius: 3px;
		border: 1px solid #323a44;
		background: #161b21;
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

.sig-floating-window {
	position: absolute;
	min-width: 22rem;
	max-width: calc(100vw - 2rem);
	min-height: 18rem;
	max-height: calc(100vh - 5.5rem);
	height: min(32rem, calc(68vh - 1rem));
		background: #161b21;
		border: 1px solid #323a44;
		border-radius: 3px;
		box-shadow: none;
	backdrop-filter: none;
	overflow-x: auto;
	overflow-y: scroll;
	scrollbar-gutter: stable both-edges;
	scrollbar-width: thin;
	scrollbar-color: rgba(137, 180, 250, 0.55) rgba(17, 17, 27, 0.42);
	resize: both;
	display: flex;
	flex-direction: column;
	z-index: 10;
}

.sig-floating-window::before {
	content: none;
}

.sig-floating-window.sig-window-active {
		border-color: rgba(126, 200, 255, 0.42);
		box-shadow: none;
}

.sig-window-titlebar {
	display: flex;
	align-items: center;
	justify-content: flex-start;
		gap: 0.32rem;
		padding: 0 0.42rem;
		height: 24px;
		background: #14181d;
		border-bottom: 1px solid #323a44;
	box-shadow: none;
	color: var(--sig-text);
	cursor: grab;
}

.sig-window-headings h2 {
	margin: 0;
		font-size: 11px;
	font-weight: 600;
	letter-spacing: 0;
	color: #e5e9f0;
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
		width: 10px;
		height: 10px;
	padding: 0;
	border-radius: 999px;
		border: 1px solid rgba(20, 23, 28, 0.35);
	color: transparent;
	font-size: 0;
	line-height: 0;
	cursor: pointer;
	box-shadow: none;
}

.sig-window-control:hover {
	text-decoration: none;
	filter: brightness(1.06);
}

.sig-window-control.close {
	background: rgba(220, 94, 101, 0.88);
}

.sig-window-control.collapse {
	background: rgba(214, 179, 88, 0.88);
}

.sig-window-control.expand {
	background: rgba(126, 179, 100, 0.88);
}

.sig-window-body {
	padding: 0;
	flex: 1 1 auto;
	min-height: 0;
	overflow-x: auto;
	overflow-y: scroll;
	display: flex;
	flex-direction: column;
		background: #161b21;
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
	gap: 0.55rem;
	min-height: 0;
}

.sig-session-grid {
	display: grid;
	grid-template-columns: repeat(3, minmax(0, 1fr));
	gap: 0.55rem;
}

.sig-session-panel {
		background: #1a1f26;
		border: 1px solid #323a44;
		border-radius: 3px;
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
		background: #1a1f26;
		border: 1px solid #323a44;
		border-radius: 3px;
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
	scrollbar-color: rgba(137, 180, 250, 0.55) rgba(17, 17, 27, 0.42);
}

.inspector-wrap {
		display: grid;
		grid-template-rows: minmax(0, 1fr) minmax(0, 1fr);
		flex: 1 1 auto;
		min-height: 0;
		height: 100%;
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
		background: #1a1f26;
		border: 1px solid #323a44;
		border-radius: 3px;
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
	color: #8f9aaa;
}

.exp-toolbar-value,
.exp-selection-value {
	display: inline-flex;
	align-items: center;
	min-height: 1.9rem;
	padding: 0.18rem 0.42rem;
	border: 1px solid rgba(56, 62, 72, 0.92);
	border-radius: 4px;
	background: rgba(21, 25, 31, 0.98);
	color: #eef6ff;
	min-width: 0;
}

.exp-user-select {
		width: 100%;
		min-height: 1.95rem;
		padding: 0.28rem 2rem 0.28rem 0.55rem;
		background: #171c22;
		color: #eef6ff;
		border: 1px solid #323a44;
		border-radius: 3px;
		font: inherit;
		appearance: none;
		-webkit-appearance: none;
		background-image:
			linear-gradient(45deg, transparent 50%, #8fb4fa 50%),
			linear-gradient(135deg, #8fb4fa 50%, transparent 50%);
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

.exp-section {
		display: flex;
		flex-direction: column;
		gap: 0.35rem;
		padding: 0.35rem;
		background: #1a1f26;
		border: 1px solid #323a44;
		border-radius: 3px;
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

.exp-pane {
		display: flex;
		flex-direction: column;
		gap: 0.45rem;
		padding: 0.38rem 0.42rem;
		min-height: auto;
}

.exp-scroll {
		overflow-x: auto;
		overflow-y: scroll;
		padding: 0.28rem 0.3rem;
		background: #171c22;
		border: 1px solid #323a44;
		border-radius: 3px;
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
	border-radius: 4px;
	border: 1px solid transparent;
	color: #d7dde6;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.exp-item:hover {
	background: rgba(36, 42, 50, 0.98);
	color: #edf1f6;
	text-decoration: none;
}

.exp-item.selected {
	background: rgba(126, 200, 255, 0.1);
	border-color: rgba(126, 200, 255, 0.14);
	color: #edf1f6;
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
		background: rgba(24, 29, 36, 0.92);
		border-bottom: 1px solid rgba(50, 58, 68, 0.92);
}

.exp-table tbody tr.exp-table-row:nth-child(even) {
		background: rgba(27, 33, 40, 0.94);
}

.exp-table tbody tr.exp-table-row:hover {
		background: rgba(45, 56, 69, 0.96);
}

.exp-table-key {
		color: #9fb0c1;
		font-weight: 700;
}

.exp-table-value {
		color: #eef6ff;
}

.inspector-value-link {
		color: #dbe4ee;
		text-decoration: none;
		border-bottom: 1px solid rgba(126, 200, 255, 0.28);
}

.inspector-value-link:hover {
		color: #eef6ff;
		border-bottom-color: rgba(126, 200, 255, 0.65);
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
	padding: 0.28rem 0.44rem;
	border-radius: 4px;
	background: transparent;
	border: 1px solid transparent;
	color: #bcc5d1;
	transition: background 120ms ease, border-color 120ms ease, color 120ms ease;
}

.sig-browser-item:hover,
.sig-root:hover {
	background: rgba(34, 40, 48, 0.98);
	color: #edf1f6;
	text-decoration: none;
	transform: none;
}

.sig-browser-item.selected,
.sig-root.selected {
	background: rgba(126, 200, 255, 0.1);
	border-color: rgba(126, 200, 255, 0.14);
	color: #edf1f6;
	font-weight: 600;
}

.sig-window-note {
		color: #aeb8c4;
		margin: 0;
		padding: 0.34rem 0.4rem;
		border-left: 1px solid rgba(126, 200, 255, 0.2);
		border-radius: 3px;
		background: #171c22;
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
		border-radius: 3px;
		background: #1a1f26;
		border: 1px solid #323a44;
	color: #d7dde6;
	font-size: 0.72rem;
	font-weight: 500;
	box-shadow: none;
	transition: background 120ms ease, border-color 120ms ease, color 120ms ease;
}

.sig-action:hover,
.sig-local-command:hover {
	background: rgba(36, 42, 50, 0.98);
	color: #edf1f6;
	text-decoration: none;
	transform: none;
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
	color: #8f9aaa;
	background: rgba(21, 25, 31, 0.98);
}

.sig-table th,
.sig-table td {
	border-top: 1px solid rgba(53, 59, 69, 0.96);
	padding: 0.34rem 0.42rem;
	text-align: left;
	vertical-align: top;
}

.sig-table tr:hover td {
	background: rgba(34, 40, 48, 0.72);
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
	scrollbar-color: rgba(137, 180, 250, 0.55) rgba(17, 17, 27, 0.42);
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
	background: rgba(17, 17, 27, 0.42);
	border-radius: 999px;
}

.sig-window-body::-webkit-scrollbar-thumb,
.exp-wrap::-webkit-scrollbar-thumb,
.sig-scroll-pane::-webkit-scrollbar-thumb {
	background: rgba(89, 106, 129, 0.92);
	border: 2px solid rgba(17, 17, 27, 0.42);
	border-radius: 999px;
}

.sig-window-body::-webkit-scrollbar-thumb:hover,
.exp-wrap::-webkit-scrollbar-thumb:hover,
.sig-scroll-pane::-webkit-scrollbar-thumb:hover {
	background: rgba(109, 128, 153, 0.96);
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
	background: rgba(17, 20, 25, 0.98);
	border: 1px solid rgba(53, 59, 69, 0.96);
	border-radius: 4px;
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
	grid-template-columns: 1.15rem 3rem minmax(0, 1fr);
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

.sig-debugger-step-caret {
	display: inline-block;
	width: 0;
	height: 1.05em;
	margin-right: 0.14rem;
	border-left: 2px solid #f9e2af;
	vertical-align: -0.12em;
	box-shadow: 0 0 0 1px rgba(249, 226, 175, 0.18);
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
	min-width: 13rem;
	padding: 0.45rem;
	border-radius: 5px;
	background: rgba(18, 21, 26, 0.99);
	border: 1px solid rgba(56, 62, 72, 0.96);
	box-shadow: 0 10px 24px rgba(0, 0, 0, 0.18);
	backdrop-filter: none;
	z-index: 2500;
}

.sig-context-group + .sig-context-group {
	margin-top: 0.8rem;
	padding-top: 0.8rem;
	border-top: 1px solid rgba(56, 62, 72, 0.92);
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
	border-radius: 4px;
	color: #d7dde6;
}

.sig-context-menu .sig-action:hover,
.sig-context-menu .sig-local-command:hover {
	background: rgba(36, 42, 50, 0.98);
	color: #edf1f6;
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
	border-radius: 4px;
	background: rgba(17, 20, 25, 0.98);
	border: 1px solid rgba(53, 59, 69, 0.96);
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
	border-radius: 4px;
	border: 1px solid rgba(56, 62, 72, 0.96);
	background: rgba(16, 19, 23, 0.98);
	box-sizing: border-box;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.86rem;
	line-height: 1.5;
	color: #dfe5ec;
	box-shadow: none;
}

.sig-workspace-editor:focus {
	outline: none;
	border-color: rgba(126, 200, 255, 0.38);
	box-shadow: none;
}

.sig-workspace-toolbar {
	display: flex;
	flex-wrap: wrap;
	gap: 0.45rem;
}

.sig-workspace-button {
	border: 1px solid rgba(126, 200, 255, 0.2);
	padding: 0.3rem 0.62rem;
	border-radius: 4px;
	background: rgba(126, 200, 255, 0.12);
	color: #edf1f6;
	font-size: 0.8rem;
	cursor: pointer;
	font-weight: 600;
}

.sig-workspace-button:hover {
	background: rgba(126, 200, 255, 0.18);
}

.sig-workspace-button.sig-workspace-button-secondary {
	background: rgba(26, 30, 36, 0.98);
	border-color: rgba(56, 62, 72, 0.96);
	color: #d7dde6;
}

.sig-workspace-output {
	background: rgba(24, 28, 34, 0.98);
	border: 1px solid rgba(53, 59, 69, 0.96);
	border-radius: 5px;
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
	border-bottom: 1px solid rgba(69, 71, 90, 0.72);
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
	color: #eef6ff;
	word-break: break-word;
}

.sig-window-body input[type="text"],
.sig-window-body textarea,
.sig-window-body select {
	border: 1px solid rgba(56, 62, 72, 0.96);
	border-radius: 4px;
	background: rgba(16, 19, 23, 0.98);
	color: #dfe5ec;
	box-shadow: none;
}

.sig-window-body input[type="text"]:focus,
.sig-window-body textarea:focus,
.sig-window-body select:focus {
	outline: none;
	border-color: rgba(126, 200, 255, 0.38);
	box-shadow: none;
}

.sig-window-body input[type="text"]::placeholder,
.sig-window-body textarea::placeholder {
	color: #6c7086;
}

button.btn,
.btn {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.26rem 0.68rem;
	border-radius: 4px;
	border: 1px solid rgba(126, 200, 255, 0.2);
	background: rgba(126, 200, 255, 0.12);
	color: #edf1f6;
	font-size: 11px;
	font-weight: 600;
	cursor: pointer;
	text-decoration: none;
	box-shadow: none;
}

button.btn:hover,
.btn:hover {
	background: rgba(126, 200, 255, 0.18);
	text-decoration: none;
}

button.btn-ghost,
.btn-ghost {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.26rem 0.62rem;
	border-radius: 4px;
	border: 1px solid rgba(56, 62, 72, 0.96);
	background: rgba(26, 30, 36, 0.98);
	color: #d7dde6;
	font-size: 11px;
	font-weight: 500;
	cursor: pointer;
	text-decoration: none;
	box-shadow: none;
}

button.btn-ghost:hover,
.btn-ghost:hover {
	background: rgba(36, 42, 50, 0.98);
	text-decoration: none;
}

button.btn-tx,
.btn-tx {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.26rem 0.68rem;
	border-radius: 4px;
	border: 1px solid rgba(56, 62, 72, 0.96);
	background: rgba(26, 30, 36, 0.98);
	color: #d7dde6;
	font-size: 11px;
	font-weight: 500;
	cursor: pointer;
	text-decoration: none;
}

button.btn-tx:hover,
.btn-tx:hover {
	background: rgba(36, 42, 50, 0.98);
	text-decoration: none;
}

.btn-tx-active {
	background: rgba(126, 200, 255, 0.12);
	border-color: rgba(126, 200, 255, 0.2);
	color: #edf1f6;
}

.btn-dbg {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	padding: 0.34rem 0.72rem;
	border-radius: 4px;
	border: 1px solid rgba(126, 200, 255, 0.18);
	background: rgba(126, 200, 255, 0.1);
	color: #edf1f6;
	font-size: 12px;
	font-weight: 600;
	cursor: pointer;
	text-decoration: none;
	flex: 1;
	box-shadow: none;
}

.btn-dbg:hover {
	background: rgba(126, 200, 255, 0.16);
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
	background: rgba(20, 23, 28, 1);
	overflow-y: scroll;
	overflow-x: hidden;
	scrollbar-gutter: stable both-edges;
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
	padding: 0.38rem 0.52rem;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.78rem;
	color: #d7ddea;
	background: rgba(20, 23, 28, 1);
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
}

.ws-entry {
	margin-bottom: 0.34rem;
}

.ws-code {
	color: #cdd6f4;
	white-space: pre-wrap;
	word-break: break-word;
}

.ws-result {
	margin-top: 0.24rem;
	padding: 0.2rem 0.42rem;
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
	border-top: 1px solid rgba(53, 59, 69, 0.96);
	display: flex;
	flex-direction: column;
	flex-shrink: 0;
	background: rgba(20, 23, 28, 1);
}

.ws-code-area {
	width: 100%;
	min-height: 6.5rem;
	padding: 0.52rem;
	border: none;
	background: rgba(16, 19, 23, 0.98);
	color: #dfe5ec;
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

.ws-hint {
	margin-left: auto;
	font-size: 0.68rem;
	color: #6c7086;
}

.txbar {
	display: flex;
	align-items: center;
	gap: 0.45rem;
	padding: 0.45rem 0.75rem;
	border-top: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
	flex-wrap: wrap;
}

.txbar span {
	font-size: 0.72rem;
	color: #6c7086;
}

.tab-strip {
	display: flex;
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
	flex-shrink: 0;
	overflow-x: auto;
}

.tab-item {
	padding: 5px 12px;
	font-size: 11px;
	color: #d7ddea;
	cursor: pointer;
	border-bottom: 2px solid transparent;
	margin-bottom: -1px;
	white-space: nowrap;
	user-select: none;
}

.tab-item:hover {
	color: #f5f8ff;
	text-decoration: none;
}

.tab-item.active {
	color: #edf1f6;
	border-bottom-color: rgba(126, 200, 255, 0.72);
	background: rgba(126, 200, 255, 0.06);
}

.sig-debugger-shell {
	display: flex;
	flex-direction: column;
	height: 100%;
	min-height: 0;
	background: rgba(20, 23, 28, 1);
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
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
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
	color: #cdd6f4;
}

.dbg-summary-error {
	color: #f38ba8;
}

.sig-debugger-frame-list {
	flex: 1;
	min-height: 80px;
	max-height: 196px;
	height: 196px;
	padding: 0;
	border: none;
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	border-radius: 0;
	background: rgba(20, 23, 28, 1);
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
	background: rgba(36, 42, 50, 0.98);
	text-decoration: none;
}

.dbg-frame-item.active,
.sig-debugger-frame.selected {
	background: rgba(126, 200, 255, 0.12);
	border-left-color: rgba(126, 200, 255, 0.72);
	color: #edf1f6;
}

.dbg-frame-icon {
	width: 12px;
	height: 12px;
	border-radius: 999px;
	display: inline-flex;
	align-items: center;
	justify-content: center;
	font-size: 7px;
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
	gap: 0.3rem;
	padding: 0.45rem 0.6rem;
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
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
	border-top: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
}

.dbg-action-bar {
	display: flex;
	align-items: stretch;
	gap: 0;
	padding: 0;
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
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
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
	color: #d7ecff;
	font-size: 10px;
	font-family: monospace;
}

.dbg-source-code {
	flex: 1;
	min-height: 0;
	background: rgba(18, 21, 26, 1);
	color: #dfe5ec;
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
	transition: background 120ms ease, border-color 120ms ease;
}

.dbg-source-line.active {
	background: rgba(126, 200, 255, 0.08);
	border-left-color: rgba(126, 200, 255, 0.72);
}

.dbg-source-marker {
	color: #9ad6ff;
	min-width: 28px;
	text-align: center;
	user-select: none;
	flex-shrink: 0;
	opacity: 0.15;
}

.dbg-step-cursor,
.dbg-step-cursor-spacer {
	display: inline-flex;
	align-items: center;
	justify-content: center;
	min-width: 22px;
	height: 16px;
	border-radius: 999px;
	font-size: 10px;
	line-height: 1;
	font-weight: 700;
}

.dbg-step-cursor {
	background: rgba(126, 200, 255, 0.18);
	color: #d8ecff;
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
	color: #9fa9bc;
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
	border-top: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
	flex-shrink: 0;
}

.dbg-self-label {
	color: #6c7086;
	font-size: 10px;
}

.dbg-self-val {
	font-family: monospace;
	color: #cba6f7;
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
	color: #a6e3a1;
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
	color: #7ec8ff;
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
	background: rgba(20, 23, 28, 1);
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
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
	flex-shrink: 0;
}

.cb-static-btn {
	pointer-events: none;
}

.cb-meta {
	display: inline-flex;
	align-items: center;
	gap: 0.24rem;
	color: #e4e9f2;
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
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	flex-shrink: 0;
}

.cb-pane {
	display: flex;
	flex-direction: column;
	min-width: 0;
	min-height: 0;
	overflow: hidden;
	border-right: 1px solid rgba(53, 59, 69, 0.96);
}

.cb-pane:last-child {
	border-right: none;
}

.cb-splitter {
	position: relative;
	background: rgba(20, 23, 28, 1);
	border-right: 1px solid rgba(53, 59, 69, 0.96);
	border-left: 1px solid rgba(53, 59, 69, 0.96);
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
	background: #4a5260;
}

.cb-pane-label {
	padding: 0.24rem 0.38rem;
	background: rgba(20, 23, 28, 1);
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	font-size: 0.62rem;
	text-transform: uppercase;
	letter-spacing: 0.06em;
	color: #d7ddea;
}

.cb-filter-wrap {
	padding: 0.24rem 0.3rem;
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
	background: rgba(20, 23, 28, 1);
}

.cb-filter {
	width: 100%;
	box-sizing: border-box;
	border: 1px solid rgba(56, 62, 72, 0.96);
	border-radius: 4px;
	background: rgba(16, 19, 23, 0.98);
	color: #dfe5ec;
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
	color: #d7dde6;
	border-left: 3px solid transparent;
	white-space: nowrap;
	overflow: hidden;
	text-overflow: ellipsis;
}

.cb-item:hover {
	background: rgba(36, 42, 50, 0.98);
	text-decoration: none;
}

.cb-item.selected {
	border-left-color: rgba(126, 200, 255, 0.72);
	background: rgba(126, 200, 255, 0.1);
	color: #edf1f6;
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
	background: rgba(20, 23, 28, 1);
	border-bottom: 1px solid rgba(53, 59, 69, 0.96);
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
	color: #8f9aaa;
}

.cb-source-btn {
	padding: 0.18rem 0.46rem;
	font-size: 0.68rem;
}

.cb-source {
	flex: 1;
	min-height: 0;
	padding: 0.38rem 0.46rem;
	background: rgba(18, 21, 26, 1);
	display: flex;
}

.cb-source-editor {
	width: 100%;
	min-height: 100%;
	height: 100%;
	padding: 0;
	border: none;
	background: transparent;
	color: #dfe5ec;
	font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, monospace;
	font-size: 0.78rem;
	line-height: 1.42;
	resize: none;
	outline: none;
}

.cb-source-editor::placeholder {
	color: #7f8997;
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
