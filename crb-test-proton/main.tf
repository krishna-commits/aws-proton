/*
This file is managed by AWS Proton. Any changes made directly to this file will be overwritten the next time AWS Proton performs an update.

To manage this resource, see AWS Proton Resource: arn:aws:proton:us-east-1:031342435657:environment/crb-test-proton

If the resource is no longer accessible within AWS Proton, it may have been deleted and may require manual cleanup.
*/

resource "aws_glue_workflow" "glue_workflow" {
  description = "Glue workflow that tracks specified triggers, jobs, and crawlers as a single entity"
}


resource "aws_glue_trigger" "parquettransformation" {
  name = join("_", [var.trigger_one, var.env_type])
  type = "SCHEDULED"
  schedule = "cron(45 11 ? * MON-FRI *)"
  start_on_creation = "true"
  workflow_name = join("_", [var.glue_workflow_name, var.env_type])
  actions {
    job_name = aws_glue_job.cfnr_glue_etl1.arn
  }

}


resource "aws_glue_trigger" "deltaviews" {
  name = join("_", [var.trigger_two, var.env_type])
  type = "CONDITIONAL"
  start_on_creation = "true"
  workflow_name = join("_", [var.glue_workflow_name, var.env_type])
  actions {
    job_name = aws_glue_job.cfnr_glue_etl2.arn
  }
  actions {
    job_name = aws_glue_job.cfnr_glue_etl3.arn
  }
  actions {
    job_name = aws_glue_job.cfnr_glue_etl4.arn
  }

  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name = aws_glue_job.cfnr_glue_etl1.arn
      state    = "SUCCEEDED"
    }
  }
}


resource "aws_glue_trigger" "deltaanalysis" {
  name = join("_", [var.trigger_three, var.env_type])
  type = "CONDITIONAL"
  start_on_creation = "true"
  workflow_name = join("_", [var.glue_workflow_name, var.env_type])
  actions {
    job_name = aws_glue_job.cfnr_glue_etl5.arn
  }

  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name = aws_glue_job.cfnr_glue_etl4.arn
      state    = "SUCCEEDED"
    }

  }
}


resource "aws_glue_trigger" "mplloansales" {
  name = join("_", [var.trigger_four, var.env_type])
  type = "CONDITIONAL"
  start_on_creation = "true"
  workflow_name = join("_", [var.glue_workflow_name, var.env_type])
  actions {
    job_name = aws_glue_job.cfnr_glue_etl6.arn
  }
  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name = aws_glue_job.cfnr_glue_etl5.arn
      state    = "SUCCEEDED"
    }
  }
}


resource "aws_glue_trigger" "mplmontlyserv" {
  name = join("_", [var.trigger_five, var.env_type])
  type = "CONDITIONAL"
  start_on_creation = "true"
  workflow_name = join("_", [var.glue_workflow_name, var.env_type])
  actions {
    job_name = aws_glue_job.cfnr_glue_etl7.arn
  }

  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name = aws_glue_job.cfnr_glue_etl6.arn
      state    = "SUCCEEDED"
    }

  }
}


resource "aws_glue_trigger" "mplredshiftandview" {
  name = join("_", [var.trigger_six, var.env_type])
  type = "CONDITIONAL"
  start_on_creation = "true"
  workflow_name = join("_", [var.glue_workflow_name, var.env_type])
  actions {
    job_name = aws_glue_job.cfnr_glue_etl8.arn
  }
  actions {
    job_name = aws_glue_job.cfnr_glue_etl9.arn
  }
  actions {
    job_name = aws_glue_job.cfnr_glue_etl10.arn
  }

  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name = aws_glue_job.cfnr_glue_etl7.arn
      state    = "SUCCEEDED"
    }

  }
}


resource "aws_glue_trigger" "mplperfredshift" {
  name = join("_", [var.trigger_seven, var.env_type])
  type = "CONDITIONAL"
  start_on_creation = "true"
  workflow_name = join("_", [var.glue_workflow_name, var.env_type])
  actions {
    job_name = aws_glue_job.cfnr_glue_etl11.arn
  }

  predicate {
    conditions {
      logical_operator = "EQUALS"
      job_name = aws_glue_job.cfnr_glue_etl9.arn
      state    = "SUCCEEDED"
    }
  }
}


resource "aws_glue_connection" "cfn_connection_redshift" {
  catalog_id = data.aws_caller_identity.current.account_id
  physical_connection_requirements {
    availability_zone = "us-east-1a"
    security_group_id_list = ["var.redshift_sg"]
    subnet_id = var.redshift_subnet
    }
    connection_properties = {
      JDBC_CONNECTION_URL = var.cfnjdbc_string
      USERname = var.cfnjdbc_user
      PASSWORD = var.cfnjdbc_password
    }
    name = var.cfn_connection_name
}


resource "aws_glue_job" "cfnr_glue_etl1" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_delta_parquet_transformation.py"
  }

  max_capacity = "30"
  execution_property {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name1, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl2" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_delta_analysis_hfitohfs.py"
  }
  max_capacity = "15"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name2, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl3" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_delta_analysis_originations.py"
  }
  max_capacity = "15"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name3, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl4" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_delta_analysis_servicing.py"
  }
  max_capacity = "15"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name4, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl5" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_delta_analysis_mpl_monthly_serv_intermediate.py"
  }
  max_capacity = "30"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name5, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl6" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_delta_analysis_mpl_loan_sales.py"
  }
  max_capacity = "10"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name6, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl7" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_delta_analysis_mpl_monthly_serv.py"
  }
  max_capacity = "30"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name7, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl8" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  connections = [ "var.cfn_connection_name" ]
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_load_to_redshift_mpl_monthly_serv.py"
  }
  max_capacity = "30"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name8, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl9" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_delta_analysis_mpl_monthly_perf.py"
  }
  max_capacity = "30"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name9, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl10" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  connections = [ "var.cfn_connection_name" ]
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_load_to_redshift_mpl_monthly_serv_platformwise.py"
  }
  max_capacity = "30"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name10, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}


resource "aws_glue_job" "cfnr_glue_etl11" {
  role_arn = "arn:aws:iam::${var.aws_account_id}:role/glue-endpoint-to-s3-role"
  connections = [ "var.cfn_connection_name" ]
  command {
    name = "glueetl"
    script_location = "s3://${var.s3_script_location}/admin/${var.env_type}/caspian_mpl_load_to_redshift_mpl_monthly_perf.py"
  }
  max_capacity = "30"
  execution_property  {
    max_concurrent_runs = "1"
  }
  name = join("_", [var.job_name11, var.env_type])
  default_arguments = {
    "--conf" = "spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore --conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.driver.maxResultSize=2g"
    "--env" = "dev"
    "--TempDir" = "s3://${var.s3_temp_dir}/admin"
    "--job-bookmark-option" = "job-bookmark-disable"
    "--enable-metrics" = ""
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter" = "true"
    "--enable-spark-ui" = "true"
    "--spark-event-logs-path" = "s3://${var.s3_glue_logs}"
    "--extra-py-files" = "s3://${var.s3_glue_libraries}/pylib/delta-1.0-py2.py3-none-any.whl"
    "--extra-jars" = "s3://${var.s3_glue_libraries}/jar/delta-core_2.11-0.6.1.jar,s3://${var.s3_glue_libraries}/jar/redshift-jdbc42-2.0.0.4.jar,s3://${var.s3_glue_libraries}/jar/spark-redshift_2.11-2.0.1.jar,s3://${var.s3_glue_libraries}/jar/spark-avro_2.11-2.4.0.jar"
  }
  glue_version = "2.0"
}
