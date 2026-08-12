#################################################
# Question 3: ADaM ADSL Dataset Creation
#################################################

library(admiral)
library(pharmaversesdtm)
library(dplyr)
library(stringr)


#################################################
# Load SDTM input datasets
#################################################

dm <- pharmaversesdtm::dm
vs <- pharmaversesdtm::vs
ex <- pharmaversesdtm::ex
ds <- pharmaversesdtm::ds
ae <- pharmaversesdtm::ae


#################################################
# Create ADSL base
#################################################

# ADSL contains one record per subject.
adsl <- dm

#################################################
# Derive age groups
#################################################

adsl <- adsl %>%
  mutate(
    AGEGR9 = case_when(
      AGE < 18 ~ "<18",
      AGE >= 18 & AGE <= 50 ~ "18 - 50",
      AGE > 50 ~ ">50",
      TRUE ~ NA_character_
    ),
    
    AGEGR9N = case_when(
      AGE < 18 ~ 1,
      AGE >= 18 & AGE <= 50 ~ 2,
      AGE > 50 ~ 3,
      TRUE ~ NA_real_
    )
  )


#################################################
# Prepare exposure data
#################################################

# Convert EXSTDTC to numeric datetime.
# Date must be complete; missing time is imputed to 00:00:00.
ex_ext <- ex %>%
  derive_vars_dtm(
    dtc = EXSTDTC,
    new_vars_prefix = "EXST",
    time_imputation = "first"
  )


#################################################
# Derive treatment start datetime
#################################################

# A valid dose is:
# EXDOSE > 0, OR
# EXDOSE = 0 and EXTRT contains PLACEBO.
#
# The earliest valid exposure determines TRTSDTM.

adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    
    filter_add =
      (
        EXDOSE > 0 |
          (
            EXDOSE == 0 &
              str_detect(
                toupper(EXTRT),
                "PLACEBO"
              )
          )
      ) &
      !is.na(EXSTDTM),
    
    new_vars = exprs(
      TRTSDTM = EXSTDTM,
      TRTSTMF = EXSTTMF
    ),
    
    order = exprs(
      EXSTDTM,
      EXSEQ
    ),
    
    mode = "first",
    
    by_vars = exprs(
      STUDYID,
      USUBJID
    )
  )


#################################################
# Derive treatment end datetime
#################################################

# Prepare EXENDTC using the same datetime approach.
ex_ext <- ex_ext %>%
  derive_vars_dtm(
    dtc = EXENDTC,
    new_vars_prefix = "EXEN",
    time_imputation = "last"
  )

# The latest valid exposure determines TRTEDTM.
adsl <- adsl %>%
  derive_vars_merged(
    dataset_add = ex_ext,
    
    filter_add =
      (
        EXDOSE > 0 |
          (
            EXDOSE == 0 &
              str_detect(
                toupper(EXTRT),
                "PLACEBO"
              )
          )
      ) &
      !is.na(EXENDTM),
    
    new_vars = exprs(
      TRTEDTM = EXENDTM,
      TRTETMF = EXENTMF
    ),
    
    order = exprs(
      EXENDTM,
      EXSEQ
    ),
    
    mode = "last",
    
    by_vars = exprs(
      STUDYID,
      USUBJID
    )
  )


#################################################
# Derive treatment dates from datetimes
#################################################

adsl <- adsl %>%
  derive_vars_dtm_to_dt(
    source_vars = exprs(
      TRTSDTM,
      TRTEDTM
    )
  )


#################################################
# Derive Intent-to-Treat Population Flag
#################################################

# ITTFL = Y if ARM is populated, otherwise N.
adsl <- adsl %>%
  mutate(
    ITTFL = if_else(
      !is.na(ARM) & ARM != "",
      "Y",
      "N"
    )
  )

#################################################
# Derive Abnormal Systolic Blood Pressure Flag
#################################################

# Y if the subject has at least one supine systolic
# blood pressure result <100 or >=140 mmHg.
adsl <- adsl %>%
  derive_var_merged_exist_flag(
    dataset_add = vs,
    
    by_vars = exprs(
      STUDYID,
      USUBJID
    ),
    
    new_var = ABNSBPFL,
    
    condition =
      VSTESTCD == "SYSBP" &
      toupper(VSPOS) == "SUPINE" & # Specifies 'Supine' but not in detailed section
      VSSTRESU == "mmHg" &
      !is.na(VSSTRESN) &
      (
        VSSTRESN < 100 |
          VSSTRESN >= 140
      ),
    
    true_value = "Y",
    false_value = "N",
    missing_value = "N"
  )

#################################################
# Derive Cardiac Population Flag
#################################################

# Y if the subject has at least one AE where
# AESOC = CARDIAC DISORDERS, otherwise missing.
adsl <- adsl %>%
  derive_var_merged_exist_flag(
    dataset_add = ae,
    
    by_vars = exprs(
      STUDYID,
      USUBJID
    ),
    
    new_var = CARPOPFL,
    
    condition =
      toupper(AESOC) ==
      "CARDIAC DISORDERS",
    
    true_value = "Y",
    false_value = NA_character_,
    missing_value = NA_character_
  )


#################################################
# Prepare dates for Last Known Alive derivation
#################################################

# Vital signs date.
vs_ext <- vs %>%
  derive_vars_dt(
    dtc = VSDTC,
    new_vars_prefix = "VS"
  )

