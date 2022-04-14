#!/usr/bin/perl
#
# rs_fetch.pl
#
#------------------------------------------------------------------------------------------------

use strict;
use warnings;
use Getopt::Long;
#use Getopt::Std;



#my $paras = GetParameters();
#if($paras) {DisplayHash($paras); }
#exit(0);

#------------------------------------------------------------------------------------------------
# main()


my $parameters;
my $status;
my $check_status;


# Get command lines args
$parameters = GetParameters();

# Help only
if($parameters->{'help'}) { exit 0;} # just print helps then exit.

# Check status only (not sending another request)
if($parameters->{'check'} ne '')
{
    $status = CheckStatus($parameters->{'check'});
    exit($status->{'status'});
}



# Below is normal sequence, SubmitRequest/WaitForCompletion ....
if($parameters->{'rs'} eq '') { PrintHelp(); exit (-1);}

$status = SubmitRequest($parameters);
if ($status->{'status'} > 2) { exit;} # if the request return some error, stop here

$status = WaitForCompletion($status);

exit ($status->{'status'});


#------------------------------------------------------------------------------------------------
# SubmitRequest($parameters)  
#
# CGI command format:
# jsoc_fetch?op=exp_request&ds=$ds&method=$method&format=txt&protocol=$protocol&filenamefmt=$ffmt
# where, $method, $protocol, $filenamefmt come from command line args ($parameters)
#
# CGI status code:
# 0=OK immediate data available or queue managed data is complete
# 1=request received and action is pending...processing
# 2=queued for processing
# 3=request too large for automatic requests
# 4=request not formed correctly, bad series, etc
# 5=request old, results requested after data timed out.
# if (status > 2) => there is element error="error message"


sub SubmitRequest
{
    my ($parameters) = @_;
    my ($uri, $op, $command, $status)=('')x4;


    $uri = 'http://jsoc.stanford.edu/cgi-bin/ajax/';
    $op  = 'jsoc_fetch?op=exp_request&ds='. $parameters->{'rs'}.'&process=no_op&method='.$parameters->{'method'}.'&protocol='.$parameters->{'protocol'}.'&format=txt&filenamefmt=' . $parameters->{'ffmt'};

    #print "$op\n";

    $op  = quotemeta($op); # escaped url
    $command = "wget -q -O - $uri$op";  # output to stdout

    $status = DoCommand($command);

    if ($status->{'status'} > 2)
    {
	print "$status->{'error'}\n";       
    }

    return $status;

}

#------------------------------------------------------------------------------------------------
# CheckStatus($requestid)
#
# CGI command format:
# jsoc_fetch?op=exp_status&requestid=$requestid
# where, $requestid comes from command line args ($parameters)
#
# GCI status code:
# 0=OK immediate data available or delayed request in queue
# 1=processing
# 2=queued for processing
# 3=large request need manual confirm
# 4=request not formed correctly, bad series, etc
# 5=request old, results requested after data timed out.
# 6=RequestID not recognized, probably need to repeat in a few seconds
# if (status > 3) => there is error="error message"
#


sub CheckStatus
{
    my ($requestid) = @_;
    my ($uri, $op, $command, $status)=('')x4;

    my $parsing_header_section = 1;

    $uri = 'http://jsoc.stanford.edu/cgi-bin/ajax/';
    $op  = "jsoc_fetch?op=exp_status&requestid=$requestid&format=txt";
    $op  = quotemeta($op);

    $command = "wget -q -O - $uri$op";  # output to stdout
  
    #print "$command\n";

    $status = DoCommand($command);

    if ($status->{'status'} > 3)
    {
    	print "\n ==> $status->{'error'}\n";       
    }

    return $status;

}

#------------------------------------------------------------------------------------------------
# DoCommand($command) return $status hash ref
#
# Text response has 2 sections:
# Header: key=value
# DATA:   record filename

