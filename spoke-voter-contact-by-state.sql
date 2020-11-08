select 
  vf.vb_vf_source_state as state,
  count(m.id) 
from sunrise_spoke.campaign_contact cc
left join sunrise_spoke.campaign c on cc.campaign_id = c.id
left join sunrise_spoke.message m on cc.id = m.campaign_contact_id
join ts.ntl_current vf on cc.external_id = vf.vb_voterbase_id
where c.title ilike '%requestaballot%'
      or c.title ilike 'gotv'
and is_from_contact = 'f'
group by  vf.vb_vf_source_state
