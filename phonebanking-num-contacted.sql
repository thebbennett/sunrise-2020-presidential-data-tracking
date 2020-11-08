-- get call results
WITH results as (
  select 
  	id,
  	max(voter_phone) as voter_phone,
  	max(voter_id) as voter_id,
  	max(date_called) as date_called,
  	max(service_account) as service_account,
  	max(caller_login) as caller_login,
  	max(result) as result
  from tmc_thrutalk.sun_call_results
  group by 1
  ),

-- get script responses to first ID question. Original script had checkbox questions, hence lines 12 through 21
scale1 as (
  select call_result_id, max(answer) as answer 
  from tmc_thrutalk.sun_script_results 
  where question in(
    'trump_to_biden_scale',
    'trump_to_biden_scale_checkbox_value_1',
    'trump_to_biden_scale_checkbox_value_2',
    'trump_to_biden_scale_checkbox_value_3',
    'trump_to_biden_scale_checkbox_value_4',
    'trump_to_biden_scale_checkbox_value_5',
    'trump_to_biden_scale_checkbox_value_6',
    'trump_to_biden_scale_checkbox_value_7',
    'trump_to_biden_scale_checkbox_value_8',
    'trump_to_biden_scale_checkbox_value_9')
  group by 1
  ),

-- get script responses for ballot ready question
ballot_ready as (
  select call_result_id, max(answer) as answer 
  from tmc_thrutalk.sun_script_results 
  where question like 'ballot_ready'
  group by 1
  ),
  
-- get answers to the vote tripple question where people provide 3 names. If not null, then they provided 3 names for vote trippling. 
votetrip as (
  select call_result_id, max(answer) as answer 
  from tmc_thrutalk.sun_script_results 
  where question ilike 'if_yes_to_vt_3_friends_names'
  group by 1
  ),
  
-- get script responses for start question. This is to make sure we exclude everyone who has gotten a call, wrong numbers, refused, ect. We need this because sometimes callers enter call results wrong.
results1 as (
  select call_result_id, max(answer) as answer 
  from tmc_thrutalk.sun_script_results
  where 
  	answer ilike '%wrong%'
  	or answer ilike '%moved%'
  	or answer ilike '%talking%'
    or answer ilike '%refused%'
    or answer ilike '%deceased%' 
    or answer ilike '%disconnected%' 
    or answer ilike '%spanish%'
  group by 1
  ),

--bring it all together in the final base from which we will pull call metrics from 
final_base as (
  select
  	results.id as id,
 	results.date_called as date_called,
  	results.service_account as service_account,
  	results.caller_login as caller_login,
  	results.result as result,
  	scale1.answer as trump_to_biden,
  	ballot_ready.answer as ballot_ready,
  	votetrip.answer as votetrip,
  	results1.answer as first_question
  from results
  left join scale1 on scale1.call_result_id = results.id
  left join ballot_ready on ballot_ready.call_result_id = results.id
  left join votetrip on votetrip.call_result_id = results.id
  left join results1 on results1.call_result_id = results.id
    -- exclude coordinated tx dials
  where not (voter_id ilike '%tx%' and service_account ilike '%2%')
  ),

