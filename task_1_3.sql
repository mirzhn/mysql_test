use work;

drop procedure if exists pc_get_operations_report;
DELIMITER $$
CREATE PROCEDURE pc_get_operations_report(dt_start datetime, dt_end datetime)
BEGIN
	with cte_borders as 
    (
		select 
			if (dt_start > cast(dt_start as date), dt_start, null) dt_detail_start, 
			if (dt_end > cast(dt_end as date), dt_end, null) dt_detail_end, 
			if (dt_start > cast(dt_start as date), DATE_ADD(cast(dt_start as date), INTERVAL 1 DAY), cast(dt_start as date)) dt_aggregate_start,
			if (dt_end > cast(dt_end as date), DATE_ADD(cast(dt_end as date), INTERVAL -1 DAY), cast(dt_end as date)) dt_aggregate_end
	),	cte_operations as 
	(
		select 
			op.id_user, op.id_type_oper, sum((op.amount_oper * move)) amount_oper 
		from operations op 
			inner join cte_borders cdb 
				on (op.dt >= dt_detail_start and op.dt < dt_aggregate_start) 
				or (op.dt > dt_aggregate_end and op.dt <= dt_detail_end) 
		group by op.id_user, op.id_type_oper
		union all 
		select 
			op.id_user, op.id_type_oper, sum((op.amount_oper)) amount_oper 
		from operations_by_date op 
		where op.dt between dt_aggregate_start and dt_aggregate_end
		group by op.id_user, op.id_type_oper
	)
	select 
		coalesce(c.name_country, 'total') name_country,
		coalesce(t.name_oper, 'total') name_oper,
		sum((op.amount_oper)) total_sum, 
		sum((op.amount_oper) * (t.comission / 100)) total_comission, 
		sum((op.amount_oper) * (1 - t.comission / 100) / cr.base_rate) total_without_comission_ruble
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
END;

DELIMITER ;
call pc_get_report_by_date('2023-03-28 14:00:00', '2023-04-01 14:00:00');

