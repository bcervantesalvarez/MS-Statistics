#!/usr/bin/env python3
"""
Enhanced PySpark Script for Bar Crawl Heavy Drinking Data Analysis
Saving CSV outputs and plots to GCS.

DATASET ORIGINS:
    We obtained "time_aligned_barCrawl.csv" by:
      1) Merging "all_accelerometer_data_pids_13.csv" with phone_types.csv by pid.
      2) For each participant, reading their "clean_tac/*.csv" file (with columns timestamp, TAC_Reading).
      3) Converting both timestamps to comparable datetime formats.
      4) Using Pandas' merge_asof (nearest join) to time-align each accelerometer row to the closest TAC reading.
      5) Concatenating all participants into one final CSV, renamed "time_aligned_barCrawl.csv".

SCRIPT STEPS:
    1. Reads "time_aligned_barCrawl.csv" from GCS into Spark.
    2. Analysis 1: Phone type impact on accelerometer readings.
    3. Analysis 2: Temporal patterns (compute magnitude, group by 1-minute windows).
    4. Analysis 3: K-means clustering on a sample of accelerometer data (with a PCA figure).
    5. Analysis 4: Correlation between magnitude and TAC_Reading (with a scatter plot).
    6. Analysis 5: Scaled-Down Logistic Regression (using cross-validation with a limited grid and sample)
       to predict intoxication (TAC >= 0.08).
    7. Writes CSV results to GCS. Plots are saved locally, then uploaded to GCS.

AUTHOR: Your Name
DATE: 2025-03-17
"""

import os
import pyspark
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    avg, stddev, sqrt, col, from_unixtime, window, when, corr
)
from pyspark.ml.feature import VectorAssembler
from pyspark.ml.clustering import KMeans
from pyspark.ml.classification import LogisticRegression
from pyspark.ml.evaluation import BinaryClassificationEvaluator
from pyspark.ml.tuning import ParamGridBuilder, CrossValidator

import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns

# For uploading images to GCS
from google.cloud import storage

def upload_file_to_gcs(local_path, bucket_name, gcs_path):
    """
    Uploads a local file to a GCS path using the google-cloud-storage library.
    Example gcs_path: 'results/analysis1_phone_type/phone_boxplots.png'
    """
    client = storage.Client()
    bucket = client.bucket(bucket_name)
    blob = bucket.blob(gcs_path)
    blob.upload_from_filename(local_path)
    print(f"Uploaded {local_path} to gs://{bucket_name}/{gcs_path}")

