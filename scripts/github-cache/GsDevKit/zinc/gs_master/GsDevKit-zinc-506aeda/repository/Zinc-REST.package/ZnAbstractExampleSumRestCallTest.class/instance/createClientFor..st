client
createClientFor: url
  ^ ZnClient new
    url: url;
    addPathSegment: #'sum';
    yourself