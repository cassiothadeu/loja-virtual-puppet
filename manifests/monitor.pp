file { "/etc/apt/preferences.d/nagios":
	owner => vagrant,
	group => vagrant,
	mode => 0644,
	content => template("/vagrant/manifests/nagios"),
}

file { "/etc/apt/sources.list.d/raring.list":
	owner => vagrant,
	group => vagrant,
	mode => 0644,
	content => template("/vagrant/manifests/raring.list"),
}

exec { "apt-update":
	command => "/usr/bin/apt-get update",
	require => [File["/etc/apt/preferences.d/nagios"], File["/etc/apt/sources.list.d/raring.list"]],
}

exec { "configure-nagios3-debconf":
	command => "echo 'postfix	postfix/main_mailer_type select Internet Site' | sudo debconf-set-selections && 
	echo 'postfix postfix/mailname string monitor.lojavirtualdevops.com.br' | sudo debconf-set-selections &&
	echo 'nagios3-cgi	nagios3/nagios1-in-apacheconf boolean false' | sudo debconf-set-selections &&
	echo 'nagios3-cgi	nagios3/adminpassword-mismatch note' | sudo debconf-set-selections &&
	echo 'nagios3-cgi	nagios3/httpd multiselect apache2' | sudo debconf-set-selections &&
	echo 'nagios3-cgi nagios3/adminpassword password nagiosadmin' | sudo debconf-set-selections &&
	echo 'nagios3-cgi nagios3/adminpassword-repeat password nagiosadmin' | sudo debconf-set-selections",
	cwd  => "/home/vagrant",
	user => "vagrant",
	path => "/usr/bin/:/bin/",
	before => Package["nagios3"],
	logoutput => true,
}

package{ "nagios3":
	ensure => installed,
	require => Exec["apt-update"],
}

package{ "nagios-nrpe-plugin":
	ensure => installed,
	require => Package["nagios3"],
}

service { "nagios3":
	ensure => running,
	enable => true,
	hasstatus => true,
	hasrestart => true,
	require => Package["nagios3"],
}

file { "/etc/nagios3/conf.d/loja_virtual.cfg":
	owner => vagrant,
	group => vagrant,
	mode => 0644,
	content => template("/vagrant/manifests/loja_virtual.cfg"),
	require => Package["nagios3"],
	notify => Exec["reload-nagios-service"],
}

file { "/etc/nagios3/conf.d/contacts_nagios2.cfg":
	owner => vagrant,
	group => vagrant,
	mode => 0644,
	content => template("/vagrant/manifests/contacts_nagios2.cfg"),
	require => Package["nagios3"],
	notify => Exec["reload-nagios-service"],
}

exec{ "reload-nagios-service":
	command => "service nagios3 reload",
	refreshonly => true,
  	path => ["/usr/sbin", "/usr/bin", "/sbin", "/bin/"],
  	logoutput => false,
}