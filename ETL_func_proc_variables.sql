-- ETL Exercises 1
-- 1. Create a procedure for adding a new employee, with the required list of input parameters. 
-- After the procedure has successfully run, the data should end up in the employees, dept_emp, salaries, and titles tables; 
-- Calculation of emp_no, calculated by the formula max(emp_no)+1. 
-- If a non-existing position is inserted, then show an error with the desired text. 
-- If the transferred salary is less than 30000, then show an error with the desired text.


DELIMITER $$

CREATE PROCEDURE emp_add (in p_birth_date date,
						in p_first_name varchar(14),
						in p_last_name varchar(16),
						in p_gender enum('M','F'),
						in p_hire_date date,
						in d_dept_no char(4),
						in d_from_date date,
						in d_to_date date,
                        in s_salary int,
						in s_from_date date,
						in s_to_date date,
                        in t_title varchar(50),
						in t_from_date date,
						in t_to_date date)                            

BEGIN
-- If a non-existing position is inserted, then show an error with the desired text. 
SET @err = (select count(title) from titles WHERE title = t_title);
IF @err = 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'This position does not exist';
END IF;

-- If the transferred salary is less than 30000, then show an error with the desired text. 
IF s_salary < 30000 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'Salary is less than 30000';
END IF;
				-- employees
                SET @emp_no = (SELECT MAX(emp_no) FROM employees.employees) + 1;
                INSERT INTO employees.employees (emp_no, birth_date, first_name, last_name, gender, hire_date) 
                VALUES(@emp_no, p_birth_date, p_first_name, p_last_name, p_gender, p_hire_date);
				SELECT * FROM employees.employees;
                -- dept_emp
                INSERT INTO employees.dept_emp (emp_no, dept_no, from_date, to_date) 
                VALUES(@emp_no, d_dept_no, d_from_date, d_to_date);
				SELECT * FROM employees.dept_emp;
                -- salaries
                INSERT INTO employees.salaries (emp_no, salary, from_date, to_date) 
                VALUES(@emp_no, s_salary, s_from_date, s_to_date);
				SELECT * FROM employees.salaries;
                --  titles
                INSERT INTO employees.titles (emp_no, title, from_date, to_date) 
                VALUES(@emp_no, t_title, t_from_date, t_to_date);
				SELECT * FROM employees.titles;



END$$

DELIMITER ;

CALL emp_add ('1989-07-15', 'Anna', 'Deryaz', 'F', curdate(), 'd005', curdate(), '9999-01-01', 60700, curdate(), DATE_ADD(curdate(), INTERVAL 1 YEAR), 'Senior Engineer', curdate(), DATE_ADD(curdate(), INTERVAL 1 YEAR));
-- error1
CALL emp_add ('1989-07-15', 'Anna', 'Deryaz', 'F', curdate(), 'd005', curdate(), '9999-01-01', 60700, curdate(), DATE_ADD(curdate(), INTERVAL 1 YEAR), 'hqqqo', curdate(), DATE_ADD(curdate(), INTERVAL 1 YEAR));
-- error2
CALL emp_add ('1989-07-15', 'Anna', 'Deryaz', 'F', curdate(), 'd005', curdate(), '9999-01-01', 607, curdate(), DATE_ADD(curdate(), INTERVAL 1 YEAR), 'Senior Engineer', curdate(), DATE_ADD(curdate(), INTERVAL 1 YEAR));

SELECT  @err;

-- 2. Create a procedure to update the salary for an employee. When updating the salary, you need to close the last active record with the current date, 
-- and create a new historical record with the current date. 
-- If non-existing employee is inserted, then show an error with the desired text.

DELIMITER $$

CREATE PROCEDURE sal_update (in s_emp_no int, 
							in s_salary int)                            

BEGIN
SET @er = (select count(emp_no) from salaries WHERE emp_no = s_emp_no);
IF @er = 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'This employee does not exist';
END IF;

				UPDATE employees.salaries 
				SET to_date = curdate()
                WHERE emp_no = s_emp_no and curdate() BETWEEN from_date AND to_date;
                
                INSERT INTO employees.salaries (emp_no, salary, from_date, to_date) 
                VALUES(s_emp_no, s_salary, curdate(), '9999-01-01');
				SELECT * FROM employees.salaries
				WHERE emp_no = s_emp_no;

END$$

DELIMITER ;

CALL sal_update (10050, 60000);
CALL sal_update (101, 60000); -- error

-- 3. Create a procedure to fire an employee, closing historical records in the dept_emp, salaries and titles tables. 
--- If a non-existent employee number is inserted, then show an error with the required text.

DELIMITER $$

CREATE PROCEDURE emp_fired (in f_emp_no int)                            

BEGIN
SET @e = (select count(emp_no) from salaries WHERE emp_no = f_emp_no);
IF @e = 0 THEN
SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT = 'This employee does not exist';
END IF;
				-- dept_emp
                UPDATE employees.dept_emp 
				SET to_date = curdate()
                WHERE emp_no = f_emp_no and curdate() BETWEEN from_date AND to_date;
                SELECT * FROM employees.dept_emp
				WHERE emp_no = f_emp_no;
                -- salaries
				UPDATE employees.salaries 
				SET to_date = curdate()
                WHERE emp_no = f_emp_no and curdate() BETWEEN from_date AND to_date;
                SELECT * FROM employees.salaries
				WHERE emp_no = f_emp_no;
                --  titles
                UPDATE employees.titles 
				SET to_date = curdate()
                WHERE emp_no = f_emp_no and curdate() BETWEEN from_date AND to_date;
                SELECT * FROM employees.titles
				WHERE emp_no = f_emp_no;

END$$

DELIMITER ;
CALL emp_fired (10001);
CALL emp_fired (1001); -- error

-- 4. Create a function that would display the current salary for an employee.

DELIMITER $$
CREATE FUNCTION get_emp_sal (s_emp_no INTEGER) RETURNS INTEGER
DETERMINISTIC

BEGIN
		DECLARE curr_sal INTEGER;

		SELECT salary    
        INTO curr_sal
        FROM employees.salaries
        WHERE curdate() BETWEEN from_date AND to_date
        AND emp_no = s_emp_no;   
        
        RETURN curr_sal;
        
END $$

DELIMITER ;
SELECT get_emp_sal (10040);