call_metrics as(
select
	service_account, 
	
    date_called, 
    
-- assign a state based on call line and date. Getting this from the schedule. 
	case
		when date_called like '2020-10-02' and service_account ilike '%1%' then 'MI'
  		when date_called like '2020-10-05' and service_account ilike '%1%' then 'MI + FL + AZ'
  		when date_called like '2020-10-06' and service_account ilike '%1%' then 'FL'
  		when date_called like '2020-10-09' and service_account ilike '%1%' then 'WI'
  		when date_called like '2020-10-09' and service_account ilike '%2%' then 'AZ'
  		when date_called like '2020-10-11' and service_account ilike '%2%' then 'AZ'
  		when date_called like '2020-10-13' and service_account ilike '%1%' then 'WI'
		when date_called like '2020-10-13' and service_account ilike '%2%' then 'AZ'
		when date_called like '2020-10-13' and service_account ilike '%2%' then 'AZ'
		when date_called like '2020-10-16' and service_account ilike '%1%' then 'MI'
  		when date_called like '2020-10-16' and service_account ilike '%2%' then 'AZ'
  		when date_called like '2020-10-18' and service_account ilike '%1%' then 'PA'
  		when date_called like '2020-10-18' and service_account ilike '%2%' then 'FL'
  		when date_called like '2020-10-19' and service_account ilike '%1%' then 'PA'
		when date_called like '2020-10-19' and service_account ilike '%2%' then 'FOIA'
  		when date_called like '2020-10-20' and service_account ilike '%1%' then 'PA'
  		when date_called like '2020-10-20' and service_account ilike '%2%' then 'WI'
  		when date_called like '2020-10-23' and service_account ilike '%1%' then 'AZ'
  		when date_called like '2020-10-23' and service_account ilike '%2%' then 'WI'
  	else 'TBD'
  	end as state,

-- get dial count
    count (*) as dials,

-- count connected to correct person
    sum(
      case 
    	when first_question ilike '%Talking to Correct Person%' then 1 
    	else 0 
      	end) as talking_to_correct_person_total, 
        
-- count wrong numbers
	sum(
      case 
   		when first_question ilike '%wrong%' then 1 
    	else 0 
      	end) as wrong_number_total,
        
-- count refused (jerks)
	sum(
      case 
   		when first_question ilike '%refused%' then 1 
    	else 0 
      	end) as refused_total,
        
-- count ids     
	sum(
      case 
      	when trump_to_biden is not null then 1
      	else 0 
      	end) as ids,
        
-- count positive ids            
	sum(
      case 
      	when trump_to_biden in (6,7,8,9,10) then 1
       	else 0 
      	end) as positive_ids,
        
-- count the number of people who went through ballot ready with a phonebanker
	sum(
      case 
      	when ballot_ready in ('complete', 'unregistered_wi','unregistered_mi','unregistered_pa','unregistered_nc','unregistered_az','unregistered_fl') then 1
       	else 0 
      	end) as completed_ballot_ready,
        
-- count the number of people who gave the names of 3 friends
	sum(
      case 
      	when votetrip is not null then 1
       	else 0 
      	end) as vote_triple_total,

-- the following 10 case whens count the number of instances of each ID rank
	sum(
      case 
      	when trump_to_biden =1 then 1
       	else 0 
      	end) as "1s",
	
    sum(
      case 
      	when trump_to_biden =2 then 1
       	else 0 
      	end) as "2s",

	sum(
      case 
      	when trump_to_biden =3 then 1
       	else 0 
      	end) as "3s",
	
    sum(
      case 
      	when trump_to_biden =4 then 1
       	else 0 
      	end) as "4s",
	
    sum(
      case 
      	when trump_to_biden =5 then 1
       	else 0 
      	end) as "5s",
        
	sum(
      case 
      	when trump_to_biden =6 then 1
       	else 0 
      	end) as "6s",

	sum(
      case 
      	when trump_to_biden =7 then 1
       	else 0 
      	end) as "7s",

	sum(
      case 
      	when trump_to_biden =8 then 1
       	else 0 
      	end) as "8s",

	sum(
      case 
      	when trump_to_biden =9 then 1
       	else 0 
      	end) as "9s",
        
	sum(
      case 
      	when trump_to_biden =10 then 1
       	else 0 
      	end) as "10s",

-- count not voting ppl (sad)
	sum(
      case 
      	when trump_to_biden like 'not_voting' then 1
       	else 0 
      	end) as not_voting, 

--  count people who already voted
    sum(
      case 
      	when trump_to_biden like 'already_voted' then 1
       	else 0 
      	end) as already_voted,

-- count people who are ineligible to vote
	sum(
      case 
      	when trump_to_biden like 'ineligible' then 1
       	else 0 
      	end) as ineligible,
  	
-- the next section is to get rates
-- rate of connected to correct voter
	sum(
    	case 
			when first_question ilike '%Talking to Correct Person%' then 1 
    		else 0 
      		end):: decimal 
     /
     count (*):: decimal as talked_to_correct_voter_rate,

-- wrong number rate
	sum(
    	case 
			when first_question ilike '%wrong%' then 1 
    		else 0 
      		end):: decimal 
     /
     count (*):: decimal as wrong_number_rate,

-- refused rate
	sum(
    	case 
			when first_question ilike '%refused%' then 1 
    		else 0 
      		end):: decimal 
     /
     count (*):: decimal as refused_rate,
      
-- ID rate
	sum(
		case 
      		when trump_to_biden is not null then 1
      		else 0 
      		end)::  decimal
    /	
	count (*):: decimal 
    as id_rate,

-- positive ID rate
	sum(
      	case 
      		when trump_to_biden in (7,8,9,10) then 1
       		else 0 
      		end):: decimal
     /
	nullif(
		sum(
			case 
          		when trump_to_biden in (1,2,3,4,5,6,7,8,9,10) then 1 
          		else 0 
          		end
        	):: decimal
		,0) as positive_id_rate,

-- Undecided rate
	sum(
      	case 
      		when trump_to_biden = 5 then 1
       		else 0 
      		end):: decimal
     /
	nullif(
		sum(
			case 
          		when trump_to_biden in (1,2,3,4,5,6,7,8,9,10) then 1 
          		else 0 
          		end
        	):: decimal
		,0) as undecided_rate,

-- not voting rate
	sum(
		case 
      		when trump_to_biden like 'not_voting' then 1
       		else 0 
      		end
    	):: decimal
     /
     nullif(
		sum(
			case 
				when first_question ilike '%Talking to Correct Person%' then 1 
    			else 0 
          		end
        	):: decimal
          	,0) as not_voting_rate,

-- ballot ready completed rate
	sum(
		case 
      		when ballot_ready in ('complete', 'unregistered_wi','unregistered_mi','unregistered_pa','unregistered_nc','unregistered_az','unregistered_fl') then 1
       		else 0 
      		end):: decimal
    /
	nullif(
		sum(
          case 
    		when first_question ilike '%Talking to Correct Person%' then 1 
    		else 0 
          	end
        	):: decimal
      		,0) as completed_ballot_ready_rate,

-- vote tripple rate
	sum(
		case when votetrip is not null then 1.0
       	else 0 
      	end
    	):: decimal
	/
	nullif(
    	sum(
          	case 
    		when first_question ilike '%Talking to Correct Person%' then 1 
    		else 0 
          	end
        	):: decimal
      		,0) as vote_triple_rate
from final_base    
group by 1, 2
order by 2 desc, 1),

