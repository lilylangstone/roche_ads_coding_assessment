#################################################
# Question 2: SDTM DS Domain Creation
#################################################

# Create the SDTM Disposition (DS) domain using sdtm.oak


#################################################
# Load packages and input data
#################################################

library(sdtm.oak)
library(pharmaverseraw)
library(pharmaversesdtm)
library(dplyr)

# Load raw Subject Disposition data
ds_raw <- pharmaverseraw::ds_raw

# Load DM for study day derivation
dm <- pharmaversesdtm::dm

# Load SV for visit information
sv <- pharmaversesdtm::sv

# Load study controlled terminology
study_ct <- read.csv(
  "question_2_sdtm/metadata/sdtm_ct.csv"
)


#################################################
# Create OAK identifier variables
#################################################

ds_raw <- ds_raw %>%
  generate_oak_id_vars(
    pat_var = "PATNUM",
    raw_src = "ds_raw"
  )


#################################################
# Controlled terminology
#################################################

# Completion/Reason for Non-Completion codelist
ncomplt_code <- "C66727"


#################################################
# Prepare raw values for SDTM mapping
#################################################

# Preserve original raw variables and create working
# variables where source values require standardisation.

ds_raw <- ds_raw %>%
  mutate(
    
    # Derive disposition category first, since the
    # applicable DSDECOD terminology depends on DSCAT.
    DSCAT_INPUT = case_when(
      
      IT.DSDECOD == "Randomized" ~
        "PROTOCOL MILESTONE",
      
      !is.na(OTHERSP) ~
        "OTHER EVENT",
      
      !is.na(IT.DSTERM) ~
        "DISPOSITION EVENT",
      
      TRUE ~ NA_character_
    ),
    
    # Prepare Completion/Reason for Non-Completion
    # values for disposition events only.
    DSDECOD_NCOMPLT_INPUT = case_when(
      
      DSCAT_INPUT != "DISPOSITION EVENT" ~
        NA_character_,
      
      IT.DSDECOD == "Completed" ~
        "Complete",
      
      IT.DSDECOD == "Study Terminated by Sponsor" ~
        "Study Terminated By Sponsor",
      
      IT.DSDECOD == "Lost to Follow-Up" ~
        "Lost To Follow-Up",
      
      IT.DSDECOD == "Screen Failure" ~
        "Trial Screen Failure",
      
      TRUE ~ IT.DSDECOD
    ),
    
    # Standardise date separators while preserving
    # the original raw values.
    DSSTDAT_INPUT = gsub(
      "/",
      "-",
      IT.DSSTDAT
    ),
    
    DSDTCOL_INPUT = gsub(
      "/",
      "-",
      DSDTCOL
    )
  )


#################################################
# Map topic variable
#################################################

# Map reported disposition term.
ds <- assign_no_ct(
  raw_dat = ds_raw,
  raw_var = "IT.DSTERM",
  tgt_var = "DSTERM",
  id_vars = oak_id_vars()
)

# OTHERSP contains additional disposition events.
ds <- ds %>%
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "OTHERSP",
    tgt_var = "DSTERM",
    id_vars = oak_id_vars()
  )


#################################################
# Validate disposition event controlled terminology
#################################################

ncomplt_ct <- study_ct %>%
  filter(
    codelist_code == ncomplt_code
  )

# Identify values accepted as inputs to the CT mapping.
valid_ncomplt_terms <- unique(
  c(
    ncomplt_ct$term_value,
    ncomplt_ct$collected_value,
    ncomplt_ct$term_synonyms
  )
)

valid_ncomplt_terms <- valid_ncomplt_terms[
  !is.na(valid_ncomplt_terms)
]

# Identify any source values which cannot be mapped.
unmatched_ncomplt_terms <- setdiff(
  unique(
    na.omit(
      ds_raw$DSDECOD_NCOMPLT_INPUT
    )
  ),
  valid_ncomplt_terms
)

