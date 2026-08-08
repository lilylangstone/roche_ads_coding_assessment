#################################################
# Question 4: TLG - Adverse Events Reporting
# 01 - Treatment-Emergent AE Summary Table
#################################################

library(pharmaverseadam)
library(dplyr)
library(tidyr)
library(gtsummary)
library(gt)


#################################################
# Load input datasets
#################################################

adae <- pharmaverseadam::adae
adsl <- pharmaverseadam::adsl


#################################################
# Define treatment order
#################################################

treatment_order <- c(
  "Placebo",
  "Xanomeline High Dose",
  "Xanomeline Low Dose"
)


#################################################
# Prepare safety population
#################################################

# Use the safety population from ADSL to provide the
# subject-level denominators for each treatment group.

safety <- adsl %>%
  filter(
    SAFFL == "Y",
    ACTARM %in% treatment_order
  ) %>%
  mutate(
    ACTARM = factor(
      ACTARM,
      levels = treatment_order
    )
  ) %>%
  select(
    USUBJID,
    ACTARM
  )


#################################################
# Prepare treatment-emergent adverse events
#################################################

# Restrict ADAE to treatment-emergent events in
# subjects belonging to the safety population.

teae <- adae %>%
  filter(
    TRTEMFL == "Y",
    USUBJID %in% safety$USUBJID,
    ACTARM %in% treatment_order
  ) %>%
  mutate(
    ACTARM = factor(
      ACTARM,
      levels = treatment_order
    )
  )


#################################################
# Derive treatment denominators
#################################################

trt_n <- safety %>%
  count(
    ACTARM,
    name = "N"
  )

stopifnot(
  sum(trt_n$N) == nrow(safety)
)

#################################################
# Determine SOC display order
#################################################

# Subjects are counted once within each SOC regardless
# of how many individual AE records they experienced.
#
# SOCs are ordered by descending overall subject
# frequency across the safety population.

soc_order <- teae %>%
  distinct(
    USUBJID,
    AESOC
  ) %>%
  count(
    AESOC,
    name = "TOTAL_N"
  ) %>%
  arrange(
    desc(TOTAL_N),
    AESOC
  ) %>%
  mutate(
    SOC_ORDER = row_number(),
    
    ROW_ID = sprintf(
      "SOC_%03d",
      SOC_ORDER
    )
  )


#################################################
# Determine preferred-term display order
#################################################

# Subjects are counted once within each SOC/AETERM.
#
# Preferred terms are ordered by descending overall
# subject frequency within their corresponding SOC.

term_order <- teae %>%
  distinct(
    USUBJID,
    AESOC,
    AETERM
  ) %>%
  count(
    AESOC,
    AETERM,
    name = "TOTAL_N"
  ) %>%
  left_join(
    soc_order %>%
      select(
        AESOC,
        SOC_ORDER
      ),
    by = "AESOC"
  ) %>%
  arrange(
    SOC_ORDER,
    desc(TOTAL_N),
    AETERM
  ) %>%
  group_by(AESOC) %>%
  mutate(
    TERM_ORDER = row_number(),
    
    ROW_ID = sprintf(
      "TERM_%03d_%03d",
      SOC_ORDER,
      TERM_ORDER
    )
  ) %>%
  ungroup()


#################################################
# Define table rows
#################################################

# The first row represents subjects with at least one
# treatment-emergent adverse event.

overall_row <- tibble(
  ROW_ID = "TEAE_ANY",
  LABEL = "Treatment Emergent AEs",
  ROW_TYPE = "OVERALL",
  DISPLAY_ORDER = 0
)


# SOC rows are displayed without indentation.

soc_rows <- soc_order %>%
  transmute(
    ROW_ID,
    LABEL = AESOC,
    ROW_TYPE = "SOC",
    DISPLAY_ORDER =
      SOC_ORDER * 1000
  )


# Preferred terms are indented beneath their SOC.
#
# Non-breaking spaces are used because normal leading
# spaces are collapsed when rendered as HTML.

term_rows <- term_order %>%
  transmute(
    ROW_ID,
    
    LABEL = paste0(
      "\u00A0\u00A0\u00A0\u00A0",
      AETERM
    ),
    
    ROW_TYPE = "TERM",
    
    DISPLAY_ORDER =
      SOC_ORDER * 1000 +
      TERM_ORDER
  )


row_definitions <- bind_rows(
  overall_row,
  soc_rows,
  term_rows
) %>%
  arrange(
    DISPLAY_ORDER
  )


#################################################
# Create subject-level TEAE indicators
#################################################

# Overall TEAE indicator.

overall_indicators <- teae %>%
  distinct(
    USUBJID,
    ACTARM
  ) %>%
  mutate(
    ROW_ID = "TEAE_ANY"
  )


# SOC indicators.

soc_indicators <- teae %>%
  distinct(
    USUBJID,
    ACTARM,
    AESOC
  ) %>%
  left_join(
    soc_order %>%
      select(
        AESOC,
        ROW_ID
      ),
    by = "AESOC"
  ) %>%
  select(
    USUBJID,
    ACTARM,
    ROW_ID
  )


