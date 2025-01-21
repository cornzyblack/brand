# Data Model

<img src="../docs/data_model.png">

You can see the documentation of the data model by running the following

```shell
source .env
cd data-models
dbt seed
dbt run
```

After which you generate the Model documentation by doing the following (still from within the `data-models` directory):

```shell
dbt docs generate
```

You can now view the documentation locally by running this:

```shell
dbt docs serve
```

You should now be able to access the Documentation for the models at [http://localhost:8080](http://localhost:8080)
