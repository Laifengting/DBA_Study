begin;
set @id:=floor(rand()*1000000 +1);
update sbtest.sbtest1 set k = k + 1 where id = @id;
commit;
