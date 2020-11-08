with base_sent AS (
    select
        *,
        ROW_NUMBER() OVER (PARTITION BY vb_voterbase_id ORDER BY postcard_mailed_on asc) = 1 AS is_earliest

    from sunrise.postcards2020_sent
      where vb_voterbase_id != '#VALUE!'
    and postcard_mailed_on != '#REF!'

),
earliest_postcard_sent as (
    select * from base_sent where is_earliest
),

base_written AS (
    select
        *,
        ROW_NUMBER() OVER (PARTITION BY vb_voterbase_id ORDER BY postcard_written_on asc) = 1 AS is_earliest

    from sunrise.postcards2020_written
      where vb_voterbase_id != '#VALUE!'

),
earliest_postcard_written as (
    select * from base_written where is_earliest
)

select 
  left(vb_voterbase_id,2) as state,
  sum(case when postcard_written_on is not null then 1 else 0 end) as is_written,
  sum(case when postcard_mailed_on is not null then 1 else 0 end) as is_sent

from earliest_postcard_written
full outer join earliest_postcard_sent using (vb_voterbase_id)
group by left(vb_voterbase_id,2)
order by state
