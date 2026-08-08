#################################################
# Question 4: TLG - Adverse Events Reporting
# 02 - Adverse Event Visualizations
#################################################

library(pharmaverseadam)
library(dplyr)
library(ggplot2)


#################################################
# Load input datasets
#################################################

adae <- pharmaverseadam::adae
adsl <- pharmaverseadam::adsl


#################################################
# Define treatment and severity order
#################################################

treatment_order <- c(
  "Placebo",
  "Xanomeline High Dose",
  "Xanomeline Low Dose"
)

# ggplot stacks factor levels in reverse order.
# This order therefore displays SEVERE at the bottom,
# MODERATE in the middle and MILD at the top.
severity_order <- c(
  "MILD",
  "MODERATE",
  "SEVERE"
)


#################################################
# Prepare safety population
#################################################

safety <- adsl %>%
  filter(
    SAFFL == "Y",
    ACTARM %in% treatment_order
  ) %>%
  select(
    USUBJID,
    ACTARM
  )


#################################################
# Prepare adverse events
#################################################

# The visualization requirements refer to adverse
# events generally and do not specify TRTEMFL.
# Therefore all AEs from safety subjects are included.

ae_all <- adae %>%
  filter(
    USUBJID %in% safety$USUBJID,
    ACTARM %in% treatment_order
  )


#################################################
# Plot 1: AE severity distribution by treatment
#################################################

severity_counts <- ae_all %>%
  filter(
    AESEV %in% severity_order
  ) %>%
  mutate(
    ACTARM = factor(
      ACTARM,
      levels = treatment_order
    ),
    
    AESEV = factor(
      AESEV,
      levels = severity_order
    )
  ) %>%
  count(
    ACTARM,
    AESEV,
    name = "N"
  )


severity_plot <- ggplot(
  severity_counts,
  aes(
    x = ACTARM,
    y = N,
    fill = AESEV
  )
) +
  geom_col(
    width = 0.9
  ) +
  
  scale_fill_manual(
    values = c(
      "MILD" = "#F8766D",
      "MODERATE" = "#00BA38",
      "SEVERE" = "#619CFF"
    ),
    
    breaks = c(
      "MILD",
      "MODERATE",
      "SEVERE"
    )
  ) +
  
  labs(
    title =
      "AE severity distribution by treatment",
    
    x =
      "Treatment Arm",
    
    y =
      "Count of AEs",
    
    fill =
      "Severity/Intensity"
  ) +
  
  theme_grey(
    base_size = 12
  ) +
  
  theme(
    plot.title = element_text(
      size = 16,
      face = "plain"
    ),
    
    axis.text.x = element_text(
      angle = 0,
      hjust = 0.5
    ),
    
    legend.position = "right"
  )


#################################################
# Prepare population for Plot 2
#################################################

# The example plot uses subjects with at least one
# adverse event as the analysis population.
#
# A subject is counted once regardless of the number
# of AE records experienced.

ae_subject_n <- ae_all %>%
  summarise(
    N = n_distinct(USUBJID)
  ) %>%
  pull(N)


#################################################
# Identify top 10 most frequent adverse events
#################################################

# Count unique subjects per reported AE term.
# Repeated occurrences of the same AE within a subject
# contribute only once.

top_10_ae <- ae_all %>%
  filter(
    !is.na(AETERM)
  ) %>%
  distinct(
    USUBJID,
    AETERM
  ) %>%
  count(
    AETERM,
    name = "N"
  ) %>%
  arrange(
    desc(N),
    AETERM
  ) %>%
  slice_head(
    n = 10
  )


#################################################
# Derive overall AE percentages
#################################################

# Treatment groups are combined for this plot.
# The denominator is the number of subjects with at
# least one adverse event.

ae_incidence <- top_10_ae %>%
  mutate(
    DENOM = ae_subject_n,
    
    PERCENT =
      100 * N / DENOM
  )


#################################################
# Derive 95% Clopper-Pearson confidence intervals
#################################################

