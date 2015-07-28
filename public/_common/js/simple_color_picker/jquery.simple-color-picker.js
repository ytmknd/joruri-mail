(function ($) {
$.fn.simpleColorPicker = function(options) {
    var defaults = {
//        colorsPerLine: 8,
//        colors: ['#000000', '#444444', '#666666', '#999999', '#cccccc', '#eeeeee', '#f3f3f3', '#ffffff'
//				, '#ff0000', '#ff9900', '#ffff00', '#00ff00', '#00ffff', '#0000ff', '#9900ff', '#ff00ff'
//				, '#f4cccc', '#fce5cd', '#fff2cc', '#d9ead3', '#d0e0e3', '#cfe2f3', '#d9d2e9', '#ead1dc'
//				, '#ea9999', '#f9cb9c', '#ffe599', '#b6d7a8', '#a2c4c9', '#9fc5e8', '#b4a7d6', '#d5a6bd'
//				, '#e06666', '#f6b26b', '#ffd966', '#93c47d', '#76a5af', '#6fa8dc', '#8e7cc3', '#c27ba0'
//				, '#cc0000', '#e69138', '#f1c232', '#6aa84f', '#45818e', '#3d85c6', '#674ea7', '#a64d79'
//				, '#990000', '#b45f06', '#bf9000', '#38761d', '#134f5c', '#0b5394', '#351c75', '#741b47'
//				, '#660000', '#783f04', '#7f6000', '#274e13', '#0c343d', '#073763', '#20124d', '#4C1130'],
        colorsPerLine: 12,
        colors: [
          '#ffffff','#e5e5e5','#cccccc','#b2b2b2','#999999','#888888','#777777','#555555','#4c4c4c','#333333','#191919','#000000',
          '#ffbbbb','#ffdfbb','#ffffbb','#dfffbb','#bbffbb','#bbffdf','#bbffff','#bbdfff','#bbbbff','#dfbbff','#ffbbff','#ffbbdf',
          '#ff8888','#ffbf88','#ffff88','#bfff88','#88ff88','#88ffbf','#88ffff','#88bfff','#8888ff','#bf88ff','#ff88ff','#ff88bf',
          '#ff4444','#ff9f44','#ffff44','#9fff44','#44ff44','#44ff9f','#44ffff','#449fff','#4444ff','#9f44ff','#ff44ff','#ff449f',
          '#ff0000','#ff7f00','#ffff00','#7fff00','#00ff00','#00ff7f','#00ffff','#007fff','#0000ff','#7f00ff','#ff00ff','#ff007f',
          '#bf0000','#bf5f00','#bfbf00','#5fbf00','#00bf00','#00bf5f','#00bfbf','#005fbf','#0000bf','#5f00bf','#bf00bf','#bf005f',
          '#8f0000','#8f3f00','#8f8f00','#3f8f00','#008f00','#008f3f','#008f8f','#003f8f','#00008f','#3f008f','#8f008f','#8f003f',
          '#5f0000','#5f1f00','#5f5f00','#1f5f00','#005f00','#005f1f','#005f5f','#001f5f','#00005f','#1f005f','#5f005f','#5f001f',
          '#2f0000','#2f0f00','#2f2f00','#0f2f00','#002f00','#002f0f','#002f2f','#000f2f','#00002f','#0f002f','#2f002f','#2f000f'
        ],
        showEffect: '',
        hideEffect: '',
        onChangeColor: false
    };

    var opts = $.extend(defaults, options);

    return this.each(function() {
        var txt = $(this);

        var colorsMarkup = '';

        var prefix = txt.attr('id').replace(/-/g, '') + '_';

        for(var i = 0; i < opts.colors.length; i++){
            var item = opts.colors[i];

            var breakLine = '';
            if (i % opts.colorsPerLine == 0)
                breakLine = 'clear: both; ';

            if (i > 0 && breakLine && $.browser && $.browser.msie && $.browser.version <= 7) {
                breakLine = '';
                colorsMarkup += '<li style="float: none; clear: both; overflow: hidden; background-color: #fff; display: block; height: 1px; line-height: 1px; font-size: 1px; margin-bottom: -2px;"></li>';
            }

            colorsMarkup += '<li id="' + prefix + 'color-' + i + '" class="color-box" style="' + breakLine + 'background-color: ' + item + '" title="' + item + '"></li>';
        }

        var box = $('<div id="' + prefix + 'color-picker" class="color-picker" style="position: absolute; left: 0px; top: 0px;"><ul>' + colorsMarkup + '</ul><div style="clear: both;"></div></div>');
        $('body').append(box);
        box.hide();

        box.find('li.color-box').click(function() {
            if (!txt.is('input')) {
              txt.val(opts.colors[this.id.substr(this.id.indexOf('-') + 1)]);
              txt.blur();
            }
            if ($.isFunction(defaults.onChangeColor)) {
              defaults.onChangeColor.call(txt, opts.colors[this.id.substr(this.id.indexOf('-') + 1)]);
            }
            hideBox(box);
        });

        $('body').live('click', function() {
            hideBox(box);
        });

        box.click(function(event) {
            event.stopPropagation();
        });

        var positionAndShowBox = function(box) {
          var pos = txt.offset();
          var left = pos.left + txt.outerWidth() - box.outerWidth();
          if (left < pos.left) left = pos.left;
          box.css({ left: left, top: (pos.top + txt.outerHeight()) });
          showBox(box);
        }

        txt.click(function(event) {
          event.stopPropagation();
          if (!txt.is('input')) {
            // element is not an input so probably a link or div which requires the color box to be shown
            positionAndShowBox(box);
          }
        });

        txt.focus(function() {
          positionAndShowBox(box);
        });

        function hideBox(box) {
            if (opts.hideEffect == 'fade')
                box.fadeOut();
            else if (opts.hideEffect == 'slide')
                box.slideUp();
            else
                box.hide();
        }

        function showBox(box) {
            if (opts.showEffect == 'fade')
                box.fadeIn();
            else if (opts.showEffect == 'slide')
                box.slideDown();
            else
                box.show();
        }
    });
};
})(jQuery);