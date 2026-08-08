#################################################
# Question 4: TLG - Adverse Events Reporting
# 03 - Detailed Adverse Event Listing
#################################################

library(pharmaverseadam)
library(dplyr)
library(gt)


#################################################
# Load input dataset
#################################################

adae <- pharmaverseadam::adae


#################################################
# Prepare treatment-emergent adverse events
#################################################

# Restrict to treatment-emergent adverse events,
# exclude screen failure patients, and sort by
# subject and event start date.

ae_listing_data <- adae %>%
  filter(
    TRTEMFL == "Y",
    ACTARM != "Screen Failure"
  ) %>%
  arrange(
    USUBJID,
    ASTDT,
    ASTDTM,
    AESEQ
  ) %>%
  select(
    USUBJID,
    ACTARM,
    AETERM,
    AESEV,
    AEREL,
    AESTDTC,
    AEENDTC
  )


#################################################
# QC
#################################################

# Confirm every record in the listing is
# treatment-emergent and is not a screen failure.

stopifnot(
  nrow(ae_listing_data) ==
    nrow(
      adae %>%
        filter(
          TRTEMFL == "Y",
          ACTARM != "Screen Failure"
        )
    )
)


# Confirm required variables are present.

stopifnot(
  all(
    c(
      "USUBJID",
      "ACTARM",
      "AETERM",
      "AESEV",
      "AEREL",
      "AESTDTC",
      "AEENDTC"
    ) %in%
      names(ae_listing_data)
  )
)


# Confirm screen failures are excluded.

stopifnot(
  !any(
    ae_listing_data$ACTARM ==
      "Screen Failure",
    na.rm = TRUE
  )
)


#################################################
# Prepare display dataset
#################################################

# Repeated Subject ID and Treatment values are
# suppressed after the first AE row for each subject,
# following standard clinical listing presentation.

ae_listing_display <- ae_listing_data %>%
  group_by(
    USUBJID
  ) %>%
  mutate(
    USUBJID_DISPLAY = if_else(
      row_number() == 1,
      USUBJID,
      ""
    ),
    
    ACTARM_DISPLAY = if_else(
      row_number() == 1,
      ACTARM,
      ""
    )
  ) %>%
  ungroup() %>%
  transmute(
    USUBJID = USUBJID_DISPLAY,
    ACTARM = ACTARM_DISPLAY,
    AETERM,
    AESEV,
    AEREL,
    AESTDTC,
    AEENDTC
  )


#################################################
# Create AE listing
#################################################

ae_listing_gt <- ae_listing_display %>%
  
  gt() %>%
  
  #################################################
# Column labels
#################################################

cols_label(
  USUBJID =
    "Unique Subject Identifier",
  
  ACTARM =
    "Description of Actual Arm",
  
  AETERM =
    "Reported Term for the Adverse Event",
  
  AESEV =
    "Severity/Intensity",
  
  AEREL =
    "Causality",
  
  AESTDTC =
    "Start Date/Time of Adverse Event",
  
  AEENDTC =
    "End Date/Time of Adverse Event"
) %>%
  
  
  #################################################
# Listing title
#################################################

tab_header(
  title = html(
    paste0(
      "Listing of Treatment-Emergent Adverse Events by Subject",
      "<br>",
      "Excluding Screen Failure Patients"
    )
  )
) %>%
  
  
  #################################################
# Body alignment
#################################################

# All body values are left aligned.

cols_align(
  align = "left",
  columns = everything()
) %>%
  
  
  #################################################
# Header alignment
#################################################

# Centre the AE Term header only.
# Values beneath it remain left aligned.

tab_style(
  style = cell_text(
    align = "center"
  ),
  
  locations = cells_column_labels(
    columns = AETERM
  )
) %>%
  
  
  #################################################
# Font styling
#################################################

tab_style(
  style = cell_text(
    font = "Courier New",
    size = px(12),
    color = "#444444"
  ),
  
  locations = cells_body(
    columns = everything()
  )
) %>%
  
  tab_style(
    style = cell_text(
      font = "Courier New",
      size = px(12),
      weight = "normal",
      color = "#444444"
    ),
    
    locations = cells_column_labels(
      columns = everything()
    )
  ) %>%
  
  tab_style(
    style = cell_text(
      font = "Courier New",
      size = px(12),
      weight = "normal",
      align = "left",
      color = "#444444"
    ),
    
    locations = cells_title(
      groups = "title"
    )
  ) %>%
  
  
  #################################################
# Remove row separator lines
#################################################

tab_style(
  style = cell_borders(
    sides = c(
      "top",
      "bottom"
    ),
    color = "transparent",
    weight = px(0)
  ),
  
  locations = cells_body(
    rows = everything()
  )
) %>%
  
  
  #################################################
# Overall table formatting
#################################################

tab_options(
  table.font.names = "Courier New",
  
  table.font.size = px(12),
  
  heading.title.font.size = px(12),
  
  heading.align = "left",
  
  # Adds space between the title and table.
  heading.padding = px(12),
  
  column_labels.font.weight = "normal",
  
  # Keep only the lines around the column headers.
  column_labels.border.top.width = px(1),
  
  column_labels.border.top.color = "#777777",
  
  column_labels.border.bottom.width = px(1),
  
  column_labels.border.bottom.color = "#777777",
  
  # Remove borders around the body.
  table_body.border.top.width = px(0),
  
  table_body.border.bottom.width = px(0),
  
  table.border.top.width = px(0),
  
  table.border.bottom.width = px(0),
  
  data_row.padding = px(4)
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
  ae_listing_gt,
  
  filename =
    "question_4_tlg/output/ae_listings.html"
)