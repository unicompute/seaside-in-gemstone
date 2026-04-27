exception handling
handleBreakpointException: exception resumeIfResumable: resumeIfResumable
  "Handle breakpoint or halt, snap off continuation, then resume"

  self createContinuation: exception description.
  (resumeIfResumable and: [ exception isResumable ])
    ifTrue: [ exception resume ]
    ifFalse: [ 
      Transcript
        cr;
        show: 'Passing ' , exception class name.
      exception pass ]