require 'formula'

class ThriftBackport < Formula
  homepage 'http://thrift.apache.org'
  url 'http://archive.apache.org/dist/thrift/0.9.1/thrift-0.9.1.tar.gz'
  sha1 'dc54a54f8dc706ffddcd3e8c6cd5301c931af1cc'

  head do
    url 'https://git-wip-us.apache.org/repos/asf/thrift.git', :branch => "master"
    depends_on :autoconf
    depends_on :automake
    depends_on :libtool
    depends_on 'pkg-config' => :build
  end

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

  def install
    system "./bootstrap.sh" if build.head?

    exclusions = ["--without-ruby", "--without-tests", "--without-php_extension"]

    exclusions << "--without-python" unless build.with? "python"
    exclusions << "--without-haskell" unless build.include? "with-haskell"
    exclusions << "--without-java" unless build.include? "with-java"
    exclusions << "--without-perl" unless build.include? "with-perl"
    exclusions << "--without-php" unless build.include? "with-php"
    exclusions << "--without-erlang" unless build.include? "with-erlang"

    ENV.cxx11 if MacOS.version >= :mavericks && ENV.compiler == :clang

    ENV["PY_PREFIX"] = prefix  # So python bindins don't install to /usr!
    ENV["PHP_PREFIX"] = prefix # So PHP bindings don't install to /usr!

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
      brew install thrift-backport --with-php
      extension available from josegonzalez/php tap

    EOS
  end
end
