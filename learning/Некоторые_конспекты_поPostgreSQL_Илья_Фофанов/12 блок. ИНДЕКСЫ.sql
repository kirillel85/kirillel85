--======================================================================
-- Конспект урока 12.0 ИНДЕКСЫ
--======================================================================

-- Список всех индексов в Postgres
SELECT amname FROM pg_am;

-- Команда запроса к планировщику о том как долго он собирается производить данный query.
-- И сколько COST-ов (ресурсов) эта операция будет стоить. 
-- COST это сумма затрат с диском и CPU. Измеряется в единицах обращения к страницам данной таблицы в БД
EXPLAIN query

EXPLAIN 
	SELECT *
    FROM orders
    
EXPLAIN ANALYZE показывает тоже что и оператор EXPLAIN + еще и показывает реальность

EXPLAIN ANALYZE
	SELECT *
    FROM orders
    
-- ========================================================================================
-- =======================			Создаём таблицу с большими данными			==============================
  
  CREATE TABLE perf_test(
  	id int, 
  	reason text COLLATE "C",  -- Использовать побайтовое сравнение латницы. Так и не понял что это такое
  	annotation text COLLATE "C"
  	);
  
  -- Генерируем данные в таблицу
  
INSERT INTO perf_test (id, reason, annotation)
	SELECT s.id, md5(random()::text), NULL -- md5 это шифровальная функция.   random()::text -  генерирует рандомные значения из шифровальной функции и сразу переводит их в текст
	FROM generate_series(1, 20000000) AS s(id) 
	ORDER BY random();
/* 
Строка s(id) в выражении FROM generate_series(1, 10000) AS s(id) указывает, что мы используем функцию generate_series для создания ряда чисел от 1 до 10000,
а затем присваиваем этому ряду псевдоним s с именем столбца id. Таким образом, после выполнения этого запроса у нас будет временная таблица 
с одним столбцом id, содержащим значения от 1 до 10000. 
Мы можем использовать эту временную таблицу для выполнения других операций, например, для вставки этих значений в другую таблицу.
*/ 

-- отдельно обновляем колонку annotation
UPDATE perf_test
SET annotation = upper(md5(random()::text));
  
-- ===============================================================================================
-- =======================	12.5 Индексы - ОДНОСОСТАВНАЯ ВЫБОРКА			=====================================

SELECT * FROM perf_test LIMIT 50;
SELECT count(*) FROM perf_test;

EXPLAIN SELECT * FROM perf_test WHERE id = 9999000;  -- 19 сек до индекса
EXPLAIN ANALYZE SELECT * FROM perf_test WHERE id = 19999000; -- 20 сек до индекса

-- Строим индекс по одному столбцу. 
CREATE INDEX idx_perf_test_id ON perf_test(id); -- Строительство индекса на 20 млн строк заняло 39 сек (на SSD диске)
  
EXPLAIN SELECT * FROM perf_test WHERE id = 9999000; -- 0.001s после индекса. ОХРЕНЕННО
EXPLAIN ANALYZE SELECT * FROM perf_test WHERE id = 19999000;  -- 0.113s.  ОХРЕНЕННО. Все работает
-- Index Scan using idx_perf_test_id on perf_test  (cost=0.44..8.46 rows=1 width=70) (actual time=0.086..0.087 rows=0 loops=1)
-- Index Cond: (id = 19999000)
-- Planning Time: 7.839 ms
-- Execution Time: 0.113 ms
  
-- ==============================================================================================
-- =======================	12.5 Индексы  ДВУСОСТАВНАЯ ВЫБОРКА			=====================================

SELECT * FROM perf_test WHERE reason LIKE 'bc%'; -- выводит за 19s

SELECT * FROM perf_test WHERE reason LIKE 'bc%' AND annotation LIKE 'AB%'; -- выводит за 20s

  -- Строим двусоставной индекс по двум полям
CREATE INDEX idx_perf_test_reason_annotation ON perf_test(reason, annotation);

SELECT * FROM perf_test WHERE reason LIKE 'bc%'; -- в первый раз почему то вывел за 15сек, а во второй кэшированый раз за 0,026с
EXPLAIN SELECT * FROM perf_test WHERE reason LIKE 'bc%'; -- пишет что индекс висит и что все норм
EXPLAIN ANALYZE SELECT * FROM perf_test WHERE reason LIKE 'bc%'; -- 
-- Index Scan using idx_perf_test_reason_annotation on perf_test  (cost=0.56..283849.45 rows=202020 width=70) (actual time=0.100..689.664 rows=77887 loops=1)
-- Index Cond: ((reason >= 'bc'::text) AND (reason < 'bd'::text))
-- Filter: (reason ~~ 'bc%'::text)
-- Planning Time: 0.099 ms
-- Execution Time: 693.144 ms
  
