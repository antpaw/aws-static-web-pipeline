const path = require('path');
const { STATUS_CODES } = require('http');

exports.handler = async (event) => {
  const { request } = event.Records[0].cf;

  if (
    request.uri !== "/index.html" &&
    request.uri !== "/error.html" &&
    request.uri !== "/not_found.html"
  ) {
    const redirectResp = checkPath(/(.*)\.html?$/, request.uri)
      || checkPath(/(.*)\/$/, request.uri);

    if (redirectResp) {
      return redirectResp;
    }

    // Append `.html` if clean path
    if (!path.extname(request.uri)) {
      request.uri += '.html';
    }
  }

  return request;
}

function checkPath(regex, uri) {
  if (regex.test(uri)) {
    const newUri = uri.replace(regex, '$1');
    return redirect(newUri);
  }
}

function redirect(to) {
  return {
    status: '301',
    statusDescription: STATUS_CODES['301'],
    headers: {
      location: [{ key: 'Location', value: to }]
    }
  };
}
