with base  as (
    SELECT
      events.title , 
      convert_timezone(events.timezone, timeslots.start_date::timestamp) as start_date ,
      timeslots.end_date , 
      part.user__given_name , 
      part.user__family_name , 
      part.user__email_address  ,
      case when creator__email_address ilike '%sunrisemovement.org%' then 'centralized' else 'hub' end as eventtype,
      row_number() over (partition by part.id order by part.created_date::date desc) = 1 as is_most_recent,
      50 as shift_goal

  from  sun_mobilize.participations part
left join sun_mobilize.events events on part.event_id = events.id
left join sun_mobilize.timeslots timeslots on timeslots.id = part.timeslot_id 
where date_part(w, timeslots.start_date::date) = date_part(w, getdate()::date ) 
  and title  ilike '%Phonebank%'

),

de_dup as (
    select 
      title , 
      shift_goal ,
      start_date ,
      end_date , 
      user__given_name , 
      user__family_name , 
      user__email_address   
  from base where is_most_recent
),

by_event as (
 select 
    title ||' '|| case when extract(hour from start_date) > 12 then to_char(start_date, 'Day Mon DD HH:MI AM') else to_char(start_date, 'Day Mon DD HH:MI PM') end as title_date, 
    shift_goal - count(user__email_address) as remaining,
    count(user__email_address) as num_sign_ups,   
    start_date, 
    shift_goal

  from de_dup
  group by title, start_date , shift_goal
  ) 

select 
title_date,
num_sign_ups,
case when remaining >0 then remaining else 0 end as remainder

from by_event

order by start_date::date asc
