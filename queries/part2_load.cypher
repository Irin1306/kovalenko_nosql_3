// Indexes

CREATE CONSTRAINT user_id IF NOT EXISTS
FOR (u:User)
REQUIRE u.userId IS UNIQUE;

CREATE CONSTRAINT movie_id IF NOT EXISTS
FOR (m:Movie)
REQUIRE m.movieId IS UNIQUE;

CREATE CONSTRAINT genre_name IF NOT EXISTS
FOR (g:Genre)
REQUIRE g.name IS UNIQUE;


// Users

LOAD CSV WITH HEADERS FROM 'file:///users.csv' AS row
MERGE (u:User {userId: toInteger(row.userId)})
SET u.gender = row.gender,
    u.age = toInteger(row.age),
    u.occupation = toInteger(row.occupation);


// Movies and genres

LOAD CSV WITH HEADERS FROM 'file:///movies.csv' AS row
MERGE (m:Movie {movieId: toInteger(row.movieId)})
SET m.title = row.title,
    m.year = toInteger(
        substring(row.title, size(row.title) - 5, 4)
    )
WITH m, row
UNWIND split(row.genres, '|') AS genreName
MERGE (g:Genre {name: genreName})
MERGE (m)-[:HAS_GENRE]->(g);


// Ratings

CALL apoc.periodic.iterate(
    "LOAD CSV WITH HEADERS FROM 'file:///ratings.csv' AS row
     RETURN row",

    "MATCH (u:User {userId: toInteger(row.userId)})
     MATCH (m:Movie {movieId: toInteger(row.movieId)})
     MERGE (u)-[r:RATED]->(m)
     SET r.rating = toInteger(row.rating),
         r.timestamp = toInteger(row.timestamp)",

    {
        batchSize: 10000,
        parallel: false,
        retries: 3
    }
);
