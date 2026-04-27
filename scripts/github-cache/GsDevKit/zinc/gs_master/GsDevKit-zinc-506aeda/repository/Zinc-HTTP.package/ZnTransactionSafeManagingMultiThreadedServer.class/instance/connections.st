accessing
connections
  connections
    ifNil: [ 
      self _setNoStubbing.	"as long as I am in memory prevent stubbing of my instance variables ... I will stay in memory as long as I am referenced from stack.."
      connections := TransientStackValue value: OrderedCollection new	"if I am committed, then do not persist collection" ].
  ^ connections value