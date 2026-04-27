queries
allSubclassesOf: aClass
"^an Array
I return the array of classes which are subclasses of aClass."

	^ClassOrganizer new allSubclassesOf: aClass
