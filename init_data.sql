use work;

truncate table operations; 
truncate table users; 
truncate table type_opers; 
truncate table currencies; 
truncate table countries; 


insert into type_opers (name_oper, comission)
values
    ('deposit', 0.00),
    ('withdrawal', 1.50),
    ('transfer', 0.50),
    ('currency exchange', 2.00),
    ('payment', 1.00);

insert into currencies (name_currency, base_rate)
values
    ('us dollar', 0.0135),
    ('euro', 0.0113),
    ('british pound', 0.0097),
    ('japanese yen', 1.48),
    ('canadian dollar', 0.0172),
    ('australian dollar', 0.0181),
    ('swiss franc', 0.0124),
    ('chinese yuan', 0.0881),
    ('hong kong dollar', 0.1051),
    ('singapore dollar', 0.0183),
    ('new zealand dollar', 0.0197),
    ('south korean won', 15.75),
    ('taiwan dollar', 0.38),
    ('indian rupee', 1.0022),
    ('swedish krona', 0.1159),
    ('norwegian krone', 0.1181),
    ('danish krone', 0.0838),
    ('russian ruble', 1);


insert into countries (name_country)
values
    ('china'),
    ('india'),
    ('united states'),
    ('indonesia'),
    ('pakistan'),
    ('brazil'),
    ('nigeria'),
    ('bangladesh'),
    ('russia'),
    ('mexico'),
    ('japan'),
    ('ethiopia'),
    ('philippines'),
    ('egypt'),
    ('vietnam'),
    ('dr congo'),
    ('turkey'),
    ('iran'),
    ('germany'),
    ('thailand'),
    ('united kingdom'),
    ('france'),
    ('tanzania'),
    ('italy'),
    ('south africa'),
    ('myanmar'),
    ('kenya'),
    ('south korea'),
    ('colombia'),
    ('spain');
    
set @@cte_max_recursion_depth = 10000000;

insert into users (id_currency, id_country)
with recursive iterator(n) as (
    select 1
    union all
    select n+1 from iterator where n < 10000
)
select 
	ceiling(rand()*(select max(id_currency) from currencies)) id_currency,
    ceiling(rand()*(select max(id_country) from countries)) id_country
from iterator;

drop procedure if exists pc_generate_operations;
delimiter $$
create procedure pc_generate_operations(dt_start date, dt_end date, rows_in_day int)
begin
	while (dt_start <= dt_end) do

	insert into operations(dt, id_user, id_type_oper, move, amount_oper)
	with recursive iterator(n) as (
		select 1
		union all
		select n+1 from iterator where n < rows_in_day
	)
	select dt, id_user, id_type_oper, move, amount_oper
	from 
	(
		select 
			timestampadd(second, floor(rand()*86400), dt_start) dt,
			ceiling(rand()*(select max(id_user) from users)) id_user,
			ceiling(rand()*(select max(id_type_oper) from type_opers)) id_type_oper, 
			sign(rand()-0.5)*1 move,
			round(rand()*10000, 5) as amount_oper,
			row_number() over() rn 
		from iterator
	) rn 
	where rn < ((rows_in_day * 0.1) + ceiling(rand()*(rows_in_day * 0.9)));
      
	set dt_start := date_add(dt_start, interval 1 day);
	end while;
end$$;

delimiter ;
call pc_generate_operations('2023-03-27', '2023-04-02', 500000);












