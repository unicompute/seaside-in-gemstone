services-status
connectTo: hostAddress port: port timeout: timeoutSeconds
  ^ self
    connectTo: (SpIPAddress host: hostAddress port: port)
    timeout: timeoutSeconds