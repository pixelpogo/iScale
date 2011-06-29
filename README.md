# iScale

Tool to manage large clusters at Scalarium from command line.

While Scalarium offers a powerful web dashboard to manage your cluster you are usually a lot faster working from command line. iScale is there to provide a role-based approach for displaying data or opening shells (using iTerm) for a single instance, all instances of a role or multiple roles in a single command.

## Installation

* Download iScale files to local directory (used as `DIR` below).
* `mv DIR/config/iScale.yml ~/.iScale`
* Edit ~/iScale to add your Scalarium username, your Scalarium token and shortcuts to your cluster names.
* `cat DIR/config/ssh_config >> ~/.ssh/config`

### Dependencies

iScale depends on these gems to be available:

* rest-client
* json

## Commands

Command pattern is always `iScale <cluster shortcut> <command> [<names>]`.

Cluster shortcuts can be defined in .iScale configuration file, otherwise specify the full name of the Scalarium cluster to use.

### roles

Syntax: `roles`

Displays all roles of a cluster.

	PROMPT$ iScale.rb staging roles
	db-master: 6 instances
	db-slave: 0 instances
	hudson-slave: 1 instances
	lb: 1 instances
	monitoring: 1 instances
	monitoring-master: 1 instances
	rails-app: 0 instances
	redis-masters: 5 instances
	redis-slaves: 0 instances

### load

Syntax: `load <roles>|all`

Executes `uptime` on specified servers and displays load information in a list. `<roles>` can be a single role or a list of roles.

	PROMPT$ iScale.rb staging load db-master redis-masters
	db-master
	mws-xdb-m01:   ssh -A jesper@IP.compute.amazonaws.com =>             load average: 0.07, 0.02, 0.00
	mws-xdb-m02:   ssh -A jesper@IP.compute.amazonaws.com =>             load average: 0.07, 0.02, 0.00
	mws-xdb-m03:   ssh -A jesper@IP.compute.amazonaws.com =>             load average: 0.07, 0.02, 0.00
	mws-xdb-m04:   ssh -A jesper@IP.compute.amazonaws.com =>             load average: 0.01, 0.01, 0.00
	mws-xdb-mf1:   ssh -A jesper@IP.compute.amazonaws.com =>             load average: 0.00, 0.00, 0.00
	mws-xdb-testing1: ssh -A jesper@IP.compute.amazonaws.com =>          load average: 0.00, 0.00, 0.00
	                                                               total load average: 0.04, 0.01, 0.00
	                                                                       total load: 0.22, 0.07, 0.00
	redis-masters
	mws-redis-m01a: ssh -A jesper@IP.compute.amazonaws.com =>            load average: 0.00, 0.00, 0.00
	mws-redis-m02a: ssh -A jesper@IP.compute.amazonaws.com =>            load average: 0.00, 0.00, 0.00
	mws-redis-m04c: ssh -A jesper@IP.compute.amazonaws.com =>            load average: 0.00, 0.00, 0.00
	mws-redis-mu1: ssh -A jesper@IP.compute.amazonaws.com =>             load average: 0.00, 0.00, 0.00
	mws-redis-mu2: ssh -A jesper@IP.compute.amazonaws.com =>             load average: 0.00, 0.00, 0.00
	                                                               total load average: 0.00, 0.00, 0.00
	                                                                       total load: 0.00, 0.00, 0.00

### cpu

Syntax: `cpu <roles>|all`

Executes `iostat 3 2` on specified servers and displays cpu usage information in a list. `<roles>` can be a single role or a list of roles.

	PROMPT$ iScale.rb staging cpu db-master redis-masters
	db-master                                              cpu average:  %user   %nice %system %iowait  %steal   %idle
	mws-xdb-m01:   ssh -A jesper@IP.compute.amazonaws.com =>               0.00,   0.00,   0.00,   0.00,   0.00, 100.00
	mws-xdb-m02:   ssh -A jesper@IP.compute.amazonaws.com =>               0.00,   0.00,   0.17,   0.00,   0.00,  99.83
	mws-xdb-m03:   ssh -A jesper@IP.compute.amazonaws.com =>               0.00,   0.00,   0.00,   0.00,   0.00, 100.00
	mws-xdb-m04:   ssh -A jesper@IP.compute.amazonaws.com =>               0.00,   0.00,   0.00,   0.00,   0.00, 100.00
	mws-xdb-mf1:   ssh -A jesper@IP.compute.amazonaws.com =>               0.17,   0.00,   0.00,   0.00,   0.00,  99.83
	mws-xdb-testing1: ssh -A jesper@IP.compute.amazonaws.com =>            0.00,   0.00,   0.17,   0.00,   0.00,  99.83
	                                                  total cpu average:   0.03,   0.00,   0.06,   0.00,   0.00,  99.92
	                                                          total cpu:   0.17,   0.00,   0.34,   0.00,   0.00, 599.49
	redis-masters                                          cpu average:  %user   %nice %system %iowait  %steal   %idle
	mws-redis-m01a: ssh -A jesper@IP.compute.amazonaws.com =>              0.00,   0.00,   0.00,   0.00,   0.00, 100.00
	mws-redis-m02a: ssh -A jesper@IP.compute.amazonaws.com =>              0.00,   0.00,   0.00,   0.00,   0.00, 100.00
	mws-redis-m04c: ssh -A jesper@IP.compute.amazonaws.com =>              0.00,   0.00,   0.00,   0.00,   0.00, 100.00
	mws-redis-mu1: ssh -A jesper@IP.compute.amazonaws.com =>               0.00,   0.00,   0.00,   0.00,   0.00, 100.00
	mws-redis-mu2: ssh -A jesper@IP.compute.amazonaws.com =>               0.00,   0.00,   0.00,   0.00,   0.00, 100.00
	                                                  total cpu average:   0.00,   0.00,   0.00,   0.00,   0.00, 100.00
	                                                          total cpu:   0.00,   0.00,   0.00,   0.00,   0.00, 500.00

### open

Syntax: `open <names>`

Opens a shell using `ssh -A` to all specified instances and immediately executes `sudo -sEH` afterwards. This will allow you to use your local private key to connect to other instances within the cluster. `<names>` is a list that can contain role or instances names. Unless `<names>` is a single instance's name shell are opened in a new iTerm window.

	PROMPT$ iScale.rb staging open db-master zeus mws-redis-mu1
	opening new window...