# Exact binomial confidence intervals are calculated
# for the percentage of AE subjects experiencing each
# of the top 10 adverse events.

ae_incidence <- ae_incidence %>%
  rowwise() %>%
  mutate(
    CI_LOW =
      100 *
      binom.test(
        N,
        DENOM
      )$conf.int[1],
    
    CI_HIGH =
      100 *
      binom.test(
        N,
        DENOM
      )$conf.int[2]
  ) %>%
  ungroup()


#################################################
# Define AE display order
#################################################

# Arrange so the most frequent adverse event appears
# at the top of the plot.

ae_incidence <- ae_incidence %>%
  arrange(
    N
  ) %>%
  mutate(
    AETERM_DISPLAY = factor(
      AETERM,
      levels = AETERM
    )
  )


#################################################
# Plot 2: Top 10 most frequent adverse events
#################################################

incidence_plot <- ggplot(
  ae_incidence,
  aes(
    x = PERCENT,
    y = AETERM_DISPLAY
  )
) +
  
  # 95% Clopper-Pearson confidence interval.
  geom_errorbar(
    aes(
      xmin = CI_LOW,
      xmax = CI_HIGH
    ),
    orientation = "y",
    width = 0.15,
    colour = "black",
    linewidth = 0.6
  ) +
  
  # Percentage point estimate.
  geom_point(
    colour = "black",
    size = 2.8
  ) +
  
  labs(
    title =
      "Top 10 Most Frequent Adverse Events",
    
    subtitle =
      paste0(
        "n = ",
        ae_subject_n,
        " subjects; 95% Clopper-Pearson CIs"
      ),
    
    x =
      "Percentage of Patients (%)",
    
    y =
      NULL
  ) +
  
  scale_x_continuous(
    limits = c(
      0,
      NA
    ),
    
    expand = expansion(
      mult = c(
        0,
        0.08
      )
    )
  ) +
  
  theme_grey(
    base_size = 12
  ) +
  
  theme(
    plot.title = element_text(
      size = 16,
      face = "plain"
    ),
    
    plot.subtitle = element_text(
      size = 11
    ),
    
    axis.title.x = element_text(
      size = 12
    ),
    
    axis.text.y = element_text(
      colour = "black"
    ),
    
    axis.text.x = element_text(
      colour = "black"
    ),
    
    panel.grid.major = element_line(
      colour = "white",
      linewidth = 0.7
    ),
    
    panel.grid.minor = element_line(
      colour = "white",
      linewidth = 0.35
    ),
    
    panel.background = element_rect(
      fill = "#EBEBEB",
      colour = NA
    ),
    
    plot.background = element_rect(
      fill = "white",
      colour = NA
    ),
    
    legend.position = "none"
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
# Save Plot 1
#################################################

ggsave(
  filename =
    "question_4_tlg/output/ae_severity_distribution.png",
  
  plot =
    severity_plot,
  
  width = 9,
  height = 6,
  dpi = 300
)


#################################################
# Save Plot 2
#################################################

ggsave(
  filename =
    "question_4_tlg/output/top_10_ae_incidence.png",
  
  plot =
    incidence_plot,
  
  width = 10,
  height = 7,
  dpi = 300
)


#################################################
# QC
#################################################

# Confirm the AE analysis population matches the
# expected number of subjects in the example.

stopifnot(
  ae_subject_n == 225
)


# Confirm exactly ten adverse events are displayed.

stopifnot(
  nrow(ae_incidence) == 10
)


# Percentages must be between 0 and 100.

stopifnot(
  all(
    ae_incidence$PERCENT >= 0 &
      ae_incidence$PERCENT <= 100
  )
)


# Confidence intervals must contain the point estimate.

stopifnot(
  all(
    ae_incidence$CI_LOW <=
      ae_incidence$PERCENT
  )
)

stopifnot(
  all(
    ae_incidence$CI_HIGH >=
      ae_incidence$PERCENT
  )
)