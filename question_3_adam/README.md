# Question 3 – ADaM ADSL Dataset

This solution creates the ADaM Subject-Level Analysis Dataset (ADSL) using SDTM source data, the `{admiral}` package, and tidyverse tools.

## Inputs

The program uses the following SDTM datasets from `{pharmaversesdtm}`:

- `dm` – subject-level demographic and treatment-arm information
- `ex` – exposure data
- `vs` – vital signs
- `ae` – adverse events
- `ds` – disposition

`DM` is used as the base dataset for ADSL, with one record per subject.

## Derived Variables

The program derives the variables requested in the assessment:

- `AGEGR9` – age group:
  - `<18`
  - `18 - 50`
  - `>50`
- `AGEGR9N` – numeric age group:
  - `1`
  - `2`
  - `3`
  
- `TRT01P` – planned treatment for Period 01, derived from `DM.ARM`
- `TRT01A` – actual treatment for Period 01, derived from `DM.ACTARM`

- `TRTSDTM` – datetime of first valid treatment exposure
- `TRTSTMF` – treatment start time imputation flag
- `TRTEDTM` – datetime of last valid treatment exposure
- `TRTETMF` – treatment end time imputation flag
- `TRTSDT` – date of first valid treatment exposure
- `TRTEDT` – date of last valid treatment exposure

A valid dose is defined as:

- `EXDOSE > 0`, or
- `EXDOSE == 0` where `EXTRT` contains `"PLACEBO"`

Missing treatment times are handled using `{admiral}` datetime derivation functions.

- `ITTFL` – `"Y"` where `DM.ARM` is populated, otherwise `"N"`

- `ABNSBPFL` – `"Y"` where the subject has at least one:
  - systolic blood pressure (`VSTESTCD = "SYSBP"`)
  - supine measurement (`VSPOS = "SUPINE"`)
  - result in `mmHg`
  - `VSSTRESN < 100` or `VSSTRESN >= 140`

  Otherwise `"N"`.

- `CARPOPFL` – `"Y"` where the subject has at least one adverse event with:
  - `AESOC = "CARDIAC DISORDERS"`

  Otherwise missing.

- `LSTALVDT` – last known alive date, derived as the latest qualifying date from:
  - valid vital-sign assessment
  - adverse-event onset
  - disposition record
  - last valid treatment exposure

## Use of `{admiral}`

Where appropriate, standard `{admiral}` functions are used for ADaM derivations, including:

- `derive_vars_dtm()`
- `derive_vars_dt()`
- `derive_vars_merged()`
- `derive_vars_dtm_to_dt()`
- `derive_var_merged_exist_flag()`
- `derive_vars_merged_summary()`

Tidyverse functions are used for study-specific categorisation, flags, filtering, and QC.

## QC

The program includes checks to confirm:

- one ADSL record per subject
- ADSL row count agrees with DM
- `AGEGR9` and `AGEGR9N` have a one-to-one relationship
- population flags contain only expected values
- subject-level derivations remain structurally valid

## Program

Run:

`question_3_adam/create_adsl.R`