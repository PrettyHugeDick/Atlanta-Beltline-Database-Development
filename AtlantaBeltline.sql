CREATE DATABASE  IF NOT EXISTS `AtlantaBeltline`;
USE `AtlantaBeltline`;

CREATE TABLE IF NOT EXISTS `users` (
`username` varchar(20) NOT NULL,
`fname` varchar(20) NOT NULL,
`lname` varchar(20) NOT NULL,
`status` enum('PENDing','Approved','Declined') NOT NULL DEFAULT 'PENDing',
`pwd` varchar(80) NOT NULL,
PRIMARY KEY (`username`)
);

DELIMITER $$
CREATE TRIGGER pwd_check BEFORE INSERT ON users
FOR EACH ROW
BEGIN

    IF char_length (NEW.pwd ) < 8 THEN
        SIGNAL SQLSTATE '10000'
            SET MESSAGE_TEXT = 'password must at least contain 8 characters';
	ELSE SET NEW.pwd = md5(NEW.pwd);
					
    END IF;
END $$   
DELIMITER ; 

CREATE TABLE IF NOT EXISTS `email` (
`email` varchar(20) NOT NULL,
`username` varchar(20) NOT NULL,
PRIMARY KEY (`email`),
FOREIGN KEY (`username`) REFERENCES `users`(`username`)
	ON DELETE CASCADE
    ON UPDATE CASCADE
);

DELIMITER $$
CREATE TRIGGER email_check BEFORE INSERT ON email
FOR EACH ROW
BEGIN

    IF NEW.email NOT REGEXP '^[A-Z0-9a-z]+@[A-Z0-9a-z]+\.[A-Z0-9a-z]+$' THEN
        SIGNAL SQLSTATE '20000'
            SET MESSAGE_TEXT = 'email format NOT valid';

    END IF;
END; 
$$
DELIMITER ;

