-- Lab subqueries - 3.02

-- 1 How many copies of the film Hunchback Impossible exist in the inventory system?
SELECT COUNT(inventory_id) AS copies_of_Hunchback_Impossible
FROM sakila.inventory 
WHERE film_id IN
(SELECT film_id
FROM sakila.film
WHERE title = 'HUNCHBACK IMPOSSIBLE');

#or
SELECT COUNT(inventory_id) AS count
FROM sakila.inventory i, sakila.film f
WHERE f.film_id = i.film_id
AND f.title = 'HUNCHBACK IMPOSSIBLE';

-- 2 List all films whose length is longer than the average of all the films.
SELECT title FROM film
WHERE length > (
  SELECT avg(length)
  FROM film
);


-- 3 Use subqueries to display all actors who appear in the film Alone Trip.
SELECT actor_id, first_name, last_name
FROM sakila.actor
WHERE actor_id IN
				(SELECT actor_id 
				FROM film_actor 
				WHERE film_id IN
							(SELECT film_id
							FROM sakila.film
							WHERE title = 'ALONE TRIP') 
);

#or
select actor_id, first_name, last_name from film_actor
JOIN actor USING(actor_id)
	where film_id = '17';

#or
select actor_id, first_name, last_name from film_actor
JOIN actor USING(actor_id)
	where film_id in (
	select film_id from film
    where film_id='17');

-- 4 Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as
# family films.
SELECT f.title, c.name
FROM sakila.film f
JOIN sakila.film_category fc
	USING (film_id)
JOIN sakila.category c
	USING (category_id)
WHERE c.name = 'Family';

#or

SELECT film_id, title
FROM sakila.film
WHERE film_id in 
	(SELECT film_id
	FROM sakila.film_category
	WHERE category_id IN (SELECT category_id
					FROM category 
					WHERE name = 'Family'));
                    
-- 5 Get name and email from customers from Canada using subqueries. Do the same with joins. Note that to create a join, you will have to 
#identify the correct tables with their primary keys and foreign keys, that will help you get the relevant information.
#country_id - city_id - address_id - customer_id

SELECT first_name, last_name, email
FROM sakila.customer
WHERE address_id IN 
(SELECT address_id
FROM sakila.address
WHERE city_id IN
		(SELECT city_id
		FROM sakila.city
		WHERE country_id IN
				(SELECT country_id
				FROM sakila.country
				WHERE country = 'Canada')));

#or

SELECT first_name, last_name, email
FROM sakila.customer
JOIN sakila.address 
    USING (address_id)
JOIN sakila.city
	USING (city_id)
JOIN sakila.country
	USING (country_id)
	WHERE country = 'Canada';

-- 6 Which are films starred by the most prolific actor? Most prolific actor is defined as the actor that has acted in the 
#most number of films. First you will have to find the most prolific actor and then use that actor_id to find the different films 
#that he/she starred.

DROP TABLE IF EXISTS movie_count;
CREATE TEMPORARY TABLE movie_count AS (
SELECT *, COUNT(film_id) AS movie_count
FROM sakila.film_actor
GROUP BY actor_id)
ORDER BY movie_count DESC
LIMIT 1
;

SELECT title 
FROM sakila.film 
	WHERE film_id IN (
	SELECT film_id FROM film_actor 
		WHERE actor_id IN (
		SELECT actor_id FROM prolific_actor
	) 
);

#or for the second part
SELECT title FROM film 
JOIN film_actor USING(film_id)
JOIN movie_count USING(actor_id);

-- 7 Films rented by most profitable customer. You can use the customer table and payment table to find the most profitable customer ie the 
#customer that has made the largest sum of payments
DROP TABLE IF EXISTS most_profitable_customer;
CREATE TEMPORARY TABLE most_profitable_customer AS (
SELECT customer_id AS most_profitable_customer, SUM(amount) AS total_amount
FROM sakila.payment
GROUP BY customer_id)
ORDER BY total_amount DESC
LIMIT 1;

SELECT title
FROM sakila.film
WHERE film_id IN
(SELECT film_id 
FROM sakila.inventory
WHERE inventory_id IN
(SELECT rental_id
FROM sakila.rental
WHERE customer_id IN (
SELECT most_profitable_customer
FROM most_profitable_customer)));

-- 8 Customers who spent more than the average payments.

CREATE TEMPORARY TABLE temp AS 
(SELECT customer_id, SUM(amount) AS total_payment 
FROM sakila.payment
GROUP BY customer_id
);

SELECT first_name, last_name, SUM(amount) 
FROM sakila.customer
JOIN sakila.payment USING(customer_id)
GROUP BY customer_id
HAVING SUM(amount) > (SELECT AVG(total_payment) FROM temp);
