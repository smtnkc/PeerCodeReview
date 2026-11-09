# PeerCodeReview: survey data and reproducible analysis

Data and code accompanying **Student participation and perceived benefits of live peer code review in introductory programming laboratories**.

**Authors:** Samet Tenekeci (first and corresponding author; [ORCID](https://orcid.org/0000-0001-8875-4111)) and Hüseyin Ünlü ([ORCID](https://orcid.org/0000-0001-9906-6066)). Both authors contributed equally across the applicable CRediT roles.

The study concerns an introductory Python programming laboratory in fall 2022. It includes 65 end-of-term respondents from 84 enrolled students. All nine item responses use the same five-point **agreement** scale: 1 = strongly disagree; 5 = strongly agree. Q5 and Q7 are not frequency measures. The study was approved on 7 December 2022 (No. 220001130).

## Data and files

| Path | Contents |
| --- | --- |
| `data/survey_responses.csv` | 65 rows and 12 columns: gender, prior programming experience, recalled initial laboratory preference, and Q1–Q9. Each row is one respondent; within-row pairing must be preserved. |
| `data/data_dictionary.csv` | All public variables, item wording, coding, and missing-value conventions. |
| `data/questionnaire.md` | Original item wording and background-question headings from the response workbook. |
| `data/aggregate_context.json` | Cohort information and aggregate demographic and experience-source descriptions. |
| `analysis/analyze_survey.R` | All focal and secondary inferential analyses, reliability and structural diagnostics, and the attempted ordinal model. |
| `analysis/create_figures.R` | Three publication figures in vector PDF format. |
| `analysis/export_tables.py` | LaTeX tables and numerical macros, generated from analysis results. |
| `analysis/verify_results.py` | Independent arithmetic checks and comparison of recomputed results against the reference outputs. |
| `analysis/ANALYSIS_DECISIONS.md` | Analysis families, inference settings, and interpretation decisions. |
| `reference_results/` | Numerical results used in the article and the original R session information. |
| `release_manifest.json` | SHA-256 checksums of all release files other than the manifest itself. |

Original response workbooks, SPSS files, record identifiers, source-row numbers, and private audit records are excluded. Individual ages, first-enrollment status, and detailed language-experience histories are distributed only as aggregates, reducing the amount of participant background information in the public release. The respondent-level data are reduced research data and should not be used to attempt identification or linkage.

**Reproducibility scope:** all inferential analyses, item summaries, and response-based figures are recomputable from the public respondent matrix. Age, course-enrollment, and detailed experience-source descriptions are read from the supplied aggregate inputs; their participant-level derivation cannot be independently rerun from this release. No raw or synthetic replacement data are claimed.

## Reproduce the outputs

Run these commands from the repository root after downloading or cloning the repository:

```sh
Rscript analysis/analyze_survey.R
Rscript analysis/create_figures.R
python3 analysis/export_tables.py
python3 analysis/verify_results.py
```

The analysis writes to `results/`, the figure script to `figures/`, and the table exporter to `tables/` plus `numbers.tex`. These generated files are ignored by Git. The scripts find the repository root from their own locations; no original project directory, SPSS installation, workbook, or private path is required. Python uses only its standard library.

The reference environment was **R 3.6.3**, **MASS 7.3-51.5**, **psych 1.9.12.31**, and **jsonlite 1.6.1**; full loaded-package versions are in `reference_results/sessionInfo.txt`. Install the three R packages if absent. Matching the recorded environment is recommended for exact numerical reproduction; different package or numerical-library versions can affect simulated results or factor diagnostics. The verifier reports any numerical differences rather than silently accepting them.

The base seed is 20261109. Permutation tests use 99,999 replicates, bootstrap intervals use 10,000 replicates, and parallel analysis uses 1,000 replicates. Parallel analysis is forced to one core. Seven focal tests share one Holm adjustment; the two secondary gender comparisons have a separate Holm adjustment. The ordinal model is retained only as a diagnostic output and must not be interpreted as an established adjusted effect.

The public pipeline was run independently of the private source workbooks. Its complete saved result object reproduced every reference numerical result exactly in the recorded environment.

## Citation

Please cite the associated article when using these materials. Publication details will be added after publication; no DOI has yet been assigned. Repository citation metadata are in `CITATION.cff`.
