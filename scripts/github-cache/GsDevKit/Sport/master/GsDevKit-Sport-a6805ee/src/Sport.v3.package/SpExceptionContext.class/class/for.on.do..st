instance creation
for: aBlock on: anException do: exceptionBlock 
	"^an Object 
	I return the result of evaluating aBlock. In VisualWorks and other 
	Smalltalks which are ANSI compliant, I delegate to aBlock."

	^aBlock on: anException do: exceptionBlock