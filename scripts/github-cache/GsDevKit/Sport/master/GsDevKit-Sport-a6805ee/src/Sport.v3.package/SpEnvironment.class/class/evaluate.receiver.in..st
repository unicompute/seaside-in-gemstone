compiling
evaluate: aString receiver: anObject in: anEnvironment 
"Used by Swazoo"
	^aString
		evaluateInContext: anObject 
		symbolList: anEnvironment.
