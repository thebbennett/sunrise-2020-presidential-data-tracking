SELECT
 sum(case when mes.is_from_contact = 'f' then 1 else 0 end)  as num_texts_sent
  
    
from  sunrise_spoke.message mes 

left join sunrise_spoke.campaign_contact cc on cc.id = mes.campaign_contact_id
left join sunrise_spoke.campaign_title_separated camp_adj on cc.campaign_id = camp_adj.id
left join sunrise_spoke.campaign camp on cc.campaign_id = camp.id

where  camp_adj.camp_tag in ('requestaballot', 'gotv', 'votetripling')
