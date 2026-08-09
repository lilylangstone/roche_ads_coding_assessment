# Question 4: TLG - Adverse Events Reporting

## Objective

Create Tables, Listings, and Graphs (TLGs) for adverse event reporting using
`pharmaverseadam::adae` and `pharmaverseadam::adsl`.

The outputs demonstrate treatment-emergent adverse event summarisation,
AE visualisation using `ggplot2`, and creation of a detailed clinical listing.

## Folder Structure

```text
question_4_tlg/
├── 01_create_ae_summary_table.R
├── 02_create_visualizations.R
├── 03_create_listings.R
├── README.md
└── output/
    ├── ae_summary_table.html
    ├── ae_severity_distribution.png
    ├── top_10_ae_incidence.png
    └── ae_listings.html