--======================================================================
-- Конспект урока 9.3 Скалярные функции. Примеры функций из урока
--======================================================================

CREATE OR REPLACE FUNCTION get_total_number_of_goods() RETURNS bigint AS $$
SELECT SUM(units_in_stock)
FROM products
$$ LANGUAGE SQL;

SELECT get_total_number_of_goods() AS total_goods;

--====================
CREATE OR REPLACE FUNCTION get_avg_price() RETURNS float8 AS $$
SELECT AVG(unit_price)
FROM products
$$ LANGUAGE SQL;

SELECT get_avg_price() AS avg_price;

--======================================================================
-- Конспект урока 9.4 IN, OUT, DEFAULT. Примеры функций из урока
--======================================================================

CREATE OR REPLACE FUNCTION get_product_price_by_name(prod_name varchar) RETURNS real AS $$
    SELECT unit_price
    FROM products
    WHERE product_name = prod_name
$$ LANGUAGE SQL;

SELECT get_product_price_by_name('Chocolade') as price;

SELECT *
FROM products
ORDER BY product_name;

--====================

CREATE OR REPLACE FUNCTION get_price_boundaries(OUT max_price real, OUT min_price real) AS $$
    SELECT MAX(unit_price), MIN(unit_price)
    FROM products
$$ LANGUAGE SQL;

SELECT get_price_boundaries();

SELECT *
FROM get_price_boundaries();

--====================

CREATE OR REPLACE FUNCTION get_price_boundaries_by_discontinuity(is_discontinued int, OUT max_price real, OUT min_price real) AS $$
    SELECT MAX(unit_price), MIN(unit_price)
    FROM products
    WHERE discontinued = is_discontinued
$$ LANGUAGE SQL;

SELECT *
FROM get_price_boundaries_by_discontinuity(1);

--====================

CREATE OR REPLACE FUNCTION get_price_boundaries_by_discontinuity_defaut(is_discontinued int DEFAULT 1, OUT max_price real, OUT min_price real) AS $$
    SELECT MAX(unit_price), MIN(unit_price)
    FROM products
    WHERE discontinued = is_discontinued
$$ LANGUAGE SQL;

SELECT *
FROM get_price_boundaries_by_discontinuity_defaut();

--======================================================================
-- Конспект урока 9.5 Возврат наборов данных. Примеры функций из урока
--======================================================================

CREATE OR REPLACE FUNCTION get_average_prices_by_prod_categories() 
        RETURNS SETOF double precision AS $$
    SELECT AVG(unit_price)
    FROM products
    GROUP BY category_id
$$ LANGUAGE SQL;

SELECT * 
FROM get_average_prices_by_prod_categories() AS average_prices;

SELECT * FROM products;

--=========================================

--  RETURNS SETOF record возвращает множество строк с данными двух полей OUT, а не одну.
CREATE OR REPLACE FUNCTION get_sum_avg_prices_by_prod_categories(OUT sum_price real, OUT avg_price float8) 
        RETURNS SETOF RECORD AS $$
    SELECT SUM(unit_price), AVG(unit_price)
    FROM products
    GROUP BY category_id
$$ LANGUAGE SQL;

SELECT * FROM get_sum_avg_prices_by_prod_categories();
SELECT sum_price, avg_price FROM get_sum_avg_prices_by_prod_categories();

SELECT sum_price AS sum_of, avg_price AS in_avg 
FROM get_sum_avg_prices_by_prod_categories();

-- Deprecated: (осуждаемый)
-- НЕ желательное использование этой функции без явных указаний типов OUT аргументов
CREATE OR REPLACE FUNCTION get_sum_avg_prices_by_prod_categories_depr() 
        RETURNS SETOF RECORD AS $$
    SELECT SUM(unit_price), AVG(unit_price)
    FROM products
    GROUP BY category_id
$$ LANGUAGE SQL;

-- Это будет работать только в этом случае. Тоесть когда в селекте явно укажешь типы OUT аргументов
SELECT *
FROM get_sum_avg_prices_by_prod_categories_depr() AS (sum_price real, avg_price float8)

--=========================================

CREATE OR REPLACE FUNCTION get_customers_by_country(customer_country varchar) 
        RETURNS TABLE(char_code char, company_name varchar) AS $$
    SELECT customer_id, company_name
    FROM customers
    WHERE country = customer_country
$$ LANGUAGE SQL;

