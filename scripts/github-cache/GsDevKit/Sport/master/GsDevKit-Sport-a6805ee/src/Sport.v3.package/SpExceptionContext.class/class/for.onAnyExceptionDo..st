tests
for: aBlock onAnyExceptionDo: exceptionBlock 
  "^an Object 
  I execute aBlock and if there is any exception I evaluate exceptionBlock.  Essentially, I look out for the most abstract kind of exception which , of course, will vary between Smalltalk implementations."

  ^ aBlock onException: Exception do: exceptionBlock
