--======================================================================
-- 15 блок. Продвинутые группировки
--======================================================================

SELECT employee_id, sum(unit_price * quantity)
FROM orders AS o 
LEFT JOIN   order_details USING(order_id)

--======================================================================
-- 15 блок. ДЗ. Продвинутые группировки
--======================================================================
/* Вывести сумму продаж (цена * кол-во) по каждому сотруднику с подсчётом полного итога (полной суммы по всем сотрудникам) отсортировав по сумме продаж (по убыванию).*/

SELECT employee_id, sum(unit_price * quantity)
FROM orders AS o 
LEFT JOIN   order_details USING(order_id)
GROUP BY ROLLUP(o.employee_id)

/*Вывести отчёт показывающий сумму продаж по сотрудникам и странам отгрузки с подытогами по сотрудникам и общим итогом.*/

SELECT employee_id, ship_country, sum(unit_price * quantity)
FROM orders AS o 
LEFT JOIN   order_details USING(order_id)
GROUP BY ROLLUP(o.employee_id, ship_country)
ORDER BY employee_id, SUM(unit_price * quantity) DESC;

/*Вывести отчёт показывающий сумму продаж по сотрудникам, странам отгрузки, сотрудникам и странам отгрузки с подитогами по сотрудникам и общим итогом.*/

SELECT employee_id, ship_country, sum(unit_price * quantity)
FROM orders AS o 
LEFT JOIN   order_details USING(order_id)
GROUP BY CUBE(o.employee_id, ship_country)
ORDER BY employee_id, SUM(unit_price * quantity) DESC;



