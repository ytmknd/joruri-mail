require File.dirname(__FILE__) + "/lib/calendar_date_select.rb"

CalendarDateSelect::FORMATS[:japanese] = {
  :date => "%Y/%m/%d",
  :time => " %H:%M",
  :javascript_include => "format_japanese"
}
CalendarDateSelect.format = :japanese
