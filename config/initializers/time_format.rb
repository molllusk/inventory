Time::DATE_FORMATS[:humanized_ago]  = ->(time) do
  st = Time.now.in_time_zone("Pacific Time (US & Canada)").beginning_of_day
  nd = Time.now.in_time_zone("Pacific Time (US & Canada)").end_of_day

  case 
  when time.between?(st + 1.day, nd + 1.day)
    "Tomorrow at #{time.strftime('%H:%M')}"
  when time.between?(st, nd)
    "Today at #{time.strftime('%H:%M')}"
  when time.between?(st - 1.day, nd - 1.day)
    "Yesterday at #{time.strftime('%H:%M')}"
  when time.between?(st - 6.day, nd - 2.day)
    time.strftime('%a %H:%M')
  else 
    time.strftime('%y-%b-%d %H:%M')
  end
end