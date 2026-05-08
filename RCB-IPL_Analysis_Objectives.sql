CREATE VIEW vw_ball_match AS
SELECT
    b.match_id,
    b.innings_no,
    b.over_id,
    b.ball_id,
    b.striker,
    b.non_striker,
    b.bowler,
    b.team_batting,
    b.team_bowling,
    b.runs_scored,     
    m.season_id,
    m.venue_id
FROM ball_by_ball b
JOIN matches m
ON b.match_id = m.match_id;
CREATE VIEW vw_batting_summary AS
SELECT
    striker AS player_id,
    season_id,
    COUNT(ball_id) AS balls_faced,
    SUM(runs_scored) AS total_runs
FROM vw_ball_match
GROUP BY striker, season_id;
CREATE VIEW vw_bowling_summary AS
SELECT
    bowler AS player_id,
    season_id,
    COUNT(ball_id) AS balls_bowled
FROM vw_ball_match
GROUP BY bowler, season_id;
CREATE VIEW vw_rcb_matches AS
SELECT *
FROM matches
WHERE match_winner = 'Royal Challengers Bangalore'
   OR toss_winner = 'Royal Challengers Bangalore';
   
-- Objective Questions
-- TASK 1 - List the different dtypes of columns in table “ball_by_ball” (using information schema)
-- DESCRIBE ball_by_ball;
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'ball_by_ball';
-- TASK 2 - What is the total number of runs scored in 1st season by RCB (bonus: also include the extra runs using the extra runs table)-- 
SELECT 
    SUM(bm.runs_scored + COALESCE(er.Extra_Runs, 0)) AS total_runs
FROM vw_ball_match bm
LEFT JOIN extra_runs er
    ON bm.match_id = er.Match_Id
   AND bm.innings_No = er.Innings_No
   AND bm.over_id = er.Over_Id
   AND bm.ball_id = er.Ball_Id
WHERE bm.team_batting = 2
  AND bm.season_id = (
        SELECT MIN(season_id)
        FROM vw_ball_match
    );
-- TASK 3 - How many players were more than the age of 25 during season 2014?    
SELECT COUNT(DISTINCT p.player_id) AS players_above_25
FROM player p
JOIN player_match pm
  ON p.player_id = pm.player_id
JOIN matches m
  ON pm.match_id = m.match_id
JOIN season s
  ON m.season_id = s.season_id
WHERE s.season_year = 2014
  AND (2014 - YEAR(p.DOB)) > 25;
-- TASK 4 - How many matches did RCB win in 2013? 
SELECT 
    COUNT(*) AS rcb_wins_2013
FROM matches m
JOIN team t
    ON m.Match_Winner = t.Team_Id
JOIN season s
    ON m.Season_Id = s.Season_Id
WHERE t.Team_Name = 'Royal Challengers Bangalore'
  AND s.Season_Year = 2013;
-- TASk 5 - List the top 10 players according to their strike rate in the last 4 seasons.
SELECT
    p.Player_Name,
    SUM(vb.Runs_Scored) AS total_runs,
    COUNT(vb.Ball_Id) AS balls_faced,
    (SUM(vb.Runs_Scored) * 100.0 / COUNT(vb.Ball_Id)) AS strike_rate
FROM vw_ball_match vb
JOIN player p
    ON vb.Striker = p.Player_Id
WHERE vb.Season_Id IN (6, 7, 8, 9)
GROUP BY p.Player_Id, p.Player_Name
HAVING COUNT(vb.Ball_Id) >= 100
ORDER BY strike_rate DESC
LIMIT 10;
-- TASk 6 - What are the average runs scored by each batsman considering all the seasons?
SELECT
    p.Player_Name,
    SUM(vb.Runs_Scored) AS total_runs,
    COUNT(DISTINCT CONCAT(vb.Match_Id, '-', vb.Innings_No)) AS innings_played,
    ROUND(
        SUM(vb.Runs_Scored) * 1.0 /
        COUNT(DISTINCT CONCAT(vb.Match_Id, '-', vb.Innings_No)),
        2
    ) AS average_runs
FROM vw_ball_match vb
JOIN player p
    ON vb.Striker = p.Player_Id