SELECT * FROM perf_test WHERE reason LIKE 'bc%' AND annotation LIKE 'AB%'; -- 0,025с
EXPLAIN ANALYZE SELECT * FROM perf_test WHERE reason LIKE 'bc%' AND annotation LIKE 'AB%'; 
-- Index Scan using idx_perf_test_reason_annotation on perf_test  (cost=0.56..5495.93 rows=2041 width=70) (actual time=0.072..9.079 rows=288 loops=1)
-- Index Cond: ((reason >= 'bc'::text) AND (reason < 'bd'::text) AND (annotation >= 'AB'::text) AND (annotation < 'AC'::text))
-- Filter: ((reason ~~ 'bc%'::text) AND (annotation ~~ 'AB%'::text))
-- Planning Time: 0.107 ms
-- Execution Time: 9.111 ms

-- УХХ МОЩЩА  !!!!!

-- ==============================================================================================
-- =======================	12.6 Индексы  По выражениям			=====================================
-- Индексы по выражениям (по функциям применённым к выражениям) автоматически не работают

EXPLAIN
SELECT *
FROM perf_test AS pt 
WHERE pt.annotation LIKE 'AB%'; --24 s
  

CREATE INDEX idx_perf_test_annotation ON perf_test(annotation); -- 1m 9s на 20 млн строк

EXPLAIN
SELECT *
FROM perf_test AS pt 
WHERE pt.annotation LIKE 'AB%'; --0.8 s  в 30 раз быстрее

-- А теперь  проводим поиск через функцию lower() по индексу annotation
EXPLAIN
SELECT *
FROM perf_test AS pt 
WHERE LOWER(annotation) LIKE 'ab%';  
/*  Результат
Index Scan using idx_perf_test_annotation_lower on perf_test pt  (cost=0.56..390296.56 rows=100000 width=70)
  Index Cond: ((lower(annotation) >= 'ab'::text) AND (lower(annotation) < 'ac'::text))
  Filter: (lower(annotation) ~~ 'ab%'::text)
*/

 -- Для того что бы это исправить нужно создать индекс по этому конкретному выражению
CREATE INDEX idx_perf_test_annotation_lower ON perf_test(LOWER(annotation)); -- 1m 8s на 20 млн строк

EXPLAIN 
SELECT *
FROM perf_test
WHERE LOWER(annotation) LIKE 'ab%';
 /*  Результат. (Что то не работает)  Какие то изменения в поздних версиях похоже
  Index Scan using idx_perf_test_annotation_lower on perf_test pt  (cost=0.56..390296.56 rows=100000 width=70)
  Index Cond: ((lower(annotation) >= 'ab'::text) AND (lower(annotation) < 'ac'::text))
  Filter: (lower(annotation) ~~ 'ab%'::text)
  */
  
-- ==============================================================================================
-- =======================	12.7 Индексы. "Сложный" индекс для поиска по тексту	=====================================
-- 12.7 "Сложный" индекс для поиска по тексту. GIST or  GIN.
--  Поиск по триграммам


EXPLAIN 
SELECT *
FROM perf_test
WHERE reason LIKE '%bc%'; --Поиск по двуграмме '%bc%'

-- Подключаем  расширение
CREATE EXTENSION pg_trgm;
  
CREATE INDEX trgm_idx_perf_test_reason ON perf_test USING gin (reason gin_trgm_ops);
  
-- Если выборка большая, то планировщик может переключится с индекса на таблицу. Тоесть не использовать индекс вообще.
    
-- Поиск по треграмме
EXPLAIN 
SELECT *
FROM perf_test
WHERE reason LIKE '%abc%'; --Поиск по триграмме '%abc%' 2.018s
/* -- Работает
 * Bitmap Heap Scan on perf_test  (cost=163.69..7947.27 rows=2000 width=70)
  Recheck Cond: (reason ~~ '%abc%'::text)
  ->  Bitmap Index Scan on trgm_idx_perf_test_reason  (cost=0.00..163.19 rows=2000 width=0)
        Index Cond: (reason ~~ '%abc%'::text)
 */
EXPLAIN 
SELECT *
FROM perf_test
WHERE reason LIKE '%bc%'; -- Поиск по двуграмме '%bc%'  35 секунд
/* 
 Seq Scan on perf_test  (cost=0.00..1525400.00 rows=2222222 width=70)
  Filter: (reason ~~ '%bc%'::text)
 */




