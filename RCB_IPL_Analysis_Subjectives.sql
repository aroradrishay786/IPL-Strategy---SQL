-- Task 1 - 1.How does the toss decision affect the result of the match? (which visualizations could be used to present your answer better) 
-- And is the impact limited to only specific venues?
SELECT
    ROUND(
        SUM(CASE WHEN m.Match_Winner = m.Toss_Winner THEN 1 ELSE 0 END) * 100.0 /
        COUNT(m.Match_Id),
        2
    ) AS rcb_toss_win_conversion_pct
FROM matches m
WHERE m.Match_Winner IS NOT NULL
  AND m.Toss_Winner = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
  );
  
  SELECT
    s.Season_Year,
    v.Venue_Name,
    COUNT(m.Match_Id) AS matches_played_after_winning_toss,
    ROUND(
        SUM(
            CASE 
                WHEN m.Match_Winner = m.Toss_Winner THEN 1 
                ELSE 0 
            END
        ) * 100.0 / COUNT(m.Match_Id),
        2
    ) AS rcb_toss_win_conversion_pct
    FROM matches m
JOIN venue v
    ON m.Venue_Id = v.Venue_Id
JOIN season s
    ON m.Season_Id = s.Season_Id
WHERE m.Match_Winner IS NOT NULL
  AND m.Toss_Winner = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
  )
GROUP BY
    s.Season_Year,
    v.Venue_Name
ORDER BY
    s.Season_Year,
    rcb_toss_win_conversion_pct DESC;
    
-- Task 2 - 2.Suggest some of the players who would be best fit for the team.
-- Batsmen Shortlist
SELECT
p.Player_Name,
COUNT(DISTINCT s.season_id) AS Seasons_Played,
ROUND(AVG(season_runs), 2) AS Avg_Runs_Per_Season,
ROUND(STDDEV(season_runs), 2) AS Runs_Variation
FROM (
SELECT
season_id,
striker AS Player_Id,
SUM(runs_scored) AS season_runs
FROM vw_ball_match
GROUP BY season_id, striker
) s
JOIN player p
ON s.Player_Id = p.Player_Id
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT season_id) >= 3
AND AVG(season_runs) >= 300
ORDER BY Runs_Variation ASC, Avg_Runs_Per_Season DESC
LIMIT 5;

-- Bowlers Shortlist
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
    GROUP BY vb.Season_Id, vb.Bowler
) bw
JOIN player p
    ON bw.Player_Id = p.Player_Id
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT bw.Season_Id) >= 3
   AND AVG(bw.season_wickets) >= 10
ORDER BY Wickets_Variation ASC, Avg_Wickets_Per_Season DESC
LIMIT 5;
-- AllRounders Shortlist
WITH batting AS (
    SELECT
        Season_Id,
        Striker AS Player_Id,
        SUM(Runs_Scored) AS season_runs
    FROM vw_ball_match
    GROUP BY Season_Id, Striker
),
bowling AS (
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
    GROUP BY vb.Season_Id, vb.Bowler
)
SELECT
    p.Player_Name,
    COUNT(DISTINCT b.Season_Id) AS Seasons_Played,
    ROUND(AVG(b.season_runs), 2) AS Avg_Runs_Per_Season,
    ROUND(AVG(w.season_wickets), 2) AS Avg_Wickets_Per_Season
FROM batting b
JOIN bowling w
    ON b.Player_Id = w.Player_Id
   AND b.Season_Id = w.Season_Id
JOIN player p
    ON p.Player_Id = b.Player_Id
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT b.Season_Id) >= 3
   AND AVG(b.season_runs) >= 200
   AND AVG(w.season_wickets) >= 5
ORDER BY Avg_Runs_Per_Season DESC, Avg_Wickets_Per_Season DESC
LIMIT 5;

-- Task 3 - 3.What are some of the parameters that should be focused on while selecting the players?
-- Batting Consistency
SELECT
    p.Player_Name,
    COUNT(DISTINCT s.Season_Id) AS Seasons_Played,
    ROUND(AVG(s.season_runs), 2) AS Avg_Runs_Per_Season,
    ROUND(STDDEV(s.season_runs), 2) AS Runs_Variation
