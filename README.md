# Data_Cleaning_and_Exploratory_Data_Analysis_Project_in_MySQL

## Overview
This project demonstrates my SQL programming skills through data cleaning and exploratory data analysis (EDA) using a real-world dataset on global layoffs from 2020–2023. The goal was to transform messy, inconsistent data into clean, usable insights, mirroring a realistic analytics workflow.

## Dataset
Source: [Kaggle - Layoffs Dataset](https://www.kaggle.com/datasets/swaptr/layoffs-2022)

Description: Records of reported tech layoffs across industries, including company name, location, date, and number of employees laid off.

Size: ~2,000 records

## Data Cleaning Steps
In Data_Cleaning_Project.sql:
- Removed duplicate records
- Standardized data and fixed errors in location and industry fields 
- Handled NULL and missing values
- Reformatted date field

## Exploratory Data Analysis
In EDA_Project.sql:
- Total layoffs by year, industry, and country
- Trend of layoffs over time via rolling sum month-by-month across 2020-2023
- Top 5 companies with the highest layoffs per year

## Tools Used
- SQL (MySQL)
- Kaggle for dataset source
