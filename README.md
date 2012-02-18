puppet-hcmbcs - Puppet provider for HCMBCS packages
===================================================

Allows use of HCMBCS with Puppet, much as one would use rpm and yum
providers. Why would one do this? Primarily to allow 'require'
dependencies on HCM packages for your other puppet resources.

Latest version of this code may be found on
[github](http://github.com/rlister/puppet-hcmbcs).
    
Installation
------------

Just drop this package in your Puppet modulepath, e.g.:

    # cd /etc/puppet/modules
    # git clone http://github.com/rlister/puppet-hcmbcs

Usage
-----

Usage is similar to the RPM and Yum providers. If your package is not
in the default repository ('bcs'), you'll need to pass that using
'install_options'.
    
    package { "orbmotd":
        provider         => hcmbcs,
        ensure           => installed,
        install_options  => {
            "repository" => "composition",
        },
    }

An ensure of 'installed' will not update the package if it is installed
already. If you wish always to get the latest version, use 'latest':

    package { "perl":
        provider => hcmbcs,
        ensure   => latest,
    }

If you want to lock to a partcular build and/or release, pass that
version as a string. Due to the, ahem, idiosyncratic treatment of
version strings by hcmbcs, you need to separate build and release with
a space.

    ## get the latest release for build 5.8.7
    package { "perl":
        provider => hcmbcs,
        ensure   => "5.8.7",
    }

    ## get precise release 5.8.7.6
    package { "perl":
        provider => hcmbcs,
        ensure   => "5.8.7 6",
    }

It would probably be a really bad idea to try and lock a version in
your Orb profile *and* in puppet, as they may end up fighting it out.
Best either to lock version in Orb and just have an ensure of
'installed', or avoid profile entry altogether and let puppet do all
the work.

To ensure a package is *not* installed, use ensure of 'absent':

    package { "perl":
        provider => hcmbcs,
        ensure   => absent,
    }
    
Again, if this package is in your materialized profile, sit back and
watch the fun. I accept no responsibility for the consequences.

Bugs
----

Probably. Version strings are really hokey in hcmbcs, if your ensured
spec doesn't seem to be working, check you have build and release
separated in the same way Orb has them.

Indeed, this whole endeavour may be misguided and ill-conceived. I
welcome bug reports, witty criticism and pull requests. Bring (hoppy)
beer.