# Warn if a future input dataset introduces terminology
# that is not represented in the supplied study CT.
if (length(unmatched_ncomplt_terms) > 0) {
  
  warning(
    paste0(
      "The following disposition event value(s) could not be ",
      "matched to NCOMPLT controlled terminology: ",
      paste(
        unmatched_ncomplt_terms,
        collapse = ", "
      )
    )
  )
}


#################################################
# Map qualifier and timing variables
#################################################

ds <- ds %>%
  
  # DISPOSITION EVENT:
  # Map using Completion/Reason for Non-Completion CT.
  assign_ct(
    raw_dat = ds_raw,
    raw_var = "DSDECOD_NCOMPLT_INPUT",
    tgt_var = "DSDECOD",
    ct_spec = study_ct,
    ct_clst = ncomplt_code,
    id_vars = oak_id_vars()
  ) %>%
  
  # OTHER EVENT:
  # Sponsor terminology is permitted.
  assign_no_ct(
    raw_dat = ds_raw,
    raw_var = "OTHERSP",
    tgt_var = "DSDECOD",
    id_vars = oak_id_vars()
  ) %>%
  
  # Map date/time of collection.
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = c(
      "DSDTCOL_INPUT",
      "DSTMCOL"
    ),
    tgt_var = "DSDTC",
    raw_fmt = c(
      "m-d-y",
      "H:M"
    ),
    id_vars = oak_id_vars()
  ) %>%
  
  # Map disposition event start date.
  assign_datetime(
    raw_dat = ds_raw,
    raw_var = "DSSTDAT_INPUT",
    tgt_var = "DSSTDTC",
    raw_fmt = "m-d-y",
    id_vars = oak_id_vars()
  )


#################################################
# Create SDTM derived variables
#################################################

ds <- ds %>%
  mutate(
    
    STUDYID = ds_raw$STUDY,
    
    DOMAIN = "DS",
    
    USUBJID = paste0(
      "01-",
      ds_raw$PATNUM
    ),
    
    DSTERM = toupper(
      DSTERM
    ),
    
    DSDECOD = toupper(
      DSDECOD
    ),
    
    # Apply derived disposition category.
    DSCAT = ds_raw$DSCAT_INPUT,
    
    # RANDOMIZED is a protocol milestone and is
    # handled separately from NCOMPLT terminology.
    DSDECOD = case_when(
      
      DSCAT == "PROTOCOL MILESTONE" ~
        "RANDOMIZED",
      
      TRUE ~ DSDECOD
    )
  )


#################################################
# Add visit information from SV
#################################################

# Match the raw clinical encounter to the corresponding
# protocol-defined visit in Subject Visits.

ds <- ds %>%
  mutate(
    VISIT_JOIN = toupper(
      ds_raw$INSTANCE
    )
  )

sv_visit <- sv %>%
  mutate(
    VISIT_JOIN = toupper(
      VISIT
    )
  ) %>%
  select(
    USUBJID,
    VISITNUM,
    VISIT,
    VISIT_JOIN
  )

# Merge protocol visit information from Subject Visits.
# Each DS record should map to no more than one SV visit
# for the subject.
ds <- ds %>%
  left_join(
    sv_visit,
    by = c(
      "USUBJID" = "USUBJID",
      "VISIT_JOIN" = "VISIT_JOIN"
    ),
    relationship = "many-to-one"
  ) %>%
  select(
    -VISIT_JOIN
  )

#################################################
# Derive sequence number and study day
#################################################

ds <- ds %>%
  
  derive_seq(
    tgt_var = "DSSEQ",
    rec_vars = c(
      "USUBJID",
      "DSSTDTC",
      "VISITNUM",
      "DSTERM"
    )
  ) %>%
  
  # SDTM study day is relative to DM.RFSTDTC.
  derive_study_day(
    sdtm_in = .,
    dm_domain = dm,
    tgdt = "DSSTDTC",
    refdt = "RFSTDTC",
    study_day_var = "DSSTDY"
  )


#################################################
# Convert SDTM ISO 8601 variables to character
#################################################

# SDTM defines DSDTC and DSSTDTC as character
# variables containing ISO 8601 values.

