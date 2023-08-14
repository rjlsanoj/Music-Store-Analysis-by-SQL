--Q.1. WHO IS THE SENIOR MOST EMPLOYEE BASED ON JOB TITLE?

select * from employee
order by levels desc
limit 1

/* Q2: Which countries have the most Invoices? */

select billing_country,count(*) as total_invoices
from invoice
group by billing_country 
order by total_invoices desc
limit 5

/* Q3: What are top 3 values of total invoice? */

select invoice_id,total from invoice
order by total desc limit 3


/* Q4: Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
Write a query that returns one city that has the highest sum of invoice totals. 
Return both the city name & sum of all invoice totals */

select billing_city,sum(total) as total_invoices from invoice
group by billing_city
order by total_invoices desc limit 1

/* Q5: Who is the best customer? The customer who has spent the most money will be declared the best customer. 
Write a query that returns the person who has spent the most money.*/

select customer.customer_id,first_name, last_name,sum(invoice.total) as total_spend from customer
join invoice
on customer.customer_id = invoice.customer_id
group by customer.customer_id
order by total_spend desc limit 1

/* Q6: Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
Return your list ordered alphabetically by email starting with A. */
select distinct email,first_name,last_name from customer
join invoice on customer.customer_id = invoice.customer_id
join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
		select track_id from track
		join genre on track.genre_id = genre.genre_id
		where genre.name = 'Rock'
)
order by email

/* Q7: Let's invite the artists who have written the most rock music in our dataset. 
Write a query that returns the Artist name and total track count of the top 10 rock bands. */

select artist.artist_id,artist.name,count(artist.artist_id) as number_of_songs from track
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id = track.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit 10

--Q8: Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first.

select name,milliseconds from track
where milliseconds > (
						select avg(milliseconds) as avg_track_length 
						from track						
					)
order by milliseconds desc

/* Q9: Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

/* Steps to Solve: First, find which artist has earned the most according to the InvoiceLines. Now use this artist to find 
which customer spent the most on this artist. For this query, you will need to use the Invoice, InvoiceLine, Track, Customer, 
Album, and Artist tables. Note, this one is tricky because the Total spent in the Invoice table might not be on a single product, 
so you need to use the InvoiceLine table to find out how many of each product was purchased, and then multiply this by the price
for each artist. */

with best_selling_artist as (
	select artist.artist_id, artist.name as artist_name,
	sum(invoice_line.unit_price*invoice_line.quantity) as total_sales
	from invoice_line
	join track on track.track_id = invoice_line.track_id
	join album on album.album_id = track.album_id
	join artist on album.artist_id = artist.artist_id
	group by 1
	order by 3 desc
	limit 1
)

select c.customer_id,c.first_name,c.last_name,bsa.artist_name,
sum(il.unit_price * il.quantity) as spend_amount from invoice i

join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album al on al.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = al.artist_id
group by 1,2,3,4
order by 5 desc

/* Q10: We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre 
with the highest amount of purchases. Write a query that returns each country along with the top Genre. For countries where 
the maximum number of purchases is shared return all Genres. */

/* Steps to Solve:  There are two parts in question- first most popular music genre and second need data at country level. */

with popular_genre as (
		select count(invoice_line.quantity) as purchases,customer.country,genre.name,genre.genre_id,
		row_number() over(partition by customer.country order by count(invoice_line.quantity)desc) as RowNo
		from invoice_line
		join invoice on invoice.invoice_id = invoice_line.invoice_id
		join customer on customer.customer_id = invoice.customer_id
		join track on track.track_id = invoice_line.track_id
		join genre on track.genre_id = genre.genre_id
		group by 2,3,4
		order by 2 asc, 1 desc
)

select * from popular_genre 
where RowNo =1

/* Q10: Write a query that determines the customer that has spent the most on music for each country. 
Write a query that returns the country along with the top customer and how much they spent. 
For countries where the top amount spent is shared, provide all customers who spent this amount. */

/* Steps to Solve:  Similar to the above question. There are two parts in question- 
first find the most spent on music for each country and second filter the data for respective customers. */

with customer_with_country as(
	select customer.customer_id,first_name,last_name,billing_country,sum(total) as total_spending,
	row_number() over(partition by billing_country order by sum(total) desc ) as rowno
	from invoice
	join customer on customer.customer_id = invoice.customer_id
	group by 1,2,3,4
	order by 4 asc , 5 desc
)
select * from customer_with_country 
where rowno = 1