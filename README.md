# attrition-model
ELT pipeline that extracts data from local sources, loads it into PostgreSQL database, then performs feature engineering transformation to create a feature mart for an attrition or employee turnover machine learning model.

# What is an attrition model or employee turn over model?
A model used to predict whether specific employees are likely to leave the company based on certain features. It analyzes historical workforce data, such as tenure, performance ratings, salaries, overtime hours and the like to identify patterns that signal potential turnover. The outputs are possible probability scores, risk categories (Low, Medium Risk), and feature importance.

# What to do with the python notebook?
For the jupyter notebook, it contains script to load the csv files as dataframes, and then load the dfs into the SQL database using SQLAlchemy library. To run:
1.) Download the notebook into local files.
2.) Run all cells of the notebook.

# After that, run the SQL file to perform the necessary feature engineering.
The SQL file contains necessary calculations of the following features: Tenure, Last Performance Rating, Number of Overtime Hours, Years Since Last Promotion, and Salary Compared to Peers, which are all features that guide the model in deciding whether an employee is likely to leave. Note that these aren't complete features and more features are needed for a more accurate model. To run:
1.) Download the SQL file and open in a relational database.
2.) Run all the code in the SQL file.
3.) Check and validate the final feature mart table. 

# Next Steps
This project is a starting point for building an attrition prediction pipeline. Future improvements may include:
- Adding more features (e.g., employee engagement scores, training history).
- Experimenting with different machine learning models.
- Automating the pipeline with Airflow or Prefect.
