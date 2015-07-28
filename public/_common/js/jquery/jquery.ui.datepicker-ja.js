/* Japanese initialisation for the jQuery UI date picker plugin. */
/* Written by Kentaro SATO (kentaro@ranvis.com). */
jQuery(function($){
  $.datepicker.regional['ja'] = {
    closeText: 'OK',
    prevText: '&#x3c;前',
    nextText: '次&#x3e;',
    currentText: '今日',
    monthNames: ['1','2','3','4','5','6','7','8','9','10','11','12'],
    monthNamesShort: ['1','2','3','4','5','6','7','8','9','10','11','12'],
    dayNames: ['日曜日','月曜日','火曜日','水曜日','木曜日','金曜日','土曜日'],
    dayNamesShort: ['日','月','火','水','木','金','土'],
    dayNamesMin: ['日','月','火','水','木','金','土'],
    weekHeader: '週',
    dateFormat: 'yy/mm/dd',
    firstDay: 0,
    isRTL: false,
    showMonthAfterYear: true,
    showButtonPanel: true,
    changeYear: true,
    changeMonth: true,
    yearSuffix: '年',
    showAnim: '',
    showOtherMonths: true,
    selectOtherMonths: true,
    showOn: 'both',
    buttonImage: '/images/calendar_date_select/calendar.gif',
    buttonImageOnly: true,
    buttonText: 'カレンダー',
    monthSuffix: '月',
    clearText: 'クリア'
  };
  $.datepicker.setDefaults($.datepicker.regional['ja']);
});