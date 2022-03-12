set @id:=floor(rand()*1000000 +1);
xa start 'h';
update sbtest.sbtest1 set k = k + 1 where id = @id;
xa end 'h';
xa prepare 'h';
xa commit 'h';
