DROP TABLE IF EXISTS repository;
CREATE TABLE repository (
  plugin_id MEDIUMINT UNSIGNED NOT NULL auto_increment,
  uid MEDIUMINT UNSIGNED NOT NULL,
  name VARCHAR(64) NOT NULL,
  description VARCHAR(254) NOT NULL,
  newdescription VARCHAR(254) NOT NULL,
  url VARCHAR(128),
  newurl VARCHAR(128),
  license TINYINT UNSIGNED NOT NULL,
  category TINYINT UNSIGNED NOT NULL,
  approved  TINYINT UNSIGNED DEFAULT '1' NOT NULL,
  approved_uid TINYINT UNSIGNED,
  reject_reason VARCHAR(254),
  created DATETIME NOT NULL,
  updated TIMESTAMP,
  UNIQUE plugin_name (name),
  PRIMARY KEY (plugin_id)
);
# newdescription and newurl are for allowing 
# users to edit their entries

DROP TABLE IF EXISTS plugin_release;
CREATE TABLE plugin_release (
  version_id MEDIUMINT UNSIGNED NOT NULL auto_increment,
  plugin_id MEDIUMINT UNSIGNED NOT NULL,
  uid MEDIUMINT UNSIGNED NOT NULL,
  changes VARCHAR(254),
  download_url VARCHAR(128) NOT NULL,
  changelog_url VARCHAR(128),
  version VARCHAR(8) NOT NULL,
  status TINYINT UNSIGNED NOT NULL, 
  approved TINYINT UNSIGNED DEFAULT '1' NOT NULL,
  approved_uid MEDIUMINT UNSIGNED,
  reject_reason VARCHAR(254),
  created DATETIME NOT NULL,
  updated TIMESTAMP,
  UNIQUE plugin_version (plugin_id,version),
  PRIMARY KEY (version_id)
);
#Need a constaint for unique on plugin_id/version
