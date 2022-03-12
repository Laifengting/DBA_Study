set @id:=floor(rand()*1000000 +1);
xa start 'd';
update sbtest.sbtest1 set k = k + 1 where id = @id;
xa end 'd';
xa prepare 'd';
xa commit 'd';
