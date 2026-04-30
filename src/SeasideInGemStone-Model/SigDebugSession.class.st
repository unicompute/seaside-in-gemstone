Class {
	#name : 'SigDebugSession',
	#superclass : 'Object',
	#instVars : [
		'sessionId',
		'sourceString',
		'status',
		'errorText',
		'resultText',
		'lastFrames',
		'lastWalkback',
		'process'
	],
	#category : 'SeasideInGemStone-Model',
	#package : 'SeasideInGemStone-Model'
}

{ #category : 'instance creation' }
SigDebugSession class >> forSource: aSourceString id: anId [
	^ self new
		initializeWithSource: aSourceString id: anId;
		yourself
]

{ #category : 'initialization' }
SigDebugSession >> initializeWithSource: aSourceString id: anId [
	sessionId := anId.
	sourceString := aSourceString.
	status := #running.
	lastFrames := #().
	lastWalkback := 'No debugger snapshot captured yet.'
]

{ #category : 'accessing' }
SigDebugSession >> sessionId [
	^ sessionId
]

{ #category : 'accessing' }
SigDebugSession >> sourceString [
	^ sourceString
]

{ #category : 'accessing' }
SigDebugSession >> status [
	^ status ifNil: [ #terminated ]
]

{ #category : 'accessing' }
SigDebugSession >> status: aSymbol [
	status := aSymbol
]

{ #category : 'testing' }
SigDebugSession >> isRunning [
	^ self status = #running
]

{ #category : 'testing' }
SigDebugSession >> isSuspended [
	^ self status = #suspended
]

{ #category : 'testing' }
SigDebugSession >> isTerminated [
	^ self status = #terminated
]

{ #category : 'testing' }
SigDebugSession >> isCompleted [
	^ self status = #completed
]

{ #category : 'accessing' }
SigDebugSession >> errorText [
	^ errorText
]

{ #category : 'accessing' }
SigDebugSession >> errorText: aString [
	errorText := aString
]

{ #category : 'accessing' }
SigDebugSession >> resultText [
	^ resultText
]

{ #category : 'accessing' }
SigDebugSession >> resultText: aString [
	resultText := aString
]

{ #category : 'accessing' }
SigDebugSession >> lastFrames [
	^ lastFrames ifNil: [ #() ]
]

{ #category : 'accessing' }
SigDebugSession >> lastFrames: anArray [
	lastFrames := anArray
]

{ #category : 'accessing' }
SigDebugSession >> lastWalkback [
	^ lastWalkback
]

{ #category : 'accessing' }
SigDebugSession >> lastWalkback: aString [
	lastWalkback := aString
]

{ #category : 'accessing' }
SigDebugSession >> process [
	^ process
]

{ #category : 'accessing' }
SigDebugSession >> process: anObject [
	process := anObject
]

{ #category : 'actions' }
SigDebugSession >> markRunning [
	status := #running.
	resultText := nil
]

{ #category : 'actions' }
SigDebugSession >> markSuspended [
	status := #suspended
]

{ #category : 'actions' }
SigDebugSession >> markTerminated [
	status := #terminated
]

{ #category : 'actions' }
SigDebugSession >> markTerminatedWithMessage: aString [
	status := #terminated.
	resultText := aString
]

{ #category : 'actions' }
SigDebugSession >> markCompletedWithResult: aResult displayString: aString [
	status := #completed.
	resultText := aString
]

{ #category : 'actions' }
SigDebugSession >> markErrored: anErrorText [
	errorText := anErrorText.
	lastFrames := #().
	lastWalkback := anErrorText
]
