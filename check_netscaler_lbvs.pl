#!/usr/bin/perl -w
# nagios: -epn
# check_netscaler_lbvs.pl
#
# Created by KlumzByte
#
# Copyright (C) 2016 KlumzByte. All rights reserved
# This program is free software; you can redistribute it or modify
# it under the terms of the GNU General Public License

use strict;
use warnings;
use Net::SNMP;
use Getopt::Long;

my $o_help = undef;
my $o_host = undef;
my $o_community = "public";
my $o_port = 161;
my $o_version = "2c";
my $o_timeout = 10;
my $session_result = undef;
my $exit_state = 0;
my $exit_descr = undef;
my $lbvs_state = undef;
my $o_lbvs = undef;
my $o_nsg = 0;

options();

# OID
my $oid_Name = "1.3.6.1.4.1.5951.4.1.3.1.1.1.$o_lbvs";
my $oid_RequestB = "1.3.6.1.4.1.5951.4.1.3.1.1.31.$o_lbvs";
my $oid_ResponseB = "1.3.6.1.4.1.5951.4.1.3.1.1.33.$o_lbvs";
my $oid_RxBytesRate = "1.3.6.1.4.1.5951.4.1.3.1.1.44.$o_lbvs";
my $oid_TxBytesRate = "1.3.6.1.4.1.5951.4.1.3.1.1.45.$o_lbvs";
my $oid_ServiceUp = "1.3.6.1.4.1.5951.4.1.3.1.1.41.$o_lbvs";
my $oid_TotHits = "1.3.6.1.4.1.5951.4.1.3.1.1.48.$o_lbvs";
my $oid_Health = "1.3.6.1.4.1.5951.4.1.3.1.1.62.$o_lbvs";
my $oid_Tick = "1.3.6.1.4.1.5951.4.1.3.1.1.63.$o_lbvs";
my $oid_ActConn = "1.3.6.1.4.1.5951.4.1.3.1.1.7.$o_lbvs";
my $oid_IpAddr = "1.3.6.1.4.1.5951.4.1.3.1.1.2.$o_lbvs";
my $oid_State = "1.3.6.1.4.1.5951.4.1.3.1.1.5.$o_lbvs";
my $oid_Sessions = "1.3.6.1.4.1.5951.4.1.3.1.1.60.$o_lbvs";

# Main
my $session = &open_session();
get_session($session);
close_session($session);

# Functions
sub open_session{
    my ($session,$error) = Net::SNMP->session(
        -hostname => $o_host,
        -community => $o_community,
        -port => $o_port,
        -version => $o_version,
		-timeout => $o_timeout);
    return $session;
}

sub close_session{
    my ($session) = @_;

    if (!defined ($session)){
        print "Session error: ", $session->error(),"\n";
        $session->close();
        exit 4;
    }
    if (defined ($session)){
        $session->close();
        exit $exit_state;
    }
}

