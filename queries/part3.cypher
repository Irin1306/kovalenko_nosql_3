// Запит 1. Знайти всі фільми жанру «Thriller» із середнім рейтингом вище 4.0   

MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre {name: 'Thriller'})
MATCH (u:User)-[r:RATED]->(m)
WITH m, avg(r.rating) AS avgRating
WHERE avgRating > 4.0
RETURN m.title AS movie,
       round(avgRating, 2) AS averageRating
ORDER BY averageRating DESC;


// Запит 2. Знайти користувачів, які поставили оцінку 5 більш ніж 50 фільмам

MATCH (u:User)-[r:RATED]->(:Movie)
WHERE r.rating = 5
WITH u, count(r) AS fiveStarRatings
WHERE fiveStarRatings > 50
RETURN u.userId AS userId,
       fiveStarRatings
ORDER BY fiveStarRatings DESC;

// Запит 3. Знайти фільми, які обидва користувачі (наприклад, userId=1 і userId=2) оцінили високо (рейтинг ≥ 4)

MATCH (u1:User {userId: 1})-[r1:RATED]->(m:Movie)
MATCH (u2:User {userId: 2})-[r2:RATED]->(m)
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.title AS movie,
       r1.rating AS user1Rating,
       r2.rating AS user2Rating;


// Запит 4. Знайти жанри, чиї фільми стабільно отримують високі оцінки — середній рейтинг і кількість оцінок

MATCH (m:Movie)-[:HAS_GENRE]->(g:Genre)
MATCH (u:User)-[r:RATED]->(m)
WITH g, avg(r.rating) AS avgRating,
     count(r) AS totalRatings
RETURN g.name AS genre,
       round(avgRating, 2) AS averageRating,
       totalRatings
ORDER BY averageRating DESC;


// Запит 5. Рекомендація «користувачі зі схожими смаками також дивилися»: для заданого користувача знайти фільми, 
// які він ще не дивився, але високо оцінили користувачі з подібними смаками

MATCH (target:User {userId: 1})-[r1:RATED]->(common:Movie)
WHERE r1.rating >= 4

MATCH (similar:User)-[r2:RATED]->(common)
WHERE similar <> target
  AND r2.rating >= 4

MATCH (similar)-[r3:RATED]->(recommended:Movie)
WHERE r3.rating >= 4
  AND NOT EXISTS {
      MATCH (target)-[:RATED]->(recommended)
  }

WITH recommended,
     count(DISTINCT similar) AS similarUsers,
     avg(r3.rating) AS avgRating

RETURN recommended.title AS recommendation,
       similarUsers,
       round(avgRating, 2) AS averageRating
ORDER BY similarUsers DESC, averageRating DESC
LIMIT 10;


// Запит 6. Знайти найкоротший ланцюжок зв’язку між двома користувачами через спільні фільми

MATCH (u1:User {userId: 1}),
      (u2:User {userId: 2})

MATCH p = shortestPath(
    (u1)-[:RATED*..6]-(u2)
)

RETURN p,
       length(p) AS pathLength;
