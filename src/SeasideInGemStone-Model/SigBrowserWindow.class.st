Class {
	#name : 'SigBrowserWindow',
	#superclass : 'Object',
	#instVars : [
		'windowId',
		'title',
		'taskbarLabel',
		'subtitle',
		'position',
		'selectedDictionaryName',
		'selectedClassName',
		'selectedProtocolName',
		'selectedSelector',
		'sourceDraftText'
	],
	#category : 'SeasideInGemStone-Model',
	#package : 'SeasideInGemStone-Model'
}

{ #category : 'instance creation' }
SigBrowserWindow class >> id: anId title: aTitle taskbarLabel: aTaskbarLabel position: aPosition [
	^ self new
		initializeWithId: anId
		title: aTitle
		taskbarLabel: aTaskbarLabel
		position: aPosition
]

{ #category : 'initialization' }
SigBrowserWindow >> initializeWithId: anId title: aTitle taskbarLabel: aTaskbarLabel position: aPosition [
	windowId := anId.
	title := aTitle.
	taskbarLabel := aTaskbarLabel.
	subtitle := ''.
	position := aPosition.
	selectedDictionaryName := #UserGlobals.
	selectedClassName := nil.
	selectedProtocolName := nil.
	selectedSelector := nil.
	sourceDraftText := nil
]

{ #category : 'accessing' }
SigBrowserWindow >> windowId [
	^ windowId
]

{ #category : 'accessing' }
SigBrowserWindow >> title [
	^ title
]

{ #category : 'accessing' }
SigBrowserWindow >> taskbarLabel [
	^ taskbarLabel
]

{ #category : 'accessing' }
SigBrowserWindow >> subtitle [
	^ subtitle
]

{ #category : 'accessing' }
SigBrowserWindow >> position [
	^ position
]

{ #category : 'accessing' }
SigBrowserWindow >> selectedDictionaryName [
	^ selectedDictionaryName
]

{ #category : 'accessing' }
SigBrowserWindow >> selectedDictionaryName: aSymbol [
	selectedDictionaryName := aSymbol.
	selectedClassName := nil.
	selectedProtocolName := nil.
	selectedSelector := nil.
	sourceDraftText := nil
]

{ #category : 'accessing' }
SigBrowserWindow >> selectedClassName [
	^ selectedClassName
]

{ #category : 'accessing' }
SigBrowserWindow >> selectedClassName: aString [
	selectedClassName := aString.
	selectedProtocolName := nil.
	selectedSelector := nil.
	sourceDraftText := nil
]

{ #category : 'accessing' }
SigBrowserWindow >> selectedProtocolName [
	^ selectedProtocolName
]

{ #category : 'accessing' }
SigBrowserWindow >> selectedProtocolName: aString [
	selectedProtocolName := aString
]

{ #category : 'accessing' }
SigBrowserWindow >> selectedSelector [
	^ selectedSelector
]

{ #category : 'accessing' }
SigBrowserWindow >> selectedSelector: aString [
	selectedSelector := aString
]

{ #category : 'accessing' }
SigBrowserWindow >> sourceDraftText [
	^ sourceDraftText
]

{ #category : 'accessing' }
SigBrowserWindow >> sourceDraftText: aString [
	sourceDraftText := aString
]

{ #category : 'compatibility' }
SigBrowserWindow >> at: aKey ifAbsent: aBlock [
	aKey = #id ifTrue: [ ^ windowId ].
	aKey = #kind ifTrue: [ ^ #browser ].
	aKey = #title ifTrue: [ ^ title ].
	aKey = #taskbarLabel ifTrue: [ ^ taskbarLabel ].
	aKey = #subtitle ifTrue: [ ^ subtitle ].
	aKey = #position ifTrue: [ ^ position ].
	aKey = #selectedBrowserDictionaryName ifTrue: [ ^ selectedDictionaryName ].
	aKey = #selectedBrowserClassName ifTrue: [ ^ selectedClassName ].
	aKey = #selectedBrowserProtocolName ifTrue: [ ^ selectedProtocolName ].
	aKey = #selectedBrowserSelector ifTrue: [ ^ selectedSelector ].
	aKey = #browserSourceDraftText ifTrue: [ ^ sourceDraftText ].
	^ aBlock value
]

{ #category : 'compatibility' }
SigBrowserWindow >> at: aKey put: aValue [
	aKey = #selectedBrowserDictionaryName ifTrue: [ self selectedDictionaryName: aValue. ^ aValue ].
	aKey = #selectedBrowserClassName ifTrue: [ self selectedClassName: aValue. ^ aValue ].
	aKey = #selectedBrowserProtocolName ifTrue: [ selectedProtocolName := aValue. ^ aValue ].
	aKey = #selectedBrowserSelector ifTrue: [ selectedSelector := aValue. ^ aValue ].
	aKey = #browserSourceDraftText ifTrue: [ sourceDraftText := aValue. ^ aValue ].
	self error: 'SigBrowserWindow: unknown key ', aKey printString
]
