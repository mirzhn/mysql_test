create database if not exists work; 
use work;

create table if not exists currencies (
	id_currency smallint(6) unsigned not null auto_increment,
	name_currency varchar(255) default null,
	base_rate decimal(15, 5) default null comment 'курс к рублю',
	primary key (id_currency)
)
engine = innodb;

create table if not exists countries (
	id_country smallint(6) unsigned not null auto_increment,
	name_country varchar(50) default null,
	primary key (id_country)
)
engine = innodb;

create table if not exists type_opers (
	id_type_oper smallint(6) unsigned not null auto_increment,
	name_oper varchar(255) default null,
	comission decimal(5, 2) default null comment 'процент комиссии за операцию',
	primary key (id_type_oper)
)
engine = innodb;

create table if not exists users (
	id_user int(11) unsigned not null auto_increment,
	id_currency smallint(6) unsigned not null,
	id_country smallint(6) unsigned not null,
	primary key (id_user)
)
engine = innodb;

create table if not exists operations (
	id_operation bigint(20) unsigned not null auto_increment,
	dt timestamp not null default current_timestamp,
	id_user int(11) unsigned not null,
	id_type_oper smallint(6) unsigned not null,
	move tinyint(4) not null comment 'направление движения (-1 - со счёта, 1 - на счёт)',
	amount_oper decimal(19, 5) not null comment 'сумма операции в валюте пользователя',
	primary key (id_operation)
)
engine = innodb;

create table if not exists log_check_user (
	dt timestamp not null default current_timestamp,
	iduser int(11) default null,
	idaction int(11) default null,
	incomingparams json default null,
	otherparams json default null,
	message smallint(6) default null
)