/*
    Created by: Ramy-Badr-Ahmed (https://github.com/Ramy-Badr-Ahmed)
    Please open any issue or pull request to address bugs/corrections to this file.
    Thank you!

 This query uses nested subqueries instead of CTEs.

    The inner subquery retrieves the highest score for each SpectrumID while filtering out scores below 0.3.
    It joins the spectrum and msrun_scan tables, then groups by SpectrumID to get the maximum score for each.

    The outer query:
    - joins the spectrum_has_match table with the results of the inner subquery to get sequences matching the highest score.
    - groups by SpectrumID, Sequence, and Score.

    Finally, the outermost query counts the distinct sequences, which gives the total number of unique sequences identified in the experiments.
*/

SELECT COUNT(DISTINCT Sequence) AS UniqueSequences
FROM (
         SELECT shm.Sequence
         FROM spectrum_has_match shm
                  JOIN (
             SELECT shm.SpectrumID, MAX(Score) AS MaxScore
             FROM spectrum_has_match shm
                      JOIN spectrum s ON shm.SpectrumID = s.SpectrumID
                      JOIN msrun_scan ms ON shm.SpectrumID = s.SpectrumID
             WHERE shm.Score >= 0.3
             GROUP BY shm.SpectrumID
         ) AS MaxScores
                       ON shm.SpectrumID = MaxScores.SpectrumID
                           AND shm.Score = MaxScores.MaxScore
         GROUP BY shm.SpectrumID, shm.Sequence, shm.Score
     );