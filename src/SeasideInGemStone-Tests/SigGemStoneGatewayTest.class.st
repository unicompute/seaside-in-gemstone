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
	session markSuspended.
	^ session
]

{ #category : 'private' }
SigGemStoneGatewayTest >> assertExecutedCodeFrameIn: aSnapshot quickStepPoint: expectedStep lineNumber: expectedLine [
	| executedFrame |
	executedFrame := (aSnapshot at: #frames)
		detect: [ :each | gateway stackFrameIsWorkspaceExecutedCode: each ]
		ifNone: [ nil ].
	self assert: executedFrame notNil.
	self assert: (executedFrame at: #quickStepPoint ifAbsent: [ nil ]) equals: expectedStep.
	self assert: (executedFrame at: #lineNumber ifAbsent: [ nil ]) equals: expectedLine
]

{ #category : 'private' }
SigGemStoneGatewayTest >> assertRestartActionSequence: actions expectedExecutedLocations: expectedLocations onSource: sourceString [
	| snapshot |
	self assert: actions size equals: expectedLocations size.
	gateway workspaceDoIt: sourceString.
	actions with: expectedLocations do: [ :action :expectedLocation |
		snapshot := gateway
			performDebugAction: action
			forSessionId: gateway lastDebugSessionId
			atLevel: 1.
		self
			assertExecutedCodeFrameIn: snapshot
			quickStepPoint: expectedLocation first
			lineNumber: expectedLocation second ].
	^ snapshot
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
		forSessionId: session sessionId
		atLevel: 3.

	self assert: process recordedCalls asArray equals: #((stepIntoFromLevel: 1)).
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
		forSessionId: session sessionId
		atLevel: 2.

	self assert: process recordedCalls asArray equals: #((step: 1)).
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
		forSessionId: session sessionId
		atLevel: 4.

	self assert: process recordedCalls asArray equals: #((stepOverFromLevel: 1)).
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
SigGemStoneGatewayTest >> testRestartDebugFrameLevelPrefersWorkspaceWrapperFrame [
	| level session |
	session := SigDebugSession forSource: '' id: 0.
	session lastFrames: {
		(Dictionary new
			at: #level put: 1;
			at: #className put: 'SigWorkspaceEvaluator';
			at: #selectorName put: 'sigWorkspaceABC123';
			at: #quickStepPoint put: 2;
			at: #sourceText put: '1+1.', String lf, '1/0';
			yourself).
		(Dictionary new
			at: #level put: 2;
			at: #className put: 'SigWorkspaceEvaluator';
			at: #selectorName put: 'sigWorkspaceABC123';
			at: #quickStepPoint put: 2;
			at: #sourceText put: 'sigWorkspaceABC123', String lf, '^ [', String lf, '1+1.', String lf, '1/0', String lf, '] value';
			yourself) }.

	level := gateway restartDebugFrameLevelForSession: session selectedLevel: 1.

	self assert: level equals: 2
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testRestartDebugFrameLevelPrefersDeepestWorkspaceWrapperFrame [
	| level session |
	session := SigDebugSession forSource: '' id: 0.
	session lastFrames: {
		(Dictionary new
			at: #level put: 1;
			at: #className put: 'SigWorkspaceEvaluator';
			at: #description put: '[] in SigWorkspaceEvaluator >> sigWorkspaceABC123';
			at: #selectorName put: 'nil';
			at: #quickStepPoint put: 4;
			at: #sourceText put: '1+1.', String lf, '2+2.', String lf, '1/0';
			at: #isExecutedCode put: true;
			yourself).
		(Dictionary new
			at: #level put: 2;
			at: #description put: 'SigWorkspaceEvaluator >> sigWorkspaceABC123';
			at: #className put: 'SigWorkspaceEvaluator';
			at: #selectorName put: 'sigWorkspaceABC123';
			at: #quickStepPoint put: 2;
			at: #sourceText put: 'sigWorkspaceABC123', String lf, '^ [', String lf, '1+1.', String lf, '2+2.', String lf, '1/0', String lf, '] value';
			yourself).
		(Dictionary new
			at: #level put: 3;
			at: #description put: 'SigWorkspaceEvaluator >> sigWorkspaceABC123';
			at: #className put: 'SigWorkspaceEvaluator';
			at: #selectorName put: 'sigWorkspaceABC123';
			at: #quickStepPoint put: 2;
			at: #sourceText put: 'sigWorkspaceABC123', String lf, '^ [', String lf, '1+1.', String lf, '2+2.', String lf, '1/0', String lf, '] value';
			yourself) }.

	level := gateway restartDebugFrameLevelForSession: session selectedLevel: 1.

	self assert: level equals: 3
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testRestartDebugFrameLevelMatchesWorkspaceSelectorFromExecutedFrameDescription [
	| level session |
	session := SigDebugSession forSource: '' id: 0.
	session lastFrames: {
		(Dictionary new
			at: #level put: 1;
			at: #description put: '[] in SigWorkspaceEvaluator >> sigWorkspaceXYZ987';
			at: #className put: 'SigWorkspaceEvaluator';
			at: #selectorName put: 'nil';
			at: #lineNumber put: 3;
			at: #quickStepPoint put: 4;
			at: #sourceText put: '1+1.', String lf, '2+2.', String lf, '1/0';
			at: #isExecutedCode put: true;
			yourself).
		(Dictionary new
			at: #level put: 2;
			at: #description put: 'SigWorkspaceEvaluator >> sigWorkspaceXYZ987';
			at: #className put: 'SigWorkspaceEvaluator';
			at: #selectorName put: 'sigWorkspaceXYZ987';
			at: #quickStepPoint put: 2;
			at: #sourceText put: 'sigWorkspaceXYZ987', String lf, '^ [', String lf, '1+1.', String lf, '2+2.', String lf, '1/0', String lf, '] value';
			yourself) }.

	level := gateway restartDebugFrameLevelForSession: session selectedLevel: 1.

	self assert: level equals: 2
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
SigGemStoneGatewayTest >> testRestartAfterMultipleStepsRewindsExecutedCodeFrameToStepOne [
	| executedFrame snapshot |
	gateway workspaceDoIt: '1+1.', String lf, '2+2.', String lf, '1/0'.
	gateway
		performDebugAction: #restart
		forSessionId: gateway lastDebugSessionId
		atLevel: 1.
	gateway
		performDebugAction: #step
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
SigGemStoneGatewayTest >> testRepeatedRestartSequenceOnFourLineWorkspace [
	| snapshot |
	snapshot := self
		assertRestartActionSequence: #(restart step step step restart restart step restart)
		expectedExecutedLocations: #((1 1) (2 1) (4 3) (5 4) (1 1) (1 1) (2 1) (1 1))
		onSource: '1+1.', String lf, '2+2.', String lf, '3+3.', String lf, '1/0'.

	self assert: (snapshot at: #sessionStatusText) equals: 'Debug process suspended.'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testRepeatedRestartSequenceOnThreeLineWorkspace [
	| snapshot |
	snapshot := self
		assertRestartActionSequence: #(restart restart step step restart restart step restart)
		expectedExecutedLocations: #((1 1) (1 1) (2 1) (4 3) (1 1) (1 1) (2 1) (1 1))
		onSource: '1+1.', String lf, '2+2.', String lf, '1/0'.

	self assert: (snapshot at: #sessionStatusText) equals: 'Debug process suspended.'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testRepeatedRestartSequenceOnTwoLineWorkspace [
	| snapshot |
	snapshot := self
		assertRestartActionSequence: #(restart restart step restart restart step restart restart)
		expectedExecutedLocations: #((1 1) (1 1) (2 1) (1 1) (1 1) (2 1) (1 1) (1 1))
		onSource: '1+1.', String lf, '1/0'.

	self assert: (snapshot at: #sessionStatusText) equals: 'Debug process suspended.'
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
	self assert: session process isNil.
	registry := gateway debugProcessRegistry.
	self assert: (registry at: session sessionId ifAbsent: [ nil ]) isNil
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
	storedProcess := session process.
	self assert: storedProcess notNil.
	self assert: storedProcess equals: session sessionId.
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
SigGemStoneGatewayTest >> testWorkspaceDebugItCreatesLiveDebuggerSnapshotForSuccessfulEvaluation [
	| result snapshot |
	result := gateway workspaceDebugIt: '1 + 2'.

	self assert: result equals: 'Workspace debug ready. Use the debugger controls to step through the code.'.
	self assert: gateway lastDebugSessionId notNil.
	snapshot := gateway debuggerSnapshotForSessionId: gateway lastDebugSessionId.
	self assert: (snapshot at: #debugSessionId) equals: gateway lastDebugSessionId.
	self assert: (snapshot at: #canRestart).
	self assert: (snapshot at: #canStepInto).
	self assert: (snapshot at: #sessionStatusText) equals: 'Debug process suspended.'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDebugItStartsAtUserSourceWithoutRestart [
	| executedFrame snapshot |
	gateway workspaceDebugIt: '1 + 2.', String lf, '3 + 4'.
	snapshot := gateway debuggerSnapshotForSessionId: gateway lastDebugSessionId.

	executedFrame := (snapshot at: #frames)
		detect: [ :each | gateway stackFrameIsWorkspaceExecutedCode: each ]
		ifNone: [ nil ].
	self assert: executedFrame notNil.
	self assert: (executedFrame at: #lineNumber ifAbsent: [ nil ]) equals: 1.
	self deny: ((snapshot at: #frames) anySatisfy: [ :each |
		(each at: #selectorName ifAbsent: [ '' ]) = 'sigSuspendForDebug' ])
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDebugItDoesNotEvaluateFailingCodeBeforeFirstStep [
	| errorText executedFrame result snapshot |
	[
		result := gateway workspaceDebugIt: '1 / 0'.

		self assert: result equals: 'Workspace debug ready. Use the debugger controls to step through the code.'.
		errorText := gateway lastErrorText ifNil: [ '' ].
		self deny: (errorText includesString: 'ZeroDivide').
		self deny: (errorText includesString: 'divide 1 by zero').
		snapshot := gateway debuggerSnapshotForSessionId: gateway lastDebugSessionId.
		self assert: (snapshot at: #sessionStatusText) equals: 'Debug process suspended.'.
		executedFrame := (snapshot at: #frames)
			detect: [ :each | gateway stackFrameIsWorkspaceExecutedCode: each ]
			ifNone: [ nil ].
		self assert: executedFrame notNil.
		self assert: (executedFrame at: #lineNumber ifAbsent: [ nil ]) equals: 1 ]
		ensure: [
			gateway lastDebugSessionId ifNotNil: [ :sessionId |
				gateway
					performDebugAction: #terminate
					forSessionId: sessionId
					atLevel: 1 ] ]
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDebugItStepsThroughMultilineSourceBeforeError [
	| errorText executedFrame lineNumbers sessionId snapshot source |
	source := '1 + 2.', String lf, String lf, '1+1. 4*4. 6-1.', String lf, String lf, '1/0'.
	[
		gateway workspaceDebugIt: source.
		sessionId := gateway lastDebugSessionId.
		snapshot := gateway debuggerSnapshotForSessionId: sessionId.
		executedFrame := (snapshot at: #frames)
			detect: [ :each | gateway stackFrameIsWorkspaceExecutedCode: each ]
			ifNone: [ nil ].
		self assert: executedFrame notNil.
		self assert: (executedFrame at: #lineNumber ifAbsent: [ nil ]) equals: 1.
		errorText := gateway lastErrorText ifNil: [ '' ].
		self deny: (errorText includesString: 'ZeroDivide').

		lineNumbers := OrderedCollection new.
		1 to: 4 do: [ :index |
			snapshot := gateway
				performDebugAction: #step
				forSessionId: sessionId
				atLevel: (executedFrame at: #level ifAbsent: [ 1 ]).
			executedFrame := (snapshot at: #frames)
				detect: [ :each | gateway stackFrameIsWorkspaceExecutedCode: each ]
				ifNone: [ nil ].
			self assert: executedFrame notNil.
			lineNumbers add: (executedFrame at: #lineNumber ifAbsent: [ nil ]) ].
		self assert: lineNumbers asArray equals: #(3 3 3 5).
		errorText := gateway lastErrorText ifNil: [ '' ].
		self deny: (errorText includesString: 'ZeroDivide').

		snapshot := gateway
			performDebugAction: #step
			forSessionId: sessionId
			atLevel: (executedFrame at: #level ifAbsent: [ 1 ]).
		errorText := snapshot at: #errorText ifAbsent: [ '' ].
		self assert: (errorText includesString: 'ZeroDivide') ]
		ensure: [
			sessionId ifNotNil: [
				gateway
					performDebugAction: #terminate
					forSessionId: sessionId
					atLevel: 1 ] ]
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceDebugMethodSourceKeepsHookOutsideUserBlock [
	| source |
	source := gateway
		workspaceDebugMethodSourceFor: #sigWorkspaceABC123
		source: '1 + 2.', String lf, '3 + 4'.

	self assert: source equals:
		'sigWorkspaceABC123', String lf,
		gateway workspaceDebugHookSourceLine, String lf,
		'^ [', String lf,
		'1 + 2.', String lf,
		'3 + 4', String lf,
		'] value'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceExecutedCodeBodyBoundsAcceptsHookOutsideBlock [
	| bounds source |
	source :=
		'sigWorkspaceABC123', String lf,
		gateway workspaceDebugHookSourceLine, String lf,
		'^ [', String lf,
		'1 + 2.', String lf,
		'3 + 4', String lf,
		'] value'.

	bounds := gateway workspaceExecutedCodeBodyBoundsInSource: source.

	self assert: (source copyFrom: bounds first to: bounds second)
		equals: '1 + 2.', String lf, '3 + 4'
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceInitialDebugFrameLevelUsesWrapperBelowInitialHook [
	| level session |
	session := SigDebugSession forSource: '' id: 9876.
	[
		gateway storeWorkspaceDebugSelector: #sigWorkspaceABC123 inSession: session.
		session lastFrames: {
			(Dictionary new
				at: #level put: 5;
				at: #className put: 'SigWorkspaceEvaluator';
				at: #selectorName put: 'sigSuspendForDebug';
				yourself).
			(Dictionary new
				at: #level put: 6;
				at: #className put: 'SigWorkspaceEvaluator';
				at: #selectorName put: 'sigWorkspaceABC123';
				at: #description put: 'SigWorkspaceEvaluator >> sigWorkspaceABC123';
				yourself).
			(Dictionary new
				at: #level put: 7;
				at: #className put: 'SigWorkspaceEvaluator';
				at: #selectorName put: 'sigWorkspaceOther';
				at: #description put: 'SigWorkspaceEvaluator >> sigWorkspaceOther';
				yourself) }.

		level := gateway workspaceInitialDebugFrameLevelForSession: session.

		self assert: level equals: 6 ]
		ensure: [ gateway storeWorkspaceDebugSelector: nil inSession: session ]
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceExecutedCodeQuickStepAfterBodyStaysAtSourceStart [
	| quickStep |
	quickStep := gateway
		workspaceExecutedCodeQuickStepPointFrom: 2
		rawSourceOffsets: #(1 105 77 84 89)
		bodyStart: 77
		bodyEnd: 89.

	self assert: quickStep equals: 1
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceExecutedFrameAdvancesWhenActiveSendIsAboveIt [
	| adjustedFrame frames source |
	source := '1 + 2.', String lf, String lf, '5*5. 6+1. 6-2.', String lf, String lf, '1/0'.
	frames := {
		(Dictionary new
			at: #level put: 1;
			at: #className put: 'SmallInteger';
			at: #selectorName put: '/';
			at: #description put: 'SmallInteger >> /';
			at: #isBridge put: false;
			at: #isInfrastructure put: false;
			yourself).
		(Dictionary new
			at: #level put: 2;
			at: #className put: 'SigWorkspaceEvaluator';
			at: #selectorName put: 'nil';
			at: #description put: '[] in SigWorkspaceEvaluator >> sigWorkspaceABC123';
			at: #quickStepPoint put: 5;
			at: #lineNumber put: 3;
			at: #sourceOffsets put: #(1 3 10 15 20 26);
			at: #sourceText put: source;
			at: #isExecutedCode put: true;
			yourself) }.

	adjustedFrame := (gateway adjustWorkspaceExecutedFrameForActiveSendIn: frames) second.

	self assert: (adjustedFrame at: #quickStepPoint) equals: 6.
	self assert: (adjustedFrame at: #lineNumber) equals: 5
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceInspectIncludesClassName [
	| result |
	result := gateway workspaceInspectIt: '1 + 2'.
	self assert: (result includesString: 'Class: SmallInteger').
	self assert: (result includesString: 'Print String:')
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testInspectionRowsCarryInspectableObjects [
	| rows |
	rows := gateway inspectionRowsFor: #(1 2 3).

	self assert: rows size equals: 3.
	self assert: (rows first includesKey: #object).
	self assert: (rows first at: #object) equals: 1
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testInspectionRowsForClassFallbackToSummaryRows [
	| rows |
	rows := gateway inspectionRowsFor: Object.

	self assert: rows isEmpty not.
	self assert: (rows first at: #key) equals: 'Name'.
	self assert: (rows first includesKey: #object)
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testSigWorkspaceEvaluatorEvaluatesExpression [
	self assert: (SigWorkspaceEvaluator evaluate: '1 + 2') equals: 3
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testSigWorkspaceEvaluatorCleansUpTemporaryMethod [
	| selectorsBefore selectorsAfter |
	selectorsBefore := SigWorkspaceEvaluator selectors asSet.
	SigWorkspaceEvaluator evaluate: '42'.
	selectorsAfter := SigWorkspaceEvaluator selectors asSet.
	self assert: selectorsBefore equals: selectorsAfter
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testSigWorkspaceEvaluatorHandlesNilSource [
	self assert: (SigWorkspaceEvaluator evaluate: nil) isNil
]

{ #category : 'tests' }
SigGemStoneGatewayTest >> testWorkspaceValueForDelegatesToSigWorkspaceEvaluator [
	self assert: (gateway workspaceValueFor: '3 * 4') equals: 12
]