# Adverse event onset date.
ae_ext <- ae %>%
  derive_vars_dt(
    dtc = AESTDTC,
    new_vars_prefix = "AEST"
  )

# Disposition event date.
ds_ext <- ds %>%
  derive_vars_dt(
    dtc = DSSTDTC,
    new_vars_prefix = "DSST"
  )


#################################################
# Derive latest vital signs date
#################################################

# Last complete vital signs date with a valid result.
adsl <- adsl %>%
  derive_vars_merged_summary(
    dataset_add = vs_ext,
    
    by_vars = exprs(
      STUDYID,
      USUBJID
    ),
    
    filter_add =
      (
        !is.na(VSSTRESN) |
          (
            !is.na(VSSTRESC) &
              VSSTRESC != ""
          )
      ) &
      !is.na(VSDT),
    
    new_vars = exprs(
      LSTVSDT = max(VSDT)
    )
  )


#################################################
# Derive latest AE onset date
#################################################

adsl <- adsl %>%
  derive_vars_merged_summary(
    dataset_add = ae_ext,
    
    by_vars = exprs(
      STUDYID,
      USUBJID
    ),
    
    filter_add =
      !is.na(AESTDT),
    
    new_vars = exprs(
      LSTAEDT = max(AESTDT)
    )
  )


#################################################
# Derive latest disposition date
#################################################

# Roche specifies any disposition record.
adsl <- adsl %>%
  derive_vars_merged_summary(
    dataset_add = ds_ext,
    
    by_vars = exprs(
      STUDYID,
      USUBJID
    ),
    
    filter_add =
      !is.na(DSSTDT),
    
    new_vars = exprs(
      LSTDSDT = max(DSSTDT)
    )
  )


#################################################
# Derive Last Known Alive Date
#################################################

# Maximum of:
# - last valid VS date
# - last AE onset date
# - last DS date
# - last valid treatment administration date
adsl <- adsl %>%
  mutate(
    LSTALVDT = pmax(
      LSTVSDT,
      LSTAEDT,
      LSTDSDT,
      TRTEDT,
      na.rm = TRUE
    )
  )


#################################################
# QC checks
#################################################

# ADSL must contain one record per subject.
stopifnot(
  anyDuplicated(adsl$USUBJID) == 0
)

# Confirm row count matches DM.
stopifnot(
  nrow(adsl) == nrow(dm)
)

# AGEGR9 and AGEGR9N must have a one-to-one relationship.
agegr_qc <- adsl %>%
  distinct(
    AGEGR9,
    AGEGR9N
  )

stopifnot(
  agegr_qc %>%
    count(AGEGR9) %>%
    filter(n > 1) %>%
    nrow() == 0
)

stopifnot(
  agegr_qc %>%
    count(AGEGR9N) %>%
    filter(n > 1) %>%
    nrow() == 0
)

# ITTFL must always be Y or N.
stopifnot(
  all(
    adsl$ITTFL %in% c(
      "Y",
      "N"
    )
  )
)

# ABNSBPFL must always be Y or N.
stopifnot(
  all(
    adsl$ABNSBPFL %in% c(
      "Y",
      "N"
    )
  )
)

# CARPOPFL must be Y or missing.
stopifnot(
  all(
    is.na(adsl$CARPOPFL) |
      adsl$CARPOPFL == "Y"
  )
)

#################################################
# Labels
#################################################

attr(adsl$ITTFL, "label")   <- "Intent-To-Treat Population Flag"
attr(adsl$TRTSDT, "label")  <- "Date of First Exposure to Treatment"
attr(adsl$TRTSDTM, "label") <- "Datetime of First Exposure to Treatment"
attr(adsl$TRTSTMF, "label") <- "Time of First Exposure Imput. Flag"
attr(adsl$TRTEDT, "label")  <- "Date of Last Exposure to Treatment"
attr(adsl$TRTEDTM, "label") <- "Datetime of Last Exposure to Treatment"
attr(adsl$TRTETMF, "label") <- "Time of Last Exposure Imput. Flag"
attr(adsl$AGEGR9, "label")    <- "Age Group"
attr(adsl$AGEGR9N, "label")   <- "Age Group (N)"
attr(adsl$ABNSBPFL, "label")  <- "Abnormal Systolic BP Flag"
attr(adsl$CARPOPFL, "label")  <- "Cardiac AE Population Flag"
attr(adsl$LSTALVDT, "label")  <- "Date Last Known Alive"

#################################################
# Final ADSL structure
#################################################

adsl <- adsl %>%
  select(
    # Identifiers
    STUDYID,
    USUBJID,
    SUBJID,
    SITEID,
    
    # Population flags
    ITTFL,
    ABNSBPFL,
    CARPOPFL,
    
    # Demographics and subject characteristics
    AGE,
    AGEU,
    AGEGR9,
    AGEGR9N,
    SEX,
    RACE,
    ETHNIC,
    COUNTRY,
    
    # Treatment assignment
    ARMCD,
    ARM,
    ACTARMCD,
    ACTARM,
    ARMNRS,
    ACTARMUD,
    
    # Treatment dates and times
    TRTSDT,
    TRTSDTM,
    TRTSTMF,
    TRTEDT,
    TRTEDTM,
    TRTETMF,
    
    # Death / important subject dates
    DTHDTC,
    DTHFL,
    LSTALVDT
  )