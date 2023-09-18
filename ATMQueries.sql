use atm_analysis
--Analyze the ATM transaction data and generate reports and visualizations that show 
--the most popular ATM locations and transaction types by time of day, day of week, and month.
create proc  GetMostDepositsLoc as
  
select [Location Name],[TransactionTypeName],[Year],max([TransactionAmount]) as max_transaction
from [atm_location lookup] loc, [transaction_type lookup] tran_type , [calendar lookup] c ,TRX_Fact trx
where c.Date=trx.TransactionStartDateTime 
and tran_type.TransactionTypeID=trx.TransactionTypeID
and loc.LocationID = trx.LocationID
and TransactionTypeName = 'deposit'
group by [Location Name],[TransactionTypeName],[Year]

exec GetMostDepositsLoc




----totoal total_tansaction_amt for each state
SELECT distinct(LOC.[State]) , sum(TRX.[TransactionAmount]) as total_tansaction_amt
FROM [atm_location lookup]  loc , [TRX_Fact] trx
WHERE loc.LocationID = trx.LocationID
GROUP BY State
ORDER BY 2 DESC


--------------THERE IS WE WILL DETECT WICH MONTH IS MORE VOLITILE IN EACH STATE 
WITH CTE AS(
SELECT distinct(LOC.[State]) , sum(TRX.[TransactionAmount]) as total_tansaction_amt,C.[Month Name],
DENSE_RANK() OVER (PARTITION BY STATE ORDER BY C.[Month Name] DESC ) AS DR
FROM [atm_location lookup]  loc , [TRX_Fact] trx ,[dbo].[calendar lookup] C
WHERE loc.LocationID = trx.LocationID
and c.date =trx.[TransactionStartDateTime]
GROUP BY State ,[Month Name])

SELECT * 
FROM CTE 
WHERE DR = 1
--NOTE {SEPTEMBER} IS THE WINNER 








---HER IS THE LOCATION WITH THE MOST WITHDRAWAL 
select [Location Name],max([TransactionAmount]) as max_transaction,[Day Name]
from [atm_location lookup] loc, [transaction_type lookup] tran_type , [calendar lookup] c ,TRX_Fact trx
where c.Date=trx.TransactionStartDateTime 
and tran_type.TransactionTypeID=trx.TransactionTypeID
and loc.LocationID = trx.LocationID
and TransactionTypeName = 'Withdrawal'
group by [Location Name],[Day Name]

---we calculate the mode for each day occure withdrawals
--veryyy importany
with cte as (
SELECT [Location Name] ,[Day Name],
dense_rank() over (partition by [Location Name] order by [Location Name] ) as DR
FROM [atm_location lookup] loc,[calendar lookup] c ,TRX_Fact trx ,[transaction_type lookup] tran_type 
WHERE c.Date=trx.TransactionStartDateTime
and loc.LocationID = trx.LocationID
and tran_type.TransactionTypeID=trx.TransactionTypeID
and TransactionTypeName = 'Withdrawal')

select [Day Name],COUNT(*) as mode from cte 
where dr = 1
group by [Day Name]

--•Calculate the average transaction amount per customer and per ATM location.
select round(AVG([TransactionAmount]),2) as avg_amount, COUNT(distinct [First Name]) no_of_customers,[Location Name] 
from [dbo].[TRX_Fact]  TRX ,  [dbo].[customers_lookup] c ,[dbo].[atm_location lookup] loc
where c.CardholderID=TRX.CardholderID
and loc.LocationID=TRX.LocationID
group by [Location Name]
order by avg_amount desc


--•Analyze the number of transactions and transaction amounts by customer age group, gender, and occupation.
select COUNT( trx.[TransactionID]) as no_of_trx,  sum(trx.[TransactionAmount]) as total_amount , c.[Segment], c.[Gender],c.[Occupation]	
from TRX_Fact trx , [dbo].[customers_lookup] c 
where c.CardholderID = trx.CardholderID
group by [Segment], [Gender],[Occupation]



