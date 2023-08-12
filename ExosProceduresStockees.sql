-- P1
-- 1
drop procedure nombreArticles;
delimiter |
create procedure nombreArticles(in dateDebut datetime, in dateFin datetime, out nbArticles tinyint)
begin
    set nbArticles = (select count(distinct idart) from detailachat where (dateachat >= dateDebut and dateachat < dateFin)) ;
end |
delimiter ;

set @dateDebut = "2020-03-26 00:00:00";
set @dateFin = "2020-03-29 12:00:00";
set @nbArticles = 0;
call nombreArticles(@dateDebut, @dateFin, @nbArticles);
select @nbArticles;

-- 2
drop procedure augmPrix;
delimiter |
create procedure augmPrix(in prixMoyen numeric(8,4), out nbAugm tinyint)
begin
    declare moyenne numeric(8,4);
    select avg(prixvente) into moyenne from article;
    set nbAugm = 0;

    while moyenne < prixMoyen
        do update article set prixvente = prixvente * 1.02;
        set nbAugm = nbAugm + 1;
        select avg(prixvente) into moyenne from article;
    end while;
end |
delimiter ;

start transaction;
set @prixObjectif = 4.8;
call augmPrix(@prixObjectif, @nbaugm);
select @nbaugm;
rollback;

-- 3
drop procedure dernierSamedi;
delimiter |
create procedure dernierSamedi(in dateTraitee date, out dernierSamedi date)

begin
	set dernierSamedi = last_day(dateTraitee);
	while(dayofweek(dernierSamedi) != 7) do
        select date_add(dernierSamedi, interval -1 day) into dernierSamedi;
    end while;
end |
delimiter ;

start transaction;
	set @dateTraitee = "2023-03-27";
	call dernierSamedi(@dateTraitee, @samedi);
	select @samedi;
rollback;

start transaction;
	set @dateTraitee = "2016-04-02";
	call dernierSamedi(@dateTraitee, @samedi);
	select @samedi;
rollback;

-- P2
-- 1
drop procedure supprEvenements;
delimiter |
create procedure supprEvenements(in nomEvenement varchar(30), in limiteParticipants int)
begin
	if (select count(*) from participation where nomevent = nomEvenement) < limiteParticipants then
		delete from participation where nomevent = nomEvenement;
		delete from evenement where nomevent = nomEvenement;
	end if;
end |
delimiter ;

start transaction;
	select * from evenement;
	call supprEvenements('Foire aux vins', 4);
	select * from evenement;
rollback;

-- 2
create user 'user_proc'@'localhost' identified by 'proc';

grant create routine on dbexercices_q2.* to 'user_proc'@'localhost';
grant alter routine on dbexercices_q2.* to 'user_proc'@'localhost';
grant select on dbexercices_q2.achat to 'user_proc'@'localhost';
grant select on dbexercices_q2.participation to 'user_proc'@'localhost';
grant execute on procedure achats_evenements to 'user_proc'@'localhost';

drop procedure achatsEtEvenements;
delimiter |
create procedure achatsEtEvenements(in numero tinyint, out nbAchat tinyint, out nbEvenements tinyint)
begin
    declare tot decimal(8,2);
    declare res varchar(100);
    set nbAchat = (select count(*) from achat where numcli like numero);
    set nbEvenements = (select count(*) from participation where numcli like numero);   
    select (sum(prixachat * quantite) - sum(prixachat * quantite) * achat.remise) into tot from detailachat left join achat using(numcli, dateachat) where numcli like numero;
    select tot;    
    if tot > 30 then
		select concat((select prenomcli from client where numcli like numero) , " ", (select nomcli from client where numcli like numero) , " est un gros client.") as message;
	else
		select concat((select prenomcli from client where numcli like numero) , " ", (select nomcli from client where numcli like numero) , " est un client occasionel.") as message;
    end if;
end |
delimiter ;

start transaction;
	set @numClient = 2;
	call achatsEtEvenements(@numClient, @nbAchats, @nbEvenements);
	select @nbAchats;
	select @nbEvenements;
rollback;