accessing
error: errorDescription message: message
  self createContinuation: errorDescription value.
  super error: errorDescription message: message