sub DoCommand
{
    my ($command) = @_;
    my ($line, $uri, $op, $key, $value)=('')x6;

    my $parsing_header_section = 1;

    my %status = ('status','','requestid','','dir','','size','','count','','wait','','error','','DATA','');


    open(COM,"$command |") || die "DoCommand($command) fails\n $!";

    while (defined ($line = <COM>)) 
    {  
	unless ($parameters->{'quiet'})  { print($line); }

	$line =~s/^\s+//; # remove leading,trailing white spaces
	$line =~s/\s+$//; 


	if($line =~ /^\#/)
	{  
	    if ($line =~ /^\# DATA/) # Found DATA, prepare to store the file list
	    {
		$parsing_header_section = 0;
		my @DATA_list = ();
		$status{'DATA'} = \@DATA_list;
		next;
	    }
	    next;
	}

	if($parsing_header_section == 1)
	{
	    ($key, $value) = split(/=/,$line);
	
	    # Save only interested items 
	    if(exists $status{$key})
	    {
		$status{$key} = $value;
	    }
	}
	else # parsing DATA
	{
	    ($key, $value) = split(/\s+/,$line);    
	    push @{$status{'DATA'}}, $value;
	    
	    #print "[$key][$value]\n";
	    #print "DATA size = ". scalar(@{$request_status{'DATA'}}). "\n";
	}
    }
    
    close(COM) || die "DoCommand() close fails : $!\n";

    unless($parameters->{'quiet'}) { print "\n";}

    return \%status;
}

#------------------------------------------------------------------------------------------------
# WaitForCompletion($reques_status)    return the lastest response
#

sub WaitForCompletion
{
    my ($status)= @_;
    my ($filename, $finish);

 
    unless ($status->{'DATA'}) # when 'method=url_quick' the DATA might be here already, no need to wait
    {
	# Keep checking for 'DATA' avail
	$finish = 0;
	while(!$finish)
	{  
	    sleep(10);

	    $status =  CheckStatus($status->{'requestid'}); 

	    if (($status->{'status'} == 0) or ($status->{'status'} > 2)) {$finish = 1;};	      
	}
    }


    if (($status->{'status'} == 0) and ($status->{'DATA'}))
    {
	foreach $filename (@{$status->{'DATA'}})
	{
	    Download($status->{'dir'}. '/'. $filename);
	}
    }
    else
    {
	if($status->{'error'}) { print "$status->{'error'}\n";}
    }

    return $status; # return the last status
}

#------------------------------------------------------------------------------------------------
# CheckEarlierSumitStatus($requestid)
# Given requestid (ie: JSOC_20091015_003), return JSOC processing status

sub CheckEarlierSubmitStatus
{
    my ($requestid) = @_;
    my $status = CheckExportStatus($requestid);  
    #DisplayStatus($status);

    return $status;
}

#------------------------------------------------------------------------------------------------
# DisplayStatus(\%status)
#
# For checking only (hash reference content)

sub DisplayStatus
{
    my ($status) = @_;

    #if (!$status->{'status'}) {return;}

    print "\n\nHash Content:\n";

    for my $key (keys(%$status))
    {
	if ($key ne 'DATA')
	{
	    print "$key=$status->{$key}\n";
	}
	else
	{
	    #print "DATA size = ". scalar(@{$request_status->{'DATA'}}). "\n";
	    
	    if($status->{'DATA'} and (! $parameters->{'quiet'}))
	    {
		print "\nFiles:\n";
		foreach my $line (@{$status->{'DATA'}} )
		{	   
		    print "$line\n";	       
		}	    
	    }
	}
    }
    print "\n";

}

#------------------------------------------------------------------------------------------------
# Download(url)

sub Download
{
    my ($url) = @_;

    #my $command = 'wget -q ftp://solarftp.stanford.edu' . $url;
    my $command = 'wget -q http://jsoc.stanford.edu' . $url;
    
    #unless($parameters->{'quiet'}) { print "$command\n"; }
    print "$command\n";

    system($command);

}

#-------------------------------------------------------------------------------------------------
# GetParamters ()


sub GetParameters
{
    my %parameters=();
    my ($item, $key, $value);


    # Defautls

    $parameters{'help'}        = 0;
    $parameters{'quiet'}       = 0;

    $parameters{'rs'}          = '';
    $parameters{'method'}      = 'url_quick';
    $parameters{'protocol'}    = 'as-is';

    $parameters{'ffmt'}        ='{seriesname}.{recnum:%lld}.{segment}'; # or {segment}
    $parameters{'check'}       ='';

    Getopt::Long::Configure("bundling");
    GetOptions("h"  => \$parameters{help},
               "q"  => \$parameters{quiet});


    # @ARGV has 4 possibilities: 'rs=...' ,'method=...','protocol=...','ffmt=...', 'check=....'
    foreach $item (@ARGV)
    {
	if (($item =~/^rs/) or ($item =~/^method/) or ($item =~ /^protocol/) or ($item =~/^ffmt/) or ($item =~/^check/))
	{
	    ($key, $value)   = split(/=/,$item);
	    $parameters{$key} = $value;
        }
	else # only ds allow to be missing, so assume the arguement is rs
	{
	    $parameters{'rs'}= $item;
	}
    }

   
    if($parameters{'help'} == 1) {PrintHelp(); }

    if(!(($parameters{'check'} ne '') or ($parameters{'help'}==1)) and ($parameters{'rs'} eq ''))
    {
	print "Missing record_set\n";	
	return undef;
    }


    return \%parameters; 

}

#-------------------------------------------------------------------------------------------------
# PrintHelp()

sub PrintHelp
{

    print "\nrs_fetch.pl [-hq] record_set [method][protocol][ffmt][check]\n\n";
  
    print "Flags:\n";
    print "  -h:  help \n";
    print "  -q:  quiet \n";

    print "Options:\n";
    print "   method      = url_quick  or   url\n";
    print "   protocol    = as-is      or   FITS     or    FITS,**NONE**\n";
    print "   ffmt={seriesname}.{recnum:%lld}.{segment} \n";
    print "   check=request_id \n\n";
    

    print "Examples:\n";

    print "rs_fetch.pl 'hmi.lev0e[1879000]'                                  : (default) fastest, export files \"as-is\",method quick_url \n";
    print "rs_fetch.pl 'hmi.lev0e[$]' 'method=url' 'protocol=FITS,**NONE**'  : as uncompressed FITS, using url method\n";
    print "rs_fetch.pl -q 'hmi.lev0e[1879000-1879001]'                       : quiet mode\n";
    print "rs_fetch.pl 'hmi.lev0e[\$]' 'ffmt={segment}'                      : get latest image, using segment filename\n";
    print "rs_fetch.pl 'check=JSOC_20091016_036'                             : check status of an earlier export request\n";

}

#-------------------------------------------------------------------------------------------------

sub DisplayHash
{
    my $hash = $_[0];

    for my $key (keys(%$hash))
    {
	print "$key=$hash->{$key}\n";
    }
}

#-------------------------------------------------------------------------------------------------
