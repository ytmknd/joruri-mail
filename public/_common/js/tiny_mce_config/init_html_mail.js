/**
 * Initializes the tinyMCE.
 */
function initTinyMCE(originalSettings) {
  var settings = {
    // General options
    doctype: '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">',
    language: "ja",
    mode: "specific_textareas",
    editor_selector: "mceEditor",
    theme: "advanced",
    plugins: "table,fullscreen,media,template,preview",
    //plugins: "table,searchreplace,contextmenu,fullscreen,paste,emotions,media,template,preview",
    
    // Theme options
    theme_advanced_buttons1: "fontselect,fontsizeselect,separator,removeformat,separator,forecolor,backcolor,separator,bold,italic,underline,strikethrough,separator,justifyleft,justifycenter,justifyright,separator,bullist,numlist,separator,outdent,indent,blockquote,separator,link,unlink,separator,code",
    theme_advanced_buttons2: "",
    theme_advanced_buttons3: "",
    theme_advanced_buttons4: "",
    theme_advanced_toolbar_location: "top",
    theme_advanced_toolbar_align: "left",
    theme_advanced_statusbar_location: "bottom",
    theme_advanced_resizing: true,
    
    // Joruri original settings.
    theme_advanced_path: false,
    theme_advanced_font_sizes: "最大=large,大=medium,標準=small,小=x-small",//最小=xx-small
    theme_advanced_blockformats: "h2,h3,h4",
    theme_advanced_statusbar_location : "none",
    indentation: '1em',
    relative_urls: false,
    convert_urls: false,
    remove_script_host : false,
    table_default_border: 1,
    //document_base_url : "./",
    //readonly : true,

    theme_advanced_fonts : "Pゴシック=ms pgothic,sans-serif;"+ 
      "P明朝=ms pmincho,serif;"+ 
      "ゴシック=ms gothic,monospace;"+ 
      "明朝=ms mincho,serif;"+
      "Sans Serif=sans-serif;"+
      "Serif=serif;"+
      "幅広=arial black,sans-serif;"+
      "幅狭=arial narrow,sans-serif;"+
      "Verdana=verdana,sens-serif;",
      //"Andale Mono=andale mono,times;"+ 
      //"Arial=arial,helvetica,sans-serif;"+ 
      //"Arial Black=arial black,avant garde;"+ 
      //"Book Antiqua=book antiqua,palatino;"+ 
      //"Comic Sans MS=comic sans ms,sans-serif;"+ 
      //"Courier New=courier new,courier;"+ 
      //"Georgia=georgia,palatino;"+ 
      //"Helvetica=helvetica;"+ 
      //"Impact=impact,chicago;"+ 
      //"Symbol=symbol;"+ 
      //"Tahoma=tahoma,arial,helvetica,sans-serif;"+ 
      //"Terminal=terminal,monaco;"+ 
      //"Times New Roman=times new roman,times;"+ 
      //"Trebuchet MS=trebuchet ms,geneva;"+ 
      //"Verdana=verdana,geneva;",//+ 
      //"Webdings=webdings;"+ 
      //"Wingdings=wingdings, zapf dingbats", 

    // Example content CSS (should be your site CSS)
    content_css: [
      "/_common/js/tiny_mce_config/content.css",
      "/_common/js/tiny_mce_config/content_html_mail.css"
    ],
  };
  for (var key in originalSettings) {
    settings[key] = originalSettings[key];
  }
  tinyMCE.init(settings);
};
