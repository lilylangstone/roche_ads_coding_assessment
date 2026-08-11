# Question 5: Clinical Data API

This directory contains a FastAPI application for querying adverse event data and calculating subject-level safety risk scores.

The API uses `adae.csv` as its input dataset.

## Files

- `main.py` - FastAPI application and endpoint logic
- `api_launcher.py` - convenience script for launching the API
- `adae.csv` - adverse event input data
- `requirements.txt` - required Python packages

## Requirements

The API requires Python and the packages listed in `requirements.txt`.

Install the required packages from the `question_5_api` directory using:

```bash
pip install -r requirements.txt
```

## Running the API


### Option 1: Launcher

The supplied launcher starts the API and opens the interactive API documentation in a browser.

From the `question_5_api` directory, run:

```bash
python3 api_launcher.py
```

Press `Ctrl+C` in the terminal to stop the API.

### Option 2: Uvicorn

The API can also be started directly using Uvicorn:

```bash
python3 -m uvicorn main:app --reload
```

The interactive FastAPI documentation is available at:

```text
http://127.0.0.1:8000/docs
```

The Swagger interface can be used to test each endpoint using the **Try it out** button.

## API Endpoints

### GET `/`

Confirms that the API is running.

Example response:

```json
{
  "message": "Clinical Trial Data API is running"
}
```

---

### POST `/ae-query`

Dynamically filters adverse event records by severity and/or treatment arm.

Both filters are optional.

Example request:

```json
{
  "severity": ["MILD", "MODERATE"],
  "treatment_arm": "Placebo"
}
```

The response contains:

- `count` - number of AE records matching the query
- `subjects` - unique subject identifiers within the resulting cohort

Example response:

```json
{
  "count": 10,
  "subjects": [
    "01-701-1015",
    "01-701-1023"
  ]
}
```

#### Severity

The following AE severity categories are accepted:

- `MILD`
- `MODERATE`
- `SEVERE`

Severity input is case-insensitive, so `"mild"` and `"MILD"` are treated equivalently.

All valid severity categories can be queried even if no records of that severity occurred in the study. A valid query with no matching AEs therefore returns a count of zero.

Multiple severities may be supplied:

```json
{
  "severity": ["MILD", "MODERATE"]
}
```

To apply no severity filter, either omit the field or set the field itself to `null`:

```json
{
  "severity": null,
  "treatment_arm": "Placebo"
}
```

`null` should not be placed inside the severity list. For example, `"severity": [null]` is invalid because each item within the list must represent a valid severity category.

#### Treatment Arm

Treatment arm is also optional and is case-insensitive.

If `treatment_arm` is omitted or set to `null`, records from all treatment arms are eligible for the cohort.

Supplying both severity and treatment arm applies both filters.

---

### GET `/subject-risk/{subject_id}`

Calculates a Safety Risk Score for an individual subject based on their adverse events.

Each AE contributes points according to its severity:

| Severity | Points |
|----------|-------:|
| MILD | 1 |
| MODERATE | 3 |
| SEVERE | 5 |

The points across all AEs for the subject are summed to produce the total risk score.

The resulting score is classified as:

| Risk Category | Score |
|---------------|-------|
| Low | < 5 |
| Medium | 5 to < 15 |
| High | >= 15 |

Example request:

```text
GET /subject-risk/01-701-1015
```

Example response:

```json
{
  "subject_id": "01-701-1015",
  "risk_score": 3,
  "risk_category": "Low"
}
```

If the requested subject does not exist, the API returns HTTP status `404`:

```json
{
  "detail": "Subject not found"
}
```

## Input Validation

Request values are validated before cohort filtering is performed.

Severity values must correspond to the supported AE severity categories, and treatment-arm values must correspond to treatment arms defined for the study.

Input is case-insensitive for convenience.

Invalid values return a validation response rather than silently being treated as a valid query with zero matching records.