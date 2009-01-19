
DROP DATABASE IF EXISTS irodsUsage;
CREATE DATABASE irodsUsage;
use irodsUsage;
CREATE TABLE IF NOT EXISTS zones
(
     id INTEGER(10) UNSIGNED NOT NULL auto_increment,
     name varchar(255) UNIQUE NOT NULL,
     PRIMARY KEY(id)
) ENGINE = InnoDB;

CREATE UNIQUE INDEX zone_ind on zones(id);

CREATE TABLE IF NOT EXISTS resources
(
     id INTEGER(10) UNSIGNED NOT NULL auto_increment,
     rsrc_name varchar(255) NOT NULL,
     zone_id INTEGER(10) UNSIGNED NOT NULL,
     PRIMARY KEY (id),
     INDEX zone_ind (zone_id),
     FOREIGN KEY(zone_id) REFERENCES zones(id) ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE UNIQUE INDEX resource_ind on resources(id);

CREATE TABLE IF NOT EXISTS users
(
     id INTEGER(10) UNSIGNED NOT NULL auto_increment,
     username varchar(255) NOT NULL,
     zone_id INTEGER(10) UNSIGNED NOT NULL,
     PRIMARY KEY (id),
     INDEX zone_ind (zone_id),
     FOREIGN KEY(zone_id) REFERENCES zones(id) ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE UNIQUE INDEX user_ind on users(id);
CREATE UNIQUE INDEX usrAtZone_ind ON users(username, zone_id);

CREATE TABLE IF NOT EXISTS groups
(
id INTEGER(10) UNSIGNED NOT NULL auto_increment,
name varchar(255) NOT NULL,
zone_id INTEGER(10) UNSIGNED NOT NULL,
PRIMARY KEY (id),
INDEX zone_ind (zone_id),
FOREIGN KEY(zone_id) REFERENCES zones(id) ON UPDATE CASCADE
) ENGINE = InnoDB;

CREATE UNIQUE INDEX groupAtZone_ind ON groups(name, zone_id);

CREATE TABLE IF NOT EXISTS use_log
(
     timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
     user_id INTEGER(10) UNSIGNED,          
     group_id INTEGER(10) UNSIGNED, 
     resource_id INTEGER(10) UNSIGNED NOT NULL,
     amount BIGINT NOT NULL,
     num_files BIGINT NOT NULL DEFAULT 0,
     xml_timestamp TIMESTAMP NOT NULL,
     INDEX user_ind(user_id),              
     INDEX resource_ind (resource_id),       
     FOREIGN KEY(user_id) REFERENCES users(id) ON UPDATE CASCADE,
     FOREIGN KEY(resource_id) REFERENCES resources(id) ON UPDATE CASCADE
) ENGINE = InnoDB;      
