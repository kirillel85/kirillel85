
--======================================================================
-- 14.1 Пользовательские типы. Домены
--======================================================================

CREATE DOMAIN text_no_space_null AS text NOT NULL CHECK (value ~ '^(?!\s*$)');

CREATE TABLE agent(
    first_name text_no_space_null,
    last_name text_no_space_null
);

INSERT INTO agent
VALUES('bob', 'marley');

SELECT * FROM agent;

--======================================================================
-- 14.2 Пользовательские типы. Композитные (Составные) типы
--======================================================================


--======================================================================
-- 14.3 Пользовательские типы. Перечисления
--======================================================================

-- Создаём табличци для примера. Класияческая таблица фактов и справочник к ней
CREATE TABLE chess_title
(
    title_id serial PRIMARY KEY,
    title    text
);

CREATE TABLE chess_player
(
    player_id  serial PRIMARY KEY,
    first_name text,
    last_name  text,
    title_id   int REFERENCES chess_title (title_id)
);

INSERT INTO chess_title(title)
	VALUES 
	('Candidate Master'),
	('FIDE Master'),
	('International Master'),
	('Grand Master');

SELECT * FROM chess_title;

INSERT INTO chess_player(first_name, last_name, title_id)
	VALUES 
	('Wesley', 'So', 4),
	('Vlad', 'Kramnik', 4),
	('Vasily', 'Pupkin', 1);

SELECT * FROM chess_player JOIN chess_title USING (title_id);


--- Подход что и выше только с enumerate
DROP TABLE chess_title CASCADE;
DROP TABLE chess_player;

CREATE TYPE chess_title AS ENUM
    ('Candidate Master', 'FIDE Master', 'International Master'); -- Тот же справочник что и выше только в виде перечесления

SELECT ENUM_RANGE(NULL::chess_title);

-- Добавляем значение  'Grand Master' в перечесление
ALTER TYPE chess_title
    ADD VALUE 'Grand Master' AFTER 'International Master';

CREATE TABLE chess_player
(
    player_id  serial PRIMARY KEY,
    first_name text,
    last_name  text,
    title      chess_title
);

INSERT INTO chess_player(first_name, last_name, title)
VALUES ('Magnus', 'Carlsen', 'Grand Master');

SELECT * FROM chess_player;


--======================================================================
-- 14 Пользовательские типы. ДЗ
--======================================================================

-- 1. Переписать функцию, которую мы разработали ранее в одном из ДЗ таким образом, чтобы функция возвращала экземпляр композитного типа. Вот та самая функция:

create or replace function get_salary_boundaries_by_city(
    emp_city varchar, out min_salary numeric, out max_salary numeric) 
AS 
$$
    SELECT MIN(salary) AS min_salary,
              MAX(salary) AS max_salary
      FROM employees
    WHERE city = emp_city
$$ language sql;

-- Создаём композитный тип
CREATE TYPE price_bounds AS (
min_price NUMERIC,
max_price NUMERIC);

--Пересоздаём функцию с перечислением
CREATE OR REPLACE FUNCTION get_salary_boundaries_by_city_type(emp_city varchar)
RETURNS setof price_bounds AS
$$
    SELECT MIN(salary) AS min_salary,
              MAX(salary) AS max_salary
      FROM employees
    WHERE city = emp_city
$$ LANGUAGE SQL;

SELECT * FROM get_salary_boundaries_by_city_type('London');


/*
2. Задание состоит из пунктов:
Создать перечисление армейских званий США, включающее следующие значения: Private, Corporal, Sergeant
Вывести все значения из перечисления.
Добавить значение Major после Sergeant в перечисление
Создать таблицу личного состава с колонками: person_id, first_name, last_name, person_rank (типа перечисления)
Добавить несколько записей, вывести все записи из таблицы
*/

CREATE TYPE army_rank AS ENUM ('Private', 'Corporal', 'Sergeant'); -- создаем перечисление

SELECT enum_range(NULL::army_rank); -- выводим перечисление

ALTER TYPE army_rank
ADD value 'Major' AFTER 'Sergeant';

DROP TABLE IF EXISTS personnel;
CREATE TABLE personnel (
	person_id serial PRIMARY KEY,
	first_name text,
	last_name text,
	person_rank army_rank
	);

SELECT * FROM personnel;

INSERT INTO  personnel(first_name, last_name, person_rank)
VALUES 
('Donald','Boyd','Private'),
('Alonzo','Duncan','Sergeant')
('Alonzo','Duncan','bla bla bla');

SELECT * FROM personnel;

INSERT INTO  personnel(first_name, last_name, person_rank)
VALUES 
('Alonzo','Duncan','bla bla bla') -- Перечисление 'bla bla bla' не существует






