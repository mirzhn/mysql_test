use work;

create table if not exists operations_by_date (
	dt date not null,
	id_user int(11) unsigned not null,
	id_type_oper smallint(6) unsigned not null,
	amount_oper decimal(19, 5) not null comment 'сумма операции в валюте пользователя (учитывая знак)',
	primary key (dt, id_user, id_type_oper)
)
engine = innodb;

truncate table operations_by_date;

drop procedure if exists pc_aggregate_operations;
delimiter $$
create procedure pc_aggregate_operations(dt_aggregate date)
begin
	delete from operations_by_date 
	where dt = dt_aggregate;
	
	insert into operations_by_date(dt, id_user, id_type_oper, amount_oper)
	select 
		dt_aggregate, id_user, id_type_oper, sum(amount_oper * move)
	from operations op 
	where op.dt >= dt_aggregate 
		and op.dt < date_add(dt_aggregate, interval 1 day)
	group by id_user, id_type_oper;
end;

delimiter ;
call pc_aggregate_operations('2023-03-29');
call pc_aggregate_operations('2023-03-30');
call pc_aggregate_operations('2023-03-31');

drop event if exists aggregate_operations;
create event aggregate_operations
on schedule every 1 day
starts '2023-04-03 00:00:00'
do
	call pc_aggregate_operations(date_add(cast(now() as date), interval -1 day));
