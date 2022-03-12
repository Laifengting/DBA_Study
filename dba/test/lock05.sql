set @id:=floor(rand()*1000000 +1);
xa start 'f';
update sbtest.sbtest1 set k = k + 1 where id = @id;
xa end 'f';
xa prepare 'f';
xa commit 'f';
