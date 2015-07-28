
function openMailForm(uri){
  var opt = null;
  var name = '_blank';
  if (arguments.length > 1) {
    opt = arguments[1];
  }
  if (arguments.length > 2) {
    name = arguments[2];
  }
  return window.open(uri, name, opt);
}