SELECT * FROM get_customers_by_country('USA');
SELECT company_name FROM get_customers_by_country('USA');
SELECT char_code, company_name FROM get_customers_by_country('USA');

CREATE OR REPLACE FUNCTION get_customers_by_country_table(customer_country varchar) 
        RETURNS SETOF customers AS $$
        
    -- won't work SELECT company_name contact_name
    SELECT *
    FROM customers
    WHERE country = customer_country
$$ LANGUAGE SQL;

SELECT * FROM get_customers_by_country_table('USA');
SELECT company_name FROM get_customers_by_country_table('USA');
SELECT customer_id, company_name FROM get_customers_by_country_table('USA');

--======================================================================
-- PL\pgSQL----PL\pgSQL----PL\pgSQL----PL\pgSQL----PL\pgSQL-----PL\pgSQL----PL\pgSQL---PL\pgSQL--PL\pgSQL
--======================================================================
-- 9.6 Введение в PL\pgSQL
-- Конспект урока 9.7. Возврат и присвоение. Примеры функций из урока
--======================================================================

DROP FUNCTION get_total_number_of_goods()

CREATE OR REPLACE FUNCTION get_total_number_of_goods() RETURNS bigint AS $$
BEGIN
    RETURN SUM(units_in_stock)
    FROM products;
END
$$ LANGUAGE plpgsql;

SELECT get_total_number_of_goods();

--======================================================================

CREATE OR REPLACE FUNCTION get_price_boundaries(OUT max_price real, OUT min_price real) AS $$
BEGIN
    SELECT MAX(unit_price), MIN(unit_price)
    INTO max_price, min_price  -- каким переменным мы присваиваем выборку
    FROM products;
END;
$$ LANGUAGE plpgsql;

SELECT get_price_boundaries();
SELECT * FROM  get_price_boundaries();
--======================================================================

-- функция возвращает сумму двух чисел
CREATE OR REPLACE FUNCTION get_sum(x int, y int, out result int) AS $$
BEGIN
    result = x + y;
    RETURN;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_sum(2, 8);

--======================================================================

DROP FUNCTION IF EXISTS get_customers_by_country;

CREATE OR REPLACE FUNCTION get_customers_by_country(customer_country varchar) RETURNS SETOF customers AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM customers
    WHERE country = customer_country;
END;
$$ LANGUAGE plpgsql;

SELECT get_customers_by_country('USA');
-- или
SELECT * FROM get_customers_by_country('USA');


--======================================================================
-- 9.9 IF / ELSE в PL\pgSQL
-- Конспект урока 9.9 IF / ELSE в PL\pgSQL. Примеры функций из урока
--======================================================================

IF expression1  THEN
	logic
ELSIF expression1 THEN
	logic
ELSIF expression1 THEN
	logic
ELSE 
	logic
END IF;

--======================================================================

-- Создаём функцию конвертации градусов по шкале фаренгейт в шкалу цельсия
CREATE FUNCTION covert_temp_to(temperature REAL, to_celsius bool DEFAULT  true)
		RETURNS REAL AS $$
DECLARE 
	result_temp real;
BEGIN
	IF to_celsius THEN  --  Если to_celsius = true, тогда:
		result_temp = (5.0/9.0) * (temperature-32);
	ELSE
		result_temp = (9 * temperature + (32*5)) / 5.0;
	END IF;
RETURN result_temp;
END;
$$ LANGUAGE plpgsql;

SELECT covert_temp_to(80, true);  --  80 градусов по фаренгейту -> выдайт 26,6666 по цельсию
SELECT covert_temp_to(26.7, false);  -- 26.7 градусов по цельсию можем тоже внести. Но для этого в аргумент to_celsius передаём FALSE

--======================================================================
DROP FUNCTION IF EXISTS get_season();
CREATE FUNCTION get_season(month_number int)
		RETURNS text AS $$
DECLARE season text;
BEGIN
	IF month_number BETWEEN 3 AND 5  THEN season = 'Spring';
	ELSEIF month_number BETWEEN 6 AND 8  THEN season = 'Summer';
	ELSEIF month_number BETWEEN 9 AND 11  THEN season = 'Autumn';
	ELSE season = 'Winter';
	END IF;

	RETURN season;
END
$$ LANGUAGE plpgsql;

SELECT get_season(12);

--======================================================================
-- 9.10  Циклы в PL\pgSQL
-- Конспект урока 9.9 Цыклы в PL\pgSQL. Примеры функций из урока
--======================================================================

-- =================		Цикл WHILE	===================================== 

