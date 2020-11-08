with base AS (
    select
        *,
        ROW_NUMBER() OVER (PARTITION BY vb_voterbase_id ORDER BY to_timestamp(left(replace(replace(postcard_written_on, '2020-09-27T01:01:21.544Z', '2020-09-26T01:01:21.544Z'),'T',' '), 19), 'YYYY-MM-DD HH24:MI:SS')::date  asc) = 1 AS is_earliest

    from sunrise.postcards2020_written
    where vb_voterbase_id != '#VALUE!'

),
earliest_postcard as (
    select * from base where is_earliest
    and vb_voterbase_id != '#VALUE!'

)

select  count(*) 
from earliest_postcard
