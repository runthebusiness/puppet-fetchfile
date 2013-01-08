# fetchfile
#
# This class downloads and decompresses files as well as managing their permissions
#
# Parameters:
#  - downloadurl: where to download the file from (Default: undef)
#  - downloadfile: the file that wget makes (Default: undef)
#  - downloadto: where to download the file too (Default: undef)
#  - compression: the type of compression the file is in, may be: none, zip, gz, targz or tar (Default: 'tar.gz')
#  - desintationpath: where to copy the file to once it is downloaded or maybe decompressed (Default: undef)
#  - destinationfile: the file that will be created when the downloaded file is decompressed or moved (Default: undef)
#  - owner: the owner that the destination file should have (Default: 'root')
#  - group: the group that the destination file should have (Default: 'root')
#  - mode: the permissions mode that the destination file should have (Default: 775)
#  - recurse: recursive setting for file management (Default: false)
#  - execrecursive: as an alternative to using the recurse method for file ownership this just does chmod and chown -- it is much faster than the recurse method (Default true)

define fetchfile(
	$downloadurl=undef,
	$downloadfile=undef,
	$downloadto=undef,
	$compression='tar.gz',
	$desintationpath=undef,
	$destinationfile=undef,
	$owner='root',
	$group='root',
	$mode='775',
	$recurse=false,
	$execrecurse=true
) {
  
  # common things for exec
  $execlaunchpaths = ["/usr/bin", "/usr/sbin", "/bin", "/sbin", "/etc"]
  $executefrom = "/tmp/"
  
  # creates tests for commandline execution
  $wgetcreates = "${downloadto}${downloadfile}"
  
  # destination creates
  $destinationcreates = "${desintationpath}${destinationfile}"
  
    # commands to be run by exec
  $wgetcommand ="wget -O '${wgetcreates}' '${downloadurl}'"
  $chowncommand = "chown -R ${owner}:${group}  ${destinationcreates}"
  $chmodcommand = "chmod -R ${mode}  ${destinationcreates}"

  # the destination file command
  if $compression == 'tar.gz' {
    $destinationcommand = "tar -C '${desintationpath}' -zxvf '${wgetcreates}'"
  } elsif $compression == 'tar' {
    $destinationcommand = "tar -C '${desintationpath}' -xvf '${wgetcreates}'"
  } elsif $compression == 'zip' {
    $destinationcommand = "unzip '${wgetcreates}' -d '${desintationpath}'"
  } elsif $compression == 'gz' {
    $destinationcommand = "gzip -d '${wgetcreates}' > '${desintationpath}'"
  } else {
    $destinationcommand = "mv '${wgetcreates}' '${desintationpath}'"
  }

  # downloads file
  exec {"${name}_fetchfiledownload":
    command=>$wgetcommand,
    cwd=> $executefrom,
    path=> $execlaunchpaths,
    creates=>$wgetcreates,
    logoutput=> on_failure,
  }

  # make destination file
  exec {"${name}_fetchfiledecompress":
    command=>$destinationcommand,
    cwd=> $executefrom,
    path=> $execlaunchpaths,
    creates=>$destinationcreates,
    logoutput=> on_failure,
    require=>exec["${name}_fetchfiledownload"]
  }
  
  # Mod file
  file {"${name}_fetchfiledecompress":
    path=>$destinationcreates,
    owner=>$owner,
    group=>$group,
    mode=>$mode,
    recurse=>$recurse,
    require=>exec["${name}_fetchfiledecompress"]
  }
  
  if $execrecurse == true {
    exec {"${name}_chmoddestinationfile":
	    command=>$chmodcommand,
	    cwd=> $executefrom,
	    path=> $execlaunchpaths,
	    logoutput=> on_failure,
	    require=>file["${name}_fetchfiledecompress"]
	  }
	  
	  exec {"${name}_chowndestinationfile":
      command=>$chowncommand,
      cwd=> $executefrom,
      path=> $execlaunchpaths,
      logoutput=> on_failure,
      require=>file["${name}_fetchfiledecompress"]
    }
  }
}