CREATE OR REPLACE FUNCTION get_next_number_Fibonachi_series(n int) RETURNS int AS $$
-- Передаём в функцию число Фибоначи, а получаем следующее число  ряда Фибоначи.

DECLARE
	fibonachi int = 0;
	previous_number int = 0;
	current_number int = 1;
BEGIN
	-- Отсечем дальнейшее исполнение кода таким условием
	IF n < 1 THEN 
		RETURN 0;
	END IF;

	while fibonachi <= n
		LOOP
			fibonachi = previous_number + current_number;
			previous_number = current_number;
			current_number = fibonachi;
		END LOOP;
	RETURN fibonachi;
END; 
$$ LANGUAGE PLPGSQL;

SELECT get_next_number_Fibonachi_series(21);

-- =================		Выражение EXIT WHEN в цикле 		==========================
--=============		Другая организация того же цикла		=============================

CREATE OR REPLACE FUNCTION get_next_number_Fibonachi_series1(n int) RETURNS int AS $$
-- Передаём в функцию число Фибоначи, а получаем следующее число  ряда Фибоначи.

DECLARE
	fibonachi int = 0;
	previous_number int = 0;
	current_number int = 1;
BEGIN
	-- Отсечем дальнейшее исполнение кода таким условием
	IF n < 1 THEN 
		RETURN 0;
	END IF;

	LOOP
		EXIT WHEN   fibonachi > n; -- выйти как только достигнет условия. Инвертированая логика по сравнению с пердидущим циклом while
		fibonachi = previous_number + current_number;
		previous_number = current_number;
		current_number = fibonachi;
	END LOOP;
	RETURN fibonachi;
END; 
$$ LANGUAGE PLPGSQL;

SELECT get_next_number_Fibonachi_series1(20);


-- =================		Выражение DO и циклы. DO можно использовать для дебажинга ==========
--=============		Другая организация того же цикла		==================================

-- Шикарный инструмент для проверки блоков кода и каких либо гипотез 
DO $$
BEGIN 
	FOR counter IN 1..5  -- от 1 до 5
	LOOP 
		RAISE NOTICE 'Counter: %', counter;  -- Выводятся значения в окно вывода 
	END LOOP;
END$$;

-- ===  Тоже самое но реверсивно
DO $$
BEGIN 
	FOR counter IN REVERSE  5..1  -- от 5 до 1
	LOOP 
		RAISE NOTICE 'Counter: %', counter;  -- Выводятся значения в окно вывода 
	END LOOP;
END$$;


-- ===  Цикл с шагом BY

DO $$
BEGIN 
	FOR counter IN 1..5 BY 2  -- от 1 до 5
	LOOP 
		RAISE NOTICE 'Counter: %', counter;  -- Выводятся значения в окно вывода 
	END LOOP;
END$$;

/*
=========================================================================================
=========================================================================================
                                                                                                ОТВЕТЫ НА ДЗ
=========================================================================================
=========================================================================================
*/

-- Создаём новую функцию. Она ничего не возвращает и ничего не принимает
-- RETURNS void выражение которое говорит, что функция ничего не возвращает (только производит действия)

CREATE OR REPLACE FUNCTION fix_customer_region() RETURNS void AS $$
UPDATE tmp_customers
SET region = 'unknown'
WHERE tmp_customers.region IS NULL
$$ LANGUAGE SQL;

-- Поскольку функция ничего не возвращает мы видим null в результирующем output
SELECT fix_customer_region();

--=========================================================================================
-- Задача №1. Создайте функцию, которая делает бэкап таблицы customers (копирует все данные в другую таблицу),
-- предварительно стирая таблицу для бэкапа, если такая уже существует (чтобы в случае многократного запуска таблица для бэкапа перезатиралась).

CREATE OR REPLACE FUNCTION get_backup_customers() 
	RETURNS text AS $$ -- возвращаем пустоту
	DROP TABLE IF EXISTS backup_customers;	
	SELECT *
	INTO backup_customers
	FROM customers;
	SELECT 'Жизнь прекрасна!!!' as result_answer; -- это не идет в возвращающееся значение. Пока не знаю как это сделать
$$ LANGUAGE SQL;

SELECT get_backup_customers();
SELECT * FROM backup_customers;

--=========================================================================================
--  2. Создать функцию, которая возвращает средний фрахт (freight) по всем заказам

