Class {
	#name : 'SigDebugProcessMock',
	#superclass : 'Object',
	#instVars : [
		'recordedCalls',
		'supportedSelectors',
		'suspended',
		'terminated'
	],
	#category : 'SeasideInGemStone-Tests',
	#package : 'SeasideInGemStone-Tests'
}

{ #category : 'initialization' }
SigDebugProcessMock >> initialize [
	super initialize.
	recordedCalls := OrderedCollection new.
	supportedSelectors := Set new.
	suspended := true.
	terminated := false
]

{ #category : 'testing' }
SigDebugProcessMock >> isSuspended [
	^ suspended
]

{ #category : 'testing' }
SigDebugProcessMock >> isTerminated [
	^ terminated
]

{ #category : 'actions' }
SigDebugProcessMock >> step: aLevel [
	recordedCalls add: { #step:. aLevel }.
	suspended := true
]

{ #category : 'actions' }
SigDebugProcessMock >> stepIntoFromLevel: aLevel [
	recordedCalls add: { #stepIntoFromLevel:. aLevel }.
	suspended := true
]

{ #category : 'actions' }
SigDebugProcessMock >> _stepIntoInFrame: aLevel [
	recordedCalls add: { #_stepIntoInFrame:. aLevel }.
	suspended := true
]

{ #category : 'actions' }
SigDebugProcessMock >> gciStepIntoFromLevel: aLevel [
	recordedCalls add: { #gciStepIntoFromLevel:. aLevel }.
	suspended := true
]

{ #category : 'actions' }
SigDebugProcessMock >> stepOverFromLevel: aLevel [
	recordedCalls add: { #stepOverFromLevel:. aLevel }.
	suspended := true
]

{ #category : 'actions' }
SigDebugProcessMock >> _stepOverInFrame: aLevel [
	recordedCalls add: { #_stepOverInFrame:. aLevel }.
	suspended := true
]

{ #category : 'actions' }
SigDebugProcessMock >> gciStepOverFromLevel: aLevel [
	recordedCalls add: { #gciStepOverFromLevel:. aLevel }.
	suspended := true
]

{ #category : 'accessing' }
SigDebugProcessMock >> recordedCalls [
	^ recordedCalls
]

{ #category : 'testing' }
SigDebugProcessMock >> respondsTo: aSelector [
	^ (supportedSelectors includes: aSelector)
		or: [ super respondsTo: aSelector ]
]

{ #category : 'accessing' }
SigDebugProcessMock >> supportedSelectors: aCollection [
	supportedSelectors := aCollection asSet
]

{ #category : 'actions' }
SigDebugProcessMock >> terminate [
	terminated := true.
	suspended := false
]
