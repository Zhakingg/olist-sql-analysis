# E-commerce Business Performance & Customer Intelligence

An end-to-end SQL Server analysis of a Brazilian online marketplace (the public Olist dataset): loading nine CSV files, validating and cleaning them, and answering 15 business questions on sales, products, customers and delivery.

**Tools:** Microsoft SQL Server (T-SQL), SSMS

> **At a glance:** 96,211 completed orders · 93,104 customers · BRL 13.18M item revenue · 97% of customers buy only once · 93.2% of orders arrive on time, but late orders score 2.27 stars vs 4.29

## Start here

| File | What it is |
|---|---|
| [KEY_FINDINGS.md](KEY_FINDINGS.md) | One-page summary of the results and recommendations |
| [BUSINESS_QUESTIONS_AND_ANSWERS.md](BUSINESS_QUESTIONS_AND_ANSWERS.md) | All 15 questions with answers, result tables and the SQL |
| [Olist_SQL_Analysis_Report.pdf](Olist_SQL_Analysis_Report.pdf) | The full report as a PDF |
| [sql/](sql) | My SQL scripts: checks, cleaning, views, and one file per question |

![Monthly revenue](images/monthly_revenue.png)

## SQL skills demonstrated

| Skill | Question | SQL file |
|---|---|---|
| Data validation: NULLs, duplicates, orphan keys, invalid dates | Q1 | [02_null_check](sql/02_null_check.sql), [03_validation_checks](sql/03_validation_checks.sql), [Q01](sql/questions/Q01.sql) |
| Data cleaning and reusable views (flags, deduplicated reviews) | Q3 | [05_data_cleaning_final_views](sql/05_data_cleaning_final_views.sql), [06_qualifying_views](sql/06_qualifying_views.sql) |
| Aggregation, GROUP BY, HAVING, CASE | Q2, Q4, Q5 | [Q02](sql/questions/Q02.sql), [Q04](sql/questions/Q04.sql), [Q05](sql/questions/Q05.sql) |
| CTEs and the LAG window function | Q6 | [Q06](sql/questions/Q06.sql) |
| RANK() and SUM() OVER: rankings, shares, running totals | Q7, Q8, Q9 | [Q07](sql/questions/Q07.sql), [Q08](sql/questions/Q08.sql), [Q09](sql/questions/Q09.sql) |
| Join grain control (one review per order with ROW_NUMBER) | Q10 | [Q10](sql/questions/Q10.sql) |
| Customer analytics: repeat rate, top customers | Q11, Q12 | [Q11](sql/questions/Q11.sql), [Q12](sql/questions/Q12.sql) |
| RFM segmentation with NTILE | Q13 | [Q13](sql/questions/Q13.sql) |
| Date logic: DATEDIFF, on-time vs late delivery | Q14 | [Q14](sql/questions/Q14.sql) |
| Evidence queries behind recommendations | Q15 | [Q15](sql/questions/Q15.sql) |

## Dataset

[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle): nine tables, about 100k orders from 2016 to 2018. The raw CSV files are not included in this repository; download them from Kaggle to reproduce the work.

## SQL files, in the order I ran them

| File | Purpose |
|---|---|
| [01_row_counts_and_preview.sql](sql/01_row_counts_and_preview.sql) | Check all nine tables loaded: row counts, sample rows |
| [02_null_check.sql](sql/02_null_check.sql) | Profile missing values and test whether NULL delivery dates are explained by status |
| [03_validation_checks.sql](sql/03_validation_checks.sql) | Orphan keys, range checks, illogical dates, payment reconciliation |
| [04_data_cleaning_steps.sql](sql/04_data_cleaning_steps.sql) | Cleaning investigations (stray header row, missing translations, orders with no items) |
| [05_data_cleaning_final_views.sql](sql/05_data_cleaning_final_views.sql) | Final cleaning script: reference-data fixes and the clean views |
| [06_qualifying_views.sql](sql/06_qualifying_views.sql) | The completed-sale views used by Q3 to Q15 |
| [questions/Q01.sql to Q15.sql](sql/questions) | One file per business question |

## How to reproduce

1. Install SQL Server and SSMS, create a database with `CREATE DATABASE Olist;`, and load the nine Kaggle CSVs.
2. Run the files in `sql/` in numbered order, then the files in `sql/questions/`.

## About

Built by **Joshua Akhigbe Adomokhai**, Data Analyst · [LinkedIn](https://www.linkedin.com/in/joshua-akhigbe-733400284/) · akhigbej254@gmail.com

*Dataset: Olist, via Kaggle. Check the dataset's licence before reusing the data.*
