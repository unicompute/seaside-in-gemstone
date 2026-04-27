private
processes
  ^ (ProcessorScheduler scheduler allProcesses
    reject: [ :each | each isTerminated or: [ each = Processor activeProcess ] ])
    sorted: [ :a :b | a priority >= b priority ]