FROM (
    SELECT
        Season_Id,
        Striker AS Player_Id,
        SUM(Runs_Scored) AS season_runs
    FROM vw_ball_match
    GROUP BY Season_Id, Striker
) s
JOIN player p
    ON s.Player_Id = p.Player_Id
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT s.Season_Id) >= 3
ORDER BY Avg_Runs_Per_Season DESC, Runs_Variation ASC;
-- Bowling Consistency
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
    GROUP BY vb.Season_Id, vb.Bowler
) bw
JOIN player p
    ON bw.Player_Id = p.Player_Id
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT bw.Season_Id) >= 3
ORDER BY Avg_Wickets_Per_Season DESC, Wickets_Variation ASC;
-- AllRounder Contribution
WITH batting AS (
    SELECT
        Season_Id,
        Striker AS Player_Id,
        SUM(Runs_Scored) AS season_runs
    FROM vw_ball_match
    GROUP BY Season_Id, Striker
),
bowling AS (
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
    GROUP BY vb.Season_Id, vb.Bowler
)
SELECT
    p.Player_Name,
    COUNT(DISTINCT b.Season_Id) AS Seasons_Played,
    ROUND(AVG(b.season_runs), 2) AS Avg_Runs_Per_Season,
    ROUND(AVG(w.season_wickets), 2) AS Avg_Wickets_Per_Season
FROM batting b
JOIN bowling w
    ON b.Player_Id = w.Player_Id
   AND b.Season_Id = w.Season_Id
JOIN player p
    ON p.Player_Id = b.Player_Id
GROUP BY p.Player_Name
HAVING AVG(b.season_runs) >= 200
   AND AVG(w.season_wickets) >= 5
ORDER BY Avg_Runs_Per_Season DESC, Avg_Wickets_Per_Season DESC;
-- Task - 4 Which players offer versatility in their skills and can contribute effectively with both bat and ball?
SELECT
    p.Player_Name,
    COUNT(DISTINCT b.Season_Id) AS Seasons_Played,
    ROUND(AVG(b.season_runs), 2) AS Avg_Runs_Per_Season,
    ROUND(AVG(w.season_wickets), 2) AS Avg_Wickets_Per_Season
FROM (
    -- Batting performance per season
    SELECT
        Season_Id,
        Striker AS Player_Id,
        SUM(Runs_Scored) AS season_runs
    FROM vw_ball_match
    GROUP BY Season_Id, Striker
) b
JOIN (
    -- Bowling performance per season
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
    GROUP BY vb.Season_Id, vb.Bowler
) w
    ON b.Player_Id = w.Player_Id
   AND b.Season_Id = w.Season_Id
JOIN player p
    ON p.Player_Id = b.Player_Id
GROUP BY p.Player_Name
HAVING
    AVG(b.season_runs) >= 200
    AND AVG(w.season_wickets) >= 5
ORDER BY
    Avg_Runs_Per_Season DESC,
    Avg_Wickets_Per_Season DESC;
