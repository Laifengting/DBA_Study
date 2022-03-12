set @id:=floor(rand()*1000000 +1);
xa start 'a';
update sbtest.sbtest1 set k = k + 1 where id = @id;
xa end 'a';
xa prepare 'a';
xa commit 'a';
