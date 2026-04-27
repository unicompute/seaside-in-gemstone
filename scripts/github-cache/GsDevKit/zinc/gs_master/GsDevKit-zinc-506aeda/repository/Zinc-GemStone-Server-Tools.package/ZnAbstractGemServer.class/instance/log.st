accessing
log
  log ifNil: [ log := self defaultLog ].
  ^ log