-- Task -5 Are there players whose presence positively influences the morale and performance of the team? 
-- Win/loss B9inary metric
WITH rcb_matches AS (
    SELECT
        m.Match_Id,
        m.Season_Id,
        CASE 
            WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 
        END AS rcb_win
    FROM matches m
    JOIN team rcb
        ON rcb.Team_Name = 'Royal Challengers Bangalore'
)
SELECT * FROM rcb_matches;
-- With Player v/s without player performance
WITH rcb_players_in_match AS (
    SELECT DISTINCT
        pm.Match_Id,
        pm.Player_Id,
        p.Player_Name
    FROM player_match pm
    JOIN player p
        ON pm.Player_Id = p.Player_Id
    JOIN team rcb
        ON pm.Team_Id = rcb.Team_Id
    WHERE rcb.Team_Name = 'Royal Challengers Bangalore'
)
SELECT * FROM rcb_players_in_match;
-- Win % WITH vs WITHOUT Each Player:-
WITH rcb_matches AS (
    SELECT
        m.Match_Id,
        CASE 
            WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 
        END AS rcb_win
    FROM matches m
    JOIN team rcb
        ON rcb.Team_Name = 'Royal Challengers Bangalore'
),
rcb_players AS (
    SELECT DISTINCT
        pm.Match_Id,
        pm.Player_Id,
        p.Player_Name
    FROM player_match pm
    JOIN player p ON pm.Player_Id = p.Player_Id
    JOIN team rcb ON pm.Team_Id = rcb.Team_Id
    WHERE rcb.Team_Name = 'Royal Challengers Bangalore'
)
SELECT
    rp.Player_Name,
    COUNT(DISTINCT rm.Match_Id) AS matches_with_player,
    ROUND(AVG(rm.rcb_win) * 100, 2) AS win_pct_with_player,
    ROUND(
        (
            SELECT AVG(rm2.rcb_win) * 100
            FROM rcb_matches rm2
            WHERE rm2.Match_Id NOT IN (
                SELECT Match_Id
                FROM rcb_players rp2
                WHERE rp2.Player_Id = rp.Player_Id
            )
        ), 2
    ) AS win_pct_without_player,
    ROUND(
        AVG(rm.rcb_win) * 100 -
        (
            SELECT AVG(rm2.rcb_win) * 100
            FROM rcb_matches rm2
            WHERE rm2.Match_Id NOT IN (
                SELECT Match_Id
                FROM rcb_players rp2
                WHERE rp2.Player_Id = rp.Player_Id
            )
        ), 2
    ) AS morale_impact_diff
FROM rcb_players rp
JOIN rcb_matches rm
    ON rp.Match_Id = rm.Match_Id
GROUP BY rp.Player_Name, rp.Player_Id
HAVING COUNT(DISTINCT rm.Match_Id) >= 15
ORDER BY morale_impact_diff DESC;
-- Team Batting Output With Player vs Overall:-
WITH rcb_team_runs AS (
    SELECT
        vb.Match_Id,
        SUM(vb.Runs_Scored) AS team_runs
    FROM vw_ball_match vb
    JOIN team rcb
        ON vb.Team_Batting = rcb.Team_Id
    WHERE rcb.Team_Name = 'Royal Challengers Bangalore'
    GROUP BY vb.Match_Id
),
rcb_players AS (
    SELECT DISTINCT
        pm.Match_Id,
        pm.Player_Id,
        p.Player_Name
    FROM player_match pm
    JOIN player p ON pm.Player_Id = p.Player_Id
    JOIN team rcb ON pm.Team_Id = rcb.Team_Id
    WHERE rcb.Team_Name = 'Royal Challengers Bangalore'
)
SELECT
    rp.Player_Name,
    ROUND(AVG(tr.team_runs), 2) AS avg_team_runs_with_player
FROM rcb_players rp
JOIN rcb_team_runs tr
    ON rp.Match_Id = tr.Match_Id
GROUP BY rp.Player_Name
HAVING COUNT(DISTINCT rp.Match_Id) >= 15
ORDER BY avg_team_runs_with_player DESC;
-- Season-wise Stability (Leadership Consistency)
WITH rcb_matches AS (
    SELECT
        m.Match_Id,
        m.Season_Id,
        CASE 
            WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 
        END AS rcb_win
    FROM matches m
    JOIN team rcb
        ON rcb.Team_Name = 'Royal Challengers Bangalore'
),
rcb_players AS (
    SELECT DISTINCT
        pm.Match_Id,
        pm.Player_Id,
        p.Player_Name
    FROM player_match pm
    JOIN player p ON pm.Player_Id = p.Player_Id
    JOIN team rcb ON pm.Team_Id = rcb.Team_Id
    WHERE rcb.Team_Name = 'Royal Challengers Bangalore'
)
SELECT
    rp.Player_Name,
    rm.Season_Id,
    ROUND(AVG(rm.rcb_win) * 100, 2) AS season_win_pct
FROM rcb_players rp
JOIN rcb_matches rm
    ON rp.Match_Id = rm.Match_Id
