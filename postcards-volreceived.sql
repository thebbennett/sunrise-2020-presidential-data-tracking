with written AS (
    select
        *,
        ROW_NUMBER() OVER (PARTITION BY vb_voterbase_id ORDER BY to_timestamp(left(replace(postcard_written_on,'T',' '), 19), 'YYYY-MM-DD HH24:MI:SS')::date  asc) = 1 AS is_earliest

    from sunrise.postcards2020_written
    where vb_voterbase_id != '#VALUE!'


),

earliest_postcard_written as (
    select 
    vb_voterbase_id,
    to_timestamp(left(replace(replace(postcard_written_on, '2020-09-27T01:01:21.544Z', '2020-09-26T01:01:21.544Z'),'T',' '), 19), 'YYYY-MM-DD HH24:MI:SS')::date as date_written
    from written where is_earliest
    and vb_voterbase_id != '#VALUE!'
  
),

sent AS (
    select
        *,
        ROW_NUMBER() OVER (PARTITION BY vb_voterbase_id ORDER BY to_timestamp(left(replace(postcard_mailed_on,'T',' '), 19), 'YYYY-MM-DD HH24:MI:SS')::date   asc) = 1 AS is_earliest

    from sunrise.postcards2020_sent
    where vb_voterbase_id != '#VALUE!'
    and postcard_mailed_on != '#REF!'
),

earliest_postcard_sent as (
    select 
    vb_voterbase_id,
    to_timestamp(left(replace(postcard_mailed_on,'T',' '), 19), 'YYYY-MM-DD HH24:MI:SS')::date as date_sent
    from sent where is_earliest
    and vb_voterbase_id != '#VALUE!'
),

base as
  (select 
  status.vb_voterbase_id,
  status.volunteer_email,
  written.date_written,
  sent.date_sent
  from sunrise.postcard_statuses status 
  left join earliest_postcard_written written on written.vb_voterbase_id = status.vb_voterbase_id
  left join earliest_postcard_sent sent on sent.vb_voterbase_id = status.vb_voterbase_id
),

num_written_and_sent as (
select 
  volunteer_email,
  sum(case when date_written is not null then 1 else 0 end) as num_postcards_written,
  sum(case when date_sent is not null then 1 else 0 end) as num_postcards_sent

from base 
group by volunteer_email
  )

select 
    count(CASE WHEN num_postcards_written > 0  THEN 1 END)::decimal / count(*)::decimal as pct_received

from num_written_and_sent
