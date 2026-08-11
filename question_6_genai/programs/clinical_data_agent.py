#################################################
# Question 6: GenAI Clinical Data Assistant
#################################################

from pathlib import Path

import pandas as pd


#################################################
# Load input data and metadata
#################################################

PROJECT_DIR = Path(__file__).parent.parent

DATA_PATH = PROJECT_DIR / "data" / "adae.csv"
METADATA_PATH = PROJECT_DIR / "data" / "adae_metadata.csv"

adae = pd.read_csv(DATA_PATH)
metadata = pd.read_csv(METADATA_PATH)


#################################################
# Define variables relevant to the assistant
#################################################

# Only variables that are likely to be useful to a
# clinical safety reviewer are supplied to the LLM.
#
# TRT01A is used rather than TRT01P to avoid ambiguity
# between planned and actual treatment.

RELEVANT_COLUMNS = [
    "USUBJID",
    "TRT01A",
    "ACTARM",
    "AETERM",
    "AEDECOD",
    "AESOC",
    "AESTDTC",
    "AEENDTC",
    "TRTEMFL",
    "AESEV",
    "AESER",
    "AESDTH",
    "AESLIFE",
    "AESHOSP",
    "AESDISAB",
    "AESCONG",
    "AEREL",
    "AEACN",
    "AEOUT",
    "AESCAN",
    "AESOD"
]


#################################################
# Build clinical schema from metadata
#################################################

# Official variable labels are taken from the
# Pharmaverse ADAE metadata.

metadata_relevant = metadata[
    metadata["variable"].isin(
        RELEVANT_COLUMNS
    )
].copy()

CLINICAL_SCHEMA = dict(
    zip(
        metadata_relevant["variable"],
        metadata_relevant["label"]
    )
)


#################################################
# Additional context for ambiguous labels
#################################################

# Most official labels are sufficiently descriptive.
# Extra context is supplied only where the label alone
# may not clearly communicate the variable's meaning.

SCHEMA_CONTEXT = {

    "AEDECOD":
        "Standardised adverse event term; useful for "
        "questions about a specific condition or event.",

    "AESOC":
        "Body system or organ class associated with "
        "the adverse event."
}


#################################################
# Clinical Trial Data Agent
#################################################

