# Survey analysis decisions

The analysis is an exploratory reanalysis of existing fall 2022 observations. Earlier manuscript findings were available when research questions and analysis priorities were formulated. This is not a preregistered confirmatory study.

- All 65 respondents are retained; the nine item responses are complete. All nine items use 1 = strongly disagree through 5 = strongly agree. No item uses frequency anchors.
- Prior programming experience means Python or any other programming language before the course. Recalled initial laboratory preference is an end-of-term recollection, not a prospectively linked baseline or an allocation to a control group.
- The seven-test focal family contains the paired sign comparison of Q7 and Q5, four rank-sum tests (experience/Q5, recalled preference/Q5, experience/Q1, recalled preference/Q1), and two Spearman associations (Q5–Q6, Q7–Q8). Holm adjustment applies across all seven, including nonsignificant results.
- The exact two-sided paired sign test uses the 46 unequal pairs. Its probability is conditional on unequal responses, not the proportion of all students who reviewed code. Equal pairs remain in every other analysis.
- Rank-sum and correlation p values use 99,999 Monte Carlo permutations and the plus-one correction. Group effects are Cliff's delta, with positive values favoring experience-yes or interactive-preference responses. Secondary gender effects are female minus male.
- Confidence intervals use 10,000 bootstrap replicates. Group comparisons resample within groups; correlations and reliability estimates resample complete participant rows. Intervals are pointwise percentile intervals, without simultaneous multiplicity coverage.
- The base seed is 42 with deterministic offsets. R uses Mersenne-Twister / Inversion / Rejection; parallel analysis uses one core to avoid fork-dependent random streams.
- Female-versus-male comparisons of Q5 and Q7 form a separate two-test Holm family. Four respondents who did not disclose gender remain in all other analyses.
- The ordinal Q5 model includes experience and recalled preference. It is reported for diagnostic transparency only: a separated highest-threshold binary fit prevents an adequate proportional-odds assessment. No substantive adjusted odds-ratio finding is claimed; no gender-adjusted ordinal model is fitted in the sparse data.
- Reliability, parallel analysis, and minimum-residual common-factor results are supplementary diagnostics. Principal components are distinguished from common factors; no validated two-item role scale or ordinal factor structure is claimed.
- No language/source subgroup significance search, mediation analysis, predictive machine learning, or learning-gain inference is performed. Agreement responses do not establish actual action frequencies or causal effects.
- The public participant matrix includes only gender, prior programming experience, recalled preference, and Q1–Q9. Age, first-enrollment status, and detailed language/source descriptions are aggregate inputs, not reconstructed individual records.
