Class {
	#name : 'SigWorkspaceEvaluator',
	#superclass : 'Object',
	#category : 'SeasideInGemStone-Model',
	#package : 'SeasideInGemStone-Model'
}

{ #category : 'private' }
SigWorkspaceEvaluator class >> methodSourceFor: aSelector source: sourceString [
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
SigWorkspaceEvaluator class >> freshSelector [
	^ ('sigWorkspace', ((UUID new asString) copyWithout: $-)) asSymbol
]

{ #category : 'evaluating' }
SigWorkspaceEvaluator class >> evaluate: sourceString [
	| selector source result |
	selector := self freshSelector.
	source := self methodSourceFor: selector source: sourceString.
	[
		self
			compileMethod: source
			category: 'workspace-temporary'.
		result := self new perform: selector ]
		ensure: [
			(self includesSelector: selector)
				ifTrue: [ self removeSelector: selector ] ].
	^ result
]

{ #category : 'debugging' }
SigWorkspaceEvaluator >> sigSuspendForDebug [
	Processor activeProcess suspend
]
