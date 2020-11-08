--IE

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

),

postcards_vb as (
    select vb_voterbase_id
    from earliest_postcard
  ),
  
  dials as (
    select left(voter_id, 2) ||'-'|| regexp_substr(voter_id,'\\d+') as vb_voterbase_id

from tmc_thrutalk.sun_call_results
where not (date_called ilike '2020-10-28' and service_account ilike '%2%') and not (date_called ilike '2020-10-29' and service_account ilike '%2%')
    ),
    
texting as (
  	SELECT
		distinct(cc.external_id) as vb_voterbase_id

    
  from  sunrise_spoke.message mes 

  left join sunrise_spoke.campaign_contact cc on cc.id = mes.campaign_contact_id
  left join sunrise_spoke.campaign_title_separated camp_adj on cc.campaign_id = camp_adj.id
  left join sunrise_spoke.campaign camp on cc.campaign_id = camp.id

  where  camp_adj.camp_tag in ('requestaballot', 'gotv', 'votetripling')
  
  ),
  
 all_ie as (
   select 
   	* 
   from postcards_vb
   UNION
   select
   * 
   from dials
   UNION
   select 
   *
   from texting
   
   ) 
   
   select count( distinct lower(vb_voterbase_id)) from all_ie
