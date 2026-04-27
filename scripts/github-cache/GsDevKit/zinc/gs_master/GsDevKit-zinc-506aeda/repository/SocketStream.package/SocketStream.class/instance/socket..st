as yet unclassified
socket: aSocket
  self _setNoStubbing.	"as long as I am in memory prevent stubbing of my instance variables ... I will stay in memory as long as I am referenced from stack.."
  socket := TransientStackValue value: aSocket	"if I am committed, then do not persist aSocket"