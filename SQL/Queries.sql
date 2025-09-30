use job;

select * from jobs_data;

select * from INFORMATION_SCHEMA.COLUMNS
where TABLE_NAME= 'jobs_data';

--1. how many data this table contains?

select count(*) as Record_count from jobs_data;

--2. does the data has duplicates
select distinct job_id , count(job_id) as counts
from jobs_data
group by job_id
order by count(job_id) desc;


select count(distinct description) from jobs_data;

select count(*) as total_count,
		count(distinct job_id) as "unique job id",
		count(distinct description) as "unique job description"
		from jobs_data;

--3. list the top 5 companies and the number of exact job postings.

--based on job postings -- description 

select company_name , count(*) as "record_count"
from jobs_data
group by company_name, description
having count(*) >1;

--4. list first 6 fields and description token for 5 random rows 
select * from JOBS_DATA;

select top 5 [index], title, company_name,[location],via, description, description_tokens
from JOBS_DATA
order by NEWID();

/* 5. avg std.salary by schedule type ans remote status.
what is the avg salary_standardized for jobs, broken down by schedule_type and whether they work from home or not
include only full-time and contract jobs for this analysis */

select schedule_type,(case when work_from_home =1 then 'Remote' when work_from_home =0 then 'Onsite' end) as Remote_status, round(AVG(salary_standardized), 2)  as avg_salary_standardize
from JOBS_DATA
where schedule_type in ('Full-time', 'Contract')
group by schedule_type, work_from_home
order by 3 desc;

/* 6. top 1 job posting sources by tot. std. salary offered.
which job posting sources (via) collectivley represents the highest sum of std.salary? */

select top 1 via, round(sum(salary_standardized),2) as salary_std
from JOBS_DATA
group by via
order by 2 desc;

/* 7. job titles with highest propotion of remote opportunities 
list top 5 job titles that have highest proportion of work from home position among all their posting. 
consider only titles with atleast 3 total postings */

select * from JOBS_DATA; 

select top 5 title , count(*) as postings_count, 
sum(case when work_from_home =1 then 1 else 0 end) as "Remote",
sum(case when work_from_home =1 then 0 else 1 end) as Onsite,
(sum(case when work_from_home =1 then 1 else 0 end)/ count(*) )*100  as percentage_remote
from JOBS_DATA
group by title 
--having count(*) >=3
order by 3 desc;


/* 8. overall avg. std. salary for hourly vs yeraly rates.
compare the overall avg. std.salary for jobs listed as salary_rate = 'hourly' vs 'year'*/

select distinct salary_rate from JOBS_DATA;

select salary_rate , round(avg(salary_standardized),0 ) as avg_salary_std
from JOBS_DATA
group by salary_rate
order by 2 desc;

/* 9. location with high concentration of specific tech jobs.
identify locations except remote that have contains 
"engineer " and "cloud " in their descriptive tokens. count how many such jobs each identified location has */

select top 10 * from JOBS_DATA;

select location, count(*) cloud_engineer_jobs from jobs_data
where work_from_home <> 1
and description_tokens like '%engineer%' 
and description_tokens like '%cloud%'
group by location;

select location, count(*) cloud_engineer_jobs from jobs_data
where work_from_home <> 1
and (description_tokens like '%frontend%' or
 description_tokens like '%backend%')
group by location;

/* 10. salary comparision of recently posted jobs 
compare the avg std.salary for jobs posted in last 7 days 
(relative to the date_time column, assuming date_time represents "now" for the data point) versus jobs posted earlier. */

select max(cast(posted_at as date)),GETDATE()  from JOBS_DATA;

--dateadd(day,-7,getdate())

select 	case when posted_at >= DATEADD(DAY,-6,getdate()) then 'posted last 7 days'
			 else 'posted earlier'
		end as posting_period,
		avg( salary_standardized) as avg_std_salary	
from JOBS_DATA
group by  case when posted_at >= DATEADD(DAY,-6,getdate()) then 'posted last 7 days'
			 else 'posted earlier'
		end 
/* 11. Determine days since job postings
show the title, company name, posted_at, date_time(time stamp when the data is observed) and a new calculated column DaysSincePosting
which represents how many days have passed between the posted_at date and the date_time of the record.*/

select * from JOBS_DATA;

select title,company_name, posted_at, date_time, datediff(DAY,posted_at,date_time) as DaysSincePosting
from JOBS_DATA
order by DaysSincePosting asc;

/* 12. categorize salary ranges
High - salary_standardized is > 120,000
Medium - salary_standardized between 75,000 to 120,000 inclusive
Low - salary_standardized < 75,000
unspecifies if salary_standardized is null.*/

select job_id, title, company_name , salary_standardized,
		case 
			when salary_standardized >120000 then 'High'
			when salary_standardized between 75000 and 120000 then 'Medium'
			when salary_standardized <75000 then 'Low'
			else 'Unspecified'
		end as SalaryTier
from JOBS_DATA; 

/* 13. potentail data/AI/ML roles

for each job, display its title, company_name, a boolena like column IsDataAIMLRole 
that is 1 if description tokens conatins "data","ai","ml" or "machine learning"
case insensitive  and 0 otherwise */

select title, company_name, description_tokens,
		case 
			when lower(description_tokens) like '%data%'
				or lower(description_tokens) like '%ai%'
				or lower(description_tokens) like '%ml%'
				or lower(description_tokens) like '%machine learning%'
			then 1
			else 0
		end as IsDataAIMLRole
from jobs_data;

/* 14. from above results, extract company name , description token that has IsDataAIMLRole =1 */


with job_cte as (
select title, company_name, description_tokens,
		case 
			when lower(description_tokens) like '%data%'
				or lower(description_tokens) like '%ai%'
				or lower(description_tokens) like '%ml%'
				or lower(description_tokens) like '%machine learning%'
			then 1
			else 0
		end as IsDataAIMLRole
from jobs_data) 

select title, company_name, description_tokens from job_cte
where IsDataAIMLRole = 1;


/*15. standardized commute category and estimated commute time in hours
create 2 calculated columns
	1. CommuteCategory - short <= 20 min, medium >20 and <=45 min, long >45 min , 'N/A' if not numeric
	2. CommuteTimeInHours - convert commute_time to hours (assuming it is in x minutes)
*/

select * from JOBS_DATA; 

with jobs_cte as(
select title, commute_time, try_cast(REPLACE(commute_time,'mins','') as int) as Commute_mins
from JOBS_DATA)
select * , round(cast(Commute_mins as float)/60,2) as CommuteTimeInHours, 
			case 
				when Commute_mins <=20 then 'Short'
				when Commute_mins between 21 and 45 then 'Medium'
				when Commute_mins >45 then 'Long'
				when Commute_mins is null then 'N/A'
				else 'N/A'
			end as CommuteCategory
from jobs_cte;

/*16. Analyze avg.salary and remote job proportion for top 5 titles.
for the 5 most frequently posted titles (excluding remote locations),
calculate their avg. std sal. then for each of these top 5 titles, determine the % of jobs that are work_from_home.
rank these top titles by their avg. standardized_salary. */

with top_5_titles as(
select top 5 title, count(title) as count_title
from JOBS_DATA
where location <> 'Remote'
group by title
order by count(*) desc)

select j.title, 
avg(salary_standardized) as AverageStandardizedSalary,
sum(cast(j.work_from_home as float)*100)/ count(j.title) as RemotePercentage, 
rank() over (order by avg(salary_standardized) desc) as SalaryRank
from top_5_titles t
join JOBS_DATA j
on t.title = j.title
group by j.title








