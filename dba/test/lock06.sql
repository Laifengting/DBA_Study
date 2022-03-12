set @id:=floor(rand()*1000000 +1);
xa start 'g';
update sbtest.sbtest1 set k = k + 1 where id = @id;
xa end 'g';
xa prepare 'g';
xa commit 'g';