-- Создаём функцию с аргументом OUT. Тип данных выводного потока указываем в скобках функции (в описании аргумента OUT). 
CREATE OR REPLACE FUNCTION get_avg_freight(OUT avg_freight float) AS $$
	SELECT avg(o.freight)
	FROM orders o;
$$ LANGUAGE SQL;

SELECT get_avg_freight();

-----  =====  Тоже самое через PLPGSQL 

CREATE OR REPLACE FUNCTION get_avg_freight_plpgsql() RETURNS float AS $$
BEGIN 
	RETURN avg(o.freight)
	FROM orders o;
END
$$ LANGUAGE plpgsql;

SELECT get_avg_freight_plpgsql();
--=========================================================================================
/* 
 3. Написать функцию, которая принимает два целочисленных параметра, используемых как нижняя и верхняя границы 
для генерации случайного числа в пределах этой границы (включая сами граничные значения).

Функция random генерирует вещественное число от 0 до 1. 
Необходимо вычислить разницу между границами и прибавить единицу.
На полученное число умножить результат функции random() и прибавить к результату значение нижней границы.
Применить функцию floor() к конечному результату, чтобы не "уехать" за границу и получить целое число.
*/
--=========================================================================================
DROP FUNCTION IF EXISTS generating_numbers_between_two_numbers;
CREATE OR REPLACE FUNCTION generating_numbers_between_two_numbers(min_int int DEFAULT 0, max_int int DEFAULT 2)
RETURNS int AS $$
	SELECT random() * (max_int - min_int + 1) + min_int;
$$ LANGUAGE SQL;

SELECT generating_numbers_between_two_numbers(0,15);

SELECT generating_numbers_between_two_numbers(0,15)
FROM generate_series(1, 5);

-- Прикольный генератор
SELECT random(1,16) FROM generate_series(1, 10);

--=========================================================================================
/* 
 3,5. Создать функцию, которая возвращает минимальную и максимальную дату рождения среди сотрудников
*/
--=========================================================================================

DROP FUNCTION IF EXISTS min_and_max_birthdate;
CREATE OR REPLACE FUNCTION min_and_max_birthdate(OUT min_birth_date date, OUT max_birth_date date) AS $$
	SELECT min(e.birth_date), max(e.birth_date)
	FROM employees e;
$$ LANGUAGE SQL;

SELECT * FROM min_and_max_birthdate();

--=================== ИЛИ такое решение ================

DROP FUNCTION IF EXISTS min_and_max_birthdate;
CREATE OR REPLACE FUNCTION min_and_max_birthdate(OUT min_birth_date date, OUT max_birth_date date) 
		RETURNS SETOF RECORD AS $$
	SELECT min(e.birth_date), max(e.birth_date)
	FROM employees e;
$$ LANGUAGE SQL;

SELECT * FROM min_and_max_birthdate();

--=========================================================================================
/* 
Создаём поле таблицы для последующих функций и генерируем для него значения рандомайзера
*/
--=========================================================================================
ALTER TABLE employees DROP COLUMN IF EXISTS salary;
ALTER TABLE employees
    ADD COLUMN salary numeric(12, 2);

UPDATE employees
    SET salary = random(40,120);
SELECT salary FROM employees e;


--=========================================================================================
/* 
 4. Создать функцию, которая возвращает самые низкую и высокую зарплаты среди сотрудников заданного города
*/
--=========================================================================================

DROP FUNCTION IF EXISTS min_and_max_salary_by_sity;
CREATE OR REPLACE FUNCTION min_and_max_salary_by_sity(city text, OUT min_salary float8, OUT max_salary float8) AS $$
	SELECT min(e.salary), max(e.salary) 
	FROM employees e
	WHERE city = city;
$$ LANGUAGE SQL;

SELECT * FROM min_and_max_salary_by_sity('London');
--=========================================================================================
/* 
5. Создать функцию, которая корректирует зарплату на заданный процент,  но не корректирует зарплату, если её уровень
 превышает заданный уровень при этом верхний уровень зарплаты по умолчанию равен 70, а процент коррекции равен 15%. 
*/
--=========================================================================================

CREATE OR REPLACE FUNCTION correct_sallary_at_the_percent(percent numeric DEFAULT 0.15, salary_high_level numeric DEFAULT 70)
RETURNS setof AS 
$$
	UPDATE employees
	SET salary = salary * percent + salary
	WHERE salary <= salary_high_level;
$$ LANGUAGE SQL;

SELECT correct_sallary_at_the_percent(80);

