as yet unclassified
close
  "Flush any data still not sent
	and take care of the socket."

  [ self flush ]
    ensure: [ 
      self socket close.
      self destroy ]