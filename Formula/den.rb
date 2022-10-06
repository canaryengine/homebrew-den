class Den < Formula
  desc "Den is a CLI utility for working with docker-compose environments"
  homepage "https://swiftotter.github.io/den"
  license "MIT"
  version "1.0.0-beta.9"
  url "https://github.com/swiftotter/den/archive/1.0.0-beta.9.tar.gz"
  sha256 "a16b6ee65df95128f83ce59d31c011fee8356866daeef49f051d351890db8e53"
  head "https://github.com/swiftotter/den.git", :branch => "main"

  # Check if Docker Desktop is installed; otherwise, install it via brew
  depends_on cask: "docker" unless File.exists?("/Applications/Docker.app")

  def install
    prefix.install Dir["*"]
  end

  def post_install
    # This is required so docker is found if it's not installed via brew
    ENV["PATH"] += ":/usr/local/bin" if OS.mac? || OS.linux?

    # Specify necessary environment variables
    ENV["WARDEN_DIR"] = prefix
    ENV["WARDEN_HOME_DIR"] = Dir.home
    ENV["WARDEN_SERVICE_DIR"] = prefix

    # Future proof environment variable names
    ENV["DEN_HOME_DIR"] = prefix
    ENV["DEN_SERVICE_DIR"] = prefix

    Pathname(prefix/"docker").cd do
      den_version = File.read(prefix/"version").strip()
      system "docker",
            "compose",
            "-p", "den",
            "build",
            "--no-cache",
            "--build-arg", "DEN_VERSION=#{den_version}",
            "dashboard"
      system "docker",
            "compose",
            "--project-directory", prefix,
            "-p", "den",
            "-f", prefix/"docker/docker-compose.yml",
            "up", "-d", "dashboard"
    end
  end

  def caveats
    <<~EOS
      Den manages a set of global services on the docker host machine. You
      will need to have Docker installed and Docker Compose (>= 2.2.3) available in your
      local $PATH configuration prior to starting Den.

      To start warden simply run:
        den svc up
      
      This command will automatically run "den install" to setup a trusted
      local root certificate and sign an SSL certificate for use by services
      managed by warden via the "warden sign-certificate warden.test" command.
      To print a complete list of available commands simply run "den" without
      any arguments.
    EOS
  end
end

