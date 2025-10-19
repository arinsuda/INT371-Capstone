-- Create Database --
create database changsurev1;

-- Check Users --
select * from mysql.user;

-- Create users --
CREATE USER 'changSure'@'localhost' IDENTIFIED BY 'changSure@sit.65';

-- Check Users --
select * from mysql.user;

-- Grant Privilege --
GRANT ALL privileges ON changsurev1.* TO 'changSure'@'localhost';


