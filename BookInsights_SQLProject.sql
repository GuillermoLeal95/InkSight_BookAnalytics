
# Create a new database for storing book recommendation data
CREATE DATABASE BookRecomendations;
# Set the active database to BookRecomendations for upcoming operations
USE BookRecomendations;

# Create the Users table to store details about each user
CREATE TABLE Users (
	User_ID INT PRIMARY KEY,  # User_ID is the primary key to uniquely identify each user
    Location VARCHAR(255) NULL, # Location field, can be NULL if unknown
    Age VARCHAR(255) NULL # Age field stored as VARCHAR to handle non-numeric entries initially
);

# Load user data from the Users.csv file into the Users table
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\Users.csv'
INTO TABLE Users
FIELDS TERMINATED BY ','  # Fields are separated by commas in the CSV file
ENCLOSED BY '"' # Fields are enclosed by double quotes in the CSV file
LINES TERMINATED BY '\n' # Each line in the CSV file represents a new record
IGNORE 1 LINES # Ignore the header row in the CSV file
(User_ID, Location, Age);

# Verify that user data has been loaded correctly
SELECT * FROM users ORDER BY User_ID DESC LIMIT 5;
SELECT COUNT(*)  FROM users;

# The user data seems correct. Proceeding to load Books and Ratings datasets.

# Create the Books table to store book information
CREATE TABLE Books (
	ISBN VARCHAR(20) PRIMARY KEY, #ISBN is the International Standard Book Number, for books that are published internationally. A book can have different ISBN (Translations, Editions, Format Variations)
    Book_Title VARCHAR(255) NULL,
    Book_Author VARCHAR(255) NULL,
    Year_Of_Publication VARCHAR(255) NULL, # Year the book was published, stored as VARCHAR for flexibility
    Publisher VARCHAR(255) NULL,
    Image_URL_S VARCHAR(255) NULL,
	Image_URL_M VARCHAR(255) NULL,
    Image_URL_L VARCHAR(255) NULL
);

# Load book data from the Books.csv file into the Books table
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\Books.csv'
INTO TABLE Books
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(ISBN, Book_Title, Book_Author , Year_Of_Publication ,Publisher,Image_URL_S,Image_URL_M,Image_URL_L );

# Confirm successful data import for books by checking distinct records
SELECT * FROM Books;
SELECT COUNT(DISTINCT ISBN), COUNT(DISTINCT Book_Title), COUNT(DISTINCT Book_Author), COUNT(DISTINCT  Year_Of_Publication), 
COUNT(DISTINCT Publisher) FROM Books;

# Create the Ratings table to store user ratings for books
CREATE TABLE Ratings (
	User_ID INT,
    ISBN VARCHAR(20),
    Book_Rating VARCHAR(20)
);

# Increase server timeout settings for large data import due to the size of the ratings dataset

SET GLOBAL net_read_timeout = 600;
SET GLOBAL net_write_timeout = 600;
SET GLOBAL wait_timeout = 600;
SET GLOBAL interactive_timeout = 600;

# Load rating data from the Ratings.csv file into the Ratings table
LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.4\\Uploads\\Ratings.csv'
INTO TABLE Ratings
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(User_ID, ISBN, Book_Rating );

# Verify that ratings data has been loaded correctly
SELECT * FROM Ratings ORDER BY ISBN DESC LIMIT 5;
SELECT COUNT(*) FROM Ratings;

# Validate the structure of all tables to ensure proper creation
SHOW Tables; # Show all tables in the BookRecomendations database
DESCRIBE Books; # Show the structure of the Books table
DESCRIBE ratings; # Show the structure of the Ratings table
DESCRIBE users; # Show the structure of the Users table


# Clean up Ratings table - Replace '0' ratings with NULL to avoid skewing average ratings
UPDATE Ratings
SET Book_Rating = NULL
WHERE Book_Rating = 0;

# Update any non-numeric ratings to NULL
UPDATE Ratings
SET Book_Rating = NULL
WHERE Book_Rating NOT REGEXP '^[0-9]+$';

# Convert Book_Rating from VARCHAR to INT for better numerical analysis
ALTER TABLE Ratings
MODIFY Book_Rating INT;

# Remove rows from Ratings with NULL User_ID or ISBN, as they are incomplete records
DELETE FROM Ratings
WHERE User_ID IS NULL OR ISBN IS NULL OR Book_Rating IS NULL;

# Convert Age in the Users table from VARCHAR to INT
# First, set non-numeric Age entries to NULL for compatibility
UPDATE Users
SET Age = NULL
WHERE Age NOT REGEXP '^[0-9]+$';  # REGEXP checks if Age contains only digits

# Alter the Age column to INT now that it only contains numeric values
ALTER TABLE Users
MODIFY Age INT;

