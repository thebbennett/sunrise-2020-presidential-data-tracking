select created_at::date, utm_campaign, count(*) as num_ptv
from sunrise_ballotready.all_data
where (state ilike '%NC%' or state ilike '%CO%' or state ilike '%PA%' or state ilike '%WI%' or state ilike '%MI%')
group by created_at::date, utm_campaign

-- (created_at::date >= date_trunc('day', getdate()::date) - 7
