-- 1
create user 'user_juillet2023'@'localhost' identified by 'juillet2023';

grant create temporary tables on ue219_juillet2023.* to 'user_juillet2023'@'localhost';
grant execute on procedure procedure_juillet2023 to 'user_juillet2023'@'localhost';

drop temporary table fact_intervention;
drop temporary table montant_par_societe;

create temporary table fact_intervention (
	idclient int, 
	nomprenomclient varchar(81),
	idtechnicien int,
	intitule_societe varchar(50),
	date_deb_intervention datetime,
	duree_intervention time,
	totalapayer numeric(7,2)
); 
	
create temporary table montant_par_societe (
	idsociete smallint, 
);

drop procedure procedure_juillet2023;
delimiter |
create procedure procedure_juillet2023(in idTech int, in dateDebutInter datetime) sql security invoker
begin
	declare salaireHorBaseTech numeric(7,2);
	declare dureeIntSec int;
	declare dureeIntHeures numeric(4,2);
	declare pourc numeric(5,2);
	declare typeDeCarte varchar(6);
	declare total numeric(7,2);
	
	set salaireHorBaseTech = (select salaire_horaire_base from fonction inner join technicien using(idfonction) where idTech = technicien.idtech);	
	set pourc = (select pourcentage from societe inner join technicien using(idsociete) where idTech = technicien.idtech);	
	set typeDeCarte = (select typecarte from client inner join intervention using(idcli) where idTech = intervention.idtech and dateDebutInter = intervention.date_debut_intervention);
		
	set dureeIntSec = timestampdiff(second, dateDebutInter, (select date_fin_intervention from intervention where date_debut_intervention = dateDebutInter));
	set dureeIntHeures = dureeIntSec / 3600;
	set total = salaireHorBaseTech * dureeIntHeures * pourc;
	case typeDeCarte 
		when 'or' then set total = total * 0.9; 
		when 'argent' then set total = total * 0.95; 
		when 'bronze' then set total = total * 0.98; 
	end case;
	
	if (month(dateDebutInter) = 4) then
		set total = total * 0.95;
	end if;
	
	insert into fact_intervention(idclient, nomprenomclient, idtechnicien, intitule_societe, date_deb_intervention, duree_intervention, totalapayer) values (
		(select idcli from intervention where date_debut_intervention = dateDebutInter),
		(select concat(nomcli, ' ', prenomcli) from client inner join intervention using(idcli) where intervention.date_debut_intervention = dateDebutInter),
		(select idTechnicien),
		(select intitulesociete from societe inner join technicien using(idsociete) where technicien.idtech = idTechnicien),
		(select dateDebutInter),
		(select sec_to_time(timestampdiff(second, (select dateDebutInter), (select date_fin_intervention from intervention where idtech = (select idTechnicien))))),	
		(select total)
	);
	
	insert into montant_par_societe(idsociete) values (
		(select idsociete from societe)
	);
end |
delimiter ;

call procedure_juillet2023(1, '2023-05-10 10:32:00');
call procedure_juillet2023(2, '2023-05-15 11:00:00');
call procedure_juillet2023(3, '2023-05-12 08:30:00');
call procedure_juillet2023(4, '2023-04-25 10:00:00');
select * from fact_intervention;
select * from montant_par_societe;

-- 2
drop table nombre_clients_par_carte;
create table if not exists nombre_clients_par_carte(
	intitule_carte varchar(8) not null,
	nombre_de_clients tinyint not null
);

drop trigger beforeInsertClient;
delimiter |
create trigger beforeInsertClient before insert on client
for each row
begin
	if new.typecarte != 'or' and new.typecarte != 'argent' and new.typecarte != 'bronze' then
		set new.typecarte = 'inconnue';
	end if;
end |
delimiter ;

drop trigger afterInsertClient;
delimiter |
create trigger afterInsertClient after insert on client
for each row
begin
	if (select count(*) from nombre_clients_par_carte where intitule_carte = new.typecarte) = 0 then
		insert into nombre_clients_par_carte(intitule_carte, nombre_de_clients) values (new.typecarte, 1);
	else
		update nombre_clients_par_carte set nombre_de_clients = nombre_de_clients + 1 where intitule_carte = new.typecarte;
	end if;
end |
delimiter ;

drop trigger beforeUpdateClient;
delimiter |
create trigger beforeUpdateClient before update on client
for each row
begin
	if new.typecarte != 'or' and new.typecarte != 'argent' and new.typecarte != 'bronze' then
		if old.typecarte = 'or' or old.typecarte = 'argent' or old.typecarte = 'bronze' then
			set new.typecarte = old.typecarte;
		else
			set new.typecarte = 'inconnue';
		end if;
	else
		update nombre_clients_par_carte set nombre_de_clients = nombre_de_clients + 1 where intitule_carte = new.typecarte;
		if (select nombre_de_clients from nombre_clients_par_carte where intitule_carte = old.typecarte) - 1 = 0 then
			delete from nombre_clients_par_carte where intitule_carte = old.typecarte;	
		else
			update nombre_clients_par_carte set nombre_de_clients = nombre_de_clients - 1 where intitule_carte = old.typecarte;
		end if;
		if (select count(*) from nombre_clients_par_carte where intitule_carte = new.typecarte) = 0 then
			insert into nombre_clients_par_carte(intitule_carte, nombre_de_clients) values (new.typecarte, 1);
		end if;
	end if;
end |
delimiter ;

start transaction;
	insert into client(idcli, nomcli, prenomcli, typecarte) values 
	(15, 'Potter', 'Harry', 'or'),
	(16, 'Weasley', 'Ron', 'argile'),
	(17, 'Granger', 'Hermione', 'argent'),
	(18, 'Dumbeldore', 'Albus', 'or'),
	(19, 'Rogue', 'Severus', 'bronze');
	update client set typecarte = 'bronze' where idcli = 17;
	select * from nombre_clients_par_carte;
	update client set typecarte = 'argile' where idcli = 15;
	update client set typecarte = 'argent' where idcli = 18;
	select * from client;
	select * from nombre_clients_par_carte;
rollback;