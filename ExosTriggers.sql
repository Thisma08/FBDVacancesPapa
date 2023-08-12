-- P1
-- 1
drop table article_log;
create table article_log like article;
alter table article_log add column type_evenement char(6) not null;
alter table article_log add column date_operation datetime not null;
alter table article_log drop primary key;

drop trigger after_update_article;
delimiter |
create trigger after_update_article after update on article
for each row
begin 
	insert into article_log(prixvente, coutrevient, id, libelle, type_evenement, date_operation) values (old.prixvente, old.coutrevient, old.id, old.libelle, 'Update', now());
end |
delimiter ;

drop trigger after_delete_article;
delimiter |
create trigger after_delete_article after delete on article
for each row
begin 
	insert into article_log(prixvente, coutrevient, id, libelle, type_evenement, date_operation) values (old.prixvente, old.coutrevient, old.id, old.libelle, 'Delete', now());
end |
delimiter ;

start transaction; 
update article set prixvente = 6.05, coutrevient = 2.1 where id = 1;
delete from article where id = 2 or id = 10;
select * from article_log;
select * from article;
rollback;

-- P2
-- 1
drop trigger before_insert_evenement;
delimiter |
create trigger before_insert_evenement before insert on evenement
for each row
begin
    if new.dateevent < now()
	    then set new.dateevent = now(); 
    end if;
	if new.dateevent > date_add(now(), interval 1 year)
		then set new.dateevent = date_add(now(), interval 1 year);
	end if;
end |
delimiter ;

start transaction;
insert into evenement(dateevent, nomevent, id) values ('2023-07-01 12:00:00', 'Ancien événement', 2);
insert into evenement(dateevent, nomevent, id) values ('2023-08-31 12:00:00', 'Evénement OK', 4);
insert into evenement(dateevent, nomevent, id) values ('2026-07-19 12:00:00', 'Trop loin événement', 5);
select * from evenement;
rollback;

-- 2
drop trigger before_insert_detailachat
delimiter |
create trigger before_insert_detailachat before insert on detailachat
for each row
begin
	declare s tinyint unsigned;
	declare qAct tinyint unsigned;
	select sum(quantite) into qAct from detailachat where idart = new.idart;
	set s = qAct + new.quantite;
	if new.quantite > 10 then
		set new.quantite = 10;
	end if;    
	if qAct < 10 then
		if s > 10 then
			set new.quantite = s - new.quantite;
		end if;
	end if;
end |	
delimiter ; 

-- 3
drop table facture;
create table facture like achat;
alter table facture drop primary key;
alter table facture add date_paiement date;

drop trigger after_insert_achat;
delimiter |
create trigger after_insert_achat after insert on achat
for each row
begin 
	declare dP date;
	set dP = date_add(new.dateachat, interval 1 month);
	set dP = last_day(dP);
	while(dayofweek(dP) != 7) do
        set dP = date_add(dP, interval -1 day);
    end while;
	insert into facture(dateachat, remise, id, numcli, date_paiement) values (new.dateachat, new.remise, new.id, new.numcli, (select dP));
end |
delimiter ;

start transaction;
	insert into achat(dateachat, remise, id, numcli) values ("2020-02-10 13:15:00", 0.1, 1, 1);
	insert into achat(dateachat, remise, id, numcli) values ("2020-01-20 13:15:00", 0.1, 1, 1);
	select * from facture;
rollback;
start transaction;
	insert into achat(id, numcli, dateachat, remise) values (1, 1, '2020-02-10 13:35:00', 0.1);
	select * from facture_bis;
rollback;