--•Analyze the distribution of transaction types by customer type (Wisabi customers vs. customers of other banks).
--
----------
select trans_typ.[TransactionTypeName], c.[IsWisabi], sum(trx.[TransactionAmount]) as trx_amount
from [dbo].[transaction_type lookup] trans_typ, [dbo].[customers_lookup] c , TRX_Fact trx
where trans_typ.TransactionTypeID = trx.TransactionTypeID 
and c.CardholderID = trx.CardholderID
group by IsWisabi , TransactionTypeName
order by trx_amount desc


--•Analyze the impact of public holidays and weekends on ATM usage and transaction patterns.
----
----------------first we detect the 0 days transaction
select B.[IsHoliday],B.[Day Name],sum(A.[TransactionAmount]) AS Total_amt
from [dbo].[TRX_Fact]  A INNER JOIN [dbo].[calendar lookup] B
ON B.Date=A.TransactionStartDateTime
WHERE B.IsHoliday = 0
Group by B.IsHoliday,B.[Day Name]


----then we detect 0 and 1 together 
select B.[IsHoliday],B.[Day Name],sum(A.[TransactionAmount]) AS Total_amt
from [dbo].[TRX_Fact]  A INNER JOIN [dbo].[calendar lookup] B
ON B.Date=A.TransactionStartDateTime
WHERE B.IsHoliday = 0
OR B.IsHoliday = 1
Group by B.IsHoliday,B.[Day Name]

-----then we detect the holidays seperated
select B.[IsHoliday],B.[Day Name],sum(A.[TransactionAmount]) AS Total_amt
from [dbo].[TRX_Fact]  A INNER JOIN [dbo].[calendar lookup] B
ON B.Date=A.TransactionStartDateTime
WHERE B.IsHoliday = 1
Group by B.IsHoliday,B.[Day Name]


----note
------------1 -->>holiday day  //// 2-->> not holiday  total holiday 8 days only

----------- total trx_amt in holidays 
select B.[IsHoliday],sum(A.[TransactionAmount]) AS Total_amt
from [dbo].[TRX_Fact]  A INNER JOIN [dbo].[calendar lookup] B
ON B.Date=A.TransactionStartDateTime
WHERE B.IsHoliday = 1
Group by B.IsHoliday


---------total trx_amt in normal day  
select B.[IsHoliday],sum(A.[TransactionAmount]) AS Total_amt
from [dbo].[TRX_Fact]  A INNER JOIN [dbo].[calendar lookup] B
ON B.Date=A.TransactionStartDateTime
WHERE B.IsHoliday = 0
Group by B.IsHoliday



-----total trx_amt percent in days what ever is holiday or not 
select B.[IsHoliday],
sum(A.[TransactionAmount]) over (partition by B.isholiday ) as total_amt,
A.[TransactionAmount]/sum(A.[TransactionAmount]) over(partition by b.isholiday) * 100 as percent_of_total,
B.[Day Name]
from [dbo].[TRX_Fact]  A INNER JOIN [dbo].[calendar lookup] B
ON B.Date=A.TransactionStartDateTime
group by B.IsHoliday ,A.TransactionAmount,B.[Day Name]
order by percent_of_total desc



select B.[Quarter], 
sum(A.[TransactionAmount]) over (partition by B.[Quarter] ) as total_amt,
A.[TransactionAmount]/sum(A.[TransactionAmount]) over(partition by B.[Quarter]) * 100 as percent_of_total

from [dbo].[TRX_Fact]  A INNER JOIN [dbo].[calendar lookup] B
ON B.Date=A.TransactionStartDateTime
group by B.[Quarter] ,A.TransactionAmount
order by percent_of_total desc


select B.[Quarter], 
sum(A.[TransactionAmount]) over (partition by B.[Quarter] ) as total_amt,
A.[TransactionAmount]/sum(A.[TransactionAmount]) over(partition by B.[Quarter]) * 100 as percent_of_total,
b.[Month Name]
from [dbo].[TRX_Fact]  A INNER JOIN [dbo].[calendar lookup] B
ON B.Date=A.TransactionStartDateTime
group by B.[Quarter] ,A.TransactionAmount,b.[Month Name]
order by percent_of_total desc



