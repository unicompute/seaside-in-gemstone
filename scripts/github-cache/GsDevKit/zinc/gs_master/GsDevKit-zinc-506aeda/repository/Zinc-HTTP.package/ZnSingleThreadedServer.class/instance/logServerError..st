logging
logServerError: exception
  "For GemStone, we want to log the exception description (conditionally snapping off a continuation) and
   dump the error information to the gem log."

  self log error: exception description.
  self handleError: exception