# Convert Year_Of_Publication in the Books table from VARCHAR to INT
# Update non-numeric Year_Of_Publication values to NULL to ensure compatibility for the conversion
UPDATE Books
SET Year_Of_Publication = NULL
WHERE Year_Of_Publication NOT REGEXP '^[0-9]+$';  # REGEXP checks if the value contains only digits

# Alter the Year_Of_Publication column to INT now that it only contains numeric values
ALTER TABLE Books
MODIFY Year_Of_Publication INT;


# Verify changes in the structure of all tables to confirm successful modifications
DESCRIBE Users;  # Check that Age is now an INT
DESCRIBE Books;  # Check that Year_Of_Publication is now an INT
DESCRIBE Ratings;  # Check that Book_Rating is now an INT

#Create Analytical Data Layer with summary table 
#Create Summary table for efficiente further analysis 
#Before the creation of the summary table we are going to create a denormalized_rating table so the analysis will be more clean and easier to understand
CREATE TABLE Denormalized_Ratings AS
SELECT 
    Ratings.User_ID,
    Users.Location,
    Users.Age,
    Ratings.ISBN,
    Books.Book_Title,
    Books.Book_Author,
    Books.Year_Of_Publication,
    Books.Publisher,
    Ratings.Book_Rating
FROM Ratings
JOIN Users ON Ratings.User_ID = Users.User_ID
JOIN Books ON Ratings.ISBN = Books.ISBN;

SELECT * FROM Denormalized_Ratings;

# Create a summary table for books, calculating average ratings and total ratings count for each book
CREATE TABLE Book_Ratings_Summary AS
SELECT 
    Denormalized_Ratings.ISBN,
    Denormalized_Ratings.Book_Title,
    Denormalized_Ratings.Book_Author,
    Denormalized_Ratings.Year_Of_Publication,
    Denormalized_Ratings.Publisher,
    AVG(Denormalized_Ratings.Book_Rating) AS Average_Rating,  # Calculate the average rating for each book
    COUNT(Denormalized_Ratings.Book_Rating) AS Total_Ratings  # Count the total number of ratings for each book
FROM Denormalized_Ratings
GROUP BY 
    Denormalized_Ratings.ISBN, 
    Denormalized_Ratings.Book_Title, 
    Denormalized_Ratings.Book_Author, 
    Denormalized_Ratings.Year_Of_Publication, 
    Denormalized_Ratings.Publisher;

SELECT * FROM Book_Ratings_Summary ORDER BY Total_Ratings DESC;

# Create a summary table for books, calculating average ratings and total ratings count for each book
CREATE TABLE User_Ratings_Summary AS
SELECT 
    Denormalized_Ratings.User_ID,
    Denormalized_Ratings.Location,
    Denormalized_Ratings.Age,
    AVG(Denormalized_Ratings.Book_Rating) AS Average_User_Rating,  # Calculate the average rating given by the user
    COUNT(Denormalized_Ratings.Book_Rating) AS Total_Ratings_Given,  # Count the total number of ratings given by the user
    MIN(Denormalized_Ratings.Book_Rating) AS Lowest_Rating_Given,  # Find the lowest rating the user has given
    MAX(Denormalized_Ratings.Book_Rating) AS Highest_Rating_Given  # Find the highest rating the user has given
FROM Denormalized_Ratings
GROUP BY 
    Denormalized_Ratings.User_ID, 
    Denormalized_Ratings.Location, 
    Denormalized_Ratings.Age;
    
SELECT * FROM User_Ratings_Summary ORDER BY Total_Ratings_Given DESC;


# Create a table summarizing the total number of editions/formats published by each author (ISBN)
CREATE TABLE Author_ISBN_Count AS
SELECT 
    Books.Book_Author,
    COUNT(Books.ISBN) AS Total_Books_Published  # Count the total number of books for each author
FROM Books
GROUP BY 
    Books.Book_Author;

SELECT * FROM Author_ISBN_Count ORDER BY Total_Books_Published DESC;

# Create a summary table for authors, calculating average and total ratings for their books
CREATE TABLE Author_Ratings_Summary AS
SELECT 
    Denormalized_Ratings.Book_Author,
    AVG(Denormalized_Ratings.Book_Rating) AS Average_Rating_By_Author,  # Calculate the average rating across all books by the author
    COUNT(Denormalized_Ratings.Book_Rating) AS Total_Ratings_For_Author  # Count the total number of ratings for all books by the author
FROM Denormalized_Ratings
GROUP BY 
    Denormalized_Ratings.Book_Author;
    
SELECT * FROM Author_Ratings_Summary ORDER BY Total_Ratings_For_Author DESC;

