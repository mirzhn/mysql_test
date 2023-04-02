use work;

drop table if exists log_check_user;
create table if not exists log_check_user (
	dt timestamp not null default current_timestamp,
	iduser int(11) default null,
	idaction int(11) default null,
	incomingparams json default null,
	otherparams json default null,
	message smallint(6) default null
);

alter table log_check_user partition by range(unix_timestamp(dt)) 
(partition log_check_user_20230327 values less than (unix_timestamp('2023-03-27 00:00:00')));


drop procedure if exists pc_add_log_check_user_partition;
delimiter $$
create procedure pc_add_log_check_user_partition(dt_key date)
begin
	set @sql = concat ('alter table log_check_user add partition 
		(partition log_check_user_', date_format(dt_key, '%y%m%d') , ' values less than (unix_timestamp(''' , dt_key, ''')));');
	prepare stmt from @sql;
	execute stmt;
end;

drop procedure if exists pc_drop_log_check_user_partition;
delimiter $$
create procedure pc_drop_log_check_user_partition(partition_name text)
begin
	set @sql = concat('alter table log_check_user drop partition ', partition_name);
	prepare stmt from @sql;
	execute stmt;
end;

/* 
	логика ротации 
	1. нахожу все партиции из information_schema.partitions старше days_before и удаляю в курсоре. 
	2. нахожу все дни от сегодня до days_forward для которых нет партиций и создаю в курсоре. 
*/
drop procedure if exists pc_rotate_log;
delimiter $$
create procedure pc_rotate_log(days_before int, days_forward int)
begin
	declare _isdone boolean default false;
	declare partition_to_drop text;
	declare partition_to_add date;
	declare partitions_to_drop cursor for 
	select 
		partition_name
	from information_schema.partitions p 
	where p.table_name = 'log_check_user'
			and p.partition_description < unix_timestamp(cast(date_sub(now(), interval days_before day) as date));
	
	declare partitions_to_add cursor for 
	with recursive dates_cte as (
		select cast(date_add(now(), interval 1 day) as date)  as generated_date
		union all
		select date_add(generated_date, interval 1 day)
		from dates_cte
		where generated_date < date_add(cast(now() as date), interval days_forward day)
	)
	select generated_date 
	from dates_cte d 
		left join information_schema.partitions p 
			on p.table_name = 'log_check_user'
			and p.partition_description = unix_timestamp(generated_date)
	where p.table_name is null;

	open partitions_to_drop;
	begin
		declare continue handler for not found set _isdone = true;
		loop_list: loop
			fetch partitions_to_drop into partition_to_drop;
			if _isdone then
				leave loop_list;
			end if;
		call pc_drop_log_check_user_partition(partition_to_drop);
		end loop loop_list;
	end;
	close partitions_to_drop;
	
	set _isdone := false;
	
	open partitions_to_add;
	begin
		declare continue handler for not found set _isdone = true;
		add_loop_list: loop
			fetch partitions_to_add into partition_to_add;
			if _isdone then
				leave add_loop_list;
			end if;
		call pc_add_log_check_user_partition(partition_to_add);
		end loop add_loop_list;
	end;
	close partitions_to_add;
end;

drop event if exists rotate_log;
create event rotate_log
on schedule every 1 day
starts '2023-04-03 00:00:00'
do
  call pc_rotate_log(14, 5);