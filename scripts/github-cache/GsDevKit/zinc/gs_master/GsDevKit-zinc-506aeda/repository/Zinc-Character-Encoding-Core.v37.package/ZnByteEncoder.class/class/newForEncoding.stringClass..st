*zinc-character-encoding-core
newForEncoding: string stringClass: ignored
  "Return a new character encoder object for an encoding described by string.
	We use our precomputed ByteTextConverters tables."

  ^ self newForEncoding: string