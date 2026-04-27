testing
expectedFailures
  | vers |
  vers := System gemVersionReport at: #'gsVersion'.
  ((vers beginsWith: '2')
    or: [ (vers beginsWith: '3.0') or: [ vers beginsWith: '3.1' ] ])
    ifTrue: [ ^ #(#'testGzippedAndChunked') ].
  ^ #()	"should be passing consistently from 3.2 onward"