GROUP BY p.Player_Id, p.Player_Name
ORDER BY average_runs DESC;
-- TASK 7 - What are the average wickets taken by each bowler considering all the seasons?
SELECT
    p.Player_Name,
    COUNT(wt.Ball_Id) AS total_wickets,
    COUNT(
        DISTINCT CONCAT(vb.Match_Id, '-', vb.Innings_No)
    ) AS innings_bowled,
    ROUND(
        COUNT(wt.Ball_Id) * 1.0 /
        COUNT(DISTINCT CONCAT(vb.Match_Id, '-', vb.Innings_No)),
        2
    ) AS average_wickets
FROM vw_ball_match vb
JOIN player p
    ON vb.Bowler = p.Player_Id
LEFT JOIN wicket_taken wt
    ON vb.Match_Id = wt.Match_Id
   AND vb.Ball_Id = wt.Ball_Id
GROUP BY p.Player_Id, p.Player_Name
ORDER BY average_wickets DESC;
-- TASK 8 - List all the players who have average runs scored greater than the overall average 
-- and who have taken wickets greater than the overall average.
SELECT
    p.Player_Name,
    ba.avg_runs,
    bo.avg_wickets
FROM
    (
        SELECT
            vb.Striker AS player_id,
            SUM(vb.Runs_Scored) * 1.0 /
            COUNT(DISTINCT CONCAT(vb.Match_Id, '-', vb.Innings_No)) AS avg_runs
        FROM vw_ball_match vb
        GROUP BY vb.Striker
    ) ba
JOIN
    (
        SELECT
            vb.Bowler AS player_id,
            COUNT(wt.Ball_Id) * 1.0 /
            COUNT(DISTINCT CONCAT(vb.Match_Id, '-', vb.Innings_No)) AS avg_wickets
        FROM vw_ball_match vb
        LEFT JOIN wicket_taken wt
            ON vb.Match_Id = wt.Match_Id
           AND vb.Ball_Id = wt.Ball_Id
        GROUP BY vb.Bowler
    ) bo
    ON ba.player_id = bo.player_id
JOIN player p
    ON p.Player_Id = ba.player_id
WHERE ba.avg_runs >
      (
          SELECT AVG(avg_runs)
          FROM (
              SELECT
                  vb.Striker,
                  SUM(vb.Runs_Scored) * 1.0 /
                  COUNT(DISTINCT CONCAT(vb.Match_Id, '-', vb.Innings_No)) AS avg_runs
              FROM vw_ball_match vb
              GROUP BY vb.Striker
          ) t
      )
  AND bo.avg_wickets >
      (
          SELECT AVG(avg_wickets)
          FROM (
              SELECT
                  vb.Bowler,
                  COUNT(wt.Ball_Id) * 1.0 /
                  COUNT(DISTINCT CONCAT(vb.Match_Id, '-', vb.Innings_No)) AS avg_wickets
              FROM vw_ball_match vb
              LEFT JOIN wicket_taken wt
                  ON vb.Match_Id = wt.Match_Id
                 AND vb.Ball_Id = wt.Ball_Id
              GROUP BY vb.Bowler
          ) t
      );
-- TASK 9 - Create a table rcb_record table that shows the wins and losses of RCB in an individual venue.
CREATE TABLE rcb_record AS
SELECT
    v.Venue_Name,
    SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) AS wins,
    SUM(CASE WHEN m.Match_Winner <> rcb.Team_Id THEN 1 ELSE 0 END) AS losses
FROM matches m
JOIN venue v
    ON m.Venue_Id = v.Venue_Id
JOIN (
    SELECT Team_Id
    FROM team
    WHERE Team_Name = 'Royal Challengers Bangalore'
) rcb
JOIN player_match pm
    ON m.Match_Id = pm.Match_Id
   AND pm.Team_Id = rcb.Team_Id
GROUP BY v.Venue_Name;
-- TASK 10 - What is the impact of bowling style on wickets taken?
SELECT
    bs.Bowling_skill,
    COUNT(wt.Player_Out) AS total_wickets
FROM vw_ball_match vb
JOIN wicket_taken wt
    ON vb.Match_Id = wt.Match_Id
   AND vb.Innings_No = wt.Innings_No
   AND vb.Over_Id = wt.Over_Id
   AND vb.Ball_Id = wt.Ball_Id
JOIN player p
    ON vb.Bowler = p.Player_Id
JOIN bowling_style bs
    ON p.Bowling_skill = bs.Bowling_Id
