Time::DATE_FORMATS[:humanized_ago]  = ->(time) do
  st = Time.now.in_time_zone("Pacific Time (US & Canada)").beginning_of_day
  nd = Time.now.in_time_zone("Pacific Time (US & Canada)").end_of_day

  case 
  when time.between?(st + 1.day, nd + 1.day)
    time.strftime('Tomorrow (%_m/%d) at %l:%M %p')
  when time.between?(st, nd)
    time.strftime('Today (%_m/%d) at %l:%M %p')
  when time.between?(st - 1.day, nd - 1.day)
    time.strftime('Yesterday (%_m/%d) at %l:%M %p')
  when time.between?(st - 6.day, nd - 2.day)
    time.strftime('%A (%_m/%d) at %l:%M %p')
  else 
    time.strftime('%_m/%d/%Y at %l:%M %p')
  end
end