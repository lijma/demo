
# hello world 
- docker-compose, ksql ui, control-center
docker exec -it ksqldb-cli ksql http://ksqldb-server:8088

CREATE STREAM AB (id VARCHAR, a DOUBLE, b DOUBLE) WITH (kafka_topic='ab', key='id', value_format='json', partitions=1);

```$xslt
INSERT INTO AB (id, a, b) VALUES ('c2309eec', 37.7877, -122.4205);
INSERT INTO AB (id, a, b) VALUES ('18f4ea86', 37.3903, -122.0643);
INSERT INTO AB (id, a, b) VALUES ('4ab5cbad', 37.3952, -122.0813);
```

# features

* Pull query support for directly querying the state store of an aggregate in ksqlDB
* Native integration with Kafka Connect connectors
* Support for nested structures
* Support for flattening an array into rows (EXPLODE)
* Better support for existing Apache Avro™️ schemas
* No more funky \ line continuation characters!
* Test runner

## db? ksql-ui?, crus/etl?, metadata(control center), transaction?
CREATE TABLE users (usertimestamp BIGINT, user_id VARCHAR, gender VARCHAR, region_id VARCHAR) WITH (KAFKA_TOPIC = 'my-users-topic', KEY = 'user_id', VALUE_FORMAT='json',PARTITIONS=2);
INSERT INTO users (usertimestamp, user_id, gender, region_id) VALUES (10000,'1', 'male', '85Z');

print 'my-users-topic' FROM BEGINNING;

## stream
CREATE STREAM score(userId VARCHAR, score1 DOUBLE, score2 DOUBLE) WITH (kafka_topic='score', key='userId', value_format='json', partitions = 1);

## push
https://docs.ksqldb.io/en/latest/concepts/queries/push/

SELECT * FROM score group by score1 EMIT CHANGES;
SELECT sum(score1) FROM score group by score1 EMIT CHANGES;
INSERT INTO score (userId, score1, score2) VALUES ('111', 90, 91);


## pull
SELECT * FROM users where ROWKEY=115; why error?
https://docs.ksqldb.io/en/latest/concepts/queries/pull/

https://docs.ksqldb.io/en/latest/concepts/materialized-views/

aggregation???/
CREATE stream book (id VARCHAR, score DOUBLE) WITH (kafka_topic='book', key='id', value_format='json', partitions=1);
create table book_score as select id, sum(score) as total_score from book group by id emit changes;

insert into book(id, score) values('1',9.0);
insert into book(id, score) values('2',9.0);
insert into book(id, score) values('1',9.0);
select * from book_score where ROWKEY='1';

## reference
https://www.confluent.io/blog/stream-processing-twitter-data-with-ksqldb/
https://docs.ksqldb.io/en/latest/developer-guide/aggregate-streaming-data/
https://www.confluent.io/blog/kafka-streams-vs-ksqldb-compared/
https://docs.ksqldb.io/en/latest/concepts/ksqldb-architecture/
https://docs.ksqldb.io/en/latest/concepts/ksqldb-architecture/
https://docs.ksqldb.io/en/latest/developer-guide/joins/partition-data/