GROUP BY bs.Bowling_skill
ORDER BY total_wickets DESC;
-- TASK 11 - Write the SQL query to provide a status of whether the performance of the team is better than 
-- the previous year's performance on the basis of the number of runs scored by the team in the season and the number of wickets taken
WITH team_runs AS (
    SELECT
        Season_Id,
        Team_Batting AS Team_Id,
        SUM(Runs_Scored) AS total_runs
    FROM vw_ball_match
    GROUP BY Season_Id, Team_Batting
),
team_wickets AS (
    SELECT
        vb.Season_Id,
        vb.Team_Bowling AS Team_Id,
        COUNT(wt.Ball_Id) AS total_wickets
    FROM vw_ball_match vb
    LEFT JOIN wicket_taken wt
        ON vb.Ball_Id = wt.Ball_Id
    GROUP BY vb.Season_Id, vb.Team_Bowling
),
team_season_stats AS (
    SELECT
        r.Season_Id,
        r.Team_Id,
        r.total_runs,
        w.total_wickets
    FROM team_runs r
    JOIN team_wickets w
        ON r.Season_Id = w.Season_Id
       AND r.Team_Id = w.Team_Id
)
SELECT
    t.Team_Name,
    s.Season_Year,
    ts.total_runs,
    ts.total_wickets,
    CASE
        WHEN ts.total_runs > LAG(ts.total_runs) OVER (PARTITION BY ts.Team_Id ORDER BY ts.Season_Id)
         AND ts.total_wickets > LAG(ts.total_wickets) OVER (PARTITION BY ts.Team_Id ORDER BY ts.Season_Id)
        THEN 'Better than previous season'
        ELSE 'Not better than previous season'
    END AS performance_status
FROM team_season_stats ts
JOIN team t
    ON ts.Team_Id = t.Team_Id
JOIN season s
    ON ts.Season_Id = s.Season_Id
ORDER BY t.Team_Name, s.Season_Year;
-- TASK 12. Can you derive more KPIs for the team strategy?-- 
-- KPI 1: Powerplay Run Rate (Overs 1–6)
-- Player Wise
SELECT
    vb.Season_Id,
    p.Player_Name AS batsman_name,
    ROUND(
        SUM(vb.Runs_Scored) / (COUNT(vb.Ball_Id) / 6.0),
        2
    ) AS powerplay_run_rate
FROM vw_ball_match vb
JOIN player p
    ON vb.Striker = p.Player_Id
WHERE vb.Over_Id BETWEEN 1 AND 6
  AND vb.Team_Batting = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
  )
GROUP BY vb.Season_Id, p.Player_Id, p.Player_Name
HAVING COUNT(vb.Ball_Id) >= 30   -- ≈ 5 powerplay overs (recommended)
ORDER BY vb.Season_Id, powerplay_run_rate DESC;

-- Team Wise
SELECT
    Season_Id,
    ROUND(SUM(Runs_Scored) * 6.0 / COUNT(Ball_Id), 2) AS rcb_powerplay_run_rate
FROM vw_ball_match
WHERE Over_Id BETWEEN 1 AND 6
  AND Team_Batting = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
  )
GROUP BY Season_Id
ORDER BY Season_Id;

-- For All Teams
SELECT
    vb.Season_Id,
    t.Team_Name,
    ROUND(
        SUM(vb.Runs_Scored) / (COUNT(vb.Ball_Id) / 6.0),
        2
    ) AS powerplay_run_rate
FROM vw_ball_match vb
JOIN team t
    ON vb.Team_Batting = t.Team_Id
WHERE vb.Over_Id BETWEEN 1 AND 6
GROUP BY vb.Season_Id, t.Team_Name
ORDER BY Team_Name, powerplay_run_rate DESC;

-- KPI 2: Death Overs Economy (Overs 16–20)
-- Player WISE
SELECT
    vb.Season_Id,
    p.Player_Name AS bowler_name,
    ROUND(
        SUM(vb.Runs_Scored) / (COUNT(vb.Ball_Id) / 6.0),
        2
    ) AS death_over_economy
FROM vw_ball_match vb
JOIN player p
    ON vb.Bowler = p.Player_Id
WHERE vb.Over_Id BETWEEN 16 AND 20
  AND vb.Team_Bowling = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
  )
GROUP BY vb.Season_Id, p.Player_Id, p.Player_Name
HAVING COUNT(vb.Ball_Id) >= 24   -- optional but recommended (≈4 death overs)
ORDER BY vb.Season_Id, death_over_economy;
-- Team Wise
SELECT
    Season_Id,
    ROUND(SUM(Runs_Scored) * 6.0 / COUNT(Ball_Id), 2) AS rcb_death_over_economy
