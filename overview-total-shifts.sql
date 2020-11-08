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
where  title  ilike '%Phonebank%'

),

de_dup as (
    select 
      title , 
      start_date ,
      end_date , 
      user__given_name , 
      user__family_name , 
      user__email_address   
  from base where is_most_recent
)

select 
      count(*) 
      + 1600 -- est textbanking shifts
      + 9000 -- postcard shifts

from de_dup
