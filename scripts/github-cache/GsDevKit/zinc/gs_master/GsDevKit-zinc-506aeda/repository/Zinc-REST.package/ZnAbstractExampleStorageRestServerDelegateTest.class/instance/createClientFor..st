client
createClientFor: url
  ^ ZnClient new
    url: url;
    addPathSegment: #'storage';
    accept: ZnMimeType applicationJson;
    contentReader: [ :entity | entity ifNotNil: [ NeoJSONReader fromString: entity contents ] ];
    contentWriter: [ :object | ZnEntity with: (NeoJSONWriter toString: object) type: ZnMimeType applicationJson ];
    yourself