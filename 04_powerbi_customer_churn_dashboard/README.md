# 04_powerbi_customer_churn_dashboard

A Power BI dashboard analyzing customer churn using the [Telco Customer Churn dataset](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) (Kaggle), covering 42K total customers, 11K churned, a 27% overall churn rate. The dashboard combines KPI cards, churn breakdowns, a key-influencers analysis, and a revenue-risk view.

## Visualization

📄 [View dashboard (PDF)](./Customer_Churn_Dashboard.pdf)

## What it shows

- Overall churn rate, plus churn broken down by contract type, tenure group, internet service, and payment method
- Revenue lost by contract type, average tenure, and CLV estimate
- A key-influencers analysis showing which factors most increase the likelihood of churn
- A churned-customer breakdown by internet service and payment method

## What I found

Churn is heavily concentrated in month-to-month contracts and fiber optic customers - having a month-to-month contract alone increases churn likelihood by over 6x, and fiber optic customers churn at more than double the rate of DSL. Electronic check is the highest-risk payment method by a wide margin. Nearly 67% of all churned customers come from the fiber optic segment alone, while DSL and non-internet customers stay comparatively stable - meaning any retention strategy has to target pricing, installation friction, or service reliability specifically within fiber, not customers broadly.

## Skills demonstrated

- Building a multi-page Power BI report that separates descriptive (what happened) from diagnostic (why it happened) analysis
- Using Power BI's key-influencers visual to quantify which factors move churn risk, not just correlate with it
- Translating a churn-rate breakdown into a specific, actionable recommendation rather than stopping at the numbers

## Tools used

- Power BI (KPI cards, key influencers, decomposition tree)
- [Telco Customer Churn dataset](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) (Kaggle)
