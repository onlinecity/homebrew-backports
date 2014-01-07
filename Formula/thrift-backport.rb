require 'formula'

class ThriftBackport < Formula
  homepage 'http://thrift.apache.org'
  # The thrift.apache.org 0.9.1 archive is missing PHP ext, fixed in THRIFT-2129
  # By grapping the source from git instead, it's fixed, but we need to bootstrap
  url 'https://git-wip-us.apache.org/repos/asf/thrift.git', :branch => "0.9.1"
  version "0.9.1"

  head do
    url 'https://git-wip-us.apache.org/repos/asf/thrift.git', :branch => "master"
    #depends_on :autoconf
    #depends_on :automake
    #depends_on :libtool
  end

  env :userpaths  # To find brew'ed php (, upstream uses `php-config` some places)

  # We need to install from sources, because website tarball is missing php-ext
  depends_on :autoconf
  depends_on :automake
  depends_on :libtool

  option "with-haskell", "Install Haskell binding"
  option "with-erlang", "Install Erlang binding"
  option "with-java", "Install Java binding"
  option "with-perl", "Install Perl binding"
  option "with-php", "Install Php binding"

  depends_on 'boost'
  depends_on :python => :optional
  depends_on "php53" => [:optional, 'with-php'] if Formula.factory("php53").linked_keg.exist?
  depends_on "php54" => [:optional, 'with-php'] if Formula.factory("php54").linked_keg.exist?
  depends_on "php55" => [:optional, 'with-php'] if Formula.factory("php55").linked_keg.exist?

  # Patches required to compile 0.9.1 with "-std=c++11", maybe remove when thrift 1.0 hits
  def patches
    [
      # Apply THRIFT-2201 fix from master to 0.9.1 branch (required for clang to compile with C++11 support)
      "https://git-wip-us.apache.org/repos/asf?p=thrift.git;a=patch;h=836d95f9f00be73c6936d407977796181d1a506c",
      # Apply THRIFT-667
      "https://git-wip-us.apache.org/repos/asf?p=thrift.git;a=patch;h=12c09f44cb291b1ecc4074cb3a55775b375fa8b2",
      # Apply THRIFT-1755
      "https://git-wip-us.apache.org/repos/asf?p=thrift.git;a=patch;h=8cd3efe50a42975375e8ff3bc03306d9e4174314",
      # Apply THRIFT-2045
      "https://git-wip-us.apache.org/repos/asf?p=thrift.git;a=patch;h=282e440c6de219b7b8f32b01cc7eb599f534f33f",
      "https://git-wip-us.apache.org/repos/asf?p=thrift.git;a=patch;h=9f9cd10e813ef574dd5578d78ca26a9088383d3a",
      "https://git-wip-us.apache.org/repos/asf?p=thrift.git;a=patch;h=e957675647d3d7caafe842aa85cbd987e91b21f9",
      # Apply THRIFT-2229 fix from master to 0.9.1 branch
      "https://git-wip-us.apache.org/repos/asf?p=thrift.git;a=patch;h=5f2d34e5ab33651059a085525b3adbab6a877e6f"
    ]
  end

  def php_conf_d
    if Formula.factory("php53").linked_keg.exist?
      "#{HOMEBREW_PREFIX}/etc/php/5.3/conf.d"
    elsif Formula.factory("php54").linked_keg.exist?
      "#{HOMEBREW_PREFIX}/etc/php/5.4/conf.d"
    elsif Formula.factory("php55").linked_keg.exist?
      "#{HOMEBREW_PREFIX}/etc/php/5.5/conf.d"
    else
      ""
    end
  end

  def install
    # system "./bootstrap.sh" if build.head?
    system "./bootstrap.sh" # always install from source

    exclusions = ["--without-ruby"]

    exclusions << "--without-python" unless build.with? "python"
    exclusions << "--without-haskell" unless build.include? "with-haskell"
    exclusions << "--without-java" unless build.include? "with-java"
    exclusions << "--without-perl" unless build.include? "with-perl"
    exclusions << "--without-php" unless build.include? "with-php"
    exclusions << "--without-erlang" unless build.include? "with-erlang"

    ENV["PY_PREFIX"] = prefix  # So python bindins don't install to /usr!
    ENV["CXXFLAGS"] = "-std=c++11" # Required on OS 10.9, see THRIFT-1458 & THRIFT-2229

    if build.include? "with-php"
      ENV["PHP_PREFIX"] = "#{HOMEBREW_PREFIX}/lib"
      ENV["PHP_CONFIG_PREFIX"] = "#{php_conf_d}"
    end

    system "./configure", "--disable-debug",
                          "--prefix=#{prefix}",
                          "--libdir=#{lib}",
                          *exclusions
    ENV.j1
    system "make"
    system "make install"
  end

  def caveats
    <<-EOS.undent
    To install Ruby bindings:
      gem install thrift

    To install PHP bindings:
      Install brew'ed php
      brew install thrift-backport --with-php

    EOS
  end
end
