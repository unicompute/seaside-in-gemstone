accessing
logListener
  logListener ifNil: [ logListener := ZnTranscriptLogger new ].
  ^ logListener
    filter: self logFilter;
    yourself