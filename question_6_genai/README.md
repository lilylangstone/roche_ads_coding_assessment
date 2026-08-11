# Question 6: GenAI Clinical Data Assistant

## Overview

This solution implements a clinical data assistant that translates
natural-language safety questions into structured queries that can be executed
against the ADAE dataset using Pandas.

The workflow is:

**Natural-language question → Prompt → LLM response → Parse → Pandas query → Subject results**

As permitted by the assessment specification, the LLM response is mocked
because an external LLM API key is not used.

Prompt construction, schema definition, structured response parsing,
validation and Pandas query execution are implemented in full.

## Project Structure

```text
question_6_genai/
│
├── data/
│   ├── adae.csv
│   └── adae_metadata.csv
│
├── programs/
│   ├── clinical_data_agent.py
│   └── test_agent.py
│
├── README.md
└── requirements.txt
```

## Clinical Schema

The assistant is provided with clinically relevant ADAE variables that a
safety reviewer may reasonably reference.

Rather than manually duplicating the variable definitions in Python, official
variable labels are read from `data/adae_metadata.csv` and used to construct
the clinical schema.

Additional plain-language context is only provided where the standard metadata
label may not be sufficiently descriptive for natural-language interpretation.

Observed values for the relevant variables are also obtained directly from
`data/adae.csv` and supplied to the LLM as additional context.

Observed values do not restrict what can be queried. For example, a reviewer
can request adverse events of `FATAL` severity even when `FATAL` is not an
observed value of `AESEV`. The resulting query is still valid and will return
zero matching subjects.

## LLM Implementation

`ClinicalTrialDataAgent` constructs a prompt containing:

- The clinical dataset schema.
- Relevant variable labels.
- Additional context where required.
- Values observed in the current dataset.
- The reviewer's natural-language question.
- The required structured output format.

A live implementation would send this prompt to an LLM.

For this assessment, the LLM response is mocked. The mock represents the
structured JSON that would normally be returned by the external LLM.

For example:

```json
{
    "target_column": "AESEV",
    "filter_value": "MODERATE"
}
```

The mocked response then passes through the same parsing, validation and Pandas
execution stages that would be used with a live LLM response.

## Query Execution

Structured output is validated before execution.

Filtering is performed using Pandas with case-insensitive character
comparisons.

The result contains:

- The number of unique matching subjects.
- A list of the matching `USUBJID` values.

The returned count therefore represents subjects rather than adverse event
records.

## Multiple-Filter Extension

The solution additionally supports questions requiring more than one filter.

For example:

> Which subjects on Placebo had Severe adverse events?

can be represented as:

```json
{
    "filters": [
        {
            "target_column": "TRT01A",
            "filter_value": "Placebo"
        },
        {
            "target_column": "AESEV",
            "filter_value": "SEVERE"
        }
    ]
}
```

Multiple filters are applied using AND logic.

This extends the required single-filter functionality to support more realistic
clinical safety questions.

## Example Tests

`programs/test_agent.py` demonstrates three scenarios:

1. A valid query for a value not observed in the dataset (`FATAL` severity),
   resulting in zero matching subjects.
2. A standard single-filter query for subjects experiencing `HEADACHE`.
3. A compound query for subjects on `Placebo` who experienced `SEVERE`
   adverse events.

These demonstrate the complete:

**Prompt → Mock LLM Response → Parse → Execute**

workflow.

## Running the Solution

From the `question_6_genai` directory, run:

```bash
python3 programs/test_agent.py
```

The script prints the question, mocked structured output, parsed filters,
unique subject count and matching subject identifiers for each test.

## Requirements

Python 3 with:

```text
pandas
```

No external LLM API key is required for the submitted mocked implementation.