def main():
    # ----------------------------------------------------------------------------
    # 1. Spark Session Initialization
    # ----------------------------------------------------------------------------
    spark = SparkSession.builder \
        .appName("barCrawlAnalysisToGCS") \
        .master("yarn") \
        .getOrCreate()

    # Bucket name (without 'gs://')
    bucket_name = "ds512_drinking_data"
    # Base path in that bucket where we will store results
    base_gcs_path = "results"

    # ----------------------------------------------------------------------------
    # 2. Read the time-aligned dataset (CSV) from GCS
    # ----------------------------------------------------------------------------
    dataset_path = "gs://ds512_drinking_data/time_aligned_barCrawl.csv"
    print(f"Reading dataset from {dataset_path}...")
    df = spark.read.format("csv") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .load(dataset_path)

    # Convert to appropriate types
    df = df.withColumn("time", col("time").cast("long")) \
           .withColumn("x", col("x").cast("float")) \
           .withColumn("y", col("y").cast("float")) \
           .withColumn("z", col("z").cast("float")) \
           .withColumn("TAC_Reading", col("TAC_Reading").cast("float")) \
           .withColumn("datetime", col("datetime").cast("timestamp"))

    # ----------------------------------------------------------------------------
    # 3. Analysis 1: Phone Type Impact
    # ----------------------------------------------------------------------------
    phone_stats = df.groupBy("phonetype").agg(
        avg("x").alias("avg_x"),
        stddev("x").alias("std_x"),
        avg("y").alias("avg_y"),
        stddev("y").alias("std_y"),
        avg("z").alias("avg_z"),
        stddev("z").alias("std_z")
    )
    # Write directly to GCS as a Spark DataFrame
    phone_stats.write.csv(
        f"gs://{bucket_name}/{base_gcs_path}/analysis1_phone_type/phone_stats",
        header=True,
        mode="overwrite"
    )
    print("Wrote phone_stats to GCS (analysis1_phone_type).")

    # ----------------------------------------------------------------------------
    # 4. Analysis 2: Temporal Patterns
    # ----------------------------------------------------------------------------
    df = df.withColumn("magnitude", sqrt(col("x")**2 + col("y")**2 + col("z")**2))

    time_window_stats = df.groupBy(window("datetime", "1 minute")).agg(
        avg("magnitude").alias("avg_magnitude")
    )

    # Flatten the struct column "window" -> separate columns
    time_window_stats_flat = time_window_stats \
        .withColumn("window_start", col("window.start")) \
        .withColumn("window_end", col("window.end")) \
        .drop("window")

    # Now you can safely write as CSV
    time_window_stats_flat.write.csv(
        f"gs://{bucket_name}/{base_gcs_path}/analysis2_temporal/time_window_stats",
        header=True,
        mode="overwrite"
    )
    print("Wrote time_window_stats to GCS (analysis2_temporal).")

    # ----------------------------------------------------------------------------
    # 5. Analysis 3: K-Means Clustering
    # ----------------------------------------------------------------------------
    df_sample = df.select("x", "y", "z", "magnitude").limit(20000)
    assembler = VectorAssembler(inputCols=["x", "y", "z", "magnitude"], outputCol="features")
    df_features = assembler.transform(df_sample).select("features")
    kmeans = KMeans(k=3, seed=1)
    model = kmeans.fit(df_features)
    predictions = model.transform(df_features)
    centers = model.clusterCenters()

    cluster_counts = predictions.groupBy("prediction").count()
    cluster_counts.write.csv(
        f"gs://{bucket_name}/{base_gcs_path}/analysis3_kmeans/cluster_counts",
        header=True,
        mode="overwrite"
    )
    print("Wrote cluster_counts to GCS (analysis3_kmeans).")

    # K-Means PCA figure (need local + upload)
    from pyspark.ml.feature import PCA as SparkPCA
    pca = SparkPCA(k=2, inputCol="features", outputCol="pcaFeatures").fit(df_features)
    df_pca = pca.transform(df_features)
    pred_df = model.transform(df_pca).select("pcaFeatures", "prediction")
    pdf_pred = pred_df.toPandas()
    pdf_pred["pc1"] = pdf_pred["pcaFeatures"].apply(lambda v: float(v[0]))
    pdf_pred["pc2"] = pdf_pred["pcaFeatures"].apply(lambda v: float(v[1]))
    plt.figure(figsize=(8, 6))
    sns.scatterplot(data=pdf_pred, x="pc1", y="pc2", hue="prediction", palette="Set1")
    plt.title("K-Means Clusters (PCA 2D)")
    local_kmeans_fig = "kmeans_pca.png"
    plt.savefig(local_kmeans_fig)
    print(f"Saved local figure {local_kmeans_fig}")
    # Upload figure to GCS
    upload_file_to_gcs(local_kmeans_fig, bucket_name, f"{base_gcs_path}/analysis3_kmeans/{local_kmeans_fig}")

    # ----------------------------------------------------------------------------
    # 6. Analysis 4: Correlation
    # ----------------------------------------------------------------------------
    corr_val = df.select(corr("magnitude", "TAC_Reading")).collect()[0][0]
    print(f"Correlation (magnitude vs. TAC_Reading): {corr_val}")
    # We'll store a single-row Spark DataFrame
    from pyspark.sql import Row
    corr_row = Row(feature1="magnitude", feature2="TAC_Reading", correlation=corr_val)
    corr_df_spark = spark.createDataFrame([corr_row])
    corr_df_spark.write.csv(
        f"gs://{bucket_name}/{base_gcs_path}/analysis4_correlation/magnitude_TAC_corr",
        header=True,
        mode="overwrite"
    )
    print("Wrote correlation result to GCS (analysis4_correlation).")

    # Correlation scatter plot
    corr_sample = df.select("magnitude", "TAC_Reading").limit(10000).toPandas()
    plt.figure(figsize=(6, 6))
    sns.scatterplot(data=corr_sample, x="magnitude", y="TAC_Reading", alpha=0.3)
    sns.regplot(data=corr_sample, x="magnitude", y="TAC_Reading", scatter=False, ci=None, color="red")
    plt.title("Magnitude vs. TAC_Reading")
    corr_fig = "magnitude_TAC_scatter.png"
    plt.savefig(corr_fig)
    upload_file_to_gcs(corr_fig, bucket_name, f"{base_gcs_path}/analysis4_correlation/{corr_fig}")

    # ----------------------------------------------------------------------------
    # 7. Analysis 5: Scaled-Down Logistic Regression
    # ----------------------------------------------------------------------------
    df = df.withColumn("label", when(col("TAC_Reading") >= 0.08, 1).otherwise(0))
    assembler_lr = VectorAssembler(inputCols=["x", "y", "z", "magnitude"], outputCol="features_lr")
    df_lr = assembler_lr.transform(df).select("features_lr", "label")
    df_lr_sample = df_lr.sample(withReplacement=False, fraction=0.01, seed=42)
    train_df, test_df = df_lr_sample.randomSplit([0.7, 0.3], seed=42)
    lr = LogisticRegression(featuresCol="features_lr", labelCol="label")

    paramGrid = (ParamGridBuilder()
                 .addGrid(lr.regParam, [0.01, 0.1])
                 .addGrid(lr.elasticNetParam, [0.0, 0.5])
                 .build())
    evaluator = BinaryClassificationEvaluator(labelCol="label", metricName="areaUnderROC")
    cv = CrossValidator(estimator=lr, estimatorParamMaps=paramGrid, evaluator=evaluator, numFolds=2)
    cvModel = cv.fit(train_df)
    bestModel = cvModel.bestModel
    predictions_lr = cvModel.transform(test_df)
    auc_val = evaluator.evaluate(predictions_lr)
    print(f"Logistic Regression AUC (scaled down): {auc_val}")

    # Save LR metrics to GCS
    from pyspark.sql import Row
    best_coeffs = bestModel.coefficients.toArray().tolist()
    intercept = bestModel.intercept
    paramMap = bestModel.extractParamMap()
    # Build a small Spark DataFrame to store them
    row_metrics = Row(
        AUC=auc_val,
        intercept=intercept,
        coeffs=str(best_coeffs),  # store as string
        paramMap=str(paramMap)
    )
    metrics_df = spark.createDataFrame([row_metrics])
    metrics_df.write.csv(
        f"gs://{bucket_name}/{base_gcs_path}/analysis5_logistic_regression/lr_metrics",
        header=True,
        mode="overwrite"
    )
    print("Wrote LR metrics to GCS (analysis5_logistic_regression).")

    # AUC curve plot
    from sklearn.metrics import roc_curve, auc as sk_auc
    pdf_lr = predictions_lr.select("label", "probability").limit(20000).toPandas()
    pdf_lr["prob_1"] = pdf_lr["probability"].apply(lambda v: float(v[1]))
    fpr, tpr, _ = roc_curve(pdf_lr["label"], pdf_lr["prob_1"])
    roc_auc = sk_auc(fpr, tpr)
    plt.figure(figsize=(6, 6))
    plt.plot(fpr, tpr, color="blue", label=f"ROC (area = {roc_auc:.2f})")
    plt.plot([0, 1], [0, 1], color="gray", linestyle="--")
    plt.title("Logistic Regression ROC Curve")
    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.legend(loc="lower right")
    local_auc_fig = "lr_roc_curve.png"
    plt.savefig(local_auc_fig)
    upload_file_to_gcs(local_auc_fig, bucket_name, f"{base_gcs_path}/analysis5_logistic_regression/{local_auc_fig}")

    # ----------------------------------------------------------------------------
    # 8. Box & Time Series Plots (Optional)
    # ----------------------------------------------------------------------------
    # We'll sample for phone type box plot
    pdf_plot = df.limit(20000).toPandas()
    plt.figure(figsize=(15, 4))
    plt.subplot(1, 3, 1)
    sns.boxplot(x="phonetype", y="x", data=pdf_plot)
    plt.title("Distribution of x by Phone Type")
    plt.subplot(1, 3, 2)
    sns.boxplot(x="phonetype", y="y", data=pdf_plot)
    plt.title("Distribution of y by Phone Type")
    plt.subplot(1, 3, 3)
    sns.boxplot(x="phonetype", y="z", data=pdf_plot)
    plt.title("Distribution of z by Phone Type")
    plt.tight_layout()
    local_boxplot = "phone_boxplots.png"
    plt.savefig(local_boxplot)
    upload_file_to_gcs(local_boxplot, bucket_name, f"{base_gcs_path}/analysis1_phone_type/{local_boxplot}")

    # Time series
    time_pdf = time_window_stats.limit(5000).toPandas()  # limit to avoid huge data
    time_pdf["window_start"] = time_pdf["window"].apply(lambda w: w["start"])
    plt.figure(figsize=(10, 6))
    sns.lineplot(x="window_start", y="avg_magnitude", data=time_pdf)
    plt.title("Average Acceleration Magnitude Over Time")
    plt.xlabel("Time")
    plt.ylabel("Avg. Magnitude")
    plt.xticks(rotation=45)
    plt.tight_layout()
    local_timeseries = "avg_magnitude_timeseries.png"
    plt.savefig(local_timeseries)
    upload_file_to_gcs(local_timeseries, bucket_name, f"{base_gcs_path}/analysis2_temporal/{local_timeseries}")

    # ----------------------------------------------------------------------------
    # 9. Stop Spark
    # ----------------------------------------------------------------------------
    spark.stop()

if __name__ == "__main__":
    main()
