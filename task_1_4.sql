use work;

drop procedure if exists pc_get_operations_report_by_user;
delimiter $$
create procedure pc_get_operations_report_by_user(dt_start datetime, dt_end datetime, p_id_user int)
begin
	select 
        coalesce(t.name_oper, 'total') name_oper, 
        sum((op.amount_oper * move)) amount_oper 
	from operations op 
		inner join type_opers t
			on t.id_type_oper = op.id_type_oper
	where op.dt between dt_start and dt_end
		and op.id_user = p_id_user
	group by t.name_oper
	with rollup;
end;

delimiter ;

call pc_get_operations_report_by_user('2023-03-30', '2023-03-31', 370);

