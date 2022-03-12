set @id:=floor(rand()*1000000 +1);
xa start 'c';
update sbtest.sbtest1 set k = k + 1 where id = @id;
xa end 'c';
xa prepare 'c';
xa commit 'c';
