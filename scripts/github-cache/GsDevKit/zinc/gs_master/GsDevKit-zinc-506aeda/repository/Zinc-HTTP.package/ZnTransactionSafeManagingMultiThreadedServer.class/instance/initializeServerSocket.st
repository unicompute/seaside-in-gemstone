private
initializeServerSocket
  "Set up a new server socket and listen on it"

  self log debug: 'Initializing server socket'.
  self _setNoStubbing.	"as long as I am in memory prevent stubbing of my instance variables ... I will stay in memory as long as I am referenced from stack.."
  serverSocket := TransientStackValue
    value:
      (self bindingAddress
        ifNil: [ ZnNetworkingUtils serverSocketOn: self port ]
        ifNotNil: [ ZnNetworkingUtils serverSocketOn: self port interface: self bindingAddress ]).	"if I am committed, then do not persist server socket instance"
  self log debug: 'Initialized server socket'