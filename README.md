# InkSight_BookAnalytics
InkSight Book Analytics is a comprehensive SQL-based project for managing, analyzing, and gaining insights from book ratings data. Designed for seamless data handling, automated updates, and real-time analytics, InkSight brings your book data to life, enabling you to dive deep into user preferences, top-rated books, and author popularity.

## Project Overview
InkSight Book Analytics organizes and explores book, user, and rating data. The project creates a robust analytical data layer, complete with automated ETL processes, summary views, and materialized views for efficient querying. By integrating advanced data quality checks, real-time summaries, and powerful visual data marts, this project transforms raw data into valuable insights.

## Key Features
+ **Data Validation:** Ensures clean and accurate data by filtering out non-numeric or missing values in ratings and user ages.
+ **Analytical Data Layer:** Combines Users, Books, and Ratings data into a denormalized table (Denormalized_Ratings) for streamlined analysis.
+ **Automated ETL Process:** Stored procedures and triggers update summary tables in real-time whenever new ratings are added.
+ **Data Marts & Materialized Views:** Optimized views and materialized tables for quick access to insights on top-rated books, active users, and popular authors.
+ **Performance Optimization:** Indexes and materialized views improve query speed and efficiency, especially when working with large datasets.

## Project Setup
1. Clone the repository:
```bash
   git clone https://github.com/GuillermoLeal95/InkSight_BookAnalytics
```
2. Open the SQL Script in MySQL Workbench
+ Load InkSight_Book_Analytics.sql into MySQL Workbench.
+ Download files already uploaded in github (Book, Ratings, Users)

3. Run the Script

## Database Structure
### Core Tables
+ Users: Contains users informatio (ID, location, age)
+ Books: Book details (ISBN, title, author, etc)
+ Ratings: Stores user ratings for each book

### Analytical Tables and Views
**Tables:**
+ Denormalized_Ratings: Merges user, book, and rating data for easier analysis.
+ Book_Ratings_Summary: Provides average ratings and total ratings for each book.
+ User_Ratings_Summary: Summarizes each user's average rating, total ratings given, and rating range.
+ Author_Ratings_Summary: Shows average rating and total ratings per author.

**Views:**
+ Top_Rated_Books, Active_Users, Top_Authors provide quick insights into popular books, active users, and highly rated authors.

### Performance Enhancements
+ Materialized View: (`Materialized_Top_Rated_Books`): Stores top-rated books for fast access.
+ Automated Refresh: A scheduled event updates `Materialized_Top_Rated_Books` daily to keep data current.

## How it works
1. **ETL Process:**
+ The `Update_Book_Ratings_Summary` stored procedure calculates and updates ratings summaries for each book.
+ The `After_Rating_Insert` trigger runs the stored procedure automatically when a new rating is added, keeping the summaries up-to-date.

2. **Data Marts and Materialized Views:**
+ Views like `Top_Rated_Books` and `Top_Authors` are optimized for frequently queried data, such as top-rated books or most active users.
+ The `Materialized_Top_Rated_Books` table stores a snapshot of the top-rated books, with a daily event refreshing the data for consistent performance.

3. **Data Validation:**
+ Validation steps handle non-numeric and missing values in `Age` and `Book_Rating`, ensuring that only high-quality data is stored and analyzed.

## Usage Instructions
+ **Run the ETL Process**
   + Call the store procedure manually if needed:
```bass
CALL Update_Book_Ratings_Summary();
```
+ **Explore the Data Marts**
  + View the `Top_Rated_Books` or `Active_Users` views for insights.
  + Example:
```bass
SELECT * FROM Top_Rated_Books;
```
+ **Inspect the Materialized View:**
  + Query `Materialized_Top_Rated_Books` for efficient access to popular books.
