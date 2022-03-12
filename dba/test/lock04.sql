set @id:=floor(rand()*1000000 +1);
xa start 'e';
update sbtest.sbtest1 set k = k + 1 where id = @id;
xa end 'e';
xa prepare 'e';
xa commit 'e';
