Extension { #name : 'SmallDateAndTime' }

{ #category : '*SeasideInGemStone-Compatibility' }
SmallDateAndTime >> truncated [
	^ self class
		secondsUTC: self asSeconds truncated
		offset: self offset
]