class ClinicalTrialDataAgent:
    """
    Interpret natural-language clinical safety questions
    and apply the resulting structured query to ADAE.
    """

    def __init__(
        self,
        dataframe,
        schema,
        schema_context=None
    ):

        self.data = dataframe
        self.schema = schema

        self.schema_context = (
            schema_context
            if schema_context is not None
            else {}
        )


    #################################################
    # Obtain observed values
    #################################################

    def get_observed_values(self):
        """
        Obtain unique observed values for each relevant
        variable directly from the current dataset.

        Observed values provide context to the LLM but
        do not restrict what the reviewer may query.
        """

        observed_values = {}

        for column in self.schema:

            if column not in self.data.columns:
                continue

            values = (
                self.data[column]
                .dropna()
                .astype(str)
                .unique()
                .tolist()
            )

            observed_values[column] = sorted(
                values
            )

        return observed_values


    #################################################
    # Build LLM prompt
    #################################################

    def build_prompt(self, question):
        """
        Build the prompt that would be supplied to an
        LLM to interpret the reviewer's question.
        """

        observed_values = (
            self.get_observed_values()
        )

        schema_details = []

        for column, label in self.schema.items():

            if column not in self.data.columns:
                continue

            values = observed_values.get(
                column,
                []
            )

            details = (
                f"Column: {column}\n"
                f"Label: {label}\n"
            )

            if column in self.schema_context:

                details += (
                    "Additional context: "
                    f"{self.schema_context[column]}\n"
                )

            details += (
                f"Observed values: {values}\n"
            )

            schema_details.append(
                details
            )

        schema_text = "\n".join(
            schema_details
        )

        prompt = f"""
You are a clinical trial safety data assistant.

A clinical safety reviewer will ask a question in
natural language. The reviewer does not know the
dataset variable names.

Use the clinical dataset schema and observed values
below to identify every filter required to answer
the question.

DATASET SCHEMA

{schema_text}

USER QUESTION

"{question}"

Observed values are provided as context only.

A reviewer may ask about a clinically meaningful value
that is not currently observed in the dataset. In that
case, still identify the appropriate target column and
requested filter value. The subsequent query may
legitimately return zero matching subjects.

If the question requires ONE filter, return JSON in
this format:

{{
    "target_column": "COLUMN_NAME",
    "filter_value": "VALUE"
}}

If the question requires MORE THAN ONE filter, return
JSON in this format:

{{
    "filters": [
        {{
            "target_column": "COLUMN_NAME",
            "filter_value": "VALUE"
        }},
        {{
            "target_column": "COLUMN_NAME",
            "filter_value": "VALUE"
        }}
    ]
}}

Return only structured JSON.
"""

        return prompt


    #################################################
    # Mock single-filter LLM response
    #################################################

    def mock_llm_response(
        self,
        target_column,
        filter_value
    ):
        """
        Mock a single-filter structured response that
        would normally be produced by an external LLM.
        """

        return {
            "target_column": target_column,
            "filter_value": filter_value
        }


    #################################################
    # Mock multiple-filter LLM response
    #################################################

    def mock_llm_multi_response(
        self,
        filters
    ):
        """
        Mock a multiple-filter structured response that
        would normally be produced by an external LLM.
        """

        return {
            "filters": filters
        }


    #################################################
    # Validate individual filter
    #################################################

    def validate_filter(
        self,
        query_filter
    ):
        """
        Validate one target-column/filter-value pair.
        """

        if not isinstance(
            query_filter,
            dict
        ):
            raise ValueError(
                "Each filter must be a dictionary."
            )

        if "target_column" not in query_filter:
            raise ValueError(
                "Filter is missing target_column."
            )

        if "filter_value" not in query_filter:
            raise ValueError(
                "Filter is missing filter_value."
            )

        target_column = (
            query_filter["target_column"]
        )

        filter_value = (
            query_filter["filter_value"]
        )

        if target_column not in self.schema:
            raise ValueError(
                f"Unknown target column: "
                f"{target_column}"
            )

        if target_column not in self.data.columns:
            raise ValueError(
                f"Column not present in dataset: "
                f"{target_column}"
            )

        return {
            "target_column": target_column,
            "filter_value": filter_value
        }


    #################################################
    # Parse and validate LLM output
    #################################################

    def parse_llm_output(
        self,
        llm_output
    ):
        """
        Parse either a single-filter or multiple-filter
        structured response from the LLM.
        """

        if not isinstance(
            llm_output,
            dict
        ):
            raise ValueError(
                "LLM output must be a dictionary."
            )


        #################################################
        # Multiple filters
        #################################################

        if "filters" in llm_output:

            if not isinstance(
                llm_output["filters"],
                list
            ):
                raise ValueError(
                    "filters must be a list."
                )

            if len(
                llm_output["filters"]
            ) == 0:
                raise ValueError(
                    "At least one filter is required."
                )

            filters = [
                self.validate_filter(
                    query_filter
                )
                for query_filter
                in llm_output["filters"]
            ]

            return {
                "filters": filters
            }


        #################################################
        # Single filter
        #################################################

        single_filter = (
            self.validate_filter(
                llm_output
            )
        )

        return {
            "filters": [
                single_filter
            ]
        }


    #################################################
    # Execute Pandas filters
    #################################################

    def execute_filters(
        self,
        filters
    ):
        """
        Apply one or more filters to ADAE.

        Multiple filters are applied sequentially,
        resulting in AND logic.
        """

        matches = self.data.copy()

        for query_filter in filters:

            target_column = (
                query_filter["target_column"]
            )

            filter_value = (
                query_filter["filter_value"]
            )

            column_values = (
                matches[target_column]
                .fillna("")
                .astype(str)
            )

            matches = matches[
                column_values.str.casefold()
                == str(filter_value).casefold()
            ]

        subjects = (
            matches["USUBJID"]
            .dropna()
            .unique()
            .tolist()
        )

        return {
            "count": len(subjects),
            "subjects": subjects
        }


    #################################################
    # Run single-filter mocked workflow
    #################################################

    def ask_mock(
        self,
        question,
        target_column,
        filter_value
    ):
        """
        Demonstrate Prompt -> Parse -> Execute using a
        mocked single-filter LLM response.
        """

        prompt = self.build_prompt(
            question
        )

        llm_output = (
            self.mock_llm_response(
                target_column,
                filter_value
            )
        )

        parsed_output = (
            self.parse_llm_output(
                llm_output
            )
        )

        result = (
            self.execute_filters(
                parsed_output["filters"]
            )
        )

        return {
            "question": question,
            "prompt": prompt,
            "llm_output": llm_output,
            "parsed_output": parsed_output,
            "result": result
        }


    #################################################
    # Run multiple-filter mocked workflow
    #################################################

    def ask_mock_multi(
        self,
        question,
        filters
    ):
        """
        Demonstrate Prompt -> Parse -> Execute using a
        mocked multiple-filter LLM response.
        """

        prompt = self.build_prompt(
            question
        )

        llm_output = (
            self.mock_llm_multi_response(
                filters
            )
        )

        parsed_output = (
            self.parse_llm_output(
                llm_output
            )
        )

        result = (
            self.execute_filters(
                parsed_output["filters"]
            )
        )

        return {
            "question": question,
            "prompt": prompt,
            "llm_output": llm_output,
            "parsed_output": parsed_output,
            "result": result
        }


#################################################
# Create agent instance
#################################################

agent = ClinicalTrialDataAgent(
    dataframe=adae,
    schema=CLINICAL_SCHEMA,
    schema_context=SCHEMA_CONTEXT
)