sub get_session{
    my ($session) = @_;
    my $session_result = $session->get_request(-varbindlist => [
        $oid_Name,
        $oid_RequestB,
        $oid_ResponseB,
        $oid_RxBytesRate,
        $oid_TxBytesRate,
        $oid_TotHits,
        $oid_Health,
        $oid_Tick,
        $oid_ActConn,
        $oid_IpAddr,
        $oid_State,
        $oid_Sessions]);
			
    if (!defined ($session_result)){
        print "Error creating sesion: ", $session->error(),".\n";
        $exit_state = 3;
    }
	elsif ($session_result->{$oid_Name} eq "noSuchInstance"){
				print "Error: noSuchInstance\n";
				$exit_state = 3;
			}
	else 
	{
		# Citrix NetScaler Gateway
		if ($o_nsg == "1"){
		
			# Critical
			if ($session_result->{$oid_State} == 1){
				$exit_descr = "CRITICAL";
				$lbvs_state = "Down";
				$exit_state = 2;
			}

			# Warning
			elsif($session_result->{$oid_State} == 4){
				$exit_descr = "WARNING";
				$lbvs_state = "Out of service";
				$exit_state = 1;				
			}

			# OK
			elsif($session_result->{$oid_State} == 7){
				$exit_descr = "OK";
				$lbvs_state = "Up";
				$exit_state = 0;
			}		
			
		print 
			$exit_descr,": Name - ",$session_result->{$oid_Name},
			", State - ",$lbvs_state,
			", Time since last state change - ",substr($session_result->{$oid_Tick}, 0, -3),
			", Sessions - ",$session_result->{$oid_Sessions},	
			", Request Bytes - ",$session_result->{$oid_RequestB},
			", Response Bytes - ",$session_result->{$oid_ResponseB},
			", Requests Bytes pr. sec - ",$session_result->{$oid_RxBytesRate},
			", Response Bytes pr. sec - ",$session_result->{$oid_TxBytesRate},
			", Total Hits - ",$session_result->{$oid_TotHits},
			", IP Address - ",$session_result->{$oid_IpAddr},
			" | Sessions=",$session_result->{$oid_Sessions}," RxBytes=",$session_result->{$oid_RequestB},"c"," TxBytes=",$session_result->{$oid_ResponseB},"c","\n";
		}
		
		# Normal Load Balancing Virtual Server
		else{
		
			# Critical
			if ($session_result->{$oid_State} == 1 || $session_result->{$oid_Health} == 0){
				$exit_descr = "Critical";
				$lbvs_state = "Down";
				$exit_state = 2;
			}
			# Warning
			elsif($session_result->{$oid_State} == 4 || $session_result->{$oid_Health} <= 99){	
				$exit_descr = "WARNING";
				$lbvs_state = "Out of service";
				$exit_state = 1;
			}
			# OK
			elsif($session_result->{$oid_State} == 7 || $session_result->{$oid_Health} == 100){
				$exit_descr = "OK";
				$lbvs_state = "Up";
				$exit_state = 0;
			}
			
		print 
			$exit_descr,": Name - ",$session_result->{$oid_Name},
			", State - ",$lbvs_state,
			", Health - ",$session_result->{$oid_Health},
			"%, Time since last state change - ",substr($session_result->{$oid_Tick}, 0, -3),
			", Active Connections - ",$session_result->{$oid_ActConn},	
			", Request Bytes - ",$session_result->{$oid_RequestB},
			", Response Bytes - ",$session_result->{$oid_ResponseB},
			", Requests Bytes pr. sec - ",$session_result->{$oid_RxBytesRate},
			", Response Bytes pr. sec - ",$session_result->{$oid_TxBytesRate},
			", Total Hits - ",$session_result->{$oid_TotHits},
			", IP Address - ",$session_result->{$oid_IpAddr},
			" | ActiveConn=",$session_result->{$oid_ActConn}," RxBytes=",$session_result->{$oid_RequestB},"c"," TxBytes=",$session_result->{$oid_ResponseB},"c","\n";
		}
	} 
}

sub usage{
print "check_netscaler_lbvs v.1.1

Copyright (C) 2016 KlumzByte. All rights reserved
This program is free software; you can redistribute it or modify
it under the terms of the GNU General Public License

Tested on the following device:

Netscaler MPX 8200

Usage: 

./check_netscaler_lbvs.pl

 -h, --help
    Print help screen
 -H, --hostname HOSTNAME
   Host to check HOSTNAME
 -C, --community NAME
   Community string. SNMP version 2c only. (default: public)
 -p, --port INT
   SNMP agent port. (default: 161)
 -t, --timeout=INTEGER
   Seconds before plugin times out (default: 10)
 -L, --lbvs=STRING
   Load Balancing Virtual Server OID
 -G, --gateway
   NetScaler Gateway (default: off)\n";
}

sub options{
    Getopt::Long::Configure("bundling");
    GetOptions(
		'h'		=> \$o_help,            'help'          => \$o_help,
		'H:s'	=> \$o_host,            'hostname:s'    => \$o_host,
		'C:s'	=> \$o_community,       'community:s'   => \$o_community,
		'p:i'	=> \$o_port,            'port:i'        => \$o_port,
		't:i'	=> \$o_timeout,         'timeout:i'     => \$o_timeout,
		'L=s'	=> \$o_lbvs,            'lbvs=s'        => \$o_lbvs,
		'G'     => \$o_nsg,             'gateway'       => \$o_nsg
    );
    if (defined $o_help){
        usage();
        exit 0;
    }
    if (!defined ($o_host) || !defined ($o_community) || !defined ($o_lbvs)){
        print "Missing arguments!\n\n";
        usage();
        exit 0;
    }
}
