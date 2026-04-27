testing
testDownloadSmallHTML
  | client |
  (System stoneVersionReport at: 'gsVersion') asMetacelloVersionNumber
    <= '3.1.0' asMetacelloVersionNumber
    ifTrue: [ 
      "skip the test for pre-3.1 GemStone versions"
      ^ self ].
  ZnFileSystemUtils deleteIfExists: 'small.html'.	"First download to a directory"
  (client := ZnClient new)
    url: 'http://zn.stfx.eu/zn/small.html';
    downloadTo: ZnFileSystemUtils defaultDirectoryPath.
  self assert: client isSuccess.
  self assert: client response contentType = ZnMimeType textHtml.
  ZnFileSystemUtils
    oldFileNamed: 'small.html'
    do: [ :stream | self assert: (stream upToEnd includesSubstring: 'Small') ].
  ZnFileSystemUtils deleteIfExists: 'small.html'.	"Second download to an explicitly named file"
  client
    url: 'http://zn.stfx.eu/zn/small.html';
    downloadTo: 'small.html'.
  self assert: client isSuccess.
  self assert: client response contentType = ZnMimeType textHtml.
  ZnFileSystemUtils
    oldFileNamed: 'small.html'
    do: [ :stream | self assert: (stream upToEnd includesSubstring: 'Small') ].
  client close.
  ZnFileSystemUtils deleteIfExists: 'small.html'