# Preferred-term indicators.

term_indicators <- teae %>%
  distinct(
    USUBJID,
    ACTARM,
    AESOC,
    AETERM
  ) %>%
  left_join(
    term_order %>%
      select(
        AESOC,
        AETERM,
        ROW_ID
      ),
    by = c(
      "AESOC",
      "AETERM"
    )
  ) %>%
  select(
    USUBJID,
    ACTARM,
    ROW_ID
  )


#################################################
# Create subject-level analysis structure
#################################################

# Each ROW_ID is converted to a Y/N subject-level
# indicator. This allows gtsummary to calculate n (%)
# using the safety-population treatment denominators.

subject_flags <- bind_rows(
  overall_indicators,
  soc_indicators,
  term_indicators
) %>%
  distinct(
    USUBJID,
    ACTARM,
    ROW_ID
  ) %>%
  mutate(
    VALUE = "Y"
  ) %>%
  pivot_wider(
    names_from = ROW_ID,
    values_from = VALUE,
    values_fill = "N"
  )


analysis_data <- safety %>%
  left_join(
    subject_flags,
    by = c(
      "USUBJID",
      "ACTARM"
    )
  )


#################################################
# Replace missing indicators with N
#################################################

row_ids <- row_definitions$ROW_ID

analysis_data <- analysis_data %>%
  mutate(
    across(
      all_of(row_ids),
      ~ replace_na(
        .x,
        "N"
      )
    )
  )


#################################################
# QC subject-level analysis dataset
#################################################

# There must remain one row per safety subject.

stopifnot(
  nrow(analysis_data) ==
    nrow(safety)
)

stopifnot(
  anyDuplicated(
    analysis_data$USUBJID
  ) == 0
)


# Confirm treatment denominators.

stopifnot(
  sum(
    analysis_data$ACTARM ==
      "Placebo"
  ) == 86
)

stopifnot(
  sum(
    analysis_data$ACTARM ==
      "Xanomeline High Dose"
  ) == 72
)

stopifnot(
  sum(
    analysis_data$ACTARM ==
      "Xanomeline Low Dose"
  ) == 96
)


#################################################
# Prepare gtsummary specifications
#################################################

label_list <- setNames(
  as.list(
    row_definitions$LABEL
  ),
  row_definitions$ROW_ID
)


type_list <- setNames(
  rep(
    list("dichotomous"),
    length(row_ids)
  ),
  row_ids
)


value_list <- setNames(
  rep(
    list("Y"),
    length(row_ids)
  ),
  row_ids
)


#################################################
# Create AE summary table
#################################################

ae_summary_table <- analysis_data %>%
  select(
    ACTARM,
    all_of(row_ids)
  ) %>%
  
  tbl_summary(
    by = ACTARM,
    
    include =
      all_of(row_ids),
    
    type =
      type_list,
    
    value =
      value_list,
    
    label =
      label_list,
    
    statistic =
      everything() ~ "{n} ({p}%)",
    
    # Display count and percentage as whole numbers.
    digits =
      everything() ~ c(0, 0),
    
    missing = "no",
    
    percent = "column"
  ) %>%
  
  # Split the descriptor heading across two lines and
  # indent the second line slightly.
  modify_header(
    label ~ paste0(
      "**Primary System Organ Class**",
      "<br>",
      "&nbsp;&nbsp;&nbsp;&nbsp;",
      "**Reported Term for the Adverse Event**"
    )
  )


#################################################
# Convert to GT and format
#################################################

ae_summary_gt <- ae_summary_table %>%
  as_gt() %>%
  
  tab_header(
    title =
      "Summary of Treatment-Emergent Adverse Events",
    
    subtitle =
      "Safety Population"
  ) %>%
  
  # Give treatment columns enough width to keep
  # n (%) values together on one line.
  cols_width(
    stat_1 ~ px(145),
    stat_2 ~ px(175),
    stat_3 ~ px(175)
  ) %>%
  
  # Prevent the n (%) statistics from wrapping.
  tab_style(
    style = cell_text(
      whitespace = "nowrap"
    ),
    locations = cells_body(
      columns = c(
        stat_1,
        stat_2,
        stat_3
      )
    )
  ) %>%
  
  tab_source_note(
    source_note =
      paste0(
        "Values are number of subjects (percentage). ",
        "A subject is counted once within each category."
      )
  )


#################################################
# Create output directory
#################################################

dir.create(
  "question_4_tlg/output",
  showWarnings = FALSE,
  recursive = TRUE
)


#################################################
# Save HTML output
#################################################

gtsave(
  ae_summary_gt,
  
  filename =
    "question_4_tlg/output/ae_summary_table.html"
)


#################################################
# Final QC
#################################################

# Confirm every safety subject is represented.

stopifnot(
  nrow(analysis_data) == 254
)


# Confirm TEAE indicator contains Y/N only.

stopifnot(
  all(
    analysis_data$TEAE_ANY %in%
      c(
        "Y",
        "N"
      )
  )
)