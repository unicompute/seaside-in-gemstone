Class {
	#name : 'SigGemStoneGatewayTest',
	#superclass : 'TestCase',
	#instVars : [
		'gateway'
	],
	#category : 'SeasideInGemStone-Tests',
	#package : 'SeasideInGemStone-Tests'
}

{ #category : 'running' }
SigGemStoneGatewayTest >> setUp [
	super setUp.
	gateway := SigGemStoneGateway new
]

{ #category : 'private' }
SigGemStoneGatewayTest >> newSuspendedDebugSessionWithProcess: aProcess [
	| session |
	session := gateway newDebugSessionForSource: '1+1.', String lf, '1/0'.
	gateway storeDebugProcess: aProcess inSession: session.
	session at: #status put: #suspended.
	^ session
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testBridgeRootCreatesLocalDictionary [
	| root |
	root := gateway bridgeRoot.
	self assert: root notNil.
	self assert: (root isKindOf: Dictionary).
	self assert: (gateway userGlobals at: #GbsBridgeRoot ifAbsent: [ nil ]) == root
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testBrowserDictionaryNamesIncludeUserGlobalsAndGlobals [
	| names |
	names := gateway browserDictionaryNames.
	self assert: (names includes: #UserGlobals).
	self assert: (names includes: #Globals)
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testConnectionSummaryDescribesCurrentSession [
	self assert: gateway connectionSummary equals: 'current GemStone session'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testStepIntoPrefersStepIntoSelectorsOverPlainStep [
	| process session snapshot |
	process := SigDebugProcessMock new.
	process supportedSelectors: #(stepIntoFromLevel: step:).
	session := self newSuspendedDebugSessionWithProcess: process.

	snapshot := gateway
		performDebugAction: #stepInto
		forSessionId: (session at: #id)
		atLevel: 3.

	self assert: process recordedCalls asArray equals: #((stepIntoFromLevel: 3)).
	self assert: (snapshot at: #sessionStatusText) equals: 'Debug process suspended.'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testStepPrefersPlainStepSelector [
	| process session snapshot |
	process := SigDebugProcessMock new.
	process supportedSelectors: #(step: stepIntoFromLevel: _stepIntoInFrame:).
	session := self newSuspendedDebugSessionWithProcess: process.

	snapshot := gateway
		performDebugAction: #step
		forSessionId: (session at: #id)
		atLevel: 2.

	self assert: process recordedCalls asArray equals: #((step: 2)).
	self assert: (snapshot at: #sessionStatusText) equals: 'Debug process suspended.'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testStepOverPrefersStepOverSelectors [
	| process session snapshot |
	process := SigDebugProcessMock new.
	process supportedSelectors: #(stepOverFromLevel: _stepOverInFrame:).
	session := self newSuspendedDebugSessionWithProcess: process.

	snapshot := gateway
		performDebugAction: #stepOver
		forSessionId: (session at: #id)
		atLevel: 4.

	self assert: process recordedCalls asArray equals: #((stepOverFromLevel: 4)).
	self assert: (snapshot at: #sessionStatusText) equals: 'Debug process suspended.'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testCurrentStackReportReturnsText [
	self assert: gateway currentStackReport size > 0
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testCurrentStackFramesReturnStructuredFrames [
	| firstFrame frames |
	frames := gateway currentStackFrames.
	self assert: frames size > 0.
	firstFrame := frames first.
	self assert: (firstFrame includesKey: #level).
	self assert: (firstFrame includesKey: #description).
	self assert: (firstFrame includesKey: #sourceText).
	self assert: (firstFrame includesKey: #text)
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testRootNamesIncludeBridgeRootAndUserGlobals [
	self assert: (gateway rootNames includes: #bridgeRoot).
	self assert: (gateway rootNames includes: #userGlobals).
	self assert: (gateway rootNames includes: #globals)
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testSymbolListDictionaryNamesIncludeUserGlobalsAndGlobals [
	| names |
	names := gateway symbolListDictionaryNames.
	self assert: (names includes: #UserGlobals).
	self assert: (names includes: #Globals)
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDoItCapturesCompileErrors [
	gateway workspaceDoIt: '1 +'.
	self assert: gateway lastErrorText notNil
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDoItCapturesRuntimeErrorStack [
	gateway workspaceDoIt: '1 / 0'.
	self assert: gateway lastErrorText notNil.
	self assert: gateway lastErrorStackText size > 0.
	self deny: (gateway lastErrorStackText includesString: 'No debugger frames captured.').
	self assert: gateway lastErrorFrames size > 0
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDoItCreatesLiveDebuggerSnapshot [
	| snapshot |
	gateway workspaceDoIt: '1 / 0'.
	self assert: gateway lastDebugSessionId notNil.
	snapshot := gateway debuggerSnapshotForSessionId: gateway lastDebugSessionId.
	self assert: (snapshot at: #debugSessionId) equals: gateway lastDebugSessionId.
	self assert: (snapshot at: #errorText) notNil.
	self assert: (snapshot at: #frames) size > 0.
	self assert: (snapshot at: #canProceed)
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testRestartKeepsDebuggerSessionControllable [
	| snapshot |
	gateway workspaceDoIt: '1 / 0'.
	snapshot := gateway
		performDebugAction: #restart
		forSessionId: gateway lastDebugSessionId
		atLevel: 1.

	self assert: (snapshot at: #canProceed).
	self assert: (snapshot at: #canRestart).
	self assert: (snapshot at: #canStepInto).
	self assert: (snapshot at: #canStepOver).
	self assert: (snapshot at: #canStepOut).
	self assert: (snapshot at: #sessionStatusText) equals: 'Debug process suspended.'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testRestartResetsExecutedCodeFrameToStepOne [
	| executedFrame snapshot |
	gateway workspaceDoIt: '1 / 0'.
	executedFrame := gateway lastErrorFrames
		detect: [ :each | gateway stackFrameIsWorkspaceExecutedCode: each ]
		ifNone: [ nil ].
	self assert: executedFrame notNil.

	snapshot := gateway
		performDebugAction: #restart
		forSessionId: gateway lastDebugSessionId
		atLevel: (executedFrame at: #level).

	executedFrame := (snapshot at: #frames)
		detect: [ :each | gateway stackFrameIsWorkspaceExecutedCode: each ]
		ifNone: [ nil ].
	self assert: executedFrame notNil.
	self assert: (executedFrame at: #quickStepPoint ifAbsent: [ nil ]) equals: 1.
	self assert: (executedFrame at: #lineNumber ifAbsent: [ nil ]) equals: 1
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testRestartAfterStepRewindsExecutedCodeFrameToStepOne [
	| executedFrame snapshot |
	gateway workspaceDoIt: '1+1.', String lf, '1/0'.
	gateway
		performDebugAction: #restart
		forSessionId: gateway lastDebugSessionId
		atLevel: 1.
	gateway
		performDebugAction: #step
		forSessionId: gateway lastDebugSessionId
		atLevel: 1.
	snapshot := gateway
		performDebugAction: #restart
		forSessionId: gateway lastDebugSessionId
		atLevel: 1.

	executedFrame := (snapshot at: #frames)
		detect: [ :each | gateway stackFrameIsWorkspaceExecutedCode: each ]
		ifNone: [ nil ].
	self assert: executedFrame notNil.
	self assert: (executedFrame at: #quickStepPoint ifAbsent: [ nil ]) equals: 1.
	self assert: (executedFrame at: #lineNumber ifAbsent: [ nil ]) equals: 1
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testUpdateStackFrameRecordNormalizesRestartedWorkspaceFrameWithoutDetailedReport [
	| frame |
	frame := Dictionary new
		at: #className put: 'SigWorkspaceEvaluator';
		at: #description put: 'SigWorkspaceEvaluator >> sigWorkspaceABC123';
		at: #isExecutedCode put: false;
		at: #level put: 1;
		at: #lineNumber put: 1;
		at: #quickStepPoint put: nil;
		at: #receiverText put: nil;
		at: #selectorName put: 'sigWorkspaceABC123';
		at: #sourceOffsets put: #();
		at: #sourceText put: 'sigWorkspaceABC123', String lf, '^ [', String lf, '1+1.', String lf, '1/0', String lf, '] value';
		at: #variables put: #();
		yourself.

	gateway
		updateStackFrameRecord: frame
		fromDetailedReport: nil
		fallbackMethod: nil
		ip: nil.

	self assert: (frame at: #isExecutedCode) equals: true.
	self assert: (frame at: #sourceText) equals: '1+1.', String lf, '1/0'.
	self assert: (frame at: #sourceOffsets) equals: #(1).
	self assert: (frame at: #quickStepPoint) equals: 1.
	self assert: (frame at: #lineNumber) equals: 1
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceExecutedCodeDetectionUsesRestartStepPoint [
	| frame |
	frame := Dictionary new
		at: #className put: 'SigWorkspaceEvaluator';
		at: #description put: 'SigWorkspaceEvaluator >> sigWorkspaceABC123';
		at: #lineNumber put: nil;
		at: #quickStepPoint put: 1;
		at: #selectorName put: 'sigWorkspaceABC123';
		yourself.

	self assert: (gateway stackFrameIsWorkspaceExecutedCode: frame) equals: true
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceExecutedCodeDetectionUsesTopLevelWorkspaceFrameAfterStep [
	| frame |
	frame := Dictionary new
		at: #className put: 'SigWorkspaceEvaluator';
		at: #description put: 'SigWorkspaceEvaluator >> sigWorkspaceABC123';
		at: #level put: 1;
		at: #lineNumber put: 5;
		at: #quickStepPoint put: 2;
		at: #selectorName put: 'sigWorkspaceABC123';
		at: #sourceText put: 'sigWorkspaceABC123', String lf, '^ [', String lf, '1+1.', String lf, '1/0', String lf, '] value';
		yourself.

	self assert: (gateway stackFrameIsWorkspaceExecutedCode: frame) equals: true
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceExecutedCodeDetectionRejectsNestedWorkspaceWrapperFrame [
	| frame |
	frame := Dictionary new
		at: #className put: 'SigWorkspaceEvaluator';
		at: #description put: 'SigWorkspaceEvaluator >> sigWorkspaceABC123';
		at: #level put: 2;
		at: #lineNumber put: 5;
		at: #quickStepPoint put: 2;
		at: #selectorName put: 'sigWorkspaceABC123';
		at: #sourceText put: 'sigWorkspaceABC123', String lf, '^ [', String lf, '1+1.', String lf, '1/0', String lf, '] value';
		yourself.

	self deny: (gateway stackFrameIsWorkspaceExecutedCode: frame)
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testNormalizeWorkspaceExecutedFrameRecordUsesUserSourceCoordinates [
	| frame lineNumber |
	frame := Dictionary new
		at: #description put: '[] in SigWorkspaceEvaluator >> sigWorkspaceABC123';
		at: #quickStepPoint put: 6;
		at: #sourceOffsets put: #(nil nil nil 49 51 56 58);
		at: #sourceText put: 'sigWorkspaceABC123', String lf, '^ [', String lf, '1+1.', String lf, '1/0', String lf, '] value';
		yourself.

	gateway normalizeWorkspaceExecutedFrameRecord: frame.
	lineNumber := gateway
		stackFrameLineNumberForSourceText: (frame at: #sourceText)
		sourceOffsets: (frame at: #sourceOffsets)
		quickStepPoint: (frame at: #quickStepPoint).

	self assert: (frame at: #sourceText) equals: '1+1.', String lf, '1/0'.
	self assert: (frame at: #quickStepPoint) equals: 3.
	self assert: (frame at: #sourceOffsets) equals: #(1 2 7).
	self assert: lineNumber equals: 2
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testTerminateClearsDebugProcessFromSessionRegistry [
	| registry session snapshot |
	gateway workspaceDoIt: '1 / 0'.
	session := gateway debugSessionAt: gateway lastDebugSessionId ifAbsent: [ nil ].
	self assert: session notNil.

	snapshot := gateway
		performDebugAction: #terminate
		forSessionId: gateway lastDebugSessionId
		atLevel: 1.

	self assert: (snapshot at: #sessionStatusText) equals: 'Debug process terminated.'.
	self assert: (session at: #process ifAbsent: [ nil ]) isNil.
	registry := gateway debugProcessRegistry.
	self assert: (registry at: (session at: #id) ifAbsent: [ nil ]) isNil
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testStackFrameLineNumberForSourceTextUsesStepPointOffsets [
	| lineNumber source |
	source := 'line one', String lf, 'line two', String lf, 'line three'.
	lineNumber := gateway
		stackFrameLineNumberForSourceText: source
		sourceOffsets: #(1 10 19)
		quickStepPoint: 2.

	self assert: lineNumber equals: 2
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDoItStoresDebugProcessInSessionRegistry [
	| registry session storedProcess |
	gateway workspaceDoIt: '1 / 0'.
	session := gateway debugSessionAt: gateway lastDebugSessionId ifAbsent: [ nil ].
	self assert: session notNil.
	storedProcess := session at: #process ifAbsent: [ nil ].
	self assert: storedProcess notNil.
	self assert: storedProcess equals: (session at: #id).
	registry := gateway debugProcessRegistry.
	self assert: (registry at: storedProcess ifAbsent: [ nil ]) notNil
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDoItEvaluatesAfterTerminatingPreviousDebugSession [
	| result |
	gateway workspaceDoIt: '1 / 0'.
	gateway
		performDebugAction: #terminate
		forSessionId: gateway lastDebugSessionId
		atLevel: 1.

	result := gateway workspaceDoIt: '1 + 2'.

	self assert: result equals: '=> 3'.
	self assert: gateway lastErrorText isNil.
	self assert: gateway lastDebugSessionId isNil
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDoItEvaluatesExpression [
	| result |
	result := gateway workspaceDoIt: '1 + 2'.
	self assert: result equals: '=> 3'.
	self assert: gateway lastErrorText isNil
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceInspectIncludesClassName [
	| result |
	result := gateway workspaceInspectIt: '1 + 2'.
	self assert: (result includesString: 'Class: SmallInteger').
	self assert: (result includesString: 'Print String:')
]
