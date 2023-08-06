-- 1
create user 'user1'@'localhost' identified with mysql_native_password by 'user';
create user 'user2'@'localhost' identified with sha256_password by 'user';

-- 2
grant select, insert, update, delete on dbexercices_q2.magasin to 'user1'@'localhost';
grant select, insert, update, delete on dbexercices_q2.evenement to 'user1'@'localhost';
grant select, insert, update, delete on dbexercices_q2.localite to 'user1'@'localhost';
grant select, insert, update, delete on dbexercices_q2.employe to 'user1'@'localhost';
grant select, insert, update, delete on dbexercices_q2.client to 'user1'@'localhost';
grant select, insert, update, delete on dbexercices_q2.article to 'user1'@'localhost';
grant select, insert, update, delete on dbexercices_q2.articleenvente to 'user1'@'localhost';
grant select, insert, update, delete on dbexercices_q2.achat to 'user1'@'localhost';
grant select, insert, update, delete on dbexercices_q2.detailachat to 'user1'@'localhost';
show grants for 'user1'@'localhost';

-- 3
grant select on dbexercices_q2.* to 'user2'@'localhost';
grant insert on dbexercices_q2.participation to 'user2'@'localhost';
grant lock tables on dbexercices_q2.* to 'user2'@'localhost';
show grants for 'user2'@'localhost';

-- 4
start transaction;
insert into evenement(dateevent, nomevent, id) values ('2023-07-11 15:00:00', 'Evenement', 4);
savepoint pt_sauvegarde;
insert into participation(numcli, nomevent) values (3, 'Evenement');
insert into participation(numcli, nomevent) values (5, 'Evenement');

rollback to pt_sauvegarde;

rollback;

commit;

-- 5
start transaction;
update evenement 
inner join participation using(nomevent)
inner join client using(numcli)
set dateevent = date_add(dateevent, interval 1 day) where nomcli like "c%";
select * from evenement;
rollback;

-- 6
start transaction;
select * from evenement;
update evenement
set dateevent = '2023-07-11 16:00:00' where nomevent like binary 'Vente de fromage';
select * from evenement;
commit;