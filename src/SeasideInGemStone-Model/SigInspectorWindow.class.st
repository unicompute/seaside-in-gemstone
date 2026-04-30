Class {
	#name : 'SigInspectorWindow',
	#superclass : 'Object',
	#instVars : [
		'windowId',
		'title',
		'taskbarLabel',
		'subtitle',
		'position',
		'label',
		'text',
		'rowsTitle',
		'rows'
	],
	#category : 'SeasideInGemStone-Model',
	#package : 'SeasideInGemStone-Model'
}

{ #category : 'instance creation' }
SigInspectorWindow class >> id: anId title: aTitle taskbarLabel: aTaskbarLabel position: aPosition label: aLabel text: aText [
	^ self new
		initializeWithId: anId
		title: aTitle
		taskbarLabel: aTaskbarLabel
		position: aPosition
		label: aLabel
		text: aText
]

{ #category : 'instance creation' }
SigInspectorWindow class >> id: anId title: aTitle taskbarLabel: aTaskbarLabel position: aPosition label: aLabel rowsTitle: aRowsTitle rows: rowsArray text: aText [
	^ self new
		initializeWithId: anId
		title: aTitle
		taskbarLabel: aTaskbarLabel
		position: aPosition
		label: aLabel
		rowsTitle: aRowsTitle
		rows: rowsArray
		text: aText
]

{ #category : 'initialization' }
SigInspectorWindow >> initializeWithId: anId title: aTitle taskbarLabel: aTaskbarLabel position: aPosition label: aLabel text: aText [
	windowId := anId.
	title := aTitle.
	taskbarLabel := aTaskbarLabel.
	subtitle := ''.
	position := aPosition.
	label := aLabel.
	text := aText ifNil: [ 'Nothing selected for inspection.' ].
	rowsTitle := 'Details'.
	rows := #()
]

{ #category : 'initialization' }
SigInspectorWindow >> initializeWithId: anId title: aTitle taskbarLabel: aTaskbarLabel position: aPosition label: aLabel rowsTitle: aRowsTitle rows: rowsArray text: aText [
	windowId := anId.
	title := aTitle.
	taskbarLabel := aTaskbarLabel.
	subtitle := ''.
	position := aPosition.
	label := aLabel.
	rowsTitle := aRowsTitle.
	rows := rowsArray.
	text := aText ifNil: [ 'Nothing selected for inspection.' ]
]

{ #category : 'accessing' }
SigInspectorWindow >> windowId [
	^ windowId
]

{ #category : 'accessing' }
SigInspectorWindow >> title [
	^ title
]

{ #category : 'accessing' }
SigInspectorWindow >> taskbarLabel [
	^ taskbarLabel
]

{ #category : 'accessing' }
SigInspectorWindow >> subtitle [
	^ subtitle
]

{ #category : 'accessing' }
SigInspectorWindow >> position [
	^ position
]

{ #category : 'accessing' }
SigInspectorWindow >> label [
	^ label
]

{ #category : 'accessing' }
SigInspectorWindow >> text [
	^ text
]

{ #category : 'accessing' }
SigInspectorWindow >> rowsTitle [
	^ rowsTitle
]

{ #category : 'accessing' }
SigInspectorWindow >> rows [
	^ rows
]

{ #category : 'compatibility' }
SigInspectorWindow >> at: aKey ifAbsent: aBlock [
	aKey = #id ifTrue: [ ^ windowId ].
	aKey = #title ifTrue: [ ^ title ].
	aKey = #taskbarLabel ifTrue: [ ^ taskbarLabel ].
	aKey = #subtitle ifTrue: [ ^ subtitle ].
	aKey = #position ifTrue: [ ^ position ].
	aKey = #label ifTrue: [ ^ label ].
	aKey = #rowsTitle ifTrue: [ ^ rowsTitle ].
	aKey = #rows ifTrue: [ ^ rows ].
	aKey = #text ifTrue: [ ^ text ].
	^ aBlock value
]