FROM vw_ball_match
WHERE Over_Id BETWEEN 16 AND 20
  AND Team_Bowling = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
  )
GROUP BY Season_Id
ORDER BY Season_Id;
-- For All time
SELECT
    vb.Season_Id,
    t.Team_Name,
    ROUND(
        SUM(vb.Runs_Scored) * 6.0 / COUNT(vb.Ball_Id),
        2
    ) AS death_over_economy
FROM vw_ball_match vb
JOIN team t
    ON vb.Team_Bowling = t.Team_Id
WHERE vb.Over_Id BETWEEN 16 AND 20
GROUP BY
    vb.Season_Id,
    t.Team_Name
ORDER BY
    t.Team_Name,
    death_over_economy DESC;

-- KPI 3: Toss Win Conversion Rate
SELECT
    v.Venue_Name,
    SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) AS wins,
    COUNT(m.Match_Id) AS matches_played,
    ROUND(
        SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) * 100.0 /
        COUNT(m.Match_Id),
        2
    ) AS win_percentage
FROM matches m
JOIN venue v
    ON m.Venue_Id = v.Venue_Id
JOIN (
    SELECT Team_Id
    FROM team
    WHERE Team_Name = 'Royal Challengers Bangalore'
) rcb
WHERE
    m.Team_1 = rcb.Team_Id
    OR m.Team_2 = rcb.Team_Id
GROUP BY v.Venue_Name
ORDER BY win_percentage DESC;



-- KPI 4: Home vs Away Win Ratio (Venue Strategy KPI)
SELECT
    v.Venue_Name,
    SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) AS wins,
    COUNT(*) AS matches_played,
    ROUND(
        SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) * 100.0 /
        COUNT(*),
        2
    ) AS win_percentage
FROM matches m
JOIN venue v
    ON m.Venue_Id = v.Venue_Id
JOIN (
    SELECT Team_Id FROM team
    WHERE Team_Name = 'Royal Challengers Bangalore'
) rcb
JOIN player_match pm
    ON m.Match_Id = pm.Match_Id
   AND pm.Team_Id = rcb.Team_Id
GROUP BY v.Venue_Name
ORDER BY win_percentage DESC;

-- KPI 5: Batting Dependency Index
WITH team_runs AS (
    SELECT
        Season_Id,
        Team_Batting AS Team_Id,
        SUM(Runs_Scored) AS total_team_runs
    FROM vw_ball_match
    GROUP BY Season_Id, Team_Batting
),
player_runs AS (
    SELECT
        Season_Id,
        Striker AS Player_Id,
        Team_Batting AS Team_Id,
        SUM(Runs_Scored) AS player_runs
    FROM vw_ball_match
    GROUP BY Season_Id, Striker, Team_Batting
)
SELECT
    tr.Season_Id,
    p.Player_Name,
    pr.player_runs,
    tr.total_team_runs,
    ROUND(pr.player_runs * 100.0 / tr.total_team_runs, 2) AS dependency_percentage
FROM player_runs pr
JOIN team_runs tr
    ON pr.Season_Id = tr.Season_Id
   AND pr.Team_Id = tr.Team_Id
JOIN player p
    ON pr.Player_Id = p.Player_Id
WHERE pr.Team_Id = (
    SELECT Team_Id
    FROM team
    WHERE Team_Name = 'Royal Challengers Bangalore'
)
ORDER BY Season_Id, dependency_percentage DESC;


-- TASK 13 - Using SQL, write a query to find out the average wickets taken by each bowler in each venue. 
-- Also, rank the gender according to the average value.
WITH bowler_venue_stats AS (
    SELECT  v.Venue_Id,  v.Venue_Name,  p.Player_Name,
        COUNT(wt.Player_Out) AS Total_Wickets_Taken,
        COUNT(DISTINCT m.Match_Id) AS Total_Matches_Played,
        ROUND(
            COUNT(wt.Player_Out) / COUNT(DISTINCT m.Match_Id),2) AS Avg_Wickets
    FROM wicket_taken wt
    JOIN ball_by_ball bb  ON wt.Match_Id = bb.Match_Id
       AND wt.Innings_No = bb.Innings_No
       AND wt.Over_Id = bb.Over_Id
       AND wt.Ball_Id = bb.Ball_Id
    JOIN matches m   ON wt.Match_Id = m.Match_Id
    JOIN venue v  ON m.Venue_Id = v.Venue_Id
    JOIN player p   ON bb.Bowler = p.Player_Id
    GROUP BY v.Venue_Id, v.Venue_Name, p.Player_Name
    HAVING COUNT(DISTINCT m.Match_Id) > 10
)
SELECT
    Venue_Name, Player_Name, Total_Matches_Played,  Total_Wickets_Taken,
    Avg_Wickets,
    DENSE_RANK() OVER (ORDER BY Avg_Wickets DESC) AS Venue_Rank
