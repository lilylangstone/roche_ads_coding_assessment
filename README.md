# Roche Programming Assessment

This repository contains my solutions to the Roche programming assessment.

The assessment covers clinical data programming, data manipulation, visualisation,
API development and a Generative AI clinical data assistant using R and Python.

## Repository Structure

Each assessment question is contained within its own folder, with the relevant
code, data and supporting documentation.

```text
project/
│
├── question_1/
│   └── descriptive_stats/
│       ├── DESCRIPTION
│       ├── man/
│       ├── NAMESPACE
│       ├── R/
│       ├── README.md
│       └── tests/
│
├── question_2_sdtm/
│   ├── 02_create_ds_domain.R
│   ├── metadata/
│   └── README.md
│
├── question_3_adam/
│   ├── create_adsl.R
│   └── README.md
│
├── question_4_tlg/
│   ├── 01_create_ae_summary_table.R
│   ├── 02_create_visualizations.R
│   ├── 03_create_listings.R
│   ├── output/
│   └── README.md
│
├── question_5_api/
│   ├── adae.csv
│   ├── api_launcher.py
│   ├── main.py
│   ├── README.md
│   └── requirements.txt
│
├── question_6_genai/
│   ├── data/
│   │   ├── adae.csv
│   │   └── adae_metadata.csv
│   ├── programs/
│   │   ├── clinical_data_agent.py
│   │   └── test_agent.py
│   ├── README.md
│   └── requirements.txt
│
├── .gitignore
├── project.Rproj
└── README.md
```

Please refer to the README within individual question folders where additional
setup or execution instructions are required.

## Languages and Tools

The solutions use a combination of:

- R
- Python
- Pandas
- FastAPI / Uvicorn
- Pharmaverse example clinical trial data

Package requirements and any question-specific setup instructions are documented
within the relevant question folders.

## Assessment Overview

- **Question 1 – Descriptive Statistics:** R package for generating descriptive statistics, including documentation and unit tests.
- **Question 2 – SDTM:** Creation of an SDTM DS domain using metadata-driven programming.
- **Question 3 – ADaM:** Creation of an ADSL dataset.
- **Question 4 – Tables, Listings and Graphics:** AE summary table, visualisations and subject-level listings.
- **Question 5 – API:** REST API for querying clinical trial data, with interactive Swagger documentation.
- **Question 6 – GenAI:** Natural-language clinical data assistant using a mocked LLM response and Pandas query execution, with additional support for compound filters.