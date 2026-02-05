const path = require('path');

exports.handler = async (event) => {
  const { request } = event.Records[0].cf;

  if (
    request.uri !== "/index.html" &&
    request.uri !== "/error.html" &&
    request.uri !== "/not_found.html"
  ) {
    if (!path.extname(request.uri)) {
      request.uri = 'REPLACE_PATH_TO_ROOT';
    }
  }

  return request;
};
