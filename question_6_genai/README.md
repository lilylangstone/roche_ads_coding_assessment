# Question 6: GenAI Clinical Data Assistant

## Overview

This solution implements a clinical data assistant that translates
natural-language safety questions into structured queries that can be
executed against the ADAE dataset using Pandas.

The intended workflow is:

**Natural-language question → Prompt → LLM → Structured output → Parse → Pandas query → Subject results**

As permitted by the assessment specification, the LLM response is mocked
because an external LLM API key is not used. The remaining workflow,
including prompt construction, schema definition, structured response
parsing, validation, filtering and subject-level results, is implemented
and executed in full.


## Files

- `clinical_data_agent.py` - Main ClinicalTrialDataAgent implementation.
- `test_agent.py` - Runs three example natural-language queries and prints
  the results.
- `adae.csv` - ADAE dataset used by the assistant.
- `adae_metadata.csv` - Variable names and labels extracted from the
  labelled `pharmaverseadam::adae` dataset.


## Clinical Schema

The assistant is provided with a subset of clinically relevant ADAE
variables that a safety reviewer may reasonably reference.

Rather than manually duplicating the clinical definitions in Python,
official variable labels are read from `adae_metadata.csv` and used to
construct the clinical schema.

Additional plain-language context is provided only for variables whose
standard metadata labels may not be sufficiently descriptive for
natural-language interpretation:

- `AEDECOD` - standardised adverse event term, useful for questions about
  a specific condition or event.
- `AESOC` - body system or organ class associated with the adverse event.

The schema includes information relating to adverse event terminology,
severity, seriousness, causality, outcome, treatment, treatment emergence,
serious event criteria and other clinically relevant AE flags.


## Observed Values

For each relevant variable, the assistant obtains the unique observed
values directly from `adae.csv`.

These values are included in the LLM prompt as additional context. They
are not treated as restrictions on what may be queried.

For example, a reviewer may ask for adverse events of `FATAL` severity
even if `FATAL` is not an observed value of `AESEV`. The assistant can
still construct and execute the query, which will correctly return zero
matching subjects.


## LLM Implementation

The `ClinicalTrialDataAgent` constructs a prompt containing:

1. The clinical variable names.
2. Their dataset labels.
3. Additional context where required.
4. Values observed in the current dataset.
5. The reviewer's natural-language question.
6. The required structured output format.

A live implementation would send this prompt to an LLM such as OpenAI
through an appropriate client or framework.

For this assessment, the LLM response is mocked. The mock represents the
structured response that would normally be returned by the external LLM.

For example:

```json
{
    "target_column": "AESEV",
    "filter_value": "MODERATE"
}

## Running the Solution ## Run from Terminal

From the `question_6_genai` directory:

```bash
python3 programs/test_agent.py 