GROUP BY rp.Player_Name, rm.Season_Id
ORDER BY rp.Player_Name, rm.Season_Id;
-- Task 6 - What would you suggest to RCB before going to the mega auction?
-- batting Consistency
SELECT
    p.Player_Name,
    COUNT(DISTINCT s.Season_Id) AS Seasons_Played,
    ROUND(AVG(s.season_runs), 2) AS Avg_Runs_Per_Season,
    ROUND(STDDEV(s.season_runs), 2) AS Runs_Variation
FROM (
    SELECT
        Season_Id,
        Striker AS Player_Id,
        SUM(Runs_Scored) AS season_runs
    FROM vw_ball_match
    GROUP BY Season_Id, Striker
) s
JOIN player p
    ON s.Player_Id = p.Player_Id
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT s.Season_Id) >= 3
ORDER BY Avg_Runs_Per_Season DESC, Runs_Variation ASC;
-- Bowling Consistency
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
    GROUP BY vb.Season_Id, vb.Bowler
) bw
JOIN player p
    ON bw.Player_Id = p.Player_Id
GROUP BY p.Player_Name
HAVING COUNT(DISTINCT bw.Season_Id) >= 3
ORDER BY Avg_Wickets_Per_Season DESC, Wickets_Variation ASC;
-- AllRounder Contribution
WITH batting AS (
    SELECT
        Season_Id,
        Striker AS Player_Id,
        SUM(Runs_Scored) AS season_runs
    FROM vw_ball_match
    GROUP BY Season_Id, Striker
),
bowling AS (
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
    GROUP BY vb.Season_Id, vb.Bowler
)
SELECT
    p.Player_Name,
    COUNT(DISTINCT b.Season_Id) AS Seasons_Played,
    ROUND(AVG(b.season_runs), 2) AS Avg_Runs_Per_Season,
    ROUND(AVG(w.season_wickets), 2) AS Avg_Wickets_Per_Season
FROM batting b
JOIN bowling w
    ON b.Player_Id = w.Player_Id
   AND b.Season_Id = w.Season_Id
JOIN player p
    ON p.Player_Id = b.Player_Id
GROUP BY p.Player_Name
HAVING AVG(b.season_runs) >= 200
   AND AVG(w.season_wickets) >= 5
ORDER BY Avg_Runs_Per_Season DESC, Avg_Wickets_Per_Season DESC;
-- Morale / Impact Player Analysis (Win % Uplift)
WITH rcb_matches AS (
    SELECT
        m.Match_Id,
        CASE 
            WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 
        END AS rcb_win
    FROM matches m
    JOIN team rcb
        ON rcb.Team_Name = 'Royal Challengers Bangalore'
),
rcb_players AS (
    SELECT DISTINCT
        pm.Match_Id,
        pm.Player_Id,
        p.Player_Name
    FROM player_match pm
    JOIN player p ON pm.Player_Id = p.Player_Id
    JOIN team rcb ON pm.Team_Id = rcb.Team_Id
    WHERE rcb.Team_Name = 'Royal Challengers Bangalore'
)
SELECT
    rp.Player_Name,
    COUNT(DISTINCT rm.Match_Id) AS matches_with_player,
    ROUND(AVG(rm.rcb_win) * 100, 2) AS win_pct_with_player,
    ROUND(
        (
            SELECT AVG(rm2.rcb_win) * 100
            FROM rcb_matches rm2
            WHERE rm2.Match_Id NOT IN (
                SELECT Match_Id
                FROM rcb_players rp2
                WHERE rp2.Player_Id = rp.Player_Id
            )
        ), 2
    ) AS win_pct_without_player,
    ROUND(
        AVG(rm.rcb_win) * 100 -
        (
            SELECT AVG(rm2.rcb_win) * 100
            FROM rcb_matches rm2
            WHERE rm2.Match_Id NOT IN (
                SELECT Match_Id
                FROM rcb_players rp2
                WHERE rp2.Player_Id = rp.Player_Id
            )
        ), 2
    ) AS morale_impact_diff
FROM rcb_players rp
JOIN rcb_matches rm
    ON rp.Match_Id = rm.Match_Id
