
<details>
<summary>Command output</summary>

```sh

kafka-topics \
    --bootstrap-server localhost:6969 \
    --command-config teamA-sa.properties \
    --list
CURRENTLOCATION
RIDERSNEARMOUNTAINVIEW
_confluent-ksql-default__command_topic
_confluent-ksql-default_query_CTAS_CURRENTLOCATION_3-Aggregate-Aggregate-Materialize-changelog
_confluent-ksql-default_query_CTAS_CURRENTLOCATION_3-Aggregate-GroupBy-repartition
_confluent-ksql-default_query_CTAS_RIDERSNEARMOUNTAINVIEW_5-Aggregate-Aggregate-Materialize-changelog
_confluent-ksql-default_query_CTAS_RIDERSNEARMOUNTAINVIEW_5-Aggregate-GroupBy-repartition
_confluent-ksql-default_query_CTAS_RIDERSNEARMOUNTAINVIEW_5-KsqlTopic-Reduce-changelog
default_ksql_processing_log
locations

```

</details>
      
