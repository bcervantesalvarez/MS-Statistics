# OSU CS512 Environment Config Assignment
# Verify you are properly set up with GCP and Python
import os
import sys
from google.cloud import bigquery
import matplotlib.pyplot as plt

# set the dataset
dataset_id = "bigquery-public-data"

#check python version
if sys.version_info[0] < 3:
	raise EnvironmentError("Not runing Python 3")
else:
	print("Running Python " + str(sys.version_info[0]))

#check GCP connection
try:
	# Create a client objectwhich python

    client = bigquery.Client()
except EnvironmentError:
	print("You are not logged or have the wrong project selected use the command `gcloud auth login` to login to an account or `gcloud config set project PROJECT_ID` to set the project ID.")
	quit()

print("Connected to the bigquery client.")

# Construct a reference to the dataset
dataset_ref = client.dataset(dataset_id)

# Create a query
# The data comes from from the CDC and covers U.S. birth records from 1969 to 2008
query = """
    SELECT state, COUNT(*) as num_births
    FROM `bigquery-public-data.samples.natality`
    GROUP BY state
    ORDER BY num_births DESC
"""

# Execute the query and get the results
query_job = client.query(query)
results = query_job.result()

# Extract the data from the results object
states = []
num_births = []
for row in results:
    # Check if any of the lists contain None values
    if None == row["state"] or None == row["num_births"]:
        print("Found empty value, skipping it")
    else:
        states.append(row["state"])
        num_births.append(row["num_births"])


# Create a bar chart
print("Generating bar chart")
plt.bar(states, num_births)
plt.xlabel("State")
plt.ylabel("Number of Births")
plt.title("Number of Births by State")
# Set the x-axis tick labels with vertical orientation
plt.xticks(rotation=90, fontsize=8)

# Show the plot
plt.show()