--=========================================================================================
/* 
6. Модифицировать функцию, корректирующую зарплату таким образом, чтобы в результате коррекции, она так же выводила бы изменённые записи.
*/
--=========================================================================================

DROP FUNCTION IF EXISTS correct_sallary_at_the_percent2;
CREATE OR REPLACE FUNCTION correct_sallary_at_the_percent2(percent numeric DEFAULT 0.15, salary_high_level numeric DEFAULT 70)
RETURNS TABLE (employee_id int, salary_before_changes int, salary_after_changes int) AS 
$$
-- Сначала создаём временную таблицу
TRUNCATE tmp_employees;
INSERT INTO tmp_employees
	SELECT employee_id, salary
	from employees
	WHERE salary <= salary_high_level;
--==================
UPDATE employees
SET salary = salary * percent + salary
WHERE salary <= salary_high_level;
--==================
-- После изменения джойним с временной таблицей данные. И получаем то что было изменено
SELECT e.employee_id, te.salary  AS salary_before_changes , e.salary  AS salary_after_changes
FROM employees e
LEFT JOIN tmp_employees te ON e.employee_id = te.employee_id 
ORDER BY salary_after_changes;
$$ LANGUAGE SQL;

SELECT * FROM correct_sallary_at_the_percent2(0.05,273);

SELECT salary FROM employees AS e ORDER BY e.salary;


--=========================================================================================
/* 
7. Модифицировать предыдущую функцию так, чтобы она возвращала только колонки last_name, first_name, title, salary
*/
--=========================================================================================

DROP FUNCTION IF EXISTS correct_sallary_at_the_percent3;
CREATE OR REPLACE FUNCTION correct_sallary_at_the_percent3(percent numeric DEFAULT 0.15, salary_high_level numeric DEFAULT 70)
RETURNS TABLE (employee_id int, salary_before_changes int, salary_after_changes int, last_name text, first_name text, title text) AS 
$$    
-- Сначала создаём временную таблицу
TRUNCATE tmp_employees;
INSERT INTO tmp_employees
	SELECT employee_id, salary
	from employees
	WHERE salary <= salary_high_level;
--==================
UPDATE employees
SET salary = salary * percent + salary
WHERE salary <= salary_high_level;
--==================
-- После изменения джойним с временной таблицей данные. И получаем то что было изменено
SELECT e.employee_id, te.salary  AS salary_before_changes , e.salary  AS salary_after_changes, e.last_name, e.first_name, e.title
FROM employees e
LEFT JOIN tmp_employees te ON e.employee_id = te.employee_id 
ORDER BY salary_after_changes;
$$ LANGUAGE SQL;

SELECT * FROM correct_sallary_at_the_percent3(0.05,52);

SELECT salary FROM employees AS e ORDER BY e.salary;

--=========================================================================================
/* 
8. Написать функцию, которая принимает метод доставки и возвращает записи из таблицы orders в которых freight 
	меньше значения, определяемого по следующему алгоритму:
	- ищем максимум фрахта (freight) среди заказов по заданному методу доставки
	- корректируем найденный максимум на 30% в сторону понижения
	- вычисляем среднее значение фрахта среди заказов по заданному методому доставки
	- вычисляем среднее значение между средним найденным на предыдущем шаге и скорректированным максимумом
	- возвращаем все заказы в которых значение фрахта меньше найденного на предыдущем шаге среднего
*/
--=========================================================================================

DROP FUNCTION IF EXISTS freight_with_conditions;
CREATE OR REPLACE FUNCTION freight_with_conditions(ship_via_method int) 
RETURNS SETOF orders AS $$
-- ищем максимум фрахта (freight) среди заказов по заданному методу доставки
DECLARE
	max_freight numeric;
	avg_freight numeric;
	middle_freight numeric;
BEGIN
	SELECT max(freight) INTO max_freight FROM orders WHERE ship_via = ship_via_method;
	SELECT avg(freight) INTO avg_freight FROM orders WHERE ship_via = ship_via_method;
	--=========================
	-- получаем скоректированный максимум и нужную цену
	max_freight = max_freight * 0.7;
	middle_freight = (max_freight + avg_freight)/2;

	RETURN QUERY 
	SELECT *
	FROM orders
	WHERE freight < middle_freight;
END;
$$ LANGUAGE plpgsql;

SELECT count(*) FROM freight_with_conditions(1);
SELECT * FROM orders AS o;

