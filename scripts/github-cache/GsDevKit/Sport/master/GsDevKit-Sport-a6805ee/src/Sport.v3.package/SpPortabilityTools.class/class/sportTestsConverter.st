scripts
sportTestsConverter

| userClasses userGlobals assocs |
userGlobals  := (GsCurrentSession currentSession symbolList resolveSymbol: #UserGlobals) value.
userClasses := (GsCurrentSession currentSession symbolList resolveSymbol: #UserClasses) value.
assocs := Array new.
userClasses associationsDo: [:assoc |
	assoc value isBehavior
		ifTrue: [
			assoc value category: 'Sport-Tests'.
			assocs add: assoc]].

assocs do: [:assoc |
	userClasses removeAssociation: assoc.
	userGlobals addAssociation: assoc].

