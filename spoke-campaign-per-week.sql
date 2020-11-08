SELECT 
	camp_adj.id,
  camp_adj.name,
  camp_adj.camp_tag,
  mes.sent_at::date,
 sum(case when mes.is_from_contact = 'f' then 1 else 0 end) as num_texts_sent
    
from sunrise_spoke.message mes 

join sunrise_spoke.campaign_contact cc on cc.id = mes.campaign_contact_id  
join sunrise_spoke.question_response qr on qr.campaign_contact_id = cc.id
join sunrise_spoke.campaign campaign on cc.campaign_id = campaign.id
left join sunrise_spoke.campaign_title_separated camp_adj on cc.campaign_id = camp_adj.id
where  
mes.sent_at::date > (getdate() - interval '7 days') 
and (camp_adj.designation ilike 'IE'
or camp_adj.camp_tag ilike '%tripling%'
     or camp_adj.camp_tag ilike '%requestaballot%'
    or camp_adj.camp_tag ilike '%gotv%')
group by
  camp_adj.id,
  camp_adj.name,
  camp_adj.camp_tag,
  mes.sent_at::date

order by
   mes.sent_at::date desc nulls last
