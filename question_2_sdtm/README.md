# Question 2 – SDTM DS Domain

This solution creates the SDTM Disposition (DS) domain using
`sdtm.oak`, the supplied study controlled terminology, and
Pharmaverse example source data.

## Inputs

- `pharmaverseraw::ds_raw` – source disposition data
- `pharmaversesdtm::dm` – subject-level reference information
- `pharmaversesdtm::sv` – protocol visit information
- `metadata/sdtm_ct.csv` – supplied study controlled terminology

## Output

The program derives the requested SDTM DS variables:

- STUDYID
- DOMAIN
- USUBJID
- DSSEQ
- DSTERM
- DSDECOD
- DSCAT
- VISITNUM
- VISIT
- DSDTC
- DSSTDTC
- DSSTDY

## Program

Run:

`02_create_ds_domain.R`

The program includes checks for controlled terminology,
visit mapping, study-day derivation, record uniqueness,
and expected DS categories.