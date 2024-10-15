/*  Created by: Ramy-Badr-Ahmed (https://github.com/Ramy-Badr-Ahmed)
    Please open any issue or pull request to address bugs/corrections to this file.
    Thank you!

The query utilizes two CTEs: MaxScores and NonAmbiguous.

MaxScores CTE:

    retrieves the highest score for each SpectrumID from the spectrum_has_match table while filtering out any scores below 0.3.
    The spectrum table is joined to access SpectrumID, and msrun_scan is included to consider spectra linked to actual mass-spectrometry runs.
    groups results by SpectrumID and computes the maximum score for each.

NonAmbiguous CTE:

    identifies sequences associated with the highest scores.
    joins the spectrum_has_match table with the results from the MaxScores CTE, conider only those sequences that match the highest score for each spectrum
    groups by SpectrumID, Sequence, Score to prepare for the next step of identifying uniqueness.

Finally:

    The final SELECT statement counts the distinct sequences found in the NonAmbiguous CTE.
    This should give the total number of unique sequences identified across the specified spectra.

 */

-- Get the highest score for each SpectrumID
WITH MaxScores AS (
    SELECT shm.SpectrumID, MAX(Score) AS MaxScore
    FROM (spectrum_has_match shm
        JOIN spectrum s ON shm.SpectrumID = s.SpectrumID) as rt     -- Join to the spectrum table
    JOIN msrun_scan ms ON rt.SpectrumID = shm.SpectrumID                      -- Link msrun_scan via spectrum
    WHERE shm.Score >= 0.3
    GROUP BY shm.SpectrumID
),
-- Check for non-ambiguous highest scores
NonAmbiguous AS (

    SELECT shm.SpectrumID, shm.Sequence, shm.Score
    FROM spectrum_has_match shm
    JOIN MaxScores ms
      ON shm.SpectrumID = ms.SpectrumID
     AND shm.Score = ms.MaxScore                        -- Match to the highest score
    -- Ensure no duplicates with the same score
    GROUP BY shm.SpectrumID, shm.Sequence, shm.Score
)
-- Finally, count the unique sequences
SELECT COUNT(DISTINCT Sequence) AS UniqueSequences
FROM NonAmbiguous;