GROUP BY rp.Player_Name, rp.Player_Id
HAVING COUNT(DISTINCT rm.Match_Id) >= 15
ORDER BY morale_impact_diff DESC;
-- Venue & Toss Impact Analysis (RCB-specific)
SELECT
    s.Season_Year,
    v.Venue_Name,
    COUNT(m.Match_Id) AS matches_played_after_winning_toss,
    ROUND(
        SUM(
            CASE 
                WHEN m.Match_Winner = m.Toss_Winner THEN 1 
                ELSE 0 
            END
        ) * 100.0 / COUNT(m.Match_Id),
        2
    ) AS rcb_toss_win_conversion_pct
FROM matches m
JOIN venue v
    ON m.Venue_Id = v.Venue_Id
JOIN season s
    ON m.Season_Id = s.Season_Id
WHERE m.Match_Winner IS NOT NULL
  AND m.Toss_Winner = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
  )
GROUP BY
    s.Season_Year,
    v.Venue_Name
ORDER BY
    s.Season_Year,
    rcb_toss_win_conversion_pct DESC;
-- Task 7 - 7.What do you think could be the factors contributing to the 
-- high-scoring matches and the impact on viewership and team strategies
-- Average first-innings score per venue:-
SELECT 
    v.Venue_Name,
    ROUND(SUM(b.Runs_Scored) / COUNT(DISTINCT m.Match_Id), 2) AS avg_first_innings_score
FROM ball_by_ball b
JOIN matches m ON b.Match_Id = m.Match_Id
JOIN venue v ON m.Venue_Id = v.Venue_Id
WHERE b.Innings_No = 1
GROUP BY v.Venue_Name
ORDER BY avg_first_innings_score DESC;
-- Powerplay scoring impact:-
SELECT 
    Match_Id,
    SUM(Runs_Scored) AS powerplay_runs
FROM ball_by_ball
WHERE Over_Id <= 6
GROUP BY Match_Id;
-- Runs scored in death overs (16–20):
SELECT 
    Match_Id,
    SUM(Runs_Scored) AS death_runs
FROM ball_by_ball
WHERE Over_Id BETWEEN 16 AND 20
GROUP BY Match_Id;
-- Players contributing with both bat & ball:
WITH batting_per_season AS (
    SELECT
        vb.Striker AS Player_Id,
        m.Season_Id,
        SUM(vb.Runs_Scored) AS season_runs
    FROM vw_ball_match vb
    JOIN matches m
        ON vb.Match_Id = m.Match_Id
    GROUP BY vb.Striker, m.Season_Id
),
bowling_per_season AS (
    SELECT
        vb.Bowler AS Player_Id,
        m.Season_Id,
        COUNT(wt.Player_Out) AS season_wickets
    FROM vw_ball_match vb
    JOIN wicket_taken wt
        ON vb.Match_Id = wt.Match_Id
       AND vb.Innings_No = wt.Innings_No
       AND vb.Over_Id = wt.Over_Id
       AND vb.Ball_Id = wt.Ball_Id
    JOIN matches m
        ON vb.Match_Id = m.Match_Id
    GROUP BY vb.Bowler, m.Season_Id
)
SELECT
    p.Player_Name,
    COUNT(DISTINCT b.Season_Id) AS Seasons_Played,
    ROUND(AVG(b.season_runs), 2) AS Avg_Runs_Per_Season,
    ROUND(AVG(w.season_wickets), 2) AS Avg_Wickets_Per_Season
FROM batting_per_season b
JOIN bowling_per_season w
    ON b.Player_Id = w.Player_Id
   AND b.Season_Id = w.Season_Id
JOIN player p
    ON b.Player_Id = p.Player_Id
WHERE b.season_runs >= 100       -- meaningful batting contribution
  AND w.season_wickets >= 5      -- meaningful bowling contribution
GROUP BY p.Player_Name
ORDER BY Avg_Runs_Per_Season DESC;
-- Runs And Wickets Co-Relation With Winning:-
SELECT
    m.Match_Id,
    SUM(
        CASE
            WHEN vb.team_batting = m.Match_Winner
            THEN vb.runs_scored
            ELSE 0
        END
    ) AS winner_runs,
    COUNT(
        CASE
            WHEN vb.team_bowling = m.Match_Winner
             AND wt.Player_Out IS NOT NULL
            THEN 1
        END
    ) AS winner_wickets
