accessing
processes
  | allProcesses |
  allProcesses := (ProcessorScheduler scheduler allProcesses asArray
    reject: [ :each | each isTerminated or: [ each = Processor activeProcess ] ])
    sorted: [ :a :b | a priority >= b priority ].
  ^ String
    streamContents: [ :out | 
      allProcesses
        doWithIndex: [ :each :index | 
          out
            print: index;
            nextPut: $.;
            space;
            nextPutAll: each name;
            space;
            nextPut: $[;
            print: each priority;
            nextPut: $];
            space;
            print: each;
            cr ] ]