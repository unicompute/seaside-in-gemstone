private
closeConnections
  self connections isEmpty
    ifTrue: [ ^ self ].
  self log
    debug: [ 'Closing ' , self connections size printString , ' connections' ].
  self lock
    critical: [ 
      self connections
        do: [ :each | 
          self log debug: [ 'Closing ' , each printString ].
          [ each close ]
            on: Error
            do: [ :exception | 
              self log
                error: exception description
                message: (GsProcess stackReportToLevel: 100) ] ].
      self connections removeAll ].
  self log debug: [ 'Done Closing connections' ]