FROM bowler_venue_stats;
-- TASK 14 - Which of the given players have consistently performed well in past seasons? 
-- BATTING Consistency
SELECT
    p.Player_Name,
    COUNT(DISTINCT season_id) AS Seasons_Played,
    ROUND(AVG(season_runs), 2) AS Avg_Runs_Per_Season,
    ROUND(STDDEV(season_runs), 2) AS Runs_Variation
FROM (
    SELECT
        vb.season_id,
        vb.striker AS Player_Id,
        SUM(vb.runs_scored) AS season_runs
    FROM vw_ball_match vb
    WHERE vb.team_batting = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
    )
    GROUP BY vb.season_id, vb.striker
) t
JOIN player p
    ON t.Player_Id = p.Player_Id
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT t.season_id) >= 3
   AND AVG(season_runs) >= 300
ORDER BY Runs_Variation ASC, Avg_Runs_Per_Season DESC;

-- BOWLER CONSISTENCY
SELECT
    p.Player_Name,
    COUNT(DISTINCT bw.Season_Id) AS Seasons_Played,
    ROUND(AVG(bw.season_wickets), 2) AS Avg_Wickets_Per_Season,
    ROUND(STDDEV(bw.season_wickets), 2) AS Wickets_Variation
FROM (
    SELECT
        vb.Season_Id,
        vb.Bowler AS Player_Id,
        COUNT(wt.Player_Out) AS season_wickets
    FROM vw_ball_match vb
    JOIN wicket_taken wt
        ON vb.Match_Id = wt.Match_Id
       AND vb.Innings_No = wt.Innings_No
       AND vb.Over_Id = wt.Over_Id
       AND vb.Ball_Id = wt.Ball_Id
    WHERE vb.Team_Bowling = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
    )
    GROUP BY vb.Season_Id, vb.Bowler
) bw
JOIN player p
    ON bw.Player_Id = p.Player_Id
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT bw.Season_Id) >= 3
   AND AVG(bw.season_wickets) >= 10
ORDER BY Wickets_Variation ASC, Avg_Wickets_Per_Season DESC;


-- TASK 15 - Are there players whose performance is more suited to specific venues or conditions? 
-- Batsmen
SELECT
    v.Venue_Name,
    p.Player_Name,
    ROUND(
        SUM(vb.Runs_Scored) * 1.0 /
        COUNT(DISTINCT CONCAT(vb.Match_Id, '-', vb.Innings_No)),
        2
    ) AS avg_runs_at_venue
FROM vw_ball_match vb
JOIN venue v
    ON vb.Venue_Id = v.Venue_Id
JOIN player p
    ON vb.Striker = p.Player_Id
GROUP BY v.Venue_Name, p.Player_Id, p.Player_Name
HAVING COUNT(DISTINCT vb.Match_Id) >= 5
ORDER BY avg_runs_at_venue DESC;
-- BOWLERS
SELECT
    v.Venue_Name,
    p.Player_Name,
    ROUND(
        w.total_wickets * 1.0 / m.matches_played,
        2
    ) AS avg_wickets_at_venue
FROM (
    SELECT
        vb.Venue_Id,
        vb.Bowler AS Player_Id,
        COUNT(wt.Ball_Id) AS total_wickets
    FROM vw_ball_match vb
    JOIN wicket_taken wt
        ON vb.Ball_Id = wt.Ball_Id
    GROUP BY vb.Venue_Id, vb.Bowler
) w
JOIN (
    SELECT
        Venue_Id,
        Bowler AS Player_Id,
        COUNT(DISTINCT Match_Id) AS matches_played
    FROM vw_ball_match
    GROUP BY Venue_Id, Bowler
) m
    ON w.Venue_Id = m.Venue_Id
   AND w.Player_Id = m.Player_Id
JOIN venue v
    ON w.Venue_Id = v.Venue_Id
JOIN player p
    ON w.Player_Id = p.Player_Id
WHERE m.matches_played >= 5
ORDER BY avg_wickets_at_venue DESC;













 