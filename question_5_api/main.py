#################################################
# Question 5: Clinical Data API
#################################################

from pathlib import Path
from enum import Enum

import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.openapi.docs import get_swagger_ui_html
from pydantic import BaseModel, field_validator


#################################################
# Load input data
#################################################

# Locate adae.csv relative to this script so that the
# API can be run from either the project root or the
# question_5_api directory.

DATA_PATH = Path(__file__).parent / "adae.csv"

adae = pd.read_csv(DATA_PATH)


#################################################
# Create FastAPI application
#################################################

# A relative server URL allows the interactive Swagger
# documentation to work both locally and when the API
# is accessed through a path-based proxy such as
# Posit Cloud.

app = FastAPI(
    title="Clinical Trial Data API",
    docs_url=None,
    redoc_url=None,
    servers=[
        {
            "url": ".",
            "description": "Current API server"
        }
    ]
)


#################################################
# Define allowed severity values
#################################################

# These represent valid AE severity categories rather
# than only values observed in the current study.
#
# For example, a valid SEVERE query can return zero
# records if no severe AEs occurred.

class Severity(str, Enum):
    MILD = "MILD"
    MODERATE = "MODERATE"
    SEVERE = "SEVERE"


#################################################
# Define study treatment arms
#################################################

# Treatment-arm values are limited to the actual
# treatment groups available in this study.

class TreatmentArm(str, Enum):
    PLACEBO = "Placebo"
    XANOMELINE_HIGH = "Xanomeline High Dose"
    XANOMELINE_LOW = "Xanomeline Low Dose"


#################################################
# Define request model
#################################################

# Both filters are optional.
#
# If omitted or supplied as null, that dimension is
# not filtered.

class AEQuery(BaseModel):

    severity: list[Severity] | None = None
    treatment_arm: TreatmentArm | None = None


    #################################################
    # Normalise severity input
    #################################################

    # Input is case-insensitive while remaining
    # restricted to valid severity categories.

    @field_validator(
        "severity",
        mode="before"
    )
    @classmethod
    def normalise_severity(cls, value):

        if value is None:
            return value

        return [
            item.upper()
            if isinstance(item, str)
            else item
            for item in value
        ]


    #################################################
    # Normalise treatment arm input
    #################################################

    # Input is case-insensitive while remaining
    # restricted to treatment arms in the study.

    @field_validator(
        "treatment_arm",
        mode="before"
    )
    @classmethod
    def normalise_treatment_arm(cls, value):

        if value is None:
            return value

        if isinstance(value, str):

            treatment_lookup = {
                "placebo":
                    "Placebo",

                "xanomeline high dose":
                    "Xanomeline High Dose",

                "xanomeline low dose":
                    "Xanomeline Low Dose"
            }

            return treatment_lookup.get(
                value.casefold(),
                value
            )

        return value


#################################################
# Interactive API documentation
#################################################

# FastAPI normally generates Swagger automatically.
#
# A custom documentation route is used here so that
# the OpenAPI specification is referenced relative to
# the current URL. This allows the documentation to
# work both locally and behind the Posit Cloud proxy.

@app.get(
    "/docs",
    include_in_schema=False
)
def custom_swagger_ui():

    return get_swagger_ui_html(
        openapi_url="openapi.json",
        title="Clinical Trial Data API - Swagger UI"
    )


#################################################
# Welcome endpoint
#################################################

@app.get("/")
def root():
    """
    Confirm that the Clinical Trial Data API is running.
    """

    return {
        "message": "Clinical Trial Data API is running"
    }


#################################################
# Dynamic adverse event query
#################################################

@app.post("/ae-query")
def query_adverse_events(query: AEQuery):
    """
    Filter adverse event records by severity and/or
    treatment arm.

    Missing or null filters are ignored.
    """

    cohort = adae.copy()


    #################################################
    # Filter by AE severity
    #################################################

    if query.severity is not None:

        severity_values = [
            severity.value
            for severity in query.severity
        ]

        cohort = cohort[
            cohort["AESEV"].isin(
                severity_values
            )
        ]


    #################################################
    # Filter by treatment arm
    #################################################

    if query.treatment_arm is not None:

        cohort = cohort[
            cohort["ACTARM"]
            == query.treatment_arm.value
        ]


    #################################################
    # Identify unique subjects
    #################################################

    subjects = (
        cohort["USUBJID"]
        .dropna()
        .unique()
        .tolist()
    )


    #################################################
    # Return query result
    #################################################

    return {
        "count": len(cohort),
        "subjects": subjects
    }


#################################################
# Subject safety risk score
#################################################

@app.get("/subject-risk/{subject_id}")
def calculate_subject_risk(subject_id: str):
    """
    Calculate the Safety Risk Score for an individual
    subject using adverse event severity.
    """

    subject_ae = adae[
        adae["USUBJID"] == subject_id
    ]


    #################################################
    # Error handling
    #################################################

    # Return HTTP 404 if the subject does not exist.

    if subject_ae.empty:

        raise HTTPException(
            status_code=404,
            detail="Subject not found"
        )


    #################################################
    # Define severity weights
    #################################################

    severity_scores = {
        "MILD": 1,
        "MODERATE": 3,
        "SEVERE": 5
    }


    #################################################
    # Calculate risk score
    #################################################

    # Each AE record contributes points according to
    # severity.
    #
    # Missing or unrecognised severity values contribute
    # zero points.

    risk_score = (
        subject_ae["AESEV"]
        .fillna("")
        .str.upper()
        .map(severity_scores)
        .fillna(0)
        .sum()
    )

    risk_score = int(
        risk_score
    )


    #################################################
    # Assign risk category
    #################################################

    if risk_score < 5:

        risk_category = "Low"

    elif risk_score < 15:

        risk_category = "Medium"

    else:

        risk_category = "High"


    #################################################
    # Return subject risk result
    #################################################

    return {
        "subject_id": subject_id,
        "risk_score": risk_score,
        "risk_category": risk_category
    }
