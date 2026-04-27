((Smalltalk at: #TonelRepository ifAbsent: [ nil ]) isNil
	or: [
		(Smalltalk at: #TonelReader ifAbsent: [ nil ]) isNil
			or: [
				((Smalltalk at: #STONJSON ifAbsent: [ nil ]) isNil
					and: [ (Smalltalk at: #NeoJSONReader ifAbsent: [ nil ]) isNil ]) ] ])
	ifTrue: [
		Error signal: 'TonelRepository/TonelReader and STONJSON or NeoJSON are not available in this image. Bootstrap Rowan and run scripts/topaz-load-seaside-in-gemstone-rowan.topaz, or add MonticelloTonel plus JSON support first.' ].

Metacello new
	baseline: 'Seaside3';
	repository: 'github://SeasideSt/Seaside:v3.5.x/repository';
	load: #('Core' 'Javascript' 'Zinc').

Metacello new
	baseline: 'SeasideInGemStone';
	repository: 'tonel:///Users/tariq/src/gemtools/seaside-in-gemstone/src';
	load: 'default'.

(Smalltalk at: #SigExplorerApplication ifAbsent: [ Error signal: 'SigExplorerApplication not loaded.' ])
	initializeApplication.

((Smalltalk at: #WAGsZincAdaptor ifAbsent: [
	Smalltalk at: #ZnZincServerAdaptor ifAbsent: [ Error signal: 'No Seaside Zinc adaptor loaded.' ] ]))
	startOn: 8080