ds <- ds %>%
  mutate(
    DSDTC = as.character(
      DSDTC
    ),
    
    DSSTDTC = as.character(
      DSSTDTC
    )
  )


#################################################
# Select final variables in SDTM order
#################################################

ds <- ds %>%
  select(
    STUDYID,
    DOMAIN,
    USUBJID,
    DSSEQ,
    DSTERM,
    DSDECOD,
    DSCAT,
    VISITNUM,
    VISIT,
    DSDTC,
    DSSTDTC,
    DSSTDY
  )


#################################################
# Apply SDTM variable labels
#################################################

attr(ds$STUDYID, "label") <-
  "Study Identifier"

attr(ds$DOMAIN, "label") <-
  "Domain Abbreviation"

attr(ds$USUBJID, "label") <-
  "Unique Subject Identifier"

attr(ds$DSSEQ, "label") <-
  "Sequence Number"

attr(ds$DSTERM, "label") <-
  "Reported Term for the Disposition Event"

attr(ds$DSDECOD, "label") <-
  "Standardized Disposition Term"

attr(ds$DSCAT, "label") <-
  "Category for Disposition Event"

attr(ds$VISITNUM, "label") <-
  "Visit Number"

attr(ds$VISIT, "label") <-
  "Visit Name"

attr(ds$DSDTC, "label") <-
  "Date/Time of Collection"

attr(ds$DSSTDTC, "label") <-
  "Start Date/Time of Disposition Event"

attr(ds$DSSTDY, "label") <-
  "Study Day of Start of Disposition Event"


#################################################
# QC checks
#################################################

# Confirm the number of output observations agrees
# with the input raw disposition dataset.
stopifnot(
  nrow(ds) == nrow(ds_raw)
)

# Confirm required variables are populated.
stopifnot(
  sum(is.na(ds$DSTERM)) == 0
)

stopifnot(
  sum(is.na(ds$DSDECOD)) == 0
)

stopifnot(
  sum(is.na(ds$DSCAT)) == 0
)


#################################################
# External data consistency checks
#################################################

# Warn if any DS records fail to map to a Subject Visit.
if (any(is.na(ds$VISITNUM) | is.na(ds$VISIT))) {
  
  warning(
    sum(
      is.na(ds$VISITNUM) |
        is.na(ds$VISIT)
    ),
    " DS record(s) could not be matched to SV visit information."
  )
}

# Identify the subject reference start date used
# for study-day derivation.
rfstdtc_qc <- dm$RFSTDTC[
  match(
    ds$USUBJID,
    dm$USUBJID
  )
]

# Warn only when DSSTDY is unexpectedly missing:
# DSSTDTC and RFSTDTC are both available, but no
# study day was derived.
missing_study_day <- (
  is.na(ds$DSSTDY) &
    !is.na(ds$DSSTDTC) &
    ds$DSSTDTC != "" &
    !is.na(rfstdtc_qc) &
    rfstdtc_qc != ""
)

if (any(missing_study_day)) {
  
  warning(
    sum(missing_study_day),
    " DS record(s) have DSSTDTC and RFSTDTC populated ",
    "but DSSTDY could not be derived."
  )
}


#################################################
# Structural QC
#################################################

# Confirm DSSEQ uniquely identifies records within subject.
stopifnot(
  anyDuplicated(
    ds[, c(
      "USUBJID",
      "DSSEQ"
    )]
  ) == 0
)

# Confirm expected DSCAT values only.
stopifnot(
  all(
    unique(ds$DSCAT) %in% c(
      "DISPOSITION EVENT",
      "PROTOCOL MILESTONE",
      "OTHER EVENT"
    )
  )
)

# Confirm VISITNUM and VISIT have a one-to-one
# relationship in the resulting DS dataset.
visit_qc <- ds %>%
  distinct(
    VISITNUM,
    VISIT
  )

stopifnot(
  visit_qc %>%
    count(VISITNUM) %>%
    filter(n > 1) %>%
    nrow() == 0
)

stopifnot(
  visit_qc %>%
    count(VISIT) %>%
    filter(n > 1) %>%
    nrow() == 0
)