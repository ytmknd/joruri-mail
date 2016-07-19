(function($){
  $.fn.popupMenu = function(config) {
    var options = $.extend({
      menu: "#menu"
    }, config);

    var buttons = $(this);
    var menus = $(options.menu);

    $(document).on('click', hideMenu);
    $(this).on('click', showMenu);

    function hideMenu(e) {
      if (e.button == 0 && !isPopupButton(e.target)) {
        menus.hide();
      }
    }
    function showMenu(e) {
      e.preventDefault();
      var button = $(e.target);
      var top = button.get(0).offsetTop + button.get(0).offsetHeight + 1;
      var left = button.get(0).offsetLeft;
      menus.css({'position': 'absolute', 'top': top, 'left': left}).show();
    }
    function isPopupButton(target) {
      for (var i=0; i<buttons.length; i++) {
        if (buttons.get(i) == target) {
          return true;
        }
      }
      return false;
    }
  };
})(jQuery);
