function MailKeywordChecker(enable, keywords) {
  this.enable = enable;
  this.keywords = keywords;
  this.quoteRe = /^>.+$/mg;
  this.forwardRe = /Original Message[\s\S]+/mg;
}
MailKeywordChecker.prototype.isEnabled = function() {
  return this.enable == '1';
};
MailKeywordChecker.prototype.regexpForKeyword = function(keyword) {
  if (keyword.match(/^[\x00-\x7F]*$/)) {
    return new RegExp('\\b' + keyword + '\\b', 'i');
  } else {
    return  new RegExp(keyword, 'i');
  }
};
MailKeywordChecker.prototype.includeKeyword = function(text) {
  text = text.replace(this.quoteRe, '').replace(this.forwardRe, '');
  for (var i=0; i<this.keywords.length; i++) {
    var re = this.regexpForKeyword(this.keywords[i]);
    if (text.match(re)) {
      return this.keywords[i];
    }
  }
  return false;
};
