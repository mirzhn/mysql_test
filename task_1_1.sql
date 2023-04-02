use work;

alter table operations add index ix_operations_dt_id_user_id_type_oper_sum (dt, id_user, id_type_oper, (amount_oper * move));
alter table users add index ix_users_id_user_id_country_id_currency (id_user, id_country, id_currency); 


drop procedure if exists pc_get_operations_report;
delimiter $$
create procedure pc_get_operations_report(dt_start datetime, dt_end datetime)
begin
	with cte_operations as 
	(
		select 
			op.id_user, op.id_type_oper, sum((op.amount_oper * move)) amount_oper 
		from operations op 
		where op.dt between dt_start and dt_end
		group by op.id_user, op.id_type_oper
	)
	select 
		coalesce(c.name_country, 'total') name_country,
		coalesce(t.name_oper, 'total') name_oper,
		sum((op.amount_oper) / cr.base_rate) total_sum, 
		sum((op.amount_oper) * (t.comission / 100) / cr.base_rate) total_comission, 
		sum((op.amount_oper) * (1 - t.comission / 100) / cr.base_rate) total_without_comission
	from cte_operations op 
		inner join users u 
			on u.id_user = op.id_user
		inner join type_opers t
			on t.id_type_oper = op.id_type_oper
		inner join countries c 
			on c.id_country = u.id_country
		inner join currencies cr 
			on cr.id_currency = u.id_currency
	group by c.name_country, t.name_oper
	with rollup;
end;

delimiter ;

call pc_get_report_by_date('2023-03-28 14:00:00', '2023-04-01 14:00:00');
