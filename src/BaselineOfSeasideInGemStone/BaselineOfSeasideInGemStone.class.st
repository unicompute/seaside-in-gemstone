Class {
	#name : 'BaselineOfSeasideInGemStone',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfSeasideInGemStone',
	#package : 'BaselineOfSeasideInGemStone'
}

{ #category : 'baselines' }
BaselineOfSeasideInGemStone >> baseline: spec [
	<baseline>
	spec for: #common do: [
		spec
			package: 'SeasideInGemStone-Model';
			package: 'SeasideInGemStone-Compatibility';
			package: 'SeasideInGemStone-App' with: [ spec requires: #('SeasideInGemStone-Model' 'SeasideInGemStone-Compatibility') ];
			package: 'SeasideInGemStone-Tests' with: [ spec requires: #('SeasideInGemStone-App') ];
			group: 'default' with: #('SeasideInGemStone-Model' 'SeasideInGemStone-Compatibility' 'SeasideInGemStone-App');
			group: 'Tests' with: #('SeasideInGemStone-Tests') ]
]
