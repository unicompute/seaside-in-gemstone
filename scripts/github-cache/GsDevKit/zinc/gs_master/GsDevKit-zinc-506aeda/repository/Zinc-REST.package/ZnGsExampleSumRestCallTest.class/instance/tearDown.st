running
tearDown
  super tearDown.
  gemServer
    stopGems;
    unregister.
  (Delay forSeconds: 3) wait