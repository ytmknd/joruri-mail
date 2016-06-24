function escapeHTML(str) {
  var escapes = {
    "&": "&amp;",
    "\"": "&quot;",
    "<": "&lt;",
    ">": "&gt;"
  };
  return str.replace(/[&"<>]/g, function(match) {
    return escapes[match];
  });
}
