private
defaultLog
  ^ ZnLogSupport new
    addListener: self logListener;
    yourself