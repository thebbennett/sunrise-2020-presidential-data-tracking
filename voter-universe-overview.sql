select 
  sun.vb_vf_source_state as state,
  count(*) as num_voters,
  sum(case when vf.vb_voterbase_race not ilike '%caucasian%' then 1  else 0 end) as num_poc,
 sum(case when sun.vb_vf_g2016 is null then 1 else 0 end) as not_voted_g2016,
 sum(case when ballot_requested_pav_and_default_flag = 1  then 1 else 0 end) as requested_ballot,
 sum(case when ballot_mailed_flag = 1  then 1  else 0 end) as ballot_mailed,
 sum(case when chase_universe_flag  = 1  then 1  else 0 end) as need_chase,
 sum(tmc_universe_all) as is_in_tmc_universe,
 sum(sunrise_contacts_total) as sunrise_contacts


from sunrise.ntl_current sun 
join ts.ntl_current vf on sun.vb_voterbase_id = vf.vb_voterbase_id
group by sun.vb_vf_source_state