CREATE TABLE IF NOT EXISTS `visitor` (
`username` varchar(20) NOT NULL,
PRIMARY KEY (`username`),
FOREIGN KEY (`username`) REFERENCES `users` (`username`)
	ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `employee` (
`username` varchar(20) NOT NULL,
`eid` decimal(9,0) NOT NULL UNIQUE,
`phone` decimal(10,0) NOT NULL UNIQUE,
`address` varchar(100) NOT NULL,
`city` varchar(50) NOT NULL,
`state` varchar(25) NOT NULL,
`zipcode` decimal(5,0) NOT NULL,
`etype` enum('Admin','Manager','Staff') NOT NULL,
PRIMARY KEY (`username`),
FOREIGN KEY (`username`) REFERENCES `users` (`username`)
	ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `site` (
`sname` varchar(30) NOT NULL, 
`mgrUsername` varchar(20) NOT NULL, 
`address` varchar(50) , 
`zipcode` decimal(5,0) NOT NULL, 
`openEveryday` boolean NOT NULL DEFAULT 0,
PRIMARY KEY (`sname`),
FOREIGN KEY (`mgrUsername`) REFERENCES `employee`(`username`)
	ON DELETE NO ACTION
    ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `event` (
`sname` varchar(30) NOT NULL,
`ename` varchar(30) NOT NULL,
`startDate` date NOT NULL, 
`ENDDate` date NOT NULL, 
`price` decimal(5,2) NOT NULL, 
`capacity` decimal(4,0) NOT NULL, 
`minStaffReq` decimal(2,0) NOT NULL, 
`description` text NOT NULL,
PRIMARY KEY (`sname`,`ename`,`startDate`),
FOREIGN KEY (`sname`) REFERENCES `site`(`sname`)
	ON DELETE CASCADE
    ON UPDATE CASCADE
);

DELIMITER $$
CREATE TRIGGER date_check BEFORE INSERT ON event
FOR EACH ROW
BEGIN

    IF NEW.startdate  > NEW.ENDdate THEN
        SIGNAL SQLSTATE '10001'
            SET MESSAGE_TEXT = 'startdate must be earlier than ENDdate';					
    END IF;
END $$   
DELIMITER ; 

DELIMITER $$
CREATE TRIGGER price_check BEFORE INSERT ON event
FOR EACH ROW
BEGIN

    IF NEW.price  < 0 THEN
        SET NEW.price=0;					
    END IF;
END $$   
DELIMITER ; 

DELIMITER $$
CREATE TRIGGER capacity_check BEFORE INSERT ON event
FOR EACH ROW
BEGIN

    IF NEW.capacity  < 0 THEN
        SET NEW.capacity=0;					
    END IF;
END $$   
DELIMITER ; 

DELIMITER $$
CREATE TRIGGER minstaff_check BEFORE INSERT ON event
FOR EACH ROW
BEGIN

    IF NEW.MinstaffReq  < 0 THEN
        SET NEW.MinstaffReq=0;					
    END IF;
END $$   
DELIMITER ; 

CREATE TABLE IF NOT EXISTS `transit` (
`type` enum('MARTA','Bus','Bike') NOT NULL, 
`route` varchar(10) NOT NULL,
`price` decimal(3,1) NOT NULL,
PRIMARY KEY (`type`,`route`)
);

DELIMITER $$
CREATE TRIGGER transit_price_check BEFORE INSERT ON transit
FOR EACH ROW
BEGIN

    IF NEW.price  < 0 THEN
        SET NEW.price=0;					
    END IF;
END $$   
DELIMITER ; 

CREATE TABLE IF NOT EXISTS `assignTo` (
`username` varchar(20) NOT NULL,
`sname` varchar(30) NOT NULL,
`ename` varchar(30) NOT NULL,
`startDate` date NOT NULL, 
PRIMARY KEY (`username`,`sname`,`ename`,`startDate`),
FOREIGN KEY (`username`) REFERENCES `employee`(`username`) 
	ON DELETE CASCADE
    ON UPDATE CASCADE,
FOREIGN KEY (`sname`,`ename`,`startDate`) REFERENCES `event`(`sname`,`ename`,`startDate`)
	ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `visitEvent` (
`username` varchar(20) NOT NULL,
`sname` varchar(30) NOT NULL,
`ename` varchar(30) NOT NULL,
`startDate` date NOT NULL,
`date` date NOT NULL,
PRIMARY KEY (`username`,`sname`,`ename`,`startDate`,`date`),
FOREIGN KEY (`username`) REFERENCES `visitor`(`username`)
	ON DELETE CASCADE
    ON UPDATE CASCADE,
FOREIGN KEY (`sname`,`ename`,`startDate`) REFERENCES `event`(`sname`,`ename`,`startDate`)
	ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `visitSite` (
`username` varchar(20) NOT NULL,
`sname` varchar(30) NOT NULL,
`date` date NOT NULL,
PRIMARY KEY (`username`,`sname`,`date`),
FOREIGN KEY (`username`) REFERENCES `visitor`(`username`) 
	ON DELETE CASCADE
    ON UPDATE CASCADE,
FOREIGN KEY (`sname`) REFERENCES `site`(`sname`)
	ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `takeTransit` (
`username` varchar(20) NOT NULL,
`type` enum('MARTA','Bus','Bike') NOT NULL, 
`route` varchar(10) NOT NULL,
`date` date NOT NULL,
PRIMARY KEY (`username`,`type`,`route`,`date`),
FOREIGN KEY (`username`) REFERENCES `users`(`username`)
	ON DELETE CASCADE
    ON UPDATE CASCADE,
FOREIGN KEY (`type`,`route`) REFERENCES `transit`(`type`,`route`)
	ON DELETE CASCADE
    ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS `connect` (
`type` enum('MARTA','Bus','Bike') NOT NULL, 
`route` varchar(10) NOT NULL,
`sname` varchar(30) NOT NULL,
PRIMARY KEY (`type`,`route`,`sname`),
FOREIGN KEY (`type`,`route`) REFERENCES `transit`(`type`,`route`)
	ON DELETE CASCADE
    ON UPDATE CASCADE,
FOREIGN KEY (`sname`) REFERENCES `site`(`sname`)
	ON DELETE CASCADE
    ON UPDATE CASCADE
);
