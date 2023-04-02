use work;

alter table operations add index ix_operations_dt_type_oper (dt, id_type_oper);

drop procedure if exists pc_get_rank_oper_type;
delimiter $$
create procedure pc_get_rank_oper_type(dt_start datetime, dt_end datetime)
begin
	select @rn := 0;
	select 
		name_oper, 
		(@rn := @rn + 1) rnk
	from (
		select 
			t.name_oper
		from operations op 
			inner join type_opers t
				on t.id_type_oper = op.id_type_oper
		where op.dt between dt_start and dt_end
		group by t.name_oper
		order by count(*) desc
	) sq; 
end;

delimiter ;

call pc_get_rank_oper_type('2023-03-30', '2023-03-31');