use MusicDatabase;
select * from employee;
select * from invoice;
select * from invoice_line;
select * from customer;
select * from genre;
select * from artist;
select * from track;
select * from media_type;
select * from album;
select * from playlist;
select * from playlist_track;



/*Q1.Who is the senior-most employee based on job title?*/
SELECT TOP 1 last_name, first_name, title, levels
FROM employee
ORDER BY levels DESC;

/*Q2.Which countries have the most Invoices?*/
SELECT billing_country, COUNT(*) AS Total_invoice_Count
FROM invoice
GROUP BY billing_country
ORDER BY Total_invoice_Count DESC;

/*Q3.What are the top 3 values of the total invoice?*/
SELECT TOP 3 total
FROM invoice
ORDER BY total DESC;

/*Q4.Which city has the best customers? We would like to throw a promotional Music Festival in the city where we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals.*/
SELECT Top 1 billing_city, ROUND(SUM(total), 2) AS invoice_total
FROM invoice
GROUP BY billing_city
ORDER BY invoice_total DESC;

/*Q5.Who is the best customer? 
The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/
SELECT 
    Top 1 customer.customer_id,
    customer.last_name,
    customer.first_name,
    round(SUM(invoice.total),2) AS Total
FROM 
    customer
JOIN 
    invoice ON customer.customer_id = invoice.customer_id
GROUP BY 
    customer.customer_id,
    customer.last_name,
    customer.first_name
ORDER BY 
    Total DESC;


/*Q6.Write a query to return the email, first name, last name, and genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A.*/
SELECT DISTINCT email AS Email,first_name AS FirstName, last_name AS LastName, genre.name AS Name
FROM customer
JOIN invoice ON invoice.customer_id = customer.customer_id
JOIN invoice_line ON invoice_line.invoice_id = invoice.invoice_id
JOIN track ON track.track_id = invoice_line.track_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
ORDER BY email;

/*Q7.Let us invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands.*/
SELECT Top 10 artist.artist_id, artist.name,COUNT(artist.artist_id) AS number_of_songs
FROM track
JOIN album ON album.album_id = track.album_id
JOIN artist ON artist.artist_id = album.artist_id
JOIN genre ON genre.genre_id = track.genre_id
WHERE genre.name LIKE 'Rock'
GROUP BY artist.artist_id, artist.name
ORDER BY number_of_songs DESC;

/*Q8.Return all the track names that have a song length longer than the average song length. 
Return the Name and Milliseconds for each track. 
Order by the song length with the longest songs listed first.*/
WITH AvgTrackLength AS (
    SELECT AVG(milliseconds) AS Avg_track_length
    FROM track
)
SELECT name, milliseconds
FROM track
WHERE milliseconds > (SELECT Avg_track_length FROM AvgTrackLength)
ORDER BY milliseconds DESC;

      --or--
SELECT name,milliseconds
FROM track
WHERE milliseconds > (
	SELECT AVG(milliseconds) AS avg_track_length
	FROM track )
ORDER BY milliseconds DESC;

/*Q9.Find how much amount spent by each customer on artists. 
Write a query to return the customerís name, artist name, and total spent.*/
WITH best_selling_artists AS (
    SELECT
        artist.artist_id AS artist_id, 
        artist.name AS artist_name, 
        SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(invoice_line.unit_price * invoice_line.quantity) DESC) AS rank
    FROM 
        invoice_line
    JOIN 
        track ON track.track_id = invoice_line.track_id
    JOIN 
        album ON album.album_id = track.album_id
    JOIN 
        artist ON artist.artist_id = album.artist_id
    GROUP BY 
        artist.artist_id, 
        artist.name
)
SELECT 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    bsa.artist_name, 
    SUM(il.unit_price * il.quantity) AS amount_spent
FROM 
    invoice i
JOIN 
    customer c ON c.customer_id = i.customer_id
JOIN 
    invoice_line il ON il.invoice_id = i.invoice_id
JOIN 
    track t ON t.track_id = il.track_id
JOIN 
    album alb ON alb.album_id = t.album_id
JOIN 
    best_selling_artists bsa ON bsa.artist_id = alb.artist_id
WHERE 
    bsa.rank = 1  -- Filter for the top-selling artist
GROUP BY 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    bsa.artist_name
ORDER BY 
    amount_spent DESC;


/*Q10.We want to find out the most popular music Genre for each country.
We determine the most popular genre as the genre with the highest number of purchases. 
Write a query that returns each country along with the top Genre. 
For countries where the maximum number of purchases is shared return all Genres.*/
WITH popular_genre AS 
(
    SELECT TOP 24 COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY customer.country, genre.name, genre.genre_id
	ORDER BY COUNT(invoice_line.quantity)  DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

/*Q11.Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount.*/
SELECT 
    country,
    CONCAT(first_name, ' ', last_name) AS customer_name,
    total_spent
FROM (
    SELECT 
        c.country,
        c.first_name,
        c.last_name,
        SUM(i.total) AS total_spent,
        RANK() OVER(PARTITION BY c.country ORDER BY SUM(i.total) DESC) AS Rank
    FROM 
        customer c
    JOIN 
        invoice i ON c.customer_id = i.customer_id
    GROUP BY 
        c.country, c.first_name, c.last_name
) AS top_customers
WHERE 
    Rank = 1

/*Q12.Which artists have the most tracks in the database?*/
SELECT 
    a.artist_id,
    a.name AS artist_name,
    COUNT(t.track_id) AS track_count
FROM 
    artist a
JOIN 
    album al ON a.artist_id = al.artist_id
JOIN 
    track t ON al.album_id = t.album_id
GROUP BY 
    a.artist_id,
    a.name
ORDER BY 
    COUNT(t.track_id) DESC;


