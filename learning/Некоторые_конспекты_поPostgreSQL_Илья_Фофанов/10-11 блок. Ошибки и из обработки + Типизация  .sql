
--======================================================================
-- 10. ДЗ.  Ошибки и из обработки
--======================================================================
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
 
