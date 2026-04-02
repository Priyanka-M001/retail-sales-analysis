# Retail Sales Data Warehouse ETL Script
# This script transforms raw retail data into dimension and fact tables
# for analytical querying in SQL and dashboard reporting.

import pandas as pd


# Load dataset
df = pd.read_csv(r"P:/Data Analytics/Projects/PROJECT 2 — Automated Business Sales Intelligence System/clean_superstore-.csv")


# Standardize column names to lowercase and snake_case
df.columns = df.columns.str.strip().str.lower().str.replace(" ", "_")

# Remove duplicate columns created after renaming
df = df.loc[:, ~df.columns.duplicated()]


# Convert date columns with mixed formats and handle errors
df["order_date"] = pd.to_datetime(
    df["order_date"],
    format="mixed",
    dayfirst=True,
    errors="coerce"
)

df["ship_date"] = pd.to_datetime(
    df["ship_date"],
    format="mixed",
    dayfirst=True,
    errors="coerce"
)

# Remove rows with invalid order_date
df = df.dropna(subset=["order_date"])


# Create date dimension for time-based analysis
dim_date = df[["order_date"]].drop_duplicates().copy()
dim_date["year"] = dim_date["order_date"].dt.year
dim_date["month"] = dim_date["order_date"].dt.month
dim_date["month_name"] = dim_date["order_date"].dt.month_name()
dim_date["quarter"] = dim_date["order_date"].dt.quarter


# Create customer dimension
dim_customer = df[[
    "customer_id",
    "customer_name",
    "segment"
]].drop_duplicates()


# Create product dimension
dim_product = df[[
    "product_id",
    "category",
    "sub-category",
    "product_name"
]].drop_duplicates()


# Create region dimension
dim_region = df[[
    "country",
    "city",
    "state",
    "postal_code",
    "region"
]].drop_duplicates().reset_index(drop=True)


# Create fact table with transactional data
fact_sales = df[[
    "order_id",
    "order_date",
    "ship_date",
    "customer_id",
    "product_id",
    "country",
    "city",
    "state",
    "postal_code",
    "sales"
]].copy()


# Generate surrogate keys for dimension tables
dim_date = dim_date.reset_index(drop=True)
dim_date["date_key"] = dim_date.index + 1

dim_customer = dim_customer.reset_index(drop=True)
dim_customer["customer_key"] = dim_customer.index + 1

dim_product = dim_product.reset_index(drop=True)
dim_product["product_key"] = dim_product.index + 1

dim_region["region_key"] = dim_region.index + 1


# Replace natural keys with surrogate keys in fact table
fact_sales = fact_sales.merge(
    dim_date[["order_date", "date_key"]],
    on="order_date",
    how="left"
)

fact_sales = fact_sales.merge(
    dim_customer[["customer_id", "customer_key"]],
    on="customer_id",
    how="left"
)

fact_sales = fact_sales.merge(
    dim_product[["product_id", "product_key"]],
    on="product_id",
    how="left"
)

fact_sales = fact_sales.merge(
    dim_region[["country", "city", "state", "postal_code", "region_key"]],
    on=["country", "city", "state", "postal_code"],
    how="left"
)


# Final fact table with surrogate keys and measure
fact_sales = fact_sales[[
    "order_id",
    "date_key",
    "customer_key",
    "product_key",
    "region_key",
    "sales"
]]


# Adjust data types for SQL compatibility
dim_region["postal_code"] = dim_region["postal_code"].astype(str)


# Reorder columns to match warehouse schema
dim_customer = dim_customer[[
    "customer_key",
    "customer_id",
    "customer_name",
    "segment"
]]

dim_date = dim_date[[
    "date_key",
    "order_date",
    "year",
    "month",
    "month_name",
    "quarter"
]]

dim_product = dim_product[[
    "product_key",
    "product_id",
    "category",
    "sub-category",
    "product_name"
]]

dim_region = dim_region[[
    "region_key",
    "country",
    "city",
    "state",
    "postal_code",
    "region"
]]

fact_sales = fact_sales[[
    "order_id",
    "date_key",
    "customer_key",
    "product_key",
    "region_key",
    "sales"
]]



# Export final tables for SQL ingestion
dim_date.to_csv(r"P:\Data Analytics\Projects\1\dim_date.csv", index=False)
dim_customer.to_csv(r"P:\Data Analytics\Projects\1\dim_customer.csv", index=False)
dim_product.to_csv(r"P:\Data Analytics\Projects\1\dim_product.csv", index=False)
dim_region.to_csv(r"P:\Data Analytics\Projects\1\dim_region.csv", index=False)
fact_sales.to_csv(r"P:\Data Analytics\Projects\1\fact_sales.csv", index=False)