-- get caller data and group by email so that our averages make sense and are on a per caller basis not a per login basis
callers as(
  select 
  	email,
  	date,
  	service_account,
  	sum(minutes_in_ready) as minutes_in_ready,
  	sum(no_contact) + sum(remove_number_from_list) + sum(talked_to_correct_person) as total_dials
from tmc_thrutalk.sun_callers
group by email, date, service_account),

-- now do some calculations so that this is ready to join with our call result metrics
caller_metrics as(
select
    callers.date,
    callers.service_account,
	count(distinct(callers.email)) as total_callers,
    avg(callers.minutes_in_ready) as avg_minutes_in_ready,
    avg(callers.total_dials) as avg_dials_per_caller
from callers
group by 1,2
),

final as 
(select
	call_metrics.state,
  call_metrics.date_called,
  call_metrics.service_account,
  caller_metrics.total_callers,
  caller_metrics.avg_minutes_in_ready,
  caller_metrics.avg_dials_per_caller, 
  call_metrics.dials,
  call_metrics.talking_to_correct_person_total,
  call_metrics.wrong_number_total,
  call_metrics.refused_total,
  call_metrics.ids,
  call_metrics.positive_ids,
  call_metrics.completed_ballot_ready,
  call_metrics.vote_triple_total,
  call_metrics."1s",
  call_metrics."2s",
  call_metrics."3s",
  call_metrics."4s",
  call_metrics."5s",
  call_metrics."6s",
  call_metrics."7s",
  call_metrics."8s",
  call_metrics."9s",
  call_metrics."10s",
  call_metrics.not_voting,
  call_metrics.already_voted,
  call_metrics.ineligible,
  call_metrics.talked_to_correct_voter_rate,
  call_metrics.wrong_number_rate,
  call_metrics.refused_rate,
  call_metrics.id_rate,
  call_metrics.positive_id_rate,
  call_metrics.undecided_rate,
  call_metrics.not_voting_rate,
  call_metrics.completed_ballot_ready_rate,
  call_metrics.vote_triple_rate
  
from call_metrics
left join caller_metrics 
  on call_metrics.date_called = caller_metrics.date 
  and call_metrics.service_account = caller_metrics.service_account
 where not (call_metrics.date_called ilike '2020-10-28' and call_metrics.service_account ilike '%2%') and not (call_metrics.date_called ilike '2020-10-29' and call_metrics.service_account ilike '%2%')
order by 
 2,3
) 

select sum(talking_to_correct_person_total)  from final
