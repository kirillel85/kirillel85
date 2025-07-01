--======================================================================
-- Конспект урока 13.0 Массивы
--======================================================================


CREATE TABLE chess_game (
    white_player text,
    black_player text,
    moves text[],
    final_state text[][]
);

INSERT INTO chess_game
VALUES ('Caruana', 'Nakamura', ARRAY['d4', 'd5', 'c4', 'c6'],
       ARRAY[
           ['Ra8', 'Qe8', 'x', 'x', 'x', 'x', 'x', 'x'],
           ['a7', 'x', 'x', 'x', 'x', 'x', 'x', 'x'],
           ['Kb5', 'Bc5', 'd5', 'x', 'x', 'x', 'x', 'x']
       ]);
       
SELECT *
FROM chess_game;

--======================================================================
-- ДЗ. Массивы
--======================================================================

--Создать функцию, которая вычисляет средний фрахт по заданным странам (функция принимает список стран). 

CREATE FUNCTION agv_freight(variadic list_of_countres text[]) 
RETURNS float8 AS $$
	SELECT avg(freight)
	FROM orders
	WHERE ship_country = ANY(list_of_countres)
$$ LANGUAGE SQL;

SELECT * FROM orders;

SELECT agv_freight('USA','UK');

SELECT agv_freight(VARIADIC ARRAY['USA','UK']);

--======================================================================
-- ДЗ. Массивы и циклы
--======================================================================
/*
Написать функцию, которая фильтрует телефонные номера по коду оператора.
Принимает 3-х значный код мобильного оператора и список телефонных номеров в формате +1(234)5678901 (variadic)
Функция возвращает только те номера, код оператора которых соответствует значению соответствующего аргумента.
Проверить функцию передав следующие аргументы:
903, +7(903)1901235, +7(926)8567589, +7(903)1532476
Попробовать передать аргументы с созданием массива и без.
Подсказка: чтобы передать массив в VARIADIC-аргумент, надо перед массивом прописать, собственно, ключевое слово variadic.
*/


CREATE OR REPLACE FUNCTION filter_by_operator(oper int, VARIADIC numbers text[]) 
RETURNS SETOF text AS $$
DECLARE
	cur_val text;
BEGIN
	FOREACH cur_val IN ARRAY numbers
	LOOP
		RAISE NOTICE 'cur val is %', cur_val;
		CONTINUE WHEN cur_val NOT LIKE CONCAT('__(', oper, ')%');
		RETURN NEXT cur_val;
	END LOOP;
END
$$ LANGUAGE plpgsql;

SELECT * FROM filter_by_operator(903,'+7(903)1901235','+7(905)1771235', '+7(903)1901565');
SELECT * FROM filter_by_operator(903,VARIADIC ARRAY ['+7(903)1901235','+7(905)1771235', '+7(903)1901565']);