# Verify the creation of the analytical tables
SHOW TABLES;
DESCRIBE Book_Ratings_Summary;
DESCRIBE User_Ratings_Summary;
DESCRIBE Author_ISBN_Count;
DESCRIBE Author_Ratings_Summary;

#Create Stored Procedures and triggers for ETL Process
# Define a stored procedure to automate updates to the Book_Ratings_Summary table


DELIMITER //
CREATE PROCEDURE Update_Book_Ratings_Summary()
BEGIN
	# Extract and Transform: Calculate average ratings and count for each book
    INSERT INTO Book_Ratings_Summary (ISBN, Book_Title, Book_Author, Year_Of_Publication, Publisher, Average_Rating, Total_Ratings)
    SELECT
		Denormalized_Ratings.ISBN,
        Denormalized_Ratings.Book_Title,
        Denormalized_Ratings.Book_Author,
        Denormalized_Ratings.Year_Of_Publication,
        Denormalized_Ratings.Publisher,
        AVG(Denormalized_Ratings.Book_Rating),
        COUNT(Denormalized_Ratings.Book_Rating)
	FROM Denormalized_Ratings
	GROUP BY
		Denormalized_Ratings.ISBN, 
        Denormalized_Ratings.Book_Title, 
        Denormalized_Ratings.Book_Author, 
        Denormalized_Ratings.Year_Of_Publication, 
        Denormalized_Ratings.Publisher
	ON DUPLICATE KEY UPDATE
		Average_Rating = VALUES(Average_Rating),
        Total_Ratings = VALUES(Total_Ratings);
END //
DELIMITER ;

# Create a trigger to maintain consistency in the summary table
# This trigger updates Book_Ratings_Summary whenever a new rating is inserted.
DELIMITER //
CREATE TRIGGER After_Rating_Insert
AFTER INSERT ON Denormalized_Ratings
FOR EACH ROW
BEGIN
    CALL Update_Book_Ratings_Summary();
END //
DELIMITER ;


CALL Update_Book_Ratings_Summary();
SELECT * FROM Book_Ratings_Summary;

# Create views to simplify analysis of top-rated books, active users, and top authors
# View for top-rated books with the highest average ratings
CREATE VIEW Top_Rated_Books AS
SELECT 
    Book_Title, 
    Average_Rating, 
    Total_Ratings
FROM Book_Ratings_Summary
WHERE Total_Ratings > 0
ORDER BY Average_Rating DESC;

SELECT * FROM Top_Rated_Books;

# View for active users who have given more than 5 ratings
CREATE VIEW Active_Users AS
SELECT 
    User_ID, 
    Location, 
    Total_Ratings_Given, 
    Average_User_Rating
FROM User_Ratings_Summary
WHERE Total_Ratings_Given > 5
ORDER BY Total_Ratings_Given DESC;

SELECT * FROM Active_Users;

# View for top authors based on their average book ratings
CREATE VIEW Top_Authors AS
SELECT 
    Book_Author, 
    Average_Rating_By_Author, 
    Total_Ratings_For_Author
FROM Author_Ratings_Summary
ORDER BY Average_Rating_By_Author DESC
LIMIT 10;

SELECT * FROM Top_Authors;

# Materialized view for faster querying of top-rated books
# This table stores the top-rated books as a snapshot for performance optimization
CREATE TABLE IF NOT EXISTS Materialized_Top_Rated_Books AS
SELECT 
    Book_Title, 
    Average_Rating, 
    Total_Ratings
FROM Top_Rated_Books;

SELECT * FROM Materialized_Top_Rated_Books;

# Enable the event scheduler for automatic updates
SET GLOBAL event_scheduler = ON;

# Define an event to refresh the materialized view daily for up-to-date data
# This event will clear and repopulate the Materialized_Top_Rated_Books table. ensuring that it always contains the most up-to-date snapshot of the top-rated books
DELIMITER //
DROP EVENT IF EXISTS Refresh_Materialized_Top_Rated_Books;  # Ensure no duplicate event exists

CREATE EVENT Refresh_Materialized_Top_Rated_Books
ON SCHEDULE EVERY 1 DAY
STARTS CURRENT_TIMESTAMP # Starts immediately and refreshes every day
DO
BEGIN
    # Clear the existing data in the materialized view
    DELETE FROM Materialized_Top_Rated_Books;

    # Repopulate the table with the latest top-rated books
    INSERT INTO Materialized_Top_Rated_Books
    SELECT 
        Book_Title, 
        Average_Rating, 
        Total_Ratings
    FROM Top_Rated_Books;
END//
DELIMITER ;

# Confirm the creation of the scheduled event for regular refreshes
SHOW EVENTS WHERE Db = 'BookRecomendations';
