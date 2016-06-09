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
function isFlashInstalled() {
  if (navigator.plugins['Shockwave Flash']) {
    return true;
  }
  try {
    new ActiveXObject('ShockwaveFlash.ShockwaveFlash');
  } catch (e) {
    return false;
  }
  return true;
}
function isFileUploadSupported() {
  try {
    var input = document.createElement('input');
    input.type = 'file';
    input.style.display = 'none';
    document.getElementsByTagName('body')[0].appendChild(input);
    if (input.disabled) {
      return false;
    }
  } catch(ex){
     return false;
  } finally {
    if (input) {
      input.parentNode.removeChild(input);
    }
  }
  return true;
}