FROM matches m
JOIN vw_ball_match vb
    ON m.Match_Id = vb.match_id
LEFT JOIN wicket_taken wt
    ON vb.match_id = wt.Match_Id
   AND vb.innings_no = wt.Innings_No
   AND vb.over_id = wt.Over_Id
   AND vb.ball_id = wt.Ball_Id
WHERE m.Match_Winner IS NOT NULL
GROUP BY m.Match_Id
ORDER BY m.Match_Id;
-- TASK 8 - 8.Analyze the impact of home-ground advantage on team performance and identify strategies to maximize this advantage for RCB.
SELECT
    CASE 
        WHEN v.Venue_Name = 'M Chinnaswamy Stadium' THEN 'Home'
        ELSE 'Away'
    END AS match_type,
    COUNT(*) AS matches_played,
    ROUND(
        SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS win_percentage
FROM matches m
JOIN venue v 
    ON m.Venue_Id = v.Venue_Id
JOIN team rcb
    ON rcb.Team_Name = 'Royal Challengers Bangalore'
WHERE m.Team_1 = rcb.Team_Id 
   OR m.Team_2 = rcb.Team_Id
GROUP BY match_type;
-- TASK 9 - 9.Come up with a visual and analytical analysis of the RCB's past season's 
-- performance and potential reasons for them not winning a trophy.
SELECT
    m.Season_Id,
    ROUND(
        SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS win_percentage
FROM matches m
JOIN team rcb
    ON rcb.Team_Name = 'Royal Challengers Bangalore'
WHERE m.Team_1 = rcb.Team_Id
   OR m.Team_2 = rcb.Team_Id
GROUP BY m.Season_Id
ORDER BY m.Season_Id;
-- Home vs Away Performance (Home Advantage Not Fully Used):
SELECT
    CASE
        WHEN m.Venue_Id = (
            SELECT Venue_Id
            FROM venue
            WHERE Venue_Name = 'M Chinnaswamy Stadium'
        ) THEN 'Home'
        ELSE 'Away'
    END AS match_type,
    COUNT(*) AS matches_played,
    ROUND(
        SUM(CASE WHEN m.Match_Winner = rcb.Team_Id THEN 1 ELSE 0 END) * 100.0
        / COUNT(*),
        2
    ) AS win_percentage
FROM matches m
JOIN team rcb
    ON rcb.Team_Name = 'Royal Challengers Bangalore'
WHERE m.Team_1 = rcb.Team_Id
   OR m.Team_2 = rcb.Team_Id
GROUP BY match_type;
-- Batting Dependency on Star Players:-
WITH team_runs AS (
    SELECT
        Season_Id,
        SUM(Runs_Scored) AS total_team_runs
    FROM vw_ball_match
    WHERE Team_Batting = (
        SELECT Team_Id FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
    )
    GROUP BY Season_Id
),
player_runs AS (
    SELECT
        Season_Id,
        Striker AS Player_Id,
        SUM(Runs_Scored) AS player_runs
    FROM vw_ball_match
    WHERE Team_Batting = (
        SELECT Team_Id FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
    )
    GROUP BY Season_Id, Striker
)
SELECT
    tr.Season_Id,
    p.Player_Name,
    ROUND(pr.player_runs * 100.0 / tr.total_team_runs, 2) AS dependency_percentage
FROM player_runs pr
JOIN team_runs tr
    ON pr.Season_Id = tr.Season_Id
JOIN player p
    ON pr.Player_Id = p.Player_Id
ORDER BY tr.Season_Id, dependency_percentage DESC;
-- Bowling Weakness in Death Overs (Match-Closing Issue):
SELECT
    Season_Id,
    ROUND(SUM(Runs_Scored) * 6.0 / COUNT(Ball_Id), 2) AS death_over_economy
FROM vw_ball_match
WHERE Over_Id BETWEEN 16 AND 20
  AND Team_Bowling = (
        SELECT Team_Id
        FROM team
        WHERE Team_Name = 'Royal Challengers Bangalore'
  )
GROUP BY Season_Id
ORDER BY Season_Id;