--=========================================================================================
/* 
9. Написать функцию, которая принимает:
уровень зарплаты, максимальную зарплату (по умолчанию 80) минимальную зарплату (по умолчанию 30), коээфициет роста зарплаты (по умолчанию 20%)
Если зарплата выше минимальной, то возвращает false
Если зарплата ниже минимальной, то увеличивает зарплату на коэффициент роста и проверяет не станет ли зарплата после повышения превышать максимальную.
Если превысит - возвращает false, в противном случае true.
Проверить реализацию, передавая следующие параметры
(где c - уровень з/п, max - макс. уровень з/п, min - минимальный уровень з/п, r - коэффициент):
c = 40, max = 80, min = 30, r = 0.2 - должна вернуть false
c = 79, max = 81, min = 80, r = 0.2 - должна вернуть false
c = 79, max = 95, min = 80, r = 0.2 - должна вернуть true
*/
--=========================================================================================

DROP FUNCTION IF EXISTS chould_increase_salary;
CREATE OR REPLACE FUNCTION chould_increase_salary(
			cur_salary NUMERIC,
			max_salary NUMERIC DEFAULT 80,
			min_salary NUMERIC DEFAULT 30,
			increase_rate NUMERIC DEFAULT 0.2	)
RETURNS bool AS
$$
DECLARE 
	new_salary NUMERIC;
BEGIN
	IF cur_salary >= max_salary OR cur_salary >= min_salary THEN
		RETURN false;
	END IF;

	IF cur_salary < min_salary THEN
		new_salary = cur_salary + (cur_salary * increase_rate);
	END IF;
	
	IF new_salary > max_salary THEN 
		RETURN false;
	ELSE 
		RETURN true;
	END IF;
END;
$$ LANGUAGE plpgsql;

SELECT chould_increase_salary(40,80,30,0.2);
SELECT chould_increase_salary(79,81,80,0.2);
SELECT chould_increase_salary(79,95,90,0.2);

SELECT salary FROM employees AS e ORDER BY e.salary;

---- Конез ДЗ из 9 блока=========================================================================
---========================================================================================

-- ДЗ 10 блока
--=========================================================================================
/* 
10  Ошибки и их обработка. raise exception
Задание:
Модифицировать функцию should_increase_salary разработанную в секции по функциям таким образом, чтобы запретить (выбрасывая исключения) передачу аргументов так, что:
минимальный уровень з/п превышает максимальный
ни минимальный, ни максимальный уровень з/п не могут быть меньше нуля
коэффициент повышения зарплаты не может быть ниже 5%
Протестировать реализацию, передавая следующие значения аргументов (с - уровень "проверяемой" зарплаты, r - коэффициент повышения зарплаты):
c = 79, max = 10, min = 80, r = 0.2
c = 79, max = 10, min = -1, r = 0.2
c = 79, max = 10, min = 10, r = 0.04

*/
--=========================================================================================


DROP FUNCTION IF EXISTS chould_increase_salary;
CREATE OR REPLACE FUNCTION chould_increase_salary(
			cur_salary NUMERIC,
			max_salary NUMERIC DEFAULT 80,
			min_salary NUMERIC DEFAULT 30,
			increase_rate NUMERIC DEFAULT 0.2	)
RETURNS bool AS
$$
DECLARE 
	new_salary NUMERIC;
BEGIN
	IF min_salary > max_salary then
		raise exception 'min salary не может превышать максимум. Min is  %, Max is %', min_salary, max_salary;
	END IF;
	IF max_salary < 0 or min_salary < 0 then
		raise exception 'min salary and max salary должен быть >=0. Min is  %, Max is %', min_salary, max_salary;
	END IF;
	IF increase_rate < 0.05 then
		raise exception 'Increase rate should be >= 0.05. You passed in %', increase_rate;
	END IF;
	IF cur_salary >= max_salary OR cur_salary >= min_salary THEN
		RETURN false;
	END IF;

	IF cur_salary < min_salary THEN
		new_salary = cur_salary + (cur_salary * increase_rate);
	END IF;
	
	IF new_salary > max_salary THEN 
		RETURN false;
	ELSE 
		RETURN true;
	END IF;
END;
$$ LANGUAGE plpgsql;

SELECT chould_increase_salary(79,10,80,0.2);
SELECT chould_increase_salary(79,10,-1,0.2);
SELECT chould_increase_salary(79,10,10,0.04);

-- типизация данных
SELECT ' 10 ' = 10;
SELECT 'abc' || 1;


