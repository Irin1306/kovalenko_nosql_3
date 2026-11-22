// 1. PageRank на графі фільмів

// Крок 1: матеріалізуємо ребра фільм-фільм через спільних користувачів
MATCH (m1:Movie)<-[r1:RATED]-(u:User)-[r2:RATED]->(m2:Movie)
WHERE r1.rating >= 4 
  AND r2.rating >= 4 
  AND id(m1) < id(m2)
WITH m1, m2, count(u) AS weight
WHERE size([(m1)<-[:RATED]-() | 1]) > 20
  AND size([(m2)<-[:RATED]-() | 1]) > 20
WITH m1, m2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (m1)-[co:CO_RATED]-(m2)
SET co.weight = weight;

// Крок 2: створюємо проєкцію на основі матеріалізованих ребер
CALL gds.graph.project(
  'movieGraph',
  'Movie',
  { CO_RATED: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount;

// Крок 3: запускаємо PageRank
CALL gds.pageRank.stream('movieGraph', {
    relationshipWeightProperty: 'weight',
    maxIterations: 20,
    dampingFactor: 0.85
})
YIELD nodeId, score

RETURN
    gds.util.asNode(nodeId).movieId AS movieId,
    gds.util.asNode(nodeId).title AS movie,
    round(score, 4) AS pageRank

ORDER BY pageRank DESC
LIMIT 10;  

// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('movieGraph');
MATCH ()-[co:CO_RATED]-() 
DELETE co;


// 2. Виявлення спільнот (Louvain)

// Крок 1: матеріалізуємо ребра користувач-користувач через спільні фільми
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5 
  AND r2.rating = 5
  AND id(u1) < id(u2)
WITH u1, u2, count(m) AS weight
WITH u1, u2, weight
ORDER BY weight DESC
LIMIT 50000
MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight;

// Крок 2: створюємо проєкцію
CALL gds.graph.project(
  'userSimilarity',
  'User',
  { SIMILAR: { orientation: 'UNDIRECTED', properties: 'weight' } }
)
YIELD graphName, nodeCount, relationshipCount; 

// Крок 3.1: запускаємо Louvain
CALL gds.louvain.stream('userSimilarity', {
    relationshipWeightProperty: 'weight'
})
YIELD nodeId, communityId

RETURN
    communityId,
    count(*) AS users

ORDER BY users DESC
LIMIT 10;

// Крок 3.2: записуємо результати Louvain
CALL gds.louvain.write('userSimilarity', {
    relationshipWeightProperty: 'weight',
    writeProperty: 'communityId'
})
YIELD communityCount, modularity, modularities

RETURN communityCount, modularity, modularities;

// Крок 4: три найпопулярніші жанри кожної спільноти
MATCH (u:User)-[r:RATED]->(m:Movie)-[:HAS_GENRE]->(g:Genre)
WHERE r.rating = 5
  AND u.communityId IS NOT NULL

WITH u.communityId AS community,
     g.name AS genre,
     count(*) AS popularity

ORDER BY community, popularity DESC

WITH community,
     collect({
         genre: genre,
         popularity: popularity
     })[0..3] AS topGenres

RETURN community, topGenres
ORDER BY community;

// Крок 5: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('userSimilarity');
MATCH ()-[sim:SIMILAR]-() 
DELETE sim;


// 3. Найкоротший шлях між користувачами   

// Крок 1: матеріалізуємо ребра користувач-користувач через спільні фільми
MATCH (u1:User)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User)
WHERE r1.rating = 5
  AND r2.rating = 5
  AND u1.userId < u2.userId

WITH u1, u2, count(m) AS weight
ORDER BY weight DESC
LIMIT 50000

MERGE (u1)-[sim:SIMILAR]-(u2)
SET sim.weight = weight,
    sim.distance = 1.0 / weight;

// Крок 2: створюємо проєкцію
CALL gds.graph.drop('userGraph', false);

CALL gds.graph.project(
    'userGraph',
    'User',
    {
        SIMILAR: {
            orientation: 'UNDIRECTED',
            properties: ['weight', 'distance']
        }
    }
)
YIELD graphName, nodeCount, relationshipCount

RETURN graphName, nodeCount, relationshipCount;  

// Крок 3: алгоритм Дейкстри 

UNWIND [
    [1, 2],
    [1, 100],
    [1, 500],
    [100, 1000],
    [500, 2000],
    [4277, 4169],
    [1680, 3032]
] AS pair

MATCH (source:User {userId: pair[0]})
MATCH (target:User {userId: pair[1]})

CALL gds.shortestPath.dijkstra.stream('userGraph', {
    sourceNode: id(source),
    targetNode: id(target),
    relationshipWeightProperty: 'distance'
})

YIELD totalCost, nodeIds

RETURN
    pair[0] AS user1,
    pair[1] AS user2,
    [nodeId IN nodeIds |
        gds.util.asNode(nodeId).userId
    ] AS userPath,
    round(totalCost, 4) AS totalCost,
    size(nodeIds) - 1 AS pathLength

ORDER BY pathLength ASC; 

// Крок 4: видаляємо проєкцію та тимчасові ребра
CALL gds.graph.drop('userGraph');
MATCH ()-[sim:SIMILAR]-()
DELETE sim;















