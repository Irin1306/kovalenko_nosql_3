// Запит 1. Знайти користувачів із найбільшою кількістю оцінок

MATCH (u:User)-[r:RATED]->()
RETURN u.userId AS userId,
       count(r) AS connections
ORDER BY connections DESC
LIMIT 10;


// Запит 2. Знайти фільми з найбільшою кількістю оцінок

MATCH (m:Movie)<-[r:RATED]-()
RETURN m.title AS movie,
       count(r) AS connections
ORDER BY connections DESC
LIMIT 10;


// Запит 3. Знайти жанри з найбільшою кількістю зв'язків

MATCH (g:Genre)<-[:HAS_GENRE]-(m:Movie)
RETURN g.name AS genre,
       count(m) AS connections
ORDER BY connections DESC;


// Запит 4. Загальна статистика зв'язків

MATCH (n)
OPTIONAL MATCH (n)-[r]-()
RETURN labels(n) AS nodeType,
       count(DISTINCT n) AS nodes,
       count(r) AS relationships
ORDER BY relationships DESC;