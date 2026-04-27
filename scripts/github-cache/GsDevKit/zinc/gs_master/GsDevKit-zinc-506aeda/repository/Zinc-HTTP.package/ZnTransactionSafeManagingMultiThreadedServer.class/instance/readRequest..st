request handling
readRequest: streamTransientStackValue
  "Read a request from stream.
	We add a virtual header containing the remote IP address of the client"

  | request |
  request := self
    withMaximumEntitySizeDo: [ self reader value: streamTransientStackValue value ].
  request headers
    at: ZnConstants remoteAddressHeader
    put:
      (ZnNetworkingUtils
        ipAddressToString: streamTransientStackValue value socket remoteAddress).
  self logRequest: request.
  ^ request