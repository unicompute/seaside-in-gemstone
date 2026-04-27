private
defaultLog
  ^ ZnGemServerLogSupport new
    enableCreateContinuations: self enableCreateContinuations;
    addListener: self logListener;
    gemServerExceptionSet: self gemServerExceptionSet;
    yourself