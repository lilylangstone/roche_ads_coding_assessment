#################################################
# Question 6: Test Clinical Data Agent
#################################################

from clinical_data_agent import agent


#################################################
# Test 1: Value not observed in the dataset
#################################################

# Demonstrates that observed dataset values are supplied
# to the LLM as context rather than as a restriction.
#
# FATAL is not an observed AESEV value, so the query is
# still executed but should return zero matching subjects.

result_1 = agent.ask_mock(
    question=(
        "Give me the subjects who had adverse events "
        "of Fatal severity"
    ),
    target_column="AESEV",
    filter_value="FATAL"
)


#################################################
# Test 2: Single-filter query
#################################################

# Demonstrates a standard natural-language question
# mapping to one dataset variable and filter value.

result_2 = agent.ask_mock(
    question=(
        "Which subjects experienced headache?"
    ),
  target_column="AETERM",
  filter_value="HEADACHE"
)


#################################################
# Test 3: Multiple-filter query
#################################################

# Demonstrates the optional extension to support compound
# questions. Both filters are applied using AND logic.

result_3 = agent.ask_mock_multi(
    question=(
        "Which subjects on Placebo had Severe "
        "adverse events?"
    ),
    filters=[
        {
            "target_column": "TRT01A",
            "filter_value": "Placebo"
        },
        {
            "target_column": "AESEV",
            "filter_value": "SEVERE"
        }
    ]
)


#################################################
# Print test results
#################################################

tests = [
    result_1,
    result_2,
    result_3
]

for number, result in enumerate(
    tests,
    start=1
):

    print(
        f"\n{'=' * 60}"
    )

    print(
        f"TEST {number}"
    )

    print(
        f"Question: {result['question']}"
    )

    print(
        f"Mock LLM output: "
        f"{result['llm_output']}"
    )

    print(
        f"Parsed filters: "
        f"{result['parsed_output']['filters']}"
    )

    print(
        f"Unique subject count: "
        f"{result['result']['count']}"
    )

    print(
        f"Subjects: "
        f"{result['result']['subjects']}"
    )
