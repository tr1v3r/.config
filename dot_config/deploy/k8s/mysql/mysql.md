# root

## 创建数据库

```sql
create database river;
create database data;
create database test;
```

## 授权

```sql
GRANT ALL PRIVILEGES ON river.* TO 'river'@'%';
GRANT ALL PRIVILEGES ON data.* TO 'river'@'%';
GRANT ALL PRIVILEGES ON test.* TO 'river'@'%';
FLUSH PRIVILEGES;
```
