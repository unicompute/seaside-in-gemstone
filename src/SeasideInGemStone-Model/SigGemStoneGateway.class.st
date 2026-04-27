Class {
	#name : 'SigGemStoneGateway',
	#superclass : 'Object',
	#instVars : [
		'lastErrorText',
		'lastErrorStackText',
		'lastErrorFrames',
		'debugSessions',
		'nextDebugSessionNumber',
		'lastDebugSessionId'
	],
	#category : 'SeasideInGemStone-Model',
	#package : 'SeasideInGemStone-Model'
}

{ #category : 'actions' }
SigGemStoneGateway >> abortTransaction [
	^ self
		withErrorHandlingDo: [
			System abortTransaction.
			true ]
		ifUnavailable: [ false ]
]

{ #category : 'private' }
SigGemStoneGateway >> clearDebugSessions [
	debugSessions ifNil: [ ^ self ].
	debugSessions valuesDo: [ :each | self terminateDebugSession: each ].
	debugSessions := Dictionary new.
	lastDebugSessionId := nil
]

{ #category : 'private' }
SigGemStoneGateway >> clearLastErrorState [
	lastErrorText := nil.
	lastErrorStackText := nil.
	lastErrorFrames := nil
]

{ #category : 'private' }
SigGemStoneGateway >> appendAssociationPreviewOf: anObject on: aStream [
	(anObject isKindOf: Association) ifFalse: [ ^ self ].
	aStream
		cr;
		cr;
		nextPutAll: 'Association:';
		cr;
		nextPutAll: 'key: ';
		nextPutAll: (self longDisplayStringFor: anObject key);
		cr;
		nextPutAll: 'value: ';
		nextPutAll: (self longDisplayStringFor: anObject value)
]

{ #category : 'private' }
SigGemStoneGateway >> appendCollectionPreviewOf: anObject on: aStream [
	| index limit |
	(anObject isKindOf: String) ifTrue: [ ^ self ].
	(anObject isKindOf: Dictionary)
		ifTrue: [
			limit := 10.
			index := 0.
			aStream
				cr;
				cr;
				nextPutAll: 'Associations:';
				cr.
			anObject associationsDo: [ :each |
				index := index + 1.
				index <= limit ifTrue: [
					aStream
						nextPutAll: each key asString;
						nextPutAll: ' -> ';
						nextPutAll: (self longDisplayStringFor: each value);
						cr ] ].
			index > limit ifTrue: [
				aStream
					nextPutAll: '... ';
					nextPutAll: (index - limit) printString;
					nextPutAll: ' more';
					cr ].
			^ self ].
	(anObject isKindOf: Collection) ifFalse: [ ^ self ].
	limit := 10.
	index := 0.
	aStream
		cr;
		cr;
		nextPutAll: 'Items:';
		cr.
	anObject do: [ :each |
		index := index + 1.
		index <= limit ifTrue: [
			aStream
				nextPutAll: index printString;
				nextPutAll: ': ';
				nextPutAll: (self longDisplayStringFor: each);
				cr ] ].
	index > limit ifTrue: [
		aStream
			nextPutAll: '... ';
			nextPutAll: (index - limit) printString;
			nextPutAll: ' more';
			cr ]
]

{ #category : 'private' }
SigGemStoneGateway >> appendNamedInstVarsOf: anObject on: aStream [
	| names |
	names := anObject class allInstVarNames.
	names isEmpty ifTrue: [ ^ self ].
	aStream
		cr;
		cr;
		nextPutAll: 'Instance Variables:';
		cr.
	1 to: names size do: [ :index |
		aStream
			nextPutAll: (names at: index) asString;
			nextPutAll: ': ';
			nextPutAll: (self longDisplayStringFor: (anObject instVarAt: index));
			cr ]
]

{ #category : 'querying' }
SigGemStoneGateway >> browserDictionaryNames [
	^ self
		withErrorHandlingDo: [
			| names |
			names := Set new.
			self currentSession symbolList do: [ :each |
				((each isKindOf: SymbolDictionary) and: [ each name notNil ])
					ifTrue: [ names add: each name ] ].
			(names asArray
				asSortedCollection: [ :left :right | left asString <= right asString ]) asArray ]
		ifUnavailable: [ #() ]
]

{ #category : 'accessing' }
SigGemStoneGateway >> bridgeRoot [
	| root userGlobals |
	userGlobals := self userGlobals.
	root := userGlobals at: #GbsBridgeRoot ifAbsent: [ nil ].
	root ifNil: [
		root := Dictionary new.
		userGlobals at: #GbsBridgeRoot put: root ].
	^ root
]

{ #category : 'querying' }
SigGemStoneGateway >> classAssociationsForDictionaryNamed: aSymbol [
	^ self
		withErrorHandlingDo: [
			| associations dictionary |
			dictionary := self symbolDictionaryNamed: aSymbol ifAbsent: [ nil ].
			dictionary ifNil: [ #() ] ifNotNil: [
			associations := dictionary associations
				select: [ :each | each value isBehavior ].
			(associations asSortedCollection: [ :left :right |
				left key asString <= right key asString ]) asArray ] ]
		ifUnavailable: [ #() ]
]

{ #category : 'private' }
SigGemStoneGateway >> classForDictionaryNamed: aSymbol classNamed: aString [
	| dictionary |
	dictionary := self symbolDictionaryNamed: aSymbol ifAbsent: [ ^ nil ].
	^ dictionary at: aString asSymbol ifAbsent: [ nil ]
]

{ #category : 'actions' }
SigGemStoneGateway >> commitTransactionOrSignalConflict [
	^ self
		withErrorHandlingDo: [
			System commitTransaction.
			true ]
		ifUnavailable: [ false ]
]

{ #category : 'accessing' }
SigGemStoneGateway >> connectionSummary [
	^ 'current GemStone session'
]

{ #category : 'accessing' }
SigGemStoneGateway >> currentSession [
	^ GsCurrentSession currentSession
]

{ #category : 'querying' }
SigGemStoneGateway >> currentStackReport [
	^ self
		withErrorHandlingDo: [ self stackReportSafely ]
		ifUnavailable: [ 'Unable to capture a GemStone stack report.' ]
]

{ #category : 'querying' }
SigGemStoneGateway >> currentStackFrames [
	^ self stackFramesSafelyToLevel: 40
]

{ #category : 'private' }
SigGemStoneGateway >> dictionaryForRootNamed: aSymbol [
	aSymbol = #bridgeRoot ifTrue: [ ^ self bridgeRoot ].
	aSymbol = #userGlobals ifTrue: [ ^ self userGlobals ].
	aSymbol = #globals ifTrue: [ ^ self globals ].
	aSymbol = #published ifTrue: [ ^ self published ].
	aSymbol = #sessionMethods ifTrue: [ ^ self sessionMethods ].
	self error: 'Unknown GemStone root: ', aSymbol asString
]

{ #category : 'private' }
SigGemStoneGateway >> displayStringFor: anObject [
	| text |
	text := [ anObject printString ] on: Error do: [ anObject class name asString ].
	text ifNil: [ ^ '(nil)' ].
	^ text size > 160
		ifTrue: [ (text first: 157), '...' ]
		ifFalse: [ text ]
]

{ #category : 'private' }
SigGemStoneGateway >> debuggerReceiverTextFromDetailedReport: aDetailedReport [
	| fullEntry receiver |
	aDetailedReport ifNil: [ ^ nil ].
	fullEntry := [ aDetailedReport first ]
		on: Error
		do: [ nil ].
	fullEntry ifNil: [ ^ nil ].
	receiver := [ fullEntry at: 2 ]
		on: Error
		do: [ nil ].
	receiver ifNil: [ ^ nil ].
	^ self displayStringFor: receiver
]

{ #category : 'private' }
SigGemStoneGateway >> debuggerVariableRecordsFromDetailedReport: aDetailedReport [
	| limit names records values |
	aDetailedReport ifNil: [ ^ #() ].
	names := (aDetailedReport size >= 7)
		ifTrue: [ aDetailedReport at: 7 ]
		ifFalse: [ #() ].
	values := (aDetailedReport size >= 8)
		ifTrue: [ aDetailedReport at: 8 ]
		ifFalse: [ #() ].
	((names isNil) or: [ values isNil ]) ifTrue: [ ^ #() ].
	records := OrderedCollection new.
	limit := (names size min: values size) min: 40.
	1 to: limit do: [ :index |
		records add: (Dictionary new
			at: #name put: (names at: index) asString;
			at: #value put: (self displayStringFor: (values at: index));
			yourself) ].
	^ records asArray
]

{ #category : 'querying' }
SigGemStoneGateway >> inspectionStringFor: anObject [
	| stream |
	stream := WriteStream on: String new.
	stream
		nextPutAll: 'Class: ';
		nextPutAll: anObject class name asString;
		cr.
	(anObject isKindOf: Collection) ifTrue: [
		[ stream
			nextPutAll: 'Size: ';
			nextPutAll: anObject size printString;
			cr ]
			on: Error
			do: [ :ex | ex return ] ].
	stream
		nextPutAll: 'Print String:';
		cr;
		nextPutAll: (self longDisplayStringFor: anObject).
	self appendAssociationPreviewOf: anObject on: stream.
	self appendCollectionPreviewOf: anObject on: stream.
	self appendNamedInstVarsOf: anObject on: stream.
	^ stream contents
]

{ #category : 'actions' }
SigGemStoneGateway >> disconnect [
	self clearDebugSessions.
	self clearLastErrorState
]

{ #category : 'private' }
SigGemStoneGateway >> formattedStackReportTextForFrames: frames [
	| stream |
	frames ifNil: [ ^ 'No debugger frames captured.' ].
	frames isEmpty ifTrue: [ ^ 'No debugger frames captured.' ].
	stream := WriteStream on: String new.
	frames
		doWithIndex: [ :each :index |
			index > 1 ifTrue: [ stream cr; cr ].
			stream nextPutAll: (each at: #text ifAbsent: [ each at: #description ifAbsent: [ 'Unknown frame' ] ]) ].
	^ stream contents
]

{ #category : 'querying' }
SigGemStoneGateway >> entryAssociationsForRootNamed: aSymbol [
	^ self
		withErrorHandlingDo: [
			| associations |
			associations := (self dictionaryForRootNamed: aSymbol) associations.
			(associations asSortedCollection: [ :left :right |
				left key asString <= right key asString ]) asArray ]
		ifUnavailable: [ #() ]
]

{ #category : 'private' }
SigGemStoneGateway >> errorTextFor: anError [
	| text |
	text := [ anError messageText ] on: Error do: [ nil ].
	(text isNil or: [ text asString isEmpty ]) ifTrue: [
		text := [ anError printString ] on: Error do: [ anError class name asString ] ].
	^ text
		ifNil: [ anError class name asString ]
		ifNotNil: [ text asString ]
]

{ #category : 'querying' }
SigGemStoneGateway >> debuggerSnapshotForSessionId: aSessionId [
	| session |
	session := self debugSessionAt: aSessionId ifAbsent: [ ^ self missingDebuggerSnapshot ].
	self refreshDebugSession: session.
	self refreshLastErrorStateFromDebugSession: session.
	^ self snapshotForDebugSession: session
]

{ #category : 'private' }
SigGemStoneGateway >> debugSessionAt: aSessionId ifAbsent: aBlock [
	(debugSessions isNil or: [ aSessionId isNil ]) ifTrue: [ ^ aBlock value ].
	^ debugSessions at: aSessionId ifAbsent: aBlock
]

{ #category : 'private' }
SigGemStoneGateway >> debugProcessForSession: aSession [
	| process sessionId storedProcess |
	aSession ifNil: [ ^ nil ].
	storedProcess := aSession at: #process ifAbsent: [ nil ].
	storedProcess ifNil: [ ^ nil ].
	(storedProcess isKindOf: TransientStackValue) ifTrue: [ ^ storedProcess value ].
	(storedProcess isInteger or: [ storedProcess isString ]) ifTrue: [
		process := self debugProcessRegistry at: storedProcess ifAbsent: [ nil ].
		process ifNil: [ aSession removeKey: #process ifAbsent: [ ] ].
		^ process ].
	sessionId := aSession at: #id ifAbsent: [ nil ].
	sessionId ifNotNil: [
		self debugProcessRegistry at: sessionId put: storedProcess.
		aSession at: #process put: sessionId ].
	self storeDebugProcess: storedProcess inSession: aSession.
	^ storedProcess
]

{ #category : 'private' }
SigGemStoneGateway >> debugSessionCanControl: aSession [
	| process status |
	aSession ifNil: [ ^ false ].
	status := aSession at: #status ifAbsent: [ #terminated ].
	process := self debugProcessForSession: aSession.
	process ifNil: [ ^ false ].
	(status = #terminated or: [ status = #completed ]) ifTrue: [ ^ false ].
	^ [ process isTerminated not ] on: Error do: [ false ]
]

{ #category : 'private' }
SigGemStoneGateway >> debugSessionStatusTextFor: aSession [
	| resultText status |
	aSession ifNil: [ ^ 'No live debug process attached.' ].
	status := aSession at: #status ifAbsent: [ #terminated ].
	status = #suspended ifTrue: [ ^ 'Debug process suspended.' ].
	status = #running ifTrue: [ ^ 'Debug process running.' ].
	status = #completed ifTrue: [
		resultText := aSession at: #resultText ifAbsent: [ nil ].
		^ resultText
			ifNil: [ 'Debug process completed.' ]
			ifNotNil: [ 'Debug process completed with ', resultText ] ].
	status = #terminated ifTrue: [ ^ 'Debug process terminated.' ].
	^ 'Debug process unavailable.'
]

{ #category : 'accessing' }
SigGemStoneGateway >> debugProcessRegistry [
	| registry |
	registry := SessionTemps current
		at: #SigGemStoneGateway_debugProcesses
		ifAbsent: [ nil ].
	registry ifNil: [
		registry := Dictionary new.
		SessionTemps current
			at: #SigGemStoneGateway_debugProcesses
			put: registry ].
	^ registry
]

{ #category : 'private' }
SigGemStoneGateway >> debugProcessContextFor: aProcess atLevel: aLevel [
	| context currentLevel targetLevel |
	aProcess ifNil: [ ^ nil ].
	targetLevel := aLevel ifNil: [ 1 ].
	context := [ aProcess topContext ] on: Error do: [ nil ].
	context ifNil: [ ^ nil ].
	currentLevel := 1.
	[ context notNil and: [ currentLevel < targetLevel ] ] whileTrue: [
		context := [ context sender ] on: Error do: [ nil ].
		currentLevel := currentLevel + 1 ].
	^ context
]

{ #category : 'private' }
SigGemStoneGateway >> debugProcessQuickStepPointFor: aProcess atLevel: aLevel [
	| fullEntry stackReport |
	((aProcess respondsTo: #_gsiStackReportFromLevel:toLevel:) not) ifTrue: [ ^ nil ].
	stackReport := [ aProcess _gsiStackReportFromLevel: aLevel toLevel: aLevel ]
		on: Error
		do: [ nil ].
	((stackReport isNil)
		or: [ (stackReport respondsTo: #size) not or: [ stackReport size < 2 ] ])
		ifTrue: [ ^ nil ].
	fullEntry := [ stackReport at: 2 ] on: Error do: [ nil ].
	fullEntry ifNil: [ ^ nil ].
	((fullEntry respondsTo: #size) and: [ fullEntry size < 5 ]) ifTrue: [ ^ nil ].
	^ [ (fullEntry at: 5) asInteger ] on: Error do: [ nil ]
]

{ #category : 'accessing' }
SigGemStoneGateway >> globals [
	^ self symbolDictionaryNamed: #Globals ifAbsent: [ self error: 'Globals unavailable' ]
]

{ #category : 'accessing' }
SigGemStoneGateway >> lastErrorStackText [
	^ lastErrorStackText
]

{ #category : 'accessing' }
SigGemStoneGateway >> lastErrorFrames [
	^ lastErrorFrames
]

{ #category : 'accessing' }
SigGemStoneGateway >> lastDebugSessionId [
	^ lastDebugSessionId
]

{ #category : 'accessing' }
SigGemStoneGateway >> lastErrorText [
	^ lastErrorText
]

{ #category : 'private' }
SigGemStoneGateway >> longDisplayStringFor: anObject [
	| text |
	text := [ anObject printString ] on: Error do: [ anObject class name asString ].
	text ifNil: [ ^ '(nil)' ].
	^ text size > 4000
		ifTrue: [ (text first: 3997), '...' ]
		ifFalse: [ text ]
]

{ #category : 'querying' }
SigGemStoneGateway >> methodSourceForClassNamed: aClassName selectorNamed: aSelectorName inDictionaryNamed: aSymbol [
	^ self
		withErrorHandlingDo: [
			| behavior selector source |
			behavior := self classForDictionaryNamed: aSymbol classNamed: aClassName.
			behavior ifNil: [ 'Select a class to browse its methods.' ] ifNotNil: [
				selector := aSelectorName.
				selector ifNil: [ 'Select a method to inspect its source.' ] ifNotNil: [
					source := behavior sourceCodeAt: selector asSymbol.
					source ifNil: [ 'Source unavailable.' ] ifNotNil: [ source asString ] ] ] ]
		ifUnavailable: [ 'Source unavailable.' ]
]

{ #category : 'querying' }
SigGemStoneGateway >> protocolNamesForClassNamed: aClassName inDictionaryNamed: aSymbol [
	^ self
		withErrorHandlingDo: [
			| behavior categories |
			behavior := self classForDictionaryNamed: aSymbol classNamed: aClassName.
			behavior ifNil: [ #() ] ifNotNil: [
				categories := behavior organization categories collect: [ :each | each asString ].
				(categories asSortedCollection: [ :left :right | left <= right ]) asArray ] ]
		ifUnavailable: [ #() ]
]

{ #category : 'accessing' }
SigGemStoneGateway >> published [
	^ self symbolDictionaryNamed: #Published ifAbsent: [ Dictionary new ]
]

{ #category : 'actions' }
SigGemStoneGateway >> performDebugAction: anActionSymbol forSessionId: aSessionId atLevel: aLevel [
	| session |
	session := self debugSessionAt: aSessionId ifAbsent: [ ^ self missingDebuggerSnapshot ].
	self performDebugAction: anActionSymbol forSession: session atLevel: aLevel.
	self refreshDebugSession: session.
	self stabilizeDebugSessionAfterAction: anActionSymbol session: session.
	self refreshLastErrorStateFromDebugSession: session.
	^ self snapshotForDebugSession: session
]

{ #category : 'private' }
SigGemStoneGateway >> performDebugAction: anActionSymbol forSession: aSession atLevel: aLevel [
	| effectiveLevel process stepLevel |
	aSession ifNil: [ ^ self ].
	process := self debugProcessForSession: aSession.
	process ifNil: [ ^ self ].
	([ process isTerminated ] on: Error do: [ ^ self ])
		ifTrue: [ ^ self ].
	effectiveLevel := aLevel ifNil: [ 1 ].
	stepLevel := effectiveLevel.
	anActionSymbol = #refresh ifTrue: [ ^ self ].
	((anActionSymbol = #proceed) or: [ anActionSymbol = #resume ]) ifTrue: [
		aSession at: #status put: #running.
		process resume.
		^ self waitForDebugProcessToStopAfterResume: process ].
	anActionSymbol = #restart ifTrue: [
		^ self restartDebugProcess: process atLevel: effectiveLevel session: aSession ].
	anActionSymbol = #step ifTrue: [
		aSession at: #status put: #running.
		[
			self
				stepDebugProcess: process
				withSelectorChain: #(step: stepIntoFromLevel: _stepIntoInFrame: gciStepIntoFromLevel:)
				level: stepLevel
				errorMessage: 'Debugger step is unavailable for this GemStone process.' ]
			on: Error
			do: [ :error |
			aSession at: #status put: #terminated.
			aSession at: #resultText put: (self errorTextFor: error) ].
		^ self waitForDebugProcessToStop: process ].
	anActionSymbol = #stepInto ifTrue: [
		aSession at: #status put: #running.
		[
			self
				stepDebugProcess: process
				withSelectorChain: #(stepIntoFromLevel: _stepIntoInFrame: gciStepIntoFromLevel: step:)
				level: stepLevel
				errorMessage: 'Debugger step-into is unavailable for this GemStone process.' ]
			on: Error
			do: [ :error |
			aSession at: #status put: #terminated.
			aSession at: #resultText put: (self errorTextFor: error) ].
		^ self waitForDebugProcessToStop: process ].
	anActionSymbol = #stepOver ifTrue: [
		aSession at: #status put: #running.
		[
			self
				stepDebugProcess: process
				withSelectorChain: #(stepOverFromLevel: _stepOverInFrame: gciStepOverFromLevel:)
				level: stepLevel
				errorMessage: 'Debugger step-over is unavailable for this GemStone process.' ]
			on: Error
			do: [ :error |
			aSession at: #status put: #terminated.
			aSession at: #resultText put: (self errorTextFor: error) ].
		^ self waitForDebugProcessToStop: process ].
	((anActionSymbol = #stepOut) or: [ anActionSymbol = #stepReturn ]) ifTrue: [
		aSession at: #status put: #running.
		[
			(process respondsTo: #stepOverFromLevel:)
				ifTrue: [ process stepOverFromLevel: stepLevel ]
				ifFalse: [ self error: 'Step Return is unavailable for this GemStone process.' ] ]
			on: Error
			do: [ :error |
			aSession at: #status put: #terminated.
			aSession at: #resultText put: (self errorTextFor: error) ].
		^ self waitForDebugProcessToStop: process ].
	anActionSymbol = #terminate ifTrue: [
		self terminateDebugSession: aSession.
		^ self ].
	self error: 'Unknown debugger action: ', anActionSymbol asString
]

{ #category : 'private' }
SigGemStoneGateway >> performStepSelector: aSelector onProcess: aProcess level: aLevel [
	aSelector = #step: ifTrue: [ ^ aProcess perform: aSelector with: aLevel ].
	(#(#stepIntoFromLevel: #_stepIntoInFrame: #gciStepIntoFromLevel: #stepOverFromLevel: #_stepOverInFrame: #gciStepOverFromLevel:)
		includes: aSelector)
		ifTrue: [ ^ aProcess perform: aSelector with: aLevel ].
	self error: 'Unknown debugger step selector: ', aSelector asString
]

{ #category : 'private' }
SigGemStoneGateway >> restartDebugFrameLevelForSession: aSession selectedLevel: aLevel [
	| executedFrame frames workspaceSelector wrapperFrame wrapperFrames |
	frames := aSession at: #lastFrames ifAbsent: [ #() ].
	executedFrame := frames
		detect: [ :each | self stackFrameIsWorkspaceExecutedCode: each ]
		ifNone: [ nil ].
	executedFrame ifNotNil: [
		workspaceSelector := self stackFrameWorkspaceSelectorNameFor: executedFrame.
		wrapperFrames := frames
			select: [ :each |
				((each at: #level ifAbsent: [ 0 ]) > (executedFrame at: #level ifAbsent: [ 0 ]))
					and: [
						(each at: #className ifAbsent: [ '' ]) = 'SigWorkspaceEvaluator'
							and: [
								workspaceSelector isNil
									ifTrue: [ (self stackFrameWorkspaceSelectorNameFor: each) notNil ]
									ifFalse: [ (self stackFrameWorkspaceSelectorNameFor: each) = workspaceSelector ] ] ] ].
		wrapperFrame := wrapperFrames
			ifEmpty: [ nil ]
			ifNotEmpty: [
				wrapperFrames
					inject: wrapperFrames first
					into: [ :deepest :each |
						((each at: #level ifAbsent: [ 0 ]) > (deepest at: #level ifAbsent: [ 0 ]))
							ifTrue: [ each ]
							ifFalse: [ deepest ] ] ].
		wrapperFrame ifNotNil: [
			^ wrapperFrame at: #level ifAbsent: [ executedFrame at: #level ifAbsent: [ aLevel ifNil: [ 1 ] ] ] ].
		^ executedFrame at: #level ifAbsent: [ aLevel ifNil: [ 1 ] ] ].
	^ aLevel ifNil: [ 1 ]
]

{ #category : 'private' }
SigGemStoneGateway >> restartDebugProcess: aProcess atLevel: aLevel session: aSession [
	| restartLevel |
	restartLevel := self
		restartDebugFrameLevelForSession: aSession
		selectedLevel: aLevel.
	[
		((aProcess respondsTo: #trimStackToLevel:)
			or: [ aProcess respondsTo: #_trimStackToLevel: ])
			ifFalse: [ self error: 'Restart is unavailable for this GemStone process.' ].
		(aProcess respondsTo: #trimStackToLevel:)
			ifTrue: [ aProcess trimStackToLevel: restartLevel ]
			ifFalse: [ aProcess _trimStackToLevel: restartLevel ].
		[self rewindDebugProcessToStepOneIfNeeded: aProcess atLevel: restartLevel]
			on: Error
			do: [ ].
		(self restartNeedsWorkspaceReplayForSession: aSession process: aProcess)
			ifTrue: [ ^ self restartWorkspaceDebugSession: aSession ].
		aSession at: #status put: #suspended ]
		on: Error
		do: [ :error |
			aSession at: #status put: #terminated.
			aSession at: #resultText put: (self errorTextFor: error) ]
]

{ #category : 'private' }
SigGemStoneGateway >> restartNeedsWorkspaceReplayForSession: aSession process: aProcess [
	| quickStepPoint sourceString |
	aSession ifNil: [ ^ false ].
	aProcess ifNil: [ ^ false ].
	sourceString := aSession at: #sourceString ifAbsent: [ nil ].
	sourceString ifNil: [ ^ false ].
	quickStepPoint := self debugProcessQuickStepPointFor: aProcess atLevel: 1.
	^ quickStepPoint notNil and: [ quickStepPoint > 1 ]
]

{ #category : 'private' }
SigGemStoneGateway >> restartWorkspaceDebugSession: aSession [
	| completionSemaphore completionSignaled outcome sessionHolder signaled sourceString |
	aSession ifNil: [ ^ self ].
	sourceString := aSession at: #sourceString ifAbsent: [ nil ].
	sourceString ifNil: [ ^ self ].
	self terminateDebugSession: aSession.
	completionSemaphore := Semaphore new.
	completionSignaled := Array with: false.
	outcome := Dictionary new.
	sessionHolder := Array with: aSession.
	[
		| result |
		[
			result := self workspaceValueFor: sourceString ]
			on: (Halt , Error)
			do: [ :error |
				| session |
				session := sessionHolder at: 1.
				session := self
					initializeDebugSessionForProcess: Processor activeProcess
					error: error
					source: sourceString
					existingSession: session.
				sessionHolder at: 1 put: session.
				outcome at: #success put: false.
				outcome at: #sessionId put: (session at: #id).
				(completionSignaled at: 1) ifFalse: [
					completionSignaled at: 1 put: true.
					completionSemaphore signal ].
				Processor activeProcess suspend.
				error resume ].
		(sessionHolder at: 1 ifAbsent: [ nil ]) ifNotNil: [ :session |
			self markDebugSessionCompleted: session result: result ].
		outcome at: #success put: true.
		outcome at: #value put: result.
		(completionSignaled at: 1) ifFalse: [
			completionSignaled at: 1 put: true.
			completionSemaphore signal ] ] fork.
	signaled := completionSemaphore waitTimeoutMSecs: self workspaceSignalTimeoutMilliseconds.
	signaled ifFalse: [
		self terminateDebugSession: aSession.
		aSession at: #status put: #terminated.
		aSession at: #resultText put: 'Workspace restart timed out before debugger capture completed.'.
		^ self ].
	(outcome at: #success ifAbsent: [ true ]) ifFalse: [
		| process restartLevel session |
		session := sessionHolder at: 1 ifAbsent: [ nil ].
		session ifNotNil: [
			self waitForDebugProcessToStop: (self debugProcessForSession: session).
			self refreshDebugSession: session.
			process := self debugProcessForSession: session.
			process ifNotNil: [
				((self debugProcessQuickStepPointFor: process atLevel: 1) ifNil: [ 0 ]) > 1
					ifTrue: [
						restartLevel := self restartDebugFrameLevelForSession: session selectedLevel: 1.
						(process respondsTo: #trimStackToLevel:)
							ifTrue: [ process trimStackToLevel: restartLevel ]
							ifFalse: [ process _trimStackToLevel: restartLevel ].
						[self rewindDebugProcessToStepOneIfNeeded: process atLevel: restartLevel]
							on: Error
							do: [ ].
						session at: #status put: #suspended.
						self refreshDebugSession: session ] ].
			self refreshLastErrorStateFromDebugSession: session ] ]
]

{ #category : 'private' }
SigGemStoneGateway >> rewindDebugContextToStepOne: aContext [
	aContext ifNil: [ ^ self ].
	(aContext respondsTo: #jumpToStepPoint:)
		ifTrue: [ [ aContext jumpToStepPoint: 1 ] on: Error do: [ ] ].
	(aContext respondsTo: #runToStepPoint:)
		ifTrue: [ [ aContext runToStepPoint: 1 ] on: Error do: [ ] ].
	(aContext respondsTo: #jumpTo:)
		ifTrue: [ [ aContext jumpTo: 1 ] on: Error do: [ ] ]
]

{ #category : 'private' }
SigGemStoneGateway >> rewindDebugProcessToStepOneIfNeeded: aProcess atLevel: aLevel [
	| context quickStepPoint |
	quickStepPoint := self debugProcessQuickStepPointFor: aProcess atLevel: aLevel.
	(quickStepPoint isNil or: [ quickStepPoint <= 1 ]) ifTrue: [ ^ self ].
	(aProcess respondsTo: #_gsiStepAtLevel:step:)
		ifTrue: [ [ aProcess _gsiStepAtLevel: aLevel step: 1 ] on: Error do: [ ] ].
	(aProcess respondsTo: #jumpToStepPoint:)
		ifTrue: [ [ aProcess jumpToStepPoint: 1 ] on: Error do: [ ] ].
	(aProcess respondsTo: #runToStepPoint:)
		ifTrue: [ [ aProcess runToStepPoint: 1 ] on: Error do: [ ] ].
	(aProcess respondsTo: #jumpTo:)
		ifTrue: [ [ aProcess jumpTo: 1 ] on: Error do: [ ] ].
	context := self debugProcessContextFor: aProcess atLevel: aLevel.
	self rewindDebugContextToStepOne: context
]

{ #category : 'private' }
SigGemStoneGateway >> refreshDebugSession: aSession [
	| frames process terminated |
	aSession ifNil: [ ^ self ].
	process := self debugProcessForSession: aSession.
	process ifNil: [ ^ self ].
	terminated := [ process isTerminated ] on: Error do: [ true ].
	terminated ifTrue: [
		(aSession at: #status ifAbsent: [ #terminated ]) = #completed
			ifFalse: [ aSession at: #status put: #terminated ].
		^ self ].
	([ process isSuspended ] on: Error do: [ false ])
		ifTrue: [ aSession at: #status put: #suspended ]
		ifFalse: [ aSession at: #status put: #running ].
	frames := self stackFramesForProcessSafely: process toLevel: 40.
	aSession at: #lastFrames put: frames.
	aSession at: #lastWalkback put: (self formattedStackReportTextForFrames: frames)
]

{ #category : 'private' }
SigGemStoneGateway >> refreshLastErrorStateFromDebugSession: aSession [
	aSession ifNil: [ ^ self ].
	lastDebugSessionId := aSession at: #id ifAbsent: [ lastDebugSessionId ].
	lastErrorText := aSession at: #errorText ifAbsent: [ lastErrorText ].
	lastErrorFrames := aSession at: #lastFrames ifAbsent: [ #() ].
	lastErrorStackText := aSession at: #lastWalkback ifAbsent: [ lastErrorStackText ]
]

{ #category : 'private' }
SigGemStoneGateway >> sanitizeDebugSessions [
	debugSessions ifNil: [ ^ self ].
	debugSessions valuesDo: [ :each |
		self debugProcessForSession: each ].
]

{ #category : 'private' }
SigGemStoneGateway >> initializeDebugSessionForProcess: aProcess error: anError source: sourceString existingSession: aSession [
	| errorText session |
	session := aSession ifNil: [ self newDebugSessionForSource: sourceString ].
	self storeDebugProcess: aProcess inSession: session.
	session at: #status put: #running.
	session removeKey: #resultText ifAbsent: [ ].
	errorText := self errorTextFor: anError.
	session at: #errorText put: errorText.
	session at: #lastFrames put: #().
	session at: #lastWalkback put: errorText.
	^ session
]

{ #category : 'initialization' }
SigGemStoneGateway >> initialize [
	super initialize.
	debugSessions := Dictionary new.
	nextDebugSessionNumber := 0.
	lastDebugSessionId := nil.
	self clearLastErrorState
]

{ #category : 'private' }
SigGemStoneGateway >> markDebugSessionCompleted: aSession result: aResult [
	aSession ifNil: [ ^ self ].
	aSession at: #status put: #completed.
	aSession at: #resultText put: ('=> ', (self longDisplayStringFor: aResult))
]

{ #category : 'private' }
SigGemStoneGateway >> missingDebuggerSnapshot [
	^ Dictionary new
		at: #walkback put: (lastErrorStackText ifNil: [ 'No debugger snapshot captured yet.' ]);
		at: #errorText put: (lastErrorText ifNil: [ 'No gateway errors recorded.' ]);
		at: #gatewayWalkback put: (lastErrorStackText ifNil: [ 'No gateway walkback recorded.' ]);
		at: #frames put: (lastErrorFrames ifNil: [ #() ]);
		at: #debugSessionId put: nil;
		at: #isLiveSession put: false;
		at: #sessionStatusText put: 'No live debug process attached.';
		at: #canProceed put: false;
		at: #canRestart put: false;
		at: #canStepInto put: false;
		at: #canStepOver put: false;
		at: #canStepOut put: false;
		at: #canTerminate put: false;
		yourself
]

{ #category : 'private' }
SigGemStoneGateway >> newDebugSessionForSource: sourceString [
	| session sessionId |
	debugSessions ifNil: [ debugSessions := Dictionary new ].
	sessionId := nextDebugSessionNumber := nextDebugSessionNumber + 1.
	session := Dictionary new.
	session at: #id put: sessionId.
	session at: #sourceString put: sourceString.
	session at: #status put: #running.
	session at: #lastFrames put: #().
	session at: #lastWalkback put: 'No debugger snapshot captured yet.'.
	debugSessions at: sessionId put: session.
	^ session
]

{ #category : 'querying' }
SigGemStoneGateway >> rootNames [
	| names |
	names := OrderedCollection with: #bridgeRoot with: #userGlobals with: #globals.
	(self symbolDictionaryNamed: #Published ifAbsent: [ nil ]) ifNotNil: [
		names add: #published ].
	(self symbolDictionaryNamed: #SessionMethods ifAbsent: [ nil ]) ifNotNil: [
		names add: #sessionMethods ].
	^ names asArray
]

{ #category : 'querying' }
SigGemStoneGateway >> selectorsForClassNamed: aClassName protocolNamed: aProtocolName inDictionaryNamed: aSymbol [
	^ self
		withErrorHandlingDo: [
			| behavior protocol selectors |
			behavior := self classForDictionaryNamed: aSymbol classNamed: aClassName.
			behavior ifNil: [ #() ] ifNotNil: [
				protocol := aProtocolName.
				protocol ifNil: [ #() ] ifNotNil: [
					selectors := behavior organization listAtCategoryNamed: protocol asSymbol.
					((selectors collect: [ :each | each asString ])
						asSortedCollection: [ :left :right | left <= right ]) asArray ] ] ]
		ifUnavailable: [ #() ]
]

{ #category : 'querying' }
SigGemStoneGateway >> symbolListDictionaryNames [
	^ self
		withErrorHandlingDo: [
			| names |
			names := OrderedCollection new.
			self currentSession symbolList do: [ :each |
				((each isKindOf: SymbolDictionary) and: [ each name notNil ])
					ifTrue: [
						(names includes: each name) ifFalse: [ names add: each name ] ] ].
			names asArray ]
		ifUnavailable: [ #() ]
]

{ #category : 'querying' }
SigGemStoneGateway >> symbolListEntryAssociationsForDictionaryNamed: aSymbol [
	^ self
		withErrorHandlingDo: [
			| dictionary associations |
			dictionary := self symbolDictionaryNamed: aSymbol ifAbsent: [ nil ].
			dictionary ifNil: [ #() ] ifNotNil: [
				associations := dictionary associations.
				(associations asSortedCollection: [ :left :right |
					left key asString <= right key asString ]) asArray ] ]
		ifUnavailable: [ #() ]
]

{ #category : 'accessing' }
SigGemStoneGateway >> sessionMethods [
	^ self symbolDictionaryNamed: #SessionMethods ifAbsent: [ Dictionary new ]
]

{ #category : 'private' }
SigGemStoneGateway >> stackReportSafely [
	^ [ GsProcess stackReportToLevel: 40 ]
		on: Error
		do: [ :error | self errorTextFor: error ]
]

{ #category : 'private' }
SigGemStoneGateway >> stackFrameLineNumberFor: aMethod ip: anInteger [
	| ip stepPoint |
	anInteger ifNil: [ ^ nil ].
	ip := anInteger < 0
		ifTrue: [ 0 ]
		ifFalse: [ anInteger ].
	^ [
		stepPoint := aMethod _previousStepPointForIp: ip.
		(aMethod _lineNumberForStep: stepPoint) + aMethod _lineNumberBias ]
		on: Error
		do: [ nil ]
]

{ #category : 'private' }
SigGemStoneGateway >> stackFrameLineNumberForSourceText: sourceText sourceOffsets: sourceOffsets quickStepPoint: quickStepPoint [
	| line offset position rawOffset stepPoint |
	(sourceText isNil or: [ sourceText isEmpty ]) ifTrue: [ ^ nil ].
	(sourceOffsets isNil or: [ quickStepPoint isNil ]) ifTrue: [ ^ nil ].
	stepPoint := [ quickStepPoint asInteger ] on: Error do: [ nil ].
	(stepPoint isNil or: [ stepPoint <= 0 ]) ifTrue: [ ^ nil ].
	rawOffset := sourceOffsets at: stepPoint ifAbsent: [ nil ].
	rawOffset ifNil: [ ^ nil ].
	offset := [ rawOffset asInteger ] on: Error do: [ nil ].
	(offset isNil or: [ offset <= 0 or: [ offset > sourceText size ] ]) ifTrue: [ ^ nil ].
	line := 1.
	position := 1.
	[ position < offset ] whileTrue: [
		(((sourceText at: position) = Character lf)
			or: [ (sourceText at: position) = Character cr ])
				ifTrue: [ line := line + 1 ].
		position := position + 1 ].
	^ line
]

{ #category : 'private' }
SigGemStoneGateway >> stackFrameSourceTextForMethod: aMethod [
	| homeMethod source |
	homeMethod := [ aMethod homeMethod ]
		on: Error
		do: [ nil ].
	source := homeMethod ifNil: [ nil ] ifNotNil: [ self sourceTextForMethod: homeMethod ].
	(source isNil or: [ source isEmpty ]) ifTrue: [
		source := self sourceTextForMethod: aMethod ].
	^ source
]

{ #category : 'private' }
SigGemStoneGateway >> stackFrameClassNameForMethod: aMethod [
	| behavior homeMethod |
	behavior := [ aMethod inClass ]
		on: Error
		do: [ nil ].
	behavior ifNil: [
		homeMethod := [ aMethod homeMethod ]
			on: Error
			do: [ nil ].
		behavior := homeMethod
			ifNil: [ nil ]
			ifNotNil: [
				[ homeMethod inClass ]
					on: Error
					do: [ nil ] ] ].
	^ behavior ifNil: [ nil ] ifNotNil: [ behavior name asString ]
]

{ #category : 'private' }
SigGemStoneGateway >> stackFrameWorkspaceSelectorNameFor: aFrameRecord [
	| description marker selectorName start |
	aFrameRecord ifNil: [ ^ nil ].
	selectorName := (aFrameRecord at: #selectorName ifAbsent: [ nil ])
		ifNil: [ nil ]
		ifNotNil: [ :value | value asString ].
	(selectorName notNil
		and: [ selectorName ~= 'nil'
			and: [ selectorName beginsWith: 'sigWorkspace' ] ])
		ifTrue: [ ^ selectorName ].
	description := (aFrameRecord at: #description ifAbsent: [ '' ]) asString.
	marker := 'SigWorkspaceEvaluator >> '.
	start := description findString: marker startingAt: 1.
	start = 0 ifTrue: [ ^ nil ].
	selectorName := (description copyFrom: start + marker size to: description size) withBlanksTrimmed.
	(selectorName isEmpty or: [ selectorName = 'nil' ]) ifTrue: [ ^ nil ].
	^ selectorName
]

{ #category : 'private' }
SigGemStoneGateway >> stackFrameIsInfrastructureClassName: className selectorName: selectorName sourceText: sourceText [
	(#('ProcessorScheduler' 'GsProcess' 'AbstractException' 'SigGemStoneGateway') includes: className)
		ifTrue: [ ^ true ].
	(className = 'ExecBlock' and: [ selectorName = 'on:do:' ])
		ifTrue: [ ^ true ].
	^ sourceText notNil
		and: [
			(sourceText includesString: 'Processor activeProcess suspend')
				or: [ sourceText includesString: 'workspaceOutcomeFor:' ] ]
]

{ #category : 'private' }
SigGemStoneGateway >> stackFrameIsWorkspaceExecutedCode: aFrameRecord [
	| className description level lineNumber quickStepPoint selectorName sourceText |
	aFrameRecord ifNil: [ ^ false ].
	description := (aFrameRecord at: #description ifAbsent: [ '' ]) asString.
	(description beginsWith: '[] in SigWorkspaceEvaluator >> sigWorkspace')
		ifTrue: [ ^ true ].
	className := (aFrameRecord at: #className ifAbsent: [ '' ]) asString.
	selectorName := (aFrameRecord at: #selectorName ifAbsent: [ '' ]) asString.
	level := aFrameRecord at: #level ifAbsent: [ nil ].
	lineNumber := aFrameRecord at: #lineNumber ifAbsent: [ nil ].
	quickStepPoint := aFrameRecord at: #quickStepPoint ifAbsent: [ nil ].
	sourceText := aFrameRecord at: #sourceText ifAbsent: [ nil ].
	^ className = 'SigWorkspaceEvaluator'
		and: [ selectorName beginsWith: 'sigWorkspace' ]
		and: [
			(lineNumber = 1)
				or: [
					(quickStepPoint = 1)
						or: [
							level = 1
								and: [ (self workspaceExecutedCodeBodyBoundsInSource: sourceText) notNil ] ] ] ]
]

{ #category : 'private' }
SigGemStoneGateway >> stackFrameRecordFor: aFrame method: aMethod number: anInteger [
	| className description environmentId fileLine frame ip isBridge isErrorContext isInfrastructure lineNumber rubyName selectorName sourceFile sourceLineNumber sourceText |
	description := [ aMethod _descrForStack ]
		on: Error
		do: [ aMethod printString ].
	className := self stackFrameClassNameForMethod: aMethod.
	environmentId := [ aMethod environmentId ]
		on: Error
		do: [ 0 ].
	ip := aFrame size >= 2
		ifTrue: [ aFrame at: 2 ]
		ifFalse: [ nil ].
	lineNumber := self stackFrameLineNumberFor: aMethod ip: ip.
	rubyName := [ aMethod homeMethod _rubyName ]
		on: Error
		do: [ nil ].
	isBridge := environmentId ~~ 0
		and: [
			[ aMethod isRubyBridgeMethod ]
				on: Error
				do: [ false ] ].
	fileLine := environmentId ~~ 0
		ifTrue: [
			[ aMethod _fileAndLine ]
				on: Error
				do: [ nil ] ]
		ifFalse: [ nil ].
	sourceFile := (fileLine notNil and: [ fileLine size >= 1 ])
		ifTrue: [ (fileLine at: 1) asString ]
		ifFalse: [ nil ].
	sourceLineNumber := (fileLine notNil and: [ fileLine size >= 2 ])
		ifTrue: [ fileLine at: 2 ]
		ifFalse: [ nil ].
	sourceText := self stackFrameSourceTextForMethod: aMethod.
	selectorName := [ aMethod selector asString ]
		on: Error
		do: [ nil ].
	isErrorContext := selectorName notNil and: [ selectorName beginsWith: '_error' ].
	isInfrastructure := self
		stackFrameIsInfrastructureClassName: className
		selectorName: selectorName
		sourceText: sourceText.
	frame := Dictionary new.
	frame at: #level put: anInteger.
	frame at: #className put: className.
	frame at: #description put: description asString.
	frame at: #environmentId put: environmentId.
	frame at: #ipOffset put: ip.
	frame at: #isBridge put: isBridge.
	frame at: #isExecutedCode put: false.
	frame at: #isErrorContext put: isErrorContext.
	frame at: #isInfrastructure put: isInfrastructure.
	frame at: #lineNumber put: lineNumber.
	frame at: #quickStepPoint put: nil.
	frame at: #rubyName put: rubyName.
	frame at: #receiverText put: nil.
	frame at: #selectorName put: selectorName.
	frame at: #sourceFile put: sourceFile.
	frame at: #sourceOffsets put: #().
	frame at: #sourceText put: sourceText.
	frame at: #sourceLineNumber put: sourceLineNumber.
	frame at: #variables put: #().
	frame at: #text put: (self stackFrameTextForRecord: frame).
	^ frame
]

{ #category : 'private' }
SigGemStoneGateway >> normalizeWorkspaceExecutedFrameRecord: aFrameRecord [
	| adjustedOffsets bounds newQuickStep oldOffsets sourceText |
	(self stackFrameIsWorkspaceExecutedCode: aFrameRecord) ifFalse: [ ^ aFrameRecord ].
	sourceText := aFrameRecord at: #sourceText ifAbsent: [ nil ].
	sourceText ifNil: [ ^ aFrameRecord ].
	bounds := self workspaceExecutedCodeBodyBoundsInSource: sourceText.
	bounds ifNil: [ ^ aFrameRecord ].
	oldOffsets := aFrameRecord at: #sourceOffsets ifAbsent: [ #() ].
	adjustedOffsets := self
		workspaceExecutedCodeOffsetsFrom: oldOffsets
		bodyStart: (bounds at: 1)
		bodyEnd: (bounds at: 2).
	adjustedOffsets := self workspaceExecutedCodeDisplayOffsetsFrom: adjustedOffsets.
	newQuickStep := self
		workspaceExecutedCodeQuickStepPointFrom: (aFrameRecord at: #quickStepPoint ifAbsent: [ nil ])
		sourceOffsets: adjustedOffsets.
	(newQuickStep isNil and: [ (aFrameRecord at: #lineNumber ifAbsent: [ nil ]) = 1 ])
		ifTrue: [ newQuickStep := 1 ].
	aFrameRecord
		at: #isExecutedCode put: true;
		at: #sourceText put: (sourceText copyFrom: (bounds at: 1) to: (bounds at: 2));
		at: #sourceOffsets put: adjustedOffsets;
		at: #quickStepPoint put: newQuickStep.
	^ aFrameRecord
]

{ #category : 'private' }
SigGemStoneGateway >> updateStackFrameRecord: aFrameRecord fromDetailedReport: aDetailedReport fallbackMethod: aMethod ip: anInteger [
	| lineNumber quickStepPoint receiverText sourceOffsets sourceText variables |
	quickStepPoint := aDetailedReport
		ifNil: [ aFrameRecord at: #quickStepPoint ifAbsent: [ nil ] ]
		ifNotNil: [
			(aDetailedReport size >= 5)
				ifTrue: [ aDetailedReport at: 5 ]
				ifFalse: [ nil ] ].
	sourceOffsets := aDetailedReport
		ifNil: [ aFrameRecord at: #sourceOffsets ifAbsent: [ #() ] ]
		ifNotNil: [
			(aDetailedReport size >= 6)
				ifTrue: [ aDetailedReport at: 6 ]
				ifFalse: [ nil ] ].
	sourceText := aDetailedReport
		ifNil: [ nil ]
		ifNotNil: [
			(aDetailedReport size >= 9)
				ifTrue: [ aDetailedReport at: 9 ]
				ifFalse: [ nil ] ].
	sourceText := sourceText
		ifNil: [ aFrameRecord at: #sourceText ifAbsent: [ self stackFrameSourceTextForMethod: aMethod ] ]
		ifNotNil: [ sourceText asString ].
	receiverText := aDetailedReport
		ifNil: [ aFrameRecord at: #receiverText ifAbsent: [ nil ] ]
		ifNotNil: [ self debuggerReceiverTextFromDetailedReport: aDetailedReport ].
	variables := aDetailedReport
		ifNil: [ aFrameRecord at: #variables ifAbsent: [ #() ] ]
		ifNotNil: [ self debuggerVariableRecordsFromDetailedReport: aDetailedReport ].
	aFrameRecord at: #receiverText put: receiverText.
	aFrameRecord at: #quickStepPoint put: quickStepPoint.
	aFrameRecord at: #sourceOffsets put: sourceOffsets.
	aFrameRecord at: #sourceText put: sourceText.
	aFrameRecord at: #variables put: variables.
	self normalizeWorkspaceExecutedFrameRecord: aFrameRecord.
	lineNumber := self
		stackFrameLineNumberForSourceText: (aFrameRecord at: #sourceText)
		sourceOffsets: (aFrameRecord at: #sourceOffsets)
		quickStepPoint: (aFrameRecord at: #quickStepPoint).
	lineNumber ifNil: [
		lineNumber := self stackFrameLineNumberFor: aMethod ip: anInteger ].
	aFrameRecord at: #lineNumber put: lineNumber.
	aFrameRecord at: #text put: (self stackFrameTextForRecord: aFrameRecord).
	^ aFrameRecord
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceExecutedCodeBodyBoundsInSource: sourceText [
	| lastLine lines secondLine |
	sourceText ifNil: [ ^ nil ].
	lines := OrderedCollection new.
	sourceText lineIndicesDo: [ :start :endWithoutDelimiters :end |
		lines add: { start. endWithoutDelimiters. end } ].
	lines size < 4 ifTrue: [ ^ nil ].
	secondLine := sourceText
		copyFrom: (lines at: 2) first
		to: (lines at: 2) second.
	lastLine := sourceText
		copyFrom: lines last first
		to: lines last second.
	(secondLine withBlanksTrimmed = '^ [')
		ifFalse: [ ^ nil ].
	(lastLine withBlanksTrimmed = '] value')
		ifFalse: [ ^ nil ].
	^ {
		(lines at: 3) first.
		(lines at: lines size - 1) second
	}
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceExecutedCodeDisplayOffsetsFrom: sourceOffsets [
	| adjustedOffsets |
	sourceOffsets ifNil: [ ^ #(1) ].
	adjustedOffsets := sourceOffsets asOrderedCollection.
	(adjustedOffsets isEmpty or: [ adjustedOffsets first ~= 1 ])
		ifTrue: [ adjustedOffsets addFirst: 1 ].
	^ adjustedOffsets asArray
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceExecutedCodeOffsetsFrom: sourceOffsets bodyStart: bodyStart bodyEnd: bodyEnd [
	| offsets |
	sourceOffsets ifNil: [ ^ #() ].
	offsets := OrderedCollection new.
	1 to: sourceOffsets size do: [ :index |
		| adjusted rawOffset |
		rawOffset := sourceOffsets at: index ifAbsent: [ nil ].
		rawOffset ifNotNil: [
			adjusted := [ rawOffset asInteger ] on: Error do: [ nil ].
			(adjusted notNil and: [ adjusted between: bodyStart and: bodyEnd ])
				ifTrue: [ offsets add: adjusted - bodyStart + 1 ] ] ].
	^ offsets asArray
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceExecutedCodeQuickStepPointFrom: quickStepPoint sourceOffsets: sourceOffsets [
	| targetStep |
	quickStepPoint ifNil: [ ^ nil ].
	sourceOffsets ifNil: [ ^ nil ].
	targetStep := [ quickStepPoint asInteger ] on: Error do: [ nil ].
	targetStep ifNil: [ ^ nil ].
	targetStep <= 0 ifTrue: [ ^ nil ].
	^ targetStep min: sourceOffsets size
]

{ #category : 'private' }
SigGemStoneGateway >> stabilizeDebugSessionAfterAction: anActionSymbol session: aSession [
	| process status |
	(#(restart step stepInto stepOver stepOut stepReturn) includes: anActionSymbol)
		ifFalse: [ ^ self ].
	aSession ifNil: [ ^ self ].
	status := aSession at: #status ifAbsent: [ #terminated ].
	(status = #running and: [ self debugSessionCanControl: aSession ])
		ifFalse: [ ^ self ].
	process := self debugProcessForSession: aSession.
	process ifNil: [ ^ self ].
	self waitForDebugProcessToStop: process.
	self refreshDebugSession: aSession
]

{ #category : 'private' }
SigGemStoneGateway >> stackFrameTextForRecord: aFrameRecord [
	| description environmentId isBridge lineNumber rubyName sourceFile sourceLineNumber stream |
	description := aFrameRecord at: #description ifAbsent: [ 'Unknown frame' ].
	lineNumber := aFrameRecord at: #lineNumber ifAbsent: [ nil ].
	environmentId := aFrameRecord at: #environmentId ifAbsent: [ 0 ].
	rubyName := aFrameRecord at: #rubyName ifAbsent: [ nil ].
	isBridge := aFrameRecord at: #isBridge ifAbsent: [ false ].
	sourceFile := aFrameRecord at: #sourceFile ifAbsent: [ nil ].
	sourceLineNumber := aFrameRecord at: #sourceLineNumber ifAbsent: [ nil ].
	stream := WriteStream on: String new.
	stream
		nextPutAll: 'Frame ';
		nextPutAll: ((aFrameRecord at: #level ifAbsent: [ 0 ]) printString);
		nextPutAll: ': ';
		nextPutAll: description.
	lineNumber ifNotNil: [
		stream
			cr;
			nextPutAll: 'Line: ';
			nextPutAll: lineNumber printString ].
	stream
		cr;
		nextPutAll: 'Environment: ';
		nextPutAll: environmentId printString.
	rubyName ifNotNil: [
		stream
			cr;
			nextPutAll: 'Ruby name: ';
			nextPutAll: rubyName asString ].
	isBridge ifTrue: [
		stream
			cr;
			nextPutAll: 'Bridge frame: true' ].
	sourceFile ifNotNil: [
		stream
			cr;
			nextPutAll: 'Source: ';
			nextPutAll: sourceFile.
		sourceLineNumber ifNotNil: [
			stream
				nextPutAll: ':';
				nextPutAll: sourceLineNumber printString ] ].
	^ stream contents
]

{ #category : 'private' }
SigGemStoneGateway >> stackFramesSafelyToLevel: aLevel [
	^ [ self stackFramesToLevel: aLevel ]
		on: Error
	do: [ :error |
				{ Dictionary new
					at: #level put: 1;
					at: #className put: nil;
					at: #description put: (self errorTextFor: error);
					at: #environmentId put: 0;
					at: #ipOffset put: nil;
					at: #isBridge put: false;
					at: #isInfrastructure put: false;
					at: #lineNumber put: nil;
					at: #quickStepPoint put: nil;
					at: #rubyName put: nil;
					at: #receiverText put: nil;
					at: #selectorName put: nil;
					at: #sourceFile put: nil;
					at: #sourceOffsets put: #();
					at: #sourceText put: nil;
					at: #sourceLineNumber put: nil;
					at: #variables put: #();
					at: #text put: (self errorTextFor: error);
					yourself } ]
]

{ #category : 'private' }
SigGemStoneGateway >> stackFramesToLevel: aLevel [
	| frame frames method rawLevel visibleLevel |
	frames := OrderedCollection new.
	rawLevel := 2.
	visibleLevel := 1.
	[
		visibleLevel <= aLevel
			and: [ (frame := GsProcess _frameContentsAt: rawLevel) ~~ nil ] ]
		whileTrue: [
			method := frame at: 1.
			method ifNotNil: [
				frames add: (self stackFrameRecordFor: frame method: method number: visibleLevel).
				visibleLevel := visibleLevel + 1 ].
			rawLevel := rawLevel + 1 ].
	^ frames asArray
]

{ #category : 'private' }
SigGemStoneGateway >> stackFramesForProcess: aProcess toLevel: aLevel [
	| detailedReport frame frames method maximumLevel record |
	frames := OrderedCollection new.
	maximumLevel := ([ aProcess localStackDepth ] on: Error do: [ 0 ]) min: aLevel.
	1 to: maximumLevel do: [ :processLevel |
		frame := [ aProcess _frameContentsAt: processLevel ]
			on: Error
			do: [ nil ].
		frame ifNotNil: [
			method := frame at: 1.
			method ifNotNil: [
				record := self stackFrameRecordFor: frame method: method number: processLevel.
				detailedReport := [ aProcess _gsiDebuggerDetailedReportAt: processLevel ]
					on: Error
					do: [ nil ].
				frames add: (self
					updateStackFrameRecord: record
					fromDetailedReport: detailedReport
					fallbackMethod: method
					ip: (frame at: 2 ifAbsent: [ nil ])) ] ] ].
	^ frames asArray
]

{ #category : 'private' }
SigGemStoneGateway >> stackFramesForProcessSafely: aProcess toLevel: aLevel [
	^ [ self stackFramesForProcess: aProcess toLevel: aLevel ]
		on: Error
		do: [ :error |
			{ Dictionary new
				at: #level put: 1;
				at: #className put: nil;
				at: #description put: (self errorTextFor: error);
				at: #environmentId put: 0;
				at: #ipOffset put: nil;
				at: #isBridge put: false;
				at: #isInfrastructure put: false;
				at: #lineNumber put: nil;
				at: #quickStepPoint put: nil;
				at: #rubyName put: nil;
				at: #receiverText put: nil;
				at: #selectorName put: nil;
				at: #sourceFile put: nil;
				at: #sourceOffsets put: #();
				at: #sourceText put: nil;
				at: #sourceLineNumber put: nil;
				at: #variables put: #();
				at: #text put: (self errorTextFor: error);
				yourself } ]
]

{ #category : 'private' }
SigGemStoneGateway >> symbolDictionaryNamed: aSymbol ifAbsent: aBlock [
	^ [ self currentSession objectNamed: aSymbol ]
		on: Error
		do: [ :error |
			lastErrorText := self errorTextFor: error.
			lastErrorStackText := self stackReportSafely.
			lastErrorFrames := self stackFramesSafelyToLevel: 40.
			aBlock value ]
]

{ #category : 'accessing' }
SigGemStoneGateway >> sourceTextForMethod: aMethod [
	| source |
	aMethod ifNil: [ ^ nil ].
	source := [ aMethod sourceString ]
		on: Error
		do: [ nil ].
	(source isNil or: [ source asString isEmpty ]) ifTrue: [
		source := [ aMethod sourceCode ]
			on: Error
			do: [ nil ] ].
	^ source ifNil: [ nil ] ifNotNil: [ source asString ]
]

{ #category : 'accessing' }
SigGemStoneGateway >> userGlobals [
	^ self symbolDictionaryNamed: #UserGlobals ifAbsent: [ self error: 'UserGlobals unavailable' ]
]

{ #category : 'private' }
SigGemStoneGateway >> snapshotForDebugSession: aSession [
	| canControl errorText frames sessionStatus status walkback |
	aSession ifNil: [ ^ self missingDebuggerSnapshot ].
	status := aSession at: #status ifAbsent: [ #terminated ].
	canControl := self debugSessionCanControl: aSession.
	errorText := aSession at: #errorText ifAbsent: [ lastErrorText ].
	errorText ifNil: [ errorText := 'No gateway errors recorded.' ].
	walkback := aSession at: #lastWalkback ifAbsent: [ nil ].
	frames := aSession at: #lastFrames ifAbsent: [ lastErrorFrames ].
	frames ifNil: [ frames := #() ].
	sessionStatus := self debugSessionStatusTextFor: aSession.
	sessionStatus ifNil: [ sessionStatus := 'No live debug process attached.' ].
	^ Dictionary new
		at: #walkback put: (walkback ifNil: [ 'No debugger snapshot captured yet.' ]);
		at: #errorText put: errorText;
		at: #gatewayWalkback put: (walkback ifNil: [ 'No gateway walkback recorded.' ]);
		at: #frames put: frames;
		at: #debugSessionId put: (aSession at: #id);
		at: #isLiveSession put: (status = #suspended and: [ canControl ]);
		at: #sessionStatusText put: sessionStatus;
		at: #resultText put: (aSession at: #resultText ifAbsent: [ nil ]);
		at: #canProceed put: (status = #suspended and: [ canControl ]);
		at: #canRestart put: (status = #suspended and: [ canControl ]);
		at: #canStepInto put: (status = #suspended and: [ canControl ]);
		at: #canStepOver put: (status = #suspended and: [ canControl ]);
		at: #canStepOut put: (status = #suspended and: [ canControl ]);
		at: #canTerminate put: ((status = #suspended or: [ status = #running ]) and: [ canControl ]);
		yourself
]

{ #category : 'private' }
SigGemStoneGateway >> storeDebugProcess: aProcess inSession: aSession [
	| sessionId |
	aSession ifNil: [ ^ self ].
	sessionId := aSession at: #id ifAbsent: [ nil ].
	sessionId ifNil: [
		aProcess
			ifNil: [ aSession removeKey: #process ifAbsent: [ ] ]
			ifNotNil: [ aSession at: #process put: (TransientStackValue value: aProcess) ].
		^ self ].
	aProcess
		ifNil: [
			(self debugProcessRegistry removeKey: sessionId ifAbsent: [ nil ]).
			aSession removeKey: #process ifAbsent: [ ] ]
		ifNotNil: [
			self debugProcessRegistry at: sessionId put: aProcess.
			aSession at: #process put: sessionId ]
]

{ #category : 'private' }
SigGemStoneGateway >> stepDebugProcess: aProcess withSelectorChain: selectorChain level: aLevel errorMessage: anErrorMessage [
	selectorChain do: [ :selector |
		(aProcess respondsTo: selector) ifTrue: [
			^ self performStepSelector: selector onProcess: aProcess level: aLevel ] ].
	self error: anErrorMessage
]

{ #category : 'private' }
SigGemStoneGateway >> terminateDebugSession: aSession [
	| process |
	aSession ifNil: [ ^ self ].
	process := self debugProcessForSession: aSession.
	process ifNotNil: [
		([ process isTerminated ] on: Error do: [ true ])
			ifFalse: [
				[ process terminate ] on: Error do: [ ].
				self waitForDebugProcessToTerminate: process ].
		self storeDebugProcess: nil inSession: aSession ].
	aSession at: #status put: #terminated.
	aSession at: #resultText put: 'Debug process terminated.'
]

{ #category : 'private' }
SigGemStoneGateway >> waitForDebugProcessToStop: aProcess [
	| tries |
	tries := 0.
	[
		(([ aProcess isTerminated ] on: Error do: [ true ])
			or: [ [ aProcess isSuspended ] on: Error do: [ false ] ])
			or: [ tries >= 4000 ] ]
		whileFalse: [
			tries := tries + 1.
			Processor yield ]
]

{ #category : 'private' }
SigGemStoneGateway >> waitForDebugProcessToTerminate: aProcess [
	| tries |
	tries := 0.
	[
		([ aProcess isTerminated ] on: Error do: [ true ])
			or: [ tries >= 4000 ] ]
		whileFalse: [
			tries := tries + 1.
			Processor yield ].
	^ [ aProcess isTerminated ] on: Error do: [ true ]
]

{ #category : 'private' }
SigGemStoneGateway >> waitForDebugProcessToStopAfterResume: aProcess [
	| tries |
	tries := 0.
	[
		(([ aProcess isTerminated ] on: Error do: [ true ])
			or: [ ([ aProcess isSuspended ] on: Error do: [ false ]) not ])
			or: [ tries >= 200 ] ]
		whileFalse: [
			tries := tries + 1.
			Processor yield ].
	^ self waitForDebugProcessToStop: aProcess
]

{ #category : 'private' }
SigGemStoneGateway >> withErrorHandlingDo: aBlock ifUnavailable: unavailableBlock [
	^ [
		| result |
		result := aBlock value.
		self clearLastErrorState.
		result ]
		on: Error
		do: [ :error |
			lastErrorText := self errorTextFor: error.
			lastErrorStackText := self stackReportSafely.
			lastErrorFrames := self stackFramesSafelyToLevel: 40.
			unavailableBlock value ]
]

{ #category : 'actions' }
SigGemStoneGateway >> workspaceDebugIt: sourceString [
	| outcome stream |
	outcome := self workspaceOutcomeFor: sourceString.
	(outcome at: #success ifAbsent: [ false ]) ifFalse: [ ^ self workspaceErrorText ].
	stream := WriteStream on: String new.
	stream
		nextPutAll: 'Workspace code completed without signaling an error.';
		cr;
		cr;
		nextPutAll: (self inspectionStringFor: (outcome at: #value));
		cr;
		cr;
		nextPutAll: 'To capture a walkback, run code that signals an Error or Halt.'.
	^ stream contents
]

{ #category : 'actions' }
SigGemStoneGateway >> workspaceDoIt: sourceString [
	| outcome |
	outcome := self workspaceOutcomeFor: sourceString.
	(outcome at: #success ifAbsent: [ false ]) ifFalse: [ ^ self workspaceErrorText ].
	^ '=> ', (self longDisplayStringFor: (outcome at: #value))
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceErrorText [
	| stream |
	stream := WriteStream on: String new.
	stream nextPutAll: (lastErrorText ifNil: [ 'Workspace evaluation failed.' ] ifNotNil: [ lastErrorText ]).
	lastErrorStackText ifNotNil: [
		stream
			cr;
			cr;
			nextPutAll: lastErrorStackText ].
	^ stream contents
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceEvaluatorClass [
	^ SigWorkspaceEvaluator
]

{ #category : 'actions' }
SigGemStoneGateway >> workspaceInspectIt: sourceString [
	| outcome |
	outcome := self workspaceOutcomeFor: sourceString.
	(outcome at: #success ifAbsent: [ false ]) ifFalse: [ ^ self workspaceErrorText ].
	^ self inspectionStringFor: (outcome at: #value)
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceMethodSourceFor: aSelector source: sourceString [
	| body stream |
	body := sourceString ifNil: [ '' ].
	body isEmpty ifTrue: [ body := '^ nil' ].
	stream := WriteStream on: String new.
	stream nextPutAll: aSelector asString.
	body = '^ nil'
		ifTrue: [
			stream
				cr;
				nextPutAll: body ]
		ifFalse: [
			stream
				cr;
				nextPutAll: '^ [';
				cr;
				nextPutAll: body;
				cr;
				nextPutAll: '] value' ].
	^ stream contents
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceSelector [
	^ ('sigWorkspace', ((UUID new asString) copyWithout: $-)) asSymbol
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceOutcomeFor: sourceString [
	| completionSemaphore completionSignaled outcome session sessionHolder signaled |
	self clearLastErrorState.
	lastDebugSessionId := nil.
	completionSemaphore := Semaphore new.
	completionSignaled := Array with: false.
	outcome := Dictionary new.
	sessionHolder := Array with: nil.
	[
		| result |
		[
			result := self workspaceValueFor: sourceString ]
			on: (Halt , Error)
			do: [ :error |
				| session |
				session := sessionHolder at: 1.
				session := self
					initializeDebugSessionForProcess: Processor activeProcess
					error: error
					source: sourceString
					existingSession: session.
				sessionHolder at: 1 put: session.
				outcome at: #success put: false.
				outcome at: #sessionId put: (session at: #id).
				(completionSignaled at: 1) ifFalse: [
					completionSignaled at: 1 put: true.
					completionSemaphore signal ].
				Processor activeProcess suspend.
				error resume ].
		(sessionHolder at: 1 ifAbsent: [ nil ]) ifNotNil: [ :session |
			self markDebugSessionCompleted: session result: result ].
		outcome at: #success put: true.
		outcome at: #value put: result.
		(completionSignaled at: 1) ifFalse: [
			completionSignaled at: 1 put: true.
			completionSemaphore signal ] ] fork.
	signaled := completionSemaphore waitTimeoutMSecs: self workspaceSignalTimeoutMilliseconds.
	signaled ifFalse: [
		session := sessionHolder at: 1 ifAbsent: [ nil ].
		session ifNotNil: [ self terminateDebugSession: session ].
		lastErrorText := 'Workspace evaluation timed out before debugger capture completed.'.
		lastErrorStackText := nil.
		lastErrorFrames := #().
		outcome at: #success put: false.
		^ outcome ].
	(outcome at: #success ifAbsent: [ true ]) ifFalse: [
		(sessionHolder at: 1 ifAbsent: [ nil ]) ifNotNil: [ :eachSession |
			session := eachSession.
			self waitForDebugProcessToStop: (self debugProcessForSession: session).
			self refreshDebugSession: session.
			self refreshLastErrorStateFromDebugSession: session ] ].
	^ outcome
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceSignalTimeoutMilliseconds [
	^ 10000
]

{ #category : 'private' }
SigGemStoneGateway >> workspaceValueFor: sourceString [
	| evaluatorClass result selector source |
	evaluatorClass := self workspaceEvaluatorClass.
	selector := self workspaceSelector.
	source := self workspaceMethodSourceFor: selector source: sourceString.
	[
		evaluatorClass
			compileMethod: source
			category: 'workspace-temporary'.
		result := evaluatorClass new perform: selector ]
		ensure: [
			(evaluatorClass includesSelector: selector)
				ifTrue: [ evaluatorClass removeSelector: selector ] ].
	^ result
]
