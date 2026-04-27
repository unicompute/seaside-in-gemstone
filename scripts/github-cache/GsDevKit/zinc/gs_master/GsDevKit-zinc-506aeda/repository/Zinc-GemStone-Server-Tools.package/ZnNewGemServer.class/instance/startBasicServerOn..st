service instance-server
startBasicServerOn: port
  "start basic server process in current vm. fork and record forked process instance. expected to return."

  | znServer |
  znServer := (self serverClass on: port)
    gemServer: self;
    log: self log;
    gemServerOptions: self options;
    yourself.
  self serverInstance: znServer.
  self
    basicServerProcess:
      ([ self basicServerOn: port ] forkAt: Processor highIOPriority)