select SUM([TransactionAmount]) as totalamt,[Quarter],[Month Name]
from TRX_Fact a ,[calendar lookup] b
where b.Date=a.TransactionStartDateTime
group by Quarter,[Month Name]
order by 1 desc

with cte as (
select SUM([TransactionAmount]) as totalamt,
[Quarter],
[Month Name],
dense_rank() over(PARTITION by quarter ORDER BY [TransactionAmount]) as RN
from TRX_Fact a ,[calendar lookup] b
where b.Date=a.TransactionStartDateTime
group by Quarter,[Month Name],transactionamount
)

SELECT * 
FROM cte 
WHERE RN=1

--•Analyze the frequency and amounts of transfers between accounts and between different banks.
select a.[TransactionTypeName],
	   b.[TransactionAmount],
	   c.[AccountType],
	   c.CardholderID,
	   count(*),
	   SUM(b.[TransactionAmount]),
	   d.date
from [dbo].[transaction_type lookup] a , [dbo].[TRX_Fact] b ,[dbo].[customers_lookup] c,[dbo].[calendar lookup] d
where a.TransactionTypeID=b.TransactionTypeID
and c.CardholderID=b.CardholderID
and d.Date =b.TransactionStartDateTime
and [TransactionTypeName] = 'transfer'

group by  a.[TransactionTypeName],
	   b.[TransactionAmount],
	   c.[AccountType],
	   c.CardholderID,
	   d.Date



--Evaluate the performance of each ATM location in terms of uptime, maintenance issues,
--and customer satisfaction.

select a.[Location Name],
count(b.TransactionID) as no_of_trx
from [dbo].[atm_location lookup] a,[dbo].[TRX_Fact] b
where a.LocationID=b.LocationID
group by a.[Location Name]
order by 2 desc

--What is the average transaction amount by location and transaction type?
select round(AVG([TransactionAmount]),2) as avg_amount ,[TransactionTypeName],[Location Name]
from TRX_Fact a, [dbo].[atm_location lookup] b , [dbo].[transaction_type lookup] c
where b.LocationID=a.LocationID
and c.TransactionTypeID =a.TransactionTypeID
group by [TransactionTypeName],[Location Name]

--Which ATM location has the highest number of transactions per day, and at what time of the day do the transactions occur most frequently?
with cte as (
SELECT [Location Name] ,[Day Name],
dense_rank() over (partition by [Location Name] order by [Location Name] ) as DR
FROM [atm_location lookup] loc,[calendar lookup] c ,TRX_Fact trx ,[transaction_type lookup] tran_type 
WHERE c.Date=trx.TransactionStartDateTime
and loc.LocationID = trx.LocationID
and tran_type.TransactionTypeID=trx.TransactionTypeID)


select [Day Name],COUNT(*) as mode from cte 
where dr = 1
group by [Day Name]
ORDER BY mode desc

-----------customer satisfaction is min per transactions
select ROUND(AVG([Min/TRX]),4) as AVG_MIN_TRX,[CardholderID]
from [dbo].[TRX_Fact]
group by CardholderID

--Which age group has the highest number of transactions, and which transaction type do they usually perform?
SELECT COUNT([TransactionID]) NO_OF_TRX,[TransactionTypeName],[Segment]
FROM [dbo].[transaction_type lookup] A ,[dbo].[customers_lookup] B ,[dbo].[TRX_Fact] C
WHERE A.TransactionTypeID=C.TransactionTypeID 
AND B.CardholderID=C.CardholderID
GROUP BY [TransactionTypeName],[Segment]

--What is the trend of transaction volume and transaction amount over time, and are there any seasonal trends or patterns?
SELECT COUNT([TransactionID]) NO_OF_TRX,sum([TransactionAmount]) sum_amounts,[Quarter]
FROM [dbo].[TRX_Fact]  A, [dbo].[calendar lookup] B
WHERE B.Date=A.TransactionStartDateTime
group by Quarter
order by sum_amounts





