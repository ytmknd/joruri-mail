//Constructor
function AddressSelector() {
  this.parseAddressURI = null;
  this.sysAddressesURI = null;
  this.priAddressesURI = null;
  this._addressBook = null;
  this._callBack = null;
  this._loadingGroupIds = {'sys':{}, 'pri':{}};
  this._selected = {'to': {}, 'cc': {}, 'bcc': {}};
}
//Singleton instance
AddressSelector.instance = new AddressSelector();
//Instance methods
AddressSelector.prototype.toggle = function(prefix, to_addr, cc_addr, bcc_addr, callBack) {
  var selectorElm = document.getElementById('addressSelector');
  if (selectorElm.style.display != 'none') {
    if (!prefix || this._addressBook == prefix) {
      this.clearCheckboxes();
      this.clearSelected();
      selectorElm.style.display = 'none';
      return false;
    } else {
      this.changeBook(prefix);
      return true;
    }
  } else {
    this.clearCheckboxes();
    this.clearSelected();
    var self = this;
    var showSelector = function(){
      selectorElm.style.display = 'block';
      self.changeBook(prefix);
      self._callBack = callBack;
    };
    if (!to_addr) to_addr = '';
    if (!cc_addr) cc_addr = '';
    if (!bcc_addr) bcc_addr = '';
    if (to_addr == '' && cc_addr == '' && bcc_addr == '') {
      showSelector();
    } else {
      jQuery.ajax(this.parseAddressURI, {
        type: 'post',
        data: { to: to_addr, cc: cc_addr, bcc: bcc_addr },
        success: function(){
          showSelector();
        },
        error: function(){
          alert('読み込みに失敗しました。');
          showSelector();
        }
      });
    }
    return true;
  }  
};
AddressSelector.prototype.changeBook = function(prefix) {
  var addrElm = null;
  var selectElm = null;
  if (this._addressBook) {
    addrElm = document.getElementById(this._addressBook + 'Addresses');
    if (addrElm.style.display != 'none') addrElm.style.display = 'none';
    selectElm = document.getElementById(this._addressBook + 'AddressSearchFieldColumn');
    if (selectElm.style.display != 'none') selectElm.style.display = 'none';
  }
  addrElm = document.getElementById(prefix + 'Addresses');
  if (!addrElm.style.display != 'none') addrElm.style.display = 'block';
  selectElm = document.getElementById(prefix + 'AddressSearchFieldColumn');
  if (!selectElm.style.display != 'none') selectElm.style.display = 'block';
  this._addressBook = prefix;  
};
AddressSelector.prototype.currentBook = function() {
  if(document.getElementById('addressSelector').style.display != 'none') {
    return this._addressBook;
  } else {
    return null;
  }
};
AddressSelector.prototype.loadItems = function(prefix, gid, opt) {
  if (!opt) opt ={}; 
  if (this._loadingGroupIds[prefix][gid]) return;
  var elmChildren = document.getElementById(prefix + 'ChildItems' + gid);
  var toggleElm = document.getElementById(prefix + 'ToggleItems' + gid);
  if (elmChildren) {
    if (toggleElm.firstChild.nodeValue == '+') {
      elmChildren.style.display = 'block';
      toggleElm.firstChild.nodeValue = '-';
      toggleElm.className = "toggleItems toggleItemsOpen";
    } else if (opt['close'] != false) {
      elmChildren.style.display = 'none';
      toggleElm.firstChild.nodeValue = '+';
      toggleElm.className = "toggleItems toggleItemsClose";
    }
    return;
  }
  var search = false;
  if (opt['parameters']) search = true;
  if (!search && !toggleElm) return;
  this._loadingGroupIds[prefix][gid] = true;
  var uri = null;
  switch(prefix) {
  case 'sys':
    if (search) {
      uri = this.sysAddressesURI + ".xml";
    } else {
      uri = this.sysAddressesURI + "/" + gid + "/child_items.xml";  
    }
    break;
  case 'pri':
    if (search || gid == 0) {
      uri = this.priAddressesURI + ".xml";
    } else {
      uri = this.priAddressesURI + "/" + gid + "/child_items.xml";  
    }    
    break;  
  }
  var self = this;
  var requestOptions = {
    type: 'get',
    dataType: 'xml',
    success: function(xml){
      var xml = jQuery(xml).get(0);
      if (search) self.showSearchGroup(xml, prefix);
      self.showItems(xml, prefix, gid);
    },
    error: function() {
      delete self._loadingGroupIds[prefix][gid];
      alert('読み込みに失敗しました。');
    }
  };
  if (opt['parameters']) {
    requestOptions['data'] = opt['parameters'];
  }
  jQuery.ajax(uri, requestOptions);
};
AddressSelector.prototype.getNodeValue = function(node, name) {
    var elem = node.getElementsByTagName(name);
    if (elem.length > 0 && elem[0].firstChild != null) { return elem[0].firstChild.nodeValue; }
    return null;
};
AddressSelector.prototype.showItems = function(xml, prefix, parent_id) {
  var groups = xml.getElementsByTagName("group");
  var items = xml.getElementsByTagName("item");
  var parentElm = document.getElementById(prefix + 'Group' + parent_id);
  var ul = document.createElement('ul');
  ul.id = prefix + 'ChildItems' + parent_id;
  ul.className = 'children';
  for (var i = 0; i < groups.length; i++) {
    var group  = groups[i];
    var id    = this.getNodeValue(group, 'id');
    var name  = this.getNodeValue(group, 'name');
    var hasChildren = this.getNodeValue(group, 'has_children');    
    ul.appendChild(this.makeGroupElement(prefix, id, name, hasChildren == '1'));
  }
  if (items.length > 0) {
    ul.appendChild(this.makeAddressElement(prefix, parent_id, '0', '（すべてをチェックする）', '', null));
  }
  for (var i = 0; i < items.length; i++) {
    var item  = items[i];
    var id    = this.getNodeValue(item, 'id');
    var name  = this.getNodeValue(item, 'name');
    var email  = this.getNodeValue(item, 'email');
    var groupName = this.getNodeValue(item, 'group_name');
    ul.appendChild(this.makeAddressElement(prefix, parent_id, id, name, email, groupName));
  }
  if (ul.childNodes.length > 0) parentElm.appendChild(ul);

  var toggleElm = document.getElementById(prefix + 'ToggleItems' + parent_id);
  if (toggleElm) {
    toggleElm.firstChild.nodeValue = '-';
    toggleElm.className = "toggleItems toggleItemsOpen";    
  }  
  delete this._loadingGroupIds[prefix][parent_id];
};
AddressSelector.prototype.escapeHTML = function(str) {
  var escapes = {
    "&": "&amp;",
    "\"": "&quot;",
    "<": "&lt;",
    ">": "&gt;"
  };
  return str.replace(/[&"<>]/g, function(match) {
    return escapes[match];
  });
};
AddressSelector.prototype.makeGroupElement = function(prefix, id, name, hasChildren) {
  var li = document.createElement('li');
  li.className = 'group';
  li.id = prefix + 'Group' + id;
  var html = '';  
  if (hasChildren) {
    html += '<a href="#" id="' + prefix + 'ToggleItems' + id + '" class="toggleItems toggleItemsClose" onclick="AddressSelector.instance.loadItems(\'' + prefix + '\', \'' + id + '\');return false;">+</a> ';
  } else {
    html += '<a href="#" class="toggleItems" style="visibility:hidden;">+</a> ';
  }
  html += '<a href="#" class="itemName groupName" onclick="AddressSelector.instance.loadItems(\'' + prefix + '\', \'' + id + '\', {\'close\':false});return false;">' + this.escapeHTML(name) + '</a>';
  li.innerHTML = html;
  return li;
};
AddressSelector.prototype.makeAddressElement = function(prefix, gid, id, name, email, group) {
  var li = document.createElement('li');
  li.className = 'address';
  li.id = prefix + 'Address' + id + '_' + gid;
  var checkId = prefix + 'CheckAddress' + id + '_' + gid;
  var checkValue = "1";
  if (id != '0') {
    checkValue = this.escapeHTML(name + "\t" + email);
  }
  var nameValue = name;
  if (group != null) nameValue += " （" + group + "）";
  var html = '';  
  html += '<a href="#" class="toggleItems" style="visibility:hidden;">+</a> ';
  html += '<input type="checkbox" id="' + checkId + '" class="check" value="' + checkValue + '" onclick="AddressSelector.instance.checked(this)">';
  html += '<a href="#" class="itemName addressName" title="' + this.escapeHTML(email) + '" onclick="AddressSelector.instance.toggleCheckbox(\'' + checkId + '\');return false;">' + this.escapeHTML(nameValue) + '</a>';
  li.innerHTML = html;
  return li;
};
AddressSelector.prototype.showSearchGroup = function(xml, prefix) {
  var items = xml.getElementsByTagName("items")[0];
  var count = this.getNodeValue(items, "count");
  var total = this.getNodeValue(items, "total");
  var name = '検索結果';
  if (total != null && total > count) {
    name += '（' + total + ' 件中 ' + count + ' 件を表示）';
  }
  var rsltElm = this.makeGroupElement(prefix, 'Search', name, count > 0);
  var rootElm = document.getElementById(prefix + 'AddressesRoot');
  if (rootElm.firstChild) {
    rootElm.insertBefore(rsltElm, rootElm.firstChild);    
  } else {
    rootElm.appendChild(rsltElm);
  }
  return count;
};
AddressSelector.prototype.removeSearchGroup = function(prefix) {
  var rsltElm = document.getElementById(prefix + 'GroupSearch');
  if (rsltElm) rsltElm.parentNode.removeChild(rsltElm);  
};
AddressSelector.prototype.search = function() {
  var prefix = this._addressBook;
  var keyword = document.getElementById('addressSearchKeyword').value;
  var field = document.getElementById(prefix + 'AddressSearchField').value;
  if (keyword == '') return false;
  var param = {'search':'on'};
  param[field] = keyword;
  this.removeSearchGroup(prefix);
  this.loadItems(prefix, 'Search', {'parameters':param});
};
AddressSelector.prototype.resetSearchResult = function() {
  this.removeSearchGroup(this._addressBook);
};
AddressSelector.prototype.addAddresses = function(type) {
  var prefix = this._addressBook;
  var reg = new RegExp('^' + prefix + 'CheckAddress(.+?)_.+$');
  var inputs = document.getElementById(prefix + 'Addresses').getElementsByTagName('input');
  for (var i = 0;i < inputs.length;i++) {
    if (inputs[i].type != 'checkbox' || !inputs[i].checked) continue;
    var mt = reg.exec(inputs[i].id);
    if (!mt) continue;
    if (mt[1] != '0') {
      var splits = inputs[i].value.split("\t");
      if (splits.length >= 2) this.add(type, splits[0], splits[1]);      
    }
    inputs[i].checked = false;
  }
};
AddressSelector.prototype.add = function(type, name, email) {
  var address = email;
  if (name) {
    address = name + ' <' + email + '>';
  }
  var newAddress = false;
  var elm = null;
  if (this._selected[type][email]) elm = document.getElementById(type + '_' + email);
  if (!elm) {
    elm = document.createElement('div');
    elm.className = 'selectedAddress';
    elm.id = type + '_' + email;
    newAddress = true;
  }
  escaped_id = this.escapeHTML(elm.id.replace(/[\\'"]/g, "\\$&"));
  var html = '<a href="#" class="deleteButton" title="削除" onclick="AddressSelector.instance.remove(\'' + escaped_id + '\'); return false;">削除</a>';
  html += '<span class="addressName">' + this.escapeHTML(address) + '</span>';
  elm.innerHTML = html;
  if (newAddress) document.getElementById(type + 'Addresses').appendChild(elm);
  this._selected[type][email] = address;
};
AddressSelector.prototype.remove = function(id) {
  var elm = document.getElementById(id);
  if (elm) elm.parentNode.removeChild(elm);
  var mt = id.match(/^(to|cc|bcc)_(.+)$/);
  if (mt) {
    delete this._selected[mt[1]][mt[2]];
  }
};
AddressSelector.prototype.finishSelection = function(ok) {
  if (this._callBack) {
    var to = null, cc = null, bcc = null;
    if (ok) {
      to = this.selected('to');
      cc = this.selected('cc');
      bcc = this.selected('bcc');
    }
    this._callBack(ok, to, cc, bcc);
  }
  this.toggle();
};
AddressSelector.prototype.clearCheckboxes = function() {
  var prefixes = ['sys', 'pri'];
  for (var i = 0;i < prefixes.length;i++) {
    var inputs = document.getElementById(prefixes[i] + 'Addresses').getElementsByTagName('input');
    for (var k = 0;k < inputs.length;k++) {
      if (inputs[k].type == 'checkbox') inputs[k].checked = false; 
    }
  }
};
AddressSelector.prototype.clearSelected = function() {
  var types = ['to', 'cc', 'bcc'];
  for (var i = 0;i < types.length;i++) {
    this._selected[types[i]] = {};
    var elm = document.getElementById(types[i] + 'Addresses');
    for (var k = elm.childNodes.length - 1;k >= 0;k--) {
      elm.removeChild(elm.childNodes[k]);
    }
  }
};
AddressSelector.prototype.toggleCheckbox = function(checkId) {
  var checkElm = document.getElementById(checkId);
  if (checkElm) {
    checkElm.checked = !checkElm.checked;
  }
  this.checked(checkElm);
};
AddressSelector.prototype.checked = function(checkElm) {
  var prefix, id, gid;
  var checkIdPattern = /^(.+?)CheckAddress(.+?)_(.+)$/;
  var mt = checkElm.id.match(checkIdPattern);
  if (mt) {
    prefix = mt[1]
    id = mt[2];
    gid = mt[3];
  }
  if (id == '0') {
    var itemsElm = document.getElementById(prefix + 'ChildItems' + gid);
    var inputs = itemsElm.getElementsByTagName('input');
    for (var i = 0;i < inputs.length;i++) {
      if (inputs[i].type != 'checkbox') continue;
      var mt = inputs[i].id.match(checkIdPattern);
      if (!mt || mt[2] == '0' || mt[3] != gid) continue;
      inputs[i].checked = checkElm.checked; 
    }
  } else {
    if (checkElm.checked) return;
    var allElm = document.getElementById(prefix + 'CheckAddress0_' + gid);
    if (allElm) allElm.checked = false;
  }
};
AddressSelector.prototype.selected = function(type) {
  var list = '';
  var nodes = document.getElementById(type + 'Addresses').childNodes;
  var reg = new RegExp('^' + type + '_(.+)$');
  for (var i = 0;i < nodes.length;i++) {
    if (nodes[i].nodeType != 1 /* ELEMENT_NODE */ || nodes[i].tagName.toLowerCase() != 'div') continue;
    var mt = reg.exec(nodes[i].id);
    if (!mt) continue;
    var address = this._selected[type][mt[1]];
    if (address) {
      if (list != '') list += ', ';
      list += address;
    }
  }
  return list;
};
