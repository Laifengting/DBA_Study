set @id:=floor(rand()*1000000 +1);
xa start 'b';
update sbtest.sbtest1 set k = k + 1 where id = @id;
xa end 'b';
xa prepare 'b';
xa commit 'b';
