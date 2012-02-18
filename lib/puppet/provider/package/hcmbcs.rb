## Puppet Package provider for HCMBCS RPMs.
## Richard Lister 2012

require 'puppet/util/package'

## subclass rpm provider
Puppet::Type.type(:package).provide :hcmbcs, :parent => :rpm, :source => :rpm do
  desc "Package support for hcmbcs."
  has_feature :versionable, :upgradeable, :install_options
  commands :hcmbcs => "/opt/bcs/bin/hcmbcs", :rpm => "/opt/bcs/bin/rpm"

  attr_accessor :latest_info

  ## check executables are working
  [ 'hcmbcs', 'rpm' ].each do |cmd|
    if command(cmd)
      confine :true => 
        begin
          send(cmd, '--version') 
        rescue Puppet::ExecutionFailure 
          false
        else
          true
        end
    end
  end

  def install
    ## install_options: repository, lifecycle, profile
    ## valid repositories: composition, ops, sapi, bcs (default)

    ## start building hcmbcs args from options given
    args = (@resource[:install_options] || {}).dup
    args[:package] = @resource[:name]

    ## value of ensure parameter
    should = @resource.should(:ensure)
    self.debug "Ensuring => #{should}"

    ## if ensure includes some component of version release, we override install_options build and release;
    ## separate with space like: ensure => "<build> <release>", e.g. "1.9.2p270 1";
    ## this allows user to specify just build and get latest release
    case should
    when true, false, Symbol
      should = nil
    else
      (build, release) = should.split
      args[:build]   = build   if build
      args[:release] = release if release
    end

    ## convert to cmdline options for hcmbcs
    argstr = args.map { |k,v| "--#{k.to_s}=#{v}" }

    ## run hcmbcs with options
    begin
      output = hcmbcs "--install", argstr.join(' ')
      self.debug "hcmbcs output: #{output}"
    rescue Puppet::ExecutionFailure
      raise Puppet::Error, "failed hcmbcs --install"
    end

    ## check package was installed
    installed = self.query
    raise Puppet::Error, "Could not find package #{self.name}" unless installed

    ## hcmbcs calls it build, rpm calls it version
    args[:version] = args[:build]
    
    ## check version and release for what we installed match what was requested
    [:version, :release].each do |v|
      if args[v] and (args[v] != installed[v])
        raise Puppet::Error, "requested #{v.to_s} #{args[v]} does not match installed #{installed[v]}"
      end
    end

  end

  ## this is called on ensure => latest to get latest version, then update() is called
  def latest
    ## make hcmbcs jump through hoops to give us latest pkg version
    begin
      output = hcmbcs "--search", "--xml", "--package=#{self.name}"
    rescue Puppet::ExecutionFailure
      raise Puppet::Error, "failed hcmbcs --search"
    end

    ## scan with group gives array of arrays
    version = output.scan(/<hcm_release_fq_hcm_pn>#{self.name}-([^<]+)<\/hcm_release_fq_hcm_pn>/).last.first
    self.debug version

    return version
  end

  ## called on ensure => latest if installed version doesn't match latest;
  ## we can just invoke hcmbcs --install, since that will get latest available
  